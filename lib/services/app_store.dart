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
    Query<Map<String, dynamic>> query = db.collection(collection);
    final tenantInbox =
        field == 'recipientUid' &&
        (collection == 'invoices' || collection == 'notifications');
    if (!collection.startsWith('users/') && !tenantInbox) {
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
  Future<Map<String, dynamic>> command(
    String action, {
    String? id,
    Map<String, dynamic>? data,
    Map<String, dynamic> args = const {},
  }) async {
    if (action == 'migrateOwnerData') {
      final result = await FirebaseFunctions.instanceFor(
        region: 'asia-southeast1',
      ).httpsCallable('manage').call({'action': action});
      return Map<String, dynamic>.from(result.data as Map);
    }
    return commands.command(action, key: id, d: data ?? {}, args: args);
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
  if (e is FirebaseException)
    return e.code == 'permission-denied'
        ? 'Chưa có quyền truy cập. Kiểm tra managers/UID, rules và tài khoản.'
        : '${e.code}: ${e.message}';
  return e.toString().replaceFirst('Bad state: ', '');
}
