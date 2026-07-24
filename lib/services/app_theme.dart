import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/particle_engine.dart' show ParticlePreset, GlowEffect;

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
    whimsicalDescription: 'A cotton candy megapack with six switchable palettes: Cotton Candy, Neon, Dreamy, Sunset, Bubblegum, and Mulberry. Cycle through pastel pink, electric magenta, whispered rose, golden-hour coral, bright bubblegum pop, and deep crimson-purple — all from one theme.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF1A101F),
      card: Color(0xFF2D1B36),
      primary: Color(0xFFFF69B4), // pink
      secondary: Color(0xFFE8A7F0), // light high-contrast lavender
      headlineStat: Color(0xFFF06292), // rose pink accent
      bulletColor: Color(0xFFE8A7F0),
      bulletGlyph: '✦',
      twinkleBullets: true,
      sparkleNumbers: true,
      numberGlowColor: Color(0xFFFF69B4),
      tabularFigures: false,
      numberSizeScale: 1.05,
      numberWeight: FontWeight.w700,
      numberStyle: FontStyle.italic,
      chipRadius: 18,
      cardRadius: 18,
      dividerColor: Color(0x55FF69B4),
      dividerThickness: 1.0,
      glowPrimary: Color(0x55FF69B4),
      glowSecondary: Color(0x3BF06292),
      auraStyle: AvatarAuraStyle.pastelPulse,
      headerGlyph: '\u2661', // ♡ open heart
      headerUnderlineColor: Color(0x88FF69B4),
    ),
  ),
  unicornII(
    label: 'Unicorn II',
    vibe: 'NEON',
    diff: 'CO-OP',
    elem: 'RAINBOW',
    whimsicalDescription: 'A neon-charged cotton candy overload. Hot pink and electric magenta scream through the dark with an intense radioactive glow. For Gungeoneers who want their pastel with extra voltage.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0F0A14),
      card: Color(0xFF1E1528),
      primary: Color(0xFFFF1493), // neon hot pink
      secondary: Color(0xFFDA70D6), // bright orchid
      headlineStat: Color(0xFFE040FB), // magenta-purple accent
      bulletColor: Color(0xFFFF1493),
      bulletGlyph: '✦',
      twinkleBullets: true,
      sparkleNumbers: true,
      numberGlowColor: Color(0xFFFF1493),
      tabularFigures: false,
      numberSizeScale: 1.08,
      numberWeight: FontWeight.w800,
      numberStyle: FontStyle.italic,
      chipRadius: 16,
      cardRadius: 16,
      dividerColor: Color(0x66FF1493),
      dividerThickness: 1.2,
      glowPrimary: Color(0x66FF1493),
      glowSecondary: Color(0x55E040FB),
      auraStyle: AvatarAuraStyle.pastelPulse,
      headerGlyph: '\u2661',
      headerUnderlineColor: Color(0xAAFF1493),
    ),
  ),
  unicornIII(
    label: 'Unicorn III',
    vibe: 'DREAMY',
    diff: 'CO-OP',
    elem: 'RAINBOW',
    whimsicalDescription: 'A softer, whispered cotton candy. Muted rose and dusty lavender drift like a watercolour sunset. For the Gungeoneer who wants the vibe turned down to a gentle hum.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF1F1825),
      card: Color(0xFF2A2230),
      primary: Color(0xFFF8BBD0), // soft blush pink
      secondary: Color(0xFFD1C4E9), // dusty lavender
      headlineStat: Color(0xFFCE93D8), // lilac accent
      bulletColor: Color(0xFFF8BBD0),
      bulletGlyph: '♡',
      twinkleBullets: false,
      sparkleNumbers: true,
      numberGlowColor: Color(0xFFF8BBD0),
      tabularFigures: false,
      numberSizeScale: 1.03,
      numberWeight: FontWeight.w600,
      numberStyle: FontStyle.italic,
      chipRadius: 20,
      cardRadius: 20,
      dividerColor: Color(0x44F8BBD0),
      dividerThickness: 0.8,
      glowPrimary: Color(0x33F8BBD0),
      glowSecondary: Color(0x22CE93D8),
      auraStyle: AvatarAuraStyle.pastelPulse,
      headerGlyph: '\u2661',
      headerUnderlineColor: Color(0x66F8BBD0),
    ),
  ),
  unicornIV(
    label: 'Unicorn IV',
    vibe: 'SUNSET',
    diff: 'CO-OP',
    elem: 'RAINBOW',
    whimsicalDescription: 'Cotton candy at golden hour. Coral pink and warm peach blend with powder-pink undertones for a sunset-drenched magical vibe. The most romantic way to enter the Gungeon.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF1A1218),
      card: Color(0xFF2A1E26),
      primary: Color(0xFFFF6B9D), // coral pink
      secondary: Color(0xFFFFAB91), // warm peach
      headlineStat: Color(0xFFFFD1DC), // powder pink accent
      bulletColor: Color(0xFFFF6B9D),
      bulletGlyph: '✦',
      twinkleBullets: false,
      sparkleNumbers: true,
      numberGlowColor: Color(0xFFFF6B9D),
      tabularFigures: false,
      numberSizeScale: 1.05,
      numberWeight: FontWeight.w700,
      numberStyle: FontStyle.italic,
      chipRadius: 18,
      cardRadius: 18,
      dividerColor: Color(0x55FF6B9D),
      dividerThickness: 1.0,
      glowPrimary: Color(0x44FF6B9D),
      glowSecondary: Color(0x33FFD1DC),
      auraStyle: AvatarAuraStyle.pastelPulse,
      headerGlyph: '\u2661',
      headerUnderlineColor: Color(0x88FF6B9D),
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
      secondary: Color(0xFFCD9F73), // high-contrast light archival tan
      headlineStat: Color(0xFFFFFDD0), // antique gold
      bulletColor: Color(0xFFD4AF37),
      bulletGlyph: '📖',
      shimmerHeadline: true,
      tabularFigures: true,
      numberSizeScale: 1.08,
      numberWeight: FontWeight.w800,
      chipRadius: 10,
      cardRadius: 12,
      cardBorderColor: Color(0x88D4AF37), // gold border
      cardBorderWidth: 1.2,
      dividerColor: Color(0x55D4AF37),
      dividerThickness: 1.0,
      glowPrimary: Color(0x55D4AF37),
      glowSecondary: Color(0x33CD9F73),
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
      secondary: Color(0xFFFFB74D), // light high-contrast sulfur orange
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
      glowPrimary: Color(0x4DFF4500),
      glowSecondary: Color(0x2EFFB74D),
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
      secondary: Color(0xFF90A4AE), // light high-contrast slate gray-blue
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
      glowPrimary: Color(0x4D00D2FF),
      glowSecondary: Color(0x2E90A4AE),
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
      primary: Color(0xFFFF0033), // Brighter lethal neon curse red!
      secondary: Color(0xFFCE93D8), // light high-contrast corrupted violet
      headlineStat: Color(0xFFFF007F), // curse neon
      bulletColor: Color(0xFFFF0033),
      bulletGlyph: '👹',
      glowCurse: true,
      tabularFigures: true,
      numberSizeScale: 1.05,
      numberWeight: FontWeight.w800,
      chipRadius: 8,
      cardRadius: 12,
      dividerColor: Color(0x77FF0033),
      dividerThickness: 1.0,
      glowPrimary: Color(0x55FF0033),
      glowSecondary: Color(0x33CE93D8),
      auraStyle: AvatarAuraStyle.oxbloodBreath,
      headerGlyph: '\u2020', // †
      headerUnderlineColor: Color(0xAAFF0033),
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
      secondary: Color(0xFF9FA8DA), // light high-contrast stone gray-purple
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
      glowPrimary: Color(0x4DFF9F1C),
      glowSecondary: Color(0x339FA8DA),
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
      secondary: Color(0xFFB388FF), // light high-contrast deep violet
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
      glowPrimary: Color(0x5539FF14),
      glowSecondary: Color(0x33B388FF),
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
      secondary: Color(0xFF81C784), // light high-contrast sewer green
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
      glowPrimary: Color(0x4DFFD700),
      glowSecondary: Color(0x2E81C784),
      auraStyle: AvatarAuraStyle.toxicOoze,
      headerGlyph: '🧀',
      headerUnderlineColor: Color(0x88FFD700),
    ),
  ),
  gungeonProper(
    label: 'Gungeon Proper',
    vibe: 'CLASSIC',
    diff: 'NORMAL',
    elem: 'STONE',
    whimsicalDescription: 'The textbook definition of entering the breach. Clean castle stone blues paired with royal purple accents that recall the long, winding entry halls of the true first floor.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0E1018),
      card: Color(0xFF1A1E2E),
      primary: Color(0xFF4682B4),
      secondary: Color(0xFF9370DB),
      headlineStat: Color(0xFF87CEEB),
      bulletColor: Color(0xFF4682B4),
      bulletGlyph: '🏰',
      tabularFigures: true,
      numberSizeScale: 1.0,
      numberWeight: FontWeight.w800,
      chipRadius: 10,
      cardRadius: 12,
      cardBorderColor: Color(0x444682B4),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x554682B4),
      dividerThickness: 1.0,
      glowPrimary: Color(0x4D4682B4),
      glowSecondary: Color(0x2E9370DB),
      auraStyle: AvatarAuraStyle.brassConic,
      headerGlyph: '🏰',
      headerUnderlineColor: Color(0x884682B4),
    ),
  ),
  theOubliette(
    label: 'The Oubliette',
    vibe: 'TOXIC',
    diff: 'HARD',
    elem: 'SLUDGE',
    whimsicalDescription: 'Descend into the hidden, damp pipeline layer. A layout covered in industrial sewer muck, rusted pipework bronze, and bright toxic spills that pop sharply against the dark.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0A0F08),
      card: Color(0xFF141A10),
      primary: Color(0xFF39FF14),
      secondary: Color(0xFF795548),
      headlineStat: Color(0xFFCCFF00),
      bulletColor: Color(0xFF39FF14),
      bulletGlyph: '☣',
      tabularFigures: true,
      numberSizeScale: 1.0,
      numberWeight: FontWeight.w800,
      chipRadius: 8,
      cardRadius: 10,
      cardBorderColor: Color(0x4439FF14),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x5539FF14),
      dividerThickness: 1.0,
      glowPrimary: Color(0x4D39FF14),
      glowSecondary: Color(0x2E795548),
      auraStyle: AvatarAuraStyle.toxicOoze,
      headerGlyph: '☣',
      headerUnderlineColor: Color(0x8839FF14),
    ),
  ),
  pastParadox(
    label: 'Past Paradox',
    vibe: 'COSMIC',
    diff: 'BRUTAL',
    elem: 'VOID',
    whimsicalDescription: 'Kill your past or fracture the space-time continuum trying. Features deep stellar space backdrops cracked wide open by unstable, flashing neon cosmic energy.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF050308),
      card: Color(0xFF0E0A1A),
      primary: Color(0xFF00E5FF),
      secondary: Color(0xFF6A1B9A),
      headlineStat: Color(0xFFE0F7FA),
      bulletColor: Color(0xFF00E5FF),
      bulletGlyph: '🌌',
      tabularFigures: true,
      numberSizeScale: 1.05,
      numberWeight: FontWeight.w800,
      chipRadius: 10,
      cardRadius: 12,
      cardBorderColor: Color(0x4400E5FF),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x5500E5FF),
      dividerThickness: 1.0,
      glowPrimary: Color(0x5500E5FF),
      glowSecondary: Color(0x336A1B9A),
      auraStyle: AvatarAuraStyle.cosmicTemporal,
      headerGlyph: '🌌',
      headerUnderlineColor: Color(0xAA00E5FF),
    ),
  ),
  highPriestVoid(
    label: 'High Priest Void',
    vibe: 'MYSTIC',
    diff: 'EXPERT',
    elem: 'SHADOW',
    whimsicalDescription: 'Immerse your loadout tracker in the ominous shadows of the true gun cultists. Dark ritual violet panels broken apart by flickering candle yellow and unstable boss accents.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0A0510),
      card: Color(0xFF160B20),
      primary: Color(0xFF8B008B),
      secondary: Color(0xFFFFD54F),
      headlineStat: Color(0xFFE1BEE7),
      bulletColor: Color(0xFF8B008B),
      bulletGlyph: '👁',
      tabularFigures: true,
      numberSizeScale: 1.0,
      numberWeight: FontWeight.w800,
      chipRadius: 10,
      cardRadius: 12,
      cardBorderColor: Color(0x448B008B),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x558B008B),
      dividerThickness: 1.0,
      glowPrimary: Color(0x4D8B008B),
      glowSecondary: Color(0x2EFFD54F),
      auraStyle: AvatarAuraStyle.lichPurple,
      headerGlyph: '👁',
      headerUnderlineColor: Color(0x888B008B),
    ),
  ),
  robotsCore(
    label: "Robot's Core",
    vibe: 'CYBER',
    diff: 'NORMAL',
    elem: 'CIRCUIT',
    whimsicalDescription: 'Ditch organic hearts entirely for pure cold steel. A ultra-clean, calculated cybernetic UI system featuring high-voltage electrical blues and neon green terminal readout indicators.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0A0F0E),
      card: Color(0xFF101818),
      primary: Color(0xFF00F5D4),
      secondary: Color(0xFF69F0AE),
      headlineStat: Color(0xFFB2DFDB),
      bulletColor: Color(0xFF00F5D4),
      bulletGlyph: '🤖',
      tabularFigures: true,
      numberSizeScale: 1.0,
      numberWeight: FontWeight.w800,
      chipRadius: 8,
      cardRadius: 10,
      cardBorderColor: Color(0x4400F5D4),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x5500F5D4),
      dividerThickness: 1.0,
      glowPrimary: Color(0x4D00F5D4),
      glowSecondary: Color(0x2E69F0AE),
      auraStyle: AvatarAuraStyle.frostRing,
      headerGlyph: '🤖',
      headerUnderlineColor: Color(0x8800F5D4),
    ),
  ),
  cultOfGundead(
    label: 'Cult of Gundead',
    vibe: 'RETRO',
    diff: 'NORMAL',
    elem: 'BRASS',
    whimsicalDescription: 'Pay homage to the standard, loyal foot soldiers of the gungeoneers\' demise. Formatted with soft ammunition brass tones and target practice reds on lead gray backdrops.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0D0B08),
      card: Color(0xFF1A1610),
      primary: Color(0xFFFF0000),
      secondary: Color(0xFFCD9F73),
      headlineStat: Color(0xFFFFD700),
      bulletColor: Color(0xFFCD9F73),
      bulletGlyph: '🎯',
      tabularFigures: true,
      numberSizeScale: 1.0,
      numberWeight: FontWeight.w800,
      chipRadius: 8,
      cardRadius: 10,
      cardBorderColor: Color(0x44CD9F73),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x55CD9F73),
      dividerThickness: 1.0,
      glowPrimary: Color(0x4DFF0000),
      glowSecondary: Color(0x2ECD9F73),
      auraStyle: AvatarAuraStyle.brassConic,
      headerGlyph: '🎯',
      headerUnderlineColor: Color(0x88CD9F73),
    ),
  ),
  synergySurge(
    label: 'Synergy Surge',
    vibe: 'ENERGETIC',
    diff: 'CO-OP',
    elem: 'FUSION',
    whimsicalDescription: 'When your inventory items fuse together perfectly. An ultra-bright, dynamic color palette based on the iconic blue arrows that appear above your gungeoneer during a item pairing.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF080B14),
      card: Color(0xFF101828),
      primary: Color(0xFF00B4D8),
      secondary: Color(0xFF42A5F5),
      headlineStat: Color(0xFFE3F2FD),
      bulletColor: Color(0xFF00B4D8),
      bulletGlyph: '🔷',
      tabularFigures: true,
      numberSizeScale: 1.05,
      numberWeight: FontWeight.w800,
      chipRadius: 10,
      cardRadius: 12,
      cardBorderColor: Color(0x4400B4D8),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x5500B4D8),
      dividerThickness: 1.0,
      glowPrimary: Color(0x5500B4D8),
      glowSecondary: Color(0x3342A5F5),
      auraStyle: AvatarAuraStyle.cosmicTemporal,
      headerGlyph: '🔷',
      headerUnderlineColor: Color(0xAA00B4D8),
    ),
  ),
  glitchedChest(
    label: 'Glitched Chest',
    vibe: 'CORRUPTED',
    diff: 'CHAOS',
    elem: 'ERROR',
    whimsicalDescription: 'Something went terribly wrong with the chest generation parameters. A distinct glitch aesthetic combining harsh digital greens and magenta color visual artifacts over a pitch-black terminal frame.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF000000),
      card: Color(0xFF0A0A0A),
      primary: Color(0xFFFF00E4),
      secondary: Color(0xFF00FF41),
      headlineStat: Color(0xFFE0E0E0),
      bulletColor: Color(0xFF00FF41),
      bulletGlyph: '💾',
      tabularFigures: true,
      numberSizeScale: 1.05,
      numberWeight: FontWeight.w800,
      chipRadius: 4,
      cardRadius: 6,
      cardBorderColor: Color(0x44FF00E4),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x55FF00E4),
      dividerThickness: 1.0,
      glowPrimary: Color(0x55FF00E4),
      glowSecondary: Color(0x3300FF41),
      auraStyle: AvatarAuraStyle.voidPulse,
      headerGlyph: '💾',
      headerUnderlineColor: Color(0xAAFF00E4),
    ),
  ),
  lichsTomb(
    label: "Lich's Tomb",
    vibe: 'ELDRITCH',
    diff: 'EXTREME',
    elem: 'BONE',
    whimsicalDescription: 'Stand face to face with the master of the gungeon floor layout. Features skeletal bone white indicators slicing through eerie, lingering phantom teal lines and deep crypt shadows.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF060808),
      card: Color(0xFF0E1212),
      primary: Color(0xFF2EC4B6),
      secondary: Color(0xFFE0E0E0),
      headlineStat: Color(0xFFF5F5DC),
      bulletColor: Color(0xFF2EC4B6),
      bulletGlyph: '☠',
      tabularFigures: true,
      numberSizeScale: 1.05,
      numberWeight: FontWeight.w800,
      chipRadius: 8,
      cardRadius: 10,
      cardBorderColor: Color(0x442EC4B6),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x552EC4B6),
      dividerThickness: 1.0,
      glowPrimary: Color(0x552EC4B6),
      glowSecondary: Color(0x33E0E0E0),
      auraStyle: AvatarAuraStyle.lichPurple,
      headerGlyph: '☠',
      headerUnderlineColor: Color(0xAA2EC4B6),
    ),
  ),
  winchestersGame(
    label: "Winchester's Game",
    vibe: 'CARNIVAL',
    diff: 'CASUAL',
    elem: 'TARGET',
    whimsicalDescription: "Step right up and test your bouncing shot trajectories. A warm, rustic carnival aesthetic balancing dark wood backgrounds with vibrant ticket orange and practice target green.",
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0F0A06),
      card: Color(0xFF1C1408),
      primary: Color(0xFFF77F00),
      secondary: Color(0xFF66BB6A),
      headlineStat: Color(0xFFFFE082),
      bulletColor: Color(0xFFF77F00),
      bulletGlyph: '🎯',
      tabularFigures: true,
      numberSizeScale: 1.0,
      numberWeight: FontWeight.w700,
      chipRadius: 10,
      cardRadius: 12,
      cardBorderColor: Color(0x44F77F00),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x55F77F00),
      dividerThickness: 1.0,
      glowPrimary: Color(0x4DF77F00),
      glowSecondary: Color(0x2E66BB6A),
      auraStyle: AvatarAuraStyle.brassConic,
      headerGlyph: '🎯',
      headerUnderlineColor: Color(0x88F77F00),
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
    if (this == AppThemeMode.unicorn) {
      return AppTheme.unicornPalette.flair;
    }
    if (kThemeRemixes.containsKey(this)) {
      final remixes = kThemeRemixes[this]!;
      final idx = AppTheme.remixFor(this);
      if (idx > 0 && idx < remixes.length) {
        final remix = remixes[idx];
        if (remix.flair != null) return remix.flair!;
        return _hueShiftFlair(_staticFlair!, remix.hueShift);
      }
    }
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

