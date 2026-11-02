import 'package:flutter/material.dart';

import '../models/record.dart';
import '../widgets/common.dart';

String _normalizeDateInput(String raw) {
  final t = raw.trim();
  final dmy = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(t);
  if (dmy != null) {
    final dd = dmy.group(1)!.padLeft(2, '0');
    final mm = dmy.group(2)!.padLeft(2, '0');
    final yyyy = dmy.group(3)!;
    return '$yyyy-$mm-$dd';
  }
  return t;
}

class ContractEditPage extends StatefulWidget {
  final Record? contract;
  final String? initialRoomId;
  final String? initialTenantId;
  const ContractEditPage({
    super.key,
    this.contract,
    this.initialRoomId,
    this.initialTenantId,
  });

  @override
  State<ContractEditPage> createState() => _ContractEditPageState();
}

class _ContractEditPageState extends State<ContractEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final String _recordId;
  late final TextEditingController _numberCtrl;
  late final TextEditingController _startCtrl;
  late final TextEditingController _endCtrl;
  late final TextEditingController _noteCtrl;
  String? _roomId;
  String? _tenantId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.contract;
    _recordId = c?.id ?? store.db.collection('_').doc().id;
    _roomId = c?.text('roomId') ?? widget.initialRoomId;
    _tenantId = c?.text('tenantId') ?? widget.initialTenantId;
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final defaultStart = now.toIso8601String().substring(0, 10);
    final defaultEnd = DateTime(now.year + 1, now.month, now.day)
        .toIso8601String()
        .substring(0, 10);
    _numberCtrl = TextEditingController(text: c?.text('number') ?? '');
    _startCtrl = TextEditingController(
      text: c?.text('startDate').isNotEmpty == true
          ? c!.text('startDate')
          : defaultStart,
    );
    _endCtrl = TextEditingController(
      text: c?.text('endDate').isNotEmpty == true
          ? c!.text('endDate')
          : defaultEnd,
    );
    _noteCtrl = TextEditingController(text: c?.text('note') ?? '');
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final current = DateTime.tryParse(_normalizeDateInput(ctrl.text)) ??
        DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() {
        ctrl.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (_roomId == null || _roomId!.isEmpty) {
      message(context, 'Vui lòng chọn phòng');
      return;
    }
    if (_tenantId == null || _tenantId!.isEmpty) {
      message(context, 'Vui lòng chọn người thuê thuộc phòng đã chọn');
      return;
    }
    final data = <String, dynamic>{
      'roomId': _roomId,
      'tenantId': _tenantId,
      'number': _numberCtrl.text.trim(),
      'startDate': _normalizeDateInput(_startCtrl.text),
      'endDate': _normalizeDateInput(_endCtrl.text),
      'note': _noteCtrl.text.trim(),
    };
    setState(() => _saving = true);
    try {
      await store.command('saveContract', id: _recordId, data: data);
      if (mounted) {
        Navigator.pop(context);
        message(context, 'Đã lưu hợp đồng lên Firebase');
      }
    } catch (e) {
      if (mounted) message(context, errorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _boxDecoration({
    required String hint,
    Widget? suffix,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF5D616D), fontSize: 13.5),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
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
      borderSide: const BorderSide(color: blue, width: 1.3),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.3),
    ),
  );

  Widget _readOnlyBox(String labelText, String value) => Container(
    height: 50,
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Text(
          labelText,
          style: const TextStyle(color: Color(0xFF5D616D), fontSize: 13.5),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ink,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.contract != null;
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
            isEdit ? 'Chỉnh sửa hợp đồng' : 'Tạo hợp đồng',
            style: const TextStyle(
              color: ink,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: RecordsView(
          collection: 'rooms',
          builder: (_, rs) => RecordsView(
            collection: 'tenants',
            builder: (_, ts) {
              final rooms = rs
                  .where((r) => !r.archived && r.condition == 'Tốt')
                  .toList()
                ..sort((a, b) => a.name.compareTo(b.name));
              final selectedRoom = rooms
                  .where((r) => r.id == _roomId)
                  .firstOrNull;
              final roomTenants = selectedRoom == null
                  ? const <Record>[]
                  : ts
                        .where(
                          (t) =>
                              !t.archived &&
                              t.text('roomId') == selectedRoom.id,
                        )
                        .toList();
              final validTenantId = roomTenants.any((t) => t.id == _tenantId)
                  ? _tenantId
                  : (roomTenants.length == 1 ? roomTenants.first.id : null);
              if (validTenantId != _tenantId) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _tenantId = validTenantId);
                });
              }
              final selectedTenant = roomTenants
                  .where((t) => t.id == validTenantId)
                  .firstOrNull;

              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: TextFormField(
                        controller: _numberCtrl,
                        style: const TextStyle(color: ink, fontSize: 14),
                        decoration: _boxDecoration(
                          hint: 'Số hợp đồng (VD: HD-01/2026-P.101)',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Vui lòng nhập số hợp đồng'
                            : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('room_${selectedRoom?.id}'),
                        initialValue: selectedRoom?.id,
                        dropdownColor: Colors.white,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: muted,
                        ),
                        style: const TextStyle(color: ink, fontSize: 14),
                        decoration: _boxDecoration(hint: 'Phòng'),
                        items: [
                          for (final r in rooms)
                            DropdownMenuItem(value: r.id, child: Text(r.name)),
                        ],
                        onChanged: (v) => setState(() {
                          _roomId = v;
                          _tenantId = null;
                        }),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Chọn phòng' : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(
                          'tenant_${selectedRoom?.id}_$validTenantId',
                        ),
                        initialValue: validTenantId,
                        dropdownColor: Colors.white,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: muted,
                        ),
                        style: const TextStyle(color: ink, fontSize: 14),
                        decoration: _boxDecoration(
                          hint: selectedRoom == null
                              ? 'Người thuê (chọn phòng trước)'
                              : roomTenants.isEmpty
                              ? 'Phòng chưa có người thuê'
                              : 'Người thuê',
                        ),
                        items: [
                          for (final t in roomTenants)
                            DropdownMenuItem(value: t.id, child: Text(t.name)),
                        ],
                        onChanged: (v) => setState(() => _tenantId = v),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Chọn người đứng hợp đồng'
                            : null,
                      ),
                    ),
                    _readOnlyBox(
                      'Số điện thoại',
                      selectedTenant?.text('phone').isNotEmpty == true
                          ? selectedTenant!.text('phone')
                          : 'Tự động theo người thuê',
                    ),
                    _readOnlyBox(
                      'Email',
                      selectedTenant?.text('email').isNotEmpty == true
                          ? selectedTenant!.text('email')
                          : 'Tự động theo người thuê',
                    ),
                    _readOnlyBox(
                      'CCCD/Passport',
                      selectedTenant?.text('identity').isNotEmpty == true
                          ? selectedTenant!.text('identity')
                          : 'Tự động theo người thuê',
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: TextFormField(
                        controller: _startCtrl,
                        style: const TextStyle(color: ink, fontSize: 14),
                        decoration: _boxDecoration(
                          hint: 'Ngày bắt đầu (YYYY-MM-DD hoặc dd/mm/yyyy)',
                          suffix: IconButton(
                            icon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: muted,
                            ),
                            onPressed: () => _pickDate(_startCtrl),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nhập ngày bắt đầu'
                            : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: TextFormField(
                        controller: _endCtrl,
                        style: const TextStyle(color: ink, fontSize: 14),
                        decoration: _boxDecoration(
                          hint: 'Ngày kết thúc (YYYY-MM-DD hoặc dd/mm/yyyy)',
                          suffix: IconButton(
                            icon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: muted,
                            ),
                            onPressed: () => _pickDate(_endCtrl),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nhập ngày kết thúc'
                            : null,
                      ),
                    ),
                    _readOnlyBox(
                      'Tiền phòng (đ/tháng)',
                      selectedRoom != null
                          ? money(selectedRoom.data['price'])
                          : 'Tự động lấy từ phòng',
                    ),
                    _readOnlyBox(
                      'Tiền đặt cọc (đ)',
                      selectedRoom != null
                          ? money(selectedRoom.data['deposit'])
                          : 'Tự động lấy từ phòng',
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: TextFormField(
                        controller: _noteCtrl,
                        maxLines: 4,
                        style: const TextStyle(color: ink, fontSize: 14),
                        decoration: _boxDecoration(hint: 'Ghi chú'),
                      ),
                    ),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14.5,
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
                            : const Text('Lưu hợp đồng'),
                      ),
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
