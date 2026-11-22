// Dữ liệu giả chỉ để hiển thị và bấm thử UI, chưa kết nối API/database.
// Khởi động lại ứng dụng sẽ trở về dữ liệu ban đầu.
final profile = <String, String>{
  'name': 'Nguyễn Minh Chiến',
  'phone': '090 123 4567',
  'email': 'chienday05@gmail.com',
  'role': 'Chủ trọ',
};

final tenantList = <Map<String, String>>[
  {
    'initial': 'NA',
    'name': 'Nguyễn Minh Chiến',
    'room': 'Phòng 101 · Khu A',
    'phone': '090 123 4567',
    'email': 'chienday05@gmail.com',
    'identity': '048203001234',
    'birthday': '24/08/2003',
    'gender': 'Nam',
    'address': 'Quảng Ngãi',
    'job': 'Sinh viên',
    'residence': 'Chưa đăng ký',
    'note': '',
    'contract': '01/06/2026 → 31/05/2027',
    'start': '01/06/2026',
    'end': '31/05/2027',
    'rent': '2500000',
    'deposit': '2500000',
    'status': 'Đang thuê',
    'memberRole': 'Trưởng phòng',
  },
  {
    'initial': 'TH',
    'name': 'Trần Văn Hùng',
    'room': 'Phòng 102 · Khu A',
    'phone': '098 765 4321',
    'contract': '15/06/2026 → 14/05/2027',
    'status': 'Đang thuê',
    'memberRole': 'Trưởng phòng',
  },
  {
    'initial': 'LP',
    'name': 'Lê Thị Phương',
    'room': 'Phòng 103 · Khu B',
    'phone': '093 111 2233',
    'contract': '01/04/2026 → 31/03/2027',
    'status': 'Đang thuê',
    'memberRole': 'Thành viên',
  },
  {
    'initial': 'NV',
    'name': 'Ngô Văn Đức',
    'room': 'Phòng 104 · Khu B',
    'phone': '091 234 5678',
    'contract': '10/03/2026 → 09/03/2027',
    'status': 'Sắp hết hạn',
    'memberRole': 'Trưởng phòng',
  },
];

final serviceList = <Map<String, String>>[
  {
    'name': 'Điện',
    'mode': 'Theo chỉ số',
    'price': '3500',
    'unit': 'kWh',
    'note': '',
  },
  {
    'name': 'Nước',
    'mode': 'Theo chỉ số',
    'price': '20000',
    'unit': 'm³',
    'note': '',
  },
  {
    'name': 'WiFi',
    'mode': 'Theo phòng',
    'price': '100000',
    'unit': 'tháng',
    'note': '',
  },
  {
    'name': 'Đổ rác',
    'mode': 'Theo phòng',
    'price': '20000',
    'unit': 'tháng',
    'note': '',
  },
  {
    'name': 'Gửi xe',
    'mode': 'Theo người',
    'price': '100000',
    'unit': 'người',
    'note': '',
  },
];

final invoiceList = <Map<String, String>>[
  {
    'id': 'HD-0005',
    'room': 'P.101',
    'tenant': 'Nguyễn Minh Chiến',
    'period': '01/05/2026 - 31/05/2026',
    'rent': '3500000',
    'electric': '455000',
    'water': '200000',
    'wifi': '100000',
    'trash': '20000',
    'price': '4.275.000đ',
    'status': 'Chưa thanh toán',
    'method': 'Chuyển khoản',
  },
  {
    'id': 'HD-0004',
    'room': 'P.101',
    'tenant': 'Nguyễn Minh Chiến',
    'period': '01/04/2026 - 30/04/2026',
    'rent': '3500000',
    'electric': '80000',
    'water': '0',
    'wifi': '100000',
    'trash': '20000',
    'price': '3.700.000đ',
    'status': 'Đã thanh toán',
    'method': 'Chuyển khoản',
  },
  {
    'id': 'HD-0006',
    'room': 'P.102',
    'tenant': 'Trần Văn Hùng',
    'period': '01/09/2026 - 30/09/2026',
    'rent': '2800000',
    'electric': '0',
    'water': '0',
    'wifi': '100000',
    'trash': '20000',
    'price': '2.920.000đ',
    'status': 'Quá hạn 3 ngày',
    'method': 'Tiền mặt',
  },
];

final contractList = <Map<String, String>>[
  {
    'id': 'HD-01/2026-P.101',
    'name': 'Nguyễn Minh Chiến',
    'room': 'P.101',
    'start': '01/06/2026',
    'end': '31/05/2027',
    'rent': '2500000',
    'deposit': '2500000',
    'phone': '090 123 4567',
    'email': 'chienday05@gmail.com',
    'identity': '048203001234',
    'status': 'Còn hiệu lực',
    'note': 'Khách thuê được phép nuôi thú cưng nhỏ',
  },
  {
    'id': 'HD-12/2024-P.104',
    'name': 'Trần Minh Huy',
    'room': 'P.104',
    'start': '01/11/2025',
    'end': '31/10/2026',
    'rent': '2500000',
    'deposit': '2500000',
    'status': 'Sắp hết hạn',
  },
  {
    'id': 'HD-9/2020-P.105',
    'name': 'Nguyễn Minh Duy',
    'room': 'P.105',
    'start': '01/01/2020',
    'end': '31/12/2020',
    'rent': '2300000',
    'deposit': '2300000',
    'status': 'Đã thanh lý',
  },
];

String money(String? value) {
  final amount = int.tryParse(value ?? '') ?? 0;
  return '${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';
}
