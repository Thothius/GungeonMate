import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/app_theme.dart';

/// Ambient "liquid tank" backdrop — a slow rising bubbly fill that
/// sits behind app content (above wallpaper, below particles).
///
/// [LiquidKind.blood]/[venom]/[umbra] render a tinted liquid whose
/// wavy surface breathes while bubbles drift up and pop. The fill
/// ramps in over ~7s on first show, then holds ~30% of screen height.
/// [LiquidKind.shells] swaps the liquid for brass casings that slide
/// around the screen in response to [tilt] (the shared smoothed
/// accelerometer stream from ThemeOverlay).
///
/// Honors `MediaQuery.disableAnimationsOf`: renders one composed
/// static frame (frozen surface, pre-seeded shells) with no ticker.
class LiquidTankField extends StatefulWidget {
  final LiquidKind kind;

  /// Smoothed device tilt (-10..10 per axis). Only read by shells mode;
  /// pass `ThemeOverlay.tiltNotifier` for live physics.
  final ValueListenable<Offset>? tilt;

  const LiquidTankField({super.key, required this.kind, this.tilt});

  @override
  State<LiquidTankField> createState() => _LiquidTankFieldState();
}

class _LiquidTankFieldState extends State<LiquidTankField>
    with TickerProviderStateMixin {
  /// Drives surface waves, bubble drift and the shells physics tick.
  late final AnimationController _wave;

  /// One-shot ramp — the liquid "fills" over the first few seconds,
  /// then holds with gentle breathing.
  late final AnimationController _fill;

  Offset _tilt = Offset.zero;
  bool _still = false;
  Size? _lastSize;
  final List<_Shell> _shells = [];
  final math.Random _rng = math.Random(0xB1005);

  /// Monotonic scene time, accumulated from ticker dt — NOT
  /// `_wave.value * duration`, which sawtooths every 12s and made the
  /// surface, fill level and every bubble teleport on the wrap.
  double _time = 0.0;

  static const _waveSeconds = 12;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _waveSeconds),
    )..addListener(_onTick);
    _fill = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );
    widget.tilt?.addListener(_onTilt);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(LiquidTankField old) {
    super.didUpdateWidget(old);
    if (old.tilt != widget.tilt) {
      old.tilt?.removeListener(_onTilt);
      widget.tilt?.addListener(_onTilt);
      _tilt = widget.tilt?.value ?? Offset.zero;
    }
    if (old.kind != widget.kind) {
      // Re-fill on kind switch — feels like the tank drains and refills.
      _fill.forward(from: 0);
      _shells.clear();
      _lastSize = null;
    }
    _syncMotion();
  }

  void _onTilt() => _tilt = widget.tilt?.value ?? Offset.zero;

  void _onTick() {
    if (_still) return;
    final dt =
        (_wave.lastElapsedDuration ?? const Duration(milliseconds: 16))
            .inMilliseconds /
        1000.0;
    final clamped = dt.clamp(0.001, 0.05);
    _time += clamped;
    if (widget.kind == LiquidKind.shells) _integrateShells(clamped);
  }

  void _syncMotion() {
    _still = MediaQuery.disableAnimationsOf(context);
    if (_still) {
      _wave.stop();
      _fill.stop();
    } else {
      if (!_wave.isAnimating) _wave.repeat();
      if (_fill.value < 1.0) _fill.forward();
    }
  }

  @override
  void dispose() {
    widget.tilt?.removeListener(_onTilt);
    _wave.dispose();
    _fill.dispose();
    super.dispose();
  }

  /// Test-only: current accumulated scene time.
  @visibleForTesting
  double get debugTime => _time;

  void _ensureShells(Size size) {
    if (_shells.isNotEmpty || size.isEmpty) return;
    for (var i = 0; i < 14; i++) {
      _shells.add(
        _Shell(
          pos: Offset(
            size.width * (0.08 + _rng.nextDouble() * 0.84),
            size.height * (0.15 + _rng.nextDouble() * 0.75),
          ),
          vel: Offset.zero,
          rot: _rng.nextDouble() * math.pi * 2,
          rotVel: (_rng.nextDouble() - 0.5) * 2.4,
          radius: 7.0 + _rng.nextDouble() * 8.0,
        ),
      );
    }
  }

  void _integrateShells(double dt) {
    final size = _lastSize;
    if (size == null) return;
    // Tilt ±10 → up to ~±520 px/s² of slide. Damping ~exp decay.
    final ax = _tilt.dx * 52.0;
    final ay = _tilt.dy * 52.0;
    final damp = math.exp(-1.6 * dt);
    for (final s in _shells) {
      s.vel = Offset((s.vel.dx + ax * dt) * damp, (s.vel.dy + ay * dt) * damp);
      s.pos += s.vel * dt;
      // Soft walls — casings tumble to a stop against the edges.
      final r = s.radius;
      if (s.pos.dx < r) {
        s.pos = Offset(r, s.pos.dy);
        s.vel = Offset(-s.vel.dx * 0.35, s.vel.dy * 0.7);
      } else if (s.pos.dx > size.width - r) {
        s.pos = Offset(size.width - r, s.pos.dy);
        s.vel = Offset(-s.vel.dx * 0.35, s.vel.dy * 0.7);
      }
      if (s.pos.dy < r) {
        s.pos = Offset(s.pos.dx, r);
        s.vel = Offset(s.vel.dx * 0.7, -s.vel.dy * 0.35);
      } else if (s.pos.dy > size.height - r) {
        s.pos = Offset(s.pos.dx, size.height - r);
        s.vel = Offset(s.vel.dx * 0.7, -s.vel.dy * 0.35);
      }
      s.rot += s.rotVel * dt;
      s.rotVel *= damp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          _lastSize = size;
          if (widget.kind == LiquidKind.shells) _ensureShells(size);
          return AnimatedBuilder(
            animation: Listenable.merge([_wave, _fill]),
            builder: (context, _) {
              final t = _still ? 41.0 : _time;
              final f = _still ? 1.0 : _fill.value;
              return CustomPaint(
                size: size,
                painter:
                    widget.kind == LiquidKind.shells
                        ? _ShellPainter(shells: _shells, time: t)
                        : _LiquidPainter(kind: widget.kind, time: t, ramp: f),
              );
            },
          );
        },
      ),
    );
  }
}

