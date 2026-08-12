import 'package:flutter/material.dart';

import '../../models/gun.dart';
import '../../models/item.dart';
import '../quality_badge.dart';
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
        GoopText(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.3,
            height: 1.1,
          ),
        ),
      ],
    ),
  );
}

Widget qualityPill(String quality) {
  if (quality.isEmpty) return const SizedBox.shrink();
  final rawColor = QualityBadge.colorFor(quality);
  final letter = quality.toUpperCase() == '1S' ? 'S' : quality.toUpperCase();
  final isS = letter == 'S';
  // S-tier uses near-black for the filled badge circle (white text on black),
  // but near-black chrome (border/text/bg tint) is invisible on dark panels.
  // Use gold as the pill accent for S-tier so it reads on any background.
  final accent = isS ? const Color(0xFFFFD700) : rawColor;
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
            border: isS ? Border.all(color: const Color(0xFFE0E0E0), width: 1.0) : null,
          ),
          child: GoopText(
            letter,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.white,
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
      color: const Color(0xFFFFC857).withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: const Color(0xFFE5A823).withValues(alpha: 0.65),
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
            gradient: const RadialGradient(
              center: Alignment(-0.3, -0.3),
              radius: 0.9,
              colors: [
                Color(0xFFFFE082),
                Color(0xFFFFC107),
                Color(0xFFB8860B),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
            border: Border.all(
              color: const Color(0xFF8B6508),
              width: 0.6,
            ),
          ),
          alignment: Alignment.center,
          child: const GoopText(
            '\$',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFF7A4E00),
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: GoopText(
            price,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFFFFD166),
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
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: GoopText(
        'no synergy',
        style: TextStyle(
          fontSize: 10,
          color: Colors.white.withValues(alpha: 0.35),
          fontStyle: FontStyle.italic,
          height: 1.1,
        ),
      ),
    );
  }
  return metaPill('$count synergy${count == 1 ? "" : "s"}',
      Colors.blueAccent,
      icon: Icons.hub);
}

class GunMeta extends StatelessWidget {
  final Gun gun;
  final int synergyCount;
  const GunMeta({super.key, required this.gun, required this.synergyCount});

  @override
  Widget build(BuildContext context) {
    final bits = <Widget>[
      qualityPill(gun.quality),
      if (gun.gunClass.isNotEmpty && gun.gunClass.toUpperCase() != 'NONE')
        metaPill(_titleCase(gun.gunClass), Colors.orangeAccent),
      if (gun.dps.isNotEmpty)
        metaPill('DPS ${gun.dpsValue.toStringAsFixed(0)}',
            Colors.deepOrangeAccent,
            icon: Icons.flash_on),
      if (gun.type.isNotEmpty)
        metaPill(gun.type, Colors.white70),
      if (gun.sellPrice.isNotEmpty && gun.sellPrice != 'N/A')
        coinPill(gun.sellPrice),
      synergyPill(synergyCount),
    ];
    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: bits,
    );
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
  const ItemMeta({super.key, required this.item, required this.synergyCount});

  @override
  Widget build(BuildContext context) {
    final bits = <Widget>[qualityPill(item.quality)];
    if (item.isCompanion) {
      bits.add(metaPill('Companion', Colors.purpleAccent));
    } else if (item.isActive) {
      bits.add(metaPill('Active', Colors.lightBlueAccent));
      if (item.rechargeTime.isNotEmpty) {
        bits.add(metaPill(item.rechargeTime, Colors.white70,
            icon: Icons.schedule));
      }
    } else if (item.isPassive) {
      bits.add(metaPill('Passive', Colors.lightGreenAccent));
    }
    if (item.sellPrice.isNotEmpty && item.sellPrice != 'N/A') {
      bits.add(coinPill(item.sellPrice));
    }
    bits.add(synergyPill(synergyCount));
    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: bits,
    );
  }
}
