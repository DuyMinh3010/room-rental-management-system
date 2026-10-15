import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'room_page.dart';

class MaintCreatePage extends StatefulWidget {
  const MaintCreatePage({super.key});

  @override
  State<MaintCreatePage> createState() => _MaintCreatePageState();
}

class _MaintCreatePageState extends State<MaintCreatePage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _photos = <Uint8List>[];
  late final List<String> _rooms;
  String? _room;
  String _type = 'Thiết bị';
  MaintPriority _priority = MaintPriority.medium;
  bool _picking = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _rooms = roomList
        .map((r) => r['name'])
        .whereType<String>()
        .where((n) => n.trim().isNotEmpty)
        .toSet()
        .toList();
    if (_rooms.isNotEmpty) {
      _room = _rooms.contains('P.102') ? 'P.102' : _rooms.first;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _msg(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  void _pick() {
    _msg('Đây là giao diện chọn ảnh. Chức năng chọn ảnh sẽ bổ sung sau.');
  }

  void _send() {
    if (_sent || _picking || !(_form.currentState?.validate() ?? false)) return;
    final room = _room;
    if (room == null || !roomList.any((r) => r['name'] == room)) {
      _msg('Phòng không còn tồn tại. Vui lòng mở lại màn hình');
      return;
    }
    setState(() => _sent = true);
    maintStore.add(
      room: room,
      type: _type,
      title: _title.text,
      desc: _desc.text,
      priority: _priority,
      photos: _photos,
    );
    Navigator.pop(context, true);
  }

  InputDecoration _deco({String? hint}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 12, color: muted),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: blue),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red),
    ),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(text, style: const TextStyle(fontSize: 10, color: muted)),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F8FA),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 30,
                        height: 34,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.chevron_left,
                            color: ink,
                            size: 28,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Tạo yêu cầu bảo trì',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Gửi yêu cầu sửa chữa đến chủ trọ',
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                  const SizedBox(height: 23),
                  const Text(
                    'Thông tin yêu cầu',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _label('Phòng'),
                  DropdownButtonFormField<String>(
                    value: _room,
                    isExpanded: true,
                    decoration: _deco(hint: 'Chọn phòng'),
                    style: const TextStyle(fontSize: 13, color: ink),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: muted,
                    ),
                    items: _rooms
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setState(() => _room = v),
                    validator: (v) => v == null ? 'Vui lòng chọn phòng' : null,
                  ),
                  const SizedBox(height: 12),
                  _label('Loại sự cố'),
                  DropdownButtonFormField<String>(
                    value: _type,
                    isExpanded: true,
                    decoration: _deco(),
                    style: const TextStyle(fontSize: 13, color: ink),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: muted,
                    ),
                    items: const ['Thiết bị', 'Điện', 'Nước', 'Khác']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _type = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  _label('Tiêu đề'),
                  TextFormField(
                    controller: _title,
                    style: const TextStyle(fontSize: 13, color: ink),
                    decoration: _deco(hint: 'Máy lạnh không mát'),
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      final text = (v ?? '').trim();
                      if (text.isEmpty) return 'Vui lòng nhập tiêu đề';
                      if (text.length > 100) return 'Tiêu đề tối đa 100 ký tự';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _label('Mô tả chi tiết'),
                  TextFormField(
                    controller: _desc,
                    style: const TextStyle(fontSize: 12, color: ink),
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 200,
                    decoration: _deco(
                      hint: 'Máy lạnh phòng P.102 bật nhưng không làm mát...',
                    ),
                    buildCounter:
                        (
                          _, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => Text(
                          '$currentLength/200',
                          style: const TextStyle(fontSize: 9, color: muted),
                        ),
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? 'Vui lòng nhập mô tả sự cố'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _label('Mức độ ưu tiên'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: MaintPriority.values.map(_chip).toList(),
                  ),
                  const SizedBox(height: 16),
                  _label('Ảnh hiện trạng'),
                  InkWell(
                    onTap: _picking ? null : _pick,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(
                            _picking ? Icons.hourglass_empty : Icons.add,
                            color: muted,
                            size: 22,
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Thêm ảnh (tối đa 3 ảnh)',
                                  style: TextStyle(fontSize: 12, color: ink),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'JPG, PNG · không bắt buộc',
                                  style: TextStyle(fontSize: 9, color: muted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_photos.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(
                        _photos.length,
                        (i) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _photos[i],
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                                errorBuilder: (_, error, stack) =>
                                    const SizedBox(
                                      width: 88,
                                      height: 88,
                                      child: Icon(Icons.broken_image_outlined),
                                    ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                onPressed: _picking
                                    ? null
                                    : () => setState(() => _photos.removeAt(i)),
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _sent || _picking ? null : _send,
                      style: FilledButton.styleFrom(
                        backgroundColor: blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Gửi yêu cầu',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Yêu cầu sẽ được gửi đến chủ trọ để xác nhận.',
                    style: TextStyle(fontSize: 9, color: muted),
                  ),
                ],
              ),
            ),
          ),
          AppBottomBar(
            selected: 5,
            onSelected: (i) {
              if (i != 5) return false;
              Navigator.pop(context);
              return true;
            },
          ),
        ],
      ),
    ),
  );

  Widget _chip(MaintPriority priority) {
    final selected = priority == _priority;
    final color = switch (priority) {
      MaintPriority.low => blue,
      MaintPriority.medium => const Color(0xFFF26B13),
      MaintPriority.urgent => const Color(0xFFE74747),
    };
    return InkWell(
      onTap: () => setState(() => _priority = priority),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: .10) : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          priority.label,
          style: TextStyle(fontSize: 10, color: selected ? color : muted),
        ),
      ),
    );
  }
}

