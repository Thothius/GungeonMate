part of '../experience_studio_screen.dart';

class _ParticlesStep extends StatelessWidget {
  const _ParticlesStep();

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
                              active: r * cols + c == prefs.particleTypeIndex,
                              onTap: () {
                                VisualPrefs.setParticleTypeIndex(r * cols + c);
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
                  // Typed particle system — 7 shapes × per-theme
                  // schemas × 3 physics flags. Clean, minimal, all
                  // user-facing (replaces the 37-preset × 16-schema
                  // layer entirely).
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
                    ],
                  ),
                  const SizedBox(height: 16),
                  _StepLabel('COLOR'),
                  const SizedBox(height: 8),
                  // 12 global palettes — horizontal scroller so every
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
                ]),
              ),
            ),
          ],
        );
      },
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
/// used by the uniform TYPE grid.
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
            Skeuo.inkIf(Colors.red),
            Skeuo.inkIf(Colors.orange),
            Skeuo.inkIf(Colors.yellow),
            Skeuo.inkIf(Colors.green),
            Skeuo.inkIf(Colors.blue),
            Skeuo.inkIf(Colors.purple),
            Skeuo.inkIf(Colors.red),
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
    }
  }

  @override
  bool shouldRepaint(_TypeGlyphPainter old) =>
      old.type != type || old.color != color;
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              on
                  ? flair.primary.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: on ? flair.primary : Colors.white.withValues(alpha: 0.15),
            width: on ? 1.6 : 1.0,
          ),
        ),
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
      ),
    );
  }
}
