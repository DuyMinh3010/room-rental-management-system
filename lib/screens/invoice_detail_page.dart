import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../widgets/form_widgets.dart';
import '../widgets/payment_qr_preview.dart';
import 'room_page.dart';

class InvoiceDetailPage extends StatefulWidget {
  final Map<String, String> invoice;
  const InvoiceDetailPage({super.key, required this.invoice});
  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  Future<void> _pay() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đã thanh toán'),
        content: const Text(
          'Đánh dấu hóa đơn đã thanh toán trong dữ liệu mẫu?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (!mounted || yes != true) return;
    setState(() => widget.invoice['status'] = 'Đã thanh toán');
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.invoice;
    final paid = b['status'] == 'Đã thanh toán';
    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(title: const Text('Chi tiết hóa đơn')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InfoCard(
            title: b['id']!,
            children: [
              InfoLine('Phòng', b['room']!),
              Text(
                b['status']!,
                style: TextStyle(color: paid ? Colors.green : Colors.orange),
              ),
              InfoLine('Người thuê', b['tenant'] ?? ''),
              InfoLine('Kỳ thanh toán', b['period'] ?? ''),
            ],
          ),
          InfoCard(
            title: 'Chi tiết khoản phí',
            children: [
              InfoLine('Tiền phòng', money(b['rent'])),
              InfoLine('Điện', money(b['electric'])),
              InfoLine('Nước', money(b['water'])),
              InfoLine('WiFi', money(b['wifi'])),
              InfoLine('Đổ rác', money(b['trash'])),
              const Divider(),
              InfoLine('Tổng cộng', b['price']!),
            ],
          ),
          InfoCard(
            title: 'Hình thức thanh toán',
            children: [
              Text(b['method'] ?? 'Chuyển khoản'),
              const SizedBox(height: 20),
              if (b['method'] != 'Tiền mặt') ...[
                Center(child: const PaymentQrPreview(size: 120)),
                const SizedBox(height: 12),
                const Text(
                  'Mã QR sẽ được cung cấp khi kết nối thanh toán.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ],
          ),
          if (!paid)
            FilledButton(
              onPressed: _pay,
              child: const Text('Xác nhận đã thanh toán'),
            ),
        ],
      ),
      bottomNavigationBar: const AppBottomBar(selected: 3),
    );
  }
}
