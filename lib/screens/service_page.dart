import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/record.dart';
import '../widgets/common.dart';
import 'service_edit_page.dart';

String _displayMonth(String yyyyMm) {
  final parts = yyyyMm.split('-');
  if (parts.length == 2) return '${parts[1]}/${parts[0]}';
  return yyyyMm;
}

List<String> _recentPeriods([int count = 12]) {
  final now = DateTime.now().toUtc().add(const Duration(hours: 7));
  return List.generate(
    count,
    (i) => periodOf(DateTime(now.year, now.month - i, 1)),
  );
}

Record? _latestMeterBefore(
  List<Record> meters,
  String serviceId,
  String period,
) {
  final previous =
      meters
          .where(
            (meter) =>
                meter.text('serviceId') == serviceId &&
                meter.text('period').compareTo(period) < 0,
          )
          .toList()
        ..sort((a, b) => b.text('period').compareTo(a.text('period')));
  return previous.firstOrNull;
}

class ServicePage extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  const ServicePage({super.key, this.onNavigate});
  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  int _tab = 0;
  String _query = '';
  String _selectedPeriod = periodOf();

  Widget _buildSegmentedTabs() => Container(
    height: 40,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: line, width: 0.7),
    ),
    child: Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _tab = 0),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _tab == 0 ? softBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Dịch vụ',
                style: TextStyle(
                  color: _tab == 0 ? blue : muted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _tab = 1),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _tab == 1 ? softBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Nhập chỉ số',
                style: TextStyle(
                  color: _tab == 1 ? blue : muted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildServicesTab(BuildContext context) => RecordsView(
    collection: 'services',
    builder: (_, all) {
      final services =
          all
              .where(
                (s) =>
                    !s.archived &&
                    s.name.toLowerCase().contains(_query.toLowerCase()),
              )
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
      return Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
              children: [
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: searchDecoration('Tìm kiếm dịch vụ...'),
                ),
                const SizedBox(height: 10),
                _buildSegmentedTabs(),
                const SizedBox(height: 12),
                if (services.isEmpty) empty('Chưa có dịch vụ'),
                for (final s in services)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: line, width: 0.7),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () =>
                          openPage(context, ServiceEditPage(service: s)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 13,
                        ),
                        child: Row(
                          children: [
                            serviceBadge(
                              s.name,
                              mode: s.text('mode'),
                              size: 34,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.name,
                                    style: const TextStyle(
                                      color: ink,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    label(s.text('mode')),
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${money(s.data['price'])}/${s.text('unit')}',
                              style: const TextStyle(
                                color: ink,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 2),
                            moreActionsMenu(
                              onEdit: () =>
                                  openPage(context, ServiceEditPage(service: s)),
                              onDelete: () async {
                                if (await confirm(
                                      context,
                                      'Xóa dịch vụ ${s.name}? Dịch vụ phải được bỏ khỏi các phòng trước.',
                                    ) &&
                                    context.mounted) {
                                  await perform(
                                    context,
                                    () => store.command(
                                      'archiveService',
                                      id: s.id,
                                    ),
                                    'Đã xóa dịch vụ khỏi danh mục',
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: () => openPage(context, const ServiceEditPage()),
                style: FilledButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('+  Thêm dịch vụ'),
              ),
            ),
          ),
        ],
      );
    },
  );

  Future<void> _assignMeterServicesAndOpen(
    BuildContext context,
    Record room,
    List<Record> meterServices,
  ) async {
    final serviceIds = meterServices.map((service) => service.id).toSet();
    final selected = room.strings('serviceIds').toSet()
      ..removeWhere((id) => !serviceIds.contains(id));
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, refresh) => AlertDialog(
          title: Text('Dịch vụ tính chỉ số · ${room.name}'),
          content: SizedBox(
            width: 400,
            child: meterServices.isEmpty
                ? const Text(
                    'Chưa có dịch vụ nào được tạo theo cách tính chỉ số. '
                    'Hãy tạo dịch vụ Điện/Nước trong Danh mục trước.',
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final service in meterServices)
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(service.name),
                            subtitle: Text(
                              '${money(service.data['price'])}/${service.text('unit')}',
                            ),
                            value: selected.contains(service.id),
                            onChanged: (checked) => refresh(() {
                              if (checked == true) {
                                selected.add(service.id);
                              } else {
                                selected.remove(service.id);
                              }
                            }),
                          ),
                      ],
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            if (meterServices.isNotEmpty)
              FilledButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, Set<String>.of(selected)),
                child: const Text('Lưu và mở ô nhập'),
              ),
          ],
        ),
      ),
    );
    if (result == null || !context.mounted) return;
    if (result.isEmpty) {
      message(context, 'Hãy chọn ít nhất một dịch vụ tính theo chỉ số');
      return;
    }

    final allServiceIds = room
        .strings('serviceIds')
        .where((id) => !serviceIds.contains(id))
        .followedBy(result)
        .toSet()
        .toList();
    try {
      await store.command(
        'assignServices',
        args: {'roomId': room.id, 'serviceIds': allServiceIds},
      );
      if (!context.mounted) return;
      final updatedRoom = Record(room.id, {
        ...room.data,
        'serviceIds': allServiceIds,
      });
      await openPage(
        context,
        RoomMeterEntryPage(
          room: updatedRoom,
          initialPeriod: _selectedPeriod,
          onNavigate: widget.onNavigate,
        ),
      );
    } catch (e) {
      if (context.mounted) message(context, errorText(e));
    }
  }

  Widget _buildMetersTab(BuildContext context) {
    final periods = _recentPeriods(12);
    if (!periods.contains(_selectedPeriod)) {
      periods.insert(0, _selectedPeriod);
    }
    return RecordsView(
      collection: 'rooms',
      builder: (_, rs) => RecordsView(
        collection: 'services',
        builder: (_, svcs) => RecordsView(
          collection: 'meters',
          field: 'period',
          equals: _selectedPeriod,
          builder: (_, meters) {
            final rooms = rs.where((r) => !r.archived).toList()
              ..sort((a, b) => a.name.compareTo(b.name));
            final meterServiceIds = svcs
                .where((s) => !s.archived && s.text('mode') == 'meter')
                .map((s) => s.id)
                .toSet();
            final meterServices = svcs
                .where((s) => !s.archived && s.text('mode') == 'meter')
                .toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
              children: [
                _buildSegmentedTabs(),
                const SizedBox(height: 12),
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: line, width: 0.7),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPeriod,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: muted,
                        size: 20,
                      ),
                      style: const TextStyle(
                        color: ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      items: [
                        for (final p in periods)
                          DropdownMenuItem(
                            value: p,
                            child: Text(_displayMonth(p)),
                          ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedPeriod = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                box(
                  const Text(
                    'Chọn phòng rồi nhập chỉ số mới cho từng dịch vụ như Điện, Nước. Lần đầu, nhập thêm chỉ số cũ đang hiển thị trên đồng hồ; từ lần sau ứng dụng tự lấy chỉ số mới của kỳ gần nhất làm chỉ số cũ.',
                    style: TextStyle(color: muted, fontSize: 12, height: 1.4),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
                const Text(
                  'Danh sách phòng',
                  style: TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (rooms.isEmpty)
                  box(
                    const Text(
                      'Chưa có phòng. Hãy tạo phòng trước khi nhập chỉ số.',
                      style: TextStyle(color: muted, fontSize: 12, height: 1.4),
                    ),
                    padding: const EdgeInsets.all(12),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: line, width: 0.7),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var i = 0; i < rooms.length; i++)
                          Builder(
                            builder: (context) {
                              final r = rooms[i];
                              final roomMeterIds = r
                                  .strings('serviceIds')
                                  .where(meterServiceIds.contains)
                                  .toList();
                              final enteredCount = roomMeterIds
                                  .where(
                                    (sid) => meters.any(
                                      (m) =>
                                          m.text('roomId') == r.id &&
                                          m.text('serviceId') == sid,
                                    ),
                                  )
                                  .length;
                              final allEntered =
                                  roomMeterIds.isNotEmpty &&
                                  enteredCount == roomMeterIds.length;
                              final divider = i < rooms.length - 1
                                  ? const Border(
                                      bottom: BorderSide(color: line),
                                    )
                                  : null;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(border: divider),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: roomMeterIds.isEmpty
                                            ? null
                                            : () => openPage(
                                                context,
                                                RoomMeterEntryPage(
                                                  room: r,
                                                  initialPeriod:
                                                      _selectedPeriod,
                                                  onNavigate: widget.onNavigate,
                                                ),
                                              ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                r.name,
                                                style: const TextStyle(
                                                  color: ink,
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                roomMeterIds.isEmpty
                                                    ? 'Chưa áp dụng dịch vụ tính chỉ số'
                                                    : '${roomMeterIds.map((id) => svcs.firstWhere((service) => service.id == id).name).join(' · ')}  •  ${allEntered ? 'Đã nhập' : 'Chưa nhập'}',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color:
                                                      roomMeterIds.isNotEmpty &&
                                                          allEntered
                                                      ? const Color(0xFF16A34A)
                                                      : muted,
                                                  fontSize: 10.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (roomMeterIds.isEmpty)
                                      FilledButton.tonalIcon(
                                        onPressed: () =>
                                            _assignMeterServicesAndOpen(
                                              context,
                                              r,
                                              meterServices,
                                            ),
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text('Chọn dịch vụ'),
                                      )
                                    else
                                      FilledButton.icon(
                                        onPressed: () => openPage(
                                          context,
                                          RoomMeterEntryPage(
                                            room: r,
                                            initialPeriod: _selectedPeriod,
                                            onNavigate: widget.onNavigate,
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.edit_note_rounded,
                                          size: 18,
                                        ),
                                        label: const Text('Nhập chỉ số'),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    appBar: AppBar(
      backgroundColor: canvas,
      title: Text(
        _tab == 0 ? 'Dịch vụ' : 'Nhập chỉ số',
        style: TextStyle(color: ink, fontSize: 22, fontWeight: FontWeight.w600),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextButton.icon(
            onPressed: () => setState(() => _tab = _tab == 0 ? 1 : 0),
            icon: Icon(
              _tab == 0 ? Icons.speed_rounded : Icons.list_alt_rounded,
            ),
            label: Text(_tab == 0 ? 'Nhập chỉ số' : 'Danh mục'),
          ),
        ),
      ],
    ),
    body: _tab == 0 ? _buildServicesTab(context) : _buildMetersTab(context),
  );
}

class RoomMeterEntryPage extends StatefulWidget {
  final Record room;
  final String initialPeriod;
  final ValueChanged<int>? onNavigate;
  const RoomMeterEntryPage({
    super.key,
    required this.room,
    required this.initialPeriod,
    this.onNavigate,
  });

  @override
  State<RoomMeterEntryPage> createState() => _RoomMeterEntryPageState();
}

class _RoomMeterEntryPageState extends State<RoomMeterEntryPage> {
  late String _period;
  final _prevCtrls = <String, TextEditingController>{};
  final _currCtrls = <String, TextEditingController>{};
  final _fieldErrors = <String, String>{};
  String _hydratedKey = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _period = widget.initialPeriod;
  }

  @override
  void dispose() {
    for (final c in _prevCtrls.values) {
      c.dispose();
    }
    for (final c in _currCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncControllers(List<Record> meterServices, List<Record> meters) {
    final key =
        '$_period:${meters.map((m) => '${m.id}=${m.data['previous']}-${m.data['current']}').join(',')}';
    if (_hydratedKey == key) return;
    _hydratedKey = key;
    for (final s in meterServices) {
      final saved = meters
          .where(
            (m) => m.text('period') == _period && m.text('serviceId') == s.id,
          )
          .firstOrNull;
      final prev = _latestMeterBefore(meters, s.id, _period);
      final initReading = _initialRoomReadingForService(widget.room, s);
      final prevVal =
          (saved?.data['previous'] ?? prev?.data['current'] ?? initReading ?? '')
              .toString();
      final currVal = saved?.data['current']?.toString() ?? '';
      _prevCtrls.putIfAbsent(s.id, () => TextEditingController()).text =
          prevVal;
      _currCtrls.putIfAbsent(s.id, () => TextEditingController()).text =
          currVal;
    }
  }

  Future<void> _saveAll(
    String roomId,
    List<Record> meterServices,
    List<Record> meters,
  ) async {
    if (_saving) return;
    setState(_fieldErrors.clear);
    if (meterServices.isEmpty) {
      message(context, 'Phòng chưa áp dụng dịch vụ theo chỉ số');
      return;
    }
    final payloads = <Map<String, dynamic>>[];
    for (final s in meterServices) {
      final currText = (_currCtrls[s.id]?.text ?? '').trim().replaceAll(
        ',',
        '.',
      );
      if (currText.isEmpty) {
        setState(() => _fieldErrors['${s.id}_current'] = 'Nhập chỉ số mới');
        return;
      }
      final prevRecord = _latestMeterBefore(meters, s.id, _period);
      final prevText = prevRecord != null
          ? '${prevRecord.data['current'] ?? 0}'
          : (_prevCtrls[s.id]?.text ?? '').trim().replaceAll(',', '.');
      if (prevText.isEmpty) {
        setState(
          () => _fieldErrors['${s.id}_previous'] = 'Nhập chỉ số đầu kỳ lần đầu',
        );
        return;
      }
      final prevNum = num.tryParse(prevText);
      final currNum = num.tryParse(currText);
      if (prevNum == null ||
          currNum == null ||
          !prevNum.isFinite ||
          !currNum.isFinite ||
          prevNum < 0 ||
          currNum < 0) {
        final field = prevNum == null || !prevNum.isFinite || prevNum < 0
            ? 'previous'
            : 'current';
        setState(() => _fieldErrors['${s.id}_$field'] = 'Chỉ số không hợp lệ');
        return;
      }
      if (currNum < prevNum) {
        setState(
          () => _fieldErrors['${s.id}_current'] =
              'Chỉ số mới phải lớn hơn hoặc bằng chỉ số cũ',
        );
        return;
      }
      payloads.add({
        'roomId': roomId,
        'serviceId': s.id,
        'period': _period,
        'previous': prevNum,
        'current': currNum,
      });
    }
    if (payloads.isEmpty) {
      message(context, 'Vui lòng nhập chỉ số mới để lưu');
      return;
    }
    setState(() => _saving = true);
    try {
      for (final data in payloads) {
        await store.command('saveMeter', data: data);
      }
      if (mounted) {
        Navigator.pop(context);
        message(context, 'Đã lưu chỉ số lên Firebase');
      }
    } catch (e) {
      if (mounted) message(context, errorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final periods = _recentPeriods(12);
    if (!periods.contains(_period)) periods.insert(0, _period);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FA),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 30, color: ink),
          onPressed: () => Navigator.maybePop(context),
        ),
        titleSpacing: 0,
        title: const Text(
          'Nhập chỉ số',
          style: TextStyle(
            color: ink,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: RecordsView(
        collection: 'services',
        builder: (_, allServices) => RecordsView(
          collection: 'meters',
          field: 'roomId',
          equals: widget.room.id,
          builder: (_, meters) {
            final assignedIds = widget.room.strings('serviceIds').toSet();
            final assigned = allServices
                .where((s) => !s.archived && assignedIds.contains(s.id))
                .toList();
            final serviceOrder = widget.room.strings('serviceIds');
            assigned.sort(
              (a, b) => serviceOrder
                  .indexOf(a.id)
                  .compareTo(serviceOrder.indexOf(b.id)),
            );
            final meterServices = assigned
                .where((s) => s.text('mode') == 'meter')
                .toList();
            final fixedServices = assigned
                .where((s) => s.text('mode') != 'meter')
                .toList();
            _syncControllers(meterServices, meters);
            final people = widget.room.number('people') ?? 0;

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF168BFF),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Phòng',
                                  style: TextStyle(color: muted, fontSize: 11),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.room.name,
                                  style: const TextStyle(
                                    color: ink,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Tháng',
                                  style: TextStyle(color: muted, fontSize: 11),
                                ),
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _period,
                                    isDense: true,
                                    iconSize: 0,
                                    dropdownColor: Colors.white,
                                    icon: const SizedBox.shrink(),
                                    style: const TextStyle(
                                      color: ink,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    items: [
                                      for (final p in periods)
                                        DropdownMenuItem(
                                          value: p,
                                          child: Text(_displayMonth(p)),
                                        ),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() {
                                          _period = v;
                                          _hydratedKey = '';
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      if (assigned.isEmpty)
                        empty('Phòng chưa áp dụng dịch vụ nào'),
                      for (final s in meterServices)
                        Builder(
                          builder: (context) {
                            final prevRecord = _latestMeterBefore(
                              meters,
                              s.id,
                              _period,
                            );
                            final prevCtrl = _prevCtrls[s.id]!;
                            final currCtrl = _currCtrls[s.id]!;
                            final prevNum = num.tryParse(
                              prevCtrl.text.trim().replaceAll(',', '.'),
                            );
                            final currNum = num.tryParse(
                              currCtrl.text.trim().replaceAll(',', '.'),
                            );
                            final price = s.number('price') ?? 0;
                            final usage =
                                (prevNum != null &&
                                    currNum != null &&
                                    currNum >= prevNum)
                                ? (currNum - prevNum)
                                : null;
                            final unit = s.text('unit');

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      serviceBadge(
                                        s.name,
                                        mode: 'meter',
                                        size: 34,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              s.name,
                                              style: const TextStyle(
                                                color: ink,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            const Text(
                                              'Theo chỉ số',
                                              style: TextStyle(
                                                color: muted,
                                                fontSize: 10.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'Đơn giá',
                                            style: TextStyle(
                                              color: muted,
                                              fontSize: 10,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${money(price)}/$unit',
                                            style: const TextStyle(
                                              color: ink,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'Chỉ số cũ',
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F7FA),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: line),
                                    ),
                                    child: Row(
                                      children: [
                                        if (prevRecord != null) ...[
                                          const Icon(
                                            Icons.auto_awesome_rounded,
                                            color: blue,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Expanded(
                                          child: prevRecord != null
                                              ? Text(
                                                  prevCtrl.text,
                                                  style: const TextStyle(
                                                    color: ink,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                )
                                              : TextField(
                                                  controller: prevCtrl,
                                                  keyboardType:
                                                      const TextInputType.numberWithOptions(
                                                        decimal: true,
                                                      ),
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter.allow(
                                                      RegExp(r'^\d*[.,]?\d*$'),
                                                    ),
                                                  ],
                                                  onChanged: (_) => setState(
                                                    () => _fieldErrors.remove(
                                                      '${s.id}_previous',
                                                    ),
                                                  ),
                                                  style: const TextStyle(
                                                    color: ink,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  decoration: const InputDecoration(
                                                    hintText:
                                                        'Nhập chỉ số đầu kỳ lần đầu',
                                                    border: InputBorder.none,
                                                    isDense: true,
                                                    contentPadding:
                                                        EdgeInsets.zero,
                                                  ),
                                                ),
                                        ),
                                        if (prevRecord != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            child: Text(
                                              'Tự lấy từ ${_displayMonth(prevRecord.text('period'))}',
                                              style: const TextStyle(
                                                color: muted,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        Text(
                                          unit,
                                          style: const TextStyle(
                                            color: muted,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_fieldErrors['${s.id}_previous'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        _fieldErrors['${s.id}_previous']!,
                                        style: const TextStyle(
                                          color: Color(0xFFB91C1C),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Chỉ số mới',
                                    style: TextStyle(
                                      color: ink,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFD1D6E0),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: currCtrl,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                RegExp(r'^\d*[.,]?\d*$'),
                                              ),
                                            ],
                                            onChanged: (_) => setState(
                                              () => _fieldErrors.remove(
                                                '${s.id}_current',
                                              ),
                                            ),
                                            style: const TextStyle(
                                              color: ink,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            decoration: const InputDecoration(
                                              hintText: 'Nhập số trên đồng hồ',
                                              hintStyle: TextStyle(
                                                color: Color(0xFF94A3B8),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w400,
                                              ),
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          unit,
                                          style: const TextStyle(
                                            color: muted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_fieldErrors['${s.id}_current'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        _fieldErrors['${s.id}_current']!,
                                        style: const TextStyle(
                                          color: Color(0xFFB91C1C),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            const Text(
                                              'Số tiêu thụ  ',
                                              style: TextStyle(
                                                color: muted,
                                                fontSize: 10.5,
                                              ),
                                            ),
                                            Flexible(
                                              child: Text(
                                                usage == null
                                                    ? 'Tự động tính'
                                                    : '$usage $unit',
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: usage == null
                                                      ? const Color(0xFF8C9CB0)
                                                      : ink,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            const Text(
                                              'Thành tiền  ',
                                              style: TextStyle(
                                                color: muted,
                                                fontSize: 10.5,
                                              ),
                                            ),
                                            Flexible(
                                              child: Text(
                                                usage == null
                                                    ? 'Tự động tính'
                                                    : money(usage * price),
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: usage == null
                                                      ? const Color(0xFF8C9CB0)
                                                      : ink,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      for (final s in fixedServices)
                        Builder(
                          builder: (context) {
                            final isPerson = s.text('mode') == 'person';
                            final price = s.number('price') ?? 0;
                            final amount = isPerson ? price * people : price;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      serviceBadge(
                                        s.name,
                                        mode: s.text('mode'),
                                        size: 34,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              s.name,
                                              style: const TextStyle(
                                                color: ink,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${label(s.text('mode'))}  •  ${money(price)}/${s.text('unit')}',
                                              style: const TextStyle(
                                                color: muted,
                                                fontSize: 10.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!isPerson)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            const Text(
                                              'Thành tiền',
                                              style: TextStyle(
                                                color: muted,
                                                fontSize: 10,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              money(amount),
                                              style: const TextStyle(
                                                color: ink,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  if (isPerson) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Text(
                                          'Số người',
                                          style: TextStyle(
                                            color: muted,
                                            fontSize: 10.5,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Container(
                                          width: 64,
                                          height: 32,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF5F7FA),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            '$people',
                                            style: const TextStyle(
                                              color: ink,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        const Text(
                                          'Thành tiền  ',
                                          style: TextStyle(
                                            color: muted,
                                            fontSize: 10.5,
                                          ),
                                        ),
                                        Text(
                                          money(amount),
                                          style: const TextStyle(
                                            color: ink,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                if (meterServices.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _saving
                            ? null
                            : () => _saveAll(
                                widget.room.id,
                                meterServices,
                                meters,
                              ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1C61EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
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
                            : const Text('Lưu chỉ số'),
                      ),
                    ),
                  ),
                if (widget.onNavigate != null)
                  RrmsBottomBar(
                    selectedIndex: 2,
                    onTap: (index) {
                      Navigator.of(context).pop();
                      widget.onNavigate?.call(index);
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Dùng chung tại Chi tiết phòng > Dịch vụ và Tổng quan.
class RoomServices extends StatelessWidget {
  final Record room;
  final bool compact;
  const RoomServices({super.key, required this.room, this.compact = false});

  Future<void> _assign(BuildContext context, List<Record> all) async {
    final picked = room.strings('serviceIds').toSet();
    final result = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Dịch vụ áp dụng cho phòng',
            style: TextStyle(
              color: ink,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (all.isEmpty)
                    const Text('Tạo dịch vụ trong danh mục trước'),
                  for (final s in all)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: blue,
                      title: Text(
                        s.name,
                        style: const TextStyle(
                          color: ink,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${money(s.data['price'])}/${s.text('unit')} · ${label(s.text('mode'))}',
                        style: const TextStyle(color: muted, fontSize: 11.5),
                      ),
                      value: picked.contains(s.id),
                      onChanged: (v) => refresh(() {
                        v == true ? picked.add(s.id) : picked.remove(s.id);
                      }),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, picked.toList()),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (result != null && context.mounted) {
      await perform(
        context,
        () => store.command(
          'assignServices',
          args: {'roomId': room.id, 'serviceIds': result},
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => RecordsView(
    collection: 'services',
    builder: (_, all) {
      final active = all.where((s) => !s.archived).toList();
      final assigned = all
          .where((s) => room.strings('serviceIds').contains(s.id))
          .toList();
      if (compact) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (assigned.isEmpty)
              const Text(
                'Chưa áp dụng dịch vụ nào',
                style: TextStyle(color: muted, fontSize: 12.5),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final s in assigned) serviceChipPill(s.name)],
              ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _assign(context, active),
              child: const Text(
                '+ Chọn / bỏ dịch vụ',
                style: TextStyle(
                  color: blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (assigned.isEmpty) empty('Chưa áp dụng dịch vụ nào'),
          for (final s in assigned)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: line, width: 0.7),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _assign(context, active),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 13,
                  ),
                  child: Row(
                    children: [
                      serviceBadge(s.name, mode: s.text('mode'), size: 34),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.name,
                              style: const TextStyle(
                                color: ink,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              label(s.text('mode')),
                              style: const TextStyle(
                                color: muted,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${money(s.data['price'])}/${s.text('unit')}',
                        style: const TextStyle(
                          color: ink,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: muted,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => _assign(context, active),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: line, width: 0.8),
              ),
              child: const Text(
                '+  Thêm dịch vụ',
                style: TextStyle(
                  color: blue,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class MeterRoomForm extends StatefulWidget {
  final Record room;
  const MeterRoomForm({super.key, required this.room});
  @override
  State<MeterRoomForm> createState() => _MeterRoomFormState();
}

class _MeterRoomFormState extends State<MeterRoomForm> {
  String period = periodOf();
  @override
  Widget build(BuildContext context) {
    final periods = _recentPeriods(12);
    if (!periods.contains(period)) periods.insert(0, period);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: line, width: 0.7),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: period,
              isExpanded: true,
              dropdownColor: Colors.white,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: muted,
                size: 20,
              ),
              style: const TextStyle(
                color: ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
              items: [
                for (final p in periods)
                  DropdownMenuItem(
                    value: p,
                    child: Text('Kỳ sử dụng: ${_displayMonth(p)}'),
                  ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => period = v);
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        RecordsView(
          collection: 'services',
          builder: (_, all) {
            final services = all
                .where(
                  (s) =>
                      !s.archived &&
                      s.text('mode') == 'meter' &&
                      widget.room.strings('serviceIds').contains(s.id),
                )
                .toList();
            return RecordsView(
              collection: 'meters',
              field: 'roomId',
              equals: widget.room.id,
              builder: (_, meters) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (services.isEmpty)
                    empty('Phòng chưa áp dụng dịch vụ theo chỉ số'),
                  for (final s in services)
                    Builder(
                      builder: (context) {
                        final saved = meters
                            .where(
                              (m) =>
                                  m.text('period') == period &&
                                  m.text('serviceId') == s.id,
                            )
                            .firstOrNull;
                        final prev = _latestMeterBefore(meters, s.id, period);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: line, width: 0.7),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 2,
                            ),
                            leading: serviceBadge(
                              s.name,
                              mode: 'meter',
                              size: 34,
                            ),
                            title: Text(
                              s.name,
                              style: const TextStyle(
                                color: ink,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              saved == null
                                  ? 'Chưa nhập chỉ số'
                                  : '${saved.number('previous')} → ${saved.number('current')} · ${saved.number('usage')} ${s.text('unit')}',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 11.5,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.edit_outlined,
                              color: blue,
                              size: 18,
                            ),
                            onTap: () => openPage(
                              context,
                              MeterInputPage(
                                room: widget.room,
                                service: s,
                                period: period,
                                meter: saved,
                                previous: prev,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  if (services.isNotEmpty)
                    OutlinedButton(
                      onPressed: () => openPage(
                        context,
                        RoomMeterEntryPage(
                          room: widget.room,
                          initialPeriod: period,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: blue,
                        side: const BorderSide(color: blue, width: 0.9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Mở bảng nhập chỉ số đầy đủ'),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

num? _initialRoomReadingForService(Record room, Record service) {
  final sName = service.name.toLowerCase();
  if (sName.contains('điện') || sName.contains('dien')) {
    return room.number('initialElectric');
  }
  if (sName.contains('nước') || sName.contains('nuoc')) {
    return room.number('initialWater');
  }
  return null;
}

class MeterInputPage extends StatelessWidget {
  final Record room, service;
  final Record? meter, previous;
  final String period;
  const MeterInputPage({
    super.key,
    required this.room,
    required this.service,
    required this.period,
    this.meter,
    this.previous,
  });
  @override
  Widget build(BuildContext context) => EditForm(
    title: '${room.name} · ${service.name} · $period',
    subtitle:
        'Nhập chỉ số cũ và chỉ số mới cho dịch vụ ${service.name} (${service.text('unit')}). Tiêu thụ = chỉ số mới − chỉ số cũ.',
    action: 'saveMeter',
    submitLabel: 'Lưu chỉ số',
    initial: {
      'previous':
          previous?.data['current'] ??
          meter?.data['previous'] ??
          _initialRoomReadingForService(room, service) ??
          '',
      'current': meter?.data['current'] ?? '',
    },
    fixed: {'roomId': room.id, 'serviceId': service.id, 'period': period},
    fields: [
      FieldSpec(
        'previous',
        'Chỉ số cũ',
        number: true,
        readOnly: previous != null,
        decimal: true,
        min: 0,
      ),
      const FieldSpec(
        'current',
        'Chỉ số mới',
        number: true,
        decimal: true,
        min: 0,
      ),
    ],
  );
}
