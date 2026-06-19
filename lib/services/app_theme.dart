import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

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
  unicorn(
    label: 'Unicorn',
    vibe: 'MAGICAL',
    diff: 'CO-OP',
    elem: 'RAINBOW',
    whimsicalDescription: 'Douse your guns in pure, unadulterated cotton candy. Complete with twinkly stars and pastel sparkles. Warning: Highly toxic to serious, dark, and brooding Gungeoneers.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF1A101F),
      card: Color(0xFF2D1B36),
      primary: Color(0xFFFF69B4), // pink
      secondary: Color(0xFFDA70D6), // lavender
      headlineStat: Color(0xFF00F5D4), // cyan accent
      bulletColor: Color(0xFFDA70D6),
      bulletGlyph: '✦',
      twinkleBullets: true,
      tabularFigures: false,
      numberSizeScale: 1.05,
      numberWeight: FontWeight.w700,
      numberStyle: FontStyle.italic,
      chipRadius: 18,
      cardRadius: 18,
      dividerColor: Color(0x55FF69B4),
      dividerThickness: 1.0,
      backdrop: ThemeBackdrop.pastelDriftSparkles,
      glowPrimary: Color(0x33FF69B4),
      glowSecondary: Color(0x22DA70D6),
      auraStyle: AvatarAuraStyle.pastelPulse,
      headerGlyph: '\u2661', // ♡ open heart
      headerUnderlineColor: Color(0x88FF69B4),
    ),
  ),
  ammonomicon(
    label: 'Ammonomicon',
    vibe: 'ARCHIVAL',
    diff: 'NORMAL',
    elem: 'KNOWLEDGE',
    whimsicalDescription: 'Flip through the pages of the ultimate Gungeon compendium. Styled with heavy book-leather browns and crisp gold-embossed trim for the meticulous researcher.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF120D0A),
      card: Color(0xFF221A14),
      primary: Color(0xFFD4AF37), // gold
      secondary: Color(0xFF8B5A2B), // leather brown
      headlineStat: Color(0xFFFFFDD0), // antique gold
      bulletColor: Color(0xFFD4AF37),
      bulletGlyph: '📖',
      shimmerHeadline: true,
      tabularFigures: true,
      numberSizeScale: 1.08,
      numberWeight: FontWeight.w800,
      chipRadius: 10,
      cardRadius: 12,
      cardBorderColor: Color(0x66D4AF37), // gold border
      cardBorderWidth: 1.2,
      dividerColor: Color(0x55D4AF37),
      dividerThickness: 1.0,
      backdrop: ThemeBackdrop.paperBreath,
      glowPrimary: Color(0x33D4AF37),
      glowSecondary: Color(0x118B5A2B),
      auraStyle: AvatarAuraStyle.brassConic,
      headerGlyph: '📖',
      headerUnderlineColor: Color(0xAAD4AF37),
    ),
  ),
  forgeMaster(
    label: 'Forge Master',
    vibe: 'INDUSTRIAL',
    diff: 'EXPERT',
    elem: 'FIRE',
    whimsicalDescription: 'Forged in the depths of the Fifth Chamber. Obsidian plates illuminated by roaring blast furnaces and the glowing scales of the High Dragun.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0F0C0A),
      card: Color(0xFF1C1714),
      primary: Color(0xFFFF4500), // dragun orange
      secondary: Color(0xFFFFAA00), // molten sulfur
      headlineStat: Color(0xFFFFCC00),
      bulletColor: Color(0xFFFF4500),
      bulletGlyph: '🔥',
      twinkleBullets: true,
      tabularFigures: true,
      numberSizeScale: 1.0,
      numberWeight: FontWeight.w800,
      chipRadius: 6,
      cardRadius: 8,
      cardBorderColor: Color(0x33FF4500),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x44FF4500),
      dividerThickness: 1.0,
      backdrop: ThemeBackdrop.forgeEmbers,
      glowPrimary: Color(0x22FF4500),
      glowSecondary: Color(0x11FFAA00),
      auraStyle: AvatarAuraStyle.forgeGlow,
      headerGlyph: '🔥',
      headerUnderlineColor: Color(0x88FF4500),
    ),
  ),
  hollowChill(
    label: 'Hollow Chill',
    vibe: 'ETHEREAL',
    diff: 'BRUTAL',
    elem: 'ICE',
    whimsicalDescription: 'Feel the creeping frost of the Fourth Chamber. Chilled directly by spectral remnants, haunted tombstones, and freezing ice-cube ammunition.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0A1118),
      card: Color(0xFF132230),
      primary: Color(0xFF00D2FF), // cyan
      secondary: Color(0xFF708090), // spectral blue
      headlineStat: Color(0xFFE0F7FA),
      bulletColor: Color(0xFF00D2FF),
      bulletGlyph: '❄',
      tabularFigures: true,
      numberSizeScale: 1.0,
      numberWeight: FontWeight.w800,
      chipRadius: 10,
      cardRadius: 12,
      cardBorderColor: Color(0x3300D2FF),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x5500D2FF),
      dividerThickness: 1.0,
      backdrop: ThemeBackdrop.iceCrystals,
      glowPrimary: Color(0x2200D2FF),
      glowSecondary: Color(0x11708090),
      auraStyle: AvatarAuraStyle.frostRing,
      headerGlyph: '\u2744',
      headerUnderlineColor: Color(0x8800D2FF),
    ),
  ),
  lordJammed(
    label: 'Lord Jammed',
    vibe: 'CURSED',
    diff: '10-CURSE',
    elem: 'JAMMED',
    whimsicalDescription: 'An irreversible pact sealed in maximum curse. Dark, corrupted purple UI accented by lethal oxblood lines. If you hear stalking footsteps, don\'t look back.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0A030C),
      card: Color(0xFF16071B),
      primary: Color(0xFF990000), // oxblood red
      secondary: Color(0xFF4A0E4E), // corrupted violet
      headlineStat: Color(0xFFFF007F), // curse neon
      bulletColor: Color(0xFF990000),
      bulletGlyph: '👹',
      glowCurse: true,
      tabularFigures: true,
      numberSizeScale: 1.05,
      numberWeight: FontWeight.w800,
      chipRadius: 8,
      cardRadius: 12,
      dividerColor: Color(0x55990000),
      dividerThickness: 1.0,
      backdrop: ThemeBackdrop.redBreathDrip,
      glowPrimary: Color(0x33990000),
      glowSecondary: Color(0x114A0E4E),
      auraStyle: AvatarAuraStyle.oxbloodBreath,
      headerGlyph: '\u2020', // †
      headerUnderlineColor: Color(0xAA990000),
    ),
  ),
  theBreach(
    label: 'The Breach',
    vibe: 'COZY',
    diff: 'STEADY',
    elem: 'BRASS',
    whimsicalDescription: 'Relax alongside Cadence, Ox, and the cult of gungeoneers. Brings a warm, comforting hearthstone glow to your loadout tracking before you drop back down.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF111216),
      card: Color(0xFF1D2026),
      primary: Color(0xFFFF9F1C), // cozy amber
      secondary: Color(0xFF7D84B2), // stone gray-purple
      headlineStat: Color(0xFFFFD166), // brass yellow
      bulletColor: Color(0xFFFF9F1C),
      bulletGlyph: '★',
      embossNumbers: true,
      tabularFigures: true,
      numberSizeScale: 1.0,
      numberWeight: FontWeight.w700,
      chipRadius: 6,
      cardRadius: 8,
      cardBorderColor: Color(0x99FF9F1C),
      cardBorderWidth: 1.2,
      dividerColor: Color(0x88FF9F1C),
      dividerThickness: 1.2,
      backdrop: ThemeBackdrop.brassMotes,
      glowPrimary: Color(0x2EFF9F1C),
      glowSecondary: Color(0x1A7D84B2),
      auraStyle: AvatarAuraStyle.brassConic,
      headerGlyph: '\u2605',
      headerUnderlineColor: Color(0xBBFF9F1C),
    ),
  ),
  bulletHell(
    label: 'Bullet Hell',
    vibe: 'HELLISH',
    diff: 'EXTREME',
    elem: 'ACID',
    whimsicalDescription: 'Descend into the absolute depths of the Gungeon floor layout. Lethal acid greens cut cleanly through a charred landscape of absolute bullet chaos.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF08090A),
      card: Color(0xFF141619),
      primary: Color(0xFF39FF14), // neon green
      secondary: Color(0xFF4B0082), // soul purple
      headlineStat: Color(0xFFCCFF00),
      bulletColor: Color(0xFF39FF14),
      bulletGlyph: '☠',
      tabularFigures: true,
      numberSizeScale: 1.05,
      numberWeight: FontWeight.w800,
      chipRadius: 8,
      cardRadius: 10,
      cardBorderColor: Color(0x4439FF14),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x6639FF14),
      dividerThickness: 1.2,
      backdrop: ThemeBackdrop.hellfire,
      glowPrimary: Color(0x3339FF14),
      glowSecondary: Color(0x114B0082),
      auraStyle: AvatarAuraStyle.cosmicTemporal,
      headerGlyph: '☠',
      headerUnderlineColor: Color(0xAA39FF14),
    ),
  ),
  resourcefulRat(
    label: 'Resourceful Rat',
    vibe: 'SNEAKY',
    diff: 'PUZZLE',
    elem: 'LOOT',
    whimsicalDescription: 'Channel the ultimate mastermind of the ventilation shafts. A clever, high-contrast layout built from dirty sewer elements and brilliant, shiny stolen items.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0D110E),
      card: Color(0xFF18221B),
      primary: Color(0xFFFFD700), // gold
      secondary: Color(0xFF2E5A44), // sewer green
      headlineStat: Color(0xFFFFA500), // cheese yellow
      bulletColor: Color(0xFFFFD700),
      bulletGlyph: '🧀',
      tabularFigures: true,
      numberSizeScale: 1.0,
      numberWeight: FontWeight.w800,
      chipRadius: 10,
      cardRadius: 12,
      cardBorderColor: Color(0x44FFD700),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x55FFD700),
      dividerThickness: 1.0,
      backdrop: ThemeBackdrop.toxicBubbles,
      glowPrimary: Color(0x22FFD700),
      glowSecondary: Color(0x112E5A44),
      auraStyle: AvatarAuraStyle.toxicOoze,
      headerGlyph: '🧀',
      headerUnderlineColor: Color(0x88FFD700),
    ),
  ),
  custom(
    label: 'Custom',
    vibe: 'TACTICAL',
    diff: 'NORMAL',
    elem: 'BULLET',
    whimsicalDescription: 'A blank canvas of absolute personal madness. Paint the town in your own choice of radioactive colors. Godspeed, designer!',
    staticFlair: null,
  );

  final String label;
  final String vibe;
  final String diff;
  final String elem;
  final String whimsicalDescription;
  final ThemeFlair? _staticFlair;

  const AppThemeMode({
    required this.label,
    required this.vibe,
    required this.diff,
    required this.elem,
    required this.whimsicalDescription,
    required ThemeFlair? staticFlair,
  }) : _staticFlair = staticFlair;

  ThemeFlair get flair {
    if (this == AppThemeMode.custom) {
      final data = AppTheme._cachedCustomTheme ?? CustomThemeData.defaultTheme;
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
    return _staticFlair!;
  }
}

