import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'admin_page.dart';

const _apiKey = String.fromEnvironment('ADMIN_FIREBASE_API_KEY');
const _appId = String.fromEnvironment('ADMIN_FIREBASE_APP_ID');
const _senderId = String.fromEnvironment('ADMIN_FIREBASE_MESSAGING_SENDER_ID');
const _projectId = String.fromEnvironment('ADMIN_FIREBASE_PROJECT_ID');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ContentNexAdminApp());
}

class ContentNexAdminApp extends StatelessWidget {
  const ContentNexAdminApp({super.key});

  Future<FirebaseApp?> _initialize() async {
    if ([_apiKey, _appId, _senderId, _projectId].any((v) => v.isEmpty)) {
      return null;
    }
    return Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: _senderId,
        projectId: _projectId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'CONTENTNEX ADMIN',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF08090D),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF9270FF),
            surface: Color(0xFF141620),
          ),
          useMaterial3: true,
        ),
        home: FutureBuilder<FirebaseApp?>(
          future: _initialize(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _PageMessage(
                title: 'กำลังเริ่มต้นระบบ',
                detail: 'กำลังเชื่อมต่อบริการบัญชีผู้ดูแล',
                loading: true,
              );
            }
            if (snapshot.hasError) {
              return _PageMessage(
                title: 'เริ่มต้น Firebase ไม่สำเร็จ',
                detail: 'ตรวจสอบการตั้งค่า Firebase ของ CONTENTNEX ADMIN',
              );
            }
            if (snapshot.data == null) {
              return const _PageMessage(
                title: 'ยังไม่ได้ตั้งค่า Firebase',
                detail: 'ต้องกำหนด ADMIN_FIREBASE_API_KEY, ADMIN_FIREBASE_APP_ID, ADMIN_FIREBASE_MESSAGING_SENDER_ID และ ADMIN_FIREBASE_PROJECT_ID ก่อน Build',
              );
            }
            return const _AdminSessionGate();
          },
        ),
      );
}

class _AdminSessionGate extends StatelessWidget {
  const _AdminSessionGate();

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
        stream: FirebaseAuth.instance.userChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _PageMessage(
              title: 'กำลังตรวจสอบบัญชี',
              detail: 'โปรดรอสักครู่',
              loading: true,
            );
          }
          final user = snapshot.data;
          if (user == null) return const _AdminLoginPage();
          if (!user.emailVerified) return const _VerifyAdminEmailPage();
          return const AdminPage();
        },
      );
}

class _AdminLoginPage extends StatefulWidget {
  const _AdminLoginPage();

  @override
  State<_AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<_AdminLoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _email.text.trim();
    if (email.isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'กรุณากรอกอีเมลและรหัสผ่าน');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _password.text,
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = 'เข้าสู่ระบบไม่สำเร็จ (${e.code})');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.admin_panel_settings_outlined,
                      size: 56, color: Color(0xFFC7B5FF)),
                  const SizedBox(height: 16),
                  const Text('CONTENTNEX ADMIN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4)),
                  const SizedBox(height: 8),
                  const Text('พื้นที่สำหรับผู้ดูแลระบบเท่านั้น',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF9295A5))),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'อีเมลผู้ดูแล',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'รหัสผ่าน',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    onSubmitted: (_) => _busy ? null : _signIn(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 12)),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _busy ? null : _signIn,
                    child: _busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('เข้าสู่ระบบแอดมิน'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ไม่มีเมนูสมัครสมาชิก บัญชีผู้ดูแลต้องได้รับการสร้างและอนุมัติโดยผู้ดูแลหลักเท่านั้น',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Color(0xFF9295A5), fontSize: 11, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _VerifyAdminEmailPage extends StatelessWidget {
  const _VerifyAdminEmailPage();

  @override
  Widget build(BuildContext context) => _PageMessage(
        title: 'กรุณายืนยันอีเมล',
        detail: 'บัญชีผู้ดูแลต้องยืนยันอีเมลก่อนเข้าใช้งาน',
        action: () => FirebaseAuth.instance.signOut(),
        actionLabel: 'ออกจากระบบ',
      );
}

class _PageMessage extends StatelessWidget {
  final String title;
  final String detail;
  final bool loading;
  final VoidCallback? action;
  final String? actionLabel;

  const _PageMessage({
    required this.title,
    required this.detail,
    this.loading = false,
    this.action,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading)
                  const CircularProgressIndicator()
                else
                  const Icon(Icons.shield_outlined,
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
                        color: Color(0xFF9295A5), height: 1.5)),
                if (action != null) ...[
                  const SizedBox(height: 18),
                  OutlinedButton(
                    onPressed: action,
                    child: Text(actionLabel ?? 'ดำเนินการ'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}
