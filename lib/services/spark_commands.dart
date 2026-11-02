import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'billing.dart';

typedef Data = Map<String, dynamic>;

// Chỉ UID được cấp trong managers mới được ghi. Mọi chủ trọ trong bản này
// cùng quản lý một nhà trọ. Không cho người thuê ghi các dữ liệu nghiệp vụ khác.
class SparkCommands {
  final FirebaseFirestore db;
  SparkCommands(this.db);
  DocumentReference<Data> ref(String c, String id) => db.collection(c).doc(id);
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  dynamic stamp() => FieldValue.serverTimestamp();
  String text(dynamic v, String label, {bool optional = false}) {
    final s = v is String ? v.trim() : '';
    if ((!optional && s.isEmpty) || s.length > 4000)
      throw StateError('Vui lòng nhập $label');
    return s;
  }

  String id(dynamic v) {
    if (v is! String || v.isEmpty || v.contains('/') || v.length > 200)
      throw StateError('ID không hợp lệ');
    return v;
  }

  bool active(Data c) => ['active', 'scheduled'].contains(c['status']);
  Data found(Data? d, String label) {
    if (d == null || d['archived'] == true)
      throw StateError('$label không tồn tại hoặc đã lưu trữ');
    return d;
  }

  Future<Data?> read(Transaction tx, String c, String key) async {
    final s = await tx.get(ref(c, key));
    return s.exists ? {...s.data()!, '_id': s.id} : null;
  }

  Future<List<Data>> list(String c, {String? field, dynamic equals}) async {
    Query<Data> q = db.collection(c);
    if (field != null) q = q.where(field, isEqualTo: equals);
    return (await q.get(const GetOptions(source: Source.server))).docs
        .map((s) => {...s.data(), '_id': s.id})
        .toList();
  }

  void notice(
    Transaction tx,
    String key,
    String title,
    String body, {
    String? recipient,
    String? invoiceId,
  }) {
    tx.set(ref('notifications', key), {
      'title': title,
      'body': body,
      'audience': recipient == null ? 'managers' : 'tenant',
      if (recipient != null) 'recipientUid': recipient,
      if (invoiceId != null) 'invoiceId': invoiceId,
      'createdAt': stamp(),
      'delivery': 'in_app',
    });
  }

