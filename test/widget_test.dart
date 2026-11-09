import 'package:flutter_test/flutter_test.dart';
import 'package:adnexa/main.dart';

void main() {
  testWidgets('ADNEXA shows Firebase setup guidance when config is missing',
      (tester) async {
    await tester.pumpWidget(const AdnexaApp());
    await tester.pumpAndSettle();

    expect(find.text('ADNEXA'), findsOneWidget);
    expect(find.text('ตั้งค่าระบบบัญชี ADNEXA'), findsOneWidget);
  });
}
