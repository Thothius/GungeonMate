import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../services/app_theme.dart';
import '../../../services/haptics.dart';
import '../../../services/goop_talk_engine.dart';

/// Fullscreen onboarding dialog that pops up when a new run starts
/// (if [VisualPrefs.showModePickerOnNewRun] is true).
///
/// Shows all 3 display modes as large animated preview cards with
/// descriptions and feature lists. 15% padding on all sides so it
/// reads as a pick overlay, not the actual run view. A "Remember
/// Pick" checkbox at the bottom — when unchecked, sets
/// `showModePickerOnNewRun` to false so it won't show again.
///
/// Tapping a card selects that mode and dismisses the dialog.
class ModePickerOnboardingDialog extends StatefulWidget {
  const ModePickerOnboardingDialog({super.key});

  @override
  State<ModePickerOnboardingDialog> createState() =>
      _ModePickerOnboardingDialogState();
}

class _ModePickerOnboardingDialogState
    extends State<ModePickerOnboardingDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  int _hoveredIndex = -1;
  bool _rememberPick = true;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _selectMode(RunDisplayMode mode) {
    Haptics.selection();
    VisualPrefs.setRunDisplayMode(mode);
    if (!_rememberPick) {
      VisualPrefs.setShowModePickerOnNewRun(false);
    }
    Navigator.of(context).pop(mode);
  }

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.15;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(padding),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _entrance, curve: Curves.easeOut),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D11),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: flair.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: flair.primary.withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                // Header
                _header(flair),
                // Mode cards
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      children: List.generate(
                        RunDisplayMode.values.length,
                        (i) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  i < RunDisplayMode.values.length - 1 ? 10 : 0,
                            ),
                            child: _modeCard(
                              RunDisplayMode.values[i],
                              i,
                              flair,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Remember Pick + dismiss
                _footer(flair),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- Header ---------------------------------------------------------

  Widget _header(ThemeFlair flair) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: flair.primary.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.view_carousel_rounded,
                  size: 20, color: flair.primary),
              const SizedBox(width: 8),
              GoopText(
                'CHOOSE YOUR ACTIVE VIEW',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: flair.primary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          GoopText(
            'Pick how you want to see your run. You can switch anytime via the mode bar.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ---- Mode card ------------------------------------------------------

  Widget _modeCard(RunDisplayMode mode, int index, ThemeFlair flair) {
    final isHovered = _hoveredIndex == index;
    final isSelected = VisualPrefs.notifier.value.runDisplayMode == mode;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: GestureDetector(
        onTap: () => _selectMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          transform: isHovered
              ? (Matrix4.identity()..scale(1.02))
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: isHovered
                ? flair.primary.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? flair.primary.withValues(alpha: 0.5)
                  : isHovered
                      ? flair.primary.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.08),
              width: isSelected || isHovered ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Animated showcase thumbnail
                _showcase(mode, flair, isHovered),
                const SizedBox(width: 14),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(_modeIcon(mode),
                              size: 18, color: flair.primary),
                          const SizedBox(width: 6),
                          GoopText(
                            mode.label.toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: flair.primary,
                              letterSpacing: 1.0,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.check_circle_rounded,
                                size: 14, color: flair.primary),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      GoopText(
                        _modeTagline(mode),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _modeFeatures(mode)
                            .map((f) => _featureChip(f, flair))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                // Tap arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isHovered
                      ? flair.primary
                      : Colors.white.withValues(alpha: 0.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- Animated showcase thumbnail ------------------------------------

  Widget _showcase(
      RunDisplayMode mode, ThemeFlair flair, bool isHovered) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: flair.primary.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
          // Mode-specific animated content
          switch (mode) {
            RunDisplayMode.classic => _classicShowcase(flair),
            RunDisplayMode.codex => _codexShowcase(flair),
            RunDisplayMode.compact => _compactShowcase(flair),
            RunDisplayMode.matrix => _matrixShowcase(flair),
            RunDisplayMode.signature => _signatureShowcase(flair),
          },
          // Hover glow
          if (isHovered)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: flair.primary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _classicShowcase(ThemeFlair flair) {
    // A gently scrolling stack of list rows — the original scroll view.
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _miniRow(flair.primary),
          _miniRow(Colors.white38),
          _miniRow(Colors.white24),
          _miniRow(Colors.white24),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .slideY(begin: 0.06, end: -0.06, duration: 1600.ms, curve: Curves.easeInOut)
        .fadeIn(duration: 400.ms);
  }

  Widget _miniRow(Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _codexShowcase(ThemeFlair flair) {
    return Center(
      child: Icon(Icons.menu_book_rounded, size: 32, color: flair.primary)
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(0.95, 0.95),
            end: const Offset(1.05, 1.05),
            duration: 1200.ms,
            curve: Curves.easeInOut,
          )
          .fadeIn(),
    );
  }

  Widget _compactShowcase(ThemeFlair flair) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _miniBar(flair.primary, 0.7),
          _miniBar(Colors.cyanAccent, 0.4),
          _miniBar(Colors.amberAccent, 0.9),
          _miniBar(flair.primary, 0.5),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(
          duration: 600.ms,
        );
  }

  Widget _miniBar(Color color, double fill) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: fill,
        minHeight: 4,
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.7)),
      ),
    );
  }

  Widget _matrixShowcase(ThemeFlair flair) {
    return Center(
      child: GoopText(
        '01\n10\n01\n11',
        style: TextStyle(
          fontSize: 8,
          fontFamily: 'monospace',
          color: flair.primary.withValues(alpha: 0.6),
          height: 1.1,
        ),
        textAlign: TextAlign.center,
      )
          .animate(onPlay: (c) => c.repeat())
          .fadeIn(duration: 300.ms)
          .then()
          .slideY(
            begin: -0.3,
            end: 0.3,
            duration: 800.ms,
            curve: Curves.linear,
          ),
    );
  }

  Widget _signatureShowcase(ThemeFlair flair) {
    return Center(
      child: Icon(Icons.auto_awesome_rounded,
              size: 28, color: flair.primary)
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .rotate(
            begin: -0.15,
            end: 0.15,
            duration: 1500.ms,
            curve: Curves.easeInOut,
          )
          .scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1.1, 1.1),
            duration: 1200.ms,
            curve: Curves.easeInOut,
          ),
    );
  }

  // ---- Footer ---------------------------------------------------------

  Widget _footer(ThemeFlair flair) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: flair.primary.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _rememberPick = !_rememberPick),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: _rememberPick,
                  onChanged: (v) =>
                      setState(() => _rememberPick = v ?? true),
                  activeColor: flair.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                GoopText(
                  'Remember Pick',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          GoopText(
            'Uncheck to skip this next time',
            style: TextStyle(
              fontSize: 9,
              color: Colors.white.withValues(alpha: 0.3),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Feature chip ---------------------------------------------------

  Widget _featureChip(String label, ThemeFlair flair) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: flair.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: flair.primary.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: GoopText(
        label,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: flair.primary.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  // ---- Mode metadata --------------------------------------------------

  IconData _modeIcon(RunDisplayMode mode) => switch (mode) {
        RunDisplayMode.classic => Icons.view_agenda_rounded,
        RunDisplayMode.codex => Icons.menu_book_rounded,
        RunDisplayMode.compact => Icons.view_compact_rounded,
        RunDisplayMode.matrix => Icons.code_rounded,
        RunDisplayMode.signature => Icons.auto_awesome_rounded,
      };

  String _modeTagline(RunDisplayMode mode) => switch (mode) {
        RunDisplayMode.classic =>
          'The original view. Full scroll, all sections, no frills.',
        RunDisplayMode.codex =>
          'Leather-and-brass compendium. Book-like two-page spread.',
        RunDisplayMode.compact =>
          'Tactical HUD. Everything at a glance, no scrolling.',
        RunDisplayMode.matrix =>
          'Purple digital rain. Data floating over the matrix.',
        RunDisplayMode.signature =>
          'Adapts to your active theme — lore, colors, decorations.',
      };

  List<String> _modeFeatures(RunDisplayMode mode) => switch (mode) {
        RunDisplayMode.classic => [
            'Full scroll view',
            'All dashboards',
            'Sort pickers',
            'Battle-tested',
          ],
        RunDisplayMode.codex => [
            'Character locket',
            'Swipeable pages',
            '2.5D inventory',
            'Live meters',
          ],
        RunDisplayMode.compact => [
            '2-column grid',
            'Stat chips',
            'Overflow sheet',
            'Gold top-DPS',
          ],
        RunDisplayMode.matrix => [
            'Matrix rain',
            'Glass panels',
            'Data streams',
            'Focus panel',
          ],
        RunDisplayMode.signature => [
            'Theme lore header',
            'Themed stat labels',
            'Decorative bg',
            'Live meters',
          ],
      };
}
