import 'package:flutter_test/flutter_test.dart';
import 'package:focus_desk/models/models.dart';
import 'package:focus_desk/state/timer_model.dart';
import 'helpers.dart';

void main() {
  final fixed = DateTime(2026, 11, 25, 10);

  test('starts empty with a default clock', () async {
    final (m, _, _) = await makeModel(clock: () => fixed);
    expect(m.active, isNull);
    expect(m.clock, '25:00');
    m.toggle();
    expect(m.running, false);
  });

  test('addTask ignores blanks and trims', () async {
    final (m, _, _) = await makeModel(clock: () => fixed);
    m.addTask('   ', 25);
    m.addTask('x', 0);
    m.addTask('  Write  ', 30, tag: ' Work ');
    expect(m.tasks.length, 1);
    expect(m.tasks.single.title, 'Write');
    expect(m.tasks.single.tag, 'work');
    expect(m.clock, '30:00');
  });

  test('finishing a block logs a session, marks the task done and syncs', () async {
    final (m, relay, n) = await makeModel(clock: () => fixed);
    m.addTask('Deep work', 1, tag: 'work');
    runBlock(m);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(m.sessions.length, 1);
    expect(m.tasks.single.done, true);
    expect(m.phase, Phase.shortBreak);
    expect(relay.posted.single['task'], 'Deep work');
    expect(m.pendingSync, 0);
    expect(n.shown.single.$1, 'Focus block done');
  });

  test('offline sessions are queued and flushed later', () async {
    final (m, relay, _) = await makeModel(clock: () => fixed);
    relay.online = false;
    m.addTask('a', 1);
    runBlock(m);
    await Future<void>.delayed(Duration.zero);
    expect(m.pendingSync, 1);
    expect(m.synced, false);
    relay.online = true;
    await m.flushSync();
    expect(m.pendingSync, 0);
    expect(m.synced, true);
    expect(relay.posted.length, 1);
  });

  test('every Nth block is followed by a long break', () async {
    final (m, _, _) = await makeModel(clock: () => fixed);
    await m.updateSettings(m.settings.copyWith(longBreakEvery: 2, autoStartBreaks: false));
    for (final n in ['a', 'b']) {
      m.addTask(n, 1);
    }
    runBlock(m);
    await Future<void>.delayed(Duration.zero);
    expect(m.phase, Phase.shortBreak);
    m.skip();
    expect(m.phase, Phase.focus);
    runBlock(m);
    await Future<void>.delayed(Duration.zero);
    expect(m.phase, Phase.longBreak);
    expect(m.clock, '15:00');
  });

  test('notifications can be turned off', () async {
    final (m, _, n) = await makeModel(clock: () => fixed);
    await m.updateSettings(m.settings.copyWith(notifications: false, autoStartBreaks: false));
    m.addTask('a', 1);
    runBlock(m);
    await Future<void>.delayed(Duration.zero);
    expect(n.shown, isEmpty);
  });

  test('skip moves the active task to the end and logs nothing', () async {
    final (m, _, _) = await makeModel(clock: () => fixed);
    m.addTask('a', 25);
    m.addTask('b', 25);
    m.skip();
    expect(m.active!.title, 'b');
    expect(m.sessions, isEmpty);
  });

  test('reorder changes the queue and keeps done tasks last', () async {
    final (m, _, _) = await makeModel(clock: () => fixed);
    for (final n in ['a', 'b', 'c']) {
      m.addTask(n, 10);
    }
    m.tasks[0].done = true;
    m.reorder(1, 0); // open is [b, c]; move c to the front
    expect(m.tasks.map((t) => t.title), ['c', 'b', 'a']);
  });

  test('removeTask and clearDone', () async {
    final (m, _, _) = await makeModel(clock: () => fixed);
    m.addTask('a', 10);
    m.addTask('b', 10);
    m.removeTask(m.tasks.first.id);
    expect(m.tasks.single.title, 'b');
    m.tasks.single.done = true;
    m.clearDone();
    expect(m.tasks, isEmpty);
  });

  test('settings change the timer length and persist', () async {
    final (m, _, _) = await makeModel(clock: () => fixed);
    m.addTask('a', 25);
    await m.updateSettings(m.settings.copyWith(shortBreak: 7));
    expect(m.storage.loadSettings().shortBreak, 7);
  });

  test('state survives a restart', () async {
    final (m, _, _) = await makeModel(clock: () => fixed);
    m.addTask('keep me', 20);
    final again = TimerModel(storage: m.storage, sync: m.sync, clock: () => fixed);
    expect(again.tasks.single.title, 'keep me');
  });

  test('stats come from the saved sessions', () async {
    final (m, _, _) = await makeModel(clock: () => fixed);
    m.sessions.add(Session(task: 'x', minutes: 40, at: fixed));
    expect(m.stats.todayMinutes, 40);
    expect(m.stats.streak, 1);
  });
}
