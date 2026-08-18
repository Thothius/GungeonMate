import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/app_theme.dart';
import '../../services/haptics.dart';

/// 2.5D volumetric wrapper for inventory tiles. Applies:
///
/// - **Perspective tilt** toward the touch/hover point (max ±8° scaled by
///   [VisualPrefs.depthTiltIntensity]). Springs back on release.
/// - **Layered depth shadow** whose blur + offset grow with tilt magnitude,
///   so the tile appears to lift off the surface.
/// - **Top-DPS idle float** — a slow ±3px bob (2s loop) when [isTopDps] is
///   true, so the "hero" gun reads as the prize.
/// - **Synergy glow pulse** — a breathing outer glow (1.4s loop) in
///   [glowColor] instead of a static border.
///
/// Wraps [child] without modifying its layout — the tilt is a paint-time
/// transform, so the child's hit-testing and intrinsic size are preserved.
///
/// Disabled entirely when `VisualPrefs.depthInventory` is false (renders
/// [child] as-is). Tilt magnitude scales with `depthTiltIntensity` (0 = flat).
class DepthTile extends StatefulWidget {
  final Widget child;
  final bool isTopDps;
  final Color? glowColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const DepthTile({
    super.key,
    required this.child,
    this.isTopDps = false,
    this.glowColor,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<DepthTile> createState() => _DepthTileState();
}

class _DepthTileState extends State<DepthTile>
    with TickerProviderStateMixin {
  // Tilt controller — 0 = resting, 1 = fully pressed/hovered.
  late final AnimationController _tilt;
  // Idle float for top-DPS — loops forever while mounted.
  late final AnimationController _float;
  // Synergy glow pulse — loops forever while a glow color is set.
  late final AnimationController _glow;

  // Normalized touch offset within the tile: (-1,-1) top-left → (1,1) bottom-right.
  // Drives the direction of the tilt. (0,0) = center → no tilt, just lift.
  Offset _touchOffset = Offset.zero;

  // Max tilt in radians (~8°). Scaled by VisualPrefs.depthTiltIntensity at
  // paint time so the slider takes effect without restarting the controller.
  static const double _maxTiltRad = 8.0 * math.pi / 180.0;

  @override
  void initState() {
    super.initState();
    _tilt = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 380),
    );
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _tilt.dispose();
    _float.dispose();
    _glow.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !mounted) return;
    final local = box.globalToLocal(details.globalPosition);
    final size = box.size;
    if (size.width == 0 || size.height == 0) return;
    // Normalize to [-1, 1] range. Touching the right edge tilts the right
    // side down (positive rotateY), touching the bottom tilts the bottom
    // down (negative rotateX — screen Y is inverted in Flutter's Matrix4).
    setState(() {
      _touchOffset = Offset(
        ((local.dx / size.width) * 2 - 1).clamp(-1.0, 1.0),
        ((local.dy / size.height) * 2 - 1).clamp(-1.0, 1.0),
      );
    });
    _tilt.forward();
    Haptics.light();
  }

  void _onTapUp(TapUpDetails _) => _release();
  void _onTapCancel() => _release();

  void _release() {
    if (!mounted) return;
    _tilt.reverse();
    setState(() => _touchOffset = Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    final prefs = VisualPrefs.notifier.value;
    final depthOn = prefs.depthInventory;
    final intensity = prefs.depthTiltIntensity;

    // Fast path: depth disabled → render child as-is (still wire gestures
    // so tap/long-press work identically to the wrapped case).
    if (!depthOn || intensity <= 0.01) {
      return GestureDetector(
        onTapDown: widget.onTap != null || widget.onLongPress != null
            ? _onTapDown
            : null,
        onTap: widget.onTap,
        onTapUp: widget.onTap != null ? _onTapUp : null,
        onTapCancel: widget.onTap != null ? _onTapCancel : null,
        onLongPress: widget.onLongPress,
        child: widget.child,
      );
    }

    return MouseRegion(
      onEnter: (_) {
        if (!mounted) return;
        _tilt.forward();
      },
      onExit: (_) {
        if (!mounted) return;
        if (!_tilt.isAnimating) _tilt.reverse();
      },
      onHover: (event) {
        if (!mounted) return;
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final local = box.globalToLocal(event.position);
        final size = box.size;
        if (size.width == 0 || size.height == 0) return;
        setState(() {
          _touchOffset = Offset(
            ((local.dx / size.width) * 2 - 1).clamp(-1.0, 1.0),
            ((local.dy / size.height) * 2 - 1).clamp(-1.0, 1.0),
          );
        });
      },
      child: GestureDetector(
        onTapDown: widget.onTap != null || widget.onLongPress != null
            ? _onTapDown
            : null,
        onTap: widget.onTap,
        onTapUp: widget.onTap != null ? _onTapUp : null,
        onTapCancel: widget.onTap != null ? _onTapCancel : null,
        onLongPress: widget.onLongPress,
        child: AnimatedBuilder(
          animation: Listenable.merge([_tilt, _float, _glow]),
          builder: (context, _) {
            final t = _tilt.value * intensity;
            // Tilt toward touch: right edge → rotateY positive, bottom edge
            // → rotateX negative (Flutter Y is down).
            final rotY = _touchOffset.dx * _maxTiltRad * t;
            final rotX = -_touchOffset.dy * _maxTiltRad * t;
            // Lift in Z — translates the tile toward the viewer by up to 6px.
            final lift = t * 6.0;
            // Idle float for top-DPS (±3px, smoothstep).
            final floatOffset = widget.isTopDps
                ? (Curves.easeInOut.transform(_float.value) * 2 - 1) * 3.0
                : 0.0;

            // Depth shadow grows with tilt — blur 4→16, offset 2→8.
            final shadowOpacity = 0.25 + t * 0.25;
            final shadowBlur = 4.0 + t * 12.0;
            final shadowOffset = 2.0 + t * 6.0;

            // Synergy glow pulse — breathing alpha 0.3↔0.6.
            final glowAlpha = widget.glowColor != null
                ? 0.3 + (Curves.easeInOut.transform(_glow.value) * 0.3)
                : 0.0;

            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.002) // perspective
                ..rotateX(rotX)
                ..rotateY(rotY)
                ..translate(0.0, floatOffset, lift),
              alignment: FractionalOffset.center,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: shadowOpacity),
                      blurRadius: shadowBlur,
                      offset: Offset(0, shadowOffset),
                    ),
                    if (widget.glowColor != null)
                      BoxShadow(
                        color: widget.glowColor!
                            .withValues(alpha: glowAlpha),
                        blurRadius: 12 + t * 8,
                        spreadRadius: 1 + t * 2,
                      ),
                  ],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}
