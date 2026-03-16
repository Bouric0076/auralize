import 'package:flutter/material.dart';

class BarVisualizer extends CustomPainter {
  final List<double> fftData;

  BarVisualizer({required this.fftData});

  @override
  void paint(Canvas canvas, Size size) {
    const int barCount = 64;
    final double barWidth = (size.width / barCount) - 2;
    final Paint paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < barCount; i++) {
      final double magnitude = fftData[i];
      final double barHeight = magnitude * size.height;
      final double x = i * (barWidth + 2);
      final double y = size.height - barHeight;

      paint.color = Color.lerp(
        const Color(0xFF1A1AFF).withValues(alpha: 0.7),
        const Color(0xFFFF2D9B).withValues(alpha: 0.95),
        magnitude,
      )!;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(4),
        ),
        paint,
      );

      if (barHeight > 4) {
        paint.color = Colors.white.withValues(alpha: magnitude * 0.8);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, barWidth, 3),
            const Radius.circular(2),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(BarVisualizer old) => true;
}