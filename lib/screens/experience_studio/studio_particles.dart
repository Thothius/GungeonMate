part of '../experience_studio_screen.dart';

class _ParticlesStep extends StatelessWidget {
  const _ParticlesStep();

  /// Horizontal scroller of the 12 curated looks — tap applies the
  /// whole config via [VisualPrefs.applyParticleLook].
  Widget _looksRow(VisualPrefs prefs) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: kParticleLooks.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, i) {
        final look = kParticleLooks[i];
        return SizedBox(
          width: 118,
          child: _LookTile(
            look: look,
            active: VisualPrefs.matchesParticleLook(prefs, look),
            onTap: () {
              VisualPrefs.applyParticleLook(look);
              Haptics.selection();
            },
          ),
        );
      },
    );
  }

  /// "ANY SPRITE…" entry tile — opens the searchable picker over all
  /// bundled gun/item sprites. Shows the current pick's thumbnail.
  Widget _anySpriteRow(BuildContext context, VisualPrefs prefs) {
    final hasSprite = prefs.particleSpritePath.isNotEmpty;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Haptics.selection();
        _SpritePickerSheet.show(context);
      },
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color:
              hasSprite
                  ? AppTheme.flair.primary.withValues(alpha: 0.14)
                  : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                hasSprite
                    ? AppTheme.flair.primary
                    : Colors.white.withValues(alpha: 0.15),
            width: hasSprite ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child:
                  hasSprite
                      ? Image.asset(
                        prefs.particleSpritePath,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (_, _, _) => Icon(
                              Icons.broken_image_outlined,
                              size: 18,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                      )
                      : Icon(
                        Icons.image_search_rounded,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GoopText(
                    hasSprite ? 'CUSTOM SPRITE' : 'ANY SPRITE…',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color:
                          hasSprite
                              ? AppTheme.flair.primary
                              : Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  GoopText(
                    hasSprite
                        ? prefs.particleSpritePath
                            .split('/')
                            .last
                            .replaceAll('.webp', '')
                            .replaceAll('_', ' ')
                        : 'search all 500+ gun & item sprites',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 7.5,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }

  /// Uniform 4-across tile grid for the shape types — equal cells,
  /// glyph + label, short row padded so widths stay consistent.
  Widget _typeGrid(VisualPrefs prefs) {
    const cols = 4;
    final types = ParticleType.values;
    return Column(
      children: [
        for (var r = 0; r * cols < types.length; r++)
          Padding(
            padding: EdgeInsets.only(
              bottom: (r + 1) * cols < types.length ? 8 : 0,
            ),
            child: Row(
              children: [
                for (var c = 0; c < cols; c++) ...[
                  Expanded(
                    child:
                        r * cols + c < types.length
                            ? _ParticleTypeTile(
                              type: types[r * cols + c],
                              // Sprite modes override typed shapes —
                              // don't highlight a stale type pick.
                              active:
                                  r * cols + c == prefs.particleTypeIndex &&
                                  prefs.particleItemIcon < 0 &&
                                  prefs.particleSpritePath.isEmpty,
                              onTap: () {
                                VisualPrefs.setParticleTypeIndex(r * cols + c);
                                // Typed shapes win — clear sprite modes
                                // so the pick is actually visible.
                                VisualPrefs.setParticleItemIcon(-1);
                                VisualPrefs.setParticleSpritePath('');
                                Haptics.selection();
                              },
                            )
                            : const SizedBox(),
                  ),
                  if (c < cols - 1) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VisualPrefs>(
      valueListenable: VisualPrefs.notifier,
      builder: (context, prefs, _) {
        return CustomScrollView(
          slivers: [
            // Sticky header: enable toggle + live preview
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyParticleHeader(prefs: prefs),
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
                  // Curated one-tap looks — 12 hand-tuned combos that
                  // cover every particle type + the sprite showcase.
                  // Tapping applies the whole config; knobs below still
                  // fine-tune afterwards.
                  _StepLabel('LOOKS'),
                  const SizedBox(height: 4),
                  GoopText(
                    'one tap = full particle config',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(height: 66, child: _looksRow(prefs)),
                  // Honest state — after hand-tweaking a look (or
                  // picking NONE) no tile is highlighted; say so.
                  if (prefs.particleSpritePath.isEmpty &&
                      prefs.particleItemIcon < 0 &&
                      !kParticleLooks.any(
                        (l) => VisualPrefs.matchesParticleLook(prefs, l),
                      ))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: GoopText(
                        'CUSTOM — knobs below define this look',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Typed particle system — shapes × per-theme
                  // schemas × physics flags.
                  _StepLabel('COUNT'),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: prefs.particleCount.toDouble(),
                          min: 0,
                          max: 200,
                          divisions: 100,
                          label: '${prefs.particleCount}',
                          onChanged:
                              (v) => VisualPrefs.setParticleCount(v.round()),
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: GoopText(
                          '${prefs.particleCount}',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: FontSizes.labelMedium,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _StepLabel('TYPE'),
                  const SizedBox(height: 8),
                  _typeGrid(prefs),
                  const SizedBox(height: 16),
                  _StepLabel('ITEM ICONS'),
                  const SizedBox(height: 4),
                  GoopText(
                    'float real game items instead of shapes',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _itemIconGrid(prefs),
                  const SizedBox(height: 12),
                  _anySpriteRow(context, prefs),
                  const SizedBox(height: 16),
                  _StepLabel('PHYSICS'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _PhysicsToggle(
                          label: 'BOUNCE',
                          on: prefs.particleBounce,
                          onTap: () {
                            VisualPrefs.setParticleBounce(
                              !prefs.particleBounce,
                            );
                            Haptics.selection();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PhysicsToggle(
                          label: 'CHAOS',
                          on: prefs.particleChaos,
                          onTap: () {
                            VisualPrefs.setParticleChaos(!prefs.particleChaos);
                            Haptics.selection();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PhysicsToggle(
                          label: 'TILT',
                          on: prefs.particleTouch,
                          onTap: () {
                            VisualPrefs.setParticleTouch(!prefs.particleTouch);
                            Haptics.selection();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PhysicsToggle(
                          label: 'LINKS',
                          on: prefs.particleLineLinks,
                          onTap: () {
                            VisualPrefs.setParticleLineLinks(
                              !prefs.particleLineLinks,
                            );
                            Haptics.selection();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _StepLabel('SIZE & SPEED'),
                  const SizedBox(height: 8),
                  _MiniSlider(
                    label: 'SIZE',
                    value: prefs.particleSizeScale,
                    min: 0.3,
                    max: 2.0,
                    display: '${(prefs.particleSizeScale * 100).round()}%',
                    onChanged: (v) => VisualPrefs.setParticleSizeScale(v),
                  ),
                  const SizedBox(height: 4),
                  _MiniSlider(
                    label: 'OPACITY',
                    value: prefs.particleOpacity,
                    min: 0.0,
                    max: 1.0,
                    display: '${(prefs.particleOpacity * 100).round()}%',
                    onChanged: (v) => VisualPrefs.setParticleOpacity(v),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final sp in ParticleSpeed.values)
                        _GlowFxChip(
                          label: sp.label.toUpperCase(),
                          on: prefs.particleSpeed == sp,
                          onTap: () {
                            VisualPrefs.setParticleSpeed(sp);
                            Haptics.selection();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _StepLabel('COLOR'),
                  const SizedBox(height: 8),
                  // 18 global palettes — horizontal scroller so every
                  // theme gets the full set (was ~3 per-theme schemas).
                  SizedBox(
                    height: 62,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: kGlobalParticlePalettes.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        return SizedBox(
                          width: 76,
                          child: _SchemaChip(
                            schema: kGlobalParticlePalettes[i],
                            active: i == prefs.particleSchemaIndex,
                            onTap: () {
                              VisualPrefs.setParticleSchemaIndex(i);
                              Haptics.selection();
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StepLabel('TYPE GLOW'),
                  const SizedBox(height: 8),
                  // Was a hidden pref — surface it. AUTO lets each type
                  // keep its own glow (none = auto since the overlay fix).
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (label, fx) in [
                        ('AUTO', GlowEffect.none),
                        ('SMOKEY', GlowEffect.smokey),
                        ('PULSE', GlowEffect.pulse),
                        ('NEON', GlowEffect.neon),
                        ('CURSED', GlowEffect.cursed),
                        ('RIPPLE', GlowEffect.ripple),
                        ('AURORA', GlowEffect.aurora),
                        ('EMBER', GlowEffect.ember),
                        ('SPECTRAL', GlowEffect.spectral),
                        ('PLASMA', GlowEffect.plasma),
                        ('PRISM', GlowEffect.prism),
                      ])
                        _GlowFxChip(
                          label: label,
                          on: prefs.particleGlowEffect == fx,
                          onTap: () {
                            VisualPrefs.setParticleGlowEffect(fx);
                            Haptics.selection();
                          },
                        ),
                    ],
                  ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Compact labeled slider for the SIZE & SPEED section — label chip,
/// slim slider, live % readout.
class _MiniSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String display;
  final ValueChanged<double> onChanged;
  const _MiniSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.display,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: GoopText(
            label,
            style: TextStyle(
              fontSize: FontSizes.labelSmall,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: GoopText(
            display,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: FontSizes.labelSmall,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowFxChip extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _GlowFxChip({
    required this.label,
    required this.on,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _SelectChip(
      selected: on,
      onTap: onTap,
      semanticsLabel: label,
      child: GoopText(
        label,
        style: TextStyle(
          fontSize: FontSizes.labelSmall,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          color: on ? AppTheme.flair.primary : Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// Sticky pinned header for the particles tab — holds the enable
/// toggle and the live particle preview so they're always visible.
class _StickyParticleHeader extends SliverPersistentHeaderDelegate {
  final VisualPrefs prefs;
  _StickyParticleHeader({required this.prefs});

  @override
  double get minExtent => 160;
  @override
  double get maxExtent => 160;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.flair.scaffold.withValues(alpha: 0.95),
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
          Insets.sm,
        ),
        child: Column(
          children: [
            _ToggleRow(
              icon: Icons.auto_awesome_outlined,
              label: 'Enable Particles',
              value: prefs.particlesEnabled,
              onChanged: (v) {
                VisualPrefs.setParticles(v);
                Haptics.selection();
              },
            ),
            const SizedBox(height: 8),
            // Always show preview (even if disabled, to show what they'd get)
            Expanded(child: _ParticlePreview(prefs: prefs)),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyParticleHeader old) => prefs != old.prefs;
}

/// Live preview box that renders the current particle preset at its
/// actual settings so users can see exactly what they're choosing.
class _ParticlePreview extends StatelessWidget {
  final VisualPrefs prefs;
  const _ParticlePreview({required this.prefs});

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    return ClipRRect(
      borderRadius: BorderRadius.all(Radii.md),
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          color: flair.scaffold.withValues(alpha: 0.6),
          border: Border.all(
            color: flair.primary.withValues(alpha: 0.2),
            width: 1.0,
          ),
          borderRadius: BorderRadius.all(Radii.md),
        ),
        child: Stack(
          children: [
            // Subtle gradient backdrop so particles are visible.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      flair.scaffold.withValues(alpha: 0.3),
                      flair.card.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
            ),
            // The live particle field — same resolution as the app-wide
            // overlay so every option visibly changes the preview.
            Positioned.fill(
              child:
                  buildBackdropParticleField(AppTheme.displayedMode, prefs) ??
                  const SizedBox.shrink(),
            ),
            // Label overlay.
            Positioned(
              left: 12,
              bottom: 8,
              child: GoopText(
                'LIVE PREVIEW',
                style: TextStyle(
                  fontSize: FontSizes.labelSmall,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.3),
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Type tile — fixed-size cell with a painted shape glyph + label,
/// ITEM ICONS - OFF tile + the 12 Gungeon item sprites. Picking one
/// swaps the whole particle field for floating game icons.
Widget _itemIconGrid(VisualPrefs prefs) {
  const cols = 4;
  final items = kItemIconParticles;
  final total = items.length + 1; // + OFF
  return Column(
    children: [
      for (var r = 0; r * cols < total; r++)
        Padding(
          padding: EdgeInsets.only(bottom: (r + 1) * cols < total ? 8 : 0),
          child: Row(
            children: [
              for (var c = 0; c < cols; c++) ...[
                Expanded(
                  child:
                      r * cols + c < total
                          ? _ItemIconTile(
                            index: r * cols + c - 1, // -1 = OFF
                            // Sprite path wins over item icons —
                            // don't highlight a stale icon pick.
                            active:
                                prefs.particleItemIcon == r * cols + c - 1 &&
                                prefs.particleSpritePath.isEmpty,
                            onTap: () {
                              VisualPrefs.setParticleItemIcon(r * cols + c - 1);
                              // Curated icons and custom sprites are
                              // mutually exclusive — picking here
                              // clears any custom sprite path.
                              VisualPrefs.setParticleSpritePath('');
                              Haptics.selection();
                            },
                          )
                          : const SizedBox(),
                ),
                if (c < cols - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
    ],
  );
}

/// used by the uniform TYPE grid.
/// One ITEM ICONS cell - OFF glyph or the item sprite + label.
class _ItemIconTile extends StatelessWidget {
  final int index; // -1 = OFF, else kItemIconParticles index
  final bool active;
  final VoidCallback onTap;
  const _ItemIconTile({
    required this.index,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final c = active ? flair.primary : Colors.white.withValues(alpha: 0.5);
    final label = index < 0 ? 'OFF' : kItemIconParticles[index].$1;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 56,
        decoration: BoxDecoration(
          color:
              active
                  ? flair.primary.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                active ? flair.primary : Colors.white.withValues(alpha: 0.12),
            width: active ? 1.6 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 22,
              child:
                  index < 0
                      ? Icon(Icons.block_rounded, size: 20, color: c)
                      : Image.asset(
                        kItemIconParticles[index].$2,
                        width: 22,
                        height: 22,
                        cacheWidth: 96,
                        errorBuilder:
                            (_, _, _) => Icon(
                              Icons.broken_image_outlined,
                              size: 18,
                              color: c,
                            ),
                      ),
            ),
            const SizedBox(height: 4),
            GoopText(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 7.5,
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                letterSpacing: 0.4,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticleTypeTile extends StatelessWidget {
  final ParticleType type;
  final bool active;
  final VoidCallback onTap;
  const _ParticleTypeTile({
    required this.type,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final c = active ? flair.primary : Colors.white.withValues(alpha: 0.5);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 56,
        decoration: BoxDecoration(
          color:
              active
                  ? flair.primary.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                active ? flair.primary : Colors.white.withValues(alpha: 0.12),
            width: active ? 1.6 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TypeGlyph(type: type, color: c),
            const SizedBox(height: 5),
            GoopText(
              type.label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                letterSpacing: 0.6,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tiny painted glyph for each particle shape — honest preview of the
/// actual particle look instead of a borrowed icon.
class _TypeGlyph extends StatelessWidget {
  final ParticleType type;
  final Color color;
  const _TypeGlyph({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _TypeGlyphPainter(type, color)),
    );
  }
}

class _TypeGlyphPainter extends CustomPainter {
  final ParticleType type;
  final Color color;
  const _TypeGlyphPainter(this.type, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final c = Offset(size.width / 2, size.height / 2);
    switch (type) {
      case ParticleType.dot:
        canvas.drawCircle(c, 4, p);
      case ParticleType.square:
        canvas.drawRect(Rect.fromCenter(center: c, width: 9, height: 9), p);
      case ParticleType.glowOrb:
        p.shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: c, radius: 8));
        canvas.drawCircle(c, 8, p);
      case ParticleType.shell:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: c, width: 6, height: 12),
            const Radius.circular(3),
          ),
          p,
        );
      case ParticleType.rainbowDot:
        p.shader = SweepGradient(
          colors: [
            Colors.red,
            Colors.orange,
            Colors.yellow,
            Colors.green,
            Colors.blue,
            Colors.purple,
            Colors.red,
          ],
        ).createShader(Rect.fromCircle(center: c, radius: 6));
        canvas.drawCircle(c, 6, p);
      case ParticleType.voidPixel:
        p.style = PaintingStyle.stroke;
        p.strokeWidth = 2;
        canvas.drawRect(Rect.fromCenter(center: c, width: 9, height: 9), p);
      case ParticleType.glitchPixel:
        canvas.drawRect(
          Rect.fromLTWH(2, 2, 7, 7),
          p..color = color.withValues(alpha: 0.6),
        );
        canvas.drawRect(Rect.fromLTWH(9, 9, 7, 7), p..color = color);
      case ParticleType.star:
        final path =
            Path()
              ..moveTo(9, 1)
              ..lineTo(11, 7)
              ..lineTo(17, 9)
              ..lineTo(11, 11)
              ..lineTo(9, 17)
              ..lineTo(7, 11)
              ..lineTo(1, 9)
              ..lineTo(7, 7)
              ..close();
        canvas.drawPath(path, p);
      case ParticleType.bolt:
        canvas.drawPath(
          Path()
            ..moveTo(11, 1)
            ..lineTo(5, 10)
            ..lineTo(9, 10)
            ..lineTo(7, 17)
            ..lineTo(13, 8)
            ..lineTo(9, 8)
            ..close(),
          p,
        );
      case ParticleType.heart:
        canvas.drawPath(
          Path()
            ..moveTo(9, 16)
            ..cubicTo(16, 11, 14, 4, 9, 7)
            ..cubicTo(4, 4, 2, 11, 9, 16)
            ..close(),
          p,
        );
      case ParticleType.skull:
        canvas.drawCircle(c, 5.5, p);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(9, 13.5), width: 7, height: 4.5),
            const Radius.circular(1),
          ),
          p,
        );
      case ParticleType.paw:
        canvas.drawOval(
          Rect.fromCenter(center: Offset(9, 13), width: 8, height: 6),
          p,
        );
        for (final dx in [-4.5, -1.5, 1.5, 4.5]) {
          canvas.drawCircle(Offset(9 + dx, 7.5), 1.8, p);
        }
      case ParticleType.crescent:
        canvas.drawPath(
          Path()
            ..addOval(Rect.fromCircle(center: c, radius: 8))
            ..addOval(Rect.fromCircle(center: const Offset(12, 6.5), radius: 7))
            ..fillType = PathFillType.evenOdd,
          p,
        );
      case ParticleType.hexagon:
        final path = Path();
        for (var i = 0; i < 6; i++) {
          final a = (math.pi / 3) * i - math.pi / 2;
          final pt = Offset(9 + 8 * math.cos(a), 9 + 8 * math.sin(a));
          i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
        }
        canvas.drawPath(path..close(), p);
      case ParticleType.smoke:
        p.color = color.withValues(alpha: 0.55);
        canvas.drawCircle(const Offset(6, 10), 4.5, p);
        canvas.drawCircle(const Offset(12, 8), 5, p);
        canvas.drawCircle(const Offset(9, 13), 4, p);
        p.color = color;
      case ParticleType.scale:
        canvas.drawPath(
          Path()
            ..moveTo(2, 12)
            ..quadraticBezierTo(2, 4, 9, 3)
            ..quadraticBezierTo(16, 4, 16, 12)
            ..quadraticBezierTo(9, 15, 2, 12)
            ..close(),
          p,
        );
      case ParticleType.triangle:
        canvas.drawPath(
          Path()
            ..moveTo(9, 2)
            ..lineTo(16, 15)
            ..lineTo(2, 15)
            ..close(),
          p,
        );
    }
  }

  @override
  bool shouldRepaint(_TypeGlyphPainter old) =>
      old.type != type || old.color != color;
}

/// One curated-look tile — name + blurb + either the look's palette
/// dots or its sprite thumbnail. Active state comes from
/// [VisualPrefs.matchesParticleLook].
class _LookTile extends StatelessWidget {
  final ParticleLook look;
  final bool active;
  final VoidCallback onTap;
  const _LookTile({
    required this.look,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final c = active ? flair.primary : Colors.white.withValues(alpha: 0.55);
    final palette =
        kGlobalParticlePalettes[look.schemaIndex.clamp(
              0,
              kGlobalParticlePalettes.length - 1,
            )]
            .colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color:
              active
                  ? flair.primary.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                active ? flair.primary : Colors.white.withValues(alpha: 0.12),
            width: active ? 1.6 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GoopText(
              look.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                // U-035: 7.5px was below the readable floor.
                fontSize: 9,
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                letterSpacing: 0.4,
                color: c,
              ),
            ),
            GoopText(
              look.blurb,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8,
                color: Colors.white.withValues(alpha: 0.38),
              ),
            ),
            const Spacer(),
            if (look.spritePath.isNotEmpty)
              Image.asset(
                look.spritePath,
                height: 20,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox(height: 20),
              )
            else
              Row(
                children: [
                  for (final col in palette.take(3))
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 3),
                      decoration: BoxDecoration(
                        color: col,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Searchable sprite picker — every bundled gun + item WEBP, filterable
/// by name. Picking one sets [VisualPrefs.particleSpritePath] and
/// clears the curated item-icon pick (mutual exclusion).
class _SpritePickerSheet extends StatefulWidget {
  const _SpritePickerSheet();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SpritePickerSheet(),
    );
  }

  @override
  State<_SpritePickerSheet> createState() => _SpritePickerSheetState();
}

class _SpritePickerSheetState extends State<_SpritePickerSheet> {
  final _searchCtrl = TextEditingController();
  List<({String name, String path, bool isGun})> _sprites = const [];
  bool _loading = true;
  String _query = '';

  /// Bundled sprite list is static — parse the JSONs once per app run
  /// instead of on every sheet open (500+ entries).
  static List<({String name, String path, bool isGun})>? _spriteCache;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final cached = _spriteCache;
    if (cached != null) {
      setState(() {
        _sprites = cached;
        _loading = false;
      });
      return;
    }
    try {
      final gunsRaw = await rootBundle.loadString('assets/data/guns.json');
      final itemsRaw = await rootBundle.loadString('assets/data/items.json');
      List<String> namesOf(String raw) =>
          (jsonDecode(raw) as List)
              .map((e) => (e as Map)['name'] as String? ?? '')
              .where((n) => n.isNotEmpty)
              .toList();
      var entries = <({String name, String path, bool isGun})>[
        for (final n in namesOf(gunsRaw))
          (name: n, path: localGunIcon(n), isGun: true),
        for (final n in namesOf(itemsRaw))
          (name: n, path: localItemIcon(n), isGun: false),
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      // Slug-derived paths can miss the actual bundled file — a pick
      // that 404s renders zero particles with no feedback. Filter
      // against the asset manifest so every tile is guaranteed live.
      // Manifest failure stays permissive (tests / odd bundles).
      try {
        final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
        final valid = manifest.listAssets().toSet();
        entries = entries.where((e) => valid.contains(e.path)).toList();
      } catch (_) {}
      _spriteCache = entries;
      if (mounted) {
        setState(() {
          _sprites = entries;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _pick(String path) {
    VisualPrefs.setParticleSpritePath(path);
    VisualPrefs.setParticleItemIcon(-1);
    Haptics.selection();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final filtered =
        _query.isEmpty
            ? _sprites
            : _sprites
                .where((s) => s.name.toLowerCase().contains(_query))
                .toList();
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: flair.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: GoopText(
                    'PICK A SPRITE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                GoopText(
                  '${filtered.length}',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: const TextStyle(fontSize: 13, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'search guns & items…',
                hintStyle: TextStyle(
                  fontSize: FontSizes.labelMedium,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // NONE tile — clears custom sprite + curated icon.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                VisualPrefs.setParticleSpritePath('');
                VisualPrefs.setParticleItemIcon(-1);
                Haptics.selection();
                Navigator.of(context).pop();
              },
              child: Container(
                height: 40,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(
                      Icons.block_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 10),
                    GoopText(
                      'NONE — back to shapes',
                      style: TextStyle(
                        fontSize: FontSizes.labelSmall,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child:
                _loading
                    ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                    : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                            childAspectRatio: 0.72,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final s = filtered[i];
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _pick(s.path),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  s.path,
                                  height: 34,
                                  fit: BoxFit.contain,
                                  cacheWidth: 128,
                                  errorBuilder:
                                      (_, _, _) => Icon(
                                        s.isGun
                                            ? Icons.gps_fixed_rounded
                                            : Icons.category_rounded,
                                        size: 20,
                                        color: Colors.white.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                ),
                                const SizedBox(height: 3),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  child: GoopText(
                                    s.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 6,
                                      height: 1.1,
                                      color: Colors.white.withValues(
                                        alpha: 0.45,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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

/// Physics toggle pill — on/off chip for bounce/chaos/tilt.
class _PhysicsToggle extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _PhysicsToggle({
    required this.label,
    required this.on,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    return _SelectChip(
      selected: on,
      onTap: onTap,
      semanticsLabel: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            on ? Icons.check_circle : Icons.circle_outlined,
            size: 13,
            color: on ? flair.primary : Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 6),
          GoopText(
            label,
            style: TextStyle(
              fontSize: FontSizes.labelMedium,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: on ? flair.primary : Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
