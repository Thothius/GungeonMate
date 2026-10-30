part of 'settings_tab.dart';

/// Data model for a compact grid action tile.
class _TileData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TileData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

/// Compact icon+label action tile for the 2-column settings grid.
class _CompactActionTile extends StatelessWidget {
  final _TileData data;
  const _CompactActionTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Material(
      color: flair.card.withValues(alpha: 0.6),
      borderRadius: BorderRadius.all(Radii.md),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.all(Radii.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radii.md),
            border: Border.all(
              color: data.color.withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.all(Radii.sm),
                ),
                child: Icon(data.icon, size: 20, color: data.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GoopText(
                  data.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: onSurface.withValues(alpha: 0.8),
                    letterSpacing: 0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A collapsible settings card with a header row (icon + title + chevron)
/// and expandable content. Tapping the header toggles expansion.
class _CollapsibleCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final ThemeFlair flair;
  final Widget child;
  final bool initiallyExpanded;

  const _CollapsibleCard({
    required this.title,
    required this.icon,
    required this.flair,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<_CollapsibleCard> createState() => _CollapsibleCardState();
}

class _CollapsibleCardState extends State<_CollapsibleCard>
    with SingleTickerProviderStateMixin {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.flair.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      decoration: BoxDecoration(
        color: widget.flair.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.all(Radii.md),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.16),
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: () {
              Haptics.selection();
              setState(() => _expanded = !_expanded);
            },
            borderRadius: BorderRadius.all(Radii.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 18,
                    color: accentColor.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GoopText(
                      widget.title,
                      style: TextStyle(
                        fontSize: FontSizes.labelMedium,
                        fontWeight: FontWeight.w900,
                        color: accentColor.withValues(alpha: 0.9),
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: widget.child,
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState:
                _expanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

/// Internal helper for 2-col settings layout — wraps a section with an
/// optional label header (e.g., "GENERAL", "CUSTOMIZATION").
class _SettingsSection extends StatelessWidget {
  final String label;
  final ThemeFlair flair;
  final Widget child;

  const _SettingsSection({
    required this.label,
    required this.flair,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: GoopText(
              label,
              style: TextStyle(
                fontSize: FontSizes.labelSmall,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.2,
                color: flair.primary.withValues(alpha: 0.65),
              ),
            ),
          ),
        child,
      ],
    );
  }
}
