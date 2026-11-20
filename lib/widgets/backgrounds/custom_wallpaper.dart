import 'package:flutter/material.dart';

import '../../services/app_theme.dart';
import '../theme_overlay.dart';

/// Bundled-image wallpaper for the custom theme — drawn over the flat
/// scaffold base color with a readability scrim so panels and text stay
/// legible on top of busy art. Used app-wide by [ThemeOverlay] and in
/// the studio's preview panes.
///
/// When `VisualPrefs.wallpaperImmersive` is on, the image gets a slow
/// breathing zoom plus device-tilt parallax (the shared smoothed
/// accelerometer stream) so the backdrop feels physically present.
/// The scrim stays locked full-frame — only the art moves. Honors
/// `MediaQuery.disableAnimationsOf` with a static composed frame.
class CustomWallpaper extends StatefulWidget {
  /// File name inside `assets/images/wallpapers/custom/` (e.g. `wp_07.webp`).
  final String assetFileName;

  /// Color used for the readability scrim — pass the theme's scaffold.
  final Color scrimColor;

  /// Scrim strength 0–1. Higher = more washed-out art, safer text.
  final double scrimStrength;

  /// Extra bottom-edge darkening (0–1) — keeps lower-screen UI readable
  /// on bright wallpapers.
  final double bottomShade;

  const CustomWallpaper({
    super.key,
    required this.assetFileName,
    required this.scrimColor,
    this.scrimStrength = 0.62,
    this.bottomShade = 0.16,
  });

  static String assetPath(String fileName) =>
      'assets/images/wallpapers/custom/$fileName';

  @override
  State<CustomWallpaper> createState() => _CustomWallpaperState();
}

class _CustomWallpaperState extends State<CustomWallpaper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _zoom;
  Offset _tilt = Offset.zero;

  /// Base overscan — the image always renders ~18% larger than the
  /// frame so zoom + parallax never expose an edge.
  static const _overscan = 1.18;

  /// Zoom breathing range on top of overscan (1.00 → 1.045 → 1.00).
  static const _zoomMin = 1.0;
  static const _zoomMax = 1.045;

  /// Parallax travel in px at full tilt (±10 → ±16px).
  static const _parallaxPerUnit = 1.6;

  @override
  void initState() {
    super.initState();
    _zoom = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    ThemeOverlay.tiltNotifier.addListener(_onTilt);
  }

  void _onTilt() => _tilt = ThemeOverlay.tiltNotifier.value;

  @override
  void dispose() {
    ThemeOverlay.tiltNotifier.removeListener(_onTilt);
    _zoom.dispose();
    super.dispose();
  }

  void _syncMotion(bool immersive, bool still) {
    if (immersive && !still) {
      if (!_zoom.isAnimating) _zoom.repeat(reverse: true);
    } else {
      _zoom.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return ValueListenableBuilder<VisualPrefs>(
      valueListenable: VisualPrefs.notifier,
      builder: (context, prefs, _) {
        final immersive = prefs.wallpaperImmersive;
        _syncMotion(immersive, still);
        return Stack(
          fit: StackFit.expand,
          children: [
            // Image layer — the only thing that moves in immersive mode.
            Positioned.fill(
              child: ClipRect(
                child: immersive
                    ? AnimatedBuilder(
                      animation: _zoom,
                      builder: (context, _) {
                        final t = still ? 0.5 : _zoom.value;
                        final zoom =
                            _overscan *
                            (_zoomMin +
                                (_zoomMax - _zoomMin) *
                                    (still ? 0.5 : t));
                        final pan = still
                            ? Offset.zero
                            : Offset(
                              -_tilt.dx * _parallaxPerUnit,
                              -_tilt.dy * _parallaxPerUnit * 0.6,
                            );
                        return Transform.translate(
                          offset: pan,
                          child: Transform.scale(
                            scale: zoom,
                            child: _wallpaperImage(),
                          ),
                        );
                      },
                    )
                    : _wallpaperImage(),
              ),
            ),
            // Scrim + bottom shade — locked to the frame, never move.
            Positioned.fill(
              child: ColoredBox(
                color: widget.scrimColor.withValues(
                  alpha: widget.scrimStrength.clamp(0.0, 1.0),
                ),
              ),
            ),
            if (widget.bottomShade > 0)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(
                          alpha: widget.bottomShade.clamp(0.0, 1.0),
                        ),
                      ],
                      stops: const [0.55, 1.0],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _wallpaperImage() {
    return Image.asset(
      CustomWallpaper.assetPath(widget.assetFileName),
      fit: BoxFit.cover,
      // Sources are ≤1280px — decoding at 1080 wide keeps full
      // quality while halving GPU texture memory.
      cacheWidth: 1080,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
