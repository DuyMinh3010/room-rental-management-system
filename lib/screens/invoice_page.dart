import 'package:flutter/material.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  // ============================================================
  // DỮ LIỆU HÓA ĐƠN TẠM THỜI
  // ============================================================
  final List<Map<String, String>> invoices = [
    {
      "room": "P.101",
      "price": "2.840.000đ",
      "status": "Đã thanh toán",
    },
    {
      "room": "P.102",
      "price": "2.760.000đ",
      "status": "Chưa thanh toán",
    },
    {
      "room": "P.201",
      "price": "3.120.000đ",
      "status": "Quá hạn 3 ngày",
    },
  ];

  // ============================================================
  // NÚT: TẠO HÓA ĐƠN
  // ============================================================
  void btnCreateInvoice() {
    // Sau này liên kết sang màn hình tạo hóa đơn
  }

  // ============================================================
  // NÚT: XEM CHI TIẾT HÓA ĐƠN
  // ============================================================
  void btnInvoiceDetail(String roomName) {
    // Sau này liên kết sang chi tiết hóa đơn
  }

  // ============================================================
  // NÚT: NHẬP CHỈ SỐ ĐIỆN NƯỚC
  // ============================================================
  void btnEnterMeter() {
    // Sau này liên kết sang màn hình nhập chỉ số điện nước
  }

  // ============================================================
  // MENU: TỔNG QUAN
  // ============================================================
  void btnOverview() {
    Navigator.popUntil(
      context,
          (route) => route.isFirst,
    );
  }

  // ============================================================
  // MENU: PHÒNG
  // ============================================================
  void btnRooms() {
    Navigator.pop(context);
  }

  // ============================================================
  // MENU: HÓA ĐƠN
  // ============================================================
  void btnInvoices() {
    // Đang ở màn hình Hóa đơn
  }

  // ============================================================
  // MENU: BẢO TRÌ
  // ============================================================
  void btnMaintenance() {
    // Làm sau
  }

  // ============================================================
  // MENU: TÀI KHOẢN
  // ============================================================
  void btnAccount() {
    // Làm sau
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
            30,
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
                          "Hóa đơn",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF202533),
                          ),
                        ),

                        SizedBox(height: 4),

                        Text(
                          "Tháng 09/2026",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ================= NÚT TẠO HÓA ĐƠN =================
                  ElevatedButton(
                    onPressed: btnCreateInvoice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEAF0FF),
                      foregroundColor: const Color(0xFF2F67EA),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Text(
                      "Tạo hóa đơn",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 27),

              // =====================================================
              // TỔNG CẦN THU
              // =====================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  18,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B86F6),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tổng cần thu",
                      style: TextStyle(
                        color: Color(0xFFDCE9FF),
                        fontSize: 13,
                      ),
                    ),

                    SizedBox(height: 8),

                    Text(
                      "27.840.000đ",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 6),

                    Text(
                      "9 đã trả · 3 chưa trả",
                      style: TextStyle(
                        color: Color(0xFFDCE9FF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              // =====================================================
              // HÓA ĐƠN THÁNG NÀY
              // =====================================================
              const Text(
                "Hóa đơn tháng này",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF202533),
                ),
              ),

              const SizedBox(height: 13),

              // ================= DANH SÁCH HÓA ĐƠN =================
              ...invoices.map(
                    (invoice) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _invoiceCard(
                    roomNumber: invoice["room"]!,
                    amount: invoice["price"]!,
                    status: invoice["status"]!,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // =====================================================
              // GHI SỐ ĐIỆN NƯỚC
              // =====================================================
              const Text(
                "Ghi số điện nước",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF202533),
                ),
              ),

              const SizedBox(height: 13),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    // ================= ICON ĐIỆN =================
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF0FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Color(0xFFFFB020),
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 13),

                    // ================= THÔNG TIN =================
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Nhập chỉ số tháng 09",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF202533),
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            "Còn 3 phòng chưa nhập",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ================= NÚT NHẬP =================
                    ElevatedButton(
                      onPressed: btnEnterMeter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEAF0FF),
                        foregroundColor: const Color(0xFF2F67EA),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 9,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Nhập",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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

            // Hóa đơn = vị trí số 2
            selectedIndex: 2,

            onDestinationSelected: (index) {
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
            },

            destinations: const [
              // MENU: TỔNG QUAN
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: "Tổng quan",
              ),

              // MENU: PHÒNG
              NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                label: "Phòng",
              ),

              // MENU: HÓA ĐƠN
              NavigationDestination(
                icon: Icon(
                  Icons.receipt_long_outlined,
                ),
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
                label: "Bảo trì",
              ),

              // MENU: TÀI KHOẢN
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                label: "Tài khoản",
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WIDGET: THẺ HÓA ĐƠN
  // ============================================================
  Widget _invoiceCard({
    required String roomNumber,
    required String amount,
    required String status,
  }) {
    Color statusBackground;
    Color statusText;

    if (status == "Đã thanh toán") {
      statusBackground = const Color(0xFFE7F8ED);
      statusText = const Color(0xFF16A15D);
    } else if (status == "Chưa thanh toán") {
      statusBackground = const Color(0xFFFFEAEA);
      statusText = const Color(0xFFE74747);
    } else {
      statusBackground = const Color(0xFFFFF0DE);
      statusText = const Color(0xFFE88623);
    }

    return InkWell(
      onTap: () {
        btnInvoiceDetail(roomNumber);
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          16,
          15,
          14,
          15,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            // ================= THÔNG TIN HÓA ĐƠN =================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roomNumber,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF202533),
                    ),
                  ),

                  const SizedBox(height: 7),

                  const Text(
                    "Tiền phòng + điện + nước + dịch vụ",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    amount,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF202533),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ================= TRẠNG THÁI + MŨI TÊN =================
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusText,
                    ),
                  ),
                ),

                const SizedBox(height: 21),

                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}