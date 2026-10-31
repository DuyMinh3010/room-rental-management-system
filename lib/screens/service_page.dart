import 'dart:async';
import 'package:flutter/material.dart';
import '../services/meter_reading_service.dart';
import '../services/room_service.dart';
import 'meter_reading_screen.dart';

class ServicePage extends StatefulWidget {
  const ServicePage({super.key});

  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  final Color primaryColor = const Color(0xFF2864F0);
  final Color backgroundColor = const Color(0xFFF4F6FA);
  final TextEditingController searchController = TextEditingController();
  final MeterReadingService readingService = MeterReadingService();
  final RoomService roomService = RoomService();

  int selectedTab = 0;
  int selectedBottom = 2;

  final String currentMonth = '09/2026';

  List<Map<String, String>> rooms = [];
  StreamSubscription<List<Map<String, String>>>? roomSubscription;

  bool isLoadingRooms = true;
  String? roomError;

  final Map<String, bool> savedRooms = {};

  final List<Map<String, dynamic>> services = [
    {
      'name': 'Điện',
      'price': '3.500đ/kWh',
      'type': 'Theo chỉ số',
      'icon': Icons.bolt,
      'color': Color(0xFF2864F0),
    },
    {
      'name': 'Nước',
      'price': '20.000đ/m³',
      'type': 'Theo chỉ số',
      'icon': Icons.water_drop,
      'color': Color(0xFF079BB5),
    },
    {
      'name': 'WiFi',
      'price': '100.000đ/tháng',
      'type': 'Theo phòng',
      'icon': Icons.wifi,
      'color': Color(0xFF853DF4),
    },
    {
      'name': 'Đổ rác',
      'price': '20.000đ/tháng',
      'type': 'Theo phòng',
      'icon': Icons.delete_outline,
      'color': Color(0xFFFF510B),
    },
    {
      'name': 'Gửi xe',
      'price': '100.000đ/người',
      'type': 'Theo người',
      'icon': Icons.local_parking,
      'color': Color(0xFF16A653),
    },
  ];

  List<Map<String, dynamic>> get filteredServices {
    return services.where((service) {
      return service['name']
          .toString()
          .toLowerCase()
          .contains(searchController.text.trim().toLowerCase());
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadRoomStatuses();
  }

  Future<void> _loadRoomStatuses() async {
    await roomSubscription?.cancel();

    if (!mounted) return;

    setState(() {
      isLoadingRooms = true;
      roomError = null;
    });

    try {
      roomSubscription = roomService.watchRooms().listen(
        (roomData) async {
          if (!mounted) return;

          final availableRooms = roomData.where((item) {
            final name = item['name'];
            return name != null &&
                name.trim().isNotEmpty &&
                name != 'Chưa cập nhật';
          }).toList();

          setState(() {
            rooms = availableRooms;
            isLoadingRooms = false;

            savedRooms.removeWhere(
              (name, _) => !availableRooms.any(
                (item) => item['name'] == name,
              ),
            );
          });

          final statuses = <String, bool>{};

          for (final item in availableRooms) {
            final name = item['name']!;

            try {
              final data = await readingService.getReading(
                room: name,
                month: currentMonth,
              );

              statuses[name] = data != null &&
                  data['electricNew'] != null &&
                  data['waterNew'] != null;
            } catch (_) {
              statuses[name] = false;
            }
          }

          if (!mounted) return;

          setState(() {
            savedRooms
              ..clear()
              ..addAll(statuses);
          });
        },
        onError: (Object error) {
          if (!mounted) return;

          setState(() {
            roomError = 'Không tải được danh sách phòng: $error';
            isLoadingRooms = false;
          });
        },
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        roomError = 'Không tải được danh sách phòng: $error';
        isLoadingRooms = false;
      });
    }
  }

  Future<void> _openMeterReading(String selectedRoom) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MeterReadingScreen(
          initialRoom: selectedRoom,
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      try {
        final data = await readingService.getReading(
          room: selectedRoom,
          month: currentMonth,
        );

        if (!mounted) return;

        setState(() {
          savedRooms[selectedRoom] = data != null &&
              data['electricNew'] != null &&
              data['waterNew'] != null;
        });
      } catch (_) {
        if (!mounted) return;

        setState(() {
          savedRooms[selectedRoom] = false;
        });
      }
    }
  }

  String _getPriceSuffix(String name) {
    switch (name) {
      case 'Điện':
        return 'đ/kWh';
      case 'Nước':
        return 'đ/m³';
      case 'WiFi':
      case 'Đổ rác':
        return 'đ/tháng';
      case 'Gửi xe':
        return 'đ/người';
      default:
        return 'đ';
    }
  }

  String _getNumericPrice(String price) {
    return price
        .replaceAll('đ', '')
        .replaceAll('/kWh', '')
        .replaceAll('/m³', '')
        .replaceAll('/tháng', '')
        .replaceAll('/người', '')
        .replaceAll('.', '')
        .trim();
  }

