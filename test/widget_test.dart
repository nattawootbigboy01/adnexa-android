import 'package:adnexa/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders ADNEXA dashboard and campaign navigation', (tester) async {
    await tester.view.setPhysicalSize(const Size(1080, 1920));
    await tester.view.setDevicePixelRatio(1);
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
}
