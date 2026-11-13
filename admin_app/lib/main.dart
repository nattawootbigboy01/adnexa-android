import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const apiBase = String.fromEnvironment('ADNEXA_API_BASE_URL', defaultValue: 'https://adnexa-api.nattawootbigboy01.workers.dev');
const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
const appId = String.fromEnvironment('FIREBASE_APP_ID');
const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
const bg = Color(0xFF080B10), panel = Color(0xFF141B26), blue = Color(0xFF258BFF), silver = Color(0xFFDDE5EF), muted = Color(0xFF9BA8B8);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if ([apiKey, appId, senderId, projectId].any((v) => v.isEmpty)) {
    runApp(const AdminApp());
    return;
  }
  try {
    await Firebase.initializeApp(options: const FirebaseOptions(apiKey: apiKey, appId: appId, messagingSenderId: senderId, projectId: projectId));
    runApp(const AdminApp(firebaseReady: true));
  } catch (e) {
    runApp(AdminApp(startupError: e.toString()));
  }
}

class AdminApp extends StatelessWidget {
  final bool firebaseReady;
  final String? startupError;
  const AdminApp({super.key, this.firebaseReady = false, this.startupError});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ADNEXA ADMIN', debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: bg, colorScheme: const ColorScheme.dark(primary: blue, surface: panel), useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: panel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
    home: startupError != null ? SetupPage(message: 'เริ่มต้น Firebase ไม่สำเร็จ: ${startupError!}') : firebaseReady ? const AdminAuthGate() : const SetupPage(),
  );
}

class SetupPage extends StatelessWidget {
  final String message;
  const SetupPage({super.key, this.message = 'ยังไม่ได้กำหนดค่า Firebase สำหรับแอปแอดมิน กรุณาตั้งค่า GitHub Actions Variables ก่อนสร้าง APK'});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: Padding(padding: const EdgeInsets.all(26), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const BrandHeader(), const SizedBox(height: 24), const Icon(Icons.lock_outline, size: 44, color: silver), const SizedBox(height: 12),
      const Text('ต้องตั้งค่าระบบก่อนใช้งาน', textAlign: TextAlign.center, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: muted, height: 1.5)),
    ])))),
  );
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 46, height: 46, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: blue)), child: const Icon(Icons.trending_up_rounded, color: blue, size: 28)),
    const SizedBox(width: 12),
    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('ADNEXA ADMIN', style: TextStyle(color: silver, fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
      Text('SECURE OPERATIONS CONSOLE', style: TextStyle(color: muted, fontSize: 8, letterSpacing: 1.1)),
    ]),
  ]);
}

class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
      return snap.data == null ? const AdminLoginPage() : const AdminAccessGate();
    },
  );
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});
  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final email = TextEditingController(), password = TextEditingController();
  bool busy = false, hide = true;
  String? error;
  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }
  Future<void> login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) { setState(() => error = 'กรุณากรอกอีเมลและรหัสผ่าน'); return; }
    setState(() { busy = true; error = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email.text.trim(), password: password.text);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => error = (e.code == 'invalid-credential' || e.code == 'wrong-password' || e.code == 'user-not-found') ? 'อีเมลหรือรหัสผ่านไม่ถูกต้อง' : 'เข้าสู่ระบบไม่สำเร็จ (${e.code})');
    } catch (_) { if (mounted) setState(() => error = 'เกิดข้อผิดพลาด กรุณาลองใหม่'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 30), const BrandHeader(), const SizedBox(height: 34),
      const Text('เข้าสู่ระบบผู้ดูแล', textAlign: TextAlign.center, style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8), const Text('ใช้บัญชีที่ได้รับสิทธิ์ Admin เท่านั้น', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12)),
      const SizedBox(height: 26),
      TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'อีเมลผู้ดูแล', prefixIcon: Icon(Icons.email_outlined))),
      const SizedBox(height: 13),
      TextField(controller: password, obscureText: hide, decoration: InputDecoration(labelText: 'รหัสผ่าน', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => hide = !hide), icon: Icon(hide ? Icons.visibility_outlined : Icons.visibility_off_outlined))), onSubmitted: (_) => busy ? null : login()),
      if (error != null) ...[const SizedBox(height: 12), Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent))],
      const SizedBox(height: 20),
      FilledButton(onPressed: busy ? null : login, child: Padding(padding: const EdgeInsets.all(13), child: busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('เข้าสู่ระบบแอดมิน'))),
      const SizedBox(height: 14), const Text('ไม่มีปุ่มสมัครสมาชิก และไม่สามารถยกระดับบัญชีตัวเองเป็น Admin ได้', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 10, height: 1.5)),
    ]))))),
  );
}

