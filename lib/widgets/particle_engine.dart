import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme_overlay.dart' show ThemeOverlay;

// =============================================================================
// Enums
// =============================================================================

enum ParticlePreset {
  gungeonDust,
  forgeEmbers,
  frostShards,
  toxicBubbles,
  cosmicStars,
  cursedSmoke,
  brassCasings,
  voidRift,
  bulletHell,
  unicornSparkles,
  cosmicDust,
  goldenSparkle,
  rainbowConfetti,
  bulletKin,
  heartContainers,
  cursedSkulls,
  masterRounds,
  jamHexes,
}

extension ParticlePresetX on ParticlePreset {
  String get label => switch (this) {
        ParticlePreset.gungeonDust => 'Gungeon Dust',
        ParticlePreset.forgeEmbers => 'Forge Embers',
        ParticlePreset.frostShards => 'Frost Shards',
        ParticlePreset.toxicBubbles => 'Toxic Bubbles',
        ParticlePreset.cosmicStars => 'Cosmic Stars',
        ParticlePreset.cursedSmoke => 'Cursed Smoke',
        ParticlePreset.brassCasings => 'Brass Casings',
        ParticlePreset.voidRift => 'Void Rift',
        ParticlePreset.bulletHell => 'Bullet Hell',
        ParticlePreset.unicornSparkles => 'Unicorn Sparkles',
        ParticlePreset.cosmicDust => 'Cosmic Dust',
        ParticlePreset.goldenSparkle => 'Golden Sparkle',
        ParticlePreset.rainbowConfetti => 'Rainbow Confetti',
        ParticlePreset.bulletKin => 'Bullet Kin Parade',
        ParticlePreset.heartContainers => 'Heart Containers',
        ParticlePreset.cursedSkulls => 'Cursed Skulls',
        ParticlePreset.masterRounds => 'Master Rounds',
        ParticlePreset.jamHexes => 'Jam Swarm',
      };

  String get description => switch (this) {
        ParticlePreset.gungeonDust => 'Subtle grey-white motes drifting upward with gentle sway',
        ParticlePreset.forgeEmbers => 'Fire embers rising with lively flicker, orange/red/gold',
        ParticlePreset.frostShards => 'Ice crystals drifting down with slow spin, cyan/white',
        ParticlePreset.toxicBubbles => 'Green bubbles wobbling upward',
        ParticlePreset.cosmicStars => 'Twinkling 4-point stars with slow rotation, cyan/gold/white',
        ParticlePreset.cursedSmoke => 'Purple-black smoke wisps with shifting cursed aura',
        ParticlePreset.brassCasings => 'Brass shell casings tumbling as they fall',
        ParticlePreset.voidRift => 'Dark purple energy triangles with dual ripple rings',
        ParticlePreset.bulletHell => 'Fast-moving small dots, dense and chaotic',
        ParticlePreset.unicornSparkles => 'Pink/purple/cyan sparkles with pulse glow and twinkle',
        ParticlePreset.cosmicDust => 'Deep blue/violet dust with ripple rings and line links',
        ParticlePreset.goldenSparkle => 'Gold/amber stars with smokey glow, slow spin',
        ParticlePreset.rainbowConfetti => 'Multi-color confetti pieces tumbling down',
        ParticlePreset.bulletKin => 'Cute brass bullet shapes drifting upward with warm glow',
        ParticlePreset.heartContainers => 'Floating heart containers with beating pulse glow',
        ParticlePreset.cursedSkulls => 'Eerie skull particles with shifting cursed aura',
        ParticlePreset.masterRounds => 'Spinning golden master rounds falling with smokey trail',
        ParticlePreset.jamHexes => 'Purple jam hexagons with cursed glow and connected network',
      };

