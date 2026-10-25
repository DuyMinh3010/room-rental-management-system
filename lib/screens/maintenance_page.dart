
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/maintenance_service.dart';
import 'maint_create_page.dart';
import 'room_page.dart';

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  int _filter = 0;

  final MaintenanceService _maintenanceService = MaintenanceService();

  Color _statusColor(String status) {
    switch (status) {
      case 'Đang xử lý':
        return const Color(0xFFF26B13);
      case 'Hoàn thành':
        return const Color(0xFF00A344);
      default:
        return const Color(0xFF2463F5);
    }
  }

  Future<void> _create() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const MaintCreatePage()),
    );

     if (!mounted || saved != true) return;

    setState(() => _filter = 0);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã tạo yêu cầu bảo trì')),
    );
  }

  Future<void> _detail(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final status = (data['status'] ?? 'Mới').toString();

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (data['title'] ?? '').toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Phòng: ${(data['room'] ?? '').toString()}',
                style: const TextStyle(color: muted),
              ),
              const SizedBox(height: 6),
              Text(
                'Người thuê: ${(data['tenantName'] ?? 'Chưa xác định').toString()}',
                style: const TextStyle(color: muted),
              ),
              const SizedBox(height: 12),
              Text(
                (data['description'] ?? '').toString(),
                style: const TextStyle(color: ink),
              ),
              const SizedBox(height: 14),
              Text(
                'Trạng thái: $status',
                style: TextStyle(color: _statusColor(status)),
              ),
              const SizedBox(height: 16),
              if (status == 'Mới')
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, 'Đang xử lý'),
                    style: FilledButton.styleFrom(backgroundColor: blue),
                    child: const Text('Tiếp nhận yêu cầu'),
                  ),
                ),
              if (status == 'Đang xử lý')
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, 'Hoàn thành'),
                    style: FilledButton.styleFrom(backgroundColor: blue),
                    child: const Text('Hoàn thành'),
                  ),
                ),    
                const SizedBox(height: 10),
SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: () => Navigator.pop(ctx, 'Xóa'),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
    ),
    child: const Text('Xóa yêu cầu'),
  ),
),       
            ],
          ),
        ),
      ),
    );

    
    if (!mounted || action == null) return;

try {
  if (action == 'Xóa') {
    await _maintenanceService.deleteMaintenanceRequest(
      documentId: doc.id,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã xóa yêu cầu bảo trì'),
      ),
    );

    return;
  }

  await _maintenanceService.updateMaintenanceStatus(
    documentId: doc.id,
    status: action,
  );

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Đã cập nhật: $action'),
    ),
  );
} catch (e) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Thao tác thất bại: $e'),
    ),
  );
}
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 26, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bảo trì',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: ink,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Theo dõi yêu cầu sửa chữa',
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _maintenanceService.getMaintenanceRequests(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Không thể tải danh sách bảo trì'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  final freshCount = docs
                      .where(
                        (doc) => (doc.data()['status'] ?? 'Mới') == 'Mới',
                      )
                      .length;

                  final activeCount = docs
                      .where(
                        (doc) =>
                            (doc.data()['status'] ?? 'Mới') == 'Đang xử lý',
                      )
                      .length;

                  final shown = docs.where((doc) {
                    final status =
                        (doc.data()['status'] ?? 'Mới').toString();

                    if (_filter == 1) return status == 'Mới';
                    if (_filter == 2) return status == 'Đang xử lý';

                    return true;
                  }).toList();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _filterItem('Tất cả', docs.length, 0),
                            _filterItem('Mới', freshCount, 1),
                            _filterItem('Đang xử lý', activeCount, 2),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (shown.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: Center(
                            child: Text(
                              'Chưa có yêu cầu bảo trì',
                              style: TextStyle(
                                color: muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ...shown.map(_card),
                    ],
                  );
                },
              ),
            ),
            const AppBottomBar(selected: 5),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 76, right: 12),
        child: SizedBox(
          width: 58,
          height: 58,
          child: FloatingActionButton(
            onPressed: _create,
            backgroundColor: blue,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _filterItem(String label, int count, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => setState(() => _filter = index),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: _filter == index ? blue : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '$label $count',
            style: TextStyle(
              fontSize: 10,
              color: _filter == index ? Colors.white : muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final status = (data['status'] ?? 'Mới').toString();
    final color = _statusColor(status);
    final updatedAt = data['updatedAt'];

    String updatedText = 'Chưa cập nhật';

    if (updatedAt is Timestamp) {
      final date = updatedAt.toDate();
      updatedText =
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _detail(doc),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (data['title'] ?? '').toString(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ink,
                ),
              ),
              const SizedBox(height: 11),
              Text(
                'Phòng ${(data['room'] ?? '').toString()} · '
                '${(data['tenantName'] ?? 'Chưa xác định').toString()}',
                style: const TextStyle(fontSize: 10, color: muted),
              ),
              const SizedBox(height: 13),
              Text(
                'Cập nhật: $updatedText',
                style: const TextStyle(fontSize: 10, color: muted),
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(fontSize: 10, color: color),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right,
                    color: muted,
                    size: 22,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
