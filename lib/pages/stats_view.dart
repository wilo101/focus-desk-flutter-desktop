import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/stats_calc.dart';
import '../state/timer_model.dart';
import '../theme.dart';
import '../widgets/ring.dart';

class StatsView extends StatelessWidget {
  const StatsView({super.key});

  static const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  Widget build(BuildContext context) {
    final m = context.watch<TimerModel>();
    final s = m.stats;
    final week = s.weekComparison;
    final diff = week.lastWeek == 0 ? null : (week.thisWeek - week.lastWeek) / week.lastWeek;
    final best = s.bestWeekday;
    final tags = s.minutesByTag.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final tagMax = tags.isEmpty ? 1 : tags.first.value;
    return ListView(padding: const EdgeInsets.all(48), children: [
      Text('Your focus', style: serif.copyWith(fontSize: 38, letterSpacing: -1)),
      Text(m.synced ? 'Saved on this device and synced with Relay' : 'Saved on this device', style: const TextStyle(color: muted)),
      const SizedBox(height: 28),
      Wrap(spacing: 18, runSpacing: 18, children: [
        _Stat('Today', StatsCalc.hm(s.todayMinutes), note: 'goal ${StatsCalc.hm(m.settings.dailyGoalMinutes)}'),
        _Stat('Current streak', '${s.streak} days', note: 'best ${s.bestStreak}'),
        _Stat('This week', StatsCalc.hm(week.thisWeek), note: diff == null ? null : '${diff >= 0 ? '+' : ''}${(diff * 100).toStringAsFixed(0)}% vs last week'),
        _Stat('All time', StatsCalc.hm(s.totalMinutes), note: '${m.sessions.length} sessions'),
      ]),
      const SizedBox(height: 32),
      Text('Last 14 days', style: serif.copyWith(fontSize: 22)),
      const SizedBox(height: 12),
      DayBars(days: s.lastDays(14), goal: m.settings.dailyGoalMinutes),
      const SizedBox(height: 8),
      Text('Green bars reached your daily goal.', style: const TextStyle(color: muted, fontSize: 12)),
      if (best != null) Padding(padding: const EdgeInsets.only(top: 20), child: Text('Your best day is ${_weekdays[best - 1]}.')),
      const SizedBox(height: 28),
      Text('By tag', style: serif.copyWith(fontSize: 22)),
      const SizedBox(height: 8),
      if (tags.isEmpty) const Text('Finish a session to see this.', style: TextStyle(color: muted)),
      for (final t in tags)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            SizedBox(width: 110, child: Text(t.key)),
            Expanded(child: LayoutBuilder(builder: (_, c) => Align(alignment: Alignment.centerLeft, child: Container(height: 10, width: c.maxWidth * t.value / tagMax, color: forest)))),
            SizedBox(width: 70, child: Text(StatsCalc.hm(t.value), textAlign: TextAlign.right)),
          ]),
        ),
      const SizedBox(height: 28),
      Text('Recent sessions', style: serif.copyWith(fontSize: 22)),
      for (final x in m.sessions.reversed.take(10))
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(x.task),
          subtitle: Text('${x.at.month}/${x.at.day}  ${x.tag.isEmpty ? '' : x.tag}'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('${x.minutes} min', style: const TextStyle(color: muted)),
            const SizedBox(width: 8),
            Icon(x.synced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined, size: 16, color: x.synced ? forest : muted),
          ]),
        ),
    ]);
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.note});
  final String label, value;
  final String? note;

  @override
  Widget build(BuildContext context) => Container(
        width: 230,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(border: Border.all(color: hairline)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: muted, fontSize: 13)),
          Text(value, style: serif.copyWith(fontSize: 38)),
          if (note != null) Text(note!, style: const TextStyle(color: muted, fontSize: 12)),
        ]),
      );
}
