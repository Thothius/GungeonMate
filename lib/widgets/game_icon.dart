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
    final color = quality.isEmpty
        ? Colors.white24
        : QualityBadge.colorFor(quality);

    final inner = (assetPath.isNotEmpty && assetPath.startsWith('assets/'))
        ? Image.asset(
            assetPath,
            width: size * 0.72,
            height: size * 0.72,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none, // crisp pixel art
            errorBuilder: (_, __, ___) =>
                Icon(fallback, size: size * 0.58, color: Colors.white),
          )
        : Icon(fallback, size: size * 0.58, color: Colors.white);

    if (!showRing) {
      return SizedBox(width: size, height: size, child: Center(child: inner));
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.5),
      ),
      child: inner,
    );
  }
}
