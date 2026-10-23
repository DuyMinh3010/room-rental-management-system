import 'package:flutter/material.dart';

import 'room_page.dart';
import 'service_page.dart';
import 'invoice_create_page.dart';
import 'invoice_detail_page.dart';
import '../utils/formatters.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final invoices = <Map<String, String>>[];

  Future<void> _create() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => const InvoiceCreatePage()),
    );
    if (result == null || !mounted) return;
    setState(() => invoices.add(result));
  }

  Future<void> _detail(Map<String, String> bill) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InvoiceDetailPage(invoice: bill)),
    );
    if (mounted) setState(() {});
  }

  void _meter() => _open(const ServicePage());

  void _open(Widget page) =>
      Navigator.push<void>(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          "Tháng 09/2026",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  ElevatedButton(
                    onPressed: _create,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEAF0FF),
                      foregroundColor: const Color(0xFF2F67EA),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Text(
                      "Tạo hóa đơn",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 27),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B86F6),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Tổng cần thu",
                      style: TextStyle(color: Color(0xFFDCE9FF), fontSize: 13),
                    ),

                    SizedBox(height: 8),

                    Text(
                      money(
                        '${invoices.where((b) => b['status'] != 'Đã thanh toán').fold<int>(0, (sum, b) => sum + int.parse(b['price']!.replaceAll(RegExp(r'[^0-9]'), '')))}',
                      ),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 6),

                    Text(
                      "${invoices.where((b) => b['status'] == 'Đã thanh toán').length} đã trả · ${invoices.where((b) => b['status'] != 'Đã thanh toán').length} chưa trả",
                      style: TextStyle(color: Color(0xFFDCE9FF), fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              const Text(
                "Hóa đơn tháng này",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF202533),
                ),
              ),

              const SizedBox(height: 13),

              if (invoices.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('Chưa có hóa đơn')),
                ),

              ...invoices.map(
                (invoice) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _invoiceCard(
                    bill: invoice,
                    roomNumber: invoice["room"]!,
                    amount: invoice["price"]!,
                    status: invoice["status"]!,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                "Ghi số điện nước",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF202533),
                ),
              ),

              const SizedBox(height: 13),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
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
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 13),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Nhập chỉ số tháng 09",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF202533),
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            "Còn 3 phòng chưa nhập",
                            style: TextStyle(fontSize: 11, color: Colors.grey),
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
                          horizontal: 13,
                          vertical: 9,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Nhập",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: const AppBottomBar(selected: 3),
    );
  }

  Widget _invoiceCard({
    required Map<String, String> bill,
    required String roomNumber,
    required String amount,
    required String status,
  }) {
    Color statusBackground;
    Color statusText;

    if (status == "Đã thanh toán") {
      statusBackground = const Color(0xFFE7F8ED);
      statusText = const Color(0xFF16A15D);
    } else if (status == "Chưa thanh toán") {
      statusBackground = const Color(0xFFFFEAEA);
      statusText = const Color(0xFFE74747);
    } else {
      statusBackground = const Color(0xFFFFF0DE);
      statusText = const Color(0xFFE88623);
    }

    return InkWell(
      onTap: () {
        _detail(bill);
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roomNumber,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF202533),
                    ),
                  ),

                  const SizedBox(height: 7),

                  const Text(
                    "Tiền phòng + điện + nước + dịch vụ",
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    amount,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF202533),
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
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusText,
                    ),
                  ),
                ),

                const SizedBox(height: 21),

                const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
