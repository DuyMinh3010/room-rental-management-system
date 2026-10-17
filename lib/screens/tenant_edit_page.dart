import 'package:flutter/material.dart';

import '../widgets/form_widgets.dart';

class TenantEditPage extends StatefulWidget {
  final Map<String, String> tenant;
  const TenantEditPage({super.key, required this.tenant});
  @override
  State<TenantEditPage> createState() => _TenantEditPageState();
}

class _TenantEditPageState extends State<TenantEditPage> {
  final formKey = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  final labels = const {
    'name': 'Họ và tên',
    'birthday': 'Ngày sinh',
    'phone': 'Số điện thoại',
    'email': 'Email',
    'identity': 'CCCD/Passport',
    'address': 'Quê quán',
    'job': 'Nghề nghiệp',
    'note': 'Ghi chú',
  };
  String gender = 'Nam';
  String residence = 'Chưa đăng ký';
  @override
  void initState() {
    super.initState();
    for (final key in labels.keys) {
      fields[key] = TextEditingController(text: widget.tenant[key] ?? '');
    }
    gender = widget.tenant['gender'] ?? 'Nam';
    residence = widget.tenant['residence'] ?? 'Chưa đăng ký';
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!formKey.currentState!.validate()) return;
    final result = Map<String, String>.from(widget.tenant);
    for (final key in fields.keys) {
      result[key] = fields[key]!.text.trim();
    }
    result['gender'] = gender;
    result['residence'] = residence;
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa người thuê')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final key in labels.keys)
              FormInput(
                labels[key]!,
                fields[key]!,
                requiredField: key == 'name' || key == 'phone',
              ),
            DropdownButtonFormField<String>(
              value: gender,
              decoration: const InputDecoration(labelText: 'Giới tính'),
              items: [
                'Nam',
                'Nữ',
                'Khác',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => gender = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: residence,
              decoration: const InputDecoration(labelText: 'Tạm trú'),
              items: [
                'Chưa đăng ký',
                'Đã đăng ký',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => residence = v!),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Lưu thay đổi')),
          ],
        ),
      ),
    );
  }
}
