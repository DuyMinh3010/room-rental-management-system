import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/form_widgets.dart';

class TenantEditPage extends StatefulWidget {
  final Map<String, String> tenant;

  const TenantEditPage({
    super.key,
    required this.tenant,
  });

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
  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    for (final key in labels.keys) {
      fields[key] = TextEditingController(
        text: widget.tenant[key] ?? '',
      );
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
    for (final controller in fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (isSaving) return;

    if (!formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    final result = Map<String, String>.from(widget.tenant);

    for (final key in fields.keys) {
      result[key] = fields[key]!.text.trim();
    }

    result['gender'] = gender;
    result['residence'] = residence;

    try {
      final contracts =
          FirebaseFirestore.instance.collection('contracts');

      // Ưu tiên document ID nếu danh sách đã truyền ID này.
      final documentId = (widget.tenant['documentId'] ?? '').trim();
      final contractId = (widget.tenant['contract'] ?? '').trim();

      DocumentReference<Map<String, dynamic>>? contractRef;

      // 1. Tìm trực tiếp theo document ID.
      if (documentId.isNotEmpty) {
        final doc = await contracts.doc(documentId).get();

        if (doc.exists) {
          contractRef = doc.reference;
        }
      }

      // 2. Nếu chưa có document ID, tìm theo trường id.
      if (contractRef == null && contractId.isNotEmpty) {
        final query = await contracts
            .where('id', isEqualTo: contractId)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          contractRef = query.docs.first.reference;
        }
      }

      // 3. Tương thích dữ liệu cũ: tìm theo tên và phòng.
      if (contractRef == null) {
        final oldName = (widget.tenant['name'] ?? '').trim();
        final room = (widget.tenant['room'] ?? '').trim();

        if (oldName.isNotEmpty) {
          final query = await contracts
              .where('name', isEqualTo: oldName)
              .get();

          final matches = query.docs.where((doc) {
            return (doc.data()['room'] ?? '').toString().trim() == room;
          }).toList();

          if (matches.length == 1) {
            contractRef = matches.first.reference;
          } else if (matches.isNotEmpty && room.isEmpty) {
            // Không đoán nếu có nhiều hợp đồng cùng tên.
            if (matches.length == 1) {
              contractRef = matches.first.reference;
            }
          } else if (query.docs.length == 1) {
            contractRef = query.docs.first.reference;
          }
        }
      }

      if (contractRef == null) {
        throw Exception(
          'Không xác định được hợp đồng cần cập nhật. '
          'Cần truyền documentId từ danh sách người thuê.',
        );
      }

      // Cập nhật các trường thông tin người thuê.
      await contractRef.update({
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật thông tin người thuê lên Firebase.'),
        ),
      );

      Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lưu thông tin thất bại: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa người thuê'),
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
                requiredField: key == 'name' || key == 'phone',
              ),
            DropdownButtonFormField<String>(
              value: gender,
              decoration: const InputDecoration(
                labelText: 'Giới tính',
              ),
              items: ['Nam', 'Nữ', 'Khác']
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(v),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => gender = v);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: residence,
              decoration: const InputDecoration(
                labelText: 'Tạm trú',
              ),
              items: ['Chưa đăng ký', 'Đã đăng ký']
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(v),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => residence = v);
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isSaving ? null : _save,
              child: Text(
                isSaving ? 'Đang lưu...' : 'Lưu thay đổi',
              ),
            ),
          ],
        ),
      ),
    );
  }
}