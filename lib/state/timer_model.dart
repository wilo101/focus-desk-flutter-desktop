import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../models/stats_calc.dart';
import '../services/notifier.dart';
import '../services/relay_sync.dart';
import '../services/storage.dart';

enum Phase { focus, shortBreak, longBreak }

/// The timer, the task queue and the session log.
/// A focus block that ends is logged and synced. Every [Settings.longBreakEvery]th one is followed by a long break.
/// The clock is driven by [tick], so tests can run a whole block without waiting.
class TimerModel extends ChangeNotifier {
  TimerModel({required this.storage, required this.sync, Notifier? notifier, DateTime Function()? clock})
      : notifier = notifier ?? SilentNotifier(),
        _clock = clock ?? DateTime.now {
    settings = storage.loadSettings();
    tasks = storage.loadTasks();
    sessions = storage.loadSessions();
    sync.baseUrl = settings.relayUrl;
    _reset();
  }

  final Storage storage;
  final RelaySync sync;
  final Notifier notifier;
  final DateTime Function() _clock;

  late Settings settings;
  late List<FocusTask> tasks;
  late List<Session> sessions;
  Phase phase = Phase.focus;
  int remaining = 0;
  int focusBlocksToday = 0;
  bool running = false;
  bool synced = false;
  Timer? _timer;

  StatsCalc get stats => StatsCalc(sessions, now: _clock());

  List<FocusTask> get open => [for (final t in tasks) if (!t.done) t];
  FocusTask? get active => open.isEmpty ? null : open.first;
  int get pendingSync => sessions.where((s) => !s.synced).length;

  int get phaseSeconds => switch (phase) {
        Phase.focus => (active?.minutes ?? settings.focusMinutes) * 60,
        Phase.shortBreak => settings.shortBreak * 60,
        Phase.longBreak => settings.longBreak * 60,
      };

  double get progress => phaseSeconds == 0 ? 0 : 1 - remaining / phaseSeconds;
  String get clock => '${(remaining ~/ 60).toString().padLeft(2, '0')}:${(remaining % 60).toString().padLeft(2, '0')}';

  String get label => switch (phase) {
        Phase.focus => active?.title ?? 'Queue is empty',
        Phase.shortBreak => 'Short break',
        Phase.longBreak => 'Long break',
      };

  void _reset() => remaining = phaseSeconds;

  Future<void> init() async {
    await flushSync();
  }

  // ---- control
  void toggle() {
    if (phase == Phase.focus && active == null) return;
    running ? pause() : start();
  }

  void start() {
    running = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    notifyListeners();
  }

  void pause() {
    running = false;
    _timer?.cancel();
    notifyListeners();
  }

  /// One second passes. Public so tests (and nothing else) can drive time.
  void tick() {
    if (!running && _timer != null) return;
    if (remaining > 0) remaining--;
    if (remaining == 0) {
      _complete();
    } else {
      notifyListeners();
    }
  }

  Future<void> _complete() async {
    pause();
    if (phase == Phase.focus) {
      final t = active!;
      t.done = true;
      final s = Session(task: t.title, minutes: t.minutes, at: _clock(), tag: t.tag);
      sessions.add(s);
      focusBlocksToday++;
      await storage.saveTasks(tasks);
      await storage.saveSessions(sessions);
      if (settings.notifications) await notifier.show('Focus block done', '${t.title} (${t.minutes} min). Time for a break.');
      phase = focusBlocksToday % settings.longBreakEvery == 0 ? Phase.longBreak : Phase.shortBreak;
      _reset();
      notifyListeners();
      if (settings.autoStartBreaks) start();
      await flushSync();
    } else {
      if (settings.notifications) await notifier.show('Break over', active == null ? 'Add a task to keep going.' : 'Next: ${active!.title}');
      phase = Phase.focus;
      _reset();
      notifyListeners();
    }
  }

  /// Skip the current block. Skipping a focus block logs nothing and moves the task to the end of the queue.
  void skip() {
    pause();
    if (phase == Phase.focus) {
      final t = active;
      if (t != null && open.length > 1) {
        tasks
          ..remove(t)
          ..add(t);
        storage.saveTasks(tasks);
      }
    } else {
      phase = Phase.focus;
    }
    _reset();
    notifyListeners();
  }

  // ---- tasks
  void addTask(String title, int minutes, {String tag = ''}) {
    if (title.trim().isEmpty || minutes < 1) return;
    final wasEmpty = active == null;
    tasks.add(FocusTask(id: storage.nextTaskId(), title: title.trim(), minutes: minutes, tag: tag.trim().toLowerCase()));
    if (wasEmpty && phase == Phase.focus && !running) _reset();
    storage.saveTasks(tasks);
    notifyListeners();
  }

  void removeTask(int id) {
    final wasActive = active?.id == id;
    tasks.removeWhere((t) => t.id == id);
    if (wasActive && phase == Phase.focus) {
      pause();
      _reset();
    }
    storage.saveTasks(tasks);
    notifyListeners();
  }

  void reorder(int oldIndex, int newIndex) {
    final o = open;
    if (oldIndex < 0 || oldIndex >= o.length) return;
    if (newIndex > oldIndex) newIndex--;
    final moved = o.removeAt(oldIndex);
    o.insert(newIndex.clamp(0, o.length), moved);
    final done = tasks.where((t) => t.done).toList();
    tasks
      ..clear()
      ..addAll(o)
      ..addAll(done);
    if (!running && phase == Phase.focus) _reset();
    storage.saveTasks(tasks);
    notifyListeners();
  }

  void clearDone() {
    tasks.removeWhere((t) => t.done);
    storage.saveTasks(tasks);
    notifyListeners();
  }

  // ---- settings and sync
  Future<void> updateSettings(Settings s) async {
    settings = s;
    sync.baseUrl = s.relayUrl;
    await storage.saveSettings(s);
    if (!running) _reset();
    notifyListeners();
  }

  Future<void> flushSync() async {
    if (pendingSync == 0) {
      synced = await _ping();
      notifyListeners();
      return;
    }
    sessions = await sync.flush(sessions);
    synced = sync.reachable && pendingSync == 0;
    await storage.saveSessions(sessions);
    notifyListeners();
  }

  Future<bool> _ping() async {
    final probe = await sync.flush(const []);
    return probe.isEmpty && sync.reachable;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
