import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'relay_sync.dart';

class FocusTask {
  FocusTask(this.title, this.minutes, {this.done = false});
  final String title;
  final int minutes;
  bool done;
}

class TimerModel extends ChangeNotifier {
  final RelaySync sync = RelaySync();
  final List<FocusTask> tasks = [
    FocusTask('Review onboarding flow', 25),
    FocusTask('Write API integration tests', 50),
    FocusTask('Plan sprint demo', 25),
  ];
  int current = 0;
  int remaining = 25 * 60;
  bool running = false;
  bool synced = false;
  List<Map<String, dynamic>> history = [];
  Timer? _t;

  FocusTask? get active => current < tasks.length ? tasks[current] : null;
  double get progress => active == null ? 0 : 1 - remaining / (active!.minutes * 60);
  String get clock => '${(remaining ~/ 60).toString().padLeft(2, '0')}:${(remaining % 60).toString().padLeft(2, '0')}';

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getStringList('tasks');
    if (saved != null && saved.isNotEmpty) {
      tasks
        ..clear()
        ..addAll(saved.map((s) {
          final parts = s.split('|');
          return FocusTask(parts[0], int.parse(parts[1]));
        }));
      remaining = tasks.first.minutes * 60;
    }
    await refreshHistory();
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('tasks', [for (final t in tasks.where((t) => !t.done)) '${t.title}|${t.minutes}']);
  }

  Future<void> refreshHistory() async {
    history = await sync.sessions();
    synced = sync.reachable;
    notifyListeners();
  }

  void toggle() {
    if (active == null) return;
    running = !running;
    _t?.cancel();
    if (running) _t = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void _tick() {
    if (remaining > 0) {
      remaining--;
    } else {
      _finish();
    }
    notifyListeners();
  }

  Future<void> _finish() async {
    _t?.cancel();
    running = false;
    final t = active!;
    t.done = true;
    synced = await sync.pushSession(t.title, t.minutes);
    current++;
    remaining = (active?.minutes ?? 25) * 60;
    await _persist();
    await refreshHistory();
  }

  void skip() {
    if (active == null) return;
    _t?.cancel();
    running = false;
    current++;
    remaining = (active?.minutes ?? 25) * 60;
    notifyListeners();
  }

  void addTask(String title, int minutes) {
    if (title.trim().isEmpty) return;
    tasks.add(FocusTask(title.trim(), minutes));
    if (current >= tasks.length - 1) remaining = active!.minutes * 60;
    _persist();
    notifyListeners();
  }

  int get totalMinutes => history.fold(0, (a, s) => a + ((s['minutes'] as num?)?.toInt() ?? 0));
}
