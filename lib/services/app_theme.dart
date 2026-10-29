import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/tokens.dart';
import '../utils/contrast.dart';
import '../widgets/particle_engine.dart'
    show ParticlePreset, GlowEffect, ParticleColorSchema, ParticleSpeed, ParticleType;

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
      statGroupCombat: Color(0xFFFF69B4), // pink
      statGroupHandling: Color(0xFFF06292), // rose
      statGroupMeta: Color(0xFFE8A7F0), // lavender
      font: AppFont.fredoka,
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
    label: 'Codex',
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
      statGroupCombat: Color(0xFFFF4500), // dragun orange
      statGroupHandling: Color(0xFFFFB74D), // sulfur orange
      statGroupMeta: Color(0xFFFFCC00), // gold
      font: AppFont.russoOne,
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
      statGroupCombat: Color(0xFF00D2FF), // cyan
      statGroupHandling: Color(0xFF90A4AE), // slate
      statGroupMeta: Color(0xFFE0F7FA), // ice white
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
      statGroupCombat: Color(0xFFFF0033), // curse red
      statGroupHandling: Color(0xFFCE93D8), // corrupted violet
      statGroupMeta: Color(0xFFFF007F), // curse neon
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
      statGroupCombat: Color(0xFF39FF14), // neon green
      statGroupHandling: Color(0xFFB388FF), // violet
      statGroupMeta: Color(0xFFCCFF00), // acid yellow
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
      primary: Color(0xFF64DD17), // sickly sewer green (distinct from Bullet Hell's neon green)
      secondary: Color(0xFF795548),
      headlineStat: Color(0xFFB2FF59), // pale toxic lime (distinct from Bullet Hell's acid yellow)
      bulletColor: Color(0xFF64DD17),
      bulletGlyph: '☣',
      tabularFigures: true,
      numberSizeScale: 1.0,
      numberWeight: FontWeight.w800,
      chipRadius: 8,
      cardRadius: 10,
      cardBorderColor: Color(0x4464DD17),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x5564DD17),
      dividerThickness: 1.0,
      glowPrimary: Color(0x4D64DD17),
      glowSecondary: Color(0x2E795548),
      auraStyle: AvatarAuraStyle.toxicOoze,
      headerGlyph: '☣',
      headerUnderlineColor: Color(0x8864DD17),
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
      statGroupCombat: Color(0xFF00F5D4), // electric teal
      statGroupHandling: Color(0xFF69F0AE), // neon green
      statGroupMeta: Color(0xFFB2DFDB), // pale teal
      font: AppFont.audiowide,
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
      primary: Color(0xFFFF1744), // styled target red (not harsh pure #FF0000)
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
      glowPrimary: Color(0x4DFF1744),
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
  mrRobot(
    label: "Mr. Robot",
    vibe: 'CYBERNETIC',
    diff: 'EXPERT',
    elem: 'CIRCUIT',
    whimsicalDescription: 'JUNK IS THE OPTIMAL SOURCE OF FUEL. A cold steel cybernetic interface with circuit-green accents and battery-blue highlights. The Robot\'s domain — efficient, calculating, and relentlessly logical.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0A0E0A),
      card: Color(0xFF121812),
      primary: Color(0xFF69F0AE), // circuit green
      secondary: Color(0xFF40C4FF), // battery blue
      headlineStat: Color(0xFFB9F6CA), // light green
      bulletColor: Color(0xFF69F0AE),
      bulletGlyph: '⚙',
      sparkleNumbers: true,
      numberGlowColor: Color(0xFF69F0AE),
      tabularFigures: true,
      numberSizeScale: 1.05,
      numberWeight: FontWeight.w800,
      chipRadius: 4,
      cardRadius: 6,
      cardBorderColor: Color(0x4469F0AE),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x4469F0AE),
      dividerThickness: 1.0,
      glowPrimary: Color(0x4469F0AE),
      glowSecondary: Color(0x3340C4FF),
      auraStyle: AvatarAuraStyle.tacticalRing,
      headerGlyph: '⚙',
      headerUnderlineColor: Color(0x8869F0AE),
      statGroupCombat: Color(0xFF69F0AE),
      statGroupHandling: Color(0xFF40C4FF),
      statGroupMeta: Color(0xFFB9F6CA),
      font: AppFont.jetBrainsMono,
    ),
  ),
  valorOfMarines(
    label: 'Valor of Marines',
    vibe: 'TACTICAL',
    diff: 'NORMAL',
    elem: 'DOG TAG',
    whimsicalDescription: 'Stay frosty. A disciplined military aesthetic with olive drab, tactical amber, and steel gray. The Marine\'s domain — precise, reliable, and always by the book.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0F0F0A),
      card: Color(0xFF1A1A14),
      primary: Color(0xFFC5E1A5), // olive drab light
      secondary: Color(0xFFFFB74D), // tactical amber
      headlineStat: Color(0xFFE6EE9C), // light olive
      bulletColor: Color(0xFFC5E1A5),
      bulletGlyph: '★',
      tabularFigures: true,
      numberSizeScale: 1.0,
      numberWeight: FontWeight.w800,
      chipRadius: 6,
      cardRadius: 8,
      cardBorderColor: Color(0x44C5E1A5),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x44C5E1A5),
      dividerThickness: 1.0,
      glowPrimary: Color(0x44C5E1A5),
      glowSecondary: Color(0x33FFB74D),
      auraStyle: AvatarAuraStyle.tacticalRing,
      headerGlyph: '★',
      headerUnderlineColor: Color(0x88C5E1A5),
      statGroupCombat: Color(0xFFFFB74D),
      statGroupHandling: Color(0xFFC5E1A5),
      statGroupMeta: Color(0xFFE6EE9C),
      font: AppFont.blackOpsOne,
    ),
  ),
  theBullet(
    label: 'The Bullet',
    vibe: 'HEROIC',
    diff: 'NORMAL',
    elem: 'BLADE',
    whimsicalDescription: 'For the glory of the Bullet-King! A brave bullet-kin aesthetic with polished brass gold, heroic red, and steel gray. The Bullet that dared to wield a blade — noble, bright, and defiant.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0F0D08),
      card: Color(0xFF1A1610),
      primary: Color(0xFFFFD740), // brass gold
      secondary: Color(0xFFEF5350), // heroic red
      headlineStat: Color(0xFFFFE57F), // light gold
      bulletColor: Color(0xFFFFD740),
      bulletGlyph: '⚔',
      shimmerHeadline: true,
      tabularFigures: true,
      numberSizeScale: 1.05,
      numberWeight: FontWeight.w800,
      chipRadius: 10,
      cardRadius: 12,
      cardBorderColor: Color(0x44FFD740),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x55FFD740),
      dividerThickness: 1.0,
      glowPrimary: Color(0x55FFD740),
      glowSecondary: Color(0x44EF5350),
      auraStyle: AvatarAuraStyle.goldShimmerRing,
      headerGlyph: '⚔',
      headerUnderlineColor: Color(0xAAFFD740),
      statGroupCombat: Color(0xFFEF5350),
      statGroupHandling: Color(0xFFFFD740),
      statGroupMeta: Color(0xFFFFE57F),
      font: AppFont.righteous,
    ),
  ),
  theParadox(
    label: 'The Paradox',
    vibe: 'FRACTURED',
    diff: 'EXPERT',
    elem: 'RIFT',
    whimsicalDescription: 'Who... what... when... am I? A fractured reality aesthetic with swirling paradox purple, time-rift violet, and stardust white. Existence is a loop inside a cylinder — broken, beautiful, and unknowable.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0A0812),
      card: Color(0xFF140F1F),
      primary: Color(0xFFCE93D8), // paradox purple
      secondary: Color(0xFF7E57C2), // rift violet
      headlineStat: Color(0xFFE1BEE7), // stardust
      bulletColor: Color(0xFFCE93D8),
      bulletGlyph: '✦',
      sparkleNumbers: true,
      numberGlowColor: Color(0xFFCE93D8),
      tabularFigures: true,
      numberSizeScale: 1.05,
      numberWeight: FontWeight.w700,
      chipRadius: 14,
      cardRadius: 16,
      cardBorderColor: Color(0x44CE93D8),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x55CE93D8),
      dividerThickness: 1.0,
      glowPrimary: Color(0x55CE93D8),
      glowSecondary: Color(0x447E57C2),
      auraStyle: AvatarAuraStyle.paradoxRift,
      headerGlyph: '✦',
      headerUnderlineColor: Color(0xAACE93D8),
      statGroupCombat: Color(0xFF7E57C2),
      statGroupHandling: Color(0xFFCE93D8),
      statGroupMeta: Color(0xFFE1BEE7),
      font: AppFont.syncopate,
    ),
  ),
  gunpowder(
    label: 'Gunpowder',
    vibe: 'EXPLOSIVE',
    diff: 'NORMAL',
    elem: 'POWDER',
    whimsicalDescription: 'Lock and load. A smoky gunpowder aesthetic with charcoal black, sulfurous gray, and ember red. The smell of spent casings and black powder — raw, industrial, and ready to detonate.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0A0A0A),
      card: Color(0xFF141414),
      primary: Color(0xFFB71C1C), // ember red
      secondary: Color(0xFF9E9E9E), // sulfurous gray
      headlineStat: Color(0xFFE57373), // light ember
      bulletColor: Color(0xFFB71C1C),
      bulletGlyph: '💥',
      tabularFigures: true,
      numberSizeScale: 1.0,
      numberWeight: FontWeight.w800,
      chipRadius: 4,
      cardRadius: 6,
      cardBorderColor: Color(0x44B71C1C),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x44B71C1C),
      dividerThickness: 1.0,
      glowPrimary: Color(0x44B71C1C),
      glowSecondary: Color(0x339E9E9E),
      auraStyle: AvatarAuraStyle.oxbloodBreath,
      headerGlyph: '💥',
      headerUnderlineColor: Color(0x88B71C1C),
      statGroupCombat: Color(0xFFB71C1C),
      statGroupHandling: Color(0xFF9E9E9E),
      statGroupMeta: Color(0xFFE57373),
      font: AppFont.rowdies,
    ),
  ),
  dragunfire(
    label: 'Dragunfire',
    vibe: 'MOLTEN',
    diff: 'BRUTAL',
    elem: 'FIRE',
    whimsicalDescription: 'Face the High Dragun. A molten inferno aesthetic with dragun orange, scale amber, and ash black. The Fifth Chamber burns — scales glint, fire roars, and only the worthy survive.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0F0805),
      card: Color(0xFF1C100A),
      primary: Color(0xFFFF4500), // dragun orange
      secondary: Color(0xFFFFAB40), // scale amber
      headlineStat: Color(0xFFFFCC00), // molten gold
      bulletColor: Color(0xFFFF4500),
      bulletGlyph: '🐲',
      shimmerHeadline: true,
      tabularFigures: true,
      numberSizeScale: 1.08,
      numberWeight: FontWeight.w800,
      chipRadius: 6,
      cardRadius: 8,
      cardBorderColor: Color(0x44FF4500),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x55FF4500),
      dividerThickness: 1.0,
      glowPrimary: Color(0x55FF4500),
      glowSecondary: Color(0x44FFAB40),
      auraStyle: AvatarAuraStyle.dragunScale,
      headerGlyph: '🐲',
      headerUnderlineColor: Color(0xAAFF4500),
      statGroupCombat: Color(0xFFFF4500),
      statGroupHandling: Color(0xFFFFAB40),
      statGroupMeta: Color(0xFFFFCC00),
      font: AppFont.archivoBlack,
    ),
  ),
  lichsDomain(
    label: "Lich's Domain",
    vibe: 'NECROTIC',
    diff: 'EXTREME',
    elem: 'BONE',
    whimsicalDescription: 'The master of the gungeon awaits. A necrotic domain with bone white, crypt teal, and void black. The Lich\'s chamber — cold, eternal, and absolute in its finality.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF050808),
      card: Color(0xFF0C1010),
      primary: Color(0xFF2EC4B6), // crypt teal
      secondary: Color(0xFFE0E0E0), // bone white
      headlineStat: Color(0xFFF5F5DC), // antique bone
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
      auraStyle: AvatarAuraStyle.voidPulse,
      headerGlyph: '☠',
      headerUnderlineColor: Color(0xAA2EC4B6),
      statGroupCombat: Color(0xFF2EC4B6),
      statGroupHandling: Color(0xFFE0E0E0),
      statGroupMeta: Color(0xFFF5F5DC),
      font: AppFont.specialElite,
    ),
  ),
  catLady(
    label: 'Cat Lady',
    vibe: 'COZY',
    diff: 'NORMAL',
    elem: 'PAW',
    whimsicalDescription: 'A warm hearth-lit den where a content gungeoneer and their nine lives nap between chambers. Amber paw prints padding across deep walnut, with soft copper accents and a gentle purr of warmth.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF1A1208),
      card: Color(0xFF2A1E10),
      primary: Color(0xFFFFB74D), // warm amber
      secondary: Color(0xFFD7CCC8), // warm cream
      headlineStat: Color(0xFFFFCC80), // light amber
      bulletColor: Color(0xFFFFB74D),
      bulletGlyph: '🐾',
      tabularFigures: true,
      numberSizeScale: 1.05,
      numberWeight: FontWeight.w700,
      chipRadius: 14,
      cardRadius: 16,
      cardBorderColor: Color(0x44FFB74D),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x44FFB74D),
      dividerThickness: 1.0,
      glowPrimary: Color(0x44FFB74D),
      glowSecondary: Color(0x33D7CCC8),
      auraStyle: AvatarAuraStyle.catPawTrail,
      headerGlyph: '🐾',
      headerUnderlineColor: Color(0x88FFB74D),
      statGroupCombat: Color(0xFFFFB74D), // amber
      statGroupHandling: Color(0xFFD7CCC8), // cream
      statGroupMeta: Color(0xFFFFCC80), // light amber
      font: AppFont.carterOne,
    ),
  ),
  moonlitChamber(
    // Re-skinned as MINIMALIST — enum id stays so old saved prefs
    // migrate seamlessly to the sleek look.
    label: 'Minimalist',
    vibe: 'CLEAN',
    diff: 'NORMAL',
    elem: 'CORE',
    whimsicalDescription: 'Stripped to the essentials. Soft whites on deep charcoal, quiet borders, no glow, no spectacle — the distilled GungeonMate for purists who want the data and nothing else.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0B0B0F),
      card: Color(0xFF141419),
      primary: Color(0xFFECEFF1), // soft white
      secondary: Color(0xFF9E9E9E), // mid grey
      headlineStat: Color(0xFFFFFFFF), // pure white
      bulletColor: Color(0xFFECEFF1),
      bulletGlyph: '▪',
      sparkleNumbers: false,
      numberGlowColor: Color(0x00000000),
      tabularFigures: true,
      numberSizeScale: 1.0,
      numberWeight: FontWeight.w600,
      chipRadius: 4,
      cardRadius: 6,
      cardBorderColor: Color(0x339E9E9E),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x339E9E9E),
      dividerThickness: 1.0,
      glowPrimary: Color(0x00000000),
      glowSecondary: Color(0x00000000),
      auraStyle: AvatarAuraStyle.moonGlow,
      headerGlyph: '▪',
      headerUnderlineColor: Color(0x559E9E9E),
      statGroupCombat: Color(0xFFECEFF1), // soft white
      statGroupHandling: Color(0xFF9E9E9E), // mid grey
      statGroupMeta: Color(0xFFBDBDBD), // light grey
      font: AppFont.gungeon,
    ),
  ),
  candyRush(
    label: 'Candy Rush',
    vibe: 'SWEET',
    diff: 'CO-OP',
    elem: 'SUGAR',
    whimsicalDescription: 'Unicorn sibling - bubblegum pink melts into cotton-candy pastels.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF241620), card: Color(0xFF33202E),
      primary: Color(0xFFF8BBD0), secondary: Color(0xFFB3E5FC),
      headlineStat: Color(0xFFF48FB1), bulletColor: Color(0xFFF8BBD0),
      bulletGlyph: '\u2665', twinkleBullets: true, sparkleNumbers: true,
      numberGlowColor: Color(0xFFF8BBD0), tabularFigures: false,
      numberSizeScale: 1.03, numberWeight: FontWeight.w700,
      numberStyle: FontStyle.italic, chipRadius: 18, cardRadius: 18,
      dividerColor: Color(0x55F8BBD0), dividerThickness: 1.0,
      glowPrimary: Color(0x55F8BBD0), glowSecondary: Color(0x3BB3E5FC),
      auraStyle: AvatarAuraStyle.pastelPulse, headerGlyph: '\u2665',
      headerUnderlineColor: Color(0x88F8BBD0),
      statGroupCombat: Color(0xFFF8BBD0),
      statGroupHandling: Color(0xFFB3E5FC),
      statGroupMeta: Color(0xFFF48FB1), font: AppFont.fredoka,
    ),
  ),
  neonPrism(
    label: 'Neon Prism',
    vibe: 'ELECTRIC', diff: 'CO-OP', elem: 'SPECTRUM',
    whimsicalDescription: 'Unicorn after dark - deep night lit by saturated prism accents.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0D0A14), card: Color(0xFF1A1226),
      primary: Color(0xFFE040FB), secondary: Color(0xFF00E5FF),
      headlineStat: Color(0xFFFFD740), bulletColor: Color(0xFFE040FB),
      bulletGlyph: '\u2726', twinkleBullets: true, sparkleNumbers: true,
      numberGlowColor: Color(0xFFE040FB), tabularFigures: true,
      numberSizeScale: 1.05, numberWeight: FontWeight.w800,
      chipRadius: 14, cardRadius: 16,
      cardBorderColor: Color(0x44E040FB), cardBorderWidth: 1.0,
      dividerColor: Color(0x55E040FB), dividerThickness: 1.0,
      glowPrimary: Color(0x55E040FB), glowSecondary: Color(0x4000E5FF),
      auraStyle: AvatarAuraStyle.pastelPulse, headerGlyph: '\u2726',
      headerUnderlineColor: Color(0xAAE040FB),
      statGroupCombat: Color(0xFFE040FB),
      statGroupHandling: Color(0xFF00E5FF),
      statGroupMeta: Color(0xFFFFD740), font: AppFont.fredoka,
    ),
  ),
  blacksmithsFire(
    label: "Blacksmiths Fire",
    vibe: 'RUSTED', diff: 'EXPERT', elem: 'EMBER',
    whimsicalDescription: 'Forge Master rougher kin - rust and deep ember over scorched iron.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF120B08), card: Color(0xFF1E130E),
      primary: Color(0xFFD84315), secondary: Color(0xFFFF8A65),
      headlineStat: Color(0xFFFFB74D), bulletColor: Color(0xFFD84315),
      bulletGlyph: '\u2622', twinkleBullets: true, tabularFigures: true,
      numberSizeScale: 1.0, numberWeight: FontWeight.w800,
      chipRadius: 4, cardRadius: 6,
      cardBorderColor: Color(0x33D84315), cardBorderWidth: 1.0,
      dividerColor: Color(0x44D84315), dividerThickness: 1.0,
      glowPrimary: Color(0x4DD84315), glowSecondary: Color(0x2EFF8A65),
      auraStyle: AvatarAuraStyle.forgeGlow, headerGlyph: '\u2622',
      headerUnderlineColor: Color(0x88D84315),
      statGroupCombat: Color(0xFFD84315),
      statGroupHandling: Color(0xFFFF8A65),
      statGroupMeta: Color(0xFFFFB74D), font: AppFont.russoOne,
    ),
  ),
  moltenSteel(
    label: 'Molten Steel',
    vibe: 'FORGED', diff: 'EXPERT', elem: 'STEEL',
    whimsicalDescription: 'Forge Master chilled - iron greys with a molten-orange edge bleeding through.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0E0E12), card: Color(0xFF18181E),
      primary: Color(0xFFFF6E40), secondary: Color(0xFFB0BEC5),
      headlineStat: Color(0xFFECEFF1), bulletColor: Color(0xFFFF6E40),
      bulletGlyph: '\u2692', twinkleBullets: false, tabularFigures: true,
      numberSizeScale: 1.0, numberWeight: FontWeight.w700,
      chipRadius: 5, cardRadius: 7,
      cardBorderColor: Color(0x3378909C), cardBorderWidth: 1.0,
      dividerColor: Color(0x3378909C), dividerThickness: 1.0,
      glowPrimary: Color(0x33FF6E40), glowSecondary: Color(0x2278909C),
      auraStyle: AvatarAuraStyle.forgeGlow, headerGlyph: '\u2692',
      headerUnderlineColor: Color(0x66FF6E40),
      statGroupCombat: Color(0xFFFF6E40),
      statGroupHandling: Color(0xFFB0BEC5),
      statGroupMeta: Color(0xFF90A4AE), font: AppFont.russoOne,
    ),
  ),
  paperInk(
    label: 'Paper & Ink',
    vibe: 'QUIET', diff: 'NORMAL', elem: 'INK',
    whimsicalDescription: 'Minimalist day shift - soft paper greys under crisp ink.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF16161A), card: Color(0xFF222228),
      primary: Color(0xFF90A4AE), secondary: Color(0xFFB0BEC5),
      headlineStat: Color(0xFFECEFF1), bulletColor: Color(0xFF90A4AE),
      bulletGlyph: '\u25AA', sparkleNumbers: false,
      numberGlowColor: Color(0x00000000), tabularFigures: true,
      numberSizeScale: 1.0, numberWeight: FontWeight.w600,
      chipRadius: 4, cardRadius: 6,
      cardBorderColor: Color(0x3390A4AE), cardBorderWidth: 1.0,
      dividerColor: Color(0x3390A4AE), dividerThickness: 1.0,
      glowPrimary: Color(0x00000000), glowSecondary: Color(0x00000000),
      auraStyle: AvatarAuraStyle.moonGlow, headerGlyph: '\u25AA',
      headerUnderlineColor: Color(0x5590A4AE),
      statGroupCombat: Color(0xFF90A4AE),
      statGroupHandling: Color(0xFFB0BEC5),
      statGroupMeta: Color(0xFF78909C), font: AppFont.gungeon,
    ),
  ),
  voidWhite(
    label: 'Void White',
    vibe: 'STARK', diff: 'BRUTAL', elem: 'VOID',
    whimsicalDescription: 'Minimalist edge - pure white on near-black, no chrome, no noise.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF08080C), card: Color(0xFF101014),
      primary: Color(0xFFFFFFFF), secondary: Color(0xFF9E9E9E),
      headlineStat: Color(0xFFFFFFFF), bulletColor: Color(0xFFFFFFFF),
      bulletGlyph: '\u25AA', sparkleNumbers: false,
      numberGlowColor: Color(0x00000000), tabularFigures: true,
      numberSizeScale: 1.0, numberWeight: FontWeight.w700,
      chipRadius: 4, cardRadius: 6,
      cardBorderColor: Color(0x33FFFFFF), cardBorderWidth: 1.0,
      dividerColor: Color(0x22FFFFFF), dividerThickness: 1.0,
      glowPrimary: Color(0x00000000), glowSecondary: Color(0x00000000),
      auraStyle: AvatarAuraStyle.moonGlow, headerGlyph: '\u25AA',
      headerUnderlineColor: Color(0x55FFFFFF),
      statGroupCombat: Color(0xFFFFFFFF),
      statGroupHandling: Color(0xFF9E9E9E),
      statGroupMeta: Color(0xFF757575), font: AppFont.gungeon,
    ),
  ),
  stormCaller(
    label: 'Storm Caller',
    vibe: 'ELECTRIC',
    diff: 'EXPERT',
    elem: 'LIGHTNING',
    whimsicalDescription: 'The gungeon trembles as thunder rolls through its corridors. Crackling electric yellow arcs against storm-grey steel, with voltage blue accents — a high-voltage aesthetic for the gungeoneer who shoots first and asks questions never.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0A0A12),
      card: Color(0xFF14141F),
      primary: Color(0xFFFFEB3B), // electric yellow
      secondary: Color(0xFF42A5F5), // voltage blue
      headlineStat: Color(0xFFFFFF00), // pure electric
      bulletColor: Color(0xFFFFEB3B),
      bulletGlyph: '⚡',
      shimmerHeadline: true,
      tabularFigures: true,
      numberSizeScale: 1.08,
      numberWeight: FontWeight.w800,
      chipRadius: 6,
      cardRadius: 8,
      cardBorderColor: Color(0x44FFEB3B),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x55FFEB3B),
      dividerThickness: 1.0,
      glowPrimary: Color(0x55FFEB3B),
      glowSecondary: Color(0x4442A5F5),
      auraStyle: AvatarAuraStyle.lightningArc,
      headerGlyph: '⚡',
      headerUnderlineColor: Color(0xAAFFEB3B),
      statGroupCombat: Color(0xFFFFEB3B), // electric yellow
      statGroupHandling: Color(0xFF42A5F5), // voltage blue
      statGroupMeta: Color(0xFFFFFF00), // pure electric
      font: AppFont.fasterOne,
    ),
  ),
  // ── 6 Character Themes ─────────────────────────────────────────
  theCultist(
    label: 'The Cultist',
    vibe: 'MYSTIC',
    diff: 'HARD',
    elem: 'SHADOW',
    whimsicalDescription: 'A hooded figure kneels in candlelight. Deep blue robes, flickering gold, and shadow-purple — for the gungeoneer who speaks in riddles and fights in silence.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0D0F1A),
      card: Color(0xFF161A2E),
      primary: Color(0xFFFFD700), // candle gold
      secondary: Color(0xFF7B68EE), // mystic purple
      headlineStat: Color(0xFFFFE082), // warm gold
      bulletColor: Color(0xFF7B68EE),
      bulletGlyph: '◈',
      sparkleNumbers: true,
      numberGlowColor: Color(0xFFFFD700),
      tabularFigures: true,
      numberSizeScale: 1.05,
      numberWeight: FontWeight.w700,
      chipRadius: 12,
      cardRadius: 14,
      cardBorderColor: Color(0x447B68EE),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x447B68EE),
      dividerThickness: 1.0,
      glowPrimary: Color(0x44FFD700),
      glowSecondary: Color(0x337B68EE),
      glowStyle: GlowStyle.halo,
      auraStyle: AvatarAuraStyle.voidPulse,
      headerGlyph: '◈',
      headerUnderlineColor: Color(0x88FFD700),
      statGroupCombat: Color(0xFFFFD700),
      statGroupHandling: Color(0xFF7B68EE),
      statGroupMeta: Color(0xFFFFE082),
      font: AppFont.medievalSharp,
    ),
  ),
  theGunslinger(
    label: 'The Gunslinger',
    vibe: 'LEGENDARY',
    diff: 'EXTREME',
    elem: 'BULLET',
    whimsicalDescription: 'The legend who killed the past with two guns and a grin. Polished gold, worn leather, and gunmetal — for the gungeoneer who walks in like they own the place.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF1A1208),
      card: Color(0xFF2A1E10),
      primary: Color(0xFFFFB300), // gold
      secondary: Color(0xFFFF6F00), // amber
      headlineStat: Color(0xFFFFD54F), // bright gold
      bulletColor: Color(0xFFFFB300),
      bulletGlyph: '✦',
      shimmerHeadline: true,
      tabularFigures: true,
      numberSizeScale: 1.08,
      numberWeight: FontWeight.w800,
      chipRadius: 8,
      cardRadius: 10,
      cardBorderColor: Color(0x66FFB300),
      cardBorderWidth: 1.2,
      dividerColor: Color(0x55FFB300),
      dividerThickness: 1.0,
      glowPrimary: Color(0x55FFB300),
      glowSecondary: Color(0x44FF6F00),
      auraStyle: AvatarAuraStyle.goldShimmerRing,
      headerGlyph: '✦',
      headerUnderlineColor: Color(0xAAFFB300),
      statGroupCombat: Color(0xFFFFB300),
      statGroupHandling: Color(0xFFFF6F00),
      statGroupMeta: Color(0xFFFFD54F),
      font: AppFont.cinzel,
    ),
  ),
  theConvict(
    label: 'The Convict',
    vibe: 'REBELLIOUS',
    diff: 'HARD',
    elem: 'FIRE',
    whimsicalDescription: 'A rebel with a shotgun and a grudge. Prison orange, rebel red, and dark steel — for the gungeoneer who fights harder when cornered.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF1A0F0A),
      card: Color(0xFF2A1810),
      primary: Color(0xFFFF5722), // prison orange
      secondary: Color(0xFFD32F2F), // rebel red
      headlineStat: Color(0xFFFF8A65), // light orange
      bulletColor: Color(0xFFFF5722),
      bulletGlyph: '▲',
      tabularFigures: true,
      numberSizeScale: 1.06,
      numberWeight: FontWeight.w800,
      chipRadius: 6,
      cardRadius: 8,
      cardBorderColor: Color(0x44FF5722),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x55FF5722),
      dividerThickness: 1.0,
      glowPrimary: Color(0x55FF5722),
      glowSecondary: Color(0x44D32F2F),
      auraStyle: AvatarAuraStyle.forgeGlow,
      headerGlyph: '▲',
      headerUnderlineColor: Color(0xAAFF5722),
      statGroupCombat: Color(0xFFFF5722),
      statGroupHandling: Color(0xFFD32F2F),
      statGroupMeta: Color(0xFFFF8A65),
      font: AppFont.anton,
    ),
  ),
  theHunter(
    label: 'The Hunter',
    vibe: 'WILDERNESS',
    diff: 'NORMAL',
    elem: 'NATURE',
    whimsicalDescription: 'A crossbow, a plan, and patience. Forest green, bark brown, and crossbow silver — for the gungeoneer who hunts from the shadows of the gungeon.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0A1208),
      card: Color(0xFF121E10),
      primary: Color(0xFF66BB6A), // forest green
      secondary: Color(0xFFA1887F), // bark brown
      headlineStat: Color(0xFFA5D6A7), // light green
      bulletColor: Color(0xFF66BB6A),
      bulletGlyph: '➤',
      tabularFigures: true,
      numberSizeScale: 1.04,
      numberWeight: FontWeight.w700,
      chipRadius: 10,
      cardRadius: 12,
      cardBorderColor: Color(0x4466BB6A),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x4466BB6A),
      dividerThickness: 1.0,
      glowPrimary: Color(0x3366BB6A),
      glowSecondary: Color(0x22A1887F),
      auraStyle: AvatarAuraStyle.pastelPulse,
      headerGlyph: '➤',
      headerUnderlineColor: Color(0x8866BB6A),
      statGroupCombat: Color(0xFF66BB6A),
      statGroupHandling: Color(0xFFA1887F),
      statGroupMeta: Color(0xFFA5D6A7),
      font: AppFont.merriweather,
    ),
  ),
  thePilot(
    label: 'The Pilot',
    vibe: 'CHARISMATIC',
    diff: 'NORMAL',
    elem: 'COSMIC',
    whimsicalDescription: 'A rogueish grin and a trusty sidearm. Space silver, trust blue, and starlight — for the gungeoneer who talks their way in and shoots their way out.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0A0E1A),
      card: Color(0xFF121829),
      primary: Color(0xFF42A5F5), // trust blue
      secondary: Color(0xFFB0BEC5), // space silver
      headlineStat: Color(0xFF82B1FF), // light blue
      bulletColor: Color(0xFF42A5F5),
      bulletGlyph: '★',
      sparkleNumbers: true,
      numberGlowColor: Color(0xFF42A5F5),
      tabularFigures: true,
      numberSizeScale: 1.05,
      numberWeight: FontWeight.w700,
      chipRadius: 10,
      cardRadius: 12,
      cardBorderColor: Color(0x4442A5F5),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x5542A5F5),
      dividerThickness: 1.0,
      glowPrimary: Color(0x4442A5F5),
      glowSecondary: Color(0x33B0BEC5),
      auraStyle: AvatarAuraStyle.cosmicTemporal,
      headerGlyph: '★',
      headerUnderlineColor: Color(0x8842A5F5),
      statGroupCombat: Color(0xFF42A5F5),
      statGroupHandling: Color(0xFFB0BEC5),
      statGroupMeta: Color(0xFF82B1FF),
      font: AppFont.orbitron,
    ),
  ),
  theRat(
    label: 'The Resourceful Rat',
    vibe: 'CUNNING',
    diff: 'NORMAL',
    elem: 'GOLD',
    whimsicalDescription: 'A dealmaker in the dark. Cheese gold, rat brown, and stolen silver — for the gungeoneer who always has a backup plan and a price.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF12100A),
      card: Color(0xFF1E1A10),
      primary: Color(0xFFFFC107), // cheese gold
      secondary: Color(0xFF8D6E63), // rat brown
      headlineStat: Color(0xFFFFD54F), // bright gold
      bulletColor: Color(0xFFFFC107),
      bulletGlyph: '◆',
      shimmerHeadline: true,
      tabularFigures: true,
      numberSizeScale: 1.04,
      numberWeight: FontWeight.w700,
      chipRadius: 8,
      cardRadius: 10,
      cardBorderColor: Color(0x44FFC107),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x55FFC107),
      dividerThickness: 1.0,
      glowPrimary: Color(0x44FFC107),
      glowSecondary: Color(0x338D6E63),
      auraStyle: AvatarAuraStyle.pastelPulse,
      headerGlyph: '◆',
      headerUnderlineColor: Color(0x88FFC107),
      statGroupCombat: Color(0xFFFFC107),
      statGroupHandling: Color(0xFF8D6E63),
      statGroupMeta: Color(0xFFFFD54F),
      font: AppFont.pressStart2p,
    ),
  ),
  // ── 6 Floor Themes ─────────────────────────────────────────────
  breachGateway(
    label: 'The Breach',
    vibe: 'ENTRY',
    diff: 'NORMAL',
    elem: 'PORTAL',
    whimsicalDescription: 'The gateway shimmers. Portal purple, breach blue, and starlight white — the first step into the gungeon, where every run begins.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0A0814),
      card: Color(0xFF14102A),
      primary: Color(0xFF7C4DFF), // portal purple
      secondary: Color(0xFF18FFFF), // portal cyan
      headlineStat: Color(0xFFB388FF), // light purple
      bulletColor: Color(0xFF7C4DFF),
      bulletGlyph: '◉',
      sparkleNumbers: true,
      numberGlowColor: Color(0xFF7C4DFF),
      tabularFigures: true,
      numberSizeScale: 1.05,
      numberWeight: FontWeight.w700,
      chipRadius: 14,
      cardRadius: 16,
      cardBorderColor: Color(0x447C4DFF),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x557C4DFF),
      dividerThickness: 1.0,
      glowPrimary: Color(0x447C4DFF),
      glowSecondary: Color(0x3318FFFF),
      auraStyle: AvatarAuraStyle.paradoxRift,
      headerGlyph: '◉',
      headerUnderlineColor: Color(0x887C4DFF),
      statGroupCombat: Color(0xFF7C4DFF),
      statGroupHandling: Color(0xFF18FFFF),
      statGroupMeta: Color(0xFFB388FF),
      font: AppFont.rajdhani,
    ),
  ),
  leadLordKeep(
    label: "Lead Lord's Keep",
    vibe: 'REGAL',
    diff: 'NORMAL',
    elem: 'BRASS',
    whimsicalDescription: 'The first chamber, ruled by the Bullet King. Brass, gold, and stone grey — a regal hall where the gungeon begins in earnest.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF12100A),
      card: Color(0xFF221E14),
      primary: Color(0xFFC5A05E), // brass
      secondary: Color(0xFFD4AF37), // gold
      headlineStat: Color(0xFFFFD700), // bright gold
      bulletColor: Color(0xFFC5A05E),
      bulletGlyph: '❖',
      shimmerHeadline: true,
      tabularFigures: true,
      numberSizeScale: 1.06,
      numberWeight: FontWeight.w800,
      chipRadius: 10,
      cardRadius: 12,
      cardBorderColor: Color(0x66C5A05E),
      cardBorderWidth: 1.2,
      dividerColor: Color(0x55C5A05E),
      dividerThickness: 1.0,
      glowPrimary: Color(0x44C5A05E),
      glowSecondary: Color(0x33D4AF37),
      auraStyle: AvatarAuraStyle.pastelPulse,
      headerGlyph: '❖',
      headerUnderlineColor: Color(0xAAC5A05E),
      statGroupCombat: Color(0xFFC5A05E),
      statGroupHandling: Color(0xFFD4AF37),
      statGroupMeta: Color(0xFFFFD700),
      font: AppFont.cinzelDecorative,
    ),
  ),
  oubliettePit(
    label: 'The Oubliette',
    vibe: 'TOXIC',
    diff: 'HARD',
    elem: 'POISON',
    whimsicalDescription: 'A forgotten chamber of sewage and poison. Toxic green, rust orange, and murky brown — for the gungeoneer who ventures where others flush.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0A1208),
      card: Color(0xFF121E0E),
      primary: Color(0xFF8BC34A), // toxic green
      secondary: Color(0xFFBF360C), // rust
      headlineStat: Color(0xFFAED581), // light green
      bulletColor: Color(0xFF8BC34A),
      bulletGlyph: '☠',
      tabularFigures: true,
      numberSizeScale: 1.04,
      numberWeight: FontWeight.w700,
      chipRadius: 8,
      cardRadius: 10,
      cardBorderColor: Color(0x448BC34A),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x558BC34A),
      dividerThickness: 1.0,
      glowPrimary: Color(0x448BC34A),
      glowSecondary: Color(0x33BF360C),
      glowStyle: GlowStyle.drip,
      auraStyle: AvatarAuraStyle.toxicOoze,
      headerGlyph: '☠',
      headerUnderlineColor: Color(0x888BC34A),
      statGroupCombat: Color(0xFF8BC34A),
      statGroupHandling: Color(0xFFBF360C),
      statGroupMeta: Color(0xFFAED581),
      font: AppFont.shareTechMono,
    ),
  ),
  blackPowderMine(
    label: 'Black Powder Mine',
    vibe: 'INDUSTRIAL',
    diff: 'HARD',
    elem: 'EXPLOSIVE',
    whimsicalDescription: 'A mine shaft of coal and gunpowder. Spark orange, coal black, and rust brown — for the gungeoneer who digs deep and shoots straight.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0A0A08),
      card: Color(0xFF14140E),
      primary: Color(0xFFFF6F00), // spark orange
      secondary: Color(0xFF795548), // coal brown
      headlineStat: Color(0xFFFFAB40), // light orange
      bulletColor: Color(0xFFFF6F00),
      bulletGlyph: '✸',
      shimmerHeadline: true,
      tabularFigures: true,
      numberSizeScale: 1.06,
      numberWeight: FontWeight.w800,
      chipRadius: 6,
      cardRadius: 8,
      cardBorderColor: Color(0x44FF6F00),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x55FF6F00),
      dividerThickness: 1.0,
      glowPrimary: Color(0x55FF6F00),
      glowSecondary: Color(0x33795548),
      auraStyle: AvatarAuraStyle.forgeGlow,
      headerGlyph: '✸',
      headerUnderlineColor: Color(0xAAFF6F00),
      statGroupCombat: Color(0xFFFF6F00),
      statGroupHandling: Color(0xFF795548),
      statGroupMeta: Color(0xFFFFAB40),
      font: AppFont.blackOpsOne,
    ),
  ),
  bulletHellFloor(
    label: 'Bullet Hell',
    vibe: 'APOCALYPTIC',
    diff: 'EXTREME',
    elem: 'BULLET',
    whimsicalDescription: 'The final floor. Blood red, bullet black, and warning yellow — for the gungeoneer who has killed their past and lives to tell about it.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0A0404),
      card: Color(0xFF140808),
      primary: Color(0xFFD32F2F), // blood red
      secondary: Color(0xFFFFC107), // warning yellow
      headlineStat: Color(0xFFFF5252), // bright red
      bulletColor: Color(0xFFD32F2F),
      bulletGlyph: '✕',
      shimmerHeadline: true,
      tabularFigures: true,
      numberSizeScale: 1.08,
      numberWeight: FontWeight.w800,
      chipRadius: 4,
      cardRadius: 6,
      cardBorderColor: Color(0x66D32F2F),
      cardBorderWidth: 1.2,
      dividerColor: Color(0x55D32F2F),
      dividerThickness: 1.0,
      glowPrimary: Color(0x55D32F2F),
      glowSecondary: Color(0x44FFC107),
      glowStyle: GlowStyle.ember,
      auraStyle: AvatarAuraStyle.lichPurple,
      headerGlyph: '✕',
      headerUnderlineColor: Color(0xAAD32F2F),
      statGroupCombat: Color(0xFFD32F2F),
      statGroupHandling: Color(0xFFFFC107),
      statGroupMeta: Color(0xFFFF5252),
      font: AppFont.archivoBlack,
    ),
  ),
  rgDepartment(
    label: 'R&G Department',
    vibe: 'BUREAUCRATIC',
    diff: 'EXPERT',
    elem: 'NEON',
    whimsicalDescription: 'The office floor of the Research & Development Department. Neon green, paper white, and office grey — for the gungeoneer who files paperwork between bullets.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0C0C0C),
      card: Color(0xFF181818),
      primary: Color(0xFF00E676), // neon green
      secondary: Color(0xFFE0E0E0), // paper white
      headlineStat: Color(0xFF69F0AE), // light green
      bulletColor: Color(0xFF00E676),
      bulletGlyph: '▸',
      tabularFigures: true,
      numberSizeScale: 1.04,
      numberWeight: FontWeight.w700,
      chipRadius: 6,
      cardRadius: 8,
      cardBorderColor: Color(0x4400E676),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x4400E676),
      dividerThickness: 0.8,
      glowPrimary: Color(0x4400E676),
      glowSecondary: Color(0x22E0E0E0),
      auraStyle: AvatarAuraStyle.lightningArc,
      headerGlyph: '▸',
      headerUnderlineColor: Color(0x8800E676),
      statGroupCombat: Color(0xFF00E676),
      statGroupHandling: Color(0xFFE0E0E0),
      statGroupMeta: Color(0xFF69F0AE),
      font: AppFont.jetBrainsMono,
    ),
  ),
  custom(
    label: 'Custom',
    vibe: 'TACTICAL',
    diff: 'NORMAL',
    elem: 'BULLET',
    whimsicalDescription: 'A blank canvas of absolute personal madness. Paint the town in your own choice of radioactive colors. Godspeed, designer!',
    staticFlair: null,
  ),
  minimalist(
    label: 'Minimalist',
    vibe: 'CLEAN',
    diff: 'NORMAL',
    elem: 'METAL',
    whimsicalDescription: 'A stripped-back metallic interface: pure black, clean white, and cold grey. No glow, no noise — just crisp information.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0A0A0A),
      card: Color(0xFF121212),
      primary: Color(0xFFE0E0E0),
      secondary: Color(0xFF9E9E9E),
      headlineStat: Color(0xFFFFFFFF),
      bulletColor: Color(0xFFBDBDBD),
      bulletGlyph: '—',
      tabularFigures: true,
      numberSizeScale: 1.0,
      numberWeight: FontWeight.w800,
      numberStyle: FontStyle.normal,
      chipRadius: 4,
      cardRadius: 6,
      cardBorderColor: Color(0x33FFFFFF),
      cardBorderWidth: 1.0,
      chipFilled: false,
      dividerColor: Color(0x22FFFFFF),
      dividerThickness: 0.5,
      glowPrimary: Color(0x11FFFFFF),
      glowSecondary: Color(0x08FFFFFF),
      auraStyle: AvatarAuraStyle.none,
      headerGlyph: null,
      headerAllCaps: true,
      headerUnderlineColor: Color(0x44FFFFFF),
      pageFrame: true,
      font: AppFont.dmSans,
    ),
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
        glowStyle: GlowStyle.orbit,
        auraStyle: data.auraStyle,
        headerGlyph: null,
        headerUnderlineColor: data.primary.withValues(alpha: 0.5),
      );
    }
    return _staticFlair!;
  }

  /// Asset slug for the theme's splash image (e.g. 'unicorn',
  /// 'forge_master'). Returns '' for themes without a splash asset.
  String get splashSlug => switch (this) {
        AppThemeMode.unicorn => 'unicorn',
        AppThemeMode.forgeMaster => 'forge_master',
        AppThemeMode.robotsCore => 'robots_core',
        AppThemeMode.catLady => 'cat_lady',
        AppThemeMode.moonlitChamber => 'moonlit_chamber',
        AppThemeMode.stormCaller => 'storm_caller',
        AppThemeMode.mrRobot => 'mr_robot',
        AppThemeMode.valorOfMarines => 'valor_of_marines',
        AppThemeMode.theBullet => 'the_bullet',
        AppThemeMode.theParadox => 'the_paradox',
        AppThemeMode.gunpowder => 'gunpowder',
        AppThemeMode.dragunfire => 'dragunfire',
        AppThemeMode.lichsDomain => 'lichs_domain',
        AppThemeMode.theCultist => 'the_cultist',
        AppThemeMode.theGunslinger => 'the_gunslinger',
        AppThemeMode.theConvict => 'the_convict',
        AppThemeMode.theHunter => 'the_hunter',
        AppThemeMode.thePilot => 'the_pilot',
        AppThemeMode.theRat => 'the_rat',
        AppThemeMode.breachGateway => 'the_breach',
        AppThemeMode.leadLordKeep => 'lead_lord_keep',
        AppThemeMode.oubliettePit => 'the_oubliette',
        AppThemeMode.blackPowderMine => 'black_powder_mine',
        AppThemeMode.bulletHellFloor => 'bullet_hell',
        AppThemeMode.rgDepartment => 'rg_department',
        AppThemeMode.custom => 'custom',
        _ => '',
      };
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
          primary: Color(0xFFFF80AB), // bubblegum pink (pastel — distinct from Neon's dark hot pink)
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

  /// Per-palette particle colors for the unicorn sparkle effect.
  /// Derived from each palette's flair colors for visual coherence.
  /// Used via ParticleField's colorsOverride when the unicorn theme is active.
  List<Color> get particleColors => switch (this) {
        cottonCandy => const [Color(0xFFFF69B4), Color(0xFFE8A7F0), Color(0xFFF06292), Color(0xFF00E5FF)],
        neon => const [Color(0xFFFF1493), Color(0xFFDA70D6), Color(0xFFE040FB), Color(0xFF00E5FF)],
        dreamy => const [Color(0xFFF8BBD0), Color(0xFFD1C4E9), Color(0xFFCE93D8), Color(0xFFB39DDB)],
        sunset => const [Color(0xFFFF6B9D), Color(0xFFFFAB91), Color(0xFFFFD1DC), Color(0xFFFFCC80)],
        bubblegum => const [Color(0xFFFF80AB), Color(0xFFE040FB), Color(0xFFB388FF), Color(0xFFFFD700)],
        mulberry => const [Color(0xFFC2185B), Color(0xFF9C27B0), Color(0xFFF06292), Color(0xFFE040FB)],
      };
}

