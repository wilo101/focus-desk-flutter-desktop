import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../state/timer_model.dart';
import '../theme.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.watch<TimerModel>();
    final s = m.settings;
    void set(Settings n) => m.updateSettings(n);
    Widget stepper(String label, int value, int min, int max, ValueChanged<int> on, {String unit = 'min'}) => Row(children: [
          Expanded(child: Text(label)),
          IconButton(icon: const Icon(Icons.remove), onPressed: value > min ? () => on(value - 1) : null),
          SizedBox(width: 64, child: Text('$value $unit', textAlign: TextAlign.center)),
          IconButton(icon: const Icon(Icons.add), onPressed: value < max ? () => on(value + 1) : null),
        ]);
    return ListView(padding: const EdgeInsets.all(48), children: [
      Text('Settings', style: serif.copyWith(fontSize: 38, letterSpacing: -1)),
      const SizedBox(height: 24),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Timer', style: serif.copyWith(fontSize: 22)),
          stepper('Focus block', s.focusMinutes, 5, 120, (v) => set(s.copyWith(focusMinutes: v))),
          stepper('Short break', s.shortBreak, 1, 30, (v) => set(s.copyWith(shortBreak: v))),
          stepper('Long break', s.longBreak, 5, 60, (v) => set(s.copyWith(longBreak: v))),
          stepper('Long break after', s.longBreakEvery, 2, 8, (v) => set(s.copyWith(longBreakEvery: v)), unit: 'blocks'),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Start breaks automatically'), value: s.autoStartBreaks, onChanged: (v) => set(s.copyWith(autoStartBreaks: v))),
          const Divider(height: 40),
          Text('Goals and alerts', style: serif.copyWith(fontSize: 22)),
          stepper('Daily goal', s.dailyGoalMinutes, 15, 600, (v) => set(s.copyWith(dailyGoalMinutes: v)), unit: 'min'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Desktop notifications'),
            subtitle: const Text('When a focus block or a break ends.'),
            value: s.notifications,
            onChanged: (v) => set(s.copyWith(notifications: v)),
          ),
          const Divider(height: 40),
          Text('Sync', style: serif.copyWith(fontSize: 22)),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: s.relayUrl,
            decoration: const InputDecoration(labelText: 'Relay server URL'),
            onFieldSubmitted: (v) {
              set(s.copyWith(relayUrl: v.trim().replaceAll(RegExp(r'/+$'), '')));
              m.flushSync();
            },
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text(m.pendingSync == 0 ? 'Everything is synced.' : '${m.pendingSync} sessions waiting to sync.')),
            OutlinedButton(style: OutlinedButton.styleFrom(shape: const RoundedRectangleBorder()), onPressed: m.flushSync, child: const Text('Sync now')),
          ]),
        ]),
      ),
    ]);
  }
}
