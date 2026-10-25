
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MeterReadingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String collectionName = 'meters';

  String _getDocumentId({
    required String room,
    required String month,
  }) {
    final safeRoom = room.replaceAll('/', '_');
    final safeMonth = month.replaceAll('/', '_');
    return '${safeRoom}_$safeMonth';
  }

  Future<Map<String, dynamic>?> getReading({
    required String room,
    required String month,
  }) async {
    if (FirebaseAuth.instance.currentUser == null) {
      throw StateError('Bạn cần đăng nhập trước.');
    }

    final documentId = _getDocumentId(
      room: room,
      month: month,
    );

    final snapshot = await _firestore
        .collection(collectionName)
        .doc(documentId)
        .get();

    if (!snapshot.exists) {
      return null;
    }

    return snapshot.data();
  }

  Future<void> saveReading({
    required String room,
    required String month,
    required int electricOld,
    required int electricNew,
    required int waterOld,
    required int waterNew,
    int electricPrice = 3500,
    int waterPrice = 20000,
  }) async {
    if (FirebaseAuth.instance.currentUser == null) {
      throw StateError('Bạn cần đăng nhập trước.');
    }

    if (electricOld < 0 ||
        electricNew < electricOld ||
        waterOld < 0 ||
        waterNew < waterOld) {
      throw ArgumentError(
        'Chỉ số mới phải lớn hơn hoặc bằng chỉ số cũ.',
      );
    }

    final electricUsage = electricNew - electricOld;
    final waterUsage = waterNew - waterOld;

    final documentId = _getDocumentId(
      room: room,
      month: month,
    );

    await _firestore
        .collection(collectionName)
        .doc(documentId)
        .set({
      'room': room,
      'month': month,
      'previous': electricOld,
      'current': electricNew,
      'electricOld': electricOld,
      'electricNew': electricNew,
      'electricUsage': electricUsage,
      'electricPrice': electricPrice,
      'electricTotal': electricUsage * electricPrice,
      'waterOld': waterOld,
      'waterNew': waterNew,
      'waterUsage': waterUsage,
      'waterPrice': waterPrice,
      'waterTotal': waterUsage * waterPrice,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
