import 'package:flutter/material.dart';

import '../services/elemental_tagger.dart';

/// Canonical elemental-property badge — tinted circle + element icon +
/// tooltip. This is the single visual language for fire/stun/explosive
/// etc. across the app: detail headers use [size] 28, compact list rows
/// pass a smaller size but keep the same icon-in-circle treatment.
class ElementBadge extends StatelessWidget {
  final ElementKind element;
  final double size;
  const ElementBadge({super.key, required this.element, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final iconSize = (size * 0.5).clamp(9.0, 18.0);
    return Tooltip(
      message: element.label,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: element.color.withValues(alpha: 0.14),
          shape: BoxShape.circle,
          border: Border.all(
            color: element.color.withValues(alpha: 0.45),
            width: 1.0,
          ),
        ),
        child: Icon(element.icon, size: iconSize, color: element.color),
      ),
    );
  }
}
