import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Eight lore-named palettes. Each is a hand-tuned palette + a
/// [ThemeFlair] record carrying extra styling knobs (numeric typography,
/// divider/chip treatment, quirk flags) so themes differ in more than
/// just hue.
///
/// - [coolmaxing]   : Gold Rush. Black + chrome-gold + magenta. Headline
///                    numbers shimmer occasionally, heavier weight.
/// - [unicorn]      : Cotton Candy. Lavender + bubblegum + mint. Rounded
///                    display numbers; ✦ bullet glyphs twinkle.
/// - [curseblaster] : Blood Moon. Maroon-black + oxblood + bone. Curse
///                    stat glows red proportional to its value.
/// - [winchester]   : Saloon. Walnut + brass + bone. Embossed tabular
///                    numerals, brass hairline borders, tick dividers.
/// - [minimalist]   : Paper. Off-black + warm off-white. Chips replaced
///                    with plain underlined labels. No animation — the
///                    stillness is the quirk.
/// - [iceTyrant]    : Frozen Throne. Ice-black + slate-blue + cyan.
///                    Falling ice crystals, frost-ring aura.
/// - [pitchBlack]   : Void. Absolute dark + white motes. Barely visible
///                    pulse — silence is the signature.
/// - [oubliette]    : Toxic Depths. Poison green + swamp black. Rising
///                    toxic bubbles, bubbling ooze aura.
enum AppThemeMode {
  cosmicWhirlwind,
  unicorn,
  curseblaster,
  winchester,
  frogCute,
  iceTyrant,
  charm,
  midnightHunter,
  voidDimension,
  firestorm,
  theBreach,
  custom,
}

/// Thematic font options for the app. Each font provides a different
/// visual personality while maintaining readability.
enum AppFont {
  /// Enter the Gungeon's official chunky pixel display font.
  /// Default — ships with the app as a bundled asset.
  gungeon,

  /// Classic 80s arcade lettering
  arcadeClassic,

  /// Hand-drawn wobbly comic style
  shakyHandComic,

  /// Elegant classic vintage typography
  feelingVintage,

  /// Bold robust modern display lettering
  helloDenver,

  /// Playful summer kids lettering
  lemonadeStand,

  /// Whimsical high-readability sans font
  lifeSavers,

  /// Mystical wizarding world lettering
  parryHotter,

  /// Sleek futuristic sci-fi tech font
  prototype,

  /// Ancient mythic lore fantasy typography
  storiesFantasy,

  /// Tropical summer look
  beachday,

  /// Majestic fantasy dragon display font
  blastDragon,

  /// Round chunky pixel font
  chonkyCat,

  /// Flaming metal lettering
  dragonFire,

  /// Arcade game paused style
  gamePaused,

  /// Gothic medieval roman lettering
  morrisRoman,

  /// Detailed extrude 8-bit game font
  pixelGame,

  /// Bold gaming serif display
  solander,

  /// Magical runic display lettering
  starlightRune,

  // 15 Magnificent New OS-Native / Fallback Fonts (Ultra Light APK Weight!)
  systemRoboto,
  systemCourier,
  systemGeorgia,
  systemImpact,
  systemMonospace,
  systemSerif,
  systemTrebuchet,
  systemTimes,
  systemGaramond,
  systemFutura,
  systemHelvetica,
  systemOptima,
  systemCentury,
  systemBaskerville,
  systemBodoni,
}

extension AppFontLabel on AppFont {
  String get label {
    switch (this) {
      case AppFont.gungeon:
        return 'Enter the Gungeon';
      case AppFont.arcadeClassic:
        return 'Arcade Classic';
      case AppFont.shakyHandComic:
        return 'Shaky Hand Comic';
      case AppFont.feelingVintage:
        return 'Feeling Vintage';
      case AppFont.helloDenver:
        return 'Hello Denver Bold';
      case AppFont.lemonadeStand:
        return 'Lemonade Stand';
      case AppFont.lifeSavers:
        return 'Life Savers Bold';
      case AppFont.parryHotter:
        return 'Parry Hotter';
      case AppFont.prototype:
        return 'Prototype';
      case AppFont.storiesFantasy:
        return 'Stories Fantasy';
      case AppFont.beachday:
        return 'Beachday Retro';
      case AppFont.blastDragon:
        return 'Blast Dragon';
      case AppFont.chonkyCat:
        return 'Chonky Cat';
      case AppFont.dragonFire:
        return 'Dragon Fire';
      case AppFont.gamePaused:
        return 'Game Paused';
      case AppFont.morrisRoman:
        return 'Morris Roman';
      case AppFont.pixelGame:
        return 'Pixel Game';
      case AppFont.solander:
        return 'Solander Bold';
      case AppFont.starlightRune:
        return 'Starlight Rune';
      case AppFont.systemRoboto:
        return 'Roboto (Sleek)';
      case AppFont.systemCourier:
        return 'Courier Prime (Retro)';
      case AppFont.systemGeorgia:
        return 'Georgia (Classic)';
      case AppFont.systemImpact:
        return 'Impact (Heavy)';
      case AppFont.systemMonospace:
        return 'Monospace Tech';
      case AppFont.systemSerif:
        return 'Serif Elegant';
      case AppFont.systemTrebuchet:
        return 'Trebuchet (Artistic)';
      case AppFont.systemTimes:
        return 'Times Roman (Formal)';
      case AppFont.systemGaramond:
        return 'Garamond (Book)';
      case AppFont.systemFutura:
        return 'Futura (Modern)';
      case AppFont.systemHelvetica:
        return 'Helvetica (Universal)';
      case AppFont.systemOptima:
        return 'Optima (Classy)';
      case AppFont.systemCentury:
        return 'Century (Vintage)';
      case AppFont.systemBaskerville:
        return 'Baskerville (Elegant)';
      case AppFont.systemBodoni:
        return 'Bodoni (Chic)';
    }
  }

  String get description {
    switch (this) {
      case AppFont.gungeon:
        return 'Official Gungeon chunky pixel';
      case AppFont.arcadeClassic:
        return 'Classic 80s arcade letterforms';
      case AppFont.shakyHandComic:
        return 'Hand-drawn wobbly comic style';
      case AppFont.feelingVintage:
        return 'Elegant classic vintage font';
      case AppFont.helloDenver:
        return 'Bold robust modern display font';
      case AppFont.lemonadeStand:
        return 'Playful summer kids lettering';
      case AppFont.lifeSavers:
        return 'Whimsical high-readability sans';
      case AppFont.parryHotter:
        return 'Mystical wizarding world lettering';
      case AppFont.prototype:
        return 'Sleek sci-fi tech font';
      case AppFont.storiesFantasy:
        return 'Ancient mythic lore lettering';
      case AppFont.beachday:
        return 'Fun retro summer vibe';
      case AppFont.blastDragon:
        return 'Chunky action game logo style';
      case AppFont.chonkyCat:
        return 'Cute rounded pixel font';
      case AppFont.dragonFire:
        return 'Aggressive fantasy lettering';
      case AppFont.gamePaused:
        return 'Retro blinking arcade look';
      case AppFont.morrisRoman:
        return 'Gothic medieval crawler feel';
      case AppFont.pixelGame:
        return 'Symmetric extruded pixel style';
      case AppFont.solander:
        return 'Adventure quest serif style';
      case AppFont.starlightRune:
        return 'Glowing runic sorcerer lettering';
      case AppFont.systemRoboto:
        return 'Sleek OS-native sans-serif font';
      case AppFont.systemCourier:
        return 'Vintage typewriter slab-serif look';
      case AppFont.systemGeorgia:
        return 'High-readability classic book style';
      case AppFont.systemImpact:
        return 'Ultra-bold high-impact heavy sans';
      case AppFont.systemMonospace:
        return 'OS-native developer console style';
      case AppFont.systemSerif:
        return 'Formal serif display lettering';
      case AppFont.systemTrebuchet:
        return 'Smooth geometric humanist sans';
      case AppFont.systemTimes:
        return 'Formal editorial newspaper look';
      case AppFont.systemGaramond:
        return 'Elegant academic roman lettering';
      case AppFont.systemFutura:
        return 'High-end geometric display lettering';
      case AppFont.systemHelvetica:
        return 'Neutral, ultra-clean design standard';
      case AppFont.systemOptima:
        return 'Gentle flared sans serif lettering';
      case AppFont.systemCentury:
        return 'Graceful educational serif layout';
      case AppFont.systemBaskerville:
        return 'Luxurious classic transitional serif';
      case AppFont.systemBodoni:
        return 'High-contrast modern theatrical serif';
    }
  }