/// Thematic font options for the app. Each font provides a different
/// visual personality while maintaining readability.
enum AppFont {
  gungeon,
  pressStart2p,
  silkscreen,
  vt323,
  pixelifySans,
  bungee,
  bungeeShade,
  rubik8bit,
  monoton,
  blackOpsOne,
  dotgothic16,
  creepster,
  orbitron,
  shareTechMono,
  syncopate,
  rajdhani,
  audiowide,
  russoOne,
  fasterOne,
  archivoBlack,
  anton,
  rowdies,
  righteous,
  comicNeue,
  fredoka,
  sniglet,
  lemon,
  lilitaOne,
  spicyRice,
  chewy,
  boogaloo,
  carterOne,
  permanentMarker,
  spaceGrotesk,
  jetBrainsMono,
  dmSans,
  outfit,
  syne,
  montserrat,
  lexend,
  kanit,
  teko,
  fjallaOne,
  bebasNeue,
  medievalSharp,
  cinzelDecorative,
  almendra,
  metalMania,
  unifrakturMaguntia,
  newRocker,
  rye,
  nosifer,
  playfairDisplay,
  ebGaramond,
  merriweather,
  libreBaskerville,
  specialElite,
  coustard,
  architectsDaughter,
  cinzel,
  megrim,
  rockSalt,
  shadowsIntoLight,
  lobster,
  caveat,
  comfortaa,
  alata,
}