/// Palette variants for the Unicorn megapack. The first four map to
/// the original Unicorn I-IV flairs; Bubblegum and Mulberry are
/// standalone palettes in the same pink/crimson/purple family.
enum UnicornPalette {
  cottonCandy,
  neon,
  dreamy,
  sunset,
  bubblegum,
  mulberry;

  String get label => switch (this) {
        cottonCandy => 'Cotton Candy',
        neon => 'Neon',
        dreamy => 'Dreamy',
        sunset => 'Sunset',
        bubblegum => 'Bubblegum',
        mulberry => 'Mulberry',
      };

  ThemeFlair get flair => switch (this) {
        cottonCandy => AppThemeMode.unicorn._staticFlair!,
        neon => AppThemeMode.unicornII._staticFlair!,
        dreamy => AppThemeMode.unicornIII._staticFlair!,
        sunset => AppThemeMode.unicornIV._staticFlair!,
        bubblegum => const ThemeFlair(
          scaffold: Color(0xFF1A0F1E),
          card: Color(0xFF2A1A30),
          primary: Color(0xFFFF80AB), // bubblegum pink
          secondary: Color(0xFFE040FB), // magenta
          headlineStat: Color(0xFFB388FF), // light violet
          bulletColor: Color(0xFFFF80AB),
          bulletGlyph: '✦',
          twinkleBullets: true,
          sparkleNumbers: true,
          numberGlowColor: Color(0xFFFF80AB),
          tabularFigures: false,
          numberSizeScale: 1.06,
          numberWeight: FontWeight.w700,
          numberStyle: FontStyle.italic,
          chipRadius: 18,
          cardRadius: 18,
          dividerColor: Color(0x55FF80AB),
          dividerThickness: 1.0,
          glowPrimary: Color(0x44FF80AB),
          glowSecondary: Color(0x33B388FF),
          auraStyle: AvatarAuraStyle.pastelPulse,
          headerGlyph: '\u2661',
          headerUnderlineColor: Color(0x88FF80AB),
        ),
        mulberry => const ThemeFlair(
          scaffold: Color(0xFF1C0A18),
          card: Color(0xFF2E1228),
          primary: Color(0xFFC2185B), // deep magenta-mulberry
          secondary: Color(0xFF9C27B0), // purple
          headlineStat: Color(0xFFF06292), // pink
          bulletColor: Color(0xFFC2185B),
          bulletGlyph: '✦',
          twinkleBullets: true,
          sparkleNumbers: true,
          numberGlowColor: Color(0xFFC2185B),
          tabularFigures: false,
          numberSizeScale: 1.06,
          numberWeight: FontWeight.w700,
          numberStyle: FontStyle.italic,
          chipRadius: 18,
          cardRadius: 18,
          dividerColor: Color(0x55C2185B),
          dividerThickness: 1.0,
          glowPrimary: Color(0x44C2185B),
          glowSecondary: Color(0x33F06292),
          auraStyle: AvatarAuraStyle.pastelPulse,
          headerGlyph: '\u2661',
          headerUnderlineColor: Color(0x77C2185B),
        ),
      };
}

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
  AppThemeMode.unicorn,
  AppThemeMode.forgeMaster,
  AppThemeMode.robotsCore,
  AppThemeMode.custom,
];

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
      case AppThemeMode.unicornII:
        return 'Unicorn Neon';
      case AppThemeMode.unicornIII:
        return 'Unicorn Dream';
      case AppThemeMode.unicornIV:
        return 'Unicorn Sunset';
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
      case AppThemeMode.gungeonProper:
        return 'Gungeon Proper';
      case AppThemeMode.theOubliette:
        return 'The Oubliette';
      case AppThemeMode.pastParadox:
        return 'Past Paradox';
      case AppThemeMode.highPriestVoid:
        return 'High Priest Void';
      case AppThemeMode.robotsCore:
        return "Robot's Core";
      case AppThemeMode.cultOfGundead:
        return 'Cult of Gundead';
      case AppThemeMode.synergySurge:
        return 'Synergy Surge';
      case AppThemeMode.glitchedChest:
        return 'Glitched Chest';
      case AppThemeMode.lichsTomb:
        return "Lich's Tomb";
      case AppThemeMode.winchestersGame:
        return "Winchester's Game";
      case AppThemeMode.custom:
        return AppTheme._customThemeName;
    }
  }

  String get tagline {
    switch (this) {
      case AppThemeMode.unicorn:
        return '${AppTheme.unicornPalette.label} — 6 palettes in one megapack';
      case AppThemeMode.unicornII:
        return 'Neon Candy — hot pink, electric magenta, glow';
      case AppThemeMode.unicornIII:
        return 'Soft Dream — blush, dusty lavender, lilac';
      case AppThemeMode.unicornIV:
        return 'Sunset Candy — coral, peach, powder pink';
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
      case AppThemeMode.gungeonProper:
        return 'Classic Dungeon — castle stone blue, royal purple, iron gray';
      case AppThemeMode.theOubliette:
        return 'Secret Sewer — sludge green, corroded bronze, toxic lime';
      case AppThemeMode.pastParadox:
        return 'Time Rift — cosmic black, neon cyan, void violet';
      case AppThemeMode.highPriestVoid:
        return 'Cultist Chamber — void purple, candle yellow, shadow magenta';
      case AppThemeMode.robotsCore:
        return 'Cybernetic — circuit teal, battery green, steel gray';
      case AppThemeMode.cultOfGundead:
        return 'Bullet Kin — brass gold, lead gray, target red';
      case AppThemeMode.synergySurge:
        return 'Blue Arrow — synergy teal, chest blue, electric white';
      case AppThemeMode.glitchedChest:
        return 'Error Code — terminal black, artifact magenta, glitch green';
      case AppThemeMode.lichsTomb:
        return 'Final Stand — bone white, phantom teal, crypt charcoal';
      case AppThemeMode.winchestersGame:
        return 'Target Practice — fairground green, ticket orange, wood brown';
      case AppThemeMode.custom:
        return 'Custom — your personal palette';
    }
  }
}

