import 'package:adnexa/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows Firebase setup instructions when build configuration is missing',
      (tester) async {
    await tester.pumpWidget(const AdnexaApp());
    await tester.pumpAndSettle();

    expect(find.text('ตั้งค่าระบบบัญชี ADNEXA'), findsOneWidget);
    expect(find.textContaining('FIREBASE_API_KEY'), findsOneWidget);
  });

  testWidgets('renders the app shell and navigates between sections',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.pumpAndSettle();

    expect(find.text('ADNEXA'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Campaigns'), findsOneWidget);

    await tester.tap(find.text('Campaigns'));
    await tester.pumpAndSettle();
    expect(find.text('Campaign Studio'), findsOneWidget);
    expect(find.text('เลือกวิธีจัดการแคมเปญ'), findsOneWidget);

    await tester.tap(find.text('AI'));
    await tester.pumpAndSettle();
    expect(find.text('ADNEXA Campaign Planner'), findsOneWidget);

    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();
    expect(find.text('Campaign performance overview'), findsOneWidget);
  });
}