  /// Family name to use directly with TextStyle.fontFamily.
  String get bundledFamily {
    switch (this) {
      case AppFont.gungeon:
        return 'EnterTheGungeonBig';
      case AppFont.arcadeClassic:
        return 'ArcadeClassic';
      case AppFont.shakyHandComic:
        return 'ShakyHandComic';
      case AppFont.feelingVintage:
        return 'FeelingVintage';
      case AppFont.helloDenver:
        return 'HelloDenver';
      case AppFont.lemonadeStand:
        return 'LemonadeStand';
      case AppFont.lifeSavers:
        return 'LifeSavers';
      case AppFont.parryHotter:
        return 'ParryHotter';
      case AppFont.prototype:
        return 'Prototype';
      case AppFont.storiesFantasy:
        return 'StoriesFantasy';
      case AppFont.beachday:
        return 'Beachday';
      case AppFont.blastDragon:
        return 'BlastDragon';
      case AppFont.chonkyCat:
        return 'ChonkyCat';
      case AppFont.dragonFire:
        return 'DragonFire';
      case AppFont.gamePaused:
        return 'GamePaused';
      case AppFont.morrisRoman:
        return 'MorrisRoman';
      case AppFont.pixelGame:
        return 'PixelGame';
      case AppFont.solander:
        return 'Solander';
      case AppFont.starlightRune:
        return 'StarlightRune';
      case AppFont.systemRoboto:
        return 'Roboto';
      case AppFont.systemCourier:
        return 'Courier New';
      case AppFont.systemGeorgia:
        return 'Georgia';
      case AppFont.systemImpact:
        return 'Impact';
      case AppFont.systemMonospace:
        return 'monospace';
      case AppFont.systemSerif:
        return 'serif';
      case AppFont.systemTrebuchet:
        return 'Trebuchet MS';
      case AppFont.systemTimes:
        return 'Times New Roman';
      case AppFont.systemGaramond:
        return 'Garamond';
      case AppFont.systemFutura:
        return 'Futura';
      case AppFont.systemHelvetica:
        return 'Helvetica';
      case AppFont.systemOptima:
        return 'Optima';
      case AppFont.systemCentury:
        return 'Century';
      case AppFont.systemBaskerville:
        return 'Baskerville';
      case AppFont.systemBodoni:
        return 'Bodoni';
    }
  }

  TextStyle get textStyle {
    return TextStyle(fontFamily: bundledFamily);
  }

  TextTheme get textTheme {
    final base = ThemeData.dark().textTheme;
    return base.apply(fontFamily: bundledFamily);
  }
}

/// Themes shown in the picker. Keep this list as the single source of
/// truth — the [AppThemeMode] enum may include historical values that
/// are no longer offered to users; on app init we migrate any persisted
/// value not in this list onto the first entry below.
const List<AppThemeMode> kVisibleThemes = <AppThemeMode>[
  AppThemeMode.frogCute,
  AppThemeMode.cosmicWhirlwind,
  AppThemeMode.unicorn,
  AppThemeMode.curseblaster,
  AppThemeMode.winchester,
  AppThemeMode.iceTyrant,
  AppThemeMode.charm,
  AppThemeMode.midnightHunter,
  AppThemeMode.voidDimension,
  AppThemeMode.firestorm,
  AppThemeMode.theBreach,
];

/// Ambient full-screen flair painted by `ThemeOverlay`. Each theme picks
/// at most one. Painters are implemented in `widgets/theme_overlay.dart`
/// — the enum is here so the flair config and the overlay agree on the
/// vocabulary in one place.
enum ThemeBackdrop {
  none,
  goldDust,            // Coolmaxing — sparse rising gold flecks.
  pastelDriftSparkles, // Unicorn — animated hue shift + ✦ sparkles.
  redBreathDrip,       // Curseblaster — corner pulse + right-edge drip.
  brassMotes,          // Winchester — slow drifting brass dust.
  paperBreath,         // Minimalist — barely-there warm gradient breath.
  iceCrystals,         // Ice Tyrant — falling cyan-white ice shards.
  whiteDust,           // Pitch Black — sparse white motes in void.
  toxicBubbles,        // Oubliette — rising green toxic ooze bubbles.
  forgeEmbers,         // Forge Master — rising fiery sparks.
  hellfire,            // Lich's Tomb — ghostly/hellish violet-crimson embers.
  cosmicRift,          // Past Slayer — cosmic temporal starry drift.
}

/// Animated avatar-border treatment. Painted by `AvatarAura` around
/// any character portrait so each theme has a distinct "aura" the user
/// can recognise from across the room.
enum AvatarAuraStyle {
  /// No aura — Minimalist's stillness signature.
  none,

  /// Coolmaxing: rotating chrome-gold shimmer ring with a magenta kicker.
  goldShimmerRing,

  /// Unicorn: dual pink/mint pulsing halo that breathes in and out.
  pastelPulse,

  /// Curseblaster: pulsing oxblood breathing ring with a darker rim.
  oxbloodBreath,

  /// Winchester: slowly rotating brass conic ring, double hairline.
  brassConic,

  /// Ice Tyrant: pulsing frost-blue ring with white frost particles.
  frostRing,

  /// Pitch Black: faint white breathing ring, barely visible.
  voidPulse,

  /// Oubliette: bubbling green toxic ooze border with dark rim.
  toxicOoze,

  /// Forge Master: glowing molten orange-red and yellow ring with spark particles.
  forgeGlow,

  /// Lich's Tomb: vortex of pulsing hellish violet-magenta fire.
  lichPurple,

  /// Past Slayer: rotating celestial rings of neon cyan and gold sparkles.
  cosmicTemporal,
}

extension AppThemeModeLabel on AppThemeMode {
  String get label {
    switch (this) {
      case AppThemeMode.cosmicWhirlwind:
        return 'Cosmic Whirlwind';
      case AppThemeMode.unicorn:
        return 'Unicorn Bubblegum';
      case AppThemeMode.curseblaster:
        return 'Curseblaster';
      case AppThemeMode.winchester:
        return 'Winchester';
      case AppThemeMode.frogCute:
        return 'Lilypad Hop';
      case AppThemeMode.iceTyrant:
        return 'Ice Tyrant';
      case AppThemeMode.charm:
        return 'Sweetheart Synergies';
      case AppThemeMode.midnightHunter:
        return 'Midnight Hunter';
      case AppThemeMode.voidDimension:
        return 'Void Dimension';
      case AppThemeMode.firestorm:
        return 'Firestorm';
      case AppThemeMode.theBreach:
        return 'The Breach';
      case AppThemeMode.custom:
        return AppTheme._customThemeName;
    }
  }

  String get tagline {
    switch (this) {
      case AppThemeMode.cosmicWhirlwind:
        return 'Vortex — swirly gradients, changing vistas, popping numbers';
      case AppThemeMode.unicorn:
        return 'Cotton Candy — lavender, pink, twinkle';
      case AppThemeMode.curseblaster:
        return 'Blood Moon — oxblood, bone, red glow';
      case AppThemeMode.winchester:
        return 'Saloon — gold rush cowboy, whiskey barrel, sheriff stars';
      case AppThemeMode.frogCute:
        return 'Pond Water — cute frogs, leaf greens, water lilies';
      case AppThemeMode.iceTyrant:
        return 'Frozen Throne — ice, cyan, frost';
      case AppThemeMode.charm:
        return 'Cupid — red & pink, sweetheart charms, arrow hearts';
      case AppThemeMode.midnightHunter:
        return 'Dark Woods — deep forest blue, hunting wood, campfires';
      case AppThemeMode.voidDimension:
        return 'Warped — weird & wobbly purples, violet nebulas, stellar teal';
      case AppThemeMode.firestorm:
        return 'Molten Ash — blazing orange, gunpowder skulls, amber sparks';
      case AppThemeMode.theBreach:
        return 'Ancient Temple — forgotten stone grey, gold, crumbling pillars';
      case AppThemeMode.custom:
        return 'Custom — your personal palette';
    }
  }
}

