import 'package:flutter/material.dart';
import 'room_page.dart';
import 'invoice_page.dart';

class LandlordHomePage extends StatefulWidget {
  const LandlordHomePage({super.key});

  @override
  State<LandlordHomePage> createState() => _LandlordHomePageState();
}

class _LandlordHomePageState extends State<LandlordHomePage> {
  int selectedIndex = 0;

  // ============================================================
  // CÁC NÚT TRÊN TRANG CHỦ
  // ============================================================

  // NÚT: THÊM PHÒNG
  void btnAddRoom() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Bạn vừa bấm Thêm phòng"),
      ),
    );
  }

  // NÚT: XEM HÓA ĐƠN QUÁ HẠN
  void btnOverdueInvoices() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Mở danh sách hóa đơn quá hạn"),
      ),
    );
  }

  // NÚT: XEM YÊU CẦU BẢO TRÌ
  void btnMaintenanceRequests() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Mở danh sách yêu cầu bảo trì"),
      ),
    );
  }

  // ============================================================
  // CÁC NÚT MENU DƯỚI
  // ============================================================

  // MENU: TỔNG QUAN
  void btnOverview() {
    setState(() {
      selectedIndex = 0;
    });
  }

  /// MENU: PHÒNG
  void btnRooms() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RoomPage(),
      ),
    );
  }

// MENU: HÓA ĐƠN
  void btnInvoices() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InvoicePage(),
      ),
    );
  }

// MENU: BẢO TRÌ
  void btnMaintenance() {
    // Chưa có màn hình bảo trì
  }

