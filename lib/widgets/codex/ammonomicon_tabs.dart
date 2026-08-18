import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/app_theme.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/haptics.dart';

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
  }) : assert(icon != null || assetIcon != null,
            'either icon or assetIcon must be provided');
}

/// A vertical strip of bookmark tabs anchored to the left edge.
///
/// Tapping a tab calls [onSelect] with its index. The active tab is
/// pulled out further and glows in its accent color; inactive tabs sit
/// flush against the edge and are dimmed. Tabs animate in from the left
/// on first build.
class AmmonomiconTabStrip extends StatelessWidget {
  final List<AmmonomiconTab> tabs;
  final int selected;
  final ValueChanged<int> onSelect;
  final double topPadding;

  const AmmonomiconTabStrip({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelect,
    this.topPadding = 12,
  });

  /// Asset path for an ammonomicon tab icon stem.
  static String tabAssetPath(String stem) {
    final ext = stem.endsWith('.png') ? 'png' : 'webp';
    return 'assets/images/codex/tabs/$stem.$ext';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < tabs.length; i++)
              _BookmarkTab(
                tab: tabs[i],
                active: i == selected,
                onTap: () {
                  Haptics.selection();
                  onSelect(i);
                },
              ).animate().fadeIn(
                    duration: 220.ms,
                    delay: (i * 35).ms,
                  ).slideX(
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
          width: active ? 64 : 52,
          height: active ? 64 : 52,
          decoration: BoxDecoration(
            color: active
                ? color.withValues(alpha: 0.22)
                : flair.card.withValues(alpha: 0.7),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(14),
              bottomRight: Radius.circular(14),
              bottomLeft: Radius.circular(6),
            ),
            border: Border.all(
              color: active
                  ? color.withValues(alpha: 0.9)
                  : color.withValues(alpha: 0.25),
              width: active ? 1.6 : 0.9,
            ),
            boxShadow: active
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
                  color: active
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
    );
  }

  Widget _buildIcon(Color color) {
    final iconColor = active ? color : color.withValues(alpha: 0.6);
    if (tab.assetIcon != null) {
      return Image.asset(
        AmmonomiconTabStrip.tabAssetPath(tab.assetIcon!),
        width: active ? 26 : 22,
        height: active ? 26 : 22,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        color: active ? null : iconColor,
        colorBlendMode: active ? null : BlendMode.srcIn,
        errorBuilder: (_, __, ___) => Icon(
          tab.icon ?? Icons.bookmark,
          size: active ? 24 : 20,
          color: iconColor,
        ),
      );
    }
    return Icon(
      tab.icon,
      size: active ? 24 : 20,
      color: iconColor,
    );
  }
}
