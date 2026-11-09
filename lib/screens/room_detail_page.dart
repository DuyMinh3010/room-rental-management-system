import 'package:flutter/material.dart';

import '../models/record.dart';
import '../widgets/common.dart';
import 'invoice_detail_page.dart';
import 'room_edit_page.dart';
import 'service_page.dart';
import 'tenant_detail_page.dart';
import 'tenant_edit_page.dart';

class RoomDetailPage extends StatelessWidget {
  final String roomId;
  const RoomDetailPage({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) => DocumentView(
    collection: 'rooms',
    id: roomId,
    builder: (room) => DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: canvas,
        appBar: AppBar(
          backgroundColor: canvas,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 30, color: ink),
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0,
          title: Text(
            room.name,
            style: const TextStyle(
              color: ink,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            moreActionsMenu(
              iconColor: ink,
              onEdit: () => openPage(context, RoomEditPage(room: room)),
              onDelete: () async {
                if (await confirm(
                      context,
                      'Xóa / lưu trữ phòng ${room.name}? Lịch sử hóa đơn vẫn được giữ.',
                    ) &&
                    context.mounted) {
                  await perform(
                    context,
                    () => store.command('archiveRoom', id: roomId),
                    'Đã xóa phòng',
                  );
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
            const SizedBox(width: 6),
          ],
          bottom: const TabBar(
            isScrollable: false,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 2.2,
            tabs: [
              Tab(text: 'Tổng quan'),
              Tab(text: 'Người thuê'),
              Tab(text: 'Dịch vụ'),
              Tab(text: 'Hóa đơn'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: Tổng quan
            RecordsView(
              collection: 'contracts',
              field: 'roomId',
              equals: roomId,
              builder: (_, contracts) {
                final day = DateTime.now()
                    .toUtc()
                    .add(const Duration(hours: 7))
                    .toIso8601String()
                    .substring(0, 10);
                final isRented = contracts.any(
                  (c) =>
                      !c.archived &&
                      ['active', 'scheduled'].contains(c.text('status')) &&
                      c.text('endDate').compareTo(day) >= 0,
                );
                final statusLabel = room.condition == 'Đang sửa'
                    ? 'Đang sửa'
                    : isRented
                    ? 'Đang có người'
                    : 'Trống';
                final hasPhotos = room.strings('imageUrls').isNotEmpty;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: line, width: 0.7),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  room.name,
                                  style: const TextStyle(
                                    color: ink,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              statusPill(statusLabel, customText: statusLabel),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${money(room.data['price'])}/tháng  •  ${room.number('area') ?? '—'}m²',
                            style: const TextStyle(color: muted, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${room.number('people') ?? 0}/${room.number('capacity') ?? '—'} người  •  Chốt tiền: ${room.text('billingDay')}',
                            style: const TextStyle(color: muted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: line, width: 0.7),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thông tin phòng',
                            style: TextStyle(
                              color: ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          info('Tình trạng', room.condition),
                          info('Diện tích', '${room.number('area') ?? '—'} m²'),
                          info('Giá thuê', '${money(room.data['price'])}/tháng'),
                          info('Tiền cọc', money(room.data['deposit'])),
                          info('Ngày chốt tiền', room.text('billingDay')),
                          info(
                            'Hạn thanh toán',
                            '${room.number('paymentTermDays') ?? 5} ngày',
                          ),
                          if (room.data['initialElectric'] != null)
                            info(
                              'Chỉ số điện ban đầu',
                              '${room.data['initialElectric']} kWh',
                            ),
                          if (room.data['initialWater'] != null)
                            info(
                              'Chỉ số nước ban đầu',
                              '${room.data['initialWater']} m³',
                            ),
                          info('Mô tả', room.text('description')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: line, width: 0.7),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dịch vụ áp dụng',
                            style: TextStyle(
                              color: ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          RoomServices(room: room, compact: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (hasPhotos)
                      photos(room)
                    else
                      Container(
                        height: 130,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: line, width: 0.7),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_outlined,
                              color: muted,
                              size: 28,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'ẢNH PHÒNG',
                              style: TextStyle(
                                color: muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),

            // TAB 2: Người thuê (Cố định nút Thêm người ở dưới cùng)
            RecordsView(
              collection: 'tenants',
              field: 'roomId',
              equals: roomId,
              builder: (_, ts) => RecordsView(
                collection: 'contracts',
                field: 'roomId',
                equals: roomId,
                builder: (_, cs) {
                  final tenants = ts.where((t) => !t.archived).toList();
                  final leaderIds = cs
                      .where(
                        (c) =>
                            !c.archived &&
                            ['active', 'scheduled'].contains(c.text('status')),
                      )
                      .map((c) => c.text('tenantId'))
                      .toSet();
                  return Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                          children: [
                            Text(
                              'Danh sách người thuê (${tenants.length})',
                              style: const TextStyle(
                                color: ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (tenants.isEmpty)
                              empty(
                                'Chưa có người thuê trong phòng này. Nhấn nút Thêm người ở bên dưới để bổ sung.',
                              ),
                            for (var i = 0; i < tenants.length; i++)
                              Builder(
                                builder: (context) {
                                  final t = tenants[i];
                                  final isLeader =
                                      leaderIds.contains(t.id) ||
                                      (leaderIds.isEmpty &&
                                          t.text('role') == 'leader');
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: line,
                                        width: 0.7,
                                      ),
                                    ),
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
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                                          color: isLeader
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
                                                          isLeader
                                                              ? 'Trưởng phòng'
                                                              : 'Thành viên',
                                                          style: TextStyle(
                                                            color: isLeader
                                                                ? blue
                                                                : const Color(
                                                                    0xFF16A34A,
                                                                  ),
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          '${room.name}  •  ${t.text('phone')}',
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                                color: muted,
                                                                fontSize: 12,
                                                              ),
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
                                              onDelete: () async {
                                                if (await confirm(
                                                      context,
                                                      'Xóa / lưu trữ người thuê ${t.name}?',
                                                    ) &&
                                                    context.mounted) {
                                                  await perform(
                                                    context,
                                                    () => store.command(
                                                      'archiveTenant',
                                                      id: t.id,
                                                    ),
                                                    'Đã xóa người thuê',
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
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
                              onPressed: () => openPage(
                                context,
                                TenantEditPage(initialRoomId: roomId),
                              ),
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

            // TAB 3: Dịch vụ
            ListView(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
              children: [
                Text(
                  'Dịch vụ của ${room.name}',
                  style: const TextStyle(
                    color: ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                RoomServices(room: room),
                const SizedBox(height: 18),
                const Text(
                  'Nhập chỉ số điện nước',
                  style: TextStyle(
                    color: ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                MeterRoomForm(room: room),
              ],
            ),

            // TAB 4: Hóa đơn
            RecordsView(
              collection: 'invoices',
              field: 'roomId',
              equals: roomId,
              builder: (_, allBs) {
                final bs = allBs.where((b) => !b.archived).toList()
                  ..sort(
                    (a, b) => b.text('period').compareTo(a.text('period')),
                  );
                return ListView(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
                  children: [
                    Text(
                      'Hóa đơn ${room.name}',
                      style: const TextStyle(
                        color: ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (bs.isEmpty) empty('Chưa có hóa đơn'),
                    for (final b in bs)
                      Builder(
                        builder: (context) {
                          final unpaid = [
                            'unpaid',
                            'reported',
                          ].contains(b.text('status'));
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: line, width: 0.7),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => openPage(
                                context,
                                InvoiceDetailPage(invoiceId: b.id),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  12,
                                  8,
                                  12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            b.text('code', b.id),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: ink,
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        statusPill(b.text('status')),
                                        moreActionsMenu(
                                          onEdit: () => openPage(
                                            context,
                                            InvoiceDetailPage(invoiceId: b.id),
                                          ),
                                          onDelete: () async {
                                            if (await confirm(
                                                  context,
                                                  'Xóa hóa đơn ${b.text('code', b.id)}? Sau khi xóa bạn có thể tạo lại hóa đơn kỳ này.',
                                                ) &&
                                                context.mounted) {
                                              await perform(
                                                context,
                                                () => store.command(
                                                  'deleteInvoice',
                                                  id: b.id,
                                                  args: {
                                                    'reason': 'Đã xóa hóa đơn',
                                                  },
                                                ),
                                                'Đã xóa hóa đơn',
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Kỳ ${b.text('period')}  •  Hạn: ${b.text('dueDate')}',
                                      style: const TextStyle(
                                        color: muted,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            money(b.data['total']),
                                            style: const TextStyle(
                                              color: ink,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        if (unpaid)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: blue,
                                              borderRadius:
                                                  BorderRadius.circular(13),
                                            ),
                                            child: const Text(
                                              'Thanh toán',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          )
                                        else if (b.text('method').isNotEmpty)
                                          Text(
                                            label(b.text('method')),
                                            style: const TextStyle(
                                              color: muted,
                                              fontSize: 11,
                                            ),
                                          ),
                                      ],
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
          ],
        ),
      ),
    ),
  );
}
