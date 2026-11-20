import 'package:flutter/material.dart';

class TouchParticle {
  Offset pos;
  Offset vel;
  Color color;
  double size;
  double life;

  /// When true this particle is an expanding sonar ring instead of a
  /// drifting diamond — [maxRadius] is the final ring radius and
  /// [decay] controls how quickly [life] burns down.
  final bool ring;
  final double maxRadius;
  final double decay;

  TouchParticle({
    required this.pos,
    required this.vel,
    required this.color,
    required this.size,
    this.life = 1.0,
    this.ring = false,
    this.maxRadius = 0,
    this.decay = 0.08,
  });
}

class TouchParticlePainter extends CustomPainter {
  final List<TouchParticle> particles;
  TouchParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      if (p.life <= 0) continue;
      paint.color = p.color.withValues(alpha: p.life);

      if (p.ring) {
        // Expanding ring — radius grows as life decays, stroke thins
        // out so the pulse reads as energy dissipating, not a drawing.
        final t = 1.0 - p.life; // 0→1 expansion progress
        final r = 6.0 + (p.maxRadius - 6.0) * t;
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = (2.6 * p.life + 0.4).clamp(0.4, 3.0)
          ..strokeCap = StrokeCap.round;
        canvas.drawCircle(p.pos, r, paint);
        paint.style = PaintingStyle.fill;
        continue;
      }

      final path = Path();
      final hs = p.size * p.life;
      path.moveTo(p.pos.dx, p.pos.dy - hs);
      path.lineTo(p.pos.dx + hs, p.pos.dy);
      path.lineTo(p.pos.dx, p.pos.dy + hs);
      path.lineTo(p.pos.dx - hs, p.pos.dy);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(TouchParticlePainter old) => true;
}
