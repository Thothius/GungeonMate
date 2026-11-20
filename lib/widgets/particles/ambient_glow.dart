import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/app_theme.dart';

class AmbientGlow extends StatefulWidget {
  final Color primary;
  final Color secondary;
  final Color? tertiary;
  final GlowStyle style;
  const AmbientGlow({
    super.key,
    required this.primary,
    required this.secondary,
    this.tertiary,
    this.style = GlowStyle.orbit,
  });

  @override
  State<AmbientGlow> createState() => _AmbientGlowState();
}

class _AmbientGlowState extends State<AmbientGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  static const _durations = <GlowStyle, Duration>{
    GlowStyle.orbit: Duration(seconds: 14),
    GlowStyle.ember: Duration(seconds: 6),
    GlowStyle.halo: Duration(seconds: 20),
    GlowStyle.drip: Duration(seconds: 12),
    GlowStyle.prism: Duration(seconds: 18),
    GlowStyle.ripple: Duration(seconds: 9),
  };

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: _durations[widget.style] ?? const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void didUpdateWidget(AmbientGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.style != widget.style) {
      _c.duration = _durations[widget.style] ?? const Duration(seconds: 14);
    }
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
      builder: (_, _) {
        final t = _c.value * 2 * math.pi;

        final pColor = widget.primary.withValues(
          alpha: (widget.primary.a * 1.55).clamp(0.0, 0.95),
        );
        final sColor = widget.secondary.withValues(
          alpha: (widget.secondary.a * 1.55).clamp(0.0, 0.95),
        );
        final tColor = (widget.tertiary ?? widget.secondary).withValues(
          alpha: ((widget.tertiary ?? widget.secondary).a * 1.4).clamp(
            0.0,
            0.85,
          ),
        );

        return switch (widget.style) {
          GlowStyle.orbit => _buildOrbit(t, pColor, sColor),
          GlowStyle.ember => _buildEmber(t, pColor, sColor),
          GlowStyle.halo => _buildHalo(t, pColor, sColor, tColor),
          GlowStyle.drip => _buildDrip(t, pColor, sColor, tColor),
          GlowStyle.prism => _buildPrism(t, pColor, sColor, tColor),
          GlowStyle.ripple => _buildRipple(t, pColor, sColor, tColor),
        };
      },
    );
  }

  // ── Orbit: dual radial gradients circling around the screen ──────────────
  Widget _buildOrbit(double t, Color pColor, Color sColor) {
    final pulse = 0.88 + 0.12 * math.sin(t * 2);
    final cx = 0.5 + 0.28 * math.cos(t);
    final cy = 0.5 + 0.20 * math.sin(t);

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(cx * 2 - 1, cy * 2 - 1),
                radius: 1.0 * pulse,
                colors: [pColor, sColor, const Color(0x00000000)],
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
                colors: [sColor, const Color(0x00000000)],
                stops: const [0.0, 0.75],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Ember: bottom-anchored flicker, fast and erratic ────────────────────
  Widget _buildEmber(double t, Color pColor, Color sColor) {
    // Erratic flicker — multiple sine waves at different frequencies
    final flicker = 0.6 + 0.25 * math.sin(t * 5) + 0.15 * math.sin(t * 11);
    final drift = 0.5 + 0.15 * math.sin(t * 3);

    return Stack(
      children: [
        // Main ember glow at bottom
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(drift * 2 - 1, 0.9),
                radius: 0.8 * flicker,
                colors: [pColor, sColor, const Color(0x00000000)],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ),
        // Secondary smaller flicker offset
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-drift * 2 + 1, 0.85),
                radius: 0.5 * (1.0 - flicker.abs()),
                colors: [sColor, const Color(0x00000000)],
                stops: const [0.0, 0.6],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Halo: centered slow pulse, minimal movement ─────────────────────────
  Widget _buildHalo(double t, Color pColor, Color sColor, Color tColor) {
    // Very slow gentle pulse — barely perceptible breathing
    final pulse = 0.95 + 0.05 * math.sin(t);
    final wobble = 0.02 * math.sin(t * 0.5);

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(wobble, wobble * 0.5),
                radius: 0.9 * pulse,
                colors: [pColor, sColor, tColor, const Color(0x00000000)],
                stops: const [0.0, 0.35, 0.6, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Drip: top-anchored gradient moving downward ─────────────────────────
  Widget _buildDrip(double t, Color pColor, Color sColor, Color tColor) {
    // Slow downward movement
    final dripY = 0.15 + 0.3 * (0.5 + 0.5 * math.sin(t));
    final pulse = 0.85 + 0.15 * math.sin(t * 2);

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(0.0, -1.0),
                end: Alignment(0.0, dripY * 2 - 1),
                colors: [pColor, sColor, tColor, const Color(0x00000000)],
                stops: const [0.0, 0.3, 0.6, 1.0],
              ),
            ),
          ),
        ),
        // Side drip
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.7, dripY * 2 - 1),
                radius: 0.6 * pulse,
                colors: [sColor, const Color(0x00000000)],
                stops: const [0.0, 0.7],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Prism: rotating color-wheel sweep ────────────────────────────────
  // A diagonal linear gradient whose axis slowly rotates while the three
  // stops drift through primary → secondary → tertiary and back. A faint
  // counter-rotating radial adds depth. Premium "energy field" feel.
  Widget _buildPrism(double t, Color pColor, Color sColor, Color tColor) {
    // t is 0..2π over the controller duration.
    final dx = math.cos(t);
    final dy = math.sin(t);
    // Color drift — each stop lerps on its own slow phase.
    final cA = Color.lerp(pColor, sColor, (math.sin(t * 0.5 + 1.2) + 1) / 2)!;
    final cB = Color.lerp(sColor, tColor, (math.sin(t * 0.4 + 3.4) + 1) / 2)!;
    final cC = Color.lerp(tColor, pColor, (math.sin(t * 0.6 + 5.1) + 1) / 2)!;

    return Stack(
      children: [
        // Main rotating sweep.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-dx * 0.95, -dy * 0.95),
                end: Alignment(dx * 0.95, dy * 0.95),
                colors: [cA, cB, cC, const Color(0x00000000)],
                stops: const [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),
        ),
        // Counter-sweep accent — opposite direction, half speed.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(
                  math.cos(-t * 0.6) * 0.8,
                  math.sin(-t * 0.6) * 0.8,
                ),
                end: Alignment(
                  -math.cos(-t * 0.6) * 0.8,
                  -math.sin(-t * 0.6) * 0.8,
                ),
                colors: [
                  cB.withValues(alpha: cB.a * 0.5),
                  const Color(0x00000000),
                  cC.withValues(alpha: cC.a * 0.4),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Ripple: sonar rings expanding from drifting centers ─────────────
  // Three staggered radial pulses — each a bright rim that swells and
  // fades, center drifting on a slow Lissajous so the rings never feel
  // mechanical. Reads as sonar / ritual pulse.
  Widget _buildRipple(double t, Color pColor, Color sColor, Color tColor) {
    Widget ring(Color c, double phase, double speed, double maxR) {
      // Ping-pong expansion: 0→1→0 over each half-cycle.
      final p = (math.sin(t * speed + phase) + 1) / 2;
      final radius = 0.15 + p * maxR;
      final alpha = (1.0 - p) * 0.85;
      return Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                0.28 * math.cos(t * 0.35 + phase),
                0.22 * math.sin(t * 0.28 + phase * 1.7),
              ),
              radius: radius,
              colors: [
                c.withValues(alpha: alpha),
                c.withValues(alpha: alpha * 0.4),
                const Color(0x00000000),
              ],
              stops: const [0.0, 0.72, 1.0],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        ring(pColor, 0.0, 1.0, 1.15),
        ring(sColor, 2.1, 1.35, 0.95),
        ring(tColor, 4.2, 0.75, 1.35),
      ],
    );
  }
}
