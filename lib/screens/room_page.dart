import 'package:flutter/material.dart';
import 'invoice_page.dart';
import 'tenant_list_page.dart';

class RoomPage extends StatefulWidget {
  const RoomPage({super.key});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  int selectedFilter = 0;

  String searchText = "";

  // ============================================================
  // DỮ LIỆU PHÒNG TẠM THỜI
  // ============================================================
  final List<Map<String, String>> rooms = [
    {
      "room": "P.101",
      "tenant": "Nguyễn Văn An",
      "price": "2.500.000đ/tháng",
      "status": "Đang thuê",
    },
    {
      "room": "P.102",
      "tenant": "Trần Minh Huy",
      "price": "2.500.000đ/tháng",
      "status": "Đang thuê",
    },
    {
      "room": "P.103",
      "tenant": "—",
      "price": "2.300.000đ/tháng",
      "status": "Trống",
    },
    {
      "room": "P.201",
      "tenant": "Lê Thị Mai",
      "price": "2.800.000đ/tháng",
      "status": "Bảo trì",
    },
  ];

  // ============================================================
// NÚT: THÊM PHÒNG
// ============================================================
  void btnAddRoom() {
    // Sau này liên kết sang màn hình thêm phòng
  }

// ============================================================
// NÚT: XEM CHI TIẾT PHÒNG
// ============================================================
  void btnRoomDetail(String roomName) {
    // Sau này liên kết sang màn hình chi tiết phòng
  }

  // ============================================================
// NÚT: DANH SÁCH NGƯỜI THUÊ
// ============================================================
  void btnTenantList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TenantListPage(),
      ),
    );
  }

// ============================================================
// MENU: TỔNG QUAN
// ============================================================
  void btnOverview() {
    Navigator.pop(context);
  }

// ============================================================
// MENU: PHÒNG
// ============================================================
  void btnRooms() {
    // Đang ở trang Phòng nên không cần làm gì
  }

// ============================================================
// MENU: HÓA ĐƠN
// ============================================================
  void btnInvoices() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InvoicePage(),
      ),
    );
  }

// ============================================================
// MENU: BẢO TRÌ
// ============================================================
  void btnMaintenance() {
    // Sau này liên kết sang màn hình bảo trì
  }

// ============================================================
// MENU: TÀI KHOẢN
// ============================================================
  void btnAccount() {
    // Sau này liên kết sang màn hình tài khoản
  }

  // ============================================================
  // LỌC PHÒNG
  // ============================================================
  List<Map<String, String>> get filteredRooms {
    List<Map<String, String>> result = rooms;

    // Lọc trạng thái
    if (selectedFilter == 1) {
      result = result
          .where((room) => room["status"] == "Đang thuê")
          .toList();
    } else if (selectedFilter == 2) {
      result = result
          .where((room) => room["status"] == "Trống")
          .toList();
    }

    // Tìm kiếm
    if (searchText.isNotEmpty) {
      result = result.where((room) {
        final roomName = room["room"]!.toLowerCase();
        final tenantName = room["tenant"]!.toLowerCase();
        final keyword = searchText.toLowerCase();

        return roomName.contains(keyword) ||
            tenantName.contains(keyword);
      }).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      // ============================================================
      // BODY
      // ============================================================
      body: SafeArea(
        child: Column(
          children: [
            // ======================================================
            // PHẦN TRÊN CÓ THỂ CUỘN
            // ======================================================
            Expanded(
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
                    // =================================================
                    // HEADER
                    // =================================================
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Phòng",
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF202533),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "15 phòng · 12 đang thuê",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ================= NÚT NGƯỜI THUÊ =================
                        IconButton(
                          onPressed: btnTenantList,
                          tooltip: "Danh sách người thuê",
                          icon: const Icon(
                            Icons.people_outline,
                            color: Color(0xFF2F67EA),
                          ),
                        ),

                        const SizedBox(width: 4),

                        // ================= NÚT THÊM =================
                        ElevatedButton.icon(
                          onPressed: btnAddRoom,
                          icon: const Icon(
                            Icons.add,
                            size: 16,
                          ),
                          label: const Text(
                            "Thêm",
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
                              horizontal: 14,
                              vertical: 11,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // =================================================
                    // Ô TÌM KIẾM
                    // =================================================
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          searchText = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText:
                        "Tìm theo số phòng hoặc người thuê",
                        hintStyle: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 18,
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                        const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E2E8),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF2F67EA),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // =================================================
                    // BỘ LỌC
                    // =================================================
                    Row(
                      children: [
                        _filterButton(
                          index: 0,
                          text: "Tất cả 15",
                          selectedColor:
                          const Color(0xFFEAF0FF),
                          textColor:
                          const Color(0xFF2F67EA),
                        ),

                        const SizedBox(width: 10),

                        _filterButton(
                          index: 1,
                          text: "Đang thuê 12",
                          selectedColor:
                          const Color(0xFFE7F8ED),
                          textColor:
                          const Color(0xFF16A15D),
                        ),

                        const SizedBox(width: 10),

                        _filterButton(
                          index: 2,
                          text: "Trống 2",
                          selectedColor:
                          const Color(0xFFF0F2F5),
                          textColor:
                          const Color(0xFF707582),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // =================================================
                    // DANH SÁCH PHÒNG
                    // =================================================
                    ...filteredRooms.map(
                          (room) => Padding(
                        padding:
                        const EdgeInsets.only(bottom: 14),
                        child: _roomCard(
                          roomNumber: room["room"]!,
                          tenant: room["tenant"]!,
                          price: room["price"]!,
                          status: room["status"]!,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ============================================================
      // THANH MENU DƯỚI
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

            // Trang Phòng = index 1
            selectedIndex: 1,

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
                selectedIcon: Icon(
                  Icons.grid_view,
                  color: Color(0xFF2F67EA),
                ),
                label: "Phòng",
              ),

              // MENU: HÓA ĐƠN
              NavigationDestination(
                icon: Icon(
                  Icons.receipt_long_outlined,
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
  // WIDGET: NÚT LỌC
  // ============================================================
  Widget _filterButton({
    required int index,
    required String text,
    required Color selectedColor,
    required Color textColor,
  }) {
    final bool isSelected = selectedFilter == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: isSelected
                ? textColor
                : Colors.grey,
            fontWeight: isSelected
                ? FontWeight.w600
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WIDGET: THẺ PHÒNG
  // ============================================================
  Widget _roomCard({
    required String roomNumber,
    required String tenant,
    required String price,
    required String status,
  }) {
    Color statusBackground;
    Color statusText;

    if (status == "Đang thuê") {
      statusBackground = const Color(0xFFE7F8ED);
      statusText = const Color(0xFF16A15D);
    } else if (status == "Trống") {
      statusBackground = const Color(0xFFEAF0FF);
      statusText = const Color(0xFF2F67EA);
    } else {
      statusBackground = const Color(0xFFFFF0DE);
      statusText = const Color(0xFFE88623);
    }

    return InkWell(
      onTap: () {
        btnRoomDetail(roomNumber);
      },
      borderRadius: BorderRadius.circular(18),

      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            // ================= ICON PHÒNG =================
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FF),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.grid_on_rounded,
                color: Color(0xFF2F67EA),
                size: 20,
              ),
            ),

            const SizedBox(width: 14),

            // ================= THÔNG TIN =================
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    roomNumber,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF202533),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    tenant,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF202533),
                    ),
                  ),
                ],
              ),
            ),

            // ================= PHẦN BÊN PHẢI =================
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
                    borderRadius: BorderRadius.circular(18),
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

                const SizedBox(height: 24),

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
