import 'package:flutter/material.dart';

class CurseBreath extends StatefulWidget {
  const CurseBreath({super.key});
  @override
  State<CurseBreath> createState() => _CurseBreathState();
}

class _CurseBreathState extends State<CurseBreath>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat(reverse: true);
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
        final t = _c.value;
        final tri = t < 0.5 ? t * 2 : (1 - t) * 2;
        final alpha = 0.12 + 0.15 * tri;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.1,
              colors: [
                Colors.black.withValues(alpha: 0.65),
                const Color(0xFF0C0204).withValues(alpha: alpha * 0.55),
                const Color(0xFF42050E).withValues(alpha: alpha * 0.95),
              ],
              stops: const [0.35, 0.72, 1.0],
            ),
          ),
        );
      },
    );
  }
}
