import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/google_auth_service.dart';
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
  final inviteFieldKey = GlobalKey<FormFieldState<String>>();
  final email = TextEditingController(),
      password = TextEditingController(),
      inviteCode = TextEditingController();
  bool busy = false, googleBusy = false, hidden = true;
  _LoginRole? selectedRole;
  String? emailAuthError, passwordAuthError, inviteAuthError;
  String? roleAuthError;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    inviteCode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (selectedRole == null) {
      setState(() => roleAuthError = 'Vui lòng chọn Chủ trọ hoặc Người thuê');
      return;
    }
    if (inviteAuthError != null) {
      setState(() => inviteAuthError = null);
    }
    if (!formKey.currentState!.validate()) return;
    final rawInvite = selectedRole == _LoginRole.tenant
        ? inviteCode.text.trim().toUpperCase()
        : '';
    setState(() {
      emailAuthError = null;
      passwordAuthError = null;
      inviteAuthError = null;
      roleAuthError = null;
      busy = true;
    });
    authTransitioning.value = true;
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
      final wantsLandlord = selectedRole == _LoginRole.landlord;
      if (wantsLandlord && !isLandlord) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          setState(() {
            roleAuthError =
                'Tài khoản này chưa được cấp quyền Chủ trọ. Hãy đăng nhập với vai trò Người thuê hoặc nâng cấp tài khoản trong mục Tài khoản.';
          });
        }
        return;
      }
      if (!wantsLandlord && rawInvite.isNotEmpty) {
        try {
          await store.joinRoomByInviteCode(rawInvite);
        } catch (e) {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            setState(() => inviteAuthError = errorText(e));
            inviteFieldKey.currentState?.validate();
          }
          return;
        }
      }
      preferredLandlordMode.value = wantsLandlord;
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
      authTransitioning.value = false;
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    if (busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (selectedRole == null) {
      setState(() => roleAuthError = 'Vui lòng chọn Chủ trọ hoặc Người thuê');
      return;
    }
    final rawInvite = selectedRole == _LoginRole.tenant
        ? inviteCode.text.trim().toUpperCase()
        : '';
    setState(() {
      emailAuthError = null;
      passwordAuthError = null;
      inviteAuthError = null;
      roleAuthError = null;
      busy = true;
      googleBusy = true;
    });
    authTransitioning.value = true;
    try {
      final credential = await GoogleAuthService.signInWithGoogle();
      if (credential == null) return;
      final user = credential.user;
      if (user == null) {
        throw StateError('Firebase không trả về tài khoản Google vừa đăng nhập');
      }
      DocumentSnapshot<Map<String, dynamic>> manager;
      try {
        manager = await FirebaseFirestore.instance
            .collection('managers')
            .doc(user.uid)
            .get();
      } catch (_) {
        await GoogleAuthService.signOut();
        rethrow;
      }

      final isLandlord = manager.data()?['enabled'] == true;
      final wantsLandlord = selectedRole == _LoginRole.landlord;

      if (wantsLandlord && !isLandlord) {
        if (!mounted) {
          await GoogleAuthService.signOut();
          return;
        }
        final normalizedEmail = (user.email ?? '').trim().toLowerCase();
        final defaultName = user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : normalizedEmail.contains('@')
            ? normalizedEmail.substring(0, normalizedEmail.indexOf('@'))
            : 'Chủ trọ';

        final submitted = await showDialog<Map<String, String>>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _GoogleLandlordSetupDialog(
            email: normalizedEmail,
            defaultName: defaultName,
          ),
        );
        if (submitted == null) {
          await GoogleAuthService.signOut();
          return;
        }
        try {
          final ownerName = submitted['name']!;
          final phone = submitted['phone'] ?? '';
          final address = submitted['address'] ?? '';
          await store.createManagerAccount(
            uid: user.uid,
            name: ownerName,
            email: normalizedEmail,
            phone: phone,
          );
          try {
            await FirebaseFirestore.instance
                .collection('settings')
                .doc(user.uid)
                .set({
                  'ownerId': user.uid,
                  'name': ownerName,
                  if (phone.isNotEmpty) 'phone': phone,
                  if (address.isNotEmpty) 'address': address,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
          } catch (_) {
            // Không chặn đăng nhập nếu settings ghi sau.
          }
        } catch (e) {
          await GoogleAuthService.signOut();
          rethrow;
        }
      }

      if (!wantsLandlord && rawInvite.isNotEmpty) {
        try {
          await store.joinRoomByInviteCode(rawInvite);
        } catch (e) {
          await GoogleAuthService.signOut();
          if (mounted) {
            final detail = errorText(e);
            setState(() => inviteAuthError = detail);
            inviteFieldKey.currentState?.validate();
            message(context, detail);
          }
          return;
        }
      }

      preferredLandlordMode.value = wantsLandlord;
    } catch (e) {
      if (!mounted) return;
      final text = e is FirebaseAuthException
          ? switch (e.code) {
              'account-exists-with-different-credential' =>
                'Email này đã được đăng ký bằng Email/Mật khẩu. Hãy đăng nhập bằng mật khẩu.',
              'user-disabled' => 'Tài khoản này đã bị vô hiệu hóa',
              'operation-not-allowed' =>
                'Đăng nhập Google chưa được bật trên Firebase Authentication',
              'network-request-failed' =>
                'Lỗi kết nối mạng. Vui lòng kiểm tra Internet và thử lại',
              _ => errorText(e),
            }
          : errorText(e);
      message(context, text);
    } finally {
      authTransitioning.value = false;
      if (mounted) {
        setState(() {
          busy = false;
          googleBusy = false;
        });
      }
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
                  inviteAuthError = null;
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
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFF8A4C),
                      Color(0xFFF26522),
                      Color(0xFFF5A94C),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
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
                            color: Color(0xFFFFF4EC),
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
                      if (selectedRole == _LoginRole.tenant) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Mã mời dãy trọ (tùy chọn)',
                          style: TextStyle(
                            color: ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Lần đầu tham gia phòng? Nhập mã mời cố định của dãy trọ bên dưới (để trống nếu tài khoản đã vào phòng trước đó).',
                          style: TextStyle(color: muted, fontSize: 11.5),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          key: inviteFieldKey,
                          controller: inviteCode,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(
                            color: ink,
                            fontSize: 14,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          onChanged: (_) =>
                              setState(() => inviteAuthError = null),
                          decoration:
                              _inputDecoration(
                                hint:
                                    'VD: A7K92P (để trống nếu đã liên kết phòng)',
                              ).copyWith(
                                hintStyle: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 12.5,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.w400,
                                ),
                                prefixIcon: const Icon(
                                  Icons.vpn_key_outlined,
                                  color: blue,
                                  size: 19,
                                ),
                              ),
                          validator: (_) => inviteAuthError,
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
                            busy && !googleBusy
                                ? 'Đang đăng nhập...'
                                : 'Đăng nhập',
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
                          onPressed: busy ? null : _loginWithGoogle,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: ink,
                            side: const BorderSide(color: Color(0xFFFAD4BE)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: googleBusy
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: blue,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Đang đăng nhập với Google...',
                                      style: TextStyle(
                                        color: blue,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: softBlue,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'G',
                                        style: TextStyle(
                                          color: blue,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Đăng nhập bằng Google',
                                      style: TextStyle(
                                        color: blue,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
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
                          onTap: () async {
                            final result = await Navigator.of(context)
                                .push<RegisterResult>(
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterPage(),
                                  ),
                                );
                            if (result == null || !context.mounted) return;
                            setState(() {
                              selectedRole =
                                  result.role == RegisterRole.landlord
                                  ? _LoginRole.landlord
                                  : _LoginRole.tenant;
                              email.text = result.email;
                              password.clear();
                              inviteCode.clear();
                              emailAuthError = null;
                              passwordAuthError = null;
                              inviteAuthError = null;
                              roleAuthError = null;
                            });
                            final joinedRoom =
                                (result.joinedRoomName ?? '').trim();
                            message(
                              context,
                              result.role == RegisterRole.landlord
                                  ? 'Đăng ký tài khoản Chủ trọ thành công. Hãy đăng nhập.'
                                  : joinedRoom.isNotEmpty
                                  ? 'Đăng ký & vào $joinedRoom thành công! Hãy đăng nhập.'
                                  : 'Đăng ký tài khoản Người thuê thành công. Hãy đăng nhập và nhập mã mời phòng.',
                            );
                          },
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
                                    color: blue,
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

class _GoogleLandlordSetupDialog extends StatefulWidget {
  final String email;
  final String defaultName;

  const _GoogleLandlordSetupDialog({
    required this.email,
    required this.defaultName,
  });

  @override
  State<_GoogleLandlordSetupDialog> createState() =>
      _GoogleLandlordSetupDialogState();
}

class _GoogleLandlordSetupDialogState
    extends State<_GoogleLandlordSetupDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.defaultName);
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    title: const Text(
      'Tạo hồ sơ Chủ trọ',
      style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w700),
    ),
    content: SingleChildScrollView(
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tài khoản Google ${widget.email} chưa đăng ký làm Chủ trọ. Nhập thông tin cơ bản để kích hoạt ngay:',
              style: const TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Họ tên chủ trọ *'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Vui lòng nhập họ tên chủ trọ'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại liên hệ (tùy chọn)',
              ),
              validator: (v) => validateVietnamesePhone(v, required: false),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ nhà trọ (tùy chọn)',
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: () {
          if (!formKey.currentState!.validate()) return;
          Navigator.pop(context, {
            'name': nameController.text.trim(),
            'phone': phoneController.text.trim(),
            'address': addressController.text.trim(),
          });
        },
        style: FilledButton.styleFrom(
          minimumSize: const Size(96, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text('Kích hoạt'),
      ),
    ],
  );
}
