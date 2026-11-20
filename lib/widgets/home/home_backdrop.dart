import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../services/app_theme.dart';
import '../particle_engine.dart';

/// Theme-reactive home-screen backdrop.
///
/// The base gradient, ember particles, and accent glow all derive from
/// the active [AppTheme.flair] — switching themes or palettes re-skins
/// the menu backdrop in the same frame as the rest of the app. The
/// sprite layers are fixed pixel art (guns, items, bullets) drifting in
/// two depths: distant flocks crossing the sky horizontally like birds,
/// and a nearer layer of smaller sprites rising slowly.
///
/// Honors `MediaQuery.disableAnimationsOf`: renders the static
/// gradient + vignette only.
class MainMenuBackdrop extends StatelessWidget {
  const MainMenuBackdrop({super.key});

  // ── Sprite pools (real extracted game art) ────────────────────
  /// Guns — bolder silhouettes for the nearer rising layer.
  static const List<String> driftGuns = [
    'assets/images/game/guns/blasphemy.png',
    'assets/images/game/guns/casey.png',
    'assets/images/game/guns/winchester.png',
    'assets/images/game/guns/railgun.png',
    'assets/images/game/guns/ak_47.png',
    'assets/images/game/guns/helix.png',
    'assets/images/game/guns/phoenix.png',
    'assets/images/game/guns/prototype_railgun.png',
    'assets/images/game/guns/zilla_shotgun.png',
    'assets/images/game/guns/budget_revolver.png',
    'assets/images/game/guns/brick_breaker.png',
    'assets/images/game/guns/snakemaker.png',
  ];

  /// Item icons — small webp sprites, the bulk of the distant flocks.
  static const List<String> driftItems = [
    'assets/images/items/bracket_key.webp',
    'assets/images/items/bomb.webp',
    'assets/images/items/medkit.webp',
    'assets/images/items/gunboots.webp',
    'assets/images/items/wax_wings.webp',
    'assets/images/items/gunknight_armor.webp',
    'assets/images/items/spice.webp',
    'assets/images/items/sprun.webp',
    'assets/images/items/heart_bottle.webp',
    'assets/images/items/iron_coin.webp',
    'assets/images/items/battle_standard.webp',
    'assets/images/items/book_of_chest_anatomy.webp',
    'assets/images/items/ammo_belt.webp',
    'assets/images/items/armor_of_thorns.webp',
  ];

  /// Bullet icons — tiny accents mixed into the flocks.
  static const List<String> driftBullets = [
    'assets/images/items/1_bullets.webp',
    'assets/images/items/alpha_bullet.webp',
    'assets/images/items/angry_bullets.webp',
    'assets/images/items/battery_bullets.webp',
    'assets/images/items/blank_bullets.webp',
    'assets/images/items/bouncy_bullets.webp',
    'assets/images/items/bloody_9mm.webp',
    'assets/images/items/cursed_bullets.webp',
  ];

  /// Everything the drift layers can draw — deduped union.
  static List<String> get driftSprites => [
    ...driftGuns,
    ...driftItems,
    ...driftBullets,
  ];

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    // Keep the dungeon dark but carry the theme's hue — lerp each
    // surface toward black so even light themes (Minimalist paper)
    // still get a dark backdrop with a colored cast.
    final bgTop = Color.lerp(flair.scaffold, Colors.black, 0.84)!;
    final bgBottom = Color.lerp(flair.card, Colors.black, 0.80)!;
    final emberColors = [
      flair.primary,
      flair.secondary,
      flair.headlineStat,
      Color.lerp(flair.primary, Colors.white, 0.35)!,
    ];

