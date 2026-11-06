import 'package:flutter/material.dart';

import '../models/record.dart';
import '../widgets/common.dart';

class TenantEditPage extends StatelessWidget {
  final Record? tenant;
  const TenantEditPage({super.key, this.tenant});
  @override
  Widget build(BuildContext context) {
    final isNew = tenant == null;
    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        backgroundColor: canvas,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 30, color: ink),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Text(
          isNew ? 'Thêm người thuê' : 'Sửa người thuê',
          style: const TextStyle(
            color: ink,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: RecordsView(
        collection: 'rooms',
        builder: (_, rs) => EditForm(
          embedded: true,
          title: isNew ? 'Thêm người thuê' : 'Sửa người thuê',
          submitLabel: isNew ? 'Thêm người thuê' : 'Lưu thay đổi',
          action: 'saveTenant',
          id: tenant?.id,
          initial: tenant?.data ?? const {},
          fields: [
            const FieldSpec('name', 'Họ và tên', hint: 'Nhập họ và tên'),
            const FieldSpec('phone', 'Số điện thoại', hint: 'Nhập số điện thoại'),
            const FieldSpec(
              'email',
              'Email',
              hint: 'example@gmail.com',
              required: false,
            ),
            const FieldSpec(
              'identity',
              'CCCD / Passport',
              hint: 'Nhập số CCCD',
              required: false,
            ),
            FieldSpec(
              'roomId',
              'Phòng đang ở',
              required: false,
              options: {
                '': 'Chưa gán phòng',
                for (final r in rs.where((r) => !r.archived)) r.id: r.name,
              },
            ),
            const FieldSpec(
              'birthday',
              'Ngày sinh',
              hint: 'VD: 24/08/2003',
              required: false,
            ),
            const FieldSpec(
              'address',
              'Quê quán / Địa chỉ thường trú',
              hint: 'Nhập địa chỉ',
              required: false,
            ),
            const FieldSpec(
              'note',
              'Ghi chú',
              hint: 'Ghi chú thêm...',
              required: false,
            ),
          ],
        ),
      ),
    );
  }
}
