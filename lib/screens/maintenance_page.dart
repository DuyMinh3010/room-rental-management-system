import 'dart:async';

import 'package:flutter/material.dart';

import 'maint_create_page.dart';
import 'room_page.dart';

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  int _filter = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _create() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const MaintCreatePage()),
    );
    if (!mounted || saved != true) return;
    setState(() => _filter = 0);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã tạo yêu cầu bảo trì')));
  }

  Color _color(MaintStatus status) => switch (status) {
    MaintStatus.fresh => const Color(0xFF2463F5),
    MaintStatus.active => const Color(0xFFF26B13),
    MaintStatus.done => const Color(0xFF00A344),
  };

  Future<void> _detail(MaintReq req) async {
    final status = await showModalBottomSheet<MaintStatus>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                req.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(req.location, style: const TextStyle(color: muted)),
              const SizedBox(height: 8),
              Text(
                '${req.type} · ${req.priority.label}',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Text(req.desc, style: const TextStyle(color: ink)),
              if (req.photos.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: req.photos
                      .map(
                        (p) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            p,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                            errorBuilder: (_, error, stack) => const SizedBox(
                              width: 96,
                              height: 96,
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Trạng thái: ${req.status.label}',
                style: TextStyle(color: _color(req.status), fontSize: 12),
              ),
              if (req.status != MaintStatus.done) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      ctx,
                      req.status == MaintStatus.fresh
                          ? MaintStatus.active
                          : MaintStatus.done,
                    ),
                    style: FilledButton.styleFrom(backgroundColor: blue),
                    child: Text(
                      req.status == MaintStatus.fresh
                          ? 'Tiếp nhận yêu cầu'
                          : 'Hoàn thành',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (!mounted || status == null) return;
    maintStore.setStatus(req.id, status);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F8FA),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder<List<MaintReq>>(
              valueListenable: maintStore,
              builder: (_, rows, child) {
                final shown = rows.where(
                  (r) =>
                      _filter == 0 ||
                      r.status ==
                          (_filter == 1
                              ? MaintStatus.fresh
                              : MaintStatus.active),
                );
                final counts = [
                  rows.length,
                  rows.where((r) => r.status == MaintStatus.fresh).length,
                  rows.where((r) => r.status == MaintStatus.active).length,
                ];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 90),
                  children: [
                    const Text(
                      'Bảo trì',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Theo dõi yêu cầu sửa chữa',
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                    const SizedBox(height: 29),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(
                          3,
                          (i) => Padding(
                            padding: const EdgeInsets.only(right: 22),
                            child: InkWell(
                              onTap: () => setState(() => _filter = i),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _filter == i ? blue : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  '${['Tất cả', 'Mới', 'Đang xử lý'][i]} ${counts[i]}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _filter == i ? Colors.white : muted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (shown.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: Text(
                            'Chưa có yêu cầu bảo trì',
                            style: TextStyle(color: muted, fontSize: 12),
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

  Widget _card(MaintReq req) {
    final color = _color(req.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _detail(req),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                req.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ink,
                ),
              ),
              const SizedBox(height: 11),
              Text(
                req.location,
                style: const TextStyle(fontSize: 10, color: muted),
              ),
              const SizedBox(height: 13),
              Text(
                'Cập nhật: ${maintTime(req.updated)}',
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
                      req.status.label,
                      style: TextStyle(fontSize: 10, color: color),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: muted, size: 22),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
