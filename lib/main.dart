import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const AdnexaApp());

const bg = Color(0xFF08090D);
const panel = Color(0xFF141620);
const violet = Color(0xFF9270FF);
const muted = Color(0xFF9295A5);

class AdnexaApp extends StatelessWidget {
  const AdnexaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ADNEXA',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(primary: violet, surface: panel),
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1B1E2A),
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
  final pages = const [DashboardPage(), CampaignPage(), AccountsPage(), AiPage(), AnalyticsPage()];
  final titles = const ['Overview', 'Campaign Studio', 'Account Center', 'ADNEXA AI', 'Analytics'];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(colors: [Color(0xFFB9A6FF), violet, Color(0xFF5634B8)]),
              boxShadow: [BoxShadow(color: violet.withOpacity(.28), blurRadius: 18)],
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white),
          ),
          const SizedBox(width: 11),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ADNEXA', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 2.2)),
            Text('ADVERTISING INTELLIGENCE', style: TextStyle(fontSize: 8, color: muted, letterSpacing: 1.4)),
          ]),
          const Spacer(),
          IconButton(onPressed: () => notice(context, 'ระบบแจ้งเตือนจะเปิดใช้เมื่อเชื่อมต่อ Backend'), icon: const Icon(Icons.notifications_none_rounded)),
          IconButton(tooltip: 'ออกจากระบบ', onPressed: () async { await FirebaseAuth.instance.signOut(); }, icon: const Icon(Icons.logout_rounded)),
          const CircleAvatar(radius: 17, backgroundColor: Color(0xFF29243C), child: Icon(Icons.person_outline, size: 19, color: Color(0xFFC7B8FF))),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Align(alignment: Alignment.centerLeft, child: Text(titles[index], style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800))),
      ),
      const SizedBox(height: 12),
      Expanded(child: IndexedStack(index: index, children: pages)),
    ])),
    bottomNavigationBar: NavigationBar(
      backgroundColor: const Color(0xFF10121A),
      indicatorColor: violet.withOpacity(.2),
      selectedIndex: index,
      onDestinationSelected: (v) => setState(() => index = v),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.campaign_outlined), label: 'Campaigns'),
        NavigationDestination(icon: Icon(Icons.link_rounded), label: 'Accounts'),
        NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'AI'),
        NavigationDestination(icon: Icon(Icons.query_stats), label: 'Insights'),
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
    children: [...children, const SizedBox(height: 12), const DemoNotice()],
  );
}

