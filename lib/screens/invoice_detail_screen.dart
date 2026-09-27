import 'package:flutter/material.dart';

import 'create_invoice_screen.dart';
import 'maintenance_screen.dart';
import 'tenant_detail_screen.dart';

class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({super.key});

  @override
  State<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState
    extends State<InvoiceDetailScreen> {
  bool isPaid = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // HEADER
                      Row(
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints:
                                const BoxConstraints(),
                            onPressed: () {
                              Navigator.maybePop(context);
                            },
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 20,
                              color: Color(0xFF111827),
                            ),
                          ),

                          const SizedBox(width: 18),

                          const Expanded(
                            child: Text(
                              'Chi tiết hóa đơn',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight:
                                    FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),

                          Container(
                            height: 26,
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? const Color(0xFFEAF8EE)
                                  : const Color(0xFFFDECEC),
                              borderRadius:
                                  BorderRadius.circular(13),
                            ),
                            child: Text(
                              isPaid
                                  ? 'Đã thanh toán'
                                  : 'Chưa thanh toán',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.w600,
                                color: isPaid
                                    ? const Color(
                                        0xFF16A34A,
                                      )
                                    : const Color(
                                        0xFFDC2626,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 34),

                      // THÔNG TIN HÓA ĐƠN
                      Container(
                        width: double.infinity,
                        height: 128,
                        padding:
                            const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(18),
                        ),
                        child: const Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tháng 09/2026',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Color(0xFF6B7280),
                              ),
                            ),

                            SizedBox(height: 8),

                            Text(
                              '2.840.000đ',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight:
                                    FontWeight.w600,
                                color:
                                    Color(0xFF111827),
                              ),
                            ),

                            SizedBox(height: 10),

                            Text(
                              'Hạn thanh toán 05/09/2026',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'Chi tiết tính tiền',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // CHI TIẾT TIỀN
                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFF5F5F5),
                          borderRadius:
                              BorderRadius.circular(18),
                        ),
                        child: const Column(
                          children: [
                            BillRow(
                              label: 'Tiền phòng',
                              value: '2.500.000đ',
                            ),

                            Divider(
                              height: 1,
                              color:
                                  Color(0xFFE5E7EB),
                            ),

                            BillRow(
                              label:
                                  'Điện · 126 kWh × 3.000đ',
                              value: '378.000đ',
                            ),

                            Divider(
                              height: 1,
                              color:
                                  Color(0xFFE5E7EB),
                            ),

                            BillRow(
                              label:
                                  'Nước · 7 m³ × 15.000đ',
                              value: '105.000đ',
                            ),

                            Divider(
                              height: 1,
                              color:
                                  Color(0xFFE5E7EB),
                            ),

                            BillRow(
                              label: 'Phí dịch vụ',
                              value: '120.000đ',
                            ),

                            Divider(
                              height: 1,
                              color:
                                  Color(0xFFE5E7EB),
                            ),

                            BillRow(
                              label: 'Giảm trừ',
                              value: '−263.000đ',
                              isDiscount: true,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // TỔNG CỘNG
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(
                          horizontal: 2,
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                            Text(
                              'Tổng cộng',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    FontWeight.w600,
                                color:
                                    Color(0xFF111827),
                              ),
                            ),

                            Text(
                              '2.840.000đ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.w600,
                                color:
                                    Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 78),

                      // THANH TOÁN
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isPaid
                              ? null
                              : () {
                                  showPaymentDialog(
                                    context,
                                  );
                                },
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(
                              0xFF4285F4,
                            ),
                            disabledBackgroundColor:
                                const Color(
                              0xFFB7C7E5,
                            ),
                            foregroundColor:
                                Colors.white,
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(14),
                            ),
                          ),
                          child: Text(
                            isPaid
                                ? 'Đã thanh toán'
                                : 'Thanh toán',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),

            const InvoiceDetailBottomNavigation(),
          ],
        ),
      ),
    );
  }

  void showPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Text(
            'Xác nhận thanh toán',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'Xác nhận thanh toán hóa đơn tháng 09/2026 với số tiền 2.840.000đ?',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Hủy'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                setState(() {
                  isPaid = true;
                });

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Thanh toán thành công',
                    ),
                    duration:
                        Duration(seconds: 2),
                  ),
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              child:
                  const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }
}

// =====================================
// DÒNG CHI TIẾT HÓA ĐƠN
// =====================================

class BillRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDiscount;

  const BillRow({
    super.key,
    required this.label,
    required this.value,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isDiscount
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF111827),
              ),
            ),
          ),

          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isDiscount
                  ? FontWeight.w600
                  : FontWeight.w400,
              color: isDiscount
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF111827),
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

class InvoiceDetailBottomNavigation
    extends StatelessWidget {
  const InvoiceDetailBottomNavigation({
    super.key,
  });

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
        mainAxisAlignment:
            MainAxisAlignment.spaceAround,
        children: [
          const InvoiceDetailNavItem(
            icon: Icons.home_outlined,
            label: 'Tổng quan',
          ),

          InvoiceDetailNavItem(
            icon:
                Icons.grid_view_outlined,
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

          InvoiceDetailNavItem(
            icon: Icons.attach_money,
            label: 'Hóa đơn',
            active: true,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const CreateInvoiceScreen(),
                ),
              );
            },
          ),

          InvoiceDetailNavItem(
            icon:
                Icons.handyman_outlined,
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

          const InvoiceDetailNavItem(
            icon: Icons.circle,
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}

// =====================================
// ITEM BOTTOM NAV
// =====================================

class InvoiceDetailNavItem
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const InvoiceDetailNavItem({
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
      borderRadius:
          BorderRadius.circular(14),
      child: SizedBox(
        width: 65,
        height: 70,
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: active ? 40 : 28,
              height: 28,
              decoration: BoxDecoration(
                color: active
                    ? const Color(
                        0xFFEAF1FF,
                      )
                    : Colors.transparent,
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: Icon(
                icon,
                size: 18,
                color: active
                    ? const Color(
                        0xFF2563EB,
                      )
                    : const Color(
                        0xFF6B7280,
                      ),
              ),
            ),

            const SizedBox(height: 4),

            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: active
                    ? const Color(
                        0xFF2563EB,
                      )
                    : const Color(
                        0xFF6B7280,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}