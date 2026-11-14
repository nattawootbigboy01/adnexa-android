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
  List<ContentItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final items = await _store.loadAll();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  String _taskLabel(String task) => switch (task) {
    'council_strategy' => 'AI COUNCIL',
    'copywriter' => 'AI COPYWRITER',
    'poster_brief' => 'POSTER STUDIO',
    'video_script' => 'VIDEO SCRIPT',
    'content_plan' => 'CONTENT PLANNER',
    'quality_review' => 'QUALITY CONTROLLER',
    _ => task,
  };

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

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
    children: [
      const Text(
        'คลังผลงานของคุณ',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 5),
      const Text(
        'เก็บร่างที่นำกลับมาจาก Gemini ไว้ในอุปกรณ์ แก้ไข คัดลอก หรือลบได้',
        style: TextStyle(color: Color(0xFF9295A5), fontSize: 11, height: 1.5),
      ),
      const SizedBox(height: 14),
      if (_loading)
        const Center(child: CircularProgressIndicator())
      else if (_items.isEmpty)
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF141620),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            children: [
              Icon(Icons.library_books_outlined, size: 30,
                  color: Color(0xFF9295A5)),
              SizedBox(height: 9),
              Text('ยังไม่มีผลงานในคลัง',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 5),
              Text(
                'ไปที่ CONTENTNEX AI แล้วใช้ปุ่ม “นำผลลัพธ์จาก Gemini เข้าแอป”',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9295A5), fontSize: 11),
              ),
            ],
          ),
        )
      else
        ..._items.map((item) => Container(
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
                Text(
                  '${item.createdAt.toLocal().toString().substring(0, 16)}',
                  style: const TextStyle(color: Color(0xFF9295A5), fontSize: 9),
                ),
                const Spacer(),
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
        )),
      const SizedBox(height: 10),
      const Text(
        'หมายเหตุ: คลังนี้จัดเก็บในอุปกรณ์เครื่องนี้เท่านั้น ยังไม่มี Cloud Sync หรือการสำรองข้อมูลออนไลน์',
        style: TextStyle(color: Color(0xFF9295A5), fontSize: 10, height: 1.5),
      ),
    ],
  );
}
