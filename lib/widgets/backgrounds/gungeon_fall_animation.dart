import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A looping portal vortex animation for the home screen.
///
/// A bright glow orbits in a circular path around the center of the
/// screen, pulsing brighter at the top and bottom of its orbit. Deep
/// purple background, ~14 second cycle. Purely decorative — wrapped
/// in [IgnorePointer], no tap interactions.
///
/// Reference: gungeonmate-animation-02.mp4
class GungeonFallAnimation extends StatefulWidget {
  final Widget child;

  const GungeonFallAnimation({super.key, required this.child});

  @override
  State<GungeonFallAnimation> createState() => _GungeonFallAnimationState();
}

class _GungeonFallAnimationState extends State<GungeonFallAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Portal vortex ──────────────────────────────────────────
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => CustomPaint(
                painter: _PortalPainter(progress: _ctrl.value),
              ),
            ),
          ),
        ),
        // ── Main menu content ──────────────────────────────────────
        widget.child,
      ],
    );
  }
}

// =============================================================================
// _PortalPainter — orbiting glow on deep purple vortex background
//
// The glow travels in a circular orbit around the screen center.
// It pulses brighter and larger at the top and bottom of the orbit
// (vertical extremes), dimmer and smaller at the sides.
//
// Orbit: counter-clockwise (right → top → left → bottom → right)
// Cycle: 14 seconds
// =============================================================================

class _PortalPainter extends CustomPainter {
  final double progress;

  const _PortalPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxDim = math.max(size.width, size.height);

    // ── Background: deep purple radial gradient ───────────────────
    // Darker at edges, slightly lighter at center (the "portal")
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [
          const Color(0xFF1A0D2E), // deep purple center
          const Color(0xFF0D0719), // darker mid
          const Color(0xFF05030A), // near-black edges
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxDim * 0.7));
    canvas.drawRect(Offset.zero & size, bgPaint);

    // ── Faint vortex rings (subtle structure) ─────────────────────
    for (var i = 1; i <= 4; i++) {
      final ringRadius = maxDim * 0.15 * i;
      final ringPaint = Paint()
        ..color = const Color(0xFF4A2C6E).withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(center, ringRadius, ringPaint);
    }

    // ── Orbiting glow ─────────────────────────────────────────────
    // The glow travels in a circle around the center.
    // Angle: 0 = right, pi/2 = top, pi = left, 3pi/2 = bottom
    // We start at the right side and go counter-clockwise (upward first)
    final angle = progress * 2 * math.pi;

    // Orbit radii — slightly elliptical, centered on screen
    final orbitRadiusX = size.width * 0.22;
    final orbitRadiusY = size.height * 0.22;

    // Glow position on the orbit
    final glowX = center.dx + orbitRadiusX * math.cos(angle);
    final glowY = center.dy - orbitRadiusY * math.sin(angle); // negative because screen y is down
    final glowPos = Offset(glowX, glowY);

    // Pulse intensity: brightest at top and bottom (|sin(angle)|)
    // sin(angle) = 1 at top (pi/2), -1 at bottom (3pi/2), 0 at sides
    final pulse = math.sin(angle).abs(); // 0 at sides, 1 at top/bottom

    // Glow size: expands at flash points (top/bottom), contracts at sides
    final glowRadius = (maxDim * 0.06) + (maxDim * 0.08) * pulse;

    // Glow brightness: 0.4 at sides, 1.0 at top/bottom
    final glowAlpha = 0.4 + 0.6 * pulse;

    // ── Outer glow halo (large, soft) ─────────────────────────────
    final haloPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        colors: [
          const Color(0xFFE0B0FF).withValues(alpha: glowAlpha * 0.6),
          const Color(0xFF9D5CDB).withValues(alpha: glowAlpha * 0.3),
          const Color(0xFF6A3BAB).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.3, 1.0],
      ).createShader(Rect.fromCircle(center: glowPos, radius: glowRadius * 2.5));
    canvas.drawCircle(glowPos, glowRadius * 2.5, haloPaint);

    // ── Inner bright core ────────────────────────────────────────
    final corePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        colors: [
          const Color(0xFFFFFFFF).withValues(alpha: glowAlpha),
          const Color(0xFFF0D0FF).withValues(alpha: glowAlpha * 0.8),
          const Color(0xFFB388E0).withValues(alpha: glowAlpha * 0.4),
          const Color(0xFF7A4DBE).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.2, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: glowPos, radius: glowRadius));
    canvas.drawCircle(glowPos, glowRadius, corePaint);

    // ── Trailing particles behind the glow ────────────────────────
    // Small dots that trail behind the orbiting glow
    for (var t = 1; t <= 8; t++) {
      final trailAngle = angle - (t * 0.08);
      final trailX = center.dx + orbitRadiusX * math.cos(trailAngle);
      final trailY = center.dy - orbitRadiusY * math.sin(trailAngle);
      final trailPos = Offset(trailX, trailY);
      final trailAlpha = glowAlpha * (1.0 - t / 8) * 0.3;
      final trailRadius = glowRadius * (1.0 - t / 10) * 0.15;

      final trailPaint = Paint()
        ..color = const Color(0xFFD4A8FF).withValues(alpha: trailAlpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0);
      canvas.drawCircle(trailPos, trailRadius, trailPaint);
    }
  }

  @override
  bool shouldRepaint(_PortalPainter old) => old.progress != progress;
}
