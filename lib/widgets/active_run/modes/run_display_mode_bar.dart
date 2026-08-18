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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
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
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _showPreferencesSheet(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 14,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
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
                onTap: () => _showPreferencesSheet(context),
                child: Icon(
                  Icons.tune_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: 8),
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
        RunDisplayMode.classic => Icons.view_agenda_rounded,
        RunDisplayMode.codex => Icons.menu_book_rounded,
        RunDisplayMode.compact => Icons.view_compact_rounded,
        RunDisplayMode.matrix => Icons.code_rounded,
        RunDisplayMode.signature => Icons.auto_awesome_rounded,
      };

  /// Opens the preferences bottom sheet — display mode picker +
  /// 2.5D inventory toggle + tilt intensity slider. The sheet uses
  /// the existing dark container + grabber styling pattern.
  void _showPreferencesSheet(BuildContext context) {
    Haptics.selection();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131316),
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        side: BorderSide(color: Color(0xFF303036), width: 1.5),
      ),
      builder: (ctx) => const _PreferencesSheet(),
    );
  }
}

/// The preferences bottom sheet — display mode + 2.5D controls.
class _PreferencesSheet extends StatelessWidget {
  const _PreferencesSheet();

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    return ValueListenableBuilder<VisualPrefs>(
      valueListenable: VisualPrefs.notifier,
      builder: (context, prefs, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grabber
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              GoopText(
                'DISPLAY PREFERENCES',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: flair.primary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16),

              // 1. Display Mode picker
              _sectionLabel('DISPLAY MODE'),
              const SizedBox(height: 8),
              Row(
                children: RunDisplayMode.values.map((mode) {
                  final selected = mode == prefs.runDisplayMode;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () {
                          Haptics.selection();
                          VisualPrefs.setRunDisplayMode(mode);
                        },
                        child: _buildModeCard(mode, selected, flair),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // 2. 2.5D Inventory toggle
              _sectionLabel('2.5D INVENTORY'),
              const SizedBox(height: 4),
              GoopText(
                'Volumetric tilt + depth shadow on inventory tiles',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 8),
              _toggleRow(
                'Enable 2.5D',
                prefs.depthInventory,
                (v) => VisualPrefs.setDepthInventory(v),
                flair,
              ),
              const SizedBox(height: 16),

              // 3. Tilt Intensity slider
              _sectionLabel('TILT INTENSITY'),
              const SizedBox(height: 4),
              GoopText(
                'Max tilt degrees on tap/hover (0 = flat, 100 = full)',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 4),
              Slider(
                value: prefs.depthTiltIntensity,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                activeColor: flair.primary,
                label: '${(prefs.depthTiltIntensity * 100).round()}%',
                onChanged: prefs.depthInventory
                    ? (v) => VisualPrefs.setDepthTiltIntensity(v)
                    : null,
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String label) {
    return GoopText(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: Colors.white.withValues(alpha: 0.5),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _toggleRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
    ThemeFlair flair,
  ) {
    return Row(
      children: [
        Expanded(
          child: GoopText(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: flair.primary,
        ),
      ],
    );
  }

  Widget _buildModeCard(RunDisplayMode mode, bool selected, ThemeFlair flair) {
    final icon = switch (mode) {
      RunDisplayMode.classic => Icons.view_agenda_rounded,
      RunDisplayMode.codex => Icons.menu_book_rounded,
      RunDisplayMode.compact => Icons.view_compact_rounded,
      RunDisplayMode.matrix => Icons.code_rounded,
      RunDisplayMode.signature => Icons.auto_awesome_rounded,
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
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
          ),
          const SizedBox(height: 4),
          GoopText(
            mode.description,
            style: TextStyle(
              fontSize: 8,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
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
      RunDisplayMode.classic => Icons.view_agenda_rounded,
      RunDisplayMode.codex => Icons.menu_book_rounded,
      RunDisplayMode.compact => Icons.view_compact_rounded,
      RunDisplayMode.matrix => Icons.code_rounded,
      RunDisplayMode.signature => Icons.auto_awesome_rounded,
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
