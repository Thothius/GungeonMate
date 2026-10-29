import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/app_theme.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/haptics.dart';
import '../../theme/tokens.dart';

/// Ammonomicon-style bookmark tab definition.
///
/// Tabs come in from the left edge of the screen like bookmarks poking
/// out of a book. Each tab has an icon (either an ammonomicon tab asset
/// or a Material icon), a label, and an accent color. The active tab is
/// pulled out further and lit; inactive tabs are dimmed and tucked in.
class AmmonomiconTab {
  final String label;
  final IconData? icon;
  final String? assetIcon; // ammonomicon tab asset stem
  final Color color;
  final bool isSpecial;

  const AmmonomiconTab({
    required this.label,
    this.icon,
    this.assetIcon,
    required this.color,
    required this.isSpecial,
  }) : assert(
         icon != null || assetIcon != null,
         'either icon or assetIcon must be provided',
       );
}

/// A vertical strip of bookmark tabs anchored to the left edge.
///
/// Tapping a tab calls [onSelect] with its index. The active tab is
/// pulled out further and glows in its accent color; inactive tabs sit
/// flush against the edge and are dimmed. Tabs animate in from the left
/// on first build.
///
/// When [collapsed] is true, the tabs slide off-screen and a small
/// toggle button remains so the user can bring them back. When false,
/// the full strip is visible with a collapse button at the top.
class AmmonomiconTabStrip extends StatelessWidget {
  final List<AmmonomiconTab> tabs;
  final int selected;
  final ValueChanged<int> onSelect;
  final double topPadding;
  final bool collapsed;
  final VoidCallback? onToggleCollapse;

  const AmmonomiconTabStrip({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelect,
    this.topPadding = 12,
    this.collapsed = false,
    this.onToggleCollapse,
  });

  /// Asset path for an ammonomicon tab icon stem.
  static String tabAssetPath(String stem) {
    // Stems may arrive with or without an extension. The codex tab
    // assets are a mix of .png and .webp, so we check both on disk via
    // the asset list. Since we can't do filesystem checks at runtime,
    // we use a lookup table for the known mixed extensions.
    final ext = _tabExtensions[stem] ?? 'webp';
    return 'assets/images/codex/tabs/$stem.$ext';
  }

  // Extension lookup — needed because the tab assets are a mix of
  // .png and .webp. If a stem isn't here, .webp is used as default.
  static const _tabExtensions = <String, String>{
    'Ammonomicon_Tab_Guns': 'png',
    'Ammonomicon_Tab_Items': 'png',
    'Ammonomicon_Tab_Enemies': 'png',
  };

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final activeTab =
        tabs.isNotEmpty ? tabs[selected.clamp(0, tabs.length - 1)] : null;

    // ── Collapsed: show only a small toggle button ──
    if (collapsed) {
      final accent = activeTab?.color ?? flair.primary;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: GestureDetector(
                onTap: () {
                  Haptics.selection();
                  onToggleCollapse?.call();
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: 32,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.22),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(2, 0),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: accent,
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 200.ms)
              .slideX(
                begin: -0.5,
                end: 0.0,
                duration: 250.ms,
                curve: Curves.easeOutCubic,
              ),
        ),
      );
    }

    // ── Expanded: full tab strip + collapse toggle at top ──
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Collapse toggle button
            if (onToggleCollapse != null)
              GestureDetector(
                onTap: () {
                  Haptics.selection();
                  onToggleCollapse!.call();
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 56,
                  height: 28,
                  margin: const EdgeInsets.only(bottom: 6, left: 0),
                  decoration: BoxDecoration(
                    color: flair.card.withValues(alpha: 0.7),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                    border: Border.all(
                      color: flair.primary.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 16,
                    color: flair.primary.withValues(alpha: 0.6),
                  ),
                ),
              ).animate().fadeIn(duration: 200.ms),
            for (var i = 0; i < tabs.length; i++)
              _BookmarkTab(
                    tab: tabs[i],
                    active: i == selected,
                    onTap: () {
                      Haptics.selection();
                      onSelect(i);
                    },
                  )
                  .animate()
                  .fadeIn(duration: 220.ms, delay: (i * 35).ms)
                  .slideX(
                    begin: -1.0,
                    end: 0.0,
                    duration: 280.ms,
                    curve: Curves.easeOutCubic,
                    delay: (i * 35).ms,
                  ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _BookmarkTab — a single bookmark poking out from the left edge
// =============================================================================

class _BookmarkTab extends StatelessWidget {
  final AmmonomiconTab tab;
  final bool active;
  final VoidCallback onTap;

  const _BookmarkTab({
    required this.tab,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final color = tab.color;
    return Padding(
      // Active tabs pull out further (more right padding on the right
      // side of the tab so it reads as "lifted"). Inactive tabs tuck
      // closer to the edge.
      padding: EdgeInsets.only(bottom: 6, right: active ? 0 : 0),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          // Active tab is wider (pulled out) and taller.
          width: active ? 68 : 56,
          height: active ? 68 : 56,
          decoration: BoxDecoration(
            color:
                active
                    ? color.withValues(alpha: 0.22)
                    : flair.card.withValues(alpha: 0.7),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(14),
              bottomRight: Radius.circular(14),
              bottomLeft: Radius.circular(6),
            ),
            border: Border.all(
              color:
                  active
                      ? color.withValues(alpha: 0.9)
                      : color.withValues(alpha: 0.5),
              width: active ? 1.6 : 1.1,
            ),
            boxShadow:
                active
                    ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(2, 0),
                      ),
                    ]
                    : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(Insets.sm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIcon(color),
                const SizedBox(height: 2),
                GoopText(
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: active ? 8.5 : 7.5,
                    fontWeight: FontWeight.w800,
                    color:
                        active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.55),
                    letterSpacing: 0.2,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(Color color) {
    // Original pixel art shows at full opacity for both active and inactive
    // states. Inactive state is conveyed by the tab container (dimmer
    // background, thinner border, no glow shadow), not by tinting the icon.
    final iconColor = color;
    if (tab.assetIcon != null) {
      return Image.asset(
        AmmonomiconTabStrip.tabAssetPath(tab.assetIcon!),
        width: active ? 28 : 24,
        height: active ? 28 : 24,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        cacheWidth: 56,
        cacheHeight: 56,
        errorBuilder:
            (_, __, ___) => Icon(
              tab.icon ?? Icons.bookmark,
              size: active ? 26 : 22,
              color: iconColor,
            ),
      );
    }
    return Icon(tab.icon, size: active ? 26 : 22, color: iconColor);
  }
}
