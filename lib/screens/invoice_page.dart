import 'package:flutter/material.dart';

import '../models/invoice.dart';
import '../services/invoice_service.dart';
import 'room_page.dart';
import 'meter_reading_screen.dart';
import 'invoice_create_page.dart';
import 'invoice_detail_page.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final InvoiceService _invoiceService = InvoiceService();
  int _currentFilter = 0; // 0: Tất cả, 1: Chưa thanh toán, 2: Đã thanh toán

  Future<void> _create() async {
    await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(builder: (_) => const InvoiceCreatePage()),
    );
  }

  Future<void> _detail(InvoiceModel bill) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceDetailPage(
          invoiceId: bill.id,
          invoice: bill,
        ),
      ),
    );
  }

  void _meter() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const MeterReadingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: StreamBuilder<List<InvoiceModel>>(
          stream: _invoiceService.watchInvoices(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allInvoices = snapshot.data ?? [];

            // Lọc hóa đơn theo tab
            final filteredInvoices = allInvoices.where((inv) {
              if (_currentFilter == 1) {
                return inv.status != 'Đã thanh toán';
              }
              if (_currentFilter == 2) {
                return inv.status == 'Đã thanh toán';
              }
              return true;
            }).toList();

            // Tính toán tổng tiền
            final unpaidInvoices =
                allInvoices.where((b) => b.status != 'Đã thanh toán');
            final totalNeedCollect = unpaidInvoices.fold<int>(
              0,
              (sum, b) => sum + b.totalAmount,
            );
            final paidCount =
                allInvoices.where((b) => b.status == 'Đã thanh toán').length;
            final unpaidCount = unpaidInvoices.length;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Hóa đơn",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF202533),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Quản lý tính tiền & hóa đơn",
                              style:
                                  TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _create,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(
                          "Tạo hóa đơn",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEAF0FF),
                          foregroundColor: const Color(0xFF2F67EA),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Thẻ Banner Tổng cần thu
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2463F5), Color(0xFF3B86F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2463F5).withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tổng cần thu",
                          style: TextStyle(
                            color: Color(0xFFDCE9FF),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          InvoiceModel.formatCurrency(totalNeedCollect),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "$paidCount đã trả · $unpaidCount chưa trả",
                          style: const TextStyle(
                            color: Color(0xFFDCE9FF),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bộ lọc trạng thái hóa đơn
                  Row(
                    children: [
                      _buildFilterChip('Tất cả (${allInvoices.length})', 0),
                      const SizedBox(width: 8),
                      _buildFilterChip('Chưa trả ($unpaidCount)', 1),
                      const SizedBox(width: 8),
                      _buildFilterChip('Đã trả ($paidCount)', 2),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Danh sách hóa đơn
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Hóa đơn theo phòng",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF202533),
                        ),
                      ),
                      Text(
                        "${filteredInvoices.length} hóa đơn",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF61738E),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 13),

                  if (filteredInvoices.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 36,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Chưa có hóa đơn nào",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF172033),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Bấm 'Tạo hóa đơn' để lập hóa đơn thu tiền cho các phòng.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filteredInvoices.map(
                      (invoice) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _invoiceCard(invoice),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Thẻ Ghi sổ điện nước
                  const Text(
                    "Ghi sổ điện nước",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF202533),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF0FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: Color(0xFFFFB020),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 13),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Nhập chỉ số điện nước",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF202533),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Ghi chỉ số hàng tháng cho các phòng",
                                style:
                                    TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _meter,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEAF0FF),
                            foregroundColor: const Color(0xFF2F67EA),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            "Nhập",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const AppBottomBar(selected: 3),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final selected = _currentFilter == index;
    return InkWell(
      onTap: () => setState(() => _currentFilter = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2463F5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF2463F5) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.white : const Color(0xFF61738E),
          ),
        ),
      ),
    );
  }

  Widget _invoiceCard(InvoiceModel invoice) {
    Color statusBackground;
    Color statusText;

    if (invoice.status == "Đã thanh toán") {
      statusBackground = const Color(0xFFE7F8ED);
      statusText = const Color(0xFF16A15D);
    } else if (invoice.status == "Quá hạn") {
      statusBackground = const Color(0xFFFFF0DE);
      statusText = const Color(0xFFE88623);
    } else {
      statusBackground = const Color(0xFFFFEAEA);
      statusText = const Color(0xFFE74747);
    }

    return InkWell(
      onTap: () => _detail(invoice),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        invoice.roomName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF202533),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "(${invoice.invoiceCode})",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8993A3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Kỳ: ${invoice.billingCycle} · ${invoice.tenantName}",
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    InvoiceModel.formatCurrency(invoice.totalAmount),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2463F5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    invoice.status,
                    style: TextStyle(
                      color: statusText,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFC0C7D2),
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
