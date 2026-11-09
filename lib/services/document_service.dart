import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/record.dart';

class DocumentService {
  static Future<pw.Document> _buildDocument(
    Record record, {
    required bool contract,
  }) async {
    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/DejaVuSans.ttf'),
    );
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: font),
    );
    final d = record.data;
    final paidTimeText = record.text('paidDateTime').isNotEmpty
        ? record.text('paidDateTime')
        : formatDateTimeVi(record.time('paidAt'), record.text('paidDate'));
    final collectDeposit = d['collectDeposit'] == true;
    final depositAmt = record.number('depositCollectedAmount') ?? 0;
    final invoiceNote = record
        .text('invoiceNote', record.text('paymentNote'))
        .trim();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Header(
            level: 0,
            text: contract ? 'HỢP ĐỒNG THUÊ PHÒNG' : 'HÓA ĐƠN TIỀN PHÒNG',
          ),
          pw.Text(
            'Số: ${record.text(contract ? 'number' : 'code', record.id)}',
          ),
          pw.SizedBox(height: 12),
          pw.Text('Phòng: ${record.text('roomName', record.text('room'))}'),
          pw.Text(
            'Người đại diện (Trưởng phòng): ${record.text('tenantName', record.text('name'))}',
          ),
          if (record.text('tenantPhone').isNotEmpty)
            pw.Text('Số điện thoại: ${record.text('tenantPhone')}'),
          if (record.text('tenantIdentity').isNotEmpty)
            pw.Text('CCCD/Passport: ${record.text('tenantIdentity')}'),
          if (contract) ...[
            pw.SizedBox(height: 8),
            pw.Text('Ngày bắt đầu hợp đồng: ${record.text('startDate')}'),
            pw.Text('Ngày kết thúc hợp đồng: ${record.text('endDate')}'),
            pw.Text('Tiền phòng: ${money(d['rent'])}/tháng'),
            pw.Text('Tiền cọc: ${money(d['deposit'])}'),
            if (d['initialElectric'] != null || d['initialWater'] != null)
              pw.Text(
                'Chỉ số ban đầu lúc làm hợp đồng: Điện ${d['initialElectric'] ?? 0} kWh · Nước ${d['initialWater'] ?? 0} m³',
              ),
            pw.SizedBox(height: 16),
            pw.Text('Điều khoản / ghi chú: ${record.text('note')}'),
            pw.SizedBox(height: 40),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('CHỦ TRỌ (ký, ghi họ tên)'),
                pw.Text('NGƯỜI THUÊ (ký, ghi họ tên)'),
              ],
            ),
          ] else ...[
            pw.Text(
              'Kỳ tiền phòng: ${record.text('period')} · Chỉ số dịch vụ: ${record.text('meterPeriod')}',
            ),
            pw.Text(
              'Ngày phát hành: ${record.text('issueDate')} · Hạn: ${record.text('dueDate')}',
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: ['Nội dung', 'Số lượng', 'Đơn giá', 'Thành tiền'],
              data: [
                for (final row in (d['lines'] as List? ?? []))
                  [
                    row['name'],
                    '${row['quantity']}',
                    money(row['unitPrice']),
                    money(row['amount']),
                  ],
              ],
              cellStyle: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 16),
            pw.Text('Tổng cộng: ${money(d['total'])}'),
            pw.Text('Trạng thái: ${label(record.text('status'))}'),
            if (record.text('status') == 'paid' && paidTimeText.isNotEmpty)
              pw.Text('Ngày giờ thanh toán: $paidTimeText'),
            if (collectDeposit || depositAmt > 0)
              pw.Text('Thu tiền cọc: Đã thu (${money(depositAmt)})'),
            if (invoiceNote.isNotEmpty)
              pw.Text('Ghi chú hóa đơn: $invoiceNote'),
            if (d['bank'] is Map) ...[
              pw.SizedBox(height: 8),
              pw.Text('Ngân hàng: ${d['bank']['name'] ?? ''}'),
              pw.Text('Số tài khoản: ${d['bank']['account'] ?? ''}'),
              pw.Text('Chủ tài khoản: ${d['bank']['holder'] ?? ''}'),
            ],
          ],
        ],
      ),
    );
    return doc;
  }

  static Future<void> printRecord(
    Record record, {
    required bool contract,
  }) async {
    final doc = await _buildDocument(record, contract: contract);
    await Printing.layoutPdf(
      name: '${contract ? 'hop-dong' : 'hoa-don'}-${record.id}.pdf',
      onLayout: (_) => doc.save(),
    );
  }

  static Future<void> shareRecord(
    Record record, {
    required bool contract,
  }) async {
    final doc = await _buildDocument(record, contract: contract);
    final bytes = await doc.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${contract ? 'hop-dong' : 'hoa-don'}-${record.id}.pdf',
    );
  }

  static String formatInvoiceText(Record record) {
    final d = record.data;
    final lines = (d['lines'] as List? ?? []).whereType<Map>().toList();
    final paidTimeText = record.text('paidDateTime').isNotEmpty
        ? record.text('paidDateTime')
        : formatDateTimeVi(record.time('paidAt'), record.text('paidDate'));
    final collectDeposit = d['collectDeposit'] == true;
    final depositAmt = record.number('depositCollectedAmount') ?? 0;
    final invoiceNote = record
        .text('invoiceNote', record.text('paymentNote'))
        .trim();
    final buf = StringBuffer()
      ..writeln('=== HÓA ĐƠN TIỀN PHÒNG ===')
      ..writeln('Mã HĐ: ${record.text('code', record.id)}')
      ..writeln('Phòng: ${record.text('roomName', record.id)}')
      ..writeln('Người đại diện: ${record.text('tenantName')}')
      ..writeln('Kỳ thanh toán: ${record.text('period')}')
      ..writeln(
        'Ngày phát hành: ${record.text('issueDate')} - Hạn: ${record.text('dueDate')}',
      )
      ..writeln('--------------------------');
    for (final row in lines) {
      buf.writeln(
        '- ${row['name']}: ${row['quantity']} x ${money(row['unitPrice'])} = ${money(row['amount'])}',
      );
    }
    buf
      ..writeln('--------------------------')
      ..writeln('TỔNG CỘNG: ${money(d['total'])}')
      ..writeln('Trạng thái: ${label(record.text('status'))}');
    if (record.text('status') == 'paid' && paidTimeText.isNotEmpty) {
      buf.writeln('Ngày giờ thanh toán: $paidTimeText');
    }
    if (collectDeposit || depositAmt > 0) {
      buf.writeln('Thu tiền cọc: ${money(depositAmt)}');
    }
    if (invoiceNote.isNotEmpty) {
      buf.writeln('Ghi chú: $invoiceNote');
    }
    return buf.toString().trim();
  }
}
