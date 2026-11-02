import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/record.dart';

class DocumentService {
  static Future<void> printRecord(
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
            'Người thuê: ${record.text('tenantName', record.text('name'))}',
          ),
          if (contract) ...[
            pw.Text(
              'Thời hạn: ${record.text('startDate')} đến ${record.text('endDate')}',
            ),
            pw.Text('Tiền phòng: ${money(d['rent'])}/tháng'),
            pw.Text('Tiền cọc: ${money(d['deposit'])}'),
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
            if (d['bank'] is Map) ...[
              pw.Text('Ngân hàng: ${d['bank']['name'] ?? ''}'),
              pw.Text('Số tài khoản: ${d['bank']['account'] ?? ''}'),
              pw.Text('Chủ tài khoản: ${d['bank']['holder'] ?? ''}'),
            ],
          ],
        ],
      ),
    );
    await Printing.layoutPdf(
      name: '${contract ? 'hop-dong' : 'hoa-don'}-${record.id}.pdf',
      onLayout: (_) => doc.save(),
    );
  }
}
