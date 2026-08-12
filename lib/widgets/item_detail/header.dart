import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/elemental_tagger.dart';
import '../game_icon.dart';
import '../quality_badge.dart';

class ItemDetailHeader extends StatelessWidget {
  final String name;
  final String subtitle;
  final String quality;
  final String quote;
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
    final isFav = context.watch<RunProvider>().isFavourite(name);
    final favColor = isFav ? Colors.pinkAccent : Colors.white38;

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

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Top row: rank badge (left) + favourite button (right, 50% bigger)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (quality.isNotEmpty)
                QualityBadge(quality: quality, size: 36)
              else
                const SizedBox(width: 36),
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: favColor,
                  size: 36,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  final p = context.read<RunProvider>();
                  final wasFav = p.isFavourite(name);
                  p.toggleFavourite(name);
                  ScaffoldMessenger.of(context).clearSnackBars();
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
          const SizedBox(height: 8),
          // Icon — no ring, bigger and cleaner
          GameIcon(
            assetPath: iconPath,
            fallback: isGun
                ? Icons.gps_fixed
                : (isActive ? Icons.flash_on : Icons.inventory_2_outlined),
            quality: quality,
            size: 128,
            showRing: false,
          ),
          const SizedBox(height: 14),
          // Item name
          GoopText(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          // All tags inline in one Wrap
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: tags,
          ),
          // Quote / description at the bottom with accent separator
          if (quote.isNotEmpty) ...[
            const SizedBox(height: 18),
            _AccentDivider(),
            const SizedBox(height: 14),
            GoopText(
              '"$quote"',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15.5,
                color: Colors.white.withValues(alpha: 0.85),
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _fmtStat(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
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
        borderRadius: BorderRadius.circular(8),
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
              fontSize: 12,
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isS ? Colors.white54 : color.withValues(alpha: 0.45),
          width: isS ? 1.2 : 0.8,
        ),
        boxShadow: isS
            ? [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.12),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 14, color: isS ? Colors.white70 : color),
          const SizedBox(width: 5),
          GoopText(
            'Chest ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isS ? Colors.white : color.withValues(alpha: 0.85),
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 0.8),
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