class DemoNotice extends StatelessWidget {
  const DemoNotice({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFF252033), borderRadius: BorderRadius.circular(13), border: Border.all(color: violet.withOpacity(.22))),
    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.info_outline, color: Color(0xFFBBA8FF), size: 18),
      SizedBox(width: 9),
      Expanded(child: Text('DEMO MODE • ตัวเลขและการเชื่อมต่อเป็นข้อมูลจำลอง ยังไม่มีการยิงโฆษณาจริง', style: TextStyle(color: Color(0xFFC5BEDA), fontSize: 11, height: 1.45))),
    ]),
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
      Icon(icon, color: const Color(0xFFB8A5FF), size: 20),
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

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) => PageBody(children: [
    Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF302653), Color(0xFF171725), Color(0xFF11131B)]),
        border: Border.all(color: violet.withOpacity(.3)),
        boxShadow: [BoxShadow(color: violet.withOpacity(.12), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('YOUR ADVERTISING,\nONE INTELLIGENT SPACE.', style: TextStyle(fontSize: 21, height: 1.25, fontWeight: FontWeight.w900, letterSpacing: .4)),
        const SizedBox(height: 9),
        const Text('วางแผน จัดการ และวิเคราะห์แคมเปญในที่เดียว', style: TextStyle(color: Color(0xFFC5BEDA), fontSize: 12)),
        const SizedBox(height: 18),
        FilledButton.icon(onPressed: () => notice(context, 'Campaign Studio เป็นโหมดทดลอง'), icon: const Icon(Icons.add, size: 18), label: const Text('Create campaign'), style: FilledButton.styleFrom(backgroundColor: violet, foregroundColor: Colors.white)),
      ]),
    ),
    const SectionTitle('Performance snapshot', action: 'DEMO DATA'),
    const Row(children: [
      Expanded(child: MetricCard(label: 'Total spend', value: '฿8,420', delta: '+12.8% vs last period', icon: Icons.payments_outlined)),
      SizedBox(width: 10),
      Expanded(child: MetricCard(label: 'Impressions', value: '42.8K', delta: '+8.4% vs last period', icon: Icons.visibility_outlined)),
    ]),
    const SizedBox(height: 10),
    const Row(children: [
      Expanded(child: MetricCard(label: 'Clicks', value: '1,284', delta: '+5.2% vs last period', icon: Icons.ads_click)),
      SizedBox(width: 10),
      Expanded(child: MetricCard(label: 'ROAS', value: '3.42x', delta: '+0.6x vs last period', icon: Icons.trending_up)),
    ]),
    const SectionTitle('Connected platforms'),
    const PlatformTile(name: 'Meta Ads', subtitle: 'Facebook & Instagram', icon: Icons.facebook, status: 'Not connected'),
    const PlatformTile(name: 'TikTok Ads', subtitle: 'TikTok for Business', icon: Icons.music_note, status: 'Not connected'),
    const PlatformTile(name: 'Google Ads', subtitle: 'Search, Display & YouTube', icon: Icons.ads_click, status: 'Not connected'),
    const SectionTitle('Quick tools'),
    const Wrap(spacing: 8, runSpacing: 8, children: [
      QuickChip(icon: Icons.auto_awesome, label: 'AI creative'),
      QuickChip(icon: Icons.groups_outlined, label: 'Audience'),
      QuickChip(icon: Icons.insights, label: 'Reports'),
      QuickChip(icon: Icons.receipt_long, label: 'Billing'),
    ]),
  ]);
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
      Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFF29243C), borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: const Color(0xFFC4B3FF))),
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
  String campaignMode = 'AI';
  String manualAge = '25–44 ปี';
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

  String _formatPeople(int value) => value.toString();

  String get reachEstimate {
    final dailyAmount = double.tryParse(budget.text.trim());
    if (dailyAmount == null || dailyAmount <= 0) {
      return 'กรุณากรอกงบประมาณต่อวันเพื่อดูประมาณการ';
    }
    final totalBudget = dailyAmount * durationDays;
    // Planning-only assumptions: CPM ฿30–฿100 and frequency 1.2–2.0.
    final low = (totalBudget / 100 * 1000 / 2).round();
    final high = (totalBudget / 30 * 1000 / 1.2).round();
    return _formatPeople(low) + '–' + _formatPeople(high) + ' คน';
  }

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
    setState(() { aiPlan = 'กลุ่มเป้าหมายแนะนำ: ' + audience + '\nพื้นที่เป้าหมาย: ประเทศไทยทั้งประเทศ\nช่วงอายุเริ่มทดสอบ: 25–44 ปี (ปรับตามข้อมูลจริง)\nชิ้นงานแนะนำ: ' + creative + '\nเป้าหมาย: ' + (objectiveLabels[objective] ?? objective) + '\n\nคำแนะนำนี้มาจากตัวช่วยภายในแอป ยังไม่ใช่ AI ออนไลน์ ต้องตรวจทานก่อนใช้'; });
  }

  @override
  void dispose() { name.dispose(); budget.dispose(); productInfo.dispose(); manualAudience.dispose(); manualInterests.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => PageBody(children: [
    const Text('เลือกวิธีจัดการแคมเปญ', style: TextStyle(color: muted, fontSize: 12)),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: _ModeCard(selected: campaignMode == 'AI', icon: Icons.auto_awesome, title: 'ให้ AI ช่วยทำ', subtitle: 'วิเคราะห์และเสนอแผน', onTap: () => setState(() { campaignMode = 'AI'; aiPlan = null; }))),
      const SizedBox(width: 10),
      Expanded(child: _ModeCard(selected: campaignMode == 'Manual', icon: Icons.tune_rounded, title: 'ทำเองทั้งหมด', subtitle: 'กำหนดเองทุกอย่าง', onTap: () => setState(() { campaignMode = 'Manual'; aiPlan = null; }))),
    ]),
    const SizedBox(height: 10),
    CardPanel(child: Text(campaignMode == 'AI' ? 'โหมด AI: ระบุสินค้า/บริการ แล้วให้ตัวช่วยเสนอแนวทาง โดยกำหนดพื้นที่โฆษณาเป็นประเทศไทยทั้งประเทศ' : 'โหมดทำเอง: คุณกำหนดกลุ่มลูกค้า อายุ เพศ และความสนใจได้เอง โดยพื้นที่โฆษณาล็อกไว้ในประเทศไทยทั้งประเทศ', style: const TextStyle(fontSize: 11, color: muted, height: 1.5))),
    const SizedBox(height: 6),
    const Text('Platform', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    const SizedBox(height: 7),
    DropdownButtonFormField<String>(value: platform, items: ['Meta Ads', 'TikTok Ads', 'Google Ads'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => platform = v!)),
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
    if (campaignMode == 'AI') ...[
      const SectionTitle('สินค้า/บริการที่ต้องการโปรโมต'),
      TextField(controller: productInfo, maxLines: 2, decoration: const InputDecoration(hintText: 'เช่น ร้านกาแฟเดลิเวอรี ราคาเริ่มต้น 45 บาท')),
      CardPanel(child: const Row(children: [Icon(Icons.location_on_outlined, color: violet, size: 18), SizedBox(width: 8), Expanded(child: Text('พื้นที่โฆษณา: ประเทศไทยทั้งประเทศ (กำหนดให้อัตโนมัติ)', style: TextStyle(fontSize: 11, color: muted)))])),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _makeAiPlan, icon: const Icon(Icons.auto_awesome), label: const Text('ให้ AI ช่วยวิเคราะห์และเสนอแผน'))),
      if (aiPlan != null) CardPanel(child: SelectableText(aiPlan!, style: const TextStyle(fontSize: 12, height: 1.6))),
    ] else ...[
      CardPanel(child: const Row(children: [Icon(Icons.location_on_outlined, color: violet, size: 18), SizedBox(width: 8), Expanded(child: Text('พื้นที่โฆษณา: ประเทศไทยทั้งประเทศ (ไม่ต้องเลือกจังหวัด)', style: TextStyle(fontSize: 11, color: muted)))])),
      const SectionTitle('กลุ่มลูกค้า'),
      TextField(controller: manualAudience, maxLines: 2, decoration: const InputDecoration(hintText: 'เช่น เจ้าของธุรกิจ / คนทำงาน')),
      const SectionTitle('ช่วงอายุ'),
      DropdownButtonFormField<String>(value: manualAge, items: ['18–24 ปี', '25–44 ปี', '45–60 ปี', 'ทุกช่วงอายุ'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => manualAge = v ?? manualAge)),
      const SectionTitle('เพศ'),
      DropdownButtonFormField<String>(value: manualGender, items: ['ทุกเพศ', 'ชาย', 'หญิง'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => manualGender = v ?? manualGender)),
      const SectionTitle('ความสนใจ (ถ้ามี)'),
      TextField(controller: manualInterests, maxLines: 2, decoration: const InputDecoration(hintText: 'เช่น กาแฟ ร้านอาหาร ธุรกิจออนไลน์')),
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
      const Text('ประมาณการจำนวนคนที่อาจเข้าถึงได้', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      const SizedBox(height: 7),
      Text(reachEstimate, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Color(0xFFBCA9FF))),
      const SizedBox(height: 5),
      Text('งบรวม: ฿${((double.tryParse(budget.text.trim()) ?? 0) * durationDays).toStringAsFixed(0)} ตลอด $durationDays วัน', style: const TextStyle(fontSize: 11, color: muted)),
      const SizedBox(height: 6),
      const Text('ตัวเลขจำลองจากสมมติฐาน CPM ฿30–฿100 และความถี่ 1.2–2 ครั้งต่อคน ยังไม่ใช่ข้อมูลประมาณการจากแพลตฟอร์มโฆษณาจริง ไม่รับประกันผลลัพธ์ และจะต้องเชื่อมต่อ API ของแพลตฟอร์มก่อนจึงจะแสดงค่าจริงได้', style: TextStyle(fontSize: 10, color: muted, height: 1.45)),
    ])),
    const SizedBox(height: 18),
    SizedBox(width: double.infinity, child: FilledButton.icon(
      onPressed: () {
        final amount = double.tryParse(budget.text);
        if (name.text.trim().isEmpty || amount == null || amount <= 0) {
          notice(context, 'กรุณากรอกชื่อแคมเปญและงบประมาณให้ถูกต้อง');
          return;
        }
        if (campaignMode == 'AI' && aiPlan == null) { notice(context, 'กรุณาให้ตัวช่วยวิเคราะห์แผนก่อนบันทึก'); return; }
        if (campaignMode == 'Manual' && manualAudience.text.trim().isEmpty) { notice(context, 'กรุณาระบุกลุ่มลูกค้าในโหมดทำเอง'); return; }
        final targeting = campaignMode == 'AI' ? 'AI PLAN: ' + (aiPlan ?? '') : 'MANUAL: พื้นที่ประเทศไทย, กลุ่ม ' + manualAudience.text.trim() + ', อายุ ' + manualAge + ', เพศ ' + manualGender + ', ความสนใจ ' + manualInterests.text.trim();
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
      decoration: BoxDecoration(color: selected ? const Color(0xFF29213F) : panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? violet : Colors.white.withOpacity(.07), width: selected ? 1.5 : 1)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: selected ? const Color(0xFFC7B5FF) : muted, size: 22), const SizedBox(height: 9), Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: selected ? Colors.white : muted)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 10, color: muted)), const SizedBox(height: 7), Text(selected ? 'SELECTED' : 'เลือกโหมดนี้', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: selected ? const Color(0xFFBCA9FF) : muted))]),
    ),
  );
}

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});
  @override
  Widget build(BuildContext context) => PageBody(children: [
    const Text('Connect your advertising accounts securely.', style: TextStyle(color: muted, fontSize: 12)),
    const SizedBox(height: 14),
    for (final p in const [
      ['Meta Ads', 'Facebook & Instagram campaign accounts', 'Meta'],
      ['TikTok Ads', 'TikTok for Business advertiser accounts', 'TikTok'],
      ['Google Ads', 'Google Search, Display and YouTube', 'Google'],
    ])
      CardPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(p[0], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 4),
        Text(p[1], style: const TextStyle(color: muted, fontSize: 11)),
        const SizedBox(height: 13),
        Row(children: [
          const Icon(Icons.link_off, color: muted, size: 16),
          const SizedBox(width: 6),
          const Expanded(child: Text('Not connected', style: TextStyle(color: muted, fontSize: 11))),
          OutlinedButton(onPressed: () => notice(context, 'การเชื่อมต่อ ${p[2]} ต้องตั้งค่า OAuth และ Backend ก่อน'), child: const Text('Connect')),
        ]),
      ])),
    const SizedBox(height: 6),
    const Text('Security principle', style: TextStyle(fontWeight: FontWeight.w700)),
    const SizedBox(height: 7),
    const Text('ADNEXA จะไม่ขอหรือเก็บรหัสผ่านบัญชีโฆษณาของคุณ การเชื่อมต่อจริงจะใช้ OAuth ทางการและจัดเก็บ Token ฝั่งเซิร์ฟเวอร์เท่านั้น', style: TextStyle(color: muted, fontSize: 12, height: 1.5)),
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
  final budget = TextEditingController(text: '300');
  String tone = 'เป็นกันเอง';
  String? output;
  String? audiencePlan;
  String? estimate;

  @override
  void dispose() {
    product.dispose();
    audience.dispose();
    budget.dispose();
    super.dispose();
  }

  void analyze() {
    final item = product.text.trim();
    final amount = double.tryParse(budget.text.trim());
    if (item.isEmpty) {
      notice(context, 'กรุณาระบุสินค้าหรือบริการก่อน');
      return;
    }
    if (amount == null || amount < 50 || amount > 1000000) {
      notice(context, 'กรุณาระบุงบประมาณตั้งแต่ 50 ถึง 1,000,000 บาท');
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
    // Illustrative planning assumptions only: CPM 30-100 THB, CTR 0.5%-2%.
    final impressionsLow = (amount / 100 * 1000).round();
    final impressionsHigh = (amount / 30 * 1000).round();
    final clicksLow = (impressionsLow * 0.005).round();
    final clicksHigh = (impressionsHigh * 0.02).round();
    final customAudience = description.isEmpty ? 'ยังไม่ได้ระบุกลุ่มลูกค้าเฉพาะ' : description;

    setState(() {
      audiencePlan = 'กลุ่มเป้าหมายตั้งต้น: $segment\nกลุ่มลูกค้าที่คุณระบุ: $customAudience\n\nกลยุทธ์ตามประเภทธุรกิจ: $strategy\nรูปแบบสื่อที่แนะนำ: $creative\nข้อเสนอที่ควรทดลอง: $offer\n\n$objectiveAdvice\nแนวทาง: เริ่มทดสอบในพื้นที่ให้บริการและปรับกลุ่มตามผลตอบรับจริง';
      output = 'พบกับ $item ที่ออกแบบมาเพื่อตอบโจทย์คุณ เลือกสิ่งที่ใช่และติดต่อเราได้วันนี้!\nโทนข้อความ: $tone';
      estimate = 'งบประมาณที่ใช้คำนวณ: ฿${amount.toStringAsFixed(0)} ต่อวัน\nการแสดงผลโดยประมาณ: ${impressionsLow.toString()}–${impressionsHigh.toString()} ครั้ง/วัน\nคลิกโดยประมาณ: ${clicksLow.toString()}–${clicksHigh.toString()} ครั้ง/วัน';
    });
  }

  @override
  Widget build(BuildContext context) => PageBody(children: [
    Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: [Color(0xFF302653), Color(0xFF171725)]),
      ),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.auto_awesome, color: Color(0xFFC7B5FF), size: 25),
        SizedBox(height: 10),
        Text('ADNEXA Campaign Planner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        SizedBox(height: 5),
        Text('วิเคราะห์เบื้องต้น วางกลุ่มเป้าหมาย และประเมินผลตามงบประมาณ', style: TextStyle(color: Color(0xFFC5BEDA), fontSize: 11)),
      ]),
    ),
    const SectionTitle('1. สินค้าหรือบริการ'),
    TextField(controller: product, maxLines: 2, decoration: const InputDecoration(hintText: 'เช่น ร้านกาแฟเดลิเวอรี / บริการล้างแอร์')),
    const SectionTitle('2. ลูกค้าที่ต้องการเข้าถึง'),
    TextField(controller: audience, maxLines: 2, decoration: const InputDecoration(hintText: 'เช่น คนทำงานอายุ 25–40 ปี ในขอนแก่น (ไม่บังคับ)')),
    const SectionTitle('3. งบประมาณต่อวัน (บาท)'),
    TextField(controller: budget, keyboardType: TextInputType.number, decoration: const InputDecoration(prefixText: '฿  ', hintText: '300')),
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
      const SectionTitle('ประมาณการผลลัพธ์'),
      CardPanel(child: SelectableText(estimate!, style: const TextStyle(fontSize: 13, height: 1.6))),
    ],
    const Text(
      'ข้อจำกัด: ระบบนี้เป็นเครื่องมือวางแผนแบบออฟไลน์ ไม่ได้เชื่อม AI หรือข้อมูลโฆษณาจริง ตัวเลขใช้สมมติฐาน CPM ฿30–฿100 และ CTR 0.5%–2% เพื่อแสดงช่วงตัวอย่างเท่านั้น ผลจริงอาจแตกต่างมากและไม่รับประกัน',
      style: TextStyle(color: muted, fontSize: 10, height: 1.5),
    ),
  ]);
}

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});
  @override
  Widget build(BuildContext context) => PageBody(children: [
    const Text('Campaign performance overview', style: TextStyle(color: muted, fontSize: 12)),
    const SectionTitle('Key metrics'),
    const MetricCard(label: 'Reach', value: '28,640', delta: 'Demo metric', icon: Icons.groups_outlined),
    const SizedBox(height: 9),
    const Row(children: [
      Expanded(child: MetricCard(label: 'CTR', value: '2.98%', delta: 'Demo metric', icon: Icons.ads_click)),
      SizedBox(width: 9),
      Expanded(child: MetricCard(label: 'Conversions', value: '146', delta: 'Demo metric', icon: Icons.shopping_bag_outlined)),
    ]),
    const SizedBox(height: 9),
    const MetricCard(label: 'ROAS', value: '3.42x', delta: 'Demo metric', icon: Icons.trending_up),
    const SectionTitle('Reporting'),
    const EmptyState(text: 'รายงานจริงจะแสดงเมื่อเชื่อมต่อแพลตฟอร์มโฆษณา'),
  ]);
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
