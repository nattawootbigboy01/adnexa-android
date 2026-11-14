import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adnexa/core/content/content_item.dart';
import 'package:adnexa/core/content/content_library_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saves and reloads content drafts', () async {
    final store = ContentLibraryStore();
    final item = ContentItem(
      id: 'draft-1',
      title: 'โพสต์ร้านกาแฟ',
      task: 'copywriter',
      content: 'กาแฟหอมพร้อมเสิร์ฟ',
      createdAt: DateTime.utc(2026, 11, 15),
    );

    await store.save(item);
    final loaded = await store.loadAll();

    expect(loaded, hasLength(1));
    expect(loaded.single.title, 'โพสต์ร้านกาแฟ');
    expect(loaded.single.content, 'กาแฟหอมพร้อมเสิร์ฟ');
  });

  test('updates an existing draft instead of duplicating it', () async {
    final store = ContentLibraryStore();
    final item = ContentItem(
      id: 'draft-1',
      title: 'ชื่อเดิม',
      task: 'copywriter',
      content: 'ร่างเดิม',
      createdAt: DateTime.utc(2026, 11, 15),
    );
    await store.save(item);
    await store.save(item.copyWith(title: 'ชื่อใหม่'));

    final loaded = await store.loadAll();
    expect(loaded, hasLength(1));
    expect(loaded.single.title, 'ชื่อใหม่');
  });

  test('deletes a draft from local storage', () async {
    final store = ContentLibraryStore();
    final item = ContentItem(
      id: 'draft-1',
      title: 'โพสต์',
      task: 'copywriter',
      content: 'เนื้อหา',
      createdAt: DateTime.utc(2026, 11, 15),
    );
    await store.save(item);
    await store.delete(item.id);

    expect(await store.loadAll(), isEmpty);
  });
}