/// Per-theme preview data for the theme picker cards. Each theme gets
/// custom stats, bullet notes, and a subheading that showcases its
/// palette identity with real Gungeon flavor.
class ThemePreviewData {
  final String subheading;
  final List<String> stats;
  final List<String> bulletNotes;

  const ThemePreviewData({
    required this.subheading,
    required this.stats,
    required this.bulletNotes,
  });
}

/// Preview data for each visible theme. Keyed by enum index for O(1) lookup.
const Map<AppThemeMode, ThemePreviewData> kThemePreviewData = {
  AppThemeMode.ammonomicon: ThemePreviewData(
    subheading: 'Ancient Lore — Deep Book-Leather, Antique Gold, Crisp Teal',
    stats: ['Infinite Ammo', 'Quality: S', 'Magnificence: 0'],
    bulletNotes: [
      '📖 Added to the clean log',
      '📖 Synergy match detected',
      '📖 Item description updated',
    ],
  ),
  AppThemeMode.theBreach: ThemePreviewData(
    subheading: 'Safe Haven — Stonework Gray, Hearthstone Amber, Warm Brass',
    stats: ['0.0 Curse', '100% Safety', 'Shop Cost: 45'],
    bulletNotes: [
      '⭐ Run successfully prepared',
      '⭐ NPC dialog refreshed',
      '⭐ Hegemony credits updated',
    ],
  ),
  AppThemeMode.unicorn: ThemePreviewData(
    subheading: 'Cotton Candy — Pastel Lavender, Sugar Pink, Rose Accent',
    stats: ['Bubblegum Mode', 'Sparkle Index: 100', 'Bowler Approved'],
    bulletNotes: [
      '✨ Rainbow chest opened',
      '✨ Cute projectile trailing active',
      '✨ Sparkle modifier maximum',
    ],
  ),
  AppThemeMode.unicornII: ThemePreviewData(
    subheading: 'Neon Candy — Hot Pink, Electric Magenta, Radioactive Glow',
    stats: ['Neon Overload', 'Glow: 200%', 'Voltage: Max'],
    bulletNotes: [
      '✨ Neon chest electrified',
      '✨ Glowing projectile active',
      '✨ Voltage modifier peaked',
    ],
  ),
  AppThemeMode.unicornIII: ThemePreviewData(
    subheading: 'Soft Dream — Blush Pink, Dusty Lavender, Lilac Accent',
    stats: ['Dream Mode', 'Softness: 100', 'Whisper Approved'],
    bulletNotes: [
      '♡ Gentle chest opened',
      '♡ Soft projectile drifting',
      '♡ Dreamy modifier steady',
    ],
  ),
  AppThemeMode.unicornIV: ThemePreviewData(
    subheading: 'Sunset Candy — Coral Pink, Warm Peach, Powder Pink Accent',
    stats: ['Sunset Mode', 'Warmth: 100', 'Golden Hour'],
    bulletNotes: [
      '✨ Coral chest discovered',
      '✨ Warm projectile glowing',
      '✨ Sunset modifier active',
    ],
  ),
  AppThemeMode.forgeMaster: ThemePreviewData(
    subheading: 'Blacksmith — Obsidian Black, Molten Sulfur, Dragun Flame',
    stats: ['DPS: 999', 'Fire Proof', 'Master Round V'],
    bulletNotes: [
      '🔥 Blacksmith order complete',
      '🔥 Weapon shell heated',
      '🔥 Obsidian casing attached',
    ],
  ),
  AppThemeMode.hollowChill: ThemePreviewData(
    subheading: 'Grave Cold — Spectral Tomb Blue, Phantom Cyan, Mist Gray',
    stats: ['Freeze Rate: Max', 'Heart Tiers: Ice', 'Chill Factor: 10'],
    bulletNotes: [
      '❄️ Ghostly presence encountered',
      '❄️ Room temperature dropped',
      '❄️ Ice chunk shattered',
    ],
  ),
  AppThemeMode.lordJammed: ThemePreviewData(
    subheading: 'Curse Born — Oxblood Red, Corrupted Void Violet, Curse Neon',
    stats: ['Curse Level: 10+', 'Stalker Spawned', 'Red Shot DMG x2'],
    bulletNotes: [
      '👿 Soul curse maximized',
      '👿 Jammed enemy variations found',
      '👿 Red visual filter applied',
    ],
  ),
  AppThemeMode.bulletHell: ThemePreviewData(
    subheading: 'Sixth Chamber — Ash Gray, Toxic Green, Soul Purple',
    stats: ['Chamber: 6', 'Extreme Danger', 'Unforgiving Layout'],
    bulletNotes: [
      '💀 Chamber entry sealed',
      '💀 Poison pool stepped over',
      '💀 Bullet hell active',
    ],
  ),
  AppThemeMode.resourcefulRat: ThemePreviewData(
    subheading: 'Lair Hoard — Sewer Green, Stolen Gold, Cheese Yellow',
    stats: ['4-Way Vector', 'Punchout Ready', 'Gnawed Key'],
    bulletNotes: [
      '🧀 Left a mocking note',
      '🧀 Infuriating puzzle solved',
      '🧀 Ammo box pilfered',
    ],
  ),
  AppThemeMode.gungeonProper: ThemePreviewData(
    subheading: 'Chamber 1 — Castle Stone Blue, Royal Purple, Dungeon Iron',
    stats: ['Floor: 1', 'Keys: 2', 'Secret Room Found'],
    bulletNotes: [
      '🏰 Iron key turned',
      '🏰 Basic chest located',
      '🏰 Trap door discovered',
    ],
  ),
  AppThemeMode.theOubliette: ThemePreviewData(
    subheading: 'Secret Sewer — Sludge Green, Corroded Bronze, Toxic Lime',
    stats: ['Poison Immune', 'Sewage Level: High', 'Old Crest Safe'],
    bulletNotes: [
      '☣️ Sewage valve turned',
      '☣️ Shield preservation checked',
      '☣️ Grate pathway cleared',
    ],
  ),
  AppThemeMode.pastParadox: ThemePreviewData(
    subheading: 'Time Rift — Cosmic Nebula Black, Neon Cyan, Void Violet',
    stats: ['Time Index: Void', 'Paradox Cost: 5', 'Weapon Swapped'],
    bulletNotes: [
      '🌌 Alternate reality loaded',
      '🌌 Space rift fluctuating',
      '🌌 Past timeline rewritten',
    ],
  ),
  AppThemeMode.highPriestVoid: ThemePreviewData(
    subheading: 'Cultist Chamber — Void Purple, Candle Yellow, Shadow Magenta',
    stats: ['Unseen Target', 'Darkness Multiplier', 'Chamber 3 Boss'],
    bulletNotes: [
      '👁️ Cultist hood equipped',
      '👁️ Wall lantern blown out',
      '👁️ Dark room bullet tracked',
    ],
  ),
  AppThemeMode.robotsCore: ThemePreviewData(
    subheading: 'Cybernetic — Circuit Teal, Battery Green, Matte Steel Gray',
    stats: ['Armor Count: 6', 'Coolant: 100%', 'Junk DMG Boost'],
    bulletNotes: [
      '🤖 Coolant tank deployed',
      '🤖 Shield capacitor charged',
      '🤖 Junk scrap collected',
    ],
  ),
  AppThemeMode.cultOfGundead: ThemePreviewData(
    subheading: 'Bullet Kin — Soft Brass Gold, Lead Gray, Target Red',
    stats: ['Kin Count: 99', 'Caliber: Standard', 'Caped Bullet Spawned'],
    bulletNotes: [
      '🎯 Bandana tied tight',
      '🎯 Waddle movement synced',
      '🎯 Target reticle centered',
    ],
  ),
  AppThemeMode.synergySurge: ThemePreviewData(
    subheading: 'Blue Arrow — Synergy Teal, Chest Blue, Electric White',
    stats: ['Synergies: 7', 'Buff: Overwhelming', 'Dual Wielding'],
    bulletNotes: [
      '🔷 Synergy fusion unlocked',
      '🔷 Secondary weapon modified',
      '🔷 Projectile overlay generated',
    ],
  ),
  AppThemeMode.glitchedChest: ThemePreviewData(
    subheading: 'Error Code — Terminal Black, Artifact Magenta, Glitch Green',
    stats: ['ERR: NULL', 'Dual Beholsters', 'Loot Drops x8'],
    bulletNotes: [
      '💾 Memory buffer overflow',
      '💾 Double boss arena spawned',
      '💾 UI asset rendered wrong',
    ],
  ),
  AppThemeMode.lichsTomb: ThemePreviewData(
    subheading: 'Final Stand — Bone White, Phantom Teal, Crypt Charcoal',
    stats: ['Phase: III', 'Boss Level: Absolute', 'Gungeon Mastered'],
    bulletNotes: [
      '☠️ Final boss phase initiated',
      '☠️ Soul tether connected',
      '☠️ Chamber victory logged',
    ],
  ),
  AppThemeMode.winchestersGame: ThemePreviewData(
    subheading: 'Target Practice — Fairground Green, Ticket Orange, Wood Brown',
    stats: ['Targets Hit: 4/4', 'Ace Rank', 'Shots Remaining: 0'],
    bulletNotes: [
      '🎯 Bouncing trajectory calculated',
      '🎯 Target shattered cleanly',
      '🎯 Black chest reward earned',
    ],
  ),
  AppThemeMode.custom: ThemePreviewData(
    subheading: 'Custom — Your Personal Palette',
    stats: ['Custom Stats', 'User Defined', 'Personal Touch'],
    bulletNotes: [
      '• Custom note one',
      '• Custom note two',
      '• Custom note three',
    ],
  ),
};

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
        'scaffold': data.scaffold.toARGB32(),
        'card': data.card.toARGB32(),
        'primary': data.primary.toARGB32(),
        'secondary': data.secondary.toARGB32(),
        'headlineStat': data.headlineStat.toARGB32(),
        'bulletColor': data.bulletColor.toARGB32(),
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
    auraStyle: AvatarAuraStyle.none,
    font: AppFont.gungeon,
  );

  /// Generate a random custom theme with a lore-style name.
  static CustomThemeData random() {
    final rng = math.Random();
    final nameGen = _RandomNameGenerator(rng);
    final colorGen = _RandomColorGenerator(rng);
    final colors = colorGen.getColors();
    return CustomThemeData(
      name: nameGen.generate(),
      scaffold: colors[0],
      card: colors[1],
      primary: colors[2],
      secondary: colors[3],
      headlineStat: colors[4],
      bulletColor: colors[5],
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
      auraStyle: auraStyle ?? this.auraStyle,
      font: font ?? this.font,
    );
  }
}

