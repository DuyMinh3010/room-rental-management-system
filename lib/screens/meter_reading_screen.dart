
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/meter_reading_service.dart';
import '../services/room_service.dart';

class MeterReadingScreen extends StatefulWidget {
  final String? initialRoom;

  const MeterReadingScreen({
    super.key,
    this.initialRoom,
  });

  @override
  State<MeterReadingScreen> createState() =>
      _MeterReadingScreenState();
}

class _MeterReadingScreenState extends State<MeterReadingScreen> {
  final Color primaryColor = const Color(0xFF2160E8);
  final Color backgroundColor = const Color(0xFFF5F6F8);

  final MeterReadingService readingService = MeterReadingService();
  final RoomService roomService = RoomService();

  List<Map<String, String>> rooms = [];
  String? room;
  final String month = '09/2026';

  StreamSubscription<List<Map<String, String>>>? roomSubscription;

  final TextEditingController electricOldController =
      TextEditingController(text: '0');
  final TextEditingController electricNewController =
      TextEditingController();

  final TextEditingController waterOldController =
      TextEditingController(text: '0');
  final TextEditingController waterNewController =
      TextEditingController();

  final TextEditingController parkingController =
      TextEditingController(text: '0');

  final double electricPrice = 3500;
  final double waterPrice = 20000;
  final double wifiPrice = 100000;
  final double trashPrice = 20000;
  final double parkingPrice = 100000;

  int selectedIndex = 2;
  bool isLoading = true;
  bool isSaving = false;
  bool hasSavedReading = false;
  String? loadError;

  int get electricOld =>
      int.tryParse(electricOldController.text) ?? 0;

  int get electricNew =>
      int.tryParse(electricNewController.text) ?? 0;

  int get waterOld =>
      int.tryParse(waterOldController.text) ?? 0;

  int get waterNew =>
      int.tryParse(waterNewController.text) ?? 0;

  int get parkingPeople =>
      int.tryParse(parkingController.text) ?? 0;

  int get electricUsage =>
      (electricNew - electricOld).clamp(0, 999999999);

  int get waterUsage =>
      (waterNew - waterOld).clamp(0, 999999999);

  int get electricTotal =>
      (electricUsage * electricPrice).toInt();

  int get waterTotal =>
      (waterUsage * waterPrice).toInt();

  int get wifiTotal => wifiPrice.toInt();

  int get trashTotal => trashPrice.toInt();

  int get parkingTotal =>
      (parkingPeople * parkingPrice).toInt();

  String formatMoney(num value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
  }

  @override
  void initState() {
    super.initState();
    room = widget.initialRoom;
    loadRooms();
  }

  void loadRooms() {
    isLoading = true;
    loadError = null;

    roomSubscription?.cancel();

    try {
      roomSubscription = roomService.watchRooms().listen(
        (value) async {
          if (!mounted) return;

          final preferredRoom = widget.initialRoom ?? room;

          final availableRooms = value
              .where(
                (r) =>
                    r['name'] != null &&
                    r['name']!.trim().isNotEmpty &&
                    r['name'] != 'Chưa cập nhật',
              )
              .toList();

          final selectedRoom = availableRooms.any(
            (r) => r['name'] == preferredRoom,
          )
              ? preferredRoom
              : availableRooms.isNotEmpty
                  ? availableRooms.first['name']
                  : null;

          final roomChanged = selectedRoom != room;

          setState(() {
            rooms = availableRooms;
            room = selectedRoom;
            loadError = null;
          });

          if (room != null) {
            if (roomChanged || isLoading) {
              await loadReading();
            }
          } else {
            electricOldController.text = '0';
            electricNewController.clear();
            waterOldController.text = '0';
            waterNewController.clear();
            parkingController.text = '0';

            setState(() {
              hasSavedReading = false;
              isLoading = false;
            });
          }
        },
        onError: (Object e) {
          if (!mounted) return;

          setState(() {
            loadError = 'Không tải được danh sách phòng: $e';
            isLoading = false;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadError = 'Không tải được danh sách phòng: $e';
        isLoading = false;
      });
    }
  }

  Future<void> loadReading() async {
    if (room == null) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        hasSavedReading = false;
      });
      return;
    }

    final selectedRoom = room!;

    setState(() {
      isLoading = true;
      loadError = null;
    });