/// Data model for custom theme settings persisted to SharedPreferences.
/// Allows users to create their own color palette with optional backdrop/aura/font.
class CustomThemeData {
  final String name;
  final Color scaffold;
  final Color card;
  final Color primary;
  final Color secondary;
  final Color headlineStat;
  final Color bulletColor;
  final ThemeBackdrop backdrop;
  final AvatarAuraStyle auraStyle;
  final AppFont font;

  const CustomThemeData({
    required this.name,
    required this.scaffold,
    required this.card,
    required this.primary,
    required this.secondary,
    required this.headlineStat,
    required this.bulletColor,
    this.backdrop = ThemeBackdrop.none,
    this.auraStyle = AvatarAuraStyle.none,
    this.font = AppFont.gungeon,
  });

  static const String _prefsKey = 'custom.theme.data';

  /// Check if a custom theme has been saved.
  static Future<bool> hasSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_prefsKey);
    } catch (_) {
      return false;
    }
  }

  /// Delete the saved custom theme from disk.
  static Future<void> delete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }

  /// Async load for actual usage in flairFor()
  static Future<CustomThemeData> loadAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefsKey);
      if (jsonStr != null) {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        return CustomThemeData(
          name: json['name'] as String? ?? 'Custom',
          scaffold: Color(json['scaffold'] as int),
          card: Color(json['card'] as int),
          primary: Color(json['primary'] as int),
          secondary: Color(json['secondary'] as int),
          headlineStat: Color(json['headlineStat'] as int),
          bulletColor: Color(json['bulletColor'] as int),
          backdrop: ThemeBackdrop.values[json['backdrop'] as int? ?? 0],
          auraStyle: AvatarAuraStyle.values[json['auraStyle'] as int? ?? 0],
          font: AppFont.values[json['font'] as int? ?? 0], // Default to Gungeon (index 0)
        );
      }
    } catch (_) {}
    return defaultTheme;
  }

  /// Save custom theme to disk.
  static Future<void> save(CustomThemeData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode({
        'name': data.name,
        'scaffold': data.scaffold.value,
        'card': data.card.value,
        'primary': data.primary.value,
        'secondary': data.secondary.value,
        'headlineStat': data.headlineStat.value,
        'bulletColor': data.bulletColor.value,
        'backdrop': data.backdrop.index,
        'auraStyle': data.auraStyle.index,
        'font': data.font.index,
      });
      await prefs.setString(_prefsKey, json);
    } catch (_) {}
  }

  /// Default custom theme (fallback).
  static const CustomThemeData defaultTheme = CustomThemeData(
    name: 'Custom',
    scaffold: Color(0xFF1A1A1A),
    card: Color(0xFF252525),
    primary: Color(0xFF4CAF50),
    secondary: Color(0xFF2196F3),
    headlineStat: Color(0xFF4CAF50),
    bulletColor: Color(0xFF4CAF50),
    backdrop: ThemeBackdrop.none,
    auraStyle: AvatarAuraStyle.none,
    font: AppFont.gungeon,
  );

  /// Generate a random custom theme with a lore-style name.
  static CustomThemeData random() {
    final rng = math.Random();
    final nameGen = _RandomNameGenerator(rng);
    final colorGen = _RandomColorGenerator(rng);
    return CustomThemeData(
      name: nameGen.generate(),
      scaffold: colorGen.dark(),
      card: colorGen.medium(),
      primary: colorGen.bright(),
      secondary: colorGen.bright(),
      headlineStat: colorGen.bright(),
      bulletColor: colorGen.bright(),
      backdrop: ThemeBackdrop.values[rng.nextInt(ThemeBackdrop.values.length)],
      auraStyle: AvatarAuraStyle.values[rng.nextInt(AvatarAuraStyle.values.length)],
      font: AppFont.values[rng.nextInt(AppFont.values.length)],
    );
  }

  CustomThemeData copyWith({
    String? name,
    Color? scaffold,
    Color? card,
    Color? primary,
    Color? secondary,
    Color? headlineStat,
    Color? bulletColor,
    ThemeBackdrop? backdrop,
    AvatarAuraStyle? auraStyle,
    AppFont? font,
  }) {
    return CustomThemeData(
      name: name ?? this.name,
      scaffold: scaffold ?? this.scaffold,
      card: card ?? this.card,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      headlineStat: headlineStat ?? this.headlineStat,
      bulletColor: bulletColor ?? this.bulletColor,
      backdrop: backdrop ?? this.backdrop,
      auraStyle: auraStyle ?? this.auraStyle,
      font: font ?? this.font,
    );
  }
}

/// Helper for generating lore-style random theme names.
class _RandomNameGenerator {
  static const _prefixes = [
    'Crimson', 'Void', 'Neon', 'Shadow', 'Frost', 'Ember',
    'Toxic', 'Golden', 'Azure', 'Obsidian', 'Solar', 'Lunar',
    'Phantom', 'Spectral', 'Ethereal', 'Radiant', 'Gloom', 'Blaze',
  ];
  static const _suffixes = [
    'Fury', 'Dream', 'Walker', 'Stalker', 'Wraith', 'Specter',
    'Blade', 'Storm', 'Flux', 'Surge', 'Pulse', 'Echo',
    'Reverie', 'Cascade', 'Overture', 'Symphony', 'Paradox', 'Zenith',
  ];

  final math.Random _rng;

  _RandomNameGenerator(this._rng);

  String generate() {
    final prefix = _prefixes[_rng.nextInt(_prefixes.length)];
    final suffix = _suffixes[_rng.nextInt(_suffixes.length)];
    return '$prefix $suffix';
  }
}

/// Helper for generating random harmonious colors.
class _RandomColorGenerator {
  final math.Random _rng;

  _RandomColorGenerator(this._rng);

  Color dark() {
    final hue = _rng.nextInt(360);
    final saturation = 0.3 + _rng.nextDouble() * 0.4; // 0.3-0.7
    final value = 0.1 + _rng.nextDouble() * 0.2; // 0.1-0.3
    return HSVColor.fromAHSV(1.0, hue.toDouble(), saturation, value).toColor();
  }

  Color medium() {
    final hue = _rng.nextInt(360);
    final saturation = 0.4 + _rng.nextDouble() * 0.4; // 0.4-0.8
    final value = 0.3 + _rng.nextDouble() * 0.3; // 0.3-0.6
    return HSVColor.fromAHSV(1.0, hue.toDouble(), saturation, value).toColor();
  }

  Color bright() {
    final hue = _rng.nextInt(360);
    final saturation = 0.6 + _rng.nextDouble() * 0.4; // 0.6-1.0
    final value = 0.7 + _rng.nextDouble() * 0.3; // 0.7-1.0
    return HSVColor.fromAHSV(1.0, hue.toDouble(), saturation, value).toColor();
  }
}

/// Extra per-theme styling knobs beyond [ColorScheme]. Read via
/// `AppTheme.flair` from any widget that wants theme-aware numeric
/// typography, chip shape, bullet glyph or quirk flags.
class ThemeFlair {
  final Color scaffold;
  final Color card;
  final Color primary;
  final Color secondary;

  /// Colour applied to big "headline" numbers (DPS, Coolness, Curse).
  /// Kept separate from primary so Unicorn's pink stat doesn't clash
  /// with a pink card border.
  final Color headlineStat;

  /// Default colour for list bullet glyphs (used by [bulletGlyph]).
  final Color bulletColor;

  /// The glyph rendered in front of list items in themed contexts
  /// (e.g. `•`, `✦`, `—`, `·`).
  final String bulletGlyph;

  /// Whether a gold shimmer should sweep across themed headline
  /// numbers periodically (Coolmaxing signature).
  final bool shimmerHeadline;

  /// Whether ✦ bullets should pulse opacity (Unicorn signature).
  final bool twinkleBullets;

  /// Whether the curse headline number should glow red, with glow
  /// intensity scaling with curse value (Curseblaster signature).
  final bool glowCurse;

  /// Whether headline numbers render with an embossed drop-shadow
  /// treatment (Winchester signature).
  final bool embossNumbers;

