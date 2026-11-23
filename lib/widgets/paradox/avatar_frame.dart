import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../utils/asset_paths.dart';

/// An avatar frame style — a border/decoration painted around the
/// portrait. Regular frames are static; specials animate.
class AvatarFrameStyle {
  const AvatarFrameStyle(
    this.id,
    this.label,
    this.color, {
    this.special = false,
  });
  final String id;
  final String label;
  final Color color;
  final bool special;
}

/// 12 regular colors.
const kAvatarFrames = <AvatarFrameStyle>[
  AvatarFrameStyle('', 'NONE', Colors.transparent),
  AvatarFrameStyle('violet', 'VIOLET', Color(0xFF7C4DFF)),
  AvatarFrameStyle('purple', 'PURPLE', Color(0xFF9C27B0)),
  AvatarFrameStyle('pink', 'PINK', Color(0xFFEC407A)),
  AvatarFrameStyle('red', 'RED', Color(0xFFE53935)),
  AvatarFrameStyle('orange', 'ORANGE', Color(0xFFFB8C00)),
  AvatarFrameStyle('amber', 'AMBER', Color(0xFFFFB300)),
  AvatarFrameStyle('green', 'GREEN', Color(0xFF43A047)),
  AvatarFrameStyle('teal', 'TEAL', Color(0xFF26A69A)),
  AvatarFrameStyle('cyan', 'CYAN', Color(0xFF00BCD4)),
  AvatarFrameStyle('blue', 'BLUE', Color(0xFF1E88E5)),
  AvatarFrameStyle('white', 'WHITE', Colors.white),
  AvatarFrameStyle('onyx', 'ONYX', Color(0xFF424242)),
];

/// 8 special frames — animated, each unique.
const kSpecialFrames = <AvatarFrameStyle>[
  AvatarFrameStyle('gold', 'GOLD', Color(0xFFFFD700), special: true),
  AvatarFrameStyle('silver', 'SILVER', Color(0xFFC0C0C0), special: true),
  AvatarFrameStyle('rainbow', 'RAINBOW', Color(0xFFFF4081), special: true),
  AvatarFrameStyle('cursed', 'CURSED', Color(0xFF7B1FA2), special: true),
  AvatarFrameStyle('cool', 'COOL', Color(0xFF4DD0E1), special: true),
  AvatarFrameStyle('fiery', 'FIERY', Color(0xFFFF5722), special: true),
  AvatarFrameStyle('cosmic', 'COSMIC', Color(0xFF5E35B1), special: true),
  AvatarFrameStyle('glitch', 'GLITCH', Color(0xFF00E5FF), special: true),
  AvatarFrameStyle('toxic', 'TOXIC', Color(0xFF76FF03), special: true),
  AvatarFrameStyle('storm', 'STORM', Color(0xFF82B1FF), special: true),
  AvatarFrameStyle('royal', 'ROYAL', Color(0xFFCE93D8), special: true),
  AvatarFrameStyle('neon', 'NEON', Color(0xFF18FFFF), special: true),
];

AvatarFrameStyle? avatarFrameStyleOf(String id) {
  for (final f in [...kAvatarFrames, ...kSpecialFrames]) {
    if (f.id == id) return f;
  }
  return null;
}

/// Framed avatar portrait — resolves `avatarPath`, paints the picked
/// frame (animated for specials), falls back to a person icon.
///
/// `idle: true` adds a subtle alive-loop — slow breathing scale, a
/// gentle sway, and a soft bob — so portraits feel present during a
/// run instead of frozen. Honors reduced-motion; the phase is derived
/// from [id] so two avatars on screen never move in sync.
class FramedAvatar extends StatelessWidget {
  const FramedAvatar({
    super.key,
    required this.id,
    this.size = 48,
    this.radius = 10,
    this.idle = false,
  });

  final String id;
  final double size;
  final double radius;
  final bool idle;

