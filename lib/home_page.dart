import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'timer_model.dart';

const _violet = Color(0xFF14130F); // ink
const _cyan = Color(0xFF2F6B4F); // accent
const _muted = Color(0xFF7A7568);

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final m = context.watch<TimerModel>();
    return Scaffold(
      body: Row(children: [
        _Sidebar(tab: tab, onTab: (i) => setState(() => tab = i), synced: m.synced),
        Expanded(child: tab == 0 ? const _TodayView() : const _StatsView()),
      ]),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.tab, required this.onTab, required this.synced});
  final int tab;
  final ValueChanged<int> onTab;
  final bool synced;
  @override
  Widget build(BuildContext context) => Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(border: Border(right: BorderSide(color: Color(0x2214130F)))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 12, 8, 28),
            child: Text('Focus Desk', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          ),
          for (final (i, l) in ['Today', 'Stats'].indexed)
            Container(
              margin: const EdgeInsets.only(bottom: 5),
              decoration: BoxDecoration(
                color: tab == i ? Colors.transparent : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                dense: true,
                title: Text(l, style: TextStyle(color: tab == i ? _violet : _muted, fontWeight: tab == i ? FontWeight.w500 : FontWeight.w400)),
                onTap: () => onTab(i),
              ),
            ),
          const Spacer(),
          Text(synced ? '● Synced with Relay' : '○ Offline, saved locally',
              style: TextStyle(fontSize: 12, color: synced ? _cyan : _muted)),
        ]),
      );
}

class _TodayView extends StatelessWidget {
  const _TodayView();
  @override
  Widget build(BuildContext context) {
    final m = context.watch<TimerModel>();
    return Row(children: [
      Expanded(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(
            width: 330,
            height: 330,
            child: Stack(alignment: Alignment.center, children: [
              CustomPaint(size: const Size(330, 330), painter: _RingPainter(m.progress)),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(m.clock, style: const TextStyle(fontFamily: 'Georgia', fontFamilyFallback: ['Gentium Plus', 'serif'], fontSize: 78, fontWeight: FontWeight.w400, letterSpacing: -2)),
                Text(m.active?.title ?? 'All done for today', style: const TextStyle(color: _muted)),
              ]),
            ]),
          ),
          const SizedBox(height: 32),
          Row(mainAxisSize: MainAxisSize.min, children: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _violet, foregroundColor: const Color(0xFFF6F8F1), padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 18)),
              onPressed: m.toggle,
              child: Text(m.running ? 'Pause' : 'Start', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 14),
            OutlinedButton(onPressed: m.skip, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18)), child: const Text('Skip')),
          ]),
        ]),
      ),
      Container(
        width: 380,
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0x2214130F)))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("TODAY'S QUEUE", style: TextStyle(color: _muted, letterSpacing: 1.2, fontSize: 13)),
          const SizedBox(height: 16),
          for (final (i, t) in m.tasks.indexed)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: i == m.current ? Colors.transparent : Colors.transparent,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: i == m.current ? _violet : const Color(0x2214130F)),
              ),
              child: Row(children: [
                Icon(t.done ? Icons.check_circle : Icons.circle_outlined, size: 20, color: t.done ? _cyan : _muted),
                const SizedBox(width: 14),
                Expanded(child: Text(t.title, style: TextStyle(decoration: t.done ? TextDecoration.lineThrough : null))),
                Text('${t.minutes} min', style: const TextStyle(color: _muted, fontSize: 13)),
              ]),
            ),
          const _AddTask(),
        ]),
      ),
    ]);
  }
}

class _AddTask extends StatefulWidget {
  const _AddTask();
  @override
  State<_AddTask> createState() => _AddTaskState();
}

class _AddTaskState extends State<_AddTask> {
  final c = TextEditingController();
  @override
  Widget build(BuildContext context) => TextField(
        controller: c,
        decoration: InputDecoration(
          hintText: '+ Add a task (25 min)',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onSubmitted: (v) {
          context.read<TimerModel>().addTask(v, 25);
          c.clear();
        },
      );
}

class _StatsView extends StatelessWidget {
  const _StatsView();
  @override
  Widget build(BuildContext context) {
    final m = context.watch<TimerModel>();
    final h = m.totalMinutes ~/ 60, min = m.totalMinutes % 60;
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Your week', style: TextStyle(fontFamily: 'Georgia', fontFamilyFallback: ['Gentium Plus', 'serif'], fontSize: 38, fontWeight: FontWeight.w400, letterSpacing: -1)),
        const Text('Pulled from the Relay /focus/sessions endpoint', style: TextStyle(color: _muted)),
        const SizedBox(height: 28),
        Wrap(spacing: 18, runSpacing: 18, children: [
          _Stat('Focus time', '${h}h ${min}m'),
          _Stat('Sessions', '${m.history.length}'),
        ]),
        const SizedBox(height: 24),
        Expanded(
          child: ListView(children: [
            for (final s in m.history.reversed.take(12))
              ListTile(title: Text('${s['task']}'), trailing: Text('${s['minutes']} min', style: const TextStyle(color: _muted))),
          ]),
        ),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Container(
        width: 230,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x2214130F))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: _muted, fontSize: 13)),
          Text(value, style: const TextStyle(fontFamily: 'Georgia', fontFamilyFallback: ['Gentium Plus', 'serif'], fontSize: 42, fontWeight: FontWeight.w400)),
        ]),
      );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.p);
  final double p;
  @override
  void paint(Canvas canvas, Size s) {
    final rect = Rect.fromCircle(center: s.center(Offset.zero), radius: s.width / 2 - 14);
    final base = Paint()..style = PaintingStyle.stroke..strokeWidth = 4..color = const Color(0x2214130F);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
            ..color = _violet;
    canvas.drawArc(rect, 0, 2 * math.pi, false, base);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * p, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.p != p;
}
