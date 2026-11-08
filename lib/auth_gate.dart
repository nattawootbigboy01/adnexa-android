import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
const _appId = String.fromEnvironment('FIREBASE_APP_ID');
const _senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');

class AuthGate extends StatefulWidget {
  final Widget child;
  const AuthGate({super.key, required this.child});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<FirebaseApp?> _firebase;

  @override
  void initState() {
    super.initState();
    _firebase = _initializeFirebase();
  }

  Future<FirebaseApp?> _initializeFirebase() async {
    if ([_apiKey, _appId, _senderId, _projectId].any((value) => value.isEmpty)) {
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
  Widget build(BuildContext context) => FutureBuilder<FirebaseApp?>(
        future: _firebase,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _AuthScaffold(
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return _SetupRequired(
              detail: 'เริ่มต้น Firebase ไม่สำเร็จ: ${snapshot.error}',
            );
          }
          if (snapshot.data == null) return const _SetupRequired();

          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.userChanges(),
            builder: (context, authSnapshot) {
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                return const _AuthScaffold(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final user = authSnapshot.data;
              if (user == null) return const EmailAuthPage();
              if (!user.emailVerified) return const VerifyEmailPage();
              return widget.child;
            },
          );
        },
      );
}

class _SetupRequired extends StatelessWidget {
  final String? detail;
  const _SetupRequired({this.detail});

  @override
  Widget build(BuildContext context) => _AuthScaffold(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48, color: Color(0xFFB8A5FF)),
                const SizedBox(height: 16),
                const Text('ตั้งค่าระบบบัญชี ADNEXA',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Text(
                  detail ?? 'ยังไม่ได้กำหนดค่า Firebase สำหรับแอปนี้ กรุณาเพิ่มค่า FIREBASE_API_KEY, FIREBASE_APP_ID, FIREBASE_MESSAGING_SENDER_ID และ FIREBASE_PROJECT_ID ใน GitHub Actions Variables ก่อนสร้าง APK',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF9295A5), height: 1.5),
                ),
              ],
            ),
          ),
        ),
      );
}

class EmailAuthPage extends StatefulWidget {
  const EmailAuthPage({super.key});

  @override
  State<EmailAuthPage> createState() => _EmailAuthPageState();
}

