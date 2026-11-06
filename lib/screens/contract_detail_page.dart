import 'package:flutter/material.dart';

import '../models/record.dart';
import '../services/document_service.dart';
import '../widgets/common.dart';
import 'contract_edit_page.dart';

String _formatDateVi(String iso) {
  final parts = iso.split('-');
  if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
  return iso;
}

class ContractDetailPage extends StatelessWidget {
  final String contractId;
  const ContractDetailPage({super.key, required this.contractId});

  Widget _contactRow(IconData icon, String title, String value) => Row(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(color: canvas, shape: BoxShape.circle),
        child: Icon(icon, size: 19, color: muted),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value.isEmpty ? 'Chưa cập nhật' : value,
              style: const TextStyle(
                color: ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _priceLine(String left, String right) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            left,
            style: const TextStyle(
              color: muted,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          right,
          style: const TextStyle(
            color: ink,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) => SizedBox(
    height: 44,
    child: FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    ),
  );

  @override
  Widget build(BuildContext context) => DocumentView(
    collection: 'contracts',
    id: contractId,
    builder: (c) => RecordsView(
      collection: 'tenants',
      builder: (_, tenants) => RecordsView(
        collection: 'rooms',
        builder: (_, rooms) => RecordsView(
          collection: 'services',
          builder: (_, services) {
            final tenant = tenants
                .where((t) => t.id == c.text('tenantId'))
                .firstOrNull;
            final contractTenants =
                tenants
                    .where(
                      (t) =>
                          t.id == c.text('tenantId') ||
                          c.strings('tenantIds').contains(t.id),
                    )
                    .toList()
                  ..sort(
                    (a, b) => a.id == c.text('tenantId')
                        ? -1
                        : b.id == c.text('tenantId')
                        ? 1
                        : a.name.compareTo(b.name),
                  );
            final room = rooms
                .where((r) => r.id == c.text('roomId'))
                .firstOrNull;
            final assignedServices = room == null
                ? const <Record>[]
                : services
                      .where(
                        (s) =>
                            !s.archived &&
                            room.strings('serviceIds').contains(s.id),
                      )
                      .toList();

            final status = c.text('status');
            final canEnd = ['active', 'scheduled'].contains(status);
            final tenantName = c.text(
              'tenantName',
              tenant?.name ?? c.text('name'),
            );
            final roomName = c.text('roomName', room?.name ?? c.text('room'));
            final startText = _formatDateVi(
              c.text('startDate', c.text('start')),
            );
            final endText = _formatDateVi(c.text('endDate', c.text('end')));

            return Scaffold(
              backgroundColor: canvas,
              appBar: AppBar(
                backgroundColor: canvas,
                leading: IconButton(
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    size: 30,
                    color: ink,
                  ),
                  onPressed: () => Navigator.maybePop(context),
                ),
                titleSpacing: 0,
                title: const Text(
                  'Chi tiết hợp đồng',
                  style: TextStyle(
                    color: ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: [
                  Center(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () =>
                          openPage(context, ContractEditPage(contract: c)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: softBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Chỉnh sửa',
                          style: const TextStyle(
                            color: blue,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  if (c.text('roomId').isEmpty || c.text('tenantId').isEmpty)
                    box(
                      const Text(
                        'Hợp đồng cũ chưa liên kết đủ dữ liệu. Đối chiếu dữ liệu cũ và tạo hợp đồng chuẩn mới nếu thiếu liên kết.',
                        style: TextStyle(color: muted, fontSize: 12.5),
                      ),
                    ),

                  // 1. Summary Card (Frame 9)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: line),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: softBlue,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.description_outlined,
                                color: blue,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.text('number', c.text('id', c.id)),
                                    style: const TextStyle(
                                      color: ink,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    tenantName,
                                    style: const TextStyle(
                                      color: Color(0xFF232D40),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Phòng : $roomName',
                                    style: const TextStyle(
                                      color: Color(0xFF232D40),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            statusPill(
                              status,
                              customText: status == 'active'
                                  ? 'Đang thuê'
                                  : null,
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: line),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 15,
                              color: muted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$startText - $endText',
                                style: const TextStyle(
                                  color: ink,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              (c.number('deposit') ?? 0) > 0
                                  ? 'Đã đặt cọc'
                                  : 'Chưa cọc',
                              style: const TextStyle(
                                color: ink,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Tenant Info Card (Frame 9)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thông tin người thuê',
                          style: TextStyle(
                            color: ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            initialAvatar(
                              tenantName,
                              size: 46,
                              solidBlue: false,
                              twoLetters: true,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                tenantName,
                                style: const TextStyle(
                                  color: ink,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: line),
                        ),
                        _contactRow(
                          Icons.phone_outlined,
                          'Số điện thoại',
                          tenant?.text('phone') ?? '',
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: line),
                        ),
                        _contactRow(
                          Icons.mark_email_unread_outlined,
                          'Email',
                          tenant?.text('email') ?? '',
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: line),
                        ),
                        _contactRow(
                          Icons.badge_outlined,
                          'CCCD',
                          tenant?.text('identity') ?? '',
                        ),
                        if (contractTenants.length > 1) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: line),
                          ),
                          const Text(
                            'Người thuê trong phòng',
                            style: TextStyle(
                              color: ink,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final person in contractTenants)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      person.name,
                                      style: const TextStyle(
                                        color: ink,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    person.id == c.text('tenantId')
                                        ? 'Trưởng phòng'
                                        : 'Thành viên',
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Room Info Card (Frame 9)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thông tin phòng',
                          style: TextStyle(
                            color: ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: canvas,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.meeting_room_outlined,
                                size: 20,
                                color: muted,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Phòng : $roomName',
                                    style: const TextStyle(
                                      color: ink,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    room == null
                                        ? 'Chưa cập nhật diện tích'
                                        : 'Diện tích: ${room.number('area') ?? '—'} m²  •  Tối đa ${room.number('capacity') ?? '—'} người',
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (room != null &&
                                      room.text('description').isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      room.text('description'),
                                      style: const TextStyle(
                                        color: muted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Payment & Services Card (Frame 9)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thông tin thanh toán & Phí dịch vụ khác',
                          style: TextStyle(
                            color: ink,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _priceLine(
                          'Tiền thuê phòng hàng tháng',
                          '${money(c.data['rent'])}/tháng',
                        ),
                        _priceLine(
                          'Tiền đặt cọc',
                          status == 'ended'
                              ? '${money(c.data['deposit'])} (Đã thanh lý)'
                              : money(c.data['deposit']),
                        ),
                        _priceLine('Kỳ thanh toán', 'Đóng 1 tháng/lần'),
                        _priceLine(
                          'Ngày thanh toán',
                          room != null && room.text('billingDay').isNotEmpty
                              ? 'Ngày ${room.text('billingDay')} hàng tháng'
                              : 'Hàng tháng',
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1, color: line),
                        ),
                        const Text(
                          'Phí dịch vụ:',
                          style: TextStyle(
                            color: ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (assignedServices.isEmpty)
                          const Text(
                            'Chưa áp dụng phí dịch vụ phụ',
                            style: TextStyle(color: muted, fontSize: 13),
                          )
                        else
                          for (final s in assignedServices)
                            _priceLine(
                              s.name,
                              '${money(s.data['price'])}/${s.text('unit')}',
                            ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1, color: line),
                        ),
                        const Text(
                          'Ghi chú',
                          style: TextStyle(
                            color: ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c.text('note').isEmpty
                              ? 'Giá và tiền cọc được chốt tại thời điểm lập hợp đồng.'
                              : c.text('note'),
                          style: const TextStyle(color: muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 5. Actions Card (Frame 9)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Hành động',
                          style: TextStyle(
                            color: ink,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _actionButton(
                          label: 'Gia hạn hợp đồng',
                          color: blue,
                          onTap: () => openPage(
                            context,
                            ContractEditPage(
                              initialRoomId: c.text('roomId'),
                              initialTenantId: c.text('tenantId'),
                            ),
                          ),
                        ),
                        if (canEnd) ...[
                          const SizedBox(height: 10),
                          _actionButton(
                            label: 'Kết thúc hợp đồng',
                            color: ink,
                            onTap: () async {
                              if (await confirm(
                                    context,
                                    'Kết thúc/hủy hợp đồng này? Hóa đơn còn nợ phải được xử lý trước.',
                                  ) &&
                                  context.mounted) {
                                await perform(
                                  context,
                                  () => store.command(
                                    'endContract',
                                    id: contractId,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                        const SizedBox(height: 10),
                        _actionButton(
                          label: 'Xuất File PDF',
                          color: const Color(0xFFDC2626),
                          onTap: () => perform(
                            context,
                            () =>
                                DocumentService.printRecord(c, contract: true),
                            'Đã mở bản in',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}
