import 'package:flutter/material.dart';

import 'create_invoice_screen.dart';
import 'tenant_detail_screen.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

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
                    const SizedBox(height: 22),

                    const Text(
                      'Bảo trì',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Theo dõi yêu cầu sửa chữa',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // BỘ LỌC
                    const SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          StatusFilter(
                            text: 'Tất cả 6',
                            background: Color(0xFFEAF1FF),
                            foreground: Color(0xFF2563EB),
                          ),

                          SizedBox(width: 14),

                          StatusFilter(
                            text: 'Mới 2',
                            background: Color(0xFFFDECEC),
                            foreground: Color(0xFFDC2626),
                          ),

                          SizedBox(width: 14),

                          StatusFilter(
                            text: 'Đang xử lý 3',
                            background: Color(0xFFFFF4E5),
                            foreground: Color(0xFFD97706),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    MaintenanceCard(
                      title: 'Máy lạnh không mát',
                      location: 'P.102 · Nguyễn Minh Huy',
                      update: 'Cập nhật: 10 phút trước',
                      status: 'Mới',
                      statusBackground: const Color(0xFFFDECEC),
                      statusColor: const Color(0xFFDC2626),
                      onTap: () {
                        showMaintenanceDetail(
                          context,
                          title: 'Máy lạnh không mát',
                          location: 'P.102 · Nguyễn Minh Huy',
                          status: 'Mới',
                          description:
                              'Máy lạnh hoạt động nhưng không làm mát. '
                              'Cần kiểm tra gas và bộ lọc.',
                        );
                      },
                    ),

                    const SizedBox(height: 14),

                    MaintenanceCard(
                      title: 'Rò rỉ vòi nước',
                      location: 'P.201 · Lê Thị Mai',
                      update: 'Cập nhật: hôm qua',
                      status: 'Đang xử lý',
                      statusBackground: const Color(0xFFFFF4E5),
                      statusColor: const Color(0xFFD97706),
                      onTap: () {
                        showMaintenanceDetail(
                          context,
                          title: 'Rò rỉ vòi nước',
                          location: 'P.201 · Lê Thị Mai',
                          status: 'Đang xử lý',
                          description:
                              'Vòi nước trong phòng tắm bị rò rỉ. '
                              'Đang chờ nhân viên kỹ thuật xử lý.',
                        );
                      },
                    ),

                    const SizedBox(height: 14),

                    MaintenanceCard(
                      title: 'Đèn hành lang hỏng',
                      location: 'Khu A · Tầng 2',
                      update: 'Cập nhật: 2 ngày trước',
                      status: 'Hoàn thành',
                      statusBackground: const Color(0xFFEAF8EE),
                      statusColor: const Color(0xFF16A34A),
                      onTap: () {
                        showMaintenanceDetail(
                          context,
                          title: 'Đèn hành lang hỏng',
                          location: 'Khu A · Tầng 2',
                          status: 'Hoàn thành',
                          description:
                              'Đèn hành lang tầng 2 đã được thay mới '
                              'và hoạt động bình thường.',
                        );
                      },
                    ),

                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),

            const MaintenanceBottomNavigation(),
          ],
        ),
      ),

      // NÚT THÊM YÊU CẦU
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 64),
        child: SizedBox(
          width: 58,
          height: 58,
          child: FloatingActionButton(
            onPressed: () {
              showAddMaintenanceDialog(context);
            },
            elevation: 0,
            backgroundColor: const Color(0xFF2563EB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.add,
              size: 30,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================
// BỘ LỌC TRẠNG THÁI
// =====================================

class StatusFilter extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const StatusFilter({
    super.key,
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}

// =====================================
// THẺ YÊU CẦU BẢO TRÌ
// =====================================

class MaintenanceCard extends StatelessWidget {
  final String title;
  final String location;
  final String update;
  final String status;
  final Color statusBackground;
  final Color statusColor;
  final VoidCallback? onTap;

  const MaintenanceCard({
    super.key,
    required this.title,
    required this.location,
    required this.update,
    required this.status,
    required this.statusBackground,
    required this.statusColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 128,
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  update,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),

                const Spacer(),

                Container(
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const Positioned(
              right: 0,
              bottom: 3,
              child: Icon(
                Icons.chevron_right,
                size: 22,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================
// BOTTOM NAVIGATION
// =====================================

class MaintenanceBottomNavigation extends StatelessWidget {
  const MaintenanceBottomNavigation({super.key});

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
          const MaintenanceNavItem(
            icon: Icons.home_outlined,
            label: 'Tổng quan',
          ),

          // PHÒNG
          MaintenanceNavItem(
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
          MaintenanceNavItem(
            icon: Icons.attach_money,
            label: 'Hóa đơn',
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

          // BẢO TRÌ
          const MaintenanceNavItem(
            icon: Icons.handyman_outlined,
            label: 'Bảo trì',
            active: true,
          ),

          // TÀI KHOẢN
          const MaintenanceNavItem(
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

class MaintenanceNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const MaintenanceNavItem({
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

// =====================================
// POPUP CHI TIẾT BẢO TRÌ
// =====================================

void showMaintenanceDetail(
  BuildContext context, {
  required String title,
  required String location,
  required String status,
  required String description,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              location,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Mô tả',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF6B7280),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

// =====================================
// POPUP THÊM YÊU CẦU BẢO TRÌ
// =====================================

void showAddMaintenanceDialog(BuildContext context) {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Thêm yêu cầu bảo trì',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Tiêu đề',
                  hintText: 'Ví dụ: Máy lạnh bị hỏng',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'Nhập nội dung cần sửa chữa',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
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

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Đã tạo yêu cầu bảo trì',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Tạo yêu cầu'),
          ),
        ],
      );
    },
  );
}