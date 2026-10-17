import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../widgets/form_widgets.dart';
import 'room_page.dart';
import 'contract_edit_page.dart';

class ContractDetailPage extends StatefulWidget {
  final Map<String, String> contract;
  const ContractDetailPage({super.key, required this.contract});
  @override
  State<ContractDetailPage> createState() => _ContractDetailPageState();
}

class _ContractDetailPageState extends State<ContractDetailPage> {
  Future<void> _edit() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => ContractEditPage(contract: widget.contract),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => widget.contract.addAll(result));
  }

  Future<void> _renew() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final parts = (widget.contract['end'] ?? '').split('/');
    final oldEnd = parts.length == 3
        ? DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          )
        : DateTime.now();
    if (!date.isAfter(oldEnd)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ngày gia hạn phải sau ngày kết thúc cũ')),
      );
      return;
    }
    setState(() {
      widget.contract['end'] =
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      widget.contract['status'] = 'Còn hiệu lực';
    });
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
    if (yes == true && mounted)
      setState(() => widget.contract['status'] = 'Đã thanh lý');
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
              InfoLine('Họ và tên', c['name'] ?? ''),
              InfoLine('Số điện thoại', c['phone'] ?? ''),
              InfoLine('Email', c['email'] ?? ''),
              InfoLine('CCCD', c['identity'] ?? ''),
            ],
          ),
          InfoCard(
            title: 'Thông tin phòng',
            children: [
              InfoLine('Phòng', c['room'] ?? ''),
              const Text(
                'Phòng khép kín, có cửa sổ',
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
              for (final s in serviceList)
                InfoLine(s['name']!, '${money(s['price'])}/${s['unit']}'),
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
