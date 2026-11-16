import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_users_page.dart';

const _adminBg = Color(0xFF08090D);
const _adminPanel = Color(0xFF141620);
const _adminAccent = Color(0xFF9270FF);
const _adminMuted = Color(0xFF9295A5);

typedef AdminClaimsLoader = Future<Map<String, dynamic>> Function();

const _adminApiBaseUrl = String.fromEnvironment('ADMIN_API_BASE_URL');

Future<Map<String, dynamic>> _loadCurrentClaims() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const {};
  final result = await user.getIdTokenResult(true);
  final claims = result.claims ?? const <String, dynamic>{};
  if (claims['contentnexRole'] != 'super_admin') return claims;

  if (_adminApiBaseUrl.isEmpty) {
    throw StateError('ADMIN_API_BASE_URL_NOT_CONFIGURED');
  }

  final client = HttpClient();
  try {
    final uri = Uri.parse(
      '${_adminApiBaseUrl.replaceFirst(RegExp(r'/+

/// CONTENTNEX access is granted only by the server-issued custom claim.
class AdminPage extends StatefulWidget {
  final AdminClaimsLoader? loadClaims;

  const AdminPage({super.key, this.loadClaims});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late Future<Map<String, dynamic>> _claims;

  @override
  void initState() {
    super.initState();
    _claims = (widget.loadClaims ?? _loadCurrentClaims)();
  }

  void _refresh() {
    setState(() {
      _claims = (widget.loadClaims ?? _loadCurrentClaims)();
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
        future: _claims,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              backgroundColor: _adminBg,
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return _AccessMessage(
              title: 'ตรวจสอบสิทธิ์ไม่สำเร็จ',
              detail: 'ไม่สามารถอ่าน Firebase ID Token ได้ กรุณาเข้าสู่ระบบใหม่และลองอีกครั้ง',
              action: _refresh,
            );
          }
          final role = snapshot.data?['contentnexRole'];
          if (role != 'super_admin' || snapshot.data?['_serverAuthorized'] != true) {
            return _AccessMessage(
              title: 'ไม่มีสิทธิ์ผู้ดูแลระบบ',
              detail: 'บัญชีนี้ไม่มีสิทธิ์ CONTENTNEX Super Admin หากเพิ่งได้รับสิทธิ์ กรุณาออกจากระบบแล้วเข้าสู่ระบบใหม่',
              action: _refresh,
            );
          }
          return _AdminDashboard(onRefresh: _refresh);
        },
      );
}

class _AccessMessage extends StatelessWidget {
  final String title;
  final String detail;
  final VoidCallback action;

  const _AccessMessage({
    required this.title,
    required this.detail,
    required this.action,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _adminBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings_outlined,
                    size: 48, color: Color(0xFFC7B5FF)),
                const SizedBox(height: 16),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(detail,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: _adminMuted, fontSize: 12, height: 1.5)),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: action,
                  icon: const Icon(Icons.refresh),
                  label: const Text('ตรวจสอบสิทธิ์อีกครั้ง'),
                ),
              ],
            ),
          ),
        ),
      );
}

