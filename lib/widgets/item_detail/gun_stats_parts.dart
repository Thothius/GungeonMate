part of 'gun_stats.dart';

/// Stat category — mirrors the old Combat/Handling/Meta grouping so the
/// color coding users knew is preserved without the heavy group headers.
enum _StatCategory { combat, handling, meta }

extension _StatCategoryColor on _StatCategory {
  /// Resolves the theme-tied category color, falling back to the canonical
  /// Combat=red, Handling=cyan, Meta=amber when a theme hasn't opted in.
  Color color(ThemeFlair flair) {
    switch (this) {
      case _StatCategory.combat:
        return flair.statGroupCombat ?? Colors.redAccent;
      case _StatCategory.handling:
        return flair.statGroupHandling ?? Colors.cyanAccent;
      case _StatCategory.meta:
        return flair.statGroupMeta ?? Colors.amberAccent;
    }
  }
}

/// Lightweight data holder for a single stat entry.
class _StatSpec {
  final String label;
  final String value;
  final IconData icon;
  final _StatCategory category;
  const _StatSpec({
    required this.label,
    required this.value,
    required this.icon,
    required this.category,
  });
}

/// Uniform vertical stat card for primary stats (Damage, Fire Rate, Range,
/// Force). Icon → value → label, all centered and consistently sized.
class _PrimaryStatCard extends StatelessWidget {
  final _StatSpec spec;
  const _PrimaryStatCard({required this.spec});

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final catColor = spec.category.color(flair);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: catColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.all(Radii.md),
        border: Border.all(color: catColor.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(spec.icon, size: 20, color: catColor),
          const SizedBox(height: 6),
          GoopText(
            spec.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: flair.headlineStat,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          GoopText(
            spec.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: FontSizes.labelSmall,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.5),
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact horizontal stat chip for secondary stats (Magazine, Max Ammo,
/// Reload, Shot Speed, Spread, Class). Icon + label + value in a row.
class _SecondaryStatChip extends StatelessWidget {
  final _StatSpec spec;
  const _SecondaryStatChip({required this.spec});

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final catColor = spec.category.color(flair);
    final hasDigit = RegExp(r'\d').hasMatch(spec.value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: catColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: catColor.withValues(alpha: 0.22), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(spec.icon, size: 11, color: catColor.withValues(alpha: 0.85)),
          const SizedBox(width: 4),
          GoopText(
            spec.label,
            style: TextStyle(
              fontSize: FontSizes.labelSmall,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 4),
          if (hasDigit)
            ThemedNumber(
              value: spec.value,
              baseSize: 11,
              colorOverride: flair.headlineStat,
              role: ThemedNumberRole.headline,
            )
          else
            GoopText(
              spec.value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: flair.headlineStat,
              ),
            ),
        ],
      ),
    );
  }
}
