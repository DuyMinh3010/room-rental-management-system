import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/common.dart';
import 'notification_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    appBar: AppBar(
      backgroundColor: canvas,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tài khoản',
            style: TextStyle(
              color: ink,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Thông tin cá nhân & cài đặt',
            style: TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    ),
    body: RecordsView(
      collection: 'settings',
      builder: (_, all) {
        final user = FirebaseAuth.instance.currentUser;
        final userEmail = user?.email ?? 'Chưa cập nhật email';
        final displayName = user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!.trim()
            : userEmail.contains('@')
            ? userEmail.substring(0, userEmail.indexOf('@'))
            : 'Tài khoản chủ trọ';

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: [
            // Profile card (Frame 6)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: line, width: 0.7),
              ),
              child: Row(
                children: [
                  initialAvatar(
                    displayName,
                    size: 58,
                    solidBlue: false,
                    twoLetters: true,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: ink,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$userEmail · Chủ trọ',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: muted, fontSize: 11.5),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF8EE),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Text(
                                'Đang hoạt động',
                                style: TextStyle(
                                  color: Color(0xFF16A34A),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: store.uid),
                                  );
                                  if (context.mounted) {
                                    message(context, 'Đã sao chép UID');
                                  }
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 3,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.copy_outlined,
                                        size: 13,
                                        color: blue,
                                      ),
                                      SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Copy UID',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: blue,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Grouped menu rows (Frame 6)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: line, width: 0.7),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _AccountMenuRow(
                    title: 'Thông tin cá nhân',
                    subtitle: 'Tên, số điện thoại, ngân hàng nhận tiền',
                    onTap: () => openPage(context, const SettingsPage()),
                  ),
                  _AccountMenuRow(
                    title: 'Gán dữ liệu cũ cho tài khoản này',
                    subtitle:
                        'Chỉ chạy một lần để thêm ownerId cho dữ liệu hiện có',
                    onTap: () async {
                      if (!await confirm(
                        context,
                        'Toàn bộ dữ liệu chưa có ownerId sẽ được gán cho tài khoản chủ trọ đang đăng nhập. Không thể tự động chuyển dữ liệu này sang owner khác. Tiếp tục?',
                      )) {
                        return;
                      }
                      if (!context.mounted) return;
                      await perform(
                        context,
                        () => store.command('migrateOwnerData'),
                        'Đã gán ownerId cho dữ liệu cũ',
                      );
                    },
                  ),
                  _AccountMenuRow(
                    title: 'Hợp đồng & kiểm tra hóa đơn',
                    subtitle: 'Chạy kiểm tra hóa đơn đến kỳ và quá hạn',
                    onTap: () => perform(
                      context,
                      () async {
                        final result = await store.command('runBilling');
                        if (context.mounted) {
                          message(
                            context,
                            'Mới: ${result['created']} · Đã có: ${result['existing']} · Chưa đủ dữ liệu: ${result['blocked']} · Nhắc quá hạn: ${result['late']}',
                          );
                        }
                      },
                      'Đã chạy kiểm tra; xem mục Thông báo để biết phòng thiếu dữ liệu',
                    ),
                  ),
                  _AccountMenuRow(
                    title: 'Thông báo',
                    subtitle: 'Cài đặt nhắc nhở & hộp thư hệ thống',
                    onTap: () => openPage(context, const NotificationPage()),
                  ),
                  _AccountMenuRow(
                    title: 'Bảo mật',
                    subtitle: 'Đổi mật khẩu',
                    onTap: () => openPage(context, const PasswordPage()),
                  ),
                  _AccountMenuRow(
                    title: 'Đăng xuất',
                    danger: true,
                    showDivider: false,
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _AccountMenuRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;
  final bool showDivider;

  const _AccountMenuRow({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.danger = false,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: danger ? const Color(0xFFDC2626) : ink,
                          fontSize: 13.5,
                          fontWeight: danger
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: const TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: danger ? const Color(0xFFDC2626) : muted,
                ),
              ],
            ),
          ),
          if (showDivider) const Divider(height: 1, color: line),
        ],
      ),
    ),
  );
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool? auto;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    appBar: AppBar(
      backgroundColor: canvas,
      leading: IconButton(
        icon: const Icon(Icons.chevron_left_rounded, size: 30, color: ink),
        onPressed: () => Navigator.maybePop(context),
      ),
      titleSpacing: 0,
      title: const Text(
        'Thông tin cá nhân',
        style: TextStyle(color: ink, fontSize: 22, fontWeight: FontWeight.w600),
      ),
    ),
    body: RecordsView(
      collection: 'settings',
      builder: (_, all) {
        final settings = all.where((r) => r.id == store.uid).firstOrNull;
        final enabled = auto ?? settings?.data['autoBilling'] == true;
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(20, 6, 20, 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: line, width: 0.7),
              ),
              child: SwitchListTile(
                activeThumbColor: blue,
                title: const Text(
                  'Tự động tạo hóa đơn khi đến kỳ',
                  style: TextStyle(
                    color: ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Lịch hệ thống kiểm tra định kỳ; app cũng kiểm tra khi mở',
                  style: TextStyle(color: muted, fontSize: 11.5),
                ),
                value: enabled,
                onChanged: (v) => setState(() => auto = v),
              ),
            ),
            Expanded(
              child: EditForm(
                embedded: true,
                title: 'Thông tin',
                action: 'saveSettings',
                id: store.uid,
                submitLabel: 'Lưu thông tin',
                initial: settings?.data ?? const {},
                fixed: {'autoBilling': enabled},
                fields: const [
                  FieldSpec('name', 'Họ tên chủ trọ'),
                  FieldSpec('phone', 'Số điện thoại'),
                  FieldSpec('address', 'Địa chỉ', required: false),
                  FieldSpec('bankName', 'Tên ngân hàng', required: false),
                  FieldSpec('bankAccount', 'Số tài khoản', required: false),
                  FieldSpec('bankHolder', 'Tên chủ tài khoản', required: false),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});
  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  final current = TextEditingController(),
      password = TextEditingController(),
      confirmPassword = TextEditingController();
  bool hideCurrent = true, hideNew = true, hideConfirm = true;

  @override
  void dispose() {
    current.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  InputDecoration _pwdDecoration(
    String hint,
    bool hidden,
    VoidCallback toggle,
  ) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: muted, fontSize: 13),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    suffixIcon: IconButton(
      icon: Icon(
        hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 19,
        color: muted,
      ),
      onPressed: toggle,
    ),
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
      borderSide: const BorderSide(color: blue, width: 1.2),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    appBar: AppBar(
      backgroundColor: canvas,
      leading: IconButton(
        icon: const Icon(Icons.chevron_left_rounded, size: 30, color: ink),
        onPressed: () => Navigator.maybePop(context),
      ),
      titleSpacing: 0,
      title: const Text(
        'Đổi mật khẩu',
        style: TextStyle(color: ink, fontSize: 22, fontWeight: FontWeight.w600),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      children: [
        const Text(
          'Mật khẩu hiện tại *',
          style: TextStyle(
            color: ink,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: current,
          obscureText: hideCurrent,
          decoration: _pwdDecoration(
            'Nhập mật khẩu hiện tại',
            hideCurrent,
            () => setState(() => hideCurrent = !hideCurrent),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Mật khẩu mới *',
          style: TextStyle(
            color: ink,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: password,
          obscureText: hideNew,
          decoration: _pwdDecoration(
            'Ít nhất 6 ký tự',
            hideNew,
            () => setState(() => hideNew = !hideNew),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Xác nhận mật khẩu mới *',
          style: TextStyle(
            color: ink,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: confirmPassword,
          obscureText: hideConfirm,
          decoration: _pwdDecoration(
            'Nhập lại mật khẩu mới',
            hideConfirm,
            () => setState(() => hideConfirm = !hideConfirm),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: FilledButton(
            onPressed: () {
              if (password.text.length < 6 ||
                  password.text != confirmPassword.text) {
                message(context, 'Mật khẩu chưa đủ dài hoặc chưa khớp');
                return;
              }
              perform(context, () async {
                final user = FirebaseAuth.instance.currentUser!;
                await user.reauthenticateWithCredential(
                  EmailAuthProvider.credential(
                    email: user.email!,
                    password: current.text,
                  ),
                );
                await user.updatePassword(password.text);
              }, 'Đã đổi mật khẩu');
            },
            style: FilledButton.styleFrom(
              backgroundColor: blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Đổi mật khẩu'),
          ),
        ),
      ],
    ),
  );
}
