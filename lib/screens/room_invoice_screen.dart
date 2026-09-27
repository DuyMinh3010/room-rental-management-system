import 'package:flutter/material.dart';
import 'invoice_detail_screen.dart';

class RoomInvoiceScreen extends StatelessWidget {
  const RoomInvoiceScreen({super.key});

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
          // ================= 4 TAB =================
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _tab('Tổng quan', false),
                _tab('Người thuê', false),
                _tab('Dịch vụ', false),
                _tab('Hóa đơn', true),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ================= DANH SÁCH HÓA ĐƠN =================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // HÓA ĐƠN 1
                  _invoiceCard(
                    context: context,
                    invoiceCode: 'HD-0005',
                    date: '01/05/2026 - 31/05/2026',
                    total: '4.275.000đ',
                    status: 'Chưa thanh toán',
                    isPaid: false,
                    blue: blue,
                  ),

                  const SizedBox(height: 12),

                  // HÓA ĐƠN 2
                  _invoiceCard(
                    context: context,
                    invoiceCode: 'HD-0004',
                    date: '01/04/2026 - 30/04/2026',
                    total: '3.700.000đ',
                    status: 'Đã thanh toán',
                    isPaid: true,
                    blue: blue,
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
        currentIndex: 3,
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

  // ================= CARD HÓA ĐƠN =================
  Widget _invoiceCard({
    required BuildContext context,
    required String invoiceCode,
    required String date,
    required String total,
    required String status,
    required bool isPaid,
    required Color blue,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),

      // Bấm card → Chi tiết hóa đơn
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const InvoiceDetailScreen(),
          ),
        );
      },

      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= MÃ + TRẠNG THÁI =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  invoiceCode,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? const Color(0xFFE8F7EE)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isPaid
                          ? Colors.green
                          : Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ================= NGÀY =================
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: Colors.grey,
                ),
                const SizedBox(width: 7),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            const Divider(height: 1),

            const SizedBox(height: 14),

            // ================= TỔNG TIỀN =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng tiền',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  total,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ================= CHƯA THANH TOÁN =================
            if (!isPaid)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const InvoiceDetailScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Thanh toán',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            // ================= ĐÃ THANH TOÁN =================
            if (isPaid)
              Row(
                children: [
                  const Icon(
                    Icons.qr_code_2,
                    size: 20,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'QR • Chuyển khoản',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}