  @override
  Widget build(BuildContext context) {
    final frame = avatarFrameStyleOf(avatarFrameId(id));
    final w = size.isFinite ? size : null;
    // Square clip — rounded corners let the white gridline edges on
    // sliced grid portraits peek through the curve gaps. Square clip +
    // 1.10 overscale covers them fully.
    final inner = ClipRect(
      child: Transform.scale(
        scale: 1.10,
        child: Image.asset(
          avatarPath(id),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.none,
          errorBuilder:
              (_, _, _) => Icon(
                Icons.person,
                size: (w ?? 40) * 0.6,
                color: Colors.white38,
              ),
        ),
      ),
    );
    Widget avatar;
    if (frame == null || frame.id.isEmpty) {
      avatar = SizedBox(width: w, height: w, child: inner);
    } else {
      avatar = SizedBox(
        width: w,
        height: w,
        child:
            frame.special
                ? _AnimatedSpecialFrame(
                  frame: frame,
                  radius: radius,
                  child: inner,
                )
                : Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: frame.color, width: 2.2),
                  ),
                  child: inner,
                ),
      );
    }
    if (!idle) return avatar;
    return _AvatarIdle(phase: (id.hashCode.abs() % 628) / 100.0, child: avatar);
  }
}

/// Idle life for [FramedAvatar] — one slow loop (~4s): the portrait
/// breathes (scale ±1.8%), sways ±1.3°, and bobs ~1px on the
/// double-time. Static under reduced-motion.
class _AvatarIdle extends StatefulWidget {
  const _AvatarIdle({required this.phase, required this.child});
  final double phase;
  final Widget child;

  @override
  State<_AvatarIdle> createState() => _AvatarIdleState();
}

class _AvatarIdleState extends State<_AvatarIdle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4000),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Don't burn vsync under reduced-motion — build returns the
    // static child, so the controller has nothing to drive.
    // (Offscreen TickerMode-muted tickers already stop scheduling
    // frames on their own — no extra gating needed.)
    if (MediaQuery.disableAnimationsOf(context)) {
      _ctrl.stop();
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = _ctrl.value * math.pi * 2 + widget.phase;
        return Transform.translate(
          offset: Offset(0, math.sin(t * 2) * 0.9),
          child: Transform.rotate(
            angle: math.sin(t) * 0.022,
            child: Transform.scale(
              scale: 1 + math.sin(t) * 0.018,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// One widget per special frame — animated border painters.
class _AnimatedSpecialFrame extends StatefulWidget {
  const _AnimatedSpecialFrame({
    required this.frame,
    required this.radius,
    required this.child,
  });
  final AvatarFrameStyle frame;
  final double radius;
  final Widget child;

  @override
  State<_AnimatedSpecialFrame> createState() => _AnimatedSpecialFrameState();
}

class _AnimatedSpecialFrameState extends State<_AnimatedSpecialFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced-motion renders one composed frame — don't burn vsync.
    if (MediaQuery.disableAnimationsOf(context)) {
      _ctrl.stop();
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget frame(double t) => CustomPaint(
      painter: _SpecialFramePainter(
        style: widget.frame.id,
        t: t,
        radius: widget.radius,
      ),
      child: Padding(padding: const EdgeInsets.all(3), child: widget.child),
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      // Static composed frame at a pleasant mid-animation point.
      return RepaintBoundary(child: frame(0.37));
    }
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) => frame(_ctrl.value),
      ),
    );
  }
}

/// Paints each special border — every style has a distinct animation.
class _SpecialFramePainter extends CustomPainter {
  _SpecialFramePainter({
    required this.style,
    required this.t,
    required this.radius,
  });
  final String style;
  final double t;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    // Square frame path — matches the square clip; corners get full
    // border coverage so no white edges show.
    final r = RRect.fromRectAndRadius(Offset.zero & size, Radius.zero);
    final p = Paint()..style = PaintingStyle.stroke;

