import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/meter_reading_service.dart';
import '../services/invoice_service.dart';
import '../models/invoice.dart';
import '../data/mock_data.dart';
import '../widgets/form_widgets.dart';
import '../widgets/payment_qr_preview.dart';
import 'room_page.dart';

class InvoiceCreatePage extends StatefulWidget {
  final String? initialRoomId;
  final String? initialRoomName;

  const InvoiceCreatePage({
    super.key,
    this.initialRoomId,
    this.initialRoomName,
  });

  @override
  State<InvoiceCreatePage> createState() => _InvoiceCreatePageState();
}

class _InvoiceCreatePageState extends State<InvoiceCreatePage> {
  final MeterReadingService meterReadingService = MeterReadingService();
  final InvoiceService invoiceService = InvoiceService();
  final formKey = GlobalKey<FormState>();

  final period = TextEditingController(
    text: '01/09/2026 - 30/09/2026',
  );
  final rent = TextEditingController(text: '3500000');
  final electric = TextEditingController(text: '0');
  final water = TextEditingController(text: '0');
  final wifi = TextEditingController(text: '100000');
  final trash = TextEditingController(text: '20000');
  final tenantNameController = TextEditingController();

  bool isLoadingReading = false;
  bool isSaving = false;

  String? selectedRoomId;
  String room = 'P.101';
  String method = 'Chuyển khoản';

  int electricOldVal = 0;
  int electricNewVal = 0;
  int waterOldVal = 0;
  int waterNewVal = 0;

  List<Map<String, String>> get availableRooms {
    return roomList.where((r) {
      final name = (r['name'] ?? '').trim();
      return name.isNotEmpty && name != 'Chưa cập nhật';
    }).toList();
  }

  String? _getMonthFromPeriod() {
    final dates = RegExp(r'\d{2}/\d{2}/\d{4}')
        .allMatches(period.text)
        .toList();

    if (dates.isEmpty) return null;

    final lastDate = dates.last.group(0)!;
    final parts = lastDate.split('/');

    return '${parts[1]}/${parts[2]}';
  }

  Future<void> _loadMeterReading() async {
    final month = _getMonthFromPeriod();

    if (month == null || room.isEmpty) {
      return;
    }

    setState(() {
      isLoadingReading = true;
    });

    try {
      final reading = await meterReadingService.getReading(
        room: room,
        month: month,
        roomId: selectedRoomId,
      );

      if (!mounted) return;

      if (reading != null) {
        electricOldVal = int.tryParse('${reading['electricOld'] ?? 0}') ?? 0;
        electricNewVal = int.tryParse('${reading['electricNew'] ?? 0}') ?? 0;
        waterOldVal = int.tryParse('${reading['waterOld'] ?? 0}') ?? 0;
        waterNewVal = int.tryParse('${reading['waterNew'] ?? 0}') ?? 0;

        final electricUsage = reading['electricUsage'] != null
            ? (int.tryParse('${reading['electricUsage']}') ?? 0)
            : (electricNewVal - electricOldVal).clamp(0, 999999999);

        final waterUsage = reading['waterUsage'] != null
            ? (int.tryParse('${reading['waterUsage']}') ?? 0)
            : (waterNewVal - waterOldVal).clamp(0, 999999999);

        setState(() {
          electric.text = '$electricUsage';
          water.text = '$waterUsage';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF22C55E),
            content: Text('Đã nạp chỉ số điện nước tháng $month của $room'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          electric.text = '0';
          water.text = '0';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Chưa có chỉ số điện nước của phòng $room trong tháng $month.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải chỉ số điện nước: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoadingReading = false;
        });
      }
    }
  }

  int get electricFee =>
      (int.tryParse(electric.text) ?? 0) * 3500;

  int get waterFee =>
      (int.tryParse(water.text) ?? 0) * 20000;

  int get total =>
      (int.tryParse(rent.text) ?? 0) +
      electricFee +
      waterFee +
      (int.tryParse(wifi.text) ?? 0) +
      (int.tryParse(trash.text) ?? 0);