extension AppFontLabel on AppFont {
  static const Map<AppFont, String> _googleFontNames = {
    AppFont.pressStart2p: 'Press Start 2P',
    AppFont.silkscreen: 'Silkscreen',
    AppFont.vt323: 'VT323',
    AppFont.pixelifySans: 'Pixelify Sans',
    AppFont.bungee: 'Bungee',
    AppFont.bungeeShade: 'Bungee Shade',
    AppFont.rubik8bit: 'Rubik 8-Bit',
    AppFont.monoton: 'Monoton',
    AppFont.blackOpsOne: 'Black Ops One',
    AppFont.dotgothic16: 'DotGothic16',
    AppFont.creepster: 'Creepster',
    AppFont.orbitron: 'Orbitron',
    AppFont.shareTechMono: 'Share Tech Mono',
    AppFont.syncopate: 'Syncopate',
    AppFont.rajdhani: 'Rajdhani',
    AppFont.audiowide: 'Audiowide',
    AppFont.russoOne: 'Russo One',
    AppFont.fasterOne: 'Faster One',
    AppFont.archivoBlack: 'Archivo Black',
    AppFont.anton: 'Anton',
    AppFont.rowdies: 'Rowdies',
    AppFont.righteous: 'Righteous',
    AppFont.comicNeue: 'Comic Neue',
    AppFont.fredoka: 'Fredoka',
    AppFont.sniglet: 'Sniglet',
    AppFont.lemon: 'Lemon',
    AppFont.lilitaOne: 'Lilita One',
    AppFont.spicyRice: 'Spicy Rice',
    AppFont.chewy: 'Chewy',
    AppFont.boogaloo: 'Boogaloo',
    AppFont.carterOne: 'Carter One',
    AppFont.permanentMarker: 'Permanent Marker',
    AppFont.spaceGrotesk: 'Space Grotesk',
    AppFont.jetBrainsMono: 'JetBrains Mono',
    AppFont.dmSans: 'DM Sans',
    AppFont.outfit: 'Outfit',
    AppFont.syne: 'Syne',
    AppFont.montserrat: 'Montserrat',
    AppFont.lexend: 'Lexend',
    AppFont.kanit: 'Kanit',
    AppFont.teko: 'Teko',
    AppFont.fjallaOne: 'Fjalla One',
    AppFont.bebasNeue: 'Bebas Neue',
    AppFont.medievalSharp: 'MedievalSharp',
    AppFont.cinzelDecorative: 'Cinzel Decorative',
    AppFont.almendra: 'Almendra',
    AppFont.metalMania: 'Metal Mania',
    AppFont.unifrakturMaguntia: 'UnifrakturMaguntia',
    AppFont.newRocker: 'New Rocker',
    AppFont.rye: 'Rye',
    AppFont.nosifer: 'Nosifer',
    AppFont.playfairDisplay: 'Playfair Display',
    AppFont.ebGaramond: 'EB Garamond',
    AppFont.merriweather: 'Merriweather',
    AppFont.libreBaskerville: 'Libre Baskerville',
    AppFont.specialElite: 'Special Elite',
    AppFont.coustard: 'Coustard',
    AppFont.architectsDaughter: 'Architects Daughter',
    AppFont.cinzel: 'Cinzel',
    AppFont.megrim: 'Megrim',
    AppFont.rockSalt: 'Rock Salt',
    AppFont.shadowsIntoLight: 'Shadows Into Light',
    AppFont.lobster: 'Lobster',
    AppFont.caveat: 'Caveat',
    AppFont.comfortaa: 'Comfortaa',
    AppFont.alata: 'Alata',
  };

