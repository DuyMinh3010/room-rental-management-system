// Tiền trong ứng dụng tính theo đồng, không dùng số thập phân cho đơn giá.
class Billing {
  static String iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static String today() =>
      iso(DateTime.now().toUtc().add(const Duration(hours: 7)));
  static String date(dynamic v) {
    final s = '$v';
    final d = DateTime.tryParse(s);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s) ||
        d == null ||
        iso(d) != s) {
      throw StateError('Ngày không hợp lệ, dùng YYYY-MM-DD');
    }
    return s;
  }

  static String period(dynamic v) {
    final s = '$v';
    if (!RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(s)) {
      throw StateError('Kỳ phải là YYYY-MM');
    }
    return s;
  }

  static String shift(String p, int months) {
    period(p);
    return iso(
      DateTime.utc(
        int.parse(p.substring(0, 4)),
        int.parse(p.substring(5)) + months,
      ),
    ).substring(0, 7);
  }

  static num number(
    dynamic v,
    String label, {
    num min = 0,
    bool integer = true,
  }) {
    final n = v is num ? v : num.tryParse('$v');
    if (n == null ||
        !n.isFinite ||
        n < min ||
        n.abs() > 9007199254740991 ||
        (integer && n != n.round())) {
      throw StateError('$label không hợp lệ');
    }
    return n;
  }

  static String billingDate(String p, int day) {
    period(p);
    if (day < 1 || day > 31) throw StateError('Ngày chốt từ 1–31');
    final y = int.parse(p.substring(0, 4)), m = int.parse(p.substring(5));
    final last = DateTime.utc(y, m + 1, 0).day;
    return iso(DateTime.utc(y, m, day > last ? last : day));
  }

  static bool late(Map<String, dynamic> b, String day) =>
      ['unpaid', 'reported'].contains(b['status']) &&
      DateTime.parse(date(day))
              .difference(DateTime.parse(date(b['dueDate'])))
              .inDays >
          5;

  static Map<String, dynamic> build({
    required Map<String, dynamic> contract,
    required Map<String, dynamic> room,
    required List<Map<String, dynamic>> services,
    required Map<String, Map<String, dynamic>?> meters,
    required List<Map<String, dynamic>> extras,
    required String p,
    required String day,
  }) {
    period(p);
    date(day);
    if (!['active', 'scheduled'].contains(contract['status']) ||
        '${contract['startDate']}'.compareTo(day) > 0 ||
        '${contract['endDate']}'.compareTo(day) < 0) {
      throw StateError('Hợp đồng ngoài thời hạn');
    }
    final rent = number(contract['rent'], 'Tiền phòng', min: 1);
    final count = number(room['people'], 'Số người');
    final mp = shift(p, -1);
    final lines = <Map<String, dynamic>>[
      {
        'name': 'Tiền phòng $p',
        'quantity': 1,
        'unitPrice': rent,
        'amount': rent,
        'type': 'rent',
      },
    ];
    for (final s in services) {
      if (s['archived'] == true) {
        throw StateError('Dịch vụ ${s['name']} đã lưu trữ');
      }
      final price = number(s['price'], 'Đơn giá');
      num quantity;
      String? usedMeterPeriod;
      switch (s['mode']) {
        case 'room':
          quantity = 1;
          break;
        case 'person':
          quantity = count;
          break;
        case 'meter':
          final m = meters[s['_id']];
          if (m == null || (m['period'] != mp && m['period'] != p)) {
            throw StateError(
              'Thiếu chỉ số ${s['name']} (hãy nhập chỉ số kỳ $p hoặc $mp tại mục Dịch vụ > Nhập chỉ số)',
            );
          }
          usedMeterPeriod = '${m['period']}';
          final old = number(m['previous'], 'Chỉ số cũ', integer: false),
              current = number(m['current'], 'Chỉ số mới', integer: false);
          if (current < old) throw StateError('Chỉ số mới nhỏ hơn chỉ số cũ');
          quantity = num.parse((current - old).toStringAsFixed(3));
          break;
        default:
          throw StateError('Cách tính dịch vụ không hợp lệ');
      }
      lines.add({
        'name': s['name'],
        'serviceId': s['_id'],
        'quantity': quantity,
        'unit': s['unit'],
        'unitPrice': price,
        'amount': (quantity * price).round(),
        'type': 'service',
        'meterPeriod': s['mode'] == 'meter' ? (usedMeterPeriod ?? mp) : null,
      });
    }
    for (final x in extras) {
      final reason = '${x['reason'] ?? ''}'.trim();
      if (reason.isEmpty) throw StateError('Phụ phí phải ghi rõ lý do');
      final amount = number(x['amount'], 'Phụ phí', min: 1);
      lines.add({
        'name': reason,
        'quantity': 1,
        'unitPrice': amount,
        'amount': amount,
        'type': 'extra',
      });
    }
    final total = lines.fold<num>(0, (sum, l) => sum + (l['amount'] as num));
    number(total, 'Tổng tiền', min: 1);
    final term = number(room['paymentTermDays'] ?? 5, 'Hạn thanh toán');
    if (term > 60) throw StateError('Hạn thanh toán tối đa 60 ngày');
    return {
      'period': p,
      'meterPeriod': mp,
      'roomId': contract['roomId'],
      'roomName': room['name'],
      'contractId': contract['_id'],
      'contractNumber': contract['number'],
      'tenantId': contract['tenantId'],
      'tenantName': contract['tenantName'],
      'tenantPhone': contract['tenantPhone'] ?? '',
      'tenantEmail': contract['tenantEmail'] ?? '',
      'tenantIdentity': contract['tenantIdentity'] ?? '',
      'deposit': contract['deposit'] ?? room['deposit'] ?? 0,
      'recipientUid': contract['recipientUid'] ?? '',
      'issueDate': day,
      'dueDate': iso(
        DateTime.parse('${day}T00:00:00Z').add(Duration(days: term.toInt())),
      ),
      'lines': lines,
      'total': total,
      'status': 'unpaid',
      'bank': contract['bank'] ?? {},
      'delivered': '${contract['recipientUid'] ?? ''}'.isNotEmpty,
    };
  }
}
