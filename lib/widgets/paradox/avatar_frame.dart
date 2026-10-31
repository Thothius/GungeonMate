import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../utils/asset_paths.dart';
import '../skeuo/skeuo_tokens.dart';

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
final kAvatarFrames = <AvatarFrameStyle>[
  AvatarFrameStyle('', 'NONE', Colors.transparent),
  AvatarFrameStyle('violet', 'VIOLET', Skeuo.collapse(Color(0xFF7C4DFF))),
  AvatarFrameStyle('purple', 'PURPLE', Skeuo.collapse(Color(0xFF9C27B0))),
  AvatarFrameStyle('pink', 'PINK', Skeuo.collapse(Color(0xFFEC407A))),
  AvatarFrameStyle('red', 'RED', Skeuo.collapse(Color(0xFFE53935))),
  AvatarFrameStyle('orange', 'ORANGE', Skeuo.collapse(Color(0xFFFB8C00))),
  AvatarFrameStyle('amber', 'AMBER', Skeuo.collapse(Color(0xFFFFB300))),
  AvatarFrameStyle('green', 'GREEN', Skeuo.collapse(Color(0xFF43A047))),
  AvatarFrameStyle('teal', 'TEAL', Skeuo.collapse(Color(0xFF26A69A))),
  AvatarFrameStyle('cyan', 'CYAN', Skeuo.collapse(Color(0xFF00BCD4))),
  AvatarFrameStyle('blue', 'BLUE', Skeuo.collapse(Color(0xFF1E88E5))),
  AvatarFrameStyle('white', 'WHITE', Skeuo.collapse(Colors.white)),
  AvatarFrameStyle('onyx', 'ONYX', Skeuo.collapse(Color(0xFF424242))),
];

/// 8 special frames — animated, each unique.
final kSpecialFrames = <AvatarFrameStyle>[
  AvatarFrameStyle(
    'gold',
    'GOLD',
    Skeuo.collapse(Color(0xFFFFD700)),
    special: true,
  ),
  AvatarFrameStyle(
    'silver',
    'SILVER',
    Skeuo.collapse(Color(0xFFC0C0C0)),
    special: true,
  ),
  AvatarFrameStyle(
    'rainbow',
    'RAINBOW',
    Skeuo.collapse(Color(0xFFFF4081)),
    special: true,
  ),
  AvatarFrameStyle(
    'cursed',
    'CURSED',
    Skeuo.collapse(Color(0xFF7B1FA2)),
    special: true,
  ),
  AvatarFrameStyle(
    'cool',
    'COOL',
    Skeuo.collapse(Color(0xFF4DD0E1)),
    special: true,
  ),
  AvatarFrameStyle(
    'fiery',
    'FIERY',
    Skeuo.collapse(Color(0xFFFF5722)),
    special: true,
  ),
  AvatarFrameStyle(
    'cosmic',
    'COSMIC',
    Skeuo.collapse(Color(0xFF5E35B1)),
    special: true,
  ),
  AvatarFrameStyle(
    'glitch',
    'GLITCH',
    Skeuo.collapse(Color(0xFF00E5FF)),
    special: true,
  ),
];

AvatarFrameStyle? avatarFrameStyleOf(String id) {
  for (final f in [...kAvatarFrames, ...kSpecialFrames]) {
    if (f.id == id) return f;
  }
  return null;
}

/// Framed avatar portrait — resolves `avatarPath`, paints the picked
/// frame (animated for specials), falls back to a person icon.
class FramedAvatar extends StatelessWidget {
  const FramedAvatar({
    super.key,
    required this.id,
    this.size = 48,
    this.radius = 10,
  });

