part of '../player_page.dart';

class _SynergyRow extends StatelessWidget {
  final Synergy synergy;
  final bool isActive;
  final Set<String> ownedLower;
  final RunProvider provider;

  const _SynergyRow({
    required this.synergy,
    required this.isActive,
    required this.ownedLower,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final allItems = [...synergy.items, ...synergy.anyOf];
    final statusColor = isActive ? Colors.greenAccent : Colors.amberAccent;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            isActive
                ? Colors.green.withValues(alpha: 0.07)
                : Colors.amber.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withValues(alpha: isActive ? 0.3 : 0.15),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (synergy.icon.isNotEmpty)
                GameIcon(assetPath: synergy.icon, size: 26, showRing: false)
              else
                Icon(Icons.auto_awesome, size: 20, color: statusColor),
              const SizedBox(width: 10),
              Expanded(
                child: GoopText(
                  synergy.name,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color:
                        isActive ? onSurface : onSurface.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.all(Radii.sm),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: GoopText(
                  isActive ? 'ACTIVE' : 'PARTIAL',
                  style: TextStyle(
                    fontSize: FontSizes.labelSmall,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GoopText(
            synergy.prettyEffect.isNotEmpty
                ? synergy.prettyEffect
                : synergy.effect,
            style: TextStyle(
              fontSize: FontSizes.labelMedium,
              color: onSurface.withValues(alpha: 0.55),
              height: 1.35,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (int i = 0; i < allItems.length; i++) ...[
                if (i > 0 && i < synergy.items.length)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Icon(
                      Icons.add,
                      size: 12,
                      color: onSurface.withValues(alpha: 0.2),
                    ),
                  ),
                _SynergyItemPill(
                  itemName: allItems[i],
                  isOwned: ownedLower.contains(allItems[i].toLowerCase()),
                  isActive: isActive,
                  provider: provider,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SynergyItemPill extends StatelessWidget {
  final String itemName;
  final bool isOwned;
  final bool isActive;
  final RunProvider provider;

  const _SynergyItemPill({
    required this.itemName,
    required this.isOwned,
    required this.isActive,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final gun = provider.gunByName(itemName);
    final item = provider.itemByName(itemName);
    final iconPath = gun?.icon ?? item?.icon ?? '';
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final pillColor =
        isActive
            ? Colors.greenAccent.withValues(alpha: 0.4)
            : isOwned
            ? onSurface.withValues(alpha: 0.3)
            : onSurface.withValues(alpha: 0.08);

    return Opacity(
      opacity: isOwned ? 1.0 : 0.4,
      child: Container(
        width: 72,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color:
              isOwned
                  ? onSurface.withValues(alpha: 0.08)
                  : AppTheme.flair.scaffold,
          borderRadius: BorderRadius.all(Radii.md),
          border: Border.all(color: pillColor, width: 1.8),
          boxShadow:
              isOwned && isActive
                  ? [
                    BoxShadow(
                      color: Colors.greenAccent.withValues(alpha: 0.15),
                      blurRadius: 8,
                    ),
                  ]
                  : null,
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.all(Radii.sm),
              child: SizedBox(
                width: 52,
                height: 52,
                child: _buildImage(iconPath),
              ),
            ),
            const SizedBox(height: 6),
            GoopText(
              itemName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: FontSizes.labelSmall,
                fontWeight: FontWeight.w700,
                color:
                    isOwned
                        ? onSurface.withValues(alpha: 0.7)
                        : onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.isEmpty) return _fallback();
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return Image.asset(
      path,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      cacheWidth: 104,
      cacheHeight: 104,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    final onSurface =
        Contrast.luminance(AppTheme.flair.card) > 0.5
            ? const Color(0xFF1E1E22)
            : const Color(0xFFF0F0F0);
    return Container(
      color: AppTheme.flair.scaffold,
      child: Center(
        child: GoopText(
          itemName.isNotEmpty ? itemName[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: FontSizes.titleSmall,
            fontWeight: FontWeight.bold,
            color: onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

/// Circular quick-action button for the floating tile-actions pill.
class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}
