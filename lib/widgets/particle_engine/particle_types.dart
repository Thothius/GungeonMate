part of '../particle_engine.dart';

enum ParticleShape {
  circle,
  star,
  triangle,
  edge,
  bullet,
  heart,
  skull,
  hexagon,
  paw,
  crescent,
  bolt,
  shard,
  smoke,
  scale,
}

enum ParticleType {
  dot, // tiny soft circles — the clean default
  square, // crisp pixel squares — minimalist
  glowOrb, // larger pulsing orbs — unicornSparkles energy
  shell, // tumbling brass bullet casings — gungeon flavor
  rainbowDot, // hue-cycling dots — playful
  voidPixel, // dark purple pixels w/ cursed aura — moody
  glitchPixel, // jittery cyan/magenta shards — paradox
}

enum GlowEffect {
  none,
  smokey,
  ripple,
  pulse,
  cursed,
  // ── 6 new artful glow effects ──
  neon, // bright neon halo with crisp edge
  aurora, // shifting hue-cycling soft halo
  ember, // warm flickering fire glow
  spectral, // ghostly translucent double-image
  plasma, // swirling electric plasma rings
  prism, // rainbow prism refraction shards
}

enum DriftDirection { up, down, random }

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
  final double trailLength; // 0 = no trail, 0.3 = short, 0.6 = long
  final double turbulence; // 0 = none, 1 = strong organic swirl
  final double hueDriftSpeed; // deg/s — 0 = static, 20 = slow, 40 = fast
  final bool shimmer; // periodic brightness sweep
  final double lifetimeMin; // seconds — 0 = infinite (legacy wrap mode)
  final double lifetimeMax; // seconds

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

  // Value equality — typedParticleConfig() returns a NEW instance every
  // call, so identity comparison in ParticleField.didUpdateWidget cleared
  // + respawned all particles on ANY parent rebuild (taps, route pushes).
  bool _colorsEq(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      other is PresetConfig &&
      _colorsEq(colors, other.colors) &&
      shape == other.shape &&
      sizeMin == other.sizeMin &&
      sizeMax == other.sizeMax &&
      speedMin == other.speedMin &&
      speedMax == other.speedMax &&
      glowEffect == other.glowEffect &&
      lineLinks == other.lineLinks &&
      drift == other.drift &&
      wobble == other.wobble &&
      rotate == other.rotate &&
      trailLength == other.trailLength &&
      turbulence == other.turbulence &&
      hueDriftSpeed == other.hueDriftSpeed &&
      shimmer == other.shimmer &&
      lifetimeMin == other.lifetimeMin &&
      lifetimeMax == other.lifetimeMax;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(colors),
    shape,
    sizeMin,
    sizeMax,
    speedMin,
    speedMax,
    glowEffect,
    lineLinks,
    drift,
    wobble,
    rotate,
    trailLength,
    turbulence,
    hueDriftSpeed,
    shimmer,
    lifetimeMin,
    lifetimeMax,
  );

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
  double age; // seconds since spawn
  double maxLifetime; // 0 = infinite (legacy), >0 = finite lifetime
  double hueOffset; // current hue rotation in degrees
  double hueDriftSpeed; // deg/s
  double rotationAccel; // rotational acceleration
  double shimmerPhase; // random phase for shimmer effect
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

extension ParticleTypeX on ParticleType {
  String get label => switch (this) {
    ParticleType.dot => 'DOT',
    ParticleType.square => 'SQUARE',
    ParticleType.glowOrb => 'GLOW ORB',
    ParticleType.shell => 'SHELL',
    ParticleType.rainbowDot => 'RAINBOW',
    ParticleType.voidPixel => 'VOID',
    ParticleType.glitchPixel => 'GLITCH',
  };
}

extension GlowEffectX on GlowEffect {
  String get label => switch (this) {
    GlowEffect.none => 'No Glow',
    GlowEffect.smokey => 'Smokey',
    GlowEffect.ripple => 'Ripple',
    GlowEffect.pulse => 'Pulse',
    GlowEffect.cursed => 'Cursed',
    GlowEffect.neon => 'Neon',
    GlowEffect.aurora => 'Aurora',
    GlowEffect.ember => 'Ember',
    GlowEffect.spectral => 'Spectral',
    GlowEffect.plasma => 'Plasma',
    GlowEffect.prism => 'Prism',
  };

  /// Short visual description for picker UI.
  String get blurb => switch (this) {
    GlowEffect.none => 'No glow — pure particles',
    GlowEffect.smokey => 'Soft diffuse blur',
    GlowEffect.ripple => 'Expanding ring waves',
    GlowEffect.pulse => 'Steady brightness pulse',
    GlowEffect.cursed => 'Hue-shifting cursed aura',
    GlowEffect.neon => 'Crisp bright neon halo',
    GlowEffect.aurora => 'Cycling hue rainbow halo',
    GlowEffect.ember => 'Warm flickering fire glow',
    GlowEffect.spectral => 'Ghostly translucent echo',
    GlowEffect.plasma => 'Swirling electric rings',
    GlowEffect.prism => 'Rainbow refraction shards',
  };
}