  Future<void> editService(Map<String, dynamic> service) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return ServiceEditorDialog(
          service: service,
          isEditing: true,
        );
      },
    );

    if (!mounted || result == null) return;

    setState(() {
      service['name'] = result['name'];
      service['price'] =
          '${result['price']}${_getPriceSuffix(result['name'].toString())}';
      service['type'] = result['type'];
    });
  }

  Future<void> addService() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return const ServiceEditorDialog(
          isEditing: false,
        );
      },
    );

    if (!mounted || result == null) return;

    setState(() {
      services.add({
        'name': result['name'],
        'price':
            '${result['price']}${_getPriceSuffix(result['name'].toString())}',
        'type': result['type'],
        'icon': Icons.miscellaneous_services,
        'color': primaryColor,
      });
    });
  }

  @override
  void dispose() {
    roomSubscription?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.maybePop(context),
                    child: const Icon(
                      Icons.chevron_left,
                      size: 28,
                      color: Color(0xFF263548),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Dịch vụ',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF172235),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                width: double.infinity,
                height: 47,
                child: TextField(
                  controller: searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm dịch vụ...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A0B3),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                      color: Color(0xFF94A0B3),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                height: 43,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _buildTab('Dịch vụ', 0),
                    _buildTab('Nhập chỉ số', 1),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: selectedTab == 0
                  ? _buildServiceList()
                  : _buildMeterList(),
            ),
            if (selectedTab == 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: addService,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      '+  Thêm dịch vụ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: rooms.isEmpty || isLoadingRooms
                        ? null
                        : () => _openMeterReading(rooms.first['name']!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Nhập chỉ số',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.only(top: 5),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 53,
            child: Row(
              children: [
                _buildBottomItem(Icons.home_outlined, 'Phòng', 0),
                _buildBottomItem(Icons.people_outline, 'Người thuê', 1),
                _buildBottomItem(Icons.circle, 'Dịch vụ', 2),
                _buildBottomItem(Icons.receipt_long_outlined, 'Hóa đơn', 3),
                _buildBottomItem(Icons.description_outlined, 'Hợp đồng', 4),
                _buildBottomItem(Icons.build_outlined, 'Bảo trì', 5),
                _buildBottomItem(Icons.settings_outlined, 'Tài khoản', 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceList() {
    final items = filteredServices;

    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Không tìm thấy dịch vụ',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF8491A4),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final service = items[index];

        return SizedBox(
          width: double.infinity,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => editService(service),
              child: Container(
                width: double.infinity,
                height: 65,
                padding: const EdgeInsets.symmetric(horizontal: 11),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: service['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        service['icon'] as IconData,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service['name'].toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF273548),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            service['type'].toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF91A0B4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      flex: 4,
                      child: Text(
                        service['price'].toString(),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF485365),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.chevron_right,
                      size: 21,
                      color: Color(0xFFA1AEC0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMeterList() {
    if (isLoadingRooms) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (roomError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            roomError!,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.red,
            ),
          ),
        ),
      );
    }

    if (rooms.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có phòng trong Firebase.',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF8491A4),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nhập chỉ số điện nước',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Kỳ ghi chỉ số: $currentMonth',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8491A4),
                ),
              ),
              const SizedBox(height: 8),
              ...rooms.map((roomData) {
                final roomName = roomData['name']!;
                final saved = savedRooms[roomName] == true;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    roomName,
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    saved ? 'Đã lưu chỉ số' : 'Chưa nhập chỉ số',
                    style: TextStyle(
                      fontSize: 11,
                      color: saved ? Colors.green : Colors.grey,
                    ),
                  ),
                  leading: Icon(
                    saved
                        ? Icons.check_circle
                        : Icons.meeting_room_outlined,
                    color: saved ? Colors.green : primaryColor,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openMeterReading(roomName),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String title, int index) {
    final selected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => selectedTab = index);
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFE7EFFF)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected
                  ? primaryColor
                  : const Color(0xFF8390A4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomItem(
    IconData icon,
    String title,
    int index,
  ) {
    final selected = selectedBottom == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => selectedBottom = index);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected
                  ? primaryColor
                  : const Color(0xFF8190A5),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w400,
                color: selected
                    ? primaryColor
                    : const Color(0xFF8190A5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceEditorDialog extends StatefulWidget {
  final Map<String, dynamic>? service;
  final bool isEditing;

  const ServiceEditorDialog({
    super.key,
    this.service,
    required this.isEditing,
  });

  @override
  State<ServiceEditorDialog> createState() => _ServiceEditorDialogState();
}

class _ServiceEditorDialogState extends State<ServiceEditorDialog> {
  late final TextEditingController nameController;
  late final TextEditingController priceController;

  late String type;

  String _getNumericPrice(String price) {
    return price
        .replaceAll('đ', '')
        .replaceAll('/kWh', '')
        .replaceAll('/m³', '')
        .replaceAll('/tháng', '')
        .replaceAll('/người', '')
        .replaceAll('.', '')
        .trim();
  }

  @override
  void initState() {
    super.initState();

    final service = widget.service;

    nameController = TextEditingController(
      text: service?['name']?.toString() ?? '',
    );

    priceController = TextEditingController(
      text: _getNumericPrice(
        service?['price']?.toString() ?? '',
      ),
    );

    type = service?['type']?.toString() ?? 'Theo phòng';
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isEditing
            ? 'Sửa ${widget.service?['name'] ?? 'dịch vụ'}'
            : 'Thêm dịch vụ',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tên dịch vụ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Đơn giá',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: type,
              decoration: const InputDecoration(
                labelText: 'Loại tính phí',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Theo phòng',
                  child: Text('Theo phòng'),
                ),
                DropdownMenuItem(
                  value: 'Theo người',
                  child: Text('Theo người'),
                ),
                DropdownMenuItem(
                  value: 'Theo chỉ số',
                  child: Text('Theo chỉ số'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    type = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = nameController.text.trim();
            final price = double.tryParse(
              priceController.text.replaceAll('.', '').trim(),
            );

            if (name.isEmpty || price == null || price < 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Vui lòng nhập thông tin hợp lệ.'),
                ),
              );
              return;
            }

            Navigator.pop(context, {
              'name': name,
              'price': price.toInt(),
              'type': type,
            });
          },
          child: Text(widget.isEditing ? 'Lưu' : 'Thêm'),
        ),
      ],
    );
  }
}