
import 'package:flutter/material.dart';

class ContractEditScreen extends StatefulWidget {
  const ContractEditScreen({super.key});

  @override
  State<ContractEditScreen> createState() => _ContractEditScreenState();
}

class _ContractEditScreenState extends State<ContractEditScreen> {
  final maHopDong = TextEditingController(text: 'HD-01/2026');
  final nguoiThue = TextEditingController(text: 'Nguyễn Minh Chiến');
  final soDienThoai = TextEditingController(text: '033 8250 458');
  final email = TextEditingController(text: 'nmc2408@gmail.com');
  final cccd = TextEditingController(text: '29219050398');
  final phong = TextEditingController(text: 'P.101 (Tầng 1)');
  final tienThue = TextEditingController(text: '2500000');
  final tienCoc = TextEditingController(text: '3000000');
  final ghiChu = TextEditingController(
    text: 'Khách thuê được phép nuôi thú cưng nhỏ',
  );

  String trangThai = 'Đang thuê';
  String ngayBatDau = '01/07/2026';
  String ngayKetThuc = '01/07/2027';

  static const nen = Color(0xFFF5F5F5);
  static const chu = Color(0xFF111827);
  static const phu = Color(0xFF64748B);
  static const xanh = Color(0xFF2563EB);
  static const vien = Color(0xFFE9EDF2);

  @override
  void dispose() {
    maHopDong.dispose();
    nguoiThue.dispose();
    soDienThoai.dispose();
    email.dispose();
    cccd.dispose();
    phong.dispose();
    tienThue.dispose();
    tienCoc.dispose();
    ghiChu.dispose();
    super.dispose();
  }

