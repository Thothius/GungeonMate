import 'package:flutter/material.dart';

import '../../../services/app_theme.dart';
import '../../../services/haptics.dart';
import '../../../services/goop_talk_engine.dart';

/// A collapsible mode-switcher bar for the active run screen.
///
/// Shows 3 tappable preview cards (Codex Book / Compact Run / Gungeon
/// Matrix) when expanded, or a single pill showing the current mode
/// when collapsed. Tapping a card switches [VisualPrefs.runDisplayMode]
/// instantly — the active run rebuilds with the new mode, no navigation.
///
/// Default state: collapsed (user-confirmed). The collapsed pill shows
/// the current mode name + a chevron. Tapping it expands to the 3-card
/// strip. Tapping a card collapses back down and applies the selection
/// in one motion.
///
/// Placement: between the MpHeader/PlayerSwitcher and the PageView in
/// `active_run_screen.dart`. Run-scope (not per-player), so it sits
/// above the PageView.
class RunDisplayModeBar extends StatefulWidget {
  const RunDisplayModeBar({super.key});

  @override
  State<RunDisplayModeBar> createState() => _RunDisplayModeBarState();
}

class _RunDisplayModeBarState extends State<RunDisplayModeBar> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    // Start collapsed (the persisted default). The user expands by
    // tapping the pill.
    _expanded = !VisualPrefs.notifier.value.runDisplayModeBarCollapsed;
  }

  void _toggleExpanded() {
    Haptics.selection();
    setState(() => _expanded = !_expanded);
    // Persist the new collapsed state.
    VisualPrefs.setRunDisplayModeBarCollapsed(!_expanded);
  }

  void _selectMode(RunDisplayMode mode) {
    Haptics.selection();
    VisualPrefs.setRunDisplayMode(mode);
    // Collapse after selection — the user picked, free the space.
    setState(() => _expanded = false);
    VisualPrefs.setRunDisplayModeBarCollapsed(true);
  }

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;

    return ValueListenableBuilder<VisualPrefs>(
      valueListenable: VisualPrefs.notifier,
      builder: (context, prefs, _) {
        final mode = prefs.runDisplayMode;
        if (_expanded) {
          return _buildExpanded(context, mode, flair);
        }
        return _buildCollapsed(context, mode, flair);
      },
    );
  }

  Widget _buildCollapsed(BuildContext context, RunDisplayMode mode, ThemeFlair flair) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: _toggleExpanded,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: flair.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: flair.primary.withValues(alpha: 0.25), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_modeIcon(mode), size: 16, color: flair.primary),
              const SizedBox(width: 8),
              GoopText(
                mode.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: flair.primary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: flair.primary.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpanded(BuildContext context, RunDisplayMode current, ThemeFlair flair) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        children: [
          Row(
            children: [
              GoopText(
                'DISPLAY MODE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.4),
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _toggleExpanded,
                child: Icon(
                  Icons.expand_less_rounded,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: RunDisplayMode.values.map((mode) {
              final selected = mode == current;
              return Expanded(
                child: _ModeCard(
                  mode: mode,
                  selected: selected,
                  onTap: () => _selectMode(mode),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _modeIcon(RunDisplayMode mode) => switch (mode) {
        RunDisplayMode.codex => Icons.menu_book_rounded,
        RunDisplayMode.compact => Icons.view_compact_rounded,
        RunDisplayMode.matrix => Icons.code_rounded,
      };
}

/// A single mode preview card in the expanded bar.
class _ModeCard extends StatelessWidget {
  final RunDisplayMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final icon = switch (mode) {
      RunDisplayMode.codex => Icons.menu_book_rounded,
      RunDisplayMode.compact => Icons.view_compact_rounded,
      RunDisplayMode.matrix => Icons.code_rounded,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? flair.primary.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? flair.primary.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.08),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: flair.primary.withValues(alpha: 0.15),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? flair.primary : Colors.white.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 6),
              GoopText(
                mode.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: selected ? flair.primary : Colors.white.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
