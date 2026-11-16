import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const _directoryBg = Color(0xFF08090D);
const _directoryPanel = Color(0xFF141620);
const _directoryAccent = Color(0xFF9270FF);
const _directoryMuted = Color(0xFF9295A5);
const _adminApiBaseUrl = String.fromEnvironment('ADMIN_API_BASE_URL');

class AdminUsersEntryCard extends StatelessWidget {
  final VoidCallback onTap;

  const AdminUsersEntryCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: _directoryPanel,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: .06)),
            ),
            child: const Row(
              children: [
                Icon(Icons.manage_accounts_outlined,
                    color: Color(0xFFC4B3FF), size: 23),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('จัดการผู้ดูแลระบบ',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      SizedBox(height: 4),
                      Text('รายชื่อผู้ดูแล บทบาท และการเพิกถอนเซสชัน',
                          style: TextStyle(color: _directoryMuted, fontSize: 10)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: _directoryMuted),
              ],
            ),
          ),
        ),
      );
}

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _users = const [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<Map<String, dynamic>> _request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('กรุณาเข้าสู่ระบบใหม่');
    if (_adminApiBaseUrl.isEmpty) {
      throw StateError('ยังไม่ได้ตั้งค่า ADMIN_API_BASE_URL');
    }

    final token = await user.getIdToken(true);
    final client = HttpClient();
    try {
      final uri = Uri.parse(
        '${_adminApiBaseUrl.replaceFirst(RegExp(r'/+$'), '')}$path',
      );
      final request = await client.openUrl(method, uri);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }
      final response = await request.close();
      final raw = await response.transform(utf8.decoder).join();
      final decoded = raw.isEmpty ? <String, dynamic>{} : jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('รูปแบบข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final code = decoded['error'] is Map
            ? decoded['error']['code']?.toString()
            : null;
        throw HttpException(code ?? 'คำขอไม่สำเร็จ (${response.statusCode})');
      }
      return decoded;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _request('/v1/admin/users');
      final rawItems = result['items'];
      final users = rawItems is List
          ? rawItems.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _revokeSession(Map<String, dynamic> admin) async {
    final uid = admin['uid']?.toString() ?? '';
    if (uid.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _directoryPanel,
        title: const Text('เพิกถอนเซสชันผู้ดูแล?'),
        content: Text(
          'บัญชี $uid จะต้องเข้าสู่ระบบใหม่ เซสชันเดิมจะถูกปฏิเสธจาก Backend',
          style: const TextStyle(color: _directoryMuted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF9B4C5B)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ยืนยันเพิกถอน'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _request('/v1/admin/sessions/revoke', method: 'POST', body: {'uid': uid});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกคำสั่งเพิกถอนเซสชันแล้ว')),
      );
      await _loadUsers();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ดำเนินการไม่สำเร็จ: $error')),
      );
    }
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      case 'support':
        return 'Support';
      default:
        return role ?? 'ไม่ระบุ';
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _directoryBg,
        appBar: AppBar(
          backgroundColor: _directoryBg,
          title: const Text('จัดการผู้ดูแลระบบ',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          actions: [
            IconButton(
              tooltip: 'รีเฟรช',
              onPressed: _loading ? null : _loadUsers,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFFFC978), size: 38),
                          const SizedBox(height: 12),
                          const Text('โหลดทะเบียนผู้ดูแลไม่สำเร็จ',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Text(_error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: _directoryMuted, fontSize: 12)),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _loadUsers,
                            icon: const Icon(Icons.refresh),
                            label: const Text('ลองอีกครั้ง'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFF242039),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _directoryAccent.withValues(alpha: .3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_user_outlined,
                                  color: Color(0xFFC7B5FF), size: 25),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Text(
                                  'ทะเบียนผู้ดูแลที่ Backend อนุญาต · ${_users.length} บัญชี',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_users.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('ยังไม่มีบัญชีผู้ดูแลในทะเบียน',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: _directoryMuted)),
                          ),
                        for (final admin in _users)
                          _AdminUserCard(
                            admin: admin,
                            roleLabel: _roleLabel(admin['role']?.toString()),
                            onRevoke: admin['uid'] == FirebaseAuth.instance.currentUser?.uid
                                ? null
                                : () => _revokeSession(admin),
                          ),
                        const SizedBox(height: 12),
                        const Text(
                          'หมายเหตุ: การเพิกถอนนี้เป็นการปิดกั้นเซสชันในระบบ CONTENTNEX โดยอาศัย auth_time ไม่ใช่การเรียก Firebase revokeRefreshTokens โดยตรง',
                          style: TextStyle(color: _directoryMuted, fontSize: 10, height: 1.5),
                        ),
                      ],
                    ),
                  ),
      );
}

class _AdminUserCard extends StatelessWidget {
  final Map<String, dynamic> admin;
  final String roleLabel;
  final VoidCallback? onRevoke;

  const _AdminUserCard({
    required this.admin,
    required this.roleLabel,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    final uid = admin['uid']?.toString() ?? '';
    final status = admin['status']?.toString() ?? 'unknown';
    final active = status == 'active';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _directoryPanel,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_circle_outlined,
                  color: Color(0xFFC7B5FF), size: 25),
              const SizedBox(width: 9),
              Expanded(
                child: Text(roleLabel,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF18372D) : const Color(0xFF39252A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(active ? 'ACTIVE' : status.toUpperCase(),
                    style: TextStyle(
                      color: active ? const Color(0xFF8CE0B6) : const Color(0xFFFFA7B0),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 9),
          SelectableText(uid,
              style: const TextStyle(color: _directoryMuted, fontSize: 10)),
          if (onRevoke != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onRevoke,
                icon: const Icon(Icons.logout, size: 15),
                label: const Text('เพิกถอนเซสชัน'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFFA7B0),
                  side: const BorderSide(color: Color(0xFF74404A)),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('บัญชีที่กำลังใช้งานอยู่ · ปิดการเพิกถอนตัวเอง',
                  style: TextStyle(color: _directoryMuted, fontSize: 10)),
            ),
        ],
      ),
    );
  }
}
