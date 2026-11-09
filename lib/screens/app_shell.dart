import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
  bool checking = false;
  bool tenantLinking = false;
  Future<Map<String, dynamic>>? tenantPortalFuture;
  Future<Map<String, dynamic>>? tenantLookupFuture;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBilling());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkBilling();
  }

  Future<void> _checkBilling() async {
    if (!widget.landlord || checking) return;
    checking = true;
    try {
      await store.command('runBilling');
    } catch (e) {
      if (mounted) message(context, 'Chưa kiểm tra được hóa đơn: $e');
    } finally {
      checking = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.landlord) return _tenantView(context);
    final pages = [
      const RoomPage(),
      const TenantListPage(),
      ServicePage(onNavigate: (v) => setState(() => index = v)),
      const InvoicePage(),
      const ContractPage(),
      const MaintenancePage(),
      const AccountPage(),
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

  Widget _tenantView(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    appBar: AppBar(
      title: Text(tenantTabLabels[tenantIndex]),
      actions: [
        const NotificationButton(landlord: false),
        if (FirebaseAuth.instance.currentUser?.emailVerified == true)
          IconButton(
            tooltip: 'Làm mới dữ liệu',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: tenantPortalFuture == null
                ? null
                : () =>
                      setState(() => tenantPortalFuture = store.tenantPortal()),
          ),
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
          },
        ),
      ],
    ),
    body: FirebaseAuth.instance.currentUser?.emailVerified == true
        ? _tenantProfile(context)
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [_emailVerificationCard(context)],
          ),
    bottomNavigationBar:
        FirebaseAuth.instance.currentUser?.emailVerified == true
        ? TenantPortalBottomBar(
            selectedIndex: tenantIndex,
            onTap: (value) => setState(() => tenantIndex = value),
          )
        : null,
  );

  Widget _emailVerificationCard(BuildContext context) => box(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Xác minh email để liên kết hồ sơ thuê',
          style: TextStyle(
            color: ink,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tài khoản: ${FirebaseAuth.instance.currentUser?.email ?? ''}',
          style: const TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 6),
        const Text(
          'Mở email xác minh do Firebase gửi. Sau khi xác minh, quay lại ứng dụng và bấm nút bên dưới.',
          style: TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.currentUser
                      ?.sendEmailVerification();
                  if (context.mounted) {
                    message(context, 'Đã gửi lại email xác minh');
                  }
                } catch (error) {
                  if (context.mounted) message(context, errorText(error));
                }
              },
              child: const Text('Gửi lại email xác minh'),
            ),
            FilledButton.tonal(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.currentUser?.reload();
                  await FirebaseAuth.instance.currentUser?.getIdToken(true);
                  if (context.mounted) setState(() {});
                  if (FirebaseAuth.instance.currentUser?.emailVerified !=
                          true &&
                      context.mounted) {
                    message(context, 'Email chưa được xác minh');
                  }
                } catch (error) {
                  if (context.mounted) message(context, errorText(error));
                }
              },
              child: const Text('Tôi đã xác minh'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _tenantProfile(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser!.email!
        .trim()
        .toLowerCase();
    tenantLookupFuture ??= store.tenantPortal(action: 'lookup');
    return FutureBuilder<Map<String, dynamic>>(
      future: tenantLookupFuture,
      builder: (context, lookup) {
        if (lookup.hasError) {
          return _tenantMessageCard(
            title: 'Không kiểm tra được hồ sơ thuê',
            detail:
                '${errorText(lookup.error)}\nHãy thử lại. Nếu lỗi tiếp tục, quản trị viên cần triển khai Cloud Functions mới nhất.',
            action: TextButton.icon(
              onPressed: () => setState(
                () => tenantLookupFuture = store.tenantPortal(action: 'lookup'),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
            ),
          );
        }
        if (!lookup.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final profiles = (lookup.data!['profiles'] as List? ?? const [])
            .whereType<Map>()
            .map((profile) => Map<String, dynamic>.from(profile))
            .toList();
        if (profiles.isEmpty) {
          return _tenantMessageCard(
            title: 'Chưa tìm thấy hồ sơ thuê',
            detail:
                'Đang đăng nhập bằng $email. Hãy nhờ chủ trọ kiểm tra hồ sơ còn hoạt động, gán phòng và nhập đúng email đăng nhập này.',
          );
        }
        if (profiles.length > 1) {
          return _tenantMessageCard(
            title: 'Email này trùng trên nhiều hồ sơ',
            detail:
                'Hãy nhờ chủ trọ kiểm tra và giữ email đăng nhập trên đúng một hồ sơ thuê.',
          );
        }

        final tenant = profiles.single;
        final tenantId = '${tenant['id'] ?? ''}';
        final linkedUid = '${tenant['authUid'] ?? ''}';
        if (linkedUid == store.uid) {
          tenantPortalFuture ??= store.tenantPortal();
          return FutureBuilder<Map<String, dynamic>>(
            future: tenantPortalFuture,
            builder: (_, snapshot) {
              if (snapshot.hasError) {
                return _tenantMessageCard(
                  title: 'Chưa tải được thông tin thuê',
                  detail: errorText(snapshot.error),
                  action: TextButton.icon(
                    onPressed: () => setState(
                      () => tenantPortalFuture = store.tenantPortal(),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Thử lại'),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return TenantPortalContent(
                index: tenantIndex,
                data: snapshot.data!,
                onNavigate: (value) => setState(() => tenantIndex = value),
                onRefresh: () =>
                    setState(() => tenantPortalFuture = store.tenantPortal()),
              );
            },
          );
        }

        return _tenantMessageCard(
          title: 'Xác nhận hồ sơ thuê của bạn',
          detail: linkedUid.isEmpty
              ? '${tenant['name'] ?? ''} · ${tenant['email'] ?? email}'
              : 'Hồ sơ này đã liên kết với tài khoản khác. Hãy liên hệ chủ trọ để kiểm tra.',
          action: linkedUid.isEmpty
              ? FilledButton.icon(
                  onPressed: tenantLinking
                      ? null
                      : () => _linkTenantByEmail(context, tenantId),
                  icon: tenantLinking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.link_rounded, size: 18),
                  label: Text(
                    tenantLinking ? 'Đang liên kết...' : 'Liên kết bằng email',
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _tenantMessageCard({
    required String title,
    required String detail,
    Widget? action,
  }) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      box(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(detail, style: const TextStyle(color: muted, fontSize: 12)),
            if (action != null) ...[const SizedBox(height: 8), action],
          ],
        ),
      ),
    ],
  );

  Future<void> _linkTenantByEmail(BuildContext context, String tenantId) async {
    setState(() => tenantLinking = true);
    try {
      final result = await store.linkCurrentTenantByEmail(tenantId);
      if (!context.mounted) return;
      setState(() {
        tenantPortalFuture = store.tenantPortal();
        tenantLookupFuture = store.tenantPortal(action: 'lookup');
      });
      message(
        context,
        'Đã liên kết hồ sơ ${result['tenantName']}. Hãy nhờ chủ trọ gửi lại các hóa đơn đã tạo trước đó.',
      );
    } catch (error) {
      if (!context.mounted) return;
      message(context, errorText(error));
    } finally {
      if (mounted) setState(() => tenantLinking = false);
    }
  }
}
