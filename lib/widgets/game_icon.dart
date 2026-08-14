import 'package:flutter/material.dart';
import 'quality_badge.dart';

/// Renders a pixel-art sprite inside a quality-colored ring.
/// If [assetPath] is empty or fails to load, falls back to a Material [fallback]
/// icon inside the same ring.
class GameIcon extends StatelessWidget {
  final String assetPath;
  final IconData fallback;
  final String quality;
  final double size;
  final bool showRing;

  const GameIcon({
    super.key,
    this.assetPath = '',
    this.fallback = Icons.help_outline,
    this.quality = '',
    this.size = 44,
    this.showRing = true,
  });

  @override
  Widget build(BuildContext context) {
    final rawColor = quality.isEmpty
        ? Colors.white24
        : QualityBadge.colorFor(quality);
    // S-tier uses near-black for the filled badge, but near-black ring
    // chrome is invisible on dark panels. Use gold for the ring so S-tier
    // items/guns are clearly framed on any background.
    final isS = quality.toUpperCase() == 'S';
    final ringColor = isS ? const Color(0xFFFFD700) : rawColor;

    final imgScale = showRing ? 0.72 : 0.83;
    final iconScale = showRing ? 0.58 : 0.67;
    final inner = (assetPath.isNotEmpty && assetPath.startsWith('assets/'))
        ? Image.asset(
            assetPath,
            width: size * imgScale,
            height: size * imgScale,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none, // crisp pixel art
            errorBuilder: (_, __, ___) =>
                Icon(fallback, size: size * iconScale, color: Colors.white),
          )
        : (assetPath.isNotEmpty && assetPath.startsWith('http'))
            ? Image.network(
                assetPath,
                width: size * imgScale,
                height: size * imgScale,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none, // crisp pixel art
                errorBuilder: (_, __, ___) =>
                    Icon(fallback, size: size * iconScale, color: Colors.white),
              )
            : Icon(fallback, size: size * iconScale, color: Colors.white);

    if (!showRing) {
      return SizedBox(width: size, height: size, child: Center(child: inner));
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ringColor.withValues(alpha: 0.18),
        border: Border.all(
          color: ringColor.withValues(alpha: isS ? 0.85 : 0.55),
          width: isS ? 2.0 : 1.5,
        ),
      ),
      child: inner,
    );
  }
}