class _AdminDashboard extends StatelessWidget {
  final VoidCallback onRefresh;
  const _AdminDashboard({required this.onRefresh});

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.admin_panel_settings_outlined,
                        color: Color(0xFFC7B5FF), size: 27),
                    const SizedBox(width: 10),
                    const Text('ADMIN CONTROL CENTER',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            fontSize: 14)),
                    const Spacer(),
                    IconButton(
                      tooltip: 'ออกจากระบบ',
                      onPressed: () => FirebaseAuth.instance.signOut(),
                      icon: const Icon(Icons.logout_rounded),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  const Text('จัดการและกำกับดูแล CONTENTNEX',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  const Text('ยืนยันสิทธิ์ CONTENTNEX Super Admin แล้ว',
                      style: TextStyle(color: Color(0xFFC5BEDA), fontSize: 11)),
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
                  Icon(Icons.info_outline, color: Color(0xFFFFC978), size: 21),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ตรวจสอบสิทธิ์ผู้ดูแลผ่าน Firebase แล้ว แต่เครื่องมือจัดการข้อมูลจริงยังรอการเชื่อมต่อ Backend และระบบบันทึก Audit Log',
                      style: TextStyle(color: Color(0xFFE5D2B5), fontSize: 11, height: 1.5),
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
              Expanded(child: _AdminMetric(label: 'ผู้ใช้งาน', value: '—', icon: Icons.people_alt)),
              SizedBox(width: 9),
              Expanded(child: _AdminMetric(label: 'รายงานรอตรวจ', value: '—', icon: Icons.flag_outlined)),
            ]),
            const SizedBox(height: 9),
            const Row(children: [
              Expanded(child: _AdminMetric(label: 'การเชื่อมต่อ', value: '—', icon: Icons.hub_outlined)),
              SizedBox(width: 9),
              Expanded(child: _AdminMetric(label: 'เหตุการณ์ระบบ', value: '—', icon: Icons.receipt_long)),
            ]),
            const SizedBox(height: 20),
            const Text('เครื่องมือผู้ดูแล',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            AdminUsersEntryCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AdminUsersPage(),
                ),
              ),
            ),
            const _AdminModule(icon: Icons.gavel_outlined, title: 'ตรวจสอบเนื้อหาและรายงาน', subtitle: 'คิวตรวจสอบ รายงาน และการดำเนินการ', status: 'รอระบบจัดเก็บ'),
            const _AdminModule(icon: Icons.link_outlined, title: 'สถานะการเชื่อมต่อแพลตฟอร์ม', subtitle: 'Meta, TikTok และสถานะบริการ', status: 'ยังไม่เชื่อมต่อ'),
            const _AdminModule(icon: Icons.history, title: 'Audit Log', subtitle: 'บันทึกผู้กระทำ เหตุผล และเวลา', status: 'รอฐานข้อมูล'),
            const _AdminModule(icon: Icons.tune_outlined, title: 'ตั้งค่าระบบ', subtitle: 'นโยบาย ความปลอดภัย และค่ากำหนด', status: 'ปิดไว้'),
            const SizedBox(height: 12),
            const Text(
              'หลักความปลอดภัย: ทุกคำสั่งสำคัญต้องตรวจสิทธิ์จากเซิร์ฟเวอร์ ไม่เชื่อข้อมูลบทบาทจากหน้าจอ และบันทึก Audit Log',
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

  const _AdminMetric({required this.label, required this.value, required this.icon});

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
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(color: _adminMuted, fontSize: 10)),
          ],
        ),
      );
}

class _AdminModule extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;

  const _AdminModule({required this.icon, required this.title, required this.subtitle, required this.status});

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
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(color: _adminMuted, fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(status, textAlign: TextAlign.end,
                style: const TextStyle(color: Color(0xFFFFC978), fontSize: 9, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
), '')}/v1/admin/access-check',
    );
    final request = await client.getUrl(uri);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer ${result.token}');
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('ADMIN_ACCESS_CHECK_${response.statusCode}: $body');
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic> || decoded['authorized'] != true) {
      throw const FormatException('ADMIN_SERVER_AUTHORIZATION_FAILED');
    }
    return {...claims, '_serverAuthorized': true};
  } finally {
    client.close(force: true);
  }
}

/// CONTENTNEX access is granted only by the server-issued custom claim.
class AdminPage extends StatefulWidget {
  final AdminClaimsLoader? loadClaims;

  const AdminPage({super.key, this.loadClaims});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late Future<Map<String, dynamic>> _claims;

  @override
  void initState() {
    super.initState();
    _claims = (widget.loadClaims ?? _loadCurrentClaims)();
  }

  void _refresh() {
    setState(() {
      _claims = (widget.loadClaims ?? _loadCurrentClaims)();
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
        future: _claims,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              backgroundColor: _adminBg,
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return _AccessMessage(
              title: 'ตรวจสอบสิทธิ์ไม่สำเร็จ',
              detail: 'ไม่สามารถอ่าน Firebase ID Token ได้ กรุณาเข้าสู่ระบบใหม่และลองอีกครั้ง',
              action: _refresh,
            );
          }
          final role = snapshot.data?['contentnexRole'];
          if (role != 'super_admin') {
            return _AccessMessage(
              title: 'ไม่มีสิทธิ์ผู้ดูแลระบบ',
              detail: 'บัญชีนี้ไม่มีสิทธิ์ CONTENTNEX Super Admin หากเพิ่งได้รับสิทธิ์ กรุณาออกจากระบบแล้วเข้าสู่ระบบใหม่',
              action: _refresh,
            );
          }
          return _AdminDashboard(onRefresh: _refresh);
        },
      );
}

class _AccessMessage extends StatelessWidget {
  final String title;
  final String detail;
  final VoidCallback action;