class _Shell {
  Offset pos;
  Offset vel;
  double rot;
  double rotVel;
  final double radius;
  _Shell({
    required this.pos,
    required this.vel,
    required this.rot,
    required this.rotVel,
    required this.radius,
  });
}

/// Per-kind liquid palette — deep body → mid → bright surface line,
/// plus the bubble tint.
class _LiquidColors {
  final Color deep;
  final Color mid;
  final Color surface;
  final Color bubble;
  const _LiquidColors(this.deep, this.mid, this.surface, this.bubble);

  static _LiquidColors of(LiquidKind kind) => switch (kind) {
    LiquidKind.blood => const _LiquidColors(
      Color(0xFF420505),
      Color(0xFF7A0E0E),
      Color(0xFFD8402F),
      Color(0xFFF0A08E),
    ),
    LiquidKind.venom => const _LiquidColors(
      Color(0xFF0C2B12),
      Color(0xFF1E5B2E),
      Color(0xFF7FBF4A),
      Color(0xFFD9FFB0),
    ),
    LiquidKind.umbra => const _LiquidColors(
      Color(0xFF140826),
      Color(0xFF2E1660),
      Color(0xFF9A63E8),
      Color(0xFFD8C0FF),
    ),
    _ => const _LiquidColors(
      Color(0xFF420505),
      Color(0xFF7A0E0E),
      Color(0xFFD8402F),
      Color(0xFFF0A08E),
    ),
  };
}

class _LiquidPainter extends CustomPainter {
  final LiquidKind kind;
  final double time;

  /// Fill ramp 0→1 (already eased by controller); multiplies the
  /// breathing target level.
  final double ramp;
  const _LiquidPainter({
    required this.kind,
    required this.time,
    required this.ramp,
  });

  /// Surface height fraction breathing around ~0.32 of screen height.
  double get _fillTarget => 0.30 + 0.035 * math.sin(time * 0.30);

  double _ease(double x) => x * x * (3 - 2 * x);

