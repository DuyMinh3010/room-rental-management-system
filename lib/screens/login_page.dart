  import 'package:flutter/material.dart';
  import 'room_page.dart';

  class LoginPage extends StatefulWidget {
    const LoginPage({super.key});

    @override
    State<LoginPage> createState() => _LoginPageState();
  }

  class _LoginPageState extends State<LoginPage> {
    bool isLandlord = true;
    bool hidePassword = true;

    // ================= NÚT ĐĂNG NHẬP =================
    void btnLogin() {
      if (isLandlord) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const RoomPage(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(""),
          ),
        );
      }
    }

    // ================= NÚT ĐĂNG KÝ =================
    void btnRegister() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(""),
        ),
      );
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ================= HEADER =================
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(
                          28,
                          35,
                          28,
                          38,
                        ),
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

                      // ================= FORM =================
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          28,
                          30,
                          28,
                          30,
                        ),
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
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(height: 30),

                            // ================= EMAIL =================
                            const Text(
                              "SĐT/Email",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 8),

                            TextField(
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

                            // ================= PASSWORD =================
                            const Text(
                              "Mật khẩu",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 8),

                            TextField(
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

                            // ================= CHỌN VAI TRÒ =================
                            Container(
                              height: 50,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF0FF),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Row(
                                children: [
                                  // NÚT CHỦ TRỌ
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
                                          borderRadius:
                                          BorderRadius.circular(10),
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

                                  // NÚT NGƯỜI THUÊ
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
                                          borderRadius:
                                          BorderRadius.circular(10),
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

                            // ================= NÚT ĐĂNG NHẬP =================
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: btnLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  const Color(0xFF3167E9),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(13),
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

                            const SizedBox(height: 24),

                            // ================= NÚT ĐĂNG KÝ =================
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
                                    onTap: btnRegister,
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