    switch (style) {
      case 'gold':
        // Rotating metallic sheen — warm gold gradient sweeping around.
        p.shader = SweepGradient(
          colors: const [
            Color(0xFFFFD700),
            Color(0xFFFFF8DC),
            Color(0xFFB8860B),
            Color(0xFFFFD700),
          ],
          transform: GradientRotation(t * math.pi * 2),
        ).createShader(Offset.zero & size);
        p.strokeWidth = 3;
        canvas.drawRRect(r, p);
      case 'silver':
        p.shader = SweepGradient(
          colors: const [
            Color(0xFFC0C0C0),
            Color(0xFFFFFFFF),
            Color(0xFF808080),
            Color(0xFFC0C0C0),
          ],
          transform: GradientRotation(t * math.pi * 2),
        ).createShader(Offset.zero & size);
        p.strokeWidth = 3;
        canvas.drawRRect(r, p);
      case 'rainbow':
        p.shader = SweepGradient(
          colors: [
            Colors.red,
            Colors.orange,
            Colors.yellow,
            Colors.green,
            Colors.cyan,
            Colors.blue,
            Colors.purple,
            Colors.red,
          ],
          transform: GradientRotation(t * math.pi * 2),
        ).createShader(Offset.zero & size);
        p.strokeWidth = 3;
        canvas.drawRRect(r, p);
      case 'cursed':
        // Flickering void border — opacity pulses irregularly.
        final flick = 0.45 + 0.55 * (0.5 + 0.5 * math.sin(t * math.pi * 6));
        p.color = const Color(0xFF7B1FA2).withValues(alpha: flick);
        p.strokeWidth = 3.5;
        canvas.drawRRect(r, p);
        // Inner ember line, phase-shifted.
        p.color = const Color(0xFFFF1744).withValues(alpha: flick * 0.5);
        p.strokeWidth = 1.2;
        canvas.drawRRect(r.deflate(2.5), p);
      case 'cool':
        // Breathing ice border.
        final pulse = 0.5 + 0.5 * math.sin(t * math.pi * 2);
        p.color =
            Color.lerp(const Color(0xFF4DD0E1), Colors.white, pulse * 0.6)!;
        p.strokeWidth = 2.5 + pulse * 1.2;
        canvas.drawRRect(r, p);
      case 'fiery':
        // Flaming gradient pulse — orange↔red breathing.
        final pulse = 0.5 + 0.5 * math.sin(t * math.pi * 3);
        p.shader = LinearGradient(
          colors: [
            const Color(0xFFFF5722),
            Color.lerp(
              const Color(0xFFFFC107),
              const Color(0xFFFF1744),
              pulse,
            )!,
            const Color(0xFFFF5722),
          ],
        ).createShader(Offset.zero & size);
        p.strokeWidth = 2.5 + pulse;
        canvas.drawRRect(r, p);
      case 'cosmic':
        // Violet border + twinkling star dots orbiting.
        p.color = const Color(0xFF5E35B1).withValues(alpha: 0.9);
        p.strokeWidth = 2.5;
        canvas.drawRRect(r, p);
        final star = Paint()..color = Colors.white;
        for (var i = 0; i < 5; i++) {
          final a = t * math.pi * 2 + i * math.pi * 2 / 5;
          final tw = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(a * 3 + i));
          final x = size.width / 2 + (size.width / 2 - 2) * math.cos(a) * 0.92;
          final y =
              size.height / 2 + (size.height / 2 - 2) * math.sin(a) * 0.92;
          star.color = Colors.white.withValues(alpha: tw);
          canvas.drawCircle(Offset(x, y), 1.6 + tw, star);
        }
      case 'glitch':
        // Datamosh jitter — double cyan/magenta border offsetting.
        final j = math.sin(t * math.pi * 14) * 1.5;
        p.color = const Color(0xFF00E5FF).withValues(alpha: 0.85);
        p.strokeWidth = 2;
        canvas.drawRRect(r.shift(Offset(j, 0)), p);
        p.color = const Color(0xFFFF4081).withValues(alpha: 0.7);
        canvas.drawRRect(r.shift(Offset(-j, 0)), p);
      case 'toxic':
        // Bubbling slime border — base line + rising bubble dots.
        p.color = const Color(0xFF76FF03).withValues(alpha: 0.8);
        p.strokeWidth = 2.5;
        canvas.drawRRect(r, p);
        final bub = Paint()..color = const Color(0xFFCCFF90);
        for (var i = 0; i < 7; i++) {
          final phase = (t + i / 7) % 1.0;
          final edge = (i * 37) % 4; // 0 top 1 right 2 bottom 3 left
          final pos = phase;
          double x, y;
          switch (edge) {
            case 0:
              x = size.width * pos;
              y = 1.5;
            case 1:
              x = size.width - 1.5;
              y = size.height * pos;
            case 2:
              x = size.width * (1 - pos);
              y = size.height - 1.5;
            default:
              x = 1.5;
              y = size.height * (1 - pos);
          }
          bub.color = const Color(
            0xFFCCFF90,
          ).withValues(alpha: 0.9 - phase * 0.7);
          canvas.drawCircle(Offset(x, y), 1.4 + phase * 1.6, bub);
        }
      case 'storm':
        // Lightning flicker — border strobes white/blue irregularly.
        final flick =
            (math.sin(t * math.pi * 22) * math.sin(t * math.pi * 7) + 1) / 2;
        p.color = Color.lerp(
          const Color(0xFF3949AB),
          Colors.white,
          flick,
        )!.withValues(alpha: 0.55 + flick * 0.45);
        p.strokeWidth = 2 + flick * 1.6;
        canvas.drawRRect(r, p);
        // Occasional bolt tick across the top edge.
        if (flick > 0.86) {
          final bolt =
              Paint()
                ..color = Colors.white.withValues(alpha: (flick - 0.86) * 5)
                ..strokeWidth = 1.4;
          final bx = size.width * (0.2 + 0.6 * ((t * 7) % 1));
          canvas.drawLine(
            Offset(bx, 0),
            Offset(bx + 4, size.height * 0.35),
            bolt,
          );
        }
      case 'royal':
        // Crown orbit — slow rotating dashed ring + jewel dots.
        p.color = const Color(0xFFCE93D8).withValues(alpha: 0.85);
        p.strokeWidth = 2;
        final rr = r;
        final path = Path()..addRRect(rr);
        for (final m in path.computeMetrics()) {
          var d = 0.0;
          while (d < m.length) {
            final e = (d + 4).clamp(0.0, m.length);
            if ((d / 8 + t * 4) % 2 < 1) {
              canvas.drawPath(m.extractPath(d, e), p);
            }
            d += 8;
          }
        }
        final jewel = Paint()..color = const Color(0xFFFFD700);
        for (var i = 0; i < 3; i++) {
          final a = t * math.pi * 2 + i * math.pi * 2 / 3;
          final x = size.width / 2 + (size.width / 2 - 3) * math.cos(a) * 0.9;
          final y = size.height / 2 + (size.height / 2 - 3) * math.sin(a) * 0.9;
          jewel.color = const Color(
            0xFFFFD700,
          ).withValues(alpha: 0.6 + 0.4 * math.sin(a * 2));
          canvas.drawCircle(Offset(x, y), 1.8, jewel);
        }
      case 'neon':
        // Split neon — cyan left edge, magenta right, pulsing seam.
        final pulse = 0.5 + 0.5 * math.sin(t * math.pi * 4);
        final mid = size.width / 2;
        p.strokeWidth = 2.4;
        p.color = const Color(
          0xFF18FFFF,
        ).withValues(alpha: 0.75 + pulse * 0.25);
        canvas.drawLine(Offset(0, 0), Offset(mid, 0), p);
        canvas.drawLine(
          Offset(mid, 0),
          Offset(size.width, 0),
          Paint()
            ..color = const Color(
              0xFFFF4081,
            ).withValues(alpha: 0.75 + (1 - pulse) * 0.25)
            ..strokeWidth = 2.4,
        );
        canvas.drawLine(
          Offset(size.width, 0),
          Offset(size.width, size.height),
          Paint()
            ..color = const Color(
              0xFF18FFFF,
            ).withValues(alpha: 0.75 + pulse * 0.25)
            ..strokeWidth = 2.4,
        );
        canvas.drawLine(
          Offset(size.width, size.height),
          Offset(0, size.height),
          Paint()
            ..color = const Color(
              0xFFFF4081,
            ).withValues(alpha: 0.75 + (1 - pulse) * 0.25)
            ..strokeWidth = 2.4,
        );
        canvas.drawLine(
          Offset(0, size.height),
          Offset(0, 0),
          Paint()
            ..color = const Color(
              0xFF18FFFF,
            ).withValues(alpha: 0.75 + pulse * 0.25)
            ..strokeWidth = 2.4,
        );
    }
  }

  @override
  bool shouldRepaint(_SpecialFramePainter old) => old.t != t;
}
