import 'package:flutter_test/flutter_test.dart';
import 'package:rrms/main.dart';

void main() {
  testWidgets('RRMS app test', (WidgetTester tester) async {
    await tester.pumpWidget(const RRMSApp());

    expect(find.byType(RRMSApp), findsOneWidget);
  });
}