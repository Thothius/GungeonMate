import 'package:flutter/material.dart';
import '../services/app_theme.dart';

/// Role a [ThemedNumber] is playing in the UI. The widget adjusts its
/// colour (and for Curseblaster, its glow strength) based on the role
/// so every theme can react semantically:
///   - [headline] : big stat readouts (DPS, Guns, Items, Synergies)
///   - [coolness] : coolness counter — never glows, always the stat colour
///   - [curse]    : curse counter — glows red in Curseblaster, otherwise
///                   tinted like headline
enum ThemedNumberRole { headline, coolness, curse }

/// A number readout that adapts its typography to the active
/// [ThemeFlair]. Wraps a small `ValueListenableBuilder` so switching
/// themes at runtime re-styles every instance without manual plumbing.
///
/// When the active flair has [ThemeFlair.shimmerHeadline], a subtle
/// gold shimmer sweeps across the digit glyphs every ~8s. When
/// [ThemeFlair.glowCurse] and the role is [ThemedNumberRole.curse] with
/// a non-zero value, a red glow is painted behind the text with
/// strength scaling with the value.
class ThemedNumber extends StatelessWidget {
  final String value;

  /// Base font size before the flair's `numberSizeScale` multiplier.
  final double baseSize;

  /// Overrides the colour from the flair. Useful when the surrounding
  /// chip already tints by stat bracket (DPS green/red) and we just
  /// want the typographic styling — not the flair's accent colour.
  final Color? colorOverride;

  /// When [ThemedNumberRole.curse], the numeric curse value driving the
  /// glow strength in Curseblaster. Ignored by other themes/roles.
  final double curseValue;

  final ThemedNumberRole role;

  const ThemedNumber({
    super.key,
    required this.value,
    this.baseSize = 14,
    this.colorOverride,
    this.curseValue = 0,
    this.role = ThemedNumberRole.headline,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: AppTheme.notifier,
      builder: (_, __, ___) {
        final f = AppTheme.flair;
        final size = baseSize * f.numberSizeScale;
        final color = colorOverride ?? f.headlineStat;
        final style = TextStyle(
          fontSize: size,
          fontWeight: f.numberWeight,
          fontStyle: f.numberStyle,
          color: color,
          fontFeatures: f.tabularFigures
              ? const [FontFeature.tabularFigures()]
              : null,
          shadows: _shadowsFor(f),
        );
        Widget text = Text(value, style: style);

        if (f.glowCurse &&
            role == ThemedNumberRole.curse &&
            curseValue > 0) {
          // Scale glow with curse value — clamp at ~8 so a legendary
          // curse stack doesn't bloom past readability.
          final t = (curseValue / 8).clamp(0.15, 1.0).toDouble();
          text = Stack(
            alignment: Alignment.center,
            children: [
              // Outer soft halo via a blurred shadow-only Text copy.
              Text(
                value,
                style: style.copyWith(
                  color: Colors.transparent,
                  shadows: [
                    Shadow(
                      color: const Color(0xFFFF4757).withValues(alpha: t),
                      blurRadius: 12 + (t * 10),
                    ),
                  ],
                ),
              ),
              text,
            ],
          );
        }

        if (f.shimmerHeadline && role == ThemedNumberRole.headline) {
          text = _ShimmerOverlay(tint: f.primary, child: text);
        }

        return text;
      },
    );
  }

  List<Shadow>? _shadowsFor(ThemeFlair f) {
    if (!f.embossNumbers) return null;
    return const [
      // Dark bottom edge + light top edge = engraved metal look.
      Shadow(
        offset: Offset(0, 1),
        blurRadius: 0,
        color: Color(0x99000000),
      ),
      Shadow(
        offset: Offset(0, -0.5),
        blurRadius: 0.5,
        color: Color(0x33FFFFFF),
      ),
    ];
  }
}

/// Wraps a child in a ShaderMask that runs a translucent gold
/// highlight across it roughly every 8 seconds. Deliberately subtle —
/// the whole point is "did I just see that glimmer?", not Las Vegas.
class _ShimmerOverlay extends StatefulWidget {
  final Widget child;
  final Color tint;
  const _ShimmerOverlay({required this.child, required this.tint});

  @override
  State<_ShimmerOverlay> createState() => _ShimmerOverlayState();
}

class _ShimmerOverlayState extends State<_ShimmerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      // 8-second cycle. Most of it is "rest"; the sweep happens in the
      // last ~25%. Tuned so the eye registers it as a rare glimmer.
      duration: const Duration(seconds: 8),
    )..repeat();
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
      builder: (_, child) {
        final t = _c.value;
        // Rest phase: no mask, just draw the child.
        if (t < 0.75) return child!;
        // Sweep phase: slide the highlight across the glyphs.
        final slide = (t - 0.75) * 4; // 0..1 over the last 25%
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final dx = (slide * (bounds.width + 60)) - 30;
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.transparent,
                widget.tint.withValues(alpha: 0.65),
                Colors.transparent,
              ],
              stops: const [0.35, 0.5, 0.65],
              transform: _SlideTransform(dx),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Translates the shimmer gradient horizontally. Implemented as a
/// [GradientTransform] instead of a Matrix4 so we stay lightweight on
/// the paint path.
class _SlideTransform extends GradientTransform {
  final double dx;
  const _SlideTransform(this.dx);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.identity()..translate(dx, 0);
  }
}

/// Bullet glyph that twinkles for Unicorn (pulsing opacity) or stays
/// static for every other theme. Index argument staggers twinkles so
/// adjacent bullets don't pulse in lock-step.
class ThemedBullet extends StatefulWidget {
  final int index;
  final double size;
  const ThemedBullet({super.key, this.index = 0, this.size = 12});

  @override
  State<ThemedBullet> createState() => _ThemedBulletState();
}

class _ThemedBulletState extends State<ThemedBullet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: AppTheme.notifier,
      builder: (_, __, ___) {
        final f = AppTheme.flair;
        final glyph = Text(
          f.bulletGlyph,
          style: TextStyle(
            fontSize: widget.size,
            color: f.bulletColor,
            height: 1,
          ),
        );
        if (!f.twinkleBullets) return glyph;
        return AnimatedBuilder(
          animation: _c,
          builder: (_, child) {
            // Stagger with a small phase offset so neighbouring bullets
            // don't pulse together — looks like a starfield, not a
            // single blink.
            final phase = (_c.value + (widget.index * 0.37)) % 1;
            final tri = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
            return Opacity(opacity: 0.45 + 0.55 * tri, child: child);
          },
          child: glyph,
        );
      },
    );
  }
}
