part of '../player_page.dart';

/// Quick-action button for the floating tile-actions pill — circular
/// icon with an optional tiny caption underneath. 76px touch target
/// keeps the pill readable and easy to hit.
class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? label;
  const _QuickActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.65),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            GoopText(
              label!,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: color.withValues(alpha: 0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact card shown when every gun/item of a section is stashed in
/// the backpack — keeps the section from looking like an empty
/// starter loadout and offers a one-tap way back into the bag.
class _AllStowedCard extends StatelessWidget {
  final String label;
  final int stashedCount;
  final VoidCallback onOpen;
  const _AllStowedCard({
    required this.label,
    required this.stashedCount,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final f = AppTheme.flair;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Material(
        color: f.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onOpen,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF8D6E63).withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.backpack_outlined,
                  size: 22,
                  color: Color(0xFF8D6E63),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GoopText(
                    'All $label stowed — $stashedCount in storage',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Colors.white38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ITEMS-section header shortcut into the Backpack screen — backpack
/// glyph with the stashed count badge.
class _BackpackHeaderBtn extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _BackpackHeaderBtn({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Open Mimic Storage',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF8D6E63).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF8D6E63).withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.backpack_outlined,
                  size: 15,
                  color: Color(0xFFBCAAA4),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 4),
                  GoopText(
                    '$count',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFBCAAA4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
