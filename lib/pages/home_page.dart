import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/timer_model.dart';
import '../theme.dart';
import 'settings_view.dart';
import 'stats_view.dart';
import 'today_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  static const _labels = ['Today', 'Stats', 'Settings'];

  @override
  Widget build(BuildContext context) {
    final m = context.watch<TimerModel>();
    final streak = m.stats.streak;
    return Scaffold(
      body: Row(children: [
        Container(
          width: 210,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(border: Border(right: BorderSide(color: hairline))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.fromLTRB(8, 12, 8, 28), child: Text('Focus Desk', style: serif.copyWith(fontSize: 22))),
            for (final (i, l) in _labels.indexed)
              ListTile(
                dense: true,
                selected: tab == i,
                selectedColor: ink,
                title: Text(l, style: TextStyle(color: tab == i ? ink : muted, fontWeight: tab == i ? FontWeight.w600 : FontWeight.w400)),
                onTap: () => setState(() => tab = i),
              ),
            const Spacer(),
            if (streak > 0) Padding(padding: const EdgeInsets.only(bottom: 10, left: 8), child: Text('$streak day streak', style: const TextStyle(fontWeight: FontWeight.w600))),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                m.synced ? '● Synced with Relay' : (m.pendingSync > 0 ? '○ ${m.pendingSync} waiting to sync' : '○ Offline, saved locally'),
                style: TextStyle(fontSize: 12, color: m.synced ? forest : muted),
              ),
            ),
          ]),
        ),
        Expanded(child: IndexedStack(index: tab, children: const [TodayView(), StatsView(), SettingsView()])),
      ]),
    );
  }
}
