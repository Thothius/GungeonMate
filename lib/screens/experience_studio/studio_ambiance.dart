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
            ],
          ),
        );
      },
    );
  }
}

/// Animated glow styles — THEME follows the active theme's flair; the
/// rest override it. AmbientGlow renders these live.
class _GlowStyleRow extends StatelessWidget {
  const _GlowStyleRow({required this.currentIndex});
  final int currentIndex;

  static const _labels = ['THEME', 'ORBIT', 'EMBER', 'HALO', 'DRIP'];

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    return Row(
      children: [
        for (var i = -1; i < GlowStyle.values.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: () {
                Haptics.selection();
                VisualPrefs.setGlowStyleIndex(i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 8),
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
      onTap: () async {
        final c = await showColorPickerDialog(
          context,
          initialColor: color,
          title: 'GLOW COLOR',
        );
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