enum AppFont {
  // ── Featured (locked) ──
  gungeon,
  megrim,
  // ── Pixel & Retro ──
  pressStart2p,
  silkscreen,
  vt323,
  pixelifySans,
  // ── Sci-Fi & Tech ──
  blackOpsOne,
  orbitron,
  shareTechMono,
  syncopate,
  rajdhani,
  audiowide,
  russoOne,
  fasterOne,
  jetBrainsMono,
  // ── Display & Impact ──
  archivoBlack,
  anton,
  rowdies,
  righteous,
  bebasNeue,
  // ── Casual & Fun ──
  fredoka,
  carterOne,
  // ── Clean & Modern ──
  dmSans,
  montserrat,
  // ── Gothic & Fantasy ──
  medievalSharp,
  cinzelDecorative,
  cinzel,
  // ── Serif & Editorial ──
  merriweather,
  specialElite,
  playfairDisplay,
}

extension AppFontLabel on AppFont {
  static const Map<AppFont, String> _googleFontNames = {
    AppFont.pressStart2p: 'Press Start 2P',
    AppFont.silkscreen: 'Silkscreen',
    AppFont.vt323: 'VT323',
    AppFont.pixelifySans: 'Pixelify Sans',
    AppFont.blackOpsOne: 'Black Ops One',
    AppFont.orbitron: 'Orbitron',
    AppFont.shareTechMono: 'Share Tech Mono',
    AppFont.syncopate: 'Syncopate',
    AppFont.rajdhani: 'Rajdhani',
    AppFont.audiowide: 'Audiowide',
    AppFont.russoOne: 'Russo One',
    AppFont.fasterOne: 'Faster One',
    AppFont.jetBrainsMono: 'JetBrains Mono',
    AppFont.archivoBlack: 'Archivo Black',
    AppFont.anton: 'Anton',
    AppFont.rowdies: 'Rowdies',
    AppFont.righteous: 'Righteous',
    AppFont.bebasNeue: 'Bebas Neue',
    AppFont.fredoka: 'Fredoka',
    AppFont.carterOne: 'Carter One',
    AppFont.dmSans: 'DM Sans',
    AppFont.montserrat: 'Montserrat',
    AppFont.medievalSharp: 'MedievalSharp',
    AppFont.cinzelDecorative: 'Cinzel Decorative',
    AppFont.cinzel: 'Cinzel',
    AppFont.merriweather: 'Merriweather',
    AppFont.specialElite: 'Special Elite',
    AppFont.playfairDisplay: 'Playfair Display',
    AppFont.megrim: 'Megrim',
  };

