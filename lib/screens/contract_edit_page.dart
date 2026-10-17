import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/mock_data.dart';
import '../widgets/form_widgets.dart';

class ContractEditPage extends StatefulWidget {
  final Map<String, String>? contract;

  const ContractEditPage({
    super.key,
    this.contract,
  });

  @override
  State<ContractEditPage> createState() => _ContractEditPageState();
}

class _ContractEditPageState extends State<ContractEditPage> {
  final formKey = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};

  bool isSaving = false;

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
      fields[key] = TextEditingController(
        text: widget.contract?[key] ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (final controller in fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  DateTime? _date(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) {
      return null;
    }

    final date = DateTime(year, month, day);

    return date.day == day &&
        date.month == month &&
        date.year == year
        ? date
        : null;
  }

  Future<void> _save() async {
    if (isSaving) return;
    if (!formKey.currentState!.validate()) return;

    final start = _date(fields['start']!.text.trim());
    final end = _date(fields['end']!.text.trim());

    if (start == null || end == null || !end.isAfter(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nhập ngày hợp lệ; ngày kết thúc phải sau ngày bắt đầu.',
          ),
        ),
      );
      return;
    }

    final contractId = fields['id']!.text.trim();

    if (contractId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số hợp đồng.'),
        ),
      );
      return;
    }

    final duplicatedLocally = contractList.any((c) {
      return c['id'] == contractId &&
          c['id'] != widget.contract?['id'];
    });

    if (duplicatedLocally) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số hợp đồng đã tồn tại.'),
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      // 1. Kiểm tra tài khoản Firebase Authentication.
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception(
          'Bạn chưa đăng nhập bằng Firebase Authentication.',
        );
      }

      final ownerId = user.uid;

      final db = FirebaseFirestore.instance;
      final contracts = db.collection('contracts');
      final tenants = db.collection('tenants');

      // 2. Xác định tài liệu hợp đồng.
      DocumentReference<Map<String, dynamic>> contractRef;

      final existingDocumentId =
          (widget.contract?['documentId'] ?? '').trim();

      if (existingDocumentId.isNotEmpty) {
        contractRef = contracts.doc(existingDocumentId);

        final existingDoc = await contractRef.get();

        if (existingDoc.exists) {
          final existingOwner = existingDoc.data()?['ownerId'];

          if (existingOwner != null &&
              existingOwner != ownerId) {
            throw Exception(
              'Bạn không có quyền chỉnh sửa hợp đồng này.',
            );
          }
        } else {
          throw Exception(
            'Không tìm thấy hợp đồng cần chỉnh sửa trên Firebase.',
          );
        }
      } else {
        final existing = await contracts
            .where('id', isEqualTo: contractId)
            .get();

        final duplicate = existing.docs.any((doc) {
          return doc.data()['ownerId'] == ownerId ||
              doc.data()['ownerId'] == null;
        });

        if (widget.contract == null && duplicate) {
          throw Exception(
            'Số hợp đồng đã tồn tại trên Firebase.',
          );
        }

        if (widget.contract != null &&
            existing.docs.isNotEmpty) {
          contractRef = existing.docs.first.reference;
        } else {
          contractRef = contracts.doc();
        }
      }

      // 3. Chuẩn bị dữ liệu hợp đồng.
      final result = Map<String, String>.from(
        widget.contract ?? <String, String>{},
      );

      for (final key in fields.keys) {
        result[key] = fields[key]!.text.trim();
      }

      result['status'] =
          widget.contract?['status'] ?? 'Còn hiệu lực';

      // 4. Tìm hồ sơ người thuê thuộc chính chủ tài khoản này.
      QuerySnapshot<Map<String, dynamic>> tenantQuery;

      tenantQuery = await tenants
          .where('ownerId', isEqualTo: ownerId)
          .where('contractId', isEqualTo: contractRef.id)
          .limit(1)
          .get();

      DocumentReference<Map<String, dynamic>> tenantRef;

      if (tenantQuery.docs.isNotEmpty) {
        tenantRef = tenantQuery.docs.first.reference;
      } else {
        // Ưu tiên tìm theo CCCD trong phạm vi chủ sở hữu.
        final identity = result['identity']?.trim() ?? '';

        if (identity.isNotEmpty) {
          tenantQuery = await tenants
              .where('ownerId', isEqualTo: ownerId)
              .where('identity', isEqualTo: identity)
              .limit(1)
              .get();
        } else {
          tenantQuery = await tenants
              .where('ownerId', isEqualTo: ownerId)
              .limit(1)
              .get();

          // Không dùng kết quả này để ghép người thuê;
          // chỉ tạo hồ sơ mới khi không có CCCD.
          tenantQuery = await tenants
              .where('ownerId', isEqualTo: ownerId)
              .where('contractId', isEqualTo: '__no_match__')
              .limit(1)
              .get();
        }

        if (tenantQuery.docs.isNotEmpty) {
          tenantRef = tenantQuery.docs.first.reference;
        } else {
          // Chưa có hồ sơ tương ứng: tạo tài liệu mới.
          tenantRef = tenants.doc();
        }
      }

      // 5. Ghi hợp đồng và hồ sơ người thuê cùng lúc.
      final batch = db.batch();

      batch.set(
        contractRef,
        {
          ...result,
          'id': contractId,
          'ownerId': ownerId,
          'updatedAt': FieldValue.serverTimestamp(),
          if (widget.contract == null)
            'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      batch.set(
        tenantRef,
        {
          'ownerId': ownerId,
          'name': result['name'] ?? '',
          'phone': result['phone'] ?? '',
          'email': result['email'] ?? '',
          'identity': result['identity'] ?? '',
          'room': result['room'] ?? '',
          'start': result['start'] ?? '',
          'end': result['end'] ?? '',
          'rent': result['rent'] ?? '',
          'deposit': result['deposit'] ?? '',
          'note': result['note'] ?? '',
          'contractId': contractRef.id,
          'updatedAt': FieldValue.serverTimestamp(),
          if (widget.contract == null)
            'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      if (!mounted) return;

      result['documentId'] = contractRef.id;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã lưu hợp đồng và hồ sơ người thuê lên Firebase.',
          ),
        ),
      );

      Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lưu dữ liệu thất bại: $e'),
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
        title: Text(
          widget.contract == null
              ? 'Tạo hợp đồng'
              : 'Chỉnh sửa hợp đồng',
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
            FilledButton(
              onPressed: isSaving ? null : _save,
              child: Text(
                isSaving ? 'Đang lưu...' : 'Lưu hợp đồng',
              ),
            ),
          ],
        ),
      ),
    );
  }
}