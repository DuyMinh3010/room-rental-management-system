import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceModel {
  final String id; // Document ID hoặc mã HĐ
  final String invoiceCode; // Mã hiển thị: HD-0005
  final String roomId; // Document ID của phòng (id_room)
  final String roomName; // Tên phòng: P.101
  final String ownerId; // UID của chủ phòng trọ (owner_room)
  final String tenantName; // Tên người thuê
  final String tenantPhone; // SĐT người thuê
  final String billingCycle; // Kỳ thanh toán: 01/05/2026 - 31/05/2026
  final String month; // Tháng: 05/2026 hoặc 09/2026

  // Chi tiết tiền
  final int roomFee; // Tiền phòng
  final int electricOld; // Chỉ số điện cũ
  final int electricNew; // Chỉ số điện mới
  final int electricUsage; // kWh tiêu thụ
  final int electricPrice; // Đơn giá kWh
  final int electricFee; // Tiền điện

  final int waterOld; // Chỉ số nước cũ
  final int waterNew; // Chỉ số nước mới
  final int waterUsage; // m3 tiêu thụ
  final int waterPrice; // Đơn giá m3
  final int waterFee; // Tiền nước

  final int wifiFee; // Tiền WiFi
  final int trashFee; // Tiền rác
  final int parkingFee; // Tiền gửi xe
  final int otherFee; // Chi phí khác
  final int totalAmount; // Tổng cộng

  final String paymentMethod; // "Chuyển khoản" hoặc "Tiền mặt"
  final String status; // "Chưa thanh toán", "Đã thanh toán", "Quá hạn"
  final DateTime? paidAt;
  final DateTime? createdAt;

  InvoiceModel({
    required this.id,
    required this.invoiceCode,
    required this.roomId,
    required this.roomName,
    required this.ownerId,
    required this.tenantName,
    this.tenantPhone = '',
    required this.billingCycle,
    required this.month,
    required this.roomFee,
    this.electricOld = 0,
    this.electricNew = 0,
    this.electricUsage = 0,
    this.electricPrice = 3500,
    required this.electricFee,
    this.waterOld = 0,
    this.waterNew = 0,
    this.waterUsage = 0,
    this.waterPrice = 20000,
    required this.waterFee,
    this.wifiFee = 100000,
    this.trashFee = 20000,
    this.parkingFee = 0,
    this.otherFee = 0,
    required this.totalAmount,
    this.paymentMethod = 'Chuyển khoản',
    this.status = 'Chưa thanh toán',
    this.paidAt,
    this.createdAt,
  });

  // Chuyển đổi an toàn từ int, double hoặc chuỗi "455,000" / "455000" thành int
  static int _parseInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is num) return val.toInt();
    if (val is String) {
      final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(clean) ?? fallback;
    }
    return fallback;
  }

  // Factory chuyển từ Firestore document sang model (hỗ trợ cả schema cũ và mới)
  factory InvoiceModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return InvoiceModel.fromMap(doc.id, data);
  }

  factory InvoiceModel.fromMap(String docId, Map<String, dynamic> data) {
    // Đọc trạng thái tương thích
    String rawStatus = data['status']?.toString() ?? 'Chưa thanh toán';
    if (rawStatus.toLowerCase() == 'unpaid') {
      rawStatus = 'Chưa thanh toán';
    } else if (rawStatus.toLowerCase() == 'paid') {
      rawStatus = 'Đã thanh toán';
    } else if (rawStatus.toLowerCase() == 'overdue') {
      rawStatus = 'Quá hạn';
    }

    final billCycle = data['billingCycle']?.toString() ??
        data['period']?.toString() ??
        'Chưa cập nhật';

    // Rút trích tháng từ billingCycle nếu thiếu
    String monthStr = data['month']?.toString() ?? '';
    if (monthStr.isEmpty) {
      final matches = RegExp(r'\d{2}/\d{2}/\d{4}').allMatches(billCycle);
      if (matches.isNotEmpty) {
        final last = matches.last.group(0)!;
        final parts = last.split('/');
        monthStr = '${parts[1]}/${parts[2]}';
      } else {
        monthStr = 'Tháng hiện tại';
      }
    }

    // Đọc các trường tiền điện tương thích (kể cả "electricity fee" có dấu cách)
    final electricVal = data['electricFee'] ??
        data['electricity fee'] ??
        data['electric'] ??
        0;
    final roomFeeVal = data['roomFee'] ?? data['rent'] ?? 0;
    final waterVal = data['waterFee'] ?? data['water'] ?? 0;
    final wifiVal = data['wifiFee'] ?? data['wifi'] ?? 100000;
    final trashVal = data['trashFee'] ?? data['trash'] ?? 20000;
    final totalVal = data['totalAmount'] ?? data['price'] ?? 0;

    final roomName = data['roomName']?.toString() ??
        data['roomId']?.toString() ??
        data['room']?.toString() ??
        'Chưa rõ phòng';

    final roomId = data['id_room']?.toString() ??
        data['roomId']?.toString() ??
        roomName;

    return InvoiceModel(
      id: docId,
      invoiceCode: data['invoiceCode']?.toString() ??
          data['id']?.toString() ??
          'HD-${docId.length > 5 ? docId.substring(0, 5).toUpperCase() : docId}',
      roomId: roomId,
      roomName: roomName,
      ownerId: data['ownerId']?.toString() ??
          data['owner_room']?.toString() ??
          '',
      tenantName: data['tenantName']?.toString() ??
          data['tenant']?.toString() ??
          'Chưa có người thuê',
      tenantPhone: data['tenantPhone']?.toString() ?? '',
      billingCycle: billCycle,
      month: monthStr,
      roomFee: _parseInt(roomFeeVal),
      electricOld: _parseInt(data['electricOld']),
      electricNew: _parseInt(data['electricNew']),
      electricUsage: _parseInt(data['electricUsage']),
      electricPrice: _parseInt(data['electricPrice'], 3500),
      electricFee: _parseInt(electricVal),
      waterOld: _parseInt(data['waterOld']),
      waterNew: _parseInt(data['waterNew']),
      waterUsage: _parseInt(data['waterUsage']),
      waterPrice: _parseInt(data['waterPrice'], 20000),
      waterFee: _parseInt(waterVal),
      wifiFee: _parseInt(wifiVal, 100000),
      trashFee: _parseInt(trashVal, 20000),
      parkingFee: _parseInt(data['parkingFee']),
      otherFee: _parseInt(data['otherFee']),
      totalAmount: _parseInt(totalVal),
      paymentMethod: data['paymentMethod']?.toString() ??
          data['method']?.toString() ??
          'Chuyển khoản',
      status: rawStatus,
      paidAt: (data['paidAt'] is Timestamp)
          ? (data['paidAt'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Chuyển sang Map chuẩn để lưu vào Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'invoiceCode': invoiceCode,
      'roomId': roomId, // ID phòng chuẩn
      'roomName': roomName, // Tên phòng
      'ownerId': ownerId, // UID chủ phòng (chống trùng phòng giữa các chủ)
      'owner_room': ownerId, // Hỗ trợ cả 2 tên trường như yêu cầu
      'tenantName': tenantName,
      'tenantPhone': tenantPhone,
      'billingCycle': billingCycle,
      'month': month,
      'roomFee': roomFee,
      'electricOld': electricOld,
      'electricNew': electricNew,
      'electricUsage': electricUsage,
      'electricPrice': electricPrice,
      'electricFee': electricFee,
      'waterOld': waterOld,
      'waterNew': waterNew,
      'waterUsage': waterUsage,
      'waterPrice': waterPrice,
      'waterFee': waterFee,
      'wifiFee': wifiFee,
      'trashFee': trashFee,
      'parkingFee': parkingFee,
      'otherFee': otherFee,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'status': status,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Tiện ích format số tiền kiểu VNĐ (ví dụ: 1.500.000đ)
  static String formatCurrency(num amount) {
    return '${amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    )}đ';
  }
}