  static const Map<AppFont, String> _googleFontDescriptions = {
    AppFont.pressStart2p: 'Classic 8-bit NES arcade pixel',
    AppFont.silkscreen: 'Crisp tiny 8-bit screen font',
    AppFont.vt323: 'Nostalgic glowing CRT terminal font',
    AppFont.pixelifySans: 'Modern hybrid geometric pixel art',
    AppFont.blackOpsOne: 'Military industrial stencil look',
    AppFont.orbitron: 'Futuristic sci-fi aerospace tech',
    AppFont.shareTechMono: 'Clean digital cybernetic HUD console',
    AppFont.syncopate: 'Wide high-end cyberpunk architecture',
    AppFont.rajdhani: 'Squarish military armor tech plates',
    AppFont.audiowide: 'Smooth streamlined robotic lettering',
    AppFont.russoOne: 'Heavy soviet metal sci-fi gaming',
    AppFont.fasterOne: 'Wind-tunnel racing speed blur lines',
    AppFont.jetBrainsMono: 'Elite software engineer monospace editor',
    AppFont.archivoBlack: 'Ultra heavy high-visibility signage',
    AppFont.anton: 'Thick solid impact display blocks',
    AppFont.rowdies: 'Edgy casual heavy fighting style',
    AppFont.righteous: 'Cool geometric art deco bubble-sans',
    AppFont.bebasNeue: 'Clean condensed billboard display legend',
    AppFont.fredoka: 'Cute rounded friendly organic blocks',
    AppFont.carterOne: 'Thick vintage brush logo signwriting',
    AppFont.dmSans: 'Neutral geometric modern interface sans',
    AppFont.montserrat: 'Clean urban geometric architectural sans',
    AppFont.medievalSharp: 'Sharp runic celtic iron broadsword',
    AppFont.cinzelDecorative: 'Ornate royalty fantasy crown capitals',
    AppFont.cinzel: 'Formal ancient roman stone carving',
    AppFont.merriweather: 'Robust highly readable editorial serif',
    AppFont.specialElite: 'Grungy ink-splattered vintage typewriter',
    AppFont.playfairDisplay: 'Luxurious high-contrast theatrical display',
    AppFont.megrim: 'Ultra-stylized thin wire outline vector',
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
  AppThemeMode.minimalist,
  AppThemeMode.unicorn,
  AppThemeMode.forgeMaster,
  AppThemeMode.robotsCore,
  AppThemeMode.catLady,
  AppThemeMode.moonlitChamber,
  AppThemeMode.stormCaller,
  AppThemeMode.mrRobot,
  AppThemeMode.valorOfMarines,
  AppThemeMode.theBullet,
  AppThemeMode.theParadox,
  AppThemeMode.gunpowder,
  AppThemeMode.dragunfire,
  AppThemeMode.lichsDomain,
  AppThemeMode.custom,
];

/// The curated themes shown in the theme picker — cut to three for
/// v3.0 (the broad picker confused users; each remaining theme's
/// customization is clearer). Users persisted on a removed theme are
/// migrated to Moonlit Chamber at load time.
/// Minimalist stays in [kVisibleThemes] as the plain default look.
const List<AppThemeMode> kPickerThemes = <AppThemeMode>[
  // Unicorn family — OG + 2 variants
  AppThemeMode.unicorn,
  AppThemeMode.candyRush,
  AppThemeMode.neonPrism,
  // Forge family — OG + 2 variants
  AppThemeMode.forgeMaster,
  AppThemeMode.blacksmithsFire,
  AppThemeMode.moltenSteel,
  // Minimalist family — OG + 2 variants
  AppThemeMode.moonlitChamber,
  AppThemeMode.paperInk,
  AppThemeMode.voidWhite,
];

/// Per-theme default particle preset. When a theme is active and the user
/// hasn't explicitly chosen a different preset (still on [ParticlePreset.gungeonDust]),
/// the theme overlay auto-applies the preset listed here. This gives every
/// visible theme a distinct particle identity out of the box without
/// clobbering an explicit user choice.
const Map<AppThemeMode, ParticlePreset> kThemeParticleDefaults =
    <AppThemeMode, ParticlePreset>{
  AppThemeMode.minimalist: ParticlePreset.gungeonDust,
  AppThemeMode.unicorn: ParticlePreset.unicornSparkles,
  AppThemeMode.unicornII: ParticlePreset.unicornSparkles,
  AppThemeMode.unicornIII: ParticlePreset.unicornSparkles,
  AppThemeMode.unicornIV: ParticlePreset.unicornSparkles,
  AppThemeMode.ammonomicon: ParticlePreset.cosmicDust,
  AppThemeMode.forgeMaster: ParticlePreset.forgeEmbers,
  AppThemeMode.hollowChill: ParticlePreset.frostShards,
  AppThemeMode.lordJammed: ParticlePreset.jamHexes,
  AppThemeMode.theBreach: ParticlePreset.gungeonDust,
  AppThemeMode.bulletHell: ParticlePreset.bulletHell,
  AppThemeMode.resourcefulRat: ParticlePreset.goldenSparkle,
  AppThemeMode.gungeonProper: ParticlePreset.gungeonDust,
  AppThemeMode.theOubliette: ParticlePreset.cursedSmoke,
  AppThemeMode.pastParadox: ParticlePreset.cosmicStars,
  AppThemeMode.highPriestVoid: ParticlePreset.voidRift,
  AppThemeMode.robotsCore: ParticlePreset.cosmicStars,
  AppThemeMode.cultOfGundead: ParticlePreset.cursedSkulls,
  AppThemeMode.synergySurge: ParticlePreset.cosmicDust,
  AppThemeMode.glitchedChest: ParticlePreset.rainbowConfetti,
  AppThemeMode.lichsTomb: ParticlePreset.cursedSkulls,
  AppThemeMode.winchestersGame: ParticlePreset.goldenSparkle,
  AppThemeMode.catLady: ParticlePreset.catPaws,
  AppThemeMode.moonlitChamber: ParticlePreset.moonlight,
  AppThemeMode.stormCaller: ParticlePreset.lightningBolts,
  AppThemeMode.mrRobot: ParticlePreset.circuitTraces,
  AppThemeMode.valorOfMarines: ParticlePreset.shellCasings,
  AppThemeMode.theBullet: ParticlePreset.heroicBlades,
  AppThemeMode.theParadox: ParticlePreset.paradoxShards,
  AppThemeMode.gunpowder: ParticlePreset.gunpowderSmoke,
  AppThemeMode.dragunfire: ParticlePreset.dragunScales,
  AppThemeMode.lichsDomain: ParticlePreset.boneShards,
  // ── 12 new themes (v2.0.4) ──
  AppThemeMode.theCultist: ParticlePreset.cursedSkulls,
  AppThemeMode.theGunslinger: ParticlePreset.goldenSparkle,
  AppThemeMode.theConvict: ParticlePreset.solarFlare,
  AppThemeMode.theHunter: ParticlePreset.crystalLattice,
  AppThemeMode.thePilot: ParticlePreset.cosmicStars,
  AppThemeMode.theRat: ParticlePreset.hegemonyCredits,
  AppThemeMode.breachGateway: ParticlePreset.cosmicDust,
  AppThemeMode.leadLordKeep: ParticlePreset.brassCasings,
  AppThemeMode.oubliettePit: ParticlePreset.toxicBubbles,
  AppThemeMode.blackPowderMine: ParticlePreset.gunpowderSmoke,
  AppThemeMode.bulletHellFloor: ParticlePreset.bulletHell,
  AppThemeMode.rgDepartment: ParticlePreset.circuitTraces,
  AppThemeMode.custom: ParticlePreset.cosmicStars,
};

/// Curated visual settings for a premade theme. When a user selects a
/// premade theme, these settings are applied to give the theme a
/// complete, intentional identity — not just colors but particles,
/// glow, shader, and font too.
class ThemeCuration {
  final ParticlePreset particlePreset;
  final ParticleColorSchema colorSchema;
  final GlowEffect glowEffect;
  final ParticleSpeed speed;
  final int particleCount;
  final double particleSizeScale;
  final double particleOpacity;
  final bool particleLineLinks;
  final bool particleBounce;
  final int glowColorIndex;
  final double glowIntensity;
  final bool shaderEnabled;
  final ShaderPreset? shaderPreset;

