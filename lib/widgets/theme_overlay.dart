import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:video_player/video_player.dart';

import '../services/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../services/haptics.dart';
import 'theme_engines.dart';
import 'particle_engine.dart';

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
      final tx = -event.x.clamp(-10.0, 10.0);
      final ty = event.y.clamp(-10.0, 10.0);
      _smoothedTilt = Offset(
        _smoothedTilt.dx + (tx - _smoothedTilt.dx) * 0.18,
        _smoothedTilt.dy + (ty - _smoothedTilt.dy) * 0.18,
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
      animation: Listenable.merge([
        AppTheme.notifier,
        AppTheme.previewNotifier,
        AppTheme.unicornPaletteNotifier,
        AppTheme.remixNotifier,
      ]),
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
          // ponytail: cap effective glow at 0.6 so max doesn't wash out UI.
          //           Now behind content, so even at cap it glows behind panels.
          final userGlowColor = VisualPrefs.glowColors[prefs.glowColorIndex];
          final effectiveGlow = prefs.glowIntensity * 0.6;
          final gP = showGlow
              ? _scaleAlpha(
                  Color.lerp(f.glowPrimary, userGlowColor, 0.5) ?? f.glowPrimary,
                  effectiveGlow,
                )
              : const Color(0x00000000);
          final gS = showGlow
              ? _scaleAlpha(
                  Color.lerp(f.glowSecondary, userGlowColor, 0.5) ?? f.glowSecondary,
                  effectiveGlow,
                )
              : const Color(0x00000000);
          final particlesOn = prefs.particlesEnabled;
          final particleBackdropBg = !particlesOn
              ? null
              : ParticleField(
                  preset: prefs.particlePreset,
                  count: prefs.particleCount,
                  sizeScale: prefs.particleSizeScale,
                  opacity: prefs.particleOpacity,
                  glowOverride: prefs.particleGlowEffect,
                  lineLinksOverride: prefs.particleLineLinks ? true : null,
                  bounce: prefs.particleBounce,
                );
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

                // 0.6. Home Screen Contrast Backing (prevents galaxy video detail bleeding through UI panels)
                if (isHomeScreen)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.62),
                      ),
                    ),
                  ),

                // 1b. Particles / Theme Backdrops (Background Layer)
                if (particleBackdropBg != null)
                  Positioned.fill(child: IgnorePointer(child: particleBackdropBg)),

                // 1c. Ambient Glow — behind content so it glows behind panels,
                //     not covering layered content on top.
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

                // 2. Middle Layer: Core App Content (wrapped in visual physics controllers)
                content,

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

                // 3.6. Enhanced Readability Scrim — when the Galaxy bg is
                // active on the Home screen, lay down a semi-opaque dark veil
                // so foreground cards, text, and panels stay crisp.
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
        // ignore: deprecated_member_use
        final pColor = widget.primary.withOpacity((widget.primary.opacity * 1.55).clamp(0.0, 0.95));
        // ignore: deprecated_member_use
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
    final paint = Paint()..style = PaintingStyle.fill;

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
      paint.shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [colors[i], colors[i].withValues(alpha: 0.0)],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: centers[i], radius: radii[i]));
      canvas.drawCircle(centers[i], radii[i], paint);
    }
    paint.shader = null;
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
      
      final y = (size.height * (1.0 - progress) + tilt.dy * 15 * progress);
      final sway = math.sin(progress * 2 * math.pi + phase * 8) * 22;
      final tiltXShift = tilt.dx * 18 * progress;
      final x = ((i / 15.0) * size.width + sway + tiltXShift);
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

// ignore: unused_element
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

        return Stack(
          children: [
            Positioned(
              bottom: 40.0,
              right: -45.0 + slideOffset,
              width: 140.0,
              height: 140.0,
              child: Transform.rotate(
                angle: wiggleAngle,
                alignment: Alignment.bottomCenter,
                child: child,
              ),
            ),
          ],
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
  int _videoInitToken = 0;

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
    final myToken = ++_videoInitToken;
    final oldController = _controller;
    if (oldController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await oldController.dispose();
      });
      _controller = null;
    }

    final path = 'assets/images/wallpapers/animated/${widget.assetName}';
    final controller = VideoPlayerController.asset(path);
    _controller = controller;

    try {
      await controller.initialize();
      if (myToken != _videoInitToken) {
        // A newer _initializeVideo call superseded us — dispose orphan.
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0.0);
      await controller.play();
      if (myToken != _videoInitToken) {
        await controller.dispose();
        return;
      }
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to initialize animated wallpaper video: $e');
      if (myToken == _videoInitToken && mounted) {
        setState(() {
          _hasError = true;
        });
      } else {
        await controller.dispose();
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
    final controller = _controller;
    if (_hasError || controller == null) {
      return const SizedBox.shrink();
    }

    if (!_initialized) {
      return const SizedBox.shrink();
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


