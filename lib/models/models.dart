import 'dart:convert';

class FocusTask {
  FocusTask({required this.id, required this.title, required this.minutes, this.tag = '', this.done = false});
  final int id;
  final String title, tag;
  final int minutes;
  bool done;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'minutes': minutes, 'tag': tag, 'done': done};
  factory FocusTask.fromJson(Map<String, dynamic> j) => FocusTask(
      id: j['id'] as int, title: '${j['title']}', minutes: j['minutes'] as int, tag: '${j['tag'] ?? ''}', done: (j['done'] ?? false) as bool);
}

/// A finished focus block.
class Session {
  const Session({required this.task, required this.minutes, required this.at, this.tag = '', this.synced = false});
  final String task, tag;
  final int minutes;
  final DateTime at;

  /// True once Relay has accepted it. Unsynced sessions are retried later.
  final bool synced;

  Session markSynced() => Session(task: task, minutes: minutes, at: at, tag: tag, synced: true);

  Map<String, dynamic> toJson() => {'task': task, 'minutes': minutes, 'at': at.toUtc().toIso8601String(), 'tag': tag, 'synced': synced};
  factory Session.fromJson(Map<String, dynamic> j) => Session(
      task: '${j['task']}',
      minutes: (j['minutes'] as num).toInt(),
      at: DateTime.parse(j['at'] as String).toLocal(),
      tag: '${j['tag'] ?? ''}',
      synced: (j['synced'] ?? false) as bool);

  static String encodeList(List<Session> l) => jsonEncode([for (final s in l) s.toJson()]);
  static List<Session> decodeList(String? s) =>
      s == null ? [] : [for (final j in jsonDecode(s) as List) Session.fromJson(j as Map<String, dynamic>)];
}

class Settings {
  const Settings({
    this.focusMinutes = 25,
    this.shortBreak = 5,
    this.longBreak = 15,
    this.longBreakEvery = 4,
    this.autoStartBreaks = true,
    this.dailyGoalMinutes = 120,
    this.notifications = true,
    this.relayUrl = 'http://localhost:8080',
  });

  final int focusMinutes, shortBreak, longBreak, longBreakEvery, dailyGoalMinutes;
  final bool autoStartBreaks, notifications;
  final String relayUrl;

  Settings copyWith({
    int? focusMinutes,
    int? shortBreak,
    int? longBreak,
    int? longBreakEvery,
    int? dailyGoalMinutes,
    bool? autoStartBreaks,
    bool? notifications,
    String? relayUrl,
  }) =>
      Settings(
        focusMinutes: focusMinutes ?? this.focusMinutes,
        shortBreak: shortBreak ?? this.shortBreak,
        longBreak: longBreak ?? this.longBreak,
        longBreakEvery: longBreakEvery ?? this.longBreakEvery,
        dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
        autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
        notifications: notifications ?? this.notifications,
        relayUrl: relayUrl ?? this.relayUrl,
      );

  Map<String, dynamic> toJson() => {
        'focusMinutes': focusMinutes,
        'shortBreak': shortBreak,
        'longBreak': longBreak,
        'longBreakEvery': longBreakEvery,
        'dailyGoalMinutes': dailyGoalMinutes,
        'autoStartBreaks': autoStartBreaks,
        'notifications': notifications,
        'relayUrl': relayUrl,
      };

  factory Settings.fromJson(Map<String, dynamic> j) {
    const d = Settings();
    return Settings(
      focusMinutes: (j['focusMinutes'] ?? d.focusMinutes) as int,
      shortBreak: (j['shortBreak'] ?? d.shortBreak) as int,
      longBreak: (j['longBreak'] ?? d.longBreak) as int,
      longBreakEvery: (j['longBreakEvery'] ?? d.longBreakEvery) as int,
      dailyGoalMinutes: (j['dailyGoalMinutes'] ?? d.dailyGoalMinutes) as int,
      autoStartBreaks: (j['autoStartBreaks'] ?? d.autoStartBreaks) as bool,
      notifications: (j['notifications'] ?? d.notifications) as bool,
      relayUrl: '${j['relayUrl'] ?? d.relayUrl}',
    );
  }
}
