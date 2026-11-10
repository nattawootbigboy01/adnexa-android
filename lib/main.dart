import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'meta_api.dart';

void main() => runApp(const AdnexaApp());

const bg = Color(0xFF08090D);
const panel = Color(0xFF141620);
const violet = Color(0xFF368CFF);
const muted = Color(0xFF9295A5);

class AdnexaApp extends StatelessWidget {
  const AdnexaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ADNEXA ADS • ยิงแอดระดับเทพ',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(primary: violet, surface: panel),
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF121A26),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    ),
    home: const AuthGate(child: AppShell()),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
  }

  Future<void> _checkAdminRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final claims = await user?.getIdTokenResult(true);
      final customClaims = claims?.claims ?? const <String, dynamic>{};
      if (!mounted) return;
      setState(() {
        _isAdmin = customClaims['admin'] == true || customClaims['role'] == 'admin';
      });
    } catch (_) {
      // Keep customer-only navigation when claims cannot be verified.
    }
  }

  List<Widget> get _pages => [
    const DashboardPage(),
    const CampaignPage(),
    const AccountsPage(),
    const AiPage(),
    const AnalyticsPage(),
    if (_isAdmin) const AdminPage(),
  ];

  List<String> get _titles => [
    'ภาพรวม', 'แคมเปญ', 'บัญชีโฆษณา', 'Planner', 'Insights',
    if (_isAdmin) 'ศูนย์ผู้ดูแล',
  ];

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    final destinations = <NavigationDestination>[
      const NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'หน้าหลัก'),
      const NavigationDestination(icon: Icon(Icons.campaign_outlined), label: 'แคมเปญ'),
      const NavigationDestination(icon: Icon(Icons.link_rounded), label: 'บัญชี'),
      const NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Planner'),
      const NavigationDestination(icon: Icon(Icons.query_stats), label: 'Insights'),
      if (_isAdmin)
        const NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), label: 'Admin'),
    ];
    if (index >= pages.length) index = 0;

    return Scaffold(
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 14, 10),
          child: Row(children: [
            const BrandMark(size: 42),
            const SizedBox(width: 11),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ADNEXA ADS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.7)),
              Text('ยิงแอดระดับเทพ', style: TextStyle(fontSize: 8, color: muted, letterSpacing: 1.3)),
            ]),
            const Spacer(),
            IconButton(
              tooltip: 'รีเฟรชสิทธิ์ผู้ดูแล',
              onPressed: _checkAdminRole,
              icon: const Icon(Icons.sync_rounded),
            ),
            IconButton(
              tooltip: 'ออกจากระบบ',
              onPressed: () async { await FirebaseAuth.instance.signOut(); },
              icon: const Icon(Icons.logout_rounded),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Expanded(child: Text(_titles[index],
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800))),
            if (_isAdmin && index == pages.length - 1)
              const Chip(avatar: Icon(Icons.verified_user, size: 14), label: Text('ADMIN')),
          ]),
        ),
        const SizedBox(height: 10),
        Expanded(child: IndexedStack(index: index, children: pages)),
      ])),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF10121A),
        indicatorColor: violet.withOpacity(.18),
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: destinations,
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: const Color(0xFF080B10),
      borderRadius: BorderRadius.circular(size * .24),
      border: Border.all(color: const Color(0xFF66758A).withOpacity(.42)),
      boxShadow: [
        BoxShadow(color: const Color(0xFF258BFF).withOpacity(.18), blurRadius: 16, offset: const Offset(0, 4)),
      ],
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Text('A', style: TextStyle(
          fontSize: size * .68, height: 1, fontWeight: FontWeight.w900,
          foreground: Paint()..shader = const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFB8C5D8), Color(0xFF71849D)],
          ).createShader(const Rect.fromLTWH(0, 0, 70, 70)),
        )),
        Positioned(
          right: size * .07, top: size * .12,
          child: Icon(Icons.trending_up_rounded, color: const Color(0xFF258BFF), size: size * .43),
        ),
      ],
    ),
  );
}

void notice(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class PageBody extends StatelessWidget {
  final List<Widget> children;
  const PageBody({super.key, required this.children});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
    children: children,
  );
}