/// Helper for generating lore-style random theme names.
class _RandomNameGenerator {
  static const _adjectives = [
    'Angry', 'Jammed', 'Cursed', 'Glitched', 'Mimic', 'Tactical',
    'Duct-Taped', 'Searing', 'Spectral', 'Toxic', 'Golden', 'Rusty',
    'Dragun', 'High-Tier', 'Coolmaxing', 'Synergy', 'Shunted', 'Blazing',
    'Hollowed', 'Shaking', 'Wobbling', 'Goopian', 'Archival', 'Bullet-Bore',
  ];
  static const _entities = [
    'Bulletkin', 'Cultist', 'Beholster', 'Blobulord', 'Gorgun', 'Dragun',
    'Mine Flayer', 'Rat', 'Gatling Gull', 'Gunnut', 'Lead Maiden', 'Ammolet',
    'Shell', 'Casey', 'Master Round', 'Hegemony', 'Synergrace', 'Bello',
    'Winchester', 'Frifle', 'Manuel', 'Gunfortuna', 'Gungeoneer', 'Shellmet',
  ];

  final math.Random _rng;

  _RandomNameGenerator(this._rng);

  String generate() {
    final adj = _adjectives[_rng.nextInt(_adjectives.length)];
    final ent = _entities[_rng.nextInt(_entities.length)];
    return '$adj $ent';
  }
}

