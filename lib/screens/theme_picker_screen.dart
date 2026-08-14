import 'package:flutter/material.dart';
import '../services/goop_talk_engine.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_theme.dart';
import '../services/haptics.dart';
import '../utils/responsive.dart';
import '../widgets/particle_engine.dart'
    show
        ParticlePreset,
        ParticlePresetX,
        ParticleColorSchema,
        ParticleColorSchemaX,
        ParticleSpeed,
        ParticleSpeedX,
        GlowEffect,
        GlowEffectX;

/// Full-screen immersive theme picker. Each page fills the entire screen
/// with the theme's scaffold colour, showcasing a large palette and a
/// short flavour description. Swipe to preview, tap to apply.
class ThemePickerScreen extends StatefulWidget {
  const ThemePickerScreen({super.key});

  @override
  State<ThemePickerScreen> createState() => _ThemePickerScreenState();
}

class _ThemePickerScreenState extends State<ThemePickerScreen> {
  late final PageController _pc;
  late int _index;
  late AppThemeMode _activeMode;
  bool _particleStudioOpen = false;

  @override
  void initState() {
    super.initState();
    _activeMode = AppTheme.mode;
    final visibleIdx = kVisibleThemes.indexOf(_activeMode);
    _index = visibleIdx >= 0 ? visibleIdx : 0;
    _pc = PageController(initialPage: _index, viewportFraction: 1.0);
    AppTheme.previewNotifier.value = _activeMode;
  }

  @override
  void dispose() {
    _pc.dispose();
    AppTheme.previewNotifier.value = null;
    super.dispose();
  }

