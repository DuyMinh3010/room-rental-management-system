import 'package:flutter/material.dart';

// Khung QR của bản UI. Thay bằng ảnh QR thật khi kết nối thanh toán.
class PaymentQrPreview extends StatelessWidget {
  final double size;
  const PaymentQrPreview({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7EAF0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_2, size: size * 0.65, color: Colors.black87),
          const Text('QR minh họa', style: TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}
