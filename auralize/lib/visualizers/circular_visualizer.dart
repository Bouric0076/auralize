import 'dart:math';
import 'package:flutter/material.dart';

class CircularVisualizer extends CustomPainter {
  final List<double> fftData;

  CircularVisualizer({required this.fftData});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width * 0.28;
    const int barCount = 128;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.05)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    for (int i = 0; i < barCount; i++) {
      final double magnitude = fftData[i % fftData.length];
      final double angle = (i / barCount) * 2 * pi - pi / 2;
      final double barLength = magnitude * size.width * 0.18;

      final Offset start = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      final Offset end = Offset(
        center.dx + (radius + barLength) * cos(angle),
        center.dy + (radius + barLength) * sin(angle),
      );

      paint.color = Color.lerp(
        const Color(0xFF00FFCC).withValues(alpha: 0.6),
        const Color(0xFFFF00FF).withValues(alpha: 0.95),
        magnitude,
      )!;

      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(CircularVisualizer old) => true;
}