  // Mobile SDK không có transaction.get(query). Các query đọc từ server sau
  // khi đọc revision; mọi lệnh quản lý đều tăng revision trong cùng transaction.
  // Khi hai máy cùng ghi, Firestore retry callback và đọc lại các query.
  // Không sửa nghiệp vụ từ Console khi app đang ghi vì Console bỏ qua revision.
  Future<T> locked<T>(Future<T> Function(Transaction) work) =>
      db.runTransaction((tx) async {
        final lock = ref('system', 'revision');
        final s = await tx.get(lock);
        final result = await work(tx);
        tx.set(lock, {
          'value': (s.data()?['value'] as num? ?? 0) + 1,
          'updatedAt': stamp(),
        });
        return result;
      });
  Future<Data> command(
    String action, {
    String? key,
    Data d = const {},
    Data args = const {},
  }) async {
    if (action == 'runBilling') return runBilling();
    if (action == 'previewInvoice' || action == 'issueInvoice')
      return invoice(
        id(args['roomId']),
        Billing.period(args['period']),
        action == 'issueInvoice',
      );
    final generated = key ?? db.collection('_').doc().id;
    return locked((tx) async {
      final k = id(generated), now = Billing.today();
      if (action == 'saveRoom') {
        final old = await read(tx, 'rooms', k);
        final name = text(d['name'], 'tên phòng');
        final rooms = await list('rooms');
        if (rooms.any(
          (r) =>
              r['_id'] != k &&
              r['archived'] != true &&
              '${r['name']}'.trim().toLowerCase() == name.toLowerCase(),
        ))
          throw StateError('Tên phòng đã tồn tại');
        final tenants = await list('tenants', field: 'roomId', equals: k);
        final count = tenants.where((t) => t['archived'] != true).length;
        final capacity = Billing.number(
          d['capacity'],
          'Số người tối đa',
          min: 1,
        );
        if (capacity > 100 || capacity < count)
          throw StateError('Số người tối đa không phù hợp');
        final condition = text(d['condition'], 'tình trạng');
        if (!['Tốt', 'Đang sửa'].contains(condition))
          throw StateError('Tình trạng phải là Tốt hoặc Đang sửa');
        final day = Billing.number(d['billingDay'], 'Ngày chốt', min: 1);
        if (day > 31) throw StateError('Ngày chốt từ 1–31');
        final term = Billing.number(d['paymentTermDays'], 'Hạn thanh toán');
        if (term > 60) throw StateError('Hạn thanh toán tối đa 60 ngày');
        tx.set(ref('rooms', k), {
          'name': name,
          'condition': condition,
          'status': condition,
          'capacity': capacity,
          'people': count,
          'area': Billing.number(
            d['area'],
            'Diện tích',
            min: 0.1,
            integer: false,
          ),
          'price': Billing.number(d['price'], 'Giá thuê', min: 1),
          'deposit': Billing.number(d['deposit'], 'Tiền cọc'),
          'billingDay': '${day.toInt().toString().padLeft(2, '0')} hàng tháng',
          'paymentTermDays': term,
          'description': text(d['description'], 'mô tả', optional: true),
          'zone': FieldValue.delete(),
          'archived': false,
          'serviceIds': old?['serviceIds'] ?? [],
          'imageUrls': old?['imageUrls'] ?? [],
          'createdAt': old?['createdAt'] ?? stamp(),
          'updatedAt': stamp(),
        }, SetOptions(merge: true));
      } else if (action == 'archiveRoom') {
        found(await read(tx, 'rooms', k), 'Phòng');
        final ts = await list('tenants', field: 'roomId', equals: k),
            cs = await list('contracts', field: 'roomId', equals: k),
            bs = await list('invoices', field: 'roomId', equals: k);
        if (ts.any((t) => t['archived'] != true) ||
            cs.any(active) ||
            bs.any((b) => ['unpaid', 'reported'].contains(b['status'])))
          throw StateError(
            'Cần chuyển người thuê, kết thúc hợp đồng và xử lý hóa đơn trước',
          );
        tx.update(ref('rooms', k), {'archived': true, 'updatedAt': stamp()});
      } else if (action == 'saveTenant' || action == 'archiveTenant') {
        final old = await read(tx, 'tenants', k);
        final roomId = action == 'archiveTenant'
            ? ''
            : text(d['roomId'], 'phòng', optional: true);
        final oldRoom = '${old?['roomId'] ?? ''}';
        final room = roomId.isEmpty
            ? null
            : found(await read(tx, 'rooms', id(roomId)), 'Phòng');
        final previousRoom = oldRoom.isEmpty
            ? null
            : await read(tx, 'rooms', oldRoom);
        final cs = await list('contracts', field: 'tenantId', equals: k);
        if (cs.any((c) => active(c) && c['roomId'] != roomId))
          throw StateError('Kết thúc hợp đồng trước khi chuyển/xóa người thuê');
        final others = roomId.isEmpty
            ? <Data>[]
            : await list('tenants', field: 'roomId', equals: roomId);
        final count =
            others.where((t) => t['_id'] != k && t['archived'] != true).length +
            1;
        if (room != null &&
            (room['condition'] == 'Đang sửa' ||
                count > (room['capacity'] as num? ?? 100)))
          throw StateError('Phòng đang sửa hoặc đã đủ người');
        if (action == 'archiveTenant') {
          found(old, 'Người thuê');
          tx.update(ref('tenants', k), {
            'archived': true,
            'roomId': '',
            'updatedAt': stamp(),
          });
        } else {
          tx.set(ref('tenants', k), {
            'name': text(d['name'], 'họ tên'),
            'phone': text(d['phone'], 'số điện thoại'),
            for (final f in [
              'email',
              'identity',
              'birthday',
              'address',
              'note',
            ])
              f: text(d[f], f, optional: true),
            'roomId': roomId,
            'archived': false,
            'authUid': old?['authUid'] ?? '',
            'createdAt': old?['createdAt'] ?? stamp(),
            'updatedAt': stamp(),
          }, SetOptions(merge: true));
        }
        if (room != null) tx.update(ref('rooms', roomId), {'people': count});
        if (previousRoom != null && oldRoom != roomId)
          tx.update(ref('rooms', oldRoom), {
            'people': FieldValue.increment(-1),
          });
      } else if (action == 'linkTenantAccount') {
        found(await read(tx, 'tenants', k), 'Người thuê');
        final authUid = id(args['authUid']);
        // Spark không thể tra UID người khác qua Auth client. Chủ trọ sao chép
        // UID chính xác từ Authentication > Users, không đưa Admin key vào app.
        final cs = await list('contracts', field: 'tenantId', equals: k);
        tx.update(ref('tenants', k), {
          'authUid': authUid,
          'updatedAt': stamp(),
        });
        for (final c in cs.where(active))
          tx.update(ref('contracts', c['_id']), {
            'recipientUid': authUid,
            'updatedAt': stamp(),
          });
      } else if (action == 'saveService' || action == 'archiveService') {
        final old = await read(tx, 'services', k);
        final rooms = (await list('rooms')).where(
          (r) =>
              r['archived'] != true &&
              (r['serviceIds'] as List? ?? []).contains(k),
        );
        if (action == 'archiveService') {
          found(old, 'Dịch vụ');
          if (rooms.isNotEmpty)
            throw StateError('Bỏ dịch vụ khỏi phòng trước khi xóa');
          tx.update(ref('services', k), {
            'archived': true,
            'updatedAt': stamp(),
          });
        } else {
          final mode = text(d['mode'], 'cách tính');
          if (!['meter', 'room', 'person'].contains(mode))
            throw StateError('Cách tính không hợp lệ');
          if (old != null && old['mode'] != mode && rooms.isNotEmpty)
            throw StateError('Bỏ dịch vụ khỏi phòng trước khi đổi cách tính');
          tx.set(ref('services', k), {
            'name': text(d['name'], 'tên dịch vụ'),
            'mode': mode,
            'price': Billing.number(d['price'], 'Đơn giá'),
            'unit': text(d['unit'], 'đơn vị'),
            'note': text(d['note'], 'ghi chú', optional: true),
            'archived': false,
            'createdAt': old?['createdAt'] ?? stamp(),
            'updatedAt': stamp(),
          }, SetOptions(merge: true));
        }
      } else if (action == 'assignServices') {
        final roomId = id(args['roomId']);
        found(await read(tx, 'rooms', roomId), 'Phòng');
        final ids = (args['serviceIds'] as List).map(id).toSet().toList();
        if (ids.length > 30) throw StateError('Tối đa 30 dịch vụ/phòng');
        for (final sid in ids)
          found(await read(tx, 'services', sid), 'Dịch vụ');
        tx.update(ref('rooms', roomId), {
          'serviceIds': ids,
          'updatedAt': stamp(),
        });
      } else if (action == 'saveMeter') {
        final roomId = id(d['roomId']),
            sid = id(d['serviceId']),
            p = Billing.period(d['period']);
        final room = found(await read(tx, 'rooms', roomId), 'Phòng'),
            service = found(await read(tx, 'services', sid), 'Dịch vụ');
        if (service['mode'] != 'meter' ||
            !(room['serviceIds'] as List? ?? []).contains(sid))
          throw StateError('Chưa áp dụng dịch vụ chỉ số cho phòng');
        if (p.compareTo(now.substring(0, 7)) > 0)
          throw StateError('Chưa nhập chỉ số tháng tương lai');
        final meterId = '${roomId}_${sid}_$p';
        final old = await read(tx, 'meters', meterId),
            prev = await read(
              tx,
              'meters',
              '${roomId}_${sid}_${Billing.shift(p, -1)}',
            ),
            next = await read(
              tx,
              'meters',
              '${roomId}_${sid}_${Billing.shift(p, 1)}',
            );
        final bills = await list('invoices', field: 'roomId', equals: roomId);
        if (bills.any((b) => b['meterPeriod'] == p && b['status'] != 'void'))
          throw StateError('Kỳ này đã phát hành hóa đơn, không sửa chỉ số');
        final previous = Billing.number(
              prev?['current'] ?? d['previous'],
              'Chỉ số cũ',
              integer: false,
            ),
            current = Billing.number(
              d['current'],
              'Chỉ số mới',
              integer: false,
            );
        if (current < previous)
          throw StateError('Chỉ số mới nhỏ hơn chỉ số cũ');
        if (next != null && next['previous'] != current)
          throw StateError('Kỳ sau đã có chỉ số phụ thuộc');
        tx.set(ref('meters', meterId), {
          'roomId': roomId,
          'serviceId': sid,
          'period': p,
          'previous': previous,
          'current': current,
          'usage': num.parse((current - previous).toStringAsFixed(3)),
          'serviceName': service['name'],
          'unit': service['unit'],
          'createdAt': old?['createdAt'] ?? stamp(),
          'updatedAt': stamp(),
        });
        return {'id': meterId};
      } else if (action == 'saveContract') {
        final old = await read(tx, 'contracts', k);
        if (old != null &&
            ['active', 'ended', 'expired', 'cancelled'].contains(old['status']))
          throw StateError(
            'Hợp đồng đã hiệu lực không sửa nội dung; hãy lập hợp đồng mới',
          );
        final roomId = id(d['roomId']), tenantId = id(d['tenantId']);
        final room = found(await read(tx, 'rooms', roomId), 'Phòng'),
            tenant = found(await read(tx, 'tenants', tenantId), 'Người thuê');
        final cs = await list('contracts');
        final number = text(d['number'], 'số hợp đồng'),
            start = Billing.date(d['startDate']),
            end = Billing.date(d['endDate']);
        if (cs.any(
          (c) =>
              c['_id'] != k &&
              '${c['number']}'.toLowerCase() == number.toLowerCase(),
        ))
          throw StateError('Số hợp đồng đã tồn tại');
        if (start.compareTo(end) > 0 || end.compareTo(now) < 0)
          throw StateError('Thời hạn hợp đồng không hợp lệ');
        if (tenant['roomId'] != roomId || room['condition'] == 'Đang sửa')
          throw StateError('Người thuê chưa thuộc phòng hoặc phòng đang sửa');
        if (cs.any(
          (c) =>
              c['_id'] != k &&
              c['roomId'] == roomId &&
              active(c) &&
              '${c['startDate']}'.compareTo(end) <= 0 &&
              '${c['endDate']}'.compareTo(start) >= 0,
        ))
          throw StateError('Hợp đồng trùng thời hạn');
        tx.set(ref('contracts', k), {
          'number': number,
          'roomId': roomId,
          'roomName': room['name'],
          'tenantId': tenantId,
          'tenantName': tenant['name'],
          'recipientUid': tenant['authUid'] ?? '',
          'startDate': start,
          'endDate': end,
          'rent': Billing.number(room['price'], 'Giá thuê', min: 1),
          'deposit': Billing.number(room['deposit'], 'Tiền cọc'),
          'status': start.compareTo(now) > 0 ? 'scheduled' : 'active',
          'note': text(d['note'], 'ghi chú', optional: true),
          'createdAt': old?['createdAt'] ?? stamp(),
          'updatedAt': stamp(),
        }, SetOptions(merge: true));
      } else if (action == 'endContract') {
        final c = found(await read(tx, 'contracts', k), 'Hợp đồng');
        final bs = await list('invoices', field: 'contractId', equals: k);
        if (!active(c) ||
            bs.any((b) => ['unpaid', 'reported'].contains(b['status'])))
          throw StateError('Hợp đồng đã kết thúc hoặc còn hóa đơn chưa trả');
        tx.update(ref('contracts', k), {
          'status': '${c['startDate']}'.compareTo(now) > 0
              ? 'cancelled'
              : 'ended',
          'endedOn': now,
          'updatedAt': stamp(),
        });
      } else if (action == 'saveExtra' || action == 'deleteExtra') {
        final old = await read(tx, 'extras', k);
        final roomId = id(d['roomId'] ?? old?['roomId']),
            p = Billing.period(d['period'] ?? old?['period']);
        found(await read(tx, 'rooms', roomId), 'Phòng');
        final bs = await list('invoices', field: 'roomId', equals: roomId);
        if (bs.any((b) => b['period'] == p && b['status'] != 'void'))
          throw StateError('Đã có hóa đơn kỳ này, không sửa phụ phí');
        if (action == 'deleteExtra') {
          tx.delete(ref('extras', k));
        } else {
          tx.set(ref('extras', k), {
            'roomId': roomId,
            'period': p,
            'reason': text(d['reason'], 'lý do phụ phí'),
            'amount': Billing.number(d['amount'], 'Phụ phí', min: 1),
            'updatedAt': stamp(),
          });
        }
      } else if (action == 'saveMaintenance') {
        final old = await read(tx, 'maintenance', k), roomId = id(d['roomId']);
        found(await read(tx, 'rooms', roomId), 'Phòng');
        final status = d['status'] ?? 'new';
        if (!['new', 'working', 'done', 'cancelled'].contains(status))
          throw StateError('Trạng thái không hợp lệ');
        tx.set(ref('maintenance', k), {
          'roomId': roomId,
          'title': text(d['title'], 'vấn đề'),
          'description': text(d['description'], 'mô tả'),
          'cost': Billing.number(d['cost'] ?? 0, 'Chi phí'),
          'status': status,
          'imageUrls': old?['imageUrls'] ?? [],
          'createdAt': old?['createdAt'] ?? stamp(),
          'updatedAt': stamp(),
        }, SetOptions(merge: true));
      } else if ([
        'confirmPayment',
        'voidInvoice',
        'resendInvoice',
      ].contains(action)) {
        final b = found(await read(tx, 'invoices', k), 'Hóa đơn');
        if (action == 'resendInvoice') {
          final t = found(
            await read(tx, 'tenants', id(b['tenantId'])),
            'Người thuê',
          );
          final recipient = '${t['authUid'] ?? ''}';
          if (recipient.isEmpty || b['status'] == 'void')
            throw StateError(
              'Chưa liên kết UID người thuê hoặc hóa đơn đã hủy',
            );
          final count = (b['resendCount'] as num? ?? 0) + 1;
          tx.update(ref('invoices', k), {
            'recipientUid': recipient,
            'delivered': true,
            'resendCount': count,
            'updatedAt': stamp(),
          });
          notice(
            tx,
            'resent_${k}_$count',
            'Hóa đơn tiền phòng',
            '${b['roomName']} · ${b['period']}',
            recipient: recipient,
            invoiceId: k,
          );
        } else {
          if (['paid', 'void'].contains(b['status']))
            throw StateError('Hóa đơn đã thanh toán hoặc đã hủy');
          if (action == 'voidInvoice') {
            tx.update(ref('invoices', k), {
              'status': 'void',
              'voidReason': text(args['reason'], 'lý do hủy'),
              'updatedAt': stamp(),
            });
          } else {
            final method = text(args['method'], 'hình thức thanh toán');
            if (!['cash', 'bank'].contains(method))
              throw StateError('Hình thức thanh toán không hợp lệ');
            tx.update(ref('invoices', k), {
              'status': 'paid',
              'method': method,
              'paidAt': stamp(),
              'paidDate': now,
              'confirmedBy': uid,
              'updatedAt': stamp(),
            });
          }
          final title = action == 'voidInvoice'
              ? 'Hóa đơn đã hủy'
              : 'Đã xác nhận thanh toán';
          notice(
            tx,
            '${action}_manager_$k',
            title,
            '${b['roomName']} · ${b['period']}',
            invoiceId: k,
          );
          if ('${b['recipientUid'] ?? ''}'.isNotEmpty)
            notice(
              tx,
              '${action}_tenant_$k',
              title,
              '${b['roomName']} · ${b['period']}',
              recipient: b['recipientUid'],
              invoiceId: k,
            );
        }
      } else if (action == 'saveSettings') {
        tx.set(ref('settings', 'landlord'), {
          'name': text(d['name'], 'tên chủ trọ'),
          'phone': text(d['phone'], 'số điện thoại'),
          for (final f in ['address', 'bankName', 'bankAccount', 'bankHolder'])
            f: text(d[f], f, optional: true),
          'autoBilling': d['autoBilling'] == true,
          'execution': 'app_open_only',
          'updatedAt': stamp(),
        }, SetOptions(merge: true));
      } else {
        throw StateError('Thao tác không được hỗ trợ trong bản Spark');
      }
      return {'id': k};
    });
  }

