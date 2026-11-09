import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/record.dart';
import '../widgets/common.dart';
import 'invoice_detail_page.dart';

const tenantTabLabels = [
  'Tổng quan',
  'Hóa đơn',
  'Dịch vụ',
  'Hợp đồng',
  'Bảo trì',
  'Tài khoản',
];

const tenantTabIcons = [
  Icons.home_outlined,
  Icons.receipt_long_outlined,
  Icons.bolt_outlined,
  Icons.description_outlined,
  Icons.handyman_outlined,
  Icons.person_outline_rounded,
];

class TenantPortalContent extends StatelessWidget {
  final int index;
  final Map<String, dynamic> data;
  final ValueChanged<int> onNavigate;
  final VoidCallback onRefresh;

  const TenantPortalContent({
    super.key,
    required this.index,
    required this.data,
    required this.onNavigate,
    required this.onRefresh,
  });

  Map<String, dynamic> get tenant => _asMap(data['tenant']);
  Map<String, dynamic> get room => _asMap(data['room']);
  Map<String, dynamic> get landlord => _asMap(data['landlord']);
  List<Record> get invoices => _records(data['invoices']);
  List<Record> get contracts => _records(data['contracts']);
  List<Record> get services => _records(data['services']);
  List<Record> get meters => _records(data['meters']);
  List<Record> get maintenance => _records(data['maintenance']);

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case 0:
        return _TenantOverview(
          tenant: tenant,
          room: room,
          invoices: invoices,
          contracts: contracts,
          maintenance: maintenance,
          onNavigate: onNavigate,
        );
      case 1:
        return _TenantInvoices(invoices: invoices);
      case 2:
        return _TenantServices(services: services, meters: meters);
      case 3:
        return _TenantContracts(contracts: contracts);
      case 4:
        return _TenantMaintenance(
          maintenance: maintenance,
          roomName: '${room['name'] ?? ''}',
          onRefresh: onRefresh,
        );
      default:
        return _TenantAccount(tenant: tenant, room: room, landlord: landlord);
    }
  }
}

class TenantPortalBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const TenantPortalBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: line, width: 1)),
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 64,
        child: Row(
          children: List.generate(tenantTabLabels.length, (i) {
            final active = selectedIndex == i;
            return Expanded(
              child: InkWell(
                onTap: () => onTap(i),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: active ? softBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tenantTabIcons[i],
                          size: 20,
                          color: active ? blue : muted,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tenantTabLabels[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: active ? blue : muted,
                            fontSize: 9,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    ),
  );
}

class _TenantOverview extends StatelessWidget {
  final Map<String, dynamic> tenant, room;
  final List<Record> invoices, contracts, maintenance;
  final ValueChanged<int> onNavigate;

  const _TenantOverview({
    required this.tenant,
    required this.room,
    required this.invoices,
    required this.contracts,
    required this.maintenance,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final activeContract = contracts
        .where((c) => ['active', 'scheduled'].contains(c.text('status')))
        .firstOrNull;
    final pendingInvoices = invoices
        .where((b) => ['unpaid', 'reported'].contains(b.text('status')))
        .toList();
    final debt = pendingInvoices.fold<num>(
      0,
      (total, bill) => total + (bill.number('total') ?? 0),
    );
    final latestMaintenance = maintenance.isNotEmpty
        ? (maintenance..sort(
                (a, b) => (b.time('createdAt') ?? DateTime(2000)).compareTo(
                  a.time('createdAt') ?? DateTime(2000),
                ),
              ))
              .first
        : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      children: [
        Text(
          'Xin chào, ${tenant['name'] ?? 'bạn'}',
          style: const TextStyle(
            color: ink,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Thông tin thuê phòng của bạn',
          style: TextStyle(color: muted, fontSize: 12.5),
        ),
        const SizedBox(height: 14),
        _portalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: softBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.meeting_room_outlined, color: blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${room['name'] ?? 'Phòng thuê'}',
                          style: const TextStyle(
                            color: ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${room['condition'] ?? 'Đang thuê'}',
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  statusPill(activeContract?.text('status') ?? 'active'),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 13),
                child: Divider(height: 1, color: line),
              ),
              _InfoLine(
                label: 'Tiền thuê',
                value: money(activeContract?.data['rent'] ?? room['price']),
              ),
              if ('${room['billingDay'] ?? ''}'.isNotEmpty)
                _InfoLine(
                  label: 'Ngày chốt tiền',
                  value: '${room['billingDay']}',
                ),
              if (room['paymentTermDays'] != null)
                _InfoLine(
                  label: 'Hạn thanh toán',
                  value: '${room['paymentTermDays']} ngày',
                ),
              if (activeContract != null) ...[
                const SizedBox(height: 8),
                _InfoLine(
                  label: 'Thời hạn',
                  value:
                      '${_date(activeContract.text('startDate'))} – ${_date(activeContract.text('endDate'))}',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                icon: Icons.payments_outlined,
                title: 'Cần thanh toán',
                value: money(debt),
                caption: '${pendingInvoices.length} hóa đơn',
                onTap: () => onNavigate(1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryTile(
                icon: Icons.handyman_outlined,
                title: 'Bảo trì',
                value: latestMaintenance == null
                    ? 'Chưa có'
                    : label(latestMaintenance.text('status')),
                caption: latestMaintenance?.text('title') ?? 'Theo dõi yêu cầu',
                onTap: () => onNavigate(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _portalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Truy cập nhanh',
                style: TextStyle(
                  color: ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickLink(
                    icon: Icons.receipt_long_outlined,
                    label: 'Hóa đơn',
                    onTap: () => onNavigate(1),
                  ),
                  _QuickLink(
                    icon: Icons.bolt_outlined,
                    label: 'Dịch vụ',
                    onTap: () => onNavigate(2),
                  ),
                  _QuickLink(
                    icon: Icons.description_outlined,
                    label: 'Hợp đồng',
                    onTap: () => onNavigate(3),
                  ),
                  _QuickLink(
                    icon: Icons.handyman_outlined,
                    label: 'Gửi yêu cầu',
                    onTap: () => onNavigate(4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TenantInvoices extends StatefulWidget {
  final List<Record> invoices;
  const _TenantInvoices({required this.invoices});

  @override
  State<_TenantInvoices> createState() => _TenantInvoicesState();
}

class _TenantInvoicesState extends State<_TenantInvoices> {
  String filter = 'all';

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.invoices]
      ..sort((a, b) => b.text('period').compareTo(a.text('period')));
    final visible = sorted.where((bill) {
      if (filter == 'all') return true;
      if (filter == 'unpaid') return bill.text('status') == 'unpaid';
      if (filter == 'reported') return bill.text('status') == 'reported';
      return bill.text('status') == 'paid';
    }).toList();
    final outstanding = widget.invoices
        .where((b) => ['unpaid', 'reported'].contains(b.text('status')))
        .fold<num>(0, (total, b) => total + (b.number('total') ?? 0));

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
      children: [
        _portalCard(
          color: blue,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tổng cần thanh toán',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 5),
              Text(
                money(outstanding),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.invoices.length} hóa đơn đã gửi',
                style: const TextStyle(color: Colors.white70, fontSize: 11.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final item in const [
                ('all', 'Tất cả'),
                ('unpaid', 'Chưa thanh toán'),
                ('reported', 'Chờ xác nhận'),
                ('paid', 'Đã thanh toán'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: figmaFilterPill(
                    label: item.$2,
                    selected: filter == item.$1,
                    onTap: () => setState(() => filter = item.$1),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (visible.isEmpty) empty('Chưa có hóa đơn trong mục này'),
        for (final bill in visible)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: line, width: 0.7),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 4,
              ),
              title: Text(
                '${bill.text('roomName')} · ${bill.text('period')}',
                style: const TextStyle(
                  color: ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  '${money(bill.data['total'])}  •  Hạn: ${bill.text('dueDate', 'Chưa cập nhật')}',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
              ),
              trailing: statusPill(bill.text('status')),
              onTap: () => openPage(
                context,
                InvoiceDetailPage(invoiceId: bill.id, landlord: false),
              ),
            ),
          ),
      ],
    );
  }
}

class _TenantServices extends StatelessWidget {
  final List<Record> services, meters;
  const _TenantServices({required this.services, required this.meters});

  @override
  Widget build(BuildContext context) {
    final ordered = [...services]..sort((a, b) => a.name.compareTo(b.name));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        const Text(
          'Dịch vụ áp dụng cho phòng',
          style: TextStyle(
            color: ink,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (ordered.isEmpty) empty('Chưa có dịch vụ được áp dụng'),
        for (final service in ordered)
          Builder(
            builder: (context) {
              final readings =
                  meters
                      .where((m) => m.text('serviceId') == service.id)
                      .toList()
                    ..sort(
                      (a, b) => b.text('period').compareTo(a.text('period')),
                    );
              final latest = readings.firstOrNull;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: line, width: 0.7),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          serviceBadge(
                            service.name,
                            mode: service.text('mode'),
                            size: 38,
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.name,
                                  style: const TextStyle(
                                    color: ink,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  label(service.text('mode')),
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${money(service.data['price'])}/${service.text('unit', 'kỳ')}',
                            style: const TextStyle(
                              color: ink,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (latest != null) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 11),
                          child: Divider(height: 1, color: line),
                        ),
                        _InfoLine(
                          label: 'Chỉ số kỳ ${latest.text('period')}',
                          value:
                              '${latest.text('previous')} → ${latest.text('current')}',
                        ),
                        _InfoLine(
                          label: 'Sản lượng',
                          value:
                              '${(latest.number('current') ?? 0) - (latest.number('previous') ?? 0)} ${service.text('unit')}',
                        ),
                      ],
                      if (service.text('description').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          service.text('description'),
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 6),
        const Text(
          'Số tiền dịch vụ được tổng hợp trong hóa đơn từng kỳ.',
          style: TextStyle(color: muted, fontSize: 11.5),
        ),
      ],
    );
  }
}

class _TenantContracts extends StatelessWidget {
  final List<Record> contracts;
  const _TenantContracts({required this.contracts});

  @override
  Widget build(BuildContext context) {
    final ordered = [...contracts]
      ..sort((a, b) => b.text('startDate').compareTo(a.text('startDate')));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        if (ordered.isEmpty) empty('Chưa có hợp đồng được liên kết'),
        for (final contract in ordered)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: line, width: 0.7),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 4,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: softBlue,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: blue,
                  size: 22,
                ),
              ),
              title: Text(
                contract.text('number', contract.id),
                style: const TextStyle(
                  color: ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${_date(contract.text('startDate'))} – ${_date(contract.text('endDate'))}',
                  style: const TextStyle(color: muted, fontSize: 11.5),
                ),
              ),
              trailing: statusPill(contract.text('status')),
              children: [
                const Divider(height: 1, color: line),
                const SizedBox(height: 10),
                _InfoLine(
                  label: 'Tiền thuê mỗi tháng',
                  value: money(contract.data['rent']),
                ),
                _InfoLine(
                  label: 'Tiền đặt cọc',
                  value: money(contract.data['deposit']),
                ),
                if (contract.text('paymentDay').isNotEmpty)
                  _InfoLine(
                    label: 'Ngày thanh toán',
                    value: contract.text('paymentDay'),
                  ),
                if (contract.text('paymentTermDays').isNotEmpty)
                  _InfoLine(
                    label: 'Thời hạn thanh toán',
                    value: '${contract.text('paymentTermDays')} ngày',
                  ),
                if (contract.text('note').isNotEmpty) ...[
                  const SizedBox(height: 9),
                  const Text(
                    'Điều khoản',
                    style: TextStyle(
                      color: ink,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contract.text('note'),
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        const Text(
          'Nếu cần điều chỉnh hoặc gia hạn, vui lòng liên hệ chủ trọ.',
          style: TextStyle(color: muted, fontSize: 11.5),
        ),
      ],
    );
  }
}

class _TenantMaintenance extends StatelessWidget {
  final List<Record> maintenance;
  final String roomName;
  final VoidCallback onRefresh;
  const _TenantMaintenance({
    required this.maintenance,
    required this.roomName,
    required this.onRefresh,
  });

  Future<void> _newRequest(BuildContext context) async {
    final request = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _TenantMaintenanceForm(),
    );
    if (request == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await store.tenantPortal(action: 'createMaintenance', data: request);
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (!context.mounted) return;
      onRefresh();
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã gửi yêu cầu bảo trì')),
      );
    } catch (error) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        message(context, errorText(error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordered = [...maintenance]
      ..sort(
        (a, b) => (b.time('createdAt') ?? DateTime(2000)).compareTo(
          a.time('createdAt') ?? DateTime(2000),
        ),
      );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        _portalCard(
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: blue, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Gửi yêu cầu sửa chữa cho phòng $roomName. Chủ trọ sẽ cập nhật tiến độ tại đây.',
                  style: const TextStyle(color: ink, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 46,
          child: FilledButton.icon(
            onPressed: () => _newRequest(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tạo yêu cầu bảo trì'),
          ),
        ),
        const SizedBox(height: 16),
        if (ordered.isEmpty) empty('Bạn chưa gửi yêu cầu bảo trì nào'),
        for (final item in ordered)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: line, width: 0.7),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.text('title'),
                        style: const TextStyle(
                          color: ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    statusPill(
                      item.text('status'),
                      customText: item.text('status') == 'new' ? 'Mới' : null,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${item.text('issueType')} · Ưu tiên ${item.text('priority')}',
                  style: const TextStyle(color: muted, fontSize: 11.5),
                ),
                if (item.text('description').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.text('description'),
                    style: const TextStyle(color: ink, fontSize: 12.5),
                  ),
                ],
                const SizedBox(height: 7),
                Text(
                  'Cập nhật: ${_dateTime(item.time('updatedAt') ?? item.time('createdAt'))}',
                  style: const TextStyle(color: muted, fontSize: 10.5),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TenantMaintenanceForm extends StatefulWidget {
  const _TenantMaintenanceForm();

  @override
  State<_TenantMaintenanceForm> createState() => _TenantMaintenanceFormState();
}

class _TenantMaintenanceFormState extends State<_TenantMaintenanceForm> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  String issueType = 'Thiết bị';
  String priority = 'Trung bình';

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    title: const Text(
      'Yêu cầu bảo trì',
      style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w700),
    ),
    content: Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: titleController,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Sự cố cần sửa'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Vui lòng nhập tiêu đề'
                  : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: descriptionController,
              minLines: 3,
              maxLines: 5,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Mô tả chi tiết',
                alignLabelWithHint: true,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Vui lòng mô tả sự cố'
                  : null,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: issueType,
              decoration: const InputDecoration(labelText: 'Loại sự cố'),
              items: const [
                DropdownMenuItem(value: 'Thiết bị', child: Text('Thiết bị')),
                DropdownMenuItem(
                  value: 'Điện / Nước',
                  child: Text('Điện / Nước'),
                ),
                DropdownMenuItem(value: 'Nội thất', child: Text('Nội thất')),
                DropdownMenuItem(value: 'Khác', child: Text('Khác')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => issueType = value);
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: priority,
              decoration: const InputDecoration(labelText: 'Mức độ ưu tiên'),
              items: const [
                DropdownMenuItem(value: 'Thấp', child: Text('Thấp')),
                DropdownMenuItem(
                  value: 'Trung bình',
                  child: Text('Trung bình'),
                ),
                DropdownMenuItem(value: 'Cao', child: Text('Cao')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => priority = value);
              },
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Đóng'),
      ),
      FilledButton(
        onPressed: () {
          if (!formKey.currentState!.validate()) return;
          Navigator.pop(context, {
            'title': titleController.text.trim(),
            'description': descriptionController.text.trim(),
            'issueType': issueType,
            'priority': priority,
          });
        },
        child: const Text('Gửi yêu cầu'),
      ),
    ],
  );
}

class _TenantAccount extends StatelessWidget {
  final Map<String, dynamic> tenant, room, landlord;
  const _TenantAccount({
    required this.tenant,
    required this.room,
    required this.landlord,
  });

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final tenantName = '${tenant['name'] ?? 'Người thuê'}';
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
      children: [
        _portalCard(
          child: Row(
            children: [
              initialAvatar(
                tenantName,
                size: 56,
                solidBlue: false,
                twoLetters: true,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenantName,
                      style: const TextStyle(
                        color: ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: muted, fontSize: 11.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Người thuê · Phòng ${room['name'] ?? ''}',
                      style: const TextStyle(color: blue, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _portalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông tin liên hệ chủ trọ',
                style: TextStyle(
                  color: ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _InfoLine(
                label: 'Chủ trọ',
                value: '${landlord['name'] ?? ''}'.isEmpty
                    ? 'Chưa cập nhật'
                    : '${landlord['name']}',
              ),
              _InfoLine(
                label: 'Số điện thoại',
                value: '${landlord['phone'] ?? ''}'.isEmpty
                    ? 'Chưa cập nhật'
                    : '${landlord['phone']}',
              ),
              if ('${landlord['address'] ?? ''}'.isNotEmpty)
                _InfoLine(label: 'Địa chỉ', value: '${landlord['address']}'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _portalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bảo mật tài khoản',
                style: TextStyle(
                  color: ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Gửi liên kết đặt lại mật khẩu đến email đăng nhập của bạn.',
                style: TextStyle(color: muted, fontSize: 11.5),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: email.isEmpty
                    ? null
                    : () async {
                        try {
                          await FirebaseAuth.instance.sendPasswordResetEmail(
                            email: email,
                          );
                          if (context.mounted) {
                            message(context, 'Đã gửi email đặt lại mật khẩu');
                          }
                        } catch (error) {
                          if (context.mounted) {
                            message(context, errorText(error));
                          }
                        }
                      },
                icon: const Icon(Icons.lock_reset_rounded, size: 18),
                label: const Text('Đặt lại mật khẩu'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String title, value, caption;
  final VoidCallback onTap;
  const _SummaryTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.caption,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(15),
    onTap: onTap,
    child: _portalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: blue),
          const SizedBox(height: 9),
          Text(title, style: const TextStyle(color: muted, fontSize: 11.5)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: muted, fontSize: 10.5),
          ),
        ],
      ),
    ),
  );
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 17),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 38),
      padding: const EdgeInsets.symmetric(horizontal: 11),
      textStyle: const TextStyle(fontSize: 11.5),
    ),
  );
}

class _InfoLine extends StatelessWidget {
  final String label, value;
  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: muted, fontSize: 12),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _portalCard({required Widget child, Color color = Colors.white}) =>
    Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: color == Colors.white
            ? Border.all(color: line, width: 0.7)
            : null,
      ),
      child: child,
    );

Map<String, dynamic> _asMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<Record> _records(dynamic value) {
  if (value is! List) return [];
  return value.whereType<Map>().map((item) {
    final data = Map<String, dynamic>.from(item);
    final id = '${data.remove('id') ?? ''}';
    return Record(id, data);
  }).toList();
}

String _date(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value.isEmpty ? 'Chưa cập nhật' : value;
  return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
}

String _dateTime(DateTime? value) {
  if (value == null) return 'Chưa cập nhật';
  final date = value.toLocal();
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