  PresetConfig get config => switch (this) {
        ParticlePreset.gungeonDust => PresetConfig(
            colors: [const Color(0xFFE0E0E0), const Color(0xFFBDBDBD), const Color(0xFF9E9E9E), const Color(0xFF757575)],
            shape: ParticleShape.circle,
            sizeMin: 1.5, sizeMax: 4.0,
            speedMin: 8.0, speedMax: 20.0,
            glowEffect: GlowEffect.none,
            lineLinks: false,
            drift: DriftDirection.up,
            wobble: 0.5,
          ),
        ParticlePreset.forgeEmbers => PresetConfig(
            colors: [const Color(0xFFFF3D00), const Color(0xFFFF9100), const Color(0xFFFFD600), const Color(0xFFFF5722)],
            shape: ParticleShape.circle,
            sizeMin: 2.0, sizeMax: 5.0,
            speedMin: 15.0, speedMax: 35.0,
            glowEffect: GlowEffect.smokey,
            lineLinks: false,
            drift: DriftDirection.up,
            wobble: 1.5,
          ),
        ParticlePreset.frostShards => PresetConfig(
            colors: [const Color(0xFF00B0FF), const Color(0xFF4FC3F7), const Color(0xFFE1F5FE)],
            shape: ParticleShape.star,
            sizeMin: 2.0, sizeMax: 5.0,
            speedMin: 6.0, speedMax: 16.0,
            glowEffect: GlowEffect.pulse,
            lineLinks: false,
            drift: DriftDirection.down,
            wobble: 0.3,
            rotate: true,
          ),
        ParticlePreset.toxicBubbles => PresetConfig(
            colors: [const Color(0xFF76FF03), const Color(0xFF64DD17), const Color(0xFFAEEA00), const Color(0xFF33691E)],
            shape: ParticleShape.circle,
            sizeMin: 3.0, sizeMax: 7.0,
            speedMin: 5.0, speedMax: 14.0,
            glowEffect: GlowEffect.none,
            lineLinks: false,
            drift: DriftDirection.up,
            wobble: 1.0,
          ),
        ParticlePreset.cosmicStars => PresetConfig(
            colors: [const Color(0xFF00E5FF), const Color(0xFFFFD700), Colors.white],
            shape: ParticleShape.star,
            sizeMin: 2.0, sizeMax: 5.0,
            speedMin: 4.0, speedMax: 12.0,
            glowEffect: GlowEffect.pulse,
            lineLinks: true,
            drift: DriftDirection.random,
            wobble: 0.2,
            rotate: true,
          ),
        ParticlePreset.cursedSmoke => PresetConfig(
            colors: [const Color(0xFF6A1B9A), const Color(0xFF4A148C), const Color(0xFF311B92), const Color(0xFF8E24AA)],
            shape: ParticleShape.circle,
            sizeMin: 4.0, sizeMax: 9.0,
            speedMin: 3.0, speedMax: 10.0,
            glowEffect: GlowEffect.cursed,
            lineLinks: false,
            drift: DriftDirection.up,
            wobble: 0.8,
          ),
        ParticlePreset.brassCasings => PresetConfig(
            colors: [const Color(0xFFB8860B), const Color(0xFFCD853F), const Color(0xFFDAA520)],
            shape: ParticleShape.edge,
            sizeMin: 2.0, sizeMax: 4.5,
            speedMin: 20.0, speedMax: 45.0,
            glowEffect: GlowEffect.none,
            lineLinks: false,
            drift: DriftDirection.down,
            rotate: true,
          ),
        ParticlePreset.voidRift => PresetConfig(
            colors: [const Color(0xFF7B1FA2), const Color(0xFF512DA8), const Color(0xFF4527A0), const Color(0xFF9575CD)],
            shape: ParticleShape.triangle,
            sizeMin: 2.5, sizeMax: 6.0,
            speedMin: 5.0, speedMax: 15.0,
            glowEffect: GlowEffect.ripple,
            lineLinks: true,
            drift: DriftDirection.random,
            wobble: 0.6,
            rotate: true,
          ),
        ParticlePreset.bulletHell => PresetConfig(
            colors: [const Color(0xFFFF5252), const Color(0xFFFFEB3B), const Color(0xFFFFAB40)],
            shape: ParticleShape.circle,
            sizeMin: 1.5, sizeMax: 3.0,
            speedMin: 30.0, speedMax: 80.0,
            glowEffect: GlowEffect.none,
            lineLinks: false,
            drift: DriftDirection.random,
            wobble: 0.3,
          ),
        ParticlePreset.unicornSparkles => PresetConfig(
            colors: [const Color(0xFFFF69B4), const Color(0xFFE040FB), const Color(0xFF00E5FF), const Color(0xFFFFD700)],
            shape: ParticleShape.star,
            sizeMin: 2.0, sizeMax: 6.0,
            speedMin: 3.0, speedMax: 10.0,
            glowEffect: GlowEffect.pulse,
            lineLinks: false,
            drift: DriftDirection.random,
            wobble: 0.4,
            rotate: true,
          ),
        ParticlePreset.cosmicDust => PresetConfig(
            colors: [const Color(0xFF1A237E), const Color(0xFF311B92), const Color(0xFF00838F), const Color(0xFF1DE9F6)],
            shape: ParticleShape.circle,
            sizeMin: 1.0, sizeMax: 3.5,
            speedMin: 2.0, speedMax: 8.0,
            glowEffect: GlowEffect.ripple,
            lineLinks: true,
            drift: DriftDirection.random,
            wobble: 0.3,
          ),
        ParticlePreset.goldenSparkle => PresetConfig(
            colors: [const Color(0xFFFFD700), const Color(0xFFFFC107), const Color(0xFFFFEB3B), const Color(0xFFFF8F00)],
            shape: ParticleShape.star,
            sizeMin: 2.0, sizeMax: 5.0,
            speedMin: 4.0, speedMax: 12.0,
            glowEffect: GlowEffect.smokey,
            lineLinks: false,
            drift: DriftDirection.random,
            wobble: 0.2,
            rotate: true,
          ),
        ParticlePreset.rainbowConfetti => PresetConfig(
            colors: [const Color(0xFFFF5252), const Color(0xFFFFEB3B), const Color(0xFF69F0AE), const Color(0xFF40C4FF), const Color(0xFFE040FB), const Color(0xFFFFAB40)],
            shape: ParticleShape.edge,
            sizeMin: 2.5, sizeMax: 5.0,
            speedMin: 15.0, speedMax: 40.0,
            glowEffect: GlowEffect.none,
            lineLinks: false,
            drift: DriftDirection.down,
            wobble: 1.2,
            rotate: true,
          ),
        ParticlePreset.bulletKin => PresetConfig(
            colors: [const Color(0xFFDAA520), const Color(0xFFCD853F), const Color(0xFFB8860B), const Color(0xFFFFD700)],
            shape: ParticleShape.bullet,
            sizeMin: 3.0, sizeMax: 7.0,
            speedMin: 5.0, speedMax: 15.0,
            glowEffect: GlowEffect.smokey,
            lineLinks: false,
            drift: DriftDirection.up,
            wobble: 0.8,
          ),
        ParticlePreset.heartContainers => PresetConfig(
            colors: [const Color(0xFFFF5252), const Color(0xFFE91E63), const Color(0xFFF06292), const Color(0xFFD32F2F)],
            shape: ParticleShape.heart,
            sizeMin: 3.0, sizeMax: 6.0,
            speedMin: 4.0, speedMax: 12.0,
            glowEffect: GlowEffect.pulse,
            lineLinks: false,
            drift: DriftDirection.up,
            wobble: 0.5,
          ),
        ParticlePreset.cursedSkulls => PresetConfig(
            colors: [const Color(0xFF6A1B9A), const Color(0xFF4A148C), const Color(0xFF8E24AA), const Color(0xFF2E7D32)],
            shape: ParticleShape.skull,
            sizeMin: 3.5, sizeMax: 7.0,
            speedMin: 3.0, speedMax: 10.0,
            glowEffect: GlowEffect.cursed,
            lineLinks: false,
            drift: DriftDirection.random,
            wobble: 0.6,
          ),
        ParticlePreset.masterRounds => PresetConfig(
            colors: [const Color(0xFFFFD700), const Color(0xFFFFC107), const Color(0xFFFF8F00), const Color(0xFFFFEB3B)],
            shape: ParticleShape.circle,
            sizeMin: 3.0, sizeMax: 6.0,
            speedMin: 6.0, speedMax: 16.0,
            glowEffect: GlowEffect.smokey,
            lineLinks: false,
            drift: DriftDirection.down,
            wobble: 0.3,
            rotate: true,
          ),
        ParticlePreset.jamHexes => PresetConfig(
            colors: [const Color(0xFF6A1B9A), const Color(0xFF4A148C), const Color(0xFF8E24AA), const Color(0xFFAB47BC)],
            shape: ParticleShape.hexagon,
            sizeMin: 3.0, sizeMax: 6.5,
            speedMin: 4.0, speedMax: 14.0,
            glowEffect: GlowEffect.cursed,
            lineLinks: true,
            drift: DriftDirection.random,
            wobble: 0.5,
            rotate: true,
          ),
      };
}

