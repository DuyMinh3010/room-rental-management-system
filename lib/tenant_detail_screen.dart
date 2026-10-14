import 'package:flutter/material.dart';

import 'app_colors.dart';

class TenantDetailScreen extends StatefulWidget {
  const TenantDetailScreen({super.key});

  @override
  State<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  final String initials = 'NA';
  final String fullName = 'Nguyễn Minh Chiến';
  final String roomInfo = 'Phòng 101 · Khu A';
  final String status = 'Đang thuê';
  final String contractRange = '01/06/2026 → 31/05/2027';

  final String birthDate = '05/10/2003';
  final String gender = 'Nam';
  final String phone = '090 123 4567';
  final String email = 'chienday05@gmail.com';
  final String hometown = 'Quảng Ngãi';
  final String job = 'Sinh Viên';
  final String residence = 'Chưa đăng ký';
  final String idCard = '048203001234';
  final String studentId = '123456789';
  final String note = '';

  static const Color _greenText = Color(0xFF16A34A);
  static const Color _greenBg = Color(0xFFDCFCE7);
  static const Color _lightBlue = Color(0xFFEAF1FF);
  static const Color _editRed = Color(0xFFDB1212);
  static const Color _divider = Color(0xFFE5E7EB);

  int selectedTab = 1;

  void _onEdit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chỉnh sửa thông tin người thuê')),
    );
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileCard(),
                    const SizedBox(height: 22),
                    const Padding(
                      padding: EdgeInsets.only(left: 2, bottom: 8),
                      child: Text(
                        'Thông tin khách thuê',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    _buildDetailCard(),
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
          const Expanded(
            child: Text(
              'Thông tin chi tiết',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _onEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _lightBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Chỉnh sửa',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _editRed,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _lightBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      roomInfo,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _greenBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _greenText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              children: [
                const TextSpan(
                  text: 'Hợp đồng thuê: ',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: contractRange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _infoRow('Họ và Tên', fullName),
          _infoRow('Ngày Sinh', birthDate),
          _infoRow('Giới Tính', gender),
          _infoRow(
            'Số Điện Thoại',
            phone,
            trailing: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone, size: 15, color: Colors.white),
            ),
          ),
          _infoRow(
            'Email',
            email,
            trailing: const Icon(
              Icons.mail_outline,
              size: 22,
              color: AppColors.textDark,
            ),
          ),
          _infoRow('Quê Quán', hometown),
          _infoRow('Nghề Nghiệp', job),
          _infoRow('Đăng Ký tạm trú', residence),
          _infoRow('CCCD/Passport', idCard),
          _infoRow('Mã Sinh Viên', studentId),
          _infoRow('Ghi Chú', note, showDivider: false),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    Widget? trailing,
    bool showDivider = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: _divider))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            flex: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing],
              ],
            ),
          ),
        ],
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
