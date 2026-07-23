import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme_overlay.dart';

class CrimsonDrip extends StatefulWidget {
  const CrimsonDrip({super.key});
  @override
  State<CrimsonDrip> createState() => _CrimsonDripState();
}

class _CrimsonDripState extends State<CrimsonDrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
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
        animation: Listenable.merge([_c, ThemeOverlay.tiltNotifier]),
        builder: (_, __) => CustomPaint(
          painter: CrimsonDripPainter(t: _c.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class CrimsonDripPainter extends CustomPainter {
  final double t;
  CrimsonDripPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final double speed = 0.65 + i * 0.25;
      final double phase = i * 0.33;
      final double progress = (t * speed + phase) % 1.0;

      double yProg;
      double alpha;
      if (progress < 0.15) {
        yProg = (progress / 0.15) * 0.05;
        alpha = (progress / 0.15) * 0.75;
      } else if (progress < 0.85) {
        yProg = 0.05 + ((progress - 0.15) / 0.7) * 0.95;
        alpha = 0.75;
      } else {
        yProg = 1.0;
        alpha = 0.75 * (1.0 - (progress - 0.85) / 0.15);
      }

      final cy = size.height * yProg;
      final cx = size.width - 6.0 - (i * 12.0);

      paint.color = const Color(0xFF8B0000).withValues(alpha: alpha);
      canvas.drawCircle(Offset(cx, cy), 3.5, paint);

      if (progress > 0.15 && progress < 0.85) {
        paint.color = const Color(0xFF5A0000).withValues(alpha: alpha * 0.45);
        final tailH = 32.0;
        canvas.drawRect(Rect.fromLTWH(cx - 1.2, cy - tailH, 2.4, tailH), paint);
      }
    }

    final math.Random rng = math.Random(666);
    final tilt = ThemeOverlay.tiltNotifier.value;
    for (int i = 0; i < 15; i++) {
      final double speed = 0.4 + rng.nextDouble() * 0.5;
      final double phase = i / 15.0;
      final double progress = (t * speed + phase) % 1.0;

      final y = (size.height * (1.0 - progress) + tilt.dy * 15 * progress);
      final sway = math.sin(progress * 2 * math.pi + phase * 8) * 22;
      final tiltXShift = tilt.dx * 18 * progress;
      final x = ((i / 15.0) * size.width + sway + tiltXShift);
      final alpha = (1.0 - progress) * progress * 4.0 * 0.45;

      paint.color = const Color(0xFF1E0206).withValues(alpha: alpha);
      final double sizeVal = 2.0 + rng.nextDouble() * 3.0;
      canvas.drawCircle(Offset(x, y), sizeVal, paint);

      if (i % 2 == 0) {
        paint.color = const Color(0xFFFF2B3C).withValues(alpha: alpha * 0.85);
        canvas.drawCircle(Offset(x, y), sizeVal * 0.45, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CrimsonDripPainter old) => old.t != t;
}
