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

  // Cho phép thay đổi kỳ thanh toán.
  String period = periodOf();

  Map<String, dynamic>? preview;
  String? previewNote;

  bool loadingPreview = false;
  bool issuing = false;

  String paymentMethod = 'bank';

  // Tránh kết quả của yêu cầu cũ ghi đè phòng/kỳ vừa chọn.
  int _previewRequest = 0;

  Future<void> _selectPeriod() async {
    if (issuing) return;

    final parts = period.split('-');
    int selectedYear = int.parse(parts[0]);
    int selectedMonth = int.parse(parts[1]);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Chọn kỳ thanh toán',
            style: TextStyle(
              color: ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Năm',
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: selectedYear,
                  isExpanded: true,
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
                  items: [
                    for (int year = 2000; year <= 2100; year++)
                      DropdownMenuItem(
                        value: year,
                        child: Text('$year'),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedYear = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tháng',
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (int month = 1; month <= 12; month++)
                      ChoiceChip(
                        label: Text(
                          'Tháng $month',
                          style: TextStyle(
                            color: selectedMonth == month ? blue : ink,
                            fontSize: 12,
                          ),
                        ),
                        selected: selectedMonth == month,
                        selectedColor: softBlue,
                        backgroundColor: Colors.white,
                        showCheckmark: false,
                        side: BorderSide(
                          color: selectedMonth == month ? blue : line,
                        ),
                        onSelected: (_) {
                          setDialogState(() => selectedMonth = month);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final selectedPeriod =
                    '$selectedYear-${selectedMonth.toString().padLeft(2, '0')}';

                Navigator.pop(dialogContext, selectedPeriod);
              },
              child: const Text('Áp dụng'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || result == null || result == period) return;

    // Vô hiệu hóa yêu cầu xem trước của kỳ cũ.
    _previewRequest++;

    setState(() {
      period = result;
      preview = null;
      previewNote = null;
      loadingPreview = false;
    });

    if (roomId != null) {
      await _autoPreview(roomId);
    }
  }

  Future<void> _autoPreview(String? targetRoomId) async {
    if (!mounted || targetRoomId == null || issuing) return;

    final targetPeriod = period;
    final request = ++_previewRequest;

    setState(() {
      loadingPreview = true;
      preview = null;
      previewNote = null;
    });

    try {
      final data = await store.command(
        'previewInvoice',
        args: {
          'roomId': targetRoomId,
          'period': targetPeriod,
        },
      );

      if (!mounted ||
          request != _previewRequest ||
          roomId != targetRoomId ||
          period != targetPeriod) {
        return;
      }

      setState(() {
        preview = data;
        previewNote = null;
      });
    } catch (e) {
      if (!mounted ||
          request != _previewRequest ||
          roomId != targetRoomId ||
          period != targetPeriod) {
        return;
      }

      setState(() {
        preview = null;
        previewNote = errorText(e);
      });
    } finally {
      if (mounted &&
          request == _previewRequest &&
          roomId == targetRoomId &&
          period == targetPeriod) {
        setState(() => loadingPreview = false);
      }
    }
  }

  Future<void> _preview() async {
    if (issuing || loadingPreview) return;

    if (roomId == null) {
      message(context, 'Vui lòng chọn phòng trước');
      return;
    }

    await _autoPreview(roomId);
  }

  Future<void> _issue() async {
    if (issuing || loadingPreview) return;

    final targetRoomId = roomId;
    final targetPeriod = period;

    if (targetRoomId == null) {
      message(context, 'Vui lòng chọn phòng cần tạo hóa đơn');
      return;
    }

    if (preview == null) {
      message(
        context,
        'Vui lòng tính được chi tiết hóa đơn trước khi phát hành',
      );
      return;
    }

    setState(() => issuing = true);

    try {
      final accepted = await confirm(
        context,
        'Phát hành hóa đơn cho kỳ $targetPeriod?',
      );

      if (!mounted || !accepted) return;

      String? issuedId;

      await perform(
        context,
        () async {
          final result = await store.command(
            'issueInvoice',
            args: {
              'roomId': targetRoomId,
              'period': targetPeriod,
            },
          );

          final id = result['id'];

          if (id is! String || id.isEmpty) {
            throw StateError('Không nhận được mã hóa đơn vừa phát hành.');
          }

          issuedId = id;
        },
        'Đã phát hành hóa đơn thành công',
      );

      if (!mounted || issuedId == null) return;

      await openPage(
        context,
        InvoiceDetailPage(invoiceId: issuedId!),
      );

      if (mounted) {
        setState(() {
          preview = null;
          previewNote =
              'Hóa đơn kỳ $targetPeriod đã được phát hành. '
              'Chọn kỳ khác nếu cần tạo hóa đơn mới.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => issuing = false);
      }
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
        icon: const Icon(
          Icons.chevron_left_rounded,
          size: 30,
          color: ink,
        ),
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

        final selectedRoomExists = activeRooms.any(
          (r) => r.id == roomId,
        );

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
                  value: selectedRoomExists ? roomId : null,
                  hint: const Text(
                    'Chọn phòng...',
                    style: TextStyle(
                      color: muted,
                      fontSize: 12.5,
                    ),
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
                      DropdownMenuItem(
                        value: r.id,
                        child: Text(r.name),
                      ),
                  ],
                  onChanged: issuing
                      ? null
                      : (value) {
                          _previewRequest++;

                          setState(() {
                            roomId = value;
                            preview = null;
                            previewNote = null;
                            loadingPreview = false;
                          });

                          _autoPreview(value);
                        },
                ),
              ),
            ),
            const SizedBox(height: 14),
            _sectionLabel('Kỳ thanh toán'),
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(
                  color: line,
                  width: 0.7,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: issuing ? null : _selectPeriod,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatPeriodRange(period),
                          style: const TextStyle(
                            color: ink,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      Text(
                        'Kỳ $period',
                        style: const TextStyle(
                          color: muted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: muted,
                        size: 20,
                      ),
                    ],
                  ),
                ),
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
                    onTap: issuing
                        ? null
                        : () async {
                            final targetRoomId = roomId;
                            final targetPeriod = period;

                            await openPage(
                              context,
                              EditForm(
                                title: 'Thêm phụ phí · $targetPeriod',
                                action: 'saveExtra',
                                submitLabel: 'Lưu phụ phí',
                                fixed: {
                                  'roomId': targetRoomId,
                                  'period': targetPeriod,
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

                            if (mounted) {
                              await _autoPreview(roomId);
                            }
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
                key: ValueKey('extras-$roomId-$period'),
                collection: 'extras',
                field: 'roomId',
                equals: roomId,
                builder: (_, xs) {
                  final list = xs
                      .where((x) => x.text('period') == period)
                      .toList();

                  if (list.isEmpty) {
                    return const SizedBox(height: 4);
                  }

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
                              border: Border.all(
                                color: line,
                                width: 0.7,
                              ),
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
                                if (!issuing)
                                  moreActionsMenu(
                                    onEdit: () async {
                                      final targetRoomId = roomId;
                                      final targetPeriod = period;

                                      await openPage(
                                        context,
                                        EditForm(
                                          title:
                                              'Sửa phụ phí · $targetPeriod',
                                          action: 'saveExtra',
                                          id: x.id,
                                          initial: x.data,
                                          submitLabel: 'Lưu phụ phí',
                                          fixed: {
                                            'roomId': targetRoomId,
                                            'period': targetPeriod,
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

                                      if (mounted) {
                                        await _autoPreview(roomId);
                                      }
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

                                      if (mounted) {
                                        await _autoPreview(roomId);
                                      }
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
                border: Border.all(
                  color: line,
                  width: 0.7,
                ),
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
                          onTap: issuing || loadingPreview
                              ? null
                              : _preview,
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
                      'Chọn phòng để tự động tính tiền phòng, điện nước '
                      'và dịch vụ từ dữ liệu Firebase. Nếu hóa đơn trước '
                      'đó đã bị hủy hoặc xóa, bạn vẫn có thể tạo lại '
                      'hóa đơn mới cho cùng kỳ.',
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                      ),
                    )
                  else if (loadingPreview)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
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
                            style: TextStyle(
                              color: muted,
                              fontSize: 12,
                            ),
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
                    for (final row in
                        (preview!['lines'] as List? ?? []))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                row['quantity'] == 1
                                    ? '${row['name']}'
                                    : '${row['name']} '
                                          '(${row['quantity']} × '
                                          '${money(row['unitPrice'])})',
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              money(row['amount']),
                              style: const TextStyle(
                                color: ink,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(
                        height: 1,
                        color: line,
                      ),
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
                          style: TextStyle(
                            color: muted,
                            fontSize: 11.5,
                          ),
                        ),
                        Text(
                          '${preview!['dueDate']}',
                          style: const TextStyle(
                            color: muted,
                            fontSize: 11.5,
                          ),
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
                border: Border.all(
                  color: line,
                  width: 0.7,
                ),
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
                  style: const TextStyle(
                    color: ink,
                    fontSize: 12.5,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'bank',
                      child: Text('Chuyển khoản'),
                    ),
                    DropdownMenuItem(
                      value: 'cash',
                      child: Text('Tiền mặt'),
                    ),
                  ],
                  onChanged: issuing
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => paymentMethod = value);
                          }
                        },
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed:
                    roomId == null ||
                        !selectedRoomExists ||
                        loadingPreview ||
                        issuing ||
                        preview == null
                    ? null
                    : _issue,
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
                child: Text(
                  issuing
                      ? 'Đang xử lý...'
                      : 'Lưu & Phát hành hóa đơn',
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}