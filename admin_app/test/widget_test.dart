import 'package:adnexa_admin/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Admin app requires Firebase build configuration', (tester) async {
    await tester.pumpWidget(const AdminApp());
    expect(find.text('ต้องตั้งค่าระบบก่อนใช้งาน'), findsOneWidget);
    expect(find.textContaining('FIREBASE_API_KEY'), findsOneWidget);
  });
}
