import 'package:flutter/material.dart';

class WaveVisualizer extends CustomPainter {
  final List<double> fftData;
  final Color color;

  WaveVisualizer({
    required this.fftData,
    this.color = const Color(0xFF00FFCC),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fftData.isEmpty) return;

    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10); // Glow effect

    final Path path = Path();
    final double step = size.width / fftData.length;

    path.moveTo(0, size.height);

    // Draw smooth curve
    for (int i = 0; i < fftData.length - 1; i++) {
      final double x1 = i * step;
      final double y1 = size.height - (fftData[i] * size.height * 0.8);
      final double x2 = (i + 1) * step;
      final double y2 = size.height - (fftData[i + 1] * size.height * 0.8);

      final double controlX = (x1 + x2) / 2;
      final double controlY = (y1 + y2) / 2;

      if (i == 0) {
        path.lineTo(x1, y1);
      }
      path.quadraticBezierTo(x1, y1, controlX, controlY);
    }

    path.lineTo(size.width, size.height);
    path.close();

    // Draw gradient fill
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withValues(alpha: 0.8),
        color.withValues(alpha: 0.1),
      ],
    ).createShader(rect);

    canvas.drawPath(path, paint);

    // Draw a second, slightly offset wave for depth
    final Path path2 = Path();
    path2.moveTo(0, size.height);
     for (int i = 0; i < fftData.length - 1; i++) {
      // Use a different offset for the second wave
      final double x1 = i * step;
      final double y1 = size.height - (fftData[i] * size.height * 0.5); // Lower amplitude
      final double x2 = (i + 1) * step;
      final double y2 = size.height - (fftData[i + 1] * size.height * 0.5);

      final double controlX = (x1 + x2) / 2;
      final double controlY = (y1 + y2) / 2;

      if (i == 0) {
        path2.lineTo(x1, y1);
      }
      path2.quadraticBezierTo(x1, y1, controlX, controlY);
    }
    path2.lineTo(size.width, size.height);
    path2.close();

     final Paint paint2 = Paint()
      ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.purpleAccent.withValues(alpha: 0.5),
        Colors.purpleAccent.withValues(alpha: 0.0),
      ],
    ).createShader(rect);
    
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
