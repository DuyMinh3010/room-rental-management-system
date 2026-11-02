import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/record.dart';
import '../widgets/common.dart';
import 'room_page.dart';
import 'tenant_list_page.dart';
import 'service_page.dart';
import 'invoice_page.dart';
import 'contract_page.dart';
import 'maintenance_page.dart';
import 'account_page.dart';
import 'notification_page.dart';
import 'invoice_detail_page.dart';

class AppShell extends StatefulWidget {
  final bool landlord;
  const AppShell({super.key, required this.landlord});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int index = 0;
  bool checking = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBilling());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkBilling();
  }

  Future<void> _checkBilling() async {
    if (!widget.landlord || checking) return;
    checking = true;
    try {
      await store.command('runBilling');
    } catch (e) {
      if (mounted) message(context, 'Chưa kiểm tra được hóa đơn: $e');
    } finally {
      checking = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.landlord) return _tenantView(context);
    final pages = [
      const RoomPage(),
      const TenantListPage(),
      const ServicePage(),
      const InvoicePage(),
      const ContractPage(),
      const MaintenancePage(),
      const AccountPage(),
    ];
    return Scaffold(
      backgroundColor: canvas,
      body: pages[index],
      bottomNavigationBar: RrmsBottomBar(
        selectedIndex: index,
        onTap: (v) => setState(() => index = v),
      ),
    );
  }

  Widget _tenantView(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    appBar: AppBar(
      title: const Text('Hóa đơn của tôi'),
      actions: [
        const NotificationButton(landlord: false),
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
          },
        ),
      ],
    ),
    body: RecordsView(
      collection: 'invoices',
      field: 'recipientUid',
      equals: store.uid,
      builder: (_, all) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          box(
            const Text(
              'Nếu bạn là chủ trọ, UID cần có trong managers với enabled = true. Nếu là người thuê, nhờ chủ trọ liên kết UID tài khoản vào hồ sơ người thuê.',
              style: TextStyle(color: muted, fontSize: 12.5),
            ),
          ),
          if (all.isEmpty) empty('Chưa có hóa đơn được gửi cho tài khoản này'),
          for (final b in all)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: line, width: 0.7),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                title: Text(
                  '${b.text('roomName')} · ${b.text('period')}',
                  style: const TextStyle(
                    color: ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${money(b.data['total'])}  •  Hạn: ${b.text('dueDate')}',
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                ),
                trailing: statusPill(b.text('status')),
                onTap: () => openPage(
                  context,
                  InvoiceDetailPage(invoiceId: b.id, landlord: false),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
