import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/record.dart';
import 'spark_commands.dart';

class AppStore {
  AppStore._();
  static final instance = AppStore._();
  static const _inviteAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final db = FirebaseFirestore.instance;
  final Map<String, Future<String>> _pendingManagerInviteCodes = {};
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  static String linkedUid(Map<String, dynamic>? tenant) {
    final userId = '${tenant?['userId'] ?? ''}'.trim();
    if (userId.isNotEmpty) return userId;
    return '${tenant?['authUid'] ?? ''}'.trim();
  }

  static bool isTenantLinkedToUid(Map<String, dynamic> tenant, String uid) =>
      '${tenant['userId'] ?? ''}'.trim() == uid ||
      '${tenant['authUid'] ?? ''}'.trim() == uid;

  static bool isTenantLinkedToOther(Map<String, dynamic> tenant, String uid) {
    final u = '${tenant['userId'] ?? ''}'.trim();
    final a = '${tenant['authUid'] ?? ''}'.trim();
    return (u.isNotEmpty && u != uid) || (a.isNotEmpty && a != uid);
  }
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

  Future<String> generateUniqueManagerInviteCode({int length = 6}) async {
    final random = Random.secure();
    for (var attempt = 0; attempt < 20; attempt++) {
      final code = List.generate(
        length,
        (_) => _inviteAlphabet[random.nextInt(_inviteAlphabet.length)],
      ).join();
      final existing = await db
          .collection('managers')
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();
      if (existing.docs.isEmpty) return code;
    }
    throw StateError('Chưa tạo được mã mời dãy trọ. Vui lòng thử lại.');
  }

  Future<String> createManagerAccount({
    required String uid,
    required String name,
    required String email,
    String phone = '',
  }) async {
    final managerRef = db.collection('managers').doc(uid);
    final existingSnap = await managerRef.get();
    final existingData = existingSnap.data();
    final existingCode = '${existingData?['inviteCode'] ?? ''}'
        .trim()
        .toUpperCase();
    final inviteCode = existingCode.isNotEmpty
        ? existingCode
        : await generateUniqueManagerInviteCode();

    if (existingSnap.exists) {
      if (existingData?['enabled'] == true && existingCode.isEmpty) {
        await managerRef.update({'inviteCode': inviteCode});
      }
      return inviteCode;
    }

    final normalizedPhone = phone.trim();
    await managerRef.set({
      'enabled': true,
      'role': 'landlord',
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      if (normalizedPhone.isNotEmpty) 'phone': normalizedPhone,
      'inviteCode': inviteCode,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return inviteCode;
  }

  Future<String> ensureManagerInviteCode() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Bạn cần đăng nhập trước.');
    }
    return _pendingManagerInviteCodes[user.uid] ??= () async {
      try {
        final managerRef = db.collection('managers').doc(user.uid);
        final snap = await managerRef.get();
        final data = snap.data();
        if (!snap.exists || data == null || data['enabled'] != true) {
          throw StateError('Tài khoản chưa được cấp quyền Chủ trọ.');
        }
        final existingCode = '${data['inviteCode'] ?? ''}'.trim().toUpperCase();
        if (existingCode.isNotEmpty) return existingCode;
        final code = await generateUniqueManagerInviteCode();
        await managerRef.update({'inviteCode': code});
        return code;
      } finally {
        _pendingManagerInviteCodes.remove(user.uid);
      }
    }();
  }

