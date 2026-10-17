import 'package:flutter/material.dart';

import 'room_page.dart';
import 'room_edit_page.dart';
import 'tenant_detail_page.dart';
import 'service_page.dart';
import 'invoice_detail_page.dart';
import '../data/mock_data.dart';

class RoomDetailPage extends StatefulWidget {
  final Map<String, String> room;
  final int initialTab;
  const RoomDetailPage({super.key, required this.room, this.initialTab = 0});
  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  late int tab;
  @override
  void initState() {
    super.initState();
    tab = widget.initialTab.clamp(0, 3).toInt();
  }

  Widget card(Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: child,
  );
  Widget heading(String s) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      s,
      style: const TextStyle(
        color: ink,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: canvas,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.chevron_left, color: ink),
                      ),
                      Expanded(
                        child: Text(
                          widget.room['name']!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ink,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz, color: ink),
                        onSelected: (_) => _edit(),
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Chỉnh sửa phòng'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 70),
                        Row(
                          children: List.generate(
                            4,
                            (i) => Expanded(
                              child: InkWell(
                                onTap: () => setState(() => tab = i),
                                child: Column(
                                  children: [
                                    Text(
                                      [
                                        'Tổng quan',
                                        'Người thuê',
                                        'Dịch vụ',
                                        'Hóa đơn',
                                      ][i],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: tab == i ? blue : muted,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      height: 2,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      color: tab == i
                                          ? blue
                                          : Colors.transparent,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 48, 14, 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (tab == 0) ...[
                                heading('Thông tin phòng'),
                                infoRow(
                                  'Diện tích',
                                  widget.room['area']!.replaceAll('m²', ' m²'),
                                ),
                                infoRow('Giá thuê', widget.room['price']!),
                                infoRow(
                                  'Tiền cọc',
                                  widget.room['deposit'] ??
                                      widget.room['price']!.split('/').first,
                                ),
                                infoRow(
                                  'Ngày chốt tiền',
                                  widget.room['billingDay'] ?? '05 hàng tháng',
                                ),
                                infoRow(
                                  'Mô tả',
                                  widget.room['description'] ??
                                      'Phòng thoáng, có cửa sổ',
                                ),
                              ],
                              if (tab == 1) ...[
                                heading('Người thuê'),
                                for (final t in tenantList.where(
                                  (t) => t['room']!.contains(
                                    widget.room['name']!.replaceAll('P.', ''),
                                  ),
                                ))
                                  tenant(
                                    t['initial'] ?? 'N',
                                    t['name']!,
                                    t['memberRole'] ?? 'Thành viên',
                                    t['phone']!,
                                  ),
                                if (!tenantList.any(
                                  (t) => t['room']!.contains(
                                    widget.room['name']!.replaceAll('P.', ''),
                                  ),
                                ))
                                  const Text('Chưa có người thuê'),
                              ],
                              if (tab == 2) ...[
                                heading('Dịch vụ'),
                                for (final s in serviceList)
                                  service(
                                    s['name']!.substring(0, 1),
                                    s['name']!,
                                    s['mode']!,
                                    '${money(s['price'])}/${s['unit']}',
                                    blue,
                                  ),
                                TextButton(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ServicePage(),
                                      ),
                                    );
                                    if (mounted) setState(() {});
                                  },
                                  child: const Text('+ Thêm dịch vụ'),
                                ),
                              ],
                              if (tab == 3) ...[
                                heading('Hóa đơn'),
                                for (final b in invoiceList.where(
                                  (b) => b['room'] == widget.room['name'],
                                ))
                                  invoice(
                                    b['id']!,
                                    b['period']!,
                                    b['price']!,
                                    b['status'] == 'Đã thanh toán',
                                  ),
                                if (!invoiceList.any(
                                  (b) => b['room'] == widget.room['name'],
                                ))
                                  const Text('Chưa có hóa đơn'),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (tab == 0) ...[
                    const SizedBox(height: 6),
                    card(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          heading('Dịch vụ áp dụng'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              serviceChip('Điện', blue),
                              serviceChip('Nước', const Color(0xFF00A2BE)),
                              serviceChip('WiFi', const Color(0xFF8F35FF)),
                              serviceChip('Rác', const Color(0xFFFF781E)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 74),
                    const Center(
                      child: Text(
                        'ẢNH PHÒNG',
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AppBottomBar(selected: 0, onRooms: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget serviceChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color)),
    );
  }

  Future<void> _edit() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => RoomEditPage(
          room: widget.room,
          usedNames: roomList
              .where((r) => r != widget.room)
              .map((r) => r['name']!)
              .toList(),
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => widget.room.addAll(result));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã lưu thông tin phòng')));
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: muted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: ink,
                fontSize: 12,
                fontWeight: label == 'Mô tả'
                    ? FontWeight.normal
                    : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget tenant(String letter, String name, String role, String phone) => card(
    Row(
      children: [
        CircleAvatar(
          backgroundColor: blue,
          child: Text(letter, style: const TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(role, style: const TextStyle(fontSize: 10, color: blue)),
              Text(
                '${widget.room['name']}  •  $phone',
                style: const TextStyle(fontSize: 10, color: muted),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () async {
            final t = tenantList.firstWhere((t) => t['name'] == name);
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TenantDetailPage(tenant: t)),
            );
            if (mounted) setState(() {});
          },
          icon: const Icon(Icons.chevron_right, color: muted),
        ),
      ],
    ),
  );
  Widget service(
    String symbol,
    String name,
    String mode,
    String price,
    Color color,
  ) => card(
    Row(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: color,
          child: Text(
            symbol,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(mode, style: const TextStyle(fontSize: 10, color: muted)),
            ],
          ),
        ),
        Text(
          price,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        IconButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ServicePage()),
            );
            if (mounted) setState(() {});
          },
          icon: const Icon(Icons.chevron_right, size: 17, color: muted),
        ),
      ],
    ),
  );
  Future<void> _openInvoice(String id) async {
    final bill = invoiceList.firstWhere((b) => b['id'] == id);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InvoiceDetailPage(invoice: bill)),
    );
    if (mounted) setState(() {});
  }

  Widget invoice(String id, String period, String amount, bool paid) => InkWell(
    onTap: () => _openInvoice(id),
    child: card(
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  id,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  period,
                  style: const TextStyle(fontSize: 10, color: muted),
                ),
                const SizedBox(height: 8),
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (paid)
                  const Text(
                    'QR • Chuyển khoản',
                    style: TextStyle(fontSize: 10, color: muted),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: paid
                      ? const Color(0xFFE8FAF0)
                      : const Color(0xFFFFF1E8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  paid ? 'Đã thanh toán' : 'Chưa thanh toán',
                  style: TextStyle(
                    fontSize: 10,
                    color: paid ? Colors.green : Colors.deepOrange,
                  ),
                ),
              ),
              if (!paid)
                Padding(
                  padding: const EdgeInsets.only(top: 13),
                  child: FilledButton(
                    onPressed: () => _openInvoice(id),
                    style: FilledButton.styleFrom(
                      backgroundColor: blue,
                      minimumSize: const Size(75, 27),
                    ),
                    child: const Text(
                      'Thanh toán',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
