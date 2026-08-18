import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A looping portal vortex animation for the home screen.
///
/// A bright purple-white glow orbits in a large circular path around the
/// screen center, traveling clockwise (right → top → left → bottom).
/// The glow pulses brighter and larger at the top and bottom of the
/// orbit, illuminating the deep purple background. A comet-like trail
/// of particles follows behind. 14-second cycle.
///
/// Reference: gungeonmate-animation-02.mp4
///
/// Purely decorative — wrapped in [IgnorePointer], no tap interactions.
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
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => CustomPaint(
                  painter: _PortalPainter(progress: _ctrl.value),
                ),
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
// Analysis of reference video (gungeonmate-animation-02.mp4):
//   - Background: deep purple (73,53,135) → near-black at edges
//   - Orbit: clockwise, center at (0.51, 0.52), radius ~38% of screen
//   - Glow color: purple-white (190,160,248)
//   - Pulse: brightest at top and bottom (|sin(angle)| peaks)
//   - Background illuminates when glow flashes
//   - Trail: comet-like particles behind the glow
//   - Cycle: 14 seconds
// =============================================================================

class _PortalPainter extends CustomPainter {
  final double progress;

  const _PortalPainter({required this.progress});

  // Colors extracted from reference video frames
  static const _bgCenter = Color(0xFF241537); // (73,53,135) deep purple
  static const _bgMid = Color(0xFF140A1F); // darker mid
  static const _bgEdge = Color(0xFF05030A); // near-black edges
  static const _glowCore = Color(0xFFBCA0F8); // (188,160,248) purple-white
  static const _glowBright = Color(0xFFF0E4FF); // bright core flash
  static const _glowHalo = Color(0xFF9D5CDB); // purple halo
  static const _trailColor = Color(0xFFD4A8FF); // trail particles

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.51, size.height * 0.52);
    final maxDim = math.max(size.width, size.height);

    // ── Angle: clockwise orbit ────────────────────────────────────
    // Start at right (3 o'clock), go clockwise: right → top → left → bottom
    // progress 0.0 = right, 0.25 = top, 0.5 = left, 0.75 = bottom
    final angle = progress * 2 * math.pi;

    // ── Pulse: brightest at top and bottom ────────────────────────
    // sin(angle) = 0 at sides (0, pi), 1 at top (pi/2), -1 at bottom (3pi/2)
    // |sin(angle)| = 0 at sides, 1 at top/bottom
    final pulse = math.sin(angle).abs();

    // ── Background: deep purple radial gradient ───────────────────
    // Background illuminates when glow pulses (up to ~40% brighter)
    final bgIllumination = pulse * 0.35;
    final bgCenterIllum = Color.lerp(_bgCenter, _glowHalo, bgIllumination * 0.3)!;

    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.85,
        colors: [
          bgCenterIllum,
          _bgMid,
          _bgEdge,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxDim * 0.7));
    canvas.drawRect(Offset.zero & size, bgPaint);

    // ── Faint vortex rings (subtle structure) ─────────────────────
    for (var i = 1; i <= 5; i++) {
      final ringRadius = maxDim * 0.12 * i;
      final ringAlpha = 0.06 + pulse * 0.04; // rings brighten slightly with pulse
      final ringPaint = Paint()
        ..color = _glowHalo.withValues(alpha: ringAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(center, ringRadius, ringPaint);
    }

    // ── Orbit parameters ──────────────────────────────────────────
    // Large orbit: ~38% of screen dimensions
    final orbitRadiusX = size.width * 0.38;
    final orbitRadiusY = size.height * 0.38;

    // Glow position: clockwise (sin for y is negative because screen y is down)
    // Clockwise: at angle=0 we're at right, angle=pi/2 at top
    // x = center + r * cos(angle)  (right at 0, left at pi)
    // y = center - r * sin(angle)  (top at pi/2, bottom at 3pi/2)
    final glowX = center.dx + orbitRadiusX * math.cos(angle);
    final glowY = center.dy - orbitRadiusY * math.sin(angle);
    final glowPos = Offset(glowX, glowY);

    // ── Glow size: expands at flash points (top/bottom) ───────────
    // Base radius + pulse expansion
    final glowRadius = (maxDim * 0.04) + (maxDim * 0.06) * pulse;

    // ── Glow brightness: 0.35 at sides, 1.0 at top/bottom ─────────
    final glowAlpha = 0.35 + 0.65 * pulse;

    // ── Background illumination glow (light up the area near the glow) ──
    // When the glow pulses, it illuminates a large area of the background
    final illumRadius = glowRadius * 4 * (0.5 + pulse * 0.5);
    final illumPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        colors: [
          _glowHalo.withValues(alpha: glowAlpha * 0.15),
          _glowHalo.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: glowPos, radius: illumRadius));
    canvas.drawCircle(glowPos, illumRadius, illumPaint);

    // ── Trailing particles behind the glow ────────────────────────
    // Comet-like trail: 12 particles trailing behind in the orbit path
    for (var t = 1; t <= 12; t++) {
      final trailAngle = angle - (t * 0.06);
      final trailX = center.dx + orbitRadiusX * math.cos(trailAngle);
      final trailY = center.dy - orbitRadiusY * math.sin(trailAngle);
      final trailPos = Offset(trailX, trailY);

      // Trail fades and shrinks with distance from glow
      final trailFade = (1.0 - t / 12);
      final trailAlpha = glowAlpha * trailFade * 0.35;
      final trailRadius = glowRadius * trailFade * 0.12;

      final trailPaint = Paint()
        ..color = _trailColor.withValues(alpha: trailAlpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0);
      canvas.drawCircle(trailPos, trailRadius, trailPaint);
    }

    // ── Outer glow halo (large, soft) ─────────────────────────────
    final haloRadius = glowRadius * 3.0;
    final haloPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        colors: [
          _glowCore.withValues(alpha: glowAlpha * 0.5),
          _glowHalo.withValues(alpha: glowAlpha * 0.25),
          _glowHalo.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.3, 1.0],
      ).createShader(Rect.fromCircle(center: glowPos, radius: haloRadius));
    canvas.drawCircle(glowPos, haloRadius, haloPaint);

    // ── Inner bright core ────────────────────────────────────────
    // At flash points, the core becomes near-white
    final coreColor = Color.lerp(_glowCore, _glowBright, pulse)!;
    final corePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        colors: [
          coreColor.withValues(alpha: glowAlpha),
          _glowCore.withValues(alpha: glowAlpha * 0.7),
          _glowHalo.withValues(alpha: glowAlpha * 0.3),
          _glowHalo.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.2, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: glowPos, radius: glowRadius));
    canvas.drawCircle(glowPos, glowRadius, corePaint);

    // ── Bright white center (only at flash peaks) ─────────────────
    if (pulse > 0.7) {
      final whiteAlpha = (pulse - 0.7) / 0.3 * glowAlpha;
      final whitePaint = Paint()
        ..color = _glowBright.withValues(alpha: whiteAlpha * 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      canvas.drawCircle(glowPos, glowRadius * 0.3, whitePaint);
    }
  }

  @override
  bool shouldRepaint(_PortalPainter old) => old.progress != progress;
}
