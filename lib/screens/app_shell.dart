import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/google_auth_service.dart';
import '../widgets/common.dart';
import 'room_page.dart';
import 'tenant_list_page.dart';
import 'service_page.dart';
import 'invoice_page.dart';
import 'contract_page.dart';
import 'maintenance_page.dart';
import 'account_page.dart';
import 'notification_page.dart';
import 'tenant_portal_content.dart';

class AppShell extends StatefulWidget {
  final bool landlord;
  const AppShell({super.key, required this.landlord});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int index = 0;
  int tenantIndex = 0;
  late bool _landlordMode;
  bool checking = false;
  bool joiningByInvite = false;
  bool upgradingToLandlord = false;
  final inviteController = TextEditingController();
  String? inviteError;
  Future<Map<String, dynamic>?>? tenantPortalFuture;
  @override
  void initState() {
    super.initState();
    _landlordMode = widget.landlord && (preferredLandlordMode.value ?? true);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBilling());
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.landlord && widget.landlord) {
      _landlordMode = preferredLandlordMode.value ?? true;
      if (_landlordMode) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _checkBilling());
      }
    } else if (oldWidget.landlord && !widget.landlord) {
      _landlordMode = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkBilling();
  }

  Future<void> _checkBilling() async {
    if (!widget.landlord || !_landlordMode || checking) return;
    checking = true;
    try {
      final res = await store.command('runBilling');
      final created = res['created'] as num? ?? 0;
      final late = res['late'] as num? ?? 0;
      if (mounted && (created > 0 || late > 0)) {
        final parts = <String>[];
        if (created > 0) parts.add('Đã tạo $created hóa đơn mới');
        if (late > 0) parts.add('$late hóa đơn quá hạn');
        message(context, 'Tự động kiểm tra: ${parts.join(', ')}');
      }
    } catch (e) {
      debugPrint('Chưa kiểm tra được hóa đơn: $e');
    } finally {
      checking = false;
    }
  }

  void _switchMode(bool toLandlord) {
    if (toLandlord && !widget.landlord) return;
    FocusManager.instance.primaryFocus?.unfocus();
    preferredLandlordMode.value = toLandlord;
    setState(() {
      _landlordMode = toLandlord;
      if (!toLandlord) {
        tenantPortalFuture = null;
        inviteError = null;
      }
    });
    if (toLandlord) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkBilling());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    inviteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_landlordMode) return _tenantView(context);
    final pages = [
      const RoomPage(),
      const TenantListPage(),
      ServicePage(onNavigate: (v) => setState(() => index = v)),
      const InvoicePage(),
      const ContractPage(),
      const MaintenancePage(),
      AccountPage(onSwitchToTenant: () => _switchMode(false)),
    ];
    return Scaffold(
      backgroundColor: canvas,
      body: pages[index],
      bottomNavigationBar: RrmsBottomBar(
        selectedIndex: index,
        onTap: (v) => setState(() => index = v),
      ),
    );
  }

  Widget _tenantView(BuildContext context) {
    tenantPortalFuture ??= store.loadTenantPortalOrNull();
    return FutureBuilder<Map<String, dynamic>?>(
      future: tenantPortalFuture,
      builder: (context, snapshot) {
        final portalData = snapshot.data;
        final hasPortal = portalData != null;
        return Scaffold(
          backgroundColor: canvas,
          appBar: AppBar(
            title: Text(hasPortal ? tenantTabLabels[tenantIndex] : 'Người thuê'),
            actions: [
              if (widget.landlord)
                TextButton.icon(
                  onPressed: () => _switchMode(true),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('Chủ trọ', style: TextStyle(fontSize: 12.5)),
                ),
              const NotificationButton(landlord: false),
              IconButton(
                tooltip: 'Làm mới dữ liệu',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => setState(
                  () => tenantPortalFuture = store.loadTenantPortalOrNull(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: () async {
                  preferredLandlordMode.value = null;
                  await GoogleAuthService.signOut();
                },
              ),
            ],
          ),
          body: () {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  box(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chưa tải được thông tin thuê',
                          style: TextStyle(
                            color: ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          errorText(snapshot.error),
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => setState(
                            () => tenantPortalFuture =
                                store.loadTenantPortalOrNull(),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                  _inviteCodeCard(context),
                  _roleActionCard(context),
                ],
              );
            }
            if (hasPortal) {
              return TenantPortalContent(
                index: tenantIndex,
                data: portalData,
                onNavigate: (value) => setState(() => tenantIndex = value),
                onRefresh: () => setState(
                  () => tenantPortalFuture = store.loadTenantPortalOrNull(),
                ),
                isLandlordAccount: widget.landlord,
                onSwitchToLandlord: () => _switchMode(true),
                onUpgradeToLandlord: _upgradeToLandlord,
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [_inviteCodeCard(context), _roleActionCard(context)],
            );
          }(),
          bottomNavigationBar: hasPortal
              ? TenantPortalBottomBar(
                  selectedIndex: tenantIndex,
                  onTap: (value) => setState(() => tenantIndex = value),
                )
              : null,
        );
      },
    );
  }

  Widget _inviteCodeCard(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return box(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tham gia phòng bằng Mã mời',
            style: TextStyle(
              color: ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Đang đăng nhập bằng $email. Nhập mã mời 6 ký tự do chủ trọ cung cấp để tự động liên kết vào đúng phòng thuê của bạn.',
            style: const TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: inviteController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              color: ink,
              fontSize: 16,
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
            ),
            onChanged: (_) {
              if (inviteError != null) setState(() => inviteError = null);
            },
            onSubmitted: (_) => _joinByInviteCode(context),
            decoration: InputDecoration(
              hintText: 'Nhập mã 6 ký tự (VD: A7K92P)',
              hintStyle: const TextStyle(
                color: muted,
                fontSize: 13,
                letterSpacing: 0,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(Icons.vpn_key_outlined, color: blue),
              errorText: inviteError,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: joiningByInvite
                  ? null
                  : () => _joinByInviteCode(context),
              icon: joiningByInvite
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.login_rounded, size: 18),
              label: Text(
                joiningByInvite ? 'Đang kiểm tra mã mời...' : 'Vào phòng ngay',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinByInviteCode(BuildContext context) async {
    if (joiningByInvite) return;
    final raw = inviteController.text.trim();
    if (raw.isEmpty) {
      setState(() => inviteError = 'Vui lòng nhập mã mời 6 ký tự từ chủ trọ');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      joiningByInvite = true;
      inviteError = null;
    });
    try {
      final result = await store.joinRoomByInviteCode(raw);
      if (!mounted) return;
      inviteController.clear();
      final roomName = '${result['roomName'] ?? ''}'.trim();
      setState(() {
        tenantIndex = 0;
        tenantPortalFuture = store.loadTenantPortalOrNull();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          message(
            this.context,
            roomName.isNotEmpty
                ? 'Đã tham gia $roomName thành công!'
                : 'Đã liên kết phòng thuê thành công!',
          );
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        inviteError =
            error is FirebaseException && error.code == 'permission-denied'
            ? 'Chưa triển khai firestore.rules cho mã mời phòng.'
            : errorText(error);
      });
    } finally {
      if (mounted) setState(() => joiningByInvite = false);
    }
  }

  Widget _roleActionCard(BuildContext context) {
    if (widget.landlord) return const SizedBox.shrink();
    return box(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bạn có phòng trọ cho thuê?',
            style: TextStyle(
              color: ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Nâng cấp tài khoản này thành Chủ trọ để quản lý dãy phòng của riêng bạn mà vẫn giữ thông tin thuê hiện tại.',
            style: TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: upgradingToLandlord ? null : _upgradeToLandlord,
            icon: upgradingToLandlord
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.home_work_outlined, size: 18),
            label: Text(
              upgradingToLandlord
                  ? 'Đang nâng cấp...'
                  : 'Đăng ký trở thành Chủ trọ',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _upgradeToLandlord() async {
    if (upgradingToLandlord) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final normalizedEmail = (user.email ?? '').trim().toLowerCase();
    final defaultName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : normalizedEmail.contains('@')
        ? normalizedEmail.substring(0, normalizedEmail.indexOf('@'))
        : 'Chủ trọ';

    FocusManager.instance.primaryFocus?.unfocus();
    final submitted = await showDialog<Map<String, String>>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _UpgradeToLandlordDialog(defaultName: defaultName),
    );

    if (submitted == null || !mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => upgradingToLandlord = true);

    // Chờ animation đóng hộp thoại hoàn tất hoàn toàn trước khi đổi cây widget sang Chủ trọ.
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;

    final previousPreferredMode = preferredLandlordMode.value;
    preferredLandlordMode.value = true;
    try {
      final ownerName = submitted['name']!;
      await FirebaseFirestore.instance.collection('managers').doc(user.uid).set({
        'enabled': true,
        'role': 'landlord',
        'name': ownerName,
        'email': normalizedEmail,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (user.displayName == null || user.displayName!.trim().isEmpty) {
        try {
          await user.updateDisplayName(ownerName);
        } catch (_) {}
      }
      final phone = submitted['phone'] ?? '';
      final address = submitted['address'] ?? '';
      if (ownerName.isNotEmpty || phone.isNotEmpty || address.isNotEmpty) {
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
          // Không chặn nâng cấp nếu người dùng sẽ cập nhật cài đặt sau.
        }
      }
      if (!mounted) return;
      setState(() => _landlordMode = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          message(
            context,
            'Chúc mừng! Tài khoản của bạn đã nâng cấp thành Chủ trọ.',
          );
        }
      });
    } catch (e) {
      preferredLandlordMode.value = previousPreferredMode;
      if (!mounted) return;
      if (e is FirebaseException && e.code == 'permission-denied') {
        message(
          context,
          'Chưa cấp quyền đăng ký Chủ trọ trên Firestore. Hãy triển khai firestore.rules mới nhất.',
        );
      } else {
        message(context, errorText(e));
      }
    } finally {
      if (mounted) setState(() => upgradingToLandlord = false);
    }
  }
}

class _UpgradeToLandlordDialog extends StatefulWidget {
  final String defaultName;
  const _UpgradeToLandlordDialog({required this.defaultName});

  @override
  State<_UpgradeToLandlordDialog> createState() =>
      _UpgradeToLandlordDialogState();
}

class _UpgradeToLandlordDialogState extends State<_UpgradeToLandlordDialog> {
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
      'Đăng ký trở thành Chủ trọ',
      style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w700),
    ),
    content: SingleChildScrollView(
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tài khoản của bạn sẽ mở khóa chế độ quản lý phòng trọ riêng biệt theo tài khoản này, đồng thời vẫn chuyển qua lại được với chế độ Người thuê.',
              style: TextStyle(color: muted, fontSize: 12),
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
        child: const Text('Xác nhận'),
      ),
    ],
  );
}
