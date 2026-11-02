import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/record.dart';
import '../services/document_service.dart';
import '../widgets/common.dart';
import '../widgets/payment_qr_preview.dart';
import 'invoice_page.dart';

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

  Future<void> _confirmPaid(BuildContext context) async {
    final method = await showDialog<String>(
      context: context,
      builder: (c) => SimpleDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Đã kiểm tra và nhận đủ tiền?',
          style: TextStyle(
            color: ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(c, 'bank'),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text('Xác nhận đã nhận chuyển khoản'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(c, 'cash'),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text('Xác nhận đã nhận tiền mặt'),
            ),
          ),
        ],
      ),
    );
    if (method != null && context.mounted) {
      await perform(
        context,
        () => store.command(
          'confirmPayment',
          id: invoiceId,
          args: {'method': method},
        ),
        'Đã xác nhận và tạo thông báo thanh toán',
      );
    }
  }

  @override
  Widget build(BuildContext context) => DocumentView(
    collection: 'invoices',
    id: invoiceId,
    builder: (bill) {
      final bank = bill.data['bank'] is Map
          ? bill.data['bank'] as Map
          : const {};
      final lines = bill.data['lines'] as List? ?? [];
      final status = bill.text('status');
      final canLandlordConfirm =
          landlord && ['unpaid', 'reported'].contains(status);
      final canTenantReport = !landlord && status == 'unpaid';

      return Scaffold(
        backgroundColor: canvas,
        appBar: AppBar(
          backgroundColor: canvas,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 30, color: ink),
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
            const SizedBox(width: 6),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // Card 1: Summary Card (Frame 27)
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
                            Text(
                              'Phòng ${bill.text('roomName')}',
                              style: const TextStyle(
                                color: blue,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      statusPill(status),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, color: line),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 17,
                        color: muted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Người thuê: ${bill.text('tenantName')}',
                          style: const TextStyle(
                            color: ink,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
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
                          style: const TextStyle(color: muted, fontSize: 13.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: muted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hạn thanh toán: ${bill.text('dueDate')}  •  HĐ: ${bill.text('contractNumber')}',
                          style: const TextStyle(color: muted, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card 2: Breakdown Card (Frame 27)
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
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card 3: Payment Info Box (Frame 27)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: line),
              ),
              child: Column(
                children: [
                  const Text(
                    'Hình thức thanh toán',
                    style: TextStyle(
                      color: muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    bill.text('method').isNotEmpty
                        ? label(bill.text('method'))
                        : 'Chuyển khoản Ngân hàng',
                    style: const TextStyle(
                      color: ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const PaymentQrPreview(size: 120, outerPadding: 16),
                  const SizedBox(height: 14),
                  const Text(
                    'Quét mã QR để thực hiện giao dịch nhanh chóng',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
                  if ('${bank['account'] ?? ''}'.isNotEmpty ||
                      '${bank['name'] ?? ''}'.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(height: 1, color: line),
                    ),
                    info('Ngân hàng', '${bank['name'] ?? ''}'),
                    info('Số tài khoản', '${bank['account'] ?? ''}'),
                    info('Chủ tài khoản', '${bank['holder'] ?? ''}'),
                    info('Nội dung CK', bill.text('code', bill.id)),
                  ],
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(
                          text:
                              '${bank['name'] ?? ''}\n${bank['account'] ?? ''}\n${bank['holder'] ?? ''}\n${money(bill.data['total'])}\n${bill.text('code', bill.id)}',
                        ),
                      );
                      if (context.mounted) {
                        message(context, 'Đã sao chép thông tin chuyển khoản');
                      }
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Sao chép thông tin thanh toán'),
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
                  'Lý do hủy: ${bill.text('voidReason')}',
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 12.5,
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
                          () => store.command('resendInvoice', id: invoiceId),
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
                    if (canLandlordConfirm) ...[
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () async {
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
                            );
                          }
                        },
                        child: const Text(
                          'Hủy hóa đơn',
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.w600,
                          ),
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
                          await _confirmPaid(context);
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
                            ? 'Xác nhận đã thanh toán'
                            : 'Tôi đã chuyển tiền – báo chủ trọ',
                      ),
                    ),
                  ),
                ),
              )
            : null,
      );
    },
  );
}
