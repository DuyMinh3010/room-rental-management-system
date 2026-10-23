import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/form_widgets.dart';
import 'room_page.dart';
import 'login_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) setState(() {});
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  void _openTenantContract() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chưa có thông tin hợp đồng.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : 'Tài khoản';
    final initials = displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(title: const Text('Tài khoản')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Thông tin cá nhân & cài đặt',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFEAF0FF),
                  child: Text(initials, style: const TextStyle(color: blue)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? user?.phoneNumber ?? '',
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Card(
            color: Colors.white,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Thông tin cá nhân'),
                  subtitle: const Text('Tên, số điện thoại, email'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(const PersonalInfoPage()),
                ),
                ListTile(
                  leading: const Icon(Icons.article_outlined),
                  title: const Text('Hợp đồng & đặt cọc'),
                  subtitle: const Text('Xem thông tin thuê phòng'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openTenantContract,
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Thông báo'),
                  subtitle: const Text('Cài đặt nhắc nhở'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(const NotificationPage()),
                ),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Bảo mật'),
                  subtitle: const Text('Đổi mật khẩu'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(const SecurityPage()),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Đăng xuất'),
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomBar(selected: 6),
    );
  }
}

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});
  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final formKey = GlobalKey<FormState>();
  final user = FirebaseAuth.instance.currentUser;
  late final name = TextEditingController(text: user?.displayName ?? '');
  late final phone = TextEditingController(text: user?.phoneNumber ?? '');
  late final email = TextEditingController(text: user?.email ?? '');
  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    try {
      if (user == null) {
        throw StateError('Bạn chưa đăng nhập.');
      }
      await user!.updateDisplayName(name.text.trim());
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu thông tin: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Thông tin cá nhân')),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          FormInput('Họ và tên', name),
          TextField(
            controller: phone,
            readOnly: true,
            decoration: const InputDecoration(labelText: 'Số điện thoại'),
          ),
          TextField(
            controller: email,
            readOnly: true,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          FilledButton(onPressed: _save, child: const Text('Lưu thay đổi')),
        ],
      ),
    ),
  );
}

// Lưu tùy chọn mẫu trong phiên chạy, chưa gửi thông báo thật.
final notificationSettings = <String, bool>{
  'Nhắc thanh toán': true,
  'Hợp đồng sắp hết hạn': true,
  'Cập nhật bảo trì': true,
};

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});
  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Thông báo')),
    body: ListView(
      children: [
        for (final key in notificationSettings.keys)
          SwitchListTile(
            title: Text(key),
            value: notificationSettings[key]!,
            onChanged: (v) => setState(() => notificationSettings[key] = v),
          ),
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Tùy chọn giao diện mẫu, chưa kết nối hệ thống gửi thông báo.',
          ),
        ),
      ],
    ),
  );
}

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});
  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final formKey = GlobalKey<FormState>();
  final current = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  @override
  void dispose() {
    current.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  void _save() {
    if (!formKey.currentState!.validate()) return;
    if (password.text.length < 6 || password.text != confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mật khẩu mới cần ít nhất 6 ký tự và xác nhận phải khớp',
          ),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Thông tin hợp lệ. Bản mẫu chưa đổi mật khẩu trên máy chủ.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bảo mật')),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          FormInput('Mật khẩu hiện tại', current, password: true),
          FormInput('Mật khẩu mới', password, password: true),
          FormInput('Xác nhận mật khẩu mới', confirm, password: true),
          FilledButton(onPressed: _save, child: const Text('Đổi mật khẩu')),
        ],
      ),
    ),
  );
}
