import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'room_page.dart';
import 'room_edit_page.dart';
import 'service_page.dart';
import 'tenant_detail_page.dart';
import '../utils/formatters.dart';

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

  Widget _tenantList() {
    final roomId = widget.room['_docId'];
    if (roomId == null || roomId.isEmpty) {
      return const Text('Chưa có người thuê');
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('contracts')
          .where('roomId', isEqualTo: roomId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Không tải được người thuê: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final contracts = (snapshot.data?.docs ?? []).where((doc) {
          final status = doc.data()['status'];
          return status == 'Còn hiệu lực' || status == 'Sắp hết hạn';
        }).toList();

        if (contracts.isEmpty) {
          return const Text('Chưa có người thuê');
        }

        return Column(
          children: contracts.expand((doc) {
            final data = doc.data();
            final savedMembers = data['members'];
            final members = savedMembers is List
                ? savedMembers.whereType<Map>().toList()
                : <Map>[];
            final tenants = members.isEmpty
                ? [
                    <String, dynamic>{
                      'name': data['name'] ?? '',
                      'role': data['memberRole'] ?? 'Trưởng phòng',
                      'phone': data['phone'] ?? '',
                      'email': data['email'] ?? '',
                      'identity': data['identity'] ?? '',
                    },
                  ]
                : members;

            return List.generate(tenants.length, (index) {
              final member = tenants[index];
              final name = (member['name'] ?? '').toString();
              final initials = name
                  .trim()
                  .split(RegExp(r'\s+'))
                  .where((part) => part.isNotEmpty)
                  .take(2)
                  .map((part) => part[0].toUpperCase())
                  .join();
              final tenant = <String, String>{
                'id': doc.id,
                'documentId': doc.id,
                'memberIndex': '$index',
                'initial': initials,
                'name': name,
                'room': (data['room'] ?? widget.room['name'] ?? '').toString(),
                'phone': (member['phone'] ?? '').toString(),
                'email': (member['email'] ?? '').toString(),
                'identity': (member['identity'] ?? '').toString(),
                'start': (data['start'] ?? '').toString(),
                'end': (data['end'] ?? '').toString(),
                'contract': (data['id'] ?? '').toString(),
                'rent': (data['rent'] ?? '').toString(),
                'deposit': (data['deposit'] ?? '').toString(),
                'status': data['status'] == 'Còn hiệu lực'
                    ? 'Đang thuê'
                    : 'Sắp hết hạn',
                'memberRole': (member['role'] ?? 'Trưởng phòng').toString(),
              };

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(initials.isEmpty ? '?' : initials),
                  ),
                  title: Text(name),
                  subtitle: Text(
                    '${tenant['memberRole']} · ${tenant['phone']}',
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TenantDetailPage(tenant: tenant),
                      ),
                    );
                  },
                ),
              );
            });
          }).toList(),
        );
      },
    );
  }

  Widget _serviceList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('services').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Không tải được dịch vụ: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final services = (snapshot.data?.docs ?? []).where((doc) {
          return doc.data()['isActive'] != false;
        }).toList();

        if (services.isEmpty) {
          return const Text('Chưa có dịch vụ');
        }

        return Column(
          children: services.map((doc) {
            final data = doc.data();
            final name = (data['name'] ?? '').toString();
            return ListTile(
              leading: CircleAvatar(
                child: Text(name.isEmpty ? '?' : name[0].toUpperCase()),
              ),
              title: Text(name),
              subtitle: Text((data['mode'] ?? 'Theo phòng').toString()),
              trailing: Text(
                '${money(data['price']?.toString())}/'
                '${data['unit'] ?? 'tháng'}',
              ),
            );
          }).toList(),
        );
      },
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
                                  widget.room['description'] ?? 'Chưa cập nhật',
                                ),
                              ],
                              if (tab == 1) ...[
                                heading('Người thuê'),
                                _tenantList(),
                              ],
                              if (tab == 2) ...[
                                heading('Dịch vụ'),
                                _serviceList(),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thông tin phòng đã được cập nhật'),
        backgroundColor: Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
}
