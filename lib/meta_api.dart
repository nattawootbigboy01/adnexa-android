import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

const _apiBaseUrl = String.fromEnvironment(
  'ADNEXA_API_BASE_URL',
  defaultValue: 'https://adnexa-api.nattawootbigboy01.workers.dev',
);

class MetaApi {
  static Future<String> _idToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('กรุณาเข้าสู่ระบบ ADNEXA ใหม่');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw Exception('ไม่สามารถยืนยันตัวตนกับเซิร์ฟเวอร์ได้');
    }
    return token;
  }

  static Future<Map<String, dynamic>> _request(
    String path, {
    String method = 'GET',
  }) async {
    final token = await _idToken();
    final uri = Uri.parse('$_apiBaseUrl$path');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    late http.Response response;
    if (method == 'POST') {
      response = await http.post(uri, headers: headers).timeout(
        const Duration(seconds: 25),
      );
    } else if (method == 'DELETE') {
      response = await http.delete(uri, headers: headers).timeout(
        const Duration(seconds: 25),
      );
    } else {
      response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 25),
      );
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('เซิร์ฟเวอร์ตอบกลับในรูปแบบที่ไม่ถูกต้อง');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final missing = data['missing_configuration'];
      if (missing is List && missing.isNotEmpty) {
        throw Exception('ยังตั้งค่า Meta OAuth ไม่ครบ: ${missing.join(', ')}');
      }
      throw Exception(
        data['error']?.toString() ?? 'เชื่อมต่อเซิร์ฟเวอร์ไม่สำเร็จ',
      );
    }
    return data;
  }

  static Future<Uri> startConnection() async {
    final data = await _request('/api/oauth/meta/start', method: 'POST');
    final value = data['authorization_url'];
    if (value is! String || value.isEmpty) {
      throw Exception('เซิร์ฟเวอร์ไม่ได้ส่งลิงก์เข้าสู่ระบบ Meta');
    }
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'www.facebook.com') {
      throw Exception('ลิงก์เข้าสู่ระบบ Meta ไม่ถูกต้อง');
    }
    return uri;
  }

  static Future<Map<String, dynamic>> connection() =>
      _request('/api/meta/connection');

  static Future<List<Map<String, dynamic>>> adAccounts() async {
    final data = await _request('/api/meta/ad-accounts');
    final items = data['accounts'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  static Future<Map<String, dynamic>> insights(
    String accountId, {
    String datePreset = 'last_7d',
  }) =>
      _request(
        '/api/meta/insights?ad_account_id=${Uri.encodeQueryComponent(accountId)}'
        '&date_preset=${Uri.encodeQueryComponent(datePreset)}',
      );

  static Future<void> disconnect() async {
    await _request('/api/meta/connection', method: 'DELETE');
  }
}
