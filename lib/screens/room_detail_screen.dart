
import 'package:flutter/material.dart';
import 'invoice_screen.dart';
import 'meter_reading_screen.dart';
import 'contract_edit_screen.dart';

class RoomDetailScreen extends StatelessWidget {
  const RoomDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left,
            color: Color(0xFF101828),
            size: 28,
          ),
          onPressed: () {},
        ),
        title: const Text(
          'P.101',
          style: TextStyle(
            color: Color(0xFF101828),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.more_horiz,
              color: Colors.black,
              size: 26,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              children: [
                                _tabItem(
                                  'Tổng quan',
                                  true,
                                  onTap: () {},
                                ),
                                _tabItem(
                                  'Người thuê',
                                  false,
                                  onTap: () {},
                                ),
                                _tabItem(
                                  'Dịch vụ',
                                  false,
                                  onTap: () {
                                    _openMeterReading(context);
                                  },
                                ),
                                _tabItem(
                                  'Hóa đơn',
                                  false,
                                  onTap: () {
                                    _openInvoice(context);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Thông tin phòng',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF101828),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _infoRow('Diện tích', '25 m²'),
                                _infoRow('Giá thuê', '3.500.000đ/tháng'),
                                _infoRow('Tiền cọc', '3.500.000đ'),
                                _infoRow('Ngày chốt tiền', '05 hàng tháng'),
                                _infoRow('Mô tả', 'Phòng thoáng, có cửa sổ'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dịch vụ áp dụng',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF101828),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _serviceTag(
                                'Điện',
                                const Color(0xFFEAF2FF),
                                const Color(0xFF2864F0),
                              ),
                              _serviceTag(
                                'Nước',
                                const Color(0xFFE8F9FB),
                                const Color(0xFF1597B5),
                              ),
                              _serviceTag(
                                'WiFi',
                                const Color(0xFFF1E8FF),
                                const Color(0xFF7B42D7),
                              ),
                              _serviceTag(
                                'Rác',
                                const Color(0xFFFFF1E7),
                                const Color(0xFFF27B22),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 260,
                      child: Center(
                        child: Text(
                          'ẢNH PHÒNG',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey.shade300,
                          ),
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
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  static void _openMeterReading(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MeterReadingScreen(),
      ),
    );
  }

  static void _openInvoice(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InvoiceScreen(),
      ),
    );
  }

  static void _openContract(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ContractEditScreen(),
      ),
    );
  }

  static Widget _tabItem(
    String title,
    bool selected, {
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected
                    ? const Color(0xFF2864F0)
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: selected
                  ? const Color(0xFF2864F0)
                  : const Color(0xFF667085),
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  static Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF98A2B3),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D2939),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _serviceTag(
    String text,
    Color background,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      height: 58,
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
            true,
            () {},
          ),
          _bottomItem(
            Icons.person_outline,
            'Người thuê',
            false,
            () {},
          ),
          _bottomItem(
            Icons.electrical_services_outlined,
            'Dịch vụ',
            false,
            () => _openMeterReading(context),
          ),
          _bottomItem(
            Icons.receipt_outlined,
            'Hóa đơn',
            false,
            () => _openInvoice(context),
          ),
          _bottomItem(
            Icons.description_outlined,
            'Hợp đồng',
            false,
            () => _openContract(context),
          ),
          _bottomItem(
            Icons.build_outlined,
            'Bảo trì',
            false,
            () {},
          ),
          _bottomItem(
            Icons.settings_outlined,
            'Tài khoản',
            false,
            () {},
          ),
        ],
      ),
    );
  }

  static Widget _bottomItem(
    IconData icon,
    String title,
    bool selected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 58,
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
                  size: 17,
                  color: selected
                      ? const Color(0xFF2864F0)
                      : const Color(0xFF667085),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 8,
                  color: selected
                      ? const Color(0xFF2864F0)
                      : const Color(0xFF667085),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
