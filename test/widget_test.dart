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


  testWidgets('Planner identifies offline capabilities and does not show synthetic forecasts', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AiPage())),
    );
    expect(
      find.text('เครื่องมือช่วยวางแผนเบื้องต้น • ยังไม่เชื่อม AI ออนไลน์'),
      findsOneWidget,
    );
    expect(find.textContaining('ไม่ใช่ AI ออนไลน์'), findsOneWidget);
    expect(find.text('ประมาณการผลลัพธ์'), findsNothing);
  });

  testWidgets('Campaign Studio restricts age targeting to 18-60', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(430, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CampaignPage())),
    );
    await tester.pumpAndSettle();

    // The age selector is shared by AI and Manual modes; switch to Manual
    // because the current default AI mode intentionally hides manual-only fields.
    await tester.tap(find.text('ทำเองทั้งหมด'));
    await tester.pumpAndSettle();

    final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
    expect(slider.min, 18);
    expect(slider.max, 60);
    expect(slider.values.start, 18);
    expect(slider.values.end, 60);
    expect(
      find.text('เลือกกลุ่มผู้ชมได้ตั้งแต่อายุ 18–60 ปี ปรับช่วงอายุได้เองทั้งโหมดตัวช่วยออฟไลน์ และโหมดทำเอง'),
      findsOneWidget,
    );
  });

  testWidgets('Campaign Studio shows a clearly labelled planning-only reach range', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(430, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CampaignPage())),
    );
    await tester.pumpAndSettle();

    final budgetField = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == '300',
    );
    expect(budgetField, findsOneWidget);
    await tester.enterText(budgetField, '300');
    await tester.pumpAndSettle();

    expect(find.textContaining('ประมาณ 10,500–58,333 คน'), findsOneWidget);
    expect(find.textContaining('CPM ฿30–฿100'), findsOneWidget);
    expect(find.textContaining('ไม่ใช่ผลคาดการณ์จาก Meta'), findsOneWidget);
  });

}
