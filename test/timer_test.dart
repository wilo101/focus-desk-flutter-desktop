import 'package:flutter_test/flutter_test.dart';
import 'package:focus_desk/timer_model.dart';

void main() {
  test('clock formats remaining time and skip advances the queue', () {
    final m = TimerModel();
    expect(m.clock, '25:00');
    m.skip();
    expect(m.current, 1);
    expect(m.clock, '25:00');
    m.addTask('Extra', 10);
    expect(m.tasks.length, 4);
  });
}
