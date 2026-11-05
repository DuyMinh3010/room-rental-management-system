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

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    appBar: AppBar(
      backgroundColor: canvas,
      title: const Text(
        'Danh sách phòng',
        style: TextStyle(
          color: ink,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
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
          ..sort((a, b) => a.name.compareTo(b.name));
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
                  c.text('roomId') == room.id &&
                  c.text('status') == 'active' &&
                  c.text('startDate').compareTo(day) <= 0 &&
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
                if (shown.isEmpty)
                  empty('Chưa có phòng hoặc không khớp bộ lọc'),
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
                            onTap: () => openPage(
                              context,
                              RoomDetailPage(roomId: r.id),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
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
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: muted,
                                    size: 22,
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
