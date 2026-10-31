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
import '../widgets/color_picker_dialog.dart';
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
  double _liveLookH = 0.30;

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
        _buildLiveLook(),
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
          _ghostBarButton(
            'PREVIEW',
            Icons.visibility_rounded,
            _showPreviewModal,
          ),
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
        child: Column(
          children: [
            Expanded(child: _buildLiveLookMock()),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate:
                  (d) => setState(
                    () =>
                        _liveLookH = (_liveLookH - d.delta.dy / sh).clamp(
                          0.15,
                          0.75,
                        ),
                  ),
              child: SizedBox(
                width: double.infinity,
                height: 20,
                child: Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
        final glow =
            VisualPrefs.glowColors[prefs.glowColorIndex.clamp(
              0,
              VisualPrefs.glowColors.length - 1,
            )];
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
            ],
          ),
        );
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

  /// PREVIEW — fullscreen modal with the themed preview card.
  void _showPreviewModal() {
    Haptics.selection();
    showDialog<void>(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(Insets.lg),
            child: _buildPreviewPane(),
          ),
    );
  }

  // ── CUSTOM tab — per-role color rows → color picker, Unicorn
  // variant switcher, glow swatch row, SAVE THEME ──────────────────

  Widget _buildCustomTab() {
    final roles = <(String, Color, CustomThemeData Function(Color))>[
      ('CANVAS', _draft.scaffold, (c) => _draft.copyWith(scaffold: c)),
      ('PANEL', _draft.card, (c) => _draft.copyWith(card: c)),
      ('PRIME', _draft.primary, (c) => _draft.copyWith(primary: c)),
      ('SECOND', _draft.secondary, (c) => _draft.copyWith(secondary: c)),
      ('STAT', _draft.headlineStat, (c) => _draft.copyWith(headlineStat: c)),
      ('BULLETS', _draft.bulletColor, (c) => _draft.copyWith(bulletColor: c)),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(Insets.lg, 0, Insets.lg, Insets.lg),
      children: [
        if (_previewMode == AppThemeMode.unicorn) _buildUnicornStrip(),
        for (final (label, color, update) in roles)
          _colorRoleRow(label, color, update),
        _buildGlowStrip(),
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

  /// One color role: name + hex + swatch → tap opens the color picker.
  Widget _colorRoleRow(
    String label,
    Color color,
    CustomThemeData Function(Color) update,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () async {
          final c = await showColorPickerDialog(
            context,
            initialColor: color,
            title: label,
          );
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
                child: GoopText(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.white70,
                  ),
                ),
              ),
              GoopText(
                '#${color.toARGB32().toRadixString(16).toUpperCase()}',
                style: const TextStyle(fontSize: 10, color: Colors.white38),
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

  /// Glow color strip — the 12-color glow palette as swatch dots.
  Widget _buildGlowStrip() {
    return ValueListenableBuilder<VisualPrefs>(
      valueListenable: VisualPrefs.notifier,
      builder: (context, prefs, _) {
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < VisualPrefs.glowColors.length; i++)
                GestureDetector(
                  onTap: () async {
                    Haptics.selection();
                    await VisualPrefs.setGlowColorIndex(i);
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: VisualPrefs.glowColors[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            i == prefs.glowColorIndex
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.15),
                        width: i == prefs.glowColorIndex ? 2 : 1,
                      ),
                      boxShadow:
                          i == prefs.glowColorIndex
                              ? [
                                BoxShadow(
                                  color: VisualPrefs.glowColors[i].withValues(
                                    alpha: 0.7,
                                  ),
                                  blurRadius: 8,
                                ),
                              ]
                              : null,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// '+ MAKE YOUR PALETTE' — jumps to the CUSTOM tab (palette making
  /// lives there now — no separate screen).
  Widget _buildMakePanel() {
    final f = AppTheme.flairFor(_previewMode);
    return GestureDetector(
      onTap: () {
        Haptics.selection();
        setState(() => _hubTab = 1);
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
                child: Column(children: [_buildMakePanel()]),
              ),
            ),
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
