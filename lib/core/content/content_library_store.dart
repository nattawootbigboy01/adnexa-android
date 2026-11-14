import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'content_item.dart';

/// Device-local draft storage. No cloud sync or external transmission.
class ContentLibraryStore {
  ContentLibraryStore({SharedPreferences? preferences})
      : _preferences = preferences;

  static const storageKey = 'contentnex.content_library.v1';
  final SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async =>
      _preferences ?? SharedPreferences.getInstance();

  Future<List<ContentItem>> loadAll() async {
    final raw = (await _prefs).getString(storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((entry) => ContentItem.fromJson(
                Map<String, dynamic>.from(entry),
              ))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  Future<void> save(ContentItem item) async {
    final items = await loadAll();
    final index = items.indexWhere((entry) => entry.id == item.id);
    if (index == -1) {
      items.insert(0, item);
    } else {
      items[index] = item;
    }
    await _write(items);
  }

  Future<void> delete(String id) async {
    final items = await loadAll();
    items.removeWhere((entry) => entry.id == id);
    await _write(items);
  }

  Future<void> _write(List<ContentItem> items) async {
    final encoded = jsonEncode(items.map((item) => item.toJson()).toList());
    await (await _prefs).setString(storageKey, encoded);
  }
}
