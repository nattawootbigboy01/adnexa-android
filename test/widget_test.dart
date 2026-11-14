import 'package:flutter_test/flutter_test.dart';
import 'package:adnexa/main.dart';

void main() {
  testWidgets('CONTENTNEX shows the Firebase setup screen when config is absent',
      (tester) async {
    await tester.pumpWidget(const AdnexaApp());
    await tester.pumpAndSettle();

    expect(find.text('ตั้งค่าระบบบัญชี CONTENTNEX'), findsOneWidget);
  });
}
