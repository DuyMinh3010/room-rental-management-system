import 'package:flutter/material.dart';

import 'room_list_screen.dart';
import 'tenant_list_screen.dart';
import 'service_list_screen.dart';
import 'invoice_list_screen.dart';
import 'contract_list_screen.dart';
import 'maintenance_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2563EB);
    const textColor = Color(0xFF111827);
    const secondary = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  22,
                  20,
                  30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================= HEADER =================
                    const Text(
                      'Tài khoản',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Thông tin cá nhân & cài đặt',
                      style: TextStyle(
                        fontSize: 11,
                        color: secondary,
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ================= PROFILE =================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEAF1FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              'NA',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: blue,
                              ),
                            ),
                          ),

                          const SizedBox(width: 14),

                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nguyễn Minh Chiến',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Phòng 101 · Người thuê',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFFE8F8EE),
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                            child: const Text(
                              'Đang thuê',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight:
                                    FontWeight.w600,
                                color:
                                    Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ============ THÔNG TIN CÁ NHÂN ============
                    _accountItem(
                      context,
                      icon: Icons.person_outline,
                      title: 'Thông tin cá nhân',
                      subtitle:
                          'Tên, số điện thoại, email',
                      onTap: () {
                        _showMessage(
                          context,
                          'Thông tin cá nhân',
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    // ============ HỢP ĐỒNG ============
                    _accountItem(
                      context,
                      icon:
                          Icons.description_outlined,
                      title: 'Hợp đồng & đặt cọc',
                      subtitle:
                          'Xem thông tin thuê phòng',
                      onTap: () {
                        _showMessage(
                          context,
                          'Thông tin hợp đồng & đặt cọc',
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    // ============ THÔNG BÁO ============
                    _accountItem(
                      context,
                      icon:
                          Icons.notifications_none,
                      title: 'Thông báo',
                      subtitle:
                          'Cài đặt nhắc nhở',
                      selected: true,
                      onTap: () {
                        _showNotificationSettings(
                          context,
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    // ============ BẢO MẬT ============
                    _accountItem(
                      context,
                      icon: Icons.lock_outline,
                      title: 'Bảo mật',
                      subtitle: 'Đổi mật khẩu',
                      onTap: () {
                        _showPasswordDialog(
                          context,
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    // ============ ĐĂNG XUẤT ============
                    _accountItem(
                      context,
                      icon: Icons.logout,
                      title: 'Đăng xuất',
                      subtitle: '',
                      danger: true,
                      onTap: () {
                        _showLogoutDialog(
                          context,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const _AccountBottomNavigation(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACCOUNT ITEM
  // ============================================================

  Widget _accountItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool selected = false,
    bool danger = false,
  }) {
    const blue = Color(0xFF2563EB);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? Border.all(
                  color: blue,
                  width: 1.4,
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: danger
                    ? const Color(0xFFFFEEEE)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 19,
                color: danger
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF475569),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: danger
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF111827),
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Icon(
              Icons.chevron_right,
              size: 20,
              color: danger
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // NOTIFICATION SETTINGS
  // ============================================================

  void _showNotificationSettings(
    BuildContext context,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (sheetContext) {
        return const _NotificationSheet();
      },
    );
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  void _showPasswordDialog(
    BuildContext context,
  ) {
    final oldPassword =
        TextEditingController();
    final newPassword =
        TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
          title: const Text(
            'Đổi mật khẩu',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPassword,
                obscureText: true,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Mật khẩu hiện tại',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPassword,
                obscureText: true,
                decoration:
                    const InputDecoration(
                  labelText: 'Mật khẩu mới',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (oldPassword.text
                        .trim()
                        .isEmpty ||
                    newPassword.text
                        .trim()
                        .isEmpty) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                );

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Đã cập nhật mật khẩu',
                    ),
                  ),
                );
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  void _showLogoutDialog(
    BuildContext context,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
          title: const Text('Đăng xuất'),
          content: const Text(
            'Bạn có chắc muốn đăng xuất khỏi tài khoản?',
            style: TextStyle(
              fontSize: 12,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Chức năng đăng xuất sẽ kết nối khi hoàn thiện đăng nhập',
                    ),
                  ),
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                        0xFFEF4444),
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// NOTIFICATION SHEET
// ============================================================

class _NotificationSheet
    extends StatefulWidget {
  const _NotificationSheet();

  @override
  State<_NotificationSheet> createState() =>
      _NotificationSheetState();
}

class _NotificationSheetState
    extends State<_NotificationSheet> {
  bool invoiceNotification = true;
  bool maintenanceNotification = true;
  bool contractNotification = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          24,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color:
                    const Color(0xFFD1D5DB),
                borderRadius:
                    BorderRadius.circular(4),
              ),
            ),

            const SizedBox(height: 18),

            const Align(
              alignment:
                  Alignment.centerLeft,
              child: Text(
                'Cài đặt thông báo',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 10),

            SwitchListTile(
              contentPadding:
                  EdgeInsets.zero,
              title: const Text(
                'Nhắc thanh toán hóa đơn',
                style:
                    TextStyle(fontSize: 12),
              ),
              value: invoiceNotification,
              onChanged: (value) {
                setState(() {
                  invoiceNotification =
                      value;
                });
              },
            ),

            SwitchListTile(
              contentPadding:
                  EdgeInsets.zero,
              title: const Text(
                'Cập nhật bảo trì',
                style:
                    TextStyle(fontSize: 12),
              ),
              value:
                  maintenanceNotification,
              onChanged: (value) {
                setState(() {
                  maintenanceNotification =
                      value;
                });
              },
            ),

            SwitchListTile(
              contentPadding:
                  EdgeInsets.zero,
              title: const Text(
                'Nhắc hợp đồng',
                style:
                    TextStyle(fontSize: 12),
              ),
              value:
                  contractNotification,
              onChanged: (value) {
                setState(() {
                  contractNotification =
                      value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BOTTOM NAVIGATION
// ============================================================

class _AccountBottomNavigation
    extends StatelessWidget {
  const _AccountBottomNavigation();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Row(
        children: [
          // PHÒNG
          _AccountNavItem(
            icon: Icons.home_outlined,
            label: 'Phòng',
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const RoomListScreen(),
                ),
              );
            },
          ),

          // NGƯỜI THUÊ
          _AccountNavItem(
            icon: Icons.people_outline,
            label: 'Người thuê',
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const TenantListScreen(),
                ),
              );
            },
          ),

          // DỊCH VỤ
          _AccountNavItem(
            icon: Icons.circle,
            label: 'Dịch vụ',
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const ServiceListScreen(),
                ),
              );
            },
          ),

          // HÓA ĐƠN
          _AccountNavItem(
            icon:
                Icons.receipt_long_outlined,
            label: 'Hóa đơn',
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const InvoiceListScreen(),
                ),
              );
            },
          ),

          // HỢP ĐỒNG
          _AccountNavItem(
            icon:
                Icons.description_outlined,
            label: 'Hợp đồng',
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const ContractListScreen(),
                ),
              );
            },
          ),

          // BẢO TRÌ
          _AccountNavItem(
            icon:
                Icons.handyman_outlined,
            label: 'Bảo trì',
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const MaintenanceScreen(),
                ),
              );
            },
          ),

          // TÀI KHOẢN
          const _AccountNavItem(
            icon:
                Icons.settings_outlined,
            label: 'Tài khoản',
            active: true,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// NAV ITEM
// ============================================================

class _AccountNavItem
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _AccountNavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const blue =
        Color(0xFF2563EB);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 70,
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                width:
                    active ? 38 : 28,
                height: 27,
                decoration:
                    BoxDecoration(
                  color: active
                      ? const Color(
                          0xFFE8F0FF)
                      : Colors.transparent,
                  borderRadius:
                      BorderRadius
                          .circular(14),
                ),
                child: Icon(
                  icon,
                  size: 17,
                  color: active
                      ? blue
                      : const Color(
                          0xFF64748B),
                ),
              ),

              const SizedBox(height: 3),

              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: active
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: active
                        ? blue
                        : const Color(
                            0xFF64748B),
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