  Future<Data> invoice(String roomId, String p, bool commit) => locked((
    tx,
  ) async {
    final now = Billing.today();
    if (p != now.substring(0, 7))
      throw StateError('Chỉ phát hành hóa đơn tháng hiện tại');
    final room = found(await read(tx, 'rooms', roomId), 'Phòng');
    final cs = (await list('contracts', field: 'roomId', equals: roomId))
        .where(
          (c) =>
              active(c) &&
              '${c['startDate']}'.compareTo(now) <= 0 &&
              '${c['endDate']}'.compareTo(now) >= 0,
        )
        .toList();
    if (cs.length != 1) throw StateError('Cần đúng một hợp đồng còn hiệu lực');
    final c = cs.single, billId = '${cs.single['_id']}_$p';
    if (await read(tx, 'invoices', billId) != null) {
      if (commit) return {'id': billId, 'existing': true};
      throw StateError('Kỳ này đã có hóa đơn, kể cả hóa đơn đã hủy');
    }
    final services = <Data>[], meters = <String, Data?>{};
    for (final sid in (room['serviceIds'] as List? ?? []).toSet()) {
      final s = found(await read(tx, 'services', id(sid)), 'Dịch vụ');
      services.add(s);
      if (s['mode'] == 'meter')
        meters[sid] = await read(
          tx,
          'meters',
          '${roomId}_${sid}_${Billing.shift(p, -1)}',
        );
    }
    final extras = await list('extras', field: 'roomId', equals: roomId),
        tenants = await list('tenants', field: 'roomId', equals: roomId);
    final settings = await read(tx, 'settings', 'landlord') ?? {};
    final tenant = found(
      await read(tx, 'tenants', id(c['tenantId'])),
      'Người thuê',
    );
    if (tenant['roomId'] != roomId)
      throw StateError('Người đứng hợp đồng không còn thuộc phòng');
    final bill = Billing.build(
      contract: {
        ...c,
        'recipientUid': tenant['authUid'] ?? c['recipientUid'] ?? '',
        'bank': {
          'name': settings['bankName'] ?? '',
          'account': settings['bankAccount'] ?? '',
          'holder': settings['bankHolder'] ?? '',
        },
      },
      room: {
        ...room,
        'people': tenants.where((t) => t['archived'] != true).length,
      },
      services: services,
      meters: meters,
      extras: extras.where((x) => x['period'] == p).toList(),
      p: p,
      day: now,
    );
    bill['code'] = 'HD-${p.replaceAll('-', '')}-$billId';
    if (commit) {
      tx.set(ref('invoices', billId), {
        ...bill,
        'createdAt': stamp(),
        'updatedAt': stamp(),
      });
      notice(
        tx,
        'issued_manager_$billId',
        'Đã phát hành hóa đơn',
        '${room['name']} · $p',
        invoiceId: billId,
      );
      if (bill['delivered'] == true)
        notice(
          tx,
          'issued_tenant_$billId',
          'Hóa đơn tiền phòng mới',
          '${room['name']} · $p: ${bill['total']}đ',
          recipient: bill['recipientUid'],
          invoiceId: billId,
        );
    }
    return {'id': billId, ...bill, 'preview': !commit};
  });

