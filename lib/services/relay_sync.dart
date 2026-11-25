import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

/// Syncs finished sessions with Relay. Never throws: offline just means "try again later".
class RelaySync {
  RelaySync({this.baseUrl = defaultUrl, http.Client? client}) : _c = client ?? http.Client();

  static const defaultUrl = String.fromEnvironment('RELAY_URL', defaultValue: 'http://localhost:8080');
  static const user = String.fromEnvironment('RELAY_USER', defaultValue: 'admin');
  static const pass = String.fromEnvironment('RELAY_PASS', defaultValue: 'admin123');

  String baseUrl;
  final http.Client _c;
  String? _token;
  bool reachable = false;

  Uri _u(String p) => Uri.parse('$baseUrl$p');
  Map<String, String> get _h => {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'};

  Future<bool> _login() async {
    try {
      final r = await _c
          .post(_u('/auth/login'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'username': user, 'password': pass}))
          .timeout(const Duration(seconds: 6));
      reachable = true;
      if (r.statusCode != 200) return false;
      _token = jsonDecode(r.body)['token'] as String;
      return true;
    } catch (_) {
      reachable = false;
      return false;
    }
  }

  Future<http.Response?> _send(Future<http.Response> Function() call) async {
    if (_token == null && !await _login()) return null;
    try {
      var r = await call().timeout(const Duration(seconds: 8));
      if (r.statusCode == 401 && await _login()) r = await call().timeout(const Duration(seconds: 8));
      reachable = true;
      return r;
    } catch (_) {
      reachable = false;
      return null;
    }
  }

  Future<bool> push(Session s) async {
    final r = await _send(() => _c.post(_u('/focus/sessions'), headers: _h, body: jsonEncode({'task': s.task, 'minutes': s.minutes, 'tag': s.tag})));
    return r?.statusCode == 201;
  }

  /// Sends every unsynced session in order and returns the list with the accepted ones marked.
  /// It stops at the first failure so the order is kept and the rest wait for the next try.
  Future<List<Session>> flush(List<Session> all) async {
    final out = [...all];
    for (var i = 0; i < out.length; i++) {
      if (out[i].synced) continue;
      if (!await push(out[i])) break;
      out[i] = out[i].markSynced();
    }
    return out;
  }
}