class AdminAccessGate extends StatefulWidget {
  const AdminAccessGate({super.key});
  @override
  State<AdminAccessGate> createState() => _AdminAccessGateState();
}
class _AdminAccessGateState extends State<AdminAccessGate> {
  late final Future<bool> access = checkAccess();
  Future<bool> checkAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.emailVerified) return false;
    try {
      // The Worker checks the current server-side role registry. This supports
      // admins granted through the protected D1 role manager, not just claims.
      await AdminApi.get('/api/admin/access');
      return true;
    } catch (_) {
      return false;
    }
  }
  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(future: access, builder: (context, snap) {
    if (snap.connectionState != ConnectionState.done) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (snap.hasError || snap.data != true) {
      return Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.gpp_bad_outlined, size: 54, color: Colors.orangeAccent), const SizedBox(height: 12),
      const Text('บัญชีนี้ยังไม่มีสิทธิ์ผู้ดูแล', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8), const Text('การเข้าสู่ระบบสำเร็จไม่ได้หมายความว่าเป็น Admin ระบบตรวจสอบ Firebase custom claim และเซิร์ฟเวอร์จะตรวจสอบซ้ำทุกครั้ง', textAlign: TextAlign.center, style: TextStyle(color: muted, height: 1.5)),
      const SizedBox(height: 20), OutlinedButton.icon(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout), label: const Text('ออกจากระบบ')),
    ]))));
    }
    return const AdminDashboardPage();
  });
}

