import 'package:flutter/material.dart';

import '../models/record.dart';
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

  Future<void> _deleteTenant(BuildContext context, Record t) async {
    if (!await confirm(
      context,
      'Xóa / lưu trữ người thuê ${t.name}? Không xóa lịch sử hợp đồng.',
    )) {
      return;
    }
    if (!context.mounted) return;
    await perform(
      context,
      () => store.command('archiveTenant', id: t.id),
      'Đã xóa người thuê ${t.name}',
    );
  }

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
                .where(
                  (c) =>
                      !c.archived &&
                      ['active', 'scheduled'].contains(c.text('status')),
                )
                .map((c) => c.text('tenantId'))
                .toSet();

            final firstInRoom = <String, String>{};
            for (final t in activeTenants) {
              final rid = t.text('roomId');
              if (rid.isNotEmpty) {
                firstInRoom.putIfAbsent(rid, () => t.id);
              }
            }

            bool isLeader(Record t) {
              final tenantId = t.id;
              final roomId = t.text('roomId');
              if (leaderIds.contains(tenantId)) return true;
              if (t.text('role') == 'leader') return true;
              if (roomId.isNotEmpty &&
                  !contracts.any(
                    (c) =>
                        !c.archived &&
                        c.text('roomId') == roomId &&
                        ['active', 'scheduled'].contains(c.text('status')),
                  ) &&
                  !activeTenants.any(
                    (o) =>
                        o.text('roomId') == roomId &&
                        o.text('role') == 'leader',
                  )) {
                return firstInRoom[roomId] == tenantId;
              }
              return false;
            }

            final shown = activeTenants.where((t) {
              final roomName =
                  rooms
                      .where((r) => r.id == t.text('roomId'))
                      .firstOrNull
                      ?.name ??
                  '';
              final matchQuery =
                  '${t.name} ${t.text('phone')} ${t.text('identity')} $roomName'
                      .toLowerCase()
                      .contains(query.trim().toLowerCase());
              if (!matchQuery) return false;
              final leader = isLeader(t);
              if (roleFilter == 'Trưởng phòng') return leader;
              if (roleFilter == 'Thành viên') return !leader;
              return true;
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        decoration: searchDecoration(
                          'Tìm kiếm theo tên, SĐT, CCCD, Phòng',
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
                                  onTap: () =>
                                      setState(() => roleFilter = label),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                    children: [
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
                            final leader = isLeader(t);
                            final hasCccd =
                                t.text('cccdFrontUrl').isNotEmpty ||
                                t.text('cccdBackUrl').isNotEmpty;
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
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      12,
                                      6,
                                      12,
                                    ),
                                    child: Row(
                                      children: [
                                        initialAvatar(t.name, size: 36),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      t.name,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: ink,
                                                        fontSize: 13.5,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  if (hasCccd) ...[
                                                    const SizedBox(width: 6),
                                                    const Icon(
                                                      Icons.verified_user_rounded,
                                                      size: 15,
                                                      color: blue,
                                                    ),
                                                  ],
                                                ],
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
                                                          : const Color(
                                                              0xFFECFDF3,
                                                            ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            13,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      leader
                                                          ? 'Trưởng phòng'
                                                          : 'Thành viên',
                                                      style: TextStyle(
                                                        color: leader
                                                            ? blue
                                                            : const Color(
                                                                0xFF16A34A,
                                                              ),
                                                        fontSize: 10.5,
                                                        fontWeight:
                                                            FontWeight.w600,
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
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        moreActionsMenu(
                                          onEdit: () => openPage(
                                            context,
                                            TenantEditPage(tenant: t),
                                          ),
                                          onDelete: () =>
                                              _deleteTenant(context, t),
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
                  ),
                ),
                // Nút "Thêm người" cố định ở dưới cùng màn hình, không cuộn trôi theo danh sách
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: line)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: () =>
                            openPage(context, const TenantEditPage()),
                        style: FilledButton.styleFrom(
                          backgroundColor: blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text(
                          'Thêm người',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