  @override
  void initState() {
    super.initState();

    final rooms = availableRooms;
    if (widget.initialRoomId != null &&
        rooms.any((r) => r['id'] == widget.initialRoomId)) {
      selectedRoomId = widget.initialRoomId;
      final matched = rooms.firstWhere((r) => r['id'] == widget.initialRoomId);
      room = matched['name'] ?? 'P.101';
      _updatePriceFromRoom(matched);
    } else if (widget.initialRoomName != null &&
        rooms.any((r) => r['name'] == widget.initialRoomName)) {
      room = widget.initialRoomName!;
      final matched = rooms.firstWhere((r) => r['name'] == room);
      selectedRoomId = matched['id'];
      _updatePriceFromRoom(matched);
    } else if (rooms.isNotEmpty) {
      final first = rooms.first;
      room = first['name'] ?? 'P.101';
      selectedRoomId = first['id'];
      _updatePriceFromRoom(first);
    }

    _guessTenant();

    for (final controller in [
      rent,
      electric,
      water,
      wifi,
      trash,
    ]) {
      controller.addListener(_refresh);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && room.isNotEmpty) {
        _loadMeterReading();
      }
    });
  }

  void _updatePriceFromRoom(Map<String, String> roomData) {
    final rawPrice = roomData['rawPrice'];
    if (rawPrice != null && rawPrice.isNotEmpty && rawPrice != '0') {
      rent.text = rawPrice;
    } else {
      final p = (roomData['price'] ?? '3500000')
          .split('/')
          .first
          .replaceAll(RegExp(r'[^0-9]'), '');
      if (p.isNotEmpty) rent.text = p;
    }
  }

  void _guessTenant() {
    final tenants = tenantList.where(
      (t) => t['room'] != null && t['room']!.contains(room.replaceAll('P.', '')),
    ).toList();
    if (tenants.isNotEmpty) {
      tenantNameController.text = tenants.first['name'] ?? '';
    } else if (tenantNameController.text.isEmpty) {
      tenantNameController.text = 'Nguyễn Văn A';
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final controller in [
      period,
      rent,
      electric,
      water,
      wifi,
      trash,
      tenantNameController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;

    if (room.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn phòng.')),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final month = _getMonthFromPeriod() ?? 'Tháng hiện tại';

      // Tạo mã hóa đơn dựa trên thời gian
      final codeSuffix = DateTime.now().millisecondsSinceEpoch % 10000;
      final invoiceCode = 'HD-${codeSuffix.toString().padLeft(4, '0')}';

      final eUsage = int.tryParse(electric.text) ?? 0;
      final wUsage = int.tryParse(water.text) ?? 0;

      final newInvoice = InvoiceModel(
        id: '', // Firestore sẽ tự sinh Document ID
        invoiceCode: invoiceCode,
        roomId: selectedRoomId ?? room, // id_room chuẩn
        roomName: room,
        ownerId: uid, // owner_room định danh chống trùng phòng
        tenantName: tenantNameController.text.trim().isNotEmpty
            ? tenantNameController.text.trim()
            : 'Chưa cập nhật',
        billingCycle: period.text.trim(),
        month: month,
        roomFee: int.tryParse(rent.text) ?? 0,
        electricOld: electricOldVal,
        electricNew: electricNewVal > 0 ? electricNewVal : electricOldVal + eUsage,
        electricUsage: eUsage,
        electricPrice: 3500,
        electricFee: electricFee,
        waterOld: waterOldVal,
        waterNew: waterNewVal > 0 ? waterNewVal : waterOldVal + wUsage,
        waterUsage: wUsage,
        waterPrice: 20000,
        waterFee: waterFee,
        wifiFee: int.tryParse(wifi.text) ?? 100000,
        trashFee: int.tryParse(trash.text) ?? 20000,
        totalAmount: total,
        paymentMethod: method,
        status: 'Chưa thanh toán',
        createdAt: DateTime.now(),
      );

      final docId = await invoiceService.saveInvoice(newInvoice);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text('Đã lưu hóa đơn $invoiceCode lên Firebase!'),
        ),
      );

      Navigator.pop(context, docId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Lỗi khi lưu hóa đơn: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rooms = availableRooms;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text(
          'Tạo hóa đơn',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF172033),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF172033)),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Chọn phòng
            DropdownButtonFormField<String>(
              value: rooms.any((r) => r['name'] == room) ? room : null,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Chọn phòng',
                prefixIcon: Icon(Icons.meeting_room_outlined),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              items: rooms.map((r) {
                return DropdownMenuItem<String>(
                  value: r['name'],
                  child: Text(
                    '${r['name']} ${r['zone'] != null && r['zone']!.isNotEmpty && r['zone'] != 'Chưa cập nhật' ? '- ${r['zone']}' : ''}',
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  room = value;
                  final roomData = rooms.firstWhere((r) => r['name'] == value);
                  selectedRoomId = roomData['id'];
                  _updatePriceFromRoom(roomData);
                  _guessTenant();
                });
                _loadMeterReading();
              },
            ),
            const SizedBox(height: 14),

            // Tên khách thuê
            FormInput(
              'Tên người thuê',
              tenantNameController,
            ),
            const SizedBox(height: 14),

            // Kỳ thanh toán
            FormInput(
              'Kỳ thanh toán',
              period,
            ),
            const SizedBox(height: 8),

            // Nút load chỉ số
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoadingReading ? null : _loadMeterReading,
                    icon: const Icon(Icons.electric_meter_outlined, size: 18),
                    label: const Text('Đồng bộ chỉ số điện nước'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (isLoadingReading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: 14),

            // Chi tiết các khoản phí
            InfoCard(
              title: 'Chi tiết khoản phí',
              children: [
                FormInput(
                  'Tiền phòng (đ)',
                  rent,
                  number: true,
                ),
                FormInput(
                  'Điện tiêu thụ (kWh) · 3.500đ/kWh',
                  electric,
                  number: true,
                ),
                FormInput(
                  'Nước tiêu thụ (m³) · 20.000đ/m³',
                  water,
                  number: true,
                ),
                FormInput(
                  'WiFi (đ)',
                  wifi,
                  number: true,
                ),
                FormInput(
                  'Đổ rác (đ)',
                  trash,
                  number: true,
                ),
                const SizedBox(height: 8),
                InfoLine(
                  'Tiền điện',
                  InvoiceModel.formatCurrency(electricFee),
                ),
                InfoLine(
                  'Tiền nước',
                  InvoiceModel.formatCurrency(waterFee),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng cộng',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172033),
                      ),
                    ),
                    Text(
                      InvoiceModel.formatCurrency(total),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2160E8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Hình thức thanh toán
            DropdownButtonFormField<String>(
              value: method,
              decoration: const InputDecoration(
                labelText: 'Hình thức thanh toán',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              items: [
                'Chuyển khoản',
                'Tiền mặt',
              ].map((value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    method = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            if (method == 'Chuyển khoản') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: const [
                    PaymentQrPreview(size: 130),
                    SizedBox(height: 10),
                    Text(
                      'Mã QR thanh toán ngân hàng (VietQR)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF61738E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2160E8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Lưu hóa đơn',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
