import 'package:cloud_firestore/cloud_firestore.dart';

class TenantModel {
  final String id;
  final String name;
  final String roomId; // id_room duy nhất trong Firestore
  final String roomName; // Tên phòng: P.101
  final String ownerId; // owner_room định danh chủ sở hữu
  final String phone;
  final String email;
  final String identity; // Số CCCD/CMND
  final String gender;
  final String birthday;
  final String address;
  final String job;
  final String memberRole; // 'Trưởng phòng' hoặc 'Thành viên'
  final String status; // 'Đang thuê' hoặc 'Đã chuyển đi'
  final String startDate;
  final String endDate;
  final int deposit;
  final DateTime? createdAt;

  TenantModel({
    required this.id,
    required this.name,
    required this.roomId,
    required this.roomName,
    required this.ownerId,
    required this.phone,
    this.email = '',
    this.identity = '',
    this.gender = 'Nam',
    this.birthday = '',
    this.address = '',
    this.job = '',
    this.memberRole = 'Thành viên',
    this.status = 'Đang thuê',
    this.startDate = '',
    this.endDate = '',
    this.deposit = 0,
    this.createdAt,
  });

  String get initial {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return 'N';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  factory TenantModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TenantModel.fromMap(doc.id, data);
  }

  factory TenantModel.fromMap(String docId, Map<String, dynamic> data) {
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      if (val is String) {
        return int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      }
      return 0;
    }

    return TenantModel(
      id: docId,
      name: data['name']?.toString() ?? 'Chưa đặt tên',
      roomId: data['roomId']?.toString() ??
          data['id_room']?.toString() ??
          '',
      roomName: data['roomName']?.toString() ??
          data['room']?.toString() ??
          '',
      ownerId: data['ownerId']?.toString() ??
          data['owner_room']?.toString() ??
          '',
      phone: data['phone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      identity: data['identity']?.toString() ?? '',
      gender: data['gender']?.toString() ?? 'Nam',
      birthday: data['birthday']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      job: data['job']?.toString() ?? '',
      memberRole: data['memberRole']?.toString() ?? 'Thành viên',
      status: data['status']?.toString() ?? 'Đang thuê',
      startDate: data['startDate']?.toString() ??
          data['start']?.toString() ??
          '',
      endDate: data['endDate']?.toString() ??
          data['end']?.toString() ??
          '',
      deposit: parseInt(data['deposit']),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name.trim(),
      'roomId': roomId, // id_room duy nhất chống trùng phòng
      'id_room': roomId,
      'roomName': roomName,
      'ownerId': ownerId, // owner_room định danh chủ sở hữu
      'owner_room': ownerId,
      'phone': phone.trim(),
      'email': email.trim(),
      'identity': identity.trim(),
      'gender': gender,
      'birthday': birthday,
      'address': address,
      'job': job,
      'memberRole': memberRole,
      'status': status,
      'startDate': startDate,
      'endDate': endDate,
      'deposit': deposit,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Chuyển sang Map<String, String> để tương thích trang TenantDetailPage hiện có
  Map<String, String> toUiMap() {
    return {
      'id': id,
      'initial': initial,
      'name': name,
      'room': roomName,
      'roomId': roomId,
      'phone': phone,
      'email': email,
      'identity': identity,
      'gender': gender,
      'birthday': birthday,
      'address': address,
      'job': job,
      'residence': 'Chưa đăng ký',
      'note': '',
      'contract': '$startDate – $endDate',
      'start': startDate,
      'end': endDate,
      'rent': '',
      'deposit': '$deposit',
      'status': status,
      'memberRole': memberRole,
    };
  }
}
