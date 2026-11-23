part of '../experience_studio_screen.dart';

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
              _StepLabel('GLOW STYLE'),
              const SizedBox(height: 8),
              _GlowStyleRow(currentIndex: prefs.glowStyleIndex),
              const SizedBox(height: 14),
              _StepLabel('GLOW COLOR'),
              const SizedBox(height: 8),
              _GlowPickRow(color: prefs.glowColor),
              const SizedBox(height: 10),
              _GlowQuickRow(currentIndex: prefs.glowColorIndex),
              const SizedBox(height: 18),
              _StepLabel('DEPTH'),
              const SizedBox(height: 8),
              _StudioSlider(
                'Vignette',
                '${(prefs.vignetteIntensity * 100).toStringAsFixed(0)}%',
                prefs.vignetteIntensity,
                0.0,
                1.5,
                15,
                flair.headlineStat,
                (v) => VisualPrefs.setVignetteIntensity(v),
              ),
              const SizedBox(height: 10),
              _StudioSlider(
                'Film Grain',
                '${(prefs.grainIntensity * 100).toStringAsFixed(0)}%',
                prefs.grainIntensity,
                0.0,
                1.0,
                20,
                flair.headlineStat,
                (v) => VisualPrefs.setGrainIntensity(v),
              ),
              const SizedBox(height: 10),
              _ShaderChip(
                label: 'CINEMA BARS',
                on: prefs.cinematicBars,
                onTap: () {
                  VisualPrefs.setCinematicBars(!prefs.cinematicBars);
                  Haptics.selection();
                },
              ),
              const SizedBox(height: 18),
              _StepLabel('ATMOSPHERE'),
              const SizedBox(height: 8),
              // Procedural backdrop scenes — each is a bespoke painter
              // tinted by the active palette. Two rows of three keeps
              // the chips tappable on phones.
              for (var row = 0; row < 2; row++) ...[
                Row(
                  children: [
                    for (
                      var i = row * 3;
                      i < (row * 3 + 3).clamp(0, AmbientKind.values.length);
                      i++
                    )
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _ShaderChip(
                            label: AmbientKind.values[i].label,
                            on: prefs.ambientKindIndex == i,
                            onTap: () {
                              VisualPrefs.setAmbientKindIndex(i);
                              Haptics.selection();
                            },
                          ),
                        ),
                      ),
                  ],
                ),
                if (row == 0) const SizedBox(height: 8),
              ],
              const SizedBox(height: 6),
              GoopText(
                'procedural scenes behind everything · stacks with liquid + shader',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 18),
              _StepLabel('SHADER'),
              const SizedBox(height: 8),
              // The shader layer existed in the engine + prefs but had
              // zero UI — surfacing it (hidden feature the user asked
              // about).
              Row(
                children: [
                  for (final (label, enabled, preset) in [
                    ('OFF', false, ShaderPreset.digitalRain),
                    ('FOG', true, ShaderPreset.darkNeonFog),
                    ('RAIN', true, ShaderPreset.digitalRain),
                  ])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _ShaderChip(
                          label: label,
                          on:
                              prefs.shaderEnabled == enabled &&
                              (!enabled || prefs.shaderPreset == preset),
                          onTap: () {
                            VisualPrefs.setShaderEnabled(enabled);
                            if (enabled) {
                              VisualPrefs.setShaderPreset(preset);
                            }
                            Haptics.selection();
                          },
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              _StepLabel('LIQUID TANK'),
              const SizedBox(height: 8),
              // Rising bubbly fill behind all content — blood/venom/
              // umbra tints, or brass shells that slide with tilt.
              Row(
                children: [
                  for (final kind in LiquidKind.values)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _ShaderChip(
                          label: kind.label,
                          on: prefs.liquidKindIndex == kind.index,
                          onTap: () {
                            VisualPrefs.setLiquidKindIndex(kind.index);
                            Haptics.selection();
                          },
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              GoopText(
                'slow fill behind everything · shells slide with tilt',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 18),
              _StepLabel('ATMOSPHERE LOAD'),
              const SizedBox(height: 8),
              _AtmosphereLoadRow(load: prefs.ambienceLoad),
              const SizedBox(height: 18),
              _StepLabel('TAP FX'),
              const SizedBox(height: 8),
              // Sparkles + ripple are VisualPrefs picks (saved with the
              // preset); haptics is a device-level Haptics.intensity —
              // it gets its own row.
              Row(
                children: [
                  Expanded(
                    child: _ShaderChip(
                      label: 'SPARKLES',
                      on: prefs.tapSparkles,
                      onTap: () {
                        VisualPrefs.setTapSparkles(!prefs.tapSparkles);
                        Haptics.selection();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ShaderChip(
                      label: 'RIPPLE',
                      on: prefs.tapRipple,
                      onTap: () {
                        VisualPrefs.setTapRipple(!prefs.tapRipple);
                        Haptics.selection();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const _HapticsChips(),
              const SizedBox(height: 6),
              GoopText(
                'sparkles = tap burst · ripple = expanding ring · haptics = vibration',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Haptics intensity chips — OFF / LIGHT / FULL. Reads the static
/// [Haptics.intensity] (persisted under its own prefs key, not part of
/// VisualPrefs) and setStates locally so the highlight tracks taps.
class _HapticsChips extends StatefulWidget {
  const _HapticsChips();

  @override
  State<_HapticsChips> createState() => _HapticsChipsState();
}

class _HapticsChipsState extends State<_HapticsChips> {
  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final current = Haptics.intensity;
    return Row(
      children: [
        for (final (label, level) in [
          ('OFF', HapticsIntensity.off),
          ('LITE', HapticsIntensity.light),
          ('FULL', HapticsIntensity.full),
        ])
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Haptics.setIntensity(level);
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color:
                        level == current
                            ? flair.primary.withValues(alpha: 0.16)
                            : Colors.white.withValues(alpha: 0.04),
                    borderRadius: const BorderRadius.all(Radii.sm),
                    border: Border.all(
                      color:
                          level == current
                              ? flair.primary
                              : Colors.white.withValues(alpha: 0.15),
                      width: level == current ? 1.4 : 0.8,
                    ),
                  ),
                  child: Center(
                    child: GoopText(
                      label,
                      style: TextStyle(
                        fontSize: FontSizes.labelSmall,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color:
                            level == current
                                ? flair.primary
                                : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Animated glow styles — THEME follows the active theme's flair; the
/// rest override it. AmbientGlow renders these live.
class _GlowStyleRow extends StatelessWidget {
  const _GlowStyleRow({required this.currentIndex});
  final int currentIndex;

  static const _labels = [
    'THEME',
    'ORBIT',
    'EMBER',
    'HALO',
    'DRIP',
    'PRISM',
    'RIPPLE',
  ];

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    return Row(
      children: [
        for (var i = -1; i < GlowStyle.values.length; i++)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Haptics.selection();
                VisualPrefs.setGlowStyleIndex(i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color:
                      i == currentIndex
                          ? flair.primary.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        i == currentIndex
                            ? flair.primary.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.1),
                    width: i == currentIndex ? 1.5 : 1.0,
                  ),
                ),
                child: Center(
                  child: GoopText(
                    _labels[i + 1],
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color:
                          i == currentIndex
                              ? flair.primary
                              : Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Custom-color picker row — the resolved glow swatch opens the full
/// color picker (custom color wins over the curated palette).
class _GlowPickRow extends StatelessWidget {
  const _GlowPickRow({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final c = await _PaletteColorSheet.show(context, color);
        if (c == null || !context.mounted) return;
        Haptics.selection();
        await VisualPrefs.setGlowColor(c);
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
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GoopText(
                'CUSTOM COLOR',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
            Icon(
              Icons.colorize_rounded,
              size: 14,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact single-row quick picks — the 12 original curated colors.
/// Tapping one clears any custom color.
class _GlowQuickRow extends StatelessWidget {
  const _GlowQuickRow({required this.currentIndex});
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    const shown = 12;
    return SizedBox(
      height: 26,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: shown.clamp(0, VisualPrefs.glowColors.length),
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = VisualPrefs.glowColors[i];
          final isSelected = i == currentIndex;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Haptics.selection();
              VisualPrefs.setGlowColorIndex(i);
            },
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.15),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: c.withValues(alpha: 0.7),
                            blurRadius: 8,
                          ),
                        ]
                        : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Atmosphere load meter — counts the heavy animated backdrop layers
/// (scene + liquid + shader + particles) so stacking all four doesn't
/// silently degrade into visual mud. At BUSY/MUDDLED a THIN STACK chip
/// appears: one tap kills the two pure-noise layers (shader + scene)
/// and keeps the identity picks.
class _AtmosphereLoadRow extends StatelessWidget {
  const _AtmosphereLoadRow({required this.load});
  final int load;

  static const _words = ['CLEAR', 'BALANCED', 'BUSY', 'MUDDLED'];

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final word = _words[load.clamp(0, _words.length - 1)];
    final hot = load >= 3;
    final dotColor = hot ? const Color(0xFFFFB300) : flair.primary;
    return Row(
      children: [
        for (var i = 0; i < 4; i++)
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  i < load
                      ? dotColor.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color:
                    i < load ? dotColor : Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
        Expanded(
          child: GoopText(
            word,
            style: TextStyle(
              fontSize: FontSizes.labelSmall,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: hot ? const Color(0xFFFFB300) : Colors.white54,
            ),
          ),
        ),
        if (hot)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              VisualPrefs.calmAmbience();
              Haptics.selection();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withValues(alpha: 0.14),
                borderRadius: const BorderRadius.all(Radii.sm),
                border: Border.all(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.6),
                  width: 1.1,
                ),
              ),
              child: GoopText(
                'THIN STACK',
                style: TextStyle(
                  fontSize: FontSizes.labelSmall,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: const Color(0xFFFFB300),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ShaderChip extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _ShaderChip({
    required this.label,
    required this.on,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              on
                  ? flair.primary.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.04),
          borderRadius: const BorderRadius.all(Radii.sm),
          border: Border.all(
            color: on ? flair.primary : Colors.white.withValues(alpha: 0.15),
            width: on ? 1.4 : 0.8,
          ),
        ),
        child: Center(
          child: GoopText(
            label,
            style: TextStyle(
              fontSize: FontSizes.labelSmall,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: on ? flair.primary : Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
