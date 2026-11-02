import 'package:flutter/material.dart';

import '../models/record.dart';
import '../widgets/common.dart';

class RoomEditPage extends StatelessWidget {
  final Record? room;
  const RoomEditPage({super.key, this.room});
  @override
  Widget build(BuildContext context) {
    final isNew = room == null;
    return EditForm(
      title: isNew ? 'Thêm phòng' : 'Sửa phòng',
      subtitle: isNew
          ? 'Tạo thông tin phòng mới'
          : 'Cập nhật thông tin phòng',
      submitLabel: isNew ? 'Thêm phòng' : 'Lưu thay đổi',
      helperText: isNew
          ? 'Phòng mới sẽ được thêm vào danh sách phòng.'
          : 'Thông tin phòng sẽ được cập nhật ngay sau khi lưu.',
      action: 'saveRoom',
      id: room?.id,
      initial: {
        ...?room?.data,
        'condition': room?.condition ?? 'Tốt',
        'billingDay':
            int.tryParse((room?.text('billingDay') ?? '05').split(' ').first) ??
            5,
        'paymentTermDays': room?.data['paymentTermDays'] ?? 5,
        'capacity': room?.data['capacity'] ?? 4,
      },
      fields: const [
        FieldSpec('name', 'Số phòng', hint: 'VD: P.101'),
        FieldSpec(
          'capacity',
          'Số lượng người tối đa',
          hint: 'VD: 4',
          number: true,
          min: 1,
          max: 100,
        ),
        FieldSpec(
          'price',
          'Giá phòng (đ/tháng)',
          hint: 'VD: 2500000',
          number: true,
          min: 1,
        ),
        FieldSpec(
          'deposit',
          'Tiền đặt cọc (đ)',
          hint: 'VD: 2500000',
          number: true,
          min: 0,
        ),
        FieldSpec(
          'area',
          'Diện tích (m²)',
          hint: 'VD: 25',
          number: true,
          decimal: true,
          min: 0.1,
        ),
        FieldSpec(
          'billingDay',
          'Ngày chốt hóa đơn hàng tháng (1–31)',
          hint: 'VD: 5',
          number: true,
          min: 1,
          max: 31,
        ),
        FieldSpec(
          'paymentTermDays',
          'Hạn thanh toán kể từ ngày phát hành (ngày)',
          hint: 'VD: 5',
          number: true,
          min: 0,
          max: 60,
        ),
        FieldSpec(
          'condition',
          'Trạng thái',
          options: {'Tốt': 'Tốt (Sẵn sàng / Đang thuê)', 'Đang sửa': 'Đang sửa'},
        ),
        FieldSpec(
          'description',
          'Mô tả phòng',
          hint: 'Phòng thoáng, có cửa sổ, gác lửng...',
          required: false,
        ),
      ],
    );
  }
}
