import 'package:flutter/material.dart';
import 'invoice_screen.dart';
import 'maintenance_screen.dart';

class TenantDetailScreen extends StatelessWidget {
  const TenantDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      // =========================
      // APP BAR
      // =========================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Chi tiết người thuê',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Chỉnh sửa',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),

      // =========================
      // BODY
      // =========================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // =========================
            // THÔNG TIN CƠ BẢN
            // =========================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),

              child: Column(
                children: [

                  // Avatar
                  Container(
                    width: 70,
                    height: 70,

                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F0FE),
                      shape: BoxShape.circle,
                    ),

                    child: const Center(
                      child: Text(
                        'NA',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tên
                  const Text(
                    'Nguyễn Văn An',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Phòng
                  const Text(
                    'Phòng 101 - Khu A',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Trạng thái
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),

                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: const Text(
                      'Đang thuê',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Bắt đầu thuê: 01/06/2026',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // =========================
            // THÔNG TIN LIÊN HỆ
            // =========================

            const Text(
              'Thông tin liên hệ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),

              child: Column(
                children: [

                  infoRow(
                    Icons.phone,
                    'Số điện thoại',
                    '0901234567',
                  ),

                  const Divider(height: 28),

                  infoRow(
                    Icons.email,
                    'Email',
                    'nguyenvanan@gmail.com',
                  ),

                  const Divider(height: 28),

                  infoRow(
                    Icons.location_on,
                    'Địa chỉ',
                    'Quảng Bình',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // =========================
            // THÔNG TIN THUÊ PHÒNG
            // =========================

            const Text(
              'Thông tin thuê phòng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),

              child: Column(
                children: [

                  infoRow(
                    Icons.meeting_room,
                    'Phòng',
                    '101 - Khu A',
                  ),

                  const Divider(height: 28),

                  infoRow(
                    Icons.attach_money,
                    'Tiền phòng',
                    '3.000.000 đ / tháng',
                  ),

                  const Divider(height: 28),

                  infoRow(
                    Icons.account_balance_wallet,
                    'Tiền cọc',
                    '3.000.000 đ',
                  ),

                  const Divider(height: 28),

                  infoRow(
                    Icons.calendar_month,
                    'Ngày bắt đầu',
                    '01/06/2026',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // =========================
            // NHÓM CHỨC NĂNG
            // =========================

            const Text(
              'Chức năng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // =========================
            // HÓA ĐƠN + BẢO TRÌ
            // =========================

            Row(
              children: [

                // HÓA ĐƠN
                Expanded(
                  child: functionButton(
                    icon: Icons.receipt_long,
                    title: 'Hóa đơn',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InvoiceScreen(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                // BẢO TRÌ
                Expanded(
                  child: functionButton(
                    icon: Icons.build,
                    title: 'Bảo trì',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MaintenanceScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // =========================
  // WIDGET THÔNG TIN
  // =========================

  static Widget infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      children: [

        Container(
          width: 40,
          height: 40,

          decoration: BoxDecoration(
            color: const Color(0xFFF1F3F5),
            borderRadius: BorderRadius.circular(10),
          ),

          child: Icon(
            icon,
            color: Colors.blue,
            size: 20,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================
  // NÚT CHỨC NĂNG
  // =========================

  static Widget functionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(14),

      child: Container(
        width: double.infinity,

        padding: const EdgeInsets.symmetric(
          vertical: 16,
        ),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
          ),
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Icon(
              icon,
              color: Colors.blue,
              size: 21,
            ),

            const SizedBox(width: 8),

            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}