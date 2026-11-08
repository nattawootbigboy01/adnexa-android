import 'package:adnexa/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders ADNEXA dashboard and navigation', (tester) async {
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
    expect(find.text('Save draft'), findsOneWidget);
  });
}
