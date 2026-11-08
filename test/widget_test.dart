import 'package:adnexa/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders ADNEXA dashboard and campaign navigation', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AdnexaApp());

    expect(find.text('ADNEXA'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Campaigns'), findsOneWidget);
    expect(find.text('Accounts'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);

    await tester.tap(find.text('Campaigns'));
    await tester.pumpAndSettle();

    expect(find.text('Campaign Studio'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Save draft'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Save draft'), findsOneWidget);
  });

  testWidgets('opens billing and shows available payment methods', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AdnexaApp());

    await tester.scrollUntilVisible(
      find.text('Billing'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Billing'));
    await tester.pumpAndSettle();

    expect(find.text('Billing & Subscription'), findsOneWidget);
    expect(find.text('โอนเงินผ่านธนาคาร'), findsOneWidget);
    expect(find.text('สแกนจ่าย PromptPay'), findsOneWidget);
    expect(find.text('บัตรเครดิต / เดบิต'), findsOneWidget);
    expect(find.text('ต่ออายุสมาชิกอัตโนมัติ'), findsOneWidget);
    expect(find.textContaining('ยังไม่มีการตัดเงินจริง'), findsOneWidget);
  });

  testWidgets('shows AI Commander automation guardrails', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AdnexaApp());
    await tester.tap(find.text('AI'));
    await tester.pumpAndSettle();

    expect(find.text('AI COMMANDER'), findsOneWidget);
    expect(find.text('อนุญาตให้ AI ปรับแคมเปญอัตโนมัติ'), findsOneWidget);
    expect(find.textContaining('เพดานงบโฆษณาต่อวัน'), findsOneWidget);
    expect(find.text('หยุด/แจ้งเตือนเมื่อ CPA เกินเป้าหมาย'), findsOneWidget);
    expect(find.text('ต้องอนุมัติก่อนสร้าง/เผยแพร่แคมเปญใหม่'), findsOneWidget);
    expect(find.textContaining('ยังไม่มี OAuth, AI API'), findsOneWidget);
  });

}
