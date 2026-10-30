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
part 'experience_studio/studio_palette.dart';
part 'experience_studio/studio_particles.dart';
part 'experience_studio/studio_typography.dart';
part 'experience_studio/studio_ambiance.dart';
part 'experience_studio/studio_widgets.dart';

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

/// A single color field row for the custom palette editor.
/// Shows a label + description + color swatch; tapping opens the color picker.
/// Long-press the info icon for a detailed tooltip of what this color affects.

// =============================================================================
// TAB 2 — PARTICLES (preset + schema + speed + studio)
// =============================================================================

/// Compact visual for a color schema.

/// Live mini particle preview. Renders a tiny [ParticleField] with a low
/// particle count when motion is enabled; falls back to the static
/// [_PresetVisual] swatch strip when reduced motion is active.

/// Compact visual representation of a preset — shows the preset's
/// colors as a horizontal swatch strip + a tiny shape icon.

// =============================================================================
// TAB 3 — TYPOGRAPHY (font family tabbed by category + sizes + weight)
// =============================================================================

// =============================================================================
// TAB 4 — AMBIANCE (glow + dialogue haptics + text speed)
// =============================================================================
