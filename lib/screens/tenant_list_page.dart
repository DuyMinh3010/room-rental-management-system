import 'package:flutter/material.dart';

class TenantListPage extends StatefulWidget {
  const TenantListPage({super.key});

  @override
  State<TenantListPage> createState() => _TenantListPageState();
}

class _TenantListPageState extends State<TenantListPage> {
  int selectedFilter = 0;
  String searchText = "";

  // ============================================================
  // DỮ LIỆU NGƯỜI THUÊ TẠM THỜI
  // ============================================================
  final List<Map<String, String>> tenants = [
    {
      "initial": "NA",
      "name": "Nguyễn Minh Chiến",
      "room": "Phòng 101 · Khu A",
      "phone": "090 123 4567",
      "contract": "01/06/2026 → 31/05/2027",
      "status": "Đang thuê",
    },
    {
      "initial": "TH",
      "name": "Trần Văn Hùng",
      "room": "Phòng 102 · Khu A",
      "phone": "098 765 4321",
      "contract": "15/06/2026 → 14/05/2027",
      "status": "Đang thuê",
    },
    {
      "initial": "LP",
      "name": "Lê Thị Phương",
      "room": "Phòng 103 · Khu B",
      "phone": "093 111 2233",
      "contract": "01/04/2026 → 31/03/2027",
      "status": "Đang thuê",
    },
    {
      "initial": "NV",
      "name": "Ngô Văn Đức",
      "room": "Phòng 104 · Khu B",
      "phone": "091 234 5678",
      "contract": "10/03/2026 → 09/03/2027",
      "status": "Sắp hết hạn",
    },
    {
      "initial": "PD",
      "name": "Phạm Thị Dung",
      "room": "Phòng 201 · Khu C",
      "phone": "097 654 3210",
      "contract": "01/02/2026 → 31/01/2027",
      "status": "Đã hết hạn",
    },
  ];

  // ============================================================
  // LỌC + TÌM KIẾM NGƯỜI THUÊ
  // ============================================================
  List<Map<String, String>> get filteredTenants {
    List<Map<String, String>> result = tenants;

    if (selectedFilter == 1) {
      result = result
          .where((tenant) => tenant["status"] == "Đang thuê")
          .toList();
    } else if (selectedFilter == 2) {
      result = result
          .where((tenant) => tenant["status"] == "Sắp hết hạn")
          .toList();
    } else if (selectedFilter == 3) {
      result = result
          .where((tenant) => tenant["status"] == "Đã hết hạn")
          .toList();
    }

    if (searchText.isNotEmpty) {
      final keyword = searchText.toLowerCase();

      result = result.where((tenant) {
        final name = tenant["name"]!.toLowerCase();
        final room = tenant["room"]!.toLowerCase();
        final phone = tenant["phone"]!.toLowerCase();

        return name.contains(keyword) ||
            room.contains(keyword) ||
            phone.contains(keyword);
      }).toList();
    }

    return result;
  }

  // ============================================================
  // NÚT: XEM CHI TIẾT NGƯỜI THUÊ
  // ============================================================
  void btnTenantDetail(String tenantName) {
    // Sau này liên kết sang trang chi tiết người thuê
  }

  // ============================================================
  // NÚT TÌM KIẾM TRÊN HEADER
  // ============================================================
  void btnSearch() {
    // Hiện tại đã có ô tìm kiếm bên dưới
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      body: SafeArea(
        child: Column(
          children: [
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
                          child: Text(
                            "Danh sách người thuê",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF202533),
                            ),
                          ),
                        ),

                        IconButton(
                          onPressed: btnSearch,
                          icon: const Icon(
                            Icons.search,
                            color: Color(0xFF707582),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

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
                        hintText: "Tìm kiếm tên, số phòng...",
                        hintStyle: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 19,
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE4E5E9),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF2F67EA),
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // =================================================
                    // BỘ LỌC
                    // =================================================
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterButton(
                            index: 0,
                            text: "Tất cả",
                            selectedColor: const Color(0xFF2F67EA),
                          ),

                          const SizedBox(width: 8),

                          _filterButton(
                            index: 1,
                            text: "Đang thuê",
                            selectedColor: const Color(0xFF2F67EA),
                          ),

                          const SizedBox(width: 8),

                          _filterButton(
                            index: 2,
                            text: "Sắp hết hạn",
                            selectedColor: const Color(0xFF2F67EA),
                          ),

                          const SizedBox(width: 8),

                          _filterButton(
                            index: 3,
                            text: "Đã hết hạn",
                            selectedColor: const Color(0xFF2F67EA),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // =================================================
                    // DANH SÁCH NGƯỜI THUÊ
                    // =================================================
                    ...filteredTenants.map(
                          (tenant) => Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: _tenantCard(
                          initial: tenant["initial"]!,
                          name: tenant["name"]!,
                          room: tenant["room"]!,
                          phone: tenant["phone"]!,
                          contract: tenant["contract"]!,
                          status: tenant["status"]!,
                        ),
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      "${filteredTenants.length} người thuê",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
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
      // BOTTOM NAVIGATION
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
            selectedIndex: 1,
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFFEAF0FF),

            onDestinationSelected: (index) {
              // Chưa liên kết các trang khác
            },

            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: "Tổng quan",
              ),

              NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(
                  Icons.people,
                  color: Color(0xFF2F67EA),
                ),
                label: "Người thuê",
              ),

              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                label: "Hóa đơn",
              ),

              NavigationDestination(
                icon: Icon(Icons.home_repair_service_outlined),
                label: "Bảo trì",
              ),

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
          horizontal: 15,
          vertical: 8,
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
                ? Colors.white
                : const Color(0xFF7E8390),
            fontWeight: isSelected
                ? FontWeight.w600
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WIDGET: THẺ NGƯỜI THUÊ
  // ============================================================
  Widget _tenantCard({
    required String initial,
    required String name,
    required String room,
    required String phone,
    required String contract,
    required String status,
  }) {
    Color statusBackground;
    Color statusText;

    if (status == "Đang thuê") {
      statusBackground = const Color(0xFFE7F8ED);
      statusText = const Color(0xFF16A15D);
    } else if (status == "Sắp hết hạn") {
      statusBackground = const Color(0xFFFFF0DE);
      statusText = const Color(0xFFE88623);
    } else {
      statusBackground = const Color(0xFFFFEAEA);
      statusText = const Color(0xFFE74747);
    }

    return InkWell(
      onTap: () {
        btnTenantDetail(name);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= AVATAR =================
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF3FF),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Color(0xFF4390E8),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ================= THÔNG TIN NGƯỜI THUÊ =================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF202533),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    room,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 13,
                        color: Colors.grey,
                      ),

                      const SizedBox(width: 5),

                      Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        size: 13,
                        color: Colors.grey,
                      ),

                      const SizedBox(width: 5),

                      Expanded(
                        child: Text(
                          contract,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),

            // ================= TRẠNG THÁI =================
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: statusText,
                    ),
                  ),
                ),

                const SizedBox(height: 34),

                const Icon(
                  Icons.chevron_right,
                  size: 18,
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