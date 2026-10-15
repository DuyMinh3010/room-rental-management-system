import 'package:flutter/material.dart';

import 'room_detail_page.dart';
import 'room_edit_page.dart';
import 'service_page.dart';
import 'tenant_list_page.dart';
import 'invoice_page.dart';
import 'maintenance_page.dart';
import 'contract_page.dart';
import 'account_page.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
const blue = Color(0xFF2463F5);
const ink = Color(0xFF172033);
const muted = Color(0xFF61738E);
const canvas = Color(0xFFF6F7F9);
// Danh sách phòng dùng chung cho các màn hình khác
List<Map<String, String>> roomList = [];

class RoomPage extends StatefulWidget {
  const RoomPage({super.key});
  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  int filter = 0;
  String query = '';

  final CollectionReference<Map<String, dynamic>> _roomsRef =
  FirebaseFirestore.instance.collection('rooms');

  List<Map<String, String>> rooms = [];

  late final StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
  _roomsSubscription;

  @override
  void initState() {
    super.initState();

    _roomsSubscription = _roomsRef.snapshots().listen(
          (snapshot) {
        final loadedRooms = snapshot.docs.map((doc) {
          final data = doc.data();

          return <String, String>{
            '_docId': doc.id,
            'name': (data['name'] ?? data['roomName'] ?? doc.id).toString(),
            'status': (data['status'] ?? 'Trống').toString(),
            'price': _formatPrice(data['price']),
            'area': _formatArea(data['area']),
            'people': _formatPeople(data['people']),
            'deposit': _formatDeposit(data['deposit']),
            'billingDay': (data['billingDay'] ?? '05 hàng tháng').toString(),
            'description': (data['description'] ?? '').toString(),
          };
        }).toList();

        if (mounted) {
          setState(() {
            rooms = loadedRooms;
            roomList = loadedRooms;
          });
        }
      },
      onError: (Object error) {
        if (mounted) {
          _msg('Không tải được dữ liệu phòng: $error');
        }
      },
    );
  }

  String _formatPrice(dynamic value) {
    if (value == null) return '0đ/tháng';

    if (value is num) {
      return '${value.toStringAsFixed(0)}đ/tháng';
    }

    final text = value.toString();
    return text.contains('đ') ? text : '${text}đ/tháng';
  }

  String _formatArea(dynamic value) {
    if (value == null) return 'Chưa cập nhật';
    final text = value.toString();
    return text.contains('m²') ? text : '${text}m²';
  }

  String _formatPeople(dynamic value) {
    if (value == null) return '0 người';
    if (value is num) return '${value.toInt()} người';
    final text = value.toString();
    return text.contains('người') ? text : '$text người';
  }

  String _formatDeposit(dynamic value) {
    if (value == null) return '0đ';
    if (value is num) return '${value.toStringAsFixed(0)}đ';
    final text = value.toString();
    return text.contains('đ') ? text : '${text}đ';
  }