class AdminApi {
  static Future<Map<String, dynamic>> get(String path) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('กรุณาเข้าสู่ระบบใหม่');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) throw Exception('ยืนยันตัวตนไม่สำเร็จ');
    final response = await http.get(Uri.parse(apiBase + path), headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'}).timeout(const Duration(seconds: 20));
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) throw Exception('รูปแบบข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง');
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception(response.statusCode == 403 ? 'เซิร์ฟเวอร์ปฏิเสธสิทธิ์ผู้ดูแล' : decoded['error']?.toString() ?? 'โหลดข้อมูลไม่สำเร็จ');
    return decoded;
  }
  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('กรุณาเข้าสู่ระบบใหม่');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) throw Exception('ยืนยันตัวตนไม่สำเร็จ');
    final response = await http.put(
      Uri.parse(apiBase + path),
      headers: {'Authorization': 'Bearer ' + token, 'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 20));
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) throw Exception('รูปแบบข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(response.statusCode == 403 ? 'ไม่มีสิทธิ์เปลี่ยนบทบาทผู้ใช้' : decoded['error']?.toString() ?? 'บันทึกไม่สำเร็จ');
    }
    return decoded;
  }

  static Future<List<Map<String, dynamic>>> list(String path, String key) async {
    final value = (await get(path))[key];
    if (value is! List) return const [];
    return value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList(growable: false);
  }
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}
class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool loading = true;
  String? error;
  Map<String, dynamic> overview = const {};
  List<Map<String, dynamic>> connections = const [], events = const [], auditDetails = const [];
  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      final results = await Future.wait([
        AdminApi.get('/api/admin/overview'),
        AdminApi.list('/api/admin/connections', 'connections'),
        AdminApi.list('/api/admin/audit', 'events'),
        AdminApi.list('/api/admin/audit', 'details'),
      ]);
      if (!mounted) return;
      setState(() {
        overview = Map<String, dynamic>.from(results[0] as Map);
        connections = results[1] as List<Map<String, dynamic>>;
        events = results[2] as List<Map<String, dynamic>>;
        auditDetails = results[3] as List<Map<String, dynamic>>;
      });
    } catch (e) { if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => loading = false); }
  }
  String dateLabel(dynamic raw) {
    final seconds = int.tryParse(raw?.toString() ?? '');
    if (seconds == null) return '—';
    final d = DateTime.fromMillisecondsSinceEpoch(seconds * 1000).toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
  @override
  Widget build(BuildContext context) {
    final metrics = overview['metrics'] is Map ? Map<String, dynamic>.from(overview['metrics']) : <String, dynamic>{};
    return Scaffold(
      appBar: AppBar(backgroundColor: bg, title: const BrandHeader(), actions: [
        IconButton(tooltip: 'จัดการสมาชิก', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MemberManagementPage())), icon: const Icon(Icons.manage_accounts_outlined)),
        IconButton(tooltip: 'รีเฟรชข้อมูล', onPressed: loading ? null : load, icon: const Icon(Icons.refresh_rounded)),
        IconButton(tooltip: 'ออกจากระบบ', onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout_rounded)),
      ]),
      body: RefreshIndicator(onRefresh: load, child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 30), children: [
        const Text('ภาพรวมระบบ', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5), const Text('ศูนย์ควบคุม ADNEXA • โหมดอ่านข้อมูลอย่างเดียว', style: TextStyle(color: muted, fontSize: 11)),
        if (loading) ...[const SizedBox(height: 18), const LinearProgressIndicator()],
        if (error != null) ...[const SizedBox(height: 16), Panel(child: Text(error!, style: const TextStyle(color: Colors.orangeAccent)))],
        if (error == null && !loading) ...[
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: MetricCard(title: 'บัญชีที่เชื่อมต่อ', value: (metrics['connected_users'] ?? 0).toString(), icon: Icons.people_alt_outlined)),
            const SizedBox(width: 10),
            Expanded(child: MetricCard(title: 'การเชื่อมต่อที่ยังใช้ได้', value: (metrics['active_connections'] ?? 0).toString(), icon: Icons.verified_outlined)),
          ]),
          const SizedBox(height: 22), const SectionTitle('การเชื่อมต่อ Meta'),
          if (connections.isEmpty) const Panel(child: Text('ยังไม่มีรายการเชื่อมต่อ Meta')),
          ...connections.map((item) => Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['meta_name']?.toString() ?? 'Meta account', style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 5), Text('Meta ID: ${item['meta_user_id']?.toString() ?? '—'}', style: const TextStyle(color: muted, fontSize: 11)),
            Text('หมดอายุ: ${dateLabel(item['expires_at'])}', style: const TextStyle(color: muted, fontSize: 10)),
          ]))),
          const SizedBox(height: 12), const SectionTitle('ประวัติการใช้งานแอดมิน'),
          if (events.isEmpty) const Panel(child: Text('ยังไม่มีประวัติกิจกรรม')),
          ...events.map((event) => Panel(child: Row(children: [
            const Icon(Icons.history, color: blue, size: 18), const SizedBox(width: 10),
            Expanded(child: Text(event['action']?.toString() ?? 'กิจกรรม')),
            Text(dateLabel(event['created_at']), style: const TextStyle(color: muted, fontSize: 9)),
          ]))),
          if (auditDetails.isNotEmpty) ...[
            const SizedBox(height: 12), const SectionTitle('รายละเอียดการเปลี่ยนสิทธิ์'),
            ...auditDetails.map((item) => Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['action']?.toString() ?? 'การเปลี่ยนแปลง', style: const TextStyle(fontWeight: FontWeight.w800)),
              Text('สมาชิก UID: ${item['target_uid']?.toString() ?? '—'}', style: const TextStyle(color: muted, fontSize: 10)),
              Text('รายละเอียด: ${item['details']?.toString() ?? '—'}', style: const TextStyle(color: muted, fontSize: 10)),
              Text(dateLabel(item['created_at']), style: const TextStyle(color: muted, fontSize: 9)),
            ]))),
          ],
          const SizedBox(height: 12), const SectionTitle('ขอบเขตความปลอดภัย'),
          const Panel(child: Text('รุ่นแรกนี้อ่านได้เฉพาะภาพรวม การเชื่อมต่อ Meta และ Audit Log เท่านั้น ยังไม่มีการค้นหาหรือแก้ไขบัญชีลูกค้า เปลี่ยนสิทธิ์ ระงับบัญชี สร้างแคมเปญ หรือใช้งบโฆษณา การกำหนดสิทธิ์ Admin ต้องทำผ่านช่องทาง Firebase Admin ที่เชื่อถือได้', style: TextStyle(color: muted, height: 1.55, fontSize: 11))),
        ],
      ])),
    );
  }
}

class MemberManagementPage extends StatefulWidget {
  const MemberManagementPage({super.key});
  @override
  State<MemberManagementPage> createState() => _MemberManagementPageState();
}

class _MemberManagementPageState extends State<MemberManagementPage> {
  final search = TextEditingController();
  bool loading = true, saving = false, canManageRoles = false;
  String? error;
  List<Map<String, dynamic>> members = const [];