  /// Use `FontFeature.tabularFigures` so digit columns align — used by
  /// every theme except Unicorn (which prefers a softer proportional
  /// look to match the rounded display vibe).
  final bool tabularFigures;

  /// Size multiplier applied to themed headline numbers.
  final double numberSizeScale;

  /// Font weight applied to themed headline numbers.
  final FontWeight numberWeight;

  /// Italic slant for themed numbers (Unicorn leans a touch).
  final FontStyle numberStyle;

  /// Corner radius for themed chips (0–20).
  final double chipRadius;

  /// Corner radius for themed cards (0–30).
  final double cardRadius;

  /// Custom border color for cards (e.g. for winchester, minimalist).
  final Color? cardBorderColor;

  /// Custom border thickness for cards.
  final double cardBorderWidth;

  /// Whether themed chips render as filled pills (true) or just outline
  /// + underlined label (false — Minimalist Paper).
  final bool chipFilled;

  /// Divider colour for themed dividers/borders. Falls back to the
  /// Material default when null.
  final Color? dividerColor;

  /// Divider thickness for themed dividers/borders. 1.0 for hairline
  /// minimalist, up to ~1.4 for brass Winchester.
  final double dividerThickness;

  /// Ambient overlay painted by `ThemeOverlay`. Defaults to none so
  /// adding a new theme costs nothing until you opt in.
  final ThemeBackdrop backdrop;

  /// Tinted glow tones used by the always-on `_AmbientGlow` layer the
  /// overlay paints behind every theme (Bubblegum-style soft radial
  /// gradient that drifts gently). Picked per-theme so the glow reads
  /// as part of the palette rather than a generic pink wash.
  final Color glowPrimary;
  final Color glowSecondary;

  /// Animated border treatment for character avatars (see
  /// `widgets/avatar_aura.dart`). Defaults to `none` — opt in per
  /// theme so the picker preview can stay clean.
  final AvatarAuraStyle auraStyle;

  /// Optional glyph rendered in front of section titles (Effects,
  /// Notes, Synergies, Referenced By). Replaces the Material icon when
  /// non-null. Each theme picks a glyph that fits its identity:
  /// Coolmaxing ❖, Unicorn ♡, Curseblaster †, Winchester ★.
  final String? headerGlyph;

  /// Render section titles in ALL CAPS with extra letter-spacing and
  /// drop the leading icon. Minimalist signature.
  final bool headerAllCaps;

  /// Optional hairline rule painted directly underneath section titles.
  /// Per-theme accent so each detail page is recognisably "the gold
  /// theme" / "the blood theme" / "the brass theme" at a glance.
  final Color? headerUnderlineColor;

  /// Paint a 1px hairline frame around the viewport. Minimalist's
  /// "printed page" signature — every other theme leaves this false.
  final bool pageFrame;

  const ThemeFlair({
    required this.scaffold,
    required this.card,
    required this.primary,
    required this.secondary,
    required this.headlineStat,
    required this.bulletColor,
    this.bulletGlyph = '•',
    this.shimmerHeadline = false,
    this.twinkleBullets = false,
    this.glowCurse = false,
    this.embossNumbers = false,
    this.tabularFigures = true,
    this.numberSizeScale = 1.0,
    this.numberWeight = FontWeight.w700,
    this.numberStyle = FontStyle.normal,
    this.chipRadius = 10,
    this.cardRadius = 12,
    this.cardBorderColor,
    this.cardBorderWidth = 1.0,
    this.chipFilled = true,
    this.dividerColor,
    this.dividerThickness = 1.0,
    this.backdrop = ThemeBackdrop.none,
    this.glowPrimary = const Color(0x22FFFFFF),
    this.glowSecondary = const Color(0x11FFFFFF),
    this.auraStyle = AvatarAuraStyle.none,
    this.headerGlyph,
    this.headerAllCaps = false,
    this.headerUnderlineColor,
    this.pageFrame = false,
  });
}

// =============================================================================
// VisualPrefs — user-controlled overlay effects, independent of palette
// =============================================================================

enum CustomParticleType {
  themeDefault,
  ember,
  frost,
  catpaw,
  rainbow,
  curse,
  vvoid,
  gunfairy,
}

extension CustomParticleTypeLabel on CustomParticleType {
  String get label {
    switch (this) {
      case CustomParticleType.themeDefault:
        return 'Theme Default';
      case CustomParticleType.ember:
        return 'Ember (Fire)';
      case CustomParticleType.frost:
        return 'Frost (Ice)';
      case CustomParticleType.catpaw:
        return 'Cat Paw (Cute)';
      case CustomParticleType.rainbow:
        return 'Rainbow (Prismatic)';
      case CustomParticleType.curse:
        return 'Curse (Purple)';
      case CustomParticleType.vvoid:
        return 'Void (Dark)';
      case CustomParticleType.gunfairy:
        return 'Gun Fairy (🧚)';
    }
  }
}

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
class VisualPrefs {
  /// Background glow intensity: 0.0 = off, 1.0 = full theme glow.
  /// Defaults to 0.0 — the out-of-box look is clean and unaffected.
  final double glowIntensity;

  /// Whether theme-specific particle/backdrop animations are shown.
  final bool particlesEnabled;

  /// Handcrafted particle effects toggles
  final bool particleRotation;
  final bool gravityVortex;
  final bool advancedFlicker;

  /// Font-weight bias applied globally on top of the active theme.
  /// Adjusted in increments of 100 (e.g. -400 to +500). Stored as an integer.
  final int fontWeightBias;

  /// Selected app-wide font. Defaults to Gungeon so the OOB look is
  /// recognisable to fans.
  final AppFont font;

  /// User-selected base font size (pt). Discrete steps for crisp UX.
  final double fontSize;

  /// Font size for inventory tiles specifically. Let users scale it independently.
  final double inventoryFontSize;

  /// Custom Particle Settings
  final CustomParticleType customParticleType;
  final CustomDiceType customDiceType;
  final bool emitFromTop;
  final bool emitFromBottom;
  final bool emitFromLeft;
  final bool emitFromRight;
  final double particleSizeScale;
  final double particleOpacity;
  final int particleCount;

  /// Hypnotic Background settings
  final bool hypnoticBgEnabled;
  final String hypnoticBgAsset;
  final double hypnoticBgSpeed;
  final double hypnoticBgOpacity;

  /// Dialogue Settings
  final bool dialogueHapticsEnabled;
  final int dialogueTextSpeedMs;

  /// Computed scale factor applied globally via MediaQuery.
  double get textScaleFactor => fontSize / 14.0;

  /// Discrete font-size steps the UI presents as chips.
  static const fontSizeSteps = [
    6.0, 8.0, 10.0, 12.0, 14.0, 18.0, 20.0, 24.0, 28.0, 32.0,
  ];

  const VisualPrefs({
    this.glowIntensity = 0.0,
    this.particlesEnabled = true,
    this.particleRotation = true,
    this.gravityVortex = true,
    this.advancedFlicker = true,
    this.fontWeightBias = 0,
    this.font = AppFont.gungeon,
    this.fontSize = 12.0,
    this.inventoryFontSize = 12.0,
    this.customParticleType = CustomParticleType.themeDefault,
    this.customDiceType = CustomDiceType.themeDefault,
    this.emitFromTop = true,
    this.emitFromBottom = true,
    this.emitFromLeft = false,
    this.emitFromRight = false,
    this.particleSizeScale = 1.0,
    this.particleOpacity = 1.0,
    this.particleCount = 35,
    this.hypnoticBgEnabled = false,
    this.hypnoticBgAsset = "circles05.gif",
    this.hypnoticBgSpeed = 1.0,
    this.hypnoticBgOpacity = 0.3,
    this.dialogueHapticsEnabled = true,
    this.dialogueTextSpeedMs = 30,
  });

  static const _kGlow     = 'vp.glow_v1';
  static const _kParticles = 'vp.particles_v1';
  static const _kRot      = 'vp.rot_v1';
  static const _kVortex   = 'vp.vortex_v1';
  static const _kFlicker  = 'vp.flicker_v1';
  static const _kWeight   = 'vp.weight_v1';
  static const _kFont     = 'vp.font_v1';
  static const _kFontSize = 'vp.font_size_v1';
  static const _kInventoryFontSize = 'vp.inventory_font_size_v1';
  static const _kScaleLegacy = 'vp.scale_v1'; // migrated to _kFontSize

