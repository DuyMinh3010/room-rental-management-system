import 'package:flutter/material.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';
import '../widgets/payment_qr_preview.dart';
import 'room_page.dart';

class InvoiceDetailPage extends StatefulWidget {
  final String? invoiceId;
  final dynamic invoice; // Hỗ trợ cả InvoiceModel và Map<String, String>
  final Map<String, String>? legacyInvoice;

  const InvoiceDetailPage({
    super.key,
    this.invoiceId,
    this.invoice,
    this.legacyInvoice,
  });

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  final InvoiceService _service = InvoiceService();
  bool _isUpdating = false;

  String get targetId {
    if (widget.invoiceId != null && widget.invoiceId!.isNotEmpty) {
      return widget.invoiceId!;
    }
    if (widget.invoice != null) {
      if (widget.invoice is InvoiceModel) {
        return (widget.invoice as InvoiceModel).id;
      }
      if (widget.invoice is Map) {
        return widget.invoice['id']?.toString() ?? '';
      }
    }
    if (widget.legacyInvoice != null) {
      return widget.legacyInvoice!['id'] ?? '';
    }
    return '';
  }

  InvoiceModel? get initialInvoiceModel {
    if (widget.invoice is InvoiceModel) {
      return widget.invoice as InvoiceModel;
    }
    if (widget.invoice is Map) {
      return _resolveInvoiceFromLegacy(Map<String, dynamic>.from(widget.invoice as Map));
    }
    if (widget.legacyInvoice != null) {
      return _resolveInvoiceFromLegacy(widget.legacyInvoice!);
    }
    return null;
  }

  Future<void> _confirmPayment(InvoiceModel bill) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Xác nhận đã thanh toán',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Bạn có chắc chắn muốn đánh dấu hóa đơn ${bill.invoiceCode} phòng ${bill.roomName} là đã thanh toán?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (!mounted || yes != true) return;

    setState(() => _isUpdating = true);

