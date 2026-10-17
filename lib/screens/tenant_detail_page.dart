import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../widgets/form_widgets.dart';
import 'room_page.dart';
import 'tenant_edit_page.dart';
import 'contract_detail_page.dart';

class TenantDetailPage extends StatefulWidget {
  final Map<String, String> tenant;
  final bool full;
  const TenantDetailPage({super.key, required this.tenant, this.full = false});
  @override
  State<TenantDetailPage> createState() => _TenantDetailPageState();
}

class _TenantDetailPageState extends State<TenantDetailPage> {
  Future<void> _edit() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => TenantEditPage(tenant: widget.tenant)),
    );
    if (!mounted || result == null) return;
    setState(() => widget.tenant.addAll(result));
  }

  void _contract() {
    final matches = contractList
        .where((c) => c['name'] == widget.tenant['name'])
        .toList();
    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Người thuê này chưa có hợp đồng mẫu')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContractDetailPage(contract: matches.first),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tenant;
    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        title: Text(
          widget.full ? 'Thông tin chi tiết' : 'Thông tin thuê phòng',
        ),
        actions: [TextButton(onPressed: _edit, child: const Text('Chỉnh sửa'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InfoCard(
            title: t['name'] ?? '',
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: blue,
                child: Icon(Icons.person, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 12),
              Text(t['room'] ?? '', textAlign: TextAlign.center),
              Text(
                t['status'] ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.green),
              ),
              InfoLine('Hợp đồng thuê', t['contract'] ?? ''),
            ],
          ),
          if (widget.full)
            InfoCard(
              title: 'Thông tin khách thuê',
              children: [
                InfoLine('Họ và tên', t['name'] ?? ''),
                InfoLine('Ngày sinh', t['birthday'] ?? ''),
                InfoLine('Giới tính', t['gender'] ?? ''),
                InfoLine('Số điện thoại', t['phone'] ?? ''),
                InfoLine('Email', t['email'] ?? ''),
                InfoLine('Quê quán', t['address'] ?? ''),
                InfoLine('Nghề nghiệp', t['job'] ?? ''),
                InfoLine('Đăng ký tạm trú', t['residence'] ?? ''),
                InfoLine('CCCD/Passport', t['identity'] ?? ''),
                InfoLine('Ghi chú', t['note'] ?? ''),
              ],
            )
          else ...[
            InfoCard(
              title: 'Thông tin liên hệ',
              children: [
                InfoLine('Số điện thoại', t['phone'] ?? ''),
                InfoLine('Email', t['email'] ?? ''),
                InfoLine('CCCD', t['identity'] ?? ''),
                TextButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TenantDetailPage(tenant: t, full: true),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                  child: const Text('Xem chi tiết →'),
                ),
              ],
            ),
            InfoCard(
              title: 'Thông tin thuê phòng',
              children: [
                InfoLine('Tiền phòng', '${money(t['rent'])} / tháng'),
                InfoLine('Tiền đặt cọc', money(t['deposit'])),
                InfoLine('Ngày bắt đầu', t['start'] ?? ''),
                InfoLine('Ngày kết thúc', t['end'] ?? ''),
                TextButton(
                  onPressed: _contract,
                  child: const Text('Xem hợp đồng →'),
                ),
              ],
            ),
          ],
        ],
      ),
      bottomNavigationBar: const AppBottomBar(selected: 1),
    );
  }
}