  static const _kCustomParticleType = 'vp.custom_particle_type_v2';
  static const _kCustomDiceType = 'vp.custom_dice_type_v1';
  static const _kEmitFromTop = 'vp.emit_from_top_v2';
  static const _kEmitFromBottom = 'vp.emit_from_bottom_v2';
  static const _kEmitFromLeft = 'vp.emit_from_left_v2';
  static const _kEmitFromRight = 'vp.emit_from_right_v2';
  static const _kParticleSizeScale = 'vp.particle_size_scale_v2';
  static const _kParticleOpacity = 'vp.particle_opacity_v1';
  static const _kParticleCount = 'vp.particle_count_v1';

  static const _kHypnoticEnabled = 'vp.hypnotic_enabled_v1';
  static const _kHypnoticAsset   = 'vp.hypnotic_asset_v1';
  static const _kHypnoticSpeed   = 'vp.hypnotic_speed_v1';
  static const _kHypnoticOpacity = 'vp.hypnotic_opacity_v1';
  static const _kDialogueHaptics = 'vp.dialogue_haptics_v1';
  static const _kDialogueTextSpeed = 'vp.dialogue_text_speed_v1';

  static final ValueNotifier<VisualPrefs> notifier =
      ValueNotifier(const VisualPrefs());

  /// Hydrate from disk. Call from `main()` before `runApp`.
  static double _snapToStep(double v) {
    return fontSizeSteps.reduce((a, b) =>
        (v - a).abs() < (v - b).abs() ? a : b);
  }

  static Future<void> init() async {
    try {
      final p = await SharedPreferences.getInstance();
      final fontIdx = p.getInt(_kFont);
      final font = (fontIdx != null && fontIdx >= 0 &&
              fontIdx < AppFont.values.length)
          ? AppFont.values[fontIdx]
          : AppFont.gungeon;

      // Migrate from old scale key if present.
      double fontSize;
      final savedSize = p.getDouble(_kFontSize);
      if (savedSize != null) {
        fontSize = _snapToStep(savedSize.clamp(6.0, 32.0));
      } else {
        final legacyScale = p.getDouble(_kScaleLegacy);
        if (legacyScale != null) {
          fontSize = _snapToStep((legacyScale * 14.0).clamp(6.0, 32.0));
          // Best-effort cleanup of legacy key.
          unawaited(p.remove(_kScaleLegacy));
          unawaited(p.setDouble(_kFontSize, fontSize));
        } else {
          fontSize = 14.0;
        }
      }

      final customParticleTypeIdx = p.getInt(_kCustomParticleType) ?? 0;
      final customParticleType = CustomParticleType.values[customParticleTypeIdx.clamp(0, CustomParticleType.values.length - 1)];

      final customDiceTypeIdx = p.getInt(_kCustomDiceType) ?? 0;
      final customDiceType = CustomDiceType.values[customDiceTypeIdx.clamp(0, CustomDiceType.values.length - 1)];

      final inventoryFontSize = p.getDouble(_kInventoryFontSize) ?? 12.0;

      notifier.value = VisualPrefs(
        glowIntensity:    p.getDouble(_kGlow)     ?? 0.0,
        particlesEnabled: p.getBool(_kParticles)  ?? true,
        particleRotation: p.getBool(_kRot)        ?? true,
        gravityVortex:    p.getBool(_kVortex)     ?? true,
        advancedFlicker:  p.getBool(_kFlicker)    ?? true,
        fontWeightBias:   p.getInt(_kWeight)      ?? 0,
        font:             font,
        fontSize:         fontSize,
        inventoryFontSize: inventoryFontSize,
        customParticleType: customParticleType,
        customDiceType:   customDiceType,
        emitFromTop:      p.getBool(_kEmitFromTop)    ?? true,
        emitFromBottom:   p.getBool(_kEmitFromBottom) ?? true,
        emitFromLeft:     p.getBool(_kEmitFromLeft)   ?? false,
        emitFromRight:    p.getBool(_kEmitFromRight)  ?? false,
        particleSizeScale: p.getDouble(_kParticleSizeScale) ?? 1.0,
        particleOpacity:   p.getDouble(_kParticleOpacity) ?? 1.0,
        particleCount:     p.getInt(_kParticleCount) ?? 35,
        hypnoticBgEnabled: p.getBool(_kHypnoticEnabled) ?? false,
        hypnoticBgAsset:   p.getString(_kHypnoticAsset) ?? "circles05.gif",
        hypnoticBgSpeed:   p.getDouble(_kHypnoticSpeed) ?? 1.0,
        hypnoticBgOpacity: p.getDouble(_kHypnoticOpacity) ?? 0.3,
        dialogueHapticsEnabled: p.getBool(_kDialogueHaptics) ?? true,
        dialogueTextSpeedMs: p.getInt(_kDialogueTextSpeed) ?? 30,
      );
    } catch (_) {}
  }

  static Future<void> setGlow(double v) async {
    notifier.value = notifier.value._with(glowIntensity: v.clamp(0.0, 1.0));
    _persist();
  }

  static Future<void> setParticles(bool v) async {
    notifier.value = notifier.value._with(particlesEnabled: v);
    _persist();
  }

  static Future<void> setParticleRotation(bool v) async {
    notifier.value = notifier.value._with(particleRotation: v);
    _persist();
  }

  static Future<void> setGravityVortex(bool v) async {
    notifier.value = notifier.value._with(gravityVortex: v);
    _persist();
  }

  static Future<void> setAdvancedFlicker(bool v) async {
    notifier.value = notifier.value._with(advancedFlicker: v);
    _persist();
  }

  static Future<void> setFontWeightBias(int v) async {
    notifier.value = notifier.value._with(fontWeightBias: v.clamp(-800, 800));
    _persist();
  }

  static Future<void> setFont(AppFont f) async {
    notifier.value = notifier.value._with(font: f);
    _persist();
  }

  static Future<void> setFontSize(double v) async {
    final clamped = v.clamp(6.0, 32.0);
    notifier.value = notifier.value._with(fontSize: clamped);
    _persist();
  }

  static Future<void> setInventoryFontSize(double v) async {
    final clamped = v.clamp(10.0, 18.0);
    notifier.value = notifier.value._with(inventoryFontSize: clamped);
    _persist();
  }

  static Future<void> setCustomParticleType(CustomParticleType type) async {
    notifier.value = notifier.value._with(customParticleType: type);
    _persist();
  }

  static Future<void> setEmitters({
    bool? top,
    bool? bottom,
    bool? left,
    bool? right,
  }) async {
    notifier.value = notifier.value._with(
      emitFromTop: top ?? notifier.value.emitFromTop,
      emitFromBottom: bottom ?? notifier.value.emitFromBottom,
      emitFromLeft: left ?? notifier.value.emitFromLeft,
      emitFromRight: right ?? notifier.value.emitFromRight,
    );
    _persist();
  }

  static Future<void> setParticleSizeScale(double v) async {
    notifier.value = notifier.value._with(particleSizeScale: v.clamp(0.5, 3.0));
    _persist();
  }

  static Future<void> setParticleOpacity(double v) async {
    notifier.value = notifier.value._with(particleOpacity: v.clamp(0.0, 1.0));
    _persist();
  }

  static Future<void> setParticleCount(int v) async {
    notifier.value = notifier.value._with(particleCount: v.clamp(5, 120));
    _persist();
  }

  static Future<void> setCustomDiceType(CustomDiceType type) async {
    notifier.value = notifier.value._with(customDiceType: type);
    _persist();
  }

  static Future<void> setHypnoticBgEnabled(bool v) async {
    notifier.value = notifier.value._with(hypnoticBgEnabled: v);
    _persist();
  }

  static Future<void> setHypnoticBgAsset(String asset) async {
    notifier.value = notifier.value._with(hypnoticBgAsset: asset);
    _persist();
  }

  static Future<void> setHypnoticBgSpeed(double v) async {
    notifier.value = notifier.value._with(hypnoticBgSpeed: v.clamp(0.1, 4.0));
    _persist();
  }

  static Future<void> setHypnoticBgOpacity(double v) async {
    notifier.value = notifier.value._with(hypnoticBgOpacity: v.clamp(0.0, 1.0));
    _persist();
  }

