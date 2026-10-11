
import 'package:flutter/material.dart';
import 'screens/room_detail_screen.dart';

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
        useMaterial3: true,
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2160E8),
        ),
      ),
      home: const RoomDetailScreen(),
    );
  }
}