  /// Wavy liquid surface — three interfering sines so the crest never
  /// looks looped. u is normalized x (0..1), y returned in px from top.
  double _surfaceY(double u, Size s, double fillPx) {
    final base = s.height - fillPx;
    final amp = (3.0 + 2.0 * math.sin(time * 0.23)).clamp(2.0, 7.0);
    return base +
        amp * math.sin(u * math.pi * 2 * 2.3 + time * 0.9) +
        amp * 0.55 * math.sin(u * math.pi * 2 * 4.1 - time * 1.35 + 1.7) +
        amp * 0.3 * math.sin(u * math.pi * 2 * 1.2 + time * 0.5 + 0.6);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = _LiquidColors.of(kind);
    final fillPx = size.height * _fillTarget * _ease(ramp);
    if (fillPx <= 1) return;

    // Liquid body — vertical gradient deep→mid, sampled along the
    // wavy surface so the top edge of the gradient follows the waves.
    final body = Path()..moveTo(0, size.height);
    const step = 14;
    for (var x = 0.0; x <= size.width; x += step) {
      body.lineTo(x, _surfaceY(x / size.width, size, fillPx));
    }
    body
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            c.mid.withValues(alpha: 0.55),
            c.deep.withValues(alpha: 0.92),
          ],
          stops: const [0.0, 0.55],
        ).createShader(Offset.zero & size),
    );

    // Bubbles — deterministic seeds, rise through the liquid and pop
    // at the surface (alpha + radius collapse in the last ~8%).
    final bubbleCount = 22;
    for (var i = 0; i < bubbleCount; i++) {
      final seed = ((i * 0.61803398875) % 1.0 + 1.0) % 1.0;
      final seed2 = ((i * 0.41421356237) % 1.0 + 1.0) % 1.0;
      final seed3 = ((i * 0.73205080757) % 1.0 + 1.0) % 1.0;
      final dur = 3.5 + seed3 * 4.5; // seconds to cross the fill
      final yy = (time / dur + seed) % 1.0;
      final x =
          size.width * (0.06 + 0.88 * seed2) +
          math.sin(time * 1.8 + seed * 9.0) * 3.0;
      final r = 1.6 + seed * 3.4;
      // Pop fade in the top 10% of travel.
      final pop = yy > 0.90 ? ((1.0 - yy) / 0.10).clamp(0.0, 1.0) : 1.0;
      final y =
          size.height -
          r -
          yy * (fillPx - r * 2) +
          math.sin(time * 2.2 + seed * 7.0) * 1.5;
      if (y < _surfaceY(x / size.width, size, fillPx) - r) continue;
      canvas.drawCircle(
        Offset(x, y),
        r * (0.6 + 0.4 * pop),
        Paint()
          ..shader = RadialGradient(
            colors: [
              c.bubble.withValues(alpha: 0.5 * pop),
              c.bubble.withValues(alpha: 0.06 * pop),
            ],
          ).createShader(Rect.fromCircle(center: Offset(x, y), radius: r)),
      );
    }

    // Surface line — bright crest stroke + soft glow pass so the
    // liquid edge reads against any wallpaper.
    final surf = Path();
    for (var x = 0.0; x <= size.width; x += step) {
      final y = _surfaceY(x / size.width, size, fillPx);
      if (x == 0) {
        surf.moveTo(x, y);
      } else {
        surf.lineTo(x, y);
      }
    }
    final surfPaint =
        Paint()
          ..color = c.surface.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round;
    canvas.drawPath(surf, surfPaint);
    canvas.drawPath(
      surf,
      Paint()
        ..color = c.surface.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
  }

  @override
  bool shouldRepaint(_LiquidPainter old) =>
      old.kind != kind || old.time != time || old.ramp != ramp;
}

/// Brass shell casings — seeded scatter, tilt-driven slide with soft
/// wall bounce. Painted as vector casings (no asset dependency).
class _ShellPainter extends CustomPainter {
  final List<_Shell> shells;
  final double time;
  const _ShellPainter({required this.shells, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in shells) {
      canvas.save();
      canvas.translate(s.pos.dx, s.pos.dy);
      canvas.rotate(s.rot);
      final w = s.radius * 1.9;
      final h = s.radius * 0.9;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        Radius.circular(h * 0.4),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [
              Color(0xFFE8C56A),
              Color(0xFFB98A3E),
              Color(0xFF7A5518),
            ],
          ).createShader(rect.outerRect),
      );
      // Rim shadow on the right end + primer dot — reads as a casing.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * 0.32, 0),
          width: w * 0.16,
          height: h * 0.8,
        ),
        Paint()..color = const Color(0xFF5E4010).withValues(alpha: 0.8),
      );
      canvas.drawCircle(
        Offset(-w * 0.28, 0),
        h * 0.16,
        Paint()..color = const Color(0xFF3E2A08).withValues(alpha: 0.9),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ShellPainter old) => old.time != time;
}