  Widget the({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: vien, width: 0.7),
      ),
      child: child,
    );
  }

  Widget tieuDe(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11.5,
          height: 1.25,
          fontWeight: FontWeight.w700,
          color: chu,
        ),
      ),
    );
  }

  Widget dongNguoiThue({
    required IconData icon,
    required String nhan,
    required String giaTri,
    bool avatar = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: avatar
                  ? const Color(0xFFE8EFFF)
                  : const Color(0xFFF2F4F7),
              shape: avatar ? BoxShape.circle : BoxShape.circle,
            ),
            child: avatar
                ? Center(
                    child: Text(
                      'NA',
                      style: TextStyle(
                        color: xanh,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : Icon(icon, size: 13, color: const Color(0xFF303844)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!avatar)
                  Text(
                    nhan,
                    style: const TextStyle(
                      color: chu,
                      fontSize: 9,
                      height: 1.3,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                Text(
                  giaTri,
                  style: TextStyle(
                    color: chu,
                    fontSize: 9.5,
                    height: 1.35,
                    fontWeight: avatar ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget dongPhi(String ten, String gia) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              ten,
              style: const TextStyle(
                fontSize: 9,
                height: 1.3,
                color: phu,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              gia,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 9,
                height: 1.3,
                color: chu,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget nut({
    required String text,
    required Color mau,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 27,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: mau,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> chonNgay(bool batDau) async {
    final hienTai = batDau ? ngayBatDau : ngayKetThuc;
    final parts = hienTai.split('/');
    final ngay = DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );

    final ketQua = await showDatePicker(
      context: context,
      initialDate: ngay,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (ketQua != null) {
      setState(() {
        final ngayMoi =
            '${ketQua.day.toString().padLeft(2, '0')}/'
            '${ketQua.month.toString().padLeft(2, '0')}/'
            '${ketQua.year}';
        if (batDau) {
          ngayBatDau = ngayMoi;
        } else {
          ngayKetThuc = ngayMoi;
        }
      });
    }
  }

  Widget truongNhap(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 13, color: chu),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12, color: phu),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
      ),
    );
  }

  void moChinhSua() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                18,
                16,
                MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chỉnh sửa thông tin',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    truongNhap('Người thuê', nguoiThue),
                    truongNhap('Số điện thoại', soDienThoai),
                    truongNhap('Email', email),
                    truongNhap('CCCD', cccd),
                    truongNhap('Phòng', phong),
                    truongNhap('Tiền thuê mỗi tháng', tienThue),
                    truongNhap('Tiền đặt cọc', tienCoc),
                    DropdownButtonFormField<String>(
                      value: trangThai,
                      decoration: const InputDecoration(
                        labelText: 'Trạng thái',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Đang thuê',
                          child: Text('Đang thuê'),
                        ),
                        DropdownMenuItem(
                          value: 'Sắp hết hạn',
                          child: Text('Sắp hết hạn'),
                        ),
                        DropdownMenuItem(
                          value: 'Đã thanh lý',
                          child: Text('Đã thanh lý'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => trangThai = value);
                          setState(() => trangThai = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ghiChu,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          setState(() {});
                        },
                        child: const Text('Lưu thay đổi'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void xuatPdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng xuất PDF chưa được tích hợp.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: nen,
      appBar: AppBar(
        toolbarHeight: 44,
        backgroundColor: nen,
        surfaceTintColor: nen,
        elevation: 0,
        leadingWidth: 38,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(
            Icons.chevron_left,
            size: 23,
            color: chu,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        titleSpacing: 4,
        title: const Text(
          'Chi tiết hợp đồng',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: chu,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Center(
              child: SizedBox(
                height: 25,
                child: TextButton(
                  onPressed: moChinhSua,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFE8EFFF),
                    foregroundColor: xanh,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Chỉnh sửa',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
        children: [
          the(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF0FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        size: 16,
                        color: xanh,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            maHopDong.text,
                            style: const TextStyle(
                              fontSize: 11,
                              height: 1.3,
                              fontWeight: FontWeight.w700,
                              color: chu,
                            ),
                          ),
                          Text(
                            nguoiThue.text,
                            style: const TextStyle(
                              fontSize: 8,
                              height: 1.4,
                              color: chu,
                            ),
                          ),
                          Text(
                            'Phòng: ${phong.text.split(' ').first}',
                            style: const TextStyle(
                              fontSize: 8,
                              height: 1.4,
                              color: phu,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F8EC),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        trangThai,
                        style: const TextStyle(
                          color: Color(0xFF079455),
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16, color: vien, thickness: 0.7),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 11,
                      color: phu,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '$ngayBatDau-$ngayKetThuc',
                        style: const TextStyle(
                          fontSize: 8.5,
                          color: chu,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Text(
                      'Đã đặt cọc',
                      style: TextStyle(
                        fontSize: 8,
                        color: chu,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          the(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tieuDe('Thông tin người thuê'),
                dongNguoiThue(
                  icon: Icons.person_outline,
                  nhan: '',
                  giaTri: nguoiThue.text,
                  avatar: true,
                ),
                const Divider(height: 1, color: vien, thickness: 0.7),
                dongNguoiThue(
                  icon: Icons.call,
                  nhan: 'Số điện thoại',
                  giaTri: soDienThoai.text,
                ),
                const Divider(height: 1, color: vien, thickness: 0.7),
                dongNguoiThue(
                  icon: Icons.email,
                  nhan: 'Email',
                  giaTri: email.text,
                ),
                const Divider(height: 1, color: vien, thickness: 0.7),
                dongNguoiThue(
                  icon: Icons.badge_outlined,
                  nhan: 'CCCD',
                  giaTri: cccd.text,
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          the(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tieuDe('Thông tin phòng'),
                dongNguoiThue(
                  icon: Icons.calendar_month_outlined,
                  nhan: 'Phòng: ${phong.text}',
                  giaTri: 'Phòng khép kín, có 1 cửa sổ',
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 35),
                  child: Text(
                    'Phòng có gác lửng',
                    style: TextStyle(
                      fontSize: 8,
                      height: 1.4,
                      color: phu,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          the(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tieuDe('Thông tin thanh toán & Phí dịch vụ khác'),
                dongPhi('Tiền thuê phòng hàng tháng', '${tienThue.text}đ/tháng'),
                dongPhi('Tiền đặt cọc', '${tienCoc.text}đ (Đã thanh lý)'),
                dongPhi('Kỳ thanh toán', 'Đóng 1 tháng/lần'),
                dongPhi('Ngày thanh toán', 'Mùng 5 hàng tháng'),
                const Divider(height: 15, color: vien, thickness: 0.7),
                const Text(
                  'Phí dịch vụ:',
                  style: TextStyle(
                    fontSize: 9,
                    color: chu,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                dongPhi('Điện', '3.500đ/kWh'),
                dongPhi('Nước', '20.000đ/m³'),
                dongPhi('Wifi', '100.000đ/tháng'),
                dongPhi('Đổ rác', '30.000đ'),
                const Divider(height: 15, color: vien, thickness: 0.7),
                const Text(
                  'Ghi chú',
                  style: TextStyle(
                    fontSize: 9,
                    color: chu,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  ghiChu.text,
                  style: const TextStyle(
                    fontSize: 8,
                    height: 1.4,
                    color: phu,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          the(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tieuDe('Hành động'),
                nut(
                  text: 'Gia hạn hợp đồng',
                  mau: xanh,
                  onPressed: () async {
                    await chonNgay(false);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã cập nhật ngày kết thúc nếu bạn chọn ngày mới.'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                nut(
                  text: 'Chỉnh sửa thông tin',
                  mau: const Color(0xFF111827),
                  onPressed: moChinhSua,
                ),
                const SizedBox(height: 6),
                nut(
                  text: 'Xuất File PDF',
                  mau: const Color(0xFFDC2626),
                  onPressed: xuatPdf,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
