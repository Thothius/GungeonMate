import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../services/haptics.dart';
import 'theme_engines.dart';

class _TouchParticle {
  Offset pos;
  Offset vel;
  Color color;
  double size;
  double life = 1.0;
  _TouchParticle({required this.pos, required this.vel, required this.color, required this.size});
}

class ThemeOverlay extends StatefulWidget {
  final Widget child;
  const ThemeOverlay({super.key, required this.child});

  @override
  State<ThemeOverlay> createState() => _ThemeOverlayState();
}

class _ThemeOverlayState extends State<ThemeOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _touchTicker;
  final List<_TouchParticle> _touchParticles = [];
  final math.Random _rng = math.Random();

  // Scale a color's alpha by [scale] (0.0–1.0).
  static Color _scaleAlpha(Color c, double scale) =>
      c.withValues(alpha: (c.a * scale).clamp(0.0, 1.0));

  @override
  void initState() {
    super.initState();
    _touchTicker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onFrame)..repeat();
  }

  @override
  void dispose() {
    _touchTicker.dispose();
    super.dispose();
  }

  void _onFrame() {
    if (_touchParticles.isEmpty) return;
    setState(() {
      for (var i = _touchParticles.length - 1; i >= 0; i--) {
        final p = _touchParticles[i];
        p.pos += p.vel;
        p.vel = Offset(p.vel.dx * 0.92, p.vel.dy * 0.92); // deceleration
        p.life -= 0.05; // decays in 20 frames (~0.3 seconds)
        if (p.life <= 0) {
          _touchParticles.removeAt(i);
        }
      }
    });
  }

  void _spawnTouchSparkles(Offset globalPosition, VisualPrefs prefs) {
    if (!prefs.particlesEnabled) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      final localPos = box.globalToLocal(globalPosition);
      final activeFlair = AppTheme.flair;
      final color = activeFlair.primary;
      setState(() {
        for (var i = 0; i < 8; i++) {
          final angle = _rng.nextDouble() * 2 * math.pi;
          final speed = 1.0 + _rng.nextDouble() * 3.5;
          _touchParticles.add(_TouchParticle(
            pos: localPos,
            vel: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
            color: color,
            size: 4.0 + _rng.nextDouble() * 5.0,
          ));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: AppTheme.notifier,
      builder: (_, mode, __) => ValueListenableBuilder<VisualPrefs>(
        valueListenable: VisualPrefs.notifier,
        builder: (_, prefs, __) {
          final f = AppTheme.flair;
          final showGlow = prefs.glowIntensity > 0.001;
          final gP = showGlow
              ? _scaleAlpha(f.glowPrimary,   prefs.glowIntensity)
              : const Color(0x00000000);
          final gS = showGlow
              ? _scaleAlpha(f.glowSecondary, prefs.glowIntensity)
              : const Color(0x00000000);
          final backdrop = prefs.hypnoticBgEnabled
              ? _HypnoticBg(
                  assetName: prefs.hypnoticBgAsset,
                  speedMultiplier: prefs.hypnoticBgSpeed,
                  opacity: prefs.hypnoticBgOpacity,
                )
              : (!prefs.particlesEnabled
                  ? null
                  : (prefs.customParticleType != CustomParticleType.themeDefault
                      ? _CustomParticleBackdrop(prefs: prefs)
                      : _backdropFor(f.backdrop, prefs)));
          Widget content = widget.child;

          // Apply visual customizer wrappers based on active Theme Mode!
          if (mode == AppThemeMode.cosmicWhirlwind || mode == AppThemeMode.voidDimension) {
            content = ElasticWobbleContainer(
              intensity: 0.05,
              speed: 0.6,
              child: content,
            );
          }

          if (mode == AppThemeMode.winchester || mode == AppThemeMode.custom) {
            content = GlintSheenOverlay(
              sheenColor: f.headlineStat.withValues(alpha: 0.6),
              duration: const Duration(milliseconds: 1800),
              interval: const Duration(seconds: 8),
              child: content,
            );
          }

          return Listener(
            onPointerDown: (event) => _spawnTouchSparkles(event.position, prefs),
            behavior: HitTestBehavior.translucent,
            child: Stack(
              children: [
                // 1. Base Layer: Hypnotic Trippy Background or Particles
                if (backdrop != null)
                  Positioned.fill(child: IgnorePointer(child: backdrop)),

                // 2. Middle Layer: Core App Content (wrapped in visual physics controllers)
                content,

                // 3. Top Layers: Ambient Glows & Page Frames
                if (showGlow)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _AmbientGlow(
                        key: ValueKey('ambient_glow_${mode.index}'),
                        primary: gP,
                        secondary: gS,
                      ),
                    ),
                  ),
                if (f.pageFrame)
                  const Positioned.fill(
                      child: IgnorePointer(child: _PageFrame())),

                // 4. Special Top-Edge Drip Overlay (Curseblaster / Oubliette themes)
                if (mode == AppThemeMode.curseblaster)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 60,
                    child: IgnorePointer(
                      child: EdgeDripWidget(
                        color: Color(0x66E83344), // Translucent Curse crimson drip
                        dripCount: 5,
                        maxDripHeight: 25.0,
                        viscosity: 1.2,
                      ),
                    ),
                  ),

                if (prefs.particlesEnabled && _touchParticles.isNotEmpty)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _TouchParticlePainter(particles: _touchParticles),
                      ),
                    ),
                  ),

                // Secret Cat Bullet King Throne Overlay!
                const _SecretCatThroneOverlay(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget? _backdropFor(ThemeBackdrop b, VisualPrefs prefs) {
    switch (b) {
      case ThemeBackdrop.none:
        return null;
      case ThemeBackdrop.goldDust:
        return _GoldDust(advancedFlicker: prefs.advancedFlicker);
      case ThemeBackdrop.pastelDriftSparkles:
        // Drift is now handled globally by _AmbientGlow; only the
        // sparkles are Unicorn-specific.
        return _Sparkles(particleRotation: prefs.particleRotation);
      case ThemeBackdrop.redBreathDrip:
        return const _RedBreathDrip();
      case ThemeBackdrop.brassMotes:
        return const _BrassMotes();
      case ThemeBackdrop.paperBreath:
        // Paper theme gets only the ambient glow + page frame — no
        // particle layer. "Stillness is the quirk."
        return null;
      case ThemeBackdrop.iceCrystals:
        return _IceCrystals(particleRotation: prefs.particleRotation);
      case ThemeBackdrop.whiteDust:
        return _WhiteDust(gravityVortex: prefs.gravityVortex);
      case ThemeBackdrop.toxicBubbles:
        return const _ToxicBubbles();
      case ThemeBackdrop.forgeEmbers:
        return _ForgeEmbers(advancedFlicker: prefs.advancedFlicker);
      case ThemeBackdrop.hellfire:
        return _Hellfire(advancedFlicker: prefs.advancedFlicker);
      case ThemeBackdrop.cosmicRift:
        return _CosmicRift(particleRotation: prefs.particleRotation);
    }
  }
}

// =============================================================================
// Ambient glow — painted behind every theme (Bubblegum-style soft radial
// gradient that drifts gently). Colors come from the live ThemeFlair.
// =============================================================================

class _AmbientGlow extends StatefulWidget {
  final Color primary;
  final Color secondary;
  const _AmbientGlow({
    super.key,
    required this.primary,
    required this.secondary,
  });

  @override
  State<_AmbientGlow> createState() => _AmbientGlowState();
}

class _AmbientGlowState extends State<_AmbientGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    // Slow — 26s cycle. Drift is supposed to be felt, not noticed.
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 26),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value * 2 * math.pi;
        // Drift the primary glow around a small ellipse — just enough
        // motion to stop the eye treating it as static.
        final cx = 0.5 + 0.28 * math.cos(t);
        final cy = 0.5 + 0.20 * math.sin(t);
        return Stack(
          children: [
            // Primary glow — brightest, wandering.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(cx * 2 - 1, cy * 2 - 1),
                    radius: 1.0,
                    colors: [
                      widget.primary,
                      widget.secondary,
                      const Color(0x00000000),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            // Secondary glow drifting the opposite direction — gives the
            // scene a subtle sense of depth without any actual 3D.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-(cx * 2 - 1), -(cy * 2 - 1)),
                    radius: 1.1,
                    colors: [
                      widget.secondary,
                      const Color(0x00000000),
                    ],
                    stops: const [0.0, 0.75],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// Coolmaxing — drifting gold dust
// =============================================================================

/// Sparse rising gold flecks. 14 particles randomised once at construction
/// so the field looks irregular but doesn't churn allocations every frame.
class _GoldDust extends StatefulWidget {
  final bool advancedFlicker;
  const _GoldDust({required this.advancedFlicker});
  @override
  State<_GoldDust> createState() => _GoldDustState();
}

class _GoldDustState extends State<_GoldDust>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_DustSpec> _specs;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    final rng = math.Random(42);
    // Even phase distribution — a particle is always exiting the top
    // exactly when another is entering the bottom, so the stream reads
    // as an unbroken upward flow instead of a randomly-clumped field.
    const count = 18;
    _specs = List.generate(count, (i) {
      return _DustSpec(
        x: rng.nextDouble(),
        // Keep speed jitter small so phases stay evenly spaced over time.
        speed: 0.92 + rng.nextDouble() * 0.16,
        phase: i / count + rng.nextDouble() * (1.0 / count) * 0.4,
        size: 1.2 + rng.nextDouble() * 1.6,
        sway: 6 + rng.nextDouble() * 14,
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _GoldDustPainter(t: _c.value, specs: _specs, advancedFlicker: widget.advancedFlicker),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _DustSpec {
  final double x;
  final double speed;
  final double phase;
  final double size;
  final double sway;
  const _DustSpec({
    required this.x,
    required this.speed,
    required this.phase,
    required this.size,
    required this.sway,
  });
}

class _GoldDustPainter extends CustomPainter {
  final double t;
  final List<_DustSpec> specs;
  final bool advancedFlicker;
  _GoldDustPainter({required this.t, required this.specs, required this.advancedFlicker});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw beautiful flowing golden wind currents
    final windPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFF6C849).withValues(alpha: 0.05 + 0.04 * math.sin(t * 2 * math.pi));
    if (advancedFlicker) {
      windPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);
    }
    for (int i = 0; i < 3; i++) {
      final pOffset = (t + i / 3.0) % 1.0;
      final path = Path();
      final startY = size.height * (1.1 - pOffset);
      final c1y = startY - size.height * 0.25;
      final c2y = startY - size.height * 0.5;
      final endY = startY - size.height * 0.75;
      
      final startX = -120.0 + pOffset * (size.width + 240.0);
      path.moveTo(startX, startY);
      path.cubicTo(
        startX + size.width * 0.25, c1y + math.sin(pOffset * 2 * math.pi) * 45,
        startX + size.width * 0.55, c2y + math.cos(pOffset * 2 * math.pi) * 45,
        startX + size.width * 0.85, endY
      );
      canvas.drawPath(path, windPaint);
    }

    // 2. Draw gold dust particles carried diagonally by the wind
    final paint = Paint();
    for (final s in specs) {
      // Position cycles 0→1 over the spec's speed-scaled duration.
      final p = ((t * s.speed) + s.phase) % 1.0;
      // Bottom→top: y starts at size.height and drifts up.
      final y = size.height * (1.0 - p);
      // Wind-swept diagonal drift (x slides from left to right as y rises!)
      final diagonalDrift = p * size.width * 0.18;
      // Lateral sway via a sine wave for a "floaty" feel.
      final sway = math.sin(p * 2 * math.pi + s.phase * 6) * s.sway;
      final x = (s.x * size.width + sway + diagonalDrift) % size.width;
      // Fade in at the bottom and out at the top for a soft entry/exit.
      final alpha = _bellAlpha(p) * 0.55;

      // Soft golden shimmer flicker
      final shimmer = advancedFlicker
          ? 0.8 + 0.2 * math.sin(t * 11 * math.pi + s.phase * 18)
          : 1.0;
      paint.color = const Color(0xFFF6C849).withValues(alpha: alpha * shimmer);

      canvas.drawCircle(Offset(x, y), s.size * shimmer, paint);
    }
  }

  /// Symmetric fade-in / fade-out so wrap-around is imperceptible.
  /// Particles enter at full transparency, peak in the middle of
  /// their rise, and fade out the same way at the top.
  double _bellAlpha(double p) {
    const ramp = 0.18;
    if (p < ramp) return p / ramp;
    if (p > 1.0 - ramp) return (1.0 - p) / ramp;
    return 1.0;
  }

  @override
  bool shouldRepaint(_GoldDustPainter old) => old.t != t;
}

// =============================================================================
// Unicorn — pastel hue drift + rising sparkles
// =============================================================================

/// Standalone rising ✦ sparkle particles. The radial drift that used
/// to live here moved to the global `_AmbientGlow` layer so every
/// theme benefits from the Bubblegum-style gradient, not just Unicorn.
class _Sparkles extends StatefulWidget {
  final bool particleRotation;
  const _Sparkles({required this.particleRotation});
  @override
  State<_Sparkles> createState() => _SparklesState();
}

class _SparklesState extends State<_Sparkles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_DustSpec> _specs;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    final rng = math.Random(7);
    // Phase distributed evenly across [0,1) so sparkles trickle up at
    // a steady rate and the wrap-around is invisible.
    const count = 14;
    _specs = List.generate(count, (i) {
      return _DustSpec(
        x: rng.nextDouble(),
        speed: 0.94 + rng.nextDouble() * 0.12,
        phase: i / count + rng.nextDouble() * (1.0 / count) * 0.4,
        size: 9 + rng.nextDouble() * 6, // sparkle font size
        sway: 8 + rng.nextDouble() * 18,
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _SparklesPainter(t: _c.value, specs: _specs, particleRotation: widget.particleRotation),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _SparklesPainter extends CustomPainter {
  final double t;
  final List<_DustSpec> specs;
  final bool particleRotation;
  _SparklesPainter({required this.t, required this.specs, required this.particleRotation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (int i = 0; i < specs.length; i++) {
      final s = specs[i];
      final p = ((t * s.speed) + s.phase) % 1.0;
      final y = size.height * (1.0 - p);
      final sway = math.sin(p * 2 * math.pi + s.phase * 6) * s.sway * 1.2;
      final x = s.x * size.width + sway;
      final alpha = _bellAlpha(p) * 0.55;

      // Soft magical twinkle scaling
      final twinkle = particleRotation
          ? 0.4 + 0.6 * math.sin(t * 18 * math.pi + s.phase * 15)
          : 1.0;
      final scaleSize = s.size * 1.6 * twinkle;
      final finalAlpha = (alpha * twinkle).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(x, y);
      
      if (i % 2 == 0) {
        // Beautiful 4-pointed vector sparkle
        paint.color = const Color(0xFFFFB2E6).withValues(alpha: finalAlpha);
        if (particleRotation) {
          canvas.rotate(p * 5.0 * math.pi + s.phase * 10);
        }
        final path = Path()
          ..moveTo(0, -scaleSize)
          ..lineTo(scaleSize * 0.22, -scaleSize * 0.22)
          ..lineTo(scaleSize, 0)
          ..lineTo(scaleSize * 0.22, scaleSize * 0.22)
          ..lineTo(0, scaleSize)
          ..lineTo(-scaleSize * 0.22, scaleSize * 0.22)
          ..lineTo(-scaleSize, 0)
          ..lineTo(-scaleSize * 0.22, -scaleSize * 0.22)
          ..close();
        canvas.drawPath(path, paint);
      } else {
        // Glowing magic cotton candy bubble with radial shader likeness
        paint.color = const Color(0xFFB3E5FC).withValues(alpha: finalAlpha * 0.6);
        canvas.drawCircle(Offset.zero, scaleSize, paint);
        
        paint.color = Colors.white.withValues(alpha: finalAlpha * 0.9);
        canvas.drawCircle(Offset.zero, scaleSize * 0.35, paint);
      }
      canvas.restore();
    }
  }

  double _bellAlpha(double p) {
    const ramp = 0.18;
    if (p < ramp) return p / ramp;
    if (p > 1.0 - ramp) return (1.0 - p) / ramp;
    return 1.0;
  }

  @override
  bool shouldRepaint(_SparklesPainter old) => old.t != t;
}

// =============================================================================
// Curseblaster — corner red pulse + right-edge crimson drip
// =============================================================================

/// Two layers stacked: the original soft red vignette breath plus a
/// fresh crimson drop that slides down the right edge every ~12s.
class _RedBreathDrip extends StatelessWidget {
  const _RedBreathDrip();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Positioned.fill(child: _CurseBreath()),
        Positioned.fill(child: _CrimsonDrip()),
      ],
    );
  }
}

class _CurseBreath extends StatefulWidget {
  const _CurseBreath();
  @override
  State<_CurseBreath> createState() => _CurseBreathState();
}

class _CurseBreathState extends State<_CurseBreath>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        final tri = t < 0.5 ? t * 2 : (1 - t) * 2;
        final alpha = 0.12 + 0.15 * tri; // Much deeper and gloomier breath pulse
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.1,
              colors: [
                Colors.black.withValues(alpha: 0.65), // Darken core for extreme atmosphere
                const Color(0xFF0C0204).withValues(alpha: alpha * 0.55), // deep blackish-purple
                const Color(0xFF42050E).withValues(alpha: alpha * 0.95),  // menacing blood-red border vignette
              ],
              stops: const [0.35, 0.72, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class _CrimsonDrip extends StatefulWidget {
  const _CrimsonDrip();
  @override
  State<_CrimsonDrip> createState() => _CrimsonDripState();
}

class _CrimsonDripState extends State<_CrimsonDrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    // 12-second cycle: drop forms (0.0–0.15), slides (0.15–0.85), fades
    // (0.85–1.0). Long rest implicit in the long cycle.
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _CrimsonDripPainter(t: _c.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _CrimsonDripPainter extends CustomPainter {
  final double t;
  _CrimsonDripPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Draw multiple blood droplets sliding down at different intervals/speeds
    for (int i = 0; i < 3; i++) {
      final double speed = 0.65 + i * 0.25;
      final double phase = i * 0.33;
      final double progress = (t * speed + phase) % 1.0;
      
      double yProg;
      double alpha;
      if (progress < 0.15) {
        yProg = (progress / 0.15) * 0.05;
        alpha = (progress / 0.15) * 0.75;
      } else if (progress < 0.85) {
        yProg = 0.05 + ((progress - 0.15) / 0.7) * 0.95;
        alpha = 0.75;
      } else {
        yProg = 1.0;
        alpha = 0.75 * (1.0 - (progress - 0.85) / 0.15);
      }
      
      final cy = size.height * yProg;
      final cx = size.width - 6.0 - (i * 12.0); // Staggered right side drip lines
      
      paint.color = const Color(0xFF8B0000).withValues(alpha: alpha); // Menacing crimson blood
      canvas.drawCircle(Offset(cx, cy), 3.5, paint);
      
      if (progress > 0.15 && progress < 0.85) {
        paint.color = const Color(0xFF5A0000).withValues(alpha: alpha * 0.45);
        final tailH = 32.0;
        canvas.drawRect(Rect.fromLTWH(cx - 1.2, cy - tailH, 2.4, tailH), paint);
      }
    }
    
    // Floating dark curse ashes (Red-Black embers) drifting upwards
    final math.Random rng = math.Random(666);
    for (int i = 0; i < 15; i++) {
      final double speed = 0.4 + rng.nextDouble() * 0.5;
      final double phase = i / 15.0;
      final double progress = (t * speed + phase) % 1.0;
      
      final y = size.height * (1.0 - progress);
      final sway = math.sin(progress * 2 * math.pi + phase * 8) * 22;
      final x = (i / 15.0) * size.width + sway;
      final alpha = (1.0 - progress) * progress * 4.0 * 0.45; // bell-shaped fade in & out
      
      // Outer charred ember
      paint.color = const Color(0xFF1E0206).withValues(alpha: alpha);
      final double sizeVal = 2.0 + rng.nextDouble() * 3.0;
      canvas.drawCircle(Offset(x, y), sizeVal, paint);
      
      // Glowing core in some embers
      if (i % 2 == 0) {
        paint.color = const Color(0xFFFF2B3C).withValues(alpha: alpha * 0.85); // bleeding red spark
        canvas.drawCircle(Offset(x, y), sizeVal * 0.45, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_CrimsonDripPainter old) => old.t != t;
}

// =============================================================================
// Winchester — slow drifting brass motes (saloon dust catching lamplight)
// =============================================================================

/// Slow, sparse brass-coloured dust. Similar cadence to Coolmaxing's
/// gold dust but drifts sideways as well as up, hovers longer, and
/// uses brass hues to match the saloon palette.
class _BrassMotes extends StatefulWidget {
  const _BrassMotes();
  @override
  State<_BrassMotes> createState() => _BrassMotesState();
}

class _BrassMotesState extends State<_BrassMotes>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_DustSpec> _specs;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28), // slower than gold dust
    )..repeat();
    final rng = math.Random(1873); // Winchester's year. Nice.
    const count = 14;
    _specs = List.generate(count, (i) {
      return _DustSpec(
        x: rng.nextDouble(),
        speed: 0.85 + rng.nextDouble() * 0.25,
        phase: i / count + rng.nextDouble() * (1.0 / count) * 0.5,
        size: 1.1 + rng.nextDouble() * 1.4,
        sway: 20 + rng.nextDouble() * 26, // wider drift = "floating" dust
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _BrassMotesPainter(t: _c.value, specs: _specs),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _BrassMotesPainter extends CustomPainter {
  final double t;
  final List<_DustSpec> specs;
  _BrassMotesPainter({required this.t, required this.specs});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < specs.length; i++) {
      final s = specs[i];
      final p = ((t * s.speed) + s.phase) % 1.0;
      final y = size.height * (1.0 - p);
      
      // Wider lazy horizontal drift matching prairie wind currents
      final sway = math.sin(p * 2 * math.pi + s.phase * 4) * s.sway * 1.5;
      final x = s.x * size.width + sway;
      final alpha = _bellAlpha(p) * 0.55;

      // Soft breeze flicker
      final flicker = 0.72 + 0.28 * math.sin(t * 8 * math.pi + s.phase * 12);
      final finalAlpha = (alpha * flicker).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(x, y);
      
      if (i % 3 == 0) {
        // Draw rotating 5-point Sheriff Star!
        paint.color = const Color(0xFFFFB300).withValues(alpha: finalAlpha);
        canvas.rotate(p * 3.5 * math.pi + s.phase * 6);
        final r = s.size * 1.8;
        final path = Path();
        for (int j = 0; j < 5; j++) {
          final double angleOuter = j * 2 * math.pi / 5 - math.pi / 2;
          final double angleInner = angleOuter + math.pi / 5;
          if (j == 0) {
            path.moveTo(math.cos(angleOuter) * r, math.sin(angleOuter) * r);
          } else {
            path.lineTo(math.cos(angleOuter) * r, math.sin(angleOuter) * r);
          }
          path.lineTo(math.cos(angleInner) * r * 0.42, math.sin(angleInner) * r * 0.42);
        }
        path.close();
        canvas.drawPath(path, paint);
      } else {
        // Draw whiskey-gold dusty circles
        paint.color = const Color(0xFFD4AF37).withValues(alpha: finalAlpha);
        canvas.drawCircle(Offset.zero, s.size * 1.2 * flicker, paint);
      }
      canvas.restore();
    }
  }

  double _bellAlpha(double p) {
    const ramp = 0.2;
    if (p < ramp) return p / ramp;
    if (p > 1.0 - ramp) return (1.0 - p) / ramp;
    return 1.0;
  }

  @override
  bool shouldRepaint(_BrassMotesPainter old) => old.t != t;
}

// =============================================================================
// Ice Tyrant — falling cyan-white ice crystals
// =============================================================================

class _IceCrystals extends StatefulWidget {
  final bool particleRotation;
  const _IceCrystals({required this.particleRotation});
  @override
  State<_IceCrystals> createState() => _IceCrystalsState();
}

class _IceCrystalsState extends State<_IceCrystals>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_DustSpec> _specs;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
    final rng = math.Random(2024);
    const count = 16;
    _specs = List.generate(count, (i) {
      return _DustSpec(
        x: rng.nextDouble(),
        speed: 0.88 + rng.nextDouble() * 0.22,
        phase: i / count + rng.nextDouble() * (1.0 / count) * 0.4,
        size: 1.4 + rng.nextDouble() * 1.8,
        sway: 8 + rng.nextDouble() * 16,
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _IceCrystalsPainter(t: _c.value, specs: _specs, particleRotation: widget.particleRotation),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _IceCrystalsPainter extends CustomPainter {
  final double t;
  final List<_DustSpec> specs;
  final bool particleRotation;
  _IceCrystalsPainter({required this.t, required this.specs, required this.particleRotation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // 1. Draw subtle diagonal frosty wind streams
    for (int i = 0; i < 3; i++) {
      final progress = (t + i / 3.0) % 1.0;
      paint.color = const Color(0x0C80DEEA); // Faint cyan ice trail
      paint.strokeWidth = 1.5;
      paint.style = PaintingStyle.stroke;
      final path = Path()
        ..moveTo(size.width * 1.2 - progress * size.width * 1.4, -50 + progress * size.height * 1.2)
        ..relativeLineTo(-size.width * 0.3, size.height * 0.25);
      canvas.drawPath(path, paint);
    }

    paint.style = PaintingStyle.fill;
    for (int i = 0; i < specs.length; i++) {
      final s = specs[i];
      final p = ((t * s.speed) + s.phase) % 1.0;
      // Top to bottom drift
      final y = size.height * p;
      final sway = math.sin(p * 2 * math.pi + s.phase * 6) * s.sway * 1.2;
      final x = s.x * size.width + sway;
      final alpha = _bellAlpha(p) * 0.65;

      // Shimmering twinkle
      final shimmer = particleRotation
          ? 0.4 + 0.6 * math.sin(t * 12 * math.pi + s.phase * 15)
          : 1.0;
      final finalAlpha = (alpha * shimmer).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(x, y);
      if (particleRotation) {
        canvas.rotate(p * 4.0 * math.pi + s.phase * 8); // Gentle orbital spinning
      }

      final r = s.size * 1.5 * shimmer;
      
      if (i % 2 == 0) {
        // Hexagonal ice crystal shard
        paint.color = const Color(0xFFE0F7FA).withValues(alpha: finalAlpha);
        final path = Path();
        for (int j = 0; j < 6; j++) {
          final double angle = j * math.pi / 3;
          final double rx = r * (j % 2 == 0 ? 1.0 : 0.62);
          if (j == 0) {
            path.moveTo(math.cos(angle) * rx, math.sin(angle) * rx);
          } else {
            path.lineTo(math.cos(angle) * rx, math.sin(angle) * rx);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
      } else {
        // Star cross crystal shape
        paint.color = const Color(0xFF80DEEA).withValues(alpha: finalAlpha);
        final path = Path()
          ..moveTo(0, -r)
          ..lineTo(r * 0.25, -r * 0.25)
          ..lineTo(r, 0)
          ..lineTo(r * 0.25, r * 0.25)
          ..lineTo(0, r)
          ..lineTo(-r * 0.25, r * 0.25)
          ..lineTo(-r, 0)
          ..lineTo(-r * 0.25, -r * 0.25)
          ..close();
        canvas.drawPath(path, paint);
      }
      canvas.restore();
    }
  }

  double _bellAlpha(double p) {
    const ramp = 0.18;
    if (p < ramp) return p / ramp;
    if (p > 1.0 - ramp) return (1.0 - p) / ramp;
    return 1.0;
  }

  @override
  bool shouldRepaint(_IceCrystalsPainter old) => old.t != t;
}

// =============================================================================
// Pitch Black — sparse white motes drifting in the void
// =============================================================================

class _WhiteDust extends StatefulWidget {
  final bool gravityVortex;
  const _WhiteDust({required this.gravityVortex});
  @override
  State<_WhiteDust> createState() => _WhiteDustState();
}

class _WhiteDustState extends State<_WhiteDust>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_DustSpec> _specs;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 32), // very slow, ghostly
    )..repeat();
    final rng = math.Random(0);
    const count = 12; // sparse
    _specs = List.generate(count, (i) {
      return _DustSpec(
        x: rng.nextDouble(),
        speed: 0.75 + rng.nextDouble() * 0.25,
        phase: i / count + rng.nextDouble() * (1.0 / count) * 0.5,
        size: 0.8 + rng.nextDouble() * 1.2,
        sway: 12 + rng.nextDouble() * 20,
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _WhiteDustPainter(t: _c.value, specs: _specs, gravityVortex: widget.gravityVortex),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _WhiteDustPainter extends CustomPainter {
  final double t;
  final List<_DustSpec> specs;
  final bool gravityVortex;
  _WhiteDustPainter({required this.t, required this.specs, required this.gravityVortex});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final avatarCenter = Offset(size.width * 0.5, 115);

    for (final s in specs) {
      final p = ((t * s.speed) + s.phase) % 1.0;
      final rawY = size.height * (1.0 - p);
      final sway = math.sin(p * 2 * math.pi + s.phase * 4) * s.sway;
      final rawX = s.x * size.width + sway;
      final alpha = _bellAlpha(p) * 0.35;

      // HANDCRAFTED Void Gravity Well: particles get subtly drawn in by the avatar aura
      final dx = avatarCenter.dx - rawX;
      final dy = avatarCenter.dy - rawY;
      final dist = math.sqrt(dx * dx + dy * dy);

      double x = rawX;
      double y = rawY;
      if (gravityVortex && dist < 250 && dist > 5) {
        final pullForce = (1.0 - dist / 250) * 45; // stronger pull
        final angle = (1.0 - dist / 250) * 1.6; // spiral twist angle
        // Pull inward toward avatar center
        x += (dx / dist) * pullForce;
        y += (dy / dist) * pullForce;
        // Rotate / spiral around avatar center
        final tempX = x - avatarCenter.dx;
        final tempY = y - avatarCenter.dy;
        x = avatarCenter.dx + tempX * math.cos(angle) - tempY * math.sin(angle);
        y = avatarCenter.dy + tempX * math.sin(angle) + tempY * math.cos(angle);
      }

      // Shimmering void spec twinkle
      final shimmer = gravityVortex
          ? 0.4 + 0.6 * math.sin(t * 16 * math.pi + s.phase * 15)
          : 1.0;
      paint.color = const Color(0xFFFFFFFF).withValues(alpha: alpha * shimmer);

      canvas.drawCircle(Offset(x, y), s.size * shimmer, paint);
    }
  }

  double _bellAlpha(double p) {
    const ramp = 0.2;
    if (p < ramp) return p / ramp;
    if (p > 1.0 - ramp) return (1.0 - p) / ramp;
    return 1.0;
  }

  @override
  bool shouldRepaint(_WhiteDustPainter old) => old.t != t;
}

// =============================================================================
// Oubliette — rising toxic green bubbles with wobble
// =============================================================================

class _ToxicBubbles extends StatefulWidget {
  const _ToxicBubbles();
  @override
  State<_ToxicBubbles> createState() => _ToxicBubblesState();
}

class _ToxicBubblesState extends State<_ToxicBubbles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_BubbleSpec> _specs;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
    final rng = math.Random(666);
    const count = 12;
    _specs = List.generate(count, (i) {
      return _BubbleSpec(
        x: rng.nextDouble(),
        speed: 0.85 + rng.nextDouble() * 0.30,
        phase: i / count + rng.nextDouble() * (1.0 / count) * 0.4,
        radius: 2.5 + rng.nextDouble() * 4.5,
        wobble: 10 + rng.nextDouble() * 18,
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _ToxicBubblesPainter(t: _c.value, specs: _specs),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _BubbleSpec {
  final double x;
  final double speed;
  final double phase;
  final double radius;
  final double wobble;
  const _BubbleSpec({
    required this.x,
    required this.speed,
    required this.phase,
    required this.radius,
    required this.wobble,
  });
}

class _ToxicBubblesPainter extends CustomPainter {
  final double t;
  final List<_BubbleSpec> specs;
  _ToxicBubblesPainter({required this.t, required this.specs});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;
    for (final s in specs) {
      final p = ((t * s.speed) + s.phase) % 1.0;
      // Bottom→top (rising ooze).
      final y = size.height * (1.0 - p);
      final wobble = math.sin(p * 2 * math.pi + s.phase * 5) * s.wobble;
      final x = s.x * size.width + wobble;
      final alpha = _bellAlpha(p) * 0.50;
      paint.color = const Color(0xFF4ADE36).withValues(alpha: alpha);
      paint.strokeWidth = 1.2;
      canvas.drawCircle(Offset(x, y), s.radius, paint);
      // Tiny highlight dot for bubble shine.
      paint.style = PaintingStyle.fill;
      paint.color = const Color(0xFF8BC34A).withValues(alpha: alpha * 0.35);
      canvas.drawCircle(
        Offset(x - s.radius * 0.25, y - s.radius * 0.25),
        s.radius * 0.25,
        paint,
      );
      paint.style = PaintingStyle.stroke;
    }
  }

  double _bellAlpha(double p) {
    const ramp = 0.18;
    if (p < ramp) return p / ramp;
    if (p > 1.0 - ramp) return (1.0 - p) / ramp;
    return 1.0;
  }

  @override
  bool shouldRepaint(_ToxicBubblesPainter old) => old.t != t;
}

// =============================================================================
// Minimalist — printed-page hairline frame
// =============================================================================

/// 1px hairline rectangle inset from the viewport edges. Reads as a
/// "page boundary" for the Paper theme without obscuring any content.
class _PageFrame extends StatelessWidget {
  const _PageFrame();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFE8E4D9).withValues(alpha: 0.18),
            width: 1,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Forge Master — rising molten embers/sparks
// =============================================================================

class _ForgeEmbers extends StatefulWidget {
  final bool advancedFlicker;
  const _ForgeEmbers({required this.advancedFlicker});
  @override
  State<_ForgeEmbers> createState() => _ForgeEmbersState();
}

class _ForgeEmbersState extends State<_ForgeEmbers>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_DustSpec> _specs;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    final rng = math.Random(718);
    const count = 22;
    _specs = List.generate(count, (i) {
      return _DustSpec(
        x: rng.nextDouble(),
        speed: 0.9 + rng.nextDouble() * 0.3,
        phase: i / count + rng.nextDouble() * (1.0 / count) * 0.5,
        size: 1.4 + rng.nextDouble() * 2.2,
        sway: 12 + rng.nextDouble() * 20,
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _ForgeEmbersPainter(t: _c.value, specs: _specs, advancedFlicker: widget.advancedFlicker),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ForgeEmbersPainter extends CustomPainter {
  final double t;
  final List<_DustSpec> specs;
  final bool advancedFlicker;
  _ForgeEmbersPainter({required this.t, required this.specs, required this.advancedFlicker});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < specs.length; i++) {
      final s = specs[i];
      final p = ((t * s.speed) + s.phase) % 1.0;
      final y = size.height * (1.0 - p);
      final sway = math.sin(p * 3 * math.pi + s.phase * 5) * s.sway * 1.4;
      final x = s.x * size.width + sway;
      final alpha = _bellAlpha(p) * 0.75;

      // Flame-like thermal flicker modulation
      final flicker = advancedFlicker
          ? 0.75 + 0.25 * math.sin(t * 18 * math.pi + s.phase * 24)
          : 1.0;
      final finalAlpha = (alpha * flicker).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(x, y);

      if (i % 3 == 0) {
        // Molten Exploding Spark: sharp star spark pattern
        paint.color = const Color(0xFFFF3D00).withValues(alpha: finalAlpha); // Bright hot orange-red
        final double sparkSize = s.size * 2.2 * flicker;
        final path = Path()
          ..moveTo(0, -sparkSize)
          ..lineTo(sparkSize * 0.15, -sparkSize * 0.15)
          ..lineTo(sparkSize, 0)
          ..lineTo(sparkSize * 0.15, sparkSize * 0.15)
          ..lineTo(0, sparkSize)
          ..lineTo(-sparkSize * 0.15, sparkSize * 0.15)
          ..lineTo(-sparkSize, 0)
          ..lineTo(-sparkSize * 0.15, -sparkSize * 0.15)
          ..close();
        canvas.drawPath(path, paint);
      } else {
        // High-thermal rising round ember with gold/orange flame-like breathing scale
        paint.color = i % 2 == 0 ? const Color(0xFFFF9100) : const Color(0xFFFFD600);
        final scaleSize = s.size * 1.5 * flicker;
        canvas.drawCircle(Offset.zero, scaleSize, paint);

        // Internal white-hot radiant heat core
        paint.color = Colors.white.withValues(alpha: finalAlpha * 0.9);
        canvas.drawCircle(Offset.zero, scaleSize * 0.45, paint);
      }
      canvas.restore();
    }
  }

  double _bellAlpha(double p) {
    const ramp = 0.15;
    if (p < ramp) return p / ramp;
    if (p > 1.0 - ramp) return (1.0 - p) / ramp;
    return 1.0;
  }

  @override
  bool shouldRepaint(_ForgeEmbersPainter old) => old.t != t;
}

// =============================================================================
// Lich's Tomb — necrotic hellfire embers
// =============================================================================

class _Hellfire extends StatefulWidget {
  final bool advancedFlicker;
  const _Hellfire({required this.advancedFlicker});
  @override
  State<_Hellfire> createState() => _HellfireState();
}

class _HellfireState extends State<_Hellfire>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_DustSpec> _specs;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    final rng = math.Random(13);
    const count = 18;
    _specs = List.generate(count, (i) {
      return _DustSpec(
        x: rng.nextDouble(),
        speed: 0.8 + rng.nextDouble() * 0.25,
        phase: i / count + rng.nextDouble() * (1.0 / count) * 0.4,
        size: 1.5 + rng.nextDouble() * 2.5,
        sway: 15 + rng.nextDouble() * 25,
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _HellfirePainter(t: _c.value, specs: _specs, advancedFlicker: widget.advancedFlicker),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _HellfirePainter extends CustomPainter {
  final double t;
  final List<_DustSpec> specs;
  final bool advancedFlicker;
  _HellfirePainter({required this.t, required this.specs, required this.advancedFlicker});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw curving turbulent heat haze / fire wind currents
    for (int i = 0; i < 3; i++) {
      final pOffset = (t + i / 3.0) % 1.0;
      final path = Path();
      final startY = size.height * (1.1 - pOffset);
      final c1y = startY - size.height * 0.25;
      final c2y = startY - size.height * 0.5;
      final endY = startY - size.height * 0.75;
      
      final startX = size.width * 1.1 - pOffset * (size.width * 1.2);
      path.moveTo(startX, startY);
      path.cubicTo(
        startX - size.width * 0.3, c1y + math.sin(pOffset * 3 * math.pi) * 60,
        startX - size.width * 0.6, c2y + math.cos(pOffset * 3 * math.pi) * 60,
        startX - size.width * 0.9, endY
      );

      final windColor = i % 2 == 0 ? const Color(0xFF9C27B0) : const Color(0xFFE91E63);
      final windPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = windColor.withValues(alpha: 0.04 + 0.03 * math.sin(t * 3 * math.pi));
      if (advancedFlicker) {
        windPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      }
      canvas.drawPath(path, windPaint);
    }

    // 2. Draw rising volcanic embers carried by hot diagonal winds
    final paint = Paint();
    for (var i = 0; i < specs.length; i++) {
      final s = specs[i];
      final p = ((t * s.speed) + s.phase) % 1.0;
      final y = size.height * (1.0 - p);
      // Hot wind diagonal sweep (sweeping leftwards from right)
      final windSweep = -p * size.width * 0.25;
      final sway = math.sin(p * 2 * math.pi + s.phase * 4) * s.sway;
      final x = (s.x * size.width + sway + windSweep) % size.width;
      final alpha = _bellAlpha(p) * 0.55;

      // Necrotic pulse vibration
      final pulse = advancedFlicker
          ? 0.85 + 0.15 * math.sin(t * 8 * math.pi + s.phase * 15)
          : 1.0;
      final finalAlpha = (alpha * pulse).clamp(0.0, 1.0);

      // Dark violet and necrotic pinkish-red
      final color = i % 2 == 0 ? const Color(0xFF9C27B0) : const Color(0xFFE91E63);
      paint.color = color.withValues(alpha: finalAlpha);

      // Draw misty glowing orbs with breathing blur radius
      if (advancedFlicker) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, (1.2 * pulse).clamp(0.4, 2.8));
      } else {
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
      }
      canvas.drawCircle(Offset(x, y), s.size * pulse, paint);
      paint.maskFilter = null;
    }
  }

  double _bellAlpha(double p) {
    const ramp = 0.2;
    if (p < ramp) return p / ramp;
    if (p > 1.0 - ramp) return (1.0 - p) / ramp;
    return 1.0;
  }

  @override
  bool shouldRepaint(_HellfirePainter old) => old.t != t;
}

// =============================================================================
// Past Slayer — cosmic temporal starry drift
// =============================================================================

class _CosmicRift extends StatefulWidget {
  final bool particleRotation;
  const _CosmicRift({required this.particleRotation});
  @override
  State<_CosmicRift> createState() => _CosmicRiftState();
}

class _CosmicRiftState extends State<_CosmicRift>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_DustSpec> _specs;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
    final rng = math.Random(321);
    const count = 24;
    _specs = List.generate(count, (i) {
      return _DustSpec(
        x: rng.nextDouble(),
        speed: 0.75 + rng.nextDouble() * 0.25,
        phase: i / count + rng.nextDouble() * (1.0 / count) * 0.5,
        size: 1.2 + rng.nextDouble() * 2.2,
        sway: 10 + rng.nextDouble() * 16,
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _CosmicRiftPainter(t: _c.value, specs: _specs, particleRotation: widget.particleRotation),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _CosmicRiftPainter extends CustomPainter {
  final double t;
  final List<_DustSpec> specs;
  final bool particleRotation;
  _CosmicRiftPainter({required this.t, required this.specs, required this.particleRotation});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw flowing cosmic solar wind paths
    for (int i = 0; i < 3; i++) {
      final pOffset = (t + i / 3.0) % 1.0;
      final path = Path();
      // Flow horizontally and vertically across representing solar winds
      final startX = size.width * (1.1 - pOffset);
      final c1x = startX - size.width * 0.25;
      final c2x = startX - size.width * 0.5;
      final endX = startX - size.width * 0.75;

      final startY = -120.0 + pOffset * (size.height + 240.0);
      path.moveTo(startX, startY);
      path.cubicTo(
        c1x + math.sin(pOffset * 2 * math.pi) * 50, startY + size.height * 0.25,
        c2x + math.cos(pOffset * 2 * math.pi) * 50, startY + size.height * 0.55,
        endX, startY + size.height * 0.85
      );

      final isCyan = i % 2 == 0;
      final windColor = isCyan ? const Color(0xFF00E5FF) : const Color(0xFFFFD700);
      final windPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = windColor.withValues(alpha: 0.05 + 0.03 * math.sin(t * 2 * math.pi));
      if (particleRotation) {
        windPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);
      }
      canvas.drawPath(path, windPaint);
    }

    // 2. Draw drifting stars and star sparkles
    final paint = Paint();
    for (var i = 0; i < specs.length; i++) {
      final s = specs[i];
      final p = ((t * s.speed) + s.phase) % 1.0;
      // Drift slowly downwards like a falling space rift
      final y = size.height * p;
      // Diagonal wind sweep (drifting bottom-rightwards)
      final windSweep = p * size.width * 0.15;
      final sway = math.sin(p * 2 * math.pi + s.phase * 6) * s.sway;
      final x = (s.x * size.width + sway + windSweep) % size.width;
      final alpha = _bellAlpha(p) * 0.50;

      // Star twinkle shimmer
      final twinkle = particleRotation
          ? 0.3 + 0.7 * math.sin(t * 22 * math.pi + s.phase * 22)
          : 1.0;

      // Neon cyan stars and cosmic gold sparkle dust
      final isCyan = i % 2 == 0;
      final color = isCyan ? const Color(0xFF00E5FF) : const Color(0xFFFFD700);
      paint.color = color.withValues(alpha: alpha);

      canvas.save();
      canvas.translate(x, y);
      if (particleRotation) {
        canvas.rotate(p * 3.8 * math.pi + s.phase * 10); // Beautiful cosmic spin
      }

      if (isCyan) {
        // Star point: small circle
        canvas.drawCircle(Offset.zero, s.size * 0.8 * twinkle, paint);
      } else {
        // Star sparkle cross / diamond shape
        final r = s.size * 1.5 * twinkle;
        final path = Path()
          ..moveTo(0, -r)
          ..lineTo(r * 0.4, 0)
          ..lineTo(0, r)
          ..lineTo(-r * 0.4, 0)
          ..close();
        canvas.drawPath(path, paint);
      }
      canvas.restore();
    }
  }

  double _bellAlpha(double p) {
    const ramp = 0.2;
    if (p < ramp) return p / ramp;
    if (p > 1.0 - ramp) return (1.0 - p) / ramp;
    return 1.0;
  }

  @override
  bool shouldRepaint(_CosmicRiftPainter old) => old.t != t;
}

// =============================================================================
// Premium Custom Particle Engine (Highly Interactive & High Performance!)
// =============================================================================

class _CustomParticleBackdrop extends StatefulWidget {
  final VisualPrefs prefs;
  const _CustomParticleBackdrop({required this.prefs});

  @override
  State<_CustomParticleBackdrop> createState() => _CustomParticleBackdropState();
}

class _CustomParticleBackdropState extends State<_CustomParticleBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final List<_CustomSpec> _specs = [];
  final Stopwatch _stopwatch = Stopwatch();
  ui.Image? _gunFairyImage;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _stopwatch.start();
    _generateSpecs();
    _loadGunFairyImage();
  }

  Future<void> _loadGunFairyImage() async {
    try {
      final data = await DefaultAssetBundle.of(context).load('assets/images/items/Gun_Fairy.webp');
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _gunFairyImage = frame.image;
        });
      }
    } catch (e) {
      debugPrint('Failed to load Gun_Fairy particle image: $e');
    }
  }

  @override
  void didUpdateWidget(_CustomParticleBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If emitters, custom type, or particle count change, regenerate some specs to match
    if (oldWidget.prefs.emitFromTop != widget.prefs.emitFromTop ||
        oldWidget.prefs.emitFromBottom != widget.prefs.emitFromBottom ||
        oldWidget.prefs.emitFromLeft != widget.prefs.emitFromLeft ||
        oldWidget.prefs.emitFromRight != widget.prefs.emitFromRight ||
        oldWidget.prefs.particleCount != widget.prefs.particleCount) {
      _generateSpecs();
    }
  }

  void _generateSpecs() {
    _specs.clear();
    final rng = math.Random();
    
    // Determine available emitter directions
    final List<String> directions = [];
    if (widget.prefs.emitFromTop) directions.add('top');
    if (widget.prefs.emitFromBottom) directions.add('bottom');
    if (widget.prefs.emitFromLeft) directions.add('left');
    if (widget.prefs.emitFromRight) directions.add('right');
    
    // Fallback if none enabled
    if (directions.isEmpty) {
      directions.add('bottom');
      directions.add('top');
    }

    for (var i = 0; i < widget.prefs.particleCount; i++) {
      final dir = directions[rng.nextInt(directions.length)];
      _specs.add(_CustomSpec(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 3.5 + rng.nextDouble() * 5.0,
        speed: 0.08 + rng.nextDouble() * 0.12,
        sway: 15 + rng.nextDouble() * 30,
        phase: rng.nextDouble(),
        direction: dir,
      ));
    }
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => CustomPaint(
        painter: _CustomParticlePainter(
          t: _stopwatch.elapsedMilliseconds / 1000.0,
          specs: _specs,
          prefs: widget.prefs,
          gunFairyImage: _gunFairyImage,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _CustomSpec {
  double x;
  double y;
  final double size;
  final double speed;
  final double sway;
  final double phase;
  final String direction; // 'top', 'bottom', 'left', 'right'

  _CustomSpec({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.sway,
    required this.phase,
    required this.direction,
  });
}

class _CustomParticlePainter extends CustomPainter {
  final double t;
  final List<_CustomSpec> specs;
  final VisualPrefs prefs;
  final ui.Image? gunFairyImage;

  _CustomParticlePainter({
    required this.t,
    required this.specs,
    required this.prefs,
    this.gunFairyImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (final s in specs) {
      // Calculate continuous progress
      final p = ((t * s.speed) + s.phase) % 1.0;
      
      // Calculate positions depending on their assigned emitter directions!
      double rawX = s.x * size.width;
      double rawY = s.y * size.height;
      final sway = math.sin(p * 2 * math.pi + s.phase * 8) * s.sway;

      if (s.direction == 'top') {
        rawY = size.height * p;
        rawX = (s.x * size.width + sway) % size.width;
      } else if (s.direction == 'bottom') {
        rawY = size.height * (1.0 - p);
        rawX = (s.x * size.width + sway) % size.width;
      } else if (s.direction == 'left') {
        rawX = size.width * p;
        rawY = (s.y * size.height + sway) % size.height;
      } else if (s.direction == 'right') {
        rawX = size.width * (1.0 - p);
        rawY = (s.y * size.height + sway) % size.height;
      }

      final alpha = _bellAlpha(p) * prefs.particleOpacity;
      if (alpha <= 0.01) continue;

      // Boost up flickering/twinkle globally! Rapid blinking sinusoids
      final twinkle = prefs.advancedFlicker
          ? 0.15 + 0.85 * math.sin(t * 32 * math.pi + s.phase * 50).abs()
          : 0.4 + 0.6 * math.sin(t * 18 * math.pi + s.phase * 22).abs();

      // Scaled size according to the size slider!
      final scaledSize = s.size * prefs.particleSizeScale * (prefs.advancedFlicker ? twinkle : 1.0);

      // Render custom types!
      switch (prefs.customParticleType) {
        case CustomParticleType.themeDefault:
          // Standard white dust as fallback
          paint.color = const Color(0xFFFFFFFF).withValues(alpha: alpha * 0.35);
          canvas.drawCircle(Offset(rawX, rawY), scaledSize * 0.5, paint);
          break;

        case CustomParticleType.ember:
          // Glowing embers/fire (Reds, Oranges, Golds)
          final isRed = s.phase < 0.4;
          final isOrange = s.phase >= 0.4 && s.phase < 0.8;
          final color = isRed
              ? const Color(0xFFFF3D00)
              : (isOrange ? const Color(0xFFFF9100) : const Color(0xFFFFD700));
          paint.color = color.withValues(alpha: alpha * twinkle * 0.8);
          
          // Draw circular glowing embers
          canvas.drawCircle(Offset(rawX, rawY), scaledSize * 0.6, paint);
          // Optional mini spark outline
          paint.color = Colors.white.withValues(alpha: alpha * twinkle * 0.3);
          canvas.drawCircle(Offset(rawX, rawY), scaledSize * 0.25, paint);
          break;

        case CustomParticleType.frost:
          // Glistening ice crystals (Cyan, Light Blue)
          final isCyan = s.phase < 0.5;
          final color = isCyan ? const Color(0xFF00E5FF) : const Color(0xFFB8E0F0);
          paint.color = color.withValues(alpha: alpha * twinkle * 0.7);

          // Draw a small ice-crystal cross / diamond shape
          final r = scaledSize * 0.8;
          final path = Path()
            ..moveTo(rawX, rawY - r)
            ..lineTo(rawX + r * 0.4, rawY)
            ..lineTo(rawX, rawY + r)
            ..lineTo(rawX - r * 0.4, rawY)
            ..close();
          canvas.drawPath(path, paint);
          break;

        case CustomParticleType.catpaw:
          // Playful Pink/Peach cat paws! Uses Text emoji/symbol 🐾
          tp.text = TextSpan(
            text: s.phase < 0.5 ? '🐾' : '🐱',
            style: TextStyle(
              fontSize: scaledSize * 2.2,
              color: const Color(0xFFFF8A80).withValues(alpha: alpha * twinkle * 0.85),
            ),
          );
          tp.layout();
          tp.paint(canvas, Offset(rawX - tp.width / 2, rawY - tp.height / 2));
          break;

        case CustomParticleType.rainbow:
          // Prismatic color shifting based on time and phase!
          final hue = (t * 360 + s.phase * 360) % 360;
          final color = HSLColor.fromAHSL(1.0, hue, 0.95, 0.6).toColor();
          paint.color = color.withValues(alpha: alpha * twinkle * 0.8);
          canvas.drawCircle(Offset(rawX, rawY), scaledSize * 0.5, paint);
          break;

        case CustomParticleType.curse:
          // Purple curses and flame wisps
          paint.color = const Color(0xFFD500F9).withValues(alpha: alpha * twinkle * 0.75);
          canvas.drawCircle(Offset(rawX, rawY), scaledSize * 0.5, paint);
          // Mini inner wisp
          paint.color = const Color(0xFF311B92).withValues(alpha: alpha * 0.4);
          canvas.drawCircle(Offset(rawX, rawY), scaledSize * 0.25, paint);
          break;

        case CustomParticleType.vvoid:
          // Deep void stars
          paint.color = const Color(0xFFECEFF1).withValues(alpha: alpha * twinkle * 0.55);
          canvas.drawCircle(Offset(rawX, rawY), scaledSize * 0.4, paint);
          break;

        case CustomParticleType.gunfairy:
          if (gunFairyImage != null) {
            final src = Rect.fromLTWH(0, 0, gunFairyImage!.width.toDouble(), gunFairyImage!.height.toDouble());
            final dst = Rect.fromCenter(center: Offset(rawX, rawY), width: scaledSize * 3.5, height: scaledSize * 3.5);
            paint.color = Colors.white.withValues(alpha: alpha);
            canvas.drawImageRect(gunFairyImage!, src, dst, paint);
          } else {
            paint.color = const Color(0xFFFF4081).withValues(alpha: alpha * twinkle);
            canvas.drawCircle(Offset(rawX, rawY), scaledSize * 0.5, paint);
          }
          break;
      }
    }
  }

  double _bellAlpha(double p) {
    const ramp = 0.15;
    if (p < ramp) return p / ramp;
    if (p > 1.0 - ramp) return (1.0 - p) / ramp;
    return 1.0;
  }

  @override
  bool shouldRepaint(_CustomParticlePainter old) => old.t != t;
}

class _TouchParticlePainter extends CustomPainter {
  final List<_TouchParticle> particles;
  _TouchParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      if (p.life <= 0) continue;
      paint.color = p.color.withValues(alpha: p.life);
      
      final path = Path();
      final hs = p.size * p.life;
      path.moveTo(p.pos.dx, p.pos.dy - hs);
      path.lineTo(p.pos.dx + hs, p.pos.dy);
      path.lineTo(p.pos.dx, p.pos.dy + hs);
      path.lineTo(p.pos.dx - hs, p.pos.dy);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_TouchParticlePainter old) => true;
}

class _HypnoticBg extends StatefulWidget {
  final String assetName;
  final double speedMultiplier;
  final double opacity;

  const _HypnoticBg({
    required this.assetName,
    required this.speedMultiplier,
    required this.opacity,
  });

  @override
  State<_HypnoticBg> createState() => _HypnoticBgState();
}

class _HypnoticBgState extends State<_HypnoticBg> {
  List<ui.Image> _frames = [];
  List<int> _durations = [];
  int _currentFrame = 0;
  Timer? _timer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGif();
  }

  @override
  void didUpdateWidget(_HypnoticBg oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetName != widget.assetName) {
      _isLoading = true;
      _currentFrame = 0;
      _timer?.cancel();
      _loadGif();
    } else if (oldWidget.speedMultiplier != widget.speedMultiplier) {
      _playGif();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadGif() async {
    try {
      final data = await rootBundle.load('assets/animations/trippy/${widget.assetName}');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      
      final List<ui.Image> frames = [];
      final List<int> durations = [];
      
      for (int i = 0; i < codec.frameCount; i++) {
        final frameInfo = await codec.getNextFrame();
        frames.add(frameInfo.image);
        durations.add(frameInfo.duration.inMilliseconds > 0 ? frameInfo.duration.inMilliseconds : 100);
      }
      
      if (mounted) {
        setState(() {
          _frames = frames;
          _durations = durations;
          _isLoading = false;
        });
        _playGif();
      }
    } catch (e) {
      debugPrint("Error loading hypnotic background gif: $e");
    }
  }

  void _playGif() {
    _timer?.cancel();
    if (_frames.isEmpty || !mounted) return;

    final baseDuration = _durations[_currentFrame];
    final adjustedDuration = (baseDuration / widget.speedMultiplier).round().clamp(10, 5000);

    _timer = Timer(Duration(milliseconds: adjustedDuration), () {
      if (!mounted) return;
      setState(() {
        _currentFrame = (_currentFrame + 1) % _frames.length;
      });
      _playGif();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _frames.isEmpty) {
      return const SizedBox.shrink();
    }
    return RawImage(
      image: _frames[_currentFrame],
      fit: BoxFit.cover,
      opacity: AlwaysStoppedAnimation<double>(widget.opacity),
    );
  }
}

class _SecretCatThroneOverlay extends StatelessWidget {
  const _SecretCatThroneOverlay();

  @override
  Widget build(BuildContext context) {
    try {
      final runProvider = Provider.of<RunProvider>(context);
      final hasThrone = runProvider.runState.allItemNames.contains("Cat Bullet King Throne");
      if (!hasThrone) return const SizedBox.shrink();

      return const Positioned.fill(
        child: IgnorePointer(
          child: _CuriousCatStareWidget(),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}

class _CuriousCatStareWidget extends StatefulWidget {
  const _CuriousCatStareWidget();

  @override
  State<_CuriousCatStareWidget> createState() => _CuriousCatStareWidgetState();
}

class _CuriousCatStareWidgetState extends State<_CuriousCatStareWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  Timer? _triggerTimer;
  bool _isPeeking = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _triggerTimer = Timer.periodic(const Duration(seconds: 35), (timer) {
      if (mounted && !_isPeeking) {
        _triggerCatPeek();
      }
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && !_isPeeking) {
        _triggerCatPeek();
      }
    });
  }

  void _triggerCatPeek() async {
    _isPeeking = true;
    if (mounted) {
      Haptics.light();
      await _animController.forward();
    }
    await Future.delayed(const Duration(milliseconds: 4500));
    if (mounted) {
      Haptics.light();
      await _animController.reverse();
    }
    _isPeeking = false;
  }

  @override
  void dispose() {
    _triggerTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final double value = _animController.value;
        final double slideOffset = (1.0 - value) * 120.0;
        final double wiggleAngle = value > 0.95
            ? math.sin(DateTime.now().millisecondsSinceEpoch * 0.005) * 0.04
            : 0.0;

        return Positioned(
          bottom: 40.0,
          right: -45.0 + slideOffset,
          width: 140.0,
          height: 140.0,
          child: Transform.rotate(
            angle: wiggleAngle,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
      child: Image.asset(
        'assets/images/items/cat_bullet_king_throne.webp',
        filterQuality: FilterQuality.none,
        fit: BoxFit.contain,
      ),
    );
  }
}


