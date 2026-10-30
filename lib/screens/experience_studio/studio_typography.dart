part of '../experience_studio_screen.dart';

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
