import 'ai_request.dart';

/// Builds a ready-to-paste prompt for the user's own Gemini account.
///
/// This class performs no network request and never accesses account
/// credentials. The user remains responsible for opening Gemini, reviewing
/// the prompt, and deciding whether to submit it.
class ManualPromptBuilder {
  const ManualPromptBuilder();

  static const Map<String, String> _roleInstructions = {
    'council_strategy':
        'รับบทเป็น AI COUNCIL: วิเคราะห์ตลาด ลูกค้าเป้าหมาย จุดขาย คู่แข่ง '
        'และเสนอแนวทางคอนเทนต์ที่ทำได้จริง พร้อมระบุสมมติฐานและสิ่งที่ยังไม่รู้',
    'copywriter':
        'รับบทเป็น AI COPYWRITER: สร้าง Hook, Caption, จุดขาย และ CTA '
        'หลายรูปแบบ หลีกเลี่ยงคำกล่าวอ้างเกินจริง',
    'poster_brief':
        'รับบทเป็น POSTER STUDIO: เสนอแนวคิดโปสเตอร์ องค์ประกอบภาพ '
        'ลำดับข้อความ โทนสี และ Layout โดยไม่อ้างว่าได้สร้างไฟล์ภาพแล้ว',
    'video_script':
        'รับบทเป็น VIDEO SCRIPT STUDIO: เขียนสคริปต์แบ่งฉาก '
        'ระบุภาพ เสียง บทพูด และเวลาของแต่ละฉาก',
    'content_plan':
        'รับบทเป็น CONTENT PLANNER: วางแผนคอนเทนต์ตามช่วงเวลาที่ระบุ '
        'พร้อมหัวข้อ รูปแบบโพสต์ และเป้าหมายของแต่ละชิ้น',
    'quality_review':
        'รับบทเป็น QUALITY CONTROLLER: ตรวจความชัดเจน ความสอดคล้อง '
        'ความน่าเชื่อถือ คำกล่าวอ้าง และเสนอวิธีแก้ไข',
  };

  String build(AiRequest request) {
    final instruction = _roleInstructions[request.task];
    if (instruction == null) {
      throw ArgumentError.value(request.task, 'task', 'Unsupported AI task');
    }

    final contextLines = request.context.entries
        .map((entry) => '- ${entry.key}: ${entry.value}')
        .join('\\n');
    final contextSection = contextLines.isEmpty
        ? 'ไม่มีข้อมูลบริบทเพิ่มเติม'
        : contextLines;

    return [
      'คุณคือผู้ช่วยสร้างคอนเทนต์สำหรับธุรกิจ',
      instruction,
      'ตอบเป็นภาษา ${request.languageCode}',
      '',
      'ข้อกำหนด:',
      '- แยกข้อเท็จจริง สมมติฐาน และคำแนะนำให้ชัดเจน',
      '- หากข้อมูลไม่พอ ให้ถามหรือระบุว่าไม่ทราบ ห้ามแต่งข้อมูลขึ้นเอง',
      '- ผลลัพธ์เป็นฉบับร่าง ผู้ใช้ต้องตรวจสอบก่อนนำไปใช้',
      '',
      'บริบท:',
      contextSection,
      '',
      'คำสั่งจากผู้ใช้:',
      request.prompt.trim(),
    ].join('\\n');
  }
}
