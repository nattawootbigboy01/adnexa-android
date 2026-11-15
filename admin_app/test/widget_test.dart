import 'package:flutter_test/flutter_test.dart';
import 'package:contentnex_admin/main.dart';

void main() {
  testWidgets('shows safe setup screen until dedicated Firebase config exists',
      (tester) async {
    await tester.pumpWidget(const ContentNexAdminApp());
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่ได้ตั้งค่า Firebase'), findsOneWidget);
    expect(find.text('CONTENTNEX ADMIN'), findsOneWidget);
  });
}