class _EmailAuthPageState extends State<EmailAuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  String? _status;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String _friendlyError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      case 'email-already-in-use':
        return 'อีเมลนี้มีบัญชีอยู่แล้ว';
      case 'weak-password':
        return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
      case 'too-many-requests':
        return 'มีการลองหลายครั้งเกินไป กรุณารอสักครู่';
      case 'network-request-failed':
        return 'เชื่อมต่ออินเทอร์เน็ตไม่ได้';
      default:
        return 'ดำเนินการไม่สำเร็จ (${error.code})';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final email = _email.text.trim();
      if (_register) {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: email,
          password: _password.text,
        );
        String? verificationError;
        try {
          await FirebaseAuth.instance.setLanguageCode('th');
          await credential.user?.sendEmailVerification();
        } on FirebaseAuthException catch (error) {
          verificationError = error.code;
        } catch (error) {
          verificationError = 'ส่งคำขอไม่สำเร็จ: ${error.runtimeType}';
        } finally {
          // A newly-created account must not remain signed in before email verification.
          await FirebaseAuth.instance.signOut();
        }
        if (mounted) {
          setState(() {
            _register = false;
            _status = verificationError == null
                ? 'ลงทะเบียนสำเร็จแล้ว กรุณาตรวจสอบอีเมลเพื่อยืนยันบัญชี จากนั้นเข้าสู่ระบบ'
                : 'ลงทะเบียนสำเร็จแล้ว แต่ส่งอีเมลยืนยันไม่สำเร็จ ($verificationError) กรุณากดลืม/ส่งยืนยันใหม่หรือติดต่อผู้ดูแล';
            _error = null;
          });
        }
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: _password.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() {
        _error = _friendlyError(error);
        _status = null;
      });
    } catch (_) {
      if (mounted) setState(() {
        _error = 'เกิดข้อผิดพลาด กรุณาลองใหม่';
        _status = null;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: _email.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('รีเซ็ตรหัสผ่าน'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'อีเมล'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('ส่งลิงก์'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (email == null || email.isEmpty) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) _message('ส่งลิงก์รีเซ็ตรหัสผ่านแล้ว กรุณาตรวจสอบอีเมล');
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) => _AuthScaffold(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.bolt_rounded,
                        size: 52, color: Color(0xFFB8A5FF)),
                    const SizedBox(height: 12),
                    const Text('ADNEXA',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3)),
                    const SizedBox(height: 6),
                    Text(
                      _register ? 'สร้างบัญชีของคุณ' : 'เข้าสู่ระบบเพื่อเริ่มต้น',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF9295A5)),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'อีเมล',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty || !email.contains('@')) {
                          return 'กรุณากรอกอีเมลให้ถูกต้อง';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      autofillHints: _register
                          ? const [AutofillHints.newPassword]
                          : const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'รหัสผ่าน',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                        ),
                      ),
                      validator: (value) {
                        if ((value ?? '').length < 6) {
                          return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                        }
                        return null;
                      },
                    ),
                    if (!_register)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _busy ? null : _forgotPassword,
                          child: const Text('ลืมรหัสผ่าน?'),
                        ),
                      )
                    else
                      const SizedBox(height: 12),
                    if (_status != null) ...[
                      Text(_status!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Color(0xFF8ED6AE), fontSize: 13, height: 1.5)),
                      const SizedBox(height: 12),
                    ],
                    if (_error != null) ...[
                      Text(_error!,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 12)),
                      const SizedBox(height: 12),
                    ],
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF9270FF),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: _busy
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_register ? 'สมัครสมาชิก' : 'เข้าสู่ระบบ'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _register = !_register;
                                _error = null;
                                _status = null;
                              }),
                      child: Text(_register
                          ? 'มีบัญชีอยู่แล้ว? เข้าสู่ระบบ'
                          : 'ยังไม่มีบัญชี? สมัครสมาชิก'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _busy = false;

  Future<void> _resend() async {
    setState(() => _busy = true);
    try {
      await FirebaseAuth.instance.setLanguageCode('th');
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('ส่งอีเมลยืนยันอีกครั้งแล้ว'),
        ));
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('ส่งอีเมลไม่สำเร็จ (${error.code})'),
        ));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('ส่งอีเมลไม่สำเร็จ (${error.runtimeType})'),
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkVerification() async {
    setState(() => _busy = true);
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user?.emailVerified == true) {
        // authStateChanges will rebuild the gate after the user reloads.
        if (mounted) setState(() {});
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('ยังไม่พบการยืนยัน กรุณากดลิงก์ในอีเมลก่อน'),
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AuthScaffold(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mark_email_unread_outlined,
                    size: 52, color: Color(0xFFB8A5FF)),
                const SizedBox(height: 16),
                const Text('ยืนยันอีเมลของคุณ',
                    style:
                        TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(
                  'เราได้ส่งลิงก์ยืนยันไปที่ ${FirebaseAuth.instance.currentUser?.email ?? ''}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFF9295A5), height: 1.5),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _checkVerification,
                  child: const Text('ฉันยืนยันอีเมลแล้ว'),
                ),
                TextButton(
                  onPressed: _busy ? null : _resend,
                  child: const Text('ส่งอีเมลอีกครั้ง'),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => FirebaseAuth.instance.signOut(),
                  child: const Text('ออกจากระบบ'),
                ),
              ],
            ),
          ),
        ),
      );
}

class _AuthScaffold extends StatelessWidget {
  final Widget child;
  const _AuthScaffold({required this.child});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'ADNEXA',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF08090D),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF9270FF),
            surface: Color(0xFF141620),
          ),
          useMaterial3: true,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF1B1E2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        home: Scaffold(body: SafeArea(child: child)),
      );
}
