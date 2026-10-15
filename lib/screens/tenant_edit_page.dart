import 'package:flutter/material.dart';

import '../widgets/form_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TenantEditPage extends StatefulWidget {
  final Map<String, String> tenant;
  const TenantEditPage({super.key, required this.tenant});
  @override
  State<TenantEditPage> createState() => _TenantEditPageState();
}

class _TenantEditPageState extends State<TenantEditPage> {
  final formKey = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  final labels = const {
    'name': 'Họ và tên',
    'birthday': 'Ngày sinh',
    'phone': 'Số điện thoại',
    'email': 'Email',
    'identity': 'CCCD/Passport',
    'address': 'Quê quán',
    'job': 'Nghề nghiệp',
    'note': 'Ghi chú',
  };
  String gender = 'Nam';
  String residence = 'Chưa đăng ký';
  @override
  void initState() {
    super.initState();
    for (final key in labels.keys) {
      fields[key] = TextEditingController(text: widget.tenant[key] ?? '');
    }
    gender = ['Nam', 'Nữ', 'Khác'].contains(widget.tenant['gender'])
        ? widget.tenant['gender']!
        : 'Nam';

    residence = ['Chưa đăng ký', 'Đã đăng ký']
        .contains(widget.tenant['residence'])
        ? widget.tenant['residence']!
        : 'Chưa đăng ký';
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }


  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;

    final result = Map<String, String>.from(widget.tenant);

    for (final key in fields.keys) {
      result[key] = fields[key]!.text.trim();
    }

    result['gender'] = gender;
    result['residence'] = residence;

    try {
      final contracts =
      FirebaseFirestore.instance.collection('contracts');

      final contractId =
      (widget.tenant['contract'] ?? '').trim();

      final oldName =
      (widget.tenant['name'] ?? '').trim();

      final room =
      (widget.tenant['room'] ?? '').trim();

      DocumentSnapshot<Map<String, dynamic>>? contractDoc;

      // 1. Tìm theo mã hợp đồng
      if (contractId.isNotEmpty) {
        final resultById = await contracts
            .where('id', isEqualTo: contractId)
            .limit(1)
            .get();

        if (resultById.docs.isNotEmpty) {
          contractDoc = resultById.docs.first;
        }
      }

      // 2. Nếu không tìm thấy theo mã, thử tìm theo tên người thuê
      if (contractDoc == null && oldName.isNotEmpty) {
        final resultByName = await contracts
            .where('name', isEqualTo: oldName)
            .get();

        if (resultByName.docs.isNotEmpty) {
          final sameRoom = resultByName.docs.where((doc) {
            return (doc.data()['room'] ?? '')
                .toString()
                .trim() ==
                room;
          }).toList();

          contractDoc = sameRoom.isNotEmpty
              ? sameRoom.first
              : resultByName.docs.first;
        }
      }

      if (contractDoc == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không tìm thấy hợp đồng. Hãy kiểm tra trường id, name và room trên Firebase.',
            ),
          ),
        );
        return;
      }

      // 3. Cập nhật thông tin người thuê vào hợp đồng tìm được
      await contractDoc.reference.update({
        'name': result['name'] ?? '',
        'phone': result['phone'] ?? '',
        'email': result['email'] ?? '',
        'identity': result['identity'] ?? '',
        'birthday': result['birthday'] ?? '',
        'gender': result['gender'] ?? '',
        'address': result['address'] ?? '',
        'job': result['job'] ?? '',
        'residence': result['residence'] ?? '',
        'note': result['note'] ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lưu thông tin thất bại: $e'),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa người thuê')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final key in labels.keys)
              FormInput(
                labels[key]!,
                fields[key]!,
                requiredField: key == 'name' || key == 'phone',
              ),
            DropdownButtonFormField<String>(
              value: gender,
              decoration: const InputDecoration(labelText: 'Giới tính'),
              items: [
                'Nam',
                'Nữ',
                'Khác',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => gender = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: residence,
              decoration: const InputDecoration(labelText: 'Tạm trú'),
              items: [
                'Chưa đăng ký',
                'Đã đăng ký',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => residence = v!),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Lưu thay đổi')),
          ],
        ),
      ),
    );
  }
}
