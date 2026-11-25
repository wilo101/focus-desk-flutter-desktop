import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

class RingPainter extends CustomPainter {
  RingPainter(this.progress, {this.color = ink});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final rect = Rect.fromCircle(center: s.center(Offset.zero), radius: s.width / 2 - 14);
    final base = Paint()..style = PaintingStyle.stroke..strokeWidth = 4..color = hairline;
    final arc = Paint()..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.round..color = color;
    canvas.drawArc(rect, 0, 2 * math.pi, false, base);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress.clamp(0.0, 1.0), false, arc);
  }

  @override
  bool shouldRepaint(RingPainter old) => old.progress != progress || old.color != color;
}

/// Bars for the last days. The tallest bar is the best day; a dashed goal line marks the daily goal.
class DayBars extends StatelessWidget {
  const DayBars({super.key, required this.days, required this.goal, this.height = 160});
  final List<MapEntry<DateTime, int>> days;
  final int goal;
  final double height;

  static const _names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final max = [goal, ...days.map((d) => d.value)].reduce((a, b) => a > b ? a : b).clamp(1, 100000);
    return SizedBox(
      height: height + 24,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final d in days)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Tooltip(
                  message: '${d.key.month}/${d.key.day}: ${d.value} min',
                  child: Container(height: height * d.value / max, color: d.value >= goal ? forest : ink.withOpacity(0.75)),
                ),
                const SizedBox(height: 6),
                Text(_names[d.key.weekday - 1], style: const TextStyle(color: muted, fontSize: 12)),
              ]),
            ),
          ),
      ]),
    );
  }
}
