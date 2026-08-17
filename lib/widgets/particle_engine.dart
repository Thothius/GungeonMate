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

// =============================================================================
// Particle Color Schemas — 16 named color palettes that can override any
// preset's default colors. Works with ALL themes and palettes.
// =============================================================================

/// Particle speed multiplier — 5 discrete steps from very slow to very fast.
enum ParticleSpeed {
  verySlow,   // 0.3x
  slow,       // 0.6x
  normal,     // 1.0x (default)
  fast,       // 1.6x
  veryFast,   // 2.5x
}

extension ParticleSpeedX on ParticleSpeed {
  String get label => switch (this) {
        ParticleSpeed.verySlow => 'Very Slow',
        ParticleSpeed.slow => 'Slow',
        ParticleSpeed.normal => 'Normal',
        ParticleSpeed.fast => 'Fast',
        ParticleSpeed.veryFast => 'Very Fast',
      };

  double get multiplier => switch (this) {
        ParticleSpeed.verySlow => 0.3,
        ParticleSpeed.slow => 0.6,
        ParticleSpeed.normal => 1.0,
        ParticleSpeed.fast => 1.6,
        ParticleSpeed.veryFast => 2.5,
      };
}

enum ParticleColorSchema {
  /// Use the preset's built-in colors (default).
  presetDefault,

  /// Match the active theme's primary/secondary colors.
  themeMatch,

  /// Warm fire palette — reds, oranges, golds.
  inferno,

  /// Cool ice palette — cyans, whites, pale blues.
  glacier,

  /// Toxic waste — greens, yellows, acid tones.
  toxic,

  /// Deep void — purples, dark blues, magenta.
  voidStorm,

  /// Golden luxury — golds, ambers, warm whites.
  gilded,

  /// Rainbow spectrum — full hue rotation.
  rainbow,

  /// Monochrome — greys and whites only.
  monochrome,

  /// Blood moon — deep reds, dark crimsons.
  bloodMoon,

  /// Neon synthwave — magenta, cyan, electric blue.
  synthwave,

  /// Forest — greens, browns, earthy tones.
  forest,

  /// Candy — pinks, pastels, light purples.
  candy,

  /// Steel — metallic greys, silvers, cool whites.
  steel,

  /// Sunset — oranges, pinks, warm purples.
  sunset,

  /// Abyss — deep blues, blacks, dark teals.
  abyss,
}

extension ParticleColorSchemaX on ParticleColorSchema {
  String get label => switch (this) {
        ParticleColorSchema.presetDefault => 'Preset Default',
        ParticleColorSchema.themeMatch => 'Theme Match',
        ParticleColorSchema.inferno => 'Inferno',
        ParticleColorSchema.glacier => 'Glacier',
        ParticleColorSchema.toxic => 'Toxic',
        ParticleColorSchema.voidStorm => 'Void Storm',
        ParticleColorSchema.gilded => 'Gilded',
        ParticleColorSchema.rainbow => 'Rainbow',
        ParticleColorSchema.monochrome => 'Monochrome',
        ParticleColorSchema.bloodMoon => 'Blood Moon',
        ParticleColorSchema.synthwave => 'Synthwave',
        ParticleColorSchema.forest => 'Forest',
        ParticleColorSchema.candy => 'Candy',
        ParticleColorSchema.steel => 'Steel',
        ParticleColorSchema.sunset => 'Sunset',
        ParticleColorSchema.abyss => 'Abyss',
      };