enum MaintStatus {
  fresh('Mới'),
  active('Đang xử lý'),
  done('Hoàn thành');

  final String label;
  const MaintStatus(this.label);
}

enum MaintPriority {
  low('Thấp'),
  medium('Trung bình'),
  urgent('Khẩn cấp');

  final String label;
  const MaintPriority(this.label);
}

class MaintReq {
  final int id;
  final String room;
  final String reporter;
  final String type;
  final String title;
  final String desc;
  final MaintPriority priority;
  final MaintStatus status;
  final DateTime updated;
  final List<Uint8List> photos;

  MaintReq({
    required this.id,
    required this.room,
    this.reporter = '',
    required this.type,
    required this.title,
    required this.desc,
    this.priority = MaintPriority.medium,
    this.status = MaintStatus.fresh,
    required this.updated,
    List<Uint8List> photos = const [],
  }) : photos = List.unmodifiable(
         photos.map((p) => Uint8List.fromList(p).asUnmodifiableView()),
       );

  String get location => reporter.isEmpty ? room : '$room · $reporter';

  MaintReq withStatus(MaintStatus value) => MaintReq(
    id: id,
    room: room,
    reporter: reporter,
    type: type,
    title: title,
    desc: desc,
    priority: priority,
    status: value,
    updated: DateTime.now(),
    photos: photos,
  );
}

class MaintStore extends ValueNotifier<List<MaintReq>> {
  MaintStore() : super(List.unmodifiable(_seed()));
  int _nextId = 4;

  void add({
    required String room,
    required String type,
    required String title,
    required String desc,
    required MaintPriority priority,
    required List<Uint8List> photos,
  }) {
    final req = MaintReq(
      id: _nextId++,
      room: room,
      type: type,
      title: title.trim(),
      desc: desc.trim(),
      priority: priority,
      photos: photos,
      updated: DateTime.now(),
    );
    value = List.unmodifiable([req, ...value]);
  }

  void setStatus(int id, MaintStatus status) {
    final idx = value.indexWhere((r) => r.id == id);
    if (idx < 0 || value[idx].status == status) return;
    final rows = [...value];
    rows[idx] = rows[idx].withStatus(status);
    value = List.unmodifiable(rows);
  }

  static List<MaintReq> _seed() {
    final now = DateTime.now();
    return [
      MaintReq(
        id: 1,
        room: 'P.102',
        reporter: 'Nguyễn Minh Huy',
        type: 'Thiết bị',
        title: 'Máy lạnh không mát',
        desc: 'Máy lạnh bật nhưng không làm mát.',
        updated: now.subtract(const Duration(minutes: 10)),
      ),
      MaintReq(
        id: 2,
        room: 'P.201',
        reporter: 'Lê Thị Mai',
        type: 'Nước',
        title: 'Rò rỉ vòi nước',
        desc: 'Vòi nước bị rò rỉ khi đã khóa.',
        status: MaintStatus.active,
        updated: now.subtract(const Duration(days: 1)),
      ),
      MaintReq(
        id: 3,
        room: 'Khu A · Tầng 2',
        type: 'Điện',
        title: 'Đèn hành lang hỏng',
        desc: 'Đèn hành lang không sáng.',
        status: MaintStatus.done,
        updated: now.subtract(const Duration(days: 2)),
      ),
    ];
  }
}

final maintStore = MaintStore();

String maintTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'vừa xong';
  if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
  if (diff.inDays < 1) return '${diff.inHours} giờ trước';
  if (diff.inDays == 1) return 'hôm qua';
  return '${diff.inDays} ngày trước';
}