    try {
      if (bill.id.isNotEmpty && !bill.id.startsWith('HD-')) {
        await _service.markAsPaid(bill.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text('Hóa đơn ${bill.invoiceCode} đã chuyển sang "Đã thanh toán"!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Lỗi khi cập nhật trạng thái: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _deleteInvoice(InvoiceModel bill) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa hóa đơn'),
        content: Text('Bạn có chắc chắn muốn xóa hóa đơn ${bill.invoiceCode}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (!mounted || yes != true) return;

    try {
      if (bill.id.isNotEmpty) {
        await _service.deleteInvoice(bill.id);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa hóa đơn thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xóa hóa đơn: $e')),
        );
      }
    }
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildLine(String label, String value, {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: muted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;

    if (status == 'Đã thanh toán') {
      bg = const Color(0xFFE8F8F0);
      text = const Color(0xFF10B981);
    } else if (status == 'Quá hạn') {
      bg = const Color(0xFFFEE2E2);
      text = const Color(0xFFEF4444);
    } else {
      bg = const Color(0xFFFEF3C7);
      text = const Color(0xFFD97706);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: text,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  InvoiceModel _resolveInvoiceFromLegacy(Map<dynamic, dynamic> m) {
    int pInt(dynamic v) =>
        int.tryParse((v?.toString() ?? '0').replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    return InvoiceModel(
      id: m['id']?.toString() ?? '',
      invoiceCode: m['id']?.toString() ?? 'HD-0000',
      roomId: m['room']?.toString() ?? 'P.101',
      roomName: m['room']?.toString() ?? 'P.101',
      ownerId: '',
      tenantName: m['tenant']?.toString() ?? 'Chưa rõ',
      billingCycle: m['period']?.toString() ?? '01/05/2026 - 31/05/2026',
      month: '05/2026',
      roomFee: pInt(m['rent']),
      electricFee: pInt(m['electric']),
      waterFee: pInt(m['water']),
      wifiFee: pInt(m['wifi']),
      trashFee: pInt(m['trash']),
      totalAmount: pInt(m['price']),
      paymentMethod: m['method']?.toString() ?? 'Chuyển khoản',
      status: m['status']?.toString() ?? 'Chưa thanh toán',
    );
  }

  Widget _buildDetailView(InvoiceModel bill) {
    final paid = bill.status == 'Đã thanh toán';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Thẻ thông tin chung hóa đơn
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    bill.invoiceCode,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ink,
                    ),
                  ),
                  _buildStatusBadge(bill.status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              _buildLine('Phòng', bill.roomName, bold: true),
              _buildLine('Khách thuê', bill.tenantName),
              _buildLine('Kỳ thanh toán', bill.billingCycle),
              if (bill.roomId != bill.roomName && bill.roomId.isNotEmpty)
                _buildLine('Mã phòng (id_room)', bill.roomId),
            ],
          ),
        ),

        // 2. Thẻ chi tiết các khoản phí
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chi tiết khoản phí',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: ink,
                ),
              ),
              const SizedBox(height: 12),
              _buildLine('Tiền phòng', InvoiceModel.formatCurrency(bill.roomFee)),
              _buildLine(
                bill.electricUsage > 0
                    ? 'Điện (${bill.electricUsage} kWh)'
                    : 'Điện',
                InvoiceModel.formatCurrency(bill.electricFee),
              ),
              _buildLine(
                bill.waterUsage > 0
                    ? 'Nước (${bill.waterUsage} m³)'
                    : 'Nước',
                InvoiceModel.formatCurrency(bill.waterFee),
              ),
              _buildLine('WiFi', InvoiceModel.formatCurrency(bill.wifiFee)),
              _buildLine('Đổ rác', InvoiceModel.formatCurrency(bill.trashFee)),
              if (bill.parkingFee > 0)
                _buildLine('Gửi xe', InvoiceModel.formatCurrency(bill.parkingFee)),
              if (bill.otherFee > 0)
                _buildLine('Phí khác', InvoiceModel.formatCurrency(bill.otherFee)),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng cộng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ink,
                    ),
                  ),
                  Text(
                    InvoiceModel.formatCurrency(bill.totalAmount),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 3. Thẻ hình thức thanh toán & Mã QR
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Hình thức thanh toán',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: ink,
                    ),
                  ),
                  Text(
                    bill.paymentMethod,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (bill.paymentMethod == 'Chuyển khoản') ...[
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        const PaymentQrPreview(size: 140),
                        const SizedBox(height: 8),
                        Text(
                          'Quét mã để thanh toán ${bill.invoiceCode}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Nội dung: ${bill.invoiceCode.replaceAll('-', '')} ${bill.roomName.replaceAll('.', '')}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: ink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Thanh toán trực tiếp bằng tiền mặt cho chủ trọ.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: muted),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 4. Nút hành động
        if (!paid)
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _isUpdating ? null : () => _confirmPayment(bill),
              style: FilledButton.styleFrom(
                backgroundColor: blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isUpdating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Xác nhận đã thanh toán',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8F0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                SizedBox(width: 8),
                Text(
                  'Hóa đơn này đã được thanh toán',
                  style: TextStyle(
                    color: Color(0xFF065F46),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 30),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (targetId.isNotEmpty && !targetId.startsWith('HD-')) {
      return StreamBuilder<InvoiceModel?>(
        stream: _service.watchInvoice(targetId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: canvas,
              appBar: AppBar(
                title: const Text('Chi tiết hóa đơn'),
                backgroundColor: Colors.white,
                elevation: 0,
                iconTheme: const IconThemeData(color: ink),
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          final bill = snapshot.data ?? initialInvoiceModel;

          if (bill == null) {
            return Scaffold(
              backgroundColor: canvas,
              appBar: AppBar(
                title: const Text('Chi tiết hóa đơn'),
                backgroundColor: Colors.white,
                elevation: 0,
                iconTheme: const IconThemeData(color: ink),
              ),
              body: const Center(
                child: Text('Không tìm thấy thông tin hóa đơn này.'),
              ),
            );
          }

          return Scaffold(
            backgroundColor: canvas,
            appBar: AppBar(
              title: const Text(
                'Chi tiết hóa đơn',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ink,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: ink),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Xóa hóa đơn',
                  onPressed: () => _deleteInvoice(bill),
                ),
              ],
            ),
            body: _buildDetailView(bill),
          );
        },
      );
    }

    final bill = initialInvoiceModel;

    if (bill == null) {
      return Scaffold(
        backgroundColor: canvas,
        appBar: AppBar(
          title: const Text('Chi tiết hóa đơn'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: Text('Không có dữ liệu hóa đơn')),
      );
    }

    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        title: const Text(
          'Chi tiết hóa đơn',
          style: TextStyle(fontWeight: FontWeight.bold, color: ink),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: ink),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Xóa hóa đơn',
            onPressed: () => _deleteInvoice(bill),
          ),
        ],
      ),
      body: _buildDetailView(bill),
    );
  }
}
