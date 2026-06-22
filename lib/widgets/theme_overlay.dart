import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:video_player/video_player.dart';

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

  /// Static global notifier for the current physical device tilt (x, y).
  /// x is tilt left/right (-10 to 10), y is tilt up/down (-10 to 10).
  static final ValueNotifier<Offset> tiltNotifier = ValueNotifier(Offset.zero);

  /// Static global notifier for the current screen index (0=Home, 1=Browse, 2=Settings).
  /// Used to force the Galaxy animated background on the Home screen only.
  static final ValueNotifier<int> currentScreenIndex = ValueNotifier(0);

  /// The Galaxy animated wallpaper asset that always plays on the Home screen.
  static const String kHomeGalaxyAsset = 'wp_anim_01_galaxy.mp4';

  @override
  State<ThemeOverlay> createState() => _ThemeOverlayState();
}

class _ThemeOverlayState extends State<ThemeOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _touchTicker;
  final List<_TouchParticle> _touchParticles = [];
  final math.Random _rng = math.Random();
  StreamSubscription? _sensorSub;
  Offset _smoothedTilt = Offset.zero;

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

    // Standard low-pass filter to smooth out gyroscope sways
    _sensorSub = accelerometerEventStream().listen((event) {
      final tx = -event.x.clamp(-6.0, 6.0);
      final ty = event.y.clamp(-6.0, 6.0);
      _smoothedTilt = Offset(
        _smoothedTilt.dx + (tx - _smoothedTilt.dx) * 0.12,
        _smoothedTilt.dy + (ty - _smoothedTilt.dy) * 0.12,
      );
      ThemeOverlay.tiltNotifier.value = _smoothedTilt;
    }, onError: (_) {
      // Graceful fallback for non-gyro devices (e.g. desktop/emulators)
    });
  }

  @override
  void dispose() {
    _touchTicker.dispose();
    _sensorSub?.cancel();
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
    return AnimatedBuilder(
      animation: Listenable.merge([AppTheme.notifier, AppTheme.previewNotifier]),
      builder: (_, __) {
        final mode = AppTheme.displayedMode;
        return ValueListenableBuilder<VisualPrefs>(
          valueListenable: VisualPrefs.notifier,
          builder: (_, prefs, __) {
            return ValueListenableBuilder<int>(
              valueListenable: ThemeOverlay.currentScreenIndex,
              builder: (_, screenIndex, __) {
                final isHomeScreen = screenIndex == 0;
            final f = AppTheme.displayedFlair;
          final showGlow = prefs.glowIntensity > 0.001;
          final gP = showGlow
              ? _scaleAlpha(f.glowPrimary,   prefs.glowIntensity)
              : const Color(0x00000000);
          final gS = showGlow
              ? _scaleAlpha(f.glowSecondary, prefs.glowIntensity)
              : const Color(0x00000000);
          final isWallpaperActive = !isHomeScreen && prefs.wallpaperMode != WallpaperMode.themeDefault;
          final hypnoticBackdrop = (prefs.hypnoticBgEnabled && !isWallpaperActive && !isHomeScreen)
              ? _HypnoticBg(
                  assetName: prefs.hypnoticBgAsset,
                  speedMultiplier: prefs.hypnoticBgSpeed,
                  opacity: prefs.hypnoticBgOpacity,
                )
              : null;
          final particlesOn = prefs.particlesEnabled &&
              prefs.customParticleType != CustomParticleType.none;
          final particleBackdropBg = !particlesOn
              ? null
              : (prefs.customParticleType != CustomParticleType.themeDefault
                  ? _CustomParticleBackdrop(prefs: prefs)
                  : _backdropFor(f.backdrop, prefs));
          final particleBackdropFg = !particlesOn
              ? null
              : (prefs.customParticleType != CustomParticleType.themeDefault
                  ? _CustomParticleBackdrop(prefs: prefs)
                  : _backdropFor(f.backdrop, prefs));
          Widget content = widget.child;

          // Apply visual customizer wrappers based on active Theme Mode!
          if (mode == AppThemeMode.bulletHell) {
            content = ElasticWobbleContainer(
              intensity: 0.05,
              speed: 0.6,
              child: content,
            );
          }

          return Listener(
            onPointerDown: (event) {
              if (ThemeOverlay.currentScreenIndex.value == 0) return;
              _spawnTouchSparkles(event.position, prefs);
            },
            behavior: HitTestBehavior.translucent,
            child: Stack(
              children: [
                // 0. Absolute Base Solid Background Color (since scaffolds are transparent)
                Positioned.fill(
                  child: Container(color: f.scaffold),
                ),

                // 0.4. Home Screen Galaxy — always plays on the Home/ActiveRun screen
                if (isHomeScreen)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.55,
                        child: _AnimatedWallpaperBackground(
                          key: const ValueKey('home_galaxy'),
                          assetName: ThemeOverlay.kHomeGalaxyAsset,
                        ),
                      ),
                    ),
                  ),

                // 0.5. Custom Still or Animated Wallpaper (non-Home screens only)
                if (!isHomeScreen && prefs.wallpaperMode == WallpaperMode.customStill)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _StillWallpaperBackground(
                        assetName: prefs.selectedStillWallpaper,
                        parallaxEnabled: prefs.parallaxMotionEnabled,
                      ),
                    ),
                  ),
                if (!isHomeScreen && prefs.wallpaperMode == WallpaperMode.customAnimated)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _AnimatedWallpaperBackground(
                        assetName: prefs.selectedAnimatedWallpaper,
                      ),
                    ),
                  ),

                // 0.6. Custom Wallpaper Contrast Backing (prevents background detail bleeding through UI panels)
                if (isWallpaperActive)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                  ),

                // 1a. Hypnotic Trippy Background
                if (hypnoticBackdrop != null)
                  Positioned.fill(child: IgnorePointer(child: hypnoticBackdrop)),

                // 1b. Particles / Theme Backdrops (Background Layer)
                if (particleBackdropBg != null)
                  Positioned.fill(child: IgnorePointer(child: particleBackdropBg)),

                // 2. Middle Layer: Core App Content (wrapped in visual physics controllers)
                content,

                // 2.5. Foreground Particles Layer (drifts gracefully over cards and panels!)
                if (particleBackdropFg != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: particleBackdropFg,
                    ),
                  ),

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

                // 3.5. Chamber Vignette Shadow Overlay (Depth effect with shadows!)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.25,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.25),
                            Colors.black.withValues(alpha: 0.48),
                          ],
                          stops: const [0.0, 0.45, 0.82, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3.6. Enhanced Readability Scrim — when any wallpaper or
                // Galaxy bg is active, lay down a semi-opaque dark veil so
                // that foreground cards, text, and panels stay crisp.
                if (isHomeScreen)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.22),
                              Colors.black.withValues(alpha: 0.08),
                              Colors.black.withValues(alpha: 0.14),
                              Colors.black.withValues(alpha: 0.28),
                            ],
                            stops: const [0.0, 0.3, 0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
                  )
                else if (isWallpaperActive)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.12),
                              Colors.black.withValues(alpha: 0.04),
                              Colors.black.withValues(alpha: 0.08),
                              Colors.black.withValues(alpha: 0.18),
                            ],
                            stops: const [0.0, 0.3, 0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                if (f.pageFrame)
                  const Positioned.fill(
                      child: IgnorePointer(child: _PageFrame())),

                // 4. Special Top-Edge Drip Overlay (Curseblaster / Oubliette themes)
                if (mode == AppThemeMode.lordJammed)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 60,
                    child: IgnorePointer(
                      child: EdgeDripWidget(
                        color: Color(0x66990000), // Translucent Curse crimson drip
                        dripCount: 5,
                        maxDripHeight: 25.0,
                        viscosity: 1.2,
                      ),
                    ),
                  ),

                if (!isHomeScreen && prefs.particlesEnabled && _touchParticles.isNotEmpty)
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
            );
        },
      );
    },
  );
}

  Widget? _backdropFor(ThemeBackdrop b, VisualPrefs prefs) {
    switch (b) {
      case ThemeBackdrop.none:
        return null;
      case ThemeBackdrop.goldDust:
        return _GoldDust(advancedFlicker: prefs.advancedFlicker, subtleMode: prefs.subtleParticleMode);
      case ThemeBackdrop.pastelDriftSparkles:
        // Drift is now handled globally by _AmbientGlow; only the
        // sparkles are Unicorn-specific.
        return _Sparkles(particleRotation: prefs.particleRotation, subtleMode: prefs.subtleParticleMode);
      case ThemeBackdrop.redBreathDrip:
        return const _RedBreathDrip();
      case ThemeBackdrop.brassMotes:
        return _BrassMotes(subtleMode: prefs.subtleParticleMode);
      case ThemeBackdrop.paperBreath:
        // Paper theme gets only the ambient glow + page frame — no
        // particle layer. "Stillness is the quirk."
        return null;
      case ThemeBackdrop.iceCrystals:
        return _IceCrystals(particleRotation: prefs.particleRotation, subtleMode: prefs.subtleParticleMode);
      case ThemeBackdrop.whiteDust:
        return _WhiteDust(gravityVortex: prefs.gravityVortex, subtleMode: prefs.subtleParticleMode);
      case ThemeBackdrop.toxicBubbles:
        return _ToxicBubbles(subtleMode: prefs.subtleParticleMode);
      case ThemeBackdrop.forgeEmbers:
        return _ForgeEmbers(advancedFlicker: prefs.advancedFlicker, subtleMode: prefs.subtleParticleMode);
      case ThemeBackdrop.hellfire:
        return _Hellfire(advancedFlicker: prefs.advancedFlicker, subtleMode: prefs.subtleParticleMode);
      case ThemeBackdrop.cosmicRift:
        return _CosmicRift(particleRotation: prefs.particleRotation, subtleMode: prefs.subtleParticleMode);
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
    // Shunted duration from 26s down to 14s for active, snappy ambiance!
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
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
        final pulse = 0.88 + 0.12 * math.sin(t * 2); // Organic breathing pulse
        
        final cx = 0.5 + 0.28 * math.cos(t);
        final cy = 0.5 + 0.20 * math.sin(t);

        // Dynamically boost background gradient alphas for vibrant contrast
        final pColor = widget.primary.withOpacity((widget.primary.opacity * 1.55).clamp(0.0, 0.95));
        final sColor = widget.secondary.withOpacity((widget.secondary.opacity * 1.55).clamp(0.0, 0.95));

        return Stack(
          children: [
            // Primary glow — brightest, wandering.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(cx * 2 - 1, cy * 2 - 1),
                    radius: 1.0 * pulse,
                    colors: [
                      pColor,
                      sColor,
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
                    radius: 1.15 * pulse,
                    colors: [
                      sColor,
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
  final bool subtleMode;
  const _GoldDust({required this.advancedFlicker, required this.subtleMode});
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
        animation: Listenable.merge([_c, ThemeOverlay.tiltNotifier]),
        builder: (_, __) => CustomPaint(
          painter: _GoldDustPainter(
            t: _c.value,
            specs: _specs,
            advancedFlicker: widget.advancedFlicker,
            subtleMode: widget.subtleMode,
          ),
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
  final bool subtleMode;
  _GoldDustPainter({
    required this.t,
    required this.specs,
    required this.advancedFlicker,
    required this.subtleMode,
  });

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

    // 2. Draw gold dust particles carried diagonally by the wind with tilt physics
    final paint = Paint();
    final tilt = ThemeOverlay.tiltNotifier.value;
    final limit = subtleMode ? (specs.length / 2).round().clamp(2, specs.length) : specs.length;
    for (int i = 0; i < limit; i++) {
      final s = specs[i];
      // Position cycles 0→1 over the spec's speed-scaled duration.
      final p = ((t * s.speed) + s.phase) % 1.0;
      // Bottom→top: y starts at size.height and drifts up, offset slightly by physical Y tilt.
      final y = (size.height * (1.0 - p) + tilt.dy * 15 * p) % size.height;
      // Wind-swept diagonal drift + physical X tilt forces!
      final diagonalDrift = p * size.width * 0.18;
      final tiltXShift = tilt.dx * 25 * p; // sways more at the top of their drift!
      // Lateral sway via a sine wave for a "floaty" feel.
      final sway = math.sin(p * 2 * math.pi + s.phase * 6) * s.sway;
      final x = (s.x * size.width + sway + diagonalDrift + tiltXShift) % size.width;
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
  final bool subtleMode;
  const _Sparkles({required this.particleRotation, required this.subtleMode});
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
        animation: Listenable.merge([_c, ThemeOverlay.tiltNotifier]),
        builder: (_, __) => CustomPaint(
          painter: _SparklesPainter(
            t: _c.value,
            specs: _specs,
            particleRotation: widget.particleRotation,
            subtleMode: widget.subtleMode,
          ),
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
  final bool subtleMode;
  _SparklesPainter({
    required this.t,
    required this.specs,
    required this.particleRotation,
    required this.subtleMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final tilt = ThemeOverlay.tiltNotifier.value;
    final limit = subtleMode ? (specs.length / 2).round().clamp(2, specs.length) : specs.length;
    for (int i = 0; i < limit; i++) {
      final s = specs[i];
      final p = ((t * s.speed) + s.phase) % 1.0;
      final y = (size.height * (1.0 - p) + tilt.dy * 12 * p) % size.height;
      final sway = math.sin(p * 2 * math.pi + s.phase * 6) * s.sway * 1.2;
      final tiltXShift = tilt.dx * 20 * p;
      final x = (s.x * size.width + sway + tiltXShift) % size.width;
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

/// Three layers stacked: a slow-morphing violet cosmic gas cloud, the original
/// soft red vignette breath, plus a fresh crimson drop sliding down every ~12s.
class _RedBreathDrip extends StatelessWidget {
  const _RedBreathDrip();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Positioned.fill(child: _CurseFog()),
        Positioned.fill(child: _CurseBreath()),
        Positioned.fill(child: _CrimsonDrip()),
      ],
    );
  }
}

class _CurseFog extends StatefulWidget {
  const _CurseFog();
  @override
  State<_CurseFog> createState() => _CurseFogState();
}

class _CurseFogState extends State<_CurseFog> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
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
      builder: (context, child) {
        final t = _c.value;
        return CustomPaint(
          painter: _CurseFogPainter(t: t),
          size: Size.infinite,
        );
      },
    );
  }
}

class _CurseFogPainter extends CustomPainter {
  final double t;
  _CurseFogPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 45);

    final centers = [
      Offset(
        size.width * (0.2 + math.sin(t * 2 * math.pi) * 0.15),
        size.height * (0.3 + math.cos(t * 2 * math.pi) * 0.1),
      ),
      Offset(
        size.width * (0.8 - math.cos(t * 2 * math.pi) * 0.15),
        size.height * (0.7 + math.sin(t * 2 * math.pi) * 0.15),
      ),
      Offset(
        size.width * (0.5 + math.sin(t * 2 * math.pi * 1.5) * 0.2),
        size.height * (0.45 - math.cos(t * 2 * math.pi * 1.5) * 0.12),
      ),
    ];

    final colors = [
      const Color(0x1B6A0D7B),
      const Color(0x223E0054),
      const Color(0x184A0E4E),
    ];

    final radii = [
      size.width * 0.45,
      size.width * 0.5,
      size.width * 0.4,
    ];

    for (int i = 0; i < centers.length; i++) {
      paint.color = colors[i];
      canvas.drawCircle(centers[i], radii[i], paint);
    }
  }

  @override
  bool shouldRepaint(_CurseFogPainter old) => old.t != t;
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
        animation: Listenable.merge([_c, ThemeOverlay.tiltNotifier]),
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
    
    // Floating dark curse ashes (Red-Black embers) drifting upwards with tilt physics!
    final math.Random rng = math.Random(666);
    final tilt = ThemeOverlay.tiltNotifier.value;
    for (int i = 0; i < 15; i++) {
      final double speed = 0.4 + rng.nextDouble() * 0.5;
      final double phase = i / 15.0;
      final double progress = (t * speed + phase) % 1.0;
      
      final y = (size.height * (1.0 - progress) + tilt.dy * 15 * progress) % size.height;
      final sway = math.sin(progress * 2 * math.pi + phase * 8) * 22;
      final tiltXShift = tilt.dx * 18 * progress;
      final x = ((i / 15.0) * size.width + sway + tiltXShift) % size.width;
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
  final bool subtleMode;
  const _BrassMotes({required this.subtleMode});
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
    const count = 28;
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
        animation: Listenable.merge([_c, ThemeOverlay.tiltNotifier]),
        builder: (_, __) => CustomPaint(
          painter: _BrassMotesPainter(
            t: _c.value,
            specs: _specs,
            subtleMode: widget.subtleMode,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _BrassMotesPainter extends CustomPainter {
  final double t;
  final List<_DustSpec> specs;
  final bool subtleMode;
  _BrassMotesPainter({
    required this.t,
    required this.specs,
    required this.subtleMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final tilt = ThemeOverlay.tiltNotifier.value;
    final limit = subtleMode ? (specs.length / 2).round().clamp(2, specs.length) : specs.length;
    for (int i = 0; i < limit; i++) {
      final s = specs[i];
      final p = ((t * s.speed) + s.phase) % 1.0;
      final y = (size.height * (1.0 - p) + tilt.dy * 12 * p) % size.height;
      
      // Wider lazy horizontal drift matching prairie wind currents + tilt!
      final sway = math.sin(p * 2 * math.pi + s.phase * 4) * s.sway * 1.5;
      final tiltXShift = tilt.dx * 18 * p;
      final x = (s.x * size.width + sway + tiltXShift) % size.width;
      final alpha = _bellAlpha(p) * 0.85;

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
  final bool subtleMode;
  const _IceCrystals({required this.particleRotation, required this.subtleMode});
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
        animation: Listenable.merge([_c, ThemeOverlay.tiltNotifier]),
        builder: (_, __) => CustomPaint(
          painter: _IceCrystalsPainter(
            t: _c.value,
            specs: _specs,
            particleRotation: widget.particleRotation,
            subtleMode: widget.subtleMode,
          ),
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
  final bool subtleMode;
  _IceCrystalsPainter({
    required this.t,
    required this.specs,
    required this.particleRotation,
    required this.subtleMode,
  });

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
    final tilt = ThemeOverlay.tiltNotifier.value;
    final limit = subtleMode ? (specs.length / 2).round().clamp(2, specs.length) : specs.length;
    for (int i = 0; i < limit; i++) {
      final s = specs[i];
      final p = ((t * s.speed) + s.phase) % 1.0;
      // Top to bottom drift + tilt!
      final y = (size.height * p + tilt.dy * 12 * p) % size.height;
      final sway = math.sin(p * 2 * math.pi + s.phase * 6) * s.sway * 1.2;
      final tiltXShift = tilt.dx * 18 * p;
      final x = (s.x * size.width + sway + tiltXShift) % size.width;
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
  final bool subtleMode;
  const _WhiteDust({required this.gravityVortex, required this.subtleMode});
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
        animation: Listenable.merge([_c, ThemeOverlay.tiltNotifier]),
        builder: (_, __) => CustomPaint(
          painter: _WhiteDustPainter(
            t: _c.value,
            specs: _specs,
            gravityVortex: widget.gravityVortex,
            subtleMode: widget.subtleMode,
          ),
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
  final bool subtleMode;
  _WhiteDustPainter({
    required this.t,
    required this.specs,
    required this.gravityVortex,
    required this.subtleMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final avatarCenter = Offset(size.width * 0.5, 115);
    final tilt = ThemeOverlay.tiltNotifier.value;
    final limit = subtleMode ? (specs.length / 2).round().clamp(2, specs.length) : specs.length;

    for (int i = 0; i < limit; i++) {
      final s = specs[i];
      final p = ((t * s.speed) + s.phase) % 1.0;
      final rawY = (size.height * (1.0 - p) + tilt.dy * 12 * p) % size.height;
      final sway = math.sin(p * 2 * math.pi + s.phase * 4) * s.sway;
      final tiltXShift = tilt.dx * 18 * p;
      final rawX = (s.x * size.width + sway + tiltXShift) % size.width;
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
  final bool subtleMode;
  const _ToxicBubbles({required this.subtleMode});
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
        animation: Listenable.merge([_c, ThemeOverlay.tiltNotifier]),
        builder: (_, __) => CustomPaint(
          painter: _ToxicBubblesPainter(
            t: _c.value,
            specs: _specs,
            subtleMode: widget.subtleMode,
          ),
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
  final bool subtleMode;
  _ToxicBubblesPainter({
    required this.t,
    required this.specs,
    required this.subtleMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;
    final tilt = ThemeOverlay.tiltNotifier.value;
    final limit = subtleMode ? (specs.length / 2).round().clamp(2, specs.length) : specs.length;
    for (int i = 0; i < limit; i++) {
      final s = specs[i];
      final p = ((t * s.speed) + s.phase) % 1.0;
      // Bottom→top (rising ooze) with tilt physics!
      final y = (size.height * (1.0 - p) + tilt.dy * 15 * p) % size.height;
      final wobble = math.sin(p * 2 * math.pi + s.phase * 5) * s.wobble;
      final tiltXShift = tilt.dx * 18 * p;
      final x = (s.x * size.width + wobble + tiltXShift) % size.width;
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
  final bool subtleMode;
  const _ForgeEmbers({required this.advancedFlicker, required this.subtleMode});
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
        animation: Listenable.merge([_c, ThemeOverlay.tiltNotifier]),
        builder: (_, __) => CustomPaint(
          painter: _ForgeEmbersPainter(
            t: _c.value,
            specs: _specs,
            advancedFlicker: widget.advancedFlicker,
            subtleMode: widget.subtleMode,
          ),
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
  final bool subtleMode;
  _ForgeEmbersPainter({
    required this.t,
    required this.specs,
    required this.advancedFlicker,
    required this.subtleMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final tilt = ThemeOverlay.tiltNotifier.value;
    final limit = subtleMode ? (specs.length / 2).round().clamp(2, specs.length) : specs.length;
    for (var i = 0; i < limit; i++) {
      final s = specs[i];
      final p = ((t * s.speed) + s.phase) % 1.0;
      // Rising embers with tilt physics!
      final y = (size.height * (1.0 - p) + tilt.dy * 15 * p) % size.height;
      final sway = math.sin(p * 3 * math.pi + s.phase * 5) * s.sway * 1.4;
      final tiltXShift = tilt.dx * 18 * p;
      final x = (s.x * size.width + sway + tiltXShift) % size.width;
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
  final bool subtleMode;
  const _Hellfire({required this.advancedFlicker, required this.subtleMode});
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
        animation: Listenable.merge([_c, ThemeOverlay.tiltNotifier]),
        builder: (_, __) => CustomPaint(
          painter: _HellfirePainter(
            t: _c.value,
            specs: _specs,
            advancedFlicker: widget.advancedFlicker,
            subtleMode: widget.subtleMode,
          ),
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
  final bool subtleMode;
  _HellfirePainter({
    required this.t,
    required this.specs,
    required this.advancedFlicker,
    required this.subtleMode,
  });

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

    // 2. Draw rising volcanic embers carried by hot diagonal winds with tilt physics!
    final paint = Paint();
    final tilt = ThemeOverlay.tiltNotifier.value;
    final limit = subtleMode ? (specs.length / 2).round().clamp(2, specs.length) : specs.length;
    for (var i = 0; i < limit; i++) {
      final s = specs[i];
      final p = ((t * s.speed) + s.phase) % 1.0;
      final y = (size.height * (1.0 - p) + tilt.dy * 15 * p) % size.height;
      // Hot wind diagonal sweep (sweeping leftwards from right)
      final windSweep = -p * size.width * 0.25;
      final sway = math.sin(p * 2 * math.pi + s.phase * 4) * s.sway;
      final tiltXShift = tilt.dx * 18 * p;
      final x = (s.x * size.width + sway + windSweep + tiltXShift) % size.width;
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
  final bool subtleMode;
  const _CosmicRift({required this.particleRotation, required this.subtleMode});
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
        animation: Listenable.merge([_c, ThemeOverlay.tiltNotifier]),
        builder: (_, __) => CustomPaint(
          painter: _CosmicRiftPainter(
            t: _c.value,
            specs: _specs,
            particleRotation: widget.particleRotation,
            subtleMode: widget.subtleMode,
          ),
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
  final bool subtleMode;
  _CosmicRiftPainter({
    required this.t,
    required this.specs,
    required this.particleRotation,
    required this.subtleMode,
  });

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

    // 2. Draw drifting stars and star sparkles with tilt physics!
    final paint = Paint();
    final tilt = ThemeOverlay.tiltNotifier.value;
    final limit = subtleMode ? (specs.length / 2).round().clamp(2, specs.length) : specs.length;
    for (var i = 0; i < limit; i++) {
      final s = specs[i];
      final p = ((t * s.speed) + s.phase) % 1.0;
      // Drift slowly downwards with tilt-Y!
      final y = (size.height * p + tilt.dy * 12 * p) % size.height;
      // Diagonal wind sweep (drifting bottom-rightwards) + tilt-X!
      final windSweep = p * size.width * 0.15;
      final sway = math.sin(p * 2 * math.pi + s.phase * 6) * s.sway;
      final tiltXShift = tilt.dx * 18 * p;
      final x = (s.x * size.width + sway + windSweep + tiltXShift) % size.width;
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
    // If emitters, custom type, subtle mode, or particle count change, regenerate some specs to match
    if (oldWidget.prefs.emitFromTop != widget.prefs.emitFromTop ||
        oldWidget.prefs.emitFromBottom != widget.prefs.emitFromBottom ||
        oldWidget.prefs.emitFromLeft != widget.prefs.emitFromLeft ||
        oldWidget.prefs.emitFromRight != widget.prefs.emitFromRight ||
        oldWidget.prefs.subtleParticleMode != widget.prefs.subtleParticleMode ||
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

    final baseCount = widget.prefs.particleCount;
    final finalCount = widget.prefs.subtleParticleMode 
        ? (baseCount / 2).round().clamp(5, 120) 
        : baseCount;

    for (var i = 0; i < finalCount; i++) {
      final dir = directions[rng.nextInt(directions.length)];
      _specs.add(_CustomSpec(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 3.5 + rng.nextDouble() * 5.0,
        speed: 0.08 + rng.nextDouble() * 0.12,
        sway: 15 + rng.nextDouble() * 30,
        phase: rng.nextDouble(),
        direction: dir,
        depth: 0.4 + rng.nextDouble() * 0.9,
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
      animation: Listenable.merge([_c, ThemeOverlay.tiltNotifier]),
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
  final double depth; // 0.4 (far/slow) to 1.3 (near/fast)

  _CustomSpec({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.sway,
    required this.phase,
    required this.direction,
    required this.depth,
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
    final tilt = ThemeOverlay.tiltNotifier.value;

    // Draw gorgeous flowing background theme wind paths for custom particles
    final windColor = switch (prefs.customParticleType) {
      CustomParticleType.ember => const Color(0xFFFF5722),      // Fire: Red-Orange
      CustomParticleType.frost => const Color(0xFF00E5FF),      // Frost: Light Cyan
      CustomParticleType.toxic => const Color(0xFF00E676),      // Toxic: Poison Green
      CustomParticleType.lightning => const Color(0xFFFFEA00),  // Lightning: Bright Yellow
      CustomParticleType.rainbow => const Color(0xFFFF4081),    // Rainbow: Prismatic Pink
      CustomParticleType.goldShells => const Color(0xFFFFD700), // Gold: Gold
      CustomParticleType.brassCasings => const Color(0xFFFFA726),// Brass: Warm Amber
      CustomParticleType.steelSparks => const Color(0xFFB0BEC5), // Steel: Cool Slate Gray
      CustomParticleType.necromantic => const Color(0xFFEA80FC), // Necro: Pale Lavender
      CustomParticleType.skeletal => const Color(0xFFECEFF1),    // Skeletal: Bone White
      CustomParticleType.tombstone => const Color(0xFF90A4AE),   // Tombstone: Dusty Gray
      _ => Colors.white,
    };
    final windPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = windColor.withValues(alpha: 0.04 + 0.02 * math.sin(t * 2 * math.pi));
    for (int i = 0; i < 3; i++) {
      final pOffset = (t + i / 3.0) % 1.0;
      final path = Path();
      final startY = size.height * (1.1 - pOffset);
      path.moveTo(-50, startY);
      path.cubicTo(
        size.width * 0.3, startY - 100 * math.sin(pOffset * math.pi),
        size.width * 0.7, startY + 100 * math.cos(pOffset * math.pi),
        size.width + 50, startY - 50
      );
      canvas.drawPath(path, windPaint);
    }

    for (final s in specs) {
      final depth = s.depth; // 0.4 (far) to 1.3 (near)
      
      // Calculate continuous progress scaled by depth (distant particles drift slower)
      final p = ((t * s.speed * depth) + s.phase) % 1.0;
      
      // Calculate positions depending on their assigned emitter directions!
      double rawX = s.x * size.width;
      double rawY = s.y * size.height;
      final sway = math.sin(p * 2 * math.pi + s.phase * 8) * s.sway * depth;
      final tiltXShift = tilt.dx * 18 * p * depth;
      final tiltYShift = tilt.dy * 12 * p * depth;

      // Wind-swept physical forces (distant particles are lighter, swept further!)
      final windShift = p * size.width * 0.14 * (1.5 - depth);

      if (s.direction == 'top') {
        rawY = (size.height * p + tiltYShift) % size.height;
        rawX = (s.x * size.width + sway + tiltXShift + windShift) % size.width;
      } else if (s.direction == 'bottom') {
        rawY = (size.height * (1.0 - p) + tiltYShift) % size.height;
        rawX = (s.x * size.width + sway + tiltXShift + windShift) % size.width;
      } else if (s.direction == 'left') {
        rawX = (size.width * p + tiltXShift + windShift) % size.width;
        rawY = (s.y * size.height + sway + tiltYShift) % size.height;
      } else if (s.direction == 'right') {
        rawX = (size.width * (1.0 - p) + tiltXShift - windShift) % size.width;
        rawY = (s.y * size.height + sway + tiltYShift) % size.height;
      }

      double edgeFade = 1.0;
      const double edgeThreshold = 32.0;
      if (rawX < edgeThreshold) {
        edgeFade = rawX / edgeThreshold;
      } else if (rawX > size.width - edgeThreshold) {
        edgeFade = (size.width - rawX) / edgeThreshold;
      }

      // Alpha is dimmer for distant particles, providing gorgeous depth scaling!
      final alpha = _bellAlpha(p) * prefs.particleOpacity * edgeFade * (0.35 + 0.65 * depth);
      if (alpha <= 0.01) continue;

      // Boost up flickering/twinkle globally! Rapid blinking sinusoids
      final twinkle = prefs.advancedFlicker
          ? 0.15 + 0.85 * math.sin(t * 32 * math.pi + s.phase * 50).abs()
          : 0.4 + 0.6 * math.sin(t * 18 * math.pi + s.phase * 22).abs();

      // Complex sprites (emoji skulls and bones) look jittery when flickering at high frequencies.
      // We override this with a slow, breathing pulse (0.88 to 1.12) for organic flow.
      final isComplexSprite = prefs.customParticleType == CustomParticleType.necromantic ||
                              prefs.customParticleType == CustomParticleType.skeletal;
      final double dynamicScaleMultiplier = isComplexSprite
          ? 0.88 + 0.12 * math.sin(t * 3.2 + s.phase * 8)
          : (prefs.advancedFlicker ? twinkle : 1.0);

      // Scaled size according to depth and premium multipliers for hand-tuned excellence!
      final scaledSize = s.size * dynamicScaleMultiplier * depth;

      // Render custom types!
      switch (prefs.customParticleType) {
        case CustomParticleType.none:
          break;

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

        case CustomParticleType.toxic:
          // Bubbling green poison (Toxic Greens and Yellow-Greens)
          final isBright = s.phase < 0.5;
          final color = isBright ? const Color(0xFF00E676) : const Color(0xFF76FF03);
          paint.color = color.withValues(alpha: alpha * twinkle * 0.8);
          canvas.drawCircle(Offset(rawX, rawY), scaledSize * 0.55, paint);
          paint.color = Colors.white.withValues(alpha: alpha * twinkle * 0.45);
          canvas.drawCircle(Offset(rawX - scaledSize * 0.15, rawY - scaledSize * 0.15), scaledSize * 0.12, paint);
          break;

        case CustomParticleType.lightning:
          // Flashing lightning sparks (Electrifying Yellow and White)
          final color = s.phase < 0.4 ? Colors.white : const Color(0xFFFFEA00);
          paint.color = color.withValues(alpha: alpha * twinkle * 0.9);
          final r = scaledSize * 0.85;
          final path = Path()
            ..moveTo(rawX, rawY - r)
            ..lineTo(rawX + r * 0.3, rawY - r * 0.1)
            ..lineTo(rawX - r * 0.3, rawY + r * 0.1)
            ..lineTo(rawX, rawY + r)
            ..lineTo(rawX - r * 0.15, rawY + r * 0.1)
            ..lineTo(rawX + r * 0.15, rawY - r * 0.1)
            ..close();
          canvas.drawPath(path, paint);
          break;

        case CustomParticleType.rainbow:
          // Prismatic color shifting based on time and phase!
          final hue = (t * 360 + s.phase * 360) % 360;
          final color = HSLColor.fromAHSL(1.0, hue, 0.95, 0.6).toColor();
          paint.color = color.withValues(alpha: alpha * twinkle * 0.8);
          canvas.drawCircle(Offset(rawX, rawY), scaledSize * 0.5, paint);
          break;

        case CustomParticleType.goldShells:
          // Shiny golden ammo shells (Pure Gold and Amber highlights)
          paint.color = const Color(0xFFFFD700).withValues(alpha: alpha * 0.85);
          final rw = scaledSize * 0.9;
          final rh = scaledSize * 1.5;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(rawX, rawY), width: rw, height: rh),
              Radius.circular(rw * 0.25),
            ),
            paint,
          );
          paint.color = Colors.white.withValues(alpha: alpha * 0.45);
          canvas.drawRect(Rect.fromLTWH(rawX - rw * 0.25, rawY - rh * 0.4, rw * 0.15, rh * 0.8), paint);
          break;

        case CustomParticleType.brassCasings:
          // Copper-brass cylindrical casing
          paint.color = const Color(0xFFFF9100).withValues(alpha: alpha * 0.8);
          final cw = scaledSize * 0.7;
          final ch = scaledSize * 1.4;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(rawX, rawY), width: cw, height: ch),
              Radius.circular(cw * 0.2),
            ),
            paint,
          );
          break;

        case CustomParticleType.steelSparks:
          // Sharp silver-steel friction sparks
          paint.color = const Color(0xFFCFD8DC).withValues(alpha: alpha * twinkle * 0.9);
          final sr = scaledSize * 0.9;
          final path = Path()
            ..moveTo(rawX, rawY - sr)
            ..lineTo(rawX + sr * 0.2, rawY - sr * 0.2)
            ..lineTo(rawX + sr, rawY)
            ..lineTo(rawX + sr * 0.2, rawY + sr * 0.2)
            ..lineTo(rawX, rawY + sr)
            ..lineTo(rawX - sr * 0.2, rawY + sr * 0.2)
            ..lineTo(rawX - sr, rawY)
            ..lineTo(rawX - sr * 0.2, rawY - sr * 0.2)
            ..close();
          canvas.drawPath(path, paint);
          break;

        case CustomParticleType.necromantic:
          // Creepy glowing purple necrotic skulls (Text-Emoji Skull 💀)
          tp.text = TextSpan(
            text: '💀',
            style: TextStyle(
              fontSize: scaledSize * 1.9,
              color: const Color(0xFFE040FB).withValues(alpha: alpha * twinkle * 0.8),
            ),
          );
          tp.layout();
          tp.paint(canvas, Offset(rawX - tp.width / 2, rawY - tp.height / 2));
          break;

        case CustomParticleType.skeletal:
          // Floating crossbone or bone-white chunks (Text-Emoji Bone 🦴)
          tp.text = TextSpan(
            text: '🦴',
            style: TextStyle(
              fontSize: scaledSize * 1.9,
              color: const Color(0xFFECEFF1).withValues(alpha: alpha * 0.85),
            ),
          );
          tp.layout();
          tp.paint(canvas, Offset(rawX - tp.width / 2, rawY - tp.height / 2));
          break;

        case CustomParticleType.tombstone:
          // Dusty tombstone gray crosses
          paint.color = const Color(0xFF78909C).withValues(alpha: alpha * 0.7);
          final tr = scaledSize * 0.8;
          final path = Path()
            ..moveTo(rawX - tr * 0.25, rawY - tr)
            ..lineTo(rawX + tr * 0.25, rawY - tr)
            ..lineTo(rawX + tr * 0.25, rawY - tr * 0.25)
            ..lineTo(rawX + tr, rawY - tr * 0.25)
            ..lineTo(rawX + tr, rawY + tr * 0.25)
            ..lineTo(rawX + tr * 0.25, rawY + tr * 0.25)
            ..lineTo(rawX + tr * 0.25, rawY + tr)
            ..lineTo(rawX - tr * 0.25, rawY + tr)
            ..lineTo(rawX - tr * 0.25, rawY + tr * 0.25)
            ..lineTo(rawX - tr, rawY + tr * 0.25)
            ..lineTo(rawX - tr, rawY - tr * 0.25)
            ..lineTo(rawX - tr * 0.25, rawY - tr * 0.25)
            ..close();
          canvas.drawPath(path, paint);
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

class _HypnoticBgState extends State<_HypnoticBg> with SingleTickerProviderStateMixin {
  List<ui.Image> _frames = [];
  List<int> _durations = [];
  int _currentFrame = 0;
  Timer? _timer;
  bool _isLoading = true;
  late final AnimationController _localCtrl;

  @override
  void initState() {
    super.initState();
    _localCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
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
    _localCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGif() async {
    if (widget.assetName == 'crt_static' ||
        widget.assetName == 'static_glitch' ||
        widget.assetName == 'matrix_code' ||
        widget.assetName == 'pixel_nebula') {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }
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
      debugPrint("Error loading animated background gif: $e");
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
    Widget bgWidget;

    final isProcedural = widget.assetName == 'crt_static' ||
                         widget.assetName == 'static_glitch' ||
                         widget.assetName == 'matrix_code' ||
                         widget.assetName == 'pixel_nebula';

    if (isProcedural) {
      bgWidget = AnimatedBuilder(
        animation: _localCtrl,
        builder: (context, _) {
          final localT = DateTime.now().millisecondsSinceEpoch / 1000.0;
          final CustomPainter p = switch (widget.assetName) {
            'crt_static' => _CRTStaticPainter(t: localT * widget.speedMultiplier),
            'static_glitch' => _StaticGlitchPainter(t: localT * widget.speedMultiplier),
            'matrix_code' => _MatrixCodePainter(t: localT * widget.speedMultiplier),
            _ => _PixelNebulaPainter(t: localT * widget.speedMultiplier),
          };
          return CustomPaint(
            painter: p,
            size: Size.infinite,
          );
        },
      );
    } else {
      if (_isLoading || _frames.isEmpty) {
        return const SizedBox.shrink();
      }
      bgWidget = RawImage(
        image: _frames[_currentFrame],
        fit: BoxFit.cover,
        opacity: AlwaysStoppedAnimation<double>(widget.opacity),
      );
    }

    // Blend the background layer with a deep central-dimming readability vignette!
    return Stack(
      children: [
        Positioned.fill(child: bgWidget),
        // Central readability vignette dimming mask (dimmer at center and edges)
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.25,
                colors: [
                  Colors.black.withValues(alpha: 0.72), // Dim the center deeply so overlays and text are 100% legible
                  Colors.black.withValues(alpha: 0.38), // Slightly lighter mid-band
                  Colors.black.withValues(alpha: 0.84), // Deep dark outer vignette border
                ],
                stops: const [0.0, 0.50, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CRTStaticPainter extends CustomPainter {
  final double t;
  final math.Random _rng = math.Random();
  _CRTStaticPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Charcoal scanline background
    paint.color = const Color(0xFF0F0F11);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Procedural noise dots
    paint.style = PaintingStyle.fill;
    final numDots = (size.width * size.height / 2200).toInt().clamp(100, 1500);
    for (int i = 0; i < numDots; i++) {
      final x = _rng.nextDouble() * size.width;
      final y = _rng.nextDouble() * size.height;
      final gray = 30 + _rng.nextInt(120);
      final alpha = 0.08 + _rng.nextDouble() * 0.15;
      paint.color = Color.fromARGB((alpha * 255).toInt(), gray, gray, gray);
      canvas.drawRect(Rect.fromLTWH(x, y, 1.8, 1.8), paint);
    }

    // CRT Scanlines
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.2;
    final lineSpacing = 6.0;
    final offset = (t * 22) % lineSpacing;
    for (double y = offset; y < size.height; y += lineSpacing) {
      paint.color = Colors.black.withValues(alpha: 0.28);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Horizontal interference bar
    paint.style = PaintingStyle.fill;
    final barY = (t * 85) % (size.height + 150) - 75;
    final barHeight = 60.0;
    final barGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withValues(alpha: 0.0),
        Colors.white.withValues(alpha: 0.05),
        Colors.white.withValues(alpha: 0.0),
      ],
    );
    paint.shader = barGradient.createShader(Rect.fromLTWH(0, barY, size.width, barHeight));
    canvas.drawRect(Rect.fromLTWH(0, barY, size.width, barHeight), paint);
    paint.shader = null;
  }

  @override
  bool shouldRepaint(_CRTStaticPainter old) => true;
}

class _StaticGlitchPainter extends CustomPainter {
  final double t;
  final math.Random _rng = math.Random();
  _StaticGlitchPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Deep cyber purple-black background
    paint.color = const Color(0xFF07050A);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Random digital glitch bars
    final numGlitchBars = 4 + _rng.nextInt(6);
    for (int i = 0; i < numGlitchBars; i++) {
      final barY = _rng.nextDouble() * size.height;
      final barHeight = 4.0 + _rng.nextDouble() * 16.0;
      final barWidth = size.width * (0.1 + _rng.nextDouble() * 0.8);
      final barX = _rng.nextDouble() * (size.width - barWidth);
      
      final colorRand = _rng.nextInt(3);
      final Color color = switch (colorRand) {
        0 => const Color(0xFF00FFFF),
        1 => const Color(0xFFFF007F),
        _ => const Color(0xFF39FF14),
      };
      
      final alpha = 0.05 + _rng.nextDouble() * 0.12;
      paint.color = color.withValues(alpha: alpha);
      canvas.drawRect(Rect.fromLTWH(barX, barY, barWidth, barHeight), paint);
    }

    // Cyber layout grid
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 0.8;
    final gridSpacing = 40.0;
    
    paint.color = const Color(0xFF00FFFF).withValues(alpha: 0.015);
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Rare strobe flash
    final isStrobe = _rng.nextDouble() < 0.04;
    if (isStrobe) {
      paint.style = PaintingStyle.fill;
      paint.color = const Color(0xFFFF007F).withValues(alpha: 0.03);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_StaticGlitchPainter old) => true;
}

class _MatrixCodePainter extends CustomPainter {
  final double t;
  final math.Random _rng = math.Random(1337);
  _MatrixCodePainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Pitch-black terminal background
    paint.color = const Color(0xFF040605);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final numCols = 18;
    final colWidth = size.width / numCols;
    
    for (int col = 0; col < numCols; col++) {
      final speed = 0.5 + _rng.nextDouble() * 0.8;
      final startY = (t * 180 * speed) % (size.height + 300) - 200;
      
      final length = 6 + _rng.nextInt(12);
      for (int i = 0; i < length; i++) {
        final charY = startY - (i * 24);
        if (charY < -20 || charY > size.height + 20) continue;
        
        final alpha = (1.0 - (i / length)).clamp(0.0, 1.0);
        
        Color color;
        if (i == 0) {
          color = const Color(0xFFE8F5E9).withValues(alpha: alpha);
        } else if (col % 2 == 0) {
          color = const Color(0xFF00FF66).withValues(alpha: alpha * 0.65);
        } else {
          color = const Color(0xFF00E5FF).withValues(alpha: alpha * 0.65);
        }
        
        paint.color = color;
        
        final glyphSize = 8.0 + _rng.nextInt(6);
        final glyphX = col * colWidth + (colWidth - glyphSize) / 2;
        
        final isGlitchOffset = _rng.nextDouble() < 0.08;
        final finalX = isGlitchOffset ? glyphX + (_rng.nextDouble() * 12 - 6) : glyphX;
        
        canvas.drawRect(Rect.fromLTWH(finalX, charY, glyphSize, glyphSize), paint);
        canvas.drawRect(Rect.fromLTWH(finalX - 2, charY + glyphSize/2, glyphSize + 4, 1.5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_MatrixCodePainter old) => true;
}

class _PixelNebulaPainter extends CustomPainter {
  final double t;
  final math.Random _rng = math.Random(101);
  _PixelNebulaPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    paint.color = const Color(0xFF0B0715);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    for (int i = 0; i < 3; i++) {
      final phase = i * (math.pi * 2 / 3);
      final cX = size.width * 0.5 + math.cos(t * 0.25 + phase) * size.width * 0.22;
      final cY = size.height * 0.5 + math.sin(t * 0.22 + phase) * size.height * 0.18;
      final radius = (size.width * 0.45) * (0.8 + 0.15 * math.sin(t * 0.4 + phase));
      
      final Color color = switch (i) {
        0 => const Color(0xFFE91E63),
        1 => const Color(0xFF9C27B0),
        _ => const Color(0xFF00E5FF),
      };
      
      paint.shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.12),
          color.withValues(alpha: 0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cX, cY), radius: radius));
      canvas.drawCircle(Offset(cX, cY), radius, paint);
      paint.shader = null;
    }

    for (int i = 0; i < 30; i++) {
      final double starX = _rng.nextDouble() * size.width;
      final double starY = _rng.nextDouble() * size.height;
      final double starSpeed = 0.5 + _rng.nextDouble() * 1.5;
      final double twinkle = (math.sin(t * starSpeed + i) + 1.0) / 2.0;
      
      final alpha = 0.1 + twinkle * 0.75;
      paint.color = Colors.white.withValues(alpha: alpha);
      
      final sizeScale = (i % 3 == 0) ? 3.0 : 1.8;
      canvas.drawRect(Rect.fromLTWH(starX, starY, sizeScale, sizeScale), paint);
    }
  }

  @override
  bool shouldRepaint(_PixelNebulaPainter old) => true;
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

class _StillWallpaperBackground extends StatelessWidget {
  final String assetName;
  final bool parallaxEnabled;

  const _StillWallpaperBackground({
    required this.assetName,
    required this.parallaxEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final imageWidget = Image.asset(
      'assets/images/wallpapers/still/$assetName',
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
    );

    if (!parallaxEnabled) {
      return imageWidget;
    }

    return ValueListenableBuilder<Offset>(
      valueListenable: ThemeOverlay.tiltNotifier,
      builder: (context, tilt, child) {
        // Subtle, elegant gyroscopic sways (tilt bounds clamped to -6..6)
        final double dx = tilt.dx * 3.8;
        final double dy = tilt.dy * 3.8;

        return Transform.scale(
          scale: 1.06, // Scale up slightly to prevent black border cropping
          alignment: Alignment.center,
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: child,
          ),
        );
      },
      child: imageWidget,
    );
  }
}

class _AnimatedWallpaperBackground extends StatefulWidget {
  final String assetName;

  const _AnimatedWallpaperBackground({
    super.key,
    required this.assetName,
  });

  @override
  State<_AnimatedWallpaperBackground> createState() => _AnimatedWallpaperBackgroundState();
}

class _AnimatedWallpaperBackgroundState extends State<_AnimatedWallpaperBackground> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(_AnimatedWallpaperBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetName != widget.assetName) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    _initialized = false;
    _hasError = false;
    final oldController = _controller;
    if (oldController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await oldController.dispose();
      });
      _controller = null;
    }

    if (widget.assetName.startsWith('procedural_')) {
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
      return;
    }

    final path = 'assets/images/wallpapers/animated/${widget.assetName}';
    final controller = VideoPlayerController.asset(path);
    _controller = controller;

    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0.0);
      await controller.play();
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to initialize animated wallpaper video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.assetName.startsWith('procedural_')) {
      final actualAsset = widget.assetName.replaceAll('procedural_crt', 'crt_static')
                                         .replaceAll('procedural_glitch', 'static_glitch')
                                         .replaceAll('procedural_matrix', 'matrix_code')
                                         .replaceAll('procedural_nebula', 'pixel_nebula');
      return _HypnoticBg(
        assetName: actualAsset,
        speedMultiplier: 1.0,
        opacity: 0.35,
      );
    }

    final controller = _controller;
    if (_hasError || controller == null) {
      // Elegant fallback: render the still counterpart
      final String fallbackStill = widget.assetName.replaceAll('wp_anim_01_galaxy.mp4', 'wp_still_05_galaxy.png')
                                                    .replaceAll('wp_anim_02_warehouse.mp4', 'wp_still_03_warehouse.png')
                                                    .replaceAll('wp_anim_03_blobulord.mp4', 'wp_still_17_blobulord.png');
      return _StillWallpaperBackground(
        assetName: fallbackStill,
        parallaxEnabled: true,
      );
    }

    if (!_initialized) {
      final String fallbackStill = widget.assetName.replaceAll('wp_anim_01_galaxy.mp4', 'wp_still_05_galaxy.png')
                                                    .replaceAll('wp_anim_02_warehouse.mp4', 'wp_still_03_warehouse.png')
                                                    .replaceAll('wp_anim_03_blobulord.mp4', 'wp_still_17_blobulord.png');
      return _StillWallpaperBackground(
        assetName: fallbackStill,
        parallaxEnabled: false,
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}


