import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tenant.dart';
import '../data/mock_data.dart';

class TenantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String collectionName = 'tenants';

  CollectionReference<Map<String, dynamic>> get _tenantsCollection =>
      _firestore.collection(collectionName);

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Lắng nghe danh sách người thuê theo phòng theo thời gian thực (Real-time Stream)
  /// Lọc theo roomId (id_room) và ownerId (owner_room) để chống trùng phòng giữa các chủ trọ
  Stream<List<TenantModel>> watchTenantsByRoom({
    required String roomId,
    String? roomName,
  }) {
    return _tenantsCollection.snapshots().map((snapshot) {
      final uid = currentUserId;

      final list = snapshot.docs.map((doc) {
        return TenantModel.fromFirestore(doc);
      }).where((t) {
        // Lọc theo chủ sở hữu (ownerId / owner_room)
        if (uid != null && t.ownerId.isNotEmpty && t.ownerId != uid) {
          return false;
        }

        // Khớp theo ID phòng duy nhất (id_room / roomId)
        if (t.roomId.isNotEmpty && t.roomId == roomId) {
          return true;
        }

        // Tương thích ngược: nếu tenant chưa có roomId chuẩn nhưng có roomName
        if (roomName != null && roomName.isNotEmpty && t.roomName.isNotEmpty) {
          if (t.roomName == roomName ||
              t.roomName.replaceAll('P.', '').trim() ==
                  roomName.replaceAll('P.', '').trim()) {
            return true;
          }
        }

        return false;
      }).toList();

      // Nếu Firestore chưa có người thuê nào của phòng này, cung cấp dữ liệu khởi tạo từ mock_data
      if (list.isEmpty && roomName != null) {
        final mockMatches = tenantList.where((m) {
          final mRoom = (m['room'] ?? '').replaceAll('P.', '').trim();
          final target = roomName.replaceAll('P.', '').trim();
          return mRoom.contains(target);
        }).toList();

        for (final m in mockMatches) {
          list.add(
            TenantModel(
              id: 'mock_${m['name']}',
              name: m['name'] ?? '',
              roomId: roomId,
              roomName: roomName,
              ownerId: uid ?? '',
              phone: m['phone'] ?? '',
              email: m['email'] ?? '',
              identity: m['identity'] ?? '',
              gender: m['gender'] ?? 'Nam',
              birthday: m['birthday'] ?? '',
              address: m['address'] ?? '',
              job: m['job'] ?? '',
              memberRole: m['memberRole'] ?? 'Trưởng phòng',
              status: m['status'] ?? 'Đang thuê',
              startDate: m['start'] ?? '01/06/2026',
              endDate: m['end'] ?? '31/05/2027',
              deposit: int.tryParse(m['deposit'] ?? '0') ?? 0,
            ),
          );
        }
      }

      return list;
    });
  }

  /// Thêm người thuê mới vào phòng (lưu vào Firestore với roomId và ownerId chuẩn)
  Future<String> addTenant(TenantModel tenant) async {
    final uid = currentUserId ?? '';
    final data = tenant.toFirestore();

    if (tenant.ownerId.isEmpty && uid.isNotEmpty) {
      data['ownerId'] = uid;
      data['owner_room'] = uid;
    }
    data['createdAt'] = FieldValue.serverTimestamp();

    final docRef = await _tenantsCollection.add(data);
    return docRef.id;
  }

  /// Cập nhật thông tin người thuê
  Future<void> updateTenant(TenantModel tenant) async {
    final data = tenant.toFirestore();
    await _tenantsCollection.doc(tenant.id).set(data, SetOptions(merge: true));
  }

  /// Xóa người thuê khỏi phòng
  Future<void> deleteTenant(String tenantId) async {
    await _tenantsCollection.doc(tenantId).delete();
  }
}
