import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../providers/run_provider.dart';
import '../services/app_theme.dart';
import 'theme_engines.dart';
import 'particle_engine.dart';
import 'particles/touch_particle.dart';
import 'particles/ambient_glow.dart';
import 'particles/ambient_field.dart';
import 'particles/liquid_tank.dart';
import 'backgrounds/page_frame.dart';
import 'backgrounds/ambient_shader.dart';
import 'backgrounds/custom_wallpaper.dart';
import 'skeuo/skeuo_backdrop.dart' show SkeuoGrainPainter;

/// Shared RouteObserver — MainMenuScreen subscribes (RouteAware) to
/// learn when a route is pushed above it or popped back to it.
final RouteObserver<ModalRoute<dynamic>> menuRouteObserver =
    RouteObserver<ModalRoute<dynamic>>();

class ThemeOverlay extends StatefulWidget {
  final Widget child;
  const ThemeOverlay({super.key, required this.child});

  /// Whether the main menu is the topmost route. Theme layers are
  /// suppressed only while the menu is actually visible —
  /// screens pushed above it (Studio, Ammonomicon, character select…)
  /// keep their themed backdrop. Set by MainMenuScreen's RouteAware
  /// callbacks; defaults true (covers the pre-menu loading state).
  static final ValueNotifier<bool> menuOnTop = ValueNotifier(true);

  /// Static global notifier for the current physical device tilt (x, y).
  /// x is tilt left/right (-10 to 10), y is tilt up/down (-10 to 10).
  static final ValueNotifier<Offset> tiltNotifier = ValueNotifier(Offset.zero);

