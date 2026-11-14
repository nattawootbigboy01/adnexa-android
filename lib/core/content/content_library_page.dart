import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'content_item.dart';
import 'content_library_store.dart';

class ContentLibraryPage extends StatefulWidget {
  const ContentLibraryPage({super.key});

  @override
  State<ContentLibraryPage> createState() => _ContentLibraryPageState();
}

class _ContentLibraryPageState extends State<ContentLibraryPage> {
  final _store = ContentLibraryStore();
  final _searchController = TextEditingController();
  List<ContentItem> _items = [];
  bool _loading = true;
  String _selectedTask = 'all';

  static const _tasks = <String, String>{
    'all': 'ทุกบทบาท',
    'council_strategy': 'AI COUNCIL',
    'copywriter': 'AI COPYWRITER',
    'poster_brief': 'POSTER STUDIO',
    'video_script': 'VIDEO SCRIPT',
    'content_plan': 'CONTENT PLANNER',
    'quality_review': 'QUALITY CONTROLLER',
  };

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final items = await _store.loadAll();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  String _taskLabel(String task) => _tasks[task] ?? task;

  List<ContentItem> get _visibleItems {
    final query = _searchController.text.trim().toLowerCase();
    return _items.where((item) {
      final matchesTask = _selectedTask == 'all' || item.task == _selectedTask;
      final searchable = '${item.title} ${item.content} ${_taskLabel(item.task)}'.toLowerCase();
      return matchesTask && (query.isEmpty || searchable.contains(query));
    }).toList();
  }

  Future<void> _edit(ContentItem item) async {
    final title = TextEditingController(text: item.title);
    final content = TextEditingController(text: item.content);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('แก้ไขผลงาน'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'ชื่อผลงาน'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: content,
                  minLines: 6,
                  maxLines: 14,
                  decoration: const InputDecoration(labelText: 'เนื้อหา'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
    if (result == true && title.text.trim().isNotEmpty &&
        content.text.trim().isNotEmpty) {
      await _store.save(item.copyWith(
        title: title.text.trim(),
        content: content.text.trim(),
        updatedAt: DateTime.now(),
      ));
      await _refresh();
    }
    title.dispose();
    content.dispose();
  }

  Future<void> _delete(ContentItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ลบผลงานนี้?'),
        content: Text('ต้องการลบ “${item.title}” จากคลังในเครื่องหรือไม่'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _store.delete(item.id);
      await _refresh();
    }
  }

  Widget _emptyState({required String title, required String detail}) =>
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF141620),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(Icons.library_books_outlined, size: 30,
                color: Color(0xFF9295A5)),
            const SizedBox(height: 9),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Text(detail, textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF9295A5), fontSize: 11)),
          ],
        ),
      );

  Widget _itemCard(ContentItem item) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF141620),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: .06)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: Text(item.title,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') _edit(item);
              if (value == 'delete') _delete(item);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
              PopupMenuItem(value: 'delete', child: Text('ลบ')),
            ],
          ),
        ]),
        Text(_taskLabel(item.task),
          style: const TextStyle(color: Color(0xFFBBA8FF), fontSize: 10)),
        const SizedBox(height: 8),
        Text(item.content, maxLines: 5, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, height: 1.5)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: Text(
              item.createdAt.toLocal().toString().substring(0, 16),
              style: const TextStyle(color: Color(0xFF9295A5), fontSize: 9),
            ),
          ),
          IconButton(
            tooltip: 'คัดลอกเนื้อหา',
            visualDensity: VisualDensity.compact,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: item.content));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('คัดลอกผลงานแล้ว')),
                );
              }
            },
            icon: const Icon(Icons.copy, size: 17),
          ),
          IconButton(
            tooltip: 'แก้ไข',
            visualDensity: VisualDensity.compact,
            onPressed: () => _edit(item),
            icon: const Icon(Icons.edit_outlined, size: 17),
          ),
        ]),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final visibleItems = _visibleItems;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        const Text(
          'คลังผลงานของคุณ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        const Text(
          'ค้นหาและจัดการร่างคอนเทนต์ที่นำกลับมาจาก Gemini',
          style: TextStyle(color: Color(0xFF9295A5), fontSize: 11, height: 1.5),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'ค้นหาชื่อผลงานหรือข้อความในเนื้อหา',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'ล้างคำค้นหา',
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _selectedTask,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'กรองตามบทบาท AI',
            prefixIcon: Icon(Icons.filter_list),
          ),
          items: _tasks.entries.map((entry) => DropdownMenuItem(
            value: entry.key,
            child: Text(entry.value, overflow: TextOverflow.ellipsis),
          )).toList(),
          onChanged: (value) => setState(() => _selectedTask = value ?? 'all'),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_items.isEmpty)
          _emptyState(
            title: 'ยังไม่มีผลงานในคลัง',
            detail: 'ไปที่ CONTENTNEX AI แล้วใช้ปุ่ม “นำผลลัพธ์จาก Gemini เข้าแอป”',
          )
        else if (visibleItems.isEmpty)
          _emptyState(
            title: 'ไม่พบผลงานที่ตรงกัน',
            detail: 'ลองเปลี่ยนคำค้นหาหรือตัวกรองบทบาท AI',
          )
        else ...[
          Text(
            'พบ ${visibleItems.length} จาก ${_items.length} ผลงาน',
            style: const TextStyle(color: Color(0xFF9295A5), fontSize: 10),
          ),
          const SizedBox(height: 9),
          ...visibleItems.map(_itemCard),
        ],
        const SizedBox(height: 10),
        const Text(
          'หมายเหตุ: คลังนี้จัดเก็บในอุปกรณ์เครื่องนี้เท่านั้น ยังไม่มี Cloud Sync หรือการสำรองข้อมูลออนไลน์',
          style: TextStyle(color: Color(0xFF9295A5), fontSize: 10, height: 1.5),
        ),
      ],
    );
  }
}
