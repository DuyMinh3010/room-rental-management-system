import 'package:flutter/material.dart';

import '../widgets/form_widgets.dart';

class ServiceEditPage extends StatefulWidget {
  final Map<String, String>? service;
  const ServiceEditPage({super.key, this.service});
  @override
  State<ServiceEditPage> createState() => _ServiceEditPageState();
}

class _ServiceEditPageState extends State<ServiceEditPage> {
  final formKey = GlobalKey<FormState>();
  final price = TextEditingController();
  final note = TextEditingController();
  final customName = TextEditingController();
  String name = 'Điện';
  String mode = 'Theo chỉ số';
  @override
  void initState() {
    super.initState();
    name = widget.service?['name'] ?? 'Điện';
    mode = widget.service?['mode'] ?? 'Theo chỉ số';
    if (!['Điện', 'Nước', 'WiFi', 'Đổ rác', 'Gửi xe'].contains(name)) {
      customName.text = name;
      name = 'Khác';
    }
    price.text = widget.service?['price'] ?? '3500';
    note.text = widget.service?['note'] ?? '';
  }

  @override
  void dispose() {
    price.dispose();
    note.dispose();
    customName.dispose();
    super.dispose();
  }

  void _save() {
    if (!formKey.currentState!.validate()) return;
    final unit = mode == 'Theo chỉ số'
        ? (name == 'Nước' ? 'm³' : 'kWh')
        : (mode == 'Theo người' ? 'người' : 'tháng');
    Navigator.pop(context, <String, String>{
      'name': name == 'Khác' ? customName.text.trim() : name,
      'mode': mode,
      'price': price.text.trim(),
      'note': note.text.trim(),
      'unit': unit,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.service == null ? 'Thêm dịch vụ' : 'Chỉnh sửa dịch vụ',
        ),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<String>(
              value: name,
              decoration: const InputDecoration(labelText: 'Loại dịch vụ'),
              items: [
                'Điện',
                'Nước',
                'WiFi',
                'Đổ rác',
                'Gửi xe',
                'Khác',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() {
                name = v!;
                mode = ['Điện', 'Nước'].contains(name)
                    ? 'Theo chỉ số'
                    : name == 'Gửi xe'
                    ? 'Theo người'
                    : 'Theo phòng';
              }),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: mode,
              decoration: const InputDecoration(labelText: 'Cách tính'),
              items: [
                'Theo chỉ số',
                'Theo phòng',
                'Theo người',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => mode = v!),
            ),
            const SizedBox(height: 20),
            if (name == 'Khác') FormInput('Tên dịch vụ', customName),
            FormInput('Đơn giá (đ)', price, number: true),
            FormInput('Mô tả', note, requiredField: false, lines: 3),
            FilledButton(
              onPressed: _save,
              child: Text(
                widget.service == null ? 'Thêm dịch vụ' : 'Lưu thay đổi',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
