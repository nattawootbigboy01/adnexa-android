import 'package:flutter/material.dart';

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
    home: const AppShell(),
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
  final drafts = <String>[];

  @override
  void dispose() { name.dispose(); budget.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => PageBody(children: [
    const Text('Build a campaign draft', style: TextStyle(color: muted, fontSize: 12)),
    const SizedBox(height: 16),
    const Text('Platform', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    const SizedBox(height: 7),
    DropdownButtonFormField<String>(value: platform, items: ['Meta Ads', 'TikTok Ads', 'Google Ads'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => platform = v!)),
    const SizedBox(height: 15),
    const Text('Campaign name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    const SizedBox(height: 7),
    TextField(controller: name, decoration: const InputDecoration(hintText: 'e.g. November product launch')),
    const SizedBox(height: 15),
    const Text('Objective', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    const SizedBox(height: 7),
    DropdownButtonFormField<String>(value: objective, items: ['Awareness', 'Traffic', 'Engagement', 'Leads', 'Sales'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => objective = v!)),
    const SizedBox(height: 15),
    const Text('Daily budget (THB)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    const SizedBox(height: 7),
    TextField(controller: budget, keyboardType: TextInputType.number, decoration: const InputDecoration(prefixText: '฿  ', hintText: '300')),
    const SizedBox(height: 18),
    SizedBox(width: double.infinity, child: FilledButton.icon(
      onPressed: () {
        final amount = double.tryParse(budget.text);
        if (name.text.trim().isEmpty || amount == null || amount <= 0) {
          notice(context, 'กรุณากรอกชื่อแคมเปญและงบประมาณให้ถูกต้อง');
          return;
        }
        setState(() => drafts.insert(0, '${name.text.trim()} • $platform • $objective • ฿${amount.toStringAsFixed(0)}/day'));
        name.clear();
        notice(context, 'บันทึก Draft ในหน่วยความจำของแอปแล้ว (ยังไม่ส่งโฆษณาจริง)');
      },
      icon: const Icon(Icons.save_outlined), label: const Text('Save draft'),
      style: FilledButton.styleFrom(backgroundColor: violet, padding: const EdgeInsets.symmetric(vertical: 14)),
    )),
    const SectionTitle('Saved drafts'),
    if (drafts.isEmpty) const EmptyState(text: 'ยังไม่มีแคมเปญฉบับร่าง'),
    ...drafts.map((d) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(13)), child: Text(d, style: const TextStyle(fontSize: 12)))),
  ]);
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
  String tone = 'Professional';
  String? output;
  @override
  void dispose() { product.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => PageBody(children: [
    Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: const LinearGradient(colors: [Color(0xFF302653), Color(0xFF171725)])), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.auto_awesome, color: Color(0xFFC7B5FF), size: 25),
      SizedBox(height: 10),
      Text('Creative intelligence', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      SizedBox(height: 5),
      Text('สร้างแนวคิดข้อความโฆษณาเบื้องต้นได้ในแอป', style: TextStyle(color: Color(0xFFC5BEDA), fontSize: 11)),
    ])),
    const SectionTitle('What are you promoting?'),
    TextField(controller: product, maxLines: 3, decoration: const InputDecoration(hintText: 'อธิบายสินค้า บริการ หรือข้อเสนอของคุณ')),
    const SectionTitle('Writing tone'),
    DropdownButtonFormField<String>(value: tone, items: ['Professional', 'Friendly', 'Luxury', 'Urgent'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => tone = v!)),
    const SizedBox(height: 14),
    SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () {
      if (product.text.trim().isEmpty) { notice(context, 'กรุณาระบุสินค้าหรือบริการก่อน'); return; }
      setState(() => output = 'พบกับ ${product.text.trim()} ที่ตอบโจทย์คุณในทุกวัน เลือกสิ่งที่ใช่ พร้อมเริ่มต้นได้แล้ววันนี้! [โทน: $tone]');
    }, icon: const Icon(Icons.auto_awesome), label: const Text('Generate demo copy'), style: FilledButton.styleFrom(backgroundColor: violet))),
    if (output != null) ...[
      const SectionTitle('Generated concept'),
      CardPanel(child: SelectableText(output!, style: const TextStyle(fontSize: 13, height: 1.6))),
    ],
    const Text('หมายเหตุ: เป็นตัวอย่างสร้างข้อความแบบออฟไลน์ ยังไม่ได้เชื่อม AI API', style: TextStyle(color: muted, fontSize: 10)),
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
