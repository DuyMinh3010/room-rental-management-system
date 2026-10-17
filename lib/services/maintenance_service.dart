import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MaintenanceService {
  final _col = FirebaseFirestore.instance.collection('maintenance_requests');

  /// Tạo yêu cầu bảo trì mới (trạng thái ban đầu: 'Mới')
  Future<String> addMaintenanceRequest({
    required String title,
    required String description,
    required String room,
    required String tenantName,
    String category = 'Thiết bị',
    String priority = 'medium',
    List<String> imageUrls = const [],
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    final ref = await _col.add({
      'room': room,
      'tenantId': user?.uid ?? '',
      'tenantName': tenantName,
      'category': category,
      'title': title,
      'description': description,
      'priority': priority,
      'status': 'Mới',
      'imageUrls': imageUrls,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Danh sách yêu cầu, mới nhất trước (maintenance_page.dart dùng hàm này)
  Stream<QuerySnapshot<Map<String, dynamic>>> getMaintenanceRequests() {
    return _col.orderBy('createdAt', descending: true).snapshots();
  }

  /// Cập nhật trạng thái: 'Mới' → 'Đang xử lý' → 'Hoàn thành'
  Future<void> updateMaintenanceStatus({
    required String documentId,
    required String status,
  }) {
    return _col.doc(documentId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}