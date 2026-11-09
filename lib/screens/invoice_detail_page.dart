import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/record.dart';
import '../services/document_service.dart';
import '../widgets/common.dart';
import 'contract_detail_page.dart';
import 'invoice_page.dart';
import 'room_detail_page.dart';
import 'tenant_detail_page.dart';

class InvoiceDetailPage extends StatelessWidget {
  final String invoiceId;
  final bool landlord;
  const InvoiceDetailPage({
    super.key,
    required this.invoiceId,
    this.landlord = true,
  });

  Future<String?> _input(BuildContext context, String title) async {
    final c = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          title,
          style: const TextStyle(
            color: ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: c,
          decoration: InputDecoration(
            hintText: 'Nhập nội dung...',
            filled: true,
            fillColor: canvas,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    c.dispose();
    return result;
  }

  Future<void> _showShareOptions(BuildContext context, Record bill) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chia sẻ hóa đơn',
                style: TextStyle(
                  color: ink,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: softBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.picture_as_pdf_outlined, color: blue),
                ),
                title: const Text(
                  'Chia sẻ file PDF hóa đơn',
                  style: TextStyle(
                    color: ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Gửi PDF qua Zalo, Messenger, Email hoặc lưu về máy',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await perform(
                    context,
                    () => DocumentService.shareRecord(bill, contract: false),
                    'Đã mở hộp thoại chia sẻ PDF',
                  );
                },
              ),
              const Divider(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.copy_all_rounded,
                    color: Color(0xFF16A34A),
                  ),
                ),
                title: const Text(
                  'Sao chép toàn bộ nội dung hóa đơn',
                  style: TextStyle(
                    color: ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Copy chi tiết hóa đơn dạng văn bản để dán gửi nhanh',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Clipboard.setData(
                    ClipboardData(text: DocumentService.formatInvoiceText(bill)),
                  );
                  if (context.mounted) {
                    message(context, 'Đã sao chép nội dung hóa đơn vào bộ nhớ tạm');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmPaid(
    BuildContext context,
    Record bill, {
    num suggestedDeposit = 0,
  }) async {
    String method = 'bank';
    bool collectDeposit = bill.data['collectDeposit'] == true;
    final defaultDep =
        bill.number('depositCollectedAmount') ??
        bill.number('deposit') ??
        suggestedDeposit;
    final depCtrl = TextEditingController(
      text: defaultDep > 0 ? '${defaultDep.round()}' : '0',
    );
    final noteCtrl = TextEditingController(
      text: bill.text('invoiceNote', bill.text('paymentNote')),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Xác nhận thanh toán hóa đơn',
            style: TextStyle(
              color: ink,
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hình thức thanh toán',
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: method,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: canvas,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'bank', child: Text('Chuyển khoản')),
                    DropdownMenuItem(value: 'cash', child: Text('Tiền mặt')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => method = v);
                  },
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: blue,
                  value: collectDeposit,
                  title: const Text(
                    'Thu tiền cọc',
                    style: TextStyle(
                      color: ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Đánh dấu đã thu tiền đặt cọc kèm hóa đơn này',
                    style: TextStyle(color: muted, fontSize: 11.5),
                  ),
                  onChanged: (v) =>
                      setDialogState(() => collectDeposit = v == true),
                ),
                if (collectDeposit) ...[
                  const SizedBox(height: 4),
                  TextField(
                    controller: depCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Số tiền cọc đã thu (đ)',
                      filled: true,
                      fillColor: canvas,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Thêm ghi chú cho hóa đơn',
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Nhập ghi chú thanh toán / tiền cọc...',
                    filled: true,
                    fillColor: canvas,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xác nhận đã thu'),
            ),
          ],
        ),
      ),
    );

    final depAmount =
        num.tryParse(
          depCtrl.text.trim().replaceAll('.', '').replaceAll(',', ''),
        ) ??
        0;
    final noteText = noteCtrl.text.trim();
    depCtrl.dispose();
    noteCtrl.dispose();

    if (confirmed == true && context.mounted) {
      await perform(
        context,
        () => store.command(
          'confirmPayment',
          id: invoiceId,
          args: {
            'method': method,
            'collectDeposit': collectDeposit,
            'depositCollectedAmount': collectDeposit ? depAmount : 0,
            'invoiceNote': noteText,
          },
        ),
        'Đã xác nhận thanh toán và lưu thông tin tiền cọc / ghi chú',
      );
    }
  }

  Future<void> _editDepositAndNote(
    BuildContext context,
    Record bill, {
    num suggestedDeposit = 0,
  }) async {
    bool collectDeposit = bill.data['collectDeposit'] == true;
    final defaultDep =
        bill.number('depositCollectedAmount') ??
        bill.number('deposit') ??
        suggestedDeposit;
    final depCtrl = TextEditingController(
      text: defaultDep > 0 ? '${defaultDep.round()}' : '0',
    );
    final noteCtrl = TextEditingController(
      text: bill.text('invoiceNote', bill.text('paymentNote')),
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Thu tiền cọc & Ghi chú hóa đơn',
            style: TextStyle(
              color: ink,
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: blue,
                  value: collectDeposit,
                  title: const Text(
                    'Thu tiền cọc',
                    style: TextStyle(
                      color: ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Xác nhận đã thu tiền cọc cho hóa đơn này',
                    style: TextStyle(color: muted, fontSize: 11.5),
                  ),
                  onChanged: (v) =>
                      setDialogState(() => collectDeposit = v == true),
                ),
                if (collectDeposit) ...[
                  const SizedBox(height: 6),
                  TextField(
                    controller: depCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Số tiền cọc đã thu (đ)',
                      filled: true,
                      fillColor: canvas,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Thêm ghi chú',
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Nhập ghi chú cho hóa đơn...',
                    filled: true,
                    fillColor: canvas,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Lưu lại'),
            ),
          ],
        ),
      ),
    );

    final depAmount =
        num.tryParse(
          depCtrl.text.trim().replaceAll('.', '').replaceAll(',', ''),
        ) ??
        0;
    final noteText = noteCtrl.text.trim();
    depCtrl.dispose();
    noteCtrl.dispose();

    if (saved == true && context.mounted) {
      await perform(
        context,
        () => store.command(
          'updateInvoicePaymentMeta',
          id: invoiceId,
          args: {
            'collectDeposit': collectDeposit,
            'depositCollectedAmount': collectDeposit ? depAmount : 0,
            'invoiceNote': noteText,
          },
        ),
        'Đã cập nhật tiền cọc và ghi chú hóa đơn',
      );
    }
  }

  @override
  Widget build(BuildContext context) => DocumentView(
    collection: 'invoices',
    id: invoiceId,
    builder: (bill) => RecordsView(
      collection: 'tenants',
      builder: (_, tenants) => RecordsView(
        collection: 'contracts',
        builder: (_, contracts) {
          final bank = bill.data['bank'] is Map
              ? bill.data['bank'] as Map
              : const {};
          final lines = bill.data['lines'] as List? ?? [];
          final status = bill.text('status');
          final canLandlordConfirm =
              landlord && ['unpaid', 'reported'].contains(status);
          final canTenantReport = !landlord && status == 'unpaid';

          final linkedTenant = tenants
              .where((t) => t.id == bill.text('tenantId'))
              .firstOrNull;
          final linkedContract = contracts
              .where((c) => c.id == bill.text('contractId'))
              .firstOrNull;
          final tenantName =
              linkedTenant?.name ?? bill.text('tenantName', 'Chưa cập nhật');
          final tenantPhone =
              linkedTenant?.text('phone') ?? bill.text('tenantPhone');
          final tenantIdentity =
              linkedTenant?.text('identity') ?? bill.text('tenantIdentity');
          final suggestedDeposit =
              bill.number('deposit') ?? linkedContract?.number('deposit') ?? 0;

          final paidDateTimeText = bill.text('paidDateTime').isNotEmpty
              ? bill.text('paidDateTime')
              : formatDateTimeVi(
                  bill.time('paidAt'),
                  bill.text('paidDate').isNotEmpty
                      ? '${bill.text('paidDate')} 00:00'
                      : '',
                );
          final collectDeposit = bill.data['collectDeposit'] == true;
          final depositCollectedAmount =
              bill.number('depositCollectedAmount') ?? 0;
          final invoiceNote = bill
              .text('invoiceNote', bill.text('paymentNote'))
              .trim();

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
                'Chi tiết hóa đơn',
                style: TextStyle(
                  color: ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'In / xuất PDF hóa đơn',
                  icon: const Icon(Icons.print_outlined, color: ink, size: 22),
                  onPressed: () => perform(
                    context,
                    () => DocumentService.printRecord(bill, contract: false),
                    'Đã mở bản in',
                  ),
                ),
                IconButton(
                  tooltip: 'Chia sẻ hóa đơn',
                  icon: const Icon(Icons.share_outlined, color: blue, size: 21),
                  onPressed: () => _showShareOptions(context, bill),
                ),
                if (landlord)
                  moreActionsMenu(
                    iconColor: ink,
                    editLabel: 'Sửa cọc / ghi chú',
                    onEdit: () => _editDepositAndNote(
                      context,
                      bill,
                      suggestedDeposit: suggestedDeposit,
                    ),
                    extras: [
                      if (canLandlordConfirm)
                        MoreMenuItem(
                          value: 'void',
                          label: 'Hủy hóa đơn',
                          icon: Icons.cancel_outlined,
                          color: const Color(0xFFD97706),
                          onTap: () async {
                            final reason = await _input(
                              context,
                              'Ghi rõ lý do hủy hóa đơn',
                            );
                            if (reason != null &&
                                reason.isNotEmpty &&
                                context.mounted) {
                              await perform(
                                context,
                                () => store.command(
                                  'voidInvoice',
                                  id: invoiceId,
                                  args: {'reason': reason},
                                ),
                                'Đã hủy hóa đơn. Bạn có thể tạo lại hóa đơn mới cho phòng này.',
                              );
                            }
                          },
                        ),
                    ],
                    onDelete: () async {
                      if (await confirm(
                            context,
                            'Xóa hóa đơn ${bill.text('code', bill.id)}? Sau khi xóa bạn có thể tạo lại hóa đơn mới cho phòng này trong cùng kỳ.',
                          ) &&
                          context.mounted) {
                        await perform(
                          context,
                          () => store.command(
                            'deleteInvoice',
                            id: invoiceId,
                            args: {'reason': 'Đã xóa hóa đơn'},
                          ),
                          'Đã xóa hóa đơn',
                        );
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  ),
                const SizedBox(width: 6),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // Card 1: Summary Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bill.text('code', bill.id),
                                  style: const TextStyle(
                                    color: ink,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: bill.text('roomId').isEmpty
                                      ? null
                                      : () => openPage(
                                          context,
                                          RoomDetailPage(
                                            roomId: bill.text('roomId'),
                                          ),
                                        ),
                                  child: Text(
                                    'Phòng ${bill.text('roomName')}',
                                    style: const TextStyle(
                                      color: blue,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          statusPill(status),
                        ],
                      ),
                      if (status == 'paid' && paidDateTimeText.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: Color(0xFF16A34A),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Ngày giờ thanh toán: $paidDateTimeText',
                                  style: const TextStyle(
                                    color: Color(0xFF15803D),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(height: 1, color: line),
                      ),
                      InkWell(
                        onTap: linkedTenant == null
                            ? null
                            : () => openPage(
                                context,
                                TenantDetailPage(tenantId: linkedTenant.id),
                              ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              size: 17,
                              color: muted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Người đại diện: $tenantName${tenantPhone.isNotEmpty ? ' • $tenantPhone' : ''}',
                                style: const TextStyle(
                                  color: ink,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (linkedTenant != null)
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: blue,
                              ),
                          ],
                        ),
                      ),
                      if (tenantIdentity.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.badge_outlined,
                              size: 16,
                              color: muted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'CCCD: $tenantIdentity',
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: muted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Kỳ thanh toán: ${formatPeriodRange(bill.text('period'))}',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: linkedContract == null
                            ? null
                            : () => openPage(
                                context,
                                ContractDetailPage(
                                  contractId: linkedContract.id,
                                ),
                              ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 16,
                              color: muted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Hạn thanh toán: ${bill.text('dueDate')}  •  HĐ: ${bill.text('contractNumber', bill.text('contractId'))}',
                                style: const TextStyle(
                                  color: blue,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Khu vực nút In & Chia sẻ nằm cạnh nhau
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => perform(
                                context,
                                () => DocumentService.printRecord(
                                  bill,
                                  contract: false,
                                ),
                                'Đã mở bản in',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ink,
                                side: const BorderSide(color: line),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.print_outlined, size: 18),
                              label: const Text('In hóa đơn'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _showShareOptions(context, bill),
                              style: FilledButton.styleFrom(
                                backgroundColor: softBlue,
                                foregroundColor: blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.share_outlined, size: 18),
                              label: const Text('Chia sẻ'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Card 2: Breakdown Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chi tiết khoản phí',
                        style: TextStyle(
                          color: ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      for (final row in lines)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  row['quantity'] == 1
                                      ? '${row['name']}'
                                      : '${row['name']} (${row['quantity']} × ${money(row['unitPrice'])})',
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                money(row['amount']),
                                style: const TextStyle(
                                  color: ink,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: line),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tổng cộng',
                            style: TextStyle(
                              color: ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            money(bill.data['total']),
                            style: const TextStyle(
                              color: ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Card 3: Thu tiền cọc & Ghi chú hóa đơn (Hiển thị và cho phép cập nhật cả trước và sau thanh toán)
                Container(
                  padding: const EdgeInsets.all(20),
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
                              'Thu tiền cọc & Ghi chú hóa đơn',
                              style: TextStyle(
                                color: ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (landlord)
                            TextButton.icon(
                              onPressed: () => _editDepositAndNote(
                                context,
                                bill,
                                suggestedDeposit: suggestedDeposit,
                              ),
                              icon: const Icon(Icons.edit_note_rounded, size: 18),
                              label: const Text('Cập nhật'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      info(
                        'Trạng thái thu tiền cọc',
                        collectDeposit || depositCollectedAmount > 0
                            ? 'Đã thu tiền cọc (${money(depositCollectedAmount)})'
                            : 'Chưa thu tiền cọc kèm hóa đơn này',
                        boldValue: collectDeposit,
                      ),
                      info(
                        'Ghi chú hóa đơn',
                        invoiceNote.isEmpty ? 'Chưa có ghi chú' : invoiceNote,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Card 4: Payment Info Box (Đã bỏ hoàn toàn mã QR)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin thanh toán',
                        style: TextStyle(
                          color: ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      info(
                        'Hình thức thanh toán',
                        bill.text('method').isNotEmpty
                            ? label(bill.text('method'))
                            : 'Chuyển khoản / Tiền mặt',
                      ),
                      if (status == 'paid' && paidDateTimeText.isNotEmpty)
                        info(
                          'Ngày giờ thanh toán',
                          paidDateTimeText,
                          boldValue: true,
                        ),
                      if ('${bank['account'] ?? ''}'.isNotEmpty ||
                          '${bank['name'] ?? ''}'.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1, color: line),
                        ),
                        info('Ngân hàng', '${bank['name'] ?? ''}'),
                        info('Số tài khoản', '${bank['account'] ?? ''}'),
                        info('Chủ tài khoản', '${bank['holder'] ?? ''}'),
                        info('Nội dung CK', bill.text('code', bill.id)),
                      ],
                      const SizedBox(height: 6),
                      Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(
                                text:
                                    '${bank['name'] ?? ''}\n${bank['account'] ?? ''}\n${bank['holder'] ?? ''}\n${money(bill.data['total'])}\n${bill.text('code', bill.id)}',
                              ),
                            );
                            if (context.mounted) {
                              message(
                                context,
                                'Đã sao chép thông tin chuyển khoản',
                              );
                            }
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Sao chép thông tin chuyển khoản'),
                        ),
                      ),
                    ],
                  ),
                ),

                if (status == 'reported') ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: Text(
                      'Người thuê đã báo chuyển tiền. Chủ trọ vui lòng kiểm tra giao dịch.\n${bill.text('paymentNote')}',
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],

                if (status == 'void') ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDECEC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Hóa đơn đã hủy. Lý do: ${bill.text('voidReason')}\n(Bạn có thể tạo lại hóa đơn mới cho phòng này trong cùng kỳ)',
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                if (landlord) ...[
                  const SizedBox(height: 14),
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
                        info(
                          'Trạng thái gửi',
                          bill.text('recipientUid').isEmpty
                              ? 'Chưa liên kết tài khoản'
                              : 'Đã gửi vào hộp thư người thuê',
                        ),
                        if (status != 'void') ...[
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () => perform(
                              context,
                              () => store.command(
                                'resendInvoice',
                                id: invoiceId,
                              ),
                              'Đã gửi vào hộp thư người thuê',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: blue,
                              side: const BorderSide(color: blue),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Gửi / gửi lại hóa đơn cho người thuê',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
            bottomNavigationBar: (canLandlordConfirm || canTenantReport)
                ? Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: line)),
                    ),
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: () async {
                            if (canLandlordConfirm) {
                              await _confirmPaid(
                                context,
                                bill,
                                suggestedDeposit: suggestedDeposit,
                              );
                            } else {
                              final note = await _input(
                                context,
                                'Ghi chú giao dịch đã chuyển',
                              );
                              if (note != null && context.mounted) {
                                await perform(
                                  context,
                                  () => store.reportPayment(invoiceId, note),
                                  'Đã báo chủ trọ; đang chờ kiểm tra',
                                );
                              }
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Text(
                            canLandlordConfirm
                                ? 'Xác nhận đã thanh toán (kèm Cọc / Ghi chú)'
                                : 'Tôi đã chuyển tiền – báo chủ trọ',
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
          );
        },
      ),
    ),
  );
}
