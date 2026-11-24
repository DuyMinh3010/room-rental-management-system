import 'dart:async';

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
  bool confirmingTransfer = false;
  bool upgradingToLandlord = false;
  final inviteController = TextEditingController();
  String? inviteError;
  Future<Map<String, dynamic>?>? tenantPortalFuture;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userMappingSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _tenantDocSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _tenantUidQuerySub;
  String? _watchedTenantId;
  String _mappedRoomId = '';
  Map<String, dynamic>? _latestTenantDoc;
  bool _latestTenantExists = false;
  String? _lastTenantStateKey;
  bool? _lastPendingTransfer;

  @override
  void initState() {
    super.initState();
    _landlordMode = widget.landlord && (preferredLandlordMode.value ?? true);
    WidgetsBinding.instance.addObserver(this);
    _setupTenantRealtimeWatch();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBilling());
  }

  void _setupTenantRealtimeWatch() {
    _cancelTenantRealtimeWatch();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _userMappingSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snap) {
          final data = snap.data();
          final tid = '${data?['tenantId'] ?? ''}'.trim();
          _mappedRoomId = '${data?['roomId'] ?? ''}'.trim();
          if (tid.isNotEmpty) {
            _tenantUidQuerySub?.cancel();
            _tenantUidQuerySub = null;
            if (_watchedTenantId == tid && _tenantDocSub != null) {
              _evaluateWatchedTenant();
            } else {
              _watchTenantDocument(tid);
            }
          } else {
            _watchTenantByUidFallback(user.uid);
          }
        }, onError: (_) {});
  }

  void _watchTenantByUidFallback(String uid) {
    if (_tenantUidQuerySub != null) return;
    _tenantDocSub?.cancel();
    _tenantDocSub = null;
    _watchedTenantId = null;
    _latestTenantDoc = null;
    _latestTenantExists = false;
    _tenantUidQuerySub = FirebaseFirestore.instance
        .collection('tenants')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((snap) {
          final activeDoc = snap.docs
              .where((d) => d.data()['archived'] != true)
              .firstOrNull;
          if (activeDoc == null) {
            _onTenantRealtimeChanged(
              stateKey: 'none',
              pendingTransfer: false,
            );
            return;
          }
          final t = activeDoc.data();
          final roomId = '${t['roomId'] ?? ''}'.trim();
          final pending = t['pendingRoomTransfer'] == true;
          _onTenantRealtimeChanged(
            stateKey: '${activeDoc.id}|$roomId|$pending|false',
            pendingTransfer: pending,
          );
        }, onError: (_) {});
  }

  void _watchTenantDocument(String tenantId) {
    _watchedTenantId = tenantId;
    _latestTenantDoc = null;
    _latestTenantExists = false;
    _tenantDocSub?.cancel();
    _tenantDocSub = FirebaseFirestore.instance
        .collection('tenants')
        .doc(tenantId)
        .snapshots()
        .listen((snap) {
          _latestTenantExists = snap.exists;
          _latestTenantDoc = snap.data();
          _evaluateWatchedTenant();
        }, onError: (_) {});
  }

  void _evaluateWatchedTenant() {
    final tenantId = _watchedTenantId;
    if (tenantId == null) return;
    final t = _latestTenantDoc;
    if (!_latestTenantExists || t == null) {
      _onTenantRealtimeChanged(stateKey: 'missing', pendingTransfer: false);
      return;
    }
    final roomId = '${t['roomId'] ?? ''}'.trim();
    final archived = t['archived'] == true;
    final pending =
        !archived &&
        (t['pendingRoomTransfer'] == true ||
            (_mappedRoomId.isNotEmpty &&
                roomId.isNotEmpty &&
                _mappedRoomId != roomId));
    _onTenantRealtimeChanged(
      stateKey: '$tenantId|$_mappedRoomId|$roomId|$pending|$archived',
      pendingTransfer: pending,
    );
  }

  void _onTenantRealtimeChanged({
    required String stateKey,
    required bool pendingTransfer,
  }) {
    final prevKey = _lastTenantStateKey;
    final prevPending = _lastPendingTransfer;
    _lastTenantStateKey = stateKey;
    _lastPendingTransfer = pendingTransfer;
    if (prevKey == null || prevKey == stateKey) return;
    if (!mounted || _landlordMode) return;

    if (pendingTransfer && prevPending != true) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          message(
            context,
            'Chủ trọ vừa chuyển phòng của bạn. Vui lòng xác nhận để xem thông tin phòng mới.',
          );
        }
      });
    }
    setState(() {
      tenantIndex = 0;
      tenantPortalFuture = store.loadTenantPortalOrNull();
    });
  }

  void _cancelTenantRealtimeWatch() {
    _userMappingSub?.cancel();
    _userMappingSub = null;
    _tenantDocSub?.cancel();
    _tenantDocSub = null;
    _tenantUidQuerySub?.cancel();
    _tenantUidQuerySub = null;
    _watchedTenantId = null;
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
    _cancelTenantRealtimeWatch();
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
        final isPendingTransfer = portalData?['pendingRoomTransfer'] == true;
        final hasPortal = portalData != null && !isPendingTransfer;
        return Scaffold(
          backgroundColor: canvas,
          appBar: AppBar(
            title: Text(
              isPendingTransfer
                  ? 'Chuyển phòng'
                  : hasPortal
                  ? tenantTabLabels[tenantIndex]
                  : 'Người thuê',
            ),
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
            if (isPendingTransfer) {
              return _pendingTransferView(context, portalData!);
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

  Widget _pendingTransferView(
    BuildContext context,
    Map<String, dynamic> transferData,
  ) {
    final fromNameRaw = '${transferData['fromRoomName'] ?? ''}'.trim();
    final toNameRaw = '${transferData['toRoomName'] ?? ''}'.trim();
    final fromLabel = fromNameRaw.isEmpty ? 'Phòng cũ' : fromNameRaw;
    final toLabel = toNameRaw.isEmpty ? 'Phòng mới' : toNameRaw;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: blue.withValues(alpha: 0.4), width: 1.1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: softBlue,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      color: blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thông báo chuyển phòng',
                          style: TextStyle(
                            color: ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Cần xác nhận để mở dashboard phòng mới',
                          style: TextStyle(
                            color: blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: canvas,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: line),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'PHÒNG CŨ',
                            style: TextStyle(
                              color: muted,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fromLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: blue,
                        size: 22,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'PHÒNG MỚI',
                            style: TextStyle(
                              color: blue,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            toLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: blue,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Chủ trọ đã chuyển bạn từ $fromLabel sang $toLabel. '
                'Vui lòng nhấn nút xác nhận bên dưới để xem thông tin phòng mới. '
                'Khi chưa xác nhận, bạn sẽ không xem được thông tin của bất kỳ phòng nào.',
                style: const TextStyle(color: muted, fontSize: 12.5, height: 1.45),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: confirmingTransfer
                      ? null
                      : () => _confirmRoomTransfer(toLabel),
                  icon: confirmingTransfer
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline_rounded, size: 19),
                  label: Text(
                    confirmingTransfer
                        ? 'Đang xác nhận...'
                        : 'Xác nhận chuyển sang $toLabel',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmRoomTransfer(String toRoomLabel) async {
    if (confirmingTransfer) return;
    setState(() => confirmingTransfer = true);
    try {
      await store.confirmRoomTransfer();
      if (!mounted) return;
      setState(() {
        tenantIndex = 0;
        tenantPortalFuture = store.loadTenantPortalOrNull();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          message(
            context,
            'Đã xác nhận chuyển phòng! Chào mừng bạn đến $toRoomLabel.',
          );
        }
      });
    } catch (e) {
      if (mounted) message(context, errorText(e));
    } finally {
      if (mounted) setState(() => confirmingTransfer = false);
    }
  }

  Widget _inviteCodeCard(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return box(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nhập mã mời dãy trọ',
            style: TextStyle(
              color: ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tài khoản $email chưa liên kết với phòng nào. Hãy nhập mã mời cố định của dãy trọ do chủ trọ cung cấp — hệ thống sẽ tự động đối chiếu email này để đưa bạn vào đúng phòng.',
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
              hintText: 'Nhập mã mời dãy trọ (VD: A7K92P)',
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
                joiningByInvite
                    ? 'Đang đối chiếu mã mời & email...'
                    : 'Xác nhận mã mời & Vào phòng',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinByInviteCode(BuildContext context) async {
    if (joiningByInvite) return;
    final raw = inviteController.text.trim().toUpperCase();
    if (raw.isEmpty) {
      setState(() => inviteError = 'Vui lòng nhập mã mời từ chủ trọ');
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
            ? 'Chưa đủ quyền truy cập Firestore. Hãy triển khai firestore.rules mới nhất.'
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
      await store.createManagerAccount(
        uid: user.uid,
        name: ownerName,
        email: normalizedEmail,
        phone: submitted['phone'] ?? '',
      );
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
