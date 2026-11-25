import 'package:flutter_test/flutter_test.dart';
import 'package:focus_desk/models/models.dart';

void main() {
  test('task json round trip', () {
    final t = FocusTask(id: 3, title: 'Write', minutes: 45, tag: 'work', done: true);
    final b = FocusTask.fromJson(t.toJson());
    expect((b.id, b.title, b.minutes, b.tag, b.done), (3, 'Write', 45, 'work', true));
  });

  test('session list round trip keeps synced flag', () {
    final l = [Session(task: 'a', minutes: 25, at: DateTime(2026, 1, 2, 3, 4)), Session(task: 'b', minutes: 5, at: DateTime(2026, 1, 3), synced: true)];
    final back = Session.decodeList(Session.encodeList(l));
    expect(back.length, 2);
    expect(back[0].synced, false);
    expect(back[1].synced, true);
    expect(back[0].at, DateTime(2026, 1, 2, 3, 4));
  });

  test('decodeList of null is empty', () => expect(Session.decodeList(null), isEmpty));

  test('markSynced keeps the rest', () {
    final s = Session(task: 'a', minutes: 25, at: DateTime(2026), tag: 'x').markSynced();
    expect((s.synced, s.tag, s.minutes), (true, 'x', 25));
  });

  test('settings defaults and copyWith', () {
    const s = Settings();
    expect(s.focusMinutes, 25);
    final c = s.copyWith(focusMinutes: 50, notifications: false);
    expect((c.focusMinutes, c.notifications, c.shortBreak), (50, false, 5));
  });

  test('settings json round trip and missing keys fall back', () {
    final s = const Settings().copyWith(longBreakEvery: 3, relayUrl: 'http://x');
    final b = Settings.fromJson(s.toJson());
    expect((b.longBreakEvery, b.relayUrl), (3, 'http://x'));
    expect(Settings.fromJson({}).dailyGoalMinutes, 120);
  });
}
