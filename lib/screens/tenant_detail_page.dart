import 'package:flutter/material.dart';

import '../models/record.dart';
import '../widgets/common.dart';
import 'contract_detail_page.dart';
import 'invoice_detail_page.dart';
import 'room_detail_page.dart';
import 'tenant_edit_page.dart';

class TenantDetailPage extends StatelessWidget {
  final String tenantId;
  const TenantDetailPage({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context) => DocumentView(
    collection: 'tenants',
    id: tenantId,
    builder: (t) => RecordsView(
      collection: 'rooms',
      builder: (_, rooms) => RecordsView(
        collection: 'contracts',
        field: 'roomId',
        equals: t.text('roomId'),
        builder: (_, cs) => RecordsView(
          collection: 'invoices',
          field: 'roomId',
          equals: t.text('roomId'),
          builder: (_, roomInvoices) {
            final room = rooms
                .where((r) => r.id == t.text('roomId'))
                .firstOrNull;
            final sortedContracts =
                cs
                    .where(
                      (c) =>
                          !c.archived &&
                          (c.text('tenantId') == tenantId ||
                              c.strings('tenantIds').contains(tenantId) ||
                              c.text('roomId') == t.text('roomId')),
                    )
                    .toList()
                  ..sort(
                    (a, b) =>
                        b.text('startDate').compareTo(a.text('startDate')),
                  );
            final activeContract =
                sortedContracts
                    .where(
                      (c) =>
                          ['active', 'scheduled'].contains(c.text('status')),
                    )
                    .firstOrNull ??
                sortedContracts.firstOrNull;
            final linkedInvoices =
                roomInvoices
                    .where(
                      (b) =>
                          !b.archived &&
                          t.text('roomId').isNotEmpty &&
                          b.text('roomId') == t.text('roomId'),
                    )
                    .toList()
                  ..sort(
                    (a, b) => b.text('period').compareTo(a.text('period')),
                  );
            final roomLabel = room?.name ?? 'Chưa gán phòng';
            final isLeader =
                activeContract?.text('tenantId') == tenantId ||
                (activeContract == null && t.text('role') == 'leader');

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
                  onPressed: () => Navigator.pop(context),
                ),
                titleSpacing: 0,
                title: const Text(
                  'Hồ sơ người thuê',
                  style: TextStyle(
                    color: ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: [
                  moreActionsMenu(
                    iconColor: ink,
                    onEdit: () => openPage(context, TenantEditPage(tenant: t)),
                    onDelete: () async {
                      if (await confirm(
                            context,
                            'Xóa / lưu trữ người thuê ${t.name}? Không xóa lịch sử hợp đồng.',
                          ) &&
                          context.mounted) {
                        await perform(
                          context,
                          () => store.command('archiveTenant', id: tenantId),
                          'Đã xóa người thuê',
                        );
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                      children: [
                        // Summary Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: line, width: 0.8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  initialAvatar(
                                    t.name,
                                    size: 64,
                                    solidBlue: false,
                                    twoLetters: true,
                                    borderRadius: 20,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.name,
                                          style: const TextStyle(
                                            color: ink,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        InkWell(
                                          onTap: room == null
                                              ? null
                                              : () => openPage(
                                                  context,
                                                  RoomDetailPage(
                                                    roomId: room.id,
                                                  ),
                                                ),
                                          child: Text(
                                            roomLabel,
                                            style: const TextStyle(
                                              color: blue,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEAF8EE),
                                                borderRadius:
                                                    BorderRadius.circular(13),
                                              ),
                                              child: Text(
                                                room != null
                                                    ? 'Đang thuê'
                                                    : 'Chưa gán phòng',
                                                style: const TextStyle(
                                                  color: Color(0xFF16A34A),
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            if (room != null)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isLeader
                                                      ? softBlue
                                                      : const Color(0xFFECFDF3),
                                                  borderRadius:
                                                      BorderRadius.circular(13),
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
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w600,
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
                              if (activeContract != null) ...[
                                const SizedBox(height: 14),
                                Text(
                                  'Hợp đồng: ${activeContract.text('number', activeContract.id)} (${activeContract.text('startDate')} → ${activeContract.text('endDate')})',
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 13.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),
                        const Text(
                          'Thông tin liên hệ & CCCD',
                          style: TextStyle(
                            color: ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: line, width: 0.8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _contactRow(
                                label: 'Số điện thoại',
                                value: t.text('phone'),
                                trailing: ClipOval(
                                  child: Image.asset(
                                    'assets/images/phone_icon.jpg',
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const Divider(height: 18),
                              _contactRow(
                                label: 'Email',
                                value: t.text('email'),
                                trailing: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.asset(
                                    'assets/images/email_icon.jpg',
                                    width: 28,
                                    height: 24,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const Divider(height: 18),
                              _contactRow(
                                label: 'Số CCCD',
                                value: t.text('identity'),
                              ),
                              const Divider(height: 18),
                              const Text(
                                'Ảnh chụp CCCD (nhấn vào ảnh để phóng to)',
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: t.text('cccdFrontUrl').isEmpty
                                          ? null
                                          : () => showCccdFullDialog(
                                              context,
                                              'CCCD Mặt trước - ${t.name}',
                                              t.text('cccdFrontUrl'),
                                            ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Mặt trước',
                                            style: TextStyle(
                                              color: ink,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          cccdImageWidget(
                                            t.text('cccdFrontUrl'),
                                            height: 105,
                                            emptyLabel: 'Chưa tải mặt trước',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: t.text('cccdBackUrl').isEmpty
                                          ? null
                                          : () => showCccdFullDialog(
                                              context,
                                              'CCCD Mặt sau - ${t.name}',
                                              t.text('cccdBackUrl'),
                                            ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Mặt sau',
                                            style: TextStyle(
                                              color: ink,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          cccdImageWidget(
                                            t.text('cccdBackUrl'),
                                            height: 105,
                                            emptyLabel: 'Chưa tải mặt sau',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              InkWell(
                                onTap: () => openPage(
                                  context,
                                  TenantFullProfilePage(
                                    tenantId: tenantId,
                                    roomLabel: roomLabel,
                                    contractSummary: activeContract == null
                                        ? null
                                        : '${activeContract.text('startDate')} → ${activeContract.text('endDate')}',
                                  ),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Xem toàn bộ hồ sơ cá nhân',
                                        style: TextStyle(
                                          color: blue,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '→',
                                        style: TextStyle(
                                          color: blue,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),
                        const Text(
                          'Liên kết Hợp đồng & Phòng đang ở',
                          style: TextStyle(
                            color: ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: line, width: 0.8),
                          ),
                          child: Column(
                            children: [
                              _contactRow(
                                label: 'Phòng đang ở',
                                value: roomLabel,
                              ),
                              const Divider(height: 18),
                              _contactRow(
                                label: 'Tiền phòng',
                                value: activeContract != null
                                    ? '${money(activeContract.data['rent'])} / tháng'
                                    : (room != null
                                          ? '${money(room.data['price'])} / tháng'
                                          : ''),
                              ),
                              const Divider(height: 18),
                              _contactRow(
                                label: 'Tiền đặt cọc',
                                value: activeContract != null
                                    ? money(activeContract.data['deposit'])
                                    : (room != null
                                          ? money(room.data['deposit'])
                                          : ''),
                              ),
                              const Divider(height: 18),
                              _contactRow(
                                label: 'Ngày bắt đầu hợp đồng',
                                value: activeContract?.text('startDate') ?? '',
                              ),
                              const Divider(height: 18),
                              _contactRow(
                                label: 'Ngày kết thúc hợp đồng',
                                value: activeContract?.text('endDate') ?? '',
                              ),
                              if (sortedContracts.isNotEmpty) ...[
                                const Divider(height: 18),
                                for (final c in sortedContracts)
                                  InkWell(
                                    onTap: () => openPage(
                                      context,
                                      ContractDetailPage(contractId: c.id),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Hợp đồng ${c.text('number', c.id)}',
                                              style: const TextStyle(
                                                color: blue,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          statusPill(c.text('status')),
                                          const SizedBox(width: 8),
                                          const Text(
                                            '→',
                                            style: TextStyle(
                                              color: blue,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
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

                        const SizedBox(height: 18),
                        const Text(
                          'Hóa đơn liên kết của phòng',
                          style: TextStyle(
                            color: ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (linkedInvoices.isEmpty)
                          box(
                            const Text(
                              'Chưa có hóa đơn phát hành cho phòng này.',
                              style: TextStyle(color: muted, fontSize: 13),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: line, width: 0.8),
                            ),
                            child: Column(
                              children: [
                                for (var i = 0; i < linkedInvoices.length; i++) ...[
                                  if (i > 0) const Divider(height: 16),
                                  InkWell(
                                    onTap: () => openPage(
                                      context,
                                      InvoiceDetailPage(
                                        invoiceId: linkedInvoices[i].id,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Kỳ ${linkedInvoices[i].text('period')} • ${money(linkedInvoices[i].data['total'])}',
                                                  style: const TextStyle(
                                                    color: ink,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  linkedInvoices[i].text(
                                                    'code',
                                                    linkedInvoices[i].id,
                                                  ),
                                                  style: const TextStyle(
                                                    color: muted,
                                                    fontSize: 11.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          statusPill(
                                            linkedInvoices[i].text('status'),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.chevron_right_rounded,
                                            color: muted,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Nút "Thêm người" cố định dưới cùng
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
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
                            TenantEditPage(
                              initialRoomId: t.text('roomId').isEmpty
                                  ? null
                                  : t.text('roomId'),
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: Text(
                            room != null
                                ? 'Thêm người vào ${room.name}'
                                : 'Thêm người thuê mới',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
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

  Widget _contactRow({
    required String label,
    required String value,
    Widget? trailing,
  }) => Row(
    children: [
      Expanded(
        flex: 4,
        child: Text(
          label,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12.5),
        ),
      ),
      Expanded(
        flex: 6,
        child: Text(
          value.isEmpty ? 'Chưa cập nhật' : value,
          textAlign: trailing == null ? TextAlign.right : TextAlign.left,
          style: const TextStyle(
            color: ink,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      if (trailing != null) ...[const SizedBox(width: 8), trailing],
    ],
  );
}

class TenantFullProfilePage extends StatelessWidget {
  final String tenantId;
  final String roomLabel;
  final String? contractSummary;
  const TenantFullProfilePage({
    super.key,
    required this.tenantId,
    required this.roomLabel,
    this.contractSummary,
  });

  @override
  Widget build(BuildContext context) => DocumentView(
    collection: 'tenants',
    id: tenantId,
    builder: (t) => Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        backgroundColor: canvas,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 30, color: ink),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: const Text(
          'Thông tin chi tiết',
          style: TextStyle(
            color: ink,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          moreActionsMenu(
            iconColor: ink,
            onEdit: () => openPage(context, TenantEditPage(tenant: t)),
            onDelete: () async {
              if (await confirm(
                    context,
                    'Xóa / lưu trữ người thuê ${t.name}?',
                  ) &&
                  context.mounted) {
                await perform(
                  context,
                  () => store.command('archiveTenant', id: tenantId),
                  'Đã xóa người thuê',
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: line, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    initialAvatar(
                      t.name,
                      size: 64,
                      solidBlue: false,
                      twoLetters: true,
                      borderRadius: 20,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.name,
                            style: const TextStyle(
                              color: ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            roomLabel,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF8EE),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Text(
                              'Đang thuê',
                              style: TextStyle(
                                color: Color(0xFF16A34A),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (contractSummary != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Hợp đồng thuê: $contractSummary',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Thông tin khách thuê',
            style: TextStyle(
              color: ink,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: line, width: 0.8),
            ),
            child: Column(
              children: [
                info('Họ và Tên', t.name),
                const Divider(height: 12),
                info(
                  'Vai trò',
                  t.text('role') == 'leader' ? 'Trưởng phòng' : 'Thành viên',
                ),
                const Divider(height: 12),
                info('Ngày Sinh', t.text('birthday')),
                const Divider(height: 12),
                info('Số Điện Thoại', t.text('phone')),
                const Divider(height: 12),
                info('Email', t.text('email')),
                const Divider(height: 12),
                info('Quê Quán / Địa chỉ', t.text('address')),
                const Divider(height: 12),
                info('CCCD/Passport', t.text('identity')),
                const Divider(height: 12),
                info('UID nhận hóa đơn', t.text('authUid')),
                const Divider(height: 12),
                info('Ghi Chú', t.text('note')),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ảnh Căn cước công dân (CCCD)',
            style: TextStyle(
              color: ink,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: t.text('cccdFrontUrl').isEmpty
                      ? null
                      : () => showCccdFullDialog(
                          context,
                          'CCCD Mặt trước - ${t.name}',
                          t.text('cccdFrontUrl'),
                        ),
                  child: box(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CCCD Mặt trước',
                          style: TextStyle(
                            color: ink,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        cccdImageWidget(t.text('cccdFrontUrl'), height: 120),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: t.text('cccdBackUrl').isEmpty
                      ? null
                      : () => showCccdFullDialog(
                          context,
                          'CCCD Mặt sau - ${t.name}',
                          t.text('cccdBackUrl'),
                        ),
                  child: box(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CCCD Mặt sau',
                          style: TextStyle(
                            color: ink,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        cccdImageWidget(t.text('cccdBackUrl'), height: 120),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
