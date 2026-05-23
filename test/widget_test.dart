import 'package:flutter_test/flutter_test.dart';
import 'package:madrasti_plus/app/madrasti_plus_app.dart';

void main() {
  testWidgets('Shows role selection screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MadrastiPlusApp());

    expect(find.text('Madrasti Plus'), findsOneWidget);
    expect(find.text('اختر نوع المستخدم'), findsOneWidget);
    expect(find.text('ولي الأمر'), findsOneWidget);
    expect(find.text('الحارس'), findsOneWidget);
    expect(find.text('المعلم'), findsOneWidget);
    expect(find.text('الإدارة'), findsOneWidget);
  });
}