  const ThemeCuration({
    required this.particlePreset,
    this.colorSchema = ParticleColorSchema.presetDefault,
    this.glowEffect = GlowEffect.smokey,
    this.speed = ParticleSpeed.normal,
    this.particleCount = 28,
    this.particleSizeScale = 1.0,
    this.particleOpacity = 0.8,
    this.particleLineLinks = false,
    this.particleBounce = false,
    this.glowColorIndex = 0,
    this.glowIntensity = 0.15,
    this.shaderEnabled = false,
    this.shaderPreset,
  });
}

/// Curated settings for each of the 8 premade picker themes.
/// When a user selects a premade, these are applied to VisualPrefs
/// so the theme has a complete, polished identity out of the box.
const Map<AppThemeMode, ThemeCuration> kThemeCuration =
    <AppThemeMode, ThemeCuration>{
  AppThemeMode.unicorn: ThemeCuration(
    particlePreset: ParticlePreset.unicornSparkles,
    colorSchema: ParticleColorSchema.candy,
    glowEffect: GlowEffect.pulse,
    speed: ParticleSpeed.slow,
    particleCount: 20,
    particleOpacity: 0.9,
    glowColorIndex: 2, // pink
    glowIntensity: 0.25,
    shaderEnabled: true,
    shaderPreset: ShaderPreset.darkNeonFog,
  ),
  AppThemeMode.forgeMaster: ThemeCuration(
    particlePreset: ParticlePreset.forgeEmbers,
    colorSchema: ParticleColorSchema.inferno,
    glowEffect: GlowEffect.ember,
    speed: ParticleSpeed.normal,
    particleCount: 18,
    particleOpacity: 0.85,
    glowColorIndex: 1, // amber
    glowIntensity: 0.3,
    shaderEnabled: true,
    shaderPreset: ShaderPreset.darkNeonFog,
  ),
  AppThemeMode.moonlitChamber: ThemeCuration(
    particlePreset: ParticlePreset.moonlight,
    colorSchema: ParticleColorSchema.glacier,
    glowEffect: GlowEffect.smokey,
    speed: ParticleSpeed.verySlow,
    particleCount: 14,
    particleOpacity: 0.7,
    glowColorIndex: 4, // blue
    glowIntensity: 0.2,
    shaderEnabled: true,
    shaderPreset: ShaderPreset.darkNeonFog,
  ),
  AppThemeMode.theBullet: ThemeCuration(
    particlePreset: ParticlePreset.heroicBlades,
    colorSchema: ParticleColorSchema.gilded,
    glowEffect: GlowEffect.neon,
    speed: ParticleSpeed.fast,
    particleCount: 16,
    particleOpacity: 0.85,
    glowColorIndex: 3, // gold
    glowIntensity: 0.25,
    shaderEnabled: false,
  ),
  AppThemeMode.theParadox: ThemeCuration(
    particlePreset: ParticlePreset.paradoxShards,
    colorSchema: ParticleColorSchema.voidStorm,
    glowEffect: GlowEffect.spectral,
    speed: ParticleSpeed.normal,
    particleCount: 22,
    particleOpacity: 0.75,
    glowColorIndex: 6, // purple
    glowIntensity: 0.3,
    shaderEnabled: true,
    shaderPreset: ShaderPreset.digitalRain,
  ),
  AppThemeMode.dragunfire: ThemeCuration(
    particlePreset: ParticlePreset.dragunScales,
    colorSchema: ParticleColorSchema.inferno,
    glowEffect: GlowEffect.ember,
    speed: ParticleSpeed.fast,
    particleCount: 20,
    particleOpacity: 0.9,
    glowColorIndex: 0, // red
    glowIntensity: 0.35,
    shaderEnabled: true,
    shaderPreset: ShaderPreset.darkNeonFog,
  ),
  AppThemeMode.lichsDomain: ThemeCuration(
    particlePreset: ParticlePreset.boneShards,
    colorSchema: ParticleColorSchema.monochrome,
    glowEffect: GlowEffect.cursed,
    speed: ParticleSpeed.slow,
    particleCount: 16,
    particleOpacity: 0.7,
    glowColorIndex: 8, // teal
    glowIntensity: 0.2,
    shaderEnabled: true,
    shaderPreset: ShaderPreset.digitalRain,
  ),
  AppThemeMode.gunpowder: ThemeCuration(
    particlePreset: ParticlePreset.gunpowderSmoke,
    colorSchema: ParticleColorSchema.steel,
    glowEffect: GlowEffect.smokey,
    speed: ParticleSpeed.normal,
    particleCount: 14,
    particleOpacity: 0.65,
    glowColorIndex: 5, // grey
    glowIntensity: 0.15,
    shaderEnabled: false,
  ),
};

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

