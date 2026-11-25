import 'dart:convert';
import 'package:http/http.dart' as http;

/// Syncs finished focus sessions to the Relay backend. Fails quietly when offline.
class RelaySync {
  static const baseUrl = String.fromEnvironment('RELAY_URL', defaultValue: 'http://localhost:8080');
  static const user = String.fromEnvironment('RELAY_USER', defaultValue: 'admin');
  static const pass = String.fromEnvironment('RELAY_PASS', defaultValue: 'admin123');
  String? _token;
  bool reachable = false;

  Future<bool> _login() async {
    try {
      final r = await http.post(Uri.parse('$baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode({'username': user, 'password': pass}));
      reachable = true;
      if (r.statusCode != 200) return false;
      _token = jsonDecode(r.body)['token'] as String;
      return true;
    } catch (_) {
      reachable = false;
      return false;
    }
  }

  Map<String, String> get _h => {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'};

  Future<bool> pushSession(String task, int minutes) async {
    if (_token == null && !await _login()) return false;
    try {
      final r = await http.post(Uri.parse('$baseUrl/focus/sessions'), headers: _h, body: jsonEncode({'task': task, 'minutes': minutes}));
      return r.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> sessions() async {
    if (_token == null && !await _login()) return [];
    try {
      final r = await http.get(Uri.parse('$baseUrl/focus/sessions'), headers: _h);
      return (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}
