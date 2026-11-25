import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/stats_calc.dart';
import '../state/timer_model.dart';
import '../theme.dart';
import '../widgets/ring.dart';

class TodayView extends StatelessWidget {
  const TodayView({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.watch<TimerModel>();
    final onBreak = m.phase != Phase.focus;
    final goal = m.stats.goalProgress(m.settings.dailyGoalMinutes);
    return Row(children: [
      Expanded(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(onBreak ? 'BREAK' : 'FOCUS', style: const TextStyle(color: muted, letterSpacing: 2, fontSize: 12)),
          const SizedBox(height: 12),
          SizedBox(
            width: 330,
            height: 330,
            child: Stack(alignment: Alignment.center, children: [
              CustomPaint(size: const Size(330, 330), painter: RingPainter(m.progress, color: onBreak ? forest : ink)),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(m.clock, style: serif.copyWith(fontSize: 78, letterSpacing: -2)),
                Text(m.label, style: const TextStyle(color: muted)),
              ]),
            ]),
          ),
          const SizedBox(height: 28),
          Row(mainAxisSize: MainAxisSize.min, children: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: ink, shape: const RoundedRectangleBorder(), padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 18)),
              onPressed: m.toggle,
              child: Text(m.running ? 'Pause' : 'Start'),
            ),
            const SizedBox(width: 14),
            OutlinedButton(
              style: OutlinedButton.styleFrom(shape: const RoundedRectangleBorder(), padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18)),
              onPressed: m.skip,
              child: Text(onBreak ? 'Skip break' : 'Skip'),
            ),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            width: 330,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Daily goal: ${StatsCalc.hm(m.stats.todayMinutes)} of ${StatsCalc.hm(m.settings.dailyGoalMinutes)}', style: const TextStyle(fontSize: 13, color: muted)),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: goal, minHeight: 4, color: goal >= 1 ? forest : ink, backgroundColor: hairline),
            ]),
          ),
        ]),
      ),
      Container(
        width: 390,
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(border: Border(left: BorderSide(color: hairline))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text("TODAY'S QUEUE", style: TextStyle(color: muted, letterSpacing: 1.2, fontSize: 13))),
            if (m.tasks.any((t) => t.done)) TextButton(onPressed: m.clearDone, child: const Text('Clear done')),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: m.open.isEmpty && m.tasks.every((t) => !t.done)
                ? const Center(child: Text('No tasks yet. Add one below.', style: TextStyle(color: muted)))
                : ListView(children: [
                    ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: true,
                      onReorder: m.reorder,
                      children: [
                        for (final (i, t) in m.open.indexed)
                          Container(
                            key: ValueKey(t.id),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                            decoration: BoxDecoration(border: Border.all(color: i == 0 ? ink : hairline)),
                            child: Row(children: [
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(t.title),
                                  if (t.tag.isNotEmpty) Text(t.tag, style: const TextStyle(color: forest, fontSize: 12)),
                                ]),
                              ),
                              Text('${t.minutes} min', style: const TextStyle(color: muted, fontSize: 13)),
                              IconButton(tooltip: 'Remove', icon: const Icon(Icons.close, size: 18), onPressed: () => m.removeTask(t.id)),
                            ]),
                          ),
                      ],
                    ),
                    for (final t in m.tasks.where((t) => t.done))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        child: Row(children: [
                          const Icon(Icons.check_circle, size: 18, color: forest),
                          const SizedBox(width: 12),
                          Expanded(child: Text(t.title, style: const TextStyle(decoration: TextDecoration.lineThrough, color: muted))),
                        ]),
                      ),
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
  final title = TextEditingController();
  final tag = TextEditingController();
  int minutes = 25;

  @override
  void dispose() {
    title.dispose();
    tag.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<TimerModel>().addTask(title.text, minutes, tag: tag.text);
    title.clear();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        TextField(controller: title, decoration: const InputDecoration(hintText: '+ Add a task'), onSubmitted: (_) => _submit()),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: tag, decoration: const InputDecoration(hintText: 'tag (optional)'))),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: minutes,
            underline: const SizedBox.shrink(),
            items: [for (final n in const [15, 25, 45, 50, 90]) DropdownMenuItem(value: n, child: Text('$n min'))],
            onChanged: (v) => setState(() => minutes = v ?? 25),
          ),
          IconButton(tooltip: 'Add', icon: const Icon(Icons.add), onPressed: _submit),
        ]),
      ]);
}