  Future<void> reportPayment(String key, String note) =>
      db.runTransaction((tx) async {
        final b = found(await read(tx, 'invoices', id(key)), 'Hóa đơn');
        if (b['recipientUid'] != uid || b['status'] != 'unpaid')
          throw StateError('Không phải hóa đơn của bạn hoặc đã báo thanh toán');
        tx.update(ref('invoices', key), {
          'status': 'reported',
          'reportedAt': stamp(),
          'paymentNote': text(note, 'ghi chú', optional: true),
          'updatedAt': stamp(),
        });
        notice(
          tx,
          'reported_$key',
          'Người thuê báo đã chuyển tiền',
          '${b['roomName']} · Kiểm tra giao dịch trước khi xác nhận.',
          invoiceId: key,
        );
      });

  Future<Data> runBilling() async {
    final day = Billing.today();
    final p = day.substring(0, 7);
    final settings = (await ref('settings', 'landlord').get()).data() ?? {};
    int created = 0, existing = 0, blocked = 0, late = 0;
    final errors = <String>[];
    for (final snapshot in await list('contracts')) {
      final c = await locked((tx) async {
        final current = found(
          await read(tx, 'contracts', snapshot['_id']),
          'Hợp đồng',
        );
        if (active(current)) {
          final next = '${current['endDate']}'.compareTo(day) < 0
              ? 'expired'
              : '${current['startDate']}'.compareTo(day) <= 0
              ? 'active'
              : 'scheduled';
          if (next != current['status']) {
            tx.update(ref('contracts', snapshot['_id']), {
              'status': next,
              'updatedAt': stamp(),
            });
            current['status'] = next;
          }
        }
        return current;
      });
      if (settings['autoBilling'] != true || c['status'] != 'active') continue;
      try {
        final room = (await ref('rooms', id(c['roomId'])).get()).data();
        if (room == null || room['archived'] == true) continue;
        final bday =
            int.tryParse('${room['billingDay']}'.split(' ').first) ?? 1;
        if (day.compareTo(Billing.billingDate(p, bday)) < 0) continue;
        final result = await invoice(c['roomId'], p, true);
        result['existing'] == true ? existing++ : created++;
      } catch (e) {
        blocked++;
        errors.add('${c['roomName'] ?? c['roomId']}: $e');
      }
    }
    for (final b in await list('invoices')) {
      if (!['unpaid', 'reported'].contains(b['status'])) continue;
      try {
        Billing.date(b['dueDate']);
      } catch (_) {
        blocked++;
        errors.add(
          'Hóa đơn ${b['_id']}: cần sửa ngày đến hạn thành YYYY-MM-DD',
        );
        continue;
      }
      final added = await locked((tx) async {
        final current = await read(tx, 'invoices', b['_id']);
        if (current == null ||
            !['unpaid', 'reported'].contains(current['status']))
          return false;
        final overdue = Billing.late(current, day),
            reported = current['status'] == 'reported';
        final overdueId = 'overdue_${b['_id']}',
            reportedId = 'reported_${b['_id']}';
        final oldLate = await read(tx, 'notifications', overdueId),
            oldReport = await read(tx, 'notifications', reportedId);
        if (reported && oldReport == null)
          notice(
            tx,
            reportedId,
            'Người thuê báo đã chuyển tiền',
            '${current['roomName']} · Kiểm tra giao dịch trước khi xác nhận.',
            invoiceId: b['_id'],
          );
        if (overdue && oldLate == null) {
          notice(
            tx,
            overdueId,
            'Hóa đơn quá hạn hơn 5 ngày',
            '${current['roomName']} · ${current['period']}: ${current['total']}đ',
            invoiceId: b['_id'],
          );
          return true;
        }
        return false;
      });
      if (added) late++;
    }
    if (errors.isNotEmpty)
      await locked((tx) async {
        notice(
          tx,
          'billing_blocked_$p',
          'Có phòng chưa xuất được hóa đơn',
          errors
              .join('\n')
              .substring(0, errors.join('\n').length.clamp(0, 3500)),
        );
      });
    return {
      'created': created,
      'existing': existing,
      'blocked': blocked,
      'late': late,
      'day': day,
      'autoBilling': settings['autoBilling'] == true,
    };
  }
}
