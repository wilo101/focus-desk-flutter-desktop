import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focus_desk/models/models.dart';
import 'package:focus_desk/services/storage.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('empty storage gives defaults', () async {
    final s = await Storage.open();
    expect(s.loadTasks(), isEmpty);
    expect(s.loadSessions(), isEmpty);
    expect(s.loadSettings().focusMinutes, 25);
  });

  test('tasks, sessions and settings persist', () async {
    final s = await Storage.open();
    await s.saveTasks([FocusTask(id: 1, title: 'a', minutes: 10)]);
    await s.saveSessions([Session(task: 'a', minutes: 10, at: DateTime(2026))]);
    await s.saveSettings(const Settings(dailyGoalMinutes: 90));
    final again = await Storage.open();
    expect(again.loadTasks().single.title, 'a');
    expect(again.loadSessions().single.minutes, 10);
    expect(again.loadSettings().dailyGoalMinutes, 90);
  });

  test('task ids increase', () async {
    final s = await Storage.open();
    expect([s.nextTaskId(), s.nextTaskId(), s.nextTaskId()], [1, 2, 3]);
  });

  test('session log is capped at 2000', () async {
    final s = await Storage.open();
    await s.saveSessions([for (var i = 0; i < 2100; i++) Session(task: '$i', minutes: 1, at: DateTime(2026))]);
    final l = s.loadSessions();
    expect(l.length, 2000);
    expect(l.last.task, '2099');
  });
}
