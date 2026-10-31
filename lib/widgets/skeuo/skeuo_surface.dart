import 'package:flutter/material.dart';

import '../../services/goop_talk_engine.dart';
import '../../services/haptics.dart';
import '../../theme/tokens.dart';
import 'skeuo_tokens.dart';

/// Surface elevation for the Neo-Skeuo kit — mirrors the reference
/// sheet's four foundation tiles.
enum SkeuoElevation {
  /// Flat paper — border only, no shadow.
  base,

  /// Offset hatched shadow (kit level 1).
  raised,

  /// Deeper offset hatched shadow (kit level 2).
  high,

  /// Recessed well — inset paper fill + inner double border.
  inset,

  /// Sunken state — thick border, shadow nearly collapsed.
  pressed,
}

/// How the offset shadow is filled — the reference mixes both.
enum SkeuoShadowStyle {
  /// Diagonal ink hatch lines (the kit's signature).
  hatch,

  /// Solid ink block (primary buttons in the reference).
  solid,
}

/// The skeuo surface — an ink-stroked paper panel with an offset
/// hatched/solid shadow. All skeuo chrome is built on this.
///
/// Layout reserves [SkeuoTokens]' shadow room on the right and bottom
/// so the shadow paints inside the widget's bounds; the card slides
/// down-right as [pressT] rises (real skeuo press physics).
class SkeuoSurface extends StatelessWidget {
  final Widget child;
  final SkeuoElevation elevation;
  final SkeuoShadowStyle shadowStyle;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double? borderWidth;
  final Color? fill;
  final double pressT;

  /// Sketch double-stroke on the border. Off for crisp kit lines.
  final bool sketchy;

  const SkeuoSurface({
    super.key,
    required this.child,
    this.elevation = SkeuoElevation.raised,
    this.shadowStyle = SkeuoShadowStyle.hatch,
    this.padding = const EdgeInsets.all(16),
    this.radius = Skeuo.rMd,
    this.borderWidth,
    this.fill,
    this.pressT = 0,
    this.sketchy = true,
  });

  double get _maxShadow => switch (elevation) {
    SkeuoElevation.high => Skeuo.shadowMed,
    SkeuoElevation.raised => Skeuo.shadowLow,
    SkeuoElevation.pressed => Skeuo.shadowLow,
    _ => 0,
  };

  double get _offset => elevation == SkeuoElevation.pressed ? 1.2 : _maxShadow;

  @override
  Widget build(BuildContext context) {
    final maxShadow = _maxShadow;
    final offset = _offset;
    final shift = maxShadow - offset;
    final inner = elevation == SkeuoElevation.inset;
    final thick = elevation == SkeuoElevation.pressed;

    return CustomPaint(
      painter: _SkeuoSurfacePainter(
        fill: fill ?? (inner ? Skeuo.insetPaper : Skeuo.card),
        radius: radius,
        borderWidth: borderWidth ?? (thick ? 3.0 : Skeuo.borderMed),
        maxShadow: maxShadow,
        shadowOffset: offset,
        shadowStyle: shadowStyle,
        innerStroke: inner,
        pressT: pressT,
        sketchy: sketchy,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: padding.resolve(TextDirection.ltr).left + shift,
          top: padding.resolve(TextDirection.ltr).top + shift,
          right: padding.resolve(TextDirection.ltr).right + maxShadow - shift,
          bottom: padding.resolve(TextDirection.ltr).bottom + maxShadow - shift,
        ),
        child: child,
      ),
    );
  }
}

/// Paints shadow hatch → card fill → border (optionally sketch
/// double-stroke) → inset inner stroke → pressed top shading.
class _SkeuoSurfacePainter extends CustomPainter {
  final Color fill;
  final double radius;
  final double borderWidth;
  final double maxShadow;
  final double shadowOffset;
  final SkeuoShadowStyle shadowStyle;
  final bool innerStroke;
  final double pressT;
  final bool sketchy;

