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
      builder: (_, __) {
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
}