class MetricCard extends StatelessWidget {
  final String label, value, delta;
  final IconData icon;
  const MetricCard({super.key, required this.label, required this.value, required this.delta, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(.055))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: const Color(0xFF78B8FF), size: 20),
      const SizedBox(height: 13),
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: muted, fontSize: 11)),
      const SizedBox(height: 8),
      Text(delta, style: const TextStyle(color: Color(0xFF8DD9B0), fontSize: 10, fontWeight: FontWeight.w600)),
    ]),
  );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  const SectionTitle(this.title, {super.key, this.action});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 11),
    child: Row(children: [
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      const Spacer(),
      if (action != null) Text(action!, style: const TextStyle(color: violet, fontSize: 11)),
    ]),
  );
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _insights;
  List<Map<String, dynamic>> _accounts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final accounts = await MetaApi.adAccounts();
      if (accounts.isEmpty) {
        if (!mounted) return;
        setState(() { _accounts = accounts; _insights = null; });
        return;
      }
      final id = accounts.first['id']?.toString() ?? '';
      if (id.isEmpty) throw Exception('ไม่พบรหัสบัญชีโฆษณา');
      final response = await MetaApi.insights(id, datePreset: 'last_7d');
      if (!mounted) return;
      final value = response['insights'];
      setState(() {
        _accounts = accounts;
        _insights = value is Map ? Map<String, dynamic>.from(value) : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _value(dynamic value, {int decimals = 0}) {
    final number = num.tryParse(value?.toString() ?? '');
    if (number == null) return '—';
    return decimals == 0 ? number.round().toString() : number.toStringAsFixed(decimals);
  }

  Widget _metric(String label, String value, IconData icon) => MetricCard(
    label: label, value: value, delta: 'ข้อมูล Meta • 7 วันล่าสุด', icon: icon,
  );

  @override
  Widget build(BuildContext context) {
    final currency = _insights?['account_currency']?.toString() ?? '';
    return PageBody(children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF14263D), Color(0xFF171925), Color(0xFF11131B)],
          ),
          border: Border.all(color: violet.withOpacity(.22)),
        ),
        child: Row(children: [
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('โฆษณาของคุณ ในมุมมองเดียว',
                style: TextStyle(fontSize: 19, height: 1.25, fontWeight: FontWeight.w800)),
              SizedBox(height: 7),
              Text('ติดตามประสิทธิภาพจากบัญชี Meta ที่เชื่อมต่อจริง',
                style: TextStyle(color: Color(0xFFC5BEDA), fontSize: 11, height: 1.5)),
            ],
          )),
          const SizedBox(width: 10),
          const BrandMark(size: 54),
        ]),
      ),
      SectionTitle('ภาพรวมผลลัพธ์', action: _loading ? 'กำลังโหลด' : '7 วันล่าสุด'),
      if (_loading) const LinearProgressIndicator(minHeight: 2),
      if (_error != null) CardPanel(child: Text(_error!, style: const TextStyle(color: Color(0xFFFFA0A0), fontSize: 12))),
      if (!_loading && _error == null && _accounts.isEmpty)
        CardPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.link_off_rounded, color: muted, size: 26),
          const SizedBox(height: 9),
          const Text('ยังไม่มีบัญชีโฆษณาที่เชื่อมต่อ', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          const Text('เชื่อมต่อ Meta เพื่อเริ่มอ่านผลโฆษณาจริง', style: TextStyle(color: muted, fontSize: 11)),
        ])),
      if (_insights != null) ...[
        Text(_insights?['account_name']?.toString() ?? 'บัญชีโฆษณาที่เลือก',
          style: const TextStyle(color: muted, fontSize: 11)),
        const SizedBox(height: 9),
        Row(children: [
          Expanded(child: _metric('ยอดใช้จ่าย', '${_value(_insights?['spend'], decimals: 2)} $currency', Icons.payments_outlined)),
          const SizedBox(width: 9),
          Expanded(child: _metric('การเข้าถึง', _value(_insights?['reach']), Icons.groups_outlined)),
        ]),
        const SizedBox(height: 9),
        Row(children: [
          Expanded(child: _metric('การแสดงผล', _value(_insights?['impressions']), Icons.visibility_outlined)),
          const SizedBox(width: 9),
          Expanded(child: _metric('คลิก', _value(_insights?['clicks']), Icons.ads_click)),
        ]),
        const SizedBox(height: 9),
        Row(children: [
          Expanded(child: _metric('CTR', '${_value(_insights?['ctr'], decimals: 2)}%', Icons.trending_up)),
          const SizedBox(width: 9),
          Expanded(child: _metric('ความถี่', _value(_insights?['frequency'], decimals: 2), Icons.repeat)),
        ]),
      ],
      if (_insights == null && !_loading && _accounts.isNotEmpty && _error == null)
        const CardPanel(child: Text('Meta ยังไม่มีข้อมูล Insights สำหรับช่วงเวลานี้ หรือสิทธิ์ ads_read ยังไม่พร้อม',
          style: TextStyle(color: muted, fontSize: 12))),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: _loading ? null : _load,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('รีเฟรชข้อมูล'),
      ),
      const SectionTitle('แพลตฟอร์มที่รองรับ'),
      PlatformTile(name: 'Meta Ads', subtitle: 'Facebook และ Instagram', icon: Icons.facebook,
        status: _accounts.isNotEmpty ? 'เชื่อมต่อแล้ว' : 'ยังไม่เชื่อมต่อ'),
      const PlatformTile(name: 'TikTok Ads', subtitle: 'TikTok for Business', icon: Icons.music_note, status: 'รอพัฒนา'),
      const SizedBox(height: 8),
      const Text('ตัวเลขจะแสดงเมื่อ API ส่งข้อมูลจริงเท่านั้น ไม่มีการเติมตัวเลขตัวอย่าง',
        style: TextStyle(color: muted, fontSize: 10, height: 1.5)),
    ]);
  }
}

class QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const QuickChip({super.key, required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(.06))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 15, color: violet), const SizedBox(width: 7), Text(label, style: const TextStyle(fontSize: 11))]),
  );
}

class PlatformTile extends StatelessWidget {
  final String name, subtitle, status;
  final IconData icon;
  const PlatformTile({super.key, required this.name, required this.subtitle, required this.icon, required this.status});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(.05))),
    child: Row(children: [
      Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFF14263D), borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: const Color(0xFF78B8FF))),
      const SizedBox(width: 11),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), Text(subtitle, style: const TextStyle(color: muted, fontSize: 10))])),
      Text(status, style: const TextStyle(color: muted, fontSize: 10)),
    ]),
  );
}

class CampaignPage extends StatefulWidget {
  const CampaignPage({super.key});
  @override
  State<CampaignPage> createState() => _CampaignPageState();
}

class _CampaignPageState extends State<CampaignPage> {
  final name = TextEditingController();
  final budget = TextEditingController(text: '300');
  String platform = 'Meta Ads';
  String objective = 'Traffic';
  String campaignMode = 'Offline';
  RangeValues ageRange = const RangeValues(18, 60);
  String? aiAgeSuggestion;
  String manualGender = 'ทุกเพศ';
  int durationDays = 7;
  final productInfo = TextEditingController();
  final manualAudience = TextEditingController();
  final manualInterests = TextEditingController();
  String? aiPlan;
  final drafts = <String>[];
  bool draftsLoading = true;

  static const Map<String, String> objectiveLabels = {
    'Reach': 'เพิ่มการเข้าถึง',
    'Awareness': 'สร้างการรับรู้แบรนด์',
    'Traffic': 'เพิ่มจำนวนผู้เข้าชม',
    'Engagement': 'เพิ่มการมีส่วนร่วม',
    'Leads': 'หาลูกค้าเป้าหมาย',
    'Sales': 'เพิ่มยอดขาย',
  };

  static const Map<String, String> objectiveDescriptions = {
    'Reach': 'เน้นให้โฆษณาเข้าถึงผู้คนให้ได้มากที่สุด',
    'Awareness': 'ทำให้ผู้คนรู้จักแบรนด์ สินค้า หรือบริการ',
    'Traffic': 'พาคนไปยังเว็บไซต์ เพจ หรือปลายทางที่กำหนด',
    'Engagement': 'กระตุ้นการกดถูกใจ แสดงความคิดเห็น แชร์ หรือมีปฏิสัมพันธ์',
    'Leads': 'หาผู้สนใจและกระตุ้นให้ติดต่อหรือส่งข้อมูล',
    'Sales': 'มุ่งกระตุ้นการสั่งซื้อหรือยอดขาย',
  };

