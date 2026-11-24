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

    expect(find.text('Mã mời dãy trọ (tùy chọn)'), findsNothing);
    await tester.tap(find.text('Người thuê'));
    await tester.pump();
    expect(find.text('Mã mời dãy trọ (tùy chọn)'), findsOneWidget);
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
    expect(
      find.textContaining('Số điện thoại', findRichText: true),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Tạo tài khoản'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Tạo tài khoản'));
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, 500));
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
        'Nhập mã mời từ chủ trọ để tự động đối chiếu email và vào đúng phòng ngay khi tạo tài khoản.',
      ),
      findsOneWidget,
    );
    expect(find.text('Mã mời vào phòng (tùy chọn)'), findsOneWidget);
  });

  testWidgets('register invite code validator enforces 6-8 alphanumeric chars', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

    await tester.tap(find.text('Người thuê'));
    await tester.pump();

    final inviteField = find.widgetWithText(
      TextFormField,
      'VD: A7K92P (có thể nhập sau khi đăng nhập)',
    );
    await tester.enterText(inviteField, 'AB12');
    await tester.pump();
    expect(find.text('Mã mời gồm 6–8 ký tự chữ và số'), findsOneWidget);

    await tester.enterText(inviteField, '  abc123  ');
    await tester.pump();
    expect(find.text('Mã mời gồm 6–8 ký tự chữ và số'), findsNothing);

    await tester.enterText(inviteField, 'ABCD1234');
    await tester.pump();
    expect(find.text('Mã mời gồm 6–8 ký tự chữ và số'), findsNothing);
  });
}
