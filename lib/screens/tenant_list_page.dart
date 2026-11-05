import 'package:flutter/material.dart';

import '../widgets/common.dart';
import 'tenant_detail_page.dart';
import 'tenant_edit_page.dart';

class TenantListPage extends StatefulWidget {
  const TenantListPage({super.key});
  @override
  State<TenantListPage> createState() => _TenantListPageState();
}

class _TenantListPageState extends State<TenantListPage> {
  String query = '';
  String roleFilter = 'Tất cả';

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    appBar: AppBar(
      backgroundColor: canvas,
      title: const Text(
        'Người thuê',
        style: TextStyle(
          color: ink,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        Center(
          child: figmaPrimaryPillButton(
            label: '+ Thêm',
            onTap: () => openPage(context, const TenantEditPage()),
          ),
        ),
        const SizedBox(width: 14),
      ],
    ),
    body: RecordsView(
      collection: 'tenants',
      builder: (_, all) => RecordsView(
        collection: 'rooms',
        builder: (_, rooms) => RecordsView(
          collection: 'contracts',
          builder: (_, contracts) {
            final activeTenants = all.where((t) => !t.archived).toList();
            final leaderIds = contracts
                .where((c) => ['active', 'scheduled'].contains(c.text('status')))
                .map((c) => c.text('tenantId'))
                .toSet();

            // Fallback: nếu phòng chưa có hợp đồng thì người đầu tiên của phòng là Trưởng phòng.
            final firstInRoom = <String, String>{};
            for (final t in activeTenants) {
              final rid = t.text('roomId');
              if (rid.isNotEmpty) {
                firstInRoom.putIfAbsent(rid, () => t.id);
              }
            }

            bool isLeader(String tenantId, String roomId) {
              if (leaderIds.contains(tenantId)) return true;
              if (roomId.isNotEmpty &&
                  !contracts.any(
                    (c) =>
                        c.text('roomId') == roomId &&
                        ['active', 'scheduled'].contains(c.text('status')),
                  )) {
                return firstInRoom[roomId] == tenantId;
              }
              return false;
            }

            final shown = activeTenants.where((t) {
              final roomName =
                  rooms.where((r) => r.id == t.text('roomId')).firstOrNull?.name ??
                  '';
              final matchQuery = '${t.name} ${t.text('phone')} $roomName'
                  .toLowerCase()
                  .contains(query.trim().toLowerCase());
              if (!matchQuery) return false;
              final leader = isLeader(t.id, t.text('roomId'));
              if (roleFilter == 'Trưởng phòng') return leader;
              if (roleFilter == 'Thành viên') return !leader;
              return true;
            }).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
              children: [
                TextField(
                  decoration: searchDecoration(
                    'Tìm kiếm theo tên, SĐT, Phòng',
                  ),
                  onChanged: (v) => setState(() => query = v),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final label in const [
                        'Tất cả',
                        'Trưởng phòng',
                        'Thành viên',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: figmaFilterPill(
                            label: label,
                            selected: roleFilter == label,
                            onTap: () => setState(() => roleFilter = label),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (shown.isEmpty) empty('Chưa có người thuê'),
                for (final t in shown)
                  Builder(
                    builder: (context) {
                      final roomName =
                          rooms
                              .where((r) => r.id == t.text('roomId'))
                              .firstOrNull
                              ?.name ??
                          'Chưa gán phòng';
                      final leader = isLeader(t.id, t.text('roomId'));
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
                              TenantDetailPage(tenantId: t.id),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 13,
                              ),
                              child: Row(
                                children: [
                                  initialAvatar(t.name, size: 34),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.name,
                                          style: const TextStyle(
                                            color: ink,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: leader
                                                    ? softBlue
                                                    : const Color(0xFFECFDF3),
                                                borderRadius:
                                                    BorderRadius.circular(13),
                                              ),
                                              child: Text(
                                                leader
                                                    ? 'Trưởng phòng'
                                                    : 'Thành viên',
                                                style: TextStyle(
                                                  color: leader
                                                      ? blue
                                                      : const Color(0xFF16A34A),
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '$roomName  •  ${t.text('phone')}',
                                                style: const TextStyle(
                                                  color: muted,
                                                  fontSize: 11,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: muted,
                                    size: 20,
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
        ),
      ),
    ),
  );
}
