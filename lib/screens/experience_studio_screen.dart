import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/tokens.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_theme.dart';
import '../services/goop_talk_engine.dart';
import '../services/haptics.dart';
import '../widgets/active_run/bottom_back_bar.dart';
import '../widgets/scale_button.dart';
import '../widgets/particle_engine.dart';
import 'palette_maker_screen.dart';
import '../utils/fast_route.dart';

/// Palettes — the default view is a simple list of tall palette
/// panels (name + organized color chips) with a back/preview/apply
/// bar. The screen skins itself with the previewed theme, so tapping
/// a panel is the live preview. A full-screen swipeable preview
/// modal sits behind the PREVIEW button. Apply commits.
///
/// [initialTab] > 0 opens the full studio chrome (Palettes /
/// Particles / Typography / Ambiance tabs) straight on that tab —
/// reached via the picker's ADVANCED row.
class ExperienceStudioScreen extends StatefulWidget {
  final int initialTab;
  const ExperienceStudioScreen({super.key, this.initialTab = 0});

  @override
  State<ExperienceStudioScreen> createState() => _ExperienceStudioScreenState();
}

class _ExperienceStudioScreenState extends State<ExperienceStudioScreen> {
  late int _tab;
  late AppThemeMode _previewMode;
  late final AppThemeMode _originalMode;
  // Simple view's own tab — PALETTES / FONTS / PARTICLES / GLOWS / PREVIEW.
  int _simpleTab = 0;

  static const _tabLabels = ['Palettes', 'Particles', 'Typography', 'Ambiance'];
  static const _tabIcons = [
    Icons.palette_rounded,
    Icons.scatter_plot_rounded,
    Icons.text_fields_rounded,
    Icons.blur_on_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _previewMode = AppTheme.mode;
    _originalMode = AppTheme.mode;
    AppTheme.previewNotifier.value = _previewMode;
  }

  @override
  void dispose() {
    AppTheme.previewNotifier.value = null;
    super.dispose();
  }

