import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../providers/run_provider.dart';
import '../services/app_theme.dart';
import 'theme_engines.dart';
import 'particle_engine.dart';
import 'particles/touch_particle.dart';
import 'particles/ambient_glow.dart';
import 'backgrounds/page_frame.dart';
import 'backgrounds/ambient_shader.dart';

/// Shared RouteObserver — MainMenuScreen subscribes (RouteAware) to
/// learn when a route is pushed above it or popped back to it.
final RouteObserver<ModalRoute<dynamic>> menuRouteObserver =
    RouteObserver<ModalRoute<dynamic>>();

class ThemeOverlay extends StatefulWidget {
  final Widget child;
  const ThemeOverlay({super.key, required this.child});

  /// Whether the main menu is the topmost route. Theme layers are
  /// suppressed only while the locked home menu is actually visible —
  /// screens pushed above it (Studio, Ammonomicon, character select…)
  /// keep their themed backdrop. Set by MainMenuScreen's RouteAware
  /// callbacks; defaults true (covers the pre-menu loading state).
  static final ValueNotifier<bool> menuOnTop = ValueNotifier(true);

  /// Static global notifier for the current physical device tilt (x, y).
  /// x is tilt left/right (-10 to 10), y is tilt up/down (-10 to 10).
  static final ValueNotifier<Offset> tiltNotifier = ValueNotifier(Offset.zero);

  /// Static global notifier for the current screen index (0=Home, 1=Browse, 2=Settings).
  /// Used to force the Galaxy animated background on the Home screen only.
  static final ValueNotifier<int> currentScreenIndex = ValueNotifier(0);

  /// The animated wallpaper asset that always plays on the Home screen.
  /// This is the orbiting purple vortex from gungeonmate-animation-02.mp4.
  static const String kHomeGalaxyAsset = 'gungeonmate-animation-02.mp4';

  @override
  State<ThemeOverlay> createState() => _ThemeOverlayState();
}

