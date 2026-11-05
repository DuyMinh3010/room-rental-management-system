import 'package:cloud_firestore/cloud_firestore.dart';

class Record {
  final String id;
  final Map<String, dynamic> data;
  const Record(this.id, this.data);
  String text(String key, [String fallback = '']) =>
      data[key]?.toString() ?? fallback;
  num? number(String key) =>
      data[key] is num ? data[key] as num : num.tryParse(text(key));
  bool get archived => data['archived'] == true;
  List<String> strings(String key) => (data[key] is List)
      ? (data[key] as List).whereType<String>().toList()
      : [];
  String get name => text('name', 'Chưa đặt tên');
  String get condition => text('condition').isNotEmpty
      ? text('condition')
      : text('status') == 'Đang sửa'
      ? 'Đang sửa'
      : 'Tốt';
  DateTime? time(String key) {
    final v = data[key];
    return v is Timestamp ? v.toDate() : DateTime.tryParse(v?.toString() ?? '');
  }
}

String money(dynamic value) {
  final n = value is num ? value : num.tryParse('$value');
  if (n == null) return 'Chưa cập nhật';
  return '${n.round()}'.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      ) +
      'đ';
}

String periodOf([DateTime? day]) {
  final d = day ?? DateTime.now().toUtc().add(const Duration(hours: 7));
  return '${d.year}-${d.month.toString().padLeft(2, '0')}';
}

String previousPeriod(String p) {
  final parts = p.split('-');
  return periodOf(DateTime(int.parse(parts[0]), int.parse(parts[1]) - 1));
}

String label(String status) =>
    const {
      'active': 'Còn hiệu lực',
      'scheduled': 'Chưa bắt đầu',
      'ended': 'Đã kết thúc',
      'expired': 'Hết hạn',
      'cancelled': 'Đã hủy',
      'unpaid': 'Chưa thanh toán',
      'reported': 'Chờ xác nhận chuyển tiền',
      'paid': 'Đã thanh toán',
      'void': 'Đã hủy',
      'new': 'Mới tiếp nhận',
      'working': 'Đang xử lý',
      'done': 'Hoàn thành',
      'meter': 'Theo chỉ số',
      'room': 'Theo phòng',
      'person': 'Theo người',
      'cash': 'Tiền mặt',
      'bank': 'Chuyển khoản',
    }[status] ??
    status;