  Future<Map<String, dynamic>> joinRoomByInviteCode(String rawCode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Bạn cần đăng nhập trước khi nhập mã mời.');
    }
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      throw StateError('Vui lòng nhập mã mời từ chủ trọ.');
    }
    final userEmail = (user.email ?? '').trim().toLowerCase();
    if (userEmail.isEmpty) {
      throw StateError('Tài khoản đăng nhập chưa có email.');
    }

    // Bước 1: Truy vấn managers theo inviteCode
    final managerSnap = await db
        .collection('managers')
        .where('inviteCode', isEqualTo: code)
        .limit(1)
        .get();
    if (managerSnap.docs.isEmpty ||
        managerSnap.docs.first.data()['enabled'] == false) {
      throw StateError('Mã mời không tồn tại hoặc không chính xác');
    }
    final ownerId = managerSnap.docs.first.id;

    // Bước 2: Truy vấn tenants theo ownerId và email đã chuẩn hóa
    final tenantSnap = await db
        .collection('tenants')
        .where('ownerId', isEqualTo: ownerId)
        .where('email', isEqualTo: userEmail)
        .limit(5)
        .get();
    final roomMatches = tenantSnap.docs.where((doc) {
      final data = doc.data();
      return data['archived'] != true &&
          '${data['roomId'] ?? ''}'.trim().isNotEmpty;
    }).toList();
    if (roomMatches.isEmpty) {
      throw StateError(
        'Email của bạn chưa được chủ trọ thêm vào phòng nào trong dãy trọ này',
      );
    }
    final activeMatches = roomMatches
        .where((doc) => doc.data()['hasActiveContract'] != false)
        .toList();
    if (activeMatches.isEmpty) {
      throw StateError(
        'Phòng của bạn hiện chưa có hợp đồng hiệu lực nên chưa thể tham gia bằng mã mời',
      );
    }

    QueryDocumentSnapshot<Map<String, dynamic>>? targetDoc;
    for (final doc in activeMatches) {
      if (isTenantLinkedToUid(doc.data(), user.uid) &&
          !isTenantLinkedToOther(doc.data(), user.uid)) {
        targetDoc = doc;
        break;
      }
    }
    targetDoc ??= activeMatches
        .where((doc) => !isTenantLinkedToOther(doc.data(), user.uid))
        .firstOrNull;
    if (targetDoc == null) {
      throw StateError(
        'Hồ sơ thuê này đã được liên kết với một tài khoản khác.',
      );
    }

    // Bước 3: Liên kết userId/authUid vào document tenants và lưu ánh xạ ở users/{uid}
    final tenantRef = targetDoc.reference;
    final userRef = db.collection('users').doc(user.uid);
    final linked = await db.runTransaction((transaction) async {
      final currentTenantSnap = await transaction.get(tenantRef);
      final userSnap = await transaction.get(userRef);
      final tenant = currentTenantSnap.data();
      final roomId = '${tenant?['roomId'] ?? ''}'.trim();
      final tenantEmail = '${tenant?['email'] ?? ''}'.trim().toLowerCase();
      if (!currentTenantSnap.exists ||
          tenant == null ||
          tenant['archived'] == true ||
          tenant['ownerId'] != ownerId ||
          tenantEmail != userEmail ||
          roomId.isEmpty) {
        throw StateError(
          'Email của bạn chưa được chủ trọ thêm vào phòng nào trong dãy trọ này',
        );
      }
      if (tenant['hasActiveContract'] == false) {
        throw StateError(
          'Phòng của bạn hiện chưa có hợp đồng hiệu lực nên chưa thể tham gia bằng mã mời',
        );
      }
      if (tenant['pendingRoomTransfer'] == true) {
        throw StateError(
          'Hồ sơ của bạn đang chờ xác nhận chuyển phòng. Hãy nhấn xác nhận chuyển phòng trên màn hình chính.',
        );
      }
      if (isTenantLinkedToOther(tenant, user.uid)) {
        throw StateError(
          'Hồ sơ thuê này đã được liên kết với một tài khoản khác.',
        );
      }

      final priorMapping = userSnap.data();
      final priorTenantId = '${priorMapping?['tenantId'] ?? ''}'.trim();
      if (priorTenantId.isNotEmpty && priorTenantId != currentTenantSnap.id) {
        final priorTenantSnap = await transaction.get(
          db.collection('tenants').doc(priorTenantId),
        );
        final priorTenant = priorTenantSnap.data();
        final stillActive =
            priorTenantSnap.exists &&
            priorTenant != null &&
            priorTenant['archived'] != true &&
            isTenantLinkedToUid(priorTenant, user.uid) &&
            '${priorTenant['roomId'] ?? ''}'.trim().isNotEmpty;
        if (stillActive) {
          if (priorTenant['roomId'] == roomId) {
            throw StateError('Tài khoản của bạn đã tham gia phòng này rồi.');
          }
          throw StateError(
            'Tài khoản của bạn đang liên kết với một phòng khác. Hãy nhờ chủ trọ cũ kết thúc hồ sơ trước.',
          );
        }
      }

      transaction.update(tenantRef, {
        'userId': user.uid,
        'authUid': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(userRef, {
        'tenantId': currentTenantSnap.id,
        'ownerId': ownerId,
        'roomId': roomId,
      });

      return {
        'roomId': roomId,
        'ownerId': ownerId,
        'tenantId': currentTenantSnap.id,
      };
    });

    var roomName = '';
    try {
      final roomSnap = await db
          .collection('rooms')
          .doc(linked['roomId'] as String)
          .get();
      roomName = '${roomSnap.data()?['name'] ?? ''}'.trim();
    } catch (_) {}

    return {...linked, 'roomName': roomName};
  }

  Map<String, dynamic> _pendingTransferPayload({
    required String tenantId,
    required Map<String, dynamic> tenantData,
    String fallbackFromRoomId = '',
  }) {
    final actualRoomId = '${tenantData['roomId'] ?? ''}'.trim();
    return {
      'pendingRoomTransfer': true,
      'tenantId': tenantId,
      'tenantName': '${tenantData['name'] ?? ''}'.trim(),
      'fromRoomId': '${tenantData['transferFromRoomId'] ?? fallbackFromRoomId}'
          .trim(),
      'fromRoomName': '${tenantData['transferFromRoomName'] ?? ''}'.trim(),
      'toRoomId':
          '${tenantData['transferToRoomId'] ?? actualRoomId}'.trim().isEmpty
          ? actualRoomId
          : '${tenantData['transferToRoomId']}'.trim(),
      'toRoomName': '${tenantData['transferToRoomName'] ?? ''}'.trim(),
    };
  }

  Future<Map<String, dynamic>> confirmRoomTransfer({String? noticeId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Bạn cần đăng nhập trước.');
    }
    final userRef = db.collection('users').doc(user.uid);
    final userSnap = await userRef.get();
    var tenantId = '${userSnap.data()?['tenantId'] ?? ''}'.trim();
    if (tenantId.isEmpty) {
      final uidDocs = await Future.wait([
        _safeQuery(
          db.collection('tenants').where('userId', isEqualTo: user.uid),
        ),
        _safeQuery(
          db.collection('tenants').where('authUid', isEqualTo: user.uid),
        ),
      ]);
      for (final docs in uidDocs) {
        for (final doc in docs) {
          final d = doc.data();
          if (d['archived'] != true &&
              '${d['roomId'] ?? ''}'.trim().isNotEmpty &&
              !isTenantLinkedToOther(d, user.uid)) {
            tenantId = doc.id;
            break;
          }
        }
        if (tenantId.isNotEmpty) break;
      }
    }
    if (tenantId.isEmpty) {
      throw StateError('Không tìm thấy hồ sơ thuê cần xác nhận chuyển phòng.');
    }

    final tenantRef = db.collection('tenants').doc(tenantId);
    final result = await db.runTransaction((transaction) async {
      final currentSnap = await transaction.get(tenantRef);
      final tenant = currentSnap.data();
      final actualOwnerId = '${tenant?['ownerId'] ?? ''}'.trim();
      final actualRoomId = '${tenant?['roomId'] ?? ''}'.trim();
      if (!currentSnap.exists ||
          tenant == null ||
          tenant['archived'] == true ||
          !isTenantLinkedToUid(tenant, user.uid) ||
          isTenantLinkedToOther(tenant, user.uid) ||
          actualOwnerId.isEmpty ||
          actualRoomId.isEmpty) {
        throw StateError('Hồ sơ thuê không còn hiệu lực.');
      }
      if (tenant['pendingRoomTransfer'] == true) {
        transaction.update(tenantRef, {
          'pendingRoomTransfer': false,
          'confirmedRoomTransferAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      transaction.set(userRef, {
        'tenantId': tenantId,
        'ownerId': actualOwnerId,
        'roomId': actualRoomId,
      });
      return {
        'tenantId': tenantId,
        'ownerId': actualOwnerId,
        'roomId': actualRoomId,
        'roomName': '${tenant['transferToRoomName'] ?? ''}'.trim(),
      };
    });

    try {
      if (noticeId != null && noticeId.trim().isNotEmpty) {
        await markRead(noticeId.trim());
      }
      final notices = await _safeQuery(
        db.collection('notifications').where('recipientUid', isEqualTo: user.uid),
      );
      for (final n in notices) {
        if (n.data()['type'] == 'room_transfer') {
          await markRead(n.id);
        }
      }
    } catch (_) {}

    return result;
  }

  Future<Map<String, dynamic>?> loadTenantPortalOrNull() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final userRef = db.collection('users').doc(user.uid);
    DocumentSnapshot<Map<String, dynamic>> userSnapshot;
    try {
      userSnapshot = await userRef.get();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return null;
      rethrow;
    }
    var mapping = userSnapshot.data();
    String? priorOwnerId;
    if (mapping != null &&
        mapping['ownerId'] is String &&
        (mapping['ownerId'] as String).trim().isNotEmpty) {
      priorOwnerId = (mapping['ownerId'] as String).trim();
    }

    if (mapping != null &&
        mapping['tenantId'] is String &&
        mapping['ownerId'] is String &&
        mapping['roomId'] is String) {
      final tenantId = (mapping['tenantId'] as String).trim();
      if (tenantId.isNotEmpty) {
        final tenantRef = db.collection('tenants').doc(tenantId);
        DocumentSnapshot<Map<String, dynamic>>? tenantSnapshot;
        try {
          tenantSnapshot = await tenantRef.get();
        } on FirebaseException catch (e) {
          if (e.code != 'permission-denied') rethrow;
        }
        final tenantData = tenantSnapshot?.data();
        final actualRoomId = '${tenantData?['roomId'] ?? ''}'.trim();
        final actualOwnerId = '${tenantData?['ownerId'] ?? ''}'.trim();
        if (tenantSnapshot != null &&
            tenantSnapshot.exists &&
            tenantData != null &&
            tenantData['archived'] != true &&
            isTenantLinkedToUid(tenantData, user.uid) &&
            !isTenantLinkedToOther(tenantData, user.uid) &&
            actualOwnerId.isNotEmpty &&
            actualRoomId.isNotEmpty) {
          final mappedRoomId = '${mapping['roomId'] ?? ''}'.trim();
          final isUnconfirmedTransfer =
              tenantData['pendingRoomTransfer'] == true ||
              (mapping['ownerId'] == actualOwnerId &&
                  mappedRoomId.isNotEmpty &&
                  mappedRoomId != actualRoomId);
          if (isUnconfirmedTransfer) {
            return _pendingTransferPayload(
              tenantId: tenantId,
              tenantData: tenantData,
              fallbackFromRoomId: mappedRoomId,
            );
          }
          final needsMappingSync =
              mapping['ownerId'] != actualOwnerId ||
              mapping['roomId'] != actualRoomId;
          final needsTenantSync =
              '${tenantData['userId'] ?? ''}'.trim() != user.uid ||
              '${tenantData['authUid'] ?? ''}'.trim() != user.uid;
          final userEmail = (user.email ?? '').trim().toLowerCase();
          final tenantEmail = '${tenantData['email'] ?? ''}'
              .trim()
              .toLowerCase();
          final canSyncTenant =
              needsTenantSync &&
              userEmail.isNotEmpty &&
              tenantEmail == userEmail;
          if (needsMappingSync || canSyncTenant) {
            mapping = await db.runTransaction((transaction) async {
              final nextMapping = {
                'tenantId': tenantId,
                'ownerId': actualOwnerId,
                'roomId': actualRoomId,
              };
              if (canSyncTenant) {
                transaction.update(tenantRef, {
                  'userId': user.uid,
                  'authUid': user.uid,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
              }
              if (needsMappingSync) {
                transaction.set(userRef, nextMapping);
              }
              return nextMapping;
            });
          }
          return _loadTenantPortal(user, resolvedMapping: mapping);
        }
      }
    }

    final pendingFromSearch = await _findPendingTransferProfile(user);
    if (pendingFromSearch != null) return pendingFromSearch;

    mapping = await _restoreTenantMapping(user, priorOwnerId: priorOwnerId);
    if (mapping == null) return null;
    return _loadTenantPortal(user, resolvedMapping: mapping);
  }

  Future<Map<String, dynamic>?> _findPendingTransferProfile(User user) async {
    final uidDocs = await Future.wait([
      _safeQuery(db.collection('tenants').where('userId', isEqualTo: user.uid)),
      _safeQuery(
        db.collection('tenants').where('authUid', isEqualTo: user.uid),
      ),
    ]);
    for (final docs in uidDocs) {
      for (final doc in docs) {
        final d = doc.data();
        if (d['archived'] != true &&
            d['pendingRoomTransfer'] == true &&
            '${d['roomId'] ?? ''}'.trim().isNotEmpty &&
            !isTenantLinkedToOther(d, user.uid)) {
          return _pendingTransferPayload(tenantId: doc.id, tenantData: d);
        }
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> tenantPortal({
    String action = 'load',
    Map<String, dynamic> data = const {},
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Hãy đăng nhập trước.');
    }
    if (action == 'lookup' && !user.emailVerified) {
      throw StateError('Hãy xác minh email trước.');
    }
    return switch (action) {
      'lookup' => _lookupTenantByEmail(user),
      'createMaintenance' => _createTenantMaintenance(user, data),
      'cancelMaintenance' => _cancelTenantMaintenance(user, data),
      'load' => _loadTenantPortal(user),
      _ => throw StateError('Thao tác người thuê không hợp lệ.'),
    };
  }

  Future<Map<String, dynamic>> _lookupTenantByEmail(User user) async {
    final email = user.email?.trim().toLowerCase();
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
            'userId': linkedUid(doc.data()),
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
      if (isTenantLinkedToOther(tenant, user.uid)) {
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
        'userId': user.uid,
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

  Future<Map<String, dynamic>> _loadTenantPortal(
    User user, {
    Map<String, dynamic>? resolvedMapping,
  }) async {
    var mapping = resolvedMapping;
    if (mapping == null) {
      final userSnapshot = await db.collection('users').doc(user.uid).get();
      mapping = userSnapshot.data();
      final priorOwnerId = mapping?['ownerId'] is String
          ? mapping!['ownerId'] as String
          : null;
      mapping ??= await _restoreTenantMapping(user, priorOwnerId: priorOwnerId);
    }
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
      _tenantInvoices(ownerId, roomId, user.uid),
    ]);
    final contracts = results[0];
    final meters = results[1];
    final maintenance = results[2];
    final invoices = results[3];
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
      'invoices': invoices
          .where((doc) => doc['archived'] != true)
          .map(
            (doc) => _projectTenantRecord(doc, [
              'id',
              'roomName',
              'period',
              'dueDate',
              'issueDate',
              'total',
              'status',
              'code',
              'paidDateTime',
              'method',
              'paymentNote',
              'invoiceNote',
            ]),
          )
          .toList(),
    };
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _safeQuery(
    Query<Map<String, dynamic>> query,
  ) async {
    try {
      return (await query.get()).docs;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return const [];
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _restoreTenantMapping(
    User user, {
    String? priorOwnerId,
  }) async {
    final normalizedEmail = (user.email ?? '').trim().toLowerCase();
    final uidDocs = await Future.wait([
      _safeQuery(db.collection('tenants').where('userId', isEqualTo: user.uid)),
      _safeQuery(db.collection('tenants').where('authUid', isEqualTo: user.uid)),
    ]);
    final byId = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final docs in uidDocs) {
      for (final doc in docs) {
        byId[doc.id] = doc;
      }
    }
    var linkedProfiles = byId.values.where((profile) {
      final tenant = profile.data();
      final tenantEmail = '${tenant['email'] ?? ''}'.trim().toLowerCase();
      final emailCompatible =
          tenantEmail.isEmpty ||
          normalizedEmail.isEmpty ||
          tenantEmail == normalizedEmail;
      return emailCompatible &&
          !isTenantLinkedToOther(tenant, user.uid) &&
          tenant['archived'] != true &&
          tenant['ownerId'] is String &&
          (tenant['ownerId'] as String).trim().isNotEmpty &&
          tenant['roomId'] is String &&
          (tenant['roomId'] as String).trim().isNotEmpty;
    }).toList();

    if (linkedProfiles.isEmpty &&
        priorOwnerId != null &&
        priorOwnerId.trim().isNotEmpty &&
        normalizedEmail.isNotEmpty) {
      final emailDocs = await _safeQuery(
        db
            .collection('tenants')
            .where('ownerId', isEqualTo: priorOwnerId.trim())
            .where('email', isEqualTo: normalizedEmail)
            .limit(5),
      );
      linkedProfiles = emailDocs.where((profile) {
        final tenant = profile.data();
        return !isTenantLinkedToOther(tenant, user.uid) &&
            tenant['archived'] != true &&
            tenant['ownerId'] == priorOwnerId.trim() &&
            tenant['roomId'] is String &&
            (tenant['roomId'] as String).trim().isNotEmpty;
      }).toList();
    }

    if (linkedProfiles.isEmpty) return null;
    if (linkedProfiles.length != 1) {
      throw StateError(
        'Tài khoản này liên kết với nhiều hồ sơ thuê. Hãy liên hệ chủ trọ.',
      );
    }

    final profile = linkedProfiles.single;
    final tenant = profile.data();
    final ownerId = (tenant['ownerId'] as String).trim();
    final roomId = (tenant['roomId'] as String).trim();
    final userRef = db.collection('users').doc(user.uid);
    final tenantRef = profile.reference;
    return db.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final tenantSnapshot = await transaction.get(tenantRef);
      final currentTenant = tenantSnapshot.data();
      if (currentTenant == null ||
          currentTenant['archived'] == true ||
          isTenantLinkedToOther(currentTenant, user.uid) ||
          currentTenant['ownerId'] != ownerId ||
          currentTenant['roomId'] != roomId) {
        throw StateError(
          'Hồ sơ thuê đã thay đổi. Hãy đăng nhập lại hoặc liên hệ chủ trọ.',
        );
      }

      final currentTenantEmail = '${currentTenant['email'] ?? ''}'
          .trim()
          .toLowerCase();
      final needsTenantUidSync =
          '${currentTenant['userId'] ?? ''}'.trim() != user.uid ||
          '${currentTenant['authUid'] ?? ''}'.trim() != user.uid;
      if (needsTenantUidSync) {
        if (normalizedEmail.isEmpty ||
            (currentTenantEmail.isNotEmpty &&
                currentTenantEmail != normalizedEmail)) {
          throw StateError(
            'Hồ sơ thuê đã thay đổi. Hãy đăng nhập lại hoặc liên hệ chủ trọ.',
          );
        }
        transaction.update(tenantRef, {
          'userId': user.uid,
          'authUid': user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final mapping = {
        'tenantId': profile.id,
        'ownerId': ownerId,
        'roomId': roomId,
      };
      final existingMapping = userSnapshot.data();
      if (existingMapping == null ||
          existingMapping['tenantId'] != mapping['tenantId'] ||
          existingMapping['ownerId'] != mapping['ownerId'] ||
          existingMapping['roomId'] != mapping['roomId']) {
        transaction.set(userRef, mapping);
      }
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

  Future<List<Map<String, dynamic>>> _tenantInvoices(
    String ownerId,
    String roomId,
    String userUid,
  ) async {
    Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> safeQuery(
      Query<Map<String, dynamic>> query,
    ) async {
      try {
        return (await query.get()).docs;
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') return const [];
        rethrow;
      }
    }

    final results = await Future.wait([
      safeQuery(
        db
            .collection('invoices')
            .where('ownerId', isEqualTo: ownerId)
            .where('roomId', isEqualTo: roomId),
      ),
      safeQuery(
        db
            .collection('invoices')
            .where('ownerId', isEqualTo: ownerId)
            .where('recipientUid', isEqualTo: userUid),
      ),
    ]);
    final byId = <String, Map<String, dynamic>>{};
    for (final docs in results) {
      for (final doc in docs) {
        byId[doc.id] = {'id': doc.id, ...doc.data()};
      }
    }
    return byId.values.toList();
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
          !isTenantLinkedToUid(tenant, user.uid) ||
          isTenantLinkedToOther(tenant, user.uid) ||
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
      final noticeRef = db
          .collection('notifications')
          .doc('maint_new_${requestRef.id}');
      transaction.set(noticeRef, {
        'ownerId': ownerId,
        'title': 'Yêu cầu bảo trì mới',
        'body':
            '${room['name'] ?? 'Phòng'} (${tenant['name'] ?? 'Người thuê'}) · $title ($priority)',
        'audience': 'managers',
        'roomId': roomId,
        'maintenanceId': requestRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'delivery': 'in_app',
      });
      return requestRef.id;
    });
    return {'id': requestId};
  }

  Future<Map<String, dynamic>> _cancelTenantMaintenance(
    User user,
    Map<String, dynamic> data,
  ) async {
    final requestId = _tenantText(data['id'], 'mã yêu cầu bảo trì', max: 200);
    if (requestId.contains('/')) {
      throw StateError('Mã yêu cầu bảo trì không hợp lệ.');
    }
    final userRef = db.collection('users').doc(user.uid);
    final reqRef = db.collection('maintenance').doc(requestId);
    await db.runTransaction((transaction) async {
      final userSnap = await transaction.get(userRef);
      final reqSnap = await transaction.get(reqRef);
      final mapping = userSnap.data();
      final req = reqSnap.data();
      if (mapping == null || !reqSnap.exists || req == null) {
        throw StateError('Không tìm thấy yêu cầu bảo trì.');
      }
      if (req['ownerId'] != mapping['ownerId'] ||
          req['roomId'] != mapping['roomId'] ||
          req['tenantId'] != mapping['tenantId']) {
        throw StateError('Bạn không có quyền hủy yêu cầu này.');
      }
      if (req['status'] != 'new') {
        throw StateError('Chỉ có thể hủy yêu cầu đang ở trạng thái Mới.');
      }
      transaction.update(reqRef, {
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
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
