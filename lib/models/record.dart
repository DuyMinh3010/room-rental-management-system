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
  final formatted = '${n.round()}'.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );
  return '$formattedđ';
}

String periodOf([DateTime? day]) {
  final d = day ?? DateTime.now().toUtc().add(const Duration(hours: 7));
  return '${d.year}-${d.month.toString().padLeft(2, '0')}';
}

String previousPeriod(String p) {
  final parts = p.split('-');
  return periodOf(DateTime(int.parse(parts[0]), int.parse(parts[1]) - 1));
}

String formatDateTimeVi(DateTime? dt, [String fallback = '']) {
  if (dt == null) return fallback;
  final vn = dt.isUtc ? dt.add(const Duration(hours: 7)) : dt;
  final d = vn.day.toString().padLeft(2, '0');
  final m = vn.month.toString().padLeft(2, '0');
  final y = vn.year.toString().padLeft(4, '0');
  final hh = vn.hour.toString().padLeft(2, '0');
  final mm = vn.minute.toString().padLeft(2, '0');
  return '$d/$m/$y $hh:$mm';
}

int naturalCompare(String a, String b) {
  final reg = RegExp(r'(\d+)|(\D+)');
  final ma = reg.allMatches(a.trim().toLowerCase()).toList();
  final mb = reg.allMatches(b.trim().toLowerCase()).toList();
  final len = ma.length < mb.length ? ma.length : mb.length;
  for (var i = 0; i < len; i++) {
    final sa = ma[i].group(0)!;
    final sb = mb[i].group(0)!;
    final na = int.tryParse(sa);
    final nb = int.tryParse(sb);
    final cmp = (na != null && nb != null) ? na.compareTo(nb) : sa.compareTo(sb);
    if (cmp != 0) return cmp;
  }
  return ma.length.compareTo(mb.length);
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
