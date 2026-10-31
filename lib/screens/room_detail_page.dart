import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/room_service.dart';
import '../services/tenant_service.dart';
import '../services/invoice_service.dart';
import '../models/tenant.dart';
import '../models/invoice.dart';
import 'room_page.dart';
import 'room_edit_page.dart';
import 'tenant_detail_page.dart';
import 'service_page.dart';
import 'invoice_detail_page.dart';
import 'invoice_create_page.dart';
import '../data/mock_data.dart';

class RoomDetailPage extends StatefulWidget {
  final String roomId;
  final int initialTab;

  const RoomDetailPage({
    super.key,
    required this.roomId,
    this.initialTab = 0,
  });

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  late int tab;
  final roomService = RoomService();
  final tenantService = TenantService();
  final invoiceService = InvoiceService();

  late Stream<Map<String, String>?> roomStream;
  Map<String, String> room = {};
  bool saving = false;

  @override
  void initState() {
    super.initState();
    roomStream = roomService.watchRoom(widget.roomId);
    tab = widget.initialTab.clamp(0, 3).toInt();
  }

  Widget card(Widget child) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );

  Widget heading(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          s,
          style: const TextStyle(
            color: ink,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  // Mở hộp thoại thêm người thuê mới vào phòng này
  Future<void> _showAddTenantDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final identityCtrl = TextEditingController();
    String role = 'Thành viên';
    bool isAdding = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Thêm người thuê vào ${room['name'] ?? 'phòng'}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại *',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: identityCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số CCCD / CMND',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: const InputDecoration(
                      labelText: 'Vai trò trong phòng',
                    ),
                    items: ['Trưởng phòng', 'Thành viên'].map((r) {
                      return DropdownMenuItem(value: r, child: Text(r));
                    }).toList(),
                    onChanged: (v) => setDialogState(() => role = v!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: isAdding
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        if (name.isEmpty || phone.isEmpty) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng nhập tên và số điện thoại.'),
                              ),
                            );
                          }
                          return;
                        }

                        setDialogState(() => isAdding = true);

                        try {
                          final currentUid =
                              FirebaseAuth.instance.currentUser?.uid ?? '';
                          final newTenant = TenantModel(
                            id: '',
                            name: name,
                            roomId: widget.roomId, // id_room duy nhất chống trùng phòng
                            roomName: room['name'] ?? '',
                            ownerId: currentUid, // owner_room định danh chủ sở hữu
                            phone: phone,
                            identity: identityCtrl.text.trim(),
                            memberRole: role,
                            status: 'Đang thuê',
                            startDate: '01/09/2026',
                            endDate: '31/08/2027',
                          );

                          await tenantService.addTenant(newTenant);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF10B981),
                                content: Text('Đã thêm $name vào ${room['name']}'),
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isAdding = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.red,
                                content: Text('Lỗi khi thêm người thuê: $e'),
                              ),
                            );
                          }
                        }
                      },
                style: FilledButton.styleFrom(backgroundColor: blue),
                child: isAdding
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Thêm'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Xác nhận thanh toán nhanh hóa đơn
  Future<void> _quickPayInvoice(InvoiceModel inv) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận thanh toán'),
        content: Text(
          'Đánh dấu hóa đơn ${inv.invoiceCode} phòng ${inv.roomName} là đã thanh toán?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (yes != true || !mounted) return;

    try {
      await invoiceService.markAsPaid(inv.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text('Hóa đơn ${inv.invoiceCode} đã thanh toán thành công!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, String>?>(
      stream: roomStream,
      builder: (context, snapshot) {
        if (snapshot.hasError ||
            snapshot.connectionState == ConnectionState.waiting ||
            snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi tiết phòng')),
            body: Center(
              child: snapshot.hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(roomError(snapshot.error!)),
                        TextButton(
                          onPressed: () => setState(() {
                            roomStream = roomService.watchRoom(widget.roomId);
                          }),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    )
                  : snapshot.connectionState == ConnectionState.waiting
                      ? const CircularProgressIndicator()
                      : const Text('Phòng đã bị xóa hoặc không tồn tại.'),
            ),
          );
        }

        room = snapshot.data!;
        final services = List<String>.from(jsonDecode(room['services']!));
        final images = List<String>.from(jsonDecode(room['imageUrls']!));

        return Scaffold(
          backgroundColor: canvas,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                    children: [
                      // Header Top bar
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.chevron_left, color: ink),
                          ),
                          Expanded(
                            child: Text(
                              room['name']!,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: ink,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_horiz, color: ink),
                            onSelected: (_) {
                              if (!saving) _edit();
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Chỉnh sửa phòng'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Container 4 Tab theo Figma
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 14),
                            // Header Tab Bar
                            Row(
                              children: List.generate(
                                4,
                                (i) => Expanded(
                                  child: InkWell(
                                    onTap: () => setState(() => tab = i),
                                    child: Column(
                                      children: [
                                        Text(
                                          [
                                            'Tổng quan',
                                            'Người thuê',
                                            'Dịch vụ',
                                            'Hóa đơn',
                                          ][i],
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: tab == i
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            color: tab == i ? blue : muted,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          height: 2.5,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: tab == i
                                                ? blue
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Divider(height: 1),

                            // Nội dung từng Tab
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(14, 16, 14, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // TAB 0: TỔNG QUAN
                                  if (tab == 0) ...[
                                    heading('Thông tin phòng'),
                                    if (saving)
                                      const LinearProgressIndicator(),
                                    infoRow('Trạng thái', room['status']!),
                                    infoRow('Khu / tầng', room['zone']!),
                                    infoRow('Số người tối đa', room['people']!),
                                    infoRow(
                                      'Diện tích',
                                      room['area']!.replaceAll('m²', ' m²'),
                                    ),
                                    infoRow('Giá thuê', room['price']!),
                                    infoRow(
                                      'Tiền cọc',
                                      room['deposit'] ??
                                          room['price']!.split('/').first,
                                    ),
                                    infoRow(
                                      'Ngày chốt tiền',
                                      room['billingDay'] ?? 'Chưa cập nhật',
                                    ),
                                    infoRow(
                                      'Mô tả',
                                      room['description'] ?? 'Chưa cập nhật',
                                    ),
                                  ],

                                  // TAB 1: NGƯỜI THUÊ (Figma # 04)
                                  if (tab == 1) _buildTenantTab(),

                                  // TAB 2: DỊCH VỤ (Figma # 05)
                                  if (tab == 2) ...[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        heading('Dịch vụ áp dụng'),
                                        TextButton(
                                          onPressed: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const ServicePage(),
                                              ),
                                            );
                                            if (mounted) setState(() {});
                                          },
                                          child: const Text('+ Thêm dịch vụ'),
                                        ),
                                      ],
                                    ),
                                    for (final s in serviceList)
                                      service(
                                        s['name']!.substring(0, 1),
                                        s['name']!,
                                        s['mode']!,
                                        '${money(s['price'])}/${s['unit']}',
                                        blue,
                                      ),
                                  ],

                                  // TAB 3: HÓA ĐƠN (Figma # 06)
                                  if (tab == 3) _buildInvoiceTab(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tiện ích & Ảnh của tab Tổng quan
                      if (tab == 0) ...[
                        const SizedBox(height: 10),
                        card(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              heading('Dịch vụ áp dụng'),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (services.isEmpty)
                                    const Text('Chưa có dịch vụ áp dụng'),
                                  for (final name in services)
                                    serviceChip(name, blue),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (images.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: Text(
                                'Chưa có ảnh phòng',
                                style: TextStyle(color: muted, fontSize: 12),
                              ),
                            ),
                          ),
                        for (final url in images)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Image.network(
                              url,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, error, stack) =>
                                  const Text('Không tải được ảnh phòng'),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                AppBottomBar(
                  selected: 0,
                  onRooms: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // TAB 1: NGƯỜI THUÊ (Figma # 04 - Chi tiết phòng - Người thuê)
  // Kết nối Firestore Real-time theo roomId & ownerId
  // ==========================================================
  Widget _buildTenantTab() {
    return StreamBuilder<List<TenantModel>>(
      stream: tenantService.watchTenantsByRoom(
        roomId: widget.roomId,
        roomName: room['name'],
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final tenants = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Danh sách người thuê',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${tenants.length} người đang thuê',
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddTenantDialog,
                  icon: const Icon(Icons.person_add_alt_1, size: 15),
                  label: const Text(
                    'Thêm người thuê',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEAF0FF),
                    foregroundColor: blue,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (tenants.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 38,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Phòng hiện chưa có người thuê',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Bấm nút "Thêm người thuê" để thêm khách vào phòng.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
              )
            else
              ...tenants.map((t) => _buildTenantItem(t)),
          ],
        );
      },
    );
  }

  Widget _buildTenantItem(TenantModel t) {
    final isLeader = t.memberRole == 'Trưởng phòng';

    return card(
      Row(
        children: [
          CircleAvatar(
            backgroundColor: isLeader ? blue : const Color(0xFF4B5563),
            radius: 20,
            child: Text(
              t.initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      t.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: ink,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isLeader
                            ? const Color(0xFFEAF0FF)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        t.memberRole,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isLeader ? blue : const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${room['name']}  ·  ${t.phone}',
                  style: const TextStyle(fontSize: 11, color: muted),
                ),
                if (t.identity.isNotEmpty)
                  Text(
                    'CCCD: ${t.identity}',
                    style: const TextStyle(fontSize: 10, color: muted),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TenantDetailPage(tenant: t.toUiMap()),
                ),
              );
              if (mounted) setState(() {});
            },
            icon: const Icon(Icons.chevron_right, color: muted),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TAB 3: HÓA ĐƠN (Figma # 06 - Chi tiết phòng - Hóa đơn)
  // Kết nối Firestore Real-time theo roomId & ownerId
  // ==========================================================
  Widget _buildInvoiceTab() {
    return StreamBuilder<List<InvoiceModel>>(
      stream: invoiceService.watchInvoices(roomId: widget.roomId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final invoices = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hóa đơn của phòng',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${invoices.length} hóa đơn',
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InvoiceCreatePage(
                          initialRoomId: widget.roomId,
                          initialRoomName: room['name'],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 15),
                  label: const Text(
                    'Tạo hóa đơn',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEAF0FF),
                    foregroundColor: blue,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (invoices.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 38,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Phòng này chưa có hóa đơn nào',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Bấm nút "Tạo hóa đơn" để lập phiếu thu tiền tháng này.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
              )
            else
              ...invoices.map((inv) => _buildInvoiceItem(inv)),
          ],
        );
      },
    );
  }

  Widget _buildInvoiceItem(InvoiceModel inv) {
    final paid = inv.status == 'Đã thanh toán';

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvoiceDetailPage(
              invoiceId: inv.id,
              invoice: inv,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: card(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        inv.invoiceCode,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: ink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        inv.month,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kỳ: ${inv.billingCycle}',
                    style: const TextStyle(fontSize: 10, color: muted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    InvoiceModel.formatCurrency(inv.totalAmount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ink,
                    ),
                  ),
                  if (paid && inv.paymentMethod == 'Chuyển khoản')
                    const Text(
                      'Thanh toán qua chuyển khoản',
                      style: TextStyle(fontSize: 10, color: muted),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: paid
                        ? const Color(0xFFE8FAF0)
                        : const Color(0xFFFFF1E8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    inv.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: paid
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEA580C),
                    ),
                  ),
                ),
                if (!paid)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      height: 28,
                      child: FilledButton(
                        onPressed: () => _quickPayInvoice(inv),
                        style: FilledButton.styleFrom(
                          backgroundColor: blue,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Thanh toán',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Tiện ích hiển thị thông tin từng dòng
  Widget infoRow(String label, String value) {
    return Padding(
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
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: ink,
                fontSize: 12,
                fontWeight: label == 'Mô tả'
                    ? FontWeight.normal
                    : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget serviceChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color)),
    );
  }

  Widget service(
    String symbol,
    String name,
    String mode,
    String price,
    Color color,
  ) =>
      card(
        Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: color,
              child: Text(
                symbol,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(mode, style: const TextStyle(fontSize: 10, color: muted)),
                ],
              ),
            ),
            Text(
              price,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            IconButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ServicePage()),
                );
                if (mounted) setState(() {});
              },
              icon: const Icon(Icons.chevron_right, size: 17, color: muted),
            ),
          ],
        ),
      );

  Future<void> _edit() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => RoomEditPage(
          room: room,
          usedNames: roomList
              .where((r) => r['id'] != widget.roomId)
              .map((r) => r['name']!)
              .toList(),
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => saving = true);
    try {
      await roomService.save(result, id: widget.roomId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu thông tin phòng lên Firebase')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(roomError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
