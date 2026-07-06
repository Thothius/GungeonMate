import 'package:flutter/material.dart';

/// A tiny badge of honor. Slapped on any gun a human has personally
/// squinted at next to the wiki page and gone "yep, checks out." 🐻
///
/// Cute, hearty, and completely unnecessary — which is exactly why it
/// exists (ponytail rule 1 says skip it, but some things are worth it).
class NeckbearMedal extends StatelessWidget {
  final double size;
  const NeckbearMedal({super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: "Neckbear's Approval — stats double-checked vs. the wiki!",
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFFFFE0B2), Color(0xFF8D5B2D), Color(0xFF5D3A1A)],
            stops: [0.0, 0.6, 1.0],
          ),
          border: Border.all(color: const Color(0xFFFFD54F), width: 1.1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.4),
              blurRadius: 3,
            ),
          ],
        ),
        child: Text(
          '🐻',
          style: TextStyle(fontSize: size * 0.62, height: 1),
        ),
      ),
    );
  }
}
