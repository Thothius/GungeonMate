import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../services/app_theme.dart';

/// Wraps a fixed-size avatar (typically a square pixel-art portrait)
/// with a per-theme animated border. Reads [AppTheme.flair.auraStyle]
/// and listens to [AppTheme.notifier] so the aura swaps live when the
/// user changes theme.
///
/// The aura always paints OUTSIDE the [size]×[size] box; pad your call
/// site by [auraPadding] (defaults to 4px) if the surrounding layout
/// would otherwise clip the glow.
///
/// All styles are pointer-transparent — taps still hit [child].
class AvatarAura extends StatelessWidget {
  /// The portrait widget to wrap (Image, Icon, etc.). Rendered at
  /// [size]×[size]. The widget itself should already include any
  /// background/border treatment.
  final Widget child;

  /// Size of the inner avatar. The aura ring sits flush against this.
  final double size;

  /// Border radius of the underlying avatar (so the aura curves match).
  /// Use [size]/2 for circular avatars.
  final double borderRadius;

  /// Slow the aura's animation cycle (1.0 = default speed). Larger
  /// values like 1.6 calm the effect when many auras tile a screen.
  final double speedScale;

  /// Hide the aura entirely. Useful for "selected" highlights that
  /// already supply their own ring.
  final bool enabled;

  const AvatarAura({
    super.key,
    required this.child,
    this.size = 64,
    this.borderRadius = 12,
    this.speedScale = 1.0,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return SizedBox(width: size, height: size, child: child);
    }
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: AppTheme.notifier,
      builder: (_, __, ___) {
        final flair = AppTheme.flair;
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Aura layer — extends ~6px beyond the avatar in every
              // direction. Painted underneath the child so the avatar
              // edges stay crisp.
              Positioned(
                left: -6,
                top: -6,
                right: -6,
                bottom: -6,
                child: IgnorePointer(
                  child: _AuraLayer(
                    style: flair.auraStyle,
                    primary: flair.primary,
                    secondary: flair.secondary,
                    radius: borderRadius + 6,
                    speedScale: speedScale,
                  ),
                ),
              ),
              // The avatar itself sits on top, untouched.
              Positioned.fill(child: child),
            ],
          ),
        );
      },
    );
  }
}

/// Internal: dispatches on [AvatarAuraStyle] and runs the right painter.
class _AuraLayer extends StatefulWidget {
  final AvatarAuraStyle style;
  final Color primary;
  final Color secondary;
  final double radius;
  final double speedScale;

  const _AuraLayer({
    required this.style,
    required this.primary,
    required this.secondary,
    required this.radius,
    required this.speedScale,
  });

  @override
  State<_AuraLayer> createState() => _AuraLayerState();
}

