import 'package:flutter/material.dart';

import 'room_page.dart';
import 'tenant_detail_page.dart';
import '../data/mock_data.dart';

class TenantListPage extends StatefulWidget {
  const TenantListPage({super.key});

  @override
  State<TenantListPage> createState() => _TenantListPageState();
}

class _TenantListPageState extends State<TenantListPage> {
  int selectedFilter = 0;
  String searchText = "";

  final tenants = tenantList;

  List<Map<String, String>> get _shown {
    const statuses = ['Tất cả', 'Trưởng phòng', 'Thành viên'];
    final q = searchText.trim().toLowerCase();
    return tenants.where((t) {
      final match =
          selectedFilter == 0 || t['memberRole'] == statuses[selectedFilter];
      return match &&
          [
            'name',
            'room',
            'phone',
          ].any((key) => (t[key] ?? '').toLowerCase().contains(q));
    }).toList();
  }

  Future<void> _detail(String name) async {
    final tenant = tenants.firstWhere((t) => t['name'] == name);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TenantDetailPage(tenant: tenant)),
    );
    if (mounted) setState(() {});
  }

  void _search() => FocusScope.of(context).unfocus();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          onPressed: _search,
                          icon: const Icon(
                            Icons.search,
                            color: Color(0xFF707582),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

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

                    Wrap(
                      spacing: 8,
                      children: List.generate(
                        3,
                        (i) => _filterButton(
                          index: i,
                          text: ['Tất cả', 'Trưởng phòng', 'Thành viên'][i],
                          selectedColor: blue,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    ..._shown.map(
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
                      "${_shown.length} người thuê",
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: const AppBottomBar(selected: 1),
    );
  }

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
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: isSelected ? Colors.white : const Color(0xFF7E8390),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

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
        _detail(name);
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
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
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

                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
