import 'dart:math' as math;
import 'package:flutter/material.dart';

class AmbientGlow extends StatefulWidget {
  final Color primary;
  final Color secondary;
  const AmbientGlow({
    super.key,
    required this.primary,
    required this.secondary,
  });

  @override
  State<AmbientGlow> createState() => _AmbientGlowState();
}

class _AmbientGlowState extends State<AmbientGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value * 2 * math.pi;
        final pulse = 0.88 + 0.12 * math.sin(t * 2);

        final cx = 0.5 + 0.28 * math.cos(t);
        final cy = 0.5 + 0.20 * math.sin(t);

        final pColor = widget.primary.withValues(alpha: (widget.primary.a * 1.55).clamp(0.0, 0.95));
        final sColor = widget.secondary.withValues(alpha: (widget.secondary.a * 1.55).clamp(0.0, 0.95));

        return Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(cx * 2 - 1, cy * 2 - 1),
                    radius: 1.0 * pulse,
                    colors: [
                      pColor,
                      sColor,
                      const Color(0x00000000),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-(cx * 2 - 1), -(cy * 2 - 1)),
                    radius: 1.15 * pulse,
                    colors: [
                      sColor,
                      const Color(0x00000000),
                    ],
                    stops: const [0.0, 0.75],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
