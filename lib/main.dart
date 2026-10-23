
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_page.dart';

Future<void> main() async {
WidgetsFlutterBinding.ensureInitialized();

await Firebase.initializeApp(
options: DefaultFirebaseOptions.currentPlatform,
);

runApp(const MyApp());
}

class MyApp extends StatelessWidget {
const MyApp({super.key});

@override
Widget build(BuildContext context) {
const blue = Color(0xFF2463F5);

return MaterialApp(
debugShowCheckedModeBanner: false,
title: 'RRMS',
theme: ThemeData(
useMaterial3: true,
colorScheme: ColorScheme.fromSeed(seedColor: blue),
scaffoldBackgroundColor: const Color(0xFFF6F7F9),
appBarTheme: const AppBarTheme(
backgroundColor: Color(0xFFF6F7F9),
surfaceTintColor: Colors.transparent,
titleTextStyle: TextStyle(
color: Color(0xFF172033),
fontSize: 20,
fontWeight: FontWeight.w600,
),
),
filledButtonTheme: FilledButtonThemeData(
style: FilledButton.styleFrom(
backgroundColor: blue,
minimumSize: const Size(80, 46),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(10),
),
),
),
),

// Giữ khung giao diện điện thoại khi chạy trên Chrome.
builder: (context, child) => Center(
child: ConstrainedBox(
constraints: const BoxConstraints(maxWidth: 480),
child: child!,
),
),

home: const LoginPage(),
);
}
}
