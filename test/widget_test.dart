// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capstone1/screens/login_page.dart';
import 'package:capstone1/screens/register_page.dart';

void main() {
  testWidgets('login page renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('RRMS'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsWidgets);
    expect(find.text('Đăng nhập với vai trò'), findsOneWidget);
    expect(find.text('Chủ trọ'), findsOneWidget);
    expect(find.text('Người thuê'), findsOneWidget);
  });

  testWidgets('login role can be selected before entering credentials', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    await tester.tap(find.text('Chủ trọ'));
    await tester.pump();

    expect(find.text('Vui lòng chọn Chủ trọ hoặc Người thuê'), findsNothing);
  });

  testWidgets('login requires selecting a role', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pump();

    expect(find.text('Vui lòng chọn Chủ trọ hoặc Người thuê'), findsOneWidget);
  });

  testWidgets('login validation is shown under each field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    await tester.tap(find.text('Người thuê'));
    await tester.pump();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập email'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
  });

  testWidgets('register page renders role selection and requires a role', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

    expect(find.text('Chủ trọ'), findsOneWidget);
    expect(find.text('Người thuê'), findsOneWidget);
    expect(find.text('Số điện thoại'), findsOneWidget);

    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Tạo tài khoản'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Tạo tài khoản'));
    await tester.pump();

    expect(find.text('Vui lòng chọn Chủ trọ hoặc Người thuê'), findsOneWidget);
  });

  testWidgets('register role selection clears role error and shows hint', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

    await tester.tap(find.text('Chủ trọ'));
    await tester.pump();

    expect(find.text('Vui lòng chọn Chủ trọ hoặc Người thuê'), findsNothing);
    expect(
      find.text(
        'Tài khoản Chủ trọ có quyền quản lý phòng, hợp đồng, hóa đơn và khách thuê.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Người thuê'));
    await tester.pump();

    expect(
      find.text(
        'Nhập mã mời 6 ký tự từ chủ trọ để tự động vào đúng phòng ngay khi tạo tài khoản.',
      ),
      findsOneWidget,
    );
    expect(find.text('Mã mời vào phòng (tùy chọn)'), findsOneWidget);
  });
}
