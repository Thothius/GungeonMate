import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/tokens.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_theme.dart';
import '../services/goop_talk_engine.dart';
import '../services/haptics.dart';
import '../widgets/scale_button.dart';
import '../widgets/particle_engine.dart';
import 'palette_maker_screen.dart';
import '../widgets/theme_overlay.dart';
import '../widgets/particles/ambient_glow.dart';
import '../utils/fast_route.dart';
part 'experience_studio/studio_palette.dart';
part 'experience_studio/studio_particles.dart';
part 'experience_studio/studio_typography.dart';
part 'experience_studio/studio_ambiance.dart';
part 'experience_studio/studio_widgets.dart';

/// Customization — the unified theme hub. One layout for every entry
/// point: sticky BACK · PREVIEW · APPLY action bar, a 5-tab strip
/// (PRESETS / CUSTOM / FONTS / PARTICLES / AMBIANCE), a draggable LIVE
/// LOOK pane rendering a mini-UI with the staged picks, and scrollable
/// options below. Picks stage live through the whole screen; APPLY
/// commits, BACK restores the entry snapshot.
///
/// [initialTab] selects the opening tab (0=PRESETS … 4=AMBIANCE).
class ExperienceStudioScreen extends StatefulWidget {
  final int initialTab;
  const ExperienceStudioScreen({super.key, this.initialTab = 0});

  @override
  State<ExperienceStudioScreen> createState() => _ExperienceStudioScreenState();
}

class _ExperienceStudioScreenState extends State<ExperienceStudioScreen> {
  late AppThemeMode _previewMode;
  late final AppThemeMode _originalMode;
  late final VisualPrefs _originalPrefs;
  late CustomThemeData _draft;
  int _hubTab = 0;
  double _liveLookH = 0.22;

