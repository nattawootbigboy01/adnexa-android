import 'package:adnexa/core/admin/admin_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('super admin claim opens the admin control center',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AdminPage(loadClaims: () async => {
        'contentnexRole': 'super_admin',
      }),
    ));
    await tester.pumpAndSettle();

    expect(find.text('ADMIN CONTROL CENTER'), findsOneWidget);
    expect(find.text('ยืนยันสิทธิ์ CONTENTNEX Super Admin แล้ว'), findsOneWidget);
    expect(find.text('โหมดต้นแบบ — ยังไม่เปิดสิทธิ์แอดมิน'), findsNothing);
  });

  testWidgets('customer claim is denied access to the admin center',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AdminPage(loadClaims: () async => {
        'contentnexRole': 'customer',
      }),
    ));
    await tester.pumpAndSettle();

    expect(find.text('ไม่มีสิทธิ์ผู้ดูแลระบบ'), findsOneWidget);
    expect(find.text('ADMIN CONTROL CENTER'), findsNothing);
  });
}