  static Future<void> setDialogueHapticsEnabled(bool v) async {
    notifier.value = notifier.value._with(dialogueHapticsEnabled: v);
    _persist();
  }

  static Future<void> setDialogueTextSpeedMs(int v) async {
    notifier.value = notifier.value._with(dialogueTextSpeedMs: v);
    _persist();
  }

  static Future<void> _persist() async {
    try {
      final p = await SharedPreferences.getInstance();
      final v = notifier.value;
      await p.setDouble(_kGlow,     v.glowIntensity);
      await p.setBool(_kParticles,  v.particlesEnabled);
      await p.setBool(_kRot,        v.particleRotation);
      await p.setBool(_kVortex,     v.gravityVortex);
      await p.setBool(_kFlicker,    v.advancedFlicker);
      await p.setInt(_kWeight,      v.fontWeightBias);
      await p.setInt(_kFont,        v.font.index);
      await p.setDouble(_kFontSize,  v.fontSize);
      await p.setDouble(_kInventoryFontSize, v.inventoryFontSize);

      await p.setInt(_kCustomParticleType, v.customParticleType.index);
      await p.setInt(_kCustomDiceType, v.customDiceType.index);
      await p.setBool(_kEmitFromTop, v.emitFromTop);
      await p.setBool(_kEmitFromBottom, v.emitFromBottom);
      await p.setBool(_kEmitFromLeft, v.emitFromLeft);
      await p.setBool(_kEmitFromRight, v.emitFromRight);
      await p.setDouble(_kParticleSizeScale, v.particleSizeScale);
      await p.setDouble(_kParticleOpacity, v.particleOpacity);
      await p.setInt(_kParticleCount, v.particleCount);
      await p.setBool(_kHypnoticEnabled, v.hypnoticBgEnabled);
      await p.setString(_kHypnoticAsset, v.hypnoticBgAsset);
      await p.setDouble(_kHypnoticSpeed, v.hypnoticBgSpeed);
      await p.setDouble(_kHypnoticOpacity, v.hypnoticBgOpacity);
      await p.setBool(_kDialogueHaptics, v.dialogueHapticsEnabled);
      await p.setInt(_kDialogueTextSpeed, v.dialogueTextSpeedMs);
    } catch (_) {}
  }

  VisualPrefs _with({
    double? glowIntensity,
    bool?   particlesEnabled,
    bool?   particleRotation,
    bool?   gravityVortex,
    bool?   advancedFlicker,
    int?    fontWeightBias,
    AppFont? font,
    double? fontSize,
    double? inventoryFontSize,
    CustomParticleType? customParticleType,
    CustomDiceType? customDiceType,
    bool?   emitFromTop,
    bool?   emitFromBottom,
    bool?   emitFromLeft,
    bool?   emitFromRight,
    double? particleSizeScale,
    double? particleOpacity,
    int?    particleCount,
    bool?   hypnoticBgEnabled,
    String? hypnoticBgAsset,
    double? hypnoticBgSpeed,
    double? hypnoticBgOpacity,
    bool?   dialogueHapticsEnabled,
    int?    dialogueTextSpeedMs,
  }) => VisualPrefs(
    glowIntensity:    glowIntensity    ?? this.glowIntensity,
    particlesEnabled: particlesEnabled ?? this.particlesEnabled,
    particleRotation: particleRotation ?? this.particleRotation,
    gravityVortex:    gravityVortex    ?? this.gravityVortex,
    advancedFlicker:  advancedFlicker  ?? this.advancedFlicker,
    fontWeightBias:   fontWeightBias   ?? this.fontWeightBias,
    font:             font             ?? this.font,
    fontSize:         fontSize         ?? this.fontSize,
    inventoryFontSize: inventoryFontSize ?? this.inventoryFontSize,
    customParticleType: customParticleType ?? this.customParticleType,
    customDiceType:   customDiceType   ?? this.customDiceType,
    emitFromTop:      emitFromTop      ?? this.emitFromTop,
    emitFromBottom:   emitFromBottom   ?? this.emitFromBottom,
    emitFromLeft:     emitFromLeft     ?? this.emitFromLeft,
    emitFromRight:    emitFromRight    ?? this.emitFromRight,
    particleSizeScale: particleSizeScale ?? this.particleSizeScale,
    particleOpacity:   particleOpacity   ?? this.particleOpacity,
    particleCount:     particleCount     ?? this.particleCount,
    hypnoticBgEnabled: hypnoticBgEnabled ?? this.hypnoticBgEnabled,
    hypnoticBgAsset:   hypnoticBgAsset   ?? this.hypnoticBgAsset,
    hypnoticBgSpeed:   hypnoticBgSpeed   ?? this.hypnoticBgSpeed,
    hypnoticBgOpacity: hypnoticBgOpacity ?? this.hypnoticBgOpacity,
    dialogueHapticsEnabled: dialogueHapticsEnabled ?? this.dialogueHapticsEnabled,
    dialogueTextSpeedMs: dialogueTextSpeedMs ?? this.dialogueTextSpeedMs,
  );
}

/// Static holder for the live [AppThemeMode]. Mutated via [setMode] and
/// rebroadcast through [notifier] so the root [MaterialApp] rebuilds
/// with the new palette + every descendant picks up the new flair.
class AppTheme {
  const AppTheme._();

  static const String _prefsKey = 'theme.mode.v2';
  // Old key from the 4-mode era. Migrated on first run then cleared so
  // returning users don't get parked on an invalid index.
  static const String _legacyKey = 'theme.mode';

  static final ValueNotifier<AppThemeMode> notifier =
      ValueNotifier<AppThemeMode>(AppThemeMode.frogCute);

  static AppThemeMode get mode => notifier.value;
  static ThemeFlair get flair => flairFor(notifier.value);

  /// Cached custom theme name for synchronous label access.
  static String _customThemeName = 'Custom';

  /// Cached custom theme data for synchronous flair access.
  static CustomThemeData? _cachedCustomTheme;

  /// Update the cached custom theme name (call when saving custom theme).
  static void setCustomThemeName(String name) {
    _customThemeName = name;
  }

  /// Update the cached custom theme data (call when saving custom theme).
  static void setCustomThemeData(CustomThemeData data) {
    _cachedCustomTheme = data;
    _customThemeName = data.name;
  }

  /// Hydrate [mode] from disk. Call once from `main()` before `runApp`.
  /// If the persisted theme is no longer in [kVisibleThemes] (e.g. one
  /// of the removed lore themes from older releases) we silently
  /// migrate the user onto the first visible theme so they don't get
  /// stranded on a now-hidden palette.
  static Future<void> init() async {
    notifier.value = kVisibleThemes.first;
    try {
      final prefs = await SharedPreferences.getInstance();
      final idx = prefs.getInt(_prefsKey);
      if (idx != null && idx >= 0 && idx < AppThemeMode.values.length) {
        final m = AppThemeMode.values[idx];
        if (kVisibleThemes.contains(m)) {
          notifier.value = m;
        } else {
          // Persisted theme was removed — migrate to default and write
          // it back so the picker shows the right active card.
          notifier.value = kVisibleThemes.first;
          await prefs.setInt(_prefsKey, kVisibleThemes.first.index);
        }
        return;
      }
      // Old legacy 4-mode index. Anything other than "marine" maps to
      // the new default; marine was the cleanest equivalent of
      // Minimalist.
      final legacyIdx = prefs.getInt(_legacyKey);
      if (legacyIdx != null) {
        notifier.value = kVisibleThemes.first;
        await prefs.setInt(_prefsKey, kVisibleThemes.first.index);
        await prefs.remove(_legacyKey);
      }
    } catch (_) {
      // Keep default on any persistence failure.
    }
  }

