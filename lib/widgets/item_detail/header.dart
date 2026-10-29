import '../../theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/elemental_tagger.dart';
import '../../services/haptics.dart';
import '../game_icon.dart';
import '../quality_badge.dart';
import '../../utils/responsive.dart';

class ItemDetailHeader extends StatelessWidget {
  final String name;
  final String subtitle;
  final String quality;
  final String quote;
  final String effect;
  final bool isGun;
  final bool isActive;
  final String iconPath;
  final String chestColor;
  final String sellPrice;
  final int synergyCount;
  final double curse;
  final double coolness;
  final Set<ElementKind> elements;
  const ItemDetailHeader({
    super.key,
    required this.name,
    required this.subtitle,
    required this.quality,
    required this.quote,
    this.effect = '',
    required this.isGun,
    required this.isActive,
    required this.iconPath,
    required this.chestColor,
    required this.sellPrice,
    required this.synergyCount,
    required this.curse,
    required this.coolness,
    required this.elements,
  });

  @override
  Widget build(BuildContext context) {
    final isFav = context.select<RunProvider, bool>((p) => p.isFavourite(name));
    final favColor = isFav ? Colors.pinkAccent : Colors.white38;
    final sf = Responsive.factor(context);

    // Build all tag chips in one list for a single inline Wrap
    final typeLabel = isGun
        ? subtitle.toUpperCase()
        : (isActive ? 'ACTIVE' : (subtitle.isNotEmpty ? subtitle.toUpperCase() : 'PASSIVE'));
    final typeColor = isGun
        ? Colors.deepOrangeAccent
        : (isActive ? Colors.lightBlueAccent : Colors.lightGreenAccent);
    final typeIcon = isGun
        ? Icons.gps_fixed
        : (isActive ? Icons.flash_on : Icons.inventory_2_outlined);

    final tags = <Widget>[
      if (!isGun)
        _TagChip(icon: typeIcon, label: typeLabel, color: typeColor),
      for (final e in elements)
        _TagChip(icon: e.icon, label: e.label, color: e.color),
      if (chestColor.isNotEmpty) _ChestChip(chestColor: chestColor),
      MetadataChip(
        icon: Icons.hub_outlined,
        label: 'Synergies',
        value: '$synergyCount',
        color: Colors.cyanAccent,
      ),
      if (sellPrice.isNotEmpty)
        MetadataChip(
          icon: Icons.payments_outlined,
          label: 'Sell',
          value: sellPrice,
          color: Colors.yellowAccent,
        ),
      if (curse > 0)
        MetadataChip(
          icon: Icons.mood_bad_outlined,
          label: 'Curse',
          value: '+${_fmtStat(curse)}',
          color: Colors.redAccent,
        ),
      if (coolness > 0)
        MetadataChip(
          icon: Icons.ac_unit,
          label: 'Coolness',
          value: '+${_fmtStat(coolness)}',
          color: Colors.lightBlueAccent,
        ),
    ];

    // ── Gun layout — simplified per redesign: no tag chips, no quote.
    // Left: tier badge + sell badge. Right: favourite. Then name → icon
    // → ornamental divider → effect line → elemental icon row. ──
    if (isGun) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (quality.isNotEmpty)
                      QualityBadge(quality: quality, size: 32)
                    else
                      const SizedBox(width: 32),
                    if (sellPrice.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _SellBadge(price: sellPrice),
                    ],
                  ],
                ),
                IconButton(
                  icon: Icon(
                    isFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: favColor,
                    size: 30,
                  ),
                  tooltip:
                      isFav ? 'Remove from favourites' : 'Add to favourites',
                  constraints:
                      const BoxConstraints(minWidth: 44, minHeight: 44),
                  onPressed: () {
                    Haptics.light();
                    final p = context.read<RunProvider>();
                    final wasFav = p.isFavourite(name);
                    p.toggleFavourite(name);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: GoopText(wasFav
                            ? '$name removed from favourites'
                            : '$name added to favourites'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Title
            GoopText(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: FontSizes.headlineMedium * sf,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            // Gun graphic
            GameIcon(
              assetPath: iconPath,
              fallback: Icons.gps_fixed,
              quality: quality,
              size: 96,
              showRing: false,
            ),
            const SizedBox(height: 12),
            const _AccentDivider(),
            const SizedBox(height: 10),
            // Main effect — replaces the flavor-quote slot.
            if (effect.isNotEmpty)
              GoopText(
                effect,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.35,
                ),
              ),
            if (elements.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final e in elements)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _ElementDot(kind: e),
                    ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Top row: rank badge (left) + favourite button (right, 50% bigger)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (quality.isNotEmpty)
                QualityBadge(quality: quality, size: 32)
              else
                const SizedBox(width: 32),
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: favColor,
                  size: 30,
                ),
                tooltip: isFav ? 'Remove from favourites' : 'Add to favourites',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () {
                  Haptics.light();
                  final p = context.read<RunProvider>();
                  final wasFav = p.isFavourite(name);
                  p.toggleFavourite(name);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: GoopText(wasFav
                          ? '$name removed from favourites'
                          : '$name added to favourites'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Icon — no ring, compact for tighter top area
          GameIcon(
            assetPath: iconPath,
            fallback: isGun
                ? Icons.gps_fixed
                : (isActive ? Icons.flash_on : Icons.inventory_2_outlined),
            quality: quality,
            size: 80,
            showRing: false,
          ),
          const SizedBox(height: 6),
          // Item name
          GoopText(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: FontSizes.headlineMedium * sf,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          // All tags inline in one Wrap
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: tags,
          ),
          // Flavor quote removed.
        ],
      ),
    );
  }

  static String _fmtStat(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

/// Sell-price chip — lives beside the tier badge on gun detail.
class _SellBadge extends StatelessWidget {
  final String price;
  const _SellBadge({required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.yellowAccent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.yellowAccent.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sell_outlined, size: 13, color: Colors.yellowAccent),
          const SizedBox(width: 4),
          GoopText(
            price,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.yellowAccent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Elemental status dot — icon-only tinted circle (fire/electric/etc).
class _ElementDot extends StatelessWidget {
  final ElementKind kind;
  const _ElementDot({required this.kind});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: kind.label,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: kind.color.withValues(alpha: 0.14),
          shape: BoxShape.circle,
          border: Border.all(
            color: kind.color.withValues(alpha: 0.45),
            width: 1.0,
          ),
        ),
        child: Icon(kind.icon, size: 15, color: kind.color),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _TagChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.all(Radii.sm),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          GoopText(
            label,
            style: TextStyle(
              fontSize: FontSizes.labelMedium,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccentDivider extends StatelessWidget {
  const _AccentDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.25),
                  Colors.white.withValues(alpha: 0.25),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.25),
                  Colors.white.withValues(alpha: 0.25),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const MetadataChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 5),
            GoopText(
              '$label ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.85),
              ),
            ),
          ],
          GoopText(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChestChip extends StatelessWidget {
  final String chestColor;
  const _ChestChip({required this.chestColor});

  static const Map<String, Color> _colors = {
    'red': Color(0xFFE53935),
    'blue': Color(0xFF1E88E5),
    'green': Color(0xFF43A047),
    'black': Color(0xFF222222),
    'brown': Color(0xFF8D6E63),
    'rainbow': Colors.pinkAccent,
  };

  static const Map<String, String> _ranks = {
    'brown': 'D',
    'blue': 'C',
    'green': 'B',
    'red': 'A',
    'black': 'S',
    'rainbow': '★',
  };

  @override
  Widget build(BuildContext context) {
    final key = chestColor.toLowerCase();
    final color = _colors[key] ?? Colors.white38;
    final rank = _ranks[key];

    final isS = key == 'black';
    // S-tier: gold accent for border/glow so it reads on any background.
    // The chest color swatch stays near-black (the actual chest color),
    // but the chip chrome uses gold to match the QualityBadge S-tier glow.
    final accent = isS ? const Color(0xFFFFD700) : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isS ? accent.withValues(alpha: 0.7) : color.withValues(alpha: 0.45),
          width: isS ? 1.2 : 0.8,
        ),
        boxShadow: isS
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.25),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 14, color: isS ? accent : color),
          const SizedBox(width: 5),
          GoopText(
            'Chest ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isS ? accent : color.withValues(alpha: 0.85),
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isS ? accent.withValues(alpha: 0.6) : Colors.white24,
                width: 0.8,
              ),
            ),
          ),
          if (rank != null) ...[
            const SizedBox(width: 5),
            GoopText(
              rank,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
