import 'package:flutter/material.dart';

import '../../models/gun.dart';
import '../../models/item.dart';
import '../../services/elemental_tagger.dart';
import '../../services/goop_talk_engine.dart';

Widget metaPill(String text, Color color, {IconData? icon}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.45), width: 0.7),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
        ],
        // Flexible + ellipsis: a pill wider than the Wrap's run width
        // (COMPLETES with an owner label, long class names) ellipsizes
        // instead of overflowing the row horizontally.
        Flexible(
          child: GoopText(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
              height: 1.1,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Synergy Predictor pill — gold/amber badge shown on browse rows when
/// acquiring this item/gun would complete a partial synergy. Shows the
/// synergy name for a single completion, or a count for multiple.
Widget completesPill(List<String> synergyNames, {String? ownerLabel}) {
  if (synergyNames.isEmpty) return const SizedBox.shrink();
  // Truncate long synergy names — the raw label overflowed browse rows
  // by ~15px on narrow screens.
  final first = synergyNames.first;
  final short = first.length > 22 ? '${first.substring(0, 21)}…' : first;
  final owner = ownerLabel == null ? '' : ' · $ownerLabel';
  final label =
      synergyNames.length == 1
          ? 'COMPLETES: $short$owner'
          : 'COMPLETES ${synergyNames.length}$owner';
  return metaPill(label, const Color(0xFFFFD700), icon: Icons.link);
}

/// Compact element dot — same visual language as the active-run
/// inventory row: a small filled circle in the element's signature
/// color. Tooltip carries the label for accessibility.
class ElementDot extends StatelessWidget {
  final ElementKind element;
  final double size;
  const ElementDot({super.key, required this.element, this.size = 8});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: element.label,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: element.color, shape: BoxShape.circle),
      ),
    );
  }
}

/// Wrap of element dots for [elements], in canonical ElementKind order.
Widget elementDots(Set<ElementKind> elements) {
  if (elements.isEmpty) return const SizedBox.shrink();
  return Wrap(
    spacing: 4,
    runSpacing: 2,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      for (final e in ElementKind.values)
        if (elements.contains(e)) ElementDot(element: e),
    ],
  );
}

class GunMeta extends StatelessWidget {
  final Gun gun;
  final int synergyCount;
  final List<String> completesSynergies;
  final String? ownerLabel;

  /// Purple LEB badge — shown on browse rows when the browse-local
  /// Lich's Eye Bullets toggle is on and the gun has synergies.
  final bool lebBadge;
  const GunMeta({
    super.key,
    required this.gun,
    required this.synergyCount,
    this.completesSynergies = const [],
    this.ownerLabel,
    this.lebBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    // Slim row meta: element dots + contextual badges only. Class,
    // DPS, and price moved to the detail screen — at browse time the
    // scan signal is "what does it DO" (elements) and "does it complete
    // something" (COMPLETES), not the stat sheet.
    final elements = ElementalTagger.elementsOfGun(gun);
    final bits = <Widget>[
      elementDots(elements),
      if (lebBadge)
        metaPill('LEB', const Color(0xFFB388FF), icon: Icons.auto_awesome),
      if (completesSynergies.isNotEmpty)
        completesPill(completesSynergies, ownerLabel: ownerLabel),
    ];
    return Wrap(spacing: 5, runSpacing: 4, children: bits);
  }
}

class ItemMeta extends StatelessWidget {
  final Item item;
  final int synergyCount;
  final List<String> completesSynergies;
  final String? ownerLabel;
  const ItemMeta({
    super.key,
    required this.item,
    required this.synergyCount,
    this.completesSynergies = const [],
    this.ownerLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Slim row meta: type tag (ACTIVE/PASSIVE/COMPANION) + element
    // dots + contextual badges. Price moved to the detail screen.
    final elements = ElementalTagger.elementsOfItem(item);
    final bits = <Widget>[
      if (item.isCompanion)
        metaPill('Companion', Colors.purpleAccent)
      else if (item.isActive)
        metaPill('Active', Colors.lightBlueAccent)
      else if (item.isPassive)
        metaPill('Passive', Colors.lightGreenAccent),
      elementDots(elements),
      if (completesSynergies.isNotEmpty)
        completesPill(completesSynergies, ownerLabel: ownerLabel),
    ];
    return Wrap(spacing: 5, runSpacing: 4, children: bits);
  }
}
