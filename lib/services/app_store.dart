import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/record.dart';
import 'spark_commands.dart';

class AppStore {
  AppStore._();
  static final instance = AppStore._();
  final db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  Stream<List<Record>> watch(
    String collection, {
    String? field,
    Object? equals,
  }) {
    if (collection == 'settings') {
      return db
          .collection(collection)
          .doc(uid)
          .snapshots()
          .map((snapshot) => snapshot.exists
              ? [Record(snapshot.id, snapshot.data()!)]
              : <Record>[]);
    }
    Query<Map<String, dynamic>> query = db.collection(collection);
    final tenantInbox =
        field == 'recipientUid' &&
        (collection == 'invoices' || collection == 'notifications');
    final tenantIdentity = collection == 'tenants' && field == 'email';
    if (!collection.startsWith('users/') && !tenantInbox && !tenantIdentity) {
      query = query.where('ownerId', isEqualTo: uid);
    }
    if (field != null) query = query.where(field, isEqualTo: equals);
    return query.snapshots().map(
      (s) => s.docs.map((d) => Record(d.id, d.data())).toList(),
    );
  }

  Stream<Record?> document(String collection, String id) => db
      .collection(collection)
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Record(d.id, d.data()!) : null);
  late final commands = SparkCommands(db);
  Future<Map<String, dynamic>> linkCurrentTenantByEmail(String tenantId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null || user.email!.trim().isEmpty) {
      throw StateError('Tài khoản đăng nhập chưa có email');
    }
    if (!user.emailVerified) {
      throw StateError('Hãy xác minh email trước khi liên kết hồ sơ thuê');
    }
    return _linkTenantByEmail(user, tenantId);
  }

  Future<Map<String, dynamic>> command(
    String action, {
    String? id,
    Map<String, dynamic>? data,
    Map<String, dynamic> args = const {},
  }) async {
    if (action == 'migrateOwnerData' || action == 'migrateServiceIds') {
      final result = await FirebaseFunctions.instanceFor(
        region: 'asia-southeast1',
      ).httpsCallable('manage').call({'action': action});
      return Map<String, dynamic>.from(result.data as Map);
    }
    return commands.command(action, key: id, d: data ?? {}, args: args);
  }

  Future<Map<String, dynamic>> tenantPortal({
    String action = 'load',
    Map<String, dynamic> data = const {},
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.emailVerified) {
      throw StateError('Hãy đăng nhập và xác minh email trước.');
    }
    return switch (action) {
      'lookup' => _lookupTenantByEmail(user),
      'createMaintenance' => _createTenantMaintenance(user, data),
      'load' => _loadTenantPortal(user),
      _ => throw StateError('Thao tác người thuê không hợp lệ.'),
    };
  }

  Future<Map<String, dynamic>> _lookupTenantByEmail(User user) async {
    final email = user.email?.trim();
    if (email == null || email.isEmpty) {
      throw StateError('Tài khoản đăng nhập chưa có email.');
    }
    final snapshot = await db
        .collection('tenants')
        .where('email', isEqualTo: email)
        .get();
    final profiles = snapshot.docs
        .where((doc) {
          final tenant = doc.data();
          return tenant['archived'] != true &&
              '${tenant['roomId'] ?? ''}'.isNotEmpty;
        })
        .map(
          (doc) => {
            'id': doc.id,
            'name': doc.data()['name'] ?? '',
            'email': doc.data()['email'] ?? '',
            'authUid': doc.data()['authUid'] ?? '',
          },
        )
        .toList();
    return {'profiles': profiles};
  }

  Future<Map<String, dynamic>> _linkTenantByEmail(
    User user,
    String tenantId,
  ) async {
    if (tenantId.isEmpty || tenantId.contains('/')) {
      throw StateError('Hồ sơ thuê không hợp lệ.');
    }
    final tenantRef = db.collection('tenants').doc(tenantId);
    final userRef = db.collection('users').doc(user.uid);
    final tenantName = await db.runTransaction((transaction) async {
      final tenantSnapshot = await transaction.get(tenantRef);
      final userSnapshot = await transaction.get(userRef);
      final tenant = tenantSnapshot.data();
      if (!tenantSnapshot.exists ||
          tenant == null ||
          '${tenant['email'] ?? ''}'.trim().toLowerCase() !=
              user.email!.trim().toLowerCase() ||
          tenant['archived'] == true ||
          '${tenant['roomId'] ?? ''}'.isEmpty) {
        throw StateError('Email không khớp hồ sơ thuê đang hoạt động.');
      }
      final linkedUid = '${tenant['authUid'] ?? ''}';
      if (linkedUid.isNotEmpty && linkedUid != user.uid) {
        throw StateError('Hồ sơ thuê này đã liên kết với tài khoản khác.');
      }
      final priorMapping = userSnapshot.data();
      if (priorMapping != null &&
          priorMapping['tenantId'] != null &&
          priorMapping['tenantId'] != tenantId) {
        throw StateError(
          'Tài khoản này đã liên kết với hồ sơ thuê khác. Hãy liên hệ chủ trọ.',
        );
      }
      transaction.update(tenantRef, {
        'authUid': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(userRef, {
        'tenantId': tenantId,
        'ownerId': tenant['ownerId'],
        'roomId': tenant['roomId'],
      });
      return '${tenant['name'] ?? ''}';
    });
    return {'tenantName': tenantName};
  }

  Future<Map<String, dynamic>> _loadTenantPortal(User user) async {
    final userSnapshot = await db.collection('users').doc(user.uid).get();
    var mapping = userSnapshot.data();
    mapping ??= await _restoreTenantMapping(user);
    if (mapping == null ||
        mapping['tenantId'] is! String ||
        mapping['ownerId'] is! String ||
        mapping['roomId'] is! String) {
      throw StateError('Hồ sơ thuê chưa được liên kết với tài khoản này.');
    }
    final tenantId = mapping['tenantId'] as String;
    final ownerId = mapping['ownerId'] as String;
    final roomId = mapping['roomId'] as String;
    final tenantRef = db.collection('tenants').doc(tenantId);
    final roomRef = db.collection('rooms').doc(roomId);
    final settingsRef = db.collection('settings').doc(ownerId);
    final tenantSnapshot = await tenantRef.get();
    final roomSnapshot = await roomRef.get();
    final settingsSnapshot = await settingsRef.get();
    if (!tenantSnapshot.exists || !roomSnapshot.exists) {
      throw StateError(
        'Không tìm thấy hồ sơ hoặc phòng thuê. Hãy liên hệ chủ trọ.',
      );
    }
    final room = roomSnapshot.data()!;
    final serviceIds = (room['serviceIds'] as List? ?? const [])
        .whereType<String>()
        .toSet();
    final serviceSnapshots = await Future.wait(
      serviceIds.map((id) => db.collection('services').doc(id).get()),
    );
    final results = await Future.wait([
      _tenantContracts(ownerId, roomId, tenantId),
      _tenantMeters(ownerId, roomId, serviceIds),
      _tenantMaintenance(ownerId, roomId, tenantId),
      db
          .collection('invoices')
          .where('ownerId', isEqualTo: ownerId)
          .where('recipientUid', isEqualTo: user.uid)
          .get(),
    ]);
    final contracts = results[0] as List<Map<String, dynamic>>;
    final meters = results[1] as List<Map<String, dynamic>>;
    final maintenance = results[2] as List<Map<String, dynamic>>;
    final invoiceSnapshot = results[3] as QuerySnapshot<Map<String, dynamic>>;
    return {
      'tenant': {
        'id': tenantId,
        for (final field in ['name', 'email', 'phone', 'role'])
          if (tenantSnapshot.data()![field] != null)
            field: tenantSnapshot.data()![field],
        'roomId': roomId,
      },
      'room': {
        'id': roomId,
        for (final field in [
          'name',
          'condition',
          'status',
          'area',
          'capacity',
          'price',
          'billingDay',
          'paymentTermDays',
          'description',
        ])
          if (room[field] != null) field: room[field],
      },
      'landlord': {
        for (final field in ['name', 'phone', 'address'])
          if (settingsSnapshot.data()?[field] != null)
            field: settingsSnapshot.data()![field],
      },
      'contracts': contracts
          .where(
            (contract) =>
                contract['tenantId'] == tenantId ||
                (contract['tenantIds'] as List? ?? const []).contains(tenantId),
          )
          .map(
            (contract) => _projectTenantRecord(contract, [
              'number',
              'status',
              'roomName',
              'startDate',
              'endDate',
              'rent',
              'deposit',
              'note',
            ]),
          )
          .toList(),
      'services': serviceSnapshots
          .where((snapshot) => snapshot.exists)
          .map(
            (snapshot) =>
                _projectTenantRecord(snapshot.data()!..['id'] = snapshot.id, [
                  'id',
                  'name',
                  'mode',
                  'price',
                  'unit',
                  'description',
                  'archived',
                ]),
          )
          .where((service) => service['archived'] != true)
          .toList(),
      'meters': meters
          .where((meter) => serviceIds.contains(meter['serviceId']))
          .map(
            (meter) => _projectTenantRecord(meter, [
              'id',
              'serviceId',
              'period',
              'previous',
              'current',
            ]),
          )
          .toList(),
      'maintenance': maintenance
          .map(
            (item) => _projectTenantRecord(item, [
              'id',
              'title',
              'description',
              'issueType',
              'priority',
              'status',
              'cost',
              'createdAt',
              'updatedAt',
            ]),
          )
          .toList(),
      'invoices': invoiceSnapshot.docs
          .map(
            (doc) => _projectTenantRecord(
              {'id': doc.id, ...doc.data()},
              [
                'id',
                'roomName',
                'period',
                'dueDate',
                'issueDate',
                'total',
                'status',
                'code',
              ],
            ),
          )
          .toList(),
    };
  }

  Future<Map<String, dynamic>?> _restoreTenantMapping(User user) async {
    final email = user.email?.trim();
    if (email == null || email.isEmpty) {
      throw StateError('Tài khoản đăng nhập chưa có email.');
    }
    final profiles = await db
        .collection('tenants')
        .where('authUid', isEqualTo: user.uid)
        .get();
    final linkedProfiles = profiles.docs.where((profile) {
      final tenant = profile.data();
      return '${tenant['email'] ?? ''}'.trim().toLowerCase() ==
              email.toLowerCase() &&
          tenant['archived'] != true &&
          tenant['ownerId'] is String &&
          tenant['roomId'] is String &&
          (tenant['roomId'] as String).isNotEmpty;
    }).toList();
    if (linkedProfiles.isEmpty) return null;
    if (linkedProfiles.length != 1) {
      throw StateError(
        'Tài khoản này liên kết với nhiều hồ sơ thuê. Hãy liên hệ chủ trọ.',
      );
    }

    final profile = linkedProfiles.single;
    final tenant = profile.data();
    final userRef = db.collection('users').doc(user.uid);
    final tenantRef = profile.reference;
    return db.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final tenantSnapshot = await transaction.get(tenantRef);
      if (userSnapshot.exists) {
        throw StateError(
          'Dữ liệu liên kết tài khoản chưa hợp lệ. Hãy liên hệ chủ trọ để kiểm tra.',
        );
      }
      final currentTenant = tenantSnapshot.data();
      if (currentTenant == null ||
          currentTenant['authUid'] != user.uid ||
          '${currentTenant['email'] ?? ''}'.trim().toLowerCase() !=
              email.toLowerCase() ||
          currentTenant['archived'] == true ||
          currentTenant['ownerId'] != tenant['ownerId'] ||
          currentTenant['roomId'] != tenant['roomId']) {
        throw StateError(
          'Hồ sơ thuê đã thay đổi. Hãy đăng nhập lại hoặc liên hệ chủ trọ.',
        );
      }
      final mapping = {
        'tenantId': profile.id,
        'ownerId': tenant['ownerId'],
        'roomId': tenant['roomId'],
      };
      transaction.set(userRef, mapping);
      return mapping;
    });
  }

  Future<List<Map<String, dynamic>>> _tenantMeters(
    String ownerId,
    String roomId,
    Set<String> serviceIds,
  ) async {
    final snapshots = await Future.wait(
      serviceIds.map(
        (serviceId) => db
            .collection('meters')
            .where('ownerId', isEqualTo: ownerId)
            .where('roomId', isEqualTo: roomId)
            .where('serviceId', isEqualTo: serviceId)
            .get(),
      ),
    );
    return [
      for (final snapshot in snapshots)
        for (final document in snapshot.docs)
          {'id': document.id, ...document.data()},
    ];
  }

  Future<List<Map<String, dynamic>>> _tenantMaintenance(
    String ownerId,
    String roomId,
    String tenantId,
  ) async {
    final snapshot = await db
        .collection('maintenance')
        .where('ownerId', isEqualTo: ownerId)
        .where('roomId', isEqualTo: roomId)
        .where('tenantId', isEqualTo: tenantId)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> _tenantContracts(
    String ownerId,
    String roomId,
    String tenantId,
  ) async {
    final contracts = await Future.wait([
      db
          .collection('contracts')
          .where('ownerId', isEqualTo: ownerId)
          .where('roomId', isEqualTo: roomId)
          .where('tenantId', isEqualTo: tenantId)
          .get(),
      db
          .collection('contracts')
          .where('ownerId', isEqualTo: ownerId)
          .where('roomId', isEqualTo: roomId)
          .where('tenantIds', arrayContains: tenantId)
          .get(),
    ]);
    final byId = <String, Map<String, dynamic>>{};
    for (final snapshot in contracts) {
      for (final document in snapshot.docs) {
        byId[document.id] = {'id': document.id, ...document.data()};
      }
    }
    return byId.values.toList();
  }

  Future<Map<String, dynamic>> _createTenantMaintenance(
    User user,
    Map<String, dynamic> data,
  ) async {
    final userRef = db.collection('users').doc(user.uid);
    final requestId = await db.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final mapping = userSnapshot.data();
      if (mapping == null ||
          mapping['tenantId'] is! String ||
          mapping['ownerId'] is! String ||
          mapping['roomId'] is! String) {
        throw StateError('Hồ sơ thuê chưa được liên kết với tài khoản này.');
      }
      final tenantId = mapping['tenantId'] as String;
      final roomId = mapping['roomId'] as String;
      final ownerId = mapping['ownerId'] as String;
      final tenantRef = db.collection('tenants').doc(tenantId);
      final roomRef = db.collection('rooms').doc(roomId);
      final tenantSnapshot = await transaction.get(tenantRef);
      final roomSnapshot = await transaction.get(roomRef);
      final tenant = tenantSnapshot.data();
      final room = roomSnapshot.data();
      if (!tenantSnapshot.exists ||
          !roomSnapshot.exists ||
          tenant == null ||
          room == null ||
          tenant['authUid'] != user.uid ||
          tenant['archived'] == true ||
          tenant['ownerId'] != ownerId ||
          tenant['roomId'] != roomId ||
          room['ownerId'] != ownerId ||
          room['archived'] == true) {
        throw StateError('Hồ sơ thuê hoặc phòng không còn hoạt động.');
      }
      final title = _tenantText(data['title'], 'tiêu đề yêu cầu', max: 100);
      final description = _tenantText(
        data['description'],
        'mô tả yêu cầu',
        max: 1000,
      );
      final issueType = _tenantText(data['issueType'], 'loại sự cố');
      final priority = _tenantText(data['priority'], 'mức độ ưu tiên');
      if (![
        'Thiết bị',
        'Điện / Nước',
        'Nội thất',
        'Khác',
      ].contains(issueType)) {
        throw StateError('Loại sự cố không hợp lệ.');
      }
      if (!['Thấp', 'Trung bình', 'Cao'].contains(priority)) {
        throw StateError('Mức độ ưu tiên không hợp lệ.');
      }
      final requestRef = db.collection('maintenance').doc();
      transaction.set(requestRef, {
        'ownerId': ownerId,
        'roomId': roomId,
        'tenantId': tenantId,
        'requesterUid': user.uid,
        'roomName': room['name'] ?? '',
        'tenantName': tenant['name'] ?? '',
        'title': title,
        'description': description,
        'issueType': issueType,
        'priority': priority,
        'status': 'new',
        'cost': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return requestRef.id;
    });
    return {'id': requestId};
  }

  Map<String, dynamic> _projectTenantRecord(
    Map<String, dynamic> source,
    List<String> fields,
  ) => {
    for (final field in fields)
      if (source.containsKey(field)) field: source[field],
  };

  String _tenantText(dynamic value, String field, {int max = 4000}) {
    if (value is! String || value.trim().isEmpty || value.length > max) {
      throw StateError('Vui lòng nhập $field.');
    }
    return value.trim();
  }

  Future<void> reportPayment(String id, String note) =>
      commands.reportPayment(id, note);

  Future<void> markRead(String noticeId) => db
      .collection('users')
      .doc(uid)
      .collection('reads')
      .doc(noticeId)
      .set({'readAt': FieldValue.serverTimestamp()});
}

String errorText(Object? e) {
  if (e is FirebaseFunctionsException && e.code == 'not-found') {
    return 'Cloud Function tenantPortal chưa được triển khai. Quản trị viên cần chạy: firebase deploy --project quan-li-phong --only functions';
  }
  if (e is FirebaseException) {
    final details = e.message?.trim();
    return details == null || details.isEmpty
        ? 'Firebase ${e.code}: Không có thêm chi tiết lỗi.'
        : 'Firebase ${e.code}: $details';
  }
  return e.toString().replaceFirst('Bad state: ', '');
}
