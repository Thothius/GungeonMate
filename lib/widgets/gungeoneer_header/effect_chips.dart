part of '../gungeoneer_header.dart';

/// Wrapped strip of recognized-effect chips. Wraps (not scrolls) so
/// every active effect is visible at a glance — the dash "grows" as
/// the run accumulates passives, which is the visual cue the user
/// asked for. Each chip combines: tag icon + label + (optional)
/// extracted numeric value.
class _EffectChipsWrap extends StatefulWidget {
  final List<EffectChip> chips;
  const _EffectChipsWrap({required this.chips});

  @override
  State<_EffectChipsWrap> createState() => _EffectChipsWrapState();
}

class _EffectChipsWrapState extends State<_EffectChipsWrap> {
  bool _isExpanded = false;

  Color _categoryColor(EffectCategory c) {
    switch (c) {
      case EffectCategory.mobility:
        return const Color(0xFF80DEEA);
      case EffectCategory.damage:
        return const Color(0xFFFFAB91);
      case EffectCategory.ammo:
        return const Color(0xFFFFE082);
      case EffectCategory.defense:
        return const Color(0xFFA5D6A7);
      case EffectCategory.utility:
        return const Color(0xFFCE93D8);
      case EffectCategory.economy:
        return const Color(0xFFFFD54F);
      case EffectCategory.status:
        return const Color(0xFFFFB74D);
      case EffectCategory.debuff:
        return const Color(0xFFEF9A9A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final maxCollapsed = 6;

    if (widget.chips.length <= maxCollapsed) {
      return Wrap(
        spacing: 5,
        runSpacing: 5,
        children: [
          for (final c in widget.chips)
            _EffectChip(chip: c, color: _categoryColor(c.tag.category)),
        ],
      );
    }

    final displayedChips =
        _isExpanded ? widget.chips : widget.chips.take(maxCollapsed).toList();
    final hiddenCount = widget.chips.length - maxCollapsed;

    return Wrap(
      spacing: 5,
      runSpacing: 5,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final c in displayedChips)
          _EffectChip(chip: c, color: _categoryColor(c.tag.category)),

        // Inline tactile expand/collapse action pill
        InkWell(
          onTap: () {
            Haptics.selection();
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: flair.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: flair.primary.withValues(alpha: 0.45),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: flair.headlineStat,
                  size: 13,
                ),
                const SizedBox(width: 3),
                GoopText(
                  _isExpanded ? 'COLLAPSE' : '+$hiddenCount MORE',
                  style: TextStyle(
                    fontSize: 10.5 * Responsive.factor(context),
                    fontWeight: FontWeight.w900,
                    color: flair.headlineStat,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
