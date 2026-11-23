import '../../theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/elemental_tagger.dart';
import '../../services/haptics.dart';
import '../game_icon.dart';
import '../quality_badge.dart';
import '../bug_report/bug_report_sheet.dart';
import '../element_badge.dart';
import '../../models/bug_report.dart';
import '../../services/codex_prefs.dart';
import '../../utils/responsive.dart';

class ItemDetailHeader extends StatelessWidget {
  final String name;
  final String subtitle;
  final String quality;
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
    final favColor =
        isFav ? Colors.pinkAccent : Theme.of(context).colorScheme.outline;
    final sf = Responsive.factor(context);

    // Build all tag chips in one list for a single inline Wrap
    final typeLabel =
        isGun
            ? subtitle.toUpperCase()
            : (isActive
                ? 'ACTIVE'
                : (subtitle.isNotEmpty ? subtitle.toUpperCase() : 'PASSIVE'));
    final typeColor =
        isGun
            ? Colors.deepOrangeAccent
            : (isActive ? Colors.lightBlueAccent : Colors.lightGreenAccent);
    final typeIcon =
        isGun
            ? Icons.gps_fixed
            : (isActive ? Icons.flash_on : Icons.inventory_2_outlined);

    final tags = <Widget>[
      if (!isGun) _TagChip(icon: typeIcon, label: typeLabel, color: typeColor),
      for (final e in elements) ElementBadge(element: e, size: 22),
      if (chestColor.isNotEmpty) _ChestChip(chestColor: chestColor),
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
    ];

