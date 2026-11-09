import 'package:flutter_test/flutter_test.dart';
import 'package:adnexa/main.dart';

void main() {
  testWidgets('ADNEXA app starts and shows its brand', (tester) async {
    await tester.pumpWidget(const AdnexaApp());
    expect(find.text('ADNEXA'), findsOneWidget);
  });
}