  String get objectiveDescription =>
      objectiveDescriptions[objective] ?? 'เลือกวัตถุประสงค์ให้ตรงกับผลลัพธ์ที่ต้องการ';


  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('campaign_drafts') ?? <String>[];
    if (!mounted) return;
    setState(() {
      drafts
        ..clear()
        ..addAll(saved);
      draftsLoading = false;
    });
  }

  Future<void> _saveDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('campaign_drafts', drafts);
  }

  void _makeAiPlan() {
    final item = productInfo.text.trim();
    if (item.isEmpty) { notice(context, 'กรุณาระบุสินค้า/บริการก่อน'); return; }
    final lower = item.toLowerCase();
    String audience;
    String creative;
    if (lower.contains('อาหาร') || lower.contains('กาแฟ') || lower.contains('ขนม') || lower.contains('food')) {
      audience = 'ผู้ที่สนใจอาหาร คาเฟ่ ร้านใกล้บ้าน และเดลิเวอรี';
      creative = 'วิดีโอเมนูหรือสินค้า 10–20 วินาที พร้อมราคาและจุดเด่น';
    } else if (lower.contains('เสื้อ') || lower.contains('แฟชั่น') || lower.contains('fashion')) {
      audience = 'ผู้ที่สนใจแฟชั่น เสื้อผ้า การแต่งตัว และช้อปปิ้ง';
      creative = 'ภาพสินค้าหลายมุม วิดีโอสาธิต และรายละเอียดไซซ์/ราคา';
    } else if (lower.contains('รถ') || lower.contains('ซ่อม') || lower.contains('motor')) {
      audience = 'เจ้าของรถและผู้สนใจดูแลหรือซ่อมบำรุงยานพาหนะ';
      creative = 'ภาพผลงานจริง ขั้นตอนบริการ ราคา และรีวิวที่ตรวจสอบได้';
    } else {
      audience = 'ผู้ที่สนใจสินค้า/บริการประเภทนี้และลูกค้าในพื้นที่ให้บริการ';
      creative = 'ภาพหรือวิดีโอแสดงประโยชน์ จุดเด่น ราคา และหลักฐานความน่าเชื่อถือ';
    }
    final suggestedAge = (lower.contains('เด็ก') || lower.contains('ของเล่น') || lower.contains('baby')) ? '25–44 ปี (ผู้ใหญ่/ผู้ปกครอง)' : (lower.contains('ผู้สูงอายุ') || lower.contains('สุขภาพวัยเกษียณ')) ? '45–60 ปี' : (lower.contains('วัยรุ่น') || lower.contains('นักศึกษา')) ? '18–25 ปี' : '18–44 ปี';
    setState(() {
      aiAgeSuggestion = suggestedAge;
      aiPlan = 'กลุ่มเป้าหมายแนะนำ: ' + audience + '\nพื้นที่เป้าหมาย: ประเทศไทยทั้งประเทศ\nช่วงอายุที่ AI แนะนำ: ' + suggestedAge + '\nชิ้นงานแนะนำ: ' + creative + '\nเป้าหมาย: ' + (objectiveLabels[objective] ?? objective) + '\n\nคำแนะนำนี้มาจากตัวช่วยภายในแอปแบบออฟไลน์ ยังไม่ใช่ AI ออนไลน์ ต้องตรวจทานก่อนใช้';
    });
  }


  void _showPublishReview() {
    if (name.text.trim().isEmpty || amount == null || amount <= 0) {
      notice(context, 'กรุณากรอกชื่อแคมเปญและงบประมาณให้ถูกต้อง');
      return;
    }
    if (campaignMode == 'Offline' && aiPlan == null) {
      notice(context, 'กรุณาให้ตัวช่วยวิเคราะห์แผนก่อนตรวจสอบ');
      return;
    }
    if (campaignMode == 'Manual' && manualAudience.text.trim().isEmpty) {
      notice(context, 'กรุณาระบุกลุ่มลูกค้าในโหมดทำเอง');
      return;
    }
    final startAge = ageRange.start.round();
    final endAge = ageRange.end.round();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ตรวจสอบแคมเปญก่อนเผยแพร่'),
        content: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('แพลตฟอร์ม: $platform'),
            Text('วัตถุประสงค์: ${objectiveLabels[objective] ?? objective}'),
            Text('ช่วงอายุ: $startAge–$endAge ปี'),
            Text('งบประมาณ: ฿${amount.toStringAsFixed(0)} ต่อวัน'),
            Text('ระยะเวลา: $durationDays วัน'),
            Text('งบรวม: ฿${(amount * durationDays).toStringAsFixed(0)}'),
            const Divider(height: 24),
            const Text('สถานะ: ยังไม่พร้อมเผยแพร่จริง', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFFFC078))),
            const SizedBox(height: 6),
            const Text('ต้องเชื่อมบัญชีโฆษณาผ่าน OAuth ทางการและตั้งค่า API ฝั่งเซิร์ฟเวอร์ก่อน ปัจจุบันบัญชีแพลตฟอร์มยังไม่เชื่อมต่อ จึงยังไม่มีการส่งโฆษณาหรือใช้เงินจริง', style: TextStyle(fontSize: 12, height: 1.45)),
          ],
        )),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('กลับไปแก้ไข')),
          FilledButton(onPressed: null, child: const Text('รอเชื่อมต่อบัญชี')),
        ],
      ),
    );
  }

  @override
  void dispose() { name.dispose(); budget.dispose(); productInfo.dispose(); manualAudience.dispose(); manualInterests.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => PageBody(children: [
    const Text('เลือกวิธีจัดการแคมเปญ', style: TextStyle(color: muted, fontSize: 12)),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: _ModeCard(selected: campaignMode == 'AI', icon: Icons.auto_awesome, title: 'ตัวช่วยวางแผน', subtitle: 'คำแนะนำออฟไลน์', onTap: () => setState(() { campaignMode = 'AI'; aiPlan = null; aiAgeSuggestion = null; }))),
      const SizedBox(width: 10),
      Expanded(child: _ModeCard(selected: campaignMode == 'Manual', icon: Icons.tune_rounded, title: 'ทำเองทั้งหมด', subtitle: 'กำหนดเองทุกอย่าง', onTap: () => setState(() { campaignMode = 'Manual'; aiPlan = null; aiAgeSuggestion = null; }))),
    ]),
    const SizedBox(height: 10),
    CardPanel(child: Text(campaignMode == 'Offline' ? 'โหมดตัวช่วย: ระบุสินค้า/บริการ แล้วให้ระบบเสนอแนวทาง โดยกำหนดพื้นที่โฆษณาเป็นประเทศไทยทั้งประเทศ' : 'โหมดทำเอง: คุณกำหนดกลุ่มลูกค้า อายุ เพศ และความสนใจได้เอง โดยพื้นที่โฆษณาล็อกไว้ในประเทศไทยทั้งประเทศ', style: const TextStyle(fontSize: 11, color: muted, height: 1.5))),
    const SizedBox(height: 6),
    const Text('Platform', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    const SizedBox(height: 7),
    DropdownButtonFormField<String>(value: platform, items: ['Meta Ads', 'TikTok Ads'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => platform = v!)),
    const SizedBox(height: 15),
    const Text('Campaign name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    const SizedBox(height: 7),
    TextField(controller: name, decoration: const InputDecoration(hintText: 'ใส่ชื่อสินค้าที่ต้องการโฆษณา')),
    const SizedBox(height: 15),
    const Text('วัตถุประสงค์การโฆษณา', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    const SizedBox(height: 7),
    DropdownButtonFormField<String>(
      value: objective,
      items: objectiveLabels.entries.map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value))).toList(),
      onChanged: (v) => setState(() => objective = v ?? objective),
    ),
    Padding(padding: const EdgeInsets.only(top: 7), child: Text(objectiveDescription, style: const TextStyle(color: muted, fontSize: 11, height: 1.4))),
    const SizedBox(height: 15),
    if (campaignMode == 'Offline') ...[
      const SectionTitle('สินค้า/บริการที่ต้องการโปรโมต'),
      TextField(controller: productInfo, maxLines: 2, decoration: const InputDecoration(hintText: 'เช่น ร้านกาแฟเดลิเวอรี ราคาเริ่มต้น 45 บาท')),
      CardPanel(child: const Row(children: [Icon(Icons.location_on_outlined, color: violet, size: 18), SizedBox(width: 8), Expanded(child: Text('พื้นที่โฆษณา: ประเทศไทยทั้งประเทศ (กำหนดให้อัตโนมัติ)', style: TextStyle(fontSize: 11, color: muted)))])),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _makeAiPlan, icon: const Icon(Icons.auto_awesome), label: const Text('สร้างคำแนะนำเบื้องต้น'))),
      if (aiPlan != null) CardPanel(child: SelectableText(aiPlan!, style: const TextStyle(fontSize: 12, height: 1.6))),
    ] else ...[
      CardPanel(child: const Row(children: [Icon(Icons.location_on_outlined, color: violet, size: 18), SizedBox(width: 8), Expanded(child: Text('พื้นที่โฆษณา: ประเทศไทยทั้งประเทศ (ไม่ต้องเลือกจังหวัด)', style: TextStyle(fontSize: 11, color: muted)))])),
      const SectionTitle('กลุ่มลูกค้า'),
      TextField(controller: manualAudience, maxLines: 2, decoration: const InputDecoration(hintText: 'เช่น เจ้าของธุรกิจ / คนทำงาน')),
      const SectionTitle('เพศ'),
      DropdownButtonFormField<String>(value: manualGender, items: ['ทุกเพศ', 'ชาย', 'หญิง'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => manualGender = v ?? manualGender)),
      const SectionTitle('ความสนใจ (ถ้ามี)'),
      TextField(controller: manualInterests, maxLines: 2, decoration: const InputDecoration(hintText: 'เช่น กาแฟ ร้านอาหาร ธุรกิจออนไลน์')),
    ],
    const SectionTitle('ช่วงอายุเป้าหมาย'),
    const Text('เลือกกลุ่มผู้ชมได้ตั้งแต่อายุ 18–60 ปี ปรับช่วงอายุได้เองทั้งโหมด AI และโหมดทำเอง', style: TextStyle(color: muted, fontSize: 10)),
    const SizedBox(height: 7),
    CardPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('อายุเริ่มต้น', style: TextStyle(color: muted, fontSize: 10)),
          Text('${ageRange.start.round()} ปี', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF8CC7FF))),
        ])),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Text('อายุสิ้นสุด', style: TextStyle(color: muted, fontSize: 10)),
          Text('${ageRange.end.round()} ปี', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF8CC7FF))),
        ])),
      ]),
      RangeSlider(
        values: ageRange,
        min: 18,
        max: 60,
        divisions: 42,
        labels: RangeLabels('${ageRange.start.round()} ปี', '${ageRange.end.round()} ปี'),
        onChanged: (values) => setState(() => ageRange = values),
      ),
      const Text('เลื่อนจุดทั้งสองด้านเพื่อกำหนดช่วงอายุ ระบบจะไม่อนุญาตให้อายุต่ำกว่า 18 ปีหรือเกิน 60 ปี', style: TextStyle(color: muted, fontSize: 10, height: 1.4)),
    ])),
    if (campaignMode == 'AI' && aiAgeSuggestion != null) ...[
      const SizedBox(height: 8),
      CardPanel(child: Row(children: [
        const Expanded(child: Text('คำแนะนำช่วงอายุจากตัวช่วย', style: TextStyle(fontSize: 11, color: muted))),
        Text(aiAgeSuggestion!, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF8CC7FF))),
        const SizedBox(width: 8),
        TextButton(onPressed: () {
          final match = RegExp(r'(\d+)\s*[–-]\s*(\d+)').firstMatch(aiAgeSuggestion!);
          if (match == null) return;
          final suggestedStart = int.parse(match.group(1)!);
          final suggestedEnd = int.parse(match.group(2)!);
          setState(() => ageRange = RangeValues(suggestedStart.toDouble(), suggestedEnd.toDouble()));
        }, child: const Text('ใช้ค่านี้')),
      ])),
    ],
    const Text('งบประมาณต่อวัน (บาท)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    const SizedBox(height: 7),
    TextField(controller: budget, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}), decoration: const InputDecoration(prefixText: '฿  ', hintText: '300')),
    const SizedBox(height: 12),
    const Text('ระยะเวลาโฆษณา', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    const SizedBox(height: 7),
    DropdownButtonFormField<int>(
      value: durationDays,
      items: const [1, 3, 7, 14, 30].map((days) => DropdownMenuItem(value: days, child: Text('$days วัน'))).toList(),
      onChanged: (value) => setState(() => durationDays = value ?? durationDays),
    ),
    const SizedBox(height: 12),
    CardPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('ผลลัพธ์จากแพลตฟอร์ม', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      const SizedBox(height: 7),
      const Text('ยังไม่มีข้อมูลจริง', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: muted)),
      const SizedBox(height: 5),
      Text('งบรวม: ฿${((double.tryParse(budget.text.trim()) ?? 0) * durationDays).toStringAsFixed(0)} ตลอด $durationDays วัน', style: const TextStyle(fontSize: 11, color: muted)),
      const SizedBox(height: 6),
      const Text('เชื่อมบัญชี Meta และเปิดหน้า Insights เพื่อดูตัวเลขจริง ระบบจะไม่สร้างตัวเลขคาดการณ์แทนข้อมูลจากแพลตฟอร์ม', style: TextStyle(fontSize: 10, color: muted, height: 1.45)),
    ])),
    const SizedBox(height: 18),
    SizedBox(width: double.infinity, child: OutlinedButton.icon(
      onPressed: _showPublishReview,
      icon: const Icon(Icons.fact_check_outlined),
      label: const Text('ตรวจสอบก่อนเผยแพร่'),
    )),
    const SizedBox(height: 9),
    SizedBox(width: double.infinity, child: FilledButton.icon(
      onPressed: () {
        final amount = double.tryParse(budget.text);
        if (name.text.trim().isEmpty || amount == null || amount <= 0) {
          notice(context, 'กรุณากรอกชื่อแคมเปญและงบประมาณให้ถูกต้อง');
          return;
        }
        final startAge = ageRange.start.round();
        final endAge = ageRange.end.round();
        if (startAge < 18 || endAge > 60 || startAge > endAge) { notice(context, 'กรุณากำหนดช่วงอายุ 18–60 ปีให้ถูกต้อง'); return; }
        if (campaignMode == 'AI' && aiPlan == null) { notice(context, 'กรุณาให้ตัวช่วยวิเคราะห์แผนก่อนบันทึก'); return; }
        if (campaignMode == 'Manual' && manualAudience.text.trim().isEmpty) { notice(context, 'กรุณาระบุกลุ่มลูกค้าในโหมดทำเอง'); return; }
        final targeting = campaignMode == 'AI' ? 'OFFLINE PLAN: ' + (aiPlan ?? '') + ', อายุ ' + startAge.toString() + '–' + endAge.toString() + ' ปี' : 'MANUAL: พื้นที่ประเทศไทย, กลุ่ม ' + manualAudience.text.trim() + ', อายุ ' + startAge.toString() + '–' + endAge.toString() + ' ปี, เพศ ' + manualGender + ', ความสนใจ ' + manualInterests.text.trim();
        setState(() => drafts.insert(0, '${name.text.trim()} • $platform • ${objectiveLabels[objective] ?? objective} • ฿${amount.toStringAsFixed(0)}/day • $durationDays วัน • พื้นที่ประเทศไทย • MODE: $campaignMode • $targeting'));
        _saveDrafts();
        name.clear();
        notice(context, 'บันทึก Draft ลงในเครื่องแล้ว (ยังไม่ส่งโฆษณาจริง)');
      },
      icon: const Icon(Icons.save_outlined), label: const Text('Save draft'),
      style: FilledButton.styleFrom(backgroundColor: violet, padding: const EdgeInsets.symmetric(vertical: 14)),
    )),
    const Text('หมายเหตุ: โหมด AI ในเวอร์ชันนี้เป็นตัวช่วยวางแผนภายในแอปแบบออฟไลน์ ยังไม่ได้เชื่อม AI ออนไลน์หรือ API ยิงโฆษณา ทั้งสองโหมดบันทึกเป็น Draft เท่านั้น ไม่มีการเผยแพร่โฆษณาจริง', style: TextStyle(color: muted, fontSize: 10, height: 1.5)),
    const SectionTitle('Saved drafts'),
    if (draftsLoading) const EmptyState(text: 'กำลังโหลดแคมเปญที่บันทึกไว้...'),
    if (!draftsLoading && drafts.isEmpty) const EmptyState(text: 'ยังไม่มีแคมเปญฉบับร่าง'),
    ...drafts.map((d) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(13)), child: Text(d, style: const TextStyle(fontSize: 12)))),
  ]);
}

