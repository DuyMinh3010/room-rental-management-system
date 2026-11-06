import 'package:flutter/material.dart';

import '../models/record.dart';
import '../widgets/common.dart';
import 'contract_detail_page.dart';
import 'tenant_edit_page.dart';

class TenantDetailPage extends StatelessWidget {
  final String tenantId;
  const TenantDetailPage({super.key, required this.tenantId});

  Future<void> _linkUid(BuildContext context, Record t) async {
    final controller = TextEditingController(text: t.text('authUid'));
    final authUid = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Liên kết tài khoản nhận hóa đơn'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'UID sao chép từ Authentication → Users',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, controller.text.trim()),
            child: const Text('Liên kết'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (authUid != null && context.mounted) {
      await perform(
        context,
        () => store.command(
          'linkTenantAccount',
          id: tenantId,
          args: {'authUid': authUid},
        ),
      );
    }
  }

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
        builder: (_, cs) {
          final room = rooms.where((r) => r.id == t.text('roomId')).firstOrNull;
          final sortedContracts =
              cs
                  .where(
                    (c) =>
                        c.text('tenantId') == tenantId ||
                        c.strings('tenantIds').contains(tenantId),
                  )
                  .toList()
                ..sort(
                  (a, b) => b.text('startDate').compareTo(a.text('startDate')),
                );
          final activeContract =
              sortedContracts
                  .where(
                    (c) => ['active', 'scheduled'].contains(c.text('status')),
                  )
                  .firstOrNull ??
              sortedContracts.firstOrNull;
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
                'Thông tin thuê phòng',
                style: TextStyle(
                  color: ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                Center(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(17),
                    onTap: () => openPage(context, TenantEditPage(tenant: t)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: softBlue,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Text(
                        'Chỉnh sửa',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: [
                // Summary Card (Frame 7)
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
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEAF8EE),
                                        borderRadius: BorderRadius.circular(13),
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
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isLeader
                                              ? softBlue
                                              : const Color(0xFFECFDF3),
                                          borderRadius: BorderRadius.circular(
                                            13,
                                          ),
                                        ),
                                        child: Text(
                                          isLeader
                                              ? 'Trưởng phòng'
                                              : 'Thành viên',
                                          style: TextStyle(
                                            color: isLeader ? blue : muted,
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
                          'Hợp đồng thuê: ${activeContract.text('startDate')} → ${activeContract.text('endDate')}',
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
                  'Thông tin liên hệ',
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
                      _contactRow(label: 'CCCD', value: t.text('identity')),
                      const Divider(height: 18),
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
                                'Xem chi tiết',
                                style: TextStyle(color: ink, fontSize: 13),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '→',
                                style: TextStyle(
                                  color: ink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Text(
                  'Thông tin thuê phòng',
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
                            : (room != null ? money(room.data['deposit']) : ''),
                      ),
                      const Divider(height: 18),
                      _contactRow(
                        label: 'Ngày bắt đầu thuê:',
                        value: activeContract?.text('startDate') ?? '',
                      ),
                      const Divider(height: 18),
                      _contactRow(
                        label: 'Ngày kết thúc :',
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
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Xem chi tiết (${c.text('number', c.id)})',
                                      style: const TextStyle(
                                        color: ink,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  statusPill(c.text('status')),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '→',
                                    style: TextStyle(
                                      color: ink,
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

                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _linkUid(context, t),
                  icon: const Icon(Icons.link_rounded, size: 18),
                  label: Text(
                    t.text('authUid').isEmpty
                        ? 'Liên kết tài khoản nhận hóa đơn'
                        : 'UID đã liên kết: ${t.text('authUid')}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () async {
                    if (await confirm(
                          context,
                          'Lưu trữ người thuê? Không xóa lịch sử hợp đồng.',
                        ) &&
                        context.mounted) {
                      await perform(
                        context,
                        () => store.command('archiveTenant', id: tenantId),
                      );
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    'Lưu trữ người thuê',
                    style: TextStyle(color: Color(0xFFDC2626)),
                  ),
                ),
              ],
            ),
          );
        },
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

// Frame 8: 09 · Thông tin chi tiết người thuê
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
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(17),
              onTap: () => openPage(context, TenantEditPage(tenant: t)),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: softBlue,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Text(
                  'Chỉnh sửa',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
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
        ],
      ),
    ),
  );
}
