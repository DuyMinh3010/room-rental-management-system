import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'room_page.dart';
import 'account_page.dart';
import '../data/mock_data.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLandlord = true;
  bool hidePassword = true;

  final email = TextEditingController();
  final password = TextEditingController();
  bool signingIn = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (signingIn) return;
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      _message('Nhập email và mật khẩu đã tạo trong Firebase Authentication.');
      return;
    }
    setState(() => signingIn = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(), password: password.text);
      if (!mounted) return;
      roomList.clear();
      profile['email'] = email.text.trim();
      profile['role'] = isLandlord ? 'Chủ trọ' : 'Người thuê';
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => isLandlord ? const RoomPage() : const AccountPage(),
      ));
    } on FirebaseAuthException catch (e) {
      if (mounted) _message(e.code == 'network-request-failed'
        ? 'Không có kết nối mạng.'
        : 'Không đăng nhập được (${e.code}). Kiểm tra email, mật khẩu và bật Email/Password trong Firebase.');
    } finally {
      if (mounted) setState(() => signingIn = false);
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(text)));

  void _register() => _message(
    'Bản kết nối phòng dùng tài khoản tạo tại Firebase Console > Authentication > Users > Add user.');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(28, 35, 28, 38),
                      decoration: const BoxDecoration(
                        color: Color(0xFF3167E9),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(28),
                          bottomRight: Radius.circular(28),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFF00C8),
                                width: 3,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE600B8),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.home_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          const Text(
                            "RRMS",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          const Text(
                            "Quản lý phòng trọ dễ dàng hơn",
                            style: TextStyle(
                              color: Color(0xFFDCE6FF),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 30, 28, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Đăng nhập",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF202533),
                            ),
                          ),

                          const SizedBox(height: 6),

                          const Text(
                            "Chào mừng bạn quay lại",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),

                          const SizedBox(height: 30),

                          const Text(
                            "SĐT/Email",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 8),

                          TextField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: "@gmail.com",
                              hintStyle: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: const BorderSide(
                                  color: Color(0xFFDADDE3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: const BorderSide(
                                  color: Color(0xFF3167E9),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          const Text(
                            "Mật khẩu",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 8),

                          TextField(
                            controller: password,
                            obscureText: hidePassword,
                            decoration: InputDecoration(
                              hintText: "••••••••",
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    hidePassword = !hidePassword;
                                  });
                                },
                                icon: Icon(
                                  hidePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: const BorderSide(
                                  color: Color(0xFFDADDE3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: const BorderSide(
                                  color: Color(0xFF3167E9),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          Container(
                            height: 50,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF0FF),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        isLandlord = true;
                                      });
                                    },
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isLandlord
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        "Chủ trọ",
                                        style: TextStyle(
                                          fontWeight: isLandlord
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isLandlord
                                              ? const Color(0xFF3167E9)
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        isLandlord = false;
                                      });
                                    },
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: !isLandlord
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        "Người thuê",
                                        style: TextStyle(
                                          fontWeight: !isLandlord
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: !isLandlord
                                              ? const Color(0xFF3167E9)
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: signingIn ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3167E9),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                              child: const Text(
                                "Đăng nhập",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.account_circle_outlined),
                            label: const Text('Đăng nhập bằng Google'),
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Đăng nhập bằng Google'),
                                content: const Text(
                                  'Bản UI: đăng nhập Google sẽ được kết nối sau. Bạn có thể dùng nút Đăng nhập để xem các màn hình.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Đóng'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Text(
                            'Bản mẫu giao diện · Đăng nhập để xem các màn hình',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 24),

                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  "Chưa có tài khoản? ",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _register,
                                  child: const Text(
                                    "Đăng ký",
                                    style: TextStyle(
                                      color: Color(0xFF3167E9),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