  @override
  void initState() {
    super.initState();
    _hubTab = widget.initialTab.clamp(0, 4);
    _previewMode = AppTheme.mode;
    _originalMode = AppTheme.mode;
    _originalPrefs = VisualPrefs.notifier.value;
    _draft = CustomThemeData.defaultTheme;
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
        body: SafeArea(
          child: Stack(
            children: [
              // ── Theme background — skins with the PREVIEW theme, not the
              // actual app theme, so the whole screen updates on tap ──
              _buildPreviewBackground(),
              _buildHub(),
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

  // ── Theme staging ──────────────────────────────────────────
  // Taps set the preview mode + curated prefs; APPLY commits.

  /// Tap-to-preview: session skin + notifier + curated preset
  /// application — same path the studio grid uses.
  void _previewTheme(AppThemeMode m) {
    Haptics.selection();
    setState(() => _previewMode = m);
    AppTheme.previewNotifier.value = m;
    final curation = kThemeCuration[m];
    if (curation != null) VisualPrefs.applyCuration(curation);
    // Presets default to the Gungeon font — the typeface is part of
    // the preset identity (user can still override in FONTS).
    if (m != AppThemeMode.custom) VisualPrefs.setFont(AppFont.gungeon);
  }

  // ── Unified Customization hub ──────────────────────────────
  // One layout for every entry point: sticky BACK · PREVIEW · APPLY
  // bar, 5-tab strip, draggable LIVE LOOK pane, scrollable options.
  static const _hubTabs = [
    'PRESETS',
    'CUSTOM',
    'FONTS',
    'PARTICLES',
    'AMBIANCE',
  ];

  Widget _buildHub() {
    return Column(
      children: [
        _buildActionBar(),
        _buildTabStrip(),
        // Particles tab gets its own live preview (bigger, on top) —
        // the shared LIVE LOOK pane hides there so the field is the star.
        if (_hubTab != 3) _buildLiveLook(),
        Expanded(child: _buildHubContent()),
      ],
    );
  }

  /// Sticky action bar — BACK discards staged picks (restores the
  /// entry snapshot), PREVIEW opens the fullscreen look, APPLY commits.
  Widget _buildActionBar() {
    final flair = AppTheme.flairFor(_previewMode);
    final fg =
        flair.primary.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Insets.lg,
        Insets.sm,
        Insets.lg,
        Insets.xs,
      ),
      child: Row(
        children: [
          _ghostBarButton('BACK', Icons.arrow_back_ios_new_rounded, _onBack),

          const SizedBox(width: 10),
          Expanded(
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

  Widget _ghostBarButton(String label, IconData icon, VoidCallback onTap) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.all(Radii.md),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            GoopText(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: Colors.white70,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabStrip() {
    final flair = AppTheme.flairFor(_previewMode);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Insets.lg,
        Insets.xs,
        Insets.lg,
        Insets.sm,
      ),
      child: Row(
        children: List.generate(_hubTabs.length, (i) {
          final active = _hubTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _hubTab = i);
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
                    _hubTabs[i],
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
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

  /// LIVE LOOK — draggable pane (~1/3 → 75% of screen) rendering a mini
  /// mock of real app UI elements with the staged picks. Updates live.
  Widget _buildLiveLook() {
    final sh = MediaQuery.sizeOf(context).height;
    final h = (sh * _liveLookH).clamp(96.0, sh * 0.75);
    return SizedBox(
      height: h,
      child: Container(
        margin: const EdgeInsets.fromLTRB(Insets.lg, 0, Insets.lg, Insets.xs),
        decoration: BoxDecoration(
          color: AppTheme.flairFor(_previewMode).card.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.flairFor(
              _previewMode,
            ).primary.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Stack(
            children: [
              // Real particles inside the pane — every particle option
              // visibly changes the LIVE LOOK (was: wrote prefs but
              // nothing rendered → "options don't do anything").
              Positioned.fill(
                child: IgnorePointer(
                  child: ValueListenableBuilder<VisualPrefs>(
                    valueListenable: VisualPrefs.notifier,
                    builder:
                        (_, prefs, _) =>
                            buildBackdropParticleField(
                              _previewMode,
                              prefs,
                              opacityScale: 0.7,
                            ) ??
                            const SizedBox.shrink(),
                  ),
                ),
              ),
              // Ambient glow layer — same resolution as the app overlay so
              // the AMBIANCE tab's style/color/intensity visibly changes.
              Positioned.fill(
                child: IgnorePointer(
                  child: ValueListenableBuilder<VisualPrefs>(
                    valueListenable: VisualPrefs.notifier,
                    builder: (_, prefs, _) {
                      final f = AppTheme.flairFor(_previewMode);
                      final eff = (prefs.glowIntensity * 1.8).clamp(0.0, 1.8);
                      if (eff <= 0.001) return const SizedBox.shrink();
                      Color scaled(Color c) =>
                          c.withValues(alpha: (c.a * eff).clamp(0.0, 1.0));
                      return AmbientGlow(
                        primary: scaled(
                          Color.lerp(f.glowPrimary, prefs.glowColor, 0.5) ??
                              f.glowPrimary,
                        ),
                        secondary: scaled(
                          Color.lerp(f.glowSecondary, prefs.glowColor, 0.5) ??
                              f.glowSecondary,
                        ),
                        tertiary: f.headlineStat.withValues(alpha: 0.3),
                        style: prefs.glowStyleOverride ?? f.glowStyle,
                      );
                    },
                  ),
                ),
              ),
              // Vignette + grain layers — AMBIANCE sliders preview here.
              Positioned.fill(
                child: IgnorePointer(
                  child: ValueListenableBuilder<VisualPrefs>(
                    valueListenable: VisualPrefs.notifier,
                    builder:
                        (_, prefs, _) => Stack(
                          children: [
                            if (prefs.vignetteIntensity > 0.01)
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      center: Alignment.center,
                                      radius: 1.25,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(
                                          alpha: 0.2 * prefs.vignetteIntensity,
                                        ),
                                        Colors.black.withValues(
                                          alpha: 0.45 * prefs.vignetteIntensity,
                                        ),
                                      ],
                                      stops: const [0.0, 0.6, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            if (prefs.grainIntensity > 0.005)
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: GrainPainter(
                                    opacity: prefs.grainIntensity * 0.35,
                                  ),
                                ),
                              ),
                          ],
                        ),
                  ),
                ),
              ),
              Column(
                children: [
                  Expanded(child: _buildLiveLookMock()),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate:
                        (d) => setState(
                          () =>
                              // Drag DOWN = pane grows (pull-down to
                              // reveal) — sign was inverted before.
                              _liveLookH = (_liveLookH + d.delta.dy / sh).clamp(
                                0.15,
                                0.75,
                              ),
                        ),
                    child: const SizedBox(
                      width: double.infinity,
                      height: 22,
                      child: Center(child: _PullHandle()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The mini-UI mock — a panel card with title, body text, stat
  /// highlight and a button, so every color role is visible at a glance.
  /// Rebuilds on VisualPrefs so font/particle/glow picks show instantly.
  Widget _buildLiveLookMock() {
    return ValueListenableBuilder<VisualPrefs>(
      valueListenable: VisualPrefs.notifier,
      builder: (context, prefs, _) {
        final flair = AppTheme.flairFor(_previewMode);
        final glow = prefs.glowColor;
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          // Non-scrolling scroll view — the mock clips at small pane
          // heights instead of overflowing its bounds.
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GoopText(
                  'PREVIEW',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                    color: flair.primary.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(
                      child: GoopText(
                        _previewMode.label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: flair.primary,
                        ),
                      ),
                    ),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: glow,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: glow.withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                GoopText(
                  'The Gungeon awaits. Body text in your font.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: flair.secondary.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    GoopText(
                      '42',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: flair.headlineStat,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GoopText(
                      'STAT',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: flair.secondary.withValues(alpha: 0.6),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: flair.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: GoopText(
                        'BUTTON',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color:
                              flair.primary.computeLuminance() > 0.5
                                  ? Colors.black87
                                  : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Mini stat chips — a second layer of real UI so the
                // preview reads as an app, not a text card.
                Row(
                  children: [
                    for (final c in [
                      ('COOL', '★', flair.secondary),
                      ('CURSE', '☠', flair.primary),
                      ('DPS', '42', flair.headlineStat),
                    ])
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: c.$3.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Center(
                            child: GoopText(
                              '${c.$2} ${c.$1}',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: c.$3,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// PRESETS — picker themes + saved customs as compact palette panels.
  Widget _buildPaletteList() {
    final activeMode = AppTheme.mode;
    return ValueListenableBuilder<List<SavedCustomTheme>>(
      valueListenable: CustomThemeStore.notifier,
      builder: (context, saved, _) {
        return GridView.count(
          padding: const EdgeInsets.fromLTRB(
            Insets.lg,
            Insets.sm,
            Insets.lg,
            Insets.sm,
          ),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.3,
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
        );
      },
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

  Widget _buildHubContent() {
    switch (_hubTab) {
      case 0:
        return _buildPaletteList();
      case 1:
        return _buildCustomTab();
      case 2:
        return const _TypographyStep();
      case 3:
        return const _ParticlesStep();
      case 4:
        return const _AmbianceStep();
      default:
        return _buildPaletteList();
    }
  }

  /// BACK — discard staged picks by restoring the entry snapshot
  /// (premade-mode restores prefs too, since curation writes them).
  Future<void> _onBack() async {
    Haptics.selection();
    AppTheme.previewNotifier.value = null;
    await VisualPrefs.replaceAndPersist(_originalPrefs);
    await AppTheme.setMode(_originalMode);
    if (!mounted) return;
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  // ── CUSTOM tab — per-role color rows → color picker, Unicorn
  // variant switcher, glow swatch row, SAVE THEME ──────────────────

  Widget _buildCustomTab() {
    // (label, plain-English description, current color, updater) —
    // the desc makes the role obvious without dev knowledge.
    final roles = <(String, String, Color, CustomThemeData Function(Color))>[
      (
        'CANVAS',
        'app background',
        _draft.scaffold,
        (c) => _draft.copyWith(scaffold: c),
      ),
      (
        'PANEL',
        'cards & containers',
        _draft.card,
        (c) => _draft.copyWith(card: c),
      ),
      (
        'PRIME',
        'accents, borders & links',
        _draft.primary,
        (c) => _draft.copyWith(primary: c),
      ),
      (
        'SECOND',
        'secondary text & hints',
        _draft.secondary,
        (c) => _draft.copyWith(secondary: c),
      ),
      (
        'STAT',
        'numbers & metrics',
        _draft.headlineStat,
        (c) => _draft.copyWith(headlineStat: c),
      ),
      (
        'BULLETS',
        'bullet & special icons',
        _draft.bulletColor,
        (c) => _draft.copyWith(bulletColor: c),
      ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(Insets.lg, 0, Insets.lg, Insets.lg),
      children: [
        if (_previewMode == AppThemeMode.unicorn) _buildUnicornStrip(),
        for (final (label, desc, color, update) in roles)
          _colorRoleRow(label, desc, color, update),
        const SizedBox(height: 14),
        ScaleButton(
          onTap: _showSaveThemeDialog,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: _draft.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _draft.primary.withValues(alpha: 0.6),
                width: 1.4,
              ),
            ),
            child: Center(
              child: GoopText(
                'SAVE THEME',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  color: _draft.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// One color role: name + plain-English desc + hex + swatch — tap
  /// slides in the curated 6×10 swatch sheet (GENERAL / METALLIC).
  Widget _colorRoleRow(
    String label,
    String desc,
    Color color,
    CustomThemeData Function(Color) update,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () async {
          final c = await _PaletteColorSheet.show(context, color);
          if (c == null || !mounted) return;
          setState(() => _draft = update(c));
          await AppTheme.saveCustomThemeData(_draft);
          _previewTheme(AppThemeMode.custom);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GoopText(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: Colors.white70,
                      ),
                    ),
                    GoopText(
                      desc,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              GoopText(
                '#${color.toARGB32().toRadixString(16).toUpperCase()}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0x80FFFFFF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Unicorn megapack — the 6 sub-palettes as switchable chips.
  Widget _buildUnicornStrip() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final p in UnicornPalette.values)
            GestureDetector(
              onTap: () async {
                Haptics.selection();
                await AppTheme.setUnicornPalette(p);
                setState(() {});
              },
              child: ValueListenableBuilder<UnicornPalette>(
                valueListenable: AppTheme.unicornPaletteNotifier,
                builder:
                    (_, active, _) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            p == active
                                ? Colors.pinkAccent.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              p == active
                                  ? Colors.pinkAccent
                                  : Colors.white.withValues(alpha: 0.12),
                          width: p == active ? 1.5 : 1.0,
                        ),
                      ),
                      child: GoopText(
                        p.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color:
                              p == active
                                  ? Colors.pinkAccent
                                  : Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
              ),
            ),
        ],
      ),
    );
  }

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
                                          (_, _, _) => Container(
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

/// Sliding color-swatch sheet for the CUSTOM tab — replaces the system
/// color picker with a curated 6x10 grid (GENERAL + METALLIC tabs).
class _PaletteColorSheet extends StatefulWidget {
  const _PaletteColorSheet({required this.current});
  final Color current;

  static Future<Color?> show(BuildContext context, Color current) {
    return showModalBottomSheet<Color>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PaletteColorSheet(current: current),
    );
  }

  @override
  State<_PaletteColorSheet> createState() => _PaletteColorSheetState();
}

class _PaletteColorSheetState extends State<_PaletteColorSheet> {
  int _tab = 0;
  static const _tabs = ['GENERAL', 'METALLIC'];

  /// 6x10 curated — darks, then hue families red→purple.
  static const _general = [
    0xFF0D0D10,
    0xFF14141A,
    0xFF1A1A22,
    0xFF1E1E28,
    0xFF22222E,
    0xFF26262F,
    0xFF2A2A35,
    0xFF101018,
    0xFF0A0A0E,
    0xFF1C1C26,
    0xFF7F1D1D,
    0xFF991B1B,
    0xFFB91C1C,
    0xFFDC2626,
    0xFFEF4444,
    0xFFF87171,
    0xFF8B0000,
    0xFFDC143C,
    0xFFB22222,
    0xFFFF6B6B,
    0xFF7C2D12,
    0xFF9A3412,
    0xFFC2410C,
    0xFFEA580C,
    0xFFF97316,
    0xFFFB923C,
    0xFFB45309,
    0xFFD97706,
    0xFFF59E0B,
    0xFFFBBF24,
    0xFF14532D,
    0xFF166534,
    0xFF15803D,
    0xFF16A34A,
    0xFF22C55E,
    0xFF4ADE80,
    0xFF065F46,
    0xFF047857,
    0xFF10B981,
    0xFF34D399,
    0xFF0C4A6E,
    0xFF075985,
    0xFF0369A1,
    0xFF0284C7,
    0xFF0EA5E9,
    0xFF38BDF8,
    0xFF164E63,
    0xFF0E7490,
    0xFF0891B2,
    0xFF22D3EE,
    0xFF3B0764,
    0xFF581C87,
    0xFF6B21A8,
    0xFF7E22CE,
    0xFFA855F7,
    0xFF831843,
    0xFF9D174D,
    0xFFBE185D,
    0xFFEC4899,
    0xFFF472B6,
  ];

  /// 6x10 curated — gunmetal, silver, gold, copper, colored metals,
  /// forged darks.
  static const _metallic = [
    0xFF1F2937,
    0xFF374151,
    0xFF4B5563,
    0xFF6B7280,
    0xFF9CA3AF,
    0xFFD1D5DB,
    0xFF23272E,
    0xFF2E3440,
    0xFF3B4252,
    0xFF4C566A,
    0xFF5A5F66,
    0xFF787D84,
    0xFF969BA2,
    0xFFB4B9C0,
    0xFFD2D7DE,
    0xFFE8ECF0,
    0xFF43484D,
    0xFF64696E,
    0xFF8A8F94,
    0xFFB0B5BA,
    0xFF78350F,
    0xFF92400E,
    0xFFB45309,
    0xFFD97706,
    0xFFF59E0B,
    0xFFFCD34D,
    0xFF713F12,
    0xFF854D0E,
    0xFFA16207,
    0xFFCA8A04,
    0xFFCD7F32,
    0xFF8C3B1B,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _tab == 0 ? _general : _metallic;
    return Container(
      height: 360,
      decoration: BoxDecoration(
        color: const Color(0xFF16161C),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 6),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tab = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        margin: EdgeInsets.only(right: i == 0 ? 6 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              _tab == i
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                _tab == i
                                    ? Colors.white.withValues(alpha: 0.35)
                                    : Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Center(
                          child: GoopText(
                            _tabs[i],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color:
                                  _tab == i
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: GridView.count(
                crossAxisCount: 10,
                mainAxisSpacing: 9,
                crossAxisSpacing: 9,
                physics: const BouncingScrollPhysics(),
                children: [for (final c in colors) _swatch(Color(c))],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _swatch(Color c) {
    final selected = c.toARGB32() == widget.current.toARGB32();
    return GestureDetector(
      onTap: () {
        Haptics.selection();
        Navigator.of(context).pop(c);
      },
      child: Container(
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(
            color:
                selected ? Colors.white : Colors.white.withValues(alpha: 0.2),
            width: selected ? 2.2 : 0.8,
          ),
          boxShadow:
              selected
                  ? [BoxShadow(color: c.withValues(alpha: 0.7), blurRadius: 8)]
                  : null,
        ),
      ),
    );
  }
}

/// Drag handle for the LIVE LOOK pane — a gentle bob + chevron that
/// keeps hinting the pane is pullable (was: a static pill users
/// couldn't discover).
class _PullHandle extends StatefulWidget {
  const _PullHandle();

  @override
  State<_PullHandle> createState() => _PullHandleState();
}

class _PullHandleState extends State<_PullHandle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder:
          (_, _) => Transform.translate(
            offset: Offset(0, -2.5 * _c.value),
            child: Opacity(
              opacity: 0.55 + 0.35 * _c.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
