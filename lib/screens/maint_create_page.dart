import 'package:flutter/material.dart';

import '../services/maintenance_service.dart';
import 'room_page.dart';

class MaintCreatePage extends StatefulWidget {
  const MaintCreatePage({super.key});

  @override
  State<MaintCreatePage> createState() => _MaintCreatePageState();
}

class _MaintCreatePageState extends State<MaintCreatePage> {
  final _maintenanceService = MaintenanceService();
  final _title = TextEditingController();
  final _desc = TextEditingController();

  static const _categories = ['Thiết bị', 'Điện', 'Nước', 'Khác'];

  String? _room;
  String _category = 'Thiết bị';
  String _priority = 'medium';
  bool _sent = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _msg(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _tenantOf(Map<String, String> r) {
    final t = (r['tenant'] ?? r['tenantName'] ?? '').trim();
    return t;
  }

  Future<void> _send() async {
    if (_sent) return;

    final room = _room;
    if (room == null) {
      _msg('Vui lòng chọn phòng');
      return;
    }
    if (_title.text.trim().isEmpty) {
      _msg('Vui lòng nhập tiêu đề');
      return;
    }
    if (!roomList.any((r) => r['name'] == room)) {
      _msg('Phòng không còn tồn tại. Vui lòng mở lại màn hình');
      return;
    }

    final roomData = roomList.firstWhere((r) => r['name'] == room);
    final tenant = _tenantOf(roomData);

    setState(() => _sent = true);

    try {
      await _maintenanceService.addMaintenanceRequest(
        title: _title.text.trim(),
        description: _desc.text.trim(),
        room: room,
        tenantName: tenant.isEmpty ? 'Chưa xác định' : tenant,
        category: _category,
        priority: _priority,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sent = false);
      _msg('Gửi thất bại: $e');
    }
  }

  InputDecoration _fieldDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: muted, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 11, color: muted)),
    );
  }

  Widget _priorityChip(String label, String value, Color color) {
    final selected = _priority == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _priority = value),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.chevron_left, color: ink),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Tạo yêu cầu bảo trì',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Gửi yêu cầu sửa chữa đến chủ trọ',
                    style: TextStyle(fontSize: 11, color: muted),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Thông tin yêu cầu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ink,
                    ),
                  ),

                  _label('Phòng'),
                  DropdownButtonFormField<String>(
                    initialValue: _room,
                    isExpanded: true,
                    decoration: _fieldDecoration(hint: 'Chọn phòng'),
                    items: roomList.map((r) {
                      final name = r['name'] ?? '';
                      final tenant = _tenantOf(r);
                      return DropdownMenuItem<String>(
                        value: name,
                        child: Text(
                          tenant.isEmpty ? name : '$name · $tenant',
                          style: const TextStyle(fontSize: 13, color: ink),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _room = v),
                  ),

                  _label('Loại sự cố'),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    isExpanded: true,
                    decoration: _fieldDecoration(),
                    items: _categories
                        .map((c) => DropdownMenuItem<String>(
                              value: c,
                              child: Text(
                                c,
                                style: const TextStyle(
                                    fontSize: 13, color: ink),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _category = v ?? _category),
                  ),

                  _label('Tiêu đề'),
                  TextField(
                    controller: _title,
                    style: const TextStyle(fontSize: 13),
                    decoration: _fieldDecoration(hint: 'Ví dụ: Máy lạnh không mát'),
                  ),

                  _label('Mô tả chi tiết'),
                  TextField(
                    controller: _desc,
                    maxLines: 4,
                    maxLength: 200,
                    style: const TextStyle(fontSize: 13),
                    decoration: _fieldDecoration(
                      hint: 'Mô tả sự cố bạn đang gặp...',
                    ),
                  ),

                  _label('Mức độ ưu tiên'),
                  Row(
                    children: [
                      _priorityChip('Thấp', 'low', muted),
                      _priorityChip(
                          'Trung bình', 'medium', const Color(0xFFF26B13)),
                      _priorityChip(
                          'Khẩn cấp', 'urgent', const Color(0xFFE5484D)),
                    ],
                  ),

                  _label('Ảnh hiện trạng'),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add, color: blue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Thêm ảnh (tối đa 3 ảnh)',
                                style: TextStyle(fontSize: 13, color: ink),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'JPG, PNG - không bắt buộc',
                                style: TextStyle(fontSize: 10, color: muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _sent ? null : _send,
                      style: FilledButton.styleFrom(
                        backgroundColor: blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: _sent
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Gửi yêu cầu'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Yêu cầu sẽ được gửi đến chủ trọ để xác nhận.',
                    style: TextStyle(fontSize: 10, color: muted),
                  ),
                ],
              ),
            ),
            const AppBottomBar(selected: 5),
          ],
        ),
      ),
    );
  }
}