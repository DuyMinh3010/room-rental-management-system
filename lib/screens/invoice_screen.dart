import 'package:flutter/material.dart';

class InvoiceScreen extends StatelessWidget {
  const InvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      // =====================================================
      // APP BAR
      // =====================================================
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 58,

        title: Row(
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 35,
              ),
              icon: const Icon(
                Icons.chevron_left,
                size: 25,
                color: Color(0xFF1D2939),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),

            const Text(
              'Chi tiết hóa đơn',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D2939),
              ),
            ),
          ],
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(
              right: 12,
            ),

            child: Center(
              child: Container(
                height: 28,

                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ),

                decoration: BoxDecoration(
                  color: const Color(0xFF2864F0),
                  borderRadius:
                      BorderRadius.circular(20),
                ),

                child: const Row(
                  children: [
                    Icon(
                      Icons.add,
                      size: 14,
                      color: Colors.white,
                    ),

                    SizedBox(width: 3),

                    Text(
                      'Thêm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // =====================================================
      // BODY
      // =====================================================
      body: Column(
        children: [

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    const SizedBox(height: 2),

                    // =================================================
                    // CARD THÔNG TIN HÓA ĐƠN
                    // =================================================
                    _buildInvoiceInformationCard(),

                    const SizedBox(height: 12),

                    // =================================================
                    // CARD CHI TIẾT KHOẢN PHÍ
                    // =================================================
                    _buildFeeCard(),

                    const SizedBox(height: 12),

                    // =================================================
                    // CARD THANH TOÁN QR
                    // =================================================
                    _buildPaymentCard(),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),

          // ==========================================================
          // NÚT XÁC NHẬN
          // ==========================================================
          Container(
            padding: const EdgeInsets.fromLTRB(
              12,
              8,
              12,
              8,
            ),

            color: const Color(0xFFF7F8FA),

            child: SizedBox(
              width: double.infinity,
              height: 40,

              child: ElevatedButton(
                onPressed: () {
                  // Sau này xử lý xác nhận thanh toán
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF2864F0),

                  foregroundColor: Colors.white,

                  elevation: 0,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                ),

                child: const Text(
                  'Xác nhận đã thanh toán',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // =====================================================
      // BOTTOM NAVIGATION
      // =====================================================
      bottomNavigationBar:
          _buildBottomNavigation(),
    );
  }

  // ==========================================================
  // CARD 1: THÔNG TIN HÓA ĐƠN
  // ==========================================================

  Widget _buildInvoiceInformationCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(12),

        border: Border.all(
          color: const Color(0xFFE4E7EC),
          width: 0.5,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          // ==========================================
          // DÒNG HD + TRẠNG THÁI
          // ==========================================

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    const Text(
                      'HD-0005',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            Color(0xFF1D2939),
                      ),
                    ),

                    const SizedBox(height: 3),

                    const Text(
                      'Phòng P.101',
                      style: TextStyle(
                        fontSize: 9,
                        color:
                            Color(0xFF2864F0),
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // TRẠNG THÁI
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),

                decoration: BoxDecoration(
                  color: const Color(
                    0xFFFFF3E5,
                  ),

                  borderRadius:
                      BorderRadius.circular(20),
                ),

                child: const Text(
                  'Chưa thanh toán',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight:
                        FontWeight.w500,
                    color:
                        Color(0xFFF28B22),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          const Divider(
            height: 1,
            color: Color(0xFFE4E7EC),
          ),

          const SizedBox(height: 9),

          // ==========================================
          // NGƯỜI THUÊ
          // ==========================================

          Row(
            children: [

              const Icon(
                Icons.person_outline,
                size: 14,
                color: Color(0xFF667085),
              ),

              const SizedBox(width: 7),

              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF667085),
                  ),

                  children: [
                    TextSpan(
                      text: 'Người thuê: ',
                    ),

                    TextSpan(
                      text: 'Nguyễn Minh Chiến',
                      style: TextStyle(
                        color:
                            Color(0xFF1D2939),
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          // ==========================================
          // KỲ THANH TOÁN
          // ==========================================

          Row(
            children: [

              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: Color(0xFF667085),
              ),

              const SizedBox(width: 7),

              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF667085),
                  ),

                  children: [
                    TextSpan(
                      text: 'Kỳ thanh toán: ',
                    ),

                    TextSpan(
                      text:
                          '01/05/2026 - 31/05/2026',
                      style: TextStyle(
                        color:
                            Color(0xFF1D2939),
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // CARD 2: CHI TIẾT KHOẢN PHÍ
  // ==========================================================

  Widget _buildFeeCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(12),

        border: Border.all(
          color: const Color(0xFFE4E7EC),
          width: 0.5,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const Text(
            'Chi tiết khoản phí',
            style: TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF1D2939),
            ),
          ),

          const SizedBox(height: 9),

          _buildFeeRow(
            'Tiền phòng',
            '3.500.000đ',
          ),

          const SizedBox(height: 7),

          _buildFeeRow(
            'Điện (130 kWh)',
            '455.000đ',
          ),

          const SizedBox(height: 7),

          _buildFeeRow(
            'Nước (10 m³)',
            '200.000đ',
          ),

          const SizedBox(height: 7),

          _buildFeeRow(
            'WiFi',
            '100.000đ',
          ),

          const SizedBox(height: 7),

          _buildFeeRow(
            'Đổ rác',
            '20.000đ',
          ),

          const SizedBox(height: 9),

          const Divider(
            height: 1,
            color: Color(0xFFE4E7EC),
          ),

          const SizedBox(height: 9),

          // TỔNG CỘNG
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

            children: const [

              Text(
                'Tổng cộng',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      Color(0xFF1D2939),
                ),
              ),

              Text(
                '4.275.000đ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      Color(0xFF1D2939),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DÒNG KHOẢN PHÍ
  // ==========================================================

  Widget _buildFeeRow(
    String title,
    String amount,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,

      children: [

        Text(
          title,
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF667085),
          ),
        ),

        Text(
          amount,
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF1D2939),
            fontWeight:
                FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // CARD 3: THANH TOÁN
  // ==========================================================

  Widget _buildPaymentCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 13,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(12),

        border: Border.all(
          color: const Color(0xFFE4E7EC),
          width: 0.5,
        ),
      ),

      child: Column(
        children: [

          const Text(
            'HÌNH THỨC THANH TOÁN',
            style: TextStyle(
              fontSize: 8,
              color: Color(0xFF667085),
              letterSpacing: 0.3,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Chuyển khoản Ngân hàng',
            style: TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF1D2939),
            ),
          ),

          const SizedBox(height: 10),

          // QR CODE GIẢ LẬP
          _buildQrCode(),

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ==========================================================
  // QR CODE
  // ==========================================================

  Widget _buildQrCode() {
    return Container(
      width: 108,
      height: 108,

      padding: const EdgeInsets.all(8),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(9),

        border: Border.all(
          color: const Color(0xFFD0D5DD),
        ),
      ),

      child: CustomPaint(
        painter: FakeQrPainter(),
      ),
    );
  }

  // ==========================================================
  // BOTTOM NAVIGATION
  // ==========================================================

  Widget _buildBottomNavigation() {
    return Container(
      height: 62,

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
        mainAxisAlignment:
            MainAxisAlignment.spaceAround,

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
            false,
          ),

          _bottomItem(
            Icons.receipt_outlined,
            'Hóa đơn',
            true,
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

  // ==========================================================
  // BOTTOM ITEM
  // ==========================================================

  Widget _bottomItem(
    IconData icon,
    String title,
    bool selected,
  ) {
    return SizedBox(
      width: 40,

      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [

          Container(
            padding:
                const EdgeInsets.all(4),

            decoration: BoxDecoration(
              color: selected
                  ? const Color(
                      0xFFEAF1FF,
                    )
                  : Colors.transparent,

              borderRadius:
                  BorderRadius.circular(7),
            ),

            child: Icon(
              icon,
              size: 14,

              color: selected
                  ? const Color(
                      0xFF2864F0,
                    )
                  : const Color(
                      0xFF667085,
                    ),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,

            style: TextStyle(
              fontSize: 5.5,

              color: selected
                  ? const Color(
                      0xFF2864F0,
                    )
                  : const Color(
                      0xFF667085,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// QR CODE GIẢ LẬP
// ============================================================
//
// Phần này chỉ để dựng UI giống ảnh.
// Sau này làm chức năng thật có thể thay bằng qr_flutter.
// ============================================================

class FakeQrPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final cellSize = size.width / 21;

    // Tạo pattern QR giả
    final pattern = [
      '111111100101101111111',
      '100000101010101000001',
      '101110100111101011101',
      '101110101100101011101',
      '101110100011101011101',
      '100000101101001000001',
      '111111101010101111111',
      '000000001101000000000',
      '101101111011101101101',
      '010010010110010010010',
      '111001101101111001101',
      '001101010010100101100',
      '110110111001111010111',
      '000000001010100001000',
      '111111101101011101101',
      '100000100011010100010',
      '101110101110111101101',
      '101110100101001001110',
      '101110101101111100101',
      '100000101011001010100',
      '111111101101101101111',
    ];

    for (int row = 0;
        row < pattern.length;
        row++) {
      for (int col = 0;
          col < pattern[row].length;
          col++) {
        if (pattern[row][col] == '1') {
          canvas.drawRect(
            Rect.fromLTWH(
              col * cellSize,
              row * cellSize,
              cellSize + 0.5,
              cellSize + 0.5,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(
    CustomPainter oldDelegate,
  ) {
    return false;
  }

          

}