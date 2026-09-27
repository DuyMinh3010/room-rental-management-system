import 'package:flutter/material.dart';

import 'create_invoice_screen.dart';
import 'maintenance_screen.dart';

class TenantDetailScreen extends StatelessWidget {
  const TenantDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // HEADER
                    Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Navigator.maybePop(context);
                          },
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 20,
                            color: Color(0xFF111827),
                          ),
                        ),

                        const SizedBox(width: 14),

                        const Expanded(
                          child: Text(
                            'Thông tin thuê phòng',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),

                        Container(
                          height: 34,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF1FF),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: const Text(
                            'Chỉnh sửa',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // THÔNG TIN NGƯỜI THUÊ
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF1FF),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'NA',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 16),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Nguyễn Minh Chiến',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF111827),
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    const Text(
                                      'Phòng 101 · Khu A',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEAF8EE),
                                        borderRadius:
                                            BorderRadius.circular(13),
                                      ),
                                      child: const Text(
                                        'Đang thuê',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Hợp đồng thuê: ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  TextSpan(
                                    text: '01/06/2026 → 31/05/2027',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // THÔNG TIN LIÊN HỆ
                    const Text(
                      'Thông tin liên hệ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          TenantInfoRow(
                            label: 'Số điện thoại',
                            value: '090 123 4567',
                          ),

                          Divider(
                            height: 1,
                            color: Color(0xFFE5E7EB),
                          ),

                          TenantInfoRow(
                            label: 'Email',
                            value: 'chienday05@gmail.com',
                          ),

                          Divider(
                            height: 1,
                            color: Color(0xFFE5E7EB),
                          ),

                          TenantInfoRow(
                            label: 'CCCD',
                            value: '048203001234',
                          ),

                          Divider(
                            height: 1,
                            color: Color(0xFFE5E7EB),
                          ),

                          DetailLink(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // THÔNG TIN THUÊ PHÒNG
                    const Text(
                      'Thông tin thuê phòng',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          TenantInfoRow(
                            label: 'Tiền phòng',
                            value: '2.500.000đ / tháng',
                          ),

                          Divider(
                            height: 1,
                            color: Color(0xFFE5E7EB),
                          ),

                          TenantInfoRow(
                            label: 'Tiền đặt cọc',
                            value: '2.500.000đ',
                          ),

                          Divider(
                            height: 1,
                            color: Color(0xFFE5E7EB),
                          ),

                          TenantInfoRow(
                            label: 'Ngày bắt đầu thuê:',
                            value: '01/06/2026',
                          ),

                          Divider(
                            height: 1,
                            color: Color(0xFFE5E7EB),
                          ),

                          TenantInfoRow(
                            label: 'Ngày kết thúc :',
                            value: '31/05/2027',
                          ),

                          SizedBox(height: 30),

                          Divider(
                            height: 1,
                            color: Color(0xFFE5E7EB),
                          ),

                          DetailLink(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            const TenantBottomNavigation(),
          ],
        ),
      ),
    );
  }
}

// ================================
// ROW THÔNG TIN
// ================================

class TenantInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const TenantInfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ),

          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================
// XEM CHI TIẾT
// ================================

class DetailLink extends StatelessWidget {
  const DetailLink({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 28,
      child: Row(
        children: [
          Text(
            'Xem chi tiết',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF111827),
            ),
          ),

          SizedBox(width: 4),

          Icon(
            Icons.arrow_forward,
            size: 14,
            color: Color(0xFF111827),
          ),
        ],
      ),
    );
  }
}

// ================================
// BOTTOM NAVIGATION
// ================================

class TenantBottomNavigation extends StatelessWidget {
  const TenantBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // TỔNG QUAN
          const TenantNavItem(
            icon: Icons.home_outlined,
            label: 'Tổng quan',
          ),

          // PHÒNG - ĐANG ACTIVE
          const TenantNavItem(
            icon: Icons.grid_view_outlined,
            label: 'Phòng',
            active: true,
          ),

          // HÓA ĐƠN
          TenantNavItem(
            icon: Icons.attach_money,
            label: 'Hóa đơn',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const CreateInvoiceScreen(),
                ),
              );
            },
          ),

          // BẢO TRÌ
          TenantNavItem(
            icon: Icons.handyman_outlined,
            label: 'Bảo trì',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const MaintenanceScreen(),
                ),
              );
            },
          ),

          // TÀI KHOẢN
          const TenantNavItem(
            icon: Icons.circle,
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}

// ================================
// ITEM TRONG BOTTOM NAV
// ================================

class TenantNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const TenantNavItem({
    super.key,
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 65,
        height: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: active ? 40 : 28,
              height: 28,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFEAF1FF)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 18,
                color: active
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF6B7280),
              ),
            ),

            const SizedBox(height: 4),

            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.normal,
                color: active
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}