  /// Tracks whether the home (no-run) state is showing: 0 = home/menu,
  /// -1 = inside a run. Used to suppress touch sparkles over the menu —
  /// the menu has its own backdrop and shouldn't get overlay particles.
  static final ValueNotifier<int> currentScreenIndex = ValueNotifier(0);

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
        // NaN.clamp() returns NaN — one bad sensor event would poison
        // the smoothed tilt and make every tilt-driven particle/shell
        // fail its boundary checks and vanish.
        if (!event.x.isFinite || !event.y.isFinite) return;
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
        p.life -= p.decay; // rings decay slower — pulse, not pop
        if (p.life <= 0) {
          _touchParticles.removeAt(i);
        }
      }
    });
  }

  void _spawnTouchSparkles(Offset globalPosition, VisualPrefs prefs) {
    if (_reduceMotion ||
        !prefs.particlesEnabled ||
        !prefs.tapSparkles ||
        AppTheme.isSkeuo) {
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      final localPos = box.globalToLocal(globalPosition);
      final activeFlair = AppTheme.flair;
      // Alternate between primary and secondary for a richer sparkle
      // that uses both theme accent colors.
      final colors = [activeFlair.primary, activeFlair.secondary];
      setState(() {
        // Expanding sonar ring — the premium punctuation under the
        // sparkle dots. Slower decay so it reads as a pulse, not a pop.
        if (prefs.tapRipple) {
          _touchParticles.add(
            TouchParticle(
              pos: localPos,
              vel: Offset.zero,
              color: colors.first,
              size: 0,
              life: 1.0,
              ring: true,
              maxRadius: 44.0 + _rng.nextDouble() * 18.0,
              decay: 0.045,
            ),
          );
        }
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
            // menu state flips the instant a run starts —
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
            // Neo-Skeuo suppresses every ambiance layer to clean paper —
            // particles, glow, shader, grain prefs all stay untouched on
            // disk and come back the moment the skin exits. The skin's
            // only texture is its own ink speckle + pencil vignette below.
            final skeuo = mode == AppThemeMode.neoSkeuo;
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
            final showGlow =
                !skeuo && !reduceMotion && effectiveUserGlow > 0.001;
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
            // Liquid tank pick — resolved once per build like the other
            // layer gates; LiquidKind.off renders nothing.
            final liquidKind =
                prefs.liquidKindIndex >= 0 &&
                        prefs.liquidKindIndex < LiquidKind.values.length
                    ? LiquidKind.values[prefs.liquidKindIndex]
                    : LiquidKind.off;
            // Procedural atmosphere pick — painter scenes tinted by the
            // flair palette; off renders nothing.
            final ambientKind =
                prefs.ambientKindIndex >= 0 &&
                        prefs.ambientKindIndex < AmbientKind.values.length
                    ? AmbientKind.values[prefs.ambientKindIndex]
                    : AmbientKind.off;
            final particleBackdropBg =
                skeuo
                    ? null
                    : buildBackdropParticleField(
                      mode,
                      prefs,
                      menuVisible: menuVisible,
                      reduceMotion: reduceMotion,
                    );
            // Custom theme wallpaper — replaces the flat scaffold fill
            // with a bundled image + scrim. Sits above the base color,
            // below shader/particles/glow so all effects stay on top.
            // bgMode gates it: solid/gradient/none suppress the image.
            final customBgMode =
                (!menuVisible && !skeuo && mode == AppThemeMode.custom)
                    ? (AppTheme.cachedCustomTheme?.bgMode ??
                        CustomThemeData.bgWallpaper)
                    : CustomThemeData.bgWallpaper;
            final customWallpaper =
                customBgMode == CustomThemeData.bgWallpaper
                    ? AppTheme.cachedCustomTheme?.wallpaper
                    : null;
            Widget content = widget.child;

            // Apply visual customizer wrappers based on active Theme Mode!
            // Skipped on the menu — MainMenuBackdrop owns that look.
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
                  // On the menu, MainMenuBackdrop's opaque gradient owns
                  // the whole look and theme layers below are suppressed —
                  // the scaffold color here is just a safety fill.
                  Positioned.fill(
                    child: Container(
                      color:
                          customBgMode == CustomThemeData.bgNone
                              ? Colors.black
                              : f.scaffold,
                    ),
                  ),

                  // 0.4. Custom-theme wallpaper — image + scrim over the
                  // base color. Particles/glow/shader layers stay above.
                  if (customWallpaper != null)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomWallpaper(
                          assetFileName: customWallpaper,
                          scrimColor: f.scaffold,
                        ),
                      ),
                    ),

                  // 0.45. Custom-theme gradient backdrop — palette sweep
                  // over the canvas for the GRADIENT bg mode.
                  if (!menuVisible &&
                      !skeuo &&
                      customBgMode == CustomThemeData.bgGradient)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                f.scaffold,
                                f.card,
                                f.primary.withValues(alpha: 0.45),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 0.47. Liquid tank — slow rising bubbly fill
                  // (blood/venom/umbra) or tilt-sliding brass shells.
                  // Studio AMBIENCE pick; reduced-motion gets a frozen
                  // composed frame inside the widget itself.
                  if (!menuVisible && !skeuo && liquidKind != LiquidKind.off)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: LiquidTankField(
                          kind: liquidKind,
                          tilt: ThemeOverlay.tiltNotifier,
                        ),
                      ),
                    ),

                  // 0.48. Ambient atmosphere — god-rays / ash / runes /
                  // scanlines / abyss painter scenes. Sits above the
                  // liquid tank, below shaders + particles so textures
                  // never cover the particle identity.
                  if (!menuVisible && !skeuo && ambientKind != AmbientKind.off)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AmbientField(
                          kind: ambientKind,
                          primary: f.primary,
                          secondary: f.secondary,
                          tertiary: f.headlineStat,
                        ),
                      ),
                    ),

                  // 0.5. Ambient Fragment Shader (Q3) — GPU-composited digital
                  // rain or dark neon fog. Sits behind particles but above the
                  // base background + video wallpaper. Opt-in via VisualPrefs.
                  if (!reduceMotion &&
                      !menuVisible &&
                      !skeuo &&
                      prefs.shaderEnabled)
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

                  // 3.5. Chamber Vignette — user-tweakable depth shadow
                  // (prefs.vignetteIntensity scales edge darkness).
                  // Neo-Skeuo gets a fixed pencil vignette instead: soft
                  // ink shading at the edges, no user-pref scaling.
                  if (!menuVisible && (skeuo || prefs.vignetteIntensity > 0.01))
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: skeuo ? 1.3 : 1.25,
                              colors:
                                  skeuo
                                      ? const [
                                        Colors.transparent,
                                        Color(0x0A1F1B16),
                                        Color(0x241F1B16),
                                      ]
                                      : [
                                        Colors.transparent,
                                        Colors.black.withValues(
                                          alpha: 0.05 * prefs.vignetteIntensity,
                                        ),
                                        Colors.black.withValues(
                                          alpha: 0.25 * prefs.vignetteIntensity,
                                        ),
                                        Colors.black.withValues(
                                          alpha: 0.48 * prefs.vignetteIntensity,
                                        ),
                                      ],
                              stops:
                                  skeuo
                                      ? const [0.0, 0.62, 1.0]
                                      : const [0.0, 0.45, 0.82, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 3.6. Film grain — static speckle at prefs.grainIntensity
                  // opacity; RepaintBoundary so it paints once per resize.
                  // Neo-Skeuo always gets its ink speckle (paper tooth).
                  if (!menuVisible && (skeuo || prefs.grainIntensity > 0.005))
                    Positioned.fill(
                      child: IgnorePointer(
                        child: RepaintBoundary(
                          child:
                              skeuo
                                  ? const CustomPaint(
                                    painter: SkeuoGrainPainter(),
                                  )
                                  : reduceMotion
                                  ? CustomPaint(
                                    painter: GrainPainter(
                                      opacity: prefs.grainIntensity * 0.35,
                                    ),
                                  )
                                  : _AnimatedGrainField(
                                    opacity: prefs.grainIntensity * 0.35,
                                  ),
                        ),
                      ),
                    ),

                  if (!menuVisible && !skeuo && f.pageFrame)
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

                  // 3.7. Cinematic letterbox — soft black bars framing
                  // top + bottom edges. Static dressing; sits above all
                  // backdrop dressing but below tap sparkles.
                  if (!menuVisible && !skeuo && prefs.cinematicBars)
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(painter: _CinemaBarsPainter()),
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

                  // 5. Foreground dust — the same particle system at very
                  //    low opacity ABOVE content. Dense screens (active
                  //    run = wall-to-wall opaque panels) hide the
                  //    backdrop field entirely; this keeps the user's
                  //    particle identity visible without covering UI.
                  if (!menuVisible && !skeuo)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: 0.18,
                          child:
                              buildBackdropParticleField(
                                mode,
                                prefs,
                                reduceMotion: reduceMotion,
                                dust: true,
                              ) ??
                              const SizedBox.shrink(),
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
  bool dust = false,
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
  // Explicit user OFF always wins — themeAutoOn only applies when the
  // user hasn't deliberately killed the particle field (curation and
  // preset picks reset particlesUserOff, so themed looks still auto-on).
  final particlesOn =
      !reduceMotion &&
      (prefs.particlesEnabled || (themeAutoOn && !prefs.particlesUserOff));
  if (!particlesOn || menuVisible) return null;
  // Sprite mode — custom picked sprite (any bundled gun/item asset)
  // wins over the curated item-icon list, same gate + knobs.
  if (prefs.particleSpritePath.isNotEmpty) {
    return ItemIconField(
      iconPath: prefs.particleSpritePath,
      count: (dust ? prefs.particleCount ~/ 2 : prefs.particleCount).clamp(
        6,
        18,
      ),
      sizeScale: prefs.particleSizeScale,
      opacity: (prefs.particleOpacity * opacityScale).clamp(0.0, 1.0),
    );
  }
  // Item-icon mode - 12 Gungeon item sprites float instead of shapes.
  // Same gate (particlesOn), same count/size/opacity knobs.
  if (prefs.particleItemIcon >= 0) {
    final iconIdx = prefs.particleItemIcon.clamp(
      0,
      kItemIconParticles.length - 1,
    );
    return ItemIconField(
      iconPath: kItemIconParticles[iconIdx].$2,
      count: (dust ? prefs.particleCount ~/ 2 : prefs.particleCount).clamp(
        6,
        18,
      ),
      sizeScale: prefs.particleSizeScale,
      opacity: (prefs.particleOpacity * opacityScale).clamp(0.0, 1.0),
    );
  }
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
    // Clamp — a persisted index from an older enum size must not throw.
    ParticleType.values[prefs.particleTypeIndex.clamp(
      0,
      ParticleType.values.length - 1,
    )],
    schemaColors,
    chaos: prefs.particleChaos,
  );
  return ParticleField(
    preset: effectivePreset,
    config: typedCfg,
    tiltEnabled: prefs.particleTouch,
    // Foreground dust runs half density and never links — the O(n²)
    // pair check is the priciest part of a frame and invisible at
    // 18% opacity anyway.
    count:
        dust ? (prefs.particleCount ~/ 2).clamp(1, 200) : prefs.particleCount,
    sizeScale: prefs.particleSizeScale,
    opacity: (prefs.particleOpacity * opacityScale).clamp(0.0, 1.0),
    // none = AUTO (let the typed config's own glow show). Passing the
    // enum through always forced no-glow on every type — the per-type
    // glows (pulse/cursed/neon) never rendered.
    glowOverride:
        prefs.particleGlowEffect == GlowEffect.none
            ? null
            : prefs.particleGlowEffect,
    lineLinksOverride: dust ? false : (prefs.particleLineLinks ? true : null),
    colorsOverride: colorOverride,
    bounce: prefs.particleBounce,
    speedMultiplier: prefs.particleSpeed.multiplier,
  );
}

