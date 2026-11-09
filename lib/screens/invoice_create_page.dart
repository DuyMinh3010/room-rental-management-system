import 'package:flutter/material.dart';

import '../models/record.dart';
import '../widgets/common.dart';
import 'invoice_detail_page.dart';
import 'invoice_page.dart';

class InvoiceCreatePage extends StatefulWidget {
  const InvoiceCreatePage({super.key});
  @override
  State<InvoiceCreatePage> createState() => _InvoiceCreatePageState();
}

class _InvoiceCreatePageState extends State<InvoiceCreatePage> {
  String? roomId;
  final period = periodOf();
  Map<String, dynamic>? preview;
  String? previewNote;
  bool loadingPreview = false;
  String paymentMethod = 'bank';

  Future<void> _autoPreview(String? targetRoomId) async {
    if (targetRoomId == null) return;
    setState(() {
      loadingPreview = true;
      previewNote = null;
    });
    try {
      final data = await store.command(
        'previewInvoice',
        args: {'roomId': targetRoomId, 'period': period},
      );
      if (mounted && roomId == targetRoomId) {
        setState(() {
          preview = data;
          previewNote = null;
        });
      }
    } catch (e) {
      if (mounted && roomId == targetRoomId) {
        setState(() {
          preview = null;
          previewNote = errorText(e);
        });
      }
    } finally {
      if (mounted && roomId == targetRoomId) {
        setState(() => loadingPreview = false);
      }
    }
  }

  Future<void> _preview() async {
    if (roomId == null) {
      message(context, 'Vui lòng chọn phòng trước');
      return;
    }
    await perform(context, () async {
      final data = await store.command(
        'previewInvoice',
        args: {'roomId': roomId, 'period': period},
      );
      if (mounted) {
        setState(() {
          preview = data;
          previewNote = null;
        });
      }
    }, 'Đã tính hóa đơn từ dữ liệu Firebase');
  }

