import 'package:flutter/material.dart';

import '../widgets/form_widgets.dart';
import 'verify_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final contact = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  String role = 'Chủ trọ';
  bool agreed = false;

  @override
  void dispose() {
    name.dispose();
    contact.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  void _register() {
    if (!formKey.currentState!.validate()) return;
    String? error;
    if (password.text.length < 6) error = 'Mật khẩu cần ít nhất 6 ký tự';
    if (password.text != confirm.text) error = 'Mật khẩu xác nhận chưa khớp';
    if (!agreed) error = 'Bạn cần đồng ý điều khoản';
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final account = <String, String>{
      'name': name.text.trim(),
      'role': role,
      (contact.text.contains('@') ? 'email' : 'phone'): contact.text.trim(),
    };
    account[contact.text.contains('@') ? 'email' : 'phone'] = contact.text
        .trim();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VerifyPage(account: account)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF86ADFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF86ADFF),
        title: const Text('Đăng ký tài khoản'),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Tạo một tài khoản để bắt đầu',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            FormInput('Họ và tên', name),
            FormInput('Số điện thoại hoặc email', contact),
            FormInput('Mật khẩu', password, password: true),
            FormInput('Xác nhận mật khẩu', confirm, password: true),
            const Text('Chọn vai trò của bạn'),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Chủ trọ', label: Text('Chủ trọ')),
                ButtonSegment(value: 'Người thuê', label: Text('Người thuê')),
              ],
              selected: {role},
              onSelectionChanged: (v) => setState(() => role = v.first),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: agreed,
              onChanged: (v) => setState(() => agreed = v ?? false),
              title: const Text(
                'Tôi đồng ý với Điều khoản và Chính sách bảo mật',
                style: TextStyle(fontSize: 13),
              ),
            ),
            FilledButton(
              onPressed: _register,
              child: const Text('Gửi yêu cầu'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đã có tài khoản? Đăng nhập ngay'),
            ),
            const Text(
              'Bản giao diện: chưa tạo tài khoản trên máy chủ.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