  const _AccessMessage({
    required this.title,
    required this.detail,
    required this.action,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _adminBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings_outlined,
                    size: 48, color: Color(0xFFC7B5FF)),
                const SizedBox(height: 16),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(detail,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: _adminMuted, fontSize: 12, height: 1.5)),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: action,
                  icon: const Icon(Icons.refresh),
                  label: const Text('ตรวจสอบสิทธิ์อีกครั้ง'),
                ),
              ],
            ),
          ),
        ),
      );
}

class _AdminDashboard extends StatelessWidget {
  final VoidCallback onRefresh;
  const _AdminDashboard({required this.onRefresh});

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.admin_panel_settings_outlined,
                        color: Color(0xFFC7B5FF), size: 27),
                    const SizedBox(width: 10),
                    const Text('ADMIN CONTROL CENTER',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            fontSize: 14)),
                    const Spacer(),
                    IconButton(
                      tooltip: 'ออกจากระบบ',
                      onPressed: () => FirebaseAuth.instance.signOut(),
                      icon: const Icon(Icons.logout_rounded),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  const Text('จัดการและกำกับดูแล CONTENTNEX',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  const Text('ยืนยันสิทธิ์ CONTENTNEX Super Admin แล้ว',
                      style: TextStyle(color: Color(0xFFC5BEDA), fontSize: 11)),
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
                  Icon(Icons.info_outline, color: Color(0xFFFFC978), size: 21),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ตรวจสอบสิทธิ์ผู้ดูแลผ่าน Firebase แล้ว แต่เครื่องมือจัดการข้อมูลจริงยังรอการเชื่อมต่อ Backend และระบบบันทึก Audit Log',
                      style: TextStyle(color: Color(0xFFE5D2B5), fontSize: 11, height: 1.5),
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
              Expanded(child: _AdminMetric(label: 'ผู้ใช้งาน', value: '—', icon: Icons.people_alt)),
              SizedBox(width: 9),
              Expanded(child: _AdminMetric(label: 'รายงานรอตรวจ', value: '—', icon: Icons.flag_outlined)),
            ]),
            const SizedBox(height: 9),
            const Row(children: [
              Expanded(child: _AdminMetric(label: 'การเชื่อมต่อ', value: '—', icon: Icons.hub_outlined)),
              SizedBox(width: 9),
              Expanded(child: _AdminMetric(label: 'เหตุการณ์ระบบ', value: '—', icon: Icons.receipt_long)),
            ]),
            const SizedBox(height: 20),
            const Text('เครื่องมือผู้ดูแล',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const _AdminModule(icon: Icons.people_outline, title: 'จัดการผู้ใช้งาน', subtitle: 'ค้นหาบัญชี ดูสถานะ และจัดการบทบาท', status: 'รอ Backend'),
            const _AdminModule(icon: Icons.gavel_outlined, title: 'ตรวจสอบเนื้อหาและรายงาน', subtitle: 'คิวตรวจสอบ รายงาน และการดำเนินการ', status: 'รอระบบจัดเก็บ'),
            const _AdminModule(icon: Icons.link_outlined, title: 'สถานะการเชื่อมต่อแพลตฟอร์ม', subtitle: 'Meta, TikTok และสถานะบริการ', status: 'ยังไม่เชื่อมต่อ'),
            const _AdminModule(icon: Icons.history, title: 'Audit Log', subtitle: 'บันทึกผู้กระทำ เหตุผล และเวลา', status: 'รอฐานข้อมูล'),
            const _AdminModule(icon: Icons.tune_outlined, title: 'ตั้งค่าระบบ', subtitle: 'นโยบาย ความปลอดภัย และค่ากำหนด', status: 'ปิดไว้'),
            const SizedBox(height: 12),
            const Text(
              'หลักความปลอดภัย: ทุกคำสั่งสำคัญต้องตรวจสิทธิ์จากเซิร์ฟเวอร์ ไม่เชื่อข้อมูลบทบาทจากหน้าจอ และบันทึก Audit Log',
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

  const _AdminMetric({required this.label, required this.value, required this.icon});

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
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(color: _adminMuted, fontSize: 10)),
          ],
        ),
      );
}

class _AdminModule extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;

  const _AdminModule({required this.icon, required this.title, required this.subtitle, required this.status});

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
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(color: _adminMuted, fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(status, textAlign: TextAlign.end,
                style: const TextStyle(color: Color(0xFFFFC978), fontSize: 9, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
