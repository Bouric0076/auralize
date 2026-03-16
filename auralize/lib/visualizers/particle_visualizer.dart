import 'dart:math';
import 'package:flutter/material.dart';

class Particle {
  Offset position;
  Offset velocity;
  double radius;
  double life;
  Color color;

  Particle({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.color,
  }) : life = 1.0;

  void update() {
    position += velocity;
    velocity *= 0.96;
    life -= 0.018;
    radius *= 0.97;
  }

  bool get isDead => life <= 0 || radius < 0.3;
}

class ParticleVisualizer extends CustomPainter {
  final List<double> fftData;
  final List<Particle> particles;
  final bool beatDetected;
  final Random _random = Random();

  ParticleVisualizer({
    required this.fftData,
    required this.particles,
    required this.beatDetected,
  });

  void spawnParticles(Size size) {
    if (beatDetected) {
      final Offset center = Offset(size.width / 2, size.height / 2);
      for (int i = 0; i < 12; i++) {
        final double angle = _random.nextDouble() * 2 * pi;
        final double speed = 3 + _random.nextDouble() * 5;
        particles.add(Particle(
          position: center,
          velocity: Offset(cos(angle) * speed, sin(angle) * speed),
          radius: 4 + _random.nextDouble() * 6,
          color: Color.lerp(
            const Color(0xFFFF2D9B),
            const Color(0xFF00FFCC),
            _random.nextDouble(),
          )!,
        ));
      }
    }

    for (int i = 0; i < 4; i++) {
      final double band = fftData[(i * 16) % 256];
      if (band > 0.15) {
        final double x = (i / 4) * size.width + _random.nextDouble() * 80;
        particles.add(Particle(
          position: Offset(x, size.height),
          velocity: Offset(
            (_random.nextDouble() - 0.5) * 2,
            -(2 + band * 6),
          ),
          radius: 2 + band * 5,
          color: Color.lerp(
            const Color(0xFF7B2FFF),
            const Color(0xFFFF9500),
            band,
          )!,
        ));
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    spawnParticles(size);

    final Paint paint = Paint()..style = PaintingStyle.fill;

    for (final Particle p in particles) {
      p.update();
      if (!p.isDead) {
        paint.color = p.color.withValues(alpha: p.life * 0.85);
        canvas.drawCircle(p.position, p.radius, paint);
      }
    }

    particles.removeWhere((p) => p.isDead);
  }

  @override
  bool shouldRepaint(ParticleVisualizer old) => true;
}