class _ModeCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _ModeCard({required this.selected, required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: selected ? const Color(0xFF14263D) : panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? violet : Colors.white.withOpacity(.07), width: selected ? 1.5 : 1)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: selected ? const Color(0xFF8CC7FF) : muted, size: 22), const SizedBox(height: 9), Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: selected ? Colors.white : muted)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 10, color: muted)), const SizedBox(height: 7), Text(selected ? 'SELECTED' : 'เลือกโหมดนี้', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: selected ? const Color(0xFF8CC7FF) : muted))]),
    ),
  );
}

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage>
    with WidgetsBindingObserver {
  bool _loading = false;
  bool _connecting = false;
  bool _connected = false;
  String? _accountName;
  String? _error;
  List<Map<String, dynamic>> _adAccounts = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_loading && !_connecting) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = await MetaApi.connection();
      final connected = status['connected'] == true;
      List<Map<String, dynamic>> accounts = const [];
      if (connected) {
        accounts = await MetaApi.adAccounts();
      }
      if (!mounted) return;
      setState(() {
        _connected = connected;
        final account = status['account'];
        _accountName = account is Map
            ? account['name']?.toString()
            : null;
        _adAccounts = accounts;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _connect() async {
    setState(() {
      _connecting = true;
      _error = null;
    });
    try {
      final authorizationUrl = await MetaApi.startConnection();
      final opened = await launchUrl(
        authorizationUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!opened) throw Exception('ไม่สามารถเปิดหน้าเข้าสู่ระบบ Meta ได้');
      if (mounted) {
        notice(context, 'เปิดหน้า Meta แล้ว กรุณาอนุญาตและกลับมาแอป ADNEXA');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยกเลิกการเชื่อมต่อ Meta?'),
        content: const Text('ADNEXA จะลบ Token ที่จัดเก็บไว้ในระบบของแอป'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await MetaApi.disconnect();
      if (!mounted) return;
      setState(() {
        _connected = false;
        _accountName = null;
        _adAccounts = const [];
      });
      notice(context, 'ลบการเชื่อมต่อ Meta จาก ADNEXA แล้ว');
    } catch (error) {
      if (mounted) {
        notice(context, error.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) => PageBody(children: [
    const Text(
      'Connect your advertising accounts securely.',
      style: TextStyle(color: muted, fontSize: 12),
    ),
    const SizedBox(height: 14),
    CardPanel(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.facebook, size: 22),
          const SizedBox(width: 9),
          const Expanded(child: Text(
            'Meta Ads',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          )),
          if (_connected)
            const Icon(Icons.check_circle, color: Color(0xFF65C995), size: 19),
        ]),
        const SizedBox(height: 4),
        const Text(
          'Facebook & Instagram advertising accounts',
          style: TextStyle(color: muted, fontSize: 11),
        ),
        const SizedBox(height: 13),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        if (_connected) ...[
          Row(children: [
            const Icon(Icons.link, color: Color(0xFF65C995), size: 16),
            const SizedBox(width: 6),
            Expanded(child: Text(
              _accountName ?? 'Meta account connected',
              style: const TextStyle(color: Color(0xFF65C995), fontSize: 11),
            )),
          ]),
          const SizedBox(height: 10),
          if (_adAccounts.isEmpty)
            const Text(
              'ยังไม่พบ Ad Account หรือบัญชีนี้ยังไม่มีสิทธิ์อ่านรายการบัญชีโฆษณา',
              style: TextStyle(color: muted, fontSize: 11),
            ),
          ..._adAccounts.map((account) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(children: [
              const Icon(Icons.campaign_outlined, color: muted, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(
                account['name']?.toString() ?? account['id'].toString(),
                style: const TextStyle(fontSize: 12),
              )),
              Text(
                account['currency']?.toString() ?? '',
                style: const TextStyle(color: muted, fontSize: 10),
              ),
            ]),
          )),
          const SizedBox(height: 12),
          Row(children: [
            OutlinedButton.icon(
              onPressed: _loading ? null : _refresh,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _disconnect,
              child: const Text('Disconnect'),
            ),
          ]),
        ] else ...[
          const Row(children: [
            Icon(Icons.link_off, color: muted, size: 16),
            SizedBox(width: 6),
            Expanded(child: Text(
              'Not connected',
              style: TextStyle(color: muted, fontSize: 11),
            )),
          ]),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _connecting || _loading ? null : _connect,
            child: Text(_connecting ? 'Opening Meta…' : 'Connect Meta'),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: const TextStyle(color: Color(0xFFFF8D8D), fontSize: 11),
          ),
        ],
      ],
    )),
    const SizedBox(height: 12),
    CardPanel(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('TikTok Ads', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        SizedBox(height: 4),
        Text('TikTok for Business advertiser accounts', style: TextStyle(color: muted, fontSize: 11)),
        SizedBox(height: 10),
        Text('ยังไม่เปิดการเชื่อมต่อจริง — อยู่ในคิวพัฒนาขั้นถัดไป', style: TextStyle(color: muted, fontSize: 11)),
      ],
    )),
    const SizedBox(height: 6),
    const Text('Security principle', style: TextStyle(fontWeight: FontWeight.w700)),
    const SizedBox(height: 7),
    const Text(
      'ADNEXA จะไม่ขอหรือเก็บรหัสผ่านบัญชีโฆษณาของคุณ การเชื่อมต่อใช้ OAuth ทางการ และ Token จะถูกเก็บแบบเข้ารหัสบนเซิร์ฟเวอร์เท่านั้น',
      style: TextStyle(color: muted, fontSize: 12, height: 1.5),
    ),
  ]);
}