    // ── Gun layout — simplified per redesign: no tag chips, no quote.
    // Left: tier badge + sell badge. Right: overflow actions menu.
    // Then name → icon → ornamental divider → effect line → elemental
    // icon row. ──
    if (isGun) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // U-025: badge cluster can exceed narrow widths —
                // scale down instead of overflowing.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (quality.isNotEmpty)
                          QualityBadge(quality: quality, size: 32)
                        else
                          const SizedBox(width: 32),
                        if (sellPrice.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _SellBadge(price: sellPrice),
                        ],
                        // Fire-mode chip (Semi/Auto/Charge…) — was
                        // invisible everywhere (U-048).
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _TagChip(
                            icon: Icons.bolt_outlined,
                            label: subtitle,
                            color: Colors.deepOrangeAccent,
                          ),
                        ],
                        // Element badges beside tier+sell — always top-left.
                        if (elements.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          for (final e in elements)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: ElementBadge(element: e),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                // U-033: three icon buttons collapsed into one labelled
                // overflow menu — the two fav systems are now explicit.
                _DetailActionsMenu(
                  name: name,
                  isGun: isGun,
                  isFav: isFav,
                  favColor: favColor,
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
            // Gun graphic — same 80px footprint as items (U-009 icon
            // unification; guns read fine at item scale).
            GameIcon(
              assetPath: iconPath,
              fallback: Icons.gps_fixed,
              quality: quality,
              size: 80,
              showRing: false,
            ),
            const SizedBox(height: 12),
            // Main effect — replaces the flavor-quote slot.
            if (effect.isNotEmpty)
              GoopText(
                effect,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.9),
                  height: 1.35,
                ),
              ),
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
              // U-025: the badge cluster overflows ~47px on ≤390px
              // windows — scale it down instead of clipping.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (quality.isNotEmpty)
                        QualityBadge(quality: quality, size: 32)
                      else
                        const SizedBox(width: 32),
                      if (sellPrice.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _SellBadge(price: sellPrice),
                      ],
                      const SizedBox(width: 8),
                      // Active vs passive — always top-left for items.
                      _TagChip(
                        icon:
                            isActive
                                ? Icons.flash_on
                                : Icons.inventory_2_outlined,
                        label: isActive ? 'ACTIVE' : 'PASSIVE',
                        color:
                            isActive
                                ? Colors.lightBlueAccent
                                : Colors.lightGreenAccent,
                      ),
                    ],
                  ),
                ),
              ),
              // U-033: collapsed action cluster — see gun variant.
              _DetailActionsMenu(
                name: name,
                isGun: false,
                isFav: isFav,
                favColor: favColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // U-034: name-first ordering, matching the gun variant.
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
          // Icon — no ring, compact for tighter top area
          GameIcon(
            assetPath: iconPath,
            fallback:
                isGun
                    ? Icons.gps_fixed
                    : (isActive ? Icons.flash_on : Icons.inventory_2_outlined),
            quality: quality,
            size: 80,
            showRing: false,
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

/// U-033: single overflow menu replacing the three-icon action cluster.
/// Labels disambiguate the two favourite systems (codex bookmark vs
/// run/loadout heart) and keep bug reporting one tap away.
class _DetailActionsMenu extends StatelessWidget {
  final String name;
  final bool isGun;
  final bool isFav;
  final Color favColor;
  const _DetailActionsMenu({
    required this.name,
    required this.isGun,
    required this.isFav,
    required this.favColor,
  });

  void _toggleFavourite(BuildContext context) {
    Haptics.light();
    final p = context.read<RunProvider>();
    final wasFav = p.isFavourite(name);
    p.toggleFavourite(name);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: GoopText(
          wasFav ? '$name removed from favourites' : '$name added to favourites',
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  PopupMenuItem<String> _item(
    String value,
    IconData icon,
    String label, {
    Color? color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color ?? Colors.white60),
          const SizedBox(width: 10),
          GoopText(
            label,
            style: const TextStyle(fontSize: FontSizes.labelMedium),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: CodexPrefs.favorites,
      builder: (context, codexFavs, _) {
        final codexKey = CodexPrefs.keyFor(isGun ? 'guns' : 'items', name);
        final codexOn = codexFavs.contains(codexKey);
        return PopupMenuButton<String>(
          tooltip: 'More actions',
          iconSize: 22,
          icon: Icon(
            Icons.more_vert,
            color: Theme.of(context).colorScheme.outline,
          ),
          offset: const Offset(0, 36),
          color: const Color(0xFF232326),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Colors.white10),
          ),
          onSelected: (value) {
            switch (value) {
              case 'codex':
                Haptics.selection();
                CodexPrefs.toggleFavorite(codexKey);
              case 'fav':
                _toggleFavourite(context);
              case 'bug':
                Haptics.light();
                BugReportSheet.show(
                  context,
                  BugReportContext.content(
                    screen: isGun ? 'Gun Detail' : 'Item Detail',
                    entity: name,
                  ),
                );
            }
          },
          itemBuilder:
              (_) => [
                _item(
                  'codex',
                  codexOn
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  codexOn ? 'Codex Favorite — Saved' : 'Save to Codex Favorites',
                  color: codexOn ? const Color(0xFFFF6E8A) : null,
                ),
                _item(
                  'fav',
                  isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  isFav
                      ? 'Remove from Favourites'
                      : 'Add to Favourites',
                  color: isFav ? favColor : null,
                ),
                const PopupMenuDivider(height: 1),
                _item('bug', Icons.bug_report_outlined, 'Report a Bug'),
              ],
        );
      },
    );
  }
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
          Icon(Icons.sell_outlined, size: 13, color: Colors.yellowAccent),
          const SizedBox(width: 4),
          GoopText(
            price,
            style: TextStyle(
              fontSize: FontSizes.labelMedium,
              fontWeight: FontWeight.w800,
              color: Colors.yellowAccent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small tinted metadata chip — icon + label used in the tag Wrap.
class _TagChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _TagChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ChipStyle.padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.all(Radii.sm),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: ChipStyle.icon, color: color),
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
      padding: ChipStyle.padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: ChipStyle.icon, color: color),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 5),
            GoopText(
              '$label ',
              style: TextStyle(
                fontSize: FontSizes.chip,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.85),
              ),
            ),
          ],
          GoopText(
            value,
            style: TextStyle(
              fontSize: FontSizes.chipStrong,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
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

  static final Map<String, Color> _colors = {
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
      padding: ChipStyle.padding,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              isS
                  ? accent.withValues(alpha: 0.7)
                  : color.withValues(alpha: 0.45),
          width: isS ? 1.2 : 0.8,
        ),
        boxShadow:
            isS
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
          Icon(
            Icons.inventory_2_outlined,
            size: ChipStyle.icon,
            color: isS ? accent : color,
          ),
          const SizedBox(width: 5),
          GoopText(
            'Chest ',
            style: TextStyle(
              fontSize: FontSizes.chip,
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
                fontSize: FontSizes.chipStrong,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

