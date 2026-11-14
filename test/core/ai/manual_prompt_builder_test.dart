import 'package:flutter_test/flutter_test.dart';
import 'package:adnexa/core/ai/ai_request.dart';
import 'package:adnexa/core/ai/manual_prompt_builder.dart';

void main() {
  const builder = ManualPromptBuilder();

  test('builds a Thai copywriter prompt with context and review safeguards', () {
    const request = AiRequest(
      task: 'copywriter',
      prompt: '  เขียนแคปชันร้านกาแฟ  ',
      languageCode: 'th',
      context: {'สินค้า': 'กาแฟเย็น', 'ราคา': '45 บาท'},
    );

    final prompt = builder.build(request);

    expect(prompt, contains('AI COPYWRITER'));
    expect(prompt, contains('ตอบเป็นภาษา th'));
    expect(prompt, contains('สินค้า: กาแฟเย็น'));
    expect(prompt, contains('เขียนแคปชันร้านกาแฟ'));
    expect(prompt, contains('ผู้ใช้ต้องตรวจสอบก่อนนำไปใช้'));
  });

  test('supports every approved CONTENTNEX AI role', () {
    const tasks = [
      'council_strategy',
      'copywriter',
      'poster_brief',
      'video_script',
      'content_plan',
      'quality_review',
    ];

    for (final task in tasks) {
      final prompt = builder.build(AiRequest(task: task, prompt: 'ทดสอบ'));
      expect(prompt, contains('ทดสอบ'));
    }
  });

  test('rejects tasks outside the allowlist', () {
    expect(
      () => builder.build(
        const AiRequest(task: 'unknown', prompt: 'test'),
      ),
      throwsArgumentError,
    );
  });

  test('marks context as empty when none is provided', () {
    final prompt = builder.build(
      const AiRequest(task: 'council_strategy', prompt: 'วิเคราะห์สินค้า'),
    );

    expect(prompt, contains('ไม่มีข้อมูลบริบทเพิ่มเติม'));
  });
}
