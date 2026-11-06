import 'package:flutter/material.dart';

import '../models/record.dart';
import '../widgets/common.dart';

class ServiceEditPage extends StatefulWidget {
  final Record? service;
  const ServiceEditPage({super.key, this.service});

  @override
  State<ServiceEditPage> createState() => _ServiceEditPageState();
}

class _ServiceEditPageState extends State<ServiceEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final String _recordId;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _noteCtrl;
  late String _mode;
  bool _saving = false;

  static const _presets = <({String name, String mode, String unit})>[
    (name: 'Điện', mode: 'meter', unit: 'kWh'),
    (name: 'Nước', mode: 'meter', unit: 'm³'),
    (name: 'WiFi', mode: 'room', unit: 'tháng'),
    (name: 'Đổ rác', mode: 'room', unit: 'tháng'),
    (name: 'Gửi xe', mode: 'person', unit: 'người'),
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.service?.data ?? const <String, dynamic>{};
    _recordId = widget.service?.id ?? store.db.collection('_').doc().id;
    _nameCtrl = TextEditingController(text: d['name']?.toString() ?? '');
    _priceCtrl = TextEditingController(text: d['price']?.toString() ?? '');
    _unitCtrl = TextEditingController(
      text: d['unit']?.toString() ?? (widget.service == null ? 'kWh' : ''),
    );
    _noteCtrl = TextEditingController(text: d['note']?.toString() ?? '');
    final initialMode = d['mode']?.toString() ?? 'meter';
    _mode = const ['meter', 'room', 'person'].contains(initialMode)
        ? initialMode
        : 'meter';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _unitCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _applyPreset(({String name, String mode, String unit}) p) {
    setState(() {
      _nameCtrl.text = p.name;
      _mode = p.mode;
      _unitCtrl.text = p.unit;
    });
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final priceText = _priceCtrl.text.trim().replaceAll('.', '').replaceAll(',', '.');
    final parsedPrice = num.tryParse(priceText);
    if (parsedPrice == null || parsedPrice < 0) {
      message(context, 'Đơn giá phải là số hợp lệ');
      return;
    }
    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'mode': _mode,
      'price': parsedPrice,
      'unit': _unitCtrl.text.trim(),
      'note': _noteCtrl.text.trim(),
    };
    setState(() => _saving = true);
    try {
      await store.command('saveService', id: _recordId, data: data);
      if (mounted) {
        Navigator.pop(context);
        message(context, 'Đã lưu lên Firebase');
      }
    } catch (e) {
      if (mounted) message(context, errorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _fieldDecoration({String? hint, Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: muted, fontSize: 12.5),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: blue, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
        ),
      );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      text,
      style: const TextStyle(
        color: muted,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isNew = widget.service == null;
    final unitPreview = _unitCtrl.text.trim().isEmpty
        ? 'đơn vị'
        : _unitCtrl.text.trim();
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: canvas,
        appBar: AppBar(
          backgroundColor: canvas,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 30, color: ink),
            onPressed: () => Navigator.maybePop(context),
          ),
          titleSpacing: 0,
          title: Text(
            isNew ? 'Thêm dịch vụ' : 'Sửa dịch vụ',
            style: const TextStyle(
              color: ink,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              _label('Loại dịch vụ'),
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: ink, fontSize: 13),
                decoration: _fieldDecoration(
                  hint: 'Điện, Nước, WiFi, Đổ rác, Gửi xe...',
                  suffix: PopupMenuButton<({String name, String mode, String unit})>(
                    tooltip: 'Chọn nhanh loại dịch vụ',
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: muted,
                      size: 20,
                    ),
                    color: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    onSelected: _applyPreset,
                    itemBuilder: (_) => [
                      for (final p in _presets)
                        PopupMenuItem(value: p, child: Text(p.name)),
                    ],
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên dịch vụ' : null,
              ),
              const SizedBox(height: 16),
              _label('Cách tính'),
              DropdownButtonFormField<String>(
                initialValue: _mode,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: muted,
                  size: 20,
                ),
                dropdownColor: Colors.white,
                style: const TextStyle(color: ink, fontSize: 13),
                decoration: _fieldDecoration(),
                items: const [
                  DropdownMenuItem(value: 'meter', child: Text('Theo chỉ số')),
                  DropdownMenuItem(value: 'room', child: Text('Theo phòng')),
                  DropdownMenuItem(value: 'person', child: Text('Theo người')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _mode = v;
                    if (_unitCtrl.text.trim().isEmpty) {
                      _unitCtrl.text = v == 'meter'
                          ? 'kWh'
                          : v == 'room'
                          ? 'tháng'
                          : 'người';
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Đơn giá'),
                        TextFormField(
                          controller: _priceCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: ink, fontSize: 13),
                          decoration: _fieldDecoration(
                            hint: '3500',
                            suffix: Padding(
                              padding: const EdgeInsets.only(
                                right: 12,
                                top: 12,
                                bottom: 12,
                              ),
                              child: Text(
                                'đ/$unitPreview',
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Nhập đơn giá'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Đơn vị'),
                        TextFormField(
                          controller: _unitCtrl,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(color: ink, fontSize: 13),
                          decoration: _fieldDecoration(hint: 'kWh, m³...'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Nhập đơn vị'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _label('Mô tả'),
              TextFormField(
                controller: _noteCtrl,
                maxLines: 3,
                style: const TextStyle(color: ink, fontSize: 13),
                decoration: _fieldDecoration(hint: 'Ghi chú dịch vụ...'),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
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
                      : Text(isNew ? 'Thêm dịch vụ' : 'Lưu dịch vụ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