enum ParticleShape { circle, star, triangle, edge, bullet, heart, skull, hexagon }

enum GlowEffect { none, smokey, ripple, pulse, cursed }

extension GlowEffectX on GlowEffect {
  String get label => switch (this) {
        GlowEffect.none => 'No Glow',
        GlowEffect.smokey => 'Smokey',
        GlowEffect.ripple => 'Ripple',
        GlowEffect.pulse => 'Pulse',
        GlowEffect.cursed => 'Cursed',
      };
}

enum DriftDirection { up, down, random }

// =============================================================================
// Preset config — bundled defaults per preset
// =============================================================================

class PresetConfig {
  final List<Color> colors;
  final ParticleShape shape;
  final double sizeMin;
  final double sizeMax;
  final double speedMin;
  final double speedMax;
  final GlowEffect glowEffect;
  final bool lineLinks;
  final DriftDirection drift;
  final double wobble; // 0 = straight, 1.5 = strong sway
  final bool rotate; // true = shapes spin slowly

  const PresetConfig({
    required this.colors,
    required this.shape,
    required this.sizeMin,
    required this.sizeMax,
    required this.speedMin,
    required this.speedMax,
    required this.glowEffect,
    required this.lineLinks,
    required this.drift,
    this.wobble = 0.0,
    this.rotate = false,
  });
}