    return Positioned.fill(
      child: Stack(
        // expand: non-positioned children (gradients, particles,
        // drift layers) must fill the whole screen — default loose
        // fit would size them to zero.
        fit: StackFit.expand,
        children: [
          // Base gradient — theme-tinted dungeon darkness.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bgTop, bgBottom],
              ),
            ),
          ),
          // Faint accent glow behind the logo area.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.55),
                radius: 0.9,
                colors: [
                  flair.primary.withValues(alpha: 0.10),
                  Colors.transparent,
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
          if (!reduceMotion) ...[
            // Theme-tinted embers rising through the dark — fixed
            // config so no user particle pref can change them.
            IgnorePointer(
              child: RepaintBoundary(
                child: ParticleField(
                  preset: ParticlePreset.gungeonDust,
                  tiltEnabled: false,
                  count: 18,
                  sizeScale: 0.9,
                  opacity: 0.85,
                  speedMultiplier: 0.4,
                  config: typedParticleConfig(
                    ParticleType.glowOrb,
                    emberColors,
                  ),
                ),
              ),
            ),
            // Distant flocks — small sprites crossing horizontally.
            const IgnorePointer(
              child: RepaintBoundary(child: _FlockDrift()),
            ),
            // Near drift — smaller sprites rising slowly.
            const IgnorePointer(
              child: RepaintBoundary(child: _RiseDrift()),
            ),
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

// =============================================================================
// Sprite drift — two depth layers drawn as single-pass CustomPaint.
// All sprites decode once into ui.Image (ItemIconField pattern) so a
// theme change never re-decodes and a frame never builds N widgets.
// =============================================================================

/// Decoded sprite bank — loads [paths] once, hands out [ui.Image]s.
/// Missing/corrupt assets are skipped silently (fewer sprites, never
/// a crash). Call [dispose] when the owning State dies.
class _SpriteBank {
  _SpriteBank(this.paths);

  final List<String> paths;
  final Map<String, ui.Image> images = {};
  bool loaded = false;
  bool _disposed = false;

  Future<void> load() async {
    await Future.wait(
      paths.map((path) async {
        try {
          final data = await rootBundle.load(path);
          final codec = await ui.instantiateImageCodec(
            data.buffer.asUint8List(),
          );
          final frame = await codec.getNextFrame();
          codec.dispose();
          // State may have been disposed mid-load — don't leak the
          // decoded frame into a bank nobody will dispose.
          if (_disposed) {
            frame.image.dispose();
            return;
          }
          images[path] = frame.image;
        } catch (_) {
          // Missing asset — skip it.
        }
      }),
    );
    loaded = true;
  }

  void dispose() {
    _disposed = true;
    for (final img in images.values) {
      img.dispose();
    }
    images.clear();
  }
}

/// Base state for both drift layers: owns the bank + ticker and feeds
/// [time] into a CustomPaint each frame.
mixin _DriftTicker<T extends StatefulWidget> on State<T> {
  late final AnimationController _ctrl;
  final _bank = _SpriteBank(MainMenuBackdrop.driftSprites);

  /// Override point — flocks cross horizontally, rise goes up.
  Duration get cycle;

  void initDrift(TickerProvider vsync) {
    _ctrl = AnimationController(vsync: vsync, duration: cycle)..repeat();
    _bank.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  void disposeDrift() {
    _ctrl.dispose();
    _bank.dispose();
  }

  _SpriteBank get bank => _bank;
}

// ── Flock layer ─────────────────────────────────────────────────

/// One flock: a loose cluster of sprites in a shallow formation that
/// crosses the sky horizontally. [depth] drives scale + opacity —
/// far flocks are tiny and faint, near ones slightly larger.
class _Flock {
  _Flock(this.r);

  final math.Random r;

  // Vertical band (fraction of height) + gentle bob.
  late final double bandY = 0.08 + r.nextDouble() * 0.6;
  late final double bobPhase = r.nextDouble() * math.pi * 2;
  late final double bobAmp = 4 + r.nextDouble() * 10;

  // Horizontal drift — alternating directions, varied pace.
  late final double dir = r.nextDouble() < 0.5 ? 1.0 : -1.0;
  late final double pace = 0.55 + r.nextDouble() * 0.5; // cycles per base cycle

  // Depth: 0 = far (tiny/faint), 1 = near.
  late final double depth = r.nextDouble();

  // Formation members: offsets in "bird units" behind the leader,
  // alternating wings like a shallow V.
  late final List<_FlockMember> members = List.generate(
    5 + r.nextInt(3), // 5–7 sprites per flock
    (i) {
      final side = i.isEven ? -1.0 : 1.0;
      final rank = (i ~/ 2) + 1;
      return _FlockMember(
        dx: -rank * (14 + r.nextDouble() * 10) * side * -1,
        dy: rank * (7 + r.nextDouble() * 5) * (i.isEven ? -1 : 1) * 0.4,
        sprite: r.nextInt(MainMenuBackdrop.driftSprites.length),
        scaleJitter: 0.85 + r.nextDouble() * 0.3,
        bobJitter: r.nextDouble() * math.pi * 2,
      );
    },
  );
}

class _FlockMember {
  _FlockMember({
    required this.dx,
    required this.dy,
    required this.sprite,
    required this.scaleJitter,
    required this.bobJitter,
  });

  final double dx, dy;
  final int sprite;
  final double scaleJitter, bobJitter;
}

/// Far layer — 3 flocks crossing the sky horizontally, ~55s base
/// cycle so crossings feel unhurried.
class _FlockDrift extends StatefulWidget {
  const _FlockDrift();

  @override
  State<_FlockDrift> createState() => _FlockDriftState();
}

class _FlockDriftState extends State<_FlockDrift>
    with SingleTickerProviderStateMixin, _DriftTicker<_FlockDrift> {
  late final List<_Flock> _flocks;

  @override
  Duration get cycle => const Duration(seconds: 55);

  @override
  void initState() {
    super.initState();
    final r = math.Random(7);
    _flocks = List.generate(3, (_) => _Flock(r));
    initDrift(this);
  }

  @override
  void dispose() {
    disposeDrift();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (bank.images.isEmpty) return const SizedBox.shrink();
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return CustomPaint(
              size: Size(c.maxWidth, c.maxHeight),
              painter: _FlockPainter(
                time: _ctrl.value,
                flocks: _flocks,
                images: bank.images,
                sprites: MainMenuBackdrop.driftSprites,
              ),
            );
          },
        );
      },
    );
  }
}

