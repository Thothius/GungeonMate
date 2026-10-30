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
