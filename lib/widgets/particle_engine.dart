import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme_overlay.dart' show ThemeOverlay;
part 'particle_engine/particle_presets.dart';
part 'particle_engine/particle_types.dart';

// =============================================================================
// Enums
// =============================================================================

// =============================================================================
// Particle Color Schemas — 16 named color palettes that can override any
// preset's default colors. Works with ALL themes and palettes.
// =============================================================================

// =============================================================================
// ParticleType — the user-facing shape system (replaces named presets).
// Each type is a curated combo of shape + motion + glow; colors come
// from the active theme's 3 flavored schemas.
// =============================================================================

// =============================================================================
// Preset config — bundled defaults per preset
// =============================================================================

// =============================================================================
// Runtime particle model
// =============================================================================

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
  final List<Color>? colorsOverride; // per-theme/per-palette color injection
  final bool bounce;
  final double speedMultiplier; // 0.3 (very slow) to 2.5 (very fast)

  /// Typed-system override — when set, this config is used instead of
  /// `preset.config` entirely (the ParticleType path).
  final PresetConfig? config;

  /// Whether device tilt nudges particles (the "move when moving
  /// phone" toggle). When false, the existing gyro feed is ignored.
  final bool tiltEnabled;

  const ParticleField({
    super.key,
    required this.preset,
    this.config,
    this.tiltEnabled = true,
    this.count = 16,
    this.sizeScale = 1.0,
    this.opacity = 0.7,
    this.glowOverride,
    this.lineLinksOverride,
    this.colorsOverride,
    this.bounce = false,
    this.speedMultiplier = 1.0,
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
        oldWidget.config != widget.config ||
        oldWidget.count != widget.count ||
        oldWidget.sizeScale != widget.sizeScale ||
        oldWidget.colorsOverride != widget.colorsOverride) {
      _particles.clear();
      _lastSize = null;
    }
    // Clear trails when preset changes (trail config may differ)
    if (oldWidget.preset != widget.preset) {
      for (final p in _particles) {
        p.trail.clear();
      }
    }
  }

  void _ensureParticles(Size size) {
    if (_particles.isNotEmpty && _lastSize == size) return;
    _particles.clear();
    _lastSize = size;

    final cfg =
        widget.config ??
        (widget.colorsOverride != null
            ? _withColors(widget.preset.config, widget.colorsOverride!)
            : widget.preset.config);
    for (var i = 0; i < widget.count; i++) {
      _spawnParticle(size, cfg);
    }
  }

  /// ponytail: shallow copy of [PresetConfig] with replaced colors.
  /// Used for per-palette particle color injection without adding new enum values.
  static PresetConfig _withColors(PresetConfig base, List<Color> colors) {
    return base.copyWith(colors: colors);
  }

  void _spawnParticle(Size size, PresetConfig cfg) {
    final drift = cfg.drift;
    double vx, vy;

    switch (drift) {
      case DriftDirection.up:
        vx = (_rng.nextDouble() - 0.5) * cfg.speedMin;
        vy =
            -(cfg.speedMin + _rng.nextDouble() * (cfg.speedMax - cfg.speedMin));
        break;
      case DriftDirection.down:
        vx = (_rng.nextDouble() - 0.5) * cfg.speedMin;
        vy = cfg.speedMin + _rng.nextDouble() * (cfg.speedMax - cfg.speedMin);
        break;
      case DriftDirection.random:
        final angle = _rng.nextDouble() * 2 * math.pi;
        final speed =
            cfg.speedMin + _rng.nextDouble() * (cfg.speedMax - cfg.speedMin);
        vx = math.cos(angle) * speed;
        vy = math.sin(angle) * speed;
        break;
    }

    // Per-particle color brightness jitter — breaks flat palette swarms
    final baseColor = cfg.colors[_rng.nextInt(cfg.colors.length)];
    final hsl = HSLColor.fromColor(baseColor);
    final lightJitter = 0.85 + _rng.nextDouble() * 0.3; // 0.85–1.15
    final jitteredColor =
        hsl
            .withLightness((hsl.lightness * lightJitter).clamp(0.0, 1.0))
            .toColor();

    // Lifetime: 0 = infinite (legacy wrap mode), >0 = finite with fade
    final maxLife =
        cfg.hasLifetime
            ? cfg.lifetimeMin +
                _rng.nextDouble() * (cfg.lifetimeMax - cfg.lifetimeMin)
            : 0.0;

    _particles.add(
      _Particle(
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
        // Upgrade fields:
        age: 0.0,
        maxLifetime: maxLife,
        hueOffset: 0.0,
        hueDriftSpeed: cfg.hueDriftSpeed * (0.7 + _rng.nextDouble() * 0.6),
        rotationAccel: cfg.rotate ? (_rng.nextDouble() - 0.5) * 0.8 : 0.0,
        shimmerPhase: _rng.nextDouble() * 2 * math.pi,
        turbulencePhase: _rng.nextDouble() * 2 * math.pi,
      ),
    );
  }

  /// Respawn a particle at a new random position with fresh lifetime.
  /// Used when lifetime expires — smooth fade-in replaces the old wrap pop.
  void _respawnParticle(_Particle p, Size size, PresetConfig cfg) {
    final drift = cfg.drift;
    double vx, vy;
    switch (drift) {
      case DriftDirection.up:
        vx = (_rng.nextDouble() - 0.5) * cfg.speedMin;
        vy =
            -(cfg.speedMin + _rng.nextDouble() * (cfg.speedMax - cfg.speedMin));
        break;
      case DriftDirection.down:
        vx = (_rng.nextDouble() - 0.5) * cfg.speedMin;
        vy = cfg.speedMin + _rng.nextDouble() * (cfg.speedMax - cfg.speedMin);
        break;
      case DriftDirection.random:
        final angle = _rng.nextDouble() * 2 * math.pi;
        final speed =
            cfg.speedMin + _rng.nextDouble() * (cfg.speedMax - cfg.speedMin);
        vx = math.cos(angle) * speed;
        vy = math.sin(angle) * speed;
        break;
    }
    final baseColor = cfg.colors[_rng.nextInt(cfg.colors.length)];
    final hsl = HSLColor.fromColor(baseColor);
    final lightJitter = 0.85 + _rng.nextDouble() * 0.3;
    p.x = _rng.nextDouble() * size.width;
    p.y = _rng.nextDouble() * size.height;
    p.vx = vx;
    p.vy = vy;
    p.color =
        hsl
            .withLightness((hsl.lightness * lightJitter).clamp(0.0, 1.0))
            .toColor();
    p.baseSize = cfg.sizeMin + _rng.nextDouble() * (cfg.sizeMax - cfg.sizeMin);
    p.phase = _rng.nextDouble();
    p.depth = 0.4 + _rng.nextDouble() * 0.9;
    p.rotation = _rng.nextDouble() * 2 * math.pi;
    p.rotationSpeed = cfg.rotate ? (_rng.nextDouble() - 0.5) * 2.0 : 0.0;
    p.age = 0.0;
    p.maxLifetime =
        cfg.hasLifetime
            ? cfg.lifetimeMin +
                _rng.nextDouble() * (cfg.lifetimeMax - cfg.lifetimeMin)
            : 0.0;
    p.hueOffset = 0.0;
    p.hueDriftSpeed = cfg.hueDriftSpeed * (0.7 + _rng.nextDouble() * 0.6);
    p.rotationAccel = cfg.rotate ? (_rng.nextDouble() - 0.5) * 0.8 : 0.0;
    p.shimmerPhase = _rng.nextDouble() * 2 * math.pi;
    p.turbulencePhase = _rng.nextDouble() * 2 * math.pi;
    p.trail.clear();
  }

  @override
  void dispose() {
    _sw.stop();
    _ticker.dispose();
    super.dispose();
  }

  void _update(double t, Size size) {
    final dt = (t - _lastT).clamp(0.001, 0.05) * widget.speedMultiplier;
    _lastT = t;
    final tilt =
        widget.tiltEnabled ? ThemeOverlay.tiltNotifier.value : Offset.zero;
    final cfg =
        widget.config ??
        (widget.colorsOverride != null
            ? _withColors(widget.preset.config, widget.colorsOverride!)
            : widget.preset.config);

    for (final p in _particles) {
      p.age += dt;

      // ── Lifetime system: fade out + respawn ──
      if (p.maxLifetime > 0 && p.age >= p.maxLifetime) {
        _respawnParticle(p, size, cfg);
        continue;
      }

      p.x += p.vx * dt;
      p.y += p.vy * dt;

      // ── Turbulence field: organic noise-based velocity perturbation ──
      if (cfg.turbulence > 0) {
        // ponytail: cheap pseudo-curl-noise via layered sines. Not true
        // Perlin but visually convincing for ambient drift. Upgrade to
        // real curl noise if higher fidelity is ever needed.
        final nx =
            math.sin(t * 0.7 + p.turbulencePhase + p.x * 0.01) +
            math.cos(t * 1.3 + p.turbulencePhase * 1.7 + p.y * 0.008);
        final ny =
            math.cos(t * 0.5 + p.turbulencePhase * 1.3 + p.x * 0.012) +
            math.sin(t * 1.1 + p.turbulencePhase + p.y * 0.009);
        p.vx += nx * cfg.turbulence * 8.0 * dt;
        p.vy += ny * cfg.turbulence * 8.0 * dt;
        // Damping so turbulence doesn't accelerate to infinity
        p.vx *= 1.0 - 0.5 * dt;
        p.vy *= 1.0 - 0.5 * dt;
      }

      // Perpendicular wobble — sine offset at ~2 Hz, amplitude scaled by depth
      if (p.wobbleAmp > 0) {
        final wobble =
            math.sin(t * 2.0 + p.wobblePhase) * p.wobbleAmp * p.depth;
        final speed = math.sqrt(p.vx * p.vx + p.vy * p.vy);
        if (speed > 0.1) {
          p.x += (-p.vy / speed) * wobble * dt * 10;
          p.y += (p.vx / speed) * wobble * dt * 10;
        }
      }

      // ── Organic rotation: acceleration + damping ──
      if (p.rotationAccel != 0) {
        p.rotationSpeed += p.rotationAccel * dt;
        // Damping toward zero + clamp
        p.rotationSpeed *= 1.0 - 0.3 * dt;
        p.rotationSpeed = p.rotationSpeed.clamp(-3.0, 3.0);
      }
      if (p.rotationSpeed != 0) {
        p.rotation += p.rotationSpeed * dt;
      }

      // ── Color drift: slow hue cycling ──
      if (p.hueDriftSpeed > 0) {
        p.hueOffset += p.hueDriftSpeed * dt;
      }

      // ── Trail: capture past positions ──
      if (cfg.trailLength > 0) {
        p.trail.add(_TrailPoint(x: p.x, y: p.y, age: 0.0));
        final maxTrailAge = cfg.trailLength * 0.5; // 0.15s - 0.3s
        for (final tp in p.trail) {
          tp.age += dt;
        }
        p.trail.removeWhere((tp) => tp.age > maxTrailAge);
        // ponytail: O(n) per particle per frame for trail cleanup. At
        // trailLength=0.6 and 60fps that's ~18 points per particle. Fine.
      }

      p.x += tilt.dx * 0.15 * p.depth;
      p.y += tilt.dy * 0.10 * p.depth;

      // ── Boundary handling ──
      if (p.maxLifetime > 0) {
        // Lifetime mode: wrap but respawn will handle fresh entry
        if (p.x < -20 ||
            p.x > size.width + 20 ||
            p.y < -20 ||
            p.y > size.height + 20) {
          _respawnParticle(p, size, cfg);
        }
      } else if (widget.bounce) {
        if (p.x < 0) {
          p.x = 0;
          p.vx = -p.vx;
        }
        if (p.x > size.width) {
          p.x = size.width;
          p.vx = -p.vx;
        }
        if (p.y < 0) {
          p.y = 0;
          p.vy = -p.vy;
        }
        if (p.y > size.height) {
          p.y = size.height;
          p.vy = -p.vy;
        }
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
        builder: (_, _) {
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
                  config:
                      widget.colorsOverride != null
                          ? _withColors(
                            widget.preset.config,
                            widget.colorsOverride!,
                          )
                          : widget.preset.config,
                  sizeScale: widget.sizeScale,
                  opacity: widget.opacity,
                  glowEffect:
                      widget.glowOverride ?? widget.preset.config.glowEffect,
                  lineLinks:
                      widget.lineLinksOverride ??
                      widget.preset.config.lineLinks,
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
  final _linePaint =
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

  /// Apply hue rotation to a color (for color drift effect).
  Color _applyHueOffset(Color color, double hueOffset) {
    if (hueOffset == 0.0) return color;
    final hsl = HSLColor.fromColor(color);
    return hsl.withHue((hsl.hue + hueOffset) % 360).toColor();
  }

  /// Lifetime fade: smoothstep in at birth, smoothstep out at death.
  double _lifetimeAlpha(_Particle p) {
    if (p.maxLifetime <= 0) return 1.0;
    const fadeIn = 0.4; // 0.4s fade in
    final fadeOut = (p.maxLifetime * 0.25).clamp(0.3, 1.0); // 25% of life
    double smoothstep(double e0, double e1, double x) {
      final t = ((x - e0) / (e1 - e0)).clamp(0.0, 1.0);
      return t * t * (3 - 2 * t);
    }

    final fadeInAlpha = smoothstep(0.0, fadeIn, p.age);
    final fadeOutAlpha = smoothstep(0.0, fadeOut, p.maxLifetime - p.age);
    return fadeInAlpha * fadeOutAlpha;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty || size == Size.zero) return;

    final w = size.width;
    final h = size.height;
    final lineDist = (w * 0.12).clamp(60.0, 160.0);

    // ── Gradient line links — color blends from A to B, thickness varies ──
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
            final proximity = 1.0 - dist / lineDist;
            final linkAlpha = proximity * opacity * 0.4;
            // Gradient from A's color to B's color
            final colorA = _applyHueOffset(
              a.color,
              a.hueOffset,
            ).withValues(alpha: linkAlpha);
            final colorB = _applyHueOffset(
              b.color,
              b.hueOffset,
            ).withValues(alpha: linkAlpha);
            _linePaint.shader = LinearGradient(
              begin: Alignment(a.x / w * 2 - 1, a.y / h * 2 - 1),
              end: Alignment(b.x / w * 2 - 1, b.y / h * 2 - 1),
              colors: [colorA, colorB],
            ).createShader(Offset.zero & size);
            // Thickness varies by proximity — closer = thicker
            _linePaint.strokeWidth = 0.5 + proximity * 1.5;
            canvas.drawLine(Offset(a.x, a.y), Offset(b.x, b.y), _linePaint);
          }
        }
      }
      _linePaint.shader = null;
    }

    // ── Draw particles ──
    for (final p in particles) {
      final depthAlpha = 0.35 + 0.65 * p.depth;
      final lifeAlpha = _lifetimeAlpha(p);
      final baseAlpha = opacity * depthAlpha * lifeAlpha;

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

      var alpha = baseAlpha * edgeFade;
      if (alpha <= 0.01) continue;

      // ── Shimmer: periodic brightness sweep ──
      if (config.shimmer) {
        final shimmerWave = math.sin(t * 2.0 + p.shimmerPhase);
        // Sharp peak when shimmerWave > 0.7, brightens up to 2x
        if (shimmerWave > 0.7) {
          alpha *= 1.0 + (shimmerWave - 0.7) * 3.0;
        }
      }

      // ── Improved breathing: dual oscillator, 16% amplitude ──
      var drawSize = p.baseSize * sizeScale * p.depth;
      if (glowEffect == GlowEffect.pulse) {
        drawSize *= 0.7 + 0.3 * math.sin(t * 3.0 + p.phase * 10).abs();
      } else {
        // Dual oscillator: primary 1.5Hz + secondary 0.7Hz for organic variation
        drawSize *=
            0.84 +
            0.10 * math.sin(t * 1.5 + p.phase * 6) +
            0.06 * math.sin(t * 0.7 + p.phase * 3.5);
      }

      // ── Color drift: apply hue rotation ──
      final driftedColor = _applyHueOffset(p.color, p.hueOffset);
      final color = driftedColor.withValues(alpha: alpha);

      // ── Depth-of-field: far particles get slight blur ──
      // depth 0.4 = far (blurry), depth 1.3 = near (sharp)
      if (p.depth < 0.7 && config.glowEffect == GlowEffect.none) {
        final dofBlur = (0.7 - p.depth) * 3.0; // 0-0.9px blur for far particles
        _paint.maskFilter = MaskFilter.blur(BlurStyle.normal, dofBlur);
      } else {
        _paint.maskFilter = null;
      }

      // ── Trails: draw fading trail behind particle ──
      if (config.trailLength > 0 && p.trail.length > 1) {
        final maxTrailAge = config.trailLength * 0.5;
        for (var ti = 0; ti < p.trail.length - 1; ti++) {
          final tp = p.trail[ti];
          final trailAlpha = (1.0 - tp.age / maxTrailAge) * alpha * 0.5;
          if (trailAlpha <= 0.01) continue;
          final trailSize = drawSize * (1.0 - tp.age / maxTrailAge) * 0.6;
          _paint.color = driftedColor.withValues(alpha: trailAlpha);
          canvas.drawCircle(Offset(tp.x, tp.y), trailSize, _paint);
        }
      }

      // Apply glow effect
      switch (glowEffect) {
        case GlowEffect.none:
          // DOF blur already set above
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
          final cursedHsl = HSLColor.fromColor(
            driftedColor,
          ).withHue((270 + cursedShift * 60) % 360);
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
            _paint.color = driftedColor.withValues(alpha: rippleAlpha);
            canvas.drawCircle(Offset(p.x, p.y), rippleR, _paint);
          }
          break;
        case GlowEffect.neon:
          // Crisp bright neon halo — tight blur + bright white core
          _paint.maskFilter = MaskFilter.blur(BlurStyle.inner, drawSize * 0.15);
          _paint.color = driftedColor.withValues(alpha: alpha * 0.7);
          canvas.drawCircle(Offset(p.x, p.y), drawSize * 1.4, _paint);
          _paint.maskFilter = null;
          _paint.color = Colors.white.withValues(alpha: alpha * 0.6);
          canvas.drawCircle(Offset(p.x, p.y), drawSize * 0.5, _paint);
          break;
        case GlowEffect.aurora:
          // Hue-cycling soft halo — shifts through the spectrum over time
          final auroraHue = (t * 60 + p.phase * 120) % 360;
          final auroraColor =
              HSLColor.fromAHSL(alpha * 0.5, auroraHue, 0.7, 0.6).toColor();
          _paint.maskFilter = MaskFilter.blur(BlurStyle.normal, drawSize * 1.0);
          _paint.color = auroraColor;
          canvas.drawCircle(Offset(p.x, p.y), drawSize * 1.8, _paint);
          break;
        case GlowEffect.ember:
          // Warm flickering fire glow — oscillating brightness + warm hue
          final flicker = (math.sin(t * 8 + p.phase * 10) * 0.5 + 0.5);
          final emberHue = (30 + flicker * 20) % 360; // 30-50deg = orange-gold
          final emberColor =
              HSLColor.fromAHSL(
                alpha * (0.4 + flicker * 0.3),
                emberHue,
                0.9,
                0.5,
              ).toColor();
          _paint.maskFilter = MaskFilter.blur(BlurStyle.normal, drawSize * 0.9);
          _paint.color = emberColor;
          canvas.drawCircle(
            Offset(p.x, p.y),
            drawSize * (1.3 + flicker * 0.5),
            _paint,
          );
          break;
        case GlowEffect.spectral:
          // Ghostly translucent double-image — offset echo of the particle
          _paint.maskFilter = MaskFilter.blur(BlurStyle.normal, drawSize * 0.6);
          _paint.color = driftedColor.withValues(alpha: alpha * 0.3);
          canvas.drawCircle(
            Offset(p.x + drawSize * 0.4, p.y + drawSize * 0.3),
            drawSize * 1.2,
            _paint,
          );
          _paint.color = driftedColor.withValues(alpha: alpha * 0.2);
          canvas.drawCircle(
            Offset(p.x - drawSize * 0.3, p.y - drawSize * 0.4),
            drawSize * 1.0,
            _paint,
          );
          break;
        case GlowEffect.plasma:
          // Swirling electric plasma rings — rotating offset circles
          _paint.maskFilter = MaskFilter.blur(BlurStyle.solid, drawSize * 0.3);
          for (final ring in [0, 1, 2]) {
            final angle = t * 2 + p.phase * 6 + (ring * 2.094); // 120deg offset
            final rx = p.x + math.cos(angle) * drawSize * 0.8;
            final ry = p.y + math.sin(angle) * drawSize * 0.8;
            _paint.color = driftedColor.withValues(
              alpha: alpha * 0.4 * (1.0 - ring * 0.25),
            );
            canvas.drawCircle(Offset(rx, ry), drawSize * 0.7, _paint);
          }
          break;
        case GlowEffect.prism:
          // Rainbow prism refraction — three offset color-split ghosts
          _paint.maskFilter = MaskFilter.blur(BlurStyle.normal, drawSize * 0.4);
          final prismColors = [
            HSLColor.fromAHSL(alpha * 0.4, 0, 0.8, 0.5).toColor(), // red
            HSLColor.fromAHSL(alpha * 0.4, 120, 0.8, 0.5).toColor(), // green
            HSLColor.fromAHSL(alpha * 0.4, 240, 0.8, 0.5).toColor(), // blue
          ];
          final offsets = [
            (drawSize * 0.5, 0.0),
            (-drawSize * 0.3, drawSize * 0.4),
            (-drawSize * 0.3, -drawSize * 0.4),
          ];
          for (int i = 0; i < 3; i++) {
            _paint.color = prismColors[i];
            canvas.drawCircle(
              Offset(p.x + offsets[i].$1, p.y + offsets[i].$2),
              drawSize * 1.1,
              _paint,
            );
          }
          break;
      }

      _paint.color = color;

      // Draw shape
      if (p.rotationSpeed != 0 && config.shape != ParticleShape.circle) {
        canvas.save();
        canvas.translate(p.x, p.y);
        canvas.rotate(p.rotation);
        _drawShape(
          canvas,
          config.shape,
          0,
          0,
          drawSize,
          _paint,
          alpha,
          glowEffect,
        );
        canvas.restore();
      } else {
        _drawShape(
          canvas,
          config.shape,
          p.x,
          p.y,
          drawSize,
          _paint,
          alpha,
          glowEffect,
        );
      }

      // Reset mask for next particle
      _paint.maskFilter = null;
    }
  }

  /// Unified shape drawer — eliminates duplicated code between rotated
  /// and non-rotated paths.
  void _drawShape(
    Canvas canvas,
    ParticleShape shape,
    double cx,
    double cy,
    double drawSize,
    Paint paint,
    double alpha,
    GlowEffect glow,
  ) {
    switch (shape) {
      case ParticleShape.circle:
        canvas.drawCircle(Offset(cx, cy), drawSize, paint);
        if (glow != GlowEffect.none) {
          paint.maskFilter = null;
          paint.color = Colors.white.withValues(alpha: alpha * 0.5);
          canvas.drawCircle(Offset(cx, cy), drawSize * 0.3, paint);
        }
        break;
      case ParticleShape.star:
        _drawStar(canvas, cx, cy, drawSize, paint);
        if (glow != GlowEffect.none) {
          paint.maskFilter = null;
          paint.color = Colors.white.withValues(alpha: alpha * 0.6);
          canvas.drawCircle(Offset(cx, cy), drawSize * 0.2, paint);
        }
        break;
      case ParticleShape.triangle:
        _drawTriangle(canvas, cx, cy, drawSize, paint);
        break;
      case ParticleShape.edge:
        final r = drawSize;
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: r * 2,
            height: r * 1.4,
          ),
          paint,
        );
        break;
      case ParticleShape.bullet:
        _drawBullet(canvas, cx, cy, drawSize, paint);
        if (glow != GlowEffect.none) {
          paint.maskFilter = null;
          paint.color = Colors.white.withValues(alpha: alpha * 0.4);
          canvas.drawCircle(
            Offset(cx, cy - drawSize * 0.3),
            drawSize * 0.15,
            paint,
          );
        }
        break;
      case ParticleShape.heart:
        _drawHeart(canvas, cx, cy, drawSize, paint);
        if (glow != GlowEffect.none) {
          paint.maskFilter = null;
          paint.color = Colors.white.withValues(alpha: alpha * 0.5);
          canvas.drawCircle(Offset(cx, cy), drawSize * 0.15, paint);
        }
        break;
      case ParticleShape.skull:
        _drawSkull(canvas, cx, cy, drawSize, paint);
        break;
      case ParticleShape.hexagon:
        _drawHexagon(canvas, cx, cy, drawSize, paint);
        break;
      case ParticleShape.paw:
        _drawPaw(canvas, cx, cy, drawSize, paint);
        break;
      case ParticleShape.crescent:
        _drawCrescent(canvas, cx, cy, drawSize, paint);
        if (glow != GlowEffect.none) {
          paint.maskFilter = null;
          paint.color = Colors.white.withValues(alpha: alpha * 0.4);
          canvas.drawCircle(
            Offset(cx - drawSize * 0.15, cy),
            drawSize * 0.12,
            paint,
          );
        }
        break;
      case ParticleShape.bolt:
        _drawBolt(canvas, cx, cy, drawSize, paint);
        if (glow != GlowEffect.none) {
          paint.maskFilter = null;
          paint.color = Colors.white.withValues(alpha: alpha * 0.5);
          canvas.drawCircle(Offset(cx, cy), drawSize * 0.15, paint);
        }
        break;
      case ParticleShape.shard:
        _drawShard(canvas, cx, cy, drawSize, paint);
        break;
      case ParticleShape.smoke:
        _drawSmoke(canvas, cx, cy, drawSize, paint);
        break;
      case ParticleShape.scale:
        _drawScale(canvas, cx, cy, drawSize, paint);
        break;
    }
  }

  void _drawStar(Canvas canvas, double cx, double cy, double r, Paint paint) {
    final path =
        Path()
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

  void _drawTriangle(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    Paint paint,
  ) {
    final path =
        Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r * 0.866, cy + r * 0.5)
          ..lineTo(cx - r * 0.866, cy + r * 0.5)
          ..close();
    canvas.drawPath(path, paint);
  }

  void _drawBullet(Canvas canvas, double cx, double cy, double r, Paint paint) {
    final path =
        Path()
          ..moveTo(cx, cy - r * 1.2)
          ..lineTo(cx + r * 0.5, cy - r * 0.3)
          ..quadraticBezierTo(cx + r * 0.7, cy + r * 0.3, cx, cy + r * 0.6)
          ..quadraticBezierTo(
            cx - r * 0.7,
            cy + r * 0.3,
            cx - r * 0.5,
            cy - r * 0.3,
          )
          ..close();
    canvas.drawPath(path, paint);
  }

  void _drawHeart(Canvas canvas, double cx, double cy, double r, Paint paint) {
    final path =
        Path()
          ..moveTo(cx, cy + r * 0.7)
          ..cubicTo(
            cx + r * 1.1,
            cy + r * 0.2,
            cx + r * 0.65,
            cy - r * 0.85,
            cx,
            cy - r * 0.25,
          )
          ..cubicTo(
            cx - r * 0.65,
            cy - r * 0.85,
            cx - r * 1.1,
            cy + r * 0.2,
            cx,
            cy + r * 0.7,
          )
          ..close();
    canvas.drawPath(path, paint);
  }

  void _drawSkull(Canvas canvas, double cx, double cy, double r, Paint paint) {
    canvas.drawCircle(Offset(cx, cy - r * 0.15), r * 0.65, paint);
    final jawRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy + r * 0.35),
        width: r * 0.7,
        height: r * 0.45,
      ),
      Radius.circular(r * 0.12),
    );
    canvas.drawRRect(jawRect, paint);
    final eyePaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    canvas.drawCircle(Offset(cx - r * 0.22, cy - r * 0.2), r * 0.14, eyePaint);
    canvas.drawCircle(Offset(cx + r * 0.22, cy - r * 0.2), r * 0.14, eyePaint);
  }

  void _drawHexagon(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    Paint paint,
  ) {
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

  /// Cat paw print: main pad + 4 toe beans.
  void _drawPaw(Canvas canvas, double cx, double cy, double r, Paint paint) {
    // Main pad (larger ellipse at bottom)
    final padRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy + r * 0.25),
        width: r * 1.1,
        height: r * 0.85,
      ),
      Radius.circular(r * 0.4),
    );
    canvas.drawRRect(padRect, paint);
    // Four toe beans (small circles above)
    final toePaint = Paint()..color = paint.color;
    for (var i = 0; i < 4; i++) {
      final tx = cx + (i - 1.5) * r * 0.32;
      final ty = cy - r * 0.35 + (i == 1 || i == 2 ? 0 : -r * 0.1);
      canvas.drawCircle(Offset(tx, ty), r * 0.22, toePaint);
    }
  }

  /// Crescent moon: filled circle with a smaller offset circle subtracted.
  void _drawCrescent(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    Paint paint,
  ) {
    // ponytail: Path-based crescent using arcDifference would be cleaner,
    // but drawCircle with BlendMode.clear needs a separate layer. Simplest
    // approach: two overlapping arcs via Path fill rule.
    final path =
        Path()
          ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r))
          ..addOval(
            Rect.fromCircle(
              center: Offset(cx + r * 0.4, cy - r * 0.15),
              radius: r * 0.85,
            ),
          )
          ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  /// Lightning bolt: zigzag path from top to bottom.
  void _drawBolt(Canvas canvas, double cx, double cy, double r, Paint paint) {
    final path =
        Path()
          ..moveTo(cx + r * 0.15, cy - r)
          ..lineTo(cx - r * 0.35, cy - r * 0.1)
          ..lineTo(cx - r * 0.05, cy - r * 0.1)
          ..lineTo(cx - r * 0.25, cy + r * 0.3)
          ..lineTo(cx + r * 0.1, cy + r * 0.05)
          ..lineTo(cx - r * 0.05, cy + r)
          ..lineTo(cx + r * 0.45, cy - r * 0.05)
          ..lineTo(cx + r * 0.1, cy - r * 0.05)
          ..lineTo(cx + r * 0.35, cy - r * 0.5)
          ..close();
    canvas.drawPath(path, paint);
  }

  /// Crystal shard: irregular polygon with sharp facets.
  void _drawShard(Canvas canvas, double cx, double cy, double r, Paint paint) {
    final path =
        Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r * 0.6, cy - r * 0.3)
          ..lineTo(cx + r * 0.4, cy + r * 0.5)
          ..lineTo(cx - r * 0.2, cy + r * 0.7)
          ..lineTo(cx - r * 0.7, cy + r * 0.1)
          ..lineTo(cx - r * 0.5, cy - r * 0.5)
          ..close();
    canvas.drawPath(path, paint);
  }

  /// Smoke puff: overlapping translucent circles for a soft cloud look.
  void _drawSmoke(Canvas canvas, double cx, double cy, double r, Paint paint) {
    canvas.drawCircle(Offset(cx - r * 0.3, cy), r * 0.7, paint);
    canvas.drawCircle(Offset(cx + r * 0.3, cy - r * 0.2), r * 0.6, paint);
    canvas.drawCircle(Offset(cx, cy + r * 0.3), r * 0.65, paint);
    canvas.drawCircle(Offset(cx + r * 0.15, cy - r * 0.1), r * 0.5, paint);
  }

  /// Dragon scale: overlapping semi-circles forming a reptilian scale pattern.
  void _drawScale(Canvas canvas, double cx, double cy, double r, Paint paint) {
    // Main scale body — rounded fan shape
    final path =
        Path()
          ..moveTo(cx - r, cy + r * 0.3)
          ..quadraticBezierTo(cx - r, cy - r * 0.8, cx, cy - r * 0.9)
          ..quadraticBezierTo(cx + r, cy - r * 0.8, cx + r, cy + r * 0.3)
          ..quadraticBezierTo(cx, cy + r * 0.6, cx - r, cy + r * 0.3)
          ..close();
    canvas.drawPath(path, paint);
    // Inner ridge line for scale detail
    final ridgePaint =
        Paint()
          ..color = paint.color.withValues(alpha: paint.color.a * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;
    canvas.drawPath(
      Path()
        ..moveTo(cx, cy - r * 0.7)
        ..quadraticBezierTo(cx, cy + r * 0.1, cx, cy + r * 0.4),
      ridgePaint,
    );
  }

  // ponytail: always-repaint is correct for animation-driven painters.
  // RepaintBoundary in the parent widget isolates this from the rest of the app.
  // If ever nested in a scrollable, add a VisibilityDetector to pause offscreen.
  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}