/// Helper for generating random harmonious colors.
class _RandomColorGenerator {
  final math.Random _rng;

  // 20 Lore-Authentic, curated Gungeon color schemas (Scaffold, Card, Primary, Secondary, Headline, Bullet)
  static const List<List<Color>> _schemas = [
    // 1. Gungeon Green (Oubliette)
    [Color(0xFF0D140E), Color(0xFF162218), Color(0xFF39FF14), Color(0xFF00FF87), Color(0xFFCCFF00), Color(0xFF39FF14)],
    // 2. Bullet Kin Brass
    [Color(0xFF111112), Color(0xFF1E1C1A), Color(0xFFFF9F1C), Color(0xFFCD9F73), Color(0xFFFFD166), Color(0xFFFF9F1C)],
    // 3. Hollow Chill Spectral
    [Color(0xFF081016), Color(0xFF111E29), Color(0xFF00D2FF), Color(0xFF90A4AE), Color(0xFFE0F7FA), Color(0xFF00D2FF)],
    // 4. Dragun Fire
    [Color(0xFF090706), Color(0xFF191210), Color(0xFFFF4500), Color(0xFFFFB74D), Color(0xFFFFD54F), Color(0xFFFF4500)],
    // 5. Gungeon Blue (The Breach)
    [Color(0xFF0E1116), Color(0xFF1B1E26), Color(0xFF00E5FF), Color(0xFF5C6BC0), Color(0xFF80DEEA), Color(0xFF00E5FF)],
    // 6. Lich Purple (Bullet Hell)
    [Color(0xFF08030C), Color(0xFF160721), Color(0xFFCE93D8), Color(0xFF990000), Color(0xFFFF007F), Color(0xFFCE93D8)],
    // 7. High-Tier Chest Red (Synergy)
    [Color(0xFF14070A), Color(0xFF261014), Color(0xFFFF1E27), Color(0xFFFFD700), Color(0xFFFF8A80), Color(0xFFFF1E27)],
    // 8. Cultist Pink
    [Color(0xFF140D1D), Color(0xFF231633), Color(0xFFFF4081), Color(0xFFE040FB), Color(0xFFF8BBD0), Color(0xFFFF4081)],
    // 9. Glitch Chest Neon
    [Color(0xFF0B1214), Color(0xFF152226), Color(0xFF00E5FF), Color(0xFFFF007F), Color(0xFFE040FB), Color(0xFF00E5FF)],
    // 10. Gunfortuna Gold
    [Color(0xFF0D0C0B), Color(0xFF1C1916), Color(0xFFFFD700), Color(0xFFFFB74D), Color(0xFFFFFDD0), Color(0xFFFFD700)],
    // 11. Rogue Marine Olive
    [Color(0xFF0E120D), Color(0xFF1B2217), Color(0xFF4CAF50), Color(0xFFFF7043), Color(0xFFA5D6A7), Color(0xFF4CAF50)],
    // 12. Convict Yellow
    [Color(0xFF14120D), Color(0xFF231E15), Color(0xFFFFB300), Color(0xFF78909C), Color(0xFFFFE082), Color(0xFFFFB300)],
    // 13. Hunter Crossbow
    [Color(0xFF0A0F0D), Color(0xFF152219), Color(0xFF66BB6A), Color(0xFF29B6F6), Color(0xFFC8E6C9), Color(0xFF66BB6A)],
    // 14. Pilot Blue
    [Color(0xFF0D121F), Color(0xFF182236), Color(0xFF29B6F6), Color(0xFFFFCA28), Color(0xFFE1F5FE), Color(0xFF29B6F6)],
    // 15. Synergy Chest Pink
    [Color(0xFF0D0B1C), Color(0xFF171333), Color(0xFFEC407A), Color(0xFF5C6BC0), Color(0xFFF8BBD0), Color(0xFFEC407A)],
    // 16. Duct Tape Steel
    [Color(0xFF111314), Color(0xFF212529), Color(0xFFB0BEC5), Color(0xFFFF7043), Color(0xFFECEFF1), Color(0xFFB0BEC5)],
    // 17. Casey Bat Brown
    [Color(0xFF120E0D), Color(0xFF241A17), Color(0xFF8D6E63), Color(0xFFFF8A80), Color(0xFFD7CCC8), Color(0xFF8D6E63)],
    // 18. Chamber 1.5 Sewer
    [Color(0xFF0F0E0D), Color(0xFF221F1C), Color(0xFF81C784), Color(0xFF795548), Color(0xFFC8E6C9), Color(0xFF81C784)],
    // 19. Sir Manuel Armor
    [Color(0xFF111417), Color(0xFF20262C), Color(0xFF90A4AE), Color(0xFFFFD54F), Color(0xFFECEFF1), Color(0xFF90A4AE)],
    // 20. Master Round Crimson
    [Color(0xFF14080D), Color(0xFF261019), Color(0xFFFF1133), Color(0xFFFFD700), Color(0xFFFF8A80), Color(0xFFFF1133)],
  ];

  _RandomColorGenerator(this._rng);

  List<Color> getColors() {
    // Return a curated pre-balanced Gungeon color scheme, completely oiled up!
    return _schemas[_rng.nextInt(_schemas.length)];
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

  /// Whether headline numbers should be surrounded by tiny twinkling
  /// sparkles (Unicorn signature). Renders a few animated star glyphs
  /// that pulse and fade around the number.
  final bool sparkleNumbers;

  /// Optional glow colour for headline numbers. When non-null, numbers
  /// get a soft outer glow in this colour. Used by Unicorn palettes to
  /// make stats feel magical.
  final Color? numberGlowColor;

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
    this.sparkleNumbers = false,
    this.numberGlowColor,
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
    this.glowPrimary = const Color(0x22FFFFFF),
    this.glowSecondary = const Color(0x11FFFFFF),
    this.auraStyle = AvatarAuraStyle.none,
    this.headerGlyph,
    this.headerAllCaps = false,
    this.headerUnderlineColor,
    this.pageFrame = false,
  });
}

