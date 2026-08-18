import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../services/home_customization.dart';

/// A field of "junk" pickups (money, blanks, guon stones, hearts, golden
/// shells) drifting and swirling through the home-screen vortex. Each
/// sprite orbits the screen center at its own radius and speed, with a
/// gentle radial breathing so the whole field pulses in and out — like
/// loot caught in a portal current. Sprites also spin individually.
///
/// Purely decorative; the caller wraps it in IgnorePointer.
class JunkParticleField extends StatefulWidget {
  const JunkParticleField({super.key});

  @override
  State<JunkParticleField> createState() => _JunkParticleFieldState();
}

class _JunkParticleFieldState extends State<JunkParticleField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final Stopwatch _clock = Stopwatch();
  List<_JunkParticle> _particles = [];
  // Cached decoded sprites, keyed by junk stem.
  final Map<String, ui.Image> _images = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
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
    // Load every supported junk sprite once; the field picks which to
    // draw based on the user's configured counts.
    await Future.wait(HomeCustomization.junkTypes.map((t) async {
      final path = HomeCustomization.junkAssetPath(t.stem);
      try {
        final data = await rootBundle.load(path);
        final codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(),
        );
        final frame = await codec.getNextFrame();
        _images[t.stem] = frame.image;
      } catch (_) {
        // Missing/corrupt asset — that stem just won't render.
      }
    }));
    if (mounted) setState(() => _loaded = true);
  }

  void _rebuildParticles(HomeCustomization cust) {
    // Deterministic per-stem seed so counts don't reshuffle every frame.
    final all = <_JunkParticle>[];
    for (final t in HomeCustomization.junkTypes) {
      final count = cust.junkCounts[t.stem] ?? 0;
      final seed = t.stem.hashCode;
      final r = math.Random(seed);
      for (var i = 0; i < count; i++) {
        all.add(_JunkParticle(
          stem: t.stem,
          // Spread orbits across a wide radius band around the vortex.
          radius: 0.18 + r.nextDouble() * 0.34,
          angle: r.nextDouble() * 2 * math.pi,
          // Slow, varied orbital speed; some clockwise, some counter.
          omega: (0.06 + r.nextDouble() * 0.18) * (r.nextBool() ? 1 : -1),
          // Radial breathing phase + amplitude (how far it drifts in/out).
          breathPhase: r.nextDouble() * 2 * math.pi,
          breathAmp: 0.03 + r.nextDouble() * 0.06,
          breathSpeed: 0.4 + r.nextDouble() * 0.8,
          // Individual sprite spin.
          spin: (r.nextDouble() * 2 - 1) * 1.2,
          size: 22 + r.nextDouble() * 18,
          opacity: 0.55 + r.nextDouble() * 0.35,
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
        _rebuildParticles(cust);
        if (_particles.isEmpty || _images.isEmpty) {
          return const SizedBox.shrink();
        }
        return IgnorePointer(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final mq = MediaQuery.of(context);
              return CustomPaint(
                size: mq.size,
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
