import 'package:adnexa/core/admin/admin_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('admin prototype clearly shows gated access and modules',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AdminPage()),
    );

    expect(find.text('ADMIN CONTROL CENTER'), findsOneWidget);
    expect(find.text('โหมดต้นแบบ — ยังไม่เปิดสิทธิ์แอดมิน'), findsOneWidget);
    expect(find.text('จัดการผู้ใช้งาน'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Audit Log'), 300);
    expect(find.text('Audit Log'), findsOneWidget);
    expect(find.text('ยังไม่เชื่อมต่อ'), findsOneWidget);
  });
}