  Future<void> _issue() async {
    if (roomId == null) {
      message(context, 'Vui lòng chọn phòng cần tạo hóa đơn');
      return;
    }
    if (!await confirm(
      context,
      'Phát hành hóa đơn cho kỳ $period?',
    )) {
      return;
    }
    if (!mounted) return;
    await perform(context, () async {
      final result = await store.command(
        'issueInvoice',
        args: {'roomId': roomId, 'period': period},
      );
      if (mounted) {
        setState(() => preview = {...?preview, 'issuedId': result['id']});
      }
    }, 'Đã phát hành hóa đơn thành công');
    if (mounted && preview?['issuedId'] != null) {
      await openPage(
        context,
        InvoiceDetailPage(invoiceId: preview!['issuedId'] as String),
      );
    }
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      text,
      style: const TextStyle(
        color: muted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    appBar: AppBar(
      backgroundColor: canvas,
      leading: IconButton(
        icon: const Icon(Icons.chevron_left_rounded, size: 30, color: ink),
        onPressed: () => Navigator.maybePop(context),
      ),
      titleSpacing: 0,
      title: const Text(
        'Tạo hóa đơn',
        style: TextStyle(
          color: ink,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    body: RecordsView(
      collection: 'rooms',
      builder: (_, all) {
        final activeRooms = all.where((r) => !r.archived).toList()
          ..sort((a, b) => naturalCompare(a.name, b.name));
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            _sectionLabel('Phòng'),
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: line, width: 0.7),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: activeRooms.any((r) => r.id == roomId) ? roomId : null,
                  hint: const Text(
                    'Chọn phòng...',
                    style: TextStyle(color: muted, fontSize: 12.5),
                  ),
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: muted,
                    size: 20,
                  ),
                  style: const TextStyle(
                    color: ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  items: [
                    for (final r in activeRooms)
                      DropdownMenuItem(value: r.id, child: Text(r.name)),
                  ],
                  onChanged: (v) {
                    setState(() {
                      roomId = v;
                      preview = null;
                      previewNote = null;
                    });
                    _autoPreview(v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            _sectionLabel('Kỳ thanh toán'),
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: line, width: 0.7),
              ),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      formatPeriodRange(period),
                      style: const TextStyle(color: ink, fontSize: 12.5),
                    ),
                  ),
                  Text(
                    'Kỳ $period',
                    style: const TextStyle(color: muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (roomId != null) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Phụ phí phát sinh',
                    style: TextStyle(
                      color: muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await openPage(
                        context,
                        EditForm(
                          title: 'Thêm phụ phí · $period',
                          action: 'saveExtra',
                          submitLabel: 'Lưu phụ phí',
                          fixed: {'roomId': roomId, 'period': period},
                          fields: const [
                            FieldSpec('reason', 'Ghi rõ vấn đề/lý do phụ phí'),
                            FieldSpec(
                              'amount',
                              'Số tiền phụ phí (đ)',
                              number: true,
                              min: 1,
                            ),
                          ],
                        ),
                      );
                      if (mounted) _autoPreview(roomId);
                    },
                    child: const Text(
                      '+ Thêm phụ phí',
                      style: TextStyle(
                        color: blue,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              RecordsView(
                collection: 'extras',
                field: 'roomId',
                equals: roomId,
                builder: (_, xs) {
                  final list = xs
                      .where((x) => x.text('period') == period)
                      .toList();
                  if (list.isEmpty) return const SizedBox(height: 4);
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      children: [
                        for (final x in list)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: line, width: 0.7),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    x.text('reason'),
                                    style: const TextStyle(
                                      color: ink,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                                Text(
                                  money(x.data['amount']),
                                  style: const TextStyle(
                                    color: ink,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                moreActionsMenu(
                                  onEdit: () async {
                                    await openPage(
                                      context,
                                      EditForm(
                                        title: 'Sửa phụ phí · $period',
                                        action: 'saveExtra',
                                        id: x.id,
                                        initial: x.data,
                                        submitLabel: 'Lưu phụ phí',
                                        fixed: {
                                          'roomId': roomId,
                                          'period': period,
                                        },
                                        fields: const [
                                          FieldSpec(
                                            'reason',
                                            'Ghi rõ vấn đề/lý do phụ phí',
                                          ),
                                          FieldSpec(
                                            'amount',
                                            'Số tiền phụ phí (đ)',
                                            number: true,
                                            min: 1,
                                          ),
                                        ],
                                      ),
                                    );
                                    if (mounted) _autoPreview(roomId);
                                  },
                                  onDelete: () async {
                                    await perform(
                                      context,
                                      () => store.command(
                                        'deleteExtra',
                                        id: x.id,
                                      ),
                                      'Đã xóa phụ phí',
                                    );
                                    if (mounted) _autoPreview(roomId);
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
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
                      const Expanded(
                        child: Text(
                          'Chi tiết hóa đơn dự kiến',
                          style: TextStyle(
                            color: ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (roomId != null)
                        GestureDetector(
                          onTap: _preview,
                          child: const Text(
                            'Tự tính lại',
                            style: TextStyle(
                              color: blue,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (roomId == null)
                    const Text(
                      'Chọn phòng để tự động tính tiền phòng, điện nước và dịch vụ từ dữ liệu Firebase. Nếu hóa đơn trước đó đã bị hủy hoặc xóa, bạn vẫn có thể tạo lại hóa đơn mới cho cùng kỳ.',
                      style: TextStyle(color: muted, fontSize: 12),
                    )
                  else if (loadingPreview)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (preview == null)
                    Text(
                      previewNote ??
                          'Bấm "Tự tính lại" để xem trước chi tiết hóa đơn.',
                      style: const TextStyle(
                        color: Color(0xFFD97706),
                        fontSize: 12,
                      ),
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Người đại diện (Trưởng phòng)',
                            style: TextStyle(color: muted, fontSize: 12),
                          ),
                          Text(
                            '${preview!['tenantName']}',
                            style: const TextStyle(
                              color: ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final row in preview!['lines'] as List)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
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
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              money(row['amount']),
                              style: const TextStyle(color: ink, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, color: line),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tổng cộng',
                          style: TextStyle(
                            color: ink,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          money(preview!['total']),
                          style: const TextStyle(
                            color: ink,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Hạn thanh toán',
                          style: TextStyle(color: muted, fontSize: 11.5),
                        ),
                        Text(
                          '${preview!['dueDate']}',
                          style: const TextStyle(color: muted, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionLabel('Hình thức thanh toán dự kiến'),
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: line, width: 0.7),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: paymentMethod,
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: muted,
                    size: 20,
                  ),
                  style: const TextStyle(color: ink, fontSize: 12.5),
                  items: const [
                    DropdownMenuItem(value: 'bank', child: Text('Chuyển khoản')),
                    DropdownMenuItem(value: 'cash', child: Text('Tiền mặt')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => paymentMethod = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: roomId == null ? null : _issue,
                style: FilledButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Lưu & Phát hành hóa đơn'),
              ),
            ),
          ],
        );
      },
    ),
  );
}
