import 'package:flutter/material.dart';
import 'room_page.dart';

class RoomDetailPage extends StatefulWidget {
  final Map<String, String> room;
  final int initialTab;
  const RoomDetailPage({super.key, required this.room, this.initialTab = 0});
  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  late int tab;
  @override
  void initState() { super.initState(); tab = widget.initialTab.clamp(0, 3); }
  void notice(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$s chưa kết nối dữ liệu')));
  Widget card(Widget child) => Container(margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: child);
  Widget heading(String s) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(s, style: const TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.bold)));

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: canvas, body: SafeArea(child: Column(children: [
    Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(13, 16, 13, 24), children: [
      Row(children: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.chevron_left)), const Text('Chi tiết phòng', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: ink))]),
      const SizedBox(height: 52),
      Row(children: List.generate(4, (i) => Expanded(child: InkWell(onTap: () => setState(() => tab = i), child: Column(children: [Text(['Tổng quan', 'Người thuê', 'Dịch vụ', 'Hóa đơn'][i], style: TextStyle(fontSize: 11, color: tab == i ? blue : muted, fontWeight: tab == i ? FontWeight.bold : FontWeight.normal)), const SizedBox(height: 8), Container(height: 2, color: tab == i ? blue : Colors.transparent)]))))),
      const SizedBox(height: 25),
      if (tab == 0) ...[heading('Tổng quan ${widget.room['name']}'), card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Phòng ${widget.room['name']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Text('Trạng thái: ${widget.room['status']}'), Text('Diện tích: ${widget.room['area']}'), Text('Số người: ${widget.room['people']}'), Text('Giá thuê: ${widget.room['price']}')]))],
      if (tab == 1) ...[heading('Danh sách người thuê (${widget.room['name'] == 'P.101' ? 2 : 0})'), if (widget.room['name'] == 'P.101') ...[
        tenant('N', 'Nguyễn Văn A', 'Người thuê chính', '0901 234 567'), tenant('T', 'Trần Thị B', 'Thành viên', '0987 654 321'),
      ] else card(const Text('Chưa có người thuê')), FilledButton(onPressed: () => notice('Thêm người thuê'), style: FilledButton.styleFrom(backgroundColor: blue), child: const Text('+ Thêm người thuê'))],
      if (tab == 2) ...[heading('Dịch vụ của ${widget.room['name']}'), service('ϟ', 'Điện', 'Theo chỉ số', '3.500đ/kWh', blue), service('●', 'Nước', 'Theo chỉ số', '20.000đ/m³', const Color(0xFF0992AA)), service('Wi', 'WiFi', 'Theo phòng', '100.000đ/tháng', const Color(0xFF783BE0)), service('R', 'Đổ rác', 'Theo phòng', '20.000đ/tháng', const Color(0xFFE45B13)), service('P', 'Gửi xe', 'Theo người', '100.000đ/người', const Color(0xFF159B4F)), SizedBox(width: double.infinity, child: TextButton(onPressed: () => notice('Thêm dịch vụ'), style: TextButton.styleFrom(backgroundColor: Colors.white), child: const Text('+ Thêm dịch vụ')))],
      if (tab == 3) ...[heading('Hóa đơn ${widget.room['name']}'), if (widget.room['name'] == 'P.101') ...[invoice('HD-0005', '01/05/2026 - 31/05/2026', '4.275.000đ', false), invoice('HD-0004', '01/04/2026 - 30/04/2026', '3.700.000đ', true)] else card(const Text('Chưa có hóa đơn'))],
    ])), AppBottomBar(selected: tab == 0 ? 0 : tab),
  ])));

  Widget tenant(String letter, String name, String role, String phone) => card(Row(children: [CircleAvatar(backgroundColor: blue, child: Text(letter, style: const TextStyle(color: Colors.white))), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)), const SizedBox(height: 5), Text(role, style: const TextStyle(fontSize: 10, color: blue)), Text('${widget.room['name']}  •  $phone', style: const TextStyle(fontSize: 10, color: muted))])), IconButton(onPressed: () => notice('Chi tiết người thuê'), icon: const Icon(Icons.chevron_right, color: muted))]));
  Widget service(String symbol, String name, String mode, String price, Color color) => card(Row(children: [CircleAvatar(radius: 17, backgroundColor: color, child: Text(symbol, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)), Text(mode, style: const TextStyle(fontSize: 10, color: muted))])), Text(price, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)), IconButton(onPressed: () => notice('Chi tiết dịch vụ'), icon: const Icon(Icons.chevron_right, size: 17, color: muted))]));
  Widget invoice(String id, String period, String amount, bool paid) => card(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(id, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(period, style: const TextStyle(fontSize: 10, color: muted)), const SizedBox(height: 8), Text(amount, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)), if (paid) const Text('QR • Chuyển khoản', style: TextStyle(fontSize: 10, color: muted))])), Column(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: paid ? const Color(0xFFE8FAF0) : const Color(0xFFFFF1E8), borderRadius: BorderRadius.circular(16)), child: Text(paid ? 'Đã thanh toán' : 'Chưa thanh toán', style: TextStyle(fontSize: 10, color: paid ? Colors.green : Colors.deepOrange))), if (!paid) Padding(padding: const EdgeInsets.only(top: 13), child: FilledButton(onPressed: () => notice('Thanh toán'), style: FilledButton.styleFrom(backgroundColor: blue, minimumSize: const Size(75, 27)), child: const Text('Thanh toán', style: TextStyle(fontSize: 10))))]) ]));
}
