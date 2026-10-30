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
