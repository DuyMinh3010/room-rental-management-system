import 'package:flutter/material.dart';

import 'app_colors.dart';

// man hinh them dich vu
class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({super.key});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final List<String> serviceTypes = const [
    'Điện',
    'Nước',
    'WiFi',
    'Rác',
    'Khác',
  ];
  final List<String> calcMethods = const [
    'Theo chỉ số',
    'Theo đầu người',
    'Cố định',
  ];

  String selectedType = 'Điện';
  String selectedMethod = 'Theo chỉ số';

  final TextEditingController priceController = TextEditingController(
    text: '3.500',
  );
  final TextEditingController noteController = TextEditingController();

  @override
  void dispose() {
    priceController.dispose();
    noteController.dispose();
    super.dispose();
  }

  String get unit {
    if (selectedMethod == 'Theo chỉ số') {
      if (selectedType == 'Điện') return 'đ/kWh';
      if (selectedType == 'Nước') return 'đ/m³';
      return 'đ/đơn vị';
    }
    if (selectedMethod == 'Theo đầu người') return 'đ/người';
    return 'đ/tháng';
  }

  void _addService() {
    // TODO: lưu dữ liệu vào database / state management
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Đã thêm dịch vụ $selectedType')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Loại dịch vụ'),
                    _buildDropdown(
                      value: selectedType,
                      items: serviceTypes,
                      onChanged: (v) => setState(() => selectedType = v!),
                    ),
                    const SizedBox(height: 16),
                    _label('Cách tính'),
                    _buildDropdown(
                      value: selectedMethod,
                      items: calcMethods,
                      onChanged: (v) => setState(() => selectedMethod = v!),
                    ),
                    const SizedBox(height: 16),
                    _label('Đơn giá'),
                    _buildPriceField(),
                    const SizedBox(height: 16),
                    _label('Mô tả'),
                    _buildNoteField(),
                    const SizedBox(height: 28),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            color: AppColors.textDark,
            onPressed: () => Navigator.maybePop(context),
          ),
          const Text(
            'Thêm dịch vụ',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildPriceField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14, color: AppColors.textDark),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          Text(
            unit,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: noteController,
        maxLines: 4,
        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
        decoration: const InputDecoration(
          hintText: 'Ghi chú dịch vụ...',
          hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _addService,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'Thêm dịch vụ',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
