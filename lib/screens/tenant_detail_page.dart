import 'dart:convert';

import 'package:flutter/material.dart';

import '../widgets/form_widgets.dart';
import 'room_page.dart';
import 'tenant_edit_page.dart';
import 'contract_detail_page.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class TenantDetailPage extends StatefulWidget {
  final Map<String, String> tenant;
  final bool full;
  const TenantDetailPage({super.key, required this.tenant, this.full = false});
  @override
  State<TenantDetailPage> createState() => _TenantDetailPageState();
}

class _TenantDetailPageState extends State<TenantDetailPage> {
  Future<void> _edit() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => TenantEditPage(tenant: widget.tenant)),
    );
    if (!mounted || result == null) return;
    setState(() => widget.tenant.addAll(result));
  }

  Future<void> _contract() async {
    try {
      final contracts = FirebaseFirestore.instance.collection('contracts');

      final contractId = (widget.tenant['contract'] ?? '').trim();
      final tenantName = (widget.tenant['name'] ?? '').trim();

      QuerySnapshot<Map<String, dynamic>> result;

      // Ưu tiên tìm bằng mã hợp đồng đã lưu trong thông tin người thuê.
      if (contractId.isNotEmpty) {
        result = await contracts
            .where('id', isEqualTo: contractId)
            .limit(1)
            .get();
      } else {
        result = await contracts.limit(0).get();
      }

      // Nếu chưa tìm thấy theo mã, tìm theo tên người thuê.
      if (result.docs.isEmpty && tenantName.isNotEmpty) {
        result = await contracts.where('name', isEqualTo: tenantName).get();
      }

      if (!mounted) return;

      if (result.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chưa tìm thấy hợp đồng của người thuê này trên Firebase.',
            ),
          ),
        );
        return;
      }

      // Nếu có nhiều hợp đồng, ưu tiên hợp đồng đúng phòng.
      final tenantRoom = (widget.tenant['room'] ?? '').trim();

      final matchingDocs = result.docs.where((doc) {
        final data = doc.data();
        return (data['room'] ?? '').toString().trim() == tenantRoom;
      }).toList();

      final selectedDoc = matchingDocs.isNotEmpty
          ? matchingDocs.first
          : result.docs.first;

      final data = selectedDoc.data();

      final contract = data.map<String, String>(
        (key, value) => MapEntry(
          key,
          value == null
              ? ''
              : value is List || value is Map
              ? jsonEncode(value)
              : value.toString(),
        ),
      );

      // Đảm bảo mã hợp đồng được lấy từ dữ liệu Firebase.
      contract['id'] = (data['id'] ?? '').toString();
      contract['documentId'] = selectedDoc.id;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ContractDetailPage(contract: contract),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không thể tải hợp đồng: $e')));
    }
  }

  String money(String? value) {
    if (value == null || value.trim().isEmpty) return '0 đ';

    final amount = double.tryParse(value.replaceAll(',', '').trim()) ?? 0;
    final number = amount.toInt().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < number.length; i++) {
      buffer.write(number[i]);

      final remaining = number.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }

    return '${buffer.toString()} đ';
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tenant;
    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        title: Text(
          widget.full ? 'Thông tin chi tiết' : 'Thông tin thuê phòng',
        ),
        actions: [TextButton(onPressed: _edit, child: const Text('Chỉnh sửa'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InfoCard(
            title: t['name'] ?? '',
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: blue,
                child: Icon(Icons.person, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 12),
              Text(t['room'] ?? '', textAlign: TextAlign.center),
              Text(
                t['status'] ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.green),
              ),
              InfoLine(
                'Hợp đồng thuê',
                t['contractPeriod'] ?? t['contract'] ?? '',
              ),
            ],
          ),
          if (widget.full)
            InfoCard(
              title: 'Thông tin khách thuê',
              children: [
                InfoLine('Họ và tên', t['name'] ?? ''),
                InfoLine('Ngày sinh', t['birthday'] ?? ''),
                InfoLine('Giới tính', t['gender'] ?? ''),
                InfoLine('Số điện thoại', t['phone'] ?? ''),
                InfoLine('Email', t['email'] ?? ''),
                InfoLine('Quê quán', t['address'] ?? ''),
                InfoLine('Nghề nghiệp', t['job'] ?? ''),
                InfoLine('Đăng ký tạm trú', t['residence'] ?? ''),
                InfoLine('CCCD/Passport', t['identity'] ?? ''),
                InfoLine('Ghi chú', t['note'] ?? ''),
              ],
            )
          else ...[
            InfoCard(
              title: 'Thông tin liên hệ',
              children: [
                InfoLine('Số điện thoại', t['phone'] ?? ''),
                InfoLine('Email', t['email'] ?? ''),
                InfoLine('CCCD', t['identity'] ?? ''),
                TextButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TenantDetailPage(tenant: t, full: true),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                  child: const Text('Xem chi tiết →'),
                ),
              ],
            ),
            InfoCard(
              title: 'Thông tin thuê phòng',
              children: [
                InfoLine('Tiền phòng', '${money(t['rent'])} / tháng'),
                InfoLine('Tiền đặt cọc', money(t['deposit'])),
                InfoLine('Ngày bắt đầu', t['start'] ?? ''),
                InfoLine('Ngày kết thúc', t['end'] ?? ''),
                TextButton(
                  onPressed: _contract,
                  child: const Text('Xem hợp đồng →'),
                ),
              ],
            ),
          ],
        ],
      ),
      bottomNavigationBar: const AppBottomBar(selected: 1),
    );
  }
}
