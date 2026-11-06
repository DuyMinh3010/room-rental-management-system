import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/validators.dart';
import '../widgets/common.dart';

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
  bool agreed = false;
  bool hidePass = true;
  bool hideConfirm = true;
  bool busy = false;
  String? emailAuthError, passwordAuthError, agreementError;

  @override
  void dispose() {
    name.dispose();
    contact.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (busy) return;
    setState(() {
      agreementError = agreed ? null : 'Bạn cần đồng ý điều khoản';
    });
    if (!formKey.currentState!.validate() || !agreed) return;
    setState(() => busy = true);
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: contact.text.trim(),
            password: password.text,
          );
      final user = credential.user;
      if (user == null) {
        throw StateError('Firebase không trả về tài khoản vừa tạo');
      }
      await user.updateDisplayName(name.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'email-already-in-use':
              emailAuthError = 'Email này đã được đăng ký';
            case 'invalid-email':
              emailAuthError = 'Email không hợp lệ';
            case 'weak-password':
              passwordAuthError = 'Mật khẩu chưa đủ mạnh';
            default:
              passwordAuthError = errorText(e);
          }
        } else {
          passwordAuthError = errorText(e);
        }
      });
      formKey.currentState?.validate();
    } finally {
      if (mounted) setState(() => busy = false);
    }
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
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập họ và tên'
                    : null,
              ),
              const SizedBox(height: 14),
              _fieldLabel('Email'),
              TextFormField(
                controller: contact,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 13.5, color: ink),
                decoration: _boxInput(),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (_) => setState(() => emailAuthError = null),
                validator: (v) => emailAuthError ?? validateEmail(v),
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
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (_) => setState(() => passwordAuthError = null),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                  if (v.length < 6) return 'Mật khẩu cần ít nhất 6 ký tự';
                  return passwordAuthError;
                },
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
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Vui lòng xác nhận mật khẩu';
                  }
                  if (v != password.text) {
                    return 'Mật khẩu xác nhận chưa khớp';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () => setState(() {
                  agreed = !agreed;
                  if (agreed) agreementError = null;
                }),
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
                          onChanged: (v) => setState(() {
                            agreed = v ?? false;
                            agreementError = agreed ? null : agreementError;
                          }),
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
              if (agreementError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 30),
                  child: Text(
                    agreementError!,
                    style: const TextStyle(
                      color: Color(0xFFB60F0F),
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 26),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: busy ? null : _register,
                  style: FilledButton.styleFrom(
                    backgroundColor: blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    busy ? 'Đang tạo tài khoản...' : 'Tạo tài khoản',
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
