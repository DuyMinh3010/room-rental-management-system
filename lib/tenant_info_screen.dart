import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'tenant_detail_screen.dart';

class TenantInfoScreen extends StatefulWidget {
  const TenantInfoScreen({super.key});

  @override
  State<TenantInfoScreen> createState() => _TenantInfoScreenState();
}

class _TenantInfoScreenState extends State<TenantInfoScreen> {
  final String initials = 'NA';
  final String fullName = 'Nguyễn Minh Chiến';
  final String roomInfo = 'Phòng 101 · Khu';
  final String status = 'Đang thuê';
  final String contractRange = '01/06/2026 → 31/05/2027';

  final String phone = '090 123 4567';
  final String email = 'chienday05@gmail.com';
  final String idCard = '048203001234';

  final String roomPrice = '2.500.000đ / tháng';
  final String deposit = '2.500.000đ';
  final String startDate = '01/06/2026';
  final String endDate = '31/05/2027';

  static const Color greenText = Color(0xFF16A34A);
  static const Color greenBg = Color(0xFFDCFCE7);
  static const Color lightBlue = Color(0xFFEAF1FF);
  static const Color editRed = Color(0xFFDB1212);
  static const Color divider = Color(0xFFE5E7EB);

  int selectedTab = 1;

  void onEdit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chỉnh sửa thông tin người thuê')),
    );
  }

  void openTenantDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TenantDetailScreen()),
    );
  }

  void openRentDetail() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trang chi tiết thuê phòng đang phát triển'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNav(
        selectedIndex: selectedTab,
        onTap: (index) {
          setState(() {
            selectedTab = index;
          });
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildProfileCard(),
                    const SizedBox(height: 20),

                    sectionTitle('Thông tin liên hệ'),
                    buildContactCard(),

                    const SizedBox(height: 20),

                    sectionTitle('Thông tin thuê phòng'),
                    buildRentCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            color: AppColors.textDark,
            onPressed: () {
              Navigator.maybePop(context);
            },
          ),

          const Expanded(
            child: Text(
              'Thông tin thuê phòng',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),

          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Chỉnh sửa',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: editRed,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
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
                  color: lightBlue,
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
                        color: greenBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Đang thuê',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: greenText,
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

  Widget buildContactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          infoRow(
            'Số điện thoại',
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

          infoRow(
            'Email',
            email,
            valueColor: const Color(0xFF1E3A8A),
            trailing: const Icon(
              Icons.mail_outline,
              size: 22,
              color: AppColors.textDark,
            ),
          ),

          infoRow('CCCD', idCard),

          const SizedBox(height: 10),

          viewDetailLink(openTenantDetail),
        ],
      ),
    );
  }

  Widget buildRentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          infoRow('Tiền phòng', roomPrice),
          infoRow('Tiền đặt cọc', deposit),
          infoRow('Ngày bắt đầu thuê', startDate, showDivider: false),
          infoRow('Ngày kết thúc', endDate, showDivider: false),

          const SizedBox(height: 20),

          const Divider(height: 1, color: divider),

          const SizedBox(height: 10),

          viewDetailLink(openRentDetail),
        ],
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    );
  }

  Widget infoRow(
    String label,
    String value, {
    Widget? trailing,
    Color valueColor = AppColors.textDark,
    bool showDivider = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: divider))
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
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: valueColor,
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

  Widget viewDetailLink(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 2),
        child: Text(
          'Xem chi tiết →',
          style: TextStyle(fontSize: 12, color: AppColors.textDark),
        ),
      ),
    );
  }
}

class BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const BottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  static const Color lightBlue = Color(0xFFEAF1FF);
  static const Color divider = Color(0xFFE5E7EB);

  static const items = [
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
        border: Border(top: BorderSide(color: divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final selected = index == selectedIndex;

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? lightBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.$2,
                          size: item.$2 == Icons.circle ? 14 : 20,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textDark,
                        ),

                        const SizedBox(height: 3),

                        Text(
                          item.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textDark,
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
