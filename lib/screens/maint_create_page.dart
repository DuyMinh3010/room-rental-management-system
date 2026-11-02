import 'package:flutter/material.dart';

import '../models/record.dart';
import '../widgets/common.dart';

class MaintCreatePage extends StatefulWidget {
  final Record? maintenance;
  const MaintCreatePage({super.key, this.maintenance});

  @override
  State<MaintCreatePage> createState() => _MaintCreatePageState();
}

class _MaintCreatePageState extends State<MaintCreatePage> {
  final _formKey = GlobalKey<FormState>();
  late final String _recordId;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _costCtrl;
  String? _roomId;
  String _issueType = 'Thiết bị';
  String _priority = 'Trung bình';
  late String _status;
  bool _saving = false;

  static const _issueTypes = ['Thiết bị', 'Điện / Nước', 'Nội thất', 'Khác'];

  @override
  void initState() {
    super.initState();
    final m = widget.maintenance;
    _recordId = m?.id ?? store.db.collection('_').doc().id;
    _roomId = m?.text('roomId');
    _titleCtrl = TextEditingController(text: m?.text('title') ?? '');
    _descCtrl = TextEditingController(text: m?.text('description') ?? '');
    _costCtrl = TextEditingController(
      text: (m?.data['cost'] ?? 0).toString(),
    );
    final initStatus = m?.text('status') ?? 'new';
    _status = const ['new', 'working', 'done', 'cancelled'].contains(initStatus)
        ? initStatus
        : 'new';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (_roomId == null || _roomId!.isEmpty) {
      message(context, 'Vui lòng chọn phòng');
      return;
    }
    final rawCost = _costCtrl.text.trim().replaceAll('.', '').replaceAll(',', '.');
    final cost = rawCost.isEmpty ? 0 : num.tryParse(rawCost);
    if (cost == null || cost < 0) {
      message(context, 'Chi phí bảo trì không hợp lệ');
      return;
    }
    final data = <String, dynamic>{
      'roomId': _roomId,
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'status': _status,
      'cost': cost,
    };
    setState(() => _saving = true);
    try {
      await store.command('saveMaintenance', id: _recordId, data: data);
      if (mounted) {
        Navigator.pop(context);
        message(context, 'Đã lưu yêu cầu bảo trì lên Firebase');
      }
    } catch (e) {
      if (mounted) message(context, errorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _fieldLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF6B717E),
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF939AA8), fontSize: 12.5),
    filled: true,
    fillColor: Colors.white,
    isDense: true,
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
      borderSide: const BorderSide(color: blue, width: 1.2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
    ),
  );

  Widget _priorityChip({
    required String label,
    required Color bg,
    required Color fg,
  }) {
    final selected = _priority == label;
    return GestureDetector(
      onTap: () => setState(() => _priority = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: selected ? Border.all(color: fg, width: 1.3) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.maintenance != null;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: canvas,
        appBar: AppBar(
          backgroundColor: canvas,
          leading: IconButton(
            icon: const Icon(
              Icons.chevron_left_rounded,
              size: 30,
              color: Color(0xFF6B717E),
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          titleSpacing: 0,
          title: Text(
            isEdit ? 'Cập nhật bảo trì' : 'Tạo yêu cầu bảo trì',
            style: const TextStyle(
              color: ink,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: RecordsView(
          collection: 'rooms',
          builder: (_, rooms) => RecordsView(
            collection: 'tenants',
            builder: (_, tenants) {
              final activeRooms = rooms.where((r) => !r.archived).toList()
                ..sort((a, b) => a.name.compareTo(b.name));
              final validRoomId = activeRooms.any((r) => r.id == _roomId)
                  ? _roomId
                  : null;

              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  children: [
                    const Text(
                      'Gửi yêu cầu sửa chữa đến chủ trọ',
                      style: TextStyle(color: ink, fontSize: 12),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Thông tin yêu cầu',
                      style: TextStyle(
                        color: ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _fieldLabel('Phòng'),
                    DropdownButtonFormField<String>(
                      initialValue: validRoomId,
                      dropdownColor: Colors.white,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF6B717E),
                      ),
                      style: const TextStyle(color: ink, fontSize: 13),
                      decoration: _inputDecoration(hint: 'Chọn phòng...'),
                      items: activeRooms.map((r) {
                        final t = tenants
                            .where(
                              (x) => !x.archived && x.text('roomId') == r.id,
                            )
                            .firstOrNull;
                        return DropdownMenuItem(
                          value: r.id,
                          child: Text(
                            t != null ? '${r.name} · ${t.name}' : r.name,
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _roomId = v),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Vui lòng chọn phòng' : null,
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel('Loại sự cố'),
                    DropdownButtonFormField<String>(
                      initialValue: _issueType,
                      dropdownColor: Colors.white,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF6B717E),
                      ),
                      style: const TextStyle(color: ink, fontSize: 13),
                      decoration: _inputDecoration(),
                      items: [
                        for (final item in _issueTypes)
                          DropdownMenuItem(value: item, child: Text(item)),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _issueType = v);
                      },
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel('Tiêu đề'),
                    TextFormField(
                      controller: _titleCtrl,
                      style: const TextStyle(color: ink, fontSize: 13),
                      decoration: _inputDecoration(hint: 'Máy lạnh không mát'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Vui lòng nhập tiêu đề sự cố'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel('Mô tả chi tiết'),
                    Stack(
                      children: [
                        TextFormField(
                          controller: _descCtrl,
                          maxLines: 3,
                          maxLength: 200,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(color: ink, fontSize: 13),
                          decoration: _inputDecoration(
                            hint: 'Máy lạnh bật nhưng không làm mát...',
                          ).copyWith(counterText: ''),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Vui lòng nhập mô tả chi tiết'
                              : null,
                        ),
                        Positioned(
                          right: 12,
                          bottom: 8,
                          child: Text(
                            '${_descCtrl.text.length}/200',
                            style: const TextStyle(
                              color: Color(0xFF939AA8),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel('Mức độ ưu tiên'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _priorityChip(
                          label: 'Thấp',
                          bg: const Color(0xFFF5F6F8),
                          fg: const Color(0xFF6B717E),
                        ),
                        _priorityChip(
                          label: 'Trung bình',
                          bg: const Color(0xFFFFF4E5),
                          fg: const Color(0xFFD97706),
                        ),
                        _priorityChip(
                          label: 'Khẩn cấp',
                          bg: const Color(0xFFFDECEC),
                          fg: const Color(0xFFDC2626),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Trạng thái'),
                              DropdownButtonFormField<String>(
                                initialValue: _status,
                                dropdownColor: Colors.white,
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Color(0xFF6B717E),
                                ),
                                style: const TextStyle(
                                  color: ink,
                                  fontSize: 12.5,
                                ),
                                decoration: _inputDecoration(),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'new',
                                    child: Text('Mới tiếp nhận'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'working',
                                    child: Text('Đang xử lý'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'done',
                                    child: Text('Hoàn thành'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'cancelled',
                                    child: Text('Đã hủy'),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null) setState(() => _status = v);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Chi phí (đ)'),
                              TextFormField(
                                controller: _costCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  color: ink,
                                  fontSize: 13,
                                ),
                                decoration: _inputDecoration(hint: '0'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel('Ảnh hiện trạng'),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => message(
                        context,
                        'Tải ảnh hiện chưa hỗ trợ trên gói Firebase Spark',
                      ),
                      child: Container(
                        height: 58,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              '+',
                              style: TextStyle(
                                color: blue,
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 16),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Thêm ảnh (tối đa 3 ảnh)',
                                  style: TextStyle(color: ink, fontSize: 12.5),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'JPG, PNG · không bắt buộc',
                                  style: TextStyle(
                                    color: Color(0xFF939AA8),
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(isEdit ? 'Lưu cập nhật' : 'Gửi yêu cầu'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Yêu cầu sẽ được gửi đến chủ trọ để xác nhận.',
                      style: TextStyle(color: ink, fontSize: 10.5),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
