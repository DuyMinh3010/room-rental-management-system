import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'room_page.dart';
import 'service_edit_page.dart';
import '../utils/formatters.dart';
import '../widgets/form_widgets.dart';

class ServicePage extends StatefulWidget {
  const ServicePage({super.key});

  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  int tab = 0;
  String query = '';
  String month = '09/2026';

  bool _loadingServices = true;

  // Danh sách dịch vụ đọc từ Firestore.
  // id là ID document, dùng để cập nhật đúng dịch vụ.
  List<Map<String, String>> _services = [];

  // Chỉ số đã lưu, khóa theo tháng và phòng.
  final Map<String, Map<String, String>> _meterCache = {};

  List<String> get roomNames => roomList.map((r) => r['name']!).toList();

  String _modeForForm(dynamic value) {
    switch (value) {
      case 'meter':
      case 'Theo chỉ số':
        return 'Theo chỉ số';
      case 'person':
      case 'Theo người':
        return 'Theo người';
      case 'room':
      case 'Theo phòng':
      default:
        return 'Theo phòng';
    }
  }

  String _modeForFirestore(String value) {
    switch (value) {
      case 'Theo chỉ số':
        return 'meter';
      case 'Theo người':
        return 'person';
      case 'Theo phòng':
        return 'room';
      default:
        throw ArgumentError.value(
          value,
          'mode',
          'Cách tính dịch vụ không hợp lệ',
        );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadServices();
    _loadMeterStatusForMonth(month);
  }

  // =========================
  // 1. DỊCH VỤ
  // =========================

  Future<void> _loadServices() async {
    try {
      final snapshot = await _db.collection('services').orderBy('name').get();

      final result = snapshot.docs.map((doc) {
        final data = doc.data();

        return <String, String>{
          'id': doc.id,
          'name': (data['name'] ?? '').toString(),
          'mode': _modeForForm(data['mode']),
          'price': (data['price'] ?? 0).toString(),
          'note': (data['note'] ?? '').toString(),
          'unit': (data['unit'] ?? 'tháng').toString(),
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _services = result;
        _loadingServices = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loadingServices = false);

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không tải được dịch vụ: $e')));
    }
  }

  Future<void> _editService([Map<String, String>? service]) async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => ServiceEditPage(service: service)),
    );

    if (result == null || !mounted) return;

    final name = result['name']?.trim() ?? '';
    final price = num.tryParse((result['price'] ?? '').replaceAll(',', '.'));

    if (name.isEmpty || price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên dịch vụ hoặc đơn giá không hợp lệ.')),
      );
      return;
    }

