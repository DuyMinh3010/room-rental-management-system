import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'room_page.dart';
import 'tenant_detail_page.dart';

class TenantListPage extends StatefulWidget {
  const TenantListPage({super.key});

  @override
  State<TenantListPage> createState() => _TenantListPageState();
}

class _TenantListPageState extends State<TenantListPage> {
  int selectedFilter = 0;
  String searchText = '';

  // Chuyển dữ liệu hợp đồng thành dữ liệu hiển thị khách thuê.
  List<Map<String, String>> _toTenants(
    Map<String, dynamic> c,
    String documentId,
  ) {
    final savedMembers = c['members'];
    final members = savedMembers is List
        ? savedMembers.whereType<Map>().toList()
        : <Map>[];
    final tenantMembers = members.isEmpty
        ? [
            <String, dynamic>{
              'name': c['name'] ?? '',
              'role': c['memberRole'] ?? 'Trưởng phòng',
              'phone': c['phone'] ?? '',
              'email': c['email'] ?? '',
              'identity': c['identity'] ?? '',
            },
          ]
        : members;
    final start = (c['start'] ?? '').toString();
    final end = (c['end'] ?? '').toString();
    final status = (c['status'] ?? '').toString();

    String tenantStatus;

    if (status == 'Còn hiệu lực') {
      tenantStatus = 'Đang thuê';
    } else if (status == 'Sắp hết hạn') {
      tenantStatus = 'Sắp hết hạn';
    } else {
      tenantStatus = 'Đã kết thúc';
    }

    final contractPeriod = start.isNotEmpty || end.isNotEmpty
        ? '$start → $end'
        : '';

    return List.generate(tenantMembers.length, (index) {
      final member = tenantMembers[index];
      final name = (member['name'] ?? '').toString();
      final nameParts = name.trim().split(RegExp(r'\s+'));
      final initial = name.trim().isEmpty
          ? '?'
          : nameParts.length == 1
          ? nameParts.first.substring(0, 1).toUpperCase()
          : '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase();

      return {
        'id': documentId,
        'documentId': documentId,
        'memberIndex': '$index',
        'initial': initial,
        'name': name,
        'room': (c['room'] ?? '').toString(),
        'phone': (member['phone'] ?? '').toString(),
        'email': (member['email'] ?? '').toString(),
        'identity': (member['identity'] ?? '').toString(),
        'birthday': (member['birthday'] ?? '').toString(),
        'gender': (member['gender'] ?? '').toString(),
        'address': (member['address'] ?? '').toString(),
        'job': (member['job'] ?? '').toString(),
        'residence': (member['residence'] ?? '').toString(),
        'note': (member['note'] ?? '').toString(),
        'contract': (c['id'] ?? '').toString(),
        'contractPeriod': contractPeriod,
        'start': start,
        'end': end,
        'rent': (c['rent'] ?? '').toString(),
        'deposit': (c['deposit'] ?? '').toString(),
        'status': tenantStatus,
        'memberRole': (member['role'] ?? 'Trưởng phòng').toString(),
      };
    });
  }

  Future<void> _detail(Map<String, String> tenant) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TenantDetailPage(tenant: tenant)),
    );
  }

  void _search() => FocusScope.of(context).unfocus();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('contracts')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Không thể tải khách thuê từ Firebase:\n'
                    '${snapshot.error}',
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // Chỉ lấy hợp đồng còn hiệu lực hoặc sắp hết hạn.
            final tenants = (snapshot.data?.docs ?? [])
                .expand((doc) => _toTenants(doc.data(), doc.id))
                .where(
                  (t) =>
                      t['status'] == 'Đang thuê' ||
                      t['status'] == 'Sắp hết hạn',
                )
                .toList();

            const statuses = ['Tất cả', 'Trưởng phòng', 'Thành viên'];

            final q = searchText.trim().toLowerCase();

            final shown = tenants.where((t) {
              final matchFilter =
                  selectedFilter == 0 ||
                  t['memberRole'] == statuses[selectedFilter];

              final matchSearch = [
                'name',
                'room',
                'phone',
              ].any((key) => (t[key] ?? '').toLowerCase().contains(q));

              return matchFilter && matchSearch;
            }).toList();

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Danh sách người thuê',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF202533),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _search,
                              icon: const Icon(
                                Icons.search,
                                color: Color(0xFF707582),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          onChanged: (value) {
                            setState(() => searchText = value);
                          },
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm tên, số phòng...',
                            hintStyle: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 19,
                              color: Colors.grey,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE4E5E9),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF2F67EA),
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Wrap(
                          spacing: 8,
                          children: List.generate(3, (i) {
                            final labels = [
                              'Tất cả',
                              'Trưởng phòng',
                              'Thành viên',
                            ];

                            final selected = selectedFilter == i;

                            return GestureDetector(
                              onTap: () {
                                setState(() => selectedFilter = i);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFF2F67EA)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  labels[i],
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFF7E8390),
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 18),
                        if (shown.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text('Chưa có khách thuê phù hợp'),
                            ),
                          ),
                        ...shown.map(
                          (tenant) => Padding(
                            padding: const EdgeInsets.only(bottom: 11),
                            child: _tenantCard(tenant),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${shown.length} người thuê',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const AppBottomBar(selected: 1),
    );
  }

  Widget _tenantCard(Map<String, String> tenant) {
    final initial = tenant['initial'] ?? '?';
    final name = tenant['name'] ?? '';
    final room = tenant['room'] ?? '';
    final phone = tenant['phone'] ?? '';
    final contract = tenant['contract'] ?? '';
    final status = tenant['status'] ?? '';

    Color statusBackground;
    Color statusText;

    if (status == 'Đang thuê') {
      statusBackground = const Color(0xFFE7F8ED);
      statusText = const Color(0xFF16A15D);
    } else if (status == 'Sắp hết hạn') {
      statusBackground = const Color(0xFFFFF0DE);
      statusText = const Color(0xFFE88623);
    } else {
      statusBackground = const Color(0xFFFFEAEA);
      statusText = const Color(0xFFE74747);
    }

    return InkWell(
      onTap: () => _detail(tenant),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF3FF),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Color(0xFF4390E8),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF202533),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    room,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 13,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          phone,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        size: 13,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          contract,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: statusBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: statusText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
