import 'package:flutter/material.dart';

import '../models/record.dart';
import '../services/document_service.dart';
import '../widgets/common.dart';
import 'contract_edit_page.dart';
import 'room_detail_page.dart';
import 'tenant_detail_page.dart';

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
                          !t.archived &&
                          (t.id == c.text('tenantId') ||
                              c.strings('tenantIds').contains(t.id) ||
                              (c.text('roomId').isNotEmpty &&
                                  t.text('roomId') == c.text('roomId'))),
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
            final tenantName =
                tenant?.name ?? c.text('tenantName', c.text('name'));
            final tenantPhone =
                tenant?.text('phone') ?? c.text('tenantPhone');
            final tenantEmail =
                tenant?.text('email') ?? c.text('tenantEmail');
            final tenantIdentity =
                tenant?.text('identity') ?? c.text('tenantIdentity');
            final roomName = room?.name ?? c.text('roomName', c.text('room'));
            final startText = _formatDateVi(
              c.text('startDate', c.text('start')),
            );
            final endText = _formatDateVi(c.text('endDate', c.text('end')));
            final initElectric =
                c.number('initialElectric') ??
                room?.number('initialElectric') ??
                0;
            final initWater =
                c.number('initialWater') ?? room?.number('initialWater') ?? 0;

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
                  moreActionsMenu(
                    iconColor: ink,
                    onEdit: () =>
                        openPage(context, ContractEditPage(contract: c)),
                    onDelete: () async {
                      if (await confirm(
                            context,
                            'Xóa hợp đồng ${c.text('number', c.id)}? Phòng sẽ trở về trạng thái Trống.',
                          ) &&
                          context.mounted) {
                        await perform(
                          context,
                          () => store.command('deleteContract', id: contractId),
                          'Đã xóa hợp đồng',
                        );
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  // 1. Summary Card
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
                                    'Trưởng phòng: $tenantName',
                                    style: const TextStyle(
                                      color: Color(0xFF232D40),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Phòng: $roomName',
                                    style: const TextStyle(
                                      color: Color(0xFF232D40),
                                      fontSize: 12.5,
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
                        info(
                          'Ngày bắt đầu hợp đồng',
                          '$startText (${c.text('startDate')})',
                          boldValue: true,
                        ),
                        info(
                          'Ngày kết thúc hợp đồng',
                          '$endText (${c.text('endDate')})',
                          boldValue: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Tenant Info Card
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
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Thông tin người thuê (Đại diện & Thành viên)',
                                style: TextStyle(
                                  color: ink,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (tenant != null)
                              TextButton(
                                onPressed: () => openPage(
                                  context,
                                  TenantDetailPage(tenantId: tenant.id),
                                ),
                                child: const Text('Hồ sơ →'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tenantName,
                                    style: const TextStyle(
                                      color: ink,
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: softBlue,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Trưởng phòng (Đại diện hợp đồng)',
                                      style: TextStyle(
                                        color: blue,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
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
                          tenantPhone,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: line),
                        ),
                        _contactRow(
                          Icons.mark_email_unread_outlined,
                          'Email',
                          tenantEmail,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: line),
                        ),
                        _contactRow(
                          Icons.badge_outlined,
                          'CCCD / Passport',
                          tenantIdentity,
                        ),
                        if (tenant != null &&
                            (tenant.text('cccdFrontUrl').isNotEmpty ||
                                tenant.text('cccdBackUrl').isNotEmpty)) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => showCccdFullDialog(
                                    context,
                                    'CCCD Mặt trước - $tenantName',
                                    tenant.text('cccdFrontUrl'),
                                  ),
                                  child: cccdImageWidget(
                                    tenant.text('cccdFrontUrl'),
                                    height: 85,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => showCccdFullDialog(
                                    context,
                                    'CCCD Mặt sau - $tenantName',
                                    tenant.text('cccdBackUrl'),
                                  ),
                                  child: cccdImageWidget(
                                    tenant.text('cccdBackUrl'),
                                    height: 85,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (contractTenants.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: line),
                          ),
                          Text(
                            'Danh sách thành viên trong phòng (${contractTenants.length})',
                            style: const TextStyle(
                              color: ink,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final person in contractTenants)
                            InkWell(
                              onTap: () => openPage(
                                context,
                                TenantDetailPage(tenantId: person.id),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${person.name} (${person.text('phone')})',
                                        style: const TextStyle(
                                          color: ink,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: person.id == c.text('tenantId')
                                            ? softBlue
                                            : const Color(0xFFECFDF3),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        person.id == c.text('tenantId')
                                            ? 'Trưởng phòng'
                                            : 'Thành viên',
                                        style: TextStyle(
                                          color: person.id == c.text('tenantId')
                                              ? blue
                                              : const Color(0xFF16A34A),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Room & Initial Meter Readings Card
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
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Thông tin phòng & Chỉ số đầu kỳ',
                                style: TextStyle(
                                  color: ink,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (room != null)
                              TextButton(
                                onPressed: () => openPage(
                                  context,
                                  RoomDetailPage(roomId: room.id),
                                ),
                                child: const Text('Xem phòng →'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _priceLine('Phòng', roomName),
                        if (room != null)
                          _priceLine(
                            'Diện tích / Sức chứa',
                            '${room.number('area') ?? '—'} m² • Tối đa ${room.number('capacity') ?? '—'} người',
                          ),
                        _priceLine(
                          'Chỉ số điện ban đầu (lúc làm HĐ)',
                          '$initElectric kWh',
                        ),
                        _priceLine(
                          'Chỉ số nước ban đầu (lúc làm HĐ)',
                          '$initWater m³',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Payment & Services Card
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
                          'Thông tin thanh toán & Phí dịch vụ',
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
                        _priceLine(
                          'Ngày bắt đầu hợp đồng',
                          c.text('startDate'),
                        ),
                        _priceLine(
                          'Ngày kết thúc hợp đồng',
                          c.text('endDate'),
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

                  // 5. Actions Card
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
                        if (canEnd) ...[
                          _actionButton(
                            label: 'Kết thúc / Thanh lý hợp đồng',
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
                          const SizedBox(height: 10),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: _actionButton(
                                label: 'In / Xuất PDF',
                                color: const Color(0xFFDC2626),
                                onTap: () => perform(
                                  context,
                                  () => DocumentService.printRecord(
                                    c,
                                    contract: true,
                                  ),
                                  'Đã mở bản in',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _actionButton(
                                label: 'Chia sẻ PDF',
                                color: blue,
                                onTap: () => perform(
                                  context,
                                  () => DocumentService.shareRecord(
                                    c,
                                    contract: true,
                                  ),
                                  'Đã mở chia sẻ hợp đồng',
                                ),
                              ),
                            ),
                          ],
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