  /// Persist + apply the picked theme.
  static Future<void> setMode(AppThemeMode m) async {
    notifier.value = m;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKey, m.index);
    } catch (_) {
      // Persistence failure is non-fatal.
    }
  }

  /// Shift every FontWeight in [base] by [bias] × 3 index steps.
  static TextTheme _applyWeightBias(TextTheme base, int bias) {
    if (bias == 0) return base;
    TextStyle? shift(TextStyle? s) {
      if (s == null) return null;
      final w = s.fontWeight ?? FontWeight.w400;
      final idx = (w.index + bias * 3).clamp(0, 8);
      return s.copyWith(fontWeight: FontWeight.values[idx]);
    }
    return base.copyWith(
      displayLarge:   shift(base.displayLarge),
      displayMedium:  shift(base.displayMedium),
      displaySmall:   shift(base.displaySmall),
      headlineLarge:  shift(base.headlineLarge),
      headlineMedium: shift(base.headlineMedium),
      headlineSmall:  shift(base.headlineSmall),
      titleLarge:     shift(base.titleLarge),
      titleMedium:    shift(base.titleMedium),
      titleSmall:     shift(base.titleSmall),
      bodyLarge:      shift(base.bodyLarge),
      bodyMedium:     shift(base.bodyMedium),
      bodySmall:      shift(base.bodySmall),
      labelLarge:     shift(base.labelLarge),
      labelMedium:    shift(base.labelMedium),
      labelSmall:     shift(base.labelSmall),
    );
  }

  /// Build the concrete [ThemeData] for the given [mode]. Surfaces,
  /// card radius and primary/secondary are pulled from [flairFor] so
  /// the MaterialApp palette and the custom widgets stay in lock-step.
  static ThemeData themeFor(AppThemeMode m) {
    final f = flairFor(m);
    final prefs = VisualPrefs.notifier.value;
    final bias = prefs.fontWeightBias;
    var textTheme = m == AppThemeMode.custom && _cachedCustomTheme != null
        ? _cachedCustomTheme!.font.textTheme
        : prefs.font.textTheme;
    textTheme = _applyWeightBias(textTheme, bias);
    
    return ThemeData(
      colorScheme: ColorScheme.dark(
        primary: f.primary,
        secondary: f.secondary,
        surface: f.card,
        onSurface: Colors.white,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: f.scaffold,
      cardColor: f.card,
      textTheme: textTheme,
      // Ensure the font is also applied to the primary text theme
      primaryTextTheme: textTheme,
      cardTheme: CardThemeData(
        color: f.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(f.cardRadius),
          side: f.cardBorderColor != null
              ? BorderSide(color: f.cardBorderColor!, width: f.cardBorderWidth)
              : BorderSide.none,
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: f.dividerColor,
        thickness: f.dividerThickness,
      ),
    );
  }

  /// Concrete flair for each theme. Kept in one place so the picker
  /// preview and the live app read the exact same values.
  static ThemeFlair flairFor(AppThemeMode m) {
    switch (m) {
      case AppThemeMode.cosmicWhirlwind:
        return const ThemeFlair(
          scaffold: Color(0xFF040209), // deep space temporal abyss
          card: Color(0xFF140B24), // swirling purple nebulas
          primary: Color(0xFFE040FB), // glowing neon magenta-purple
          secondary: Color(0xFF00E5FF), // glowing stellar cyan
          headlineStat: Color(0xFFFFFF00), // supernova sun yellow
          bulletColor: Color(0xFF00E5FF),
          bulletGlyph: '🌀', // swirly vortex
          shimmerHeadline: true,
          tabularFigures: true,
          numberSizeScale: 1.12,
          numberWeight: FontWeight.w900,
          chipRadius: 10,
          cardRadius: 12,
          cardBorderColor: Color(0x7700E5FF), // stardust cyan neon border
          cardBorderWidth: 1.5,
          dividerColor: Color(0x66E040FB),
          dividerThickness: 1.2,
          backdrop: ThemeBackdrop.cosmicRift,
          glowPrimary: Color(0x44E040FB),
          glowSecondary: Color(0x2200E5FF),
          auraStyle: AvatarAuraStyle.cosmicTemporal,
          headerGlyph: '🌀',
          headerUnderlineColor: Color(0xAAE040FB),
        );
      case AppThemeMode.unicorn:
        return const ThemeFlair(
          scaffold: Color(0xFF2A1F3A),
          card: Color(0xFF362A4A),
          primary: Color(0xFFFF5DA8), // bolder bubblegum (was #FF7EB4)
          secondary: Color(0xFF5BE8B8), // bolder mint (was #7FE8C5)
          headlineStat: Color(0xFFFF5DA8),
          bulletColor: Color(0xFFFFC1DD),
          bulletGlyph: '✦',
          twinkleBullets: true,
          tabularFigures: false,
          numberSizeScale: 1.05,
          numberWeight: FontWeight.w700,
          numberStyle: FontStyle.italic,
          chipRadius: 18,
          cardRadius: 18,
          dividerColor: Color(0x55FF5DA8),
          dividerThickness: 1.0,
          backdrop: ThemeBackdrop.pastelDriftSparkles,
          glowPrimary: Color(0x33FF5DA8),
          glowSecondary: Color(0x225BE8B8),
          auraStyle: AvatarAuraStyle.pastelPulse,
          headerGlyph: '\u2661', // ♡ open heart
          headerUnderlineColor: Color(0x88FF5DA8),
        );
      case AppThemeMode.curseblaster:
        return const ThemeFlair(
          scaffold: Color(0xFF100608),
          card: Color(0xFF1B0C0F),
          primary: Color(0xFFE83344), // bolder oxblood (was #C62E3A)
          secondary: Color(0xFFFCEFD8), // brighter bone (was #EFE4D6)
          headlineStat: Color(0xFFFCEFD8),
          bulletColor: Color(0xFFE83344),
          bulletGlyph: '†', // gothic dagger
          glowCurse: true,
          tabularFigures: true,
          numberSizeScale: 1.05,
          numberWeight: FontWeight.w800,
          chipRadius: 8,
          cardRadius: 12,
          dividerColor: Color(0x55E83344),
          dividerThickness: 1.0,
          backdrop: ThemeBackdrop.redBreathDrip,
          glowPrimary: Color(0x33E83344),
          glowSecondary: Color(0x118A0F18),
          auraStyle: AvatarAuraStyle.oxbloodBreath,
          headerGlyph: '\u2020', // † dagger cross
          headerUnderlineColor: Color(0xAAE83344),
        );
      case AppThemeMode.winchester:
        return const ThemeFlair(
          scaffold: Color(0xFF0C0705), // saloon dust wood
          card: Color(0xFF1D100A), // whiskey-aged charcoal barrel wood
          primary: Color(0xFFFFB300), // gleaming gold rush gold!
          secondary: Color(0xFFE5A93C), // spurred brass tan
          headlineStat: Color(0xFFFFD54F), // warm gold coin yellow
          bulletColor: Color(0xFFFFB300),
          bulletGlyph: '★', // sheriff star
          embossNumbers: true,
          tabularFigures: true,
          numberSizeScale: 1.0,
          numberWeight: FontWeight.w700,
          chipRadius: 6,
          cardRadius: 8,
          cardBorderColor: Color(0x99FFB300), // glowing brass frame
          cardBorderWidth: 1.2,
          dividerColor: Color(0x88FFB300),
          dividerThickness: 1.2,
          backdrop: ThemeBackdrop.brassMotes,
          glowPrimary: Color(0x2EFFB300),
          glowSecondary: Color(0x1AE5A93C),
          auraStyle: AvatarAuraStyle.brassConic,
          headerGlyph: '\u2605', // ★ sheriff star
          headerUnderlineColor: Color(0xBBFFB300),
        );
      case AppThemeMode.frogCute:
        return const ThemeFlair(
          scaffold: Color(0xFF07140B), // shadow pond swamp
          card: Color(0xFF112918), // mossy lilypad green
          primary: Color(0xFF4CAF50), // saturated moss frog green
          secondary: Color(0xFFA5D6A7), // sweet pale leaf mint green
          headlineStat: Color(0xFFE8F5E9), // fresh dew droplet white
          bulletColor: Color(0xFF81C784),
          bulletGlyph: '🐸', // FROG EMOJI!
          tabularFigures: true,
          numberSizeScale: 1.0,
          numberWeight: FontWeight.w800,
          chipRadius: 10,
          cardRadius: 12,
          cardBorderColor: Color(0x444CAF50), // leafy light green border
          cardBorderWidth: 1.0,
          dividerColor: Color(0x554CAF50),
          dividerThickness: 1.0,
          backdrop: ThemeBackdrop.toxicBubbles,
          glowPrimary: Color(0x224CAF50),
          glowSecondary: Color(0x11A5D6A7),
          auraStyle: AvatarAuraStyle.toxicOoze,
          headerGlyph: '🐸',
          headerUnderlineColor: Color(0x884CAF50),
        );
      case AppThemeMode.iceTyrant:
        return const ThemeFlair(
          scaffold: Color(0xFF0A0F14), // deep ice-black
          card: Color(0xFF141E28), // dark slate blue
          primary: Color(0xFF7EC8E3), // ice cyan
          secondary: Color(0xFFB8E0F0), // pale ice
          headlineStat: Color(0xFFB8E0F0),
          bulletColor: Color(0xFF7EC8E3),
          bulletGlyph: '❄', // snowflake
          tabularFigures: true,
          numberSizeScale: 1.0,
          numberWeight: FontWeight.w800,
          chipRadius: 10,
          cardRadius: 12,
          cardBorderColor: Color(0x337EC8E3), // icy cyan border
          cardBorderWidth: 1.0,
          dividerColor: Color(0x557EC8E3),
          dividerThickness: 1.0,
          backdrop: ThemeBackdrop.iceCrystals,
          glowPrimary: Color(0x227EC8E3),
          glowSecondary: Color(0x11B8E0F0),
          auraStyle: AvatarAuraStyle.frostRing,
          headerGlyph: '\u2744',
          headerUnderlineColor: Color(0x887EC8E3),
        );
      case AppThemeMode.charm:
        return const ThemeFlair(
          scaffold: Color(0xFF120308), // sweet dark velvet red
          card: Color(0xFF280C14), // satin crimson rose
          primary: Color(0xFFFF2A6D), // glowing sweetheart hot pink
          secondary: Color(0xFFFF85A1), // rosebud pink cream
          headlineStat: Color(0xFFFF2A6D),
          bulletColor: Color(0xFFFF85A1),
          bulletGlyph: '💘', // sweetheart charm
          tabularFigures: true,
          numberSizeScale: 1.0,
          numberWeight: FontWeight.w800,
          chipRadius: 12,
          cardRadius: 12,
          cardBorderColor: Color(0x55FF2A6D), // sweetheart pink border
          cardBorderWidth: 1.0,
          dividerColor: Color(0x33FF2A6D),
          dividerThickness: 1.0,
          backdrop: ThemeBackdrop.pastelDriftSparkles,
          glowPrimary: Color(0x22FF2A6D),
          glowSecondary: Color(0x11FF85A1),
          auraStyle: AvatarAuraStyle.pastelPulse,
          headerGlyph: '💘',
          headerUnderlineColor: Color(0x88FF2A6D),
        );
      case AppThemeMode.midnightHunter:
        return const ThemeFlair(
          scaffold: Color(0xFF060B12), // midnight forest
          card: Color(0xFF101926), // mossy hunting camp wood
          primary: Color(0xFF1E88E5), // hunters steel blue
          secondary: Color(0xFFFFD54F), // campfire gold
          headlineStat: Color(0xFF90CAF9), // soft hunter blue
          bulletColor: Color(0xFFFFD54F),
          bulletGlyph: '🏹', // bow and arrow
          tabularFigures: true,
          numberSizeScale: 1.0,
          numberWeight: FontWeight.w800,
          chipRadius: 10,
          cardRadius: 12,
          cardBorderColor: Color(0x331E88E5), // hunter steel blue border
          cardBorderWidth: 1.0,
          dividerColor: Color(0x551E88E5),
          dividerThickness: 1.0,
          backdrop: ThemeBackdrop.brassMotes,
          glowPrimary: Color(0x221E88E5),
          glowSecondary: Color(0x11FFD54F),
          auraStyle: AvatarAuraStyle.frostRing,
          headerGlyph: '🏹',
          headerUnderlineColor: Color(0x881E88E5),
        );
      case AppThemeMode.voidDimension:
        return const ThemeFlair(
          scaffold: Color(0xFF0F051A), // void space
          card: Color(0xFF220A38), // dark violet cosmic nebulas
          primary: Color(0xFFBA68C8), // warped violet
          secondary: Color(0xFF00E5FF), // stellar teal
          headlineStat: Color(0xFFBA68C8),
          bulletColor: Color(0xFF00E5FF),
          bulletGlyph: '🌀', // spiral vortex
          tabularFigures: true,
          numberSizeScale: 1.05,
          numberWeight: FontWeight.w800,
          chipRadius: 8,
          cardRadius: 10,
          cardBorderColor: Color(0x44BA68C8), // warped violet border
          cardBorderWidth: 1.0,
          dividerColor: Color(0x66BA68C8),
          dividerThickness: 1.2,
          backdrop: ThemeBackdrop.cosmicRift,
          glowPrimary: Color(0x33BA68C8),
          glowSecondary: Color(0x1100E5FF),
          auraStyle: AvatarAuraStyle.cosmicTemporal,
          headerGlyph: '🌀',
          headerUnderlineColor: Color(0xAABA68C8),
        );
      case AppThemeMode.firestorm:
        return const ThemeFlair(
          scaffold: Color(0xFF140C0A), // molten ash
          card: Color(0xFF261510), // burnt gunpowder crate
          primary: Color(0xFFE64A19), // blazing orange
          secondary: Color(0xFFFFB74D), // spark yellow
          headlineStat: Color(0xFFFFB74D),
          bulletColor: Color(0xFFE64A19),
          bulletGlyph: '💀', // skull
          twinkleBullets: true,
          tabularFigures: true,
          numberSizeScale: 1.0,
          numberWeight: FontWeight.w800,
          chipRadius: 6,
          cardRadius: 8,
          cardBorderColor: Color(0x33E64A19), // blazing orange border
          cardBorderWidth: 1.0,
          dividerColor: Color(0x44E64A19),
          dividerThickness: 1.0,
          backdrop: ThemeBackdrop.forgeEmbers,
          glowPrimary: Color(0x22E64A19),
          glowSecondary: Color(0x11FFB74D),
          auraStyle: AvatarAuraStyle.forgeGlow,
          headerGlyph: '💀',
          headerUnderlineColor: Color(0x88E64A19),
        );
      case AppThemeMode.theBreach:
        return const ThemeFlair(
          scaffold: Color(0xFF141311), // ancient sandstone
          card: Color(0xFF2B2520), // crumbling pillar brown
          primary: Color(0xFFB0BEC5), // ancient stone grey
          secondary: Color(0xFFFFB300), // forgotten temple gold
          headlineStat: Color(0xFFB0BEC5),
          bulletColor: Color(0xFFFFB300),
          bulletGlyph: '🏛️', // temple crumbling pillar
          shimmerHeadline: true,
          tabularFigures: true,
          numberSizeScale: 1.08,
          numberWeight: FontWeight.w700,
          chipRadius: 10,
          cardRadius: 12,
          cardBorderColor: Color(0x33B0BEC5), // ancient stone border
          cardBorderWidth: 1.0,
          dividerColor: Color(0x55B0BEC5),
          dividerThickness: 1.0,
          backdrop: ThemeBackdrop.paperBreath,
          glowPrimary: Color(0x33B0BEC5),
          glowSecondary: Color(0x11FFB300),
          auraStyle: AvatarAuraStyle.brassConic,
          headerGlyph: '🏛️',
          headerUnderlineColor: Color(0x88B0BEC5),
        );
      case AppThemeMode.custom:
        final data = _cachedCustomTheme ?? CustomThemeData.defaultTheme;
        return ThemeFlair(
          scaffold: data.scaffold,
          card: data.card,
          primary: data.primary,
          secondary: data.secondary,
          headlineStat: data.headlineStat,
          bulletColor: data.bulletColor,
          bulletGlyph: '•',
          tabularFigures: true,
          numberSizeScale: 1.0,
          numberWeight: FontWeight.w700,
          chipRadius: 10,
          cardRadius: 10,
          chipFilled: true,
          dividerColor: data.primary.withValues(alpha: 0.3),
          dividerThickness: 1.0,
          backdrop: data.backdrop,
          glowPrimary: data.primary.withValues(alpha: 0.2),
          glowSecondary: data.secondary.withValues(alpha: 0.1),
          auraStyle: data.auraStyle,
          headerGlyph: null,
          headerUnderlineColor: data.primary.withValues(alpha: 0.5),
        );
    }
  }
}