  /// Cat: warm amber paw-print trail circling the avatar.
  catPawTrail,

  /// Moon: silver-blue crescent glow that breathes with lunar phases.
  moonGlow,

  /// Lightning: crackling electric blue-yellow arc border.
  lightningArc,

  /// Paradox: fractured purple-violet shards orbiting in a time rift.
  paradoxRift,

  /// Dragun: molten orange-red scales rotating around the avatar.
  dragunScale,

  /// Tactical: precise military green crosshair ring with sweep.
  tacticalRing,
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
        return 'The Codex';
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
      case AppThemeMode.catLady:
        return 'Cat Lady';
      case AppThemeMode.candyRush:
        return 'Candy Rush';
      case AppThemeMode.neonPrism:
        return 'Neon Prism';
      case AppThemeMode.blacksmithsFire:
        return "Blacksmith's Fire";
      case AppThemeMode.moltenSteel:
        return 'Molten Steel';
      case AppThemeMode.paperInk:
        return 'Paper & Ink';
      case AppThemeMode.voidWhite:
        return 'Void White';
      case AppThemeMode.moonlitChamber:
        return 'Minimalist';
      case AppThemeMode.stormCaller:
        return 'Storm Caller';
      case AppThemeMode.mrRobot:
        return 'Mr. Robot';
      case AppThemeMode.valorOfMarines:
        return 'Valor of Marines';
      case AppThemeMode.theBullet:
        return 'The Bullet';
      case AppThemeMode.theParadox:
        return 'The Paradox';
      case AppThemeMode.gunpowder:
        return 'Gunpowder';
      case AppThemeMode.dragunfire:
        return 'Dragunfire';
      case AppThemeMode.lichsDomain:
        return "Lich's Domain";
      case AppThemeMode.theCultist:
        return 'The Cultist';
      case AppThemeMode.theGunslinger:
        return 'The Gunslinger';
      case AppThemeMode.theConvict:
        return 'The Convict';
      case AppThemeMode.theHunter:
        return 'The Hunter';
      case AppThemeMode.thePilot:
        return 'The Pilot';
      case AppThemeMode.theRat:
        return 'The Resourceful Rat';
      case AppThemeMode.breachGateway:
        return 'The Breach';
      case AppThemeMode.leadLordKeep:
        return "Lead Lord's Keep";
      case AppThemeMode.oubliettePit:
        return 'The Oubliette';
      case AppThemeMode.blackPowderMine:
        return 'Black Powder Mine';
      case AppThemeMode.bulletHellFloor:
        return 'Bullet Hell';
      case AppThemeMode.rgDepartment:
        return 'R&G Department';
      case AppThemeMode.minimalist:
        return 'Minimalist';
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
      case AppThemeMode.catLady:
        return 'Cozy Den — warm amber, cream, walnut brown with paw prints';
      case AppThemeMode.candyRush:
        return 'Bubblegum — pastel pink, cotton-candy blue, sweet rose';
      case AppThemeMode.neonPrism:
        return 'Neon Spectrum — magenta, cyan, electric gold on night';
      case AppThemeMode.blacksmithsFire:
        return 'Rusted Ember — deep rust, hot copper, scorched iron';
      case AppThemeMode.moltenSteel:
        return 'Iron & Molten — steel greys, one hot orange edge';
      case AppThemeMode.paperInk:
        return 'Sketchbook — ink blue-grey, paper grey, quiet tones';
      case AppThemeMode.voidWhite:
        return 'Stark — pure white on near-black, zero chrome';
      case AppThemeMode.moonlitChamber:
        return 'Distilled — soft whites on deep charcoal, no glow';
      case AppThemeMode.stormCaller:
        return 'High Voltage — electric yellow, voltage blue, storm steel';
      case AppThemeMode.mrRobot:
        return 'Cybernetic — circuit green, battery blue, steel black';
      case AppThemeMode.valorOfMarines:
        return 'Stay Frosty — olive drab, tactical amber, steel gray';
      case AppThemeMode.theBullet:
        return 'Heroic Blade — brass gold, heroic red, steel gray';
      case AppThemeMode.theParadox:
        return 'Fractured Reality — paradox purple, rift violet, stardust';
      case AppThemeMode.gunpowder:
        return 'Explosive — ember red, sulfurous gray, charcoal black';
      case AppThemeMode.dragunfire:
        return 'Molten Inferno — dragun orange, scale amber, ash black';
      case AppThemeMode.lichsDomain:
        return 'Necrotic — crypt teal, bone white, void black';
      case AppThemeMode.theCultist:
        return 'Mystic — candle gold, mystic purple, shadow';
      case AppThemeMode.theGunslinger:
        return 'Legendary — gold, amber, gunmetal';
      case AppThemeMode.theConvict:
        return 'Rebellious — prison orange, rebel red, steel';
      case AppThemeMode.theHunter:
        return 'Wilderness — forest green, bark brown, silver';
      case AppThemeMode.thePilot:
        return 'Charismatic — trust blue, space silver, starlight';
      case AppThemeMode.theRat:
        return 'Cunning — cheese gold, rat brown, stolen silver';
      case AppThemeMode.breachGateway:
        return 'Entry — portal purple, breach cyan, starlight';
      case AppThemeMode.leadLordKeep:
        return 'Regal — brass, gold, stone grey';
      case AppThemeMode.oubliettePit:
        return 'Toxic — toxic green, rust, murky brown';
      case AppThemeMode.blackPowderMine:
        return 'Industrial — spark orange, coal black, rust';
      case AppThemeMode.bulletHellFloor:
        return 'Apocalyptic — blood red, bullet black, warning yellow';
      case AppThemeMode.rgDepartment:
        return 'Bureaucratic — neon green, paper white, office grey';
      case AppThemeMode.minimalist:
        return 'Stripped Back — pure black, clean white, cold grey';
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

/// Ambient fragment shader preset (Q3 genius audit). Each preset maps
/// to a .frag file in assets/shaders/. See AmbientShaderLayer.
enum ShaderPreset {
  digitalRain,
  darkNeonFog;
}

extension ShaderPresetX on ShaderPreset {
  String get label => switch (this) {
        ShaderPreset.digitalRain => 'Digital Rain',
        ShaderPreset.darkNeonFog => 'Dark Neon Fog',
      };
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

  /// Serialize for embedding inside SavedCustomTheme.
  Map<String, dynamic> toJson() => {
    'name': name,
    'scaffold': scaffold.toARGB32(),
    'card': card.toARGB32(),
    'primary': primary.toARGB32(),
    'secondary': secondary.toARGB32(),
    'headlineStat': headlineStat.toARGB32(),
    'bulletColor': bulletColor.toARGB32(),
    'auraStyle': auraStyle.index,
    'font': font.index,
  };