  /// Returns the color list for this schema, or null if the preset's
  /// default colors should be used.
  List<Color>? get colors => switch (this) {
        ParticleColorSchema.presetDefault => null,
        ParticleColorSchema.themeMatch => null, // handled by caller — uses theme flair
        ParticleColorSchema.inferno => const [
            Color(0xFFFF1744),
            Color(0xFFFF6D00),
            Color(0xFFFFAB00),
            Color(0xFFFFD600),
          ],
        ParticleColorSchema.glacier => const [
            Color(0xFF00E5FF),
            Color(0xFF4FC3F7),
            Color(0xFFB3E5FC),
            Color(0xFFFFFFFF),
          ],
        ParticleColorSchema.toxic => const [
            Color(0xFF76FF03),
            Color(0xFF64DD17),
            Color(0xFFAEEA00),
            Color(0xFFCCFF00),
          ],
        ParticleColorSchema.voidStorm => const [
            Color(0xFF7B1FA2),
            Color(0xFF512DA8),
            Color(0xFF4527A0),
            Color(0xFFAB47BC),
          ],
        ParticleColorSchema.gilded => const [
            Color(0xFFFFD700),
            Color(0xFFFFC107),
            Color(0xFFFFB300),
            Color(0xFFFFE082),
          ],
        ParticleColorSchema.rainbow => const [
            Color(0xFFFF1744),
            Color(0xFFFF9100),
            Color(0xFFFFEA00),
            Color(0xFF00E676),
            Color(0xFF00B0FF),
            Color(0xFFD500F9),
          ],
        ParticleColorSchema.monochrome => const [
            Color(0xFFFFFFFF),
            Color(0xFFE0E0E0),
            Color(0xFFBDBDBD),
            Color(0xFF9E9E9E),
          ],
        ParticleColorSchema.bloodMoon => const [
            Color(0xFFB71C1C),
            Color(0xFFD32F2F),
            Color(0xFFE53935),
            Color(0xFF880E4F),
          ],
        ParticleColorSchema.synthwave => const [
            Color(0xFFD500F9),
            Color(0xFF00E5FF),
            Color(0xFF304FFE),
            Color(0xFFFF4081),
          ],
        ParticleColorSchema.forest => const [
            Color(0xFF2E7D32),
            Color(0xFF4CAF50),
            Color(0xFF81C784),
            Color(0xFFA1887F),
          ],
        ParticleColorSchema.candy => const [
            Color(0xFFFF69B4),
            Color(0xFFFFB6C1),
            Color(0xFFE1BEE7),
            Color(0xFFB39DDB),
          ],
        ParticleColorSchema.steel => const [
            Color(0xFFB0BEC5),
            Color(0xFF90A4AE),
            Color(0xFF78909C),
            Color(0xFFECEFF1),
          ],
        ParticleColorSchema.sunset => const [
            Color(0xFFFF6E40),
            Color(0xFFFFAB40),
            Color(0xFFFF80AB),
            Color(0xFFCE93D8),
          ],
        ParticleColorSchema.abyss => const [
            Color(0xFF0D47A1),
            Color(0xFF1565C0),
            Color(0xFF006064),
            Color(0xFF263238),
          ],
      };
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
            // Upgrades: gentle turbulence for organic drift, long lifetime
            turbulence: 0.3,
            lifetimeMin: 6.0, lifetimeMax: 10.0,
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
            // Upgrades: trails for fire streaks, short lifetime, color drift
            trailLength: 0.4,
            turbulence: 0.5,
            hueDriftSpeed: 15.0,
            lifetimeMin: 2.5, lifetimeMax: 5.0,
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
            // Upgrades: shimmer for ice sparkle, slow lifetime
            shimmer: true,
            lifetimeMin: 5.0, lifetimeMax: 8.0,
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
            // Upgrades: turbulence for bubble wobble, color drift
            turbulence: 0.6,
            hueDriftSpeed: 10.0,
            lifetimeMin: 4.0, lifetimeMax: 7.0,
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
            // Upgrades: shimmer for twinkling, long lifetime
            shimmer: true,
            lifetimeMin: 8.0, lifetimeMax: 14.0,
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
            // Upgrades: heavy turbulence for smoke swirl, color drift, trails
            turbulence: 0.8,
            hueDriftSpeed: 20.0,
            trailLength: 0.3,
            lifetimeMin: 4.0, lifetimeMax: 8.0,
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
            // Upgrades: short lifetime (casings fall and disappear)
            lifetimeMin: 2.0, lifetimeMax: 4.0,
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
            // Upgrades: turbulence for rift energy, color drift, shimmer
            turbulence: 0.7,
            hueDriftSpeed: 30.0,
            shimmer: true,
            lifetimeMin: 5.0, lifetimeMax: 9.0,
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
            // Upgrades: trails for bullet streaks, very short lifetime
            trailLength: 0.5,
            lifetimeMin: 1.0, lifetimeMax: 2.5,
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
            // Upgrades: shimmer for magical twinkle, color drift, turbulence
            shimmer: true,
            hueDriftSpeed: 25.0,
            turbulence: 0.3,
            lifetimeMin: 4.0, lifetimeMax: 7.0,
          ),
        ParticlePreset.cosmicDust => PresetConfig(
            colors: [const Color(0xFF5C6BC0), const Color(0xFF7E57C2), const Color(0xFF26C6DA), const Color(0xFF80DEEA)],
            shape: ParticleShape.circle,
            sizeMin: 1.0, sizeMax: 3.5,
            speedMin: 2.0, speedMax: 8.0,
            glowEffect: GlowEffect.ripple,
            lineLinks: true,
            drift: DriftDirection.random,
            wobble: 0.3,
            // Upgrades: gentle turbulence, slow color drift, long life
            turbulence: 0.4,
            hueDriftSpeed: 15.0,
            lifetimeMin: 8.0, lifetimeMax: 14.0,
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
            // Upgrades: shimmer for golden gleam, slow color drift
            shimmer: true,
            hueDriftSpeed: 8.0,
            lifetimeMin: 5.0, lifetimeMax: 9.0,
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
            // Upgrades: color drift for rainbow cycling, short life
            hueDriftSpeed: 40.0,
            turbulence: 0.4,
            lifetimeMin: 2.0, lifetimeMax: 4.5,
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
            // Upgrades: gentle turbulence, long life
            turbulence: 0.3,
            lifetimeMin: 6.0, lifetimeMax: 10.0,
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
            // Upgrades: shimmer for heartbeat gleam
            shimmer: true,
            lifetimeMin: 5.0, lifetimeMax: 9.0,
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
            // Upgrades: heavy turbulence for eerie drift, color drift
            turbulence: 0.6,
            hueDriftSpeed: 18.0,
            lifetimeMin: 5.0, lifetimeMax: 9.0,
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
            // Upgrades: shimmer for golden gleam, trail for smokey fall
            shimmer: true,
            trailLength: 0.3,
            lifetimeMin: 4.0, lifetimeMax: 7.0,
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
            // Upgrades: turbulence for swarm movement, color drift
            turbulence: 0.5,
            hueDriftSpeed: 22.0,
            lifetimeMin: 5.0, lifetimeMax: 9.0,
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

  // ── New upgrade fields (all default to off/zero for backward compat) ──
  final double trailLength;      // 0 = no trail, 0.3 = short, 0.6 = long
  final double turbulence;       // 0 = none, 1 = strong organic swirl
  final double hueDriftSpeed;    // deg/s — 0 = static, 20 = slow, 40 = fast
  final bool shimmer;            // periodic brightness sweep
  final double lifetimeMin;      // seconds — 0 = infinite (legacy wrap mode)
  final double lifetimeMax;      // seconds

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
    this.trailLength = 0.0,
    this.turbulence = 0.0,
    this.hueDriftSpeed = 0.0,
    this.shimmer = false,
    this.lifetimeMin = 0.0,
    this.lifetimeMax = 0.0,
  });

  /// Whether this config uses the lifetime system (vs legacy wrap).
  bool get hasLifetime => lifetimeMax > 0.0;

  PresetConfig copyWith({
    List<Color>? colors,
    ParticleShape? shape,
    double? sizeMin,
    double? sizeMax,
    double? speedMin,
    double? speedMax,
    GlowEffect? glowEffect,
    bool? lineLinks,
    DriftDirection? drift,
    double? wobble,
    bool? rotate,
    double? trailLength,
    double? turbulence,
    double? hueDriftSpeed,
    bool? shimmer,
    double? lifetimeMin,
    double? lifetimeMax,
  }) {
    return PresetConfig(
      colors: colors ?? this.colors,
      shape: shape ?? this.shape,
      sizeMin: sizeMin ?? this.sizeMin,
      sizeMax: sizeMax ?? this.sizeMax,
      speedMin: speedMin ?? this.speedMin,
      speedMax: speedMax ?? this.speedMax,
      glowEffect: glowEffect ?? this.glowEffect,
      lineLinks: lineLinks ?? this.lineLinks,
      drift: drift ?? this.drift,
      wobble: wobble ?? this.wobble,
      rotate: rotate ?? this.rotate,
      trailLength: trailLength ?? this.trailLength,
      turbulence: turbulence ?? this.turbulence,
      hueDriftSpeed: hueDriftSpeed ?? this.hueDriftSpeed,
      shimmer: shimmer ?? this.shimmer,
      lifetimeMin: lifetimeMin ?? this.lifetimeMin,
      lifetimeMax: lifetimeMax ?? this.lifetimeMax,
    );
  }
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

  // ── Upgrade fields ──
  double age;            // seconds since spawn
  double maxLifetime;    // 0 = infinite (legacy), >0 = finite lifetime
  double hueOffset;      // current hue rotation in degrees
  double hueDriftSpeed;  // deg/s
  double rotationAccel;  // rotational acceleration
  double shimmerPhase;   // random phase for shimmer effect
  double turbulencePhase; // random phase for turbulence field
  final List<_TrailPoint> trail; // past positions for trail effect

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
    this.age = 0.0,
    this.maxLifetime = 0.0,
    this.hueOffset = 0.0,
    this.hueDriftSpeed = 0.0,
    this.rotationAccel = 0.0,
    this.shimmerPhase = 0.0,
    this.turbulencePhase = 0.0,
    List<_TrailPoint>? trail,
  }) : trail = trail ?? [];
}

