
import 'package:flutter/material.dart';

class MeterReadingScreen extends StatefulWidget {
  const MeterReadingScreen({super.key});

  @override
  State<MeterReadingScreen> createState() =>
      _MeterReadingScreenState();
}

class _MeterReadingScreenState
    extends State<MeterReadingScreen> {
  final TextEditingController electricOldController =
      TextEditingController(text: '1250');

  final TextEditingController electricNewController =
      TextEditingController();

  final TextEditingController waterOldController =
      TextEditingController(text: '48');

  final TextEditingController waterNewController =
      TextEditingController();

  final TextEditingController parkingController =
      TextEditingController(text: '0');

  final TextEditingController wifiController =
      TextEditingController(text: '100000');

  final TextEditingController rubbishController =
      TextEditingController(text: '20000');

  final int parkingPrice = 100000;

  int get parkingTotal {
    final people =
        int.tryParse(parkingController.text) ?? 0;
    return (people < 0 ? 0 : people) * parkingPrice;
  }

  String formatMoney(int amount) {
    return '${amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    )}đ';
  }

  @override
  void dispose() {
    electricOldController.dispose();
    electricNewController.dispose();
    waterOldController.dispose();
    waterNewController.dispose();
    parkingController.dispose();
    wifiController.dispose();
    rubbishController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 62,
        title: const Text(
          'Nhập chỉ số P.101 - Đủ dịch vụ',
          style: TextStyle(
            color: Color(0xFF2997F5),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF1597F4),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints:
                                    const BoxConstraints(
                                  minWidth: 25,
                                  minHeight: 25,
                                ),
                                icon: const Icon(
                                  Icons.chevron_left,
                                  size: 21,
                                  color: Color(0xFF1D2939),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              const Text(
                                'Nhập chỉ số',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1D2939),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FB),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                _smallInfo('Phòng', 'P.101'),
                                _smallInfo(
                                  'Tháng',
                                  '09/2026',
                                  alignRight: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildElectricCard(),
                          const SizedBox(height: 8),
                          _buildWaterCard(),
                          const SizedBox(height: 8),
                          _buildSimpleServiceCard(
                            icon: Icons.wifi,
                            iconColor: const Color(0xFF5B45D6),
                            title: 'WiFi',
                            subtitle:
                                'Theo phòng • Có thể sửa giá',
                            controller: wifiController,
                          ),
                          const SizedBox(height: 8),
                          _buildSimpleServiceCard(
                            icon: Icons.delete_outline,
                            iconColor: const Color(0xFF23A653),
                            title: 'Đổ rác',
                            subtitle:
                                'Theo phòng • Có thể sửa giá',
                            controller: rubbishController,
                          ),
                          const SizedBox(height: 8),
                          _buildParkingCard(),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 39,
                            child: ElevatedButton(
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Đã lưu chỉ số',
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF2864F0),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(7),
                                ),
                              ),
                              child: const Text(
                                'Lưu chỉ số',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _smallInfo(
    String title,
    String value, {
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 6.5,
            color: Color(0xFF98A2B3),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D2939),
          ),
        ),
      ],
    );
  }

  Widget _buildElectricCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _serviceIcon(
                Icons.bolt,
                const Color(0xFF3B64E5),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Điện',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D2939),
                      ),
                    ),
                    Text(
                      'Theo chỉ số',
                      style: TextStyle(
                        fontSize: 6.5,
                        color: Color(0xFF98A2B3),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    'Đơn giá',
                    style: TextStyle(
                      fontSize: 6,
                      color: Color(0xFF98A2B3),
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    '3.500đ/kWh',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: _buildMeterInput(
                  label: 'Chỉ số cũ',
                  controller: electricOldController,
                  unit: 'kWh',
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _buildMeterInput(
                  label: 'Chỉ số mới',
                  controller: electricNewController,
                  unit: 'kWh',
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: const [
              Expanded(
                child: Text(
                  'Số tiêu thụ',
                  style: TextStyle(
                    fontSize: 6,
                    color: Color(0xFF98A2B3),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Tự động tính',
                  style: TextStyle(
                    fontSize: 6,
                    color: Color(0xFF98A2B3),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Thành tiền',
                  style: TextStyle(
                    fontSize: 6,
                    color: Color(0xFF98A2B3),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Tự động tính',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 6,
                    color: Color(0xFF98A2B3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _serviceIcon(
                Icons.water_drop_outlined,
                const Color(0xFF1297B8),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Nước',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Theo chỉ số',
                      style: TextStyle(
                        fontSize: 6.5,
                        color: Color(0xFF98A2B3),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    'Đơn giá',
                    style: TextStyle(
                      fontSize: 6,
                      color: Color(0xFF98A2B3),
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    '20.000đ/m³',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: _buildMeterInput(
                  label: 'Chỉ số cũ',
                  controller: waterOldController,
                  unit: 'm³',
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _buildMeterInput(
                  label: 'Chỉ số mới',
                  controller: waterNewController,
                  unit: 'm³',
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: const [
              Expanded(
                child: Text(
                  'Số tiêu thụ',
                  style: TextStyle(
                    fontSize: 6,
                    color: Color(0xFF98A2B3),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Tự động tính',
                  style: TextStyle(
                    fontSize: 6,
                    color: Color(0xFF98A2B3),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Thành tiền',
                  style: TextStyle(
                    fontSize: 6,
                    color: Color(0xFF98A2B3),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Tự động tính',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 6,
                    color: Color(0xFF98A2B3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeterInput({
    required String label,
    required TextEditingController controller,
    required String unit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 6.5,
            color: Color(0xFF667085),
          ),
        ),
        const SizedBox(height: 3),
        Container(
          height: 27,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: const Color(0xFFE4E7EC),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (_) {
                    setState(() {});
                  },
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 0,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 7),
                child: Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 5.5,
                    color: Color(0xFF98A2B3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleServiceCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required TextEditingController controller,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          _serviceIcon(icon, iconColor),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 6,
                    color: Color(0xFF98A2B3),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 90,
            height: 27,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              onChanged: (_) {
                setState(() {});
              },
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                suffixText: 'đ',
                suffixStyle: const TextStyle(
                  fontSize: 7,
                  color: Color(0xFF667085),
                ),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 6,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: Color(0xFFE4E7EC),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: Color(0xFFE4E7EC),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParkingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          _serviceIcon(
            Icons.local_parking,
            const Color(0xFFF28B22),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Gửi xe',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Theo người • 100.000đ/người',
                  style: TextStyle(
                    fontSize: 6,
                    color: Color(0xFF98A2B3),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Số người gửi',
                style: TextStyle(
                  fontSize: 6,
                  color: Color(0xFF98A2B3),
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: 42,
                height: 22,
                child: TextField(
                  controller: parkingController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (_) {
                    setState(() {});
                  },
                  style: const TextStyle(fontSize: 8),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF2F4F7),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Thành tiền',
                style: TextStyle(
                  fontSize: 6,
                  color: Color(0xFF98A2B3),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                formatMoney(parkingTotal),
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _serviceIcon(
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 13,
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 54,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE4E7EC),
            width: 0.7,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _bottomItem(
            Icons.home_outlined,
            'Phòng',
            false,
          ),
          _bottomItem(
            Icons.person_outline,
            'Người thuê',
            false,
          ),
          _bottomItem(
            Icons.circle,
            'Dịch vụ',
            true,
          ),
          _bottomItem(
            Icons.receipt_outlined,
            'Hóa đơn',
            false,
          ),
          _bottomItem(
            Icons.description_outlined,
            'Hợp đồng',
            false,
          ),
          _bottomItem(
            Icons.build_outlined,
            'Bảo trì',
            false,
          ),
          _bottomItem(
            Icons.settings_outlined,
            'Tài khoản',
            false,
          ),
        ],
      ),
    );
  }

  Widget _bottomItem(
    IconData icon,
    String title,
    bool selected,
  ) {
    return SizedBox(
      width: 42,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFEAF1FF)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              icon,
              size: 13,
              color: selected
                  ? const Color(0xFF2864F0)
                  : const Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 5.5,
              color: selected
                  ? const Color(0xFF2864F0)
                  : const Color(0xFF667085),
            ),
          ),
        ],
      ),
    );
  }
}
