import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../particle_engine.dart';

/// Fixed, theme-independent home-screen backdrop.
///
/// The main menu must look identical on every theme — full design
/// control lives here. Deep violet gradient base, warm ember
/// particles rising, faint pixel-gun sprites drifting up through
/// the dark, and a fixed vignette. ThemeOverlay skips all its
/// theme-driven layers while the home screen is visible, so nothing
/// else can tint this.
///
/// Honors `MediaQuery.disableAnimationsOf`: renders the static
/// gradient + vignette only.
class MainMenuBackdrop extends StatelessWidget {
  const MainMenuBackdrop({super.key});

  // ── Locked home palette (never read from AppTheme) ────────────
  static const Color baseTop = Color(0xFF0A0710);
  static const Color baseBottom = Color(0xFF141022);
  static const Color ember = Color(0xFFFFB84D);
  static const Color emberHot = Color(0xFFFF8C2E);
  static const Color emberGold = Color(0xFFFFD54F);
  static const Color emberDeep = Color(0xFFFF5E3A);

  static const List<Color> emberColors = [
    ember,
    emberHot,
    emberGold,
    emberDeep,
  ];

  /// Gun sprites (real extracted game art) drifting in the back —
  /// a small curated set with iconic silhouettes.
  static const List<String> driftSprites = [
    'assets/images/game/guns/blasphemy.png',
    'assets/images/game/guns/casey.png',
    'assets/images/game/guns/winchester.png',
    'assets/images/game/guns/railgun.png',
  ];

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Positioned.fill(
      child: Stack(
        // expand: non-positioned children (gradients, particles,
        // drift layer) must fill the whole screen — default loose
        // fit would size them to zero.
        fit: StackFit.expand,
        children: [
          // Base gradient — deep violet dungeon darkness.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [baseTop, baseBottom],
              ),
            ),
          ),
          // Faint ember glow behind the logo area.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.55),
                radius: 0.9,
                colors: [Color(0x1AFFB84D), Colors.transparent],
                stops: [0.0, 1.0],
              ),
            ),
          ),
          if (!reduceMotion) ...[
            // Embers rising through the dark — fixed config so no
            // theme or user particle pref can change them.
            IgnorePointer(
              child: RepaintBoundary(
                child: ParticleField(
                  preset: ParticlePreset.gungeonDust,
                  tiltEnabled: false,
                  count: 18,
                  sizeScale: 0.9,
                  opacity: 0.85,
                  speedMultiplier: 0.4,
                  config: _emberConfig,
                ),
              ),
            ),
            // Drifting gun silhouettes — slow, faint, pixel-crisp.
            const IgnorePointer(child: RepaintBoundary(child: _SpriteDrift())),
          ],
          // Fixed vignette — closes the frame like a dungeon door.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.3,
                colors: [
                  Colors.transparent,
                  Color(0x40000000),
                  Color(0xB3000000),
                ],
                stops: [0.0, 0.72, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final PresetConfig _emberConfig = typedParticleConfig(
  ParticleType.glowOrb,
  MainMenuBackdrop.emberColors,
);

/// Slow-rising faint gun sprites. A single controller drives all
/// sprites with per-sprite phase offsets; positions wrap so the
/// field never empties. Pixel art stays crisp (FilterQuality.none).
class _SpriteDrift extends StatefulWidget {
  const _SpriteDrift();

  @override
  State<_SpriteDrift> createState() => _SpriteDriftState();
}

class _SpriteDriftState extends State<_SpriteDrift>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _rng = math.Random(42); // fixed seed — same layout every run
  late final List<Offset> _seeds;

  /// One full rise cycle — slow enough to read as ambiance, not motion.
  static const _cycle = Duration(seconds: 36);

  @override
  void initState() {
    super.initState();
    _seeds = List.generate(
      MainMenuBackdrop.driftSprites.length,
      (_) => Offset(_rng.nextDouble(), _rng.nextDouble()),
    );
    _ctrl = AnimationController(vsync: this, duration: _cycle)..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final kids = <Widget>[];
            for (var i = 0; i < MainMenuBackdrop.driftSprites.length; i++) {
              final seed = _seeds[i];
              // Phase-offset progress so sprites are spread vertically.
              final p = (_ctrl.value + seed.dy) % 1.0;
              // Drift slightly side-to-side as they rise.
              final dx = math.sin((p + seed.dx) * math.pi * 2) * 0.03;
              final scale = 3.0 + seed.dx * 1.5;
              kids.add(
                Positioned(
                  left: (seed.dx + dx) * c.maxWidth,
                  bottom: p * (c.maxHeight + 80) - 40,
                  child: Opacity(
                    opacity: 0.14,
                    child: Transform.scale(
                      scale: scale,
                      child: Image.asset(
                        MainMenuBackdrop.driftSprites[i],
                        filterQuality: FilterQuality.none,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              );
            }
            return Stack(children: kids);
          },
        );
      },
    );
  }
}
