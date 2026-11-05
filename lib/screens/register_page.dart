import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../widgets/common.dart';
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
  bool hidePass = true;
  bool hideConfirm = true;

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final account = Map<String, String>.from(profile);
    account['name'] = name.text.trim();
    account['role'] = role;
    account[contact.text.contains('@') ? 'email' : 'phone'] = contact.text
        .trim();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VerifyPage(account: account)),
    );
  }

  Widget _fieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Color(0xFFB60F0F)),
          ),
        ],
      ),
    ),
  );

  InputDecoration _boxInput({Widget? suffixIcon}) => InputDecoration(
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    suffixIcon: suffixIcon,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: blue, width: 1.4),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC8DCFF),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        size: 32,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const Text(
                    'Đăng Ký tài khoản',
                    style: TextStyle(
                      color: ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Tạo một tài khoản để bắt đầu',
                style: TextStyle(
                  color: Color(0xFF444444),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              _fieldLabel('Họ và tên'),
              TextFormField(
                controller: name,
                style: const TextStyle(fontSize: 13.5, color: ink),
                decoration: _boxInput(),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ và tên' : null,
              ),
              const SizedBox(height: 14),
              _fieldLabel('Số điện thoại hoặc email'),
              TextFormField(
                controller: contact,
                style: const TextStyle(fontSize: 13.5, color: ink),
                decoration: _boxInput(),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập SĐT hoặc email'
                    : null,
              ),
              const SizedBox(height: 14),
              _fieldLabel('Mật khẩu'),
              TextFormField(
                controller: password,
                obscureText: hidePass,
                style: const TextStyle(fontSize: 13.5, color: ink),
                decoration: _boxInput(
                  suffixIcon: IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => hidePass = !hidePass),
                    icon: Icon(
                      hidePass
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: const Color(0xFF6B717E),
                    ),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
              ),
              const SizedBox(height: 14),
              _fieldLabel('Xác nhận mật khẩu'),
              TextFormField(
                controller: confirm,
                obscureText: hideConfirm,
                style: const TextStyle(fontSize: 13.5, color: ink),
                decoration: _boxInput(
                  suffixIcon: IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => hideConfirm = !hideConfirm),
                    icon: Icon(
                      hideConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: const Color(0xFF6B717E),
                    ),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Vui lòng xác nhận mật khẩu'
                    : null,
              ),
              const SizedBox(height: 14),
              _fieldLabel('Chọn vai trò của bạn'),
              Container(
                height: 44,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: softBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    for (final item in const ['Chủ trọ', 'Người thuê'])
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => role = item),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: role == item
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Text(
                              item,
                              style: TextStyle(
                                color: role == item
                                    ? blue
                                    : const Color(0xFF6B7280),
                                fontSize: 12,
                                fontWeight: role == item
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () => setState(() => agreed = !agreed),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: agreed,
                          activeColor: blue,
                          onChanged: (v) => setState(() => agreed = v ?? false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Tôi đã đọc, hiểu và đồng ý với Điều khoản và Cam kết và Chính sách bảo mật',
                          style: TextStyle(
                            color: Color(0xFF6B717E),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _register,
                  style: FilledButton.styleFrom(
                    backgroundColor: blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Gửi yêu cầu',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Bạn đã có tài khoản? Đăng nhập ngay',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