class _FlockPainter extends CustomPainter {
  _FlockPainter({
    required this.time,
    required this.flocks,
    required this.images,
    required this.sprites,
  });

  final double time; // 0..1 controller value
  final List<_Flock> flocks;
  final Map<String, ui.Image> images;
  final List<String> sprites;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = time * 55.0; // seconds into cycle

    for (final flock in flocks) {
      // Horizontal wrap: p sweeps a 1.4× span with a 160px margin so
      // even the outermost formation members fully exit before wrap.
      final p = (time * flock.pace * flock.dir + flock.bandY * 0.13) % 1.0;
      final px =
          flock.dir > 0
              ? (p * 1.4 - 0.2) * (size.width + 320) - 160
              : size.width + 160 - p * 1.4 * (size.width + 320);
      final bobY =
          flock.bandY * size.height +
          math.sin(t * 0.5 + flock.bobPhase) * flock.bobAmp;

      // Depth: far = small + faint, near = bigger + slightly brighter.
      final baseScale = 14 + flock.depth * 22; // target px height-ish
      final opacity = 0.05 + flock.depth * 0.10;

      for (final m in flock.members) {
        final path = sprites[m.sprite];
        final img = images[path];
        if (img == null) continue;

        // Member offset behind the leader, scaled by depth.
        final ox = px + m.dx * (0.7 + flock.depth * 0.6);
        final oy =
            bobY +
            m.dy * (0.7 + flock.depth * 0.6) +
            math.sin(t * 0.8 + m.bobJitter) * 2.5;

        final h = baseScale * m.scaleJitter;
        final w = h * (img.width / img.height);
        final dst = Rect.fromCenter(
          center: Offset(ox, oy),
          width: w,
          height: h,
        );
        final src = Rect.fromLTWH(
          0,
          0,
          img.width.toDouble(),
          img.height.toDouble(),
        );
        canvas.drawImageRect(
          img,
          src,
          dst,
          Paint()
            ..filterQuality = FilterQuality.none
            ..color = Colors.white.withValues(alpha: opacity),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FlockPainter old) => true;
}

// ── Rise layer ──────────────────────────────────────────────────

/// Near layer — a handful of smaller sprites rising slowly with sway,
/// like debris caught in an updraft. Guns lean heavier here.
class _RiseDrift extends StatefulWidget {
  const _RiseDrift();

  @override
  State<_RiseDrift> createState() => _RiseDriftState();
}

class _RiseDriftState extends State<_RiseDrift>
    with SingleTickerProviderStateMixin, _DriftTicker<_RiseDrift> {
  late final List<_RiseSprite> _sprites;

  @override
  Duration get cycle => const Duration(seconds: 42);

  @override
  void initState() {
    super.initState();
    final r = math.Random(99);
    // ~60% guns, 40% items/bullets — nearer layer reads as "stuff".
    _sprites = List.generate(11, (i) {
      final useGun = i < 7;
      final pool = useGun
          ? MainMenuBackdrop.driftGuns
          : [
            ...MainMenuBackdrop.driftItems.take(8),
            ...MainMenuBackdrop.driftBullets.take(4),
          ];
      return _RiseSprite(
        sprite: pool[r.nextInt(pool.length)],
        xSeed: r.nextDouble(),
        speedSeed: r.nextDouble(),
        sizeSeed: r.nextDouble(),
        swaySeed: r.nextDouble(),
        phase: r.nextDouble() * math.pi * 2,
        rotSeed: r.nextDouble(),
      );
    });
    initDrift(this);
  }

  @override
  void dispose() {
    disposeDrift();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (bank.images.isEmpty) return const SizedBox.shrink();
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return CustomPaint(
              size: Size(c.maxWidth, c.maxHeight),
              painter: _RisePainter(
                time: _ctrl.value,
                sprites: _sprites,
                images: bank.images,
              ),
            );
          },
        );
      },
    );
  }
}

