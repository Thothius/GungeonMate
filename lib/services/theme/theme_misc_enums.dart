part of '../app_theme.dart';

// Split from theme_enums.dart — same library, no import changes.

enum InventoryDisplayMode { classicPeriodic, tacticalStats }

/// Ambient fragment shader preset (Q3 genius audit). Each preset maps
/// to a .frag file in assets/shaders/. See AmbientShaderLayer.
enum ShaderPreset { digitalRain, darkNeonFog }

extension ShaderPresetX on ShaderPreset {
  String get label => switch (this) {
    ShaderPreset.digitalRain => 'Digital Rain',
    ShaderPreset.darkNeonFog => 'Dark Neon Fog',
  };
}

/// Ambient liquid backdrop — a slow rising fill behind app content
/// (the "blood tank"). [off] renders nothing; [blood]/[venom]/[umbra]
/// are tinted bubbly fills; [shells] swaps the liquid for brass
/// casings that slide with device tilt. Persisted as an int index.
enum LiquidKind { off, blood, venom, umbra, shells }

extension LiquidKindX on LiquidKind {
  String get label => switch (this) {
    LiquidKind.off => 'OFF',
    LiquidKind.blood => 'BLOOD',
    LiquidKind.venom => 'VENOM',
    LiquidKind.umbra => 'UMBRA',
    LiquidKind.shells => 'SHELLS',
  };
}

/// Procedural atmosphere backdrop — painter-driven ambient effects that
/// sit between the liquid tank and the fragment shaders. Each kind is a
/// CustomPainter scene tinted by the active flair palette. Persisted as
/// an int index; [off] renders nothing.
enum AmbientKind {
  /// Nothing — clean backdrop.
  off,

  /// Volumetric light shafts sweeping down from the top edge.
  godRays,

  /// Ember/ash motes drifting upward with per-mote flicker.
  ash,

  /// Slowly rotating arcane ring with orbiting rune ticks.
  runes,

  /// CRT scanlines with an occasional horizontal glitch band.
  scanlines,

  /// Deep parallax speck field — far dust + a few near motes.
  abyss,
}

extension AmbientKindX on AmbientKind {
  String get label => switch (this) {
    AmbientKind.off => 'OFF',
    AmbientKind.godRays => 'RAYS',
    AmbientKind.ash => 'ASH',
    AmbientKind.runes => 'RUNES',
    AmbientKind.scanlines => 'SCAN',
    AmbientKind.abyss => 'ABYSS',
  };
}

/// Data model for custom theme settings persisted to SharedPreferences.
/// Allows users to create their own color palette with optional backdrop/aura/font.

enum GlowStyle {
  /// Orbiting dual-radial gradient (current behavior). Default.
  orbit,

  /// Bottom-up flicker — ember-like, fast and erratic.
  ember,

  /// Centered slow halo — static-ish, gentle pulse.
  halo,

  /// Top-down drip — slow downward gradient movement.
  drip,

  /// Rotating color-wheel sweep — linear gradient angle spins slowly,
  /// colors cycle through primary → secondary → tertiary.
  prism,

  /// Sonar rings — staggered radial pulses expanding from center.
  ripple,
}

/// Extra per-theme styling knobs beyond [ColorScheme]. Read via
/// `AppTheme.flair` from any widget that wants theme-aware numeric
/// typography, chip shape, bullet glyph or quirk flags.

enum CustomDiceType {
  themeDefault,
  classicWhite,
  goldGlimmer,
  frostShard,
  moltenAmber,
  voidPurple,
  toxicOoze,
}

extension CustomDiceTypeLabel on CustomDiceType {
  String get label {
    switch (this) {
      case CustomDiceType.themeDefault:
        return 'Theme Default';
      case CustomDiceType.classicWhite:
        return 'Classic White';
      case CustomDiceType.goldGlimmer:
        return 'Gold Glimmer';
      case CustomDiceType.frostShard:
        return 'Frost Shard';
      case CustomDiceType.moltenAmber:
        return 'Molten Amber';
      case CustomDiceType.voidPurple:
        return 'Void Purple';
      case CustomDiceType.toxicOoze:
        return 'Toxic Ooze';
    }
  }
}

/// User-controlled visual preferences persisted to SharedPreferences.
/// Independent of the active theme palette so any theme can be used
/// with or without glow / particles / bold text.