// =============================================================================
// Runtime particle model
// =============================================================================

class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double baseSize;
  Color color;
  double phase;
  double depth; // 0.4 (far) to 1.3 (near)
  double wobbleAmp;
  double wobblePhase;
  double rotation;
  double rotationSpeed;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.baseSize,
    required this.color,
    required this.phase,
    required this.depth,
    this.wobbleAmp = 0.0,
    this.wobblePhase = 0.0,
    this.rotation = 0.0,
    this.rotationSpeed = 0.0,
  });
}

// =============================================================================
// ParticleField — the main widget
// =============================================================================

class ParticleField extends StatefulWidget {
  final ParticlePreset preset;
  final int count;
  final double sizeScale; // 0.3 (tiny) to 2.0 (medium)
  final double opacity; // 0.0 to 1.0
  final GlowEffect? glowOverride;
  final bool? lineLinksOverride;
  final bool bounce;

  const ParticleField({
    super.key,
    required this.preset,
    this.count = 16,
    this.sizeScale = 1.0,
    this.opacity = 0.7,
    this.glowOverride,
    this.lineLinksOverride,
    this.bounce = false,
  });

  @override
  State<ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<ParticleField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  final Stopwatch _sw = Stopwatch();
  final List<_Particle> _particles = [];
  final math.Random _rng = math.Random();
  Size? _lastSize;
  double _lastT = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _sw.start();
  }

  @override
  void didUpdateWidget(ParticleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preset != widget.preset ||
        oldWidget.count != widget.count ||
        oldWidget.sizeScale != widget.sizeScale) {
      _particles.clear();
      _lastSize = null;
    }
  }

  void _ensureParticles(Size size) {
    if (_particles.isNotEmpty && _lastSize == size) return;
    _particles.clear();
    _lastSize = size;

    final cfg = widget.preset.config;
    for (var i = 0; i < widget.count; i++) {
      _spawnParticle(size, cfg);
    }
  }

  void _spawnParticle(Size size, PresetConfig cfg) {
    final drift = cfg.drift;
    double vx, vy;

    switch (drift) {
      case DriftDirection.up:
        vx = (_rng.nextDouble() - 0.5) * cfg.speedMin;
        vy = -(cfg.speedMin + _rng.nextDouble() * (cfg.speedMax - cfg.speedMin));
        break;
      case DriftDirection.down:
        vx = (_rng.nextDouble() - 0.5) * cfg.speedMin;
        vy = cfg.speedMin + _rng.nextDouble() * (cfg.speedMax - cfg.speedMin);
        break;
      case DriftDirection.random:
        final angle = _rng.nextDouble() * 2 * math.pi;
        final speed = cfg.speedMin + _rng.nextDouble() * (cfg.speedMax - cfg.speedMin);
        vx = math.cos(angle) * speed;
        vy = math.sin(angle) * speed;
        break;
    }

    // Per-particle color brightness jitter — breaks flat palette swarms
    final baseColor = cfg.colors[_rng.nextInt(cfg.colors.length)];
    final hsl = HSLColor.fromColor(baseColor);
    final lightJitter = 0.85 + _rng.nextDouble() * 0.3; // 0.85–1.15
    final jitteredColor = hsl
        .withLightness((hsl.lightness * lightJitter).clamp(0.0, 1.0))
        .toColor();

    _particles.add(_Particle(
      x: _rng.nextDouble() * size.width,
      y: _rng.nextDouble() * size.height,
      vx: vx,
      vy: vy,
      baseSize: cfg.sizeMin + _rng.nextDouble() * (cfg.sizeMax - cfg.sizeMin),
      color: jitteredColor,
      phase: _rng.nextDouble(),
      depth: 0.4 + _rng.nextDouble() * 0.9,
      wobbleAmp: cfg.wobble,
      wobblePhase: _rng.nextDouble() * 2 * math.pi,
      rotation: _rng.nextDouble() * 2 * math.pi,
      rotationSpeed: cfg.rotate ? (_rng.nextDouble() - 0.5) * 2.0 : 0.0,
    ));
  }

  @override
  void dispose() {
    _sw.stop();
    _ticker.dispose();
    super.dispose();
  }

  void _update(double t, Size size) {
    final dt = (t - _lastT).clamp(0.001, 0.05);
    _lastT = t;
    final tilt = ThemeOverlay.tiltNotifier.value;

    // ponytail: tilt is applied as a per-frame offset, not accumulated velocity.
    // Particles drift in the tilt direction and return via wrap/bounce when tilt
    // stops. This is correct for ambient dust — upgrade to spring-back if physical
    // inertia is ever needed.
    for (final p in _particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;

      // Perpendicular wobble — sine offset at ~2 Hz, amplitude scaled by depth
      if (p.wobbleAmp > 0) {
        final wobble = math.sin(t * 2.0 + p.wobblePhase) * p.wobbleAmp * p.depth;
        final speed = math.sqrt(p.vx * p.vx + p.vy * p.vy);
        if (speed > 0.1) {
          p.x += (-p.vy / speed) * wobble * dt * 10;
          p.y += (p.vx / speed) * wobble * dt * 10;
        }
      }

      // Rotation
      if (p.rotationSpeed != 0) {
        p.rotation += p.rotationSpeed * dt;
      }

      p.x += tilt.dx * 0.15 * p.depth;
      p.y += tilt.dy * 0.10 * p.depth;

      if (widget.bounce) {
        if (p.x < 0) { p.x = 0; p.vx = -p.vx; }
        if (p.x > size.width) { p.x = size.width; p.vx = -p.vx; }
        if (p.y < 0) { p.y = 0; p.vy = -p.vy; }
        if (p.y > size.height) { p.y = size.height; p.vy = -p.vy; }
      } else {
        if (p.x < -10) p.x = size.width + 10;
        if (p.x > size.width + 10) p.x = -10;
        if (p.y < -10) p.y = size.height + 10;
        if (p.y > size.height + 10) p.y = -10;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ticker,
        builder: (_, __) {
          return LayoutBuilder(
            builder: (_, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              if (size == Size.zero) return const SizedBox.shrink();
              _ensureParticles(size);

              final t = _sw.elapsedMilliseconds / 1000.0;
              _update(t, size);

              return CustomPaint(
                painter: _ParticlePainter(
                  t: t,
                  particles: _particles,
                  config: widget.preset.config,
                  sizeScale: widget.sizeScale,
                  opacity: widget.opacity,
                  glowEffect: widget.glowOverride ?? widget.preset.config.glowEffect,
                  lineLinks: widget.lineLinksOverride ?? widget.preset.config.lineLinks,
                ),
                size: size,
              );
            },
          );
        },
      ),
    );
  }
}

