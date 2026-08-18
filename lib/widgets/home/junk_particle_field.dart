import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../services/home_customization.dart';
import 'vortex_config.dart';

/// A field of "junk" pickups (money, blanks, guon stones, hearts, golden
/// shells) drifting and swirling through the home-screen vortex. Each
/// sprite orbits the screen center at its own radius and speed, with a
/// gentle radial breathing so the whole field pulses in and out — like
/// loot caught in a portal current. Sprites also spin individually.
///
/// All motion parameters are driven by [VortexConfig] — tweak there to
/// adjust the simulation.
///
/// **Optimizations vs. original:**
///   • Particles are rebuilt only when the customization changes (not every
///     frame). A cached list is kept and invalidated on HomeCustomization
///     updates.
///   • Uses `MediaQuery.sizeOf` instead of `MediaQuery.of` to avoid
///     rebuilds on keyboard/orientation changes.
///   • The repaint trigger (AnimationController) is decoupled from particle
///     data — only the painter rebuilds per frame, not the widget tree.
///
/// Purely decorative; the caller wraps it in IgnorePointer.
class JunkParticleField extends StatefulWidget {
  final VortexConfig config;

  const JunkParticleField({
    super.key,
    this.config = VortexConfig.defaultConfig,
  });

  @override
  State<JunkParticleField> createState() => _JunkParticleFieldState();
}

class _JunkParticleFieldState extends State<JunkParticleField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final Stopwatch _clock = Stopwatch();
  List<_JunkParticle> _particles = [];
  final Map<String, ui.Image> _images = {};
  bool _loaded = false;
  // Cache key for particle rebuild — only rebuild when counts change.
  String _lastCountsKey = '';

  VortexConfig get _cfg => widget.config;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: _cfg.junkControllerDuration.round()),
    )..repeat();
    _clock.start();
    _loadImages();
  }

  @override
  void dispose() {
    _clock.stop();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadImages() async {
    await Future.wait(HomeCustomization.junkTypes.map((t) async {
      final path = HomeCustomization.junkAssetPath(t.stem);
      try {
        final data = await rootBundle.load(path);
        final codec =
            await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        _images[t.stem] = frame.image;
      } catch (_) {
        // Missing/corrupt asset — that stem just won't render.
      }
    }));
    if (mounted) setState(() => _loaded = true);
  }

  /// Build a cache key from current junk counts so we only rebuild the
  /// particle list when counts actually change — not every frame.
  String _countsKey(HomeCustomization cust) {
    return HomeCustomization.junkTypes
        .map((t) => '${t.stem}:${cust.junkCounts[t.stem] ?? 0}')
        .join('|');
  }

  void _rebuildParticlesIfNeeded(HomeCustomization cust) {
    final key = _countsKey(cust);
    if (key == _lastCountsKey) return; // counts unchanged — keep cached list
    _lastCountsKey = key;
    final cfg = _cfg;
    final all = <_JunkParticle>[];
    for (final t in HomeCustomization.junkTypes) {
      final count = cust.junkCounts[t.stem] ?? 0;
      final seed = t.stem.hashCode;
      final r = math.Random(seed);
      for (var i = 0; i < count; i++) {
        all.add(_JunkParticle(
          stem: t.stem,
          radius: cfg.junkRadiusMin +
              r.nextDouble() * (cfg.junkRadiusMax - cfg.junkRadiusMin),
          angle: r.nextDouble() * 2 * math.pi,
          omega: (cfg.junkOmegaMin +
                  r.nextDouble() * (cfg.junkOmegaMax - cfg.junkOmegaMin)) *
              (r.nextBool() ? 1 : -1),
          breathPhase: r.nextDouble() * 2 * math.pi,
          breathAmp: 0.03 + r.nextDouble() * 0.06,
          breathSpeed: 0.4 + r.nextDouble() * 0.8,
          spin: cfg.junkSpinMin +
              r.nextDouble() * (cfg.junkSpinMax - cfg.junkSpinMin),
          size: cfg.junkSizeMin +
              r.nextDouble() * (cfg.junkSizeMax - cfg.junkSizeMin),
          opacity: cfg.junkOpacityMin +
              r.nextDouble() * (cfg.junkOpacityMax - cfg.junkOpacityMin),
        ));
      }
    }
    _particles = all;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HomeCustomization>(
      valueListenable: HomeCustomization.notifier,
      builder: (context, cust, _) {
        if (!cust.showJunk || cust.totalJunk == 0 || !_loaded) {
          return const SizedBox.shrink();
        }
        _rebuildParticlesIfNeeded(cust);
        if (_particles.isEmpty || _images.isEmpty) {
          return const SizedBox.shrink();
        }
        return IgnorePointer(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              // sizeOf avoids rebuilds on keyboard/orientation changes.
              final size = MediaQuery.sizeOf(context);
              return CustomPaint(
                size: size,
                painter: _JunkPainter(
                  particles: _particles,
                  images: _images,
                  progress: _ctrl.value,
                  elapsed: _clock.elapsedMilliseconds / 1000.0,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _JunkPainter extends CustomPainter {
  final List<_JunkParticle> particles;
  final Map<String, ui.Image> images;
  final double progress;
  final double elapsed;

  const _JunkPainter({
    required this.particles,
    required this.images,
    required this.progress,
    required this.elapsed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.52);
    final maxDim = math.max(size.width, size.height);
    for (final p in particles) {
      final img = images[p.stem];
      if (img == null) continue;
      // Orbital angle advances with elapsed time (not progress wrap) so
      // motion is time-stable regardless of controller duration.
      final angle = p.angle + p.omega * elapsed;
      // Radial breathing: drift in and out around the base radius.
      final breath =
          math.sin(elapsed * p.breathSpeed + p.breathPhase) * p.breathAmp;
      final r = (p.radius + breath) * maxDim;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      final pos = Offset(x, y);

      // Depth fade: particles on the far side (behind the vortex) dim.
      final depth = (math.sin(angle) + 1) / 2; // 0..1
      final alpha = (p.opacity * (0.5 + 0.5 * depth)).clamp(0.0, 1.0);

      final scale = (0.7 + 0.3 * depth) * (p.size / 40.0);
      final rot = elapsed * p.spin;

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(rot);
      canvas.scale(scale);
      final iw = img.width.toDouble();
      final ih = img.height.toDouble();
      final paint = Paint()..color = Color.fromRGBO(255, 255, 255, alpha);
      // Center the sprite on its orbit point.
      canvas.drawImage(img, Offset(-iw / 2, -ih / 2), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_JunkPainter old) =>
      old.progress != progress || old.elapsed != elapsed;
}

class _JunkParticle {
  final String stem;
  final double radius; // fraction of max screen dim
  final double angle; // radians
  final double omega; // angular velocity (rad/s)
  final double breathPhase;
  final double breathAmp;
  final double breathSpeed;
  final double spin; // rad/s
  final double size; // base px
  final double opacity;

  const _JunkParticle({
    required this.stem,
    required this.radius,
    required this.angle,
    required this.omega,
    required this.breathPhase,
    required this.breathAmp,
    required this.breathSpeed,
    required this.spin,
    required this.size,
    required this.opacity,
  });
}
