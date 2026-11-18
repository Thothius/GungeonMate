import 'package:flutter/material.dart';

/// Bundled-image wallpaper for the custom theme — drawn over the flat
/// scaffold base color with a readability scrim so panels and text stay
/// legible on top of busy art. Used app-wide by [ThemeOverlay] and in
/// the studio's preview panes.
class CustomWallpaper extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          assetPath(assetFileName),
          fit: BoxFit.cover,
          // Sources are ≤1280px — decoding at 1080 wide keeps full
          // quality while halving GPU texture memory.
          cacheWidth: 1080,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
        Positioned.fill(
          child: ColoredBox(
            color: scrimColor.withValues(alpha: scrimStrength.clamp(0.0, 1.0)),
          ),
        ),
        if (bottomShade > 0)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: bottomShade.clamp(0.0, 1.0)),
                  ],
                  stops: const [0.55, 1.0],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