/// Shift the hue of a [Color] by [degrees] in HSL space.
Color _hueShift(Color c, double degrees) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withHue((hsl.hue + degrees) % 360).toColor();
}

/// Return a copy of [f] with every [Color] field hue-shifted by [degrees].
ThemeFlair _hueShiftFlair(ThemeFlair f, double degrees) {
  if (degrees == 0) return f;
  return ThemeFlair(
    scaffold: _hueShift(f.scaffold, degrees),
    card: _hueShift(f.card, degrees),
    primary: _hueShift(f.primary, degrees),
    secondary: _hueShift(f.secondary, degrees),
    headlineStat: _hueShift(f.headlineStat, degrees),
    bulletColor: _hueShift(f.bulletColor, degrees),
    bulletGlyph: f.bulletGlyph,
    shimmerHeadline: f.shimmerHeadline,
    sparkleNumbers: f.sparkleNumbers,
    numberGlowColor: f.numberGlowColor != null ? _hueShift(f.numberGlowColor!, degrees) : null,
    twinkleBullets: f.twinkleBullets,
    glowCurse: f.glowCurse,
    embossNumbers: f.embossNumbers,
    tabularFigures: f.tabularFigures,
    numberSizeScale: f.numberSizeScale,
    numberWeight: f.numberWeight,
    numberStyle: f.numberStyle,
    chipRadius: f.chipRadius,
    cardRadius: f.cardRadius,
    cardBorderColor: f.cardBorderColor != null ? _hueShift(f.cardBorderColor!, degrees) : null,
    cardBorderWidth: f.cardBorderWidth,
    chipFilled: f.chipFilled,
    dividerColor: f.dividerColor != null ? _hueShift(f.dividerColor!, degrees) : null,
    dividerThickness: f.dividerThickness,
    glowPrimary: _hueShift(f.glowPrimary, degrees),
    glowSecondary: _hueShift(f.glowSecondary, degrees),
    auraStyle: f.auraStyle,
    headerGlyph: f.headerGlyph,
    headerAllCaps: f.headerAllCaps,
    headerUnderlineColor: f.headerUnderlineColor != null ? _hueShift(f.headerUnderlineColor!, degrees) : null,
    pageFrame: f.pageFrame,
  );
}

/// A single remix variant. When [flair] is non-null it replaces the
/// theme's static flair entirely; otherwise [hueShift] is applied.
class ThemeRemix {
  final String label;
  final double hueShift;
  final ThemeFlair? flair;
  const ThemeRemix({required this.label, this.hueShift = 0, this.flair});
}