/// A single point in a particle's trail history.
class _TrailPoint {
  final double x;
  final double y;
  double age; // seconds since this point was captured

  _TrailPoint({required this.x, required this.y, required this.age});
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
  final List<Color>? colorsOverride; // per-theme/per-palette color injection
  final bool bounce;
  final double speedMultiplier; // 0.3 (very slow) to 2.5 (very fast)

  const ParticleField({
    super.key,
    required this.preset,
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

    final cfg = widget.colorsOverride != null
        ? _withColors(widget.preset.config, widget.colorsOverride!)
        : widget.preset.config;
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

    // Lifetime: 0 = infinite (legacy wrap mode), >0 = finite with fade
    final maxLife = cfg.hasLifetime
        ? cfg.lifetimeMin + _rng.nextDouble() * (cfg.lifetimeMax - cfg.lifetimeMin)
        : 0.0;

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
      // Upgrade fields:
      age: 0.0,
      maxLifetime: maxLife,
      hueOffset: 0.0,
      hueDriftSpeed: cfg.hueDriftSpeed * (0.7 + _rng.nextDouble() * 0.6),
      rotationAccel: cfg.rotate ? (_rng.nextDouble() - 0.5) * 0.8 : 0.0,
      shimmerPhase: _rng.nextDouble() * 2 * math.pi,
      turbulencePhase: _rng.nextDouble() * 2 * math.pi,
    ));
  }

  /// Respawn a particle at a new random position with fresh lifetime.
  /// Used when lifetime expires — smooth fade-in replaces the old wrap pop.
  void _respawnParticle(_Particle p, Size size, PresetConfig cfg) {
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
    final baseColor = cfg.colors[_rng.nextInt(cfg.colors.length)];
    final hsl = HSLColor.fromColor(baseColor);
    final lightJitter = 0.85 + _rng.nextDouble() * 0.3;
    p.x = _rng.nextDouble() * size.width;
    p.y = _rng.nextDouble() * size.height;
    p.vx = vx;
    p.vy = vy;
    p.color = hsl.withLightness((hsl.lightness * lightJitter).clamp(0.0, 1.0)).toColor();
    p.baseSize = cfg.sizeMin + _rng.nextDouble() * (cfg.sizeMax - cfg.sizeMin);
    p.phase = _rng.nextDouble();
    p.depth = 0.4 + _rng.nextDouble() * 0.9;
    p.rotation = _rng.nextDouble() * 2 * math.pi;
    p.rotationSpeed = cfg.rotate ? (_rng.nextDouble() - 0.5) * 2.0 : 0.0;
    p.age = 0.0;
    p.maxLifetime = cfg.hasLifetime
        ? cfg.lifetimeMin + _rng.nextDouble() * (cfg.lifetimeMax - cfg.lifetimeMin)
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
    final tilt = ThemeOverlay.tiltNotifier.value;
    final cfg = widget.colorsOverride != null
        ? _withColors(widget.preset.config, widget.colorsOverride!)
        : widget.preset.config;

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
        final nx = math.sin(t * 0.7 + p.turbulencePhase + p.x * 0.01) +
                   math.cos(t * 1.3 + p.turbulencePhase * 1.7 + p.y * 0.008);
        final ny = math.cos(t * 0.5 + p.turbulencePhase * 1.3 + p.x * 0.012) +
                   math.sin(t * 1.1 + p.turbulencePhase + p.y * 0.009);
        p.vx += nx * cfg.turbulence * 8.0 * dt;
        p.vy += ny * cfg.turbulence * 8.0 * dt;
        // Damping so turbulence doesn't accelerate to infinity
        p.vx *= 1.0 - 0.5 * dt;
        p.vy *= 1.0 - 0.5 * dt;
      }

      // Perpendicular wobble — sine offset at ~2 Hz, amplitude scaled by depth
      if (p.wobbleAmp > 0) {
        final wobble = math.sin(t * 2.0 + p.wobblePhase) * p.wobbleAmp * p.depth;
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
        if (p.x < -20 || p.x > size.width + 20 ||
            p.y < -20 || p.y > size.height + 20) {
          _respawnParticle(p, size, cfg);
        }
      } else if (widget.bounce) {
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
                  config: widget.colorsOverride != null
                      ? _withColors(widget.preset.config, widget.colorsOverride!)
                      : widget.preset.config,
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

  /// Apply hue rotation to a color (for color drift effect).
  Color _applyHueOffset(Color color, double hueOffset) {
    if (hueOffset == 0.0) return color;
    final hsl = HSLColor.fromColor(color);
    return hsl.withHue((hsl.hue + hueOffset) % 360).toColor();
  }

  /// Lifetime fade: smoothstep in at birth, smoothstep out at death.
  double _lifetimeAlpha(_Particle p) {
    if (p.maxLifetime <= 0) return 1.0;
    const fadeIn = 0.4;   // 0.4s fade in
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
            final colorA = _applyHueOffset(a.color, a.hueOffset)
                .withValues(alpha: linkAlpha);
            final colorB = _applyHueOffset(b.color, b.hueOffset)
                .withValues(alpha: linkAlpha);
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
        drawSize *= 0.84 + 0.10 * math.sin(t * 1.5 + p.phase * 6)
                         + 0.06 * math.sin(t * 0.7 + p.phase * 3.5);
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
          final cursedHsl = HSLColor.fromColor(driftedColor)
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
            _paint.color = driftedColor.withValues(alpha: rippleAlpha);
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
        _drawShape(canvas, config.shape, 0, 0, drawSize, _paint, alpha, glowEffect);
        canvas.restore();
      } else {
        _drawShape(canvas, config.shape, p.x, p.y, drawSize, _paint, alpha, glowEffect);
      }

      // Reset mask for next particle
      _paint.maskFilter = null;
    }
  }

  /// Unified shape drawer — eliminates duplicated code between rotated
  /// and non-rotated paths.
  void _drawShape(Canvas canvas, ParticleShape shape, double cx, double cy,
      double drawSize, Paint paint, double alpha, GlowEffect glow) {
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
          Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 1.4),
          paint,
        );
        break;
      case ParticleShape.bullet:
        _drawBullet(canvas, cx, cy, drawSize, paint);
        if (glow != GlowEffect.none) {
          paint.maskFilter = null;
          paint.color = Colors.white.withValues(alpha: alpha * 0.4);
          canvas.drawCircle(Offset(cx, cy - drawSize * 0.3), drawSize * 0.15, paint);
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