  void _select(AppThemeMode m) {
    AppTheme.previewNotifier.value = null;
    AppTheme.setMode(m);
    setState(() => _activeMode = m);
    Haptics.success();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final modes = kVisibleThemes;
    final cleanTextTheme =
        GoogleFonts.montserratTextTheme(ThemeData.dark().textTheme);
    final cleanTheme = Theme.of(context).copyWith(textTheme: cleanTextTheme);

    return Theme(
      data: cleanTheme,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top bar ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4, right: 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20, color: Colors.white70),
                    ),
                    const Spacer(),
                    GoopText(
                      'PALETTE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.4),
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
              // ── Compact horizontal swipeable theme cards ────────────
              SizedBox(
                height: 100,
                child: PageView.builder(
                  controller: _pc,
                  itemCount: modes.length,
                  onPageChanged: (i) {
                    setState(() => _index = i);
                    AppTheme.previewNotifier.value = modes[i];
                    Haptics.selection();
                  },
                  itemBuilder: (context, i) {
                    final m = modes[i];
                    return _CompactThemeCard(
                      mode: m,
                      isActive: m == _activeMode,
                      isFocused: i == _index,
                      onTap: () => _select(m),
                    );
                  },
                ),
              ),
              // ── Dot indicator ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(modes.length, (i) {
                    final on = i == _index;
                    final f = AppTheme.flairFor(modes[i]);
                    return GestureDetector(
                      onTap: () {
                        _pc.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: on ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: on ? f.primary : Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              // ── Theme details: name + tagline + apply ───────────────
              _CompactThemeDetails(
                mode: modes[_index],
                isActive: modes[_index] == _activeMode,
                onApply: () => _select(modes[_index]),
              ),
              // ── Particle strips ─────────────────────────────────────
              ValueListenableBuilder<VisualPrefs>(
                valueListenable: VisualPrefs.notifier,
                builder: (context, prefs, _) {
                  return _QuickParticleStrip(
                    activeMode: modes[_index],
                    currentPreset: prefs.particlePreset,
                    onPreset: (p) {
                      VisualPrefs.setParticlePreset(p);
                      Haptics.selection();
                    },
                  );
                },
              ),
              ValueListenableBuilder<VisualPrefs>(
                valueListenable: VisualPrefs.notifier,
                builder: (context, prefs, _) {
                  return _ParticleColorSchemaStrip(
                    currentSchema: prefs.particleColorSchema,
                    onSchema: (s) {
                      VisualPrefs.setParticleColorSchema(s);
                      Haptics.selection();
                    },
                  );
                },
              ),
              ValueListenableBuilder<VisualPrefs>(
                valueListenable: VisualPrefs.notifier,
                builder: (context, prefs, _) {
                  return _ParticleSpeedStrip(
                    currentSpeed: prefs.particleSpeed,
                    onSpeed: (s) {
                      VisualPrefs.setParticleSpeed(s);
                      Haptics.selection();
                    },
                  );
                },
              ),
              // ── Particle Studio (expandable) ────────────────────────
              _buildParticleStudio(),
            ],
          ),
        ),
      ),
    );
  }

  /// Particle Studio — expandable panel with all advanced particle
  /// controls (enable, count, size, opacity, glow, line links, bounce).
  /// Collapsed by default so the 3 quick strips stay compact.
  Widget _buildParticleStudio() {
    final flair = AppTheme.flair;
    return Column(
      children: [
        // Toggle header
        InkWell(
          onTap: () {
            Haptics.selection();
            setState(() => _particleStudioOpen = !_particleStudioOpen);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: flair.card.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _particleStudioOpen
                    ? flair.primary.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.08),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _particleStudioOpen
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: _particleStudioOpen
                      ? flair.primary
                      : Colors.white.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 10),
                GoopText(
                  'PARTICLE STUDIO',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: _particleStudioOpen ? Colors.white70 : Colors.white38,
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
                Icon(Icons.tune_rounded, size: 14, color: flair.primary.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
        // Expanded panel
        if (_particleStudioOpen)
          ValueListenableBuilder<VisualPrefs>(
            valueListenable: VisualPrefs.notifier,
            builder: (context, prefs, _) {
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: flair.card.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: flair.primary.withValues(alpha: 0.18)),
                ),
                child: Column(
                  children: [
                    // Enable toggle
                    _studioSwitchRow(
                      icon: Icons.auto_awesome_outlined,
                      label: 'Enable Particles',
                      value: prefs.particlesEnabled,
                      onChanged: VisualPrefs.setParticles,
                      flair: flair,
                    ),
                    if (prefs.particlesEnabled) ...[
                      const Divider(color: Colors.white12, height: 20),
                      // Count
                      _studioSliderRow(
                        'Particle Count',
                        '${prefs.particleCount}',
                        prefs.particleCount.toDouble(),
                        1.0, 32.0, 31,
                        flair.headlineStat,
                        (v) => VisualPrefs.setParticleCount(v.toInt()),
                      ),
                      const SizedBox(height: 10),
                      // Size
                      _studioSliderRow(
                        'Particle Size',
                        '${prefs.particleSizeScale.toStringAsFixed(1)}x',
                        prefs.particleSizeScale,
                        0.3, 2.0, 17,
                        flair.headlineStat,
                        (v) => VisualPrefs.setParticleSizeScale(v),
                      ),
                      const SizedBox(height: 10),
                      // Opacity
                      _studioSliderRow(
                        'Particle Opacity',
                        '${(prefs.particleOpacity * 100).toStringAsFixed(0)}%',
                        prefs.particleOpacity,
                        0.0, 1.0, 20,
                        flair.headlineStat,
                        (v) => VisualPrefs.setParticleOpacity(v),
                      ),
                      const SizedBox(height: 12),
                      // Glow effect picker
                      SizedBox(
                        height: 48,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: GlowEffect.values.map((e) {
                            final sel = e == prefs.particleGlowEffect;
                            return GestureDetector(
                              onTap: () {
                                VisualPrefs.setParticleGlowEffect(e);
                                Haptics.selection();
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? flair.card.withValues(alpha: 0.9)
                                      : flair.card.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: sel ? flair.primary.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08),
                                    width: sel ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Center(
                                  child: GoopText(
                                    e.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: sel ? Colors.white : Colors.white54,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Line links toggle
                      _studioSwitchRow(
                        icon: Icons.timeline_outlined,
                        label: 'Line Links',
                        value: prefs.particleLineLinks,
                        onChanged: VisualPrefs.setParticleLineLinks,
                        flair: flair,
                      ),
                      const SizedBox(height: 6),
                      // Bounce toggle
                      _studioSwitchRow(
                        icon: Icons.sports_baseball_outlined,
                        label: 'Edge Bounce',
                        value: prefs.particleBounce,
                        onChanged: VisualPrefs.setParticleBounce,
                        flair: flair,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _studioSwitchRow({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ThemeFlair flair,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: flair.card.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: flair.primary.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 10),
          Expanded(
            child: GoopText(
              label.toUpperCase(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 0.5),
            ),
          ),
          Switch(
            value: value,
            activeColor: flair.primary,
            activeTrackColor: flair.primary.withValues(alpha: 0.25),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white10,
            onChanged: (val) {
              onChanged(val);
              Haptics.selection();
            },
          ),
        ],
      ),
    );
  }

  Widget _studioSliderRow(
    String label,
    String displayValue,
    double value,
    double min,
    double max,
    int divisions,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GoopText(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white70)),
            GoopText(displayValue, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
        SizedBox(
          height: 32,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
              activeTrackColor: color,
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
              valueIndicatorColor: color,
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
    );
  }
}

/// Quick particle preset strip — a horizontally scrollable row of
/// preset chips at the bottom of the theme picker. Tapping a chip
/// immediately changes the particle effect visible behind the picker.
/// Shows the theme's default preset first (highlighted) so the user
/// can quickly restore the curated pairing.
class _QuickParticleStrip extends StatelessWidget {
  final AppThemeMode activeMode;
  final ParticlePreset currentPreset;
  final ValueChanged<ParticlePreset> onPreset;

  const _QuickParticleStrip({
    required this.activeMode,
    required this.currentPreset,
    required this.onPreset,
  });

  @override
  Widget build(BuildContext context) {
    final themeDefault = kThemeParticleDefaults[activeMode] ??
        ParticlePreset.gungeonDust;

    // Show the theme's default first, then a curated subset of the rest.
    // ponytail: not all 18 presets — that's overwhelming. Show the
    // theme default + 7 hand-picked complementary presets, deduped.
    final seen = <ParticlePreset>{};
    final curated = <ParticlePreset>[
      themeDefault,
      ParticlePreset.cosmicStars,
      ParticlePreset.forgeEmbers,
      ParticlePreset.frostShards,
      ParticlePreset.unicornSparkles,
      ParticlePreset.goldenSparkle,
      ParticlePreset.cursedSmoke,
      ParticlePreset.bulletHell,
    ].where((p) => seen.add(p)).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: curated.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final preset = curated[i];
            final isActive = preset == currentPreset ||
                (currentPreset == ParticlePreset.gungeonDust &&
                    preset == themeDefault);
            final f = AppTheme.flairFor(activeMode);
            return GestureDetector(
              onTap: () => onPreset(preset),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? f.primary.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? f.primary.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.1),
                    width: isActive ? 1.5 : 1.0,
                  ),
                ),
                child: Center(
                  child: GoopText(
                    preset.label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      color: isActive
                          ? f.primary
                          : Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A single full-screen theme page. The background is the theme's
/// scaffold colour, so the user immediately feels the palette.
/// Compact horizontal theme card — a small tappable card showing the
/// theme's color swatches and name. Transparent background so particles
/// show through from the ThemeOverlay behind it.
class _CompactThemeCard extends StatelessWidget {
  final AppThemeMode mode;
  final bool isActive;
  final bool isFocused;
  final VoidCallback onTap;

  const _CompactThemeCard({
    required this.mode,
    required this.isActive,
    required this.isFocused,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnicorn = mode == AppThemeMode.unicorn;
    final hasRemix = kThemeRemixes.containsKey(mode);
    final listenable = isUnicorn
        ? AppTheme.unicornPaletteNotifier
        : hasRemix
            ? AppTheme.remixNotifier
            : null;
    if (listenable != null) {
      return ListenableBuilder(
        listenable: listenable,
        builder: (context, _) => _buildCard(context),
      );
    }
    return _buildCard(context);
  }

  Widget _buildCard(BuildContext context) {
    final f = AppTheme.flairFor(mode);
    final sf = Responsive.factor(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 6 * sf, vertical: 4),
        decoration: BoxDecoration(
          // Transparent — particles show through
          color: f.card.withValues(alpha: isFocused ? 0.35 : 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isFocused
                ? f.primary.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.08),
            width: isFocused ? 2.0 : 1.0,
          ),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: f.primary.withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Color swatch row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _swatch(f.scaffold, radiusLeft: true),
                _swatch(f.primary),
                _swatch(f.secondary),
                _swatch(f.headlineStat, radiusRight: true),
              ],
            ),
            const SizedBox(height: 6),
            // Theme name
            GoopText(
              mode.label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11 * sf,
                fontWeight: FontWeight.w900,
                color: isFocused ? f.headlineStat : Colors.white.withValues(alpha: 0.6),
                letterSpacing: 1.2,
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: 2),
              GoopText(
                '✓ ACTIVE',
                style: TextStyle(
                  fontSize: 8 * sf,
                  fontWeight: FontWeight.w900,
                  color: f.primary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _swatch(Color color, {bool radiusLeft = false, bool radiusRight = false}) {
    return Container(
      width: 22,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.horizontal(
          left: radiusLeft ? const Radius.circular(5) : Radius.zero,
          right: radiusRight ? const Radius.circular(5) : Radius.zero,
        ),
      ),
    );
  }
}

/// Compact theme details — name, tagline, and apply button in a
/// single compact row below the card carousel. Transparent background.
class _CompactThemeDetails extends StatelessWidget {
  final AppThemeMode mode;
  final bool isActive;
  final VoidCallback onApply;

  const _CompactThemeDetails({
    required this.mode,
    required this.isActive,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final isUnicorn = mode == AppThemeMode.unicorn;
    final hasRemix = kThemeRemixes.containsKey(mode);
    final listenable = isUnicorn
        ? AppTheme.unicornPaletteNotifier
        : hasRemix
            ? AppTheme.remixNotifier
            : null;
    if (listenable != null) {
      return ListenableBuilder(
        listenable: listenable,
        builder: (context, _) => _build(context),
      );
    }
    return _build(context);
  }

  Widget _build(BuildContext context) {
    final f = AppTheme.flairFor(mode);
    final sf = Responsive.factor(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          // Name + tagline + apply button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GoopText(
                      mode.label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16 * sf,
                        fontWeight: FontWeight.w900,
                        color: f.headlineStat,
                        letterSpacing: 2,
                        height: 1.1,
                        shadows: f.numberGlowColor != null
                            ? [Shadow(color: f.numberGlowColor!, blurRadius: 10)]
                            : null,
                      ),
                    ),
                    GoopText(
                      mode.tagline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10 * sf,
                        fontWeight: FontWeight.w500,
                        color: f.secondary.withValues(alpha: 0.7),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 38 * sf,
                child: FilledButton(
                  onPressed: onApply,
                  style: FilledButton.styleFrom(
                    backgroundColor: f.primary,
                    foregroundColor:
                        f.primary.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: GoopText(
                    isActive ? '✓ Active' : 'Apply',
                    style: TextStyle(
                      fontSize: 12 * sf,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Palette / remix selector — compact, only for themes that have it
          if (mode == AppThemeMode.unicorn)
            ListenableBuilder(
              listenable: AppTheme.unicornPaletteNotifier,
              builder: (context, _) {
                final active = AppTheme.unicornPalette;
                return _PaletteSelector(
                  flair: f,
                  items: UnicornPalette.values.map((p) {
                    final pf = p.flair;
                    return (
                      label: p.label,
                      colors: [pf.scaffold, pf.primary, pf.headlineStat],
                    );
                  }).toList(),
                  activeIndex: active.index,
                  onTap: (i) {
                    AppTheme.setUnicornPalette(UnicornPalette.values[i]);
                    Haptics.selection();
                  },
                );
              },
            )
          else if (kThemeRemixes.containsKey(mode))
            ListenableBuilder(
              listenable: AppTheme.remixNotifier,
              builder: (context, _) {
                final remixes = kThemeRemixes[mode]!;
                final active = AppTheme.remixFor(mode);
                return _PaletteSelector(
                  flair: f,
                  items: remixes.map((r) {
                    final rf = r.flair;
                    return (
                      label: r.label,
                      colors: rf != null
                          ? [rf.scaffold, rf.primary, rf.headlineStat]
                          : [f.scaffold, f.primary, f.headlineStat],
                    );
                  }).toList(),
                  activeIndex: active,
                  onTap: (i) {
                    AppTheme.setRemix(mode, i);
                    Haptics.selection();
                  },
                );
              },
            ),
          // Custom theme editor button
          if (mode == AppThemeMode.custom)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: OutlinedButton.icon(
                onPressed: () async {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppTheme.flair.card,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    builder: (sheetCtx) => const _CustomThemeEditorSheet(),
                  );
                  if (context.mounted) AppTheme.refresh();
                },
                icon: Icon(Icons.tune_rounded, size: 16, color: f.primary),
                label: GoopText(
                  'Customize Colors',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: f.primary,
                    letterSpacing: 0.4,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: f.primary.withValues(alpha: 0.5), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(f.chipRadius),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


/// Curated Gungeon color palette for the custom theme editor.
/// 24 deep, saturated colors that work well as scaffold/card/primary/secondary.
const _kCustomColorPalette = <Color>[
  Color(0xFF0D0C0B), Color(0xFF1A1A1A), Color(0xFF1A101F), Color(0xFF0F0A14),
  Color(0xFF0A030C), Color(0xFF080510), Color(0xFF050308), Color(0xFF0A0F0E),
  Color(0xFF0E1018), Color(0xFF120D0A), Color(0xFF0D110E), Color(0xFF0A1118),
  Color(0xFFFF69B4), Color(0xFFFF1493), Color(0xFFE91E63), Color(0xFFFF4500),
  Color(0xFFFFD700), Color(0xFF00E5FF), Color(0xFF00E676), Color(0xFF7C4DFF),
  Color(0xFFB71C1C), Color(0xFF1B5E20), Color(0xFF1A237E), Color(0xFF4A148C),
];

/// Simple HSV color picker dialog — hue/saturation/lightness sliders.
class _HsvColorPickerDialog extends StatefulWidget {
  final Color initial;
  const _HsvColorPickerDialog({required this.initial});

  @override
  State<_HsvColorPickerDialog> createState() => _HsvColorPickerDialogState();
}

class _HsvColorPickerDialogState extends State<_HsvColorPickerDialog> {
  late double _hue;
  late double _saturation;
  late double _value;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initial);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
  }

  Color get _color => HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.flair.card,
      title: const Text('Pick Color', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color preview
          Container(
            width: double.infinity,
            height: 48,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24, width: 1.5),
            ),
          ),
          // Hue slider
          _HueSlider(
            value: _hue,
            onChanged: (v) => setState(() => _hue = v),
          ),
          const SizedBox(height: 12),
          // Saturation slider
          _SatSlider(
            hue: _hue,
            value: _saturation,
            onChanged: (v) => setState(() => _saturation = v),
          ),
          const SizedBox(height: 12),
          // Value slider
          _ValSlider(
            hue: _hue,
            saturation: _saturation,
            value: _value,
            onChanged: (v) => setState(() => _value = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _color),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class _HueSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _HueSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hue', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70)),
        Slider(
          value: value,
          min: 0,
          max: 360,
          activeColor: HSVColor.fromAHSV(1.0, value, 1.0, 1.0).toColor(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SatSlider extends StatelessWidget {
  final double hue;
  final double value;
  final ValueChanged<double> onChanged;
  const _SatSlider({required this.hue, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Saturation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70)),
        Slider(
          value: value,
          activeColor: HSVColor.fromAHSV(1.0, hue, value, 1.0).toColor(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ValSlider extends StatelessWidget {
  final double hue;
  final double saturation;
  final double value;
  final ValueChanged<double> onChanged;
  const _ValSlider({required this.hue, required this.saturation, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lightness', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70)),
        Slider(
          value: value,
          activeColor: HSVColor.fromAHSV(1.0, hue, saturation, value).toColor(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Font picker for the custom theme editor.
class _FontSlotPicker extends StatelessWidget {
  final AppFont current;
  final ValueChanged<AppFont> onPicked;
  const _FontSlotPicker({required this.current, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FONT TYPE',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.4),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AppFont.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final font = AppFont.values[i];
                final selected = font == current;
                return GestureDetector(
                  onTap: () {
                    onPicked(font);
                    Haptics.selection();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? Colors.white70 : Colors.white12,
                        width: selected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        font.label,
                        style: font.textStyle.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: selected ? Colors.white : Colors.white54,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomThemeEditorSheet extends StatefulWidget {
  const _CustomThemeEditorSheet();

  @override
  State<_CustomThemeEditorSheet> createState() => _CustomThemeEditorSheetState();
}

class _CustomThemeEditorSheetState extends State<_CustomThemeEditorSheet> {
  late CustomThemeData _data;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _data = await CustomThemeData.loadAsync();
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save() async {
    await CustomThemeData.save(_data);
    AppTheme.setCustomThemeData(_data);
    if (mounted) {
      AppTheme.refresh();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const GoopText(
                  'CUSTOMIZE THEME',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _data = CustomThemeData.random());
                    Haptics.selection();
                  },
                  icon: const Icon(Icons.casino, size: 16),
                  label: const GoopText('Randomize', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ColorSlotPicker(
              label: 'Background',
              current: _data.scaffold,
              onPicked: (c) => setState(() => _data = _data.copyWith(scaffold: c)),
            ),
            _ColorSlotPicker(
              label: 'Card',
              current: _data.card,
              onPicked: (c) => setState(() => _data = _data.copyWith(card: c)),
            ),
            _ColorSlotPicker(
              label: 'Primary',
              current: _data.primary,
              onPicked: (c) => setState(() => _data = _data.copyWith(primary: c)),
            ),
            _ColorSlotPicker(
              label: 'Secondary',
              current: _data.secondary,
              onPicked: (c) => setState(() => _data = _data.copyWith(secondary: c)),
            ),
            _ColorSlotPicker(
              label: 'Accent / Headline',
              current: _data.headlineStat,
              onPicked: (c) => setState(() => _data = _data.copyWith(headlineStat: c)),
            ),
            _ColorSlotPicker(
              label: 'Bullet',
              current: _data.bulletColor,
              onPicked: (c) => setState(() => _data = _data.copyWith(bulletColor: c)),
            ),
            const SizedBox(height: 16),

            // Font type picker
            _FontSlotPicker(
              current: _data.font,
              onPicked: (f) => setState(() => _data = _data.copyWith(font: f)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: FilledButton(
                onPressed: _save,
                child: const GoopText(
                  'Save Theme',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single color slot with a horizontal scrollable row of swatches.
class _ColorSlotPicker extends StatelessWidget {
  final String label;
  final Color current;
  final ValueChanged<Color> onPicked;
  const _ColorSlotPicker({required this.label, required this.current, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GoopText(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: current,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _kCustomColorPalette.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                // Last item: custom color picker button
                if (i == _kCustomColorPalette.length) {
                  return GestureDetector(
                    onTap: () async {
                      final picked = await showDialog<Color>(
                        context: context,
                        builder: (_) => _HsvColorPickerDialog(initial: current),
                      );
                      if (picked != null) {
                        onPicked(picked);
                        Haptics.selection();
                      }
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white30,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(Icons.add, size: 18, color: Colors.white70),
                    ),
                  );
                }
                final c = _kCustomColorPalette[i];
                final selected = c.toARGB32() == current.toARGB32();
                return GestureDetector(
                  onTap: () {
                    onPicked(c);
                    Haptics.selection();
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? Colors.white : Colors.white12,
                        width: selected ? 2.0 : 1.0,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// _PaletteSelector — Big tappable palette cards with color swatches.
// Replaces the old small _RemixChips with something much more
// tactile and visual.
// ═══════════════════════════════════════════════════════════════
class _PaletteSelector extends StatelessWidget {
  final ThemeFlair flair;
  final List<({String label, List<Color> colors})> items;
  final int activeIndex;
  final ValueChanged<int> onTap;

  const _PaletteSelector({
    required this.flair,
    required this.items,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isActive = i == activeIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isActive
                    ? flair.primary.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? flair.primary
                      : Colors.white.withValues(alpha: 0.08),
                  width: isActive ? 2.0 : 1.0,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: flair.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Color swatch stack
                  Row(
                    children: [
                      for (int c = 0; c < item.colors.length; c++) ...[
                        if (c > 0) const SizedBox(width: 2),
                        Container(
                          width: 14,
                          height: 28,
                          decoration: BoxDecoration(
                            color: item.colors[c],
                            borderRadius: BorderRadius.horizontal(
                              left: c == 0 ? const Radius.circular(3) : Radius.zero,
                              right: c == item.colors.length - 1
                                  ? const Radius.circular(3)
                                  : Radius.zero,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(width: 8),
                  // Label
                  GoopText(
                    item.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                      color: isActive
                          ? flair.primary
                          : Colors.white.withValues(alpha: 0.65),
                      letterSpacing: 0.4,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 5),
                    Icon(Icons.check_circle_rounded, size: 13, color: flair.primary),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Particle color schema strip — a horizontally scrollable row of 16
/// named color palette pills. Each pill shows a mini color preview
/// (3-4 dots) + the schema name. Tapping immediately overrides the
/// particle colors for the current preset. Works with ALL themes.
class _ParticleColorSchemaStrip extends StatelessWidget {
  final ParticleColorSchema currentSchema;
  final ValueChanged<ParticleColorSchema> onSchema;

  const _ParticleColorSchemaStrip({
    required this.currentSchema,
    required this.onSchema,
  });

  @override
  Widget build(BuildContext context) {
    final schemas = ParticleColorSchema.values;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: schemas.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final schema = schemas[i];
            final isActive = schema == currentSchema;
            final colors = schema.colors;
            return GestureDetector(
              onTap: () => onSchema(schema),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.08),
                    width: isActive ? 1.4 : 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mini color preview dots
                    if (colors != null) ...[
                      ...colors.take(3).map((c) => Padding(
                            padding: const EdgeInsets.only(right: 3),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: c,
                                boxShadow: [
                                  BoxShadow(
                                    color: c.withValues(alpha: 0.5),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          )),
                    ] else if (schema == ParticleColorSchema.themeMatch) ...[
                      // Theme match — show theme primary + secondary dots
                      Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.flair.primary,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.flair.secondary,
                          ),
                        ),
                      ),
                    ] else
                      // Preset default — show a small dash icon
                      const Padding(
                        padding: EdgeInsets.only(right: 3),
                        child: Icon(Icons.auto_awesome, size: 10,
                            color: Colors.white54),
                      ),
                    const SizedBox(width: 2),
                    GoopText(
                      schema.label,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight:
                            isActive ? FontWeight.w800 : FontWeight.w600,
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 120.ms, delay: 20.ms * i);
          },
        ),
      ),
    );
  }
}

/// Particle speed selector — 5 discrete speed pills from Very Slow to
/// Very Fast. Normal is the default (middle). Tapping immediately
/// changes the particle animation speed visible behind the picker.
class _ParticleSpeedStrip extends StatelessWidget {
  final ParticleSpeed currentSpeed;
  final ValueChanged<ParticleSpeed> onSpeed;

  const _ParticleSpeedStrip({
    required this.currentSpeed,
    required this.onSpeed,
  });

  @override
  Widget build(BuildContext context) {
    final speeds = ParticleSpeed.values;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: SizedBox(
        height: 32,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(
            decelerationRate: ScrollDecelerationRate.fast,
          ),
          itemCount: speeds.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final speed = speeds[i];
            final isActive = speed == currentSpeed;
            // Speed icon — more bars = faster
            final icon = switch (speed) {
              ParticleSpeed.verySlow => Icons.speed,
              ParticleSpeed.slow => Icons.speed,
              ParticleSpeed.normal => Icons.speed,
              ParticleSpeed.fast => Icons.speed,
              ParticleSpeed.veryFast => Icons.speed,
            };
            return GestureDetector(
              onTap: () => onSpeed(speed),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.08),
                    width: isActive ? 1.4 : 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 12,
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 4),
                    GoopText(
                      speed.label,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight:
                            isActive ? FontWeight.w800 : FontWeight.w600,
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 120.ms, delay: 20.ms * i);
          },
        ),
      ),
    );
  }
}