class _ThemeOverlayState extends State<ThemeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _touchTicker;
  final List<TouchParticle> _touchParticles = [];
  final math.Random _rng = math.Random();
  StreamSubscription? _sensorSub;
  Offset _smoothedTilt = Offset.zero;

  /// Cached reduced-motion preference (updated each build, read in
  /// `_spawnTouchSparkles` which runs outside the build path).
  bool _reduceMotion = false;

  // Scale a color's alpha by [scale] (0.0–1.0).
  static Color _scaleAlpha(Color c, double scale) =>
      c.withValues(alpha: (c.a * scale).clamp(0.0, 1.0));

  @override
  void initState() {
    super.initState();
    _touchTicker =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(_onFrame)
          ..repeat();

    // Standard low-pass filter to smooth out gyroscope sways
    _sensorSub = accelerometerEventStream().listen(
      (event) {
        final tx = -event.x.clamp(-10.0, 10.0);
        final ty = event.y.clamp(-10.0, 10.0);
        _smoothedTilt = Offset(
          _smoothedTilt.dx + (tx - _smoothedTilt.dx) * 0.18,
          _smoothedTilt.dy + (ty - _smoothedTilt.dy) * 0.18,
        );
        ThemeOverlay.tiltNotifier.value = _smoothedTilt;
      },
      onError: (_) {
        // Graceful fallback for non-gyro devices (e.g. desktop/emulators)
      },
    );
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
        p.vel = Offset(p.vel.dx * 0.85, p.vel.dy * 0.85); // deceleration
        p.life -= 0.08; // decays in ~12 frames (~0.2 seconds)
        if (p.life <= 0) {
          _touchParticles.removeAt(i);
        }
      }
    });
  }

  void _spawnTouchSparkles(Offset globalPosition, VisualPrefs prefs) {
    if (_reduceMotion || !prefs.particlesEnabled) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      final localPos = box.globalToLocal(globalPosition);
      final activeFlair = AppTheme.flair;
      // Alternate between primary and secondary for a richer sparkle
      // that uses both theme accent colors.
      final colors = [activeFlair.primary, activeFlair.secondary];
      setState(() {
        for (var i = 0; i < 5; i++) {
          final angle = _rng.nextDouble() * 2 * math.pi;
          final speed = 0.5 + _rng.nextDouble() * 1.5;
          _touchParticles.add(
            TouchParticle(
              pos: localPos,
              vel: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
              color: colors[i % 2],
              size: 3.0 + _rng.nextDouble() * 3.0,
            ),
          );
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
        ThemeOverlay.menuOnTop,
      ]),
      builder: (_, _) {
        final mode = AppTheme.displayedMode;
        return ValueListenableBuilder<VisualPrefs>(
          valueListenable: VisualPrefs.notifier,
          builder: (_, prefs, _) {
            // Reduced-motion: respect the platform's "remove animations"
            // accessibility setting. All animated decorative layers
            // (particles, shader, glow, sparkles, wobble, video wallpaper)
            // are skipped; static layers (base color, vignette, scrim,
            // page frame) remain so the theme's color identity is preserved.
            final reduceMotion = MediaQuery.disableAnimationsOf(context);
            _reduceMotion = reduceMotion;
            // Determine isHomeScreen directly from RunProvider so the
            // galaxy background disappears the instant a run starts —
            // no 1-frame lag from a child-set ValueNotifier.
            final runProvider = context.watch<RunProvider>();
            final isHomeScreen =
                runProvider.isLoading ||
                runProvider.runState.selectedCharacter == null;
            // The theme lock applies only while the main menu is the
            // topmost route — pushed screens keep themed layers.
            final menuVisible = isHomeScreen && ThemeOverlay.menuOnTop.value;
            // Keep the static notifier in sync for the touch-sparkle
            // guard below (which runs outside the build path).
            final desiredIndex = isHomeScreen ? 0 : -1;
            if (ThemeOverlay.currentScreenIndex.value != desiredIndex) {
              ThemeOverlay.currentScreenIndex.value = desiredIndex;
            }
            final f = AppTheme.displayedFlair;
            // Auto-glow: themes with a non-transparent glowPrimary get a
            // subtle ambient glow even if the user hasn't manually enabled
            // it. This ensures every themed mode "feels" alive out of the
            // box. The user's explicit glowIntensity always overrides/
            // enhances the auto-glow.
            final themeHasGlow = f.glowPrimary.a > 0.01;
            final autoGlowIntensity = themeHasGlow ? 0.15 : 0.0;
            final effectiveUserGlow =
                prefs.glowIntensity > 0.001
                    ? prefs.glowIntensity
                    : autoGlowIntensity;
            final showGlow = !reduceMotion && effectiveUserGlow > 0.001;
            final userGlowColor = prefs.glowColor;
            // 3x boost: user requested glow be more significant at 100%.
            // Cap at 1.8 to prevent total washout while making max clearly visible.
            final effectiveGlow = (effectiveUserGlow * 1.8).clamp(0.0, 1.8);
            final gP =
                showGlow
                    ? _scaleAlpha(
                      Color.lerp(f.glowPrimary, userGlowColor, 0.5) ??
                          f.glowPrimary,
                      effectiveGlow,
                    )
                    : const Color(0x00000000);
            final gS =
                showGlow
                    ? _scaleAlpha(
                      Color.lerp(f.glowSecondary, userGlowColor, 0.5) ??
                          f.glowSecondary,
                      effectiveGlow,
                    )
                    : const Color(0x00000000);
            final particleBackdropBg = buildBackdropParticleField(
              mode,
              prefs,
              menuVisible: menuVisible,
              reduceMotion: reduceMotion,
            );
            Widget content = widget.child;

            // Apply visual customizer wrappers based on active Theme Mode!
            // Locked on home — the menu must look identical on every theme.
            if (!reduceMotion &&
                !menuVisible &&
                mode == AppThemeMode.bulletHell) {
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
                  // The home menu is theme-locked — its own backdrop
                  // (MainMenuBackdrop) owns the whole look, so we use
                  // its fixed base color and skip all theme layers below.
                  Positioned.fill(
                    child: Container(
                      color: menuVisible ? const Color(0xFF0A0710) : f.scaffold,
                    ),
                  ),

                  // Home screen vortex animation removed — default to
                  // Minimalist. ThemeOverlay provides only the base color
                  // and themed layers (particles, glow, shader).

                  // 0.5. Ambient Fragment Shader (Q3) — GPU-composited digital
                  // rain or dark neon fog. Sits behind particles but above the
                  // base background + video wallpaper. Opt-in via VisualPrefs.
                  if (!reduceMotion && !menuVisible && prefs.shaderEnabled)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AmbientShaderLayer(
                          shader:
                              prefs.shaderPreset == ShaderPreset.darkNeonFog
                                  ? AmbientShader.darkNeonFog
                                  : AmbientShader.digitalRain,
                        ),
                      ),
                    ),

                  // 1b. Particles / Theme Backdrops (Background Layer)
                  if (!menuVisible && particleBackdropBg != null)
                    Positioned.fill(
                      child: IgnorePointer(child: particleBackdropBg),
                    ),

                  // 1c. Ambient Glow — behind content so it glows behind panels,
                  //     not covering layered content on top.
                  if (showGlow && !menuVisible)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AmbientGlow(
                          key: ValueKey('ambient_glow_${mode.index}'),
                          primary: gP,
                          secondary: gS,
                          style: prefs.glowStyleOverride ?? f.glowStyle,
                          tertiary: f.headlineStat.withValues(alpha: 0.3),
                        ),
                      ),
                    ),

                  // 2. Middle Layer: Core App Content (wrapped in visual physics controllers)
                  content,

                  // 3.5. Chamber Vignette Shadow Overlay (Depth effect with shadows!)
                  if (!menuVisible)
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

                  if (!menuVisible && f.pageFrame)
                    const Positioned.fill(
                      child: IgnorePointer(child: PageFrame()),
                    ),

                  // 4. Special Top-Edge Drip Overlay (Curseblaster / Oubliette themes)
                  if (!menuVisible && mode == AppThemeMode.lordJammed)
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 60,
                      child: IgnorePointer(
                        child: EdgeDripWidget(
                          color: Color(
                            0x66990000,
                          ), // Translucent Curse crimson drip
                          dripCount: 5,
                          maxDripHeight: 25.0,
                          viscosity: 1.2,
                        ),
                      ),
                    ),

                  if (!reduceMotion &&
                      !isHomeScreen &&
                      prefs.particlesEnabled &&
                      _touchParticles.isNotEmpty)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: TouchParticlePainter(
                              particles: _touchParticles,
                            ),
                          ),
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
  }
}