// MENU: TÀI KHOẢN
  void btnAccount() {
    // Chưa có màn hình tài khoản
  }

  // XỬ LÝ MENU DƯỚI
  void handleBottomNavigation(int index) {
    if (index == 0) {
      btnOverview();
    } else if (index == 1) {
      btnRooms();
    } else if (index == 2) {
      btnInvoices();
    } else if (index == 3) {
      btnMaintenance();
    } else if (index == 4) {
      btnAccount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      // ============================================================
      // BODY
      // ============================================================
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            25,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =====================================================
              // HEADER
              // =====================================================
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Xin chào, Chủ trọ 👋",
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF202533),
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Tổng quan nhà trọ hôm nay",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ================= NÚT THÊM PHÒNG =================
                  ElevatedButton.icon(
                    onPressed: btnAddRoom,
                    icon: const Icon(
                      Icons.add,
                      size: 16,
                    ),
                    label: const Text(
                      "Thêm phòng",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEAF0FF),
                      foregroundColor: const Color(0xFF2F67EA),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // =====================================================
              // THỐNG KÊ
              // =====================================================
              Row(
                children: [
                  // ================= PHÒNG ĐANG THUÊ =================
                  Expanded(
                    child: Container(
                      height: 125,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F0FF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Phòng đang thuê",
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF4E7EEB),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "12",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF202533),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "trên 15 phòng",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ================= DOANH THU THÁNG =================
                  Expanded(
                    child: Container(
                      height: 125,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF8EF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Doanh thu tháng",
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF28A866),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "18,6tr",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF202533),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "+8% so với tháng trước",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // =====================================================
              // TRẠNG THÁI PHÒNG
              // =====================================================
              const Text(
                "Trạng thái phòng",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF202533),
                ),
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        _statusChip(
                          "Đang thuê 12",
                          const Color(0xFFE7F8ED),
                          const Color(0xFF16A15D),
                        ),

                        _statusChip(
                          "Trống 2",
                          const Color(0xFFE9F0FF),
                          const Color(0xFF2F67EA),
                        ),

                        _statusChip(
                          "Bảo trì 1",
                          const Color(0xFFFFF1E3),
                          const Color(0xFFFF8A29),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: const LinearProgressIndicator(
                        minHeight: 10,
                        value: 0.80,
                        backgroundColor: Color(0xFFE3E5EA),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF2F67EA),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // =====================================================
              // VIỆC CẦN XỬ LÝ
              // =====================================================
              const Text(
                "Việc cần xử lý",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF202533),
                ),
              ),

              const SizedBox(height: 12),

              // ================= NÚT XEM HÓA ĐƠN =================
              _taskCard(
                icon: Icons.priority_high,
                iconBackground: const Color(0xFFFFE9E9),
                iconColor: const Color(0xFFFF5555),
                title: "3 hóa đơn quá hạn",
                subtitle: "Cần nhắc thanh toán hôm nay",
                buttonColor: const Color(0xFFFFEAEA),
                buttonTextColor: const Color(0xFFE84747),
                onViewPressed: btnOverdueInvoices,
              ),

              const SizedBox(height: 12),

              // ================= NÚT XEM BẢO TRÌ =================
              _taskCard(
                icon: Icons.home_repair_service_outlined,
                iconBackground: const Color(0xFFFFF3E3),
                iconColor: const Color(0xFF555555),
                title: "2 yêu cầu bảo trì",
                subtitle: "1 yêu cầu đang chờ xác nhận",
                buttonColor: const Color(0xFFFFF0DE),
                buttonTextColor: const Color(0xFFE38B24),
                onViewPressed: btnMaintenanceRequests,
              ),

              const SizedBox(height: 25),

              // =====================================================
              // DOANH THU GẦN ĐÂY
              // =====================================================
              const Text(
                "Doanh thu gần đây",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF202533),
                ),
              ),

              const SizedBox(height: 12),

              Container(
                height: 180,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment:
                  MainAxisAlignment.spaceAround,
                  children: [
                    _revenueBar(45),
                    _revenueBar(75),
                    _revenueBar(105),
                    _revenueBar(70),
                    _revenueBar(125),
                    _revenueBar(95),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // ============================================================
      // MENU DƯỚI
      // ============================================================
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Color(0xFFEEEEEE),
            ),
          ),
        ),
        child: SafeArea(
          child: NavigationBar(
            height: 70,
            elevation: 0,
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFFEAF0FF),
            selectedIndex: selectedIndex,

            // ================= XỬ LÝ MENU =================
            onDestinationSelected: handleBottomNavigation,

            destinations: const [
              // MENU: TỔNG QUAN
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(
                  Icons.home,
                  color: Color(0xFF2F67EA),
                ),
                label: "Tổng quan",
              ),

              // MENU: PHÒNG
              NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(
                  Icons.grid_view,
                  color: Color(0xFF2F67EA),
                ),
                label: "Phòng",
              ),

              // MENU: HÓA ĐƠN
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(
                  Icons.receipt_long,
                  color: Color(0xFF2F67EA),
                ),
                label: "Hóa đơn",
              ),

              // MENU: BẢO TRÌ
              NavigationDestination(
                icon: Icon(
                  Icons.home_repair_service_outlined,
                ),
                selectedIcon: Icon(
                  Icons.home_repair_service,
                  color: Color(0xFF2F67EA),
                ),
                label: "Bảo trì",
              ),

              // MENU: TÀI KHOẢN
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(
                  Icons.person,
                  color: Color(0xFF2F67EA),
                ),
                label: "Tài khoản",
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WIDGET TRẠNG THÁI PHÒNG
  // ============================================================
  Widget _statusChip(
      String text,
      Color backgroundColor,
      Color textColor,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // WIDGET VIỆC CẦN XỬ LÝ
  // ============================================================
  Widget _taskCard({
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color buttonColor,
    required Color buttonTextColor,
    required VoidCallback onViewPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 21,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // ================= NÚT XEM =================
          InkWell(
            onTap: onViewPressed,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: buttonColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Xem",
                style: TextStyle(
                  color: buttonTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGET CỘT DOANH THU
  // ============================================================
  Widget _revenueBar(double height) {
    return Container(
      width: 28,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE9F0FF),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.bottomCenter,
      child: Container(
        width: 28,
        height: height - 12,
        decoration: BoxDecoration(
          color: const Color(0xFF2F67EA),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}