/// Per-theme remix options. Unicorn uses [UnicornPalette] instead.
const kThemeRemixes = <AppThemeMode, List<ThemeRemix>>{
  AppThemeMode.forgeMaster: [
    ThemeRemix(label: 'Original'),
    ThemeRemix(label: 'Ember', hueShift: 12),
    ThemeRemix(label: 'Magma', hueShift: 30),
    ThemeRemix(label: 'Inferno', hueShift: -12),
  ],
  AppThemeMode.robotsCore: [
    ThemeRemix(label: 'Original'),
    ThemeRemix(label: 'Rust', hueShift: -25),
    ThemeRemix(
      label: 'Arc Flash',
      flair: ThemeFlair(
        scaffold: Color(0xFF080A12),
        card: Color(0xFF0F1424),
        primary: Color(0xFF42A5F5),
        secondary: Color(0xFF90CAF9),
        headlineStat: Color(0xFFE3F2FD),
        bulletColor: Color(0xFF42A5F5),
        bulletGlyph: '⚡',
        tabularFigures: true,
        numberSizeScale: 1.0,
        numberWeight: FontWeight.w800,
        chipRadius: 6,
        cardRadius: 8,
        cardBorderColor: Color(0x4442A5F5),
        cardBorderWidth: 1.0,
        dividerColor: Color(0x5542A5F5),
        dividerThickness: 1.0,
        glowPrimary: Color(0x4D42A5F5),
        glowSecondary: Color(0x2E90CAF9),
        auraStyle: AvatarAuraStyle.frostRing,
        headerGlyph: '⚡',
        headerUnderlineColor: Color(0x8842A5F5),
      ),
    ),
    ThemeRemix(
      label: 'Voltage',
      flair: ThemeFlair(
        scaffold: Color(0xFF0C0814),
        card: Color(0xFF161020),
        primary: Color(0xFFAB47BC),
        secondary: Color(0xFFCE93D8),
        headlineStat: Color(0xFFE1BEE7),
        bulletColor: Color(0xFFAB47BC),
        bulletGlyph: '⚡',
        tabularFigures: true,
        numberSizeScale: 1.0,
        numberWeight: FontWeight.w800,
        chipRadius: 6,
        cardRadius: 8,
        cardBorderColor: Color(0x44AB47BC),
        cardBorderWidth: 1.0,
        dividerColor: Color(0x55AB47BC),
        dividerThickness: 1.0,
        glowPrimary: Color(0x4DAB47BC),
        glowSecondary: Color(0x2ECE93D8),
        auraStyle: AvatarAuraStyle.frostRing,
        headerGlyph: '⚡',
        headerUnderlineColor: Color(0x88AB47BC),
      ),
    ),
  ],
};


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

  /// Whether the particle system is enabled. Off by default.
  final bool particlesEnabled;

  /// Selected particle preset (replaces old CustomParticleType).
  final ParticlePreset particlePreset;

  /// Glow effect applied to particles.
  final GlowEffect particleGlowEffect;

  /// Whether to connect nearby particles with lines (particles.js style).
  final bool particleLineLinks;

  /// Whether particles bounce off edges instead of wrapping.
  final bool particleBounce;

  /// User-selected glow color for the ambient screen glow (12-color palette).
  final int glowColorIndex;

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

  /// Custom Dice Settings
  final CustomDiceType customDiceType;
  final double particleSizeScale;
  final double particleOpacity;
  final int particleCount;

  /// Dialogue Settings
  final bool dialogueHapticsEnabled;
  final int dialogueTextSpeedMs;

  final bool isGoopianLanguage;
  final bool spongeActive;

  /// Whether the universal Damage Calculator terminal is shown on the
  /// active-run dashboard for every character (Robot keeps its own
  /// dedicated HUD regardless of this flag).
  final bool showDamageCalculator;

  /// Whether the Effects panel accordion is shown on the active-run dashboard.
  final bool showEffectsPanel;

  /// Whether the Shrine tracker panel is shown on the active-run dashboard.
  final bool showShrinePanel;

  /// Whether special-item/gun dashboards are shown on the active-run screen.
  final bool showDashboards;

  /// User-defined column count for the classic Periodic grid. 0 = Auto, or 2, 3, 4.
  final int periodicGridColumnCount;


  /// Computed scale factor applied globally via MediaQuery.
  double get textScaleFactor => fontSize / 14.0;

  /// Discrete font-size steps the UI presents as chips.
  static const fontSizeSteps = [
    6.0, 8.0, 10.0, 12.0, 14.0, 18.0, 20.0, 24.0, 28.0, 32.0,
  ];

  /// 12 deep, curated glow colors for the ambient screen glow.
  static const glowColors = [
    Color(0xFF0D47A1), // Abyssal Blue
    Color(0xFFB71C1C), // Curse Crimson
    Color(0xFFE65100), // Forge Amber
    Color(0xFF006064), // Frost Cyan
    Color(0xFF1B5E20), // Toxic Green
    Color(0xFF4A148C), // Void Purple
    Color(0xFFBF8C00), // Gungeon Gold
    Color(0xFF1A237E), // Shadow Indigo
    Color(0xFF880E4F), // Blood Rose
    Color(0xFF004D40), // Ethereal Teal
    Color(0xFF6A1B9A), // Magenta Pulse
    Color(0xFF263238), // Obsidian Grey
  ];

  const VisualPrefs({
    this.glowIntensity = 0.0,
    this.particlesEnabled = false,
    this.particlePreset = ParticlePreset.gungeonDust,
    this.particleGlowEffect = GlowEffect.none,
    this.particleLineLinks = false,
    this.particleBounce = false,
    this.glowColorIndex = 0,
    this.fontWeightBias = 0,
    this.font = AppFont.gungeon,
    this.fontSize = 12.0,
    this.inventoryFontSize = 12.0,
    this.inventoryDisplayMode = InventoryDisplayMode.classicPeriodic,
    this.customDiceType = CustomDiceType.themeDefault,
    this.particleSizeScale = 1.0,
    this.particleOpacity = 0.7,
    this.particleCount = 16,
    this.dialogueHapticsEnabled = true,
    this.dialogueTextSpeedMs = 30,
    this.isGoopianLanguage = false,
    this.spongeActive = false,
    this.showDamageCalculator = false,
    this.showEffectsPanel = false,
    this.showShrinePanel = false,
    this.showDashboards = true,
    this.periodicGridColumnCount = 0,
  });

  static const _kGlow     = 'vp.glow_v1';
  static const _kParticles = 'vp.particles_v1';
  static const _kWeight   = 'vp.weight_v1';
  static const _kFont     = 'vp.font_v1';
  static const _kFontSize = 'vp.font_size_v1';
  static const _kInventoryFontSize = 'vp.inventory_font_size_v1';
  static const _kInventoryDisplayMode = 'vp.inventory_display_mode_v1';
  static const _kScaleLegacy = 'vp.scale_v1'; // migrated to _kFontSize

  static const _kParticlePreset = 'vp.particle_preset_v3';
  static const _kParticleGlowEffect = 'vp.particle_glow_effect_v1';
  static const _kParticleLineLinks = 'vp.particle_line_links_v1';
  static const _kParticleBounce = 'vp.particle_bounce_v1';
  static const _kGlowColorIndex = 'vp.glow_color_index_v1';
  static const _kCustomDiceType = 'vp.custom_dice_type_v1';
  static const _kParticleSizeScale = 'vp.particle_size_scale_v2';
  static const _kParticleOpacity = 'vp.particle_opacity_v1';
  static const _kParticleCount = 'vp.particle_count_v1';

  static const _kDialogueHaptics = 'vp.dialogue_haptics_v1';
  static const _kDialogueTextSpeed = 'vp.dialogue_text_speed_v1';
  static const _kGoopianLanguage = 'vp.goopian_language_v1';
  static const _kSpongeActive = 'vp.sponge_active_v1';
  static const _kShowDamageCalculator = 'vp.show_damage_calculator_v1';
  static const _kShowEffectsPanel = 'vp.show_effects_panel_v1';
  static const _kShowShrinePanel = 'vp.show_shrine_panel_v1';
  static const _kShowDashboards = 'vp.show_dashboards_v1';
  static const _kPeriodicGridColumnCount = 'vp.periodic_grid_column_count_v1';

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

      final particlePresetIdx = p.getInt(_kParticlePreset) ?? 0;
      final particlePreset = ParticlePreset.values[particlePresetIdx.clamp(0, ParticlePreset.values.length - 1)];
      final particleGlowIdx = p.getInt(_kParticleGlowEffect) ?? 0;
      final particleGlowEffect = GlowEffect.values[particleGlowIdx.clamp(0, GlowEffect.values.length - 1)];
      final particleLineLinks = p.getBool(_kParticleLineLinks) ?? false;
      final particleBounce = p.getBool(_kParticleBounce) ?? false;
      final glowColorIndex = p.getInt(_kGlowColorIndex) ?? 0;

      final customDiceTypeIdx = p.getInt(_kCustomDiceType) ?? 0;
      final customDiceType = CustomDiceType.values[customDiceTypeIdx.clamp(0, CustomDiceType.values.length - 1)];

      final inventoryFontSize = p.getDouble(_kInventoryFontSize) ?? 12.0;
      final displayModeIdx = p.getInt(_kInventoryDisplayMode) ?? 0;
      final inventoryDisplayMode = InventoryDisplayMode.values[displayModeIdx.clamp(0, InventoryDisplayMode.values.length - 1)];

      final isGoopian = p.getBool(_kGoopianLanguage) ?? false;
      final spongeActive = p.getBool(_kSpongeActive) ?? false;
      final showDamageCalculator = p.getBool(_kShowDamageCalculator) ?? false;
      final showEffectsPanel = p.getBool(_kShowEffectsPanel) ?? false;
      final showShrinePanel = p.getBool(_kShowShrinePanel) ?? false;
      final showDashboards = p.getBool(_kShowDashboards) ?? true;
      final periodicGridColumnCount = p.getInt(_kPeriodicGridColumnCount) ?? 0;


      notifier.value = VisualPrefs(
        glowIntensity:    p.getDouble(_kGlow)     ?? 0.0,
        particlesEnabled: p.getBool(_kParticles)  ?? false,
        particlePreset:   particlePreset,
        particleGlowEffect: particleGlowEffect,
        particleLineLinks: particleLineLinks,
        particleBounce:   particleBounce,
        glowColorIndex:   glowColorIndex,
        fontWeightBias:   p.getInt(_kWeight)      ?? 0,
        font:             font,
        fontSize:         fontSize,
        inventoryFontSize: inventoryFontSize,
        inventoryDisplayMode: inventoryDisplayMode,
        customDiceType:   customDiceType,
        particleSizeScale: p.getDouble(_kParticleSizeScale) ?? 1.0,
        particleOpacity:   p.getDouble(_kParticleOpacity) ?? 0.7,
        particleCount:     p.getInt(_kParticleCount) ?? 16,
        dialogueHapticsEnabled: p.getBool(_kDialogueHaptics) ?? true,
        dialogueTextSpeedMs: p.getInt(_kDialogueTextSpeed) ?? 30,
        isGoopianLanguage: isGoopian,
        spongeActive: spongeActive,
        showDamageCalculator: showDamageCalculator,
        showEffectsPanel: showEffectsPanel,
        showShrinePanel: showShrinePanel,
        showDashboards: showDashboards,
        periodicGridColumnCount: periodicGridColumnCount,
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

  static Future<void> setParticlePreset(ParticlePreset v) async {
    notifier.value = notifier.value._with(particlePreset: v);
    _persist();
  }

  static Future<void> setParticleGlowEffect(GlowEffect v) async {
    notifier.value = notifier.value._with(particleGlowEffect: v);
    _persist();
  }

  static Future<void> setParticleLineLinks(bool v) async {
    notifier.value = notifier.value._with(particleLineLinks: v);
    _persist();
  }

  static Future<void> setParticleBounce(bool v) async {
    notifier.value = notifier.value._with(particleBounce: v);
    _persist();
  }

  static Future<void> setGlowColorIndex(int v) async {
    notifier.value = notifier.value._with(glowColorIndex: v.clamp(0, 11));
    _persist();
  }

  static Future<void> setParticleSizeScale(double v) async {
    notifier.value = notifier.value._with(particleSizeScale: v.clamp(0.3, 2.0));
    _persist();
  }

  static Future<void> setParticleOpacity(double v) async {
    notifier.value = notifier.value._with(particleOpacity: v.clamp(0.0, 1.0));
    _persist();
  }

  static Future<void> setParticleCount(int v) async {
    notifier.value = notifier.value._with(particleCount: v.clamp(1, 32));
    _persist();
  }

  static Future<void> setCustomDiceType(CustomDiceType type) async {
    notifier.value = notifier.value._with(customDiceType: type);
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

  static Future<void> setShowDamageCalculator(bool v) async {
    notifier.value = notifier.value._with(showDamageCalculator: v);
    _persist();
  }

  static Future<void> setShowEffectsPanel(bool v) async {
    notifier.value = notifier.value._with(showEffectsPanel: v);
    _persist();
  }

  static Future<void> setShowShrinePanel(bool v) async {
    notifier.value = notifier.value._with(showShrinePanel: v);
    _persist();
  }

  static Future<void> setShowDashboards(bool v) async {
    notifier.value = notifier.value._with(showDashboards: v);
    _persist();
  }

  static Future<void> setPeriodicGridColumnCount(int v) async {
    notifier.value = notifier.value._with(periodicGridColumnCount: v.clamp(0, 4));
    _persist();
  }


  static Future<void> _persist() async {
    try {
      final p = await SharedPreferences.getInstance();
      final v = notifier.value;
      await p.setDouble(_kGlow,     v.glowIntensity);
      await p.setBool(_kParticles,  v.particlesEnabled);
      await p.setInt(_kWeight,      v.fontWeightBias);
      await p.setInt(_kFont,        v.font.index);
      await p.setDouble(_kFontSize,  v.fontSize);
      await p.setDouble(_kInventoryFontSize, v.inventoryFontSize);
      await p.setInt(_kInventoryDisplayMode, v.inventoryDisplayMode.index);

      await p.setInt(_kParticlePreset, v.particlePreset.index);
      await p.setInt(_kParticleGlowEffect, v.particleGlowEffect.index);
      await p.setBool(_kParticleLineLinks, v.particleLineLinks);
      await p.setBool(_kParticleBounce, v.particleBounce);
      await p.setInt(_kGlowColorIndex, v.glowColorIndex);
      await p.setInt(_kCustomDiceType, v.customDiceType.index);
      await p.setDouble(_kParticleSizeScale, v.particleSizeScale);
      await p.setDouble(_kParticleOpacity, v.particleOpacity);
      await p.setInt(_kParticleCount, v.particleCount);
      await p.setBool(_kDialogueHaptics, v.dialogueHapticsEnabled);
      await p.setInt(_kDialogueTextSpeed, v.dialogueTextSpeedMs);
      await p.setBool(_kGoopianLanguage, v.isGoopianLanguage);
      await p.setBool(_kSpongeActive, v.spongeActive);
      await p.setBool(_kShowDamageCalculator, v.showDamageCalculator);
      await p.setBool(_kShowEffectsPanel, v.showEffectsPanel);
      await p.setBool(_kShowShrinePanel, v.showShrinePanel);
      await p.setBool(_kShowDashboards, v.showDashboards);
      await p.setInt(_kPeriodicGridColumnCount, v.periodicGridColumnCount);
    } catch (_) {}
  }

  VisualPrefs _with({
    double? glowIntensity,
    bool?   particlesEnabled,
    int?    fontWeightBias,
    AppFont? font,
    double? fontSize,
    double? inventoryFontSize,
    InventoryDisplayMode? inventoryDisplayMode,
    ParticlePreset? particlePreset,
    GlowEffect? particleGlowEffect,
    bool?   particleLineLinks,
    bool?   particleBounce,
    int?    glowColorIndex,
    CustomDiceType? customDiceType,
    double? particleSizeScale,
    double? particleOpacity,
    int?    particleCount,
    bool?   dialogueHapticsEnabled,
    int?    dialogueTextSpeedMs,
    bool?   isGoopianLanguage,
    bool?   spongeActive,
    bool?   showDamageCalculator,
    bool?   showEffectsPanel,
    bool?   showShrinePanel,
    bool?   showDashboards,
    int?    periodicGridColumnCount,
  }) => VisualPrefs(
    glowIntensity:    glowIntensity    ?? this.glowIntensity,
    particlesEnabled: particlesEnabled ?? this.particlesEnabled,
    fontWeightBias:   fontWeightBias   ?? this.fontWeightBias,
    font:             font             ?? this.font,
    fontSize:         fontSize         ?? this.fontSize,
    inventoryFontSize: inventoryFontSize ?? this.inventoryFontSize,
    inventoryDisplayMode: inventoryDisplayMode ?? this.inventoryDisplayMode,
    particlePreset:   particlePreset   ?? this.particlePreset,
    particleGlowEffect: particleGlowEffect ?? this.particleGlowEffect,
    particleLineLinks: particleLineLinks ?? this.particleLineLinks,
    particleBounce:   particleBounce   ?? this.particleBounce,
    glowColorIndex:   glowColorIndex   ?? this.glowColorIndex,
    customDiceType:   customDiceType   ?? this.customDiceType,
    particleSizeScale: particleSizeScale ?? this.particleSizeScale,
    particleOpacity:   particleOpacity   ?? this.particleOpacity,
    particleCount:     particleCount     ?? this.particleCount,
    dialogueHapticsEnabled: dialogueHapticsEnabled ?? this.dialogueHapticsEnabled,
    dialogueTextSpeedMs: dialogueTextSpeedMs ?? this.dialogueTextSpeedMs,
    isGoopianLanguage: isGoopianLanguage ?? this.isGoopianLanguage,
    spongeActive:     spongeActive      ?? this.spongeActive,
    showDamageCalculator: showDamageCalculator ?? this.showDamageCalculator,
    showEffectsPanel: showEffectsPanel ?? this.showEffectsPanel,
    showShrinePanel: showShrinePanel ?? this.showShrinePanel,
    showDashboards: showDashboards ?? this.showDashboards,
    periodicGridColumnCount: periodicGridColumnCount ?? this.periodicGridColumnCount,
  );
}

/// Static holder for the live [AppThemeMode]. Mutated via [setMode] and
/// rebroadcast through [notifier] so the root [MaterialApp] rebuilds
/// with the new palette + every descendant picks up the new flair.
class AppTheme {
  const AppTheme._();

  static const String _prefsKey = 'theme.mode.v2';
  static const String _unicornPaletteKey = 'theme.unicorn.palette.v1';
  // Old key from the 4-mode era. Migrated on first run then cleared so
  // returning users don't get parked on an invalid index.
  static const String _legacyKey = 'theme.mode';

  static final RefreshableValueNotifier<AppThemeMode> notifier =
      RefreshableValueNotifier<AppThemeMode>(AppThemeMode.unicorn);

  static final ValueNotifier<AppThemeMode?> previewNotifier =
      ValueNotifier<AppThemeMode?>(null);

  static AppThemeMode get mode => notifier.value;
  static ThemeFlair get flair => flairFor(notifier.value);

  static AppThemeMode get displayedMode => previewNotifier.value ?? notifier.value;
  static ThemeFlair get displayedFlair => flairFor(displayedMode);

  /// Active palette for the Unicorn megapack. Persisted across sessions.
  static UnicornPalette _unicornPalette = UnicornPalette.cottonCandy;
  static UnicornPalette get unicornPalette => _unicornPalette;
  static final ValueNotifier<UnicornPalette> unicornPaletteNotifier =
      ValueNotifier<UnicornPalette>(UnicornPalette.cottonCandy);

  static Future<void> setUnicornPalette(UnicornPalette p) async {
    _unicornPalette = p;
    unicornPaletteNotifier.value = p;
    notifier.refresh();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_unicornPaletteKey, p.index);
    } catch (_) {}
  }

  /// Per-theme remix index (0 = original). Persisted.
  static final Map<AppThemeMode, int> _remixIndex = {};
  static final ValueNotifier<int> remixNotifier = ValueNotifier(0);

  static int remixFor(AppThemeMode m) => _remixIndex[m] ?? 0;

  static Future<void> setRemix(AppThemeMode m, int idx) async {
    _remixIndex[m] = idx;
    remixNotifier.value = idx;
    notifier.refresh();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme.remix.${m.index}', idx);
    } catch (_) {}
  }

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

      // Load unicorn palette preference.
      final palIdx = prefs.getInt(_unicornPaletteKey);
      if (palIdx != null && palIdx >= 0 && palIdx < UnicornPalette.values.length) {
        _unicornPalette = UnicornPalette.values[palIdx];
        unicornPaletteNotifier.value = _unicornPalette;
      }

      // Load per-theme remix indices.
      for (final m in kThemeRemixes.keys) {
        final rIdx = prefs.getInt('theme.remix.${m.index}');
        if (rIdx != null && rIdx >= 0 && rIdx < kThemeRemixes[m]!.length) {
          _remixIndex[m] = rIdx;
        }
      }

      final idx = prefs.getInt(_prefsKey);
      if (idx != null && idx >= 0 && idx < AppThemeMode.values.length) {
        final m = AppThemeMode.values[idx];
        if (kVisibleThemes.contains(m)) {
          notifier.value = m;
        } else {
          // Migrate Unicorn II-IV to Unicorn + corresponding palette.
          if (m == AppThemeMode.unicornII) {
            _unicornPalette = UnicornPalette.neon;
            unicornPaletteNotifier.value = _unicornPalette;
            await prefs.setInt(_unicornPaletteKey, UnicornPalette.neon.index);
          } else if (m == AppThemeMode.unicornIII) {
            _unicornPalette = UnicornPalette.dreamy;
            unicornPaletteNotifier.value = _unicornPalette;
            await prefs.setInt(_unicornPaletteKey, UnicornPalette.dreamy.index);
          } else if (m == AppThemeMode.unicornIV) {
            _unicornPalette = UnicornPalette.sunset;
            unicornPaletteNotifier.value = _unicornPalette;
            await prefs.setInt(_unicornPaletteKey, UnicornPalette.sunset.index);
          }
          // Persisted theme was removed — migrate to Unicorn (first visible).
          notifier.value = kVisibleThemes.first;
          await prefs.setInt(_prefsKey, kVisibleThemes.first.index);
        }
        return;
      }
      // Old legacy 4-mode index.
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

  /// Force a rebuild of all widgets listening to [notifier] without
  /// changing the mode. Used after custom theme data is edited.
  static void refresh() => notifier.refresh();

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
      scaffoldBackgroundColor: Colors.transparent,
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
          side: BorderSide(
            color: f.cardBorderColor ?? f.primary.withValues(alpha: 0.16),
            width: f.cardBorderColor != null ? f.cardBorderWidth : 1.2,
          ),
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

/// A [ValueNotifier] that exposes [refresh] so external callers can
/// force a rebuild without changing the value.
class RefreshableValueNotifier<T> extends ValueNotifier<T> {
  RefreshableValueNotifier(super.value);
  void refresh() => notifyListeners();
}