// =============================================================================
// ParticlePainter — single painter for all presets and effects
// =============================================================================

class _ParticlePainter extends CustomPainter {
  final double t;
  final List<_Particle> particles;
  final PresetConfig config;
  final double sizeScale;
  final double opacity;
  final GlowEffect glowEffect;
  final bool lineLinks;

  _ParticlePainter({
    required this.t,
    required this.particles,
    required this.config,
    required this.sizeScale,
    required this.opacity,
    required this.glowEffect,
    required this.lineLinks,
  });

  final _paint = Paint()..style = PaintingStyle.fill;
  final _linePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty || size == Size.zero) return;

    final w = size.width;
    final h = size.height;
    final lineDist = (w * 0.12).clamp(60.0, 160.0);

    // ponytail: O(n²) pair check per frame. At count=32 that's 496 pairs — fine.
    // If max count ever increases above ~64, switch to spatial hashing.
    if (lineLinks && particles.length > 1) {
      for (var i = 0; i < particles.length; i++) {
        for (var j = i + 1; j < particles.length; j++) {
          final a = particles[i];
          final b = particles[j];
          final dx = a.x - b.x;
          final dy = a.y - b.y;
          final dist = math.sqrt(dx * dx + dy * dy);
          if (dist < lineDist) {
            final linkAlpha = (1.0 - dist / lineDist) * opacity * 0.4;
            _linePaint.color = a.color.withValues(alpha: linkAlpha);
            canvas.drawLine(Offset(a.x, a.y), Offset(b.x, b.y), _linePaint);
          }
        }
      }
    }

    // Draw particles
    for (final p in particles) {
      final depthAlpha = 0.35 + 0.65 * p.depth;
      final baseAlpha = opacity * depthAlpha;

      // Edge fade — smoothstep for softer falloff
      double edgeFade = 1.0;
      const edgeThreshold = 24.0;
      double smoothstep(double e0, double e1, double x) {
        final t = ((x - e0) / (e1 - e0)).clamp(0.0, 1.0);
        return t * t * (3 - 2 * t);
      }
      if (p.x < edgeThreshold) {
        edgeFade = smoothstep(0, edgeThreshold, p.x);
      } else if (p.x > w - edgeThreshold) {
        edgeFade = smoothstep(0, edgeThreshold, w - p.x);
      }
      if (p.y < edgeThreshold) {
        edgeFade = math.min(edgeFade, smoothstep(0, edgeThreshold, p.y));
      } else if (p.y > h - edgeThreshold) {
        edgeFade = math.min(edgeFade, smoothstep(0, edgeThreshold, h - p.y));
      }

      final alpha = baseAlpha * edgeFade;
      if (alpha <= 0.01) continue;

      // Size with optional pulse effect + subtle breathing for all particles
      var drawSize = p.baseSize * sizeScale * p.depth;
      if (glowEffect == GlowEffect.pulse) {
        drawSize *= 0.7 + 0.3 * math.sin(t * 3.0 + p.phase * 10).abs();
      } else {
        drawSize *= 0.92 + 0.08 * math.sin(t * 1.5 + p.phase * 6);
      }

      final color = p.color.withValues(alpha: alpha);

      // Apply glow effect
      switch (glowEffect) {
        case GlowEffect.none:
          _paint.maskFilter = null;
          break;
        case GlowEffect.smokey:
          _paint.maskFilter = MaskFilter.blur(BlurStyle.normal, drawSize * 0.8);
          break;
        case GlowEffect.pulse:
          _paint.maskFilter = MaskFilter.blur(BlurStyle.normal, drawSize * 0.3);
          break;
        case GlowEffect.cursed:
          // Hue-shifted outer aura — oscillates between purple and sickly green
          final cursedShift = math.sin(t * 1.5 + p.phase * 6) * 0.5 + 0.5;
          final cursedHsl = HSLColor.fromColor(p.color)
              .withHue((270 + cursedShift * 60) % 360);
          _paint.maskFilter = MaskFilter.blur(BlurStyle.normal, drawSize * 1.2);
          _paint.color = cursedHsl.toColor().withValues(alpha: alpha * 0.3);
          canvas.drawCircle(Offset(p.x, p.y), drawSize * 1.5, _paint);
          break;
        case GlowEffect.ripple:
          _paint.maskFilter = null;
          // Two expanding ripple rings — staggered phase for richer effect
          for (final offset in [0.0, 0.5]) {
            final ripplePhase = (t * 1.5 + p.phase + offset) % 1.0;
            final rippleR = drawSize * (1.5 + ripplePhase * 3.0);
            final rippleAlpha = alpha * (1.0 - ripplePhase) * 0.4;
            _paint.color = p.color.withValues(alpha: rippleAlpha);
            canvas.drawCircle(Offset(p.x, p.y), rippleR, _paint);
          }
          break;
      }

      _paint.color = color;

      // Draw shape
      if (p.rotationSpeed != 0 && config.shape != ParticleShape.circle) {
        canvas.save();
        canvas.translate(p.x, p.y);
        canvas.rotate(p.rotation);
        switch (config.shape) {
          case ParticleShape.star:
            _drawStar(canvas, 0, 0, drawSize, _paint);
            if (glowEffect != GlowEffect.none) {
              _paint.maskFilter = null;
              _paint.color = Colors.white.withValues(alpha: alpha * 0.6);
              canvas.drawCircle(Offset.zero, drawSize * 0.2, _paint);
            }
            break;
          case ParticleShape.triangle:
            _drawTriangle(canvas, 0, 0, drawSize, _paint);
            break;
          case ParticleShape.edge:
            final r = drawSize;
            canvas.drawRect(
              Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 1.4),
              _paint,
            );
            break;
          case ParticleShape.bullet:
            _drawBullet(canvas, 0, 0, drawSize, _paint);
            break;
          case ParticleShape.heart:
            _drawHeart(canvas, 0, 0, drawSize, _paint);
            if (glowEffect != GlowEffect.none) {
              _paint.maskFilter = null;
              _paint.color = Colors.white.withValues(alpha: alpha * 0.5);
              canvas.drawCircle(Offset.zero, drawSize * 0.15, _paint);
            }
            break;
          case ParticleShape.skull:
            _drawSkull(canvas, 0, 0, drawSize, _paint);
            break;
          case ParticleShape.hexagon:
            _drawHexagon(canvas, 0, 0, drawSize, _paint);
            break;
          case ParticleShape.circle:
            break; // handled below
        }
        canvas.restore();
      } else {
        switch (config.shape) {
          case ParticleShape.circle:
            canvas.drawCircle(Offset(p.x, p.y), drawSize, _paint);
            if (glowEffect != GlowEffect.none) {
              // Bright core
              _paint.maskFilter = null;
              _paint.color = Colors.white.withValues(alpha: alpha * 0.5);
              canvas.drawCircle(Offset(p.x, p.y), drawSize * 0.3, _paint);
            }
            break;

          case ParticleShape.star:
            _drawStar(canvas, p.x, p.y, drawSize, _paint);
            if (glowEffect != GlowEffect.none) {
              _paint.maskFilter = null;
              _paint.color = Colors.white.withValues(alpha: alpha * 0.6);
              canvas.drawCircle(Offset(p.x, p.y), drawSize * 0.2, _paint);
            }
            break;

          case ParticleShape.triangle:
            _drawTriangle(canvas, p.x, p.y, drawSize, _paint);
            break;

          case ParticleShape.edge:
            final r = drawSize;
            canvas.drawRect(
              Rect.fromCenter(center: Offset(p.x, p.y), width: r * 2, height: r * 1.4),
              _paint,
            );
            break;
          case ParticleShape.bullet:
            _drawBullet(canvas, p.x, p.y, drawSize, _paint);
            if (glowEffect != GlowEffect.none) {
              _paint.maskFilter = null;
              _paint.color = Colors.white.withValues(alpha: alpha * 0.4);
              canvas.drawCircle(Offset(p.x, p.y - drawSize * 0.3), drawSize * 0.15, _paint);
            }
            break;
          case ParticleShape.heart:
            _drawHeart(canvas, p.x, p.y, drawSize, _paint);
            if (glowEffect != GlowEffect.none) {
              _paint.maskFilter = null;
              _paint.color = Colors.white.withValues(alpha: alpha * 0.5);
              canvas.drawCircle(Offset(p.x, p.y), drawSize * 0.15, _paint);
            }
            break;
          case ParticleShape.skull:
            _drawSkull(canvas, p.x, p.y, drawSize, _paint);
            break;
          case ParticleShape.hexagon:
            _drawHexagon(canvas, p.x, p.y, drawSize, _paint);
            break;
        }
      }

      // Reset mask for next particle
      _paint.maskFilter = null;
    }
  }

  void _drawStar(Canvas canvas, double cx, double cy, double r, Paint paint) {
    final path = Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx + r * 0.22, cy - r * 0.22)
      ..lineTo(cx + r, cy)
      ..lineTo(cx + r * 0.22, cy + r * 0.22)
      ..lineTo(cx, cy + r)
      ..lineTo(cx - r * 0.22, cy + r * 0.22)
      ..lineTo(cx - r, cy)
      ..lineTo(cx - r * 0.22, cy - r * 0.22)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawTriangle(Canvas canvas, double cx, double cy, double r, Paint paint) {
    final path = Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx + r * 0.866, cy + r * 0.5)
      ..lineTo(cx - r * 0.866, cy + r * 0.5)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawBullet(Canvas canvas, double cx, double cy, double r, Paint paint) {
    final path = Path()
      ..moveTo(cx, cy - r * 1.2)
      ..lineTo(cx + r * 0.5, cy - r * 0.3)
      ..quadraticBezierTo(cx + r * 0.7, cy + r * 0.3, cx, cy + r * 0.6)
      ..quadraticBezierTo(cx - r * 0.7, cy + r * 0.3, cx - r * 0.5, cy - r * 0.3)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawHeart(Canvas canvas, double cx, double cy, double r, Paint paint) {
    final path = Path()
      ..moveTo(cx, cy + r * 0.7)
      ..cubicTo(cx + r * 1.1, cy + r * 0.2, cx + r * 0.65, cy - r * 0.85, cx, cy - r * 0.25)
      ..cubicTo(cx - r * 0.65, cy - r * 0.85, cx - r * 1.1, cy + r * 0.2, cx, cy + r * 0.7)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawSkull(Canvas canvas, double cx, double cy, double r, Paint paint) {
    canvas.drawCircle(Offset(cx, cy - r * 0.15), r * 0.65, paint);
    final jawRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + r * 0.35), width: r * 0.7, height: r * 0.45),
      Radius.circular(r * 0.12),
    );
    canvas.drawRRect(jawRect, paint);
    final eyePaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    canvas.drawCircle(Offset(cx - r * 0.22, cy - r * 0.2), r * 0.14, eyePaint);
    canvas.drawCircle(Offset(cx + r * 0.22, cy - r * 0.2), r * 0.14, eyePaint);
  }

  void _drawHexagon(Canvas canvas, double cx, double cy, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 2;
      final px = cx + r * math.cos(angle);
      final py = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  // ponytail: always-repaint is correct for animation-driven painters.
  // RepaintBoundary in the parent widget isolates this from the rest of the app.
  // If ever nested in a scrollable, add a VisibilityDetector to pause offscreen.
  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

// =============================================================================
// ParticlePreviewPicker — swipeable live mini-canvas for settings UI
// =============================================================================

class ParticlePreviewPicker extends StatefulWidget {
  final ParticlePreset selected;
  final ValueChanged<ParticlePreset> onChanged;
  final Color accentColor;

  const ParticlePreviewPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  State<ParticlePreviewPicker> createState() => _ParticlePreviewPickerState();
}

class _ParticlePreviewPickerState extends State<ParticlePreviewPicker> {
  late PageController _pageCtrl;
  late int _page;

  @override
  void initState() {
    super.initState();
    _page = widget.selected.index;
    _pageCtrl = PageController(initialPage: _page);
  }

  @override
  void didUpdateWidget(ParticlePreviewPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected && widget.selected.index != _page) {
      _page = widget.selected.index;
      _pageCtrl.animateToPage(
        _page,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final presets = ParticlePreset.values;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 120,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: presets.length,
            onPageChanged: (i) {
              setState(() => _page = i);
              widget.onChanged(presets[i]);
            },
            itemBuilder: (_, i) {
              final preset = presets[i];
              final isSelected = i == _page;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? widget.accentColor.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.08),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Stack(
                  children: [
                    // Dark backing
                    Positioned.fill(child: Container(color: const Color(0xFF1E1E22))),
                    // Live particle preview only on the selected page
                    if (isSelected)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: ParticleField(
                            preset: preset,
                            count: 12,
                            sizeScale: 0.8,
                            opacity: 0.8,
                          ),
                        ),
                      ),
                    // Label overlay at bottom
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                        child: Text(
                          preset.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              color: Colors.white54,
              onPressed: _page > 0
                  ? () {
                      _pageCtrl.animateToPage(
                        _page - 1,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      );
                    }
                  : null,
            ),
            Text(
              '${_page + 1} / ${presets.length}',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white38,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              color: Colors.white54,
              onPressed: _page < presets.length - 1
                  ? () {
                      _pageCtrl.animateToPage(
                        _page + 1,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      );
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