class _RiseSprite {
  _RiseSprite({
    required this.sprite,
    required this.xSeed,
    required this.speedSeed,
    required this.sizeSeed,
    required this.swaySeed,
    required this.phase,
    required this.rotSeed,
  });

  final String sprite;
  final double xSeed, speedSeed, sizeSeed, swaySeed, phase, rotSeed;
}

class _RisePainter extends CustomPainter {
  _RisePainter({
    required this.time,
    required this.sprites,
    required this.images,
  });

  final double time;
  final List<_RiseSprite> sprites;
  final Map<String, ui.Image> images;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = time * 42.0;

    for (final s in sprites) {
      final img = images[s.sprite];
      if (img == null) continue;

      // Rise progress — phase offset spreads them vertically.
      final p = (time + s.xSeed * 0.9) % 1.0;
      final dx = math.sin((p + s.swaySeed) * math.pi * 2) * 0.025;

      // Smaller than the old drift — 18–38px tall, opacity 0.10–0.22.
      final h = 18 + s.sizeSeed * 20;
      final w = h * (img.width / img.height);
      final src = Rect.fromLTWH(
        0,
        0,
        img.width.toDouble(),
        img.height.toDouble(),
      );
      final paint =
          Paint()
            ..filterQuality = FilterQuality.none
            ..color = Colors.white.withValues(
              alpha: 0.10 + s.speedSeed * 0.12,
            );

      // Gentle tumble — slow rotation reads as drift, not spin.
      final tilt = math.sin(t * 0.4 + s.phase) * 0.12 * (s.rotSeed - 0.5) * 2;
      canvas.save();
      canvas.translate(
        (s.xSeed + dx) * size.width,
        size.height + 40 - p * (size.height + 80),
      );
      canvas.rotate(tilt);
      canvas.drawImageRect(
        img,
        src,
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_RisePainter old) => true;
}