  Future<void> _applyAndClose() async {
    Haptics.success();
    AppTheme.previewNotifier.value = null;
    await AppTheme.setMode(_previewMode);
    if (!mounted) return;
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cleanTextTheme = GoogleFonts.montserratTextTheme(
      ThemeData.dark().textTheme,
    );
    final cleanTheme = Theme.of(context).copyWith(textTheme: cleanTextTheme);

    return Theme(
      data: cleanTheme,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // Back moved to the bottom thumb zone (task 17 sweep).
        bottomNavigationBar:
            Navigator.of(context).canPop() ? const BottomBackBar() : null,
        body: SafeArea(
          child: Stack(
            children: [
              // ── Theme background — skins with the PREVIEW theme, not the
              // actual app theme, so the whole screen updates on tap ──
              _buildPreviewBackground(),
              widget.initialTab == 0 ? _buildSimpleBody() : _buildStudioBody(),
            ],
          ),
        ),
      ),
    );
  }

  /// Background that skins with the preview theme so the entire screen
  /// immediately reflects the selected theme — not just the preview box.
  Widget _buildPreviewBackground() {
    final flair = AppTheme.flairFor(_previewMode);
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [flair.scaffold, flair.scaffold.withValues(alpha: 0.95)],
          ),
        ),
      ),
    );
  }

  // ── Simple picker (initialTab == 0) ───────────────────────────
  // Tall palette panels + a back/preview/apply bar. Nothing else —
  // the screen itself is the preview.

  /// Tap-to-preview: session skin + notifier + curated preset
  /// application — same path the studio grid uses.
  void _previewTheme(AppThemeMode m) {
    Haptics.selection();
    setState(() => _previewMode = m);
    AppTheme.previewNotifier.value = m;
    final curation = kThemeCuration[m];
    if (curation != null) VisualPrefs.applyCuration(curation);
  }

  Widget _buildSimpleBody() {
    return Column(
      children: [
        _buildCurrentPanel(),
        _buildSimpleTabBar(),
        Expanded(child: _buildSimpleTabContent()),
        _buildSimpleBottomBar(),
      ],
    );
  }

  static const _simpleTabs = [
    'PALETTES',
    'FONTS',
    'PARTICLES',
    'GLOWS',
    'PREVIEW',
  ];

  /// Top panel — current active picks at a glance.
  Widget _buildCurrentPanel() {
    final flair = AppTheme.flairFor(_previewMode);
    final prefs = VisualPrefs.notifier.value;
    final pType = ParticleType.values[prefs.particleTypeIndex];
    final glow =
        VisualPrefs.glowColors[prefs.glowColorIndex.clamp(
          0,
          VisualPrefs.glowColors.length - 1,
        )];
    return Container(
      margin: const EdgeInsets.fromLTRB(
        Insets.lg,
        Insets.sm,
        Insets.lg,
        Insets.xs,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: flair.card.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: flair.primary.withValues(alpha: 0.4),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: flair.glowPrimary.withValues(alpha: 0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GoopText(
                  _previewMode.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: flair.primary,
                  ),
                ),
                const SizedBox(height: 4),
                GoopText(
                  '${prefs.font.label} · ${pType.name.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: flair.secondary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          // Current glow swatch
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: glow,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(color: glow.withValues(alpha: 0.6), blurRadius: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Compact pill tab bar for the simple view.
  Widget _buildSimpleTabBar() {
    final flair = AppTheme.flairFor(_previewMode);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Insets.lg,
        Insets.xs,
        Insets.lg,
        Insets.sm,
      ),
      child: Row(
        children: List.generate(_simpleTabs.length, (i) {
          final active = _simpleTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _simpleTab = i);
                Haptics.selection();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color:
                      active
                          ? flair.primary.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        active
                            ? flair.primary.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.12),
                    width: active ? 1.5 : 1.0,
                  ),
                ),
                child: Center(
                  child: GoopText(
                    _simpleTabs[i],
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color:
                          active
                              ? flair.primary
                              : Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSimpleTabContent() {
    switch (_simpleTab) {
      case 0:
        return _buildPaletteList();
      case 1:
        return const _TypographyStep();
      case 2:
        return const _ParticlesStep();
      case 3:
        return const _AmbianceStep();
      default:
        return _buildPreviewPane();
    }
  }

  /// PREVIEW — themed card chrome with the working palette.
  Widget _buildPreviewPane() {
    final flair = AppTheme.flairFor(_previewMode);
    return Center(
      child: Container(
        margin: const EdgeInsets.all(Insets.lg),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: flair.card,
          borderRadius: BorderRadius.circular(flair.cardRadius),
          border: Border.all(
            color:
                flair.cardBorderColor ?? flair.primary.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: flair.glowPrimary.withValues(alpha: 0.4),
              blurRadius: 14,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GoopText(
              _previewMode.label.toUpperCase(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: flair.headlineStat,
              ),
            ),
            const SizedBox(height: 8),
            GoopText(
              _previewMode.vibe,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: flair.secondary,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final c in [
                  flair.scaffold,
                  flair.card,
                  flair.primary,
                  flair.secondary,
                  flair.headlineStat,
                ])
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaletteList() {
    final activeMode = AppTheme.mode;
    return ValueListenableBuilder<List<SavedCustomTheme>>(
      valueListenable: CustomThemeStore.notifier,
      builder: (context, saved, _) {
        return CustomScrollView(
          slivers: [
            // Palettes in a 2-column grid — picker + saved.
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                Insets.lg,
                Insets.sm,
                Insets.lg,
                Insets.sm,
              ),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.15,
                children: [
                  for (final m in kPickerThemes)
                    () {
                      final f = AppTheme.flairFor(m);
                      return _PalettePanel(
                        name: m.label,
                        subtitle: '${m.vibe} · ${m.elem}',
                        colors: [
                          f.scaffold,
                          f.card,
                          f.primary,
                          f.secondary,
                          f.headlineStat,
                        ],
                        nameColor: f.primary,
                        isActive: m == activeMode,
                        isPreview: m == _previewMode,
                        onTap: () => _previewTheme(m),
                      );
                    }(),
                  for (final t in saved) _buildSavedPanel(t),
                ],
              ),
            ),
            // Full-width rows below the grid — make + advanced.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.lg,
                  0,
                  Insets.lg,
                  Insets.sm,
                ),
                child: Column(
                  children: [_buildMakePanel(), _buildAdvancedPanel()],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// '+ MAKE YOUR PALETTE' — opens the palette maker.
  Widget _buildMakePanel() {
    final f = AppTheme.flairFor(_previewMode);
    return GestureDetector(
      onTap: () {
        Haptics.selection();
        Navigator.push(context, fastRoute(const PaletteMakerScreen()));
      },
      child: Container(
        height: 64,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: f.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 22, color: f.primary),
            const SizedBox(width: 8),
            GoopText(
              'MAKE YOUR PALETTE',
              style: TextStyle(
                fontSize: FontSizes.labelMedium,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: f.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Saved user palette — tap applies it via the custom theme path.
  Widget _buildSavedPanel(SavedCustomTheme t) {
    final d = t.customData ?? CustomThemeData.defaultTheme;
    return _PalettePanel(
      name: t.name,
      subtitle: 'SAVED PALETTE',
      colors: [d.scaffold, d.card, d.primary, d.secondary, d.headlineStat],
      nameColor: d.primary,
      isActive: false,
      isPreview: _previewMode == AppThemeMode.custom,
      onTap: () {
        AppTheme.saveCustomThemeData(d);
        _previewTheme(AppThemeMode.custom);
      },
    );
  }

  /// Quiet footer row — opens the full studio (particles / fonts /
  /// glow / the old tabbed chrome) on the Particles tab.
  Widget _buildAdvancedPanel() {
    return GestureDetector(
      onTap: () {
        Haptics.selection();
        Navigator.push(
          context,
          fastRoute(const ExperienceStudioScreen(initialTab: 1)),
        );
      },
      child: Container(
        height: 52,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 15,
              color: Colors.white.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 8),
            GoopText(
              'ADVANCED — PARTICLES · FONTS · GLOW',
              style: TextStyle(
                fontSize: FontSizes.labelSmall,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleBottomBar() {
    final flair = AppTheme.flairFor(_previewMode);
    final fg =
        flair.primary.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Insets.lg,
        Insets.xs,
        Insets.lg,
        Insets.md,
      ),
      child: Row(
        children: [
          // BACK — bottom-left ghost.
          ScaleButton(
            onTap: () {
              Haptics.selection();
              Navigator.of(context).maybePop();
            },
            child: Container(
              height: 48,
              width: 92,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.all(Radii.md),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 14,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  GoopText(
                    'BACK',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.white70,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // PREVIEW — center ghost-green.
          const SizedBox(width: 10),
          // APPLY — bottom-right, primary solid.
          Expanded(
            child: ScaleButton(
              onTap: _applyAndClose,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: flair.primary,
                  borderRadius: BorderRadius.all(Radii.md),
                  boxShadow: [
                    BoxShadow(
                      color: flair.primary.withValues(alpha: 0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_rounded, size: 16, color: fg),
                    const SizedBox(width: 8),
                    GoopText(
                      'APPLY',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: fg,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Full studio (initialTab > 0) ───────────────────────────────

  Widget _buildStudioBody() {
    return Column(
      children: [
        _buildTopBar(),
        _buildTabBar(),
        // ── Tab content (bottom portion, scrollable) ──
        Expanded(child: _buildTabContent()),
        // ── Reset / Preview / Apply bar ──
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildTopBar() {
    final f = AppTheme.flairFor(_previewMode);
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.only(
        left: Insets.xs,
        right: Insets.xs,
        top: Insets.xs,
        bottom: Insets.xs,
      ),
      child: Row(
        children: [
          if (!canPop) const SizedBox(width: 48),
          // Theme name + vibe inline
          Expanded(
            child: Column(
              children: [
                GoopText(
                  _previewMode.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: f.primary.withValues(alpha: 0.8),
                    letterSpacing: 1.5,
                  ),
                ),
                GoopText(
                  '${_previewMode.vibe} · ${_previewMode.elem}',
                  style: TextStyle(
                    fontSize: FontSizes.labelSmall,
                    fontWeight: FontWeight.w700,
                    color: f.headlineStat.withValues(alpha: 0.6),
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          // SAVE THEME button (top-right) — visible on any theme so users
          // can save a customized variant of any premade or the custom palette.
          ScaleButton(
            onTap: _showSaveThemeDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.all(Radii.sm),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.6),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.save_rounded, size: 14, color: Colors.amber),
                  const SizedBox(width: 5),
                  GoopText(
                    'SAVE THEME',
                    style: TextStyle(
                      fontSize: FontSizes.labelSmall,
                      fontWeight: FontWeight.w900,
                      color: Colors.amber,
                      letterSpacing: 0.8,
                      shadows: [
                        Shadow(
                          color: Colors.amber.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final flair = AppTheme.flairFor(_previewMode);
    final themeActive = _previewMode == AppTheme.mode;
    final isCustomMode = _previewMode == AppThemeMode.custom;
    return Container(
      margin: const EdgeInsets.fromLTRB(Insets.md, 2, Insets.md, Insets.xs),
      child: Row(
        children: List.generate(_tabLabels.length, (i) {
          final isCurrent = i == _tab;
          final showGreenOutline = i == 0 && themeActive;
          // When CUSTOM is selected, glow the non-theme tabs to direct users
          final showCustomGlow = isCustomMode && i > 0;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                Haptics.selection();
                setState(() => _tab = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: Insets.sm),
                decoration: BoxDecoration(
                  color:
                      isCurrent
                          ? (showGreenOutline
                              ? Colors.green.withValues(alpha: 0.12)
                              : flair.primary.withValues(alpha: 0.15))
                          : (showCustomGlow
                              ? Colors.amber.withValues(alpha: 0.08)
                              : Colors.transparent),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        showGreenOutline
                            ? (isCurrent
                                ? Colors.green
                                : Colors.green.withValues(alpha: 0.5))
                            : (showCustomGlow
                                ? Colors.amber.withValues(
                                  alpha: isCurrent ? 0.6 : 0.3,
                                )
                                : (isCurrent
                                    ? flair.primary.withValues(alpha: 0.5)
                                    : Colors.white.withValues(alpha: 0.08))),
                    width: isCurrent ? 1.5 : 1.0,
                  ),
                  boxShadow:
                      showCustomGlow && !isCurrent
                          ? [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.15),
                              blurRadius: 6,
                            ),
                          ]
                          : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _tabIcons[i],
                      size: 16,
                      color:
                          showGreenOutline
                              ? (isCurrent
                                  ? Colors.green
                                  : Colors.green.withValues(alpha: 0.6))
                              : (showCustomGlow
                                  ? (isCurrent
                                      ? Colors.amber
                                      : Colors.amber.withValues(alpha: 0.7))
                                  : (isCurrent
                                      ? flair.primary
                                      : Colors.white.withValues(alpha: 0.4))),
                    ),
                    const SizedBox(height: 2),
                    GoopText(
                      _tabLabels[i].toUpperCase(),
                      style: TextStyle(
                        fontSize: FontSizes.labelSmall,
                        fontWeight: FontWeight.w900,
                        color:
                            showGreenOutline
                                ? (isCurrent
                                    ? Colors.green
                                    : Colors.green.withValues(alpha: 0.6))
                                : (showCustomGlow
                                    ? (isCurrent
                                        ? Colors.amber
                                        : Colors.amber.withValues(alpha: 0.7))
                                    : (isCurrent
                                        ? flair.primary
                                        : Colors.white.withValues(alpha: 0.4))),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomBar() {
    final flair = AppTheme.flairFor(_previewMode);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Insets.md,
        Insets.sm,
        Insets.md,
        Insets.sm,
      ),
      child: Row(
        children: [
          // RESET
          Expanded(
            child: ScaleButton(
              onTap: _showResetDialog,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.all(Radii.md),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    GoopText(
                      'RESET',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white70,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: Insets.sm),
          // APPLY
          Expanded(
            flex: 2,
            child: ScaleButton(
              onTap: _applyAndClose,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: flair.primary,
                  borderRadius: BorderRadius.all(Radii.md),
                  boxShadow: [
                    BoxShadow(
                      color: flair.primary.withValues(alpha: 0.5),
                      blurRadius: 16,
                      spreadRadius: 0,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: flair.primary.withValues(alpha: 0.2),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      size: 16,
                      color:
                          flair.primary.computeLuminance() > 0.5
                              ? Colors.black87
                              : Colors.white,
                    ),
                    const SizedBox(width: 8),
                    GoopText(
                      'APPLY',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color:
                            flair.primary.computeLuminance() > 0.5
                                ? Colors.black87
                                : Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) {
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.1, 0),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey(_tab), child: _buildTabWidget()),
    );
  }

  Widget _buildTabWidget() {
    switch (_tab) {
      case 0:
        return _ThemeStep(
          previewMode: _previewMode,
          onPreview: (m) {
            setState(() => _previewMode = m);
            AppTheme.previewNotifier.value = m;
            // Apply curated settings for premade themes to the session
            final curation = kThemeCuration[m];
            if (curation != null) {
              VisualPrefs.applyCuration(curation);
            }
          },
          onQuickApply: (m) {
            setState(() => _previewMode = m);
            AppTheme.previewNotifier.value = m;
            _applyAndClose();
          },
        );
      case 1:
        return const _ParticlesStep();
      case 2:
        return const _TypographyStep();
      case 3:
        return const _AmbianceStep();
      default:
        return const SizedBox.shrink();
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder:
          (c) => AlertDialog(
            backgroundColor: AppTheme.flair.card,
            title: const GoopText(
              'Reset to defaults?',
              style: TextStyle(
                fontSize: FontSizes.titleSmall,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: const GoopText(
              'Reverts your preview back to the theme you started with. Your saved settings won\'t change until you Apply.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const GoopText('Cancel'),
              ),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade900,
                ),
                onPressed: () {
                  Navigator.pop(c);
                  _resetAll();
                },
                child: const GoopText('Reset'),
              ),
            ],
          ),
    );
  }

  void _resetAll() {
    Haptics.selection();
    setState(() {
      _previewMode = _originalMode;
      AppTheme.previewNotifier.value = _originalMode;
    });
  }

  /// Show the save-theme dialog — user names the theme and picks a graphic.
  /// Works for any theme (premade or custom). When saving a custom palette,
  /// the CustomThemeData is captured alongside the VisualPrefs.
  void _showSaveThemeDialog() {
    Haptics.selection();
    final nameCtrl = TextEditingController(text: 'My Theme');
    String selectedSplash =
        _previewMode == AppThemeMode.custom
            ? kPickerThemes.first.splashSlug
            : _previewMode.splashSlug;
    String? validationError;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final onSurface = Theme.of(ctx).colorScheme.onSurface;
            final flair = AppTheme.flair;
            return AlertDialog(
              backgroundColor: flair.scaffold,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radii.lg),
              ),
              title: GoopText(
                'Save Theme',
                style: TextStyle(
                  fontSize: FontSizes.titleSmall,
                  fontWeight: FontWeight.w900,
                  color: flair.primary,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GoopText(
                      'Theme Name',
                      style: TextStyle(
                        fontSize: FontSizes.labelSmall,
                        fontWeight: FontWeight.w700,
                        color: onSurface.withValues(alpha: 0.5),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      maxLength: 24,
                      style: TextStyle(
                        color: onSurface,
                        fontSize: FontSizes.bodyMedium,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter theme name...',
                        hintStyle: TextStyle(
                          color: onSurface.withValues(alpha: 0.3),
                        ),
                        filled: true,
                        fillColor: onSurface.withValues(alpha: 0.06),
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: flair.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: flair.primary.withValues(alpha: 0.7),
                          ),
                        ),
                        errorText: validationError,
                      ),
                      onChanged: (value) {
                        if (validationError != null) {
                          setDialogState(() => validationError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    GoopText(
                      'Select Graphic',
                      style: TextStyle(
                        fontSize: FontSizes.labelSmall,
                        fontWeight: FontWeight.w700,
                        color: onSurface.withValues(alpha: 0.5),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 200,
                      child: GridView.builder(
                        shrinkWrap: true,
                        itemCount: kPickerThemes.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 6,
                              mainAxisSpacing: 6,
                            ),
                        itemBuilder: (ctx, i) {
                          final mode = kPickerThemes[i];
                          final slug = mode.splashSlug;
                          final isSelected = slug == selectedSplash;
                          return GestureDetector(
                            onTap: () {
                              Haptics.selection();
                              setDialogState(() => selectedSplash = slug);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radii.sm),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? flair.primary
                                          : onSurface.withValues(alpha: 0.1),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(
                                      'assets/images/themes/splash/$slug.jpg',
                                      fit: BoxFit.cover,
                                      cacheWidth: 200,
                                      cacheHeight: 266,
                                      errorBuilder:
                                          (_, __, ___) => Container(
                                            color: flair.card,
                                            child: Icon(
                                              Icons.image,
                                              size: 24,
                                              color: onSurface.withValues(
                                                alpha: 0.3,
                                              ),
                                            ),
                                          ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 2,
                                          horizontal: 4,
                                        ),
                                        color: Colors.black.withValues(
                                          alpha: 0.6,
                                        ),
                                        child: GoopText(
                                          mode.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: FontSizes.labelSmall,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: GoopText(
                    'CANCEL',
                    style: TextStyle(
                      fontSize: FontSizes.labelMedium,
                      fontWeight: FontWeight.w700,
                      color: onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                ScaleButton(
                  onTap: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      setDialogState(
                        () => validationError = 'Name cannot be empty',
                      );
                      return;
                    }
                    // Check for duplicates
                    final existing =
                        CustomThemeStore.themes
                            .where(
                              (t) => t.name.toLowerCase() == name.toLowerCase(),
                            )
                            .toList();
                    if (existing.isNotEmpty) {
                      setDialogState(
                        () =>
                            validationError =
                                'A theme named "$name" already exists',
                      );
                      return;
                    }
                    Haptics.success();
                    final theme = SavedCustomTheme(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      splashSlug: selectedSplash,
                      baseMode: _previewMode,
                      prefs: VisualPrefs.notifier.value,
                      // Capture custom palette data if saving from CUSTOM mode
                      customData:
                          _previewMode == AppThemeMode.custom
                              ? (AppTheme.cachedCustomTheme ??
                                      CustomThemeData.defaultTheme)
                                  .copyWith(name: name)
                              : null,
                    );
                    await CustomThemeStore.save(theme);
                    if (!ctx.mounted) return;
                    Navigator.of(ctx).pop();
                    // Show confirmation snackbar
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: GoopText('Theme "$name" saved!'),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Insets.lg,
                      vertical: Insets.sm,
                    ),
                    decoration: BoxDecoration(
                      color: flair.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: GoopText(
                      'SAVE',
                      style: TextStyle(
                        fontSize: FontSizes.labelMedium,
                        fontWeight: FontWeight.w900,
                        color:
                            flair.primary.computeLuminance() > 0.5
                                ? Colors.black87
                                : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => nameCtrl.dispose());
  }
}

/// Compact always-visible live preview showing theme BG + particles + glow.
/// Particles are always shown here (regardless of the enable toggle)
/// so users can see what they're picking.
/// Tall palette panel — name + vibe on top, the theme's five core
/// colors as labeled chips along the bottom. The panel's own surface
/// is the theme's card color, so the panel previews the theme.
class _PalettePanel extends StatelessWidget {
  final String name;
  final String subtitle;
  final List<Color> colors; // canvas · panel · prime · second · stat
  final Color nameColor;
  final bool isActive;
  final bool isPreview;
  final VoidCallback onTap;

  const _PalettePanel({
    required this.name,
    required this.subtitle,
    required this.colors,
    required this.nameColor,
    required this.isActive,
    required this.isPreview,
    required this.onTap,
  });

  static const _chipLabels = ['CANVAS', 'PANEL', 'PRIME', 'SECOND', 'STAT'];

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isActive
            ? Colors.green
            : isPreview
            ? nameColor
            : Colors.white.withValues(alpha: 0.08);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        decoration: BoxDecoration(
          color: colors[1].withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: isActive || isPreview ? 1.8 : 1.0,
          ),
          boxShadow:
              isPreview
                  ? [
                    BoxShadow(
                      color: nameColor.withValues(alpha: 0.18),
                      blurRadius: 10,
                    ),
                  ]
                  : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GoopText(
                        name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: nameColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      GoopText(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          letterSpacing: 0.8,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.6),
                      ),
                    ),
                    child: GoopText(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                for (var i = 0; i < colors.length && i < 5; i++) ...[
                  Expanded(child: _colorChip(colors[i], _chipLabels[i])),
                  if (i < 4) const SizedBox(width: 6),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorChip(Color c, String label) {
    return Column(
      children: [
        Container(
          height: 18,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
        ),
        const SizedBox(height: 3),
        GoopText(
          label,
          style: TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}

class _ThemeStepState extends State<_ThemeStep> {
  /// Open the color picker for a single palette field and persist the result.
  /// Show the custom palette editor — a bottom sheet with color swatches
  /// for each palette field. Tapping a swatch opens the color picker.
  @override
  Widget build(BuildContext context) {
    final activeMode = AppTheme.mode;

    // 9 premade palettes + MAKE + saved user palettes.
    final saved = CustomThemeStore.notifier.value;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        Insets.lg,
        Insets.sm,
        Insets.lg,
        Insets.lg,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: kPickerThemes.length + 1 + saved.length,
      itemBuilder: (context, i) {
        if (i < kPickerThemes.length) {
          return _buildPremadeTile(kPickerThemes[i], activeMode, i);
        }
        if (i == kPickerThemes.length) return _buildMakeTile();
        final t = saved[i - kPickerThemes.length - 1];
        return _buildSavedTile(t);
      },
    );
  }

  /// The '+ MAKE' tile — opens the palette maker.
  Widget _buildMakeTile() {
    final f = AppTheme.flair;
    return GestureDetector(
      onTap: () {
        Haptics.selection();
        Navigator.push(context, fastRoute(const PaletteMakerScreen()));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: f.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 28, color: f.primary),
            const SizedBox(height: 6),
            GoopText(
              'MAKE',
              style: TextStyle(
                fontSize: FontSizes.labelSmall,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: f.primary,
              ),
            ),
            const SizedBox(height: 2),
            GoopText(
              'your palette',
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Saved user palette — tap applies it via the custom theme path.
  Widget _buildSavedTile(SavedCustomTheme t) {
    final d = t.customData ?? CustomThemeData.defaultTheme;
    return GestureDetector(
      onTap: () {
        Haptics.selection();
        AppTheme.saveCustomThemeData(d);
        widget.onPreview(AppThemeMode.custom);
      },
      child: Container(
        decoration: BoxDecoration(
          color: d.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: d.primary.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Same band language as premade tiles.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                height: 5,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: d.primary,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: Container(color: d.secondary)),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: d.headlineStat,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: GoopText(
                t.name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: d.primary,
                ),
              ),
            ),
            const SizedBox(height: 2),
            GoopText(
              'SAVED',
              style: TextStyle(
                fontSize: 8,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremadeTile(AppThemeMode m, AppThemeMode activeMode, int index) {
    final f = AppTheme.flairFor(m);
    final isPreview = m == widget.previewMode;
    final isActive = m == activeMode;

    return GestureDetector(
      onTap: () {
        widget.onPreview(m);
        Haptics.selection();
      },
      onLongPress: () {
        widget.onQuickApply(m);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: f.scaffold.withValues(alpha: 0.85),
          borderRadius: BorderRadius.all(Radii.md),
          border: Border.all(
            color:
                isActive
                    ? Colors.green
                    : (isPreview
                        ? f.primary
                        : Colors.white.withValues(alpha: 0.08)),
            width: isActive ? 2.0 : (isPreview ? 2.0 : 1.0),
          ),
          boxShadow:
              isPreview
                  ? [
                    BoxShadow(
                      color: f.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ]
                  : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (m.splashSlug.isNotEmpty)
              Image.asset(
                'assets/images/themes/splash/${m.splashSlug}.jpg',
                fit: BoxFit.cover,
                opacity: AlwaysStoppedAnimation(isPreview ? 1.0 : 0.88),
                cacheWidth: 160,
                cacheHeight: 200,
                errorBuilder:
                    (_, __, ___) => DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.2,
                          colors: [
                            f.primary.withValues(alpha: 0.15),
                            f.scaffold,
                          ],
                        ),
                      ),
                    ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
            ),
            // Palette signature band — instant read of the palette's
            // three prime colors across the tile top.
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: f.primary,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: Container(color: f.secondary)),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: f.headlineStat,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 4,
              bottom: 4,
              right: 4,
              child: GoopText(
                m.label.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: FontSizes.labelSmall,
                  fontWeight: FontWeight.w900,
                  color: isPreview ? f.headlineStat : Colors.white,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
            if (isActive)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 10,
                    color: Colors.black,
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms, delay: (index * 30).ms);
  }
}

/// A single color field row for the custom palette editor.
/// Shows a label + description + color swatch; tapping opens the color picker.
/// Long-press the info icon for a detailed tooltip of what this color affects.

// =============================================================================
// TAB 2 — PARTICLES (preset + schema + speed + studio)
// =============================================================================

class _ParticlesStep extends StatelessWidget {
  const _ParticlesStep();

  /// Uniform 4-across tile grid for the shape types — equal cells,
  /// glyph + label, short row padded so widths stay consistent.
  Widget _typeGrid(VisualPrefs prefs) {
    const cols = 4;
    final types = ParticleType.values;
    return Column(
      children: [
        for (var r = 0; r * cols < types.length; r++)
          Padding(
            padding: EdgeInsets.only(
              bottom: (r + 1) * cols < types.length ? 8 : 0,
            ),
            child: Row(
              children: [
                for (var c = 0; c < cols; c++) ...[
                  Expanded(
                    child:
                        r * cols + c < types.length
                            ? _ParticleTypeTile(
                              type: types[r * cols + c],
                              active: r * cols + c == prefs.particleTypeIndex,
                              onTap: () {
                                VisualPrefs.setParticleTypeIndex(r * cols + c);
                                Haptics.selection();
                              },
                            )
                            : const SizedBox(),
                  ),
                  if (c < cols - 1) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VisualPrefs>(
      valueListenable: VisualPrefs.notifier,
      builder: (context, prefs, _) {
        return CustomScrollView(
          slivers: [
            // Sticky header: enable toggle + live preview
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyParticleHeader(prefs: prefs),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                Insets.lg,
                Insets.sm,
                Insets.lg,
                Insets.lg,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Typed particle system — 7 shapes × per-theme
                  // schemas × 3 physics flags. Clean, minimal, all
                  // user-facing (replaces the 37-preset × 16-schema
                  // layer entirely).
                  _StepLabel('COUNT'),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: prefs.particleCount.toDouble(),
                          min: 0,
                          max: 200,
                          divisions: 100,
                          label: '${prefs.particleCount}',
                          onChanged:
                              (v) => VisualPrefs.setParticleCount(v.round()),
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: GoopText(
                          '${prefs.particleCount}',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: FontSizes.labelMedium,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _StepLabel('TYPE'),
                  const SizedBox(height: 8),
                  _typeGrid(prefs),
                  const SizedBox(height: 16),
                  _StepLabel('PHYSICS'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _PhysicsToggle(
                          label: 'BOUNCE',
                          on: prefs.particleBounce,
                          onTap: () {
                            VisualPrefs.setParticleBounce(
                              !prefs.particleBounce,
                            );
                            Haptics.selection();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PhysicsToggle(
                          label: 'CHAOS',
                          on: prefs.particleChaos,
                          onTap: () {
                            VisualPrefs.setParticleChaos(!prefs.particleChaos);
                            Haptics.selection();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PhysicsToggle(
                          label: 'TILT',
                          on: prefs.particleTouch,
                          onTap: () {
                            VisualPrefs.setParticleTouch(!prefs.particleTouch);
                            Haptics.selection();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _StepLabel('COLOR'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (
                        var i = 0;
                        i <
                            (kThemeParticleSchemas[AppTheme.notifier.value] ??
                                    kThemeParticleSchemas[AppThemeMode
                                        .moonlitChamber]!)
                                .length;
                        i++
                      ) ...[
                        Expanded(
                          child: _SchemaChip(
                            schema:
                                (kThemeParticleSchemas[AppTheme
                                        .notifier
                                        .value] ??
                                    kThemeParticleSchemas[AppThemeMode
                                        .moonlitChamber]!)[i],
                            active: i == prefs.particleSchemaIndex,
                            onTap: () {
                              VisualPrefs.setParticleSchemaIndex(i);
                              Haptics.selection();
                            },
                          ),
                        ),
                        if (i < 2) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Swipable 2-column x 4-row paged grid. Each page shows 8 items.
/// Swipe horizontally to see more pages. Saves vertical space.
/// A grid item for the swipable grid.
class _GridItem {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Widget child;
  const _GridItem({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.child,
  });
}

class _ThemeStep extends StatefulWidget {
  final AppThemeMode previewMode;
  final ValueChanged<AppThemeMode> onPreview;
  final ValueChanged<AppThemeMode> onQuickApply;

  const _ThemeStep({
    required this.previewMode,
    required this.onPreview,
    required this.onQuickApply,
  });

  @override
  State<_ThemeStep> createState() => _ThemeStepState();
}

class _SwipableGrid2x4 extends StatefulWidget {
  final List<_GridItem> items;
  const _SwipableGrid2x4({required this.items});

  @override
  State<_SwipableGrid2x4> createState() => _SwipableGrid2x4State();
}

class _SwipableGrid2x4State extends State<_SwipableGrid2x4> {
  int _page = 0;
  static const _perPage = 8; // 2 cols x 4 rows
  static const _rowHeight = 44.0;
  static const _spacing = 6.0;

  @override
  Widget build(BuildContext context) {
    final pageCount = (widget.items.length / _perPage).ceil();
    final flair = AppTheme.flair;
    return Column(
      children: [
        SizedBox(
          height: _rowHeight * 4 + _spacing * 3, // 4 rows + 3 gaps
          child: PageView.builder(
            itemCount: pageCount,
            onPageChanged: (i) {
              setState(() => _page = i);
              Haptics.selection();
            },
            itemBuilder: (context, page) {
              final start = page * _perPage;
              final end = (start + _perPage).clamp(0, widget.items.length);
              final pageItems = widget.items.sublist(start, end);
              // Build 4 rows of 2 items each — reliable fixed sizing
              final rows = <Widget>[];
              for (int r = 0; r < 4; r++) {
                final idx0 = r * 2;
                final idx1 = r * 2 + 1;
                if (idx0 >= pageItems.length) break;
                rows.add(
                  Row(
                    children: [
                      Expanded(child: _buildTile(pageItems[idx0], flair)),
                      const SizedBox(width: _spacing),
                      if (idx1 < pageItems.length)
                        Expanded(child: _buildTile(pageItems[idx1], flair))
                      else
                        const Expanded(child: SizedBox()),
                    ],
                  ),
                );
                if (r < 3 && idx1 < pageItems.length) {
                  rows.add(const SizedBox(height: _spacing));
                }
              }
              return Column(children: rows);
            },
          ),
        ),
        if (pageCount > 1)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pageCount, (i) {
                final isActive = i == _page;
                return Container(
                  width: isActive ? 7 : 5,
                  height: isActive ? 7 : 5,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color:
                        isActive
                            ? flair.primary
                            : Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildTile(_GridItem item, ThemeFlair flair) {
    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: _rowHeight,
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.sm,
          vertical: Insets.xs,
        ),
        decoration: BoxDecoration(
          color:
              item.isActive
                  ? flair.primary.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.all(Radii.sm),
          border: Border.all(
            color:
                item.isActive
                    ? flair.primary.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.08),
            width: item.isActive ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            item.child,
            const SizedBox(width: 6),
            Expanded(
              child: GoopText(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: FontSizes.labelSmall,
                  fontWeight: item.isActive ? FontWeight.w900 : FontWeight.w700,
                  color:
                      item.isActive
                          ? flair.primary
                          : Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact visual for a color schema.

/// Sticky pinned header for the particles tab — holds the enable
/// toggle and the live particle preview so they're always visible.
class _StickyParticleHeader extends SliverPersistentHeaderDelegate {
  final VisualPrefs prefs;
  _StickyParticleHeader({required this.prefs});

  @override
  double get minExtent => 160;
  @override
  double get maxExtent => 160;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.flair.scaffold.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Insets.lg,
          Insets.xs,
          Insets.lg,
          Insets.sm,
        ),
        child: Column(
          children: [
            _ToggleRow(
              icon: Icons.auto_awesome_outlined,
              label: 'Enable Particles',
              value: prefs.particlesEnabled,
              onChanged: (v) {
                VisualPrefs.setParticles(v);
                Haptics.selection();
              },
            ),
            const SizedBox(height: 8),
            // Always show preview (even if disabled, to show what they'd get)
            Expanded(child: _ParticlePreview(prefs: prefs)),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyParticleHeader old) => prefs != old.prefs;
}

/// Live preview box that renders the current particle preset at its
/// actual settings so users can see exactly what they're choosing.
class _ParticlePreview extends StatelessWidget {
  final VisualPrefs prefs;
  const _ParticlePreview({required this.prefs});

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    return ClipRRect(
      borderRadius: BorderRadius.all(Radii.md),
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          color: flair.scaffold.withValues(alpha: 0.6),
          border: Border.all(
            color: flair.primary.withValues(alpha: 0.2),
            width: 1.0,
          ),
          borderRadius: BorderRadius.all(Radii.md),
        ),
        child: Stack(
          children: [
            // Subtle gradient backdrop so particles are visible.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      flair.scaffold.withValues(alpha: 0.3),
                      flair.card.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
            ),
            // The live particle field.
            Positioned.fill(
              child: ParticleField(
                preset: prefs.particlePreset,
                count: prefs.particleCount,
                sizeScale: prefs.particleSizeScale,
                opacity: prefs.particleOpacity,
                glowOverride: prefs.particleGlowEffect,
                lineLinksOverride: prefs.particleLineLinks,
                bounce: prefs.particleBounce,
                speedMultiplier: prefs.particleSpeed.multiplier,
              ),
            ),
            // Label overlay.
            Positioned(
              left: 12,
              bottom: 8,
              child: GoopText(
                'LIVE PREVIEW',
                style: TextStyle(
                  fontSize: FontSizes.labelSmall,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.3),
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Live mini particle preview. Renders a tiny [ParticleField] with a low
/// particle count when motion is enabled; falls back to the static
/// [_PresetVisual] swatch strip when reduced motion is active.

/// Compact visual representation of a preset — shows the preset's
/// colors as a horizontal swatch strip + a tiny shape icon.

// =============================================================================
// TAB 3 — TYPOGRAPHY (font family tabbed by category + sizes + weight)
// =============================================================================

class _TypographyStep extends StatelessWidget {
  const _TypographyStep();

  /// The curated six — one flat 2-col grid, no sub-categories.
  static const _fonts = [
    AppFont.gungeon,
    AppFont.megrim,
    AppFont.russoOne,
    AppFont.fredoka,
    AppFont.dmSans,
    AppFont.jetBrainsMono,
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VisualPrefs>(
      valueListenable: VisualPrefs.notifier,
      builder: (context, prefs, _) {
        return CustomScrollView(
          slivers: [
            // Sticky font preview header
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyFontHeader(prefs: prefs),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                Insets.lg,
                Insets.sm,
                Insets.lg,
                Insets.lg,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _StepLabel('FONT FAMILY'),
                  const SizedBox(height: 8),
                  // 2-col uniform tiles — font name rendered in its font.
                  for (var r = 0; r * 2 < _fonts.length; r++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: (r + 1) * 2 < _fonts.length ? 8 : 0,
                      ),
                      child: Row(
                        children: [
                          for (var c = 0; c < 2; c++) ...[
                            Expanded(
                              child:
                                  r * 2 + c < _fonts.length
                                      ? _FontTile(
                                        font: _fonts[r * 2 + c],
                                        selected:
                                            _fonts[r * 2 + c] == prefs.font,
                                      )
                                      : const SizedBox(),
                            ),
                            if (c < 1) const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),
                  _StepLabel('BASE FONT SIZE'),
                  const SizedBox(height: 10),
                  _FontSizeSlider(
                    current: prefs.fontSize,
                    onChanged: (v) => VisualPrefs.setFontSize(v),
                  ),
                  const SizedBox(height: 18),
                  _StepLabel('WEIGHT BIAS'),
                  const SizedBox(height: 10),
                  _WeightRow(current: prefs.fontWeightBias),
                  const SizedBox(height: 14),
                  _StepLabel('LETTER SPACING'),
                  const SizedBox(height: 10),
                  _LetterRow(current: prefs.fontLetterSpacing),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Sticky pinned header for the typography tab — shows a live font
/// preview sample so users can see how their font choice looks.
class _StickyFontHeader extends SliverPersistentHeaderDelegate {
  final VisualPrefs prefs;
  _StickyFontHeader({required this.prefs});

  @override
  double get minExtent => 90;
  @override
  double get maxExtent => 90;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final flair = AppTheme.flair;
    final font = prefs.font;
    final isBold = prefs.fontWeightBias > 0;
    // Build the font style — use a consistent base size; FittedBox
    // normalizes visual size across fonts with different metrics.
    TextStyle baseStyle;
    if (font == AppFont.gungeon) {
      baseStyle = TextStyle(
        fontFamily: 'EnterTheGungeonBig',
        fontSize: FontSizes.headlineSmall,
        fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
        color: flair.headlineStat,
        letterSpacing: 1.5,
      );
    } else {
      baseStyle = GoogleFonts.getFont(font.label).copyWith(
        fontSize: FontSizes.headlineSmall,
        fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
        color: flair.headlineStat,
        letterSpacing: 1.5,
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: flair.scaffold.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Insets.lg,
          Insets.xs,
          Insets.lg,
          Insets.xs,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Font name label (always Montserrat — system chrome)
            GoopText(
              '${font.label.toUpperCase()} · ${(prefs.fontSize * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: FontSizes.labelSmall,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.3),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            // Primary preview — FittedBox in fixed height = uniform visual size
            SizedBox(
              height: 28,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: GoopText('The Gungeon Awaits', style: baseStyle),
              ),
            ),
            const SizedBox(height: 2),
            // Secondary preview — also FittedBox in fixed height
            SizedBox(
              height: 14,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: GoopText(
                  'DPS 42 · Quality S · Master Round',
                  style: baseStyle.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyFontHeader old) => prefs != old.prefs;
}

/// Uniform font tile — the font's name rendered in its own face,
/// fixed height so all tiles read identically.
class _FontTile extends StatelessWidget {
  final AppFont font;
  final bool selected;
  const _FontTile({required this.font, required this.selected});

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    return GestureDetector(
      onTap: () {
        VisualPrefs.setFont(font);
        Haptics.selection();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        decoration: BoxDecoration(
          color:
              selected
                  ? flair.primary.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                selected
                    ? flair.primary.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.08),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GoopText(
                font.label,
                style: font.textStyle.copyWith(
                  fontSize: FontSizes.titleMedium,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : Colors.white54,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FontSizeSlider extends StatelessWidget {
  final double current;
  final ValueChanged<double> onChanged;
  const _FontSizeSlider({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final steps = VisualPrefs.fontSizeSteps;
    final activeStep = steps.indexOf(current);
    final stepLabel = current == 0 ? 'Auto' : '${current.toStringAsFixed(0)}pt';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live preview text in the actual size
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Insets.md),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: flair.card.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: flair.primary.withValues(alpha: 0.12)),
          ),
          child: GoopText(
            'The quick brown fox jumps over the lazy dog. 1234567890',
            style: TextStyle(
              fontSize: current.clamp(6.0, 32.0),
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.3,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GoopText(
              'Size',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white60,
              ),
            ),
            GoopText(
              stepLabel,
              style: TextStyle(
                fontSize: FontSizes.labelMedium,
                fontWeight: FontWeight.w900,
                color: flair.headlineStat,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
            activeTrackColor: flair.primary,
            inactiveTrackColor: Colors.white12,
            thumbColor: Colors.white,
          ),
          child: Slider(
            value: activeStep >= 0 ? activeStep.toDouble() : 3.0,
            min: 0,
            max: (steps.length - 1).toDouble(),
            divisions: steps.length - 1,
            label: stepLabel,
            onChanged: (v) => onChanged(steps[v.toInt()]),
          ),
        ),
        // Step dots
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(steps.length, (i) {
            final on = i == (activeStep >= 0 ? activeStep : 3);
            return GoopText(
              steps[i].toStringAsFixed(0),
              style: TextStyle(
                fontSize: 7,
                fontWeight: on ? FontWeight.w900 : FontWeight.w400,
                color: on ? flair.primary : Colors.white.withValues(alpha: 0.3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _WeightRow extends StatelessWidget {
  final int current;
  const _WeightRow({required this.current});

  @override
  Widget build(BuildContext context) {
    final options = [-2, 0, 2];
    final labels = ['200\nTHIN', '400\nNORMAL', '800\nBOLD'];
    final flair = AppTheme.flair;
    return Row(
      children: List.generate(options.length, (i) {
        final isActive = options[i] == current;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              VisualPrefs.setFontWeightBias(options[i]);
              Haptics.selection();
            },
            child: Container(
              margin: const EdgeInsets.only(right: Insets.sm),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color:
                    isActive
                        ? flair.primary.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.all(Radii.sm),
                border: Border.all(
                  color:
                      isActive
                          ? flair.primary.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Center(
                child: GoopText(
                  labels[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    color:
                        isActive
                            ? flair.primary
                            : Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// =============================================================================
// TAB 4 — AMBIANCE (glow + dialogue haptics + text speed)
// =============================================================================

class _AmbianceStep extends StatelessWidget {
  const _AmbianceStep();

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    return ValueListenableBuilder<VisualPrefs>(
      valueListenable: VisualPrefs.notifier,
      builder: (context, prefs, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Insets.lg,
            Insets.sm,
            Insets.lg,
            Insets.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepLabel('SCREEN GLOW'),
              const SizedBox(height: 8),
              _StudioSlider(
                'Glow Intensity',
                '${(prefs.glowIntensity * 100).toStringAsFixed(0)}%',
                prefs.glowIntensity,
                0.0,
                1.0,
                20,
                flair.headlineStat,
                (v) => VisualPrefs.setGlow(v),
              ),
              const SizedBox(height: 14),
              _StepLabel('GLOW COLOR'),
              const SizedBox(height: 8),
              _GlowColorPaged(currentIndex: prefs.glowColorIndex),
            ],
          ),
        );
      },
    );
  }
}

/// 5x2 paged swipable glow color grid. Each page shows 10 colors
/// (5 columns x 2 rows). Swipe horizontally to see more pages.
class _GlowColorPaged extends StatelessWidget {
  const _GlowColorPaged({required this.currentIndex});
  final int currentIndex;
  static const _spacing = 6.0;

  @override
  Widget build(BuildContext context) {
    final colors = VisualPrefs.glowColors;
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: _spacing,
      crossAxisSpacing: _spacing,
      children: List.generate(colors.length, (i) {
        final c = colors[i];
        final isSelected = i == currentIndex;
        return GestureDetector(
          onTap: () {
            VisualPrefs.setGlowColorIndex(i);
            Haptics.selection();
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.all(Radii.sm),
              border: Border.all(
                color:
                    isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.12),
                width: isSelected ? 2.5 : 0.8,
              ),
              boxShadow:
                  isSelected
                      ? [
                        BoxShadow(
                          color: c.withValues(alpha: 0.6),
                          blurRadius: 10,
                        ),
                      ]
                      : null,
            ),
          ),
        );
      }),
    );
  }
}

class _StepLabel extends StatelessWidget {
  final String text;
  const _StepLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return GoopText(
      text,
      style: TextStyle(
        fontSize: FontSizes.bodyMedium,
        fontWeight: FontWeight.w900,
        color: AppTheme.flair.primary.withValues(alpha: 0.85),
        letterSpacing: 1.5,
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: Insets.sm),
      decoration: BoxDecoration(
        color: flair.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.all(Radii.sm),
        border: Border.all(color: flair.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white54),
          const SizedBox(width: 10),
          Expanded(
            child: GoopText(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),
          ),
          Switch(
            value: value,
            activeColor: flair.primary,
            activeTrackColor: flair.primary.withValues(alpha: 0.25),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _StudioSlider extends StatelessWidget {
  final String label, displayValue;
  final double value, min, max;
  final int divisions;
  final Color color;
  final ValueChanged<double> onChanged;
  const _StudioSlider(
    this.label,
    this.displayValue,
    this.value,
    this.min,
    this.max,
    this.divisions,
    this.color,
    this.onChanged,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GoopText(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              GoopText(
                displayValue,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 28,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3.0,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 6.0,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 12.0,
                ),
                activeTrackColor: color,
                inactiveTrackColor: Colors.white12,
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Type tile — fixed-size cell with a painted shape glyph + label,
/// used by the uniform TYPE grid.
class _ParticleTypeTile extends StatelessWidget {
  final ParticleType type;
  final bool active;
  final VoidCallback onTap;
  const _ParticleTypeTile({
    required this.type,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final c = active ? flair.primary : Colors.white.withValues(alpha: 0.5);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 56,
        decoration: BoxDecoration(
          color:
              active
                  ? flair.primary.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                active ? flair.primary : Colors.white.withValues(alpha: 0.12),
            width: active ? 1.6 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TypeGlyph(type: type, color: c),
            const SizedBox(height: 5),
            GoopText(
              type.label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                letterSpacing: 0.6,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tiny painted glyph for each particle shape — honest preview of the
/// actual particle look instead of a borrowed icon.
class _TypeGlyph extends StatelessWidget {
  final ParticleType type;
  final Color color;
  const _TypeGlyph({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _TypeGlyphPainter(type, color)),
    );
  }
}

class _TypeGlyphPainter extends CustomPainter {
  final ParticleType type;
  final Color color;
  const _TypeGlyphPainter(this.type, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final c = Offset(size.width / 2, size.height / 2);
    switch (type) {
      case ParticleType.dot:
        canvas.drawCircle(c, 4, p);
      case ParticleType.square:
        canvas.drawRect(Rect.fromCenter(center: c, width: 9, height: 9), p);
      case ParticleType.glowOrb:
        p.shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: c, radius: 8));
        canvas.drawCircle(c, 8, p);
      case ParticleType.shell:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: c, width: 6, height: 12),
            const Radius.circular(3),
          ),
          p,
        );
      case ParticleType.rainbowDot:
        p.shader = const SweepGradient(
          colors: [
            Colors.red,
            Colors.orange,
            Colors.yellow,
            Colors.green,
            Colors.blue,
            Colors.purple,
            Colors.red,
          ],
        ).createShader(Rect.fromCircle(center: c, radius: 6));
        canvas.drawCircle(c, 6, p);
      case ParticleType.voidPixel:
        p.style = PaintingStyle.stroke;
        p.strokeWidth = 2;
        canvas.drawRect(Rect.fromCenter(center: c, width: 9, height: 9), p);
      case ParticleType.glitchPixel:
        canvas.drawRect(
          Rect.fromLTWH(2, 2, 7, 7),
          p..color = color.withValues(alpha: 0.6),
        );
        canvas.drawRect(Rect.fromLTWH(9, 9, 7, 7), p..color = color);
    }
  }

  @override
  bool shouldRepaint(_TypeGlyphPainter old) =>
      old.type != type || old.color != color;
}

/// Physics toggle pill — on/off chip for bounce/chaos/tilt.
class _PhysicsToggle extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _PhysicsToggle({
    required this.label,
    required this.on,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              on
                  ? flair.primary.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: on ? flair.primary : Colors.white.withValues(alpha: 0.15),
            width: on ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              on ? Icons.check_circle : Icons.circle_outlined,
              size: 13,
              color: on ? flair.primary : Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 6),
            GoopText(
              label,
              style: TextStyle(
                fontSize: FontSizes.labelMedium,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: on ? flair.primary : Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Schema chip — colored dots + name for the per-theme color pick.
class _SchemaChip extends StatelessWidget {
  final ({String name, List<Color> colors}) schema;
  final bool active;
  final VoidCallback onTap;
  const _SchemaChip({
    required this.schema,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color:
              active
                  ? flair.primary.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                active ? flair.primary : Colors.white.withValues(alpha: 0.15),
            width: active ? 1.6 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < schema.colors.length && i < 4; i++)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: schema.colors[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            GoopText(
              schema.name,
              style: TextStyle(
                fontSize: FontSizes.labelSmall,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color:
                    active
                        ? flair.primary
                        : Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 5-step letter spacing pills — -2..2 × 0.5pt (tight → wide).
class _LetterRow extends StatelessWidget {
  final int current;
  const _LetterRow({required this.current});

  @override
  Widget build(BuildContext context) {
    final options = [-2, -1, 0, 1, 2];
    final labels = ['TIGHT', '-0.5', '0', '+0.5', 'WIDE'];
    final flair = AppTheme.flair;
    return Row(
      children: List.generate(options.length, (i) {
        final isActive = options[i] == current;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              VisualPrefs.setFontLetterSpacing(options[i]);
              Haptics.selection();
            },
            child: Container(
              margin: const EdgeInsets.only(right: Insets.sm),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color:
                    isActive
                        ? flair.primary.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.all(Radii.sm),
                border: Border.all(
                  color:
                      isActive
                          ? flair.primary.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Center(
                child: GoopText(
                  labels[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    color:
                        isActive
                            ? flair.primary
                            : Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