  static const Map<AppFont, String> _googleFontDescriptions = {
    AppFont.pressStart2p: 'Classic 8-bit NES arcade pixel',
    AppFont.silkscreen: 'Crisp tiny 8-bit screen font',
    AppFont.vt323: 'Nostalgic glowing CRT terminal font',
    AppFont.pixelifySans: 'Modern hybrid geometric pixel art',
    AppFont.bungee: 'Chunky vertical urban sign look',
    AppFont.bungeeShade: 'Shadowed retro arcade heading',
    AppFont.rubik8bit: 'Extra heavy 3D pixel letters',
    AppFont.monoton: 'Triple-line futuristic high-tech race style',
    AppFont.blackOpsOne: 'Military industrial stencil look',
    AppFont.dotgothic16: 'Authentic 90s Japanese arcade style',
    AppFont.creepster: 'Spooky classic halloween horror lettering',
    AppFont.orbitron: 'Futuristic sci-fi aerospace tech',
    AppFont.shareTechMono: 'Clean digital cybernetic HUD console',
    AppFont.syncopate: 'Wide high-end cyberpunk architecture',
    AppFont.rajdhani: 'Squarish military armor tech plates',
    AppFont.audiowide: 'Smooth streamlined robotic lettering',
    AppFont.russoOne: 'Heavy soviet metal sci-fi gaming',
    AppFont.fasterOne: 'Wind-tunnel racing speed blur lines',
    AppFont.archivoBlack: 'Ultra heavy high-visibility signage',
    AppFont.anton: 'Thick solid impact display blocks',
    AppFont.rowdies: 'Edgy casual heavy fighting style',
    AppFont.righteous: 'Cool geometric art deco bubble-sans',
    AppFont.comicNeue: 'Highly readable modern cartoon comic',
    AppFont.fredoka: 'Cute rounded friendly organic blocks',
    AppFont.sniglet: 'Playful bouncy summer kids cartoon',
    AppFont.lemon: 'Thick juicy casual letter blocks',
    AppFont.lilitaOne: 'Chubby fat-finger casual display',
    AppFont.spicyRice: 'Wacky tropical retro gaming logo',
    AppFont.chewy: 'Squishy melting marshmallow cartoon',
    AppFont.boogaloo: 'Swinging 60s retro party lettering',
    AppFont.carterOne: 'Thick vintage brush logo signwriting',
    AppFont.permanentMarker: 'Grungy hand-drawn permanent ink scribble',
    AppFont.spaceGrotesk: 'Sleek geometric tech sans with character',
    AppFont.jetBrainsMono: 'Elite software engineer monospace editor',
    AppFont.dmSans: 'Neutral geometric modern interface sans',
    AppFont.outfit: 'Perfect luxury circular modern display',
    AppFont.syne: 'Artistic high-fashion expressive layout',
    AppFont.montserrat: 'Clean urban geometric architectural sans',
    AppFont.lexend: 'Ultra readable educational interface sans',
    AppFont.kanit: 'Sleek compact high-density modern sans',
    AppFont.teko: 'Super tall condensed athletic metal block',
    AppFont.fjallaOne: 'High impact condensed newspaper heading',
    AppFont.bebasNeue: 'Clean condensed billboard display legend',
    AppFont.medievalSharp: 'Sharp runic celtic iron broadsword',
    AppFont.cinzelDecorative: 'Ornate royalty fantasy crown capitals',
    AppFont.almendra: 'Classic gothic fantasy parchment script',
    AppFont.metalMania: 'Heavy thrash metal guitar typography',
    AppFont.unifrakturMaguntia: 'Traditional blackletter gothic cathedral script',
    AppFont.newRocker: 'Aggressive hard rock jagged lettering',
    AppFont.rye: 'Wanted poster wild west saloon woodcut',
    AppFont.nosifer: 'Dripping toxic acid blood splatter',
    AppFont.playfairDisplay: 'Luxurious high-contrast theatrical display',
    AppFont.ebGaramond: 'Classic scholarly book antique print',
    AppFont.merriweather: 'Robust highly readable editorial serif',
    AppFont.libreBaskerville: 'Elegant traditional transitional book serif',
    AppFont.specialElite: 'Grungy ink-splattered vintage typewriter',
    AppFont.coustard: 'Slab-serif heavy typewriter-slab block',
    AppFont.architectsDaughter: 'Messy architect blueprints hand scribble',
    AppFont.cinzel: 'Formal ancient roman stone carving',
    AppFont.megrim: 'Ultra-stylized thin wire outline vector',
    AppFont.rockSalt: 'Scribbled dry-erase whiteboard marker',
    AppFont.shadowsIntoLight: 'Neat feminine clean gel-pen handwriting',
    AppFont.lobster: 'Thick bold retro script lettering',
    AppFont.caveat: 'Natural fluid cursive ink handwriting',
    AppFont.comfortaa: 'Soft circular geometric outline sans',
    AppFont.alata: 'Clean balanced minimal graphic sans',
  };

