import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adnexa/main.dart';

void main() {
  testWidgets('ADNEXA shows setup guidance when Firebase build variables are absent', (tester) async {
    await tester.pumpWidget(const AdnexaApp());
    await tester.pumpAndSettle();

    expect(find.text('ตั้งค่าระบบบัญชี ADNEXA'), findsOneWidget);
    expect(find.textContaining('FIREBASE_API_KEY'), findsOneWidget);
  });

  testWidgets('Campaign Studio restricts age targeting to 18-60', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CampaignPage())),
    );
    await tester.pumpAndSettle();

    // The age selector is shared by AI and Manual modes; switch to Manual
    // because the current default AI mode intentionally hides manual-only fields.
    await tester.tap(find.text('ทำเองทั้งหมด'));
    await tester.pumpAndSettle();

    // CampaignPage uses a lazy ListView; scroll the age control into the tree.
    await tester.scrollUntilVisible(
      find.byType(RangeSlider),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
    expect(slider.min, 18);
    expect(slider.max, 60);
    expect(slider.values.start, 18);
    expect(slider.values.end, 60);
    expect(
      find.text('เลือกกลุ่มผู้ชมได้ตั้งแต่อายุ 18–60 ปี ปรับช่วงอายุได้เองทั้งโหมด AI และโหมดทำเอง'),
      findsOneWidget,
    );
  });
}
