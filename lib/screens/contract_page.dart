import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/formatters.dart';
import 'room_page.dart';
import 'contract_detail_page.dart';
import 'contract_edit_page.dart';

class ContractPage extends StatefulWidget {
  const ContractPage({super.key});

  @override
  State<ContractPage> createState() => _ContractPageState();
}

class _ContractPageState extends State<ContractPage> {
  String filter = 'Tất cả';
  String query = '';

  final CollectionReference<Map<String, dynamic>> contracts = FirebaseFirestore
      .instance
      .collection('contracts');

  // ContractEditPage persists the contract and tenant before returning.
  Future<void> _create() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => const ContractEditPage()),
    );

    if (!mounted || result == null) return;

    setState(() {
      filter = 'Tất cả';
      query = '';
    });
  }

  Future<void> _open(Map<String, String> contract) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ContractDetailPage(contract: contract)),
    );

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        title: const Text('Hợp đồng'),
        actions: [
          TextButton(onPressed: _create, child: const Text('+ Tạo mới')),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: contracts.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Không thể tải hợp đồng từ Firebase:\n${snapshot.error}',
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allContracts = (snapshot.data?.docs ?? []).map((doc) {
            final data = doc.data();

            final contract = data.map(
              (key, value) => MapEntry(
                key,
                value == null
                    ? ''
                    : value is List || value is Map
                    ? jsonEncode(value)
                    : value.toString(),
              ),
            );
            contract['documentId'] = doc.id;
            return contract;
          }).toList();

          final shown = allContracts.where((c) {
            final status = c['status'] ?? '';

            final matchesFilter = filter == 'Tất cả' || status == filter;

            final searchText = query.toLowerCase();

            final matchesQuery = [
              'id',
              'name',
              'room',
            ].any((key) => (c[key] ?? '').toLowerCase().contains(searchText));

            return matchesFilter && matchesQuery;
          }).toList();

          final activeCount = allContracts
              .where((c) => c['status'] == 'Còn hiệu lực')
              .length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${allContracts.length} hợp đồng · '
                '$activeCount còn hiệu lực',
                style: const TextStyle(color: muted),
              ),
              const SizedBox(height: 14),
              TextField(
                onChanged: (v) => setState(() => query = v),
                decoration: const InputDecoration(
                  hintText: 'Tìm số hợp đồng, người thuê hoặc phòng...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children:
                    [
                      'Tất cả',
                      'Còn hiệu lực',
                      'Sắp hết hạn',
                      'Đã thanh lý',
                    ].map((s) {
                      return ChoiceChip(
                        label: Text(s),
                        selected: filter == s,
                        onSelected: (_) {
                          setState(() => filter = s);
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 14),
              if (shown.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Không tìm thấy hợp đồng'),
                  ),
                ),
              for (final c in shown)
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c['id'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('${c['name'] ?? ''} · ${c['room'] ?? ''}'),
                        const SizedBox(height: 6),
                        Text(
                          'Thuê: ${money(c['rent'])}/tháng',
                          style: const TextStyle(color: muted),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          c['status'] ?? '',
                          style: TextStyle(
                            color: c['status'] == 'Còn hiệu lực'
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _open(c),
                            child: const Text('Chi tiết →'),
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
      bottomNavigationBar: const AppBottomBar(selected: 4),
    );
  }
}
