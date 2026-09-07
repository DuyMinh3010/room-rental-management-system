import 'package:flutter/material.dart';
import 'screens/tenant_detail_screen.dart';

void main() {
  runApp(const RRMSApp());
}

class RRMSApp extends StatelessWidget {
  const RRMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'RRMS',

      theme: ThemeData(
        fontFamily: 'Arial',
        useMaterial3: true,
      ),

      home: const TenantDetailScreen(),
    );
  }
}