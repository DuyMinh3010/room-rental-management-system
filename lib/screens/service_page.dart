import 'package:flutter/material.dart';

import 'room_page.dart';
import 'service_edit_page.dart';
import '../data/mock_data.dart';
import '../widgets/form_widgets.dart';

final meterData = <String, Map<String, String>>{
  '09/2026-P.101': {
    'electric': '120',
    'water': '15',
    'oldElectric': '1250',
    'oldWater': '48',
    'newElectric': '1370',
    'newWater': '63',
  },
  '09/2026-P.102': {
    'electric': '95',
    'water': '12',
    'oldElectric': '1250',
    'oldWater': '48',
    'newElectric': '1345',
    'newWater': '60',
  },
};

class ServicePage extends StatefulWidget {
  const ServicePage({super.key});

  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  int tab = 0;
  String query = '';
  String month = '09/2026';
  List<String> get roomNames => roomList.map((r) => r['name']!).toList();

  Future<void> _enter(String room) async {
    final key = '$month-$room';
    final old = meterData[key];
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => MeterInputPage(room: room, month: month, data: old),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => meterData[key] = result);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Đã lưu chỉ số $room')));
  }

  Future<void> _editService([Map<String, String>? service]) async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => ServiceEditPage(service: service)),
    );
    if (result == null || !mounted) return;
    if (serviceList.any((s) => s != service && s['name'] == result['name'])) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dịch vụ này đã có. Hãy chọn dịch vụ để sửa.'),
        ),
      );
      return;
    }
    setState(() {
      if (service == null) {
        serviceList.add(result);
      } else {
        service.addAll(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: canvas,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.chevron_left, color: ink),
                      ),
                      const Text(
                        'Dịch vụ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: List.generate(
                        2,
                        (i) => Expanded(
                          child: InkWell(
                            onTap: () => setState(() => tab = i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: tab == i
                                    ? const Color(0xFFEAF0FF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  ['Dịch vụ', 'Nhập chỉ số'][i],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: tab == i ? blue : muted,
                                    fontWeight: tab == i
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (tab == 1) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: month,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            size: 20,
                            color: muted,
                          ),
                          style: const TextStyle(
                            color: ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          items: ['08/2026', '09/2026', '10/2026']
                              .map(
                                (m) =>
                                    DropdownMenuItem(value: m, child: Text(m)),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => month = value);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Danh sách phòng',
                      style: TextStyle(fontSize: 10, color: muted),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: List.generate(roomNames.length, (i) {
                          final name = roomNames[i];
                          final saved = meterData.containsKey('$month-$name');
                          return Column(
                            children: [
                              if (i > 0)
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFE7EAF0),
                                ),
                              InkWell(
                                onTap: () => _enter(name),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: ink,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              saved ? 'Đã nhập' : 'Chưa nhập',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: muted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: muted,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      onChanged: (v) => setState(() => query = v),
                      decoration: const InputDecoration(
                        hintText: 'Tìm kiếm dịch vụ...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final s in serviceList.where(
                      (s) => s['name']!.toLowerCase().contains(
                        query.toLowerCase(),
                      ),
                    ))
                      InkWell(
                        onTap: () => _editService(s),
                        child: serviceRow(
                          s['name']!,
                          '${money(s['price'])}/${s['unit']}',
                          blue,
                        ),
                      ),
                    OutlinedButton(
                      onPressed: () => _editService(),
                      child: const Text('+ Thêm dịch vụ'),
                    ),
                  ],
                ],
              ),
            ),
            const AppBottomBar(selected: 2),
          ],
        ),
      ),
    );
  }

  Widget serviceRow(String name, String price, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 14, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(name)),
          Text(price, style: const TextStyle(fontSize: 12, color: muted)),
        ],
      ),
    );
  }
}

class MeterInputPage extends StatefulWidget {
  final String room;
  final String month;
  final Map<String, String>? data;
  const MeterInputPage({
    super.key,
    required this.room,
    required this.month,
    this.data,
  });
  @override
  State<MeterInputPage> createState() => _MeterInputPageState();
}

class _MeterInputPageState extends State<MeterInputPage> {
  final formKey = GlobalKey<FormState>();
  final electric = TextEditingController();
  final water = TextEditingController();
  final parking = TextEditingController(text: '0');
  late double oldElectric;
  late double oldWater;
  double get electricUsed =>
      (double.tryParse(electric.text.replaceAll(',', '.')) ?? oldElectric) -
      oldElectric;
  double get waterUsed =>
      (double.tryParse(water.text.replaceAll(',', '.')) ?? oldWater) - oldWater;
  @override
  void initState() {
    super.initState();
    oldElectric = double.tryParse(widget.data?['oldElectric'] ?? '') ?? 1250;
    oldWater = double.tryParse(widget.data?['oldWater'] ?? '') ?? 48;
    electric.text = widget.data?['newElectric'] ?? '';
    water.text = widget.data?['newWater'] ?? '';
    parking.text = widget.data?['parking'] ?? '0';
    for (final c in [electric, water, parking]) {
      c.addListener(_refresh);
    }
  }

  void _refresh() => setState(() {});
  @override
  void dispose() {
    electric.dispose();
    water.dispose();
    parking.dispose();
    super.dispose();
  }

  void _save() {
    if (!formKey.currentState!.validate()) return;
    Navigator.pop(context, <String, String>{
      'oldElectric': '$oldElectric',
      'oldWater': '$oldWater',
      'newElectric': electric.text.replaceAll(',', '.'),
      'newWater': water.text.replaceAll(',', '.'),
      'electric': '$electricUsed',
      'water': '$waterUsed',
      'parking': parking.text,
    });
  }

  Widget _meter(
    String label,
    TextEditingController controller,
    double old,
    String unit,
    int price,
  ) {
    final used = controller == electric ? electricUsed : waterUsed;
    return InfoCard(
      title: label,
      children: [
        InfoLine('Đơn giá', '${money('$price')}/$unit'),
        InfoLine('Chỉ số cũ', '$old $unit'),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Chỉ số mới',
            suffixText: unit,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            final n = double.tryParse((value ?? '').replaceAll(',', '.'));
            return n == null || !n.isFinite || n < old
                ? 'Chỉ số mới phải lớn hơn hoặc bằng $old'
                : null;
          },
        ),
        const SizedBox(height: 12),
        InfoLine('Số tiêu thụ', '${used < 0 ? 0 : used} $unit'),
        InfoLine(
          'Thành tiền',
          money('${((used < 0 ? 0 : used) * price).round()}'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    appBar: AppBar(title: const Text('Nhập chỉ số')),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          InfoLine('Phòng', widget.room),
          InfoLine('Tháng', widget.month),
          _meter('Điện', electric, oldElectric, 'kWh', 3500),
          _meter('Nước', water, oldWater, 'm³', 20000),
          const InfoCard(
            title: 'WiFi',
            children: [InfoLine('Theo phòng', '100.000đ/tháng')],
          ),
          const InfoCard(
            title: 'Đổ rác',
            children: [InfoLine('Theo phòng', '20.000đ/tháng')],
          ),
          InfoCard(
            title: 'Gửi xe',
            children: [
              FormInput('Số người gửi xe', parking, number: true),
              InfoLine(
                'Thành tiền',
                money('${(int.tryParse(parking.text) ?? 0) * 100000}'),
              ),
            ],
          ),
          FilledButton(onPressed: _save, child: const Text('Lưu chỉ số')),
        ],
      ),
    ),
  );
}
