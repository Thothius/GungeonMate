import 'dart:math' as math;
import 'package:flutter/material.dart';

// =============================================================================
// Synergy glow — CustomPainter border + soft outer glow.
//
// Q1 (genius audit v0.0.7): CustomPainter glowing borders around active
// synergy trackers for peripheral awareness. Replaces the previous
// flutter_animate Container-based approach (which rebuilt a Container
// widget every frame) with a direct canvas draw — no widget rebuilds,
// just a repaint of the isolated RepaintBoundary layer.
//
// Glow pattern: 2 draw calls (neon pattern from MUTATION_STATION):
//   1. Outer halo — thick stroke + MaskFilter.blur(BlurStyle.outer)
//   2. Crisp inner border — thin stroke, no blur
// The glow intensity breathes via the passed-in AnimationController.
//
// API is preserved: callers still pass controller, color, effectIndex,
// radius, showBgTint. The controller is now actually used (previously
// ignored in favour of a flutter_animate-internal controller).
// =============================================================================

/// Deterministic effect index per synergy name. Kept stable for any
/// downstream code that maps it to a colour or label.
int synergyEffectFor(String name) => name.hashCode.abs() % 10;

/// Returned for API compatibility.
Duration synergyEffectDuration(int idx) =>
    const Duration(milliseconds: 500);

/// Returned for API compatibility.
bool synergyEffectReverse(int idx) => false;

// =============================================================================
// SynergyGlowOverlay
// =============================================================================

/// Wraps [child] with a glowing, breathing synergy outline drawn by a
/// [CustomPainter]. The glow is wrapped in a [RepaintBoundary] so only
/// the border layer repaints on each animation tick — the child (and
/// the surrounding widget tree) is never invalidated.
///
/// [color] is the synergy's deterministic group colour. [controller]
/// drives the breathing pulse (callers set up a repeating reverse
/// controller, typically 1500ms). [effectIndex] is accepted for API
/// compatibility but does not change the visual. Use [showBgTint] for
/// list rows (a faint coloured wash behind the child for slightly more
/// presence in long lists).
class SynergyGlowOverlay extends StatelessWidget {
  final Widget child;
  final Color color;
  final AnimationController controller;
  final int effectIndex;
  final double radius;
  final bool showBgTint;

  const SynergyGlowOverlay({
    super.key,
    required this.child,
    required this.color,
    required this.controller,
    required this.effectIndex,
    this.radius = 8,
    this.showBgTint = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (showBgTint)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
            ),
          ),
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: controller,
                builder: (_, __) => CustomPaint(
                  painter: _SynergyBorderPainter(
                    color: color,
                    t: controller.value,
                    radius: radius,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _SynergyBorderPainter — 2-draw-call neon glow (MUTATION_STATION pattern)
// =============================================================================

class _SynergyBorderPainter extends CustomPainter {
  final Color color;
  final double t; // 0..1, reversing (from repeat(reverse: true) controller)
  final double radius;

  _SynergyBorderPainter({
    required this.color,
    required this.t,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Breathing intensity: 0..1 from controller, smoothed with a sin curve
    // for organic feel (MUTATION_STATION organicBreathing pattern, simplified
    // to single-oscillator since the controller already provides the timing).
    final pulse = 0.5 + 0.5 * math.sin(t * math.pi); // 0..1..0 smooth

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      Radius.circular(radius),
    );

    // Draw 1: outer halo — thick stroke + outer blur (the glow that extends
    // beyond the border). Alpha and blur radius breathe with the pulse.
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.12 + 0.22 * pulse)
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, 6 + 8 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRRect(rrect, glowPaint);

    // Draw 2: crisp inner border — thin stroke, no blur. The visible
    // border line itself. Alpha breathes so the border "lives".
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.40 + 0.35 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(_SynergyBorderPainter old) =>
      old.t != t || old.color != color || old.radius != radius;
}