  String get label {
    if (this == AppFont.gungeon) return 'Enter the Gungeon';
    return _googleFontNames[this] ?? 'Enter the Gungeon';
  }

  String get description {
    if (this == AppFont.gungeon) return 'Official Gungeon chunky pixel';
    return _googleFontDescriptions[this] ?? 'Google Font';
  }

  TextStyle get textStyle {
    if (this == AppFont.gungeon) return const TextStyle(fontFamily: 'EnterTheGungeonBig');
    try {
      return GoogleFonts.getFont(label);
    } catch (_) {
      return const TextStyle(fontFamily: 'EnterTheGungeonBig');
    }
  }

  TextTheme get textTheme {
    final base = ThemeData.dark().textTheme;
    if (this == AppFont.gungeon) return base.apply(fontFamily: 'EnterTheGungeonBig');
    try {
      return GoogleFonts.getTextTheme(label, base);
    } catch (_) {
      return base.apply(fontFamily: 'EnterTheGungeonBig');
    }
  }
}

/// Themes shown in the picker. Keep this list as the single source of
/// truth — the [AppThemeMode] enum may include historical values that
/// are no longer offered to users; on app init we migrate any persisted
/// value not in this list onto the first entry below.
const List<AppThemeMode> kVisibleThemes = <AppThemeMode>[
  AppThemeMode.ammonomicon,
  AppThemeMode.theBreach,
  AppThemeMode.unicorn,
  AppThemeMode.forgeMaster,
  AppThemeMode.hollowChill,
  AppThemeMode.lordJammed,
  AppThemeMode.bulletHell,
  AppThemeMode.resourcefulRat,
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
      case AppThemeMode.unicorn:
        return 'Unicorn Bubblegum';
      case AppThemeMode.ammonomicon:
        return 'The Ammonomicon';
      case AppThemeMode.forgeMaster:
        return 'Forge Master';
      case AppThemeMode.hollowChill:
        return 'Hollow Chill';
      case AppThemeMode.lordJammed:
        return 'Lord Jammed';
      case AppThemeMode.theBreach:
        return 'The Breach';
      case AppThemeMode.bulletHell:
        return 'Bullet Hell';
      case AppThemeMode.resourcefulRat:
        return 'Resourceful Rat';
      case AppThemeMode.custom:
        return AppTheme._customThemeName;
    }
  }

  String get tagline {
    switch (this) {
      case AppThemeMode.unicorn:
        return 'Cotton Candy — lavender, pink, twinkle';
      case AppThemeMode.ammonomicon:
        return 'Ancient Lore — leather brown, antique gold, crisp teal';
      case AppThemeMode.forgeMaster:
        return 'Blacksmith — obsidian black, molten sulfur, dragun orange';
      case AppThemeMode.hollowChill:
        return 'Grave Cold — spectral blue, phantom cyan, mist gray';
      case AppThemeMode.lordJammed:
        return 'Lord of the Jammed — oxblood red, corrupted violet, curse neon';
      case AppThemeMode.theBreach:
        return 'Safe Haven — stone gray, hearth amber, brass yellow';
      case AppThemeMode.bulletHell:
        return 'Sixth Chamber — ash gray, toxic radioactive green, soul purple';
      case AppThemeMode.resourcefulRat:
        return 'Lair Hoard — sewer green, stolen gold, cheese yellow';
      case AppThemeMode.custom:
        return 'Custom — your personal palette';
    }
  }
}

