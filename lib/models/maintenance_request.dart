import 'package:cloud_firestore/cloud_firestore.dart';

class MaintenanceRequest {
  final String id;
  final String room;
  final String tenantId;
  final String tenantName;
  final String category;
  final String title;
  final String description;
  final String priority;
  final String status;
  final List<String> imageUrls;
  final DateTime? createdAt;

  MaintenanceRequest({
    required this.id,
    required this.room,
    required this.tenantId,
    required this.tenantName,
    required this.category,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.imageUrls,
    this.createdAt,
  });

  factory MaintenanceRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return MaintenanceRequest(
      id: doc.id,
      room: d['room'] ?? '',
      tenantId: d['tenantId'] ?? '',
      tenantName: d['tenantName'] ?? '',
      category: d['category'] ?? '',
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      priority: d['priority'] ?? 'medium',
      status: d['status'] ?? 'pending',
      imageUrls: List<String>.from(d['imageUrls'] ?? []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}