    // Không cho tạo hai dịch vụ cùng tên.
    final duplicate = _services.any(
      (s) =>
          s['name']?.toLowerCase() == name.toLowerCase() &&
          s['id'] != service?['id'],
    );

    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dịch vụ này đã có. Hãy chọn dịch vụ để sửa.'),
        ),
      );
      return;
    }

    try {
      final collection = _db.collection('services');
      final now = FieldValue.serverTimestamp();

      final data = <String, dynamic>{
        'name': name,
        'mode': _modeForFirestore(result['mode'] ?? 'Theo phòng'),
        'price': price,
        'note': result['note'] ?? '',
        'unit': result['unit'] ?? 'tháng',
        'isActive': true,
        'updatedAt': now,
      };

      if (service == null) {
        // Thêm dịch vụ mới.
        data['createdAt'] = now;
        await collection.add(data);
      } else {
        // Cập nhật document đã có.
        final id = service['id'];

        if (id == null || id.isEmpty) {
          throw Exception('Không tìm thấy ID dịch vụ cần sửa.');
        }

        await collection.doc(id).update(data);
      }

      await _loadServices();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            service == null
                ? 'Đã thêm dịch vụ vào Firebase.'
                : 'Đã cập nhật dịch vụ trên Firebase.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final message = e is FirebaseException && e.code == 'permission-denied'
          ? 'Firestore từ chối lưu dịch vụ. Kiểm tra tài khoản có quyền quản '
                'lý và dữ liệu dịch vụ khớp Firestore Rules: mode là meter, '
                'room hoặc person; price là số không âm.'
          : 'Lưu dịch vụ thất bại: $e';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // =========================
  // 2. CHỈ SỐ ĐIỆN, NƯỚC
  // =========================

  String _meterDocId(String targetMonth, String room) {
    // Tạo ID ổn định cho mỗi phòng trong mỗi tháng.
    final safeMonth = targetMonth.replaceAll('/', '-');
    final safeRoom = room.replaceAll('/', '_');

    return '${safeMonth}_$safeRoom';
  }

  String _previousMonth(String value) {
    final parts = value.split('/');
    var m = int.tryParse(parts[0]) ?? 1;
    var y = int.tryParse(parts[1]) ?? 2026;

    m--;

    if (m < 1) {
      m = 12;
      y--;
    }

    return '${m.toString().padLeft(2, '0')}/$y';
  }

  Map<String, String> _readingToForm(Map<String, dynamic> data) {
    return {
      'oldElectric': (data['oldElectric'] ?? 1250).toString(),
      'oldWater': (data['oldWater'] ?? 48).toString(),
      'newElectric': (data['newElectric'] ?? '').toString(),
      'newWater': (data['newWater'] ?? '').toString(),
      'electric': (data['electric'] ?? '0').toString(),
      'water': (data['water'] ?? '0').toString(),
      'parking': (data['parking'] ?? '0').toString(),
    };
  }

  Future<void> _loadMeterStatusForMonth(String targetMonth) async {
    try {
      final snapshot = await _db
          .collection('meters')
          .where('month', isEqualTo: targetMonth)
          .get();

      if (!mounted) return;

      setState(() {
        // Xóa cache cũ của tháng đang tải.
        _meterCache.removeWhere(
          (key, value) => key.startsWith('$targetMonth-'),
        );

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final room = data['room']?.toString();

          if (room == null || room.isEmpty) continue;

          _meterCache['$targetMonth-$room'] = _readingToForm(data);
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được chỉ số điện nước: $e')),
      );
    }
  }

  Future<void> _enter(String room) async {
    final key = '$month-$room';
    Map<String, String>? inputData;

    try {
      // Tải dữ liệu đã lưu của tháng hiện tại.
      final currentDoc = await _db
          .collection('meters')
          .doc(_meterDocId(month, room))
          .get();

      if (currentDoc.exists) {
        inputData = _readingToForm(currentDoc.data()!);
      } else {
        // Nếu chưa có dữ liệu tháng này, lấy chỉ số mới
        // của tháng trước làm chỉ số cũ nếu đã có.
        final previous = _previousMonth(month);

        final previousDoc = await _db
            .collection('meters')
            .doc(_meterDocId(previous, room))
            .get();

        final previousData = previousDoc.data();

        inputData = {
          'oldElectric': (previousData?['newElectric'] ?? 1250).toString(),
          'oldWater': (previousData?['newWater'] ?? 48).toString(),
          'newElectric': '',
          'newWater': '',
          'electric': '0',
          'water': '0',
          'parking': '0',
        };
      }

      if (!mounted) return;

      final result = await Navigator.push<Map<String, String>>(
        context,
        MaterialPageRoute(
          builder: (_) => MeterInputPage(
            room: room,
            month: month,
            data: inputData,
            services: _services,
          ),
        ),
      );

      if (result == null || !mounted) return;

      final oldElectric = double.tryParse(result['oldElectric'] ?? '');
      final oldWater = double.tryParse(result['oldWater'] ?? '');
      final newElectric = double.tryParse(result['newElectric'] ?? '');
      final newWater = double.tryParse(result['newWater'] ?? '');
      final electricUsed = double.tryParse(result['electric'] ?? '');
      final waterUsed = double.tryParse(result['water'] ?? '');
      final parking = int.tryParse(result['parking'] ?? '');

      if (oldElectric == null ||
          oldWater == null ||
          newElectric == null ||
          newWater == null ||
          electricUsed == null ||
          waterUsed == null ||
          parking == null) {
        throw Exception('Dữ liệu chỉ số không hợp lệ.');
      }

      final ref = _db.collection('meters').doc(_meterDocId(month, room));

      final existed = await ref.get();

      final data = <String, dynamic>{
        'room': room,
        'month': month,
        'previous': oldElectric,
        'current': newElectric,
        'oldElectric': oldElectric,
        'oldWater': oldWater,
        'newElectric': newElectric,
        'newWater': newWater,
        'electric': electricUsed,
        'water': waterUsed,
        'parking': parking,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!existed.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      await ref.set(data, SetOptions(merge: true));

      if (!mounted) return;

      setState(() {
        _meterCache[key] = result!;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã lưu chỉ số $room lên Firebase.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lưu chỉ số thất bại: $e')));
    }
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

                  // Hai tab giữ nguyên giao diện cũ.
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
                            if (value == null) return;

                            setState(() => month = value);
                            _loadMeterStatusForMonth(value);
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
                          final saved = _meterCache.containsKey('$month-$name');

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

                    if (_loadingServices)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_services.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Chưa có dịch vụ. Nhấn "+ Thêm dịch vụ" để bắt đầu.',
                          style: TextStyle(color: muted),
                        ),
                      )
                    else
                      for (final s in _services.where(
                        (s) => (s['name'] ?? '').toLowerCase().contains(
                          query.toLowerCase(),
                        ),
                      ))
                        InkWell(
                          onTap: () => _editService(s),
                          child: serviceRow(
                            s['name'] ?? '',
                            '${money(s['price'] ?? '0')}/${s['unit'] ?? 'tháng'}',
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

// =====================================================
// TRANG NHẬP CHỈ SỐ
// =====================================================

class MeterInputPage extends StatefulWidget {
  final String room;
  final String month;
  final Map<String, String>? data;
  final List<Map<String, String>> services;

  const MeterInputPage({
    super.key,
    required this.room,
    required this.month,
    this.data,
    this.services = const [],
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

  int _servicePrice(String name, int fallback) {
    for (final service in widget.services) {
      if (service['name'] == name) {
        return (num.tryParse(service['price'] ?? '') ?? fallback).round();
      }
    }

    return fallback;
  }

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
    final safeUsed = used < 0 ? 0.0 : used;

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
        InfoLine('Số tiêu thụ', '$safeUsed $unit'),
        InfoLine('Thành tiền', money('${(safeUsed * price).round()}')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final electricPrice = _servicePrice('Điện', 3500);
    final waterPrice = _servicePrice('Nước', 20000);
    final wifiPrice = _servicePrice('WiFi', 100000);
    final trashPrice = _servicePrice('Đổ rác', 20000);
    final parkingPrice = _servicePrice('Gửi xe', 100000);

    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(title: const Text('Nhập chỉ số')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            InfoLine('Phòng', widget.room),
            InfoLine('Tháng', widget.month),

            _meter('Điện', electric, oldElectric, 'kWh', electricPrice),

            _meter('Nước', water, oldWater, 'm³', waterPrice),

            InfoCard(
              title: 'WiFi',
              children: [
                InfoLine('Theo phòng', '${money('$wifiPrice')}/tháng'),
              ],
            ),

            InfoCard(
              title: 'Đổ rác',
              children: [
                InfoLine('Theo phòng', '${money('$trashPrice')}/tháng'),
              ],
            ),

            InfoCard(
              title: 'Gửi xe',
              children: [
                FormInput('Số người gửi xe', parking, number: true),
                InfoLine(
                  'Thành tiền',
                  money('${(int.tryParse(parking.text) ?? 0) * parkingPrice}'),
                ),
              ],
            ),

            FilledButton(onPressed: _save, child: const Text('Lưu chỉ số')),
          ],
        ),
      ),
    );
  }
}
