import 'package:flutter/material.dart';

import '../models/record.dart';
import '../widgets/common.dart';
import 'notification_page.dart';
import 'room_detail_page.dart';
import 'room_edit_page.dart';

class RoomPage extends StatefulWidget {
  const RoomPage({super.key});
  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  String query = '', filter = 'Tất cả';

  Future<void> _migrateLegacyData(BuildContext context) async {
    if (!await confirm(
      context,
      'Gán các dữ liệu Firestore chưa có ownerId cho tài khoản chủ trọ đang đăng nhập? Chỉ tiếp tục nếu bạn là chủ sở hữu dữ liệu cũ.',
    )) {
      return;
    }
    if (!context.mounted) return;
    await perform(
      context,
      () => store.command('migrateOwnerData'),
      'Đã khôi phục liên kết dữ liệu cũ. Danh sách phòng sẽ tự cập nhật.',
    );
  }

  Future<void> _deleteRoom(BuildContext context, Record r) async {
    if (!await confirm(
      context,
      'Xóa / lưu trữ phòng ${r.name}? Lịch sử hóa đơn vẫn được giữ.',
    )) {
      return;
    }
    if (!context.mounted) return;
    await perform(
      context,
      () => store.command('archiveRoom', id: r.id),
      'Đã xóa phòng ${r.name}',
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    appBar: AppBar(
      backgroundColor: canvas,
      title: const Text(
        'Danh sách phòng',
        style: TextStyle(color: ink, fontSize: 22, fontWeight: FontWeight.w600),
      ),
      actions: [
        const NotificationButton(),
        Center(
          child: figmaPrimaryPillButton(
            label: '+ Thêm',
            onTap: () => openPage(context, const RoomEditPage()),
          ),
        ),
        const SizedBox(width: 14),
      ],
    ),
    body: RecordsView(
      collection: 'rooms',
      builder: (_, all) {
        final rooms = all.where((r) => !r.archived).toList()
          ..sort((a, b) => naturalCompare(a.name, b.name));
        return RecordsView(
          collection: 'contracts',
          builder: (_, contracts) {
            final day = DateTime.now()
                .toUtc()
                .add(const Duration(hours: 7))
                .toIso8601String()
                .substring(0, 10);
            bool rented(Record room) => contracts.any(
              (c) =>
                  !c.archived &&
                  c.text('roomId') == room.id &&
                  ['active', 'scheduled'].contains(c.text('status')) &&
                  c.text('endDate').compareTo(day) >= 0,
            );
            final shown = rooms
                .where(
                  (r) =>
                      r.name.toLowerCase().contains(
                        query.trim().toLowerCase(),
                      ) &&
                      (filter == 'Tất cả' ||
                          filter == 'Đang thuê' &&
                              r.condition != 'Đang sửa' &&
                              rented(r) ||
                          filter == 'Trống' &&
                              r.condition != 'Đang sửa' &&
                              !rented(r) ||
                          filter == 'Tốt' && r.condition == 'Tốt' ||
                          filter == 'Đang sửa' && r.condition == 'Đang sửa'),
                )
                .toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
              children: [
                TextField(
                  onChanged: (v) => setState(() => query = v),
                  decoration: searchDecoration('Tìm kiếm phòng...'),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final item in const [
                        ('Tất cả', 'Tất cả'),
                        ('Đang thuê', 'Đang cho thuê'),
                        ('Trống', 'Trống'),
                        ('Đang sửa', 'Đang sửa'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: figmaFilterPill(
                            label: item.$2,
                            selected: filter == item.$1,
                            onTap: () => setState(() => filter = item.$1),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (shown.isEmpty) ...[
                  empty(
                    rooms.isEmpty
                        ? 'Chưa tìm thấy phòng thuộc tài khoản này'
                        : 'Không có phòng khớp bộ lọc',
                  ),
                  if (rooms.isEmpty)
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () => _migrateLegacyData(context),
                        icon: const Icon(Icons.sync_rounded),
                        label: const Text('Hiển thị dữ liệu phòng cũ'),
                      ),
                    ),
                ],
                for (final r in shown)
                  Builder(
                    builder: (context) {
                      final statusLabel = r.condition == 'Đang sửa'
                          ? 'Đang sửa'
                          : rented(r)
                          ? 'Đang cho thuê'
                          : 'Trống';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: line, width: 0.7),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () =>
                                openPage(context, RoomDetailPage(roomId: r.id)),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 62,
                                    height: 80,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAF0F7),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'PHÒNG',
                                          style: TextStyle(
                                            color: muted,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            r.name,
                                            maxLines: 1,
                                            style: const TextStyle(
                                              color: ink,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        statusPill(
                                          statusLabel,
                                          customText: statusLabel,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${money(r.data['price'])}/tháng',
                                          style: const TextStyle(
                                            color: ink,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${r.number('area') ?? '—'}m²  •  ${r.number('people') ?? 0} người',
                                          style: const TextStyle(
                                            color: muted,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  moreActionsMenu(
                                    onEdit: () => openPage(
                                      context,
                                      RoomEditPage(room: r),
                                    ),
                                    onDelete: () => _deleteRoom(context, r),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        );
      },
    ),
  );
}
