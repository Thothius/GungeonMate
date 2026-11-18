import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/tokens.dart';

import 'package:google_fonts/google_fonts.dart';

import '../services/app_theme.dart';
import '../services/goop_talk_engine.dart';
import '../services/haptics.dart';
import '../widgets/scale_button.dart';
import '../widgets/particle_engine.dart';
import '../widgets/theme_overlay.dart';
import '../widgets/backgrounds/custom_wallpaper.dart';
import '../widgets/backgrounds/ambient_shader.dart';
import '../widgets/particles/ambient_glow.dart';
import '../utils/asset_paths.dart';
import '../widgets/skeuo/skeuo_tokens.dart';
part 'experience_studio/studio_particles.dart';
part 'experience_studio/studio_typography.dart';
part 'experience_studio/studio_ambiance.dart';
part 'experience_studio/studio_widgets.dart';
part 'experience_studio/studio_flow.dart';

/// Customization — the unified theme hub. One layout for every entry
/// point: sticky BACK · PREVIEW · APPLY action bar, a 5-tab strip
/// (PRESETS / CUSTOM / FONTS / PARTICLES / AMBIANCE), a draggable LIVE
/// LOOK pane rendering a mini-UI with the staged picks, and scrollable
/// options below. Picks stage live through the whole screen; APPLY
/// commits, BACK restores the entry snapshot.
///
/// [initialTab] selects the opening wizard tab (1=COLORS & BG …
/// 5=SAVE); 0 opens the pick-or-create CHOOSE stage.
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
  late final CustomThemeData? _originalCustomTheme;
  late CustomThemeData _draft;
  // Set right before every intentional pop — PopScope blocks raw
  // system-back so staged picks always route through the restore path.
  bool _allowPop = false;
  int _hubTab = 0;
  double _liveLookH = 0.22;

  // ── Pick-or-create flow ────────────────────────────────────
  // choose → gallery | source → wizard. Deep links (initialTab>0)
  // land straight in the wizard.
  _StudioStage _stage = _StudioStage.choose;
  final PageController _galleryCtrl = PageController();
  int _galleryIndex = 0;
  bool _gallerySelect = false; // gallery doubles as copy-source picker
  bool _cameFromFlow = false; // wizard entered via NEW PRESET
  String _presetName = '';
  // Gallery presentation — list (official/custom sections, easy scan)
  // vs cards (fullscreen swipe). Persisted; list is the default since
  // the swiper doesn't scale past a handful of presets.
  bool _galleryListView = true;
  /// 3 quick-slot favorites above the preset doors - encoded refs
  /// `m:<AppThemeMode.name>` / `s:<SavedCustomTheme.id>`. Tap applies
  /// instantly; tap empty assigns via the gallery; long-press removes.
  static const _kQuickSlotsKey = 'studio.quickSlots.v1';
  List<String?> _quickSlots = List<String?>.filled(3, null);
  int _quickPickSlot = -1; // gallery doubles as slot picker for this idx

  @override
  void initState() {
    super.initState();
    _stage = widget.initialTab <= 0 ? _StudioStage.choose : _StudioStage.wizard;
    _hubTab = widget.initialTab.clamp(0, _hubTabs.length - 1);
    _previewMode = AppTheme.mode;
    _originalMode = AppTheme.mode;
    _originalPrefs = VisualPrefs.notifier.value;
    _originalCustomTheme = AppTheme.cachedCustomTheme;
    // Seed the draft from the LIVE custom theme, not a blank default —
    // deep links (initialTab>0) open the wizard on the real palette.
    _draft = AppTheme.cachedCustomTheme ?? CustomThemeData.defaultTheme;
    AppTheme.previewNotifier.value = _previewMode;
    SharedPreferences.getInstance().then((p) {
      final v = p.getBool('studio.galleryListView');
      if (v != null && mounted) setState(() => _galleryListView = v);
    });
    _loadQuickSlots();
  }

  Future<void> _loadQuickSlots() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_kQuickSlotsKey);
      if (raw == null || !mounted) return;
      final list = (jsonDecode(raw) as List).cast<String?>();
      setState(() {
        _quickSlots = [
          for (var i = 0; i < 3; i++) i < list.length ? list[i] : null,
        ];
      });
    } catch (_) {}
  }

  Future<void> _saveQuickSlots() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kQuickSlotsKey, jsonEncode(_quickSlots));
    } catch (_) {}
  }

  @override
  void dispose() {
    _galleryCtrl.dispose();
    AppTheme.previewNotifier.value = null;
    super.dispose();
  }

  /// Intentional close — commits staged picks, clears the preview and
  /// pops. PopScope's canPop is baked at build time, so flip the flag,
  /// rebuild, then pop post-frame (covers both pop semantics).
  void _closeAfterCommit() {
    AppTheme.previewNotifier.value = null;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _applyAndClose() async {
    Haptics.success();
    await AppTheme.setMode(_previewMode);
    _closeAfterCommit();
  }

  @override
  Widget build(BuildContext context) {
    final cleanTextTheme = GoogleFonts.montserratTextTheme(
      ThemeData.dark().textTheme,
    );
    final cleanTheme = Theme.of(context).copyWith(textTheme: cleanTextTheme);

    // Neo-Skeuo locks Customization — the skin ships as a fixed
    // hand-drawn identity with nothing to tune. Deep links land on a
    // locked page instead of the hub.
    if (AppTheme.isSkeuo) {
      return Theme(
        data: cleanTheme,
        child: Scaffold(
          backgroundColor: const Color(0xFFF0E9D8),
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(Insets.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 44,
                      color: Color(0xFF1F1B16),
                    ),
                    const SizedBox(height: Insets.lg),
                    const GoopText(
                      'CUSTOMIZATION IS LOCKED',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                        color: Color(0xFF1F1B16),
                      ),
                    ),
                    const SizedBox(height: Insets.sm),
                    const GoopText(
                      'Neo-Skeuo is a fixed hand-drawn identity — nothing to tune here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF5C5548)),
                    ),
                    const SizedBox(height: Insets.xl),
                    TextButton(
                      onPressed: () {
                        Haptics.selection();
                        AppTheme.exitSkeuo();
                      },
                      child: const GoopText(
                        'EXIT NEO-SKEUO',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Color(0xFF1F1B16),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: Insets.sm),
                    TextButton(
                      onPressed: () {
                        Haptics.selection();
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const GoopText(
                        'BACK',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: Color(0xFF5C5548),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Theme(
      data: cleanTheme,
      // System back / iOS swipe must walk the same stage-back path as the
      // on-screen BACK button — a raw pop would leak staged VisualPrefs
      // writes (gallery curation persists on every swipe) and skip the
      // mode + custom-theme restore.
      child: PopScope(
        canPop: _allowPop,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _onFlowBack();
        },
        child: Scaffold(
        backgroundColor: Colors.transparent,
        // Back moved to the bottom thumb zone (task 17 sweep).
        body: SafeArea(
          child: Stack(
            children: [
              // ── Theme background — skins with the PREVIEW theme, not the
              // actual app theme, so the whole screen updates on tap ──
              _buildPreviewBackground(),
              switch (_stage) {
                _StudioStage.choose => _buildChoose(),
                _StudioStage.gallery => _buildGallery(),
                _StudioStage.source => _buildSource(),
                _StudioStage.wizard => _buildHub(),
              },
            ],
          ),
        ),
        ),
      ),
    );
  }

  /// Background that skins with the preview theme so the entire screen
  /// immediately reflects the selected theme — not just the preview box.
  Widget _buildPreviewBackground() {
    final flair = AppTheme.flairFor(_previewMode);
    // Custom theme with a wallpaper picked — show the real image +
    // scrim instead of the flat canvas gradient.
    final wp =
        _previewMode == AppThemeMode.custom
            ? AppTheme.cachedCustomTheme?.wallpaper
            : null;
    if (wp != null) {
      return Positioned.fill(
        child: CustomWallpaper(
          assetFileName: wp,
          scrimColor: flair.scaffold,
          scrimStrength: 0.66,
        ),
      );
    }
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
  // bar, tab strip, draggable LIVE LOOK pane, scrollable options.
  // Tabs: DETAILS / COLORS & BG / TYPE / PARTICLES / AMBIANCE / SAVE.
  static const _hubTabs = [
    'DETAILS',
    'COLORS & BG',
    'TYPE',
    'PARTICLES',
    'AMBIANCE',
    'SAVE',
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
          _ghostBarButton('BACK', Icons.arrow_back_ios_new_rounded, _onFlowBack),

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
              behavior: HitTestBehavior.opaque,
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
              // Wallpaper under everything — the CANVAS pick previews
              // here exactly like the app renders it.
              if (_previewMode == AppThemeMode.custom &&
                  AppTheme.cachedCustomTheme?.wallpaper != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomWallpaper(
                      assetFileName: AppTheme.cachedCustomTheme!.wallpaper!,
                      scrimColor: AppTheme.flairFor(_previewMode).scaffold,
                      scrimStrength: 0.72,
                    ),
                  ),
                ),
              // Ambient shader — same layer the app overlay renders so
              // FOG/RAIN picks are visible in the pane (was: prefs
              // wrote but nothing rendered → looked dead).
              Positioned.fill(
                child: IgnorePointer(
                  child: ValueListenableBuilder<VisualPrefs>(
                    valueListenable: VisualPrefs.notifier,
                    builder: (_, prefs, _) {
                      if (!prefs.shaderEnabled) {
                        return const SizedBox.shrink();
                      }
                      return AmbientShaderLayer(
                        shader:
                            prefs.shaderPreset == ShaderPreset.darkNeonFog
                                ? AmbientShader.darkNeonFog
                                : AmbientShader.digitalRain,
                      );
                    },
                  ),
                ),
              ),
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
                      // Same resolution as ThemeOverlay: theme auto-glow
                      // when the user hasn't set one, ×1.8 boost.
                      final auto = f.glowPrimary.a > 0.01 ? 0.15 : 0.0;
                      final user =
                          prefs.glowIntensity > 0.001
                              ? prefs.glowIntensity
                              : auto;
                      final eff = (user * 1.8).clamp(0.0, 1.8);
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
                            // Exact ThemeOverlay vignette — same
                            // 4-stop radial + per-stop alphas so the
                            // slider previews what the app renders.
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
                                          alpha:
                                              0.05 * prefs.vignetteIntensity,
                                        ),
                                        Colors.black.withValues(
                                          alpha:
                                              0.25 * prefs.vignetteIntensity,
                                        ),
                                        Colors.black.withValues(
                                          alpha:
                                              0.48 * prefs.vignetteIntensity,
                                        ),
                                      ],
                                      stops: const [0.0, 0.45, 0.82, 1.0],
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

  Widget _buildHubContent() {
    switch (_hubTab) {
      case 0:
        return _buildDetailsStep();
      case 1:
        return _buildCustomTab();
      case 2:
        return const _TypographyStep();
      case 3:
        return const _ParticlesStep();
      case 4:
        return const _AmbianceStep();
      case 5:
        return _buildSaveStep();
      default:
        return _buildDetailsStep();
    }
  }

  // ── Pick-or-create flow stages ─────────────────────────────

  /// CHOOSE — the two doors: browse ready-made presets or build one.
  Widget _buildChoose() {
    final flair = AppTheme.flairFor(_previewMode);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Insets.xl,
        Insets.xl,
        Insets.xl,
        Insets.lg,
      ),
      children: [
        GoopText(
          'CUSTOMIZE',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: flair.primary,
          ),
        ),
        const SizedBox(height: 6),
        GoopText(
          'pick a look or build your own',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 22),
        _buildQuickSlots(),
        _FlowCard(
          icon: Icons.auto_awesome_rounded,
          title: 'BROWSE PRESETS',
          subtitle: 'swipe through every ready-made theme and saved preset',
          accent: flair.primary,
          onTap: () {
            Haptics.selection();
            setState(() {
              _stage = _StudioStage.gallery;
              _gallerySelect = false;
              _quickPickSlot = -1;
              _galleryIndex = 0;
            });
            // PageView isn't attached until the gallery builds — jump
            // post-frame or PageController throws.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_galleryCtrl.hasClients) _galleryCtrl.jumpToPage(0);
            });
          },
        ),
        const SizedBox(height: 14),
        _FlowCard(
          icon: Icons.edit_note_rounded,
          title: 'NEW PRESET',
          subtitle: 'name it, copy an existing preset or start blank',
          accent: flair.secondary,
          onTap: _onNewPreset,
        ),
      ],
    );
  }

  /// NEW PRESET — name first, then pick a source.
  Future<void> _onNewPreset() async {
    Haptics.selection();
    final name = await _promptPresetName();
    if (name == null || !mounted) return;
    setState(() {
      _presetName = name;
      _stage = _StudioStage.source;
      _cameFromFlow = true;
    });
  }

  /// Name dialog for a new preset — validates empty + duplicates.
  Future<String?> _promptPresetName() {
    final nameCtrl = TextEditingController(text: _presetName);
    String? error;
    final flair = AppTheme.flairFor(_previewMode);
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: flair.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: flair.primary.withValues(alpha: 0.4)),
          ),
          title: GoopText(
            'NAME YOUR PRESET',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: flair.primary,
            ),
          ),
          content: TextField(
            controller: nameCtrl,
            autofocus: true,
            maxLength: 24,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'e.g. Neon Cat',
              counterText: '',
              errorText: error,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
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
            ),
            onChanged: (_) {
              if (error != null) setDialogState(() => error = null);
            },
            onSubmitted:
                (v) => _submitPresetName(
                  ctx,
                  v,
                  (e) => setDialogState(() => error = e),
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const GoopText(
                'CANCEL',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ScaleButton(
              onTap:
                  () => _submitPresetName(
                    ctx,
                    nameCtrl.text,
                    (e) => setDialogState(() => error = e),
                  ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: flair.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: GoopText(
                  'NEXT',
                  style: TextStyle(
                    fontSize: 12,
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
        ),
      ),
    ).then((v) {
      nameCtrl.dispose();
      return v;
    });
  }

  void _submitPresetName(
    BuildContext ctx,
    String raw,
    void Function(String?) setErr,
  ) {
    final name = raw.trim();
    String? err;
    if (name.isEmpty) {
      err = 'Name cannot be empty';
    } else if (CustomThemeStore.themes.any(
          (t) => t.name.toLowerCase() == name.toLowerCase(),
        ) ||
        kPickerThemes.any(
          (t) => t.label.toLowerCase() == name.toLowerCase(),
        )) {
      err = 'A preset named "$name" exists';
    }
    if (err != null) {
      setErr(err);
      return;
    }
    Navigator.of(ctx).pop(name);
  }

  /// SOURCE — copy an existing preset's settings or start blank.
  Widget _buildSource() {
    final flair = AppTheme.flairFor(_previewMode);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Insets.xl,
        Insets.xl,
        Insets.xl,
        Insets.lg,
      ),
      children: [
        GoopText(
          'START FROM',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: flair.primary,
          ),
        ),
        const SizedBox(height: 6),
        GoopText(
          '"$_presetName" — pick a starting point',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 22),
        _FlowCard(
          icon: Icons.copy_rounded,
          title: 'COPY EXISTING',
          subtitle: 'start from any preset — all settings copied, then tweak',
          accent: flair.primary,
          onTap: () {
            Haptics.selection();
            setState(() {
              _stage = _StudioStage.gallery;
              _gallerySelect = true;
              _quickPickSlot = -1;
              _galleryIndex = 0;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_galleryCtrl.hasClients) _galleryCtrl.jumpToPage(0);
            });
          },
        ),
        const SizedBox(height: 14),
        _FlowCard(
          icon: Icons.blur_on_rounded,
          title: 'START FROM SCRATCH',
          subtitle: 'blank canvas — pick every color, particle and effect',
          accent: flair.secondary,
          onTap: _seedScratch,
        ),
      ],
    );
  }

  /// Gallery entries — premade picker themes first, then saved customs.
  List<_PresetEntry> _presetEntries() => [
    for (final m in kPickerThemes) _presetEntryForMode(m),
    for (final t in CustomThemeStore.themes) _presetEntryForSaved(t),
  ];

  _PresetEntry _presetEntryForMode(AppThemeMode m) => _PresetEntry(
    name: m.label,
    subtitle: '${m.vibe} · ${m.elem}',
    colors: [
      AppTheme.flairFor(m).scaffold,
      AppTheme.flairFor(m).card,
      AppTheme.flairFor(m).primary,
      AppTheme.flairFor(m).secondary,
      AppTheme.flairFor(m).headlineStat,
    ],
    mode: m,
    splash: m.splashSlug.isEmpty ? null : m.splashSlug,
  );

  _PresetEntry _presetEntryForSaved(SavedCustomTheme t) => _PresetEntry(
    name: t.name,
    subtitle: 'SAVED PRESET',
    colors: _savedColors(t),
    saved: t,
    // 'custom' → custom.jpg exists; premade-based saves keep the
    // source theme's splash - both render real card art.
    splash: t.splashSlug.isEmpty ? null : t.splashSlug,
  );

  /// Decode a quick-slot ref into a gallery entry - null when the ref
  /// is stale (saved preset deleted, mode removed from the picker).
  _PresetEntry? _resolveSlot(int i) {
    final ref = i >= 0 && i < _quickSlots.length ? _quickSlots[i] : null;
    if (ref == null) return null;
    if (ref.startsWith('m:')) {
      final name = ref.substring(2);
      for (final m in kPickerThemes) {
        if (m.name == name) return _presetEntryForMode(m);
      }
      return null;
    }
    if (ref.startsWith('s:')) {
      final id = ref.substring(2);
      for (final t in CustomThemeStore.themes) {
        if (t.id == id) return _presetEntryForSaved(t);
      }
    }
    return null;
  }

  void _onSlotTap(int i) {
    Haptics.selection();
    final e = _resolveSlot(i);
    if (e != null) {
      // Filled slot = one-tap apply, same as PICK PRESET.
      _applyEntry(e);
      return;
    }
    // Empty slot -> gallery in slot-pick mode.
    setState(() {
      _stage = _StudioStage.gallery;
      _quickPickSlot = i;
      _gallerySelect = false;
      _galleryIndex = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_galleryCtrl.hasClients) _galleryCtrl.jumpToPage(0);
    });
  }

  void _showSlotInfo(int i, _PresetEntry e) {
    Haptics.selection();
    final flair = AppTheme.flairFor(_previewMode);
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: flair.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: flair.primary.withValues(alpha: 0.4)),
            ),
            title: GoopText(
              'SLOT ${i + 1}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: flair.primary,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GoopText(
                  e.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                GoopText(
                  e.mode != null
                      ? 'Official preset - tap the slot to apply it instantly.'
                      : 'Your saved preset - tap the slot to apply it instantly.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const GoopText(
                  'CLOSE',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _quickSlots[i] = null);
                  _saveQuickSlots();
                  Navigator.of(ctx).pop();
                },
                child: const GoopText(
                  'REMOVE',
                  style: TextStyle(color: Color(0xFFE57373)),
                ),
              ),
            ],
          ),
    );
  }

  List<Color> _savedColors(SavedCustomTheme t) {
    final d =
        t.customData ??
        _customDataFromFlair(AppTheme.flairFor(t.baseMode), name: t.name);
    return [d.scaffold, d.card, d.primary, d.secondary, d.headlineStat];
  }

  /// Seed the wizard draft from a premade theme's flair.
  CustomThemeData _customDataFromFlair(ThemeFlair f, {required String name}) {
    return CustomThemeData(
      name: name,
      scaffold: f.scaffold,
      card: f.card,
      primary: f.primary,
      secondary: f.secondary,
      headlineStat: f.headlineStat,
      bulletColor: f.bulletColor,
      auraStyle: f.auraStyle,
      font: VisualPrefs.notifier.value.font,
    );
  }

  /// GALLERY — swipeable preset cards + bottom pick button. In
  /// [_gallerySelect] mode the pick seeds the wizard instead.
  Widget _buildGallery() {
    final entries = _presetEntries();
    final flair = AppTheme.flairFor(_previewMode);
    final idx = _galleryIndex.clamp(0, entries.length - 1);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.lg,
            Insets.sm,
            Insets.lg,
            0,
          ),
          child: Row(
            children: [
              _ghostBarButton(
                'BACK',
                Icons.arrow_back_ios_new_rounded,
                _onFlowBack,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GoopText(
                  _quickPickSlot >= 0
                      ? 'PICK FOR SLOT ${_quickPickSlot + 1}'
                      : (_gallerySelect ? 'COPY FROM' : 'PRESETS'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    color: flair.primary,
                  ),
                ),
              ),
              // View toggle — LIST scans official + custom sections;
              // CARDS keeps the fullscreen swipe gallery.
              _galleryViewToggle(flair),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child:
              _galleryListView
                  ? _buildPresetList(entries, idx)
                  : PageView.builder(
                    controller: _galleryCtrl,
                    onPageChanged: (i) {
                      setState(() => _galleryIndex = i);
                      _previewGalleryEntry(entries[i]);
                    },
                    itemCount: entries.length,
                    itemBuilder: (ctx, i) {
                      final e = entries[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 8,
                        ),
                        child: _presetCard(e, i == idx, i),
                      );
                    },
                  ),
        ),
        // Page dots — card view only.
        if (!_galleryListView)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < entries.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: i == idx ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color:
                          i == idx
                              ? flair.primary
                              : Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
        // Bottom pick bar
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.lg,
            0,
            Insets.lg,
            Insets.lg,
          ),
          child: ScaleButton(
            onTap: () => _onGalleryPick(entries[idx]),
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
                  Icon(
                    _quickPickSlot >= 0
                        ? Icons.star_rounded
                        : (_gallerySelect
                            ? Icons.copy_rounded
                            : Icons.check_rounded),
                    size: 16,
                    color:
                        flair.primary.computeLuminance() > 0.5
                            ? Colors.black87
                            : Colors.white,
                  ),
                  const SizedBox(width: 8),
                  GoopText(
                    _quickPickSlot >= 0
                        ? 'SET SLOT'
                        : (_gallerySelect ? 'USE AS BASE' : 'PICK PRESET'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color:
                          flair.primary.computeLuminance() > 0.5
                              ? Colors.black87
                              : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// LIST/CARDS toggle for the gallery header — persisted so the
  /// user's preferred browsing style sticks across sessions.
  Widget _galleryViewToggle(ThemeFlair flair) {
    Widget btn(bool list, IconData icon) {
      final on = _galleryListView == list;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Haptics.selection();
          setState(() => _galleryListView = list);
          SharedPreferences.getInstance().then(
            (p) => p.setBool('studio.galleryListView', list),
          );
          // Flipping to cards must land on the list's selected entry —
          // the PageView keeps its own page or the highlight lies.
          if (!list) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_galleryCtrl.hasClients) {
                _galleryCtrl.jumpToPage(_galleryIndex);
              }
            });
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color:
                on
                    ? flair.primary.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  on
                      ? flair.primary.withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Icon(
            icon,
            size: 15,
            color: on ? flair.primary : Colors.white.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [btn(true, Icons.view_list_rounded), btn(false, Icons.grid_view_rounded)],
    );
  }

  /// List presentation — OFFICIAL section (premade picker themes) on
  /// top, YOURS (saved presets) below. Every row is tappable, saved
  /// rows get a delete affordance in browse mode.
  Widget _buildPresetList(List<_PresetEntry> entries, int idx) {
    final flair = AppTheme.flairFor(_previewMode);
    final officialCount = entries.where((e) => e.mode != null).length;
    final hasCustom = entries.length > officialCount;
    Widget sectionHeader(String label) => Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
      child: GoopText(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.6,
          color: Colors.white.withValues(alpha: 0.4),
        ),
      ),
    );

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: entries.length + (hasCustom ? 2 : 1),
      itemBuilder: (ctx, i) {
        // Section headers occupy slots 0 and officialCount+1.
        if (i == 0) return sectionHeader('OFFICIAL');
        if (hasCustom && i == officialCount + 1) {
          return sectionHeader('YOURS');
        }
        final ei = i - 1 - (hasCustom && i > officialCount + 1 ? 1 : 0);
        final e = entries[ei];
        return _presetListTile(e, ei, ei == idx, flair);
      },
    );
  }

  /// One list row — splash thumb (or color dots), name + vibe, select
  /// highlight, delete icon on saved presets (browse mode only).
  Widget _presetListTile(
    _PresetEntry e,
    int index,
    bool isCurrent,
    ThemeFlair flair,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Haptics.selection();
          setState(() => _galleryIndex = index);
          _previewGalleryEntry(e);
        },
        // Same affordance as the card view — long-press deletes a saved
        // preset (browse mode only, never in the copy-source picker).
        onLongPress:
            e.saved != null && !_gallerySelect
                ? () => _confirmDeletePreset(e.saved!)
                : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color:
                isCurrent
                    ? flair.primary.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isCurrent
                      ? flair.primary.withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.1),
              width: isCurrent ? 1.6 : 1.0,
            ),
          ),
          child: Row(
            children: [
              // Thumb — splash art when the preset has one, else the
              // palette gradient.
              Container(
                width: 44,
                height: 44,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child:
                    e.splash != null
                        ? Image.asset(
                          'assets/images/themes/splash/${e.splash}.jpg',
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, _, _) => _presetListThumbFallback(e),
                        )
                        : _presetListThumbFallback(e),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GoopText(
                      e.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: isCurrent ? flair.primary : Colors.white,
                      ),
                    ),
                    GoopText(
                      e.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (e.saved != null && !_gallerySelect && _quickPickSlot < 0)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _confirmDeletePreset(e.saved!),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 17,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                )
              else if (isCurrent)
                Icon(Icons.check_circle_rounded, size: 16, color: flair.primary),
            ],
          ),
        ),
      ),
    );
  }

  /// The 3 quick slots pinned above the preset doors.
  Widget _buildQuickSlots() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: _quickSlot(i)),
          ],
        ],
      ),
    );
  }

  Widget _quickSlot(int i) {
    final e = _resolveSlot(i);
    final flair = AppTheme.flairFor(_previewMode);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onSlotTap(i),
      onLongPress: e == null ? null : () => _showSlotInfo(i, e),
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: e == null ? 0.03 : 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                e == null
                    ? Colors.white.withValues(alpha: 0.14)
                    : flair.primary.withValues(alpha: 0.45),
            width: e == null ? 1.0 : 1.4,
          ),
        ),
        child:
            e == null
                ? Center(
                  child: Icon(
                    Icons.add_rounded,
                    color: Colors.white.withValues(alpha: 0.35),
                    size: 22,
                  ),
                )
                : Row(
                  children: [
                    const SizedBox(width: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 30,
                        height: 38,
                        child: _slotThumb(e),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GoopText(
                        e.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
      ),
    );
  }

  Widget _slotThumb(_PresetEntry e) {
    if (e.splash != null) {
      return Image.asset(
        'assets/images/themes/splash/${e.splash}.jpg',
        fit: BoxFit.cover,
        errorBuilder:
            (_, _, _) => _presetListThumbFallback(e),
      );
    }
    return _presetListThumbFallback(e);
  }

  Widget _presetListThumbFallback(_PresetEntry e) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [e.colors[0], e.colors[1], e.colors[2]],
        ),
      ),
    );
  }

  /// One gallery card — splash art when available, else a palette
  /// gradient; name + vibe strip at the bottom.
  Widget _presetCard(_PresetEntry e, bool isCurrent, int index) {
    final flair = AppTheme.flairFor(_previewMode);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Haptics.selection();
        _galleryCtrl.animateToPage(
          index,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      },
      // Long-press a saved preset to delete it — browse mode only;
      // the copy-source picker shouldn't mutate the store mid-flow.
      onLongPress:
          e.saved != null && !_gallerySelect && _quickPickSlot < 0
              ? () => _confirmDeletePreset(e.saved!)
              : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isCurrent
                    ? flair.primary.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.15),
            width: isCurrent ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (e.splash != null)
                Image.asset(
                  'assets/images/themes/splash/${e.splash}.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _presetCardBg(e),
                )
              else
                _presetCardBg(e),
              // Bottom info panel
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 22, 14, 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.82),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GoopText(
                        e.name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      GoopText(
                        e.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (final c in e.colors)
                            Expanded(
                              child: Container(
                                height: 6,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  color: c,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Long-press delete for saved presets — confirm, remove from the
  /// store, and rebuild the gallery without it.
  Future<void> _confirmDeletePreset(SavedCustomTheme t) async {
    Haptics.selection();
    final flair = AppTheme.flairFor(_previewMode);
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: flair.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: flair.primary.withValues(alpha: 0.4)),
            ),
            title: GoopText(
              'DELETE PRESET',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: flair.primary,
              ),
            ),
            content: GoopText(
              '"${t.name}" will be removed from your presets. This cannot be undone.',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const GoopText(
                  'CANCEL',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: GoopText(
                  'DELETE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
    );
    if (ok != true || !mounted) return;
    await CustomThemeStore.delete(t.id);
    if (mounted) setState(() {});
  }

  Widget _presetCardBg(_PresetEntry e) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [e.colors[0], e.colors[1], e.colors[2]],
        ),
      ),
    );
  }

  /// Live-preview the gallery entry under the finger. Saved presets
  /// swap the whole VisualPrefs snapshot (not persisted — PICK/seed
  /// persists, BACK restores the entry snapshot) so particles, font
  /// and glow preview honestly instead of showing the last entry's.
  void _previewGalleryEntry(_PresetEntry e) {
    if (e.mode != null) {
      _previewTheme(e.mode!);
    } else if (e.saved != null) {
      final s = e.saved!;
      final d =
          s.customData ??
          _customDataFromFlair(
            AppTheme.flairFor(s.baseMode),
            name: s.name,
          );
      VisualPrefs.notifier.value = s.prefs;
      AppTheme.saveCustomThemeData(d);
      _previewTheme(AppThemeMode.custom);
    }
  }

  /// Bottom pick - assign quick slot, seed wizard (copy), or apply
  /// & close (browse).
  Future<void> _onGalleryPick(_PresetEntry e) async {
    Haptics.success();
    if (_quickPickSlot >= 0) {
      setState(() {
        _quickSlots[_quickPickSlot] =
            e.mode != null ? 'm:${e.mode!.name}' : 's:${e.saved!.id}';
        _quickPickSlot = -1;
        _stage = _StudioStage.choose;
      });
      await _saveQuickSlots();
      return;
    }
    if (_gallerySelect) {
      await _seedFromEntry(e);
      return;
    }
    await _applyEntry(e);
  }

  /// Apply a gallery entry app-wide and close - premade swaps the mode
  /// (curation applies inside setMode); saved presets restore their
  /// full VisualPrefs snapshot + palette.
  Future<void> _applyEntry(_PresetEntry e) async {
    if (e.mode != null) {
      await AppTheme.setMode(e.mode!);
    } else if (e.saved != null) {
      final s = e.saved!;
      final d =
          s.customData ??
          _customDataFromFlair(AppTheme.flairFor(s.baseMode), name: s.name);
      await VisualPrefs.replaceAndPersist(s.prefs);
      await AppTheme.saveCustomThemeData(d);
      await AppTheme.setMode(AppThemeMode.custom);
    }
    _closeAfterCommit();
  }

  /// Seed the wizard from a gallery entry (copy-existing path).
  Future<void> _seedFromEntry(_PresetEntry e) async {
    Haptics.success();
    if (e.mode != null) {
      final curation = kThemeCuration[e.mode!];
      if (curation != null) await VisualPrefs.applyCuration(curation);
      // Match setMode's font behavior — a premade's typeface is part of
      // its identity; copying it shouldn't inherit the old font.
      final themeFont = e.mode!.flair.font;
      if (themeFont != null) await VisualPrefs.setFont(themeFont);
      setState(() {
        _draft = _customDataFromFlair(
          AppTheme.flairFor(e.mode!),
          name: _presetName,
        );
        _previewMode = AppThemeMode.custom;
        _stage = _StudioStage.wizard;
        _hubTab = 0;
        _gallerySelect = false;
      });
    } else if (e.saved != null) {
      final s = e.saved!;
      await VisualPrefs.replaceAndPersist(s.prefs);
      setState(() {
        _draft =
            s.customData ??
            _customDataFromFlair(
              AppTheme.flairFor(s.baseMode),
              name: _presetName,
            );
        _previewMode = AppThemeMode.custom;
        _stage = _StudioStage.wizard;
        _hubTab = 0;
        _gallerySelect = false;
      });
    }
    await AppTheme.saveCustomThemeData(_draft);
    AppTheme.previewNotifier.value = _previewMode;
  }

  /// Scratch — blank custom draft, keep current visual prefs.
  Future<void> _seedScratch() async {
    Haptics.success();
    setState(() {
      _draft = CustomThemeData.defaultTheme.copyWith(name: _presetName);
      _previewMode = AppThemeMode.custom;
      _stage = _StudioStage.wizard;
      _hubTab = 0;
      _cameFromFlow = true;
    });
    await AppTheme.saveCustomThemeData(_draft);
    AppTheme.previewNotifier.value = _previewMode;
  }

  /// DETAILS tab — compact summary of every pick + fullscreen preview.
  Widget _buildDetailsStep() {
    final flair = AppTheme.flairFor(_previewMode);
    return ValueListenableBuilder<VisualPrefs>(
      valueListenable: VisualPrefs.notifier,
      builder: (_, prefs, _) {
        final wp = AppTheme.cachedCustomTheme?.wallpaper;
        Widget chip(String label, String value, {Color? dot}) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 74,
                child: GoopText(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ),
              if (dot != null) ...[
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: dot,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                ),
              ],
              Expanded(
                child: GoopText(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        );
        String hex(Color c) =>
            '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            Insets.lg,
            0,
            Insets.lg,
            Insets.lg,
          ),
          children: [
            GoopText(
              _presetName.isEmpty ? 'CURRENT LOOK' : 'PRESET: $_presetName',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: flair.primary,
              ),
            ),
            const SizedBox(height: 14),
            // Palette strip — the six color roles at a glance.
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  for (final c in [
                    _draft.scaffold,
                    _draft.card,
                    _draft.primary,
                    _draft.secondary,
                    _draft.headlineStat,
                    _draft.bulletColor,
                  ])
                    Expanded(
                      child: Container(
                        height: 26,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            chip(
              'CANVAS',
              _previewMode == AppThemeMode.custom
                  ? (wp != null
                      ? 'WALLPAPER ${wp.toUpperCase()}'
                      : 'SOLID ${hex(_draft.scaffold)}')
                  : 'THEME',
            ),
            chip('PANEL', hex(_draft.card)),
            chip('PRIME', hex(_draft.primary), dot: _draft.primary),
            chip('SECOND', hex(_draft.secondary), dot: _draft.secondary),
            chip('STAT', hex(_draft.headlineStat), dot: _draft.headlineStat),
            // The typed system's real picks — shape type + color
            // palette — not the hidden particlePreset curation field.
            chip(
              'PARTICLES',
              '${ParticleType.values[prefs.particleTypeIndex.clamp(0, ParticleType.values.length - 1)].label} · ${kGlobalParticlePalettes[prefs.particleSchemaIndex.clamp(0, kGlobalParticlePalettes.length - 1)].name}',
            ),
            chip('FONT', prefs.font.label),
            chip('GLOW', '${(prefs.glowIntensity * 100).round()}%'),
            chip(
              'SHADER',
              prefs.shaderEnabled ? prefs.shaderPreset.name : 'OFF',
            ),
            const SizedBox(height: 10),
            ScaleButton(
              onTap: _openMockPreview,
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: flair.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: flair.primary.withValues(alpha: 0.6),
                    width: 1.4,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.preview_rounded, size: 16, color: flair.primary),
                    const SizedBox(width: 8),
                    GoopText(
                      'FULLSCREEN PREVIEW',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: flair.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            GoopText(
              'mock run + gun detail — swipe inside preview',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openMockPreview() {
    Haptics.selection();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _MockPreviewScreen()),
    );
  }

  /// SAVE tab — review + persist the preset, then apply & close.
  Widget _buildSaveStep() {
    final flair = AppTheme.flairFor(_previewMode);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Insets.lg,
        0,
        Insets.lg,
        Insets.lg,
      ),
      children: [
        GoopText(
          'SAVE PRESET',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
            color: flair.primary,
          ),
        ),
        const SizedBox(height: 8),
        GoopText(
          _presetName.isEmpty
              ? 'this look will be saved under a name you pick'
              : '"$_presetName" joins your preset gallery',
          style: TextStyle(
            fontSize: 11,
            height: 1.4,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 20),
        ScaleButton(
          onTap: _onSavePreset,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: flair.primary,
              borderRadius: BorderRadius.all(Radii.md),
              boxShadow: [
                BoxShadow(
                  color: flair.primary.withValues(alpha: 0.5),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_added_rounded,
                  size: 18,
                  color:
                      flair.primary.computeLuminance() > 0.5
                          ? Colors.black87
                          : Colors.white,
                ),
                const SizedBox(width: 10),
                GoopText(
                  'SAVE & APPLY',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color:
                        flair.primary.computeLuminance() > 0.5
                            ? Colors.black87
                            : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        GoopText(
          'saving keeps every pick — colors, wallpaper, particles, glow, font',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9.5,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  /// Persist the staged look as a [SavedCustomTheme], apply it, close.
  Future<void> _onSavePreset() async {
    var name = _presetName;
    if (name.isEmpty) {
      final picked = await _promptPresetName();
      if (picked == null || !mounted) return;
      name = picked;
      _presetName = name;
    }
    Haptics.success();
    final isCustom = _previewMode == AppThemeMode.custom;
    final theme = SavedCustomTheme(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      splashSlug: isCustom ? 'custom' : _previewMode.splashSlug,
      baseMode: _previewMode,
      prefs: VisualPrefs.notifier.value,
      customData: isCustom ? _draft.copyWith(name: name) : null,
    );
    await CustomThemeStore.save(theme);
    if (isCustom) {
      await AppTheme.saveCustomThemeData(_draft.copyWith(name: name));
    }
    await AppTheme.setMode(_previewMode);
    _closeAfterCommit();
  }

  /// Stage-aware BACK — walk the flow backwards; at CHOOSE it does
  /// the hard restore-and-pop.
  void _onFlowBack() {
    Haptics.selection();
    switch (_stage) {
      case _StudioStage.wizard:
        if (_cameFromFlow) {
          setState(() => _stage = _StudioStage.source);
        } else {
          _onBack();
        }
      case _StudioStage.gallery:
        setState(() {
          _quickPickSlot = -1;
          _stage =
              _gallerySelect ? _StudioStage.source : _StudioStage.choose;
        });
      case _StudioStage.source:
        setState(() => _stage = _StudioStage.choose);
      case _StudioStage.choose:
        _onBack();
    }
  }

  /// BACK — discard staged picks by restoring the entry snapshot
  /// (premade-mode restores prefs too, since curation writes them;
  /// custom-theme data restores because color/wallpaper edits persist
  /// eagerly through saveCustomThemeData).
  Future<void> _onBack() async {
    Haptics.selection();
    AppTheme.previewNotifier.value = null;
    await VisualPrefs.replaceAndPersist(_originalPrefs);
    await AppTheme.restoreCustomThemeData(_originalCustomTheme);
    await AppTheme.setMode(_originalMode);
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
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
    final rows = <Widget>[
      for (var i = 0; i < roles.length; i++) ...[
        _colorRoleRow(roles[i].$1, roles[i].$2, roles[i].$3, roles[i].$4),
        // BG mode + wallpaper picker sit directly under CANVAS — the
        // backdrop is either the solid canvas color or a wallpaper.
        if (i == 0) ...[_buildBgModeRow(), _buildWallpaperRow()],
      ],
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(Insets.lg, 0, Insets.lg, Insets.lg),
      children: [
        if (_previewMode == AppThemeMode.unicorn) _buildUnicornStrip(),
        ...rows,
        const SizedBox(height: 14),
        _buildPanelChromeSection(),
        const SizedBox(height: 14),
        GoopText(
          'save your finished preset from the SAVE tab',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9.5,
            color: Colors.white.withValues(alpha: 0.4),
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
        behavior: HitTestBehavior.opaque,
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
                style: const TextStyle(fontSize: 10, color: Color(0x80FFFFFF)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// PANELS — global chrome overrides applied to every panel surface
  /// (dashboard, gun/item tiles, browse cards, bottom nav) via the
  /// flairFor post-process. All controls write VisualPrefs directly so
  /// they persist and ride inside preset saves like every other pref.
  Widget _buildPanelChromeSection() {
    final flair = AppTheme.flairFor(_previewMode);
    return ValueListenableBuilder<VisualPrefs>(
      valueListenable: VisualPrefs.notifier,
      builder: (_, prefs, _) {
        final borderMode = prefs.panelBorderColor == -1
            ? 2
            : prefs.panelBorderColor != 0
            ? 1
            : 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GoopText(
              'PANELS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
                color: flair.primary,
              ),
            ),
            const SizedBox(height: 2),
            GoopText(
              'every card, tile & nav surface',
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 8),
            _chromeColorRow(
              'PANEL COLOR',
              'fill for all panels',
              prefs.panelColor != 0 ? Color(prefs.panelColor) : flair.card,
              prefs.panelColor != 0,
              (c) => VisualPrefs.setPanelColor(c.toARGB32()),
              onClear: () => VisualPrefs.setPanelColor(0),
            ),
            _StudioSlider(
              'OPACITY',
              '${(prefs.panelOpacity * 100).round()}%',
              prefs.panelOpacity,
              0.15,
              1.0,
              17,
              flair.primary,
              (v) => VisualPrefs.setPanelOpacity(v),
            ),
            Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: _ShaderChip(
                      label: const ['AUTO', 'CUSTOM', 'NONE'][i],
                      on: borderMode == i,
                      onTap: () async {
                        if (i == 0) {
                          await VisualPrefs.setPanelBorderColor(0);
                        } else if (i == 2) {
                          await VisualPrefs.setPanelBorderColor(-1);
                        } else {
                          final c = await _PaletteColorSheet.show(
                            context,
                            prefs.panelBorderColor > 0
                                ? Color(prefs.panelBorderColor)
                                : flair.primary,
                          );
                          if (c != null && mounted) {
                            await VisualPrefs.setPanelBorderColor(
                              c.toARGB32(),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
            if (prefs.panelBorderColor > 0) ...[
              const SizedBox(height: 8),
              _chromeColorRow(
                'BORDER COLOR',
                'panel outline',
                Color(prefs.panelBorderColor),
                true,
                (c) => VisualPrefs.setPanelBorderColor(c.toARGB32()),
                onClear: () => VisualPrefs.setPanelBorderColor(0),
              ),
              _StudioSlider(
                'BORDER WIDTH',
                prefs.panelBorderWidth > 0
                    ? prefs.panelBorderWidth.toStringAsFixed(1)
                    : 'AUTO',
                prefs.panelBorderWidth > 0 ? prefs.panelBorderWidth : 1.0,
                0.5,
                3.0,
                10,
                flair.primary,
                (v) => VisualPrefs.setPanelBorderWidth(v),
              ),
            ],
            _StudioSlider(
              'RADIUS',
              prefs.panelRadius > 0
                  ? prefs.panelRadius.toStringAsFixed(0)
                  : 'AUTO',
              prefs.panelRadius > 0 ? prefs.panelRadius : 12.0,
              0.0,
              24.0,
              24,
              flair.primary,
              (v) => VisualPrefs.setPanelRadius(v),
            ),
          ],
        );
      },
    );
  }

  /// Callback variant of [_colorRoleRow] for prefs-backed chrome picks —
  /// same sheet, same look, writes VisualPrefs instead of the draft.
  Widget _chromeColorRow(
    String label,
    String desc,
    Color color,
    bool overridden,
    void Function(Color) onPick, {
    VoidCallback? onClear,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          final c = await _PaletteColorSheet.show(context, color);
          if (c == null || !mounted) return;
          onPick(c);
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
              if (overridden && onClear != null)
                GestureDetector(
                  onTap: onClear,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: GoopText(
                      'AUTO',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: AppTheme.flair.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// BG MODE chips — SOLID uses the CANVAS color, WALLPAPER opens the
  /// picker sheet. Mirrors the wallpaper sheet's NONE tile so both
  /// paths clear/set the same field.
  Widget _buildBgModeRow() {
    final wp = AppTheme.cachedCustomTheme?.wallpaper;
    Widget chip(String label, bool on, VoidCallback onTap) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: _ShaderChip(label: label, on: on, onTap: onTap),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          chip('SOLID', wp == null, () {
            if (wp == null) return;
            Haptics.selection();
            setState(() => _draft = _draft.copyWith(wallpaper: null));
            AppTheme.saveCustomThemeData(_draft);
            _previewTheme(AppThemeMode.custom);
          }),
          chip('WALLPAPER', wp != null, () {
            Haptics.selection();
            _showWallpaperSheet();
          }),
        ],
      ),
    );
  }

  /// Wallpaper row under CANVAS — shows the current pick (or NONE)
  /// and opens the wallpaper sheet. Picking one swaps the flat canvas
  /// color for the image app-wide; NONE restores the solid color.
  Widget _buildWallpaperRow() {
    final wp = AppTheme.cachedCustomTheme?.wallpaper;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _showWallpaperSheet,
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
                width: 26,
                height: 34,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: _draft.scaffold,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child:
                    wp == null
                        ? const Icon(
                          Icons.wallpaper_outlined,
                          size: 14,
                          color: Colors.white38,
                        )
                        : Image.asset(
                          CustomWallpaper.assetPath(wp),
                          fit: BoxFit.cover,
                          cacheWidth: 96,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GoopText(
                      'WALLPAPER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: Colors.white70,
                      ),
                    ),
                    GoopText(
                      'app backdrop image',
                      style: TextStyle(fontSize: 9, color: Color(0x80FFFFFF)),
                    ),
                  ],
                ),
              ),
              GoopText(
                wp == null
                    ? 'NONE'
                    : (wp.length >= 5 ? 'WP ${wp.substring(3, 5)}' : wp),
                style: const TextStyle(fontSize: 10, color: Color(0x80FFFFFF)),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom sheet grid of bundled wallpapers + a NONE tile. Picking one
  /// applies immediately to the draft (same live-preview path as the
  /// color rows) and pops the sheet.
  void _showWallpaperSheet() {
    Haptics.selection();
    final current = AppTheme.cachedCustomTheme?.wallpaper;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final flair = AppTheme.flairFor(_previewMode);
        return Container(
          height: MediaQuery.sizeOf(ctx).height * 0.62,
          decoration: BoxDecoration(
            color: flair.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            border: Border.all(color: flair.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: GoopText(
                        'WALLPAPER',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                          color: flair.primary,
                        ),
                      ),
                    ),
                    GoopText(
                      'replaces CANVAS color',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: kCustomWallpaperAssets.length + 1,
                  itemBuilder: (ctx, i) {
                    // Tile 0 = NONE (solid canvas color).
                    if (i == 0) {
                      final isSel = current == null;
                      return _WallpaperTile(
                        selected: isSel,
                        accent: flair.primary,
                        onTap: () => _applyWallpaper(null),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wallpaper_outlined,
                              size: 26,
                              color: isSel ? flair.primary : Colors.white54,
                            ),
                            const SizedBox(height: 6),
                            GoopText(
                              'NONE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                color:
                                    isSel
                                        ? flair.primary
                                        : Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    final file = kCustomWallpaperAssets[i - 1];
                    final isSel = file == current;
                    return _WallpaperTile(
                      selected: isSel,
                      accent: flair.primary,
                      onTap: () => _applyWallpaper(file),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          CustomWallpaper.assetPath(file),
                          fit: BoxFit.cover,
                          cacheWidth: 240,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Persist the wallpaper pick into the custom draft + live preview,
  /// then close the sheet.
  Future<void> _applyWallpaper(String? file) async {
    Haptics.selection();
    setState(() => _draft = _draft.copyWith(wallpaper: file));
    await AppTheme.saveCustomThemeData(_draft);
    _previewTheme(AppThemeMode.custom);
    if (mounted && Navigator.of(context).canPop()) {
      // Pop the bottom sheet — the studio screen itself stays open.
      Navigator.of(context).pop();
    }
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
              behavior: HitTestBehavior.opaque,
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
                                ? Skeuo.inkIf(
                                  Colors.pinkAccent,
                                ).withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              p == active
                                  ? Skeuo.inkIf(Colors.pinkAccent)
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
                                  ? Skeuo.inkIf(Colors.pinkAccent)
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
                      behavior: HitTestBehavior.opaque,
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
      behavior: HitTestBehavior.opaque,
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
    with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  // One-shot first-open demo — 3 big bounces (~2.4s) so users discover
  // the drag affordance without a manual, then falls back to the bob.
  AnimationController? _demo;
  bool _demoing = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted || prefs.getBool('experienceStudioDragDemoSeen') == true) {
        return;
      }
      prefs.setBool('experienceStudioDragDemoSeen', true);
      setState(() {
        _demoing = true;
        _demo =
            AnimationController(
                vsync: this,
                duration: const Duration(milliseconds: 2400),
              )
              ..addStatusListener((st) {
                if (st == AnimationStatus.completed) {
                  setState(() => _demoing = false);
                }
              })
              ..forward();
      });
    });
  }

  @override
  void dispose() {
    _demo?.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder:
          (_, _) => Transform.translate(
            offset: Offset(
              0,
              _demoing
                  ? -9 * math.sin(_demo!.value * math.pi * 3)
                  : -2.5 * _c.value,
            ),
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
