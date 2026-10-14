import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'CreateInvoiceScreen.dart';
import 'add_service_screen.dart';
import 'add_room_screen.dart';
import 'tenant_info_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      //  home: const CreateInvoiceScreen(), // -> chay app tren man hinh tao hoa don
      // home: const AddServiceScreen(), // -> chay app tren man hinh them dich vu
      home: const AddRoomScreen(), // -> chay app tren man hinh them phong
      //  home: const TenantInfoScreen(), // -> chay app tren man hinh thong tin khach thue
      // home: const TenantInfoScreen(), // -> chay app tren man hinh thong tin khach thue
    );
  }
}
// flutter run -d emulator-5554 -> nhập lệnh này vào terminal để chạy app trên máy ảo