/// Static film-grain speckle — deterministic seeded dots painted once
/// (inside a RepaintBoundary). Cheap: ~600 dots, no animation.
class GrainPainter extends CustomPainter {
  final double opacity;
  const GrainPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0 || size.width <= 0 || size.height <= 0) return;
    // Deterministic pseudo-random from a fixed seed — stable across
    // repaints so the grain doesn't shimmer.
    final rnd = math.Random(77);
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: opacity)
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round;
    final pts = <Offset>[
      for (var i = 0; i < 600; i++)
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
    ];
    canvas.drawPoints(PointMode.points, pts, paint);
    // Dark counter-specks give the grain real "film" texture.
    paint.color = Colors.black.withValues(alpha: opacity * 0.9);
    final dark = <Offset>[
      for (var i = 0; i < 600; i++)
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
    ];
    canvas.drawPoints(PointMode.points, dark, paint);
  }

  @override
  bool shouldRepaint(GrainPainter old) => old.opacity != opacity;
}

/// Cinematic letterbox — soft black gradients framing the top and
/// bottom ~7% of the screen. Pure depth dressing, no animation.
class _CinemaBarsPainter extends CustomPainter {
  const _CinemaBarsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final barH = size.height * 0.07;
    final top =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.92),
              Colors.black.withValues(alpha: 0.55),
              const Color(0x00000000),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, barH));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, barH), top);
    final bottom =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.92),
              Colors.black.withValues(alpha: 0.55),
              const Color(0x00000000),
            ],
          ).createShader(
            Rect.fromLTWH(0, size.height - barH, size.width, barH),
          );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - barH, size.width, barH),
      bottom,
    );
  }

  @override
  bool shouldRepaint(_CinemaBarsPainter old) => false;
}