  @override
  void initState() { super.initState(); load(); }
  @override
  void dispose() { search.dispose(); super.dispose(); }

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      final query = Uri.encodeQueryComponent(search.text.trim());
      final result = await AdminApi.get(
        '/api/admin/members?limit=100${query.isEmpty ? '' : '&search=$query'}',
      );
      if (!mounted) return;
      setState(() {
        members = (result['members'] as List? ?? const [])
          .whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
        canManageRoles = result['can_manage_roles'] == true;
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> changeRole(Map<String, dynamic> member, String role) async {
    final uid = member['uid']?.toString() ?? '';
    final email = member['email']?.toString() ?? uid;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการเปลี่ยนสิทธิ์'),
        content: Text('ต้องการกำหนดสิทธิ์ $role ให้ $email ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ยืนยัน')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() { saving = true; error = null; });
    try {
      await AdminApi.put('/api/admin/members/${Uri.encodeComponent(uid)}/role', {'role': role});
      await load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกสิทธิ์เรียบร้อย')));
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String roleLabel(String role) {
    switch (role) {
      case 'super_admin': return 'ผู้ดูแลสูงสุด';
      case 'admin': return 'ผู้ดูแลระบบ';
      case 'support': return 'ฝ่ายสนับสนุน';
      default: return 'ลูกค้าทั่วไป';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('จัดการสมาชิก'), actions: [
        IconButton(onPressed: loading ? null : load, icon: const Icon(Icons.refresh)),
      ]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: [
            Expanded(child: TextField(
              controller: search,
              onSubmitted: (_) => load(),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ค้นหาอีเมลหรือ UID'),
            )),
            const SizedBox(width: 8),
            IconButton(onPressed: loading ? null : load, icon: const Icon(Icons.search, color: blue)),
          ]),
        ),
        if (saving) const LinearProgressIndicator(minHeight: 2),
        if (error != null) Padding(padding: const EdgeInsets.all(12), child: Text(error!, style: const TextStyle(color: Colors.orangeAccent))),
        Expanded(child: loading
          ? const Center(child: CircularProgressIndicator())
          : members.isEmpty
            ? const Center(child: Text('ยังไม่มีสมาชิกในทะเบียน\nสมาชิกจะปรากฏเมื่อเข้าสู่ระบบ ADNEXA หลังยืนยันอีเมล', textAlign: TextAlign.center, style: TextStyle(color: muted)))
            : RefreshIndicator(
                onRefresh: load,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final uid = member['uid']?.toString() ?? '';
                    final role = member['role']?.toString() ?? 'customer';
                    final email = member['email']?.toString() ?? 'ไม่พบอีเมล';
                    final canEdit = canManageRoles && uid != currentUid && role != 'super_admin';
                    return Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.account_circle_outlined, color: blue, size: 25),
                        const SizedBox(width: 9),
                        Expanded(child: Text(email, style: const TextStyle(fontWeight: FontWeight.w800))),
                        if (canEdit) PopupMenuButton<String>(
                          enabled: !saving,
                          tooltip: 'เปลี่ยนสิทธิ์',
                          onSelected: (value) => changeRole(member, value),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'customer', child: Text('ลูกค้าทั่วไป')),
                            PopupMenuItem(value: 'support', child: Text('ฝ่ายสนับสนุน')),
                            PopupMenuItem(value: 'admin', child: Text('ผู้ดูแลระบบ')),
                          ],
                        ),
                      ]),
                      const SizedBox(height: 7),
                      Text(roleLabel(role), style: const TextStyle(color: blue, fontSize: 11, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('UID: $uid', style: const TextStyle(color: muted, fontSize: 9)),
                      Text('เข้าใช้ล่าสุด: ${member['last_seen_at']?.toString() ?? '—'}', style: const TextStyle(color: muted, fontSize: 9)),
                    ]));
                  },
                ),
              )),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Text(
            canManageRoles
              ? 'ผู้ดูแลสูงสุดเท่านั้นที่เปลี่ยนบทบาทได้ • ไม่มีการระงับหรือลบบัญชีในรุ่นนี้'
              : 'ดูรายชื่อสมาชิกได้ • ต้องให้ผู้ดูแลสูงสุดเป็นผู้เปลี่ยนบทบาท',
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, fontSize: 10),
          ),
        ),
      ]),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)));
}
class Panel extends StatelessWidget {
  final Widget child;
  const Panel({required this.child, super.key});
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: .05))), child: child);
}
class MetricCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  const MetricCard({required this.title, required this.value, required this.icon, super.key});
  @override
  Widget build(BuildContext context) => Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, color: blue, size: 22), const SizedBox(height: 12),
    Text(value, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
    const SizedBox(height: 4), Text(title, style: const TextStyle(color: muted, fontSize: 10)),
  ]));
}
