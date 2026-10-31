import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/invoice.dart';

class InvoiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tên collection trên Firestore (hỗ trợ cả "Invoices" trong ảnh Firebase)
  static const String collectionName = 'Invoices';

  CollectionReference<Map<String, dynamic>> get _invoicesCollection =>
      _firestore.collection(collectionName);

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Lắng nghe danh sách hóa đơn theo thời gian thực (Real-time Stream)
  /// Tự động lọc theo ownerId nếu người dùng đã đăng nhập, hoặc hỗ trợ fallback dữ liệu cũ
  Stream<List<InvoiceModel>> watchInvoices({String? roomId}) {
    return _invoicesCollection.snapshots().map((snapshot) {
      final uid = currentUserId;

      final list = snapshot.docs.map((doc) {
        return InvoiceModel.fromFirestore(doc);
      }).where((inv) {
        // Nếu truyền roomId thì lọc đúng phòng
        if (roomId != null && roomId.isNotEmpty) {
          if (inv.roomId != roomId && inv.roomName != roomId) {
            return false;
          }
        }

        // Lọc theo ownerId của chủ trọ đang đăng nhập (hoặc nếu document cũ chưa có ownerId thì vẫn hiện để không bị mất dữ liệu)
        if (uid != null && inv.ownerId.isNotEmpty && inv.ownerId != uid) {
          return false;
        }

        return true;
      }).toList();

      // Sắp xếp mới nhất lên đầu
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return list;
    });
  }

  /// Lắng nghe chi tiết 1 hóa đơn cụ thể theo ID
  Stream<InvoiceModel?> watchInvoice(String id) {
    return _invoicesCollection.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return InvoiceModel.fromFirestore(doc);
    });
  }

  /// Lấy thông tin 1 hóa đơn 1 lần
  Future<InvoiceModel?> getInvoice(String id) async {
    final doc = await _invoicesCollection.doc(id).get();
    if (!doc.exists) return null;
    return InvoiceModel.fromFirestore(doc);
  }

  /// Lưu hóa đơn mới hoặc cập nhật hóa đơn hiện có
  Future<String> saveInvoice(InvoiceModel invoice) async {
    final uid = currentUserId ?? '';
    final data = invoice.toFirestore();

    // Đảm bảo luôn gán ownerId để chống trùng phòng giữa các chủ
    if (invoice.ownerId.isEmpty && uid.isNotEmpty) {
      data['ownerId'] = uid;
      data['owner_room'] = uid;
    }

    if (invoice.id.isEmpty || invoice.id.startsWith('temp_')) {
      data['createdAt'] = FieldValue.serverTimestamp();
      final docRef = await _invoicesCollection.add(data);
      return docRef.id;
    } else {
      await _invoicesCollection.doc(invoice.id).set(data, SetOptions(merge: true));
      return invoice.id;
    }
  }

  /// Cập nhật trạng thái xác nhận đã thanh toán
  Future<void> markAsPaid(String invoiceId, {String? paymentMethod}) async {
    final updates = <String, dynamic>{
      'status': 'Đã thanh toán',
      'paidAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      updates['paymentMethod'] = paymentMethod;
    }
    await _invoicesCollection.doc(invoiceId).update(updates);
  }

  /// Xóa hóa đơn
  Future<void> deleteInvoice(String invoiceId) async {
    await _invoicesCollection.doc(invoiceId).delete();
  }
}