  void _msg(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
  Future<void> _open(Map<String, String> room, {int tab = 0}) async {
    final oldRoom = Map<String, String>.from(room);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomDetailPage(room: room, initialTab: tab),
      ),
    );
    if (!mounted) return;
    setState(() {
      if (oldRoom.keys.any((key) => oldRoom[key] != room[key])) {
        filter = 0;
        query = '';
        
      }
    });
  }


  Future<void> _edit([Map<String, String>? room]) async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => RoomEditPage(
          room: room,
          usedNames: rooms
              .where((r) => r['_docId'] != room?['_docId'])
              .map((r) => r['name']!)
              .toList(),
        ),
      ),
    );

    if (result == null || !mounted) return;

    int parseMoney(String? value) {
      return int.tryParse(
        (value ?? '').replaceAll(RegExp(r'[^0-9]'), ''),
      ) ??
          0;
    }

    try {
      final data = <String, dynamic>{
        'name': result['name'] ?? '',
        'status': result['status'] ?? 'Trống',
        'price': parseMoney(result['price']),
        'deposit': parseMoney(result['deposit']),
        'area': double.tryParse(
          (result['area'] ?? '')
              .replaceAll('m²', '')
              .replaceAll(',', '.')
              .trim(),
        ) ??
            0,
        'people': int.tryParse(
          (result['people'] ?? '')
              .replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
            0,
        'zone': result['zone'] ?? '',
        'billingDay': result['billingDay'] ?? '05',
        'description': result['description'] ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docId = room?['_docId'];

      if (docId == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await _roomsRef.add(data);
      } else {
        await _roomsRef.doc(docId).update(data);
      }

      if (!mounted) return;

      setState(() {
        filter = 0;
        query = '';

      });

      _msg(docId == null
          ? 'Đã thêm phòng lên Firebase'
          : 'Đã cập nhật phòng trên Firebase');
    } catch (e) {
      if (!mounted) return;
      _msg('Không thể lưu phòng lên Firebase: $e');
    }
  }

  @override
  void dispose() {
    _roomsSubscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const statuses = ['Tất cả', 'Đang có người', 'Trống', 'Đang sửa'];
    const labels = ['Tất cả', 'Đang cho thuê', 'Trống', 'Đang sửa'];
    final shown = rooms
        .where(
          (r) =>
              (filter == 0 || r['status'] == statuses[filter]) &&
              r['name']!.toLowerCase().contains(query.trim().toLowerCase()),
        )
        .toList();
    return Scaffold(
      backgroundColor: canvas,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Danh sách phòng',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ink,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 26,
                        child: FilledButton(
                          onPressed: () => _edit(),
                          style: FilledButton.styleFrom(
                            backgroundColor: blue,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          child: const Text(
                            '+ Thêm',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(

                    onChanged: (v) => setState(() => query = v),
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm phòng...',
                      hintStyle: const TextStyle(color: muted, fontSize: 12),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 15,
                        color: muted,
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 28),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        4,
                        (i) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => setState(() => filter = i),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: filter == i ? blue : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                labels[i],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: filter == i ? Colors.white : muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (shown.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('Không tìm thấy phòng')),
                    ),
                  ...shown.map(roomCard),
                ],
              ),
            ),
            const AppBottomBar(selected: 0),
          ],
        ),
      ),
    );
  }

  Widget roomCard(Map<String, String> room) {
    final status = room['status']!;
    final rented = status == 'Đang có người';
    final color = rented
        ? const Color(0xFF00A344)
        : status == 'Trống'
        ? blue
        : const Color(0xFFF26B13);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: () => _open(room),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 76,
                padding: const EdgeInsets.only(left: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PHÒNG',
                      style: TextStyle(fontSize: 8, color: muted),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      room['name']!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .07),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        rented ? 'Đang cho thuê' : status,
                        style: TextStyle(fontSize: 9, color: color),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      room['price']!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${room['area']}  •  ${room['people']}',
                      style: const TextStyle(fontSize: 10, color: muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}

class AppBottomBar extends StatelessWidget {
  final int selected;
  final VoidCallback? onRooms;
  final bool Function(int)? onSelected;
  const AppBottomBar({
    super.key,
    required this.selected,
    this.onRooms,
    this.onSelected,
  });

  void _go(BuildContext context, int idx) {
    if (onSelected?.call(idx) ?? false) return;
    if (idx == 0 && onRooms != null) {
      onRooms!();
      return;
    }
    if (idx == selected) return;
    final Widget? page = switch (idx) {
      0 => const RoomPage(),
      1 => const TenantListPage(),
      2 => const ServicePage(),
      3 => const InvoicePage(),
      4 => const ContractPage(),
      5 => const MaintenancePage(),
      6 => const AccountPage(),
      _ => null,
    };
    if (page == null) return;
    Navigator.push<void>(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    const labels = [
      'Phòng',
      'Người thuê',
      'Dịch vụ',
      'Hóa đơn',
      'Hợp đồng',
      'Bảo trì',
      'Tài khoản',
    ];
    const icons = [
      Icons.home_outlined,
      Icons.person_outline,
      Icons.circle,
      Icons.receipt_outlined,
      Icons.article_outlined,
      Icons.handyman_outlined,
      Icons.settings_outlined,
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE7EAF0))),
      ),
      child: Row(
        children: List.generate(
          7,
          (i) => Expanded(
            child: InkWell(
              onTap: () => _go(context, i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: selected == i ? const Color(0xFFEAF0FF) : null,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icons[i],
                      size: 15,
                      color: selected == i ? blue : muted,
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 8,
                          color: selected == i ? blue : muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
