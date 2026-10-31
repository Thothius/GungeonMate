import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/gun.dart';
import '../../providers/run_provider.dart';
import '../../services/app_theme.dart';
import '../../services/goop_talk_engine.dart';
import '../../theme/tokens.dart';
import '../../widgets/themed_number.dart';
import 'quick_jump_button.dart';
import '../skeuo/skeuo_tokens.dart';
part 'gun_stats_parts.dart';
part 'gun_stats_sections.dart';

class EvolverStageSpec {
  final int id;
  final String name;
  final String dps;
  final String bullet;
  final IconData icon;
  final Color color;
  const EvolverStageSpec({
    required this.id,
    required this.name,
    required this.dps,
    required this.bullet,
    required this.icon,
    required this.color,
  });
}

class StatGroup extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<MapEntry<String, String>> stats;
  const StatGroup({
    super.key,
    required this.label,
    required this.icon,
    required this.stats,
  });

  /// Resolves the group's accent color: theme override if set, else
  /// semantic defaults (Combat=red, Handling=cyan, Meta=amber).
  Color _groupColor() {
    final f = AppTheme.flair;
    switch (label.toLowerCase()) {
      case 'combat':
        return f.statGroupCombat ?? const Color(0xFFFF5252);
      case 'handling':
        return f.statGroupHandling ?? const Color(0xFF40C4FF);
      case 'meta':
        return f.statGroupMeta ?? const Color(0xFFFFD54F);
      default:
        return f.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _groupColor();
    final flair = AppTheme.flair;
    final useFilledPill = flair.chipFilled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Insets.sm),
          child:
              useFilledPill
                  ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.all(Radii.sm),
                      border: Border.all(
                        color: color.withValues(alpha: 0.5),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 18, color: color),
                        const SizedBox(width: 7),
                        GoopText(
                          label.toUpperCase(),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  )
                  : Row(
                    children: [
                      Container(
                        width: 3,
                        height: 18,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: Insets.sm),
                      Icon(icon, size: 18, color: color),
                      const SizedBox(width: 7),
                      GoopText(
                        label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: color,
                        ),
                      ),
                    ],
                  ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children:
              stats
                  .map(
                    (e) => StatPill(
                      label: e.key,
                      value: e.value,
                      groupColor: color,
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }
}

class StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color? groupColor;
  const StatPill({
    super.key,
    required this.label,
    required this.value,
    this.groupColor,
  });

  static final Map<String, Color> _chestColors = {
    'red': Color(0xFFE53935),
    'blue': Color(0xFF1E88E5),
    'green': Color(0xFF43A047),
    'black': Color(0xFF222222),
    'brown': Color(0xFF8D6E63),
    'rainbow': Skeuo.inkIf(Colors.pinkAccent),
  };

  static const Map<String, String> _chestRanks = {
    'brown': 'D',
    'blue': 'C',
    'green': 'B',
    'red': 'A',
    'black': 'S',
    'rainbow': '★',
  };

  @override
  Widget build(BuildContext context) {
    final isChest = label.toLowerCase() == 'chest';
    final isCharge = label.toLowerCase() == 'charge';
    final isDuration = label.toLowerCase() == 'duration';
    final chestColor = isChest ? _chestColors[value.toLowerCase()] : null;
    final chestRank = isChest ? _chestRanks[value.toLowerCase()] : null;
    final hasDigit = RegExp(r'\d').hasMatch(value);
    final flair = AppTheme.flair;
    final filled = flair.chipFilled;
    final accentColor =
        isCharge
            ? Skeuo.inkIf(Colors.lightBlueAccent)
            : isDuration
            ? Skeuo.inkIf(Colors.greenAccent.shade200)
            : null;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: filled ? 10 : 4,
        vertical: filled ? 6 : 2,
      ),
      decoration: BoxDecoration(
        color:
            filled
                ? (accentColor?.withValues(alpha: 0.08) ??
                    Colors.white.withValues(alpha: 0.06))
                : null,
        borderRadius: BorderRadius.circular(flair.chipRadius),
        border:
            filled
                ? (accentColor != null
                    ? Border.all(
                      color: accentColor.withValues(alpha: 0.35),
                      width: 0.8,
                    )
                    : null)
                : Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCharge) ...[
            Icon(
              Icons.electric_bolt,
              size: 12,
              color: Skeuo.inkIf(Colors.lightBlueAccent),
            ),
            const SizedBox(width: 3),
          ],
          if (isDuration) ...[
            Icon(
              Icons.timer_outlined,
              size: 12,
              color: Skeuo.inkIf(Colors.greenAccent.shade200),
            ),
            const SizedBox(width: 3),
          ],
          GoopText(
            '$label  ',
            style: TextStyle(
              fontSize: FontSizes.labelMedium,
              color:
                  accentColor?.withValues(alpha: 0.85) ??
                  groupColor?.withValues(alpha: 0.75) ??
                  Colors.white.withValues(alpha: 0.6),
            ),
          ),
          if (chestColor != null) ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: chestColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 0.8),
              ),
            ),
            const SizedBox(width: 5),
          ],
          if (hasDigit)
            ThemedNumber(
              value: value,
              baseSize: 13,
              colorOverride: Colors.white,
              role: ThemedNumberRole.headline,
            )
          else
            GoopText(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          if (chestRank != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: (chestColor ?? Colors.white24).withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: (chestColor ?? Colors.white24).withValues(alpha: 0.7),
                  width: 0.7,
                ),
              ),
              child: GoopText(
                chestRank,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class GunStats extends StatelessWidget with _GunStatsSections {
  @override
  final Gun gun;
  const GunStats({super.key, required this.gun});

  @override
  Widget build(BuildContext context) {
    final p = context.read<RunProvider>();
    final gunderfuryLevel = context.select<RunProvider, int>(
      (p) => p.gunderfuryLevel,
    );
    final gunderfuryInfo =
        gun.name.toLowerCase() == 'gunderfury'
            ? _buildGunderfuryInfo(context, p)
            : null;
    final tripleGunInfo =
        gun.name.toLowerCase() == 'triple gun'
            ? _buildTripleGunInfo(context, p)
            : null;
    final evolverInfo =
        gun.name.toLowerCase() == 'evolver'
            ? _buildEvolverInfo(context, p)
            : null;
    final shellegunInfo =
        gun.name.toLowerCase() == 'shellegun'
            ? _buildShellegunInfo(context, p)
            : null;
    final chamberGunInfo =
        gun.name.toLowerCase() == 'chamber gun'
            ? _buildChamberGunInfo(context, p)
            : null;
    final caseyInfo =
        gun.name.toLowerCase() == 'casey' ? _buildCaseyInfo(context) : null;

    final String typeLower = gun.type.toLowerCase();
    if (typeLower.contains('charged') || typeLower.contains('charge')) {
    } else if (typeLower.contains('beam')) {
    } else if (typeLower.contains('burst')) {
    } else if (typeLower.contains('automatic') || typeLower.contains('auto')) {
    } else {}

    // All form-stateful guns get their dynamic DPS — same params
    // _avgDpsFor uses, so the header stat matches run averages.
    final String dpsValue = () {
      final dyn = gun.getDynamicDps(
        gunderLevel: gunderfuryLevel,
        tripleForm: context.select<RunProvider, int>((p) => p.tripleGunForm),
        evolverStage: context.select<RunProvider, int>((p) => p.evolverForm),
        shellegunMode: context.select<RunProvider, int>((p) => p.shellegunMode),
        chamberGunFloor: context.select<RunProvider, int>(
          (p) => p.chamberGunFloor,
        ),
      );
      return dyn > 0
          ? dyn.toStringAsFixed(1)
          : (gun.dps.isEmpty ? '0.0' : gun.dps);
    }();

    // Hero row — the four stats that matter most (per redesign):
    // Unified stat grid — one borderless label-over-number table for
    // every stat. DPS leads; all cells identical size; no icons.
    final gridSpecs = <(String, String)>[
      (
        'DPS',
        dpsValue.replaceAll(RegExp(r'\s*DPS\s*$', caseSensitive: false), ''),
      ),
      if (gun.damage.isNotEmpty) ('DAMAGE', gun.damage),
      if (gun.fireRate.isNotEmpty) ('FIRE RATE', gun.fireRate),
      if (gun.reloadTime.isNotEmpty) ('RELOAD', gun.reloadTime),
      if (gun.shotSpeed.isNotEmpty) ('SHOT SPEED', gun.shotSpeed),
      if (gun.range.isNotEmpty) ('RANGE', gun.range),
      if (gun.force.isNotEmpty) ('FORCE', gun.force),
      if (gun.spread.isNotEmpty) ('SPREAD', gun.spread),
      if (gun.magazineSize.isNotEmpty) ('MAGAZINE', gun.magazineSize),
      if (gun.ammoCapacity.isNotEmpty) ('MAX AMMO', gun.ammoCapacity),
      if (gun.gunClass.isNotEmpty) ('CLASS', gun.gunClass),
      if (gun.chestColorDisplay.isNotEmpty) ('CHEST', gun.chestColorDisplay),
      if (gun.curse > 0) ('CURSE', '+${gun.curse}'),
      if (gun.coolness > 0) ('COOL', '+${gun.coolness}'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatGrid(specs: gridSpecs),
          const SizedBox(height: 14),
          // ── Special gun info panels (unchanged) ──
          if (gunderfuryInfo != null) ...[
            gunderfuryInfo,
            const SizedBox(height: 14),
          ],
          if (tripleGunInfo != null) ...[
            tripleGunInfo,
            const SizedBox(height: 14),
          ],
          if (evolverInfo != null) ...[evolverInfo, const SizedBox(height: 14)],
          if (shellegunInfo != null) ...[
            shellegunInfo,
            const SizedBox(height: 14),
          ],
          if (chamberGunInfo != null) ...[
            chamberGunInfo,
            const SizedBox(height: 14),
          ],
          if (caseyInfo != null) ...[caseyInfo, const SizedBox(height: 14)],
        ],
      ),
    );
  }
}