  /// Deserialize from embedded JSON. Color fields fall back to defaults
  /// if missing (handles legacy/partial JSON gracefully).
  factory CustomThemeData.fromJson(Map<String, dynamic> j) {
    final d = CustomThemeData.defaultTheme;
    return CustomThemeData(
      name: j['name'] as String? ?? 'Custom',
      scaffold: Color(j['scaffold'] as int? ?? d.scaffold.toARGB32()),
      card: Color(j['card'] as int? ?? d.card.toARGB32()),
      primary: Color(j['primary'] as int? ?? d.primary.toARGB32()),
      secondary: Color(j['secondary'] as int? ?? d.secondary.toARGB32()),
      headlineStat: Color(j['headlineStat'] as int? ?? d.headlineStat.toARGB32()),
      bulletColor: Color(j['bulletColor'] as int? ?? d.bulletColor.toARGB32()),
      auraStyle: AvatarAuraStyle.values[j['auraStyle'] as int? ?? 0],
      font: AppFont.values[j['font'] as int? ?? 0],
    );
  }

  /// Copy with optional overrides (used by color picker).
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
    } catch (e) { debugPrint('[AppTheme] prefs error: $e'); }
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
    } catch (e) { debugPrint('[AppTheme] prefs error: $e'); }
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
    } catch (e) { debugPrint('[AppTheme] prefs error: $e'); }
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