enum InventoryDisplayMode {
  classicPeriodic,
  tacticalStats,
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
  none,
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
      case CustomParticleType.none:
        return 'No Particles 🚫';
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

  /// Global display mode for inventory screens (grid variations).
  final InventoryDisplayMode inventoryDisplayMode;

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

  final bool isGoopianLanguage;
  final bool spongeActive;

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
    this.inventoryDisplayMode = InventoryDisplayMode.classicPeriodic,
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
    this.isGoopianLanguage = false,
    this.spongeActive = false,
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
  static const _kInventoryDisplayMode = 'vp.inventory_display_mode_v1';
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
  static const _kGoopianLanguage = 'vp.goopian_language_v1';
  static const _kSpongeActive = 'vp.sponge_active_v1';

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
      final displayModeIdx = p.getInt(_kInventoryDisplayMode) ?? 0;
      final inventoryDisplayMode = InventoryDisplayMode.values[displayModeIdx.clamp(0, InventoryDisplayMode.values.length - 1)];

      final isGoopian = p.getBool(_kGoopianLanguage) ?? false;
      final spongeActive = p.getBool(_kSpongeActive) ?? false;

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
        inventoryDisplayMode: inventoryDisplayMode,
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
        isGoopianLanguage: isGoopian,
        spongeActive: spongeActive,
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

