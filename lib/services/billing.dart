// Tiền trong ứng dụng tính theo đồng.
// Không dùng số thập phân cho đơn giá.
class Billing {
  static String iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

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

  static String periodStart(String p) {
    period(p);
    return '$p-01';
  }

  static String periodEnd(String p) {
    period(p);

    final year = int.parse(p.substring(0, 4));
    final month = int.parse(p.substring(5));

    return iso(DateTime.utc(year, month + 1, 0));
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

    if (day < 1 || day > 31) {
      throw StateError('Ngày chốt từ 1–31');
    }

    final year = int.parse(p.substring(0, 4));
    final month = int.parse(p.substring(5));
    final last = DateTime.utc(year, month + 1, 0).day;

    return iso(
      DateTime.utc(
        year,
        month,
        day > last ? last : day,
      ),
    );
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

    final start = periodStart(p);
    final end = periodEnd(p);

    final contractStart = date(contract['startDate']);
    final contractEnd = date(contract['endDate']);

    // Kiểm tra hợp đồng có thời gian thuê trong kỳ được chọn.
    if (!['active', 'scheduled'].contains(contract['status']) ||
        contractStart.compareTo(end) > 0 ||
        contractEnd.compareTo(start) < 0) {
      throw StateError(
        'Hợp đồng không có hiệu lực trong kỳ $p.',
      );
    }

    final rent = number(
      contract['rent'],
      'Tiền phòng',
      min: 1,
    );

    final count = number(room['people'], 'Số người');

    // Chỉ số điện nước phải thuộc đúng kỳ hóa đơn.
    final meterPeriod = p;

    final lines = <Map<String, dynamic>>[
      {
        'name': 'Tiền phòng $p',
        'quantity': 1,
        'unitPrice': rent,
        'amount': rent,
        'type': 'rent',
      },
    ];

    for (final service in services) {
      if (service['archived'] == true) {
        throw StateError(
          'Dịch vụ ${service['name']} đã lưu trữ',
        );
      }

      final price = number(
        service['price'],
        'Đơn giá',
      );

      num quantity;

      switch (service['mode']) {
        case 'room':
          quantity = 1;
          break;

        case 'person':
          quantity = count;
          break;

        case 'meter':
          final meter = meters[service['_id']];

          if (meter == null || meter['period'] != p) {
            throw StateError(
              'Chưa có chỉ số ${service['name']} kỳ $p. '
              'Vui lòng nhập tại Dịch vụ > Nhập chỉ số.',
            );
          }

          final previous = number(
            meter['previous'],
            'Chỉ số cũ',
            integer: false,
          );

          final current = number(
            meter['current'],
            'Chỉ số mới',
            integer: false,
          );

          if (current < previous) {
            throw StateError(
              'Chỉ số mới ${service['name']} nhỏ hơn chỉ số cũ.',
            );
          }

          quantity = num.parse(
            (current - previous).toStringAsFixed(3),
          );
          break;

        default:
          throw StateError('Cách tính dịch vụ không hợp lệ');
      }

      lines.add({
        'name': service['name'],
        'serviceId': service['_id'],
        'quantity': quantity,
        'unit': service['unit'],
        'unitPrice': price,
        'amount': (quantity * price).round(),
        'type': 'service',
        'meterPeriod': service['mode'] == 'meter'
            ? meterPeriod
            : null,
      });
    }

    for (final extra in extras) {
      final reason = '${extra['reason'] ?? ''}'.trim();

      if (reason.isEmpty) {
        throw StateError('Phụ phí phải ghi rõ lý do');
      }

      final amount = number(
        extra['amount'],
        'Phụ phí',
        min: 1,
      );

      lines.add({
        'name': reason,
        'quantity': 1,
        'unitPrice': amount,
        'amount': amount,
        'type': 'extra',
      });
    }

    final total = lines.fold<num>(
      0,
      (sum, line) => sum + (line['amount'] as num),
    );

    number(total, 'Tổng tiền', min: 1);

    final term = number(
      room['paymentTermDays'] ?? 5,
      'Hạn thanh toán',
    );

    if (term > 60) {
      throw StateError('Hạn thanh toán tối đa 60 ngày');
    }

    return {
      'period': p,
      'meterPeriod': meterPeriod,
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
        DateTime.parse('${day}T00:00:00Z').add(
          Duration(days: term.toInt()),
        ),
      ),
      'lines': lines,
      'total': total,
      'status': 'unpaid',
      'bank': contract['bank'] ?? {},
      'delivered': '${contract['recipientUid'] ?? ''}'.isNotEmpty,
    };
  }
}