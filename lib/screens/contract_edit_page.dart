import 'package:flutter/material.dart';

import '../models/record.dart';
import '../utils/validators.dart';
import '../widgets/common.dart';
import '../widgets/form_widgets.dart';

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

class _TenantDraft {
  final String id;
  final TextEditingController name = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController identity = TextEditingController();
  String role;

  _TenantDraft({required this.id, required this.role});

  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    identity.dispose();
  }
}

class ContractEditPage extends StatefulWidget {
  final Record? contract;
  final String? initialRoomId;
  final String? initialTenantId;
  final List<String>? initialTenantIds;
  const ContractEditPage({
    super.key,
    this.contract,
    this.initialRoomId,
    this.initialTenantId,
    this.initialTenantIds,
  });

  @override
  State<ContractEditPage> createState() => _ContractEditPageState();
}

class _ContractEditPageState extends State<ContractEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberCtrl;
  late final TextEditingController _startCtrl;
  late final TextEditingController _endCtrl;
  late final TextEditingController _rentCtrl;
  late final TextEditingController _depositCtrl;
  late final TextEditingController _initialElectricCtrl;
  late final TextEditingController _initialWaterCtrl;
  late final TextEditingController _noteCtrl;
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _identityCtrl = TextEditingController();

  String? _roomId;
  String? _tenantId;
  String? _contactTenantId;
  late bool _useExistingTenant;
  late List<_TenantDraft> _tenantDrafts;
  late Set<String> _existingMemberIds;
  Set<String>? _serviceIds;
  bool _saving = false;
  bool _didPrefillRoomPricing = false;

  @override
  void initState() {
    super.initState();
    final c = widget.contract;
    _roomId = c?.text('roomId') ?? widget.initialRoomId;
    _tenantId = c?.text('tenantId') ?? widget.initialTenantId;
    _useExistingTenant = c != null || widget.initialTenantId != null;
    final initialTenantIds =
        widget.initialTenantIds ?? c?.strings('tenantIds') ?? const [];
    _existingMemberIds = initialTenantIds
        .where((id) => id != _tenantId)
        .toSet();
    _tenantDrafts = c == null && !_useExistingTenant
        ? [_newTenantDraft('leader')]
        : [];
    _serviceIds = c?.data.containsKey('serviceIds') == true
        ? c!.strings('serviceIds').toSet()
        : null;
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final defaultStart = now.toIso8601String().substring(0, 10);
    final defaultEnd = DateTime(
      now.year + 1,
      now.month,
      now.day,
    ).toIso8601String().substring(0, 10);
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
    _rentCtrl = TextEditingController(
      text: c?.number('rent') != null ? '${c!.number('rent')!.round()}' : '',
    );
    _depositCtrl = TextEditingController(
      text: c?.number('deposit') != null
          ? '${c!.number('deposit')!.round()}'
          : '',
    );
    _initialElectricCtrl = TextEditingController(
      text: c?.number('initialElectric') != null
          ? '${c!.number('initialElectric')}'
          : '0',
    );
    _initialWaterCtrl = TextEditingController(
      text: c?.number('initialWater') != null
          ? '${c!.number('initialWater')}'
          : '0',
    );
    _noteCtrl = TextEditingController(text: c?.text('note') ?? '');
    if (c != null) _didPrefillRoomPricing = true;
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _rentCtrl.dispose();
    _depositCtrl.dispose();
    _initialElectricCtrl.dispose();
    _initialWaterCtrl.dispose();
    _noteCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _identityCtrl.dispose();
    for (final tenant in _tenantDrafts) {
      tenant.dispose();
    }
    super.dispose();
  }

  _TenantDraft _newTenantDraft(String role) =>
      _TenantDraft(id: store.db.collection('tenants').doc().id, role: role);

  void _addTenantDraft() {
    setState(() {
      final hasLeader =
          _useExistingTenant || _tenantDrafts.any((t) => t.role == 'leader');
      _tenantDrafts.add(_newTenantDraft(hasLeader ? 'member' : 'leader'));
    });
  }

  void _removeTenantDraft(_TenantDraft draft) {
    setState(() {
      final wasLeader = draft.role == 'leader';
      _tenantDrafts.remove(draft);
      if (wasLeader && !_useExistingTenant && _tenantDrafts.isNotEmpty) {
        _tenantDrafts.first.role = 'leader';
      }
    });
    draft.dispose();
  }

  void _selectDraftRole(_TenantDraft target, String role) {
    setState(() {
      if (role == 'leader') {
        for (final t in _tenantDrafts) {
          t.role = t == target ? 'leader' : 'member';
        }
      } else {
        target.role = 'member';
        if (!_useExistingTenant &&
            !_tenantDrafts.any((t) => t.role == 'leader') &&
            _tenantDrafts.isNotEmpty) {
          final fallback = _tenantDrafts.firstWhere(
            (t) => t != target,
            orElse: () => target,
          );
          fallback.role = 'leader';
        }
      }
    });
  }

  void _setContact(Record? tenant) {
    if (tenant?.id == _contactTenantId) return;
    _contactTenantId = tenant?.id;
    _phoneCtrl.text = tenant?.text('phone') ?? '';
    _emailCtrl.text = tenant?.text('email') ?? '';
    _identityCtrl.text = tenant?.text('identity') ?? '';
  }

  void _applyRoomDefaults(Record? room) {
    if (room == null) return;
    _rentCtrl.text = '${(room.number('price') ?? 0).round()}';
    _depositCtrl.text = '${(room.number('deposit') ?? 0).round()}';
    _initialElectricCtrl.text = '${room.number('initialElectric') ?? 0}';
    _initialWaterCtrl.text = '${room.number('initialWater') ?? 0}';
  }

  Widget _contactField(String label, TextEditingController controller) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: controller,
          keyboardType: label == 'Số điện thoại'
              ? TextInputType.phone
              : label == 'Email'
              ? TextInputType.emailAddress
              : TextInputType.text,
          style: const TextStyle(color: ink, fontSize: 14),
          decoration: _boxDecoration(hint: label),
          validator: (value) {
            if (label == 'Số điện thoại') {
              return validateVietnamesePhone(value, required: false);
            }
            if (label == 'Email') {
              return validateEmail(value, required: false);
            }
            return validateIdentity(value);
          },
        ),
      );

  Future<void> _pickDate(TextEditingController ctrl) async {
    final current =
        DateTime.tryParse(_normalizeDateInput(ctrl.text)) ?? DateTime.now();
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

  Future<void> _save(Set<String> occupiedRoomIds) async {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (_roomId == null || _roomId!.isEmpty) {
      message(context, 'Vui lòng chọn phòng');
      return;
    }
    if (occupiedRoomIds.contains(_roomId)) {
      message(
        context,
        'Phòng này đang có hợp đồng hiệu lực. Chỉ phòng Trống mới được phép tạo hợp đồng mới!',
      );
      return;
    }
    final tenants = _tenantDrafts
        .where((t) => t.name.text.trim().isNotEmpty)
        .toList();
    if (widget.contract == null && _useExistingTenant) {
      if (_tenantId == null || _tenantId!.isEmpty) {
        message(context, 'Vui lòng chọn Trưởng phòng (Người đứng hợp đồng)');
        return;
      }
    } else if (widget.contract == null) {
      final leaders = tenants.where((t) => t.role == 'leader').length;
      if (tenants.isEmpty || leaders != 1) {
        message(
          context,
          'Vui lòng nhập người thuê và chọn duy nhất 1 Trưởng phòng',
        );
        return;
      }
    } else if (_tenantId == null || _tenantId!.isEmpty) {
      message(context, 'Vui lòng chọn Trưởng phòng thuộc phòng đã chọn');
      return;
    }
    final rent = num.tryParse(
      _rentCtrl.text.trim().replaceAll('.', '').replaceAll(',', ''),
    );
    final deposit = num.tryParse(
      _depositCtrl.text.trim().replaceAll('.', '').replaceAll(',', ''),
    );
    final initialElectric = num.tryParse(
      _initialElectricCtrl.text.trim().replaceAll(',', '.'),
    );
    final initialWater = num.tryParse(
      _initialWaterCtrl.text.trim().replaceAll(',', '.'),
    );
    if (rent == null || rent <= 0) {
      message(context, 'Tiền phòng không hợp lệ');
      return;
    }
    if (deposit == null || deposit < 0) {
      message(context, 'Tiền đặt cọc không hợp lệ');
      return;
    }
    if (initialElectric == null || initialElectric < 0) {
      message(context, 'Chỉ số điện ban đầu không hợp lệ');
      return;
    }
    if (initialWater == null || initialWater < 0) {
      message(context, 'Chỉ số nước ban đầu không hợp lệ');
      return;
    }

    final data = <String, dynamic>{
      'roomId': _roomId,
      'tenantId': widget.contract == null && !_useExistingTenant
          ? ''
          : _tenantId,
      'newTenants': widget.contract == null
          ? [
              for (final t in tenants)
                {
                  'id': t.id,
                  'name': t.name.text.trim(),
                  'role': t.role,
                  'phone': t.phone.text.trim(),
                  'email': t.email.text.trim(),
                  'identity': t.identity.text.trim(),
                },
            ]
          : const [],
      'tenantContact': {
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'identity': _identityCtrl.text.trim(),
      },
      'existingMemberIds': _existingMemberIds
          .where((id) => id != _tenantId)
          .toList(),
      'serviceIds': (_serviceIds ?? const <String>{}).toList(),
      'number': widget.contract == null ? '' : _numberCtrl.text.trim(),
      'startDate': _normalizeDateInput(_startCtrl.text),
      'endDate': _normalizeDateInput(_endCtrl.text),
      'rent': rent.round(),
      'deposit': deposit.round(),
      'initialElectric': initialElectric,
      'initialWater': initialWater,
      'note': _noteCtrl.text.trim(),
    };
    setState(() => _saving = true);
    try {
      final result = await store.command(
        'saveContract',
        id: widget.contract?.id,
        data: data,
      );
      if (mounted) {
        Navigator.pop(context);
        message(
          context,
          'Đã lưu hợp đồng ${result['number'] ?? _numberCtrl.text}',
        );
      }
    } catch (e) {
      if (mounted) message(context, errorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _boxDecoration({required String hint, Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF5D616D), fontSize: 13.5),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
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

  String _suggestedNumber(List<Record> contracts) {
    final year = DateTime.now().toUtc().add(const Duration(hours: 7)).year;
    final prefix = 'HD-$year-';
    var highest = 0;
    for (final contract in contracts) {
      final number = contract.text('number');
      if (!number.startsWith(prefix)) continue;
      final sequence = int.tryParse(number.substring(prefix.length));
      if (sequence != null && sequence > highest) highest = sequence;
    }
    return '$prefix${(highest + 1).toString().padLeft(4, '0')}';
  }

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
            builder: (_, ts) => RecordsView(
              collection: 'services',
              builder: (_, services) => RecordsView(
                collection: 'contracts',
                builder: (_, contracts) {
                  final rooms =
                      rs
                          .where((r) => !r.archived && r.condition == 'Tốt')
                          .toList()
                        ..sort((a, b) => naturalCompare(a.name, b.name));

                  // Các phòng đang có hợp đồng hiệu lực (ngoại trừ hợp đồng đang sửa)
                  final occupiedRoomIds = contracts
                      .where(
                        (c) =>
                            !c.archived &&
                            c.id != widget.contract?.id &&
                            ['active', 'scheduled'].contains(c.text('status')),
                      )
                      .map((c) => c.text('roomId'))
                      .toSet();

                  final selectedRoom = rooms
                      .where((r) => r.id == _roomId)
                      .firstOrNull;
                  if (!_didPrefillRoomPricing && selectedRoom != null) {
                    _didPrefillRoomPricing = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() => _applyRoomDefaults(selectedRoom));
                      }
                    });
                  }
                  if (_serviceIds == null && selectedRoom != null) {
                    _serviceIds = selectedRoom.strings('serviceIds').toSet();
                  }
                  final roomTenants = selectedRoom == null
                      ? const <Record>[]
                      : ts
                            .where(
                              (t) =>
                                  !t.archived &&
                                  t.text('roomId') == selectedRoom.id,
                            )
                            .toList();
                  final needsExistingTenant = isEdit || _useExistingTenant;
                  final validTenantId = !needsExistingTenant
                      ? null
                      : roomTenants.any((t) => t.id == _tenantId)
                      ? _tenantId
                      : (roomTenants.isNotEmpty
                            ? (roomTenants
                                      .where((t) => t.text('role') == 'leader')
                                      .firstOrNull
                                      ?.id ??
                                  roomTenants.first.id)
                            : null);
                  if (validTenantId != _tenantId) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _tenantId = validTenantId);
                    });
                  }
                  final selectedTenant = roomTenants
                      .where((t) => t.id == validTenantId)
                      .firstOrNull;
                  if (needsExistingTenant) {
                    _setContact(selectedTenant);
                  }
                  final isSelectedRoomOccupied =
                      selectedRoom != null &&
                      occupiedRoomIds.contains(selectedRoom.id);

                  return Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                      children: [
                        if (isEdit) ...[
                          formLabel('Số hợp đồng', required: true),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: TextFormField(
                              controller: _numberCtrl,
                              style: const TextStyle(color: ink, fontSize: 14),
                              decoration: _boxDecoration(hint: 'Số hợp đồng'),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Vui lòng nhập số hợp đồng'
                                  : null,
                            ),
                          ),
                        ] else
                          _readOnlyBox(
                            'Số hợp đồng (tự động)',
                            _suggestedNumber(contracts),
                          ),

                        formLabel('Chọn phòng (chỉ phòng Trống)', required: true),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('room_${selectedRoom?.id}'),
                            initialValue: selectedRoom?.id,
                            dropdownColor: Colors.white,
                            isExpanded: true,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: muted,
                            ),
                            style: const TextStyle(color: ink, fontSize: 14),
                            decoration: _boxDecoration(
                              hint: 'Chọn phòng trống để lập hợp đồng',
                            ),
                            items: [
                              for (final r in rooms)
                                DropdownMenuItem(
                                  value: r.id,
                                  child: Text(
                                    occupiedRoomIds.contains(r.id)
                                        ? '${r.name} — Đang thuê (Đã có hợp đồng)'
                                        : '${r.name} — Trống (${money(r.data['price'])}/tháng)',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: occupiedRoomIds.contains(r.id)
                                          ? const Color(0xFFDC2626)
                                          : ink,
                                      fontWeight: occupiedRoomIds.contains(r.id)
                                          ? FontWeight.w500
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                            onChanged: (v) {
                              final room = rooms
                                  .where((r) => r.id == v)
                                  .firstOrNull;
                              _setContact(null);
                              setState(() {
                                _roomId = v;
                                _tenantId = null;
                                _existingMemberIds.clear();
                                _serviceIds = room
                                    ?.strings('serviceIds')
                                    .toSet();
                                _applyRoomDefaults(room);
                              });
                            },
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Vui lòng chọn phòng';
                              }
                              if (occupiedRoomIds.contains(v)) {
                                return 'Phòng này đang có hợp đồng hiệu lực. Chỉ phòng Trống mới được lập hợp đồng!';
                              }
                              return null;
                            },
                          ),
                        ),
                        if (isSelectedRoomOccupied)
                          Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDECEC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Color(0xFFDC2626),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Phòng này đang có hợp đồng hiệu lực. Hệ thống không cho phép tạo hợp đồng thứ 2 chồng lên phòng đang thuê. Vui lòng chọn phòng Trống!',
                                    style: TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const SizedBox(height: 6),

                        if (!isEdit)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                  value: false,
                                  label: Text('Tạo người thuê mới'),
                                ),
                                ButtonSegment(
                                  value: true,
                                  label: Text('Chọn người có sẵn'),
                                ),
                              ],
                              selected: {_useExistingTenant},
                              onSelectionChanged: (selection) {
                                setState(() {
                                  _useExistingTenant = selection.first;
                                  _tenantId = null;
                                  if (_useExistingTenant) {
                                    for (final tenant in _tenantDrafts) {
                                      tenant.role = 'member';
                                    }
                                  } else if (_tenantDrafts.isEmpty) {
                                    _tenantDrafts.add(
                                      _newTenantDraft('leader'),
                                    );
                                  } else {
                                    for (
                                      var i = 0;
                                      i < _tenantDrafts.length;
                                      i++
                                    ) {
                                      _tenantDrafts[i].role = i == 0
                                          ? 'leader'
                                          : 'member';
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                        if (isEdit || _useExistingTenant) ...[
                          formLabel(
                            'Trưởng phòng (Người đại diện đứng tên hợp đồng)',
                            required: true,
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
                                    ? 'Chọn phòng trước'
                                    : roomTenants.isEmpty
                                    ? 'Phòng chưa có người thuê sẵn'
                                    : 'Chọn duy nhất 1 Trưởng phòng',
                              ),
                              items: [
                                for (final t in roomTenants)
                                  DropdownMenuItem(
                                    value: t.id,
                                    child: Text('${t.name} (${t.text('phone')})'),
                                  ),
                              ],
                              onChanged: (v) {
                                final previousLeader = _tenantId;
                                setState(() {
                                  _tenantId = v;
                                  if (previousLeader != null &&
                                      previousLeader != v &&
                                      roomTenants.any(
                                        (tenant) => tenant.id == previousLeader,
                                      )) {
                                    _existingMemberIds.add(previousLeader);
                                  }
                                  if (v != null) {
                                    _existingMemberIds.remove(v);
                                  }
                                });
                                _setContact(
                                  roomTenants
                                      .where((t) => t.id == v)
                                      .firstOrNull,
                                );
                              },
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Vui lòng chọn Trưởng phòng đứng tên hợp đồng'
                                  : null,
                            ),
                          ),
                        ],
                        if (roomTenants.any((t) => t.id != validTenantId)) ...[
                          const Padding(
                            padding: EdgeInsets.only(top: 2, bottom: 4),
                            child: Text(
                              'Thành viên ở ghép trong phòng (tự động là Thành viên)',
                              style: TextStyle(
                                color: ink,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          for (final member in roomTenants.where(
                            (t) => t.id != validTenantId,
                          ))
                            CheckboxListTile(
                              value: _existingMemberIds.contains(member.id),
                              activeColor: blue,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              title: Text(
                                member.name,
                                style: const TextStyle(
                                  color: ink,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: const Text(
                                'Thành viên ở ghép',
                                style: TextStyle(color: muted, fontSize: 11),
                              ),
                              onChanged: (checked) => setState(() {
                                if (checked == true) {
                                  _existingMemberIds.add(member.id);
                                } else {
                                  _existingMemberIds.remove(member.id);
                                }
                              }),
                            ),
                        ],
                        if (!isEdit) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              _useExistingTenant
                                  ? 'Thêm thành viên ở ghép mới (nếu có)'
                                  : 'Danh sách người thuê (Chỉ duy nhất 1 Trưởng phòng)',
                              style: const TextStyle(
                                color: ink,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          for (final tenant in _tenantDrafts)
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      (!_useExistingTenant &&
                                          tenant.role == 'leader')
                                      ? blue
                                      : line,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    controller: tenant.name,
                                    style: const TextStyle(
                                      color: ink,
                                      fontSize: 14,
                                    ),
                                    decoration:
                                        _boxDecoration(
                                          hint: 'Họ và tên người thuê *',
                                        ).copyWith(
                                          suffixIcon: _tenantDrafts.length > 1
                                              ? IconButton(
                                                  icon: const Icon(
                                                    Icons.close_rounded,
                                                    color: muted,
                                                  ),
                                                  onPressed: () =>
                                                      _removeTenantDraft(
                                                        tenant,
                                                      ),
                                                )
                                              : null,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    key: ValueKey(
                                      'role_${tenant.id}_${_useExistingTenant ? 'member' : tenant.role}',
                                    ),
                                    initialValue: _useExistingTenant
                                        ? 'member'
                                        : tenant.role,
                                    decoration: _boxDecoration(hint: 'Vai trò'),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'leader',
                                        child: Text(
                                          'Trưởng phòng (Đại diện hợp đồng)',
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'member',
                                        child: Text('Thành viên ở ghép'),
                                      ),
                                    ],
                                    onChanged: _useExistingTenant
                                        ? null
                                        : (role) {
                                            if (role != null) {
                                              _selectDraftRole(tenant, role);
                                            }
                                          },
                                  ),
                                  const SizedBox(height: 10),
                                  _contactField('Số điện thoại', tenant.phone),
                                  _contactField('Email', tenant.email),
                                  _contactField(
                                    'CCCD/Passport',
                                    tenant.identity,
                                  ),
                                ],
                              ),
                            ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _addTenantDraft,
                              icon: const Icon(Icons.person_add_alt_1_rounded),
                              label: const Text('Thêm thành viên ở ghép'),
                            ),
                          ),
                        ],
                        if (isEdit || _useExistingTenant) ...[
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Thông tin liên hệ Trưởng phòng',
                              style: TextStyle(
                                color: ink,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          _contactField('Số điện thoại', _phoneCtrl),
                          _contactField('Email', _emailCtrl),
                          _contactField('CCCD/Passport', _identityCtrl),
                        ],

                        const SizedBox(height: 4),
                        formLabel('Ngày bắt đầu hợp đồng', required: true),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: TextFormField(
                            controller: _startCtrl,
                            style: const TextStyle(color: ink, fontSize: 14),
                            decoration: _boxDecoration(
                              hint: 'YYYY-MM-DD hoặc dd/MM/yyyy',
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
                                ? 'Vui lòng nhập ngày bắt đầu hợp đồng'
                                : null,
                          ),
                        ),

                        formLabel('Ngày kết thúc hợp đồng', required: true),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: TextFormField(
                            controller: _endCtrl,
                            style: const TextStyle(color: ink, fontSize: 14),
                            decoration: _boxDecoration(
                              hint: 'YYYY-MM-DD hoặc dd/MM/yyyy',
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
                                ? 'Vui lòng nhập ngày kết thúc hợp đồng'
                                : null,
                          ),
                        ),

                        formLabel('Tiền phòng (đ/tháng)', required: true),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: TextFormField(
                            controller: _rentCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              color: ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: _boxDecoration(
                              hint: 'Nhập giá tiền phòng hàng tháng (VD: 3500000)',
                            ),
                            validator: (v) {
                              final n = num.tryParse(
                                (v ?? '')
                                    .trim()
                                    .replaceAll('.', '')
                                    .replaceAll(',', ''),
                              );
                              if (n == null || n <= 0) {
                                return 'Vui lòng nhập tiền phòng hợp lệ';
                              }
                              return null;
                            },
                          ),
                        ),

                        formLabel('Tiền đặt cọc (đ)', required: true),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: TextFormField(
                            controller: _depositCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              color: ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: _boxDecoration(
                              hint: 'Nhập số tiền đặt cọc (VD: 3500000)',
                            ),
                            validator: (v) {
                              final n = num.tryParse(
                                (v ?? '')
                                    .trim()
                                    .replaceAll('.', '')
                                    .replaceAll(',', ''),
                              );
                              if (n == null || n < 0) {
                                return 'Vui lòng nhập tiền cọc hợp lệ';
                              }
                              return null;
                            },
                          ),
                        ),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  formLabel(
                                    'Chỉ số điện ban đầu (lúc làm hợp đồng)',
                                    required: true,
                                  ),
                                  TextFormField(
                                    controller: _initialElectricCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    style: const TextStyle(
                                      color: ink,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    decoration: _boxDecoration(
                                      hint: 'VD: 120 (kWh)',
                                    ),
                                    validator: (v) {
                                      final n = num.tryParse(
                                        (v ?? '').trim().replaceAll(',', '.'),
                                      );
                                      if (n == null || n < 0) {
                                        return 'Nhập chỉ số điện >= 0';
                                      }
                                      return null;
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
                                  formLabel(
                                    'Chỉ số nước ban đầu (lúc làm hợp đồng)',
                                    required: true,
                                  ),
                                  TextFormField(
                                    controller: _initialWaterCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    style: const TextStyle(
                                      color: ink,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    decoration: _boxDecoration(
                                      hint: 'VD: 35 (m³)',
                                    ),
                                    validator: (v) {
                                      final n = num.tryParse(
                                        (v ?? '').trim().replaceAll(',', '.'),
                                      );
                                      if (n == null || n < 0) {
                                        return 'Nhập chỉ số nước >= 0';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 6, bottom: 14),
                          child: Text(
                            'Chỉ số điện & nước ban đầu sẽ được lưu vào hợp đồng và phòng để làm mốc chỉ số cũ khi tính hóa đơn tháng đầu tiên.',
                            style: TextStyle(color: muted, fontSize: 11.5),
                          ),
                        ),

                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Dịch vụ áp dụng',
                            style: TextStyle(
                              color: ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (services.where((s) => !s.archived).isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 14),
                            child: Text(
                              'Chưa có dịch vụ nào để chọn',
                              style: TextStyle(color: muted, fontSize: 12),
                            ),
                          ),
                        for (final service
                            in services.where((s) => !s.archived).toList()
                              ..sort((a, b) => a.name.compareTo(b.name)))
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CheckboxListTile(
                              value: (_serviceIds ?? {}).contains(service.id),
                              activeColor: blue,
                              title: Text(
                                service.name,
                                style: const TextStyle(
                                  color: ink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${label(service.text('mode'))} · ${money(service.data['price'])}/${service.text('unit')}',
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 11,
                                ),
                              ),
                              onChanged: (checked) => setState(() {
                                final selected = Set<String>.from(
                                  _serviceIds ??
                                      selectedRoom?.strings('serviceIds') ??
                                      const [],
                                );
                                if (checked == true) {
                                  selected.add(service.id);
                                } else {
                                  selected.remove(service.id);
                                }
                                _serviceIds = selected;
                              }),
                            ),
                          ),
                        const SizedBox(height: 8),
                        formLabel('Ghi chú hợp đồng'),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 22),
                          child: TextFormField(
                            controller: _noteCtrl,
                            maxLines: 3,
                            style: const TextStyle(color: ink, fontSize: 14),
                            decoration: _boxDecoration(hint: 'Ghi chú điều khoản...'),
                          ),
                        ),
                        SizedBox(
                          height: 50,
                          child: FilledButton(
                            onPressed: _saving
                                ? null
                                : () => _save(occupiedRoomIds),
                            style: FilledButton.styleFrom(
                              backgroundColor: blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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
                                : Text(
                                    isEdit
                                        ? 'Lưu thay đổi hợp đồng'
                                        : 'Lưu hợp đồng',
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