  static Future<void> setInventoryDisplayMode(InventoryDisplayMode mode) async {
    notifier.value = notifier.value._with(inventoryDisplayMode: mode);
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

  static Future<void> setIsGoopianLanguage(bool v) async {
    notifier.value = notifier.value._with(isGoopianLanguage: v);
    _persist();
  }

  static Future<void> setSpongeActive(bool v) async {
    notifier.value = notifier.value._with(spongeActive: v);
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
      await p.setInt(_kInventoryDisplayMode, v.inventoryDisplayMode.index);

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
      await p.setBool(_kGoopianLanguage, v.isGoopianLanguage);
      await p.setBool(_kSpongeActive, v.spongeActive);
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
    InventoryDisplayMode? inventoryDisplayMode,
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
    bool?   isGoopianLanguage,
    bool?   spongeActive,
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
    inventoryDisplayMode: inventoryDisplayMode ?? this.inventoryDisplayMode,
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
    isGoopianLanguage: isGoopianLanguage ?? this.isGoopianLanguage,
    spongeActive:     spongeActive      ?? this.spongeActive,
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
      ValueNotifier<AppThemeMode>(AppThemeMode.ammonomicon);

  static final ValueNotifier<AppThemeMode?> previewNotifier =
      ValueNotifier<AppThemeMode?>(null);

  static AppThemeMode get mode => notifier.value;
  static ThemeFlair get flair => flairFor(notifier.value);

  static AppThemeMode get displayedMode => previewNotifier.value ?? notifier.value;
  static ThemeFlair get displayedFlair => flairFor(displayedMode);

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
    final selectedFont = m == AppThemeMode.custom && _cachedCustomTheme != null
        ? _cachedCustomTheme!.font
        : prefs.font;
    var textTheme = selectedFont.textTheme;
    textTheme = _applyWeightBias(textTheme, bias);
    
    String? fontFamilyName;
    if (selectedFont == AppFont.gungeon) {
      fontFamilyName = 'EnterTheGungeonBig';
    } else {
      try {
        fontFamilyName = GoogleFonts.getFont(selectedFont.label).fontFamily;
      } catch (_) {
        fontFamilyName = 'EnterTheGungeonBig';
      }
    }
    
    return ThemeData(
      colorScheme: ColorScheme.dark(
        primary: f.primary,
        secondary: f.secondary,
        surface: f.card,
        onSurface: Colors.white,
      ),
      useMaterial3: true,
      fontFamily: fontFamilyName,
      scaffoldBackgroundColor: prefs.hypnoticBgEnabled
          ? Colors.transparent
          : f.scaffold.withValues(alpha: 0.90),
      cardColor: f.card,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: (textTheme.titleLarge ?? const TextStyle()).copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      tabBarTheme: TabBarTheme(
        labelStyle: (textTheme.titleSmall ?? const TextStyle()).copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: (textTheme.titleSmall ?? const TextStyle()).copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogTheme: DialogTheme(
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
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
  static ThemeFlair flairFor(AppThemeMode m) => m.flair;
}

