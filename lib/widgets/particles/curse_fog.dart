import 'dart:math' as math;
import 'package:flutter/material.dart';

class CurseFog extends StatefulWidget {
  const CurseFog({super.key});
  @override
  State<CurseFog> createState() => _CurseFogState();
}

class _CurseFogState extends State<CurseFog> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = _c.value;
          return CustomPaint(
            painter: CurseFogPainter(t: t),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class CurseFogPainter extends CustomPainter {
  final double t;
  CurseFogPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final centers = [
      Offset(
        size.width * (0.2 + math.sin(t * 2 * math.pi) * 0.15),
        size.height * (0.3 + math.cos(t * 2 * math.pi) * 0.1),
      ),
      Offset(
        size.width * (0.8 - math.cos(t * 2 * math.pi) * 0.15),
        size.height * (0.7 + math.sin(t * 2 * math.pi) * 0.15),
      ),
      Offset(
        size.width * (0.5 + math.sin(t * 2 * math.pi * 1.5) * 0.2),
        size.height * (0.45 - math.cos(t * 2 * math.pi * 1.5) * 0.12),
      ),
    ];

    final colors = [
      const Color(0x1B6A0D7B),
      const Color(0x223E0054),
      const Color(0x184A0E4E),
    ];

    final radii = [
      size.width * 0.45,
      size.width * 0.5,
      size.width * 0.4,
    ];

    for (int i = 0; i < centers.length; i++) {
      paint.shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [colors[i], colors[i].withValues(alpha: 0.0)],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: centers[i], radius: radii[i]));
      canvas.drawCircle(centers[i], radii[i], paint);
    }
    paint.shader = null;
  }

  @override
  bool shouldRepaint(CurseFogPainter old) => old.t != t;
}
