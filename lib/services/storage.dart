import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Everything saved on the device lives here. Sessions are kept locally too, so stats work offline.
class Storage {
  Storage(this._p);
  final SharedPreferences _p;

  static Future<Storage> open() async => Storage(await SharedPreferences.getInstance());

  List<FocusTask> loadTasks() {
    final s = _p.getString('tasks');
    if (s == null) return [];
    return [for (final j in jsonDecode(s) as List) FocusTask.fromJson(j as Map<String, dynamic>)];
  }

  Future<void> saveTasks(List<FocusTask> t) => _p.setString('tasks', jsonEncode([for (final x in t) x.toJson()]));

  List<Session> loadSessions() => Session.decodeList(_p.getString('sessions'));

  Future<void> saveSessions(List<Session> s) => _p.setString('sessions', Session.encodeList(s.length > 2000 ? s.sublist(s.length - 2000) : s));

  Settings loadSettings() {
    final s = _p.getString('settings');
    return s == null ? const Settings() : Settings.fromJson(jsonDecode(s) as Map<String, dynamic>);
  }

  Future<void> saveSettings(Settings s) => _p.setString('settings', jsonEncode(s.toJson()));

  int nextTaskId() {
    final n = (_p.getInt('nextTaskId') ?? 1);
    _p.setInt('nextTaskId', n + 1);
    return n;
  }
}
