import 'package:flutter/material.dart';

import 'app_colors.dart';

class AddRoomScreen extends StatefulWidget {
  const AddRoomScreen({super.key});

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final List<String> statuses = const ['Trống', 'Đang thuê', 'Đang sửa chữa'];

  String selectedStatus = 'Trống';

  final List<String> roles = const ['Chủ hợp đồng', 'Thành viên'];

  final List<TextEditingController> memberControllers = [
    TextEditingController(text: 'Thành viên 1'),
    TextEditingController(text: 'Thành viên 2'),
  ];

  final List<String> memberRoles = ['Chủ hợp đồng', 'Thành viên'];

  final TextEditingController roomController = TextEditingController(
    text: 'P.202',
  );

  final TextEditingController peopleController = TextEditingController(
    text: '2 người',
  );

  final TextEditingController priceController = TextEditingController(
    text: '2.500.000đ / tháng',
  );

  final TextEditingController depositController = TextEditingController(
    text: '2.500.000đ',
  );

  final TextEditingController areaController = TextEditingController(
    text: '25 m²',
  );

  static const Color _lightBlue = Color(0xFFEAF1FF);
  static const Color _divider = Color(0xFFE5E7EB);

  int selectedTab = 0;

  @override
  void dispose() {
    roomController.dispose();
    peopleController.dispose();
    priceController.dispose();
    depositController.dispose();
    areaController.dispose();

    for (final c in memberControllers) {
      c.dispose();
    }

    super.dispose();
  }

  void _createRoom() {
    final name = roomController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập số phòng')));
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Đã thêm phòng $name')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _BottomNav(
        selectedIndex: selectedTab,
        onTap: (i) => setState(() => selectedTab = i),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Số phòng *'),
                    _textField(roomController),
                    const SizedBox(height: 12),
                    _label('Số lượng người*'),
                    _textField(peopleController),
                    const SizedBox(height: 12),
                    _label('Giá phòng *'),
                    _textField(priceController),
                    const SizedBox(height: 12),
                    _label('Tiền đặt cọc *'),
                    _textField(depositController),
                    const SizedBox(height: 12),
                    _label('Diện tích *'),
                    _textField(areaController),
                    const SizedBox(height: 12),
                    _label('Tên thành viên*'),
                    _buildMembers(),
                    const SizedBox(height: 18),
                    const Text(
                      'Trạng thái',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStatusDropdown(),
                    const SizedBox(height: 16),
                    _buildSubmitButton(),
                    const SizedBox(height: 10),
                    const Text(
                      'Phòng mới sẽ được thêm vào danh sách phòng.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 28),
                color: AppColors.textDark,
                onPressed: () => Navigator.maybePop(context),
              ),
              const Text(
                'Thêm phòng',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text(
              'Tạo thông tin phòng mới',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _textField(TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildMembers() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: List.generate(memberControllers.length, (i) {
          return Row(
            children: [
              Expanded(
                child: TextField(
                  controller: memberControllers[i],
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  hint: Text(
                    i == 0 ? 'Vai trò' : '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                  ),
                  value: i == 0 ? null : memberRoles[i],
                  icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                  items: roles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => memberRoles[i] = v);
                    }
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _lightBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedStatus,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
          items: statuses
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() => selectedStatus = v);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _createRoom,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'Thêm phòng',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  static const Color _lightBlue = Color(0xFFEAF1FF);
  static const Color _divider = Color(0xFFE5E7EB);

  static const List<(String, IconData)> _items = [
    ('Phòng', Icons.home_outlined),
    ('Người thuê', Icons.person_outline),
    ('Dịch vụ', Icons.circle),
    ('Hóa đơn', Icons.receipt_long_outlined),
    ('Hợp đồng', Icons.description_outlined),
    ('Bảo trì', Icons.build_outlined),
    ('Tài khoản', Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: List.generate(_items.length, (i) {
              final label = _items[i].$1;
              final icon = _items[i].$2;
              final selected = i == selectedIndex;
              final color = selected ? AppColors.primary : AppColors.textDark;

              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onTap(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? _lightBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: icon == Icons.circle ? 14 : 20,
                          color: color,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ],
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
}
