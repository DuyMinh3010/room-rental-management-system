import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/validators.dart';
import '../widgets/common.dart';
import 'register_page.dart';

enum _LoginRole { landlord, tenant }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final emailFieldKey = GlobalKey<FormFieldState<String>>();
  final email = TextEditingController(), password = TextEditingController();
  bool busy = false, hidden = true;
  _LoginRole? selectedRole;
  String? emailAuthError, passwordAuthError;
  String? roleAuthError;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (busy) return;
    if (selectedRole == null) {
      setState(() => roleAuthError = 'Vui lòng chọn Chủ trọ hoặc Người thuê');
      return;
    }
    if (!formKey.currentState!.validate()) return;
    setState(() {
      emailAuthError = null;
      passwordAuthError = null;
      roleAuthError = null;
      busy = true;
    });
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim().toLowerCase(),
        password: password.text,
      );
      final user = credential.user;
      if (user == null) {
        throw StateError('Firebase không trả về tài khoản vừa đăng nhập');
      }
      DocumentSnapshot<Map<String, dynamic>> manager;
      try {
        manager = await FirebaseFirestore.instance
            .collection('managers')
            .doc(user.uid)
            .get();
      } catch (_) {
        await FirebaseAuth.instance.signOut();
        rethrow;
      }
      final isLandlord = manager.data()?['enabled'] == true;
      if (isLandlord != (selectedRole == _LoginRole.landlord)) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          setState(() {
            roleAuthError = isLandlord
                ? 'Tài khoản này là Chủ trọ. Hãy chọn đúng vai trò để đăng nhập.'
                : 'Tài khoản này chưa được cấp quyền Chủ trọ. Hãy chọn Người thuê hoặc liên hệ chủ hệ thống.';
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'invalid-email':
              emailAuthError = 'Email không hợp lệ';
            case 'user-not-found':
              emailAuthError = 'Không tìm thấy tài khoản với email này';
            case 'wrong-password':
              passwordAuthError = 'Mật khẩu không chính xác';
            case 'invalid-credential':
              passwordAuthError = 'Email hoặc mật khẩu không chính xác';
            case 'user-disabled':
              emailAuthError = 'Tài khoản này đã bị vô hiệu hóa';
            case 'too-many-requests':
              passwordAuthError =
                  'Đăng nhập tạm thời bị khóa. Vui lòng thử lại sau';
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

  Future<void> _resetPassword() async {
    final error = validateEmail(email.text);
    if (error != null) {
      setState(() => emailAuthError = error);
      emailFieldKey.currentState?.validate();
      return;
    }
    setState(() => emailAuthError = null);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.text.trim().toLowerCase(),
      );
      if (mounted) {
        message(context, 'Nếu email hợp lệ, hãy kiểm tra thư đặt lại mật khẩu');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        emailAuthError = e is FirebaseAuthException
            ? switch (e.code) {
                'invalid-email' => 'Email không hợp lệ',
                'user-not-found' => 'Không tìm thấy tài khoản với email này',
                _ => errorText(e),
              }
            : errorText(e);
      });
      emailFieldKey.currentState?.validate();
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? suffixIcon,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    suffixIcon: suffixIcon,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: line, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: line, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: blue, width: 1.4),
    ),
  );

  Widget _roleButton(_LoginRole role, String label, IconData icon) {
    final selected = selectedRole == role;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: busy
              ? null
              : () => setState(() {
                  selectedRole = role;
                  roleAuthError = null;
                }),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: selected ? softBlue : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? blue : line,
                width: selected ? 1.3 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: selected ? blue : muted),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? blue : ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    body: SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: double.infinity,
                color: const Color(0xFF4285F4),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(36),
                          child: Image.asset(
                            'assets/images/rrms_logo.png',
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 62,
                              height: 62,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Text(
                                'R',
                                style: TextStyle(
                                  color: blue,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'RRMS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Quản lý phòng trọ dễ dàng hơn',
                          style: TextStyle(
                            color: Color(0xFFDBEAFE),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Đăng nhập',
                        style: TextStyle(
                          color: ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Chào mừng bạn quay lại',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Đăng nhập với vai trò',
                        style: TextStyle(
                          color: ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _roleButton(
                            _LoginRole.landlord,
                            'Chủ trọ',
                            Icons.home_work_outlined,
                          ),
                          const SizedBox(width: 10),
                          _roleButton(
                            _LoginRole.tenant,
                            'Người thuê',
                            Icons.person_outline_rounded,
                          ),
                        ],
                      ),
                      if (roleAuthError != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          roleAuthError!,
                          style: const TextStyle(
                            color: Color(0xFFB91C1C),
                            fontSize: 11,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      const Text(
                        'Email',
                        style: TextStyle(
                          color: ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: emailFieldKey,
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: ink, fontSize: 13.5),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        onChanged: (_) => setState(() => emailAuthError = null),
                        decoration: _inputDecoration(hint: '@gmail.com'),
                        validator: (value) =>
                            emailAuthError ?? validateEmail(value),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mật khẩu',
                            style: TextStyle(
                              color: ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          GestureDetector(
                            onTap: _resetPassword,
                            child: const Text(
                              'Quên mật khẩu?',
                              style: TextStyle(
                                color: blue,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: password,
                        obscureText: hidden,
                        style: const TextStyle(color: ink, fontSize: 13.5),
                        onFieldSubmitted: (_) => _login(),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        onChanged: (_) =>
                            setState(() => passwordAuthError = null),
                        decoration: _inputDecoration(
                          hint: '••••••••',
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => hidden = !hidden),
                            icon: Icon(
                              hidden
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFF5F6368),
                              size: 20,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '').isEmpty) {
                            return 'Vui lòng nhập mật khẩu';
                          }
                          return passwordAuthError;
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: busy ? null : _login,
                          style: FilledButton.styleFrom(
                            backgroundColor: blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            busy ? 'Đang đăng nhập...' : 'Đăng nhập',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () =>
                              openPage(context, const GoogleSignInSheetPage()),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: blue,
                            side: const BorderSide(color: Color(0xFFBFDBFE)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'G  Đăng nhập bằng Google',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Lần đầu đăng nhập? Bổ sung SĐT và thông tin cá nhân.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: muted, fontSize: 10.5),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: GestureDetector(
                          onTap: () => openPage(context, const RegisterPage()),
                          child: RichText(
                            text: const TextSpan(
                              text: 'Chưa có tài khoản?  ',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 12.5,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Đăng ký',
                                  style: TextStyle(
                                    color: Color(0xFF3787EB),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class GoogleSignInSheetPage extends StatelessWidget {
  const GoogleSignInSheetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        backgroundColor: canvas,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 30, color: ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Đăng nhập với Google'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 374),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: line),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: Image.asset(
                      'assets/images/rrms_logo.png',
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chọn một tài khoản',
                    style: TextStyle(
                      color: Color(0xFF202124),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'để tiếp tục tới RRMS',
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
                  const SizedBox(height: 22),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                    leading: initialAvatar('R', size: 36),
                    title: const Text(
                      'Sử dụng tài khoản Email / Mật khẩu',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Quay lại đăng nhập bằng tài khoản Firebase Auth',
                      style: TextStyle(fontSize: 11.5, color: muted),
                    ),
                    onTap: () => Navigator.pop(context),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Tiếng Việt',
                        style: TextStyle(
                          color: Color(0xFF202124),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        size: 18,
                        color: Color(0xFF444444),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Đóng'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
