import 'package:flutter/material.dart';

import 'room_page.dart';

class RoomEditPage extends StatefulWidget {
  final Map<String, String>? room;
  final List<String> usedNames;

  const RoomEditPage({super.key, this.room, required this.usedNames});

  @override
  State<RoomEditPage> createState() => _RoomEditPageState();
}

class _RoomEditPageState extends State<RoomEditPage> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final price = TextEditingController();
  final area = TextEditingController();
  final people = TextEditingController();
  final deposit = TextEditingController();
  final zone = TextEditingController();
  final description = TextEditingController();
  final billingDay = TextEditingController(text: '05');
  String status = 'Trống';

  @override
  void initState() {
    super.initState();
    final room = widget.room;
    if (room != null) {
      name.text = room['name'] ?? '';
      price.text = (room['price'] ?? '').replaceAll(RegExp(r'[^0-9]'), '');
      area.text = (room['area'] ?? '').replaceAll('m²', '').trim();
      people.text = (room['people'] ?? '').replaceAll(' người', '').trim();
      status = room['status'] ?? 'Trống';
      deposit.text = (room['deposit'] ?? '0').replaceAll(RegExp(r'[^0-9]'), '');
      zone.text = room['zone'] ?? 'Khu A · Tầng 1';
      description.text = room['description'] ?? '';
      billingDay.text = (room['billingDay'] ?? '05').split(' ').first;
    } else {
      people.text = '0';
      deposit.text = '0';
    }
  }

  @override
  void dispose() {
    name.dispose();
    price.dispose();
    area.dispose();
    people.dispose();
    deposit.dispose();
    zone.dispose();
    description.dispose();
    billingDay.dispose();
    super.dispose();
  }

  void _save() {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final amount = int.parse(price.text.trim());
    final priceText = amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    Navigator.pop(context, <String, String>{
      'name': name.text.trim(),
      'deposit': '${deposit.text.trim()}đ',
      'zone': zone.text.trim(),
      'description': description.text.trim(),
      'billingDay': '${billingDay.text.trim()} hàng tháng',
      'status': status,
      'price': '${priceText}đ/tháng',
      'area': '${area.text.trim().replaceAll(',', '.')}m²',
      'people': '${people.text.trim()} người',
    });
  }

  Widget input(
    String label,
    TextEditingController controller, {
    bool number = false,
    bool decimal = false,
    String? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: number
            ? TextInputType.numberWithOptions(decimal: decimal)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) {
          final text = (value ?? '').trim();
          if (controller == description || controller == zone) return null;
          if (text.isEmpty) return 'Vui lòng nhập $label';
          if (controller == name) {
            if (widget.usedNames.any(
              (n) => n.toLowerCase() == text.toLowerCase(),
            )) {
              return 'Tên phòng đã tồn tại';
            }
          } else if (controller == people) {
            final count = int.tryParse(text);
            if (count == null || count < 0) return 'Nhập số người hợp lệ';
            if (status != 'Đang có người' && count != 0) {
              return 'Phòng trống hoặc đang sửa phải có 0 người';
            }
            if (status == 'Đang có người' && count == 0) {
              return 'Phòng đang có người cần ít nhất 1 người';
            }
          } else if (controller == deposit) {
            if (int.tryParse(text) == null || int.parse(text) < 0)
              return 'Nhập tiền cọc không âm';
          } else if (controller == billingDay) {
            final day = int.tryParse(text);
            if (day == null || day < 1 || day > 31)
              return 'Nhập ngày từ 1 đến 31';
          } else if (controller == price) {
            final amount = int.tryParse(text);
            if (amount == null || amount <= 0) return 'Nhập giá thuê lớn hơn 0';
          } else {
            final size = double.tryParse(text.replaceAll(',', '.'));
            if (size == null || !size.isFinite || size <= 0) {
              return 'Nhập diện tích lớn hơn 0';
            }
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.room == null ? 'Thêm phòng' : 'Chỉnh sửa phòng'),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            input('Tên phòng', name),
            input('Khu / tầng', zone),
            input('Giá thuê', price, number: true, suffix: 'đ/tháng'),
            input('Tiền đặt cọc', deposit, number: true, suffix: 'đ'),
            input('Ngày chốt tiền', billingDay, number: true),
            input('Diện tích', area, number: true, decimal: true, suffix: 'm²'),
            DropdownButtonFormField<String>(
              value: status,
              decoration: InputDecoration(
                labelText: 'Trạng thái',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                'Trống',
                'Đang có người',
                'Đang sửa',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (value) {
                setState(() {
                  if (value == null) return;
                  status = value;
                  if (status != 'Đang có người') people.text = '0';
                });
              },
            ),
            const SizedBox(height: 16),
            input('Số người', people, number: true, suffix: 'người'),
            input('Mô tả', description),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: blue,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Lưu phòng'),
            ),
          ],
        ),
      ),
    );
  }
}
