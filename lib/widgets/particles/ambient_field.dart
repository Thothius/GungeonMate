import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/app_theme.dart';

/// Procedural atmosphere backdrop — five bespoke painter scenes that
/// sit between the liquid tank and the fragment shaders. Every scene
/// is a pure function of accumulated scene time + normalized seeds,
/// so reduced-motion renders a stable composed frame with no ticker.
///
/// Colors come from the active flair palette (primary / secondary /
/// headlineStat) so each [AmbientKind] re-skins with the theme.
class AmbientField extends StatefulWidget {
  final AmbientKind kind;
  final Color primary;
  final Color secondary;
  final Color tertiary;

  const AmbientField({
    super.key,
    required this.kind,
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  @override
  State<AmbientField> createState() => _AmbientFieldState();
}

class _AmbientFieldState extends State<AmbientField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tick;

  /// Monotonic scene time accumulated from ticker dt — same pattern as
  /// LiquidTankField so nothing teleports on a controller wrap.
  double _time = 0.0;
  bool _still = false;

  @override
  void initState() {
    super.initState();
    _tick = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(AmbientField old) {
    super.didUpdateWidget(old);
    _syncMotion();
  }

  void _onTick() {
    if (_still) return;
    final dt =
        (_tick.lastElapsedDuration ?? const Duration(milliseconds: 16))
            .inMilliseconds /
        1000.0;
    _time += dt.clamp(0.001, 0.05);
  }

  void _syncMotion() {
    _still = MediaQuery.disableAnimationsOf(context);
    if (_still) {
      _tick.stop();
    } else if (!_tick.isAnimating) {
      _tick.repeat();
    }
  }

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _tick,
        builder: (context, _) {
          return CustomPaint(
            painter: _AmbientPainter(
              kind: widget.kind,
              time: _still ? 37.5 : _time,
              primary: widget.primary,
              secondary: widget.secondary,
              tertiary: widget.tertiary,
            ),
          );
        },
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  final AmbientKind kind;
  final double time;
  final Color primary;
  final Color secondary;
  final Color tertiary;

  const _AmbientPainter({
    required this.kind,
    required this.time,
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    switch (kind) {
      case AmbientKind.off:
        return;
      case AmbientKind.godRays:
        _godRays(canvas, size);
      case AmbientKind.ash:
        _ash(canvas, size);
      case AmbientKind.runes:
        _runes(canvas, size);
      case AmbientKind.scanlines:
        _scanlines(canvas, size);
      case AmbientKind.abyss:
        _abyss(canvas, size);
    }
  }

  // ── GODRAYS — volumetric shafts sweeping down from the top ──────────
  // Five tilted light blades whose angle and alpha breathe on separate
  // sines, plus a soft source glow at the top edge. Additive-ish via
  // low-alpha screen-bright colors.
  void _godRays(Canvas canvas, Size s) {
    final cx = s.width * 0.5;
    final topGlow =
        Paint()
          ..shader = RadialGradient(
            colors: [
              primary.withValues(alpha: 0.20),
              secondary.withValues(alpha: 0.07),
              const Color(0x00000000),
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: Offset(cx, -s.height * 0.12),
              radius: s.width * 0.75,
            ),
          );
    canvas.drawRect(Offset.zero & s, topGlow);

    for (var i = 0; i < 5; i++) {
      final seed = i / 5.0;
      final sway =
          math.sin(time * 0.11 + seed * math.pi * 2.0) * 0.16 +
          math.sin(time * 0.043 + seed * 9.0) * 0.07;
      final baseX = s.width * (0.14 + seed * 0.72);
      final width = s.width * (0.05 + 0.025 * math.sin(seed * 7.0 + 1.0));
      final alpha = (0.05 +
              0.035 * (0.5 + 0.5 * math.sin(time * 0.23 + seed * 5.0)))
          .clamp(0.02, 0.11);
      final color = i.isEven ? primary : secondary;

      // Shaft = wide triangle from a top point fanning to the bottom.
      final path =
          Path()
            ..moveTo(baseX - width * 0.4, -s.height * 0.05)
            ..lineTo(baseX + width * 0.4, -s.height * 0.05)
            ..lineTo(
              baseX + width * 2.6 + sway * s.width * 0.4,
              s.height * 1.05,
            )
            ..lineTo(
              baseX - width * 2.2 + sway * s.width * 0.4,
              s.height * 1.05,
            )
            ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: alpha * 0.15),
              const Color(0x00000000),
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(Offset.zero & s),
      );
    }
  }

  // ── ASH — ember motes drifting up with per-mote flicker ─────────────
  // ~34 motes on golden-ratio seeds; rise speed, wobble phase and flicker
  // rate all derive from the seed so the field never visibly loops.
  void _ash(Canvas canvas, Size s) {
    final ember = Color.lerp(const Color(0xFFFF8A3C), primary, 0.45)!;
    const count = 34;
    for (var i = 0; i < count; i++) {
      final s1 = ((i * 0.61803398875) % 1.0 + 1.0) % 1.0;
      final s2 = ((i * 0.41421356237) % 1.0 + 1.0) % 1.0;
      final s3 = ((i * 0.73205080757) % 1.0 + 1.0) % 1.0;

      final rise = 0.010 + s3 * 0.020; // screen-heights per second
      final yy = (s1 - time * rise) % 1.0;
      final y = (yy < 0 ? yy + 1 : yy) * s.height;
      final x =
          s.width * (0.04 + 0.92 * s2) +
          math.sin(time * (0.6 + s1 * 1.4) + s1 * 20.0) * (4.0 + s3 * 7.0);

      // Two-octave flicker — reads as a real ember, not a blinking dot.
      final flick =
          0.55 +
          0.28 * math.sin(time * (2.0 + s2 * 3.0) + s1 * 30.0) +
          0.17 * math.sin(time * (5.0 + s3 * 4.0) + s2 * 40.0);
      final alpha = (0.25 + 0.55 * flick.clamp(0.0, 1.0)).clamp(0.05, 0.85);
      final r = 0.8 + s2 * 2.2;

      // Rare brighter "coal" — every ~7th mote gets a hot core.
      final hot = i % 7 == 0;
      canvas.drawCircle(
        Offset(x, y),
        r * (hot ? 1.5 : 1.0),
        Paint()
          ..color = (hot ? const Color(0xFFFFD9A0) : ember).withValues(
            alpha: alpha * (hot ? 0.9 : 0.6),
          ),
      );
      if (r > 2.2) {
        canvas.drawCircle(
          Offset(x, y),
          r * 2.4,
          Paint()
            ..color = ember.withValues(alpha: alpha * 0.10)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
    }
  }

  // ── RUNES — rotating arcane ring with orbiting ticks ────────────────
  // A faint circle + 28 ticks on a golden-ratio spacing rotate slowly;
  // every 7th tick is a longer "rune" stroke. Four diamond nodes orbit
  // the ring on independent phases. Cultist/paradox energy.
  void _runes(Canvas canvas, Size s) {
    final c = Offset(s.width * 0.5, s.height * 0.40);
    final R = s.shortestSide * 0.34;
    final rot = time * 0.05; // ~2min per revolution — meditative

    // Ambient center glow.
    canvas.drawCircle(
      c,
      R * 1.7,
      Paint()
        ..shader = RadialGradient(
          colors: [tertiary.withValues(alpha: 0.10), const Color(0x00000000)],
        ).createShader(Rect.fromCircle(center: c, radius: R * 1.7)),
    );

    // Ring band — two strokes, soft outer + crisp inner.
    final ringPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    canvas.drawCircle(
      c,
      R,
      ringPaint
        ..color = tertiary.withValues(alpha: 0.05)
        ..strokeWidth = 10,
    );
    canvas.drawCircle(
      c,
      R,
      ringPaint
        ..color = tertiary.withValues(alpha: 0.22)
        ..strokeWidth = 1.4,
    );

    // Ticks — deterministic per-index angle offset.
    const ticks = 28;
    for (var i = 0; i < ticks; i++) {
      final a = rot + (i / ticks) * math.pi * 2;
      final major = i % 7 == 0;
      final len = major ? R * 0.10 : R * 0.045;
      final p1 = Offset(
        c.dx + math.cos(a) * (R - len),
        c.dy + math.sin(a) * (R - len),
      );
      final p2 = Offset(
        c.dx + math.cos(a) * (R + len * 0.4),
        c.dy + math.sin(a) * (R + len * 0.4),
      );
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = (major ? primary : tertiary).withValues(
            alpha: major ? 0.5 : 0.28,
          )
          ..strokeWidth = major ? 2.2 : 1.2
          ..strokeCap = StrokeCap.round,
      );
    }

    // Orbiting diamonds — 4 nodes on independent radii/phases.
    for (var i = 0; i < 4; i++) {
      final seed = i / 4.0;
      final a = -rot * (1.4 + seed) + seed * math.pi * 2;
      final rr = R * (1.18 + 0.10 * math.sin(time * 0.11 + seed * 9));
      final p = Offset(c.dx + math.cos(a) * rr, c.dy + math.sin(a) * rr);
      final d = R * 0.028;
      final pulse = 0.6 + 0.4 * math.sin(time * 0.8 + seed * 12);
      final path =
          Path()
            ..moveTo(p.dx, p.dy - d)
            ..lineTo(p.dx + d, p.dy)
            ..lineTo(p.dx, p.dy + d)
            ..lineTo(p.dx - d, p.dy)
            ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = (i.isEven ? secondary : primary).withValues(
            alpha: 0.55 * pulse,
          )
          ..style = PaintingStyle.fill,
      );
    }
  }

  // ── SCANLINES — CRT raster + periodic glitch band ───────────────────
  // Fine horizontal raster always on; every ~7s a tear band sweeps
  // vertically with a faint RGB split — cheap, reads as analog decay.
  void _scanlines(Canvas canvas, Size s) {
    // Raster — 1px dark line every 3px.
    final linePaint =
        Paint()
          ..color = Colors.black.withValues(alpha: 0.10)
          ..strokeWidth = 1;
    for (var y = 0.0; y < s.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(s.width, y), linePaint);
    }
    // Faint top-light gradient so the raster doesn't look printed.
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            secondary.withValues(alpha: 0.05),
            const Color(0x00000000),
            primary.withValues(alpha: 0.04),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Offset.zero & s),
    );

    // Glitch band — position loops every 7s, active only mid-sweep.
    final cycle = (time % 7.0) / 7.0;
    if (cycle > 0.15 && cycle < 0.85) {
      final bandY = s.height * (0.1 + 0.8 * ((cycle - 0.15) / 0.7));
      final bandH = s.height * 0.045;
      final jitter = (math.sin(time * 47.0) * 0.5 + 0.5) * s.width * 0.012;
      void split(Color c, double dx) {
        canvas.drawRect(
          Rect.fromLTWH(dx, bandY, s.width, bandH),
          Paint()..color = c.withValues(alpha: 0.05),
        );
      }

      split(const Color(0xFFFF2D55), -jitter);
      split(const Color(0xFF00E5FF), jitter);
      // Tear edge lines.
      canvas.drawLine(
        Offset(0, bandY),
        Offset(s.width, bandY),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.06)
          ..strokeWidth = 1,
      );
      canvas.drawLine(
        Offset(0, bandY + bandH),
        Offset(s.width, bandY + bandH),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.06)
          ..strokeWidth = 1,
      );
    }
  }

  // ── ABYSS — deep parallax speck field ───────────────────────────────
  // ~64 far motes drift slowly with twinkle; 7 near motes are larger,
  // soft-glow and move faster — real depth layering, not uniform dust.
  void _abyss(Canvas canvas, Size s) {
    const far = 64;
    for (var i = 0; i < far; i++) {
      final s1 = ((i * 0.61803398875) % 1.0 + 1.0) % 1.0;
      final s2 = ((i * 0.41421356237) % 1.0 + 1.0) % 1.0;
      final s3 = ((i * 0.73205080757) % 1.0 + 1.0) % 1.0;
      // Slow diagonal drift downward; wrap vertically.
      final drift = time * (0.004 + s3 * 0.008);
      final y = ((s1 + drift) % 1.0) * s.height;
      final x =
          ((s2 + drift * 0.35 + time * 0.002 * (s1 - 0.5)) % 1.0) * s.width;
      final twinkle = 0.5 + 0.5 * math.sin(time * (0.5 + s2) + s1 * 40.0);
      final alpha = (0.10 + 0.35 * twinkle).clamp(0.04, 0.5);
      final r = 0.6 + s3 * 1.4;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = (i % 5 == 0 ? secondary : tertiary).withValues(
            alpha: alpha,
          ),
      );
    }

    // Near motes — soft radial glows, faster drift, primary-tinted.
    for (var i = 0; i < 7; i++) {
      final s1 = ((i * 0.7548776662) % 1.0 + 1.0) % 1.0;
      final s2 = ((i * 0.56984029) % 1.0 + 1.0) % 1.0;
      final drift = time * (0.012 + s1 * 0.010);
      final y = ((s2 - drift) % 1.0) * s.height;
      final x = ((s1 + drift * 0.2) % 1.0) * s.width;
      final pulse = 0.7 + 0.3 * math.sin(time * 0.9 + i * 2.4);
      final r = s.shortestSide * (0.05 + s2 * 0.05);
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              primary.withValues(alpha: 0.16 * pulse),
              primary.withValues(alpha: 0.04 * pulse),
              const Color(0x00000000),
            ],
            stops: const [0.0, 0.4, 1.0],
          ).createShader(Rect.fromCircle(center: Offset(x, y), radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(_AmbientPainter old) =>
      old.kind != kind ||
      old.time != time ||
      old.primary != primary ||
      old.secondary != secondary ||
      old.tertiary != tertiary;
}