/// Per-theme ambient glow animation style. Controls how the
/// [_AmbientGlow] layer behind every theme moves and pulses.
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

  /// Per-theme ambient glow animation style. See [GlowStyle].
  final GlowStyle glowStyle;

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

  /// Optional per-stat-group accent colors for the gun detail screen.
  /// When null, [StatGroup] falls back to semantic defaults
  /// (Combat=red, Handling=cyan, Meta=amber). Themes opt in to
  /// palette-tied group colors by setting these.
  final Color? statGroupCombat;
  final Color? statGroupHandling;
  final Color? statGroupMeta;

  /// Per-theme default font. When non-null, switching to this theme
  /// applies this font. Users can still override via the font picker.
  /// When null, the global VisualPrefs font is used.
  final AppFont? font;

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
    this.glowStyle = GlowStyle.orbit,
    this.auraStyle = AvatarAuraStyle.none,
    this.headerGlyph,
    this.headerAllCaps = false,
    this.headerUnderlineColor,
    this.pageFrame = false,
    this.statGroupCombat,
    this.statGroupHandling,
    this.statGroupMeta,
    this.font,
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
    glowStyle: f.glowStyle,
    auraStyle: f.auraStyle,
    headerGlyph: f.headerGlyph,
    headerAllCaps: f.headerAllCaps,
    headerUnderlineColor: f.headerUnderlineColor != null ? _hueShift(f.headerUnderlineColor!, degrees) : null,
    pageFrame: f.pageFrame,
    statGroupCombat: f.statGroupCombat != null ? _hueShift(f.statGroupCombat!, degrees) : null,
    statGroupHandling: f.statGroupHandling != null ? _hueShift(f.statGroupHandling!, degrees) : null,
    statGroupMeta: f.statGroupMeta != null ? _hueShift(f.statGroupMeta!, degrees) : null,
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
    ThemeRemix(label: 'Ember', hueShift: 25),
    ThemeRemix(label: 'Magma', hueShift: 35),
    ThemeRemix(label: 'Inferno', hueShift: -25),
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
  AppThemeMode.minimalist: [
    ThemeRemix(label: 'Original'),
    ThemeRemix(
      label: 'Graphite',
      flair: ThemeFlair(
        scaffold: Color(0xFF0F0F0F),
        card: Color(0xFF1A1A1A),
        primary: Color(0xFFB0B0B0),
        secondary: Color(0xFF808080),
        headlineStat: Color(0xFFE0E0E0),
        bulletColor: Color(0xFFB0B0B0),
        bulletGlyph: '—',
        tabularFigures: true,
        numberSizeScale: 1.0,
        numberWeight: FontWeight.w800,
        chipRadius: 4,
        cardRadius: 6,
        cardBorderColor: Color(0x33B0B0B0),
        cardBorderWidth: 1.0,
        chipFilled: false,
        dividerColor: Color(0x22B0B0B0),
        dividerThickness: 0.5,
        glowPrimary: Color(0x11B0B0B0),
        glowSecondary: Color(0x08808080),
        auraStyle: AvatarAuraStyle.none,
        headerAllCaps: true,
        headerUnderlineColor: Color(0x44B0B0B0),
        pageFrame: true,
      ),
    ),
    ThemeRemix(
      label: 'Platinum',
      flair: ThemeFlair(
        scaffold: Color(0xFF151515),
        card: Color(0xFF202020),
        primary: Color(0xFFF5F5F5),
        secondary: Color(0xFFC0C0C0),
        headlineStat: Color(0xFFFFFFFF),
        bulletColor: Color(0xFFF5F5F5),
        bulletGlyph: '—',
        tabularFigures: true,
        numberSizeScale: 1.0,
        numberWeight: FontWeight.w800,
        chipRadius: 4,
        cardRadius: 6,
        cardBorderColor: Color(0x33F5F5F5),
        cardBorderWidth: 1.0,
        chipFilled: false,
        dividerColor: Color(0x22F5F5F5),
        dividerThickness: 0.5,
        glowPrimary: Color(0x11F5F5F5),
        glowSecondary: Color(0x08C0C0C0),
        auraStyle: AvatarAuraStyle.none,
        headerAllCaps: true,
        headerUnderlineColor: Color(0x44F5F5F5),
        pageFrame: true,
      ),
    ),
    ThemeRemix(
      label: 'Charcoal',
      flair: ThemeFlair(
        scaffold: Color(0xFF050505),
        card: Color(0xFF0D0D0D),
        primary: Color(0xFF9E9E9E),
        secondary: Color(0xFF616161),
        headlineStat: Color(0xFFBDBDBD),
        bulletColor: Color(0xFF9E9E9E),
        bulletGlyph: '—',
        tabularFigures: true,
        numberSizeScale: 1.0,
        numberWeight: FontWeight.w800,
        chipRadius: 4,
        cardRadius: 6,
        cardBorderColor: Color(0x339E9E9E),
        cardBorderWidth: 1.0,
        chipFilled: false,
        dividerColor: Color(0x229E9E9E),
        dividerThickness: 0.5,
        glowPrimary: Color(0x119E9E9E),
        glowSecondary: Color(0x08616161),
        auraStyle: AvatarAuraStyle.none,
        headerAllCaps: true,
        headerUnderlineColor: Color(0x449E9E9E),
        pageFrame: true,
      ),
    ),
    ThemeRemix(
      label: 'Obsidian',
      flair: ThemeFlair(
        scaffold: Color(0xFF000000),
        card: Color(0xFF080808),
        primary: Color(0xFF757575),
        secondary: Color(0xFF424242),
        headlineStat: Color(0xFFBDBDBD),
        bulletColor: Color(0xFF757575),
        bulletGlyph: '—',
        tabularFigures: true,
        numberSizeScale: 1.0,
        numberWeight: FontWeight.w800,
        chipRadius: 4,
        cardRadius: 6,
        cardBorderColor: Color(0x33757575),
        cardBorderWidth: 1.0,
        chipFilled: false,
        dividerColor: Color(0x22757575),
        dividerThickness: 0.5,
        glowPrimary: Color(0x11757575),
        glowSecondary: Color(0x08424242),
        auraStyle: AvatarAuraStyle.none,
        headerAllCaps: true,
        headerUnderlineColor: Color(0x44757575),
        pageFrame: true,
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
  final int fontLetterSpacing; // ±steps ×0.5pt applied in GoopText

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

  /// Whether the Effects panel accordion is shown on the active-run dashboard.
  final bool showEffectsPanel;

  /// Whether the Shrine tracker panel is shown on the active-run dashboard.
  final bool showShrinePanel;

  /// Whether special-item/gun dashboards are shown on the active-run screen.
  final bool showDashboards;

  /// User-defined column count for the classic Periodic grid. 0 = Auto, or 2, 3, 4.
  final int periodicGridColumnCount;

  /// User-selected particle color schema (overrides preset colors).
  final ParticleColorSchema particleColorSchema;

  /// User-selected particle speed multiplier.
  final ParticleSpeed particleSpeed;

  /// Typed particle system — index into [ParticleType.values] (0 = dot).
  final int particleTypeIndex;

  /// Index into the active theme's 3 flavored color schemas (0-2).
  final int particleSchemaIndex;

  /// Chaotic motion toggle — organic turbulence on top of drift.
  final bool particleChaos;

  /// Touch/tilt-reactive toggle — particles respond to device tilt.
  final bool particleTouch;

  /// Whether ambient fragment shaders (Q3) are enabled. Off by default —
  /// shaders are GPU-intensive and opt-in. See [shaderPreset].
  final bool shaderEnabled;

  /// Which ambient shader to render when [shaderEnabled] is true.
  /// Defaults to [ShaderPreset.digitalRain].
  final ShaderPreset shaderPreset;


  /// Computed scale factor applied globally via MediaQuery.
  double get textScaleFactor => fontSize / 14.0;

  /// Discrete font-size steps the UI presents as chips.
  static const fontSizeSteps = [
    6.0, 8.0, 10.0, 12.0, 14.0, 18.0, 20.0, 24.0, 28.0, 32.0,
  ];

  /// 36 deep, curated glow colors for the ambient screen glow.
  static const glowColors = [
    // Original 12
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
    // 24 new curated colors
    Color(0xFF01579B), // Deep Ocean
    Color(0xFFD32F2F), // Ember Red
    Color(0xFFF57F17), // Sunfire
    Color(0xFF00838F), // Arctic Teal
    Color(0xFF2E7D32), // Forest
    Color(0xFF6A1B9A), // Royal Plum
    Color(0xFFF9A825), // Honey
    Color(0xFF283593), // Navy
    Color(0xFFAD1457), // Wine
    Color(0xFF00695C), // Peacock
    Color(0xFFAD1457), // Raspberry
    Color(0xFF37474F), // Slate
    Color(0xFF1565C0), // Sapphire
    Color(0xFFC62828), // Ruby
    Color(0xFFEF6C00), // Tangerine
    Color(0xFF00ACC1), // Aqua
    Color(0xFF558B2F), // Olive
    Color(0xFF4527A0), // Indigo Night
    Color(0xFFC17900), // Bronze
    Color(0xFF1A237E), // Midnight
    Color(0xFF6D214F), // Maroon
    Color(0xFF0D7377), // Lagoon
    Color(0xFF8E24AA), // Orchid
    Color(0xFF455A64), // Steel
    // 12 pinks & purples — the glow lab's neon side
    Color(0xFFEC407A), // Hot Pink
    Color(0xFFAB47BC), // Mauve Glow
    Color(0xFF7B1FA2), // Deep Purple
    Color(0xFFD81B60), // Raspberry
    Color(0xFF9C27B0), // Neon Violet
    Color(0xFFBA68C8), // Lilac
    Color(0xFFE91E63), // Magenta Blaze
    Color(0xFF8E24AA), // Amethyst
    Color(0xFFCE93D8), // Soft Orchid
    Color(0xFFF06292), // Bubblegum
    Color(0xFF5E35B1), // Ultraviolet
    Color(0xFFAD1457), // Deep Rose
  ];

  const VisualPrefs({
    this.glowIntensity = 0.0,
    this.particlesEnabled = true,
    this.particlePreset = ParticlePreset.gungeonDust,
    this.particleGlowEffect = GlowEffect.none,
    this.particleLineLinks = false,
    this.particleBounce = false,
    this.glowColorIndex = 0,
    this.fontWeightBias = 0,
    this.fontLetterSpacing = 0,
    this.font = AppFont.gungeon,
    this.fontSize = 12.0,
    this.inventoryFontSize = 12.0,
    this.inventoryDisplayMode = InventoryDisplayMode.classicPeriodic,
    this.customDiceType = CustomDiceType.themeDefault,
    this.particleSizeScale = 1.0,
    this.particleOpacity = 0.55,
    this.particleCount = 32,
    this.dialogueHapticsEnabled = true,
    this.dialogueTextSpeedMs = 30,
    this.isGoopianLanguage = false,
    this.spongeActive = false,
    this.showEffectsPanel = false,
    this.showShrinePanel = false,
    this.showDashboards = true,
    this.periodicGridColumnCount = 0,
    this.particleColorSchema = ParticleColorSchema.presetDefault,
    this.particleSpeed = ParticleSpeed.normal,
    this.particleTypeIndex = 0,
    this.particleSchemaIndex = 0,
    this.particleChaos = false,
    this.particleTouch = true,
    this.shaderEnabled = false,
    this.shaderPreset = ShaderPreset.digitalRain,
  });

  static const _kGlow     = 'vp.glow_v1';
  static const _kParticles = 'vp.particles_v2'; // v2: default on (was v1=false)
  static const _kSpacing = 'visual.font.spacing';
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
  static const _kShowEffectsPanel = 'vp.show_effects_panel_v1';
  static const _kShowShrinePanel = 'vp.show_shrine_panel_v1';
  static const _kShowDashboards = 'vp.show_dashboards_v1';
  static const _kPeriodicGridColumnCount = 'vp.periodic_grid_column_count_v1';
  static const _kParticleColorSchema = 'vp.particle_color_schema_v1';
  static const _kParticleSpeed = 'vp.particle_speed_v1';
  static const _kParticleTypeIdx = 'vp.particle_type_v1';
  static const _kParticleSchemaIdx = 'vp.particle_schema_idx_v1';
  static const _kParticleChaos = 'vp.particle_chaos_v1';
  static const _kParticleTouch = 'vp.particle_touch_v1';
  static const _kShaderEnabled = 'vp.shader_enabled_v1';
  static const _kShaderPreset = 'vp.shader_preset_v1';

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
        fontSize = _snapToStep(savedSize.clamp(6.0, 20.0));
      } else {
        final legacyScale = p.getDouble(_kScaleLegacy);
        if (legacyScale != null) {
          fontSize = _snapToStep((legacyScale * 14.0).clamp(6.0, 20.0));
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
      final showEffectsPanel = p.getBool(_kShowEffectsPanel) ?? false;
      final showShrinePanel = p.getBool(_kShowShrinePanel) ?? false;
      final showDashboards = p.getBool(_kShowDashboards) ?? true;
      final periodicGridColumnCount = p.getInt(_kPeriodicGridColumnCount) ?? 0;
      final particleColorSchemaIdx = p.getInt(_kParticleColorSchema) ?? 0;
      final particleColorSchema = ParticleColorSchema.values[particleColorSchemaIdx.clamp(0, ParticleColorSchema.values.length - 1)];
      final particleSpeedIdx = p.getInt(_kParticleSpeed) ?? 2;
      final particleSpeed = ParticleSpeed.values[particleSpeedIdx.clamp(0, ParticleSpeed.values.length - 1)];

      final shaderEnabled = p.getBool(_kShaderEnabled) ?? false;
      final shaderPresetIdx = p.getInt(_kShaderPreset) ?? 0;
      final shaderPreset = ShaderPreset.values[shaderPresetIdx.clamp(0, ShaderPreset.values.length - 1)];


      notifier.value = VisualPrefs(
        glowIntensity:    p.getDouble(_kGlow)     ?? 0.0,
        particlesEnabled: p.getBool(_kParticles)  ?? true,
        particlePreset:   particlePreset,
        particleGlowEffect: particleGlowEffect,
        particleLineLinks: particleLineLinks,
        particleBounce:   particleBounce,
        glowColorIndex:   glowColorIndex,
        fontWeightBias:   p.getInt(_kWeight)      ?? 0,
        fontLetterSpacing: p.getInt(_kSpacing)    ?? 0,
        font:             font,
        fontSize:         fontSize,
        inventoryFontSize: inventoryFontSize,
        inventoryDisplayMode: inventoryDisplayMode,
        customDiceType:   customDiceType,
        particleSizeScale: p.getDouble(_kParticleSizeScale) ?? 1.0,
        particleOpacity:   p.getDouble(_kParticleOpacity) ?? 0.55,
        particleCount:     p.getInt(_kParticleCount) ?? 32,
        dialogueHapticsEnabled: p.getBool(_kDialogueHaptics) ?? true,
        dialogueTextSpeedMs: p.getInt(_kDialogueTextSpeed) ?? 30,
        isGoopianLanguage: isGoopian,
        spongeActive: spongeActive,
        showEffectsPanel: showEffectsPanel,
        showShrinePanel: showShrinePanel,
        showDashboards: showDashboards,
        periodicGridColumnCount: periodicGridColumnCount,
        particleColorSchema: particleColorSchema,
        particleSpeed: particleSpeed,
        particleTypeIndex: (p.getInt(_kParticleTypeIdx) ?? 0).clamp(0, ParticleType.values.length - 1),
        particleSchemaIndex: (p.getInt(_kParticleSchemaIdx) ?? 0).clamp(0, 2),
        particleChaos: p.getBool(_kParticleChaos) ?? false,
        particleTouch: p.getBool(_kParticleTouch) ?? true,
        shaderEnabled: shaderEnabled,
        shaderPreset: shaderPreset,
      );
    } catch (e) { debugPrint('[AppTheme] prefs error: $e'); }
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
  }

  static void setFontLetterSpacing(int v) {
    notifier.value = notifier.value._with(fontLetterSpacing: v.clamp(-2, 2));
    _persist();
  }

  static Future<void> setFont(AppFont f) async {
    notifier.value = notifier.value._with(font: f);
    _persist();
  }

  static Future<void> setFontSize(double v) async {
    final clamped = v.clamp(6.0, 20.0);
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
    notifier.value = notifier.value._with(glowColorIndex: v.clamp(0, glowColors.length - 1));
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
    notifier.value = notifier.value._with(particleCount: v.clamp(1, 200));
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

  static Future<void> setParticleColorSchema(ParticleColorSchema v) async {
    notifier.value = notifier.value._with(particleColorSchema: v);
    _persist();
  }

  static Future<void> setParticleTypeIndex(int v) async {
    notifier.value = notifier.value._with(
        particleTypeIndex: v.clamp(0, ParticleType.values.length - 1));
    _persist();
  }

  static Future<void> setParticleSchemaIndex(int v) async {
    notifier.value = notifier.value._with(particleSchemaIndex: v.clamp(0, 2));
    _persist();
  }

  static Future<void> setParticleChaos(bool v) async {
    notifier.value = notifier.value._with(particleChaos: v);
    _persist();
  }

  static Future<void> setParticleTouch(bool v) async {
    notifier.value = notifier.value._with(particleTouch: v);
    _persist();
  }

  static Future<void> setParticleSpeed(ParticleSpeed v) async {
    notifier.value = notifier.value._with(particleSpeed: v);
    _persist();
  }

  static Future<void> setShaderEnabled(bool v) async {
    notifier.value = notifier.value._with(shaderEnabled: v);
    _persist();
  }

  /// Apply a full set of curated visual settings at once (used when
  /// selecting a premade theme).
  static Future<void> applyCuration(ThemeCuration c) async {
    notifier.value = notifier.value._with(
      particlePreset: c.particlePreset,
      particleColorSchema: c.colorSchema,
      particleGlowEffect: c.glowEffect,
      particleSpeed: c.speed,
      particleCount: c.particleCount,
      particleSizeScale: c.particleSizeScale,
      particleOpacity: c.particleOpacity,
      particleLineLinks: c.particleLineLinks,
      particleBounce: c.particleBounce,
      glowColorIndex: c.glowColorIndex,
      glowIntensity: c.glowIntensity,
      shaderEnabled: c.shaderEnabled,
      shaderPreset: c.shaderPreset ?? notifier.value.shaderPreset,
      particlesEnabled: true,
    );
    _persist();
  }

  static Future<void> setShaderPreset(ShaderPreset v) async {
    notifier.value = notifier.value._with(shaderPreset: v);
    _persist();
  }

  /// Replace the entire VisualPrefs state and persist to disk.
  /// Used when restoring a saved custom theme's preferences.
  static Future<void> replaceAndPersist(VisualPrefs prefs) async {
    notifier.value = prefs;
    await _persist();
  }


  static Future<void> _persist() async {
    try {
      final p = await SharedPreferences.getInstance();
      final v = notifier.value;
      await p.setDouble(_kGlow,     v.glowIntensity);
      await p.setBool(_kParticles,  v.particlesEnabled);
      await p.setInt(_kWeight,      v.fontWeightBias);
      await p.setInt(_kSpacing,     v.fontLetterSpacing);
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
      await p.setBool(_kShowEffectsPanel, v.showEffectsPanel);
      await p.setBool(_kShowShrinePanel, v.showShrinePanel);
      await p.setBool(_kShowDashboards, v.showDashboards);
      await p.setInt(_kPeriodicGridColumnCount, v.periodicGridColumnCount);
      await p.setInt(_kParticleColorSchema, v.particleColorSchema.index);
      await p.setInt(_kParticleSpeed, v.particleSpeed.index);
      await p.setInt(_kParticleTypeIdx, v.particleTypeIndex);
      await p.setInt(_kParticleSchemaIdx, v.particleSchemaIndex);
      await p.setBool(_kParticleChaos, v.particleChaos);
      await p.setBool(_kParticleTouch, v.particleTouch);
      await p.setBool(_kShaderEnabled, v.shaderEnabled);
      await p.setInt(_kShaderPreset, v.shaderPreset.index);
    } catch (e) { debugPrint('[AppTheme] prefs error: $e'); }
  }

  VisualPrefs _with({
    double? glowIntensity,
    bool?   particlesEnabled,
    int?    fontWeightBias,
    int?    fontLetterSpacing,
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
    bool?   showEffectsPanel,
    bool?   showShrinePanel,
    bool?   showDashboards,
    int?    periodicGridColumnCount,
    ParticleColorSchema? particleColorSchema,
    ParticleSpeed? particleSpeed,
    int? particleTypeIndex,
    int? particleSchemaIndex,
    bool? particleChaos,
    bool? particleTouch,
    bool? shaderEnabled,
    ShaderPreset? shaderPreset,
  }) => VisualPrefs(
    glowIntensity:    glowIntensity    ?? this.glowIntensity,
    particlesEnabled: particlesEnabled ?? this.particlesEnabled,
    fontWeightBias:   fontWeightBias   ?? this.fontWeightBias,
    fontLetterSpacing: fontLetterSpacing ?? this.fontLetterSpacing,
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
    showEffectsPanel: showEffectsPanel ?? this.showEffectsPanel,
    showShrinePanel: showShrinePanel ?? this.showShrinePanel,
    showDashboards: showDashboards ?? this.showDashboards,
    periodicGridColumnCount: periodicGridColumnCount ?? this.periodicGridColumnCount,
    particleColorSchema: particleColorSchema ?? this.particleColorSchema,
    particleSpeed: particleSpeed ?? this.particleSpeed,
    particleTypeIndex: particleTypeIndex ?? this.particleTypeIndex,
    particleSchemaIndex: particleSchemaIndex ?? this.particleSchemaIndex,
    particleChaos: particleChaos ?? this.particleChaos,
    particleTouch: particleTouch ?? this.particleTouch,
    shaderEnabled: shaderEnabled ?? this.shaderEnabled,
    shaderPreset: shaderPreset ?? this.shaderPreset,
  );

  /// Serialize to JSON for custom theme persistence.
  Map<String, dynamic> toJson() => {
    'glowIntensity': glowIntensity,
    'particlesEnabled': particlesEnabled,
    'fontWeightBias': fontWeightBias,
    'font': font.index,
    'fontSize': fontSize,
    'inventoryFontSize': inventoryFontSize,
    'inventoryDisplayMode': inventoryDisplayMode.index,
    'particlePreset': particlePreset.index,
    'particleGlowEffect': particleGlowEffect.index,
    'particleLineLinks': particleLineLinks,
    'particleBounce': particleBounce,
    'glowColorIndex': glowColorIndex,
    'customDiceType': customDiceType.index,
    'particleSizeScale': particleSizeScale,
    'particleOpacity': particleOpacity,
    'particleCount': particleCount,
    'dialogueHapticsEnabled': dialogueHapticsEnabled,
    'dialogueTextSpeedMs': dialogueTextSpeedMs,
    'isGoopianLanguage': isGoopianLanguage,
    'spongeActive': spongeActive,
    'showEffectsPanel': showEffectsPanel,
    'showShrinePanel': showShrinePanel,
    'showDashboards': showDashboards,
    'periodicGridColumnCount': periodicGridColumnCount,
    'particleColorSchema': particleColorSchema.index,
    'particleSpeed': particleSpeed.index,
    'shaderEnabled': shaderEnabled,
    'shaderPreset': shaderPreset.index,
  };

  /// Deserialize from JSON for custom theme restoration.
  factory VisualPrefs.fromJson(Map<String, dynamic> j) {
    return VisualPrefs(
      glowIntensity: (j['glowIntensity'] as num?)?.toDouble() ?? 0.0,
      particlesEnabled: j['particlesEnabled'] as bool? ?? false,
      fontWeightBias: j['fontWeightBias'] as int? ?? 0,
      font: AppFont.values[(j['font'] as int?) ?? 0],
      fontSize: (j['fontSize'] as num?)?.toDouble() ?? 12.0,
      inventoryFontSize: (j['inventoryFontSize'] as num?)?.toDouble() ?? 11.0,
      inventoryDisplayMode: InventoryDisplayMode.values[(j['inventoryDisplayMode'] as int?) ?? 0],
      particlePreset: ParticlePreset.values[(j['particlePreset'] as int?) ?? 0],
      particleGlowEffect: GlowEffect.values[(j['particleGlowEffect'] as int?) ?? 0],
      particleLineLinks: j['particleLineLinks'] as bool? ?? false,
      particleBounce: j['particleBounce'] as bool? ?? false,
      glowColorIndex: j['glowColorIndex'] as int? ?? 0,
      customDiceType: CustomDiceType.values[(j['customDiceType'] as int?) ?? 0],
      particleSizeScale: (j['particleSizeScale'] as num?)?.toDouble() ?? 1.0,
      particleOpacity: (j['particleOpacity'] as num?)?.toDouble() ?? 0.8,
      particleCount: j['particleCount'] as int? ?? 16,
      dialogueHapticsEnabled: j['dialogueHapticsEnabled'] as bool? ?? true,
      dialogueTextSpeedMs: j['dialogueTextSpeedMs'] as int? ?? 30,
      isGoopianLanguage: j['isGoopianLanguage'] as bool? ?? false,
      spongeActive: j['spongeActive'] as bool? ?? false,
      showEffectsPanel: j['showEffectsPanel'] as bool? ?? true,
      showShrinePanel: j['showShrinePanel'] as bool? ?? true,
      showDashboards: j['showDashboards'] as bool? ?? true,
      periodicGridColumnCount: j['periodicGridColumnCount'] as int? ?? 0,
      particleColorSchema: ParticleColorSchema.values[(j['particleColorSchema'] as int?) ?? 0],
      particleSpeed: ParticleSpeed.values[(j['particleSpeed'] as int?) ?? 2],
      shaderEnabled: j['shaderEnabled'] as bool? ?? false,
      shaderPreset: ShaderPreset.values[(j['shaderPreset'] as int?) ?? 0],
    );
  }
}

/// A saved custom theme — captures the full visual state (base theme
/// palette + all VisualPrefs) so it can be restored and displayed in
/// the theme picker alongside the premades.
class SavedCustomTheme {
  final String id;       // unique timestamp-based ID
  final String name;     // user-given name
  final String splashSlug; // graphic asset key from a premade
  final AppThemeMode baseMode; // the premade theme this was built from
  final VisualPrefs prefs;     // the visual settings at save time
  final CustomThemeData? customData; // custom palette (only when baseMode == custom)
  final String icon;           // Material icon codePoint as string (e.g. "0xe3af")

  const SavedCustomTheme({
    required this.id,
    required this.name,
    required this.splashSlug,
    required this.baseMode,
    required this.prefs,
    this.customData,
    this.icon = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'splashSlug': splashSlug,
    'baseMode': baseMode.index,
    'prefs': prefs.toJson(),
    if (customData != null) 'customData': customData!.toJson(),
    if (icon.isNotEmpty) 'icon': icon,
  };

  factory SavedCustomTheme.fromJson(Map<String, dynamic> j) {
    return SavedCustomTheme(
      id: j['id'] as String,
      name: j['name'] as String,
      splashSlug: j['splashSlug'] as String,
      baseMode: AppThemeMode.values[j['baseMode'] as int],
      prefs: VisualPrefs.fromJson(j['prefs'] as Map<String, dynamic>),
      customData: j['customData'] != null
          ? CustomThemeData.fromJson(j['customData'] as Map<String, dynamic>)
          : null,
      icon: j['icon'] as String? ?? '',
    );
  }
}

/// Persisted store of user-saved custom themes. Stored as a JSON list
/// in SharedPreferences. Unlimited count.
class CustomThemeStore {
  static const _key = 'custom.themes.v1';
  static final ValueNotifier<List<SavedCustomTheme>> notifier =
      ValueNotifier<List<SavedCustomTheme>>([]);

  static List<SavedCustomTheme> get themes => notifier.value;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_key);
      if (json != null) {
        final list = jsonDecode(json) as List;
        notifier.value = list
            .map((j) => SavedCustomTheme.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
  }

  static Future<void> save(SavedCustomTheme theme) async {
    final updated = [...notifier.value, theme];
    notifier.value = updated;
    await _persist(updated);
  }

  static Future<void> delete(String id) async {
    final updated = notifier.value.where((t) => t.id != id).toList();
    notifier.value = updated;
    await _persist(updated);
  }

  static Future<void> _persist(List<SavedCustomTheme> themes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(themes.map((t) => t.toJson()).toList());
      await prefs.setString(_key, json);
    } catch (_) {}
  }
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
      RefreshableValueNotifier<AppThemeMode>(AppThemeMode.minimalist);

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
    } catch (e) { debugPrint('[AppTheme] prefs error: $e'); }
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
    } catch (e) { debugPrint('[AppTheme] prefs error: $e'); }
  }

  /// Cached custom theme name for synchronous label access.
  static String _customThemeName = 'Custom';

  /// Cached custom theme data for synchronous flair access.
  static CustomThemeData? _cachedCustomTheme;

  /// Public read-only access to the cached custom theme data.
  static CustomThemeData? get cachedCustomTheme => _cachedCustomTheme;

  /// Update the cached custom theme name (call when saving custom theme).
  static void setCustomThemeName(String name) {
    _customThemeName = name;
  }

  /// Update the cached custom theme data (call when saving custom theme).
  static void setCustomThemeData(CustomThemeData data) {
    _cachedCustomTheme = data;
    _customThemeName = data.name;
  }

  /// Persist custom theme palette to disk + update cache + refresh listeners.
  static Future<void> saveCustomThemeData(CustomThemeData data) async {
    _cachedCustomTheme = data;
    _customThemeName = data.name;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(CustomThemeData._prefsKey, jsonEncode(data.toJson()));
    } catch (_) {}
    refresh();
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

      // Load custom theme palette data (if previously saved).
      final customJson = prefs.getString(CustomThemeData._prefsKey);
      if (customJson != null) {
        try {
          final j = jsonDecode(customJson) as Map<String, dynamic>;
          _cachedCustomTheme = CustomThemeData.fromJson(j);
          _customThemeName = _cachedCustomTheme!.name;
        } catch (_) {}
      }

      final idx = prefs.getInt(_prefsKey);
      if (idx != null && idx >= 0 && idx < AppThemeMode.values.length) {
        var m = AppThemeMode.values[idx];
        // v3.0 theme cut — anything outside the three supported picker
        // themes (or the plain Minimalist default) migrates to Moonlit
        // Chamber. Covers the removed picker themes and custom themes.
        if (m != AppThemeMode.minimalist && !kPickerThemes.contains(m)) {
          m = AppThemeMode.moonlitChamber;
          await prefs.setInt(_prefsKey, m.index);
        }
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
    // Debug-only: audit contrast ratios for all visible themes so
    // accessibility regressions surface during development.
    if (kDebugMode) {
      _auditAllThemeContrast();
    }
  }

  /// Debug-only: print WCAG contrast warnings for every visible theme.
  /// Runs once at startup. Themes that fail the large-text threshold
  /// (3:1) are flagged as FAIL; those that pass large but fail body
  /// (4.5:1) are flagged as WARN.
  static void _auditAllThemeContrast() {
    for (final mode in kVisibleThemes) {
      if (mode == AppThemeMode.custom) continue;
      final f = mode.flair;
      final results = auditThemeContrast(
        scaffold: f.scaffold,
        card: f.card,
        primary: f.primary,
        secondary: f.secondary,
        headlineStat: f.headlineStat,
        themeLabel: mode.label,
      );
      final failures = results.where((r) => r.fails).toList();
      final warnings =
          results.where((r) => !r.fails && !r.passesBody).toList();
      if (failures.isNotEmpty || warnings.isNotEmpty) {
        debugPrint('┌─ Contrast: ${mode.label}');
        for (final r in failures) {
          debugPrint('│ FAIL $r');
        }
        for (final r in warnings) {
          debugPrint('│ WARN $r');
        }
        debugPrint('└─');
      }
    }
  }

  /// Persist + apply the picked theme.
  /// For premade themes, curated particle/typo/ambiance settings are
  /// applied to give the theme a complete identity. For custom themes,
  /// only the font is applied (user keeps their visual prefs).
  static Future<void> setMode(AppThemeMode m) async {
    notifier.value = m;
    // Apply the theme's curated font as the new default.
    final themeFont = m.flair.font;
    if (themeFont != null) {
      await VisualPrefs.setFont(themeFont);
    }
    // Apply curated visual settings for premade themes.
    final curation = kThemeCuration[m];
    if (curation != null) {
      await VisualPrefs.applyCuration(curation);
    }
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

    // Build a deliberate type scale with tuned sizes, heights, and
    // letter-spacings — never the raw Material/Google Fonts defaults.
    // The font family is applied via ThemeData.fontFamily below, so the
    // type scale values are preserved when the font changes.
    //
    // onSurface is derived from the surface luminance so that text
    // stays readable on any flair — dark surfaces get off-white text,
    // light surfaces get near-black text. This prevents the white-text-
    // on-light-fill contrast bug (U-002).
    final surfaceLum = Contrast.luminance(f.card);
    final onSurface = surfaceLum > 0.5
        ? const Color(0xFF1E1E22) // dark text on light surface
        : const Color(0xFFF0F0F0); // off-white text on dark surface
    final onSurfaceVariant = onSurface.withValues(alpha: 0.7);
    final scheme = ColorScheme.dark(
      primary: f.primary,
      secondary: f.secondary,
      surface: f.card,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
    );
    var textTheme = buildAppTextTheme(scheme);
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

    // CRITICAL: Apply the font family to the textTheme itself, not just
    // ThemeData.fontFamily. ThemeData.fontFamily is a fallback that only
    // applies to Text widgets with no TextStyle at all. Text widgets that
    // use Theme.of(context).textTheme.* or inherit via DefaultTextStyle
    // get the style from textTheme — if those styles have fontFamily: null,
    // Flutter uses the platform default (Roboto), NOT ThemeData.fontFamily.
    // Applying here ensures every text style carries the picked font.
    if (fontFamilyName != null) {
      textTheme = textTheme.apply(fontFamily: fontFamilyName);
    }

    return ThemeData(
      colorScheme: scheme,
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
        titleTextStyle: (textTheme.titleMedium ?? const TextStyle()).copyWith(
          fontWeight: FontWeight.w900,
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
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 24),
          ),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          )),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.white.withValues(alpha: 0.12);
            }
            if (states.contains(WidgetState.pressed)) {
              return f.primary.withValues(alpha: 0.88);
            }
            return f.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return onSurface.withValues(alpha: 0.38);
            }
            // Contrast-correct foreground for the primary fill: dark
            // text on light primaries, light text on dark primaries.
            return Contrast.luminance(f.primary) > 0.5
                ? const Color(0xFF1E1E22)
                : const Color(0xFFF0F0F0);
          }),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          )),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: f.dividerColor,
        thickness: f.dividerThickness,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
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



