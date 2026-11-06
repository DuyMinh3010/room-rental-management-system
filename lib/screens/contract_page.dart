import 'package:flutter/material.dart';

import '../models/record.dart';
import '../widgets/common.dart';
import 'contract_detail_page.dart';
import 'contract_edit_page.dart';

bool _isExpiringSoon(Record c) {
  final status = c.text('status');
  if (status == 'scheduled' || status == 'expired') return true;
  if (status != 'active') return false;
  final end = DateTime.tryParse(c.text('endDate'));
  if (end == null) return false;
  final now = DateTime.now().toUtc().add(const Duration(hours: 7));
  final days = end.difference(DateTime(now.year, now.month, now.day)).inDays;
  return days <= 30;
}

class ContractPage extends StatefulWidget {
  const ContractPage({super.key});
  @override
  State<ContractPage> createState() => _ContractPageState();
}

class _ContractPageState extends State<ContractPage> {
  String query = '', filter = 'all';

  Widget _coloredFilterPill({
    required String id,
    required String text,
    required Color bg,
    required Color fg,
  }) {
    final selected = filter == id;
    return GestureDetector(
      onTap: () => setState(() => filter = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(13),
          border: selected ? Border.all(color: fg, width: 1.3) : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: fg,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _cardStatusPill(Record c) {
    final status = c.text('status');
    final expiring = _isExpiringSoon(c);
    Color bg;
    Color fg;
    String text;
    if (status == 'active' && expiring) {
      bg = const Color(0xFFE9CBCC);
      fg = const Color(0xFFC7070E);
      text = 'Sắp hết hạn';
    } else if (status == 'active') {
      bg = const Color(0xFFB9F1C9);
      fg = const Color(0xFF16A34A);
      text = 'Còn hiệu lực';
    } else if (status == 'scheduled') {
      bg = const Color(0xFFFFF4E5);
      fg = const Color(0xFFD97706);
      text = 'Chưa bắt đầu';
    } else if (status == 'expired') {
      bg = const Color(0xFFE9CBCC);
      fg = const Color(0xFFC7070E);
      text = 'Hết hạn';
    } else {
      bg = const Color(0xFFBDCCE9);
      fg = ink;
      text = 'Đã thanh lý';
    }
    return Container(
      width: 78,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: fg,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => RecordsView(
    collection: 'contracts',
    builder: (_, all) {
      final activeCount = all.where((c) => c.text('status') == 'active').length;
      final expiringCount = all.where(_isExpiringSoon).length;
      final endedCount = all
          .where((c) => ['ended', 'cancelled'].contains(c.text('status')))
          .length;

      final contracts = all.where((c) {
        final matchesQuery =
            '${c.text('number', c.text('id', c.id))} ${c.text('tenantName', c.text('name'))} ${c.text('roomName', c.text('room'))}'
                .toLowerCase()
                .contains(query.toLowerCase());
        if (!matchesQuery) return false;
        if (filter == 'all') return true;
        if (filter == 'active') return c.text('status') == 'active';
        if (filter == 'expiring') return _isExpiringSoon(c);
        if (filter == 'ended') {
          return ['ended', 'cancelled'].contains(c.text('status'));
        }
        return true;
      }).toList()
        ..sort((a, b) => b.text('startDate').compareTo(a.text('startDate')));

      return Scaffold(
        backgroundColor: canvas,
        appBar: AppBar(
          backgroundColor: canvas,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hợp đồng',
                style: TextStyle(
                  color: ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${all.length} hợp đồng · $activeCount còn hiệu lực',
                style: const TextStyle(
                  color: muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          actions: [
            Center(
              child: figmaPrimaryPillButton(
                label: '+ Tạo mới',
                soft: true,
                onTap: () => openPage(context, const ContractEditPage()),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          children: [
            TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: searchDecoration(
                'Tìm theo số hợp đồng, người thuê hoặc phòng...',
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _coloredFilterPill(
                    id: 'all',
                    text: 'Tất cả ${all.length}',
                    bg: softBlue,
                    fg: blue,
                  ),
                  const SizedBox(width: 8),
                  _coloredFilterPill(
                    id: 'active',
                    text: 'Còn hiệu lực $activeCount',
                    bg: const Color(0xFFB9F1C9),
                    fg: const Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 8),
                  _coloredFilterPill(
                    id: 'expiring',
                    text: 'Sắp hết hạn $expiringCount',
                    bg: const Color(0xFFF3D5D5),
                    fg: const Color(0xFFC7070E),
                  ),
                  const SizedBox(width: 8),
                  _coloredFilterPill(
                    id: 'ended',
                    text: 'Đã thanh lý $endedCount',
                    bg: const Color(0xFFBDCCE9),
                    fg: ink,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (contracts.isEmpty) empty('Chưa có hợp đồng'),
            for (final c in contracts)
              Builder(
                builder: (context) {
                  final canEnd = [
                    'active',
                    'scheduled',
                  ].contains(c.text('status'));
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: line, width: 0.7),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => openPage(
                        context,
                        ContractDetailPage(contractId: c.id),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: softBlue,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.description_outlined,
                                color: blue,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.text('number', c.text('id', c.id)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: ink,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${c.text('tenantName', c.text('name'))}  •  ${c.text('roomName', c.text('room'))}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Thuê : ${money(c.data['rent'])}/tháng',
                                    style: const TextStyle(
                                      color: ink,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _cardStatusPill(c),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () => openPage(
                                    context,
                                    ContractDetailPage(contractId: c.id),
                                  ),
                                  child: Container(
                                    width: 78,
                                    height: 26,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1C54C4),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: const Text(
                                      'Chi tiết',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                if (canEnd) ...[
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () async {
                                      if (await confirm(
                                            context,
                                            'Kết thúc / thanh lý hợp đồng ${c.text('number', c.id)}? Hóa đơn còn nợ phải được xử lý trước.',
                                          ) &&
                                          context.mounted) {
                                        await perform(
                                          context,
                                          () => store.command(
                                            'endContract',
                                            id: c.id,
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      width: 78,
                                      height: 26,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFBDCCE9),
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: const Text(
                                        'Thanh lý',
                                        style: TextStyle(
                                          color: Color(0xFF3C4558),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      );
    },
  );
}
