import 'package:flutter/material.dart';

import '../models/record.dart';
import '../widgets/common.dart';
import 'maint_create_page.dart';

String _relativeUpdateText(DateTime? dt) {
  if (dt == null) return 'Cập nhật: vừa xong';
  final diff = DateTime.now().difference(dt.toLocal());
  if (diff.inMinutes < 1) return 'Cập nhật: vừa xong';
  if (diff.inMinutes < 60) return 'Cập nhật: ${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return 'Cập nhật: ${diff.inHours} giờ trước';
  if (diff.inDays == 1) return 'Cập nhật: hôm qua';
  if (diff.inDays < 30) return 'Cập nhật: ${diff.inDays} ngày trước';
  return 'Cập nhật: ${dt.toLocal().toString().substring(0, 10)}';
}

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});
  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  String filter = 'all';

  Future<void> _deleteMaintenance(BuildContext context, Record m) async {
    if (!await confirm(
      context,
      'Xóa yêu cầu bảo trì "${m.text('title')}"?',
    )) {
      return;
    }
    if (!context.mounted) return;
    await perform(
      context,
      () => store.command('deleteMaintenance', id: m.id),
      'Đã xóa yêu cầu bảo trì',
    );
  }

  Widget _maintFilterPill({
    required String id,
    required String text,
    required Color bg,
    required Color fg,
  }) {
    final selected = filter == id;
    return GestureDetector(
      onTap: () => setState(() => filter = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(13),
          border: selected ? Border.all(color: fg, width: 1.3) : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: fg,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    appBar: AppBar(
      backgroundColor: canvas,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bảo trì',
            style: TextStyle(
              color: ink,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Theo dõi yêu cầu sửa chữa',
            style: TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    ),
    floatingActionButton: SizedBox(
      width: 58,
      height: 58,
      child: FloatingActionButton(
        tooltip: 'Tạo yêu cầu bảo trì',
        elevation: 2,
        onPressed: () => openPage(context, const MaintCreatePage()),
        backgroundColor: blue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    ),
    body: RecordsView(
      collection: 'maintenance',
      builder: (_, rawAll) => RecordsView(
        collection: 'rooms',
        builder: (_, rooms) => RecordsView(
          collection: 'tenants',
          builder: (_, tenants) {
            final all = rawAll.where((m) => !m.archived).toList()
              ..sort(
                (a, b) => (b.time('createdAt') ?? DateTime(2000)).compareTo(
                  a.time('createdAt') ?? DateTime(2000),
                ),
              );
            final newCount = all.where((m) => m.text('status') == 'new').length;
            final workingCount = all
                .where((m) => m.text('status') == 'working')
                .length;
            final doneCount = all
                .where((m) => m.text('status') == 'done')
                .length;

            final filtered = all
                .where((m) => filter == 'all' || m.text('status') == filter)
                .toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 92),
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _maintFilterPill(
                        id: 'all',
                        text: 'Tất cả ${all.length}',
                        bg: softBlue,
                        fg: blue,
                      ),
                      const SizedBox(width: 8),
                      _maintFilterPill(
                        id: 'new',
                        text: 'Mới $newCount',
                        bg: const Color(0xFFFDECEC),
                        fg: const Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 8),
                      _maintFilterPill(
                        id: 'working',
                        text: 'Đang xử lý $workingCount',
                        bg: const Color(0xFFFFF4E5),
                        fg: const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 8),
                      _maintFilterPill(
                        id: 'done',
                        text: 'Hoàn thành $doneCount',
                        bg: const Color(0xFFEAF8EE),
                        fg: const Color(0xFF16A34A),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (filtered.isEmpty) empty('Chưa có yêu cầu bảo trì'),
                for (final m in filtered)
                  Builder(
                    builder: (context) {
                      final r = rooms
                          .where((x) => x.id == m.text('roomId'))
                          .firstOrNull;
                      final roomName = r?.name ?? m.text('roomId');
                      final roomTenant = tenants
                          .where(
                            (t) =>
                                !t.archived &&
                                t.text('roomId') == m.text('roomId'),
                          )
                          .firstOrNull;
                      final status = m.text('status');
                      final subtitle = roomTenant != null
                          ? '$roomName · ${roomTenant.name}'
                          : roomName;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: line, width: 0.7),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => openPage(
                            context,
                            MaintenanceDetailPage(maintenanceId: m.id),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        m.text('title'),
                                        style: const TextStyle(
                                          color: ink,
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    statusPill(
                                      status,
                                      customText: status == 'new'
                                          ? 'Mới'
                                          : null,
                                    ),
                                    moreActionsMenu(
                                      onEdit: () => openPage(
                                        context,
                                        MaintCreatePage(maintenance: m),
                                      ),
                                      onDelete: () =>
                                          _deleteMaintenance(context, m),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 11.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _relativeUpdateText(
                                    m.time('updatedAt') ?? m.time('createdAt'),
                                  ),
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class MaintenanceDetailPage extends StatelessWidget {
  final String maintenanceId;
  const MaintenanceDetailPage({super.key, required this.maintenanceId});
  @override
  Widget build(BuildContext context) => DocumentView(
    collection: 'maintenance',
    id: maintenanceId,
    builder: (m) => Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        backgroundColor: canvas,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 30, color: ink),
          onPressed: () => Navigator.maybePop(context),
        ),
        titleSpacing: 0,
        title: const Text(
          'Chi tiết bảo trì',
          style: TextStyle(
            color: ink,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          moreActionsMenu(
            iconColor: ink,
            onEdit: () => openPage(context, MaintCreatePage(maintenance: m)),
            onDelete: () async {
              if (await confirm(
                    context,
                    'Xóa yêu cầu bảo trì "${m.text('title')}"?',
                  ) &&
                  context.mounted) {
                await perform(
                  context,
                  () => store.command('deleteMaintenance', id: maintenanceId),
                  'Đã xóa yêu cầu bảo trì',
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RecordsView(
        collection: 'rooms',
        builder: (_, rooms) {
          final roomName =
              rooms.where((r) => r.id == m.text('roomId')).firstOrNull?.name ??
              m.text('roomId');
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            m.text('title'),
                            style: const TextStyle(
                              color: ink,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        statusPill(m.text('status')),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: line),
                    ),
                    info('Phòng', roomName),
                    info('Mô tả chi tiết', m.text('description')),
                    info('Trạng thái', label(m.text('status'))),
                    info('Chi phí sửa chữa', money(m.data['cost'])),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              photos(m),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: () =>
                      openPage(context, MaintCreatePage(maintenance: m)),
                  style: FilledButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Cập nhật xử lý'),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Chi phí bảo trì không tự cộng vào hóa đơn. Nếu người thuê phải chi trả, thêm phụ phí có lý do khi lập hóa đơn.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
          );
        },
      ),
    ),
  );
}
