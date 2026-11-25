import 'models.dart';

/// Pure functions over a list of sessions, so the numbers on the stats screen are easy to test.
class StatsCalc {
  const StatsCalc(this.sessions, {DateTime? now}) : _now = now;
  final List<Session> sessions;
  final DateTime? _now;

  DateTime get now => _now ?? DateTime.now();

  static DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);

  int get totalMinutes => sessions.fold(0, (a, s) => a + s.minutes);

  Map<DateTime, int> get minutesByDay {
    final m = <DateTime, int>{};
    for (final s in sessions) {
      final d = day(s.at);
      m[d] = (m[d] ?? 0) + s.minutes;
    }
    return m;
  }

  int minutesOn(DateTime d) => minutesByDay[day(d)] ?? 0;

  int get todayMinutes => minutesOn(now);

  /// The last [n] days ending today, oldest first, with zero for quiet days.
  List<MapEntry<DateTime, int>> lastDays(int n) {
    final today = day(now);
    return [
      for (var i = n - 1; i >= 0; i--) MapEntry(DateTime(today.year, today.month, today.day - i), minutesOn(DateTime(today.year, today.month, today.day - i)))
    ];
  }

  /// Consecutive days with at least one session. Today counts if it has one;
  /// if today is still empty the streak that ended yesterday is kept alive.
  int get streak {
    final days = minutesByDay.keys.toSet();
    var d = day(now);
    if (!days.contains(d)) d = DateTime(d.year, d.month, d.day - 1);
    var n = 0;
    while (days.contains(d)) {
      n++;
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return n;
  }

  int get bestStreak {
    final days = minutesByDay.keys.toList()..sort();
    var best = 0, run = 0;
    DateTime? prev;
    for (final d in days) {
      run = prev != null && DateTime(prev.year, prev.month, prev.day + 1) == d ? run + 1 : 1;
      if (run > best) best = run;
      prev = d;
    }
    return best;
  }

  Map<String, int> get minutesByTag {
    final m = <String, int>{};
    for (final s in sessions) {
      final k = s.tag.isEmpty ? 'untagged' : s.tag;
      m[k] = (m[k] ?? 0) + s.minutes;
    }
    return m;
  }

  double goalProgress(int goalMinutes) => goalMinutes <= 0 ? 0 : (todayMinutes / goalMinutes).clamp(0.0, 1.0);

  /// Minutes this week (Monday to today) against last week's same span.
  ({int thisWeek, int lastWeek}) get weekComparison {
    final today = day(now);
    final monday = DateTime(today.year, today.month, today.day - (today.weekday - 1));
    final prevMonday = DateTime(monday.year, monday.month, monday.day - 7);
    var a = 0, b = 0;
    for (final e in minutesByDay.entries) {
      if (!e.key.isBefore(monday) && !e.key.isAfter(today)) a += e.value;
      final end = DateTime(today.year, today.month, today.day - 7);
      if (!e.key.isBefore(prevMonday) && !e.key.isAfter(end)) b += e.value;
    }
    return (thisWeek: a, lastWeek: b);
  }

  /// The weekday (1 = Monday) with the most focus time, or null with no data.
  int? get bestWeekday {
    if (sessions.isEmpty) return null;
    final m = <int, int>{};
    for (final s in sessions) {
      m[s.at.weekday] = (m[s.at.weekday] ?? 0) + s.minutes;
    }
    return (m.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
  }

  static String hm(int minutes) => minutes >= 60 ? '${minutes ~/ 60}h ${minutes % 60}m' : '${minutes}m';
}
