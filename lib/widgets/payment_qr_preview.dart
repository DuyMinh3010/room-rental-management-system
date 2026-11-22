import 'package:flutter/material.dart';

class PaymentQrPreview extends StatelessWidget {
  final double size;
  final double outerPadding;
  const PaymentQrPreview({
    super.key,
    this.size = 120,
    this.outerPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + outerPadding * 2,
      height: size + outerPadding * 2,
      padding: EdgeInsets.all(outerPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Image.asset(
        'assets/images/payment_qr.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Icon(
          Icons.qr_code_2_rounded,
          size: size * 0.85,
          color: const Color(0xFF111827),
        ),
      ),
    );
  }
}
