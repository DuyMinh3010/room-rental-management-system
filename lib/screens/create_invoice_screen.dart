import 'package:flutter/material.dart';

import 'invoice_detail_screen.dart';
import 'maintenance_screen.dart';
import 'meter_reading_screen.dart';
import 'tenant_detail_screen.dart';

class CreateInvoiceScreen extends StatelessWidget {
  const CreateInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // HEADER
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.maybePop(context);
                          },
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 18,
                            color: Color(0xFF6B717E),
                          ),
                        ),

                        const Expanded(
                          child: Text(
                            'Tạo hóa đơn mới',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),

                        const SizedBox(width: 48),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // CHỌN PHÒNG
                    const Text(
                      'Chọn phòng',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 6),

                    _selectorBox(
                      text: 'P.102 · Trần Minh Huy',
                      trailing: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: Color(0xFF6B717E),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // KỲ HÓA ĐƠN
                    const Text(
                      'Kỳ hóa đơn',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 6),

                    _selectorBox(
                      text: 'Tháng 10/2025',
                      trailing: const Icon(
                        Icons.calendar_month,
                        size: 22,
                        color: Color(0xFF6B717E),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Thông tin hóa đơn',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // BẤM VÀO KHỐI NÀY
                    // -> NHẬP CHỈ SỐ ĐIỆN NƯỚC
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const MeterReadingScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(
                          22,
                          16,
                          16,
                          14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC8D9FA),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Column(
                          children: [
                            _InvoiceRow(
                              label: 'Tiền phòng',
                              value: '2.500.000đ',
                            ),

                            Divider(height: 1),

                            _InvoiceRow(
                              label: 'Tiền điện (31 kWh x 3.500đ)',
                              value: '250.000đ',
                            ),

                            Divider(height: 1),

                            _InvoiceRow(
                              label: 'Tiền nước (3 m³ x 20.000đ)',
                              value: '75.000đ',
                            ),

                            Divider(height: 1),

                            _InvoiceRow(
                              label: 'Tiền Internet',
                              value: '100.000đ',
                            ),

                            Divider(height: 1),

                            _InvoiceRow(
                              label: 'Dịch vụ chung',
                              value: '50.000đ',
                            ),

                            Divider(
                              height: 18,
                              thickness: 1,
                              color: Color(0xFF111827),
                            ),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Tổng tiền',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            SizedBox(height: 8),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tổng Cộng',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),

                                Text(
                                  '2.975.000đ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 28),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Hạn thanh toán : 10/10/2025',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // GHI CHÚ
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Text(
                        'Ghi chú',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Container(
                      height: 86,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6D6D6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Stack(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              'Nhập ghi chú cho hóa đơn...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B717E),
                              ),
                            ),
                          ),

                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              '0/200',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF939AA8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 64),

                    // TẠO VÀ GỬI HÓA ĐƠN
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const InvoiceDetailScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Tạo và gửi hóa đơn',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            const InvoiceBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _selectorBox({
    required String text,
    required Widget trailing,
  }) {
    return Container(
      height: 48,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF111827),
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

// =====================================
// DÒNG THÔNG TIN HÓA ĐƠN
// =====================================

class _InvoiceRow extends StatelessWidget {
  final String label;
  final String value;

  const _InvoiceRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),

          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================
// BOTTOM NAVIGATION
// =====================================

class InvoiceBottomNavigation extends StatelessWidget {
  const InvoiceBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E8ED),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // TỔNG QUAN
          const InvoiceBottomItem(
            icon: Icons.home_outlined,
            label: 'Tổng quan',
          ),

          // PHÒNG
          InvoiceBottomItem(
            icon: Icons.grid_view_outlined,
            label: 'Phòng',
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const TenantDetailScreen(),
                ),
              );
            },
          ),

          // HÓA ĐƠN
          const InvoiceBottomItem(
            icon: Icons.attach_money,
            label: 'Hóa đơn',
            active: true,
          ),

          // BẢO TRÌ
          InvoiceBottomItem(
            icon: Icons.handyman_outlined,
            label: 'Bảo trì',
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const MaintenanceScreen(),
                ),
              );
            },
          ),

          // TÀI KHOẢN
          const InvoiceBottomItem(
            icon: Icons.circle,
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}

// =====================================
// ITEM BOTTOM NAVIGATION
// =====================================

class InvoiceBottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const InvoiceBottomItem({
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
                    : const Color(0xFF6B717E),
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
                    : const Color(0xFF6B717E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}