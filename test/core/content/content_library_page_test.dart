import 'package:adnexa/core/content/content_item.dart';
import 'package:adnexa/core/content/content_library_page.dart';
import 'package:adnexa/core/content/content_library_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('search filters saved drafts by title and content', (tester) async {
    final store = ContentLibraryStore();
    await store.save(ContentItem(
      id: 'coffee',
      title: 'โพสต์ร้านกาแฟ',
      task: 'copywriter',
      content: 'กาแฟคั่วสดพร้อมเสิร์ฟ',
      createdAt: DateTime.utc(2026, 11, 15),
    ));
    await store.save(ContentItem(
      id: 'shoes',
      title: 'แผนขายรองเท้า',
      task: 'content_plan',
      content: 'รองเท้าวิ่งสำหรับมือใหม่',
      createdAt: DateTime.utc(2026, 11, 14),
    ));

    await tester.pumpWidget(const MaterialApp(home: ContentLibraryPage()));
    await tester.pumpAndSettle();

    expect(find.text('โพสต์ร้านกาแฟ'), findsOneWidget);
    expect(find.text('แผนขายรองเท้า'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField).first,
      'กาแฟคั่วสด',
    );
    await tester.pumpAndSettle();

    expect(find.text('โพสต์ร้านกาแฟ'), findsOneWidget);
    expect(find.text('แผนขายรองเท้า'), findsNothing);
    expect(find.text('พบ 1 จาก 2 ผลงาน'), findsOneWidget);
  });

  testWidgets('AI role filter narrows the library', (tester) async {
    final store = ContentLibraryStore();
    await store.save(ContentItem(
      id: 'copy',
      title: 'ข้อความขายสินค้า',
      task: 'copywriter',
      content: 'รายละเอียดสินค้า',
      createdAt: DateTime.utc(2026, 11, 15),
    ));
    await store.save(ContentItem(
      id: 'video',
      title: 'บทวิดีโอ',
      task: 'video_script',
      content: 'ฉากเปิดเรื่อง',
      createdAt: DateTime.utc(2026, 11, 14),
    ));

    await tester.pumpWidget(const MaterialApp(home: ContentLibraryPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI COPYWRITER').last);
    await tester.pumpAndSettle();

    expect(find.text('ข้อความขายสินค้า'), findsOneWidget);
    expect(find.text('บทวิดีโอ'), findsNothing);
    expect(find.text('พบ 1 จาก 2 ผลงาน'), findsOneWidget);
  });
}
