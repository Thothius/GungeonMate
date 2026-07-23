import 'package:flutter/material.dart';

class TouchParticle {
  Offset pos;
  Offset vel;
  Color color;
  double size;
  double life = 1.0;
  TouchParticle({
    required this.pos,
    required this.vel,
    required this.color,
    required this.size,
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
