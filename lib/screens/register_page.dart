import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/validators.dart';
import '../widgets/common.dart';

enum RegisterRole { landlord, tenant }

class RegisterResult {
  final String email;
  final RegisterRole role;
  final String? joinedRoomName;

  const RegisterResult({
    required this.email,
    required this.role,
    this.joinedRoomName,
  });
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final phone = TextEditingController();
  final contact = TextEditingController();
  final inviteCode = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  RegisterRole? selectedRole;
  bool agreed = false;
  bool hidePass = true;
  bool hideConfirm = true;
  bool busy = false;
  String? roleError,
      inviteAuthError,
      emailAuthError,
      passwordAuthError,
      agreementError;

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    contact.dispose();
    inviteCode.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (busy) return;
    setState(() {
      roleError = selectedRole == null
          ? 'Vui lòng chọn Chủ trọ hoặc Người thuê'
          : null;
      inviteAuthError = null;
      agreementError = agreed ? null : 'Bạn cần đồng ý điều khoản';
    });
    if (selectedRole == null || !formKey.currentState!.validate() || !agreed) {
      return;
    }
    final role = selectedRole!;
    final displayName = name.text.trim();
    final normalizedPhone = phone.text.trim();
    final normalizedEmail = contact.text.trim().toLowerCase();
    final rawInvite = role == RegisterRole.tenant
        ? inviteCode.text.trim().toUpperCase()
        : '';
    setState(() {
      emailAuthError = null;
      passwordAuthError = null;
      inviteAuthError = null;
      busy = true;
    });
    authTransitioning.value = true;
    String? joinedRoomName;
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: normalizedEmail,
            password: password.text,
          );
      final user = credential.user;
      if (user == null) {
        throw StateError('Firebase không trả về tài khoản vừa tạo');
      }
      await user.updateDisplayName(displayName);
      await user.getIdToken(true);
      if (role == RegisterRole.landlord) {
        try {
          await store.createManagerAccount(
            uid: user.uid,
            name: displayName,
            email: normalizedEmail,
            phone: normalizedPhone,
          );
          try {
            await FirebaseFirestore.instance
                .collection('settings')
                .doc(user.uid)
                .set({
                  'ownerId': user.uid,
                  'name': displayName,
                  if (normalizedPhone.isNotEmpty) 'phone': normalizedPhone,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
          } catch (_) {
            // Không chặn đăng ký nếu settings ghi sau.
          }
        } catch (e) {
          try {
            await user.delete();
          } catch (_) {
            await FirebaseAuth.instance.signOut();
          }
          if (e is FirebaseException && e.code == 'permission-denied') {
            throw StateError(
              'Chưa cấp quyền đăng ký Chủ trọ trên Firestore. Hãy triển khai firestore.rules mới nhất.',
            );
          }
          rethrow;
        }
      } else if (rawInvite.isNotEmpty) {
        try {
          final joined = await store.joinRoomByInviteCode(rawInvite);
          joinedRoomName = '${joined['roomName'] ?? ''}';
        } catch (e) {
          try {
            await user.delete();
          } catch (_) {
            await FirebaseAuth.instance.signOut();
          }
          if (!mounted) return;
          setState(() {
            inviteAuthError = e is FirebaseException && e.code == 'permission-denied'
                ? 'Chưa triển khai firestore.rules cho mã mời dãy trọ.'
                : errorText(e);
          });
          formKey.currentState?.validate();
          return;
        }
      }
      try {
        await user.sendEmailVerification();
      } catch (_) {
        // Không làm hỏng luồng đăng ký nếu gửi email xác minh gặp giới hạn tạm thời.
      }
      await FirebaseAuth.instance.signOut();
      authTransitioning.value = false;
      if (mounted) {
        Navigator.pop(
          context,
          RegisterResult(
            email: normalizedEmail,
            role: role,
            joinedRoomName: joinedRoomName,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final detail = errorText(e);
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
              passwordAuthError = detail;
          }
        } else {
          passwordAuthError = detail;
        }
      });
      formKey.currentState?.validate();
      if (e is! FirebaseAuthException) {
        message(context, detail);
      }
    } finally {
      authTransitioning.value = false;
      if (mounted) setState(() => busy = false);
    }
  }

  Widget _roleButton(RegisterRole role, String label, IconData icon) {
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
                  roleError = null;
                }),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: selected ? softBlue : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? blue : Colors.white,
                width: selected ? 1.4 : 1,
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
      backgroundColor: const Color(0xFFFDEEE4),
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
              const SizedBox(height: 18),
              _fieldLabel('Đăng ký với vai trò'),
              Row(
                children: [
                  _roleButton(
                    RegisterRole.landlord,
                    'Chủ trọ',
                    Icons.home_work_outlined,
                  ),
                  const SizedBox(width: 10),
                  _roleButton(
                    RegisterRole.tenant,
                    'Người thuê',
                    Icons.person_outline_rounded,
                  ),
                ],
              ),
              if (selectedRole != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    selectedRole == RegisterRole.landlord
                        ? 'Tài khoản Chủ trọ có quyền quản lý phòng, hợp đồng, hóa đơn và khách thuê.'
                        : 'Nhập mã mời từ chủ trọ để tự động đối chiếu email và vào đúng phòng ngay khi tạo tài khoản.',
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 11.5,
                    ),
                  ),
                ),
              if (roleError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    roleError!,
                    style: const TextStyle(
                      color: Color(0xFFB60F0F),
                      fontSize: 12,
                    ),
                  ),
                ),
              if (selectedRole == RegisterRole.tenant) ...[
                const SizedBox(height: 14),
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Mã mời vào phòng (tùy chọn)',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextFormField(
                  controller: inviteCode,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: ink,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _boxInput().copyWith(
                    hintText: 'VD: A7K92P (có thể nhập sau khi đăng nhập)',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12.5,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: (_) => setState(() => inviteAuthError = null),
                  validator: (v) {
                    if (inviteAuthError != null) return inviteAuthError;
                    final cleaned = (v ?? '').trim().toUpperCase();
                    if (cleaned.isEmpty) return null;
                    if (!RegExp(r'^[A-Z0-9]{6,8}$').hasMatch(cleaned)) {
                      return 'Mã mời gồm 6–8 ký tự chữ và số';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 14),
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
              _fieldLabel('Số điện thoại'),
              TextFormField(
                controller: phone,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 13.5, color: ink),
                decoration: _boxInput(),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) => validateVietnamesePhone(v),
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
