import 'package:flutter/material.dart';

import '../models/record.dart';
import '../widgets/common.dart';
import 'invoice_create_page.dart';
import 'invoice_detail_page.dart';
import 'notification_page.dart';

String formatPeriodRange(String period) {
  final parts = period.split('-');
  if (parts.length != 2) return period;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (y == null || m == null) return period;
  final lastDay = DateTime(y, m + 1, 0).day.toString().padLeft(2, '0');
  final mm = m.toString().padLeft(2, '0');
  return '01/$mm/$y - $lastDay/$mm/$y';
}

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});
  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  String filter = 'all', query = '';

  Future<void> _deleteInvoice(BuildContext context, Record b) async {
    if (!await confirm(
      context,
      'Xóa hóa đơn ${b.text('code', b.id)} của phòng ${b.text('roomName')}? Sau khi xóa hoặc hủy, bạn có thể tạo lại hóa đơn mới cho phòng này trong cùng kỳ.',
    )) {
      return;
    }
    if (!context.mounted) return;
    await perform(
      context,
      () => store.command(
        'deleteInvoice',
        id: b.id,
        args: {'reason': 'Đã xóa hóa đơn'},
      ),
      'Đã xóa hóa đơn. Bạn có thể tạo lại hóa đơn mới cho kỳ này.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = periodOf();
    final parts = currentMonth.split('-');
    final monthSubtitle = parts.length == 2
        ? 'Tháng ${parts[1]}/${parts[0]}'
        : currentMonth;

    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        backgroundColor: canvas,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hóa đơn',
              style: TextStyle(
                color: ink,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              monthSubtitle,
              style: const TextStyle(
                color: muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          const NotificationButton(),
          Center(
            child: figmaPrimaryPillButton(
              label: '+ Tạo mới',
              soft: true,
              onTap: () => openPage(context, const InvoiceCreatePage()),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: RecordsView(
        collection: 'invoices',
        builder: (_, rawAll) {
          final all = rawAll.where((b) => !b.archived).toList();
          final bills = all
              .where(
                (b) =>
                    (filter == 'all' || b.text('status') == filter) &&
                    '${b.text('code')} ${b.text('roomName')} ${b.text('tenantName')} ${b.text('period')}'
                        .toLowerCase()
                        .contains(query.toLowerCase()),
              )
              .toList();
          bills.sort(
            (a, b) => b.text('issueDate').compareTo(a.text('issueDate')),
          );
          final unpaidBills = all.where(
            (b) => ['unpaid', 'reported'].contains(b.text('status')),
          );
          final paidCount = all.where((b) => b.text('status') == 'paid').length;
          final unpaidCount = unpaidBills.length;
          final debt = unpaidBills.fold<num>(
            0,
            (sum, b) => sum + (b.number('total') ?? 0),
          );
          const filters = [
            ('all', 'Tất cả'),
            ('unpaid', 'Chưa thanh toán'),
            ('reported', 'Chờ xác nhận'),
            ('paid', 'Đã thanh toán'),
            ('void', 'Đã hủy'),
          ];

          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tổng cần thu',
                      style: TextStyle(
                        color: Color(0xFFDCE8FF),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      money(debt),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$paidCount đã thanh toán  •  $unpaidCount chưa thanh toán',
                      style: const TextStyle(
                        color: Color(0xFFE0ECFF),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => setState(() => query = v),
                decoration: searchDecoration(
                  'Tìm kiếm phòng, người thuê, mã hóa đơn...',
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final item in filters)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: figmaFilterPill(
                          label: item.$2,
                          selected: filter == item.$1,
                          onTap: () => setState(() => filter = item.$1),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (bills.isEmpty) empty('Chưa có hóa đơn'),
              for (final b in bills)
                Builder(
                  builder: (context) {
                    final unpaid = [
                      'unpaid',
                      'reported',
                    ].contains(b.text('status'));
                    final paidTimeText = b.text('paidDateTime').isNotEmpty
                        ? b.text('paidDateTime')
                        : formatDateTimeVi(
                            b.time('paidAt'),
                            b.text('paidDate'),
                          );
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
                          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${b.text('roomName')}  •  ${b.text('code', b.id)}',
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
                                    onDelete: () => _deleteInvoice(context, b),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${b.text('tenantName')}  •  ${formatPeriodRange(b.text('period'))}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                b.text('status') == 'paid' &&
                                        paidTimeText.isNotEmpty
                                    ? 'Ngày giờ thanh toán: $paidTimeText'
                                    : 'Hạn thanh toán: ${b.text('dueDate')}',
                                style: TextStyle(
                                  color: b.text('status') == 'paid'
                                      ? const Color(0xFF16A34A)
                                      : muted,
                                  fontSize: 10.5,
                                  fontWeight: b.text('status') == 'paid'
                                      ? FontWeight.w600
                                      : FontWeight.w400,
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
                                        borderRadius: BorderRadius.circular(13),
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
    );
  }
}