    try {
      final data = await readingService.getReading(
        room: selectedRoom,
        month: month,
      );

      if (!mounted || room != selectedRoom) return;

      if (data != null) {
        electricOldController.text =
            '${data['electricOld'] ?? 0}';

        waterOldController.text =
            '${data['waterOld'] ?? 0}';

        electricNewController.text =
            data['electricNew']?.toString() ?? '';

        waterNewController.text =
            data['waterNew']?.toString() ?? '';

        parkingController.text =
            '${data['parking'] ?? 0}';

        hasSavedReading = data['electricNew'] != null &&
            data['waterNew'] != null;
      } else {
        electricOldController.text = '0';
        electricNewController.clear();
        waterOldController.text = '0';
        waterNewController.clear();
        parkingController.text = '0';

        hasSavedReading = false;
      }
    } catch (e) {
      if (!mounted || room != selectedRoom) return;

      setState(() {
        loadError = 'Không tải được dữ liệu Firebase: $e';
      });
    } finally {
      if (mounted && room == selectedRoom) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> saveReading() async {
    if (isSaving) return;

    if (room == null) {
      showMessage('Vui lòng chọn phòng trước khi lưu.');
      return;
    }

    if (electricNewController.text.trim().isEmpty ||
        waterNewController.text.trim().isEmpty) {
      showMessage('Vui lòng nhập chỉ số điện và nước mới.');
      return;
    }

    if (electricNew < electricOld || waterNew < waterOld) {
      showMessage('Chỉ số mới không được nhỏ hơn chỉ số cũ.');
      return;
    }

    if (electricNew < 0 ||
        waterNew < 0 ||
        parkingPeople < 0) {
      showMessage('Chỉ số không được là số âm.');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await readingService.saveReading(
        room: room!,
        month: month,
        electricOld: electricOld,
        electricNew: electricNew,
        waterOld: waterOld,
        waterNew: waterNew,
        electricPrice: electricPrice.toInt(),
        waterPrice: waterPrice.toInt(),
      );

      if (!mounted) return;

      setState(() {
        hasSavedReading = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lưu chỉ số lên Firebase thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      showMessage('Lưu thất bại: $e');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    roomSubscription?.cancel();
    electricOldController.dispose();
    electricNewController.dispose();
    waterOldController.dispose();
    waterNewController.dispose();
    parkingController.dispose();
    super.dispose();
  }

  Widget buildInput({
    required TextEditingController controller,
    required String unit,
    bool editable = true,
  }) {
    return Container(
      height: 43,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: editable ? Colors.white : const Color(0xFFF1F3F7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: editable
              ? const Color(0xFFDDE2EA)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: !editable || isLoading || isSaving,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF303846),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF9AA3B2),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMeterCard({
    required String title,
    required String subtitle,
    required String icon,
    required Color iconColor,
    required int usage,
    required int total,
    required String unit,
    required String priceText,
    required TextEditingController oldController,
    required TextEditingController newController,
    required bool highlighted,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: highlighted
            ? Border.all(color: primaryColor, width: 2.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  icon,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF343B49),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF8993A3),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Đơn giá',
                    style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFF8993A3),
                    ),
                  ),
                  Text(
                    priceText,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF424A58),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chỉ số cũ',
                      style: TextStyle(
                        fontSize: 9,
                        color: Color(0xFF697386),
                      ),
                    ),
                    const SizedBox(height: 5),
                    buildInput(
                      controller: oldController,
                      unit: unit,
                      editable: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chỉ số mới',
                      style: TextStyle(
                        fontSize: 9,
                        color: Color(0xFF697386),
                      ),
                    ),
                    const SizedBox(height: 5),
                    buildInput(
                      controller: newController,
                      unit: unit,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Số tiêu thụ',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF8993A3),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '$usage $unit',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF657186),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'Thành tiền',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF8993A3),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '${formatMoney(total)}đ',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF657186),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildFixedService({
    required String title,
    required String subtitle,
    required String icon,
    required Color color,
    required int total,
  }) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              icon,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF343B49),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF8993A3),
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Thành tiền',
                style: TextStyle(
                  fontSize: 9,
                  color: Color(0xFF8993A3),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${formatMoney(total)}đ',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424A58),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildParkingCard() {
    return Container(
      height: 88,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 27,
                height: 27,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF9015),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'P',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gửi xe',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF343B49),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Theo người · 100.000đ/người',
                      style: TextStyle(
                        fontSize: 9,
                        color: Color(0xFF8993A3),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Thành tiền',
                    style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFF8993A3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatMoney(parkingTotal)}đ',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF424A58),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Expanded(
                flex: 2,
                child: Text(
                  'Số người gửi',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF8993A3),
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 26,
                  child: TextField(
                    controller: parkingController,
                    keyboardType: TextInputType.number,
                    readOnly: isLoading || isSaving,
                    textAlign: TextAlign.center,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF1F3F7),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              const Text(' ', style: TextStyle(fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildBottomNavigation() {
    final items = [
      ('Phòng', Icons.home_outlined),
      ('Người thuê', Icons.person_outline),
      ('Dịch vụ', Icons.payments_outlined),
      ('Hóa đơn', Icons.receipt_long_outlined),
      ('Hợp đồng', Icons.description_outlined),
      ('Bảo trì', Icons.build_outlined),
      ('Tài khoản', Icons.settings_outlined),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFEDF0F4),
            width: 0.7,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: List.generate(items.length, (index) {
              final isSelected = selectedIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => selectedIndex = index);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        items[index].$2,
                        size: 17,
                        color: isSelected
                            ? primaryColor
                            : const Color(0xFF8490A2),
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          items[index].$1,
                          style: TextStyle(
                            fontSize: 8,
                            color: isSelected
                                ? primaryColor
                                : const Color(0xFF8490A2),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 45,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 17,
            color: Color(0xFF424A58),
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Nhập chỉ số',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF343B49),
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          if (loadError != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.all(8),
              child: Text(
                loadError!,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.red,
                ),
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 62,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Phòng',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Color(0xFF8993A3),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 32,
                                    child: DropdownButton<String>(
                                      value: room != null &&
                                              rooms.any(
                                                (r) => r['name'] == room,
                                              )
                                          ? room
                                          : null,
                                      isExpanded: true,
                                      isDense: true,
                                      underline: const SizedBox(),
                                      iconSize: 18,
                                      hint: const Text(
                                        'Chọn phòng',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                      items: rooms.map((r) {
                                        return DropdownMenuItem<String>(
                                          value: r['name'],
                                          child: Text(
                                            r['name']!,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF343B49),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: isLoading ||
                                              isSaving ||
                                              rooms.isEmpty
                                          ? null
                                          : (value) async {
                                              if (value == null ||
                                                  value == room) {
                                                return;
                                              }

                                              setState(() {
                                                room = value;
                                                isLoading = true;
                                                hasSavedReading = false;
                                                electricOldController.text = '0';
                                                electricNewController.clear();
                                                waterOldController.text = '0';
                                                waterNewController.clear();
                                                parkingController.text = '0';
                                              });

                                              await loadReading();
                                            },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Tháng',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFF8993A3),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  month,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF343B49),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      buildMeterCard(
                        title: 'Điện',
                        subtitle: 'Theo chỉ số',
                        icon: 'ϟ',
                        iconColor: primaryColor,
                        usage: electricUsage,
                        total: electricTotal,
                        unit: 'kWh',
                        priceText: '3.500đ/kWh',
                        oldController: electricOldController,
                        newController: electricNewController,
                        highlighted: false,
                      ),
                      const SizedBox(height: 10),
                      buildMeterCard(
                        title: 'Nước',
                        subtitle: 'Theo chỉ số',
                        icon: '♦',
                        iconColor: const Color(0xFF079DB7),
                        usage: waterUsage,
                        total: waterTotal,
                        unit: 'm³',
                        priceText: '20.000đ/m³',
                        oldController: waterOldController,
                        newController: waterNewController,
                        highlighted: false,
                      ),
                      const SizedBox(height: 10),
                      buildFixedService(
                        title: 'WiFi',
                        subtitle: 'Theo phòng · 101.000đ/tháng',
                        icon: '⌁',
                        color: const Color(0xFF6046D8),
                        total: wifiTotal,
                      ),
                      const SizedBox(height: 8),
                      buildFixedService(
                        title: 'Đổ rác',
                        subtitle: 'Theo phòng · 20.000đ/tháng',
                        icon: '♻',
                        color: const Color(0xFF20A653),
                        total: trashTotal,
                      ),
                      const SizedBox(height: 8),
                      buildParkingCard(),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 43,
                        child: ElevatedButton(
                          onPressed: isLoading ||
                                  isSaving ||
                                  room == null
                              ? null
                              : saveReading,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                primaryColor.withValues(alpha: 0.6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  isLoading
                                      ? 'Đang tải dữ liệu...'
                                      : hasSavedReading
                                          ? 'Cập nhật chỉ số'
                                          : 'Lưu chỉ số',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: buildBottomNavigation(),
    );
  }
}
