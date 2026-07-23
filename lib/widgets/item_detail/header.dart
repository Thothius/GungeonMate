import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../services/goop_talk_engine.dart';
import '../quality_badge.dart';
import '../game_icon.dart';

class ItemDetailHeader extends StatelessWidget {
  final String name;
  final String subtitle;
  final String quality;
  final String quote;
  final bool isGun;
  final bool isActive;
  final String iconPath;
  final String sellPrice;
  final int synergyCount;
  final double curse;
  final double coolness;
  const ItemDetailHeader({
    super.key,
    required this.name,
    required this.subtitle,
    required this.quality,
    required this.quote,
    required this.isGun,
    required this.isActive,
    required this.iconPath,
    required this.sellPrice,
    required this.synergyCount,
    required this.curse,
    required this.coolness,
  });

  @override
  Widget build(BuildContext context) {
    final isFav = context.watch<RunProvider>().isFavourite(name);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFav ? Colors.pinkAccent : Colors.white38,
                  size: 24,
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
          GameIcon(
                assetPath: iconPath,
                fallback: isGun
                    ? Icons.gps_fixed
                    : (isActive ? Icons.flash_on : Icons.inventory_2_outlined),
                quality: quality,
                size: 128,
              ),
              const SizedBox(height: 14),
              GoopText(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              if (quote.isNotEmpty) ...[
                const SizedBox(height: 10),
                GoopText(
                  '"$quote"',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.5,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (quality.isNotEmpty)
                    MetadataChip(
                      icon: Icons.star_rounded,
                      label: 'Rank',
                      value: quality.toUpperCase(),
                      color: QualityBadge.colorFor(quality),
                    ),
                  if (sellPrice.isNotEmpty)
                    MetadataChip(
                      icon: Icons.monetization_on_outlined,
                      label: 'Sell',
                      value: sellPrice,
                      color: Colors.amber,
                    ),
                  MetadataChip(
                    icon: Icons.hub_outlined,
                    label: 'Synergies',
                    value: '$synergyCount',
                    color: Colors.cyanAccent,
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
                ],
              ),
            ],
          ),
      );
  }

  static String _fmtStat(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
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
          const SizedBox(width: 5),
          GoopText(
            '$label ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.85),
            ),
          ),
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
