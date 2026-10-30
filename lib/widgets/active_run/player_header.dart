import '../../theme/tokens.dart';
import 'package:flutter/material.dart';
import '../paradox/avatar_frame.dart';
import '../../services/goop_talk_engine.dart';
import '../../utils/asset_paths.dart';

/// Two-up player switcher used when local co-op is active (not MP).
/// Each tab is equal-width, large enough to read at a glance, and shows
/// the slot label (P1 / P2) above the character's name.
class PlayerSwitcher extends StatelessWidget {
  final int currentPage;
  final String mainName;
  final String coopName;
  final void Function(int) onPick;
  const PlayerSwitcher({
    super.key,
    required this.currentPage,
    required this.mainName,
    required this.coopName,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
        child: Row(
          children: [
            Expanded(
              child: BigPlayerTab(
                active: currentPage == 0,
                slotLabel: 'P1',
                characterName: mainName,
                onTap: () => onPick(0),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BigPlayerTab(
                active: currentPage == 1,
                slotLabel: 'P2',
                characterName: coopName,
                onTap: () => onPick(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sleek tall pill used by both local-coop and MP player switchers.
/// Two-line layout: slot/role label on top, name on bottom. Active state
/// fills with primary tint; inactive is a hairline outline on near-black.
class BigPlayerTab extends StatelessWidget {
  final bool active;
  final String slotLabel;
  final String characterName;
  final VoidCallback onTap;

  /// Optional opacity multiplier for showing a peer tab as stale.
  final double opacity;

  /// Gungeoneer name used for the map icon lookup. In local co-op this
  /// is the same as [characterName]. In MP, [characterName] is the
  /// lobby nickname (shown as text) while [gungeoneerName] is the
  /// actual character (used for the map icon). Falls back to
  /// [characterName] when null.
  final String? gungeoneerName;

  /// Custom avatar (`id` or `id:frame`) — replaces the gungeoneer map
  /// icon when set, matching the paradox panel's FramedAvatar.
  final String? avatarId;
  const BigPlayerTab({
    super.key,
    required this.active,
    required this.slotLabel,
    required this.characterName,
    required this.onTap,
    this.opacity = 1.0,
    this.gungeoneerName,
    this.avatarId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;
    final onSurface = colorScheme.onSurface;
    return Opacity(
      opacity: opacity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.all(Radii.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.all(Radii.sm),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color:
                  active
                      ? primary.withValues(alpha: 0.15)
                      : onSurface.withValues(alpha: 0.02),
              borderRadius: BorderRadius.all(Radii.sm),
              border: Border.all(
                color:
                    active
                        ? primary.withValues(alpha: 0.5)
                        : onSurface.withValues(alpha: 0.06),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Gungeoneer map icon (9x9px pixel art, scaled up crisp).
                // Use gungeoneerName for the icon lookup (falls back to
                // characterName for local co-op where they're the same).
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child:
                      avatarId != null && avatarId!.isNotEmpty
                          ? FramedAvatar(id: avatarId!, size: 36, radius: 8)
                          : () {
                            final iconName = gungeoneerName ?? characterName;
                            return Image.asset(
                              gungeoneerMapIconPath(iconName) ??
                                  localGungeoneerIcon(iconName),
                              width: 36,
                              height: 36,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.none,
                              cacheWidth: 72,
                              cacheHeight: 72,
                              errorBuilder:
                                  (_, _, _) => Image.asset(
                                    localGungeoneerIcon(iconName),
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.none,
                                    cacheWidth: 72,
                                    cacheHeight: 72,
                                    errorBuilder:
                                        (_, _, _) => const SizedBox.shrink(),
                                  ),
                            );
                          }(),
                ),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GoopText(
                        slotLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                          color:
                              active
                                  ? primary
                                  : onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: GoopText(
                          characterName,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight:
                                active ? FontWeight.w800 : FontWeight.w600,
                            color:
                                active
                                    ? onSurface
                                    : onSurface.withValues(alpha: 0.82),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