/// Shared backdrop particle resolution — the exact preset/colors/config the
/// app-wide [ThemeOverlay] uses, so the studio's own preview and the LIVE
/// LOOK pane show what the app actually renders. Returns null when particles
/// are off so callers can skip a layer entirely.
Widget? buildBackdropParticleField(
  AppThemeMode mode,
  VisualPrefs prefs, {
  bool menuVisible = false,
  bool reduceMotion = false,
  double opacityScale = 1.0,
}) {
  final f = AppTheme.flairFor(mode);
  // auto-bind particles to the active theme. Every visible theme has a
  // default preset in kThemeParticleDefaults; an explicit user preset
  // choice always wins.
  final themeDefault =
      kThemeParticleDefaults[mode] ?? ParticlePreset.gungeonDust;
  final effectivePreset =
      prefs.particlePreset == ParticlePreset.gungeonDust
          ? themeDefault
          : prefs.particlePreset;
  final themeAutoOn = themeDefault != ParticlePreset.gungeonDust;
  final particlesOn = !reduceMotion && (prefs.particlesEnabled || themeAutoOn);
  if (!particlesOn || menuVisible) return null;
  // color schema priority — explicit user schema > unicorn palette >
  // preset default. themeMatch uses the active flair's colors.
  List<Color>? colorOverride;
  if (prefs.particleColorSchema != ParticleColorSchema.presetDefault) {
    if (prefs.particleColorSchema == ParticleColorSchema.themeMatch) {
      colorOverride = [f.primary, f.secondary, f.glowPrimary, f.headlineStat];
    } else {
      colorOverride = prefs.particleColorSchema.colors;
    }
  } else if (mode == AppThemeMode.unicorn) {
    colorOverride = AppTheme.unicornPalette.particleColors;
  }
  // Typed particle system — user-facing type + per-theme flavored schema +
  // chaos/tilt physics flags.
  final schemaColors = particleSchemaColors(mode, prefs.particleSchemaIndex);
  final typedCfg = typedParticleConfig(
    ParticleType.values[prefs.particleTypeIndex],
    schemaColors,
    chaos: prefs.particleChaos,
  );
  return ParticleField(
    preset: effectivePreset,
    config: typedCfg,
    tiltEnabled: prefs.particleTouch,
    count: prefs.particleCount,
    sizeScale: prefs.particleSizeScale,
    opacity: (prefs.particleOpacity * opacityScale).clamp(0.0, 1.0),
    glowOverride: prefs.particleGlowEffect,
    lineLinksOverride: prefs.particleLineLinks ? true : null,
    colorsOverride: colorOverride,
    bounce: prefs.particleBounce,
    speedMultiplier: prefs.particleSpeed.multiplier,
  );
}
