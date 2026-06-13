import 'package:flutter/material.dart';

/// Rank-tier badge. Colors match the in-game chest tiers:
///   S → black pill, white label, golden glow (animated)
///   A → red
///   B → green
///   C → blue
///   D → grey
///   N → purple (starter / Junk)
class QualityBadge extends StatefulWidget {
  final String quality;
  final double size;
  const QualityBadge({super.key, required this.quality, this.size = 20});

  static String _displayLetter(String q) {
    final u = q.toUpperCase();
    if (u == '1S') return 'S';
    return u;
  }

  static bool _isS(String q) {
    final u = q.toUpperCase();
    return u == 'S' || u == '1S';
  }

  /// Pill background color. S returns near-black; others return their tier hue.
  static Color colorFor(String q) {
    switch (q.toUpperCase()) {
      case 'S':
      case '1S':
        return const Color(0xFFFFD700); // Bright premium gold instead of dark near-black
      case 'A':
        return const Color(0xFFE53935); // red
      case 'B':
        return const Color(0xFF43A047); // green
      case 'C':
        return const Color(0xFF1E88E5); // blue
      case 'D':
        return const Color(0xFF757575); // grey
      case 'N':
        return const Color(0xFF5E35B1); // purple (starter)
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  State<QualityBadge> createState() => _QualityBadgeState();
}

class _QualityBadgeState extends State<QualityBadge>
    with SingleTickerProviderStateMixin {
  AnimationController? _glow;

  @override
  void initState() {
    super.initState();
    if (QualityBadge._isS(widget.quality)) {
      _glow = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800),
      )..repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant QualityBadge old) {
    super.didUpdateWidget(old);
    final wantsGlow = QualityBadge._isS(widget.quality);
    if (wantsGlow && _glow == null) {
      _glow = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800),
      )..repeat(reverse: true);
    } else if (!wantsGlow && _glow != null) {
      _glow!.dispose();
      _glow = null;
    }
  }

  @override
  void dispose() {
    _glow?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quality.isEmpty) return const SizedBox.shrink();
    final s = widget.size;
    final bg = QualityBadge.colorFor(widget.quality);
    final letter = QualityBadge._displayLetter(widget.quality);
    final isS = QualityBadge._isS(widget.quality);

    final badge = Container(
      width: s,
      height: s,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: isS
            ? Border.all(color: const Color(0xFFE0E0E0), width: 1.6) // Silver/white fatter frame
            : null,
      ),
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.white,
          fontSize: s * 0.55,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    );

    if (!isS || _glow == null) return badge;

    return AnimatedBuilder(
      animation: _glow!,
      builder: (_, child) {
        final t = _glow!.value;
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFFFFF).withValues(alpha: 0.3 + 0.4 * t), // Silver/white glow
                blurRadius: 4 + 8 * t,
                spreadRadius: 0.5 + t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: badge,
    );
  }
}
