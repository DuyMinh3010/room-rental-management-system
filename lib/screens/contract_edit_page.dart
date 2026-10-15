import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../widgets/form_widgets.dart';

class ContractEditPage extends StatefulWidget {
  final Map<String, String>? contract;
  const ContractEditPage({super.key, this.contract});
  @override
  State<ContractEditPage> createState() => _ContractEditPageState();
}

class _ContractEditPageState extends State<ContractEditPage> {
  final formKey = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  final labels = const {
    'id': 'Số hợp đồng',
    'name': 'Người thuê',
    'room': 'Phòng',
    'phone': 'Số điện thoại',
    'email': 'Email',
    'identity': 'CCCD/Passport',
    'start': 'Ngày bắt đầu (dd/mm/yyyy)',
    'end': 'Ngày kết thúc (dd/mm/yyyy)',
    'rent': 'Tiền phòng (đ/tháng)',
    'deposit': 'Tiền đặt cọc (đ)',
    'note': 'Ghi chú',
  };
  @override
  void initState() {
    super.initState();
    for (final key in labels.keys) {
      fields[key] = TextEditingController(text: widget.contract?[key] ?? '');
    }
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  DateTime? _date(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    final date = DateTime(year, month, day);
    return date.day == day && date.month == month && date.year == year
        ? date
        : null;
  }

  void _save() {
    if (!formKey.currentState!.validate()) return;
    final start = _date(fields['start']!.text.trim());
    final end = _date(fields['end']!.text.trim());
    String? error;
    if (start == null || end == null || !end.isAfter(start))
      error = 'Nhập ngày hợp lệ; ngày kết thúc phải sau ngày bắt đầu';
    if (contractList.any(
      (c) => c != widget.contract && c['id'] == fields['id']!.text.trim(),
    ))
      error = 'Số hợp đồng đã tồn tại';
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final result = Map<String, String>.from(widget.contract ?? {});
    for (final key in fields.keys) {
      result[key] = fields[key]!.text.trim();
    }
    result['status'] = widget.contract?['status'] ?? 'Còn hiệu lực';
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.contract == null ? 'Tạo hợp đồng' : 'Chỉnh sửa hợp đồng',
        ),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final key in labels.keys)
              FormInput(
                labels[key]!,
                fields[key]!,
                number: key == 'rent' || key == 'deposit',
                requiredField: ![
                  'email',
                  'identity',
                  'note',
                  'phone',
                ].contains(key),
                lines: key == 'note' ? 3 : 1,
              ),
            FilledButton(onPressed: _save, child: const Text('Lưu hợp đồng')),
          ],
        ),
      ),
    );
  }
}
