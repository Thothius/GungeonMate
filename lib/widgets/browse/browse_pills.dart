import 'package:flutter/material.dart';

import '../../models/gun.dart';
import '../../models/item.dart';
import '../quality_badge.dart';
import '../../services/goop_talk_engine.dart';
import '../../theme/tokens.dart';
import '../skeuo/skeuo_tokens.dart';

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

Widget qualityPill(String quality) {
  if (quality.isEmpty) return const SizedBox.shrink();
  final rawColor = QualityBadge.colorFor(quality);
  final letter = quality.toUpperCase();
  final isS = letter == 'S';
  // S-tier uses near-black for the filled badge circle (white text on black),
  // but near-black chrome (border/text/bg tint) is invisible on dark panels.
  // Use gold as the pill accent for S-tier so it reads on any background.
  final accent = isS ? Skeuo.collapse(Color(0xFFFFD700)) : rawColor;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: accent.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: accent.withValues(alpha: 0.7), width: 0.8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 15,
          height: 15,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: rawColor,
            shape: BoxShape.circle,
            border:
                isS
                    ? Border.all(
                      color: Skeuo.collapse(Color(0xFFE0E0E0)),
                      width: 1.0,
                    )
                    : null,
          ),
          child: GoopText(
            letter,
            style: TextStyle(
              fontSize: FontSizes.labelSmall,
              fontWeight: FontWeight.w900,
              color: Skeuo.collapse(Colors.white),
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: GoopText(
            '$letter-tier',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accent,
              letterSpacing: 0.2,
              height: 1.1,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget coinPill(String price) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Skeuo.collapse(Color(0xFFFFC857)).withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: Skeuo.collapse(Color(0xFFE5A823)).withValues(alpha: 0.65),
        width: 0.8,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: Alignment(-0.3, -0.3),
              radius: 0.9,
              colors: [
                Skeuo.collapse(Color(0xFFFFE082)),
                Skeuo.collapse(Color(0xFFFFC107)),
                Skeuo.collapse(Color(0xFFB8860B)),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
            border: Border.all(
              color: Skeuo.collapse(Color(0xFF8B6508)),
              width: 0.6,
            ),
          ),
          alignment: Alignment.center,
          child: GoopText(
            '\$',
            style: TextStyle(
              fontSize: FontSizes.labelSmall,
              fontWeight: FontWeight.w900,
              color: Skeuo.collapse(Color(0xFF7A4E00)),
              height: 1,
            ),
          ),
        ),
        SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: GoopText(
            price,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Skeuo.collapse(Color(0xFFFFD166)),
              letterSpacing: 0.3,
              height: 1.1,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget synergyPill(int count) {
  if (count == 0) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Skeuo.collapse(Colors.white).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: GoopText(
        'no synergy',
        style: TextStyle(
          fontSize: FontSizes.labelSmall,
          color: Skeuo.collapse(Colors.white).withValues(alpha: 0.35),
          fontStyle: FontStyle.italic,
          height: 1.1,
        ),
      ),
    );
  }
  return metaPill(
    '$count ${count == 1 ? 'synergy' : 'synergies'}',
    Skeuo.inkIf(Colors.blueAccent),
    icon: Icons.hub,
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
  return metaPill(label, Skeuo.collapse(Color(0xFFFFD700)), icon: Icons.link);
}

class GunMeta extends StatelessWidget {
  final Gun gun;
  final int synergyCount;
  final List<String> completesSynergies;
  final String? ownerLabel;
  const GunMeta({
    super.key,
    required this.gun,
    required this.synergyCount,
    this.completesSynergies = const [],
    this.ownerLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Slim row meta (v3): quality + gun class + DPS + price only.
    // The busy tag soup (gun type, synergy count, recharge) is gone —
    // "COMPLETES" only surfaces when the caller passes completions
    // (the SYNERGIES browse view).
    final bits = <Widget>[
      if (gun.gunClass.isNotEmpty && gun.gunClass.toUpperCase() != 'NONE')
        metaPill(_titleCase(gun.gunClass), Skeuo.inkIf(Colors.orangeAccent)),
      if (gun.dps.isNotEmpty)
        metaPill(
          'DPS ${gun.dpsValue.toStringAsFixed(0)}',
          Skeuo.inkIf(Colors.deepOrangeAccent),
          icon: Icons.flash_on,
        ),
      if (gun.sellPrice.isNotEmpty && gun.sellPrice != 'N/A')
        coinPill(gun.sellPrice),
      if (completesSynergies.isNotEmpty)
        completesPill(completesSynergies, ownerLabel: ownerLabel),
    ];
    return Wrap(spacing: 5, runSpacing: 4, children: bits);
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    final l = s.toLowerCase();
    return l[0].toUpperCase() + l.substring(1);
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
    // Slim row meta (v3): quality + role tag + price only.
    final bits = <Widget>[];
    if (item.isCompanion) {
      bits.add(metaPill('Companion', Skeuo.inkIf(Colors.purpleAccent)));
    } else if (item.isActive) {
      bits.add(metaPill('Active', Skeuo.inkIf(Colors.lightBlueAccent)));
    } else if (item.isPassive) {
      bits.add(metaPill('Passive', Skeuo.inkIf(Colors.lightGreenAccent)));
    }
    if (item.sellPrice.isNotEmpty && item.sellPrice != 'N/A') {
      bits.add(coinPill(item.sellPrice));
    }
    if (completesSynergies.isNotEmpty) {
      bits.add(completesPill(completesSynergies, ownerLabel: ownerLabel));
    }
    return Wrap(spacing: 5, runSpacing: 4, children: bits);
  }
}