// =============================================================================
// Typed particle color schemas — 3 flavored palettes per picker theme.
// Each theme gets names that feel like its own fantasy.
// =============================================================================

/// (name, colors) per theme — index 0 is the theme's signature look.
const Map<AppThemeMode, List<({String name, List<Color> colors})>>
    kThemeParticleSchemas = {
  AppThemeMode.unicorn: [
    (name: 'RAINBOW', colors: [Color(0xFFFF5252), Color(0xFFFFB300), Color(0xFF69F0AE), Color(0xFF40C4FF), Color(0xFFB388FF)]),
    (name: 'PASTEL', colors: [Color(0xFFF8BBD0), Color(0xFFB3E5FC), Color(0xFFD1C4E9), Color(0xFFC8E6C9)]),
    (name: 'GOLD', colors: [Color(0xFFFFD700), Color(0xFFFFB300), Color(0xFFFFF8DC)]),
  ],
  AppThemeMode.forgeMaster: [
    (name: 'EMBER', colors: [Color(0xFFFF5722), Color(0xFFFF8A65), Color(0xFFD84315)]),
    (name: 'AMBER', colors: [Color(0xFFFFB300), Color(0xFFFFD54F), Color(0xFFFF6F00)]),
    (name: 'STEEL', colors: [Color(0xFFB0BEC5), Color(0xFF78909C), Color(0xFFECEFF1)]),
  ],
  AppThemeMode.candyRush: [
    (name: 'BUBBLEGUM', colors: [Color(0xFFF8BBD0), Color(0xFFF48FB1), Color(0xFFFCE4EC)]),
    (name: 'COTTON', colors: [Color(0xFFB3E5FC), Color(0xFFE1BEE7), Color(0xFFF8BBD0)]),
    (name: 'SUGAR', colors: [Color(0xFFFFF0F5), Color(0xFFF8BBD0), Color(0xFFEC407A)]),
  ],
  AppThemeMode.neonPrism: [
    (name: 'PRISM', colors: [Color(0xFFE040FB), Color(0xFF00E5FF), Color(0xFFFFD740)]),
    (name: 'VOLT', colors: [Color(0xFF00E5FF), Color(0xFF76FF03), Color(0xFFE040FB)]),
    (name: 'RAIN', colors: [Color(0xFF7C4DFF), Color(0xFF18FFFF), Color(0xFFFF4081)]),
  ],
  AppThemeMode.blacksmithsFire: [
    (name: 'RUST', colors: [Color(0xFFD84315), Color(0xFF8D6E63), Color(0xFFFF8A65)]),
    (name: 'COAL', colors: [Color(0xFF3E2723), Color(0xFFD84315), Color(0xFFFFB74D)]),
    (name: 'FORGE', colors: [Color(0xFFFF8A65), Color(0xFFD84315), Color(0xFFFFCC80)]),
  ],
  AppThemeMode.moltenSteel: [
    (name: 'MOLTEN', colors: [Color(0xFFFF6E40), Color(0xFFFF8A65), Color(0xFFDD2C00)]),
    (name: 'STEEL', colors: [Color(0xFFB0BEC5), Color(0xFF78909C), Color(0xFFECEFF1)]),
    (name: 'IRON', colors: [Color(0xFF546E7A), Color(0xFF90A4AE), Color(0xFFFF6E40)]),
  ],
  AppThemeMode.paperInk: [
    (name: 'INK', colors: [Color(0xFF90A4AE), Color(0xFF546E7A), Color(0xFF263238)]),
    (name: 'PAPER', colors: [Color(0xFFECEFF1), Color(0xFFCFD8DC), Color(0xFFB0BEC5)]),
    (name: 'SKETCH', colors: [Color(0xFF78909C), Color(0xFFB0BEC5), Color(0xFF90A4AE)]),
  ],
  AppThemeMode.voidWhite: [
    (name: 'VOID', colors: [Color(0xFFFFFFFF), Color(0xFF9E9E9E), Color(0xFF424242)]),
    (name: 'STARK', colors: [Color(0xFFFAFAFA), Color(0xFF616161), Color(0xFFBDBDBD)]),
    (name: 'INVERT', colors: [Color(0xFF212121), Color(0xFF616161), Color(0xFF9E9E9E)]),
  ],
  AppThemeMode.moonlitChamber: [
    (name: 'MONO', colors: [Color(0xFFECEFF1), Color(0xFFB0BEC5), Color(0xFF90A4AE)]),
    (name: 'WHITE', colors: [Color(0xFFFFFFFF), Color(0xFFFAFAFA), Color(0xFFE0E0E0)]),
    (name: 'ONYX', colors: [Color(0xFF616161), Color(0xFF424242), Color(0xFF9E9E9E)]),
  ],
};

/// Schema colors for the current mode + pref index (clamped).
List<Color> particleSchemaColors(AppThemeMode mode, int schemaIdx) {
  final list = kThemeParticleSchemas[mode] ??
      kThemeParticleSchemas[AppThemeMode.moonlitChamber]!;
  return list[schemaIdx.clamp(0, list.length - 1)].colors;
}
