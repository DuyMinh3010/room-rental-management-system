import 'package:flutter/material.dart';
import 'room_detail_page.dart';

const blue = Color(0xFF245DE5);
const ink = Color(0xFF202A3A);
const muted = Color(0xFF61738E);
const canvas = Color(0xFFF7F9FC);

class RoomPage extends StatefulWidget {
  const RoomPage({super.key});
  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  int filter = 0;
  String query = '';
  final rooms = <Map<String, String>>[
    {'name':'P.101','status':'Đang có người','price':'3.500.000đ/tháng','area':'25m²','people':'2 người'},
    {'name':'P.102','status':'Trống','price':'2.800.000đ/tháng','area':'20m²','people':'0 người'},
    {'name':'P.103','status':'Đang có người','price':'3.200.000đ/tháng','area':'22m²','people':'3 người'},
    {'name':'P.201','status':'Đang sửa','price':'2.500.000đ/tháng','area':'18m²','people':'0 người'},
  ];

  void notice(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  void openRoom(Map<String, String> room, {int tab = 0}) => Navigator.push(context, MaterialPageRoute(builder: (_) => RoomDetailPage(room: room, initialTab: tab)));

  @override
  Widget build(BuildContext context) {
    final shown = rooms.where((r) => (filter == 0 || r['status'] == (filter == 1 ? 'Đang có người' : 'Trống')) && r['name']!.toLowerCase().contains(query.toLowerCase())).toList();
    return Scaffold(
      backgroundColor: canvas,
      body: SafeArea(child: Column(children: [
        Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 20), children: [
          Row(children: [const Expanded(child: Text('Danh sách phòng', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ink))),
            FilledButton(onPressed: () => notice('Chức năng thêm phòng chưa kết nối dữ liệu'), style: FilledButton.styleFrom(backgroundColor: blue, minimumSize: const Size(70, 32), padding: const EdgeInsets.symmetric(horizontal: 12)), child: const Text('+ Thêm'))]),
          const SizedBox(height: 14),
          TextField(onChanged: (v) => setState(() => query = v), decoration: InputDecoration(hintText: '⌕  Tìm kiếm phòng...', hintStyle: const TextStyle(color: muted, fontSize: 14), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13))),
          const SizedBox(height: 12),
          Row(children: List.generate(3, (i) => Padding(padding: const EdgeInsets.only(right: 7), child: ChoiceChip(label: Text(['Tất cả','Đang có người','Trống'][i], style: TextStyle(fontSize: 12, color: filter == i ? Colors.white : muted)), selected: filter == i, selectedColor: blue, backgroundColor: Colors.white, showCheckmark: false, side: BorderSide.none, onSelected: (_) => setState(() => filter = i))))),
          const SizedBox(height: 10),
          if (shown.isEmpty) const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Không tìm thấy phòng'))),
          ...shown.map((room) => _roomCard(room)),
        ])),
        const AppBottomBar(selected: 0),
      ])),
    );
  }

  Widget _roomCard(Map<String, String> room) {
    final status = room['status']!;
    final color = status == 'Đang có người' ? const Color(0xFF07934B) : status == 'Trống' ? blue : const Color(0xFFDD510D);
    return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Row(children: [
      InkWell(onTap: () => openRoom(room), child: Container(width: 57, height: 70, decoration: BoxDecoration(color: const Color(0xFFEAF1FA), borderRadius: BorderRadius.circular(9)), child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [const Padding(padding: EdgeInsets.only(left: 6), child: Text('PHÒNG', style: TextStyle(fontSize: 9, color: muted))), Padding(padding: const EdgeInsets.only(left: 6), child: Text(room['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: ink)))]))),
      const SizedBox(width: 10),
      Expanded(child: InkWell(onTap: () => openRoom(room), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3), decoration: BoxDecoration(color: color.withValues(alpha: .08), borderRadius: BorderRadius.circular(12)), child: Text(status, style: TextStyle(fontSize: 10, color: color))), const SizedBox(height: 5), Text(room['price']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: ink)), Text('${room['area']}  •  ${room['people']}', style: const TextStyle(fontSize: 10, color: muted)), Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: () => notice('Chức năng sửa phòng chưa kết nối dữ liệu'), style: TextButton.styleFrom(visualDensity: VisualDensity.compact, backgroundColor: const Color(0xFFEAF0FF)), child: const Text('Sửa', style: TextStyle(fontSize: 11))), const SizedBox(width: 5), TextButton(onPressed: () => notice('Chức năng xóa phòng chưa kết nối dữ liệu'), style: TextButton.styleFrom(visualDensity: VisualDensity.compact, backgroundColor: const Color(0xFFFFEEEE)), child: const Text('Xóa', style: TextStyle(fontSize: 11, color: Colors.red)))] )]))),
      IconButton(onPressed: () => openRoom(room), icon: const Icon(Icons.chevron_right, size: 19, color: muted)),
    ]));
  }
}

class AppBottomBar extends StatelessWidget {
  final int selected;
  const AppBottomBar({super.key, required this.selected});
  @override
  Widget build(BuildContext context) {
    const labels = ['Phòng','Người thuê','Dịch vụ','Hóa đơn','Tài khoản'];
    const icons = [Icons.home_outlined, Icons.people_outline, Icons.circle_outlined, Icons.receipt_long_outlined, Icons.settings_outlined];
    return Container(
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE7EAF0)))),
      padding: const EdgeInsets.fromLTRB(3, 4, 3, 6),
      child: Row(
        children: List.generate(5, (i) => Expanded(
          child: InkWell(
            onTap: () {
              if (i == 0) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const RoomPage()), (route) => false);
              } else if (i < 4) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => RoomDetailPage(room: const {'name':'P.101','status':'Đang có người','price':'3.500.000đ/tháng','area':'25m²','people':'2 người'}, initialTab: i)));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trang tài khoản sẽ được hoàn thiện sau')));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(color: selected == i ? const Color(0xFFEAF0FF) : null, borderRadius: BorderRadius.circular(13)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icons[i], size: 18, color: selected == i ? blue : muted),
                const SizedBox(height: 3),
                Text(labels[i], maxLines: 1, style: TextStyle(fontSize: 10, color: selected == i ? blue : muted)),
              ]),
            ),
          ),
        )),
      ),
    );
  }
}