  final String id;
  final double size;
  final double radius;

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
                size: size * 0.6,
                color: Skeuo.collapse(Colors.white38),
              ),
        ),
      ),
    );
    if (frame == null || frame.id.isEmpty) {
      return SizedBox(width: w, height: w, child: inner);
    }
    return SizedBox(
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
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder:
            (_, child) => CustomPaint(
              painter: _SpecialFramePainter(
                style: widget.frame.id,
                t: _ctrl.value,
                radius: widget.radius,
              ),
              child: Padding(padding: const EdgeInsets.all(3), child: child),
            ),
        child: widget.child,
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
          colors: [
            Skeuo.collapse(Color(0xFFFFD700)),
            Skeuo.collapse(Color(0xFFFFF8DC)),
            Skeuo.collapse(Color(0xFFB8860B)),
            Skeuo.collapse(Color(0xFFFFD700)),
          ],
          transform: GradientRotation(t * math.pi * 2),
        ).createShader(Offset.zero & size);
        p.strokeWidth = 3;
        canvas.drawRRect(r, p);
      case 'silver':
        p.shader = SweepGradient(
          colors: [
            Skeuo.collapse(Color(0xFFC0C0C0)),
            Skeuo.collapse(Color(0xFFFFFFFF)),
            Skeuo.collapse(Color(0xFF808080)),
            Skeuo.collapse(Color(0xFFC0C0C0)),
          ],
          transform: GradientRotation(t * math.pi * 2),
        ).createShader(Offset.zero & size);
        p.strokeWidth = 3;
        canvas.drawRRect(r, p);
      case 'rainbow':
        p.shader = SweepGradient(
          colors: [
            Skeuo.inkIf(Colors.red),
            Skeuo.inkIf(Colors.orange),
            Skeuo.inkIf(Colors.yellow),
            Skeuo.inkIf(Colors.green),
            Skeuo.inkIf(Colors.cyan),
            Skeuo.inkIf(Colors.blue),
            Skeuo.inkIf(Colors.purple),
            Skeuo.inkIf(Colors.red),
          ],
          transform: GradientRotation(t * math.pi * 2),
        ).createShader(Offset.zero & size);
        p.strokeWidth = 3;
        canvas.drawRRect(r, p);
      case 'cursed':
        // Flickering void border — opacity pulses irregularly.
        final flick = 0.45 + 0.55 * (0.5 + 0.5 * math.sin(t * math.pi * 6));
        p.color = Skeuo.collapse(Color(0xFF7B1FA2)).withValues(alpha: flick);
        p.strokeWidth = 3.5;
        canvas.drawRRect(r, p);
        // Inner ember line, phase-shifted.
        p.color = Skeuo.collapse(
          Color(0xFFFF1744),
        ).withValues(alpha: flick * 0.5);
        p.strokeWidth = 1.2;
        canvas.drawRRect(r.deflate(2.5), p);
      case 'cool':
        // Breathing ice border.
        final pulse = 0.5 + 0.5 * math.sin(t * math.pi * 2);
        p.color =
            Color.lerp(
              Skeuo.collapse(Color(0xFF4DD0E1)),
              Skeuo.collapse(Colors.white),
              pulse * 0.6,
            )!;
        p.strokeWidth = 2.5 + pulse * 1.2;
        canvas.drawRRect(r, p);
      case 'fiery':
        // Flaming gradient pulse — orange↔red breathing.
        final pulse = 0.5 + 0.5 * math.sin(t * math.pi * 3);
        p.shader = LinearGradient(
          colors: [
            Skeuo.collapse(Color(0xFFFF5722)),
            Color.lerp(
              Skeuo.collapse(Color(0xFFFFC107)),
              Skeuo.collapse(Color(0xFFFF1744)),
              pulse,
            )!,
            Skeuo.collapse(Color(0xFFFF5722)),
          ],
        ).createShader(Offset.zero & size);
        p.strokeWidth = 2.5 + pulse;
        canvas.drawRRect(r, p);
      case 'cosmic':
        // Violet border + twinkling star dots orbiting.
        p.color = Skeuo.collapse(Color(0xFF5E35B1)).withValues(alpha: 0.9);
        p.strokeWidth = 2.5;
        canvas.drawRRect(r, p);
        final star = Paint()..color = Skeuo.collapse(Colors.white);
        for (var i = 0; i < 5; i++) {
          final a = t * math.pi * 2 + i * math.pi * 2 / 5;
          final tw = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(a * 3 + i));
          final x = size.width / 2 + (size.width / 2 - 2) * math.cos(a) * 0.92;
          final y =
              size.height / 2 + (size.height / 2 - 2) * math.sin(a) * 0.92;
          star.color = Skeuo.collapse(Colors.white).withValues(alpha: tw);
          canvas.drawCircle(Offset(x, y), 1.6 + tw, star);
        }
      case 'glitch':
        // Datamosh jitter — double cyan/magenta border offsetting.
        final j = math.sin(t * math.pi * 14) * 1.5;
        p.color = Skeuo.collapse(Color(0xFF00E5FF)).withValues(alpha: 0.85);
        p.strokeWidth = 2;
        canvas.drawRRect(r.shift(Offset(j, 0)), p);
        p.color = Skeuo.collapse(Color(0xFFFF4081)).withValues(alpha: 0.7);
        canvas.drawRRect(r.shift(Offset(-j, 0)), p);
    }
  }

  @override
  bool shouldRepaint(_SpecialFramePainter old) => old.t != t;
}
