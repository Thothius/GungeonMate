import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../services/app_theme.dart';
import 'theme_engines.dart';
import 'particle_engine.dart';
import 'particles/touch_particle.dart';
import 'particles/ambient_glow.dart';
import 'backgrounds/page_frame.dart';
import 'backgrounds/animated_wallpaper.dart';

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
  final List<TouchParticle> _touchParticles = [];
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
          _touchParticles.add(TouchParticle(
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
          // ponytail: auto-bind particles to the active theme. Every visible
          //           theme has a default preset in kThemeParticleDefaults. When
          //           the user hasn't explicitly chosen a preset (still on
          //           gungeonDust), the theme's default is used. Particles are
          //           also auto-enabled for any theme with a non-dust default so
          //           each theme shows its identity out of the box. An explicit
          //           user preset choice is always respected.
          final themeDefault = kThemeParticleDefaults[mode] ??
              ParticlePreset.gungeonDust;
          final userOnDefault = prefs.particlePreset == ParticlePreset.gungeonDust;
          final effectivePreset = userOnDefault ? themeDefault : prefs.particlePreset;
          final themeAutoOn = themeDefault != ParticlePreset.gungeonDust;
          final particlesOn = prefs.particlesEnabled || themeAutoOn;
          final particleBackdropBg = !particlesOn
              ? null
              : ParticleField(
                  preset: effectivePreset,
                  count: prefs.particleCount,
                  sizeScale: prefs.particleSizeScale,
                  opacity: prefs.particleOpacity,
                  glowOverride: prefs.particleGlowEffect,
                  lineLinksOverride: prefs.particleLineLinks ? true : null,
                  colorsOverride: mode == AppThemeMode.unicorn
                      ? AppTheme.unicornPalette.particleColors
                      : null,
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
                        child: AnimatedWallpaperBackground(
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
                      child: AmbientGlow(
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
                      child: IgnorePointer(child: PageFrame())),

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
                        painter: TouchParticlePainter(particles: _touchParticles),
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
