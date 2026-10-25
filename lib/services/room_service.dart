
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final roomList = <Map<String, String>>[];

class RoomService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _rooms {
    if (FirebaseAuth.instance.currentUser == null) {
      throw StateError('Bạn cần đăng nhập trước.');
    }
    return _db.collection('rooms');
  }

  Stream<List<Map<String, String>>> watchRooms() =>
      _rooms.snapshots().map((snapshot) {
        final rooms = snapshot.docs
            .map((doc) => _toUi(doc.id, doc.data()))
            .toList();

        rooms.sort((a, b) => a['name']!.compareTo(b['name']!));

        roomList
          ..clear()
          ..addAll(rooms);

        return rooms;
      });

  Stream<Map<String, String>?> watchRoom(String id) =>
      _rooms.doc(id).snapshots().map(
            (doc) => doc.exists ? _toUi(doc.id, doc.data()!) : null,
          );

  Future<void> save(Map<String, String> room, {String? id}) async {
    final data = <String, dynamic>{
      'name': room['name']!.trim(),
      'status': room['status'],
      'price': _integer(room['price']),
      'deposit': _integer(room['deposit']),
      'area': double.parse(
        room['area']!.replaceAll('m²', '').trim(),
      ),
      'people': _integer(room['people']),
      'billingDay': room['billingDay']!,
      'zone': room['zone'] ?? '',
      'description': room['description'] ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (id == null) {
      data.addAll({
        'services': <String>[],
        'imageUrls': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _rooms.add(data);
    } else {
      await _rooms.doc(id).update(data);
    }
  }

  static int _integer(String? value) =>
      int.parse((value ?? '0').replaceAll(RegExp(r'[^0-9]'), ''));

  static String _money(num value) => '${value.toInt()}'.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );

  static String _textValue(dynamic value, String fallback) {
    if (value == null || value == '') return fallback;
    if (value is String) return value;
    if (value is num) return value.toString();
    return fallback;
  }

  static List<String> _stringList(dynamic value) {
    if (value == null || value is! List) return [];

    final result = <String>[];

    for (final item in value) {
      if (item is String) {
        result.add(item);
      } else if (item is Map) {
        final name = item['name'] ??
            item['serviceName'] ??
            item['service'] ??
            item['title'];

        if (name is String && name.trim().isNotEmpty) {
          result.add(name.trim());
        } else {
          result.add(jsonEncode(item));
        }
      } else if (item != null) {
        result.add(item.toString());
      }
    }

    return result;
  }

  static Map<String, String> _toUi(
    String id,
    Map<String, dynamic> data,
  ) {
    const missing = 'Chưa cập nhật';

    String text(String field) {
      final value = data[field];

      if (value == null || value == '') return missing;
      if (value is String) return value;
      if (value is num) return value.toString();

      throw FormatException(
        'Phòng $id: trường $field không đúng kiểu dữ liệu.',
      );
    }

    num? number(String field) {
      final value = data[field];

      if (value == null || value == '') return null;

      final result = value is num
          ? value
          : value is String
              ? num.tryParse(value.trim().replaceAll(',', ''))
              : null;

      if (result == null || !result.isFinite) {
        throw FormatException(
          'Phòng $id: trường $field phải là số.',
        );
      }

      return result;
    }

    String moneyField(String field, String suffix) {
      final value = number(field);
      return value == null ? missing : '${_money(value)}$suffix';
    }

    final area = number('area');
    final people = number('people');
    final day = data['billingDay'];

    String billingDay;

    if (day == null || day == '') {
      billingDay = missing;
    } else if (day is String) {
      billingDay = day;
    } else if (day is num &&
        day == day.toInt() &&
        day >= 1 &&
        day <= 31) {
      billingDay =
          '${day.toInt().toString().padLeft(2, '0')} hàng tháng';
    } else {
      billingDay = missing;
    }

    return {
      'id': id,
      'name': text('name'),
      'status': text('status'),
      'price': moneyField('price', 'đ/tháng'),
      'deposit': moneyField('deposit', 'đ'),
      'area': area == null ? missing : '${area}m²',
      'people': people == null ? missing : '${people.toInt()} người',
      'billingDay': billingDay,
      'zone': text('zone'),
      'description': text('description'),
      'services': jsonEncode(_stringList(data['services'])),
      'imageUrls': jsonEncode(_stringList(data['imageUrls'])),
    };
  }
}

String roomError(Object error) {
  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return 'Không có quyền đọc/ghi phòng. Kiểm tra Firestore Rules.';
    }

    if (error.code == 'unavailable') {
      return 'Không kết nối được Firebase. Kiểm tra mạng rồi thử lại.';
    }

    return 'Firebase báo lỗi: ${error.code}';
  }

  if (error is FormatException) return error.message;

  return 'Lỗi dữ liệu phòng: $error';
}
