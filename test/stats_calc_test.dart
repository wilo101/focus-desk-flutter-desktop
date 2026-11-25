import 'package:flutter_test/flutter_test.dart';
import 'package:focus_desk/models/stats_calc.dart';
import 'helpers.dart';

void main() {
  final now = DateTime(2026, 11, 25, 14); // a Wednesday
  DateTime d(int back, [int h = 9]) => DateTime(2026, 11, 25 - back, h);

  test('empty list gives zeros', () {
    final c = StatsCalc(const [], now: now);
    expect(c.totalMinutes, 0);
    expect(c.streak, 0);
    expect(c.bestStreak, 0);
    expect(c.bestWeekday, isNull);
  });

  test('today and total minutes', () {
    final c = StatsCalc([sess(d(0), minutes: 25), sess(d(0, 11), minutes: 50), sess(d(3), minutes: 10)], now: now);
    expect(c.todayMinutes, 75);
    expect(c.totalMinutes, 85);
  });

  test('streak counts consecutive days including today', () {
    final c = StatsCalc([sess(d(0)), sess(d(1)), sess(d(2)), sess(d(4))], now: now);
    expect(c.streak, 3);
  });

  test('streak stays alive when only today is empty', () {
    final c = StatsCalc([sess(d(1)), sess(d(2))], now: now);
    expect(c.streak, 2);
  });

  test('streak breaks after a missed day', () {
    final c = StatsCalc([sess(d(2)), sess(d(3))], now: now);
    expect(c.streak, 0);
  });

  test('best streak finds the longest run', () {
    final c = StatsCalc([sess(d(0)), sess(d(1)), sess(d(5)), sess(d(6)), sess(d(7)), sess(d(8))], now: now);
    expect(c.bestStreak, 4);
  });

  test('minutes by tag groups untagged', () {
    final c = StatsCalc([sess(d(0), tag: 'work', minutes: 30), sess(d(0), tag: 'work', minutes: 20), sess(d(0))], now: now);
    expect(c.minutesByTag, {'work': 50, 'untagged': 25});
  });

  test('lastDays fills quiet days with zero and ends today', () {
    final c = StatsCalc([sess(d(1), minutes: 40)], now: now);
    final days = c.lastDays(3);
    expect(days.map((e) => e.value), [0, 40, 0]);
    expect(days.last.key, DateTime(2026, 11, 25));
  });

  test('goal progress is clamped', () {
    final c = StatsCalc([sess(d(0), minutes: 200)], now: now);
    expect(c.goalProgress(100), 1.0);
    expect(c.goalProgress(0), 0);
  });

  test('week comparison uses Monday to today', () {
    // Wed 25 Nov: this week = Mon 23..Wed 25. Last week = Mon 16..Wed 18.
    final c = StatsCalc([sess(d(2), minutes: 30), sess(d(0), minutes: 20), sess(d(7), minutes: 60), sess(d(9), minutes: 15)], now: now);
    final w = c.weekComparison;
    expect(w.thisWeek, 50);
    expect(w.lastWeek, 60);
  });

  test('best weekday', () {
    final c = StatsCalc([sess(d(0), minutes: 10), sess(d(1), minutes: 90)], now: now);
    expect(c.bestWeekday, DateTime(2026, 11, 24).weekday);
  });

  test('hm formatting', () {
    expect(StatsCalc.hm(45), '45m');
    expect(StatsCalc.hm(125), '2h 5m');
  });
}