  const _SkeuoSurfacePainter({
    required this.fill,
    required this.radius,
    required this.borderWidth,
    required this.maxShadow,
    required this.shadowOffset,
    required this.shadowStyle,
    required this.innerStroke,
    required this.pressT,
    required this.sketchy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final shift = maxShadow - shadowOffset;
    final card = Rect.fromLTRB(
      shift,
      shift,
      size.width - maxShadow + shift,
      size.height - maxShadow + shift,
    );
    final cardRRect = RRect.fromRectAndRadius(card, Radius.circular(radius));
    final inkPaint =
        Paint()
          ..color = Skeuo.ink
          ..isAntiAlias = true;

    // 1. Offset shadow — hatch lines or solid block. Only the strip not
    //    covered by the card remains visible (bottom-right edge).
    if (shadowOffset > 0.01) {
      final shadow = card.shift(Offset(shadowOffset, shadowOffset));
      final shadowRRect = RRect.fromRectAndRadius(
        shadow,
        Radius.circular(radius),
      );
      canvas.save();
      canvas.clipRRect(shadowRRect);
      if (shadowStyle == SkeuoShadowStyle.solid) {
        canvas.drawPaint(inkPaint..color = Skeuo.ink);
      } else {
        final hatch =
            Paint()
              ..color = Skeuo.ink
              ..strokeWidth = 1.2
              ..isAntiAlias = true;
        for (
          var x = shadow.left - shadow.height;
          x < shadow.right;
          x += Skeuo.hatchGap
        ) {
          canvas.drawLine(
            Offset(x, shadow.top),
            Offset(x + shadow.height, shadow.bottom),
            hatch,
          );
        }
      }
      canvas.restore();
    }

    // 2. Card fill.
    canvas.drawRRect(
      cardRRect,
      Paint()
        ..color = fill
        ..isAntiAlias = true,
    );

    // 3. Border — main stroke + a faint shifted second stroke for the
    //    hand-drawn double-line feel (deterministic, no per-frame jitter).
    canvas.drawRRect(
      cardRRect,
      inkPaint
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..color = Skeuo.ink,
    );
    if (sketchy) {
      canvas.drawRRect(
        cardRRect.shift(const Offset(0.45, 0.4)).inflate(borderWidth * 0.15),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (borderWidth * 0.55).clamp(0.7, 2.0)
          ..color = Skeuo.ink.withValues(alpha: 0.28)
          ..isAntiAlias = true,
      );
    }

    // 4. Inset double border — recessed wells get a second inner rule.
    if (innerStroke) {
      canvas.drawRRect(
        cardRRect.deflate(3),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = Skeuo.borderThin
          ..color = Skeuo.ink.withValues(alpha: 0.55)
          ..isAntiAlias = true,
      );
    }

    // 5. Pressed shading — ink pools along the top inner edge as the
    //    card sinks into its shadow.
    if (pressT > 0.01) {
      canvas.save();
      canvas.clipRRect(cardRRect);
      final shade =
          Paint()
            ..color = Skeuo.ink.withValues(alpha: 0.14 * pressT)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawRect(
        Rect.fromLTRB(card.left, card.top, card.right, card.top + 8),
        shade,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SkeuoSurfacePainter old) =>
      old.fill != fill ||
      old.radius != radius ||
      old.borderWidth != borderWidth ||
      old.maxShadow != maxShadow ||
      old.shadowOffset != shadowOffset ||
      old.shadowStyle != shadowStyle ||
      old.innerStroke != innerStroke ||
      old.pressT != pressT ||
      old.sketchy != sketchy;
}

/// The skeuo button — presses physically into the page: the card
/// slides down-right into its shadow while ink shades the top edge.
/// [SkeuoButtonStyle.primary] is the reference's ink-filled hero.
enum SkeuoButtonStyle { primary, outline, disabled }

class SkeuoButton extends StatefulWidget {
  final String? label;
  final Widget? child;
  final IconData? icon;
  final VoidCallback? onTap;
  final SkeuoButtonStyle style;
  final bool loading;
  final double? height;
  final double radius;
  final EdgeInsetsGeometry padding;

  /// Hug the content instead of expanding to the widest constraint.
  final bool compact;

  const SkeuoButton({
    super.key,
    this.label,
    this.child,
    this.icon,
    this.onTap,
    this.style = SkeuoButtonStyle.outline,
    this.loading = false,
    this.height,
    this.radius = Skeuo.rMd,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.compact = false,
  }) : assert(label != null || child != null, 'needs a label or child');

  /// Filled ink hero button — the reference's Primary.
  const SkeuoButton.primary({
    super.key,
    this.label,
    this.child,
    this.icon,
    this.onTap,
    this.loading = false,
    this.height,
    this.radius = Skeuo.rMd,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.compact = false,
  }) : style = SkeuoButtonStyle.primary,
       assert(label != null || child != null, 'needs a label or child');

  /// Ghosted, non-interactive — the reference's Disabled.
  const SkeuoButton.disabled({
    super.key,
    this.label,
    this.child,
    this.icon,
    this.height,
    this.radius = Skeuo.rMd,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.compact = false,
  }) : onTap = null,
       loading = false,
       style = SkeuoButtonStyle.disabled,
       assert(label != null || child != null, 'needs a label or child');

  @override
  State<SkeuoButton> createState() => _SkeuoButtonState();
}

class _SkeuoButtonState extends State<SkeuoButton> {
  bool _pressed = false;

  bool get _enabled =>
      widget.style != SkeuoButtonStyle.disabled &&
      widget.onTap != null &&
      !widget.loading;

  bool get _isPrimary => widget.style == SkeuoButtonStyle.primary;
  bool get _isDisabled => widget.style == SkeuoButtonStyle.disabled;

  @override
  Widget build(BuildContext context) {
    final fg =
        _isPrimary
            ? Skeuo.paper
            : _isDisabled
            ? Skeuo.pencil
            : Skeuo.ink;

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg),
            ),
          )
        else if (widget.icon != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(widget.icon, size: 18, color: fg),
          ),
        Flexible(
          child:
              widget.child ??
              FittedBox(
                fit: BoxFit.scaleDown,
                child: GoopText(
                  widget.label!,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: fg,
                  ),
                ),
              ),
        ),
      ],
    );

    final pad = widget.padding.resolve(TextDirection.ltr);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: _pressed ? 1 : 0),
      duration: Motion.fast,
      curve: Curves.easeOut,
      builder: (context, t, _) {
        final offset = _isDisabled ? 0.0 : lerp(Skeuo.shadowLow, 1.2, t);
        final shift = _isDisabled ? 0.0 : Skeuo.shadowLow - offset;
        final fill =
            _isPrimary
                ? Skeuo.ink
                : _isDisabled
                ? Skeuo.paper
                : Skeuo.card;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown:
              _enabled
                  ? (_) {
                    setState(() => _pressed = true);
                    Haptics.light();
                  }
                  : null,
          onTapUp:
              _enabled
                  ? (_) {
                    setState(() => _pressed = false);
                    Haptics.selection();
                    widget.onTap!();
                  }
                  : null,
          onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
          child: CustomPaint(
            painter: _SkeuoSurfacePainter(
              fill: fill,
              radius: widget.radius,
              borderWidth: _isDisabled ? Skeuo.borderThin : Skeuo.borderMed + t,
              maxShadow: _isDisabled ? 0 : Skeuo.shadowLow,
              shadowOffset: offset,
              shadowStyle:
                  _isPrimary ? SkeuoShadowStyle.solid : SkeuoShadowStyle.hatch,
              innerStroke: false,
              pressT: t,
              sketchy: !_isPrimary,
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: pad.left + shift,
                top: pad.top + shift,
                right: pad.right + Skeuo.shadowLow - shift,
                bottom: pad.bottom + Skeuo.shadowLow - shift,
              ),
              child:
                  widget.height != null
                      ? SizedBox(
                        height: widget.height,
                        child: Center(child: content),
                      )
                      : (widget.compact ? content : Center(child: content)),
            ),
          ),
        );
      },
    );
  }

  static double lerp(double a, double b, double t) => a + (b - a) * t;
}
