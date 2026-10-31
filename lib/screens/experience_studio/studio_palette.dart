part of '../experience_studio_screen.dart';

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
            ? Skeuo.inkIf(Colors.green)
            : isPreview
            ? nameColor
            : Colors.white.withValues(alpha: 0.08);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
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
                      SizedBox(height: 2),
                      GoopText(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          letterSpacing: 0.8,
                          color: Colors.white.withValues(alpha: 0.5),
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
                      color: Skeuo.inkIf(Colors.green).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Skeuo.inkIf(Colors.green).withValues(alpha: 0.6),
                      ),
                    ),
                    child: GoopText(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: Skeuo.inkIf(Colors.green),
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
        // Labels shrink to fit — 'CANVAS'/'SECOND' wrapped at 320dp
        // without this.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: GoopText(
            label,
            style: TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Colors.white.withValues(alpha: 0.5),
            ),
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
      behavior: HitTestBehavior.opaque,
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
                color: Colors.white.withValues(alpha: 0.5),
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
      behavior: HitTestBehavior.opaque,
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
      behavior: HitTestBehavior.opaque,
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
                    ? Skeuo.inkIf(Colors.green)
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
                    (_, _, _) => DecoratedBox(
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
                    color: Skeuo.inkIf(Colors.green),
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
      behavior: HitTestBehavior.opaque,
      onTap: item.onTap,
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
