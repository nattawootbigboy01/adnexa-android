import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adnexa/main.dart';

void main() {
  testWidgets('ADNEXA app starts and shows its brand', (tester) async {
    await tester.pumpWidget(const AdnexaApp());
    expect(find.text('ADNEXA'), findsOneWidget);
  });

  testWidgets('Campaign Studio restricts age targeting to 18-60', (tester) async {
    await tester.pumpWidget(const AdnexaApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Campaigns'));
    await tester.pumpAndSettle();

    final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
    expect(slider.min, 18);
    expect(slider.max, 60);
    expect(slider.values.start, 18);
    expect(slider.values.end, 60);
    expect(find.text('เลือกกลุ่มผู้ชมได้ตั้งแต่อายุ 18–60 ปี ปรับช่วงอายุได้เองทั้งโหมด AI และโหมดทำเอง'), findsOneWidget);
  });
}
