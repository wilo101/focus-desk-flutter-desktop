import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_desk/widgets/ring.dart';

void main() {
  testWidgets('DayBars draws one column per day', (t) async {
    final days = [for (var i = 0; i < 7; i++) MapEntry(DateTime(2026, 11, 19 + i), i * 10)];
    await t.pumpWidget(MaterialApp(home: Scaffold(body: DayBars(days: days, goal: 30))));
    expect(find.byType(Tooltip), findsNWidgets(7));
  });

  test('RingPainter repaints only on change', () {
    expect(RingPainter(0.5).shouldRepaint(RingPainter(0.5)), false);
    expect(RingPainter(0.5).shouldRepaint(RingPainter(0.6)), true);
  });
}
