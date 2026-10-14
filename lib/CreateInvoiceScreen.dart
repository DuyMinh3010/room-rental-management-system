import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'app_colors.dart';

// man hinh tao hoa don
class InvoiceItem {
  final String label;
  final int amount;
  const InvoiceItem(this.label, this.amount);
}

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  static const String room = 'P.101';
  static const String period = '01/05/2026 - 31/05/2026';

  final List<InvoiceItem> items = const [
    InvoiceItem('Tiền phòng', 3500000),
    InvoiceItem('Điện (130 kWh)', 455000),
    InvoiceItem('Nước (10 m³)', 200000),
    InvoiceItem('WiFi', 100000),
    InvoiceItem('Đồ rác', 20000),
  ];

  final List<String> paymentMethods = const ['Chuyển khoản', 'Tiền mặt'];
  String selectedMethod = 'Chuyển khoản';

  int get total => items.fold(0, (sum, e) => sum + e.amount);

  String formatMoney(int v) {
    final s = v.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => '.',
    );
    return '${s}đ';
  }

  void _saveInvoice() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã lưu hóa đơn')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Phòng'),
                    _valueBox(room, bold: true),
                    const SizedBox(height: 16),
                    _label('Kỳ thanh toán'),
                    _valueBox(period),
                    const SizedBox(height: 20),
                    _buildDetailCard(),
                    const SizedBox(height: 20),
                    _label('Hình thức thanh toán'),
                    _buildDropdown(),
                    if (selectedMethod == 'Chuyển khoản') _buildQr(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            color: AppColors.textDark,
            onPressed: () => Navigator.maybePop(context),
          ),
          const Text(
            'Tạo hóa đơn',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _valueBox(String text, {bool bold = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildDetailCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          ...items.map((e) => _detailRow(e.label, formatMoney(e.amount))),
          _detailRow('Tổng cộng', formatMoney(total), bold: true),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: bold ? AppColors.textDark : AppColors.textMuted,
            ),
          ),
          SizedBox(
            width: 110,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedMethod,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
          items: paymentMethods
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (v) => setState(() => selectedMethod = v!),
        ),
      ),
    );
  }

  Widget _buildQr() {
    // Thay chuỗi này bằng payload VietQR thật của bạn
    final qrData = 'PHONG=$room|KY=$period|SOTIEN=$total';
    return Column(
      children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 140,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Quét mã QR để thanh toán',
          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _saveInvoice,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'Lưu hóa đơn',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