class AiPage extends StatefulWidget {
  const AiPage({super.key});
  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final product = TextEditingController();
  final audience = TextEditingController();
  String tone = 'เป็นกันเอง';
  String? output;
  String? audiencePlan;

  @override
  void dispose() {
    product.dispose();
    audience.dispose();
    super.dispose();
  }

  void analyze() {
    final item = product.text.trim();
    final amount = double.tryParse(budget.text.trim());
    if (item.isEmpty) {
      notice(context, 'กรุณาระบุสินค้าหรือบริการก่อน');
      return;
    }

    final description = audience.text.trim();
    final lower = item.toLowerCase();
    String segment;
    if (lower.contains('อาหาร') || lower.contains('กาแฟ') || lower.contains('ขนม') || lower.contains('food')) {
      segment = 'คนในพื้นที่ที่สนใจอาหาร คาเฟ่ ร้านใกล้บ้าน และรีวิวร้าน';
    } else if (lower.contains('เสื้อ') || lower.contains('แฟชั่น') || lower.contains('fashion')) {
      segment = 'ผู้ที่สนใจแฟชั่น เสื้อผ้า การแต่งตัว และช้อปปิ้งออนไลน์';
    } else if (lower.contains('รถ') || lower.contains('ซ่อม') || lower.contains('motor')) {
      segment = 'เจ้าของรถและผู้ที่สนใจบริการดูแลหรือซ่อมบำรุงยานพาหนะ';
    } else if (lower.contains('เรียน') || lower.contains('คอร์ส') || lower.contains('สอน')) {
      segment = 'ผู้ที่สนใจพัฒนาทักษะ การเรียนรู้ และคอร์สเฉพาะทาง';
    } else {
      segment = 'ผู้ที่มีความสนใจเกี่ยวข้องกับสินค้า/บริการ และกลุ่มลูกค้าในพื้นที่ให้บริการ';
    }

    String strategy;
    String creative;
    String offer;
    if (segment.contains('อาหาร')) {
      strategy = 'เน้นความสะดวก ความน่ากิน ราคา และความเร็วในการจัดส่ง ทดลองยิงโฆษณาในพื้นที่ให้บริการก่อน';
      creative = 'ทำคลิปเมนูขายดี 10–20 วินาที พร้อมราคาและภาพสินค้าจริง';
      offer = 'ทดลองชุดเมนูแนะนำหรือชุดคุ้มค่า โดยคำนวณต้นทุนก่อนให้ส่วนลด';
    } else if (segment.contains('แฟชั่น')) {
      strategy = 'เน้นดีไซน์ ราคา ไซซ์ และความมั่นใจในคุณภาพ';
      creative = 'ใช้ภาพหลายมุม วิดีโอขณะสวมใส่ และตารางไซซ์';
      offer = 'ทดลองจัดเซตสินค้า หรือส่งฟรีเมื่อถึงยอดขั้นต่ำ';
    } else if (segment.contains('รถ')) {
      strategy = 'เน้นความน่าเชื่อถือ ราคาโปร่งใส ความชำนาญ และการรับประกันงาน';
      creative = 'ใช้ภาพก่อน–หลัง ขั้นตอนทำงานจริง และรีวิวที่ตรวจสอบได้';
      offer = 'ทำแพ็กเกจตรวจเช็กหรือบริการพื้นฐาน พร้อมระบุเงื่อนไขชัดเจน';
    } else if (segment.contains('เรียน')) {
      strategy = 'เน้นผลลัพธ์การเรียนรู้ ความน่าเชื่อถือของผู้สอน และตารางเรียน';
      creative = 'ทำคลิปสอนสั้น ตัวอย่างบทเรียน และรีวิวผู้เรียนจริง';
      offer = 'ให้ทดลองเรียนหรือประเมินพื้นฐานก่อนสมัคร';
    } else {
      strategy = 'สื่อสารปัญหาของลูกค้า ประโยชน์ที่ได้รับ ความแตกต่าง และหลักฐานความน่าเชื่อถือ';
      creative = 'ทำวิดีโอสาธิต ภาพจุดเด่น รีวิวจริง และโพสต์ตอบคำถามที่พบบ่อย';
      offer = 'ทดลองข้อเสนอเริ่มต้นหรือแพ็กเกจที่ตรวจสอบกำไรแล้ว';
    }
    final objectiveAdvice = 'เป้าหมายแคมเปญ: เพิ่มการรับรู้ให้วัดการเข้าถึงและความถี่; เพิ่มผู้สนใจให้วัดจำนวน Lead และต้นทุนต่อ Lead; เพิ่มยอดขายให้วัดคำสั่งซื้อและกำไรหลังหักต้นทุน';
    final customAudience = description.isEmpty ? 'ยังไม่ได้ระบุกลุ่มลูกค้าเฉพาะ' : description;

    setState(() {
      audiencePlan = 'กลุ่มเป้าหมายตั้งต้น: $segment\nกลุ่มลูกค้าที่คุณระบุ: $customAudience\n\nกลยุทธ์ตามประเภทธุรกิจ: $strategy\nรูปแบบสื่อที่แนะนำ: $creative\nข้อเสนอที่ควรทดลอง: $offer\n\n$objectiveAdvice\nแนวทาง: เริ่มทดสอบในพื้นที่ให้บริการและปรับกลุ่มตามผลตอบรับจริง';
      output = 'พบกับ $item ที่ออกแบบมาเพื่อตอบโจทย์คุณ เลือกสิ่งที่ใช่และติดต่อเราได้วันนี้!\nโทนข้อความ: $tone';
    });
  }

