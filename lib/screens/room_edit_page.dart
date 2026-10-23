import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final deposit = TextEditingController();
  final description = TextEditingController();
  final billingDay = TextEditingController(text: '05');

  String status = 'Trống';
  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    final room = widget.room;

    if (room != null) {
      name.text = room['name'] ?? '';

      price.text = (room['price'] ?? '').replaceAll(RegExp(r'[^0-9]'), '');

      area.text = (room['area'] ?? '').replaceAll('m²', '').trim();

      status = room['status'] ?? 'Trống';

      deposit.text = (room['deposit'] ?? '0').replaceAll(RegExp(r'[^0-9]'), '');

      description.text = room['description'] ?? '';

      billingDay.text = (room['billingDay'] ?? '05').split(' ').first;
    } else {
      deposit.text = '0';
    }
  }

  @override
  void dispose() {
    name.dispose();
    price.dispose();
    area.dispose();
    deposit.dispose();
    description.dispose();
    billingDay.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (isSaving || !(formKey.currentState?.validate() ?? false)) return;

    final amount = int.parse(price.text.trim());
    final depositAmount = int.parse(deposit.text.trim());
    final areaAmount = double.parse(area.text.trim().replaceAll(',', '.'));

    final priceText = amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );

    final result = <String, String>{
      'name': name.text.trim(),
      'status': status,
      'price': '$priceTextđ/tháng',
      'deposit': '${deposit.text.trim()}đ',
      'area': '${area.text.trim().replaceAll(',', '.')}m²',
      'billingDay': '${billingDay.text.trim()} hàng tháng',
      'description': description.text.trim(),
    };

    setState(() => isSaving = true);

    try {
      final rooms = FirebaseFirestore.instance.collection('rooms');
      final docId = widget.room?['_docId'];
      final roomRef = docId == null ? rooms.doc() : rooms.doc(docId);
      final existingSnapshot = docId == null ? null : await roomRef.get();

      if (existingSnapshot != null && !existingSnapshot.exists) {
        throw Exception('Không tìm thấy phòng cần cập nhật.');
      }

      final existingData = existingSnapshot?.data() ?? {};
      final existingServiceIds = existingData['serviceIds'];
      final existingCapacity = existingData['capacity'];
      final people =
          int.tryParse(
            (widget.room?['people'] ?? '').replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          1;

      await roomRef.set({
        'name': result['name'],
        'status': status,
        'condition': status == 'Đang sửa' ? 'Đang sửa' : 'Tốt',
        'price': amount,
        'deposit': depositAmount,
        'area': areaAmount,
        'people': people,
        'capacity': existingCapacity is num && existingCapacity >= 1
            ? existingCapacity
            : people < 1
            ? 1
            : people,
        'serviceIds': existingServiceIds is List ? existingServiceIds : [],
        'billingDay': result['billingDay'],
        'description': result['description'],
        if (docId == null) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      result['_docId'] = roomRef.id;
      Navigator.pop<Map<String, String>>(context, result);
    } catch (error) {
      if (!mounted) return;

      final action = widget.room == null ? 'thêm' : 'cập nhật';
      final message = error is FirebaseException
          ? error.code == 'permission-denied'
                ? 'Bạn không có quyền $action phòng này. Vui lòng kiểm tra tài khoản đang đăng nhập.'
                : 'Không thể $action phòng: ${error.message ?? error.code}'
          : 'Không thể $action phòng: $error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Widget input(
    String label,
    TextEditingController controller, {
    bool number = false,
    bool decimal = false,
    String? suffix,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: number
            ? TextInputType.numberWithOptions(decimal: decimal)
            : TextInputType.text,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) {
          final text = (value ?? '').trim();

          if (controller == description) {
            return null;
          }

          if (text.isEmpty) {
            return 'Vui lòng nhập $label';
          }

          if (controller == name) {
            final currentName = widget.room?['name']?.trim().toLowerCase();

            final isSameName = text.toLowerCase() == currentName;

            final isDuplicate = widget.usedNames.any(
              (n) => n.trim().toLowerCase() == text.toLowerCase(),
            );

            if (!isSameName && isDuplicate) {
              return 'Tên phòng đã tồn tại';
            }

            return null;
          }

          if (controller == deposit) {
            final value = int.tryParse(text);

            if (value == null || value < 0) {
              return 'Nhập tiền cọc không âm';
            }

            return null;
          }

          if (controller == billingDay) {
            final day = int.tryParse(text);

            if (day == null || day < 1 || day > 31) {
              return 'Nhập ngày từ 1 đến 31';
            }

            return null;
          }

          if (controller == price) {
            final amount = int.tryParse(text);

            if (amount == null || amount <= 0) {
              return 'Nhập giá thuê lớn hơn 0';
            }

            return null;
          }

          final size = double.tryParse(text.replaceAll(',', '.'));

          if (size == null || !size.isFinite || size <= 0) {
            return 'Nhập diện tích lớn hơn 0';
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
            input('Giá thuê', price, number: true, suffix: 'đ/tháng'),
            input('Tiền đặt cọc', deposit, number: true, suffix: 'đ'),
            input('Ngày chốt tiền', billingDay, number: true),
            input('Diện tích', area, number: true, decimal: true, suffix: 'm²'),
            DropdownButtonFormField<String>(
              initialValue: status,
              decoration: InputDecoration(
                labelText: 'Trạng thái',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: ['Trống', 'Tốt', 'Đang sửa'].map((s) {
                return DropdownMenuItem(value: s, child: Text(s));
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  status = value;
                });
              },
            ),
            const SizedBox(height: 16),
            input('Mô tả', description),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: blue,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(isSaving ? 'Đang lưu...' : 'Lưu phòng'),
            ),
          ],
        ),
      ),
    );
  }
}
