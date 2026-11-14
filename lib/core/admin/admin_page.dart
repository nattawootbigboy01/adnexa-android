import 'package:flutter/material.dart';

const _adminBg = Color(0xFF08090D);
const _adminPanel = Color(0xFF141620);
const _adminAccent = Color(0xFF9270FF);
const _adminMuted = Color(0xFF9295A5);

/// Admin UI prototype. Privileged actions remain unavailable until the
/// verified backend endpoint, trusted admin claims, and audit storage exist.
class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _adminBg,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF302653), Color(0xFF171725)],
                ),
                border: Border.all(color: _adminAccent.withValues(alpha: .3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.admin_panel_settings_outlined,
                        color: Color(0xFFC7B5FF), size: 27),
                    SizedBox(width: 10),
                    Text('ADMIN CONTROL CENTER',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            fontSize: 14)),
                  ]),
                  SizedBox(height: 12),
                  Text('จัดการและกำกับดูแล CONTENTNEX',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  SizedBox(height: 5),
                  Text(
                    'พื้นที่ผู้ดูแลระบบ • แยกสิทธิ์จากบัญชีลูกค้า',
                    style: TextStyle(color: Color(0xFFC5BEDA), fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2117),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF9A6B2D)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_clock_outlined,
                      color: Color(0xFFFFC978), size: 21),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('โหมดต้นแบบ — ยังไม่เปิดสิทธิ์แอดมิน',
                            style: TextStyle(
                                color: Color(0xFFFFD99A),
                                fontWeight: FontWeight.w800,
                                fontSize: 12)),
                        SizedBox(height: 5),
                        Text(
                          'Backend ยังไม่ได้ Deploy และยังไม่มีการกำหนด Firebase Admin Custom Claims จึงยังไม่สามารถยืนยันสิทธิ์หรือจัดการข้อมูลจริงได้',
                          style: TextStyle(
                              color: Color(0xFFE5D2B5),
                              fontSize: 10,
                              height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('ภาพรวมระบบ',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const Row(children: [
              Expanded(
                  child: _AdminMetric(
                      label: 'ผู้ใช้งาน', value: '—', icon: Icons.people_alt)),
              SizedBox(width: 9),
              Expanded(
                  child: _AdminMetric(
                      label: 'รายงานรอตรวจ', value: '—', icon: Icons.flag_outlined)),
            ]),
            const SizedBox(height: 9),
            const Row(children: [
              Expanded(
                  child: _AdminMetric(
                      label: 'การเชื่อมต่อ', value: '—', icon: Icons.hub_outlined)),
              SizedBox(width: 9),
              Expanded(
                  child: _AdminMetric(
                      label: 'เหตุการณ์ระบบ', value: '—', icon: Icons.receipt_long)),
            ]),
            const SizedBox(height: 20),
            const Text('เครื่องมือผู้ดูแล',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const _AdminModule(
                icon: Icons.people_outline,
                title: 'จัดการผู้ใช้งาน',
                subtitle: 'ค้นหาบัญชี ดูสถานะ และจัดการบทบาท',
                status: 'รอ Backend'),
            const _AdminModule(
                icon: Icons.gavel_outlined,
                title: 'ตรวจสอบเนื้อหาและรายงาน',
                subtitle: 'คิวตรวจสอบ รายงาน และการดำเนินการ',
                status: 'รอระบบจัดเก็บ'),
            const _AdminModule(
                icon: Icons.link_outlined,
                title: 'สถานะการเชื่อมต่อแพลตฟอร์ม',
                subtitle: 'Meta, TikTok และสถานะบริการ',
                status: 'ยังไม่เชื่อมต่อ'),
            const _AdminModule(
                icon: Icons.history,
                title: 'Audit Log',
                subtitle: 'บันทึกผู้กระทำ เหตุผล และเวลา',
                status: 'รอฐานข้อมูล'),
            const _AdminModule(
                icon: Icons.tune_outlined,
                title: 'ตั้งค่าระบบ',
                subtitle: 'นโยบาย ความปลอดภัย และค่ากำหนด',
                status: 'ปิดไว้'),
            const SizedBox(height: 12),
            const Text(
              'หลักความปลอดภัย: ไม่กำหนดสิทธิ์จากข้อมูลในแอป, ไม่แสดงข้อมูลลูกค้าข้ามบัญชี และทุกคำสั่งสำคัญต้องตรวจสิทธิ์จากเซิร์ฟเวอร์พร้อมบันทึก Audit Log',
              style: TextStyle(color: _adminMuted, fontSize: 10, height: 1.55),
            ),
          ],
        ),
      );
}

class _AdminMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _AdminMetric(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _adminPanel,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: .06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFFC0AEFF), size: 19),
            const SizedBox(height: 10),
            Text(value,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(label,
                style: const TextStyle(color: _adminMuted, fontSize: 10)),
          ],
        ),
      );
}

class _AdminModule extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;

  const _AdminModule(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.status});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: _adminPanel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: .055)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF29243C),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: const Color(0xFFC4B3FF), size: 19),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style:
                          const TextStyle(color: _adminMuted, fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(status,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    color: Color(0xFFFFC978),
                    fontSize: 9,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
