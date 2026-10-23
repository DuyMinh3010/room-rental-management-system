import 'dart:convert';

import 'package:flutter/material.dart';

import '../utils/formatters.dart';
import '../widgets/form_widgets.dart';
import 'room_page.dart';
import 'contract_edit_page.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class ContractDetailPage extends StatefulWidget {
  final Map<String, String> contract;
  const ContractDetailPage({super.key, required this.contract});
  @override
  State<ContractDetailPage> createState() => _ContractDetailPageState();
}

class _ContractDetailPageState extends State<ContractDetailPage> {
  Future<void> _saveContractToFirebase({
    required Map<String, dynamic> updates,
  }) async {
    final contracts = FirebaseFirestore.instance.collection('contracts');
    final documentId = (widget.contract['documentId'] ?? '').trim();
    final id = (widget.contract['id'] ?? '').trim();

    DocumentReference<Map<String, dynamic>> contractRef;
    if (documentId.isNotEmpty) {
      contractRef = contracts.doc(documentId);
    } else {
      if (id.isEmpty) {
        throw Exception('Không tìm thấy mã hợp đồng');
      }

      final result = await contracts.where('id', isEqualTo: id).limit(1).get();

      if (result.docs.isEmpty) {
        throw Exception('Không tìm thấy hợp đồng trên Firebase');
      }
      contractRef = result.docs.first.reference;
      widget.contract['documentId'] = contractRef.id;
    }

    final snapshot = await contractRef.get();
    final data = snapshot.data();
    if (data == null) {
      throw Exception('Không tìm thấy hợp đồng trên Firebase');
    }

    num parseAmount(dynamic value, String field) {
      if (value is num) return value;
      final digits = value.toString().replaceAll(RegExp(r'[^0-9-]'), '');
      final parsed = num.tryParse(digits);
      if (parsed == null) {
        throw Exception('Dữ liệu $field của hợp đồng không hợp lệ');
      }
      return parsed;
    }

    await contractRef.update({
      ...updates,
      'rent': parseAmount(data['rent'], 'tiền thuê'),
      'deposit': parseAmount(data['deposit'], 'tiền cọc'),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _edit() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => ContractEditPage(contract: widget.contract),
      ),
    );

    if (result == null || !mounted) return;

    // ContractEditPage persists the contract and tenant before returning.
    // Do not write the display strings back to Firestore here.
    widget.contract.addAll(result);
    setState(() {});
  }

  List<Map<String, dynamic>> _members() {
    final value = widget.contract['members'];
    if (value == null || value.isEmpty) return [];

    final decoded = jsonDecode(value);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((member) => Map<String, dynamic>.from(member))
        .toList();
  }

  Future<void> _renew() async {
    final parts = (widget.contract['end'] ?? '').split('/');

    final oldEnd = parts.length == 3
        ? DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          )
        : DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: oldEnd.isAfter(DateTime.now())
          ? oldEnd.add(const Duration(days: 1))
          : DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date == null || !mounted) return;

    if (!date.isAfter(oldEnd)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ngày gia hạn phải sau ngày kết thúc cũ')),
      );
      return;
    }

    final oldData = Map<String, String>.from(widget.contract);

    setState(() {
      widget.contract['end'] =
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
      widget.contract['status'] = 'Còn hiệu lực';
    });

    try {
      await _saveContractToFirebase(
        updates: {
          'end': widget.contract['end'],
          'status': widget.contract['status'],
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã gia hạn hợp đồng')));
    } catch (e) {
      widget.contract
        ..clear()
        ..addAll(oldData);

      if (!mounted) return;
      setState(() {});

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi lưu gia hạn: $e')));
    }
  }

  Future<void> _close() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thanh lý hợp đồng?'),
        content: const Text('Hợp đồng sẽ chuyển sang trạng thái đã thanh lý.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Thanh lý'),
          ),
        ],
      ),
    );

    if (yes != true || !mounted) return;

    final oldStatus = widget.contract['status'];

    setState(() {
      widget.contract['status'] = 'Đã thanh lý';
    });

    try {
      await _saveContractToFirebase(
        updates: {'status': widget.contract['status']},
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã thanh lý hợp đồng')));
    } catch (e) {
      widget.contract['status'] = oldStatus ?? '';

      if (!mounted) return;
      setState(() {});

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi thanh lý hợp đồng: $e')));
    }
  }

  void _previewPdf() {
    final c = widget.contract;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xem trước hợp đồng'),
        content: SingleChildScrollView(
          child: Text(
            '${c['id']}\n\nNgười thuê: ${c['name']}\nPhòng: ${c['room']}\n'
            'Thời hạn: ${c['start']} - ${c['end']}\n'
            'Tiền phòng: ${money(c['rent'])}/tháng\nĐặt cọc: ${money(c['deposit'])}\n\n'
            'Bản UI: chức năng tạo file PDF sẽ bổ sung sau.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.contract;
    final closed = c['status'] == 'Đã thanh lý';
    final members = _members();
    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        title: const Text('Chi tiết hợp đồng'),
        actions: [TextButton(onPressed: _edit, child: const Text('Chỉnh sửa'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InfoCard(
            title: c['id']!,
            children: [
              Text(c['name'] ?? ''),
              InfoLine('Phòng', c['room'] ?? ''),
              InfoLine('Thời hạn', '${c['start']} - ${c['end']}'),
              InfoLine('Trạng thái', c['status'] ?? ''),
            ],
          ),
          InfoCard(
            title: 'Thông tin người thuê',
            children: [
              if (members.isEmpty)
                InfoLine('Họ và tên', c['name'] ?? '')
              else
                for (final member in members)
                  InfoLine(
                    (member['role'] ?? 'Thành viên').toString(),
                    (member['name'] ?? '').toString(),
                  ),
              InfoLine('Số điện thoại', c['phone'] ?? ''),
              InfoLine('Email', c['email'] ?? ''),
              InfoLine('CCCD', c['identity'] ?? ''),
            ],
          ),
          InfoCard(
            title: 'Thông tin phòng',
            children: [
              InfoLine('Phòng', c['room'] ?? ''),
              Text(
                c['description'] ?? 'Chưa cập nhật',
                style: TextStyle(color: muted),
              ),
            ],
          ),
          InfoCard(
            title: 'Thanh toán & phí dịch vụ',
            children: [
              InfoLine('Tiền thuê hàng tháng', '${money(c['rent'])}/tháng'),
              InfoLine('Tiền đặt cọc', money(c['deposit'])),
              const InfoLine('Kỳ thanh toán', 'Đóng 1 tháng/lần'),
              const InfoLine('Ngày thanh toán', 'Mùng 5 hàng tháng'),
            ],
          ),
          InfoCard(
            title: 'Ghi chú',
            children: [Text(c['note'] ?? 'Chưa có ghi chú')],
          ),
          InfoCard(
            title: 'Hành động',
            children: [
              if (!closed) ...[
                OutlinedButton(
                  onPressed: _renew,
                  child: const Text('Gia hạn hợp đồng'),
                ),
                OutlinedButton(
                  onPressed: _close,
                  child: const Text('Thanh lý hợp đồng'),
                ),
              ],
              OutlinedButton(
                onPressed: _edit,
                child: const Text('Chỉnh sửa thông tin'),
              ),
              FilledButton(
                onPressed: _previewPdf,
                child: const Text('Xuất file PDF'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