class _AuraLayerState extends State<_AuraLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    // 4s base cycle. Each painter remaps t→its own visual rhythm.
    final ms = (4000 * widget.speedScale).round();
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: ms),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant _AuraLayer old) {
    super.didUpdateWidget(old);
    if (old.speedScale != widget.speedScale) {
      _c.duration =
          Duration(milliseconds: (4000 * widget.speedScale).round());
      _c
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.style == AvatarAuraStyle.none) {
      return const SizedBox.shrink();
    }
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _AuraPainter(
            style: widget.style,
            t: _c.value,
            primary: widget.primary,
            secondary: widget.secondary,
            radius: widget.radius,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

/// Single painter that branches on [AvatarAuraStyle]. Keeps the painter
/// graph small (one CustomPaint per avatar) instead of one painter type
/// per style — simpler hot-path and easier to compare side-by-side.
class _AuraPainter extends CustomPainter {
  final AvatarAuraStyle style;
  final double t;
  final Color primary;
  final Color secondary;
  final double radius;

  _AuraPainter({
    required this.style,
    required this.t,
    required this.primary,
    required this.secondary,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(2),
      Radius.circular(radius),
    );
    switch (style) {
      case AvatarAuraStyle.none:
        return;
      case AvatarAuraStyle.goldShimmerRing:
        _paintGoldShimmer(canvas, size, rrect);
      case AvatarAuraStyle.pastelPulse:
        _paintPastelPulse(canvas, size, rrect);
      case AvatarAuraStyle.oxbloodBreath:
        _paintOxbloodBreath(canvas, size, rrect);
      case AvatarAuraStyle.brassConic:
        _paintBrassConic(canvas, size, rrect);
      case AvatarAuraStyle.frostRing:
        _paintFrostRing(canvas, size, rrect);
      case AvatarAuraStyle.voidPulse:
        _paintVoidPulse(canvas, size, rrect);
      case AvatarAuraStyle.toxicOoze:
        _paintToxicOoze(canvas, size, rrect);
      case AvatarAuraStyle.forgeGlow:
        _paintForgeGlow(canvas, size, rrect);
      case AvatarAuraStyle.lichPurple:
        _paintLichPurple(canvas, size, rrect);
      case AvatarAuraStyle.cosmicTemporal:
        _paintCosmicTemporal(canvas, size, rrect);
    }
  }

  // -- Coolmaxing: rotating gold conic with a magenta hot-spot --------
  void _paintGoldShimmer(Canvas canvas, Size size, RRect rrect) {
    final center = _rectCenter(size);
    final angle = t * 2 * math.pi;
    // Sweep gradient: gold dominant with magenta kicker rotating.
    final shader = SweepGradient(
      startAngle: 0,
      endAngle: 2 * math.pi,
      transform: GradientRotation(angle),
      colors: [
        primary.withValues(alpha: 0.0),
        primary.withValues(alpha: 0.85),
        secondary.withValues(alpha: 0.75),
        primary.withValues(alpha: 0.85),
        primary.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: size.shortestSide));
    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawRRect(rrect, paint);
    // Inner hairline keeps the avatar from "floating" inside the glow.
    final inner = Paint()
      ..color = primary.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect.deflate(1.2), inner);
  }

  // -- Unicorn: bubblegum + mint dual halo, breathes in/out -----------
  void _paintPastelPulse(Canvas canvas, Size size, RRect rrect) {
    // Triangle wave 0→1→0 over t (period = full cycle).
    final tri = t < 0.5 ? t * 2 : (1 - t) * 2;
    final outerAlpha = 0.30 + 0.35 * tri;
    final innerAlpha = 0.55 + 0.30 * tri;
    final outer = Paint()
      ..color = primary.withValues(alpha: outerAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 + 2 * tri
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + 3 * tri);
    canvas.drawRRect(rrect.inflate(2), outer);
    final mid = Paint()
      ..color = secondary.withValues(alpha: innerAlpha * 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawRRect(rrect, mid);
    final inner = Paint()
      ..color = primary.withValues(alpha: innerAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRRect(rrect.deflate(1.0), inner);
  }

  // -- Curseblaster: oxblood breathing ring with darker rim ----------
  void _paintOxbloodBreath(Canvas canvas, Size size, RRect rrect) {
    final tri = t < 0.5 ? t * 2 : (1 - t) * 2;
    final glowAlpha = 0.35 + 0.45 * tri;
    final outer = Paint()
      ..color = primary.withValues(alpha: glowAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 + 2.2 * tri
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.5 + 2.5 * tri);
    canvas.drawRRect(rrect.inflate(1.5), outer);
    final rim = Paint()
      ..color = const Color(0xFF400308).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRRect(rrect, rim);
    final inner = Paint()
      ..color = primary.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect.deflate(1.4), inner);
  }

  // -- Winchester: slowly rotating brass conic, double hairline -------
  void _paintBrassConic(Canvas canvas, Size size, RRect rrect) {
    final center = _rectCenter(size);
    // Slower than gold shimmer; saloon clock pace.
    final angle = t * 2 * math.pi * 0.5;
    final shader = SweepGradient(
      startAngle: 0,
      endAngle: 2 * math.pi,
      transform: GradientRotation(angle),
      colors: [
        primary.withValues(alpha: 0.15),
        secondary.withValues(alpha: 0.65),
        primary.withValues(alpha: 0.85),
        secondary.withValues(alpha: 0.65),
        primary.withValues(alpha: 0.15),
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: size.shortestSide));
    final outer = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawRRect(rrect, outer);
    // Brass hairline 3px in for a "pressed brass plate" double-line look.
    final inner = Paint()
      ..color = primary.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawRRect(rrect.deflate(3), inner);
  }

  // -- Ice Tyrant: sharp cyan frost ring with white frost sparkles ------
  void _paintFrostRing(Canvas canvas, Size size, RRect rrect) {
    final tri = t < 0.5 ? t * 2 : (1 - t) * 2;
    final glowAlpha = 0.35 + 0.40 * tri;
    final outer = Paint()
      ..color = primary.withValues(alpha: glowAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 + 1.5 * tri
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 + 2 * tri);
    canvas.drawRRect(rrect.inflate(1.5), outer);
    final mid = Paint()
      ..color = secondary.withValues(alpha: 0.65 + 0.25 * tri)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRRect(rrect, mid);
    // Tiny frost sparkle dots at the corners.
    final sparkle = Paint()
      ..color = Colors.white.withValues(alpha: 0.5 + 0.3 * tri);
    final cornerInset = radius + 4;
    for (final corner in [
      Offset(cornerInset, cornerInset),
      Offset(size.width - cornerInset, cornerInset),
      Offset(cornerInset, size.height - cornerInset),
      Offset(size.width - cornerInset, size.height - cornerInset),
    ]) {
      canvas.drawCircle(corner, 1.2 + 0.6 * tri, sparkle);
    }
  }

  // -- Pitch Black: extremely faint white breathing ring ---------------
  void _paintVoidPulse(Canvas canvas, Size size, RRect rrect) {
    final tri = t < 0.5 ? t * 2 : (1 - t) * 2;
    final alpha = 0.08 + 0.10 * tri; // barely visible
    final outer = Paint()
      ..color = primary.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 + 1.5 * tri
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + 3 * tri);
    canvas.drawRRect(rrect.inflate(1), outer);
    final inner = Paint()
      ..color = secondary.withValues(alpha: alpha * 1.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    canvas.drawRRect(rrect.deflate(1.5), inner);
  }

  // -- Oubliette: bubbling toxic green ooze border -----------------------
  void _paintToxicOoze(Canvas canvas, Size size, RRect rrect) {
    final tri = t < 0.5 ? t * 2 : (1 - t) * 2;
    final glowAlpha = 0.40 + 0.40 * tri;
    // Outer toxic glow.
    final outer = Paint()
      ..color = primary.withValues(alpha: glowAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 + 2 * tri
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + 2 * tri);
    canvas.drawRRect(rrect.inflate(2), outer);
    // Dark swamp rim.
    final rim = Paint()
      ..color = const Color(0xFF0A1A0A).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRRect(rrect, rim);
    // Inner ooze line.
    final inner = Paint()
      ..color = secondary.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect.deflate(1.4), inner);
    // Two "bubbles" that drift around the border.
    final bubblePaint = Paint()
      ..color = primary.withValues(alpha: 0.6 + 0.3 * tri);
    final cx = size.width / 2;
    final cy = size.height / 2;
    final bubbleR = radius * 0.5;
    for (var i = 0; i < 2; i++) {
      final bt = (t + i * 0.5) % 1.0;
      final bx = cx + math.cos(bt * 2 * math.pi) * bubbleR;
      final by = cy + math.sin(bt * 2 * math.pi) * bubbleR;
      canvas.drawCircle(Offset(bx, by), 2.2, bubblePaint);
    }
  }

  // -- Forge Master: molten hot sparks and pulsing fire -----------------
  void _paintForgeGlow(Canvas canvas, Size size, RRect rrect) {
    final tri = t < 0.5 ? t * 2 : (1 - t) * 2;
    final center = _rectCenter(size);
    final angle = t * 2 * math.pi;

    // Glowing molten backdrop ring
    final glow = Paint()
      ..color = primary.withValues(alpha: 0.35 + 0.35 * tri)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 + 2 * tri
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 + 3 * tri);
    canvas.drawRRect(rrect, glow);

    // Rotating hot-spots (SweepGradient)
    final shader = SweepGradient(
      startAngle: 0,
      endAngle: 2 * math.pi,
      transform: GradientRotation(-angle),
      colors: [
        primary.withValues(alpha: 0.1),
        secondary.withValues(alpha: 0.8),
        primary.withValues(alpha: 0.9),
        secondary.withValues(alpha: 0.8),
        primary.withValues(alpha: 0.1),
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: size.shortestSide));

    final sweep = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawRRect(rrect, sweep);

    // Dynamic rising forge sparks
    final spark = Paint()..color = secondary.withValues(alpha: 0.6 + 0.4 * tri);
    final offsets = [
      Offset(size.width * 0.25, size.height * (0.9 - tri * 0.5)),
      Offset(size.width * 0.75, size.height * (0.8 - tri * 0.6)),
      Offset(size.width * (0.1 + tri * 0.2), size.height * 0.2),
    ];
    for (final offset in offsets) {
      canvas.drawCircle(offset, 1.5, spark);
    }
  }

  // -- Lich's Tomb: ethereal necrotic vortex ----------------------------
  void _paintLichPurple(Canvas canvas, Size size, RRect rrect) {
    final tri = t < 0.5 ? t * 2 : (1 - t) * 2;
    final center = _rectCenter(size);
    final angle = t * 2 * math.pi * 1.5; // faster swirl

    // Swirling toxic gradient
    final shader = SweepGradient(
      startAngle: 0,
      endAngle: 2 * math.pi,
      transform: GradientRotation(angle),
      colors: [
        primary.withValues(alpha: 0.0),
        primary.withValues(alpha: 0.8),
        secondary.withValues(alpha: 0.9),
        primary.withValues(alpha: 0.8),
        primary.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: size.shortestSide));

    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 + 1.5 * tri
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + 2 * tri);
    canvas.drawRRect(rrect, paint);

    // Outer ghostly border
    final outer = Paint()
      ..color = secondary.withValues(alpha: 0.35 + 0.25 * tri)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect.inflate(2.5), outer);
  }

  // -- Past Slayer: celestial rotating cosmic rings ----------------------
  void _paintCosmicTemporal(Canvas canvas, Size size, RRect rrect) {
    final tri = t < 0.5 ? t * 2 : (1 - t) * 2;
    final center = _rectCenter(size);
    final angle1 = t * 2 * math.pi;
    final angle2 = -t * 2 * math.pi * 0.6; // counter-rotating

    // Outer cyan orbital sweep
    final shader1 = SweepGradient(
      startAngle: 0,
      endAngle: 2 * math.pi,
      transform: GradientRotation(angle1),
      colors: [
        primary.withValues(alpha: 0.0),
        primary.withValues(alpha: 0.85),
        Colors.white.withValues(alpha: 0.55),
        primary.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.45, 0.5, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: size.shortestSide));

    final paint1 = Paint()
      ..shader = shader1
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawRRect(rrect.inflate(1), paint1);

    // Inner gold temporal sweep
    final shader2 = SweepGradient(
      startAngle: 0,
      endAngle: 2 * math.pi,
      transform: GradientRotation(angle2),
      colors: [
        secondary.withValues(alpha: 0.0),
        secondary.withValues(alpha: 0.75),
        secondary.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: size.shortestSide));

    final paint2 = Paint()
      ..shader = shader2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(rrect.deflate(1.5), paint2);

    // Cosmic sparkle stars orbiting the avatar
    final sparkle = Paint()..color = Colors.white.withValues(alpha: 0.5 + 0.5 * tri);
    final radiusX = size.width / 2;
    final radiusY = size.height / 2;
    for (var i = 0; i < 2; i++) {
      final theta = angle1 + i * math.pi;
      final sx = center.dx + math.cos(theta) * (radiusX - 1);
      final sy = center.dy + math.sin(theta) * (radiusY - 1);
      canvas.drawCircle(Offset(sx, sy), 1.2 + 0.4 * tri, sparkle);
    }
  }

  Offset _rectCenter(Size s) => Offset(s.width / 2, s.height / 2);

  @override
  bool shouldRepaint(_AuraPainter old) =>
      old.t != t ||
      old.style != style ||
      old.primary != primary ||
      old.secondary != secondary;
}
