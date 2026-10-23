import 'package:flutter/material.dart';

import '../widgets/form_widgets.dart';
import '../widgets/payment_qr_preview.dart';
import 'room_page.dart';
import '../utils/formatters.dart';

class InvoiceCreatePage extends StatefulWidget {
  const InvoiceCreatePage({super.key});
  @override
  State<InvoiceCreatePage> createState() => _InvoiceCreatePageState();
}

class _InvoiceCreatePageState extends State<InvoiceCreatePage> {
  final formKey = GlobalKey<FormState>();
  final period = TextEditingController();
  final rent = TextEditingController();
  final electric = TextEditingController();
  final water = TextEditingController();
  final wifi = TextEditingController();
  final trash = TextEditingController();
  String? room;
  String method = 'Chuyển khoản';
  int get electricFee => (int.tryParse(electric.text) ?? 0) * 3500;
  int get waterFee => (int.tryParse(water.text) ?? 0) * 20000;
  int get total =>
      (int.tryParse(rent.text) ?? 0) +
      electricFee +
      waterFee +
      (int.tryParse(wifi.text) ?? 0) +
      (int.tryParse(trash.text) ?? 0);
  @override
  void initState() {
    super.initState();
    for (final c in [rent, electric, water, wifi, trash]) {
      c.addListener(_refresh);
    }
  }

  void _refresh() {
    setState(() {});
  }

  @override
  void dispose() {
    for (final c in [period, rent, electric, water, wifi, trash]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!formKey.currentState!.validate()) return;
    if (room == null || room!.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Vui lòng chọn phòng.')));
      return;
    }
    Navigator.pop(context, <String, String>{
      'id': 'HD-${DateTime.now().millisecondsSinceEpoch}',
      'room': room!,
      'tenant': 'Chưa có người thuê',
      'period': period.text.trim(),
      'rent': rent.text,
      'electric': '$electricFee',
      'water': '$waterFee',
      'wifi': wifi.text,
      'trash': trash.text,
      'price': money('$total'),
      'status': 'Chưa thanh toán',
      'method': method,
    });
  }

  @override
  Widget build(BuildContext context) {
    final names = roomList.map((r) => r['name']!).toList();
    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(title: const Text('Tạo hóa đơn')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<String>(
              initialValue: room,
              decoration: const InputDecoration(labelText: 'Phòng'),
              items: names
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  room = v;
                  rent.text = roomList
                      .firstWhere((r) => r['name'] == v)['price']!
                      .split('/')
                      .first
                      .replaceAll(RegExp(r'[^0-9]'), '');
                });
              },
            ),
            const SizedBox(height: 20),
            FormInput('Kỳ thanh toán', period),
            InfoCard(
              title: 'Chi tiết',
              children: [
                FormInput('Tiền phòng (đ)', rent, number: true),
                FormInput(
                  'Điện tiêu thụ (kWh) · 3.500đ/kWh',
                  electric,
                  number: true,
                ),
                FormInput(
                  'Nước tiêu thụ (m³) · 20.000đ/m³',
                  water,
                  number: true,
                ),
                FormInput('WiFi (đ)', wifi, number: true),
                FormInput('Đổ rác (đ)', trash, number: true),
                InfoLine('Tiền điện', money('$electricFee')),
                InfoLine('Tiền nước', money('$waterFee')),
                const Divider(),
                InfoLine('Tổng cộng', money('$total')),
              ],
            ),
            DropdownButtonFormField<String>(
              value: method,
              decoration: const InputDecoration(
                labelText: 'Hình thức thanh toán',
              ),
              items: [
                'Chuyển khoản',
                'Tiền mặt',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => method = v!),
            ),
            const SizedBox(height: 20),
            if (method == 'Chuyển khoản') ...[
              Center(child: const PaymentQrPreview(size: 110)),
              const SizedBox(height: 10),
              const Text(
                'Khu vực hiển thị QR thanh toán',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: muted),
              ),
              const SizedBox(height: 20),
            ],
            FilledButton(onPressed: _save, child: const Text('Lưu hóa đơn')),
          ],
        ),
      ),
    );
  }
}
