part of '../particle_engine.dart';

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
  catPaws,
  moonlight,
  lightningBolts,
  paradoxShards,
  gunpowderSmoke,
  dragunScales,
  circuitTraces,
  shellCasings,
  heroicBlades,
  boneShards,
  // ── 6 new artful presets ──
  auroraVeil, // flowing hue-cycling ribbon of light
  crystalLattice, // geometric hexagonal lattice with line links
  inkSplatter, // bold ink drops with spectral echo
  solarFlare, // explosive corona bursts with ember glow
  tidePool, // liquid blob shapes with ripple glow
  stainedGlass, // prism-glow geometric shards
  // ── 3 new Gungeon-unique presets ──
  blankShells, // Gungeon Blank starburst shells
  hegemonyCredits, // spinning Hegemony Credit coins
  masterRoundAura, // Master Ring halo orbit
}

/// Particle speed multiplier — 5 discrete steps from very slow to very fast.
enum ParticleSpeed {
  verySlow, // 0.3x
  slow, // 0.6x
  normal, // 1.0x (default)
  fast, // 1.6x
  veryFast, // 2.5x
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

/// Build the engine config for a user-facing type. Chaos ON adds
/// turbulence (organic swirl); bounce + touch are widget-level flags.
PresetConfig typedParticleConfig(
  ParticleType t,
  final List<Color> colors, {
  bool chaos = false,
}) {
  final turb = chaos ? 0.9 : 0.0;
  switch (t) {
    case ParticleType.dot:
      return PresetConfig(
        colors: colors,
        shape: ParticleShape.circle,
        sizeMin: 1.5,
        sizeMax: 3.5,
        speedMin: 4,
        speedMax: 10,
        glowEffect: GlowEffect.smokey,
        lineLinks: false,
        drift: DriftDirection.random,
        wobble: 0.4,
        turbulence: turb,
      );
    case ParticleType.square:
      return PresetConfig(
        colors: colors,
        shape: ParticleShape.edge,
        sizeMin: 2,
        sizeMax: 4,
        speedMin: 3,
        speedMax: 8,
        glowEffect: GlowEffect.none,
        lineLinks: false,
        drift: DriftDirection.down,
        wobble: 0.2,
        turbulence: turb,
      );
    case ParticleType.glowOrb:
      return PresetConfig(
        colors: colors,
        shape: ParticleShape.circle,
        sizeMin: 3,
        sizeMax: 7,
        speedMin: 3,
        speedMax: 8,
        glowEffect: GlowEffect.pulse,
        lineLinks: false,
        drift: DriftDirection.up,
        wobble: 0.6,
        shimmer: true,
        turbulence: turb,
      );
    case ParticleType.shell:
      return PresetConfig(
        colors: colors,
        shape: ParticleShape.bullet,
        sizeMin: 3,
        sizeMax: 6,
        speedMin: 6,
        speedMax: 14,
        glowEffect: GlowEffect.none,
        lineLinks: false,
        drift: DriftDirection.down,
        rotate: true,
        turbulence: turb,
      );
    case ParticleType.rainbowDot:
      return PresetConfig(
        colors: colors,
        shape: ParticleShape.circle,
        sizeMin: 2,
        sizeMax: 5,
        speedMin: 4,
        speedMax: 10,
        glowEffect: GlowEffect.smokey,
        lineLinks: false,
        drift: DriftDirection.random,
        wobble: 0.5,
        hueDriftSpeed: 40,
        turbulence: turb,
      );
    case ParticleType.voidPixel:
      return PresetConfig(
        colors: colors,
        shape: ParticleShape.edge,
        sizeMin: 2.5,
        sizeMax: 5,
        speedMin: 3,
        speedMax: 8,
        glowEffect: GlowEffect.cursed,
        lineLinks: false,
        drift: DriftDirection.up,
        wobble: 0.7,
        turbulence: turb,
      );
    case ParticleType.glitchPixel:
      return PresetConfig(
        colors: colors,
        shape: ParticleShape.shard,
        sizeMin: 2,
        sizeMax: 5,
        speedMin: 8,
        speedMax: 18,
        glowEffect: GlowEffect.neon,
        lineLinks: false,
        drift: DriftDirection.random,
        wobble: 0.3,
        turbulence: chaos ? 1.4 : 0.6,
      );
  }
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
    ParticleColorSchema.themeMatch =>
      null, // handled by caller — uses theme flair
    ParticleColorSchema.inferno => [
      Color(0xFFFF1744),
      Color(0xFFFF6D00),
      Color(0xFFFFAB00),
      Color(0xFFFFD600),
    ],
    ParticleColorSchema.glacier => [
      Color(0xFF00E5FF),
      Color(0xFF4FC3F7),
      Color(0xFFB3E5FC),
      Color(0xFFFFFFFF),
    ],
    ParticleColorSchema.toxic => [
      Color(0xFF76FF03),
      Color(0xFF64DD17),
      Color(0xFFAEEA00),
      Color(0xFFCCFF00),
    ],
    ParticleColorSchema.voidStorm => [
      Color(0xFF7B1FA2),
      Color(0xFF512DA8),
      Color(0xFF4527A0),
      Color(0xFFAB47BC),
    ],
    ParticleColorSchema.gilded => [
      Color(0xFFFFD700),
      Color(0xFFFFC107),
      Color(0xFFFFB300),
      Color(0xFFFFE082),
    ],
    ParticleColorSchema.rainbow => [
      Color(0xFFFF1744),
      Color(0xFFFF9100),
      Color(0xFFFFEA00),
      Color(0xFF00E676),
      Color(0xFF00B0FF),
      Color(0xFFD500F9),
    ],
    ParticleColorSchema.monochrome => [
      Color(0xFFFFFFFF),
      Color(0xFFE0E0E0),
      Color(0xFFBDBDBD),
      Color(0xFF9E9E9E),
    ],
    ParticleColorSchema.bloodMoon => [
      Color(0xFFB71C1C),
      Color(0xFFD32F2F),
      Color(0xFFE53935),
      Color(0xFF880E4F),
    ],
    ParticleColorSchema.synthwave => [
      Color(0xFFD500F9),
      Color(0xFF00E5FF),
      Color(0xFF304FFE),
      Color(0xFFFF4081),
    ],
    ParticleColorSchema.forest => [
      Color(0xFF2E7D32),
      Color(0xFF4CAF50),
      Color(0xFF81C784),
      Color(0xFFA1887F),
    ],
    ParticleColorSchema.candy => [
      Color(0xFFFF69B4),
      Color(0xFFFFB6C1),
      Color(0xFFE1BEE7),
      Color(0xFFB39DDB),
    ],
    ParticleColorSchema.steel => [
      Color(0xFFB0BEC5),
      Color(0xFF90A4AE),
      Color(0xFF78909C),
      Color(0xFFECEFF1),
    ],
    ParticleColorSchema.sunset => [
      Color(0xFFFF6E40),
      Color(0xFFFFAB40),
      Color(0xFFFF80AB),
      Color(0xFFCE93D8),
    ],
    ParticleColorSchema.abyss => [
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
    ParticlePreset.catPaws => 'Cat Paws',
    ParticlePreset.moonlight => 'Moonlight',
    ParticlePreset.lightningBolts => 'Lightning Bolts',
    ParticlePreset.paradoxShards => 'Paradox Shards',
    ParticlePreset.gunpowderSmoke => 'Gunpowder Smoke',
    ParticlePreset.dragunScales => 'Dragun Scales',
    ParticlePreset.circuitTraces => 'Circuit Traces',
    ParticlePreset.shellCasings => 'Shell Casings',
    ParticlePreset.heroicBlades => 'Heroic Blades',
    ParticlePreset.boneShards => 'Bone Shards',
    ParticlePreset.auroraVeil => 'Aurora Veil',
    ParticlePreset.crystalLattice => 'Crystal Lattice',
    ParticlePreset.inkSplatter => 'Ink Splatter',
    ParticlePreset.solarFlare => 'Solar Flare',
    ParticlePreset.tidePool => 'Tide Pool',
    ParticlePreset.stainedGlass => 'Stained Glass',
    ParticlePreset.blankShells => 'Blank Shells',
    ParticlePreset.hegemonyCredits => 'Hegemony Credits',
    ParticlePreset.masterRoundAura => 'Master Round Aura',
  };

  String get description => switch (this) {
    ParticlePreset.gungeonDust =>
      'Subtle grey-white motes drifting upward with gentle sway',
    ParticlePreset.forgeEmbers =>
      'Fire embers rising with lively flicker, orange/red/gold',
    ParticlePreset.frostShards =>
      'Ice crystals drifting down with slow spin, cyan/white',
    ParticlePreset.toxicBubbles => 'Green bubbles wobbling upward',
    ParticlePreset.cosmicStars =>
      'Twinkling 4-point stars with slow rotation, cyan/gold/white',
    ParticlePreset.cursedSmoke =>
      'Purple-black smoke wisps with shifting cursed aura',
    ParticlePreset.brassCasings => 'Brass shell casings tumbling as they fall',
    ParticlePreset.voidRift =>
      'Dark purple energy triangles with dual ripple rings',
    ParticlePreset.bulletHell => 'Fast-moving small dots, dense and chaotic',
    ParticlePreset.unicornSparkles =>
      'Pink/purple/cyan sparkles with pulse glow and twinkle',
    ParticlePreset.cosmicDust =>
      'Deep blue/violet dust with ripple rings and line links',
    ParticlePreset.goldenSparkle =>
      'Gold/amber stars with smokey glow, slow spin',
    ParticlePreset.rainbowConfetti =>
      'Multi-color confetti pieces tumbling down',
    ParticlePreset.bulletKin =>
      'Cute brass bullet shapes drifting upward with warm glow',
    ParticlePreset.heartContainers =>
      'Floating heart containers with beating pulse glow',
    ParticlePreset.cursedSkulls =>
      'Eerie skull particles with shifting cursed aura',
    ParticlePreset.masterRounds =>
      'Spinning golden master rounds falling with smokey trail',
    ParticlePreset.jamHexes =>
      'Purple jam hexagons with cursed glow and connected network',
    ParticlePreset.catPaws =>
      'Tiny cat paw prints drifting upward with warm amber glow',
    ParticlePreset.moonlight =>
      'Crescent moons and stars drifting with silver glow and twinkle',
    ParticlePreset.lightningBolts =>
      'Electric lightning bolts striking downward with flash glow',
    ParticlePreset.paradoxShards =>
      'Fractured crystal shards spinning through a time rift with cursed glow',
    ParticlePreset.gunpowderSmoke =>
      'Dark smoke puffs drifting upward with sulfurous ember glow',
    ParticlePreset.dragunScales =>
      'Reptilian dragon scales falling with molten orange-red glow',
    ParticlePreset.circuitTraces =>
      'Circuit-board traces connecting with electric green-blue line links',
    ParticlePreset.shellCasings =>
      'Spent brass shell casings falling with warm metallic clink',
    ParticlePreset.heroicBlades =>
      'Heroic blade tips spinning upward with gold-red valor glow',
    ParticlePreset.boneShards =>
      'Fractured bone shards drifting with eerie crypt-teal cursed glow',
    ParticlePreset.auroraVeil =>
      'Flowing hue-cycling ribbon of light with aurora glow',
    ParticlePreset.crystalLattice =>
      'Geometric hexagonal lattice with line links and pulse glow',
    ParticlePreset.inkSplatter =>
      'Bold ink drops with spectral echo and dark splatter trails',
    ParticlePreset.solarFlare =>
      'Explosive corona bursts with ember flicker glow',
    ParticlePreset.tidePool => 'Liquid blob shapes drifting with ripple glow',
    ParticlePreset.stainedGlass =>
      'Prism-glow geometric shards refracting rainbow light',
    ParticlePreset.blankShells =>
      'Gungeon Blank starburst shells expanding outward',
    ParticlePreset.hegemonyCredits =>
      'Spinning Hegemony Credit coins falling with golden glow',
    ParticlePreset.masterRoundAura =>
      'Master Round halo orbit with pulsing valor glow',
  };

  PresetConfig get config => switch (this) {
    ParticlePreset.gungeonDust => PresetConfig(
      colors: [
        const Color(0xFFE0E0E0),
        const Color(0xFFBDBDBD),
        const Color(0xFF9E9E9E),
        const Color(0xFF757575),
        const Color(0xFFD7D7D7),
      ],
      shape: ParticleShape.circle,
      sizeMin: 0.8,
      sizeMax: 2.8,
      speedMin: 3.0,
      speedMax: 10.0,
      glowEffect: GlowEffect.none,
      lineLinks: false,
      drift: DriftDirection.up,
      wobble: 0.3,
      // Upgrades: gentle turbulence for organic drift, long lifetime,
      // slow fade — matches the real Gungeon's subtle chamber dust
      turbulence: 0.15,
      lifetimeMin: 8.0,
      lifetimeMax: 14.0,
    ),
    ParticlePreset.forgeEmbers => PresetConfig(
      colors: [
        const Color(0xFFFF3D00),
        const Color(0xFFFF9100),
        const Color(0xFFFFD600),
        const Color(0xFFFF5722),
      ],
      shape: ParticleShape.circle,
      sizeMin: 2.0,
      sizeMax: 5.0,
      speedMin: 15.0,
      speedMax: 35.0,
      glowEffect: GlowEffect.smokey,
      lineLinks: false,
      drift: DriftDirection.up,
      wobble: 1.5,
      // Upgrades: trails for fire streaks, short lifetime, color drift
      trailLength: 0.4,
      turbulence: 0.5,
      hueDriftSpeed: 15.0,
      lifetimeMin: 2.5,
      lifetimeMax: 5.0,
    ),
    ParticlePreset.frostShards => PresetConfig(
      colors: [
        const Color(0xFF00B0FF),
        const Color(0xFF4FC3F7),
        const Color(0xFFE1F5FE),
      ],
      shape: ParticleShape.star,
      sizeMin: 2.0,
      sizeMax: 5.0,
      speedMin: 6.0,
      speedMax: 16.0,
      glowEffect: GlowEffect.pulse,
      lineLinks: false,
      drift: DriftDirection.down,
      wobble: 0.3,
      rotate: true,
      // Upgrades: shimmer for ice sparkle, slow lifetime
      shimmer: true,
      lifetimeMin: 5.0,
      lifetimeMax: 8.0,
    ),
    ParticlePreset.toxicBubbles => PresetConfig(
      colors: [
        const Color(0xFF76FF03),
        const Color(0xFF64DD17),
        const Color(0xFFAEEA00),
        const Color(0xFF33691E),
      ],
      shape: ParticleShape.circle,
      sizeMin: 3.0,
      sizeMax: 7.0,
      speedMin: 5.0,
      speedMax: 14.0,
      glowEffect: GlowEffect.none,
      lineLinks: false,
      drift: DriftDirection.up,
      wobble: 1.0,
      // Upgrades: turbulence for bubble wobble, color drift
      turbulence: 0.6,
      hueDriftSpeed: 10.0,
      lifetimeMin: 4.0,
      lifetimeMax: 7.0,
    ),
    ParticlePreset.cosmicStars => PresetConfig(
      colors: [const Color(0xFF00E5FF), const Color(0xFFFFD700), Colors.white],
      shape: ParticleShape.star,
      sizeMin: 2.0,
      sizeMax: 5.0,
      speedMin: 4.0,
      speedMax: 12.0,
      glowEffect: GlowEffect.pulse,
      lineLinks: true,
      drift: DriftDirection.random,
      wobble: 0.2,
      rotate: true,
      // Upgrades: shimmer for twinkling, long lifetime
      shimmer: true,
      lifetimeMin: 8.0,
      lifetimeMax: 14.0,
    ),
    ParticlePreset.cursedSmoke => PresetConfig(
      colors: [
        const Color(0xFF6A1B9A),
        const Color(0xFF4A148C),
        const Color(0xFF311B92),
        const Color(0xFF8E24AA),
      ],
      shape: ParticleShape.circle,
      sizeMin: 4.0,
      sizeMax: 9.0,
      speedMin: 3.0,
      speedMax: 10.0,
      glowEffect: GlowEffect.cursed,
      lineLinks: false,
      drift: DriftDirection.up,
      wobble: 0.8,
      // Upgrades: heavy turbulence for smoke swirl, color drift, trails
      turbulence: 0.8,
      hueDriftSpeed: 20.0,
      trailLength: 0.3,
      lifetimeMin: 4.0,
      lifetimeMax: 8.0,
    ),
    ParticlePreset.brassCasings => PresetConfig(
      colors: [
        const Color(0xFFB8860B),
        const Color(0xFFCD853F),
        const Color(0xFFDAA520),
      ],
      shape: ParticleShape.edge,
      sizeMin: 2.0,
      sizeMax: 4.5,
      speedMin: 20.0,
      speedMax: 45.0,
      glowEffect: GlowEffect.none,
      lineLinks: false,
      drift: DriftDirection.down,
      rotate: true,
      // Upgrades: short lifetime (casings fall and disappear)
      lifetimeMin: 2.0,
      lifetimeMax: 4.0,
    ),
    ParticlePreset.voidRift => PresetConfig(
      colors: [
        const Color(0xFF7B1FA2),
        const Color(0xFF512DA8),
        const Color(0xFF4527A0),
        const Color(0xFF9575CD),
      ],
      shape: ParticleShape.triangle,
      sizeMin: 2.5,
      sizeMax: 6.0,
      speedMin: 5.0,
      speedMax: 15.0,
      glowEffect: GlowEffect.ripple,
      lineLinks: true,
      drift: DriftDirection.random,
      wobble: 0.6,
      rotate: true,
      // Upgrades: turbulence for rift energy, color drift, shimmer
      turbulence: 0.7,
      hueDriftSpeed: 30.0,
      shimmer: true,
      lifetimeMin: 5.0,
      lifetimeMax: 9.0,
    ),
    ParticlePreset.bulletHell => PresetConfig(
      colors: [
        const Color(0xFFFF5252),
        const Color(0xFFFFEB3B),
        const Color(0xFFFFAB40),
      ],
      shape: ParticleShape.circle,
      sizeMin: 1.5,
      sizeMax: 3.0,
      speedMin: 30.0,
      speedMax: 80.0,
      glowEffect: GlowEffect.none,
      lineLinks: false,
      drift: DriftDirection.random,
      wobble: 0.3,
      // Upgrades: trails for bullet streaks, very short lifetime
      trailLength: 0.5,
      lifetimeMin: 1.0,
      lifetimeMax: 2.5,
    ),
    ParticlePreset.unicornSparkles => PresetConfig(
      colors: [
        const Color(0xFFFF69B4),
        const Color(0xFFE040FB),
        const Color(0xFF00E5FF),
        const Color(0xFFFFD700),
      ],
      shape: ParticleShape.star,
      sizeMin: 2.0,
      sizeMax: 6.0,
      speedMin: 3.0,
      speedMax: 10.0,
      glowEffect: GlowEffect.pulse,
      lineLinks: false,
      drift: DriftDirection.random,
      wobble: 0.4,
      rotate: true,
      // Upgrades: shimmer for magical twinkle, color drift, turbulence
      shimmer: true,
      hueDriftSpeed: 25.0,
      turbulence: 0.3,
      lifetimeMin: 4.0,
      lifetimeMax: 7.0,
    ),
    ParticlePreset.cosmicDust => PresetConfig(
      colors: [
        const Color(0xFF5C6BC0),
        const Color(0xFF7E57C2),
        const Color(0xFF26C6DA),
        const Color(0xFF80DEEA),
      ],
      shape: ParticleShape.circle,
      sizeMin: 1.0,
      sizeMax: 3.5,
      speedMin: 2.0,
      speedMax: 8.0,
      glowEffect: GlowEffect.ripple,
      lineLinks: true,
      drift: DriftDirection.random,
      wobble: 0.3,
      // Upgrades: gentle turbulence, slow color drift, long life
      turbulence: 0.4,
      hueDriftSpeed: 15.0,
      lifetimeMin: 8.0,
      lifetimeMax: 14.0,
    ),
    ParticlePreset.goldenSparkle => PresetConfig(
      colors: [
        const Color(0xFFFFD700),
        const Color(0xFFFFC107),
        const Color(0xFFFFEB3B),
        const Color(0xFFFF8F00),
      ],
      shape: ParticleShape.star,
      sizeMin: 2.0,
      sizeMax: 5.0,
      speedMin: 4.0,
      speedMax: 12.0,
      glowEffect: GlowEffect.smokey,
      lineLinks: false,
      drift: DriftDirection.random,
      wobble: 0.2,
      rotate: true,
      // Upgrades: shimmer for golden gleam, slow color drift
      shimmer: true,
      hueDriftSpeed: 8.0,
      lifetimeMin: 5.0,
      lifetimeMax: 9.0,
    ),
    ParticlePreset.rainbowConfetti => PresetConfig(
      colors: [
        const Color(0xFFFF5252),
        const Color(0xFFFFEB3B),
        const Color(0xFF69F0AE),
        const Color(0xFF40C4FF),
        const Color(0xFFE040FB),
        const Color(0xFFFFAB40),
      ],
      shape: ParticleShape.edge,
      sizeMin: 2.5,
      sizeMax: 5.0,
      speedMin: 15.0,
      speedMax: 40.0,
      glowEffect: GlowEffect.none,
      lineLinks: false,
      drift: DriftDirection.down,
      wobble: 1.2,
      rotate: true,
      // Upgrades: color drift for rainbow cycling, short life
      hueDriftSpeed: 40.0,
      turbulence: 0.4,
      lifetimeMin: 2.0,
      lifetimeMax: 4.5,
    ),
    ParticlePreset.bulletKin => PresetConfig(
      colors: [
        const Color(0xFFDAA520),
        const Color(0xFFCD853F),
        const Color(0xFFB8860B),
        const Color(0xFFFFD700),
      ],
      shape: ParticleShape.bullet,
      sizeMin: 3.0,
      sizeMax: 7.0,
      speedMin: 5.0,
      speedMax: 15.0,
      glowEffect: GlowEffect.smokey,
      lineLinks: false,
      drift: DriftDirection.up,
      wobble: 0.8,
      // Upgrades: gentle turbulence, long life
      turbulence: 0.3,
      lifetimeMin: 6.0,
      lifetimeMax: 10.0,
    ),
    ParticlePreset.heartContainers => PresetConfig(
      colors: [
        const Color(0xFFFF5252),
        const Color(0xFFE91E63),
        const Color(0xFFF06292),
        const Color(0xFFD32F2F),
      ],
      shape: ParticleShape.heart,
      sizeMin: 3.0,
      sizeMax: 6.0,
      speedMin: 4.0,
      speedMax: 12.0,
      glowEffect: GlowEffect.pulse,
      lineLinks: false,
      drift: DriftDirection.up,
      wobble: 0.5,
      // Upgrades: shimmer for heartbeat gleam
      shimmer: true,
      lifetimeMin: 5.0,
      lifetimeMax: 9.0,
    ),
    ParticlePreset.cursedSkulls => PresetConfig(
      colors: [
        const Color(0xFF6A1B9A),
        const Color(0xFF4A148C),
        const Color(0xFF8E24AA),
        const Color(0xFF2E7D32),
      ],
      shape: ParticleShape.skull,
      sizeMin: 3.5,
      sizeMax: 7.0,
      speedMin: 3.0,
      speedMax: 10.0,
      glowEffect: GlowEffect.cursed,
      lineLinks: false,
      drift: DriftDirection.random,
      wobble: 0.6,
      // Upgrades: heavy turbulence for eerie drift, color drift
      turbulence: 0.6,
      hueDriftSpeed: 18.0,
      lifetimeMin: 5.0,
      lifetimeMax: 9.0,
    ),
    ParticlePreset.masterRounds => PresetConfig(
      colors: [
        const Color(0xFFFFD700),
        const Color(0xFFFFC107),
        const Color(0xFFFF8F00),
        const Color(0xFFFFEB3B),
      ],
      shape: ParticleShape.circle,
      sizeMin: 3.0,
      sizeMax: 6.0,
      speedMin: 6.0,
      speedMax: 16.0,
      glowEffect: GlowEffect.smokey,
      lineLinks: false,
      drift: DriftDirection.down,
      wobble: 0.3,
      rotate: true,
      // Upgrades: shimmer for golden gleam, trail for smokey fall
      shimmer: true,
      trailLength: 0.3,
      lifetimeMin: 4.0,
      lifetimeMax: 7.0,
    ),
    ParticlePreset.jamHexes => PresetConfig(
      colors: [
        const Color(0xFF6A1B9A),
        const Color(0xFF4A148C),
        const Color(0xFF8E24AA),
        const Color(0xFFAB47BC),
      ],
      shape: ParticleShape.hexagon,
      sizeMin: 3.0,
      sizeMax: 6.5,
      speedMin: 4.0,
      speedMax: 14.0,
      glowEffect: GlowEffect.cursed,
      lineLinks: true,
      drift: DriftDirection.random,
      wobble: 0.5,
      rotate: true,
      // Upgrades: turbulence for swarm movement, color drift
      turbulence: 0.5,
      hueDriftSpeed: 22.0,
      lifetimeMin: 5.0,
      lifetimeMax: 9.0,
    ),
    ParticlePreset.catPaws => PresetConfig(
      colors: [
        const Color(0xFFFFB74D),
        const Color(0xFFFFCC80),
        const Color(0xFFFFE0B2),
        const Color(0xFFFF8A65),
      ],
      shape: ParticleShape.paw,
      sizeMin: 3.0,
      sizeMax: 7.0,
      speedMin: 3.0,
      speedMax: 10.0,
      glowEffect: GlowEffect.smokey,
      lineLinks: false,
      drift: DriftDirection.up,
      wobble: 0.6,
      rotate: false,
      // Upgrades: gentle turbulence for playful drift, warm shimmer
      turbulence: 0.3,
      shimmer: true,
      lifetimeMin: 5.0,
      lifetimeMax: 9.0,
    ),
    ParticlePreset.moonlight => PresetConfig(
      colors: [
        const Color(0xFFE1F5FE),
        const Color(0xFFB3E5FC),
        const Color(0xFF90CAF9),
        const Color(0xFFE0F7FA),
      ],
      shape: ParticleShape.crescent,
      sizeMin: 2.5,
      sizeMax: 6.0,
      speedMin: 2.0,
      speedMax: 8.0,
      glowEffect: GlowEffect.pulse,
      lineLinks: false,
      drift: DriftDirection.random,
      wobble: 0.3,
      rotate: true,
      // Upgrades: shimmer for moonlight twinkle, long life
      shimmer: true,
      lifetimeMin: 7.0,
      lifetimeMax: 12.0,
    ),
    ParticlePreset.lightningBolts => PresetConfig(
      colors: [
        const Color(0xFFFFEB3B),
        const Color(0xFFFFFF00),
        const Color(0xFF42A5F5),
        const Color(0xFF90CAF9),
      ],
      shape: ParticleShape.bolt,
      sizeMin: 2.5,
      sizeMax: 6.0,
      speedMin: 15.0,
      speedMax: 40.0,
      glowEffect: GlowEffect.smokey,
      lineLinks: true,
      drift: DriftDirection.down,
      wobble: 0.2,
      rotate: false,
      // Upgrades: trails for electric streaks, very short lifetime
      trailLength: 0.5,
      lifetimeMin: 1.0,
      lifetimeMax: 2.5,
    ),
    ParticlePreset.paradoxShards => PresetConfig(
      colors: [
        const Color(0xFFCE93D8),
        const Color(0xFFAB47BC),
        const Color(0xFF7E57C2),
        const Color(0xFFE1BEE7),
      ],
      shape: ParticleShape.shard,
      sizeMin: 2.5,
      sizeMax: 6.0,
      speedMin: 3.0,
      speedMax: 12.0,
      glowEffect: GlowEffect.cursed,
      lineLinks: true,
      drift: DriftDirection.random,
      wobble: 0.4,
      rotate: true,
      // Upgrades: turbulence for rift chaos, hue drift for time-warp
      turbulence: 0.6,
      hueDriftSpeed: 45.0,
      lifetimeMin: 5.0,
      lifetimeMax: 10.0,
    ),
    ParticlePreset.gunpowderSmoke => PresetConfig(
      colors: [
        const Color(0xFF424242),
        const Color(0xFF616161),
        const Color(0xFF757575),
        const Color(0xFFB71C1C),
      ],
      shape: ParticleShape.smoke,
      sizeMin: 4.0,
      sizeMax: 9.0,
      speedMin: 2.0,
      speedMax: 8.0,
      glowEffect: GlowEffect.smokey,
      lineLinks: false,
      drift: DriftDirection.up,
      wobble: 0.7,
      rotate: false,
      // Upgrades: heavy turbulence for billowing, long life
      turbulence: 0.5,
      lifetimeMin: 6.0,
      lifetimeMax: 11.0,
    ),
    ParticlePreset.dragunScales => PresetConfig(
      colors: [
        const Color(0xFFFF4500),
        const Color(0xFFFF6E40),
        const Color(0xFFFFAB40),
        const Color(0xFFD84315),
      ],
      shape: ParticleShape.scale,
      sizeMin: 3.0,
      sizeMax: 7.0,
      speedMin: 4.0,
      speedMax: 14.0,
      glowEffect: GlowEffect.pulse,
      lineLinks: false,
      drift: DriftDirection.down,
      wobble: 0.5,
      rotate: true,
      // Upgrades: shimmer for molten glint, medium life
      shimmer: true,
      lifetimeMin: 4.0,
      lifetimeMax: 8.0,
    ),
    ParticlePreset.circuitTraces => PresetConfig(
      colors: [
        const Color(0xFF69F0AE),
        const Color(0xFF40C4FF),
        const Color(0xFF00E676),
        const Color(0xFF82B1FF),
      ],
      shape: ParticleShape.edge,
      sizeMin: 2.0,
      sizeMax: 5.0,
      speedMin: 1.0,
      speedMax: 5.0,
      glowEffect: GlowEffect.smokey,
      lineLinks: true,
      drift: DriftDirection.random,
      wobble: 0.2,
      rotate: false,
      // Upgrades: shimmer for electric pulse, long life for persistent circuit
      shimmer: true,
      lifetimeMin: 8.0,
      lifetimeMax: 14.0,
    ),
    ParticlePreset.shellCasings => PresetConfig(
      colors: [
        const Color(0xFFFFB74D),
        const Color(0xFFD7CCC8),
        const Color(0xFFBCAAA4),
        const Color(0xFFFFCC80),
      ],
      shape: ParticleShape.edge,
      sizeMin: 2.5,
      sizeMax: 5.5,
      speedMin: 8.0,
      speedMax: 20.0,
      glowEffect: GlowEffect.none,
      lineLinks: false,
      drift: DriftDirection.down,
      wobble: 0.6,
      rotate: true,
      // Upgrades: trails for casing spin, short life (they hit the ground)
      trailLength: 0.3,
      lifetimeMin: 2.0,
      lifetimeMax: 4.0,
    ),
    ParticlePreset.heroicBlades => PresetConfig(
      colors: [
        const Color(0xFFFFD740),
        const Color(0xFFEF5350),
        const Color(0xFFFFE57F),
        const Color(0xFFFFCDD2),
      ],
      shape: ParticleShape.triangle,
      sizeMin: 3.0,
      sizeMax: 7.0,
      speedMin: 3.0,
      speedMax: 10.0,
      glowEffect: GlowEffect.pulse,
      lineLinks: false,
      drift: DriftDirection.up,
      wobble: 0.4,
      rotate: true,
      // Upgrades: shimmer for heroic gleam, medium life
      shimmer: true,
      lifetimeMin: 5.0,
      lifetimeMax: 9.0,
    ),
    ParticlePreset.boneShards => PresetConfig(
      colors: [
        const Color(0xFFE0E0E0),
        const Color(0xFF2EC4B6),
        const Color(0xFFF5F5DC),
        const Color(0xFF80CBC4),
      ],
      shape: ParticleShape.shard,
      sizeMin: 2.5,
      sizeMax: 6.0,
      speedMin: 2.0,
      speedMax: 8.0,
      glowEffect: GlowEffect.cursed,
      lineLinks: true,
      drift: DriftDirection.random,
      wobble: 0.5,
      rotate: true,
      // Upgrades: turbulence for necrotic drift, hue drift for decay
      turbulence: 0.4,
      hueDriftSpeed: 15.0,
      lifetimeMin: 6.0,
      lifetimeMax: 11.0,
    ),
    // ── 6 new artful presets ──
    ParticlePreset.auroraVeil => PresetConfig(
      colors: [
        const Color(0xFF00E5FF),
        const Color(0xFF76FF03),
        const Color(0xFFE040FB),
        const Color(0xFFFFEB3B),
      ],
      shape: ParticleShape.circle,
      sizeMin: 3.0,
      sizeMax: 7.0,
      speedMin: 4.0,
      speedMax: 12.0,
      glowEffect: GlowEffect.aurora,
      lineLinks: false,
      drift: DriftDirection.up,
      wobble: 1.0,
      // Upgrades: hue drift for full spectrum cycle, turbulence for ribbon flow
      hueDriftSpeed: 45.0,
      turbulence: 0.5,
      lifetimeMin: 8.0,
      lifetimeMax: 14.0,
    ),
    ParticlePreset.crystalLattice => PresetConfig(
      colors: [
        const Color(0xFFB3E5FC),
        const Color(0xFF80DEEA),
        const Color(0xFF26C6DA),
        const Color(0xFFE1F5FE),
      ],
      shape: ParticleShape.hexagon,
      sizeMin: 3.0,
      sizeMax: 6.0,
      speedMin: 2.0,
      speedMax: 6.0,
      glowEffect: GlowEffect.pulse,
      lineLinks: true,
      drift: DriftDirection.random,
      wobble: 0.2,
      rotate: true,
      // Upgrades: shimmer for crystal gleam, long life
      shimmer: true,
      lifetimeMin: 10.0,
      lifetimeMax: 16.0,
    ),
    ParticlePreset.inkSplatter => PresetConfig(
      colors: [
        const Color(0xFF1A1A1A),
        const Color(0xFF212121),
        const Color(0xFF424242),
        const Color(0xFF616161),
      ],
      shape: ParticleShape.shard,
      sizeMin: 3.0,
      sizeMax: 8.0,
      speedMin: 5.0,
      speedMax: 18.0,
      glowEffect: GlowEffect.spectral,
      lineLinks: false,
      drift: DriftDirection.random,
      wobble: 0.7,
      rotate: true,
      // Upgrades: turbulence for splatter chaos, short life
      turbulence: 0.7,
      trailLength: 0.3,
      lifetimeMin: 4.0,
      lifetimeMax: 8.0,
    ),
    ParticlePreset.solarFlare => PresetConfig(
      colors: [
        const Color(0xFFFFAB00),
        const Color(0xFFFF6D00),
        const Color(0xFFFFD600),
        const Color(0xFFFF3D00),
      ],
      shape: ParticleShape.star,
      sizeMin: 3.0,
      sizeMax: 7.0,
      speedMin: 8.0,
      speedMax: 25.0,
      glowEffect: GlowEffect.ember,
      lineLinks: false,
      drift: DriftDirection.up,
      wobble: 0.6,
      rotate: true,
      // Upgrades: trail for corona streaks, short life, shimmer
      trailLength: 0.5,
      shimmer: true,
      lifetimeMin: 3.0,
      lifetimeMax: 6.0,
    ),
    ParticlePreset.tidePool => PresetConfig(
      colors: [
        const Color(0xFF00BCD4),
        const Color(0xFF26C6DA),
        const Color(0xFF80DEEA),
        const Color(0xFF0097A7),
      ],
      shape: ParticleShape.circle,
      sizeMin: 4.0,
      sizeMax: 9.0,
      speedMin: 3.0,
      speedMax: 9.0,
      glowEffect: GlowEffect.ripple,
      lineLinks: true,
      drift: DriftDirection.random,
      wobble: 0.8,
      // Upgrades: turbulence for liquid motion, hue drift, long life
      turbulence: 0.5,
      hueDriftSpeed: 10.0,
      lifetimeMin: 8.0,
      lifetimeMax: 14.0,
    ),
    ParticlePreset.stainedGlass => PresetConfig(
      colors: [
        const Color(0xFFE91E63),
        const Color(0xFF9C27B0),
        const Color(0xFF2196F3),
        const Color(0xFFFFC107),
        const Color(0xFF4CAF50),
      ],
      shape: ParticleShape.triangle,
      sizeMin: 3.0,
      sizeMax: 7.0,
      speedMin: 3.0,
      speedMax: 10.0,
      glowEffect: GlowEffect.prism,
      lineLinks: true,
      drift: DriftDirection.random,
      wobble: 0.4,
      rotate: true,
      // Upgrades: hue drift for shifting refractions, shimmer
      hueDriftSpeed: 20.0,
      shimmer: true,
      lifetimeMin: 7.0,
      lifetimeMax: 12.0,
    ),
    // ── 3 new Gungeon-unique presets ──
    ParticlePreset.blankShells => PresetConfig(
      colors: [
        const Color(0xFFFFFFFF),
        const Color(0xFFE0F7FA),
        const Color(0xFF80DEEA),
        const Color(0xFFB3E5FC),
      ],
      shape: ParticleShape.star,
      sizeMin: 4.0,
      sizeMax: 9.0,
      speedMin: 12.0,
      speedMax: 30.0,
      glowEffect: GlowEffect.neon,
      lineLinks: false,
      drift: DriftDirection.random,
      wobble: 0.3,
      rotate: true,
      // Upgrades: trail for starburst streaks, short life, shimmer for flash
      trailLength: 0.6,
      shimmer: true,
      lifetimeMin: 2.0,
      lifetimeMax: 5.0,
    ),
    ParticlePreset.hegemonyCredits => PresetConfig(
      colors: [
        const Color(0xFFFFD700),
        const Color(0xFFFFC107),
        const Color(0xFFB8860B),
        const Color(0xFFFFE082),
      ],
      shape: ParticleShape.hexagon,
      sizeMin: 3.5,
      sizeMax: 7.0,
      speedMin: 8.0,
      speedMax: 22.0,
      glowEffect: GlowEffect.smokey,
      lineLinks: false,
      drift: DriftDirection.down,
      wobble: 0.5,
      rotate: true,
      // Upgrades: shimmer for coin gleam, medium life
      shimmer: true,
      lifetimeMin: 4.0,
      lifetimeMax: 8.0,
    ),
    ParticlePreset.masterRoundAura => PresetConfig(
      colors: [
        const Color(0xFFFFD700),
        const Color(0xFFFFC107),
        const Color(0xFFFF8F00),
        const Color(0xFFFFEB3B),
      ],
      shape: ParticleShape.circle,
      sizeMin: 2.0,
      sizeMax: 5.0,
      speedMin: 2.0,
      speedMax: 6.0,
      glowEffect: GlowEffect.plasma,
      lineLinks: true,
      drift: DriftDirection.up,
      wobble: 0.3,
      // Upgrades: shimmer for valor gleam, slow hue drift, long life
      shimmer: true,
      hueDriftSpeed: 8.0,
      lifetimeMin: 10.0,
      lifetimeMax: 18.0,
    ),
  };
}