/// Animated film grain — same 1200-speck field as [GrainPainter] but the
/// speckle positions jitter ~10×/sec via a frame-bucketed reseed, giving
/// real per-frame grain shimmer instead of a printed-on texture. Only
/// used when animations are enabled; reduced-motion falls back to the
/// static painter.
class _AnimatedGrainField extends StatefulWidget {
  final double opacity;
  const _AnimatedGrainField({required this.opacity});

  @override
  State<_AnimatedGrainField> createState() => _AnimatedGrainFieldState();
}

class _AnimatedGrainFieldState extends State<_AnimatedGrainField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
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
      builder:
          (_, _) => CustomPaint(
            painter: _AnimatedGrainPainter(
              opacity: widget.opacity,
              frame: (_c.value * 10).floor(),
            ),
          ),
    );
  }
}

class _AnimatedGrainPainter extends CustomPainter {
  final double opacity;
  final int frame;
  const _AnimatedGrainPainter({required this.opacity, required this.frame});

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0 || size.isEmpty) return;
    // Reseed per frame-bucket — deterministic within a frame, different
    // speckle field every ~100ms.
    final rnd = math.Random(77 + frame * 7919);
    final light =
        Paint()
          ..color = Colors.white.withValues(alpha: opacity)
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round;
    final dark =
        Paint()
          ..color = Colors.black.withValues(alpha: opacity * 0.9)
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round;
    final pts = <Offset>[
      for (var i = 0; i < 600; i++)
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
    ];
    canvas.drawPoints(PointMode.points, pts, light);
    final darkPts = <Offset>[
      for (var i = 0; i < 600; i++)
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
    ];
    canvas.drawPoints(PointMode.points, darkPts, dark);
  }

  @override
  bool shouldRepaint(_AnimatedGrainPainter old) => old.frame != frame;
}
