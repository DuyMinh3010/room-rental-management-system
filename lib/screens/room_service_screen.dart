import 'package:flutter/material.dart';
import 'add_room_service_screen.dart';

class RoomServiceScreen extends StatefulWidget {
  const RoomServiceScreen({super.key});

  @override
  State<RoomServiceScreen> createState() => _RoomServiceScreenState();
}

class _RoomServiceScreenState extends State<RoomServiceScreen> {
  final List<Map<String, dynamic>> roomServices = [
    {
      'name': 'Tiền điện',
      'price': '3500',
      'unit': '/ kWh',
      'icon': Icons.bolt,
    },
    {
      'name': 'Tiền nước',
      'price': '15000',
      'unit': '/ m³',
      'icon': Icons.water_drop_outlined,
    },
    {
      'name': 'Internet / Wifi',
      'price': '100000',
      'unit': '/ tháng',
      'icon': Icons.wifi,
    },
    {
      'name': 'Phí vệ sinh',
      'price': '50000',
      'unit': '/ tháng',
      'icon': Icons.delete_outline,
    },
  ];

  // ================= THÊM DỊCH VỤ =================
  Future<void> _addService() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddRoomServiceScreen(),
      ),
    );

    if (result == null) return;

    String name = result['name'];
    String price = result['price'];

    IconData icon = Icons.miscellaneous_services;
    String unit = '/ tháng';

    if (name == 'Tiền điện') {
      icon = Icons.bolt;
      unit = '/ kWh';
    } else if (name == 'Tiền nước') {
      icon = Icons.water_drop_outlined;
      unit = '/ m³';
    } else if (name == 'Internet / Wifi') {
      icon = Icons.wifi;
    } else if (name == 'Phí vệ sinh') {
      icon = Icons.delete_outline;
    } else if (name == 'Giữ xe') {
      icon = Icons.two_wheeler;
    }

    setState(() {
      roomServices.add({
        'name': name,
        'price': price,
        'unit': unit,
        'icon': icon,
      });
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm $name'),
      ),
    );
  }

  // ================= FORMAT GIÁ =================
  String formatPrice(String price) {
    final number = int.tryParse(price);

    if (number == null) {
      return price;
    }

    String value = number.toString();
    String result = '';
    int count = 0;

    for (int i = value.length - 1; i >= 0; i--) {
      result = value[i] + result;
      count++;

      if (count == 3 && i != 0) {
        result = '.$result';
        count = 0;
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF0D6EFD);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      // ================= HEADER =================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () {
            Navigator.maybePop(context);
          },
        ),
        title: const Text(
          'Chi tiết phòng',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      // ================= BODY =================
      body: Column(
        children: [
          // ================= TAB =================
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _tab('Tổng quan', false),
                _tab('Người thuê', false),
                _tab('Dịch vụ', true),
                _tab('Hóa đơn', false),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dịch vụ đang sử dụng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ================= DANH SÁCH =================
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: roomServices.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 10);
                    },
                    itemBuilder: (context, index) {
                      final service = roomServices[index];

                      return _serviceCard(
                        icon: service['icon'],
                        title: service['name'],
                        price:
                            '${formatPrice(service['price'])}đ ${service['unit']}',
                        blue: blue,
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // ================= THÊM DỊCH VỤ =================
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _addService,
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'Thêm dịch vụ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: blue,
                        side: const BorderSide(color: blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ],
      ),

      // ================= BOTTOM NAVIGATION =================
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 2,
        selectedItemColor: blue,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: (index) {
          // Navigation các màn khác sẽ nối sau
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.meeting_room_outlined),
            label: 'Phòng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Người thuê',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            label: 'Dịch vụ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Hóa đơn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }

  // ================= TAB =================
  Widget _tab(String text, bool selected) {
    const blue = Color(0xFF0D6EFD);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? blue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? blue : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  // ================= CARD DỊCH VỤ =================
  Widget _serviceCard({
    required IconData icon,
    required String title,
    required String price,
    required Color blue,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: blue,
              size: 24,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {
              // Chức năng sửa sẽ làm sau
            },
            icon: const Icon(
              Icons.edit_outlined,
              size: 21,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}