  @override
  Widget build(BuildContext context) => PageBody(children: [
    Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: [Color(0xFF14263D), Color(0xFF11141C)]),
      ),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.auto_awesome, color: Color(0xFF8CC7FF), size: 25),
        SizedBox(height: 10),
        Text('ADNEXA ADS Planner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        SizedBox(height: 5),
        Text('เครื่องมือช่วยวางแผนเบื้องต้น • ยังไม่เชื่อม AI ออนไลน์', style: TextStyle(color: Color(0xFFC5BEDA), fontSize: 11)),
      ]),
    ),
    const SectionTitle('1. สินค้าหรือบริการ'),
    TextField(controller: product, maxLines: 2, decoration: const InputDecoration(hintText: 'เช่น ร้านกาแฟเดลิเวอรี / บริการล้างแอร์')),
    const SectionTitle('2. ลูกค้าที่ต้องการเข้าถึง'),
    TextField(controller: audience, maxLines: 2, decoration: const InputDecoration(hintText: 'เช่น คนทำงานอายุ 25–40 ปี ในขอนแก่น (ไม่บังคับ)')),
    const SectionTitle('4. โทนข้อความโฆษณา'),
    DropdownButtonFormField<String>(
      value: tone,
      items: ['เป็นกันเอง', 'มืออาชีพ', 'พรีเมียม', 'เร่งให้ตัดสินใจ'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
      onChanged: (v) => setState(() => tone = v ?? tone),
    ),
    const SizedBox(height: 16),
    SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: analyze,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('วิเคราะห์และวางแผนโฆษณา'),
        style: FilledButton.styleFrom(backgroundColor: violet, padding: const EdgeInsets.symmetric(vertical: 14)),
      ),
    ),
    if (audiencePlan != null) ...[
      const SectionTitle('ผลวิเคราะห์กลุ่มเป้าหมาย'),
      CardPanel(child: SelectableText(audiencePlan!, style: const TextStyle(fontSize: 13, height: 1.6))),
      const SectionTitle('ข้อความโฆษณาตัวอย่าง'),
      CardPanel(child: SelectableText(output!, style: const TextStyle(fontSize: 13, height: 1.6))),
    ],
    const Text(
      'สถานะ: ตัวช่วยนี้ทำงานด้วยกฎออฟไลน์ ไม่ใช่ AI ออนไลน์ ไม่ได้ดึงข้อมูลจาก Meta และไม่ส่งคำสั่งสร้างหรือเผยแพร่แคมเปญ ตัวเลขผลลัพธ์จริงจะแสดงในหน้า Insights หลังเชื่อมบัญชีและอ่านข้อมูลสำเร็จเท่านั้น',
      style: TextStyle(color: muted, fontSize: 10, height: 1.5),
    ),
  ]);
}

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});
  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  static const _ranges = <String, String>{
    'last_7d': '7 วันที่ผ่านมา',
    'last_14d': '14 วันที่ผ่านมา',
    'last_30d': '30 วันที่ผ่านมา',
    'last_90d': '90 วันที่ผ่านมา',
    'this_month': 'เดือนนี้',
    'last_month': 'เดือนที่แล้ว',
    'yesterday': 'เมื่อวาน',
  };

  List<Map<String, dynamic>> _accounts = const [];
  String? _selectedAccountId;
  String _datePreset = 'last_7d';
  Map<String, dynamic>? _insights;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _number(dynamic value, {int decimals = 0}) {
    final parsed = num.tryParse(value?.toString() ?? '');
    if (parsed == null) return '—';
    if (decimals == 0) return parsed.round().toString();
    return parsed.toStringAsFixed(decimals);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final accounts = await MetaApi.adAccounts();
      if (accounts.isEmpty) {
        if (!mounted) return;
        setState(() {
          _accounts = const [];
          _selectedAccountId = null;
          _insights = null;
          _error = 'ยังไม่พบบัญชีโฆษณา Meta ที่เข้าถึงได้';
        });
        return;
      }

      final availableIds = accounts
          .map((item) => item['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      var selected = _selectedAccountId;
      if (selected == null || !availableIds.contains(selected)) {
        selected = accounts.first['id']?.toString();
      }
      if (selected == null || selected.isEmpty) {
        throw Exception('ไม่พบรหัสบัญชีโฆษณา');
      }

      final result = await MetaApi.insights(
        selected,
        datePreset: _datePreset,
      );
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _selectedAccountId = selected;
        final value = result['insights'];
        _insights = value is Map
            ? Map<String, dynamic>.from(value)
            : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _insights = null;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _metric(String label, String value, IconData icon) => MetricCard(
    label: label,
    value: value,
    delta: 'ข้อมูลจาก Meta Ads',
    icon: icon,
  );

  @override
  Widget build(BuildContext context) {
    final currency = _insights?['account_currency']?.toString() ?? '';
    final spend = _number(_insights?['spend'], decimals: 2);
    final dateStart = _insights?['date_start']?.toString();
    final dateStop = _insights?['date_stop']?.toString();

    return PageBody(children: [
      const Text(
        'ผลการโฆษณาจริงจากบัญชี Meta ที่เชื่อมต่อ (Read-only)',
        style: TextStyle(color: muted, fontSize: 12),
      ),
      const SectionTitle('ตัวกรองรายงาน'),
      DropdownButtonFormField<String>(
        value: _accounts.any((a) => a['id']?.toString() == _selectedAccountId)
            ? _selectedAccountId
            : null,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'บัญชีโฆษณา'),
        items: _accounts.map((account) {
          final id = account['id']?.toString() ?? '';
          final name = account['name']?.toString() ?? id;
          return DropdownMenuItem<String>(
            value: id,
            child: Text(name, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: _loading ? null : (value) {
          if (value == null) return;
          setState(() => _selectedAccountId = value);
          _load();
        },
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: _datePreset,
        decoration: const InputDecoration(labelText: 'ช่วงเวลา'),
        items: _ranges.entries.map((entry) => DropdownMenuItem(
          value: entry.key,
          child: Text(entry.value),
        )).toList(),
        onChanged: _loading ? null : (value) {
          if (value == null) return;
          setState(() => _datePreset = value);
          _load();
        },
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
          label: const Text('รีเฟรชข้อมูล'),
        ),
      ),
      if (_loading) ...[
        const SizedBox(height: 12),
        const LinearProgressIndicator(minHeight: 2),
        const SizedBox(height: 8),
        const Text('กำลังอ่านข้อมูลจาก Meta…', style: TextStyle(color: muted, fontSize: 11)),
      ],
      if (_error != null) ...[
        const SizedBox(height: 12),
        CardPanel(child: Text(
          _error!,
          style: const TextStyle(color: Color(0xFFFFA0A0), fontSize: 12),
        )),
      ],
      if (_insights != null) ...[
        const SectionTitle('ผลการโฆษณา'),
        if (dateStart != null && dateStop != null)
          Text('ช่วงข้อมูล: $dateStart ถึง $dateStop',
            style: const TextStyle(color: muted, fontSize: 10)),
        const SizedBox(height: 9),
        _metric('ยอดใช้จ่าย', '$spend $currency', Icons.payments_outlined),
        const SizedBox(height: 9),
        Row(children: [
          Expanded(child: _metric('การเข้าถึง', _number(_insights?['reach']), Icons.groups_outlined)),
          const SizedBox(width: 9),
          Expanded(child: _metric('การแสดงผล', _number(_insights?['impressions']), Icons.visibility_outlined)),
        ]),
        const SizedBox(height: 9),
        Row(children: [
          Expanded(child: _metric('คลิกทั้งหมด', _number(_insights?['clicks']), Icons.ads_click)),
          const SizedBox(width: 9),
          Expanded(child: _metric('CTR', '${_number(_insights?['ctr'], decimals: 2)}%', Icons.trending_up)),
        ]),
        const SizedBox(height: 9),
        Row(children: [
          Expanded(child: _metric('CPC', '${_number(_insights?['cpc'], decimals: 2)} $currency', Icons.touch_app_outlined)),
          const SizedBox(width: 9),
          Expanded(child: _metric('CPM', '${_number(_insights?['cpm'], decimals: 2)} $currency', Icons.bar_chart)),
        ]),
        const SizedBox(height: 9),
        _metric('ความถี่เฉลี่ย', _number(_insights?['frequency'], decimals: 2), Icons.repeat),
      ],
      const SizedBox(height: 10),
      const Text(
        'หมายเหตุ: รายงานนี้ดึงข้อมูลแบบอ่านอย่างเดียวจาก Meta Marketing API ตัวเลขอาจล่าช้าตามการประมวลผลและเขตเวลาของบัญชีโฆษณา ไม่มีการสร้าง แก้ไข หรือเผยแพร่โฆษณา',
        style: TextStyle(color: muted, fontSize: 10, height: 1.5),
      ),
    ]);
  }
}

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _overview = const {};
  List<Map<String, dynamic>> _connections = const [];
  List<Map<String, dynamic>> _events = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final overview = await MetaApi.adminOverview();
      final connections = await MetaApi.adminConnections();
      final events = await MetaApi.adminAudit();
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _connections = connections;
        _events = events;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _overview['metrics'] is Map
        ? Map<String, dynamic>.from(_overview['metrics'])
        : <String, dynamic>{};
    return PageBody(children: [
      CardPanel(child: Row(children: [
        const Icon(Icons.admin_panel_settings_outlined, color: violet, size: 30),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ADNEXA Control Center', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          SizedBox(height: 3),
          Text('พื้นที่ผู้ดูแลระบบ • สิทธิ์แยกจากบัญชีลูกค้า', style: TextStyle(color: muted, fontSize: 10)),
        ])),
        const Chip(label: Text('ADMIN')),
      ])),
      if (_loading) const LinearProgressIndicator(minHeight: 2),
      if (_error != null) CardPanel(child: Text(
        _error! + (_error!.contains('Forbidden') ? '\nบัญชีนี้ยังไม่มี Firebase admin custom claim' : ''),
        style: const TextStyle(color: Color(0xFFFFA0A0), fontSize: 12),
      )),
      if (_error == null && !_loading) ...[
        const SectionTitle('สถานะระบบ'),
        Row(children: [
          Expanded(child: MetricCard(
            label: 'บัญชีที่เชื่อมต่อ',
            value: '${metrics['connected_users'] ?? 0}',
            delta: 'จากฐานข้อมูล ADNEXA',
            icon: Icons.people_alt_outlined,
          )),
          const SizedBox(width: 9),
          Expanded(child: MetricCard(
            label: 'การเชื่อมต่อที่ยังใช้ได้',
            value: '${metrics['active_connections'] ?? 0}',
            delta: 'ตรวจจากวันหมดอายุ Token',
            icon: Icons.verified_outlined,
          )),
        ]),
        const SectionTitle('การเชื่อมต่อ Meta'),
        if (_connections.isEmpty)
          const CardPanel(child: Text('ยังไม่มีรายการเชื่อมต่อ', style: TextStyle(color: muted, fontSize: 11))),
        ..._connections.map((item) => CardPanel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['meta_name']?.toString() ?? 'Meta account',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 4),
            Text('Meta ID: ${item['meta_user_id'] ?? '—'}',
              style: const TextStyle(color: muted, fontSize: 10)),
            Text('User UID: ${item['user_id'] ?? '—'}',
              style: const TextStyle(color: muted, fontSize: 9)),
          ]),
        )),
        const SectionTitle('บันทึกกิจกรรมผู้ดูแล'),
        if (_events.isEmpty)
          const CardPanel(child: Text('ยังไม่มีบันทึกกิจกรรม', style: TextStyle(color: muted, fontSize: 11))),
        ..._events.map((event) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            const Icon(Icons.history, color: muted, size: 17),
            const SizedBox(width: 8),
            Expanded(child: Text(event['action']?.toString() ?? 'admin action',
              style: const TextStyle(fontSize: 11))),
            Text(event['created_at']?.toString() ?? '',
              style: const TextStyle(color: muted, fontSize: 9)),
          ]),
        )),
        const SectionTitle('ขอบเขตสิทธิ์ในรุ่นนี้'),
        const CardPanel(child: Text(
          'รุ่นนี้เป็น Admin Read-only: ตรวจดูจำนวนการเชื่อมต่อ Meta และบันทึกการเข้าถึงได้ ยังไม่เปิดดู/แก้ไขข้อมูลส่วนตัวลูกค้า จัดการบทบาท ระงับบัญชี หรือควบคุมงบโฆษณา การเพิ่มผู้ดูแลต้องกำหนด Firebase custom claim จากช่องทางที่เชื่อถือได้เท่านั้น',
          style: TextStyle(color: muted, fontSize: 11, height: 1.55),
        )),
      ],
      OutlinedButton.icon(
        onPressed: _loading ? null : _load,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('รีเฟรชข้อมูลผู้ดูแล'),
      ),
    ]);
  }
}

class CardPanel extends StatelessWidget {
  final Widget child;
  const CardPanel({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(.055))),
    child: child,
  );
}

class EmptyState extends StatelessWidget {
  final String text;
  const EmptyState({super.key, required this.text});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(15)),
    child: Column(children: [const Icon(Icons.inbox_outlined, color: muted, size: 25), const SizedBox(height: 8), Text(text, textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 11))]),
  );
}
