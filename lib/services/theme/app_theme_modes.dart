part of '../app_theme.dart';

// Split from theme_enums.dart — same library, no import changes.

enum AppThemeMode {
  unicorn(
    label: 'Unicorn',
    vibe: 'MAGICAL',
    diff: 'CO-OP',
    elem: 'RAINBOW',
    whimsicalDescription:
        'A cotton candy megapack with six switchable palettes: Cotton Candy, Neon, Dreamy, Sunset, Bubblegum, and Mulberry. Cycle through pastel pink, electric magenta, whispered rose, golden-hour coral, bright bubblegum pop, and deep crimson-purple — all from one theme.',
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
    whimsicalDescription:
        'A neon-charged cotton candy overload. Hot pink and electric magenta scream through the dark with an intense radioactive glow. For Gungeoneers who want their pastel with extra voltage.',
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
    whimsicalDescription:
        'A softer, whispered cotton candy. Muted rose and dusty lavender drift like a watercolour sunset. For the Gungeoneer who wants the vibe turned down to a gentle hum.',
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
    whimsicalDescription:
        'Cotton candy at golden hour. Coral pink and warm peach blend with powder-pink undertones for a sunset-drenched magical vibe. The most romantic way to enter the Gungeon.',
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
    whimsicalDescription:
        'Flip through the pages of the ultimate Gungeon compendium. Styled with heavy book-leather browns and crisp gold-embossed trim for the meticulous researcher.',
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
    whimsicalDescription:
        'Forged in the depths of the Fifth Chamber. Obsidian plates illuminated by roaring blast furnaces and the glowing scales of the High Dragun.',
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
    whimsicalDescription:
        'Feel the creeping frost of the Fourth Chamber. Chilled directly by spectral remnants, haunted tombstones, and freezing ice-cube ammunition.',
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
    whimsicalDescription:
        'An irreversible pact sealed in maximum curse. Dark, corrupted purple UI accented by lethal oxblood lines. If you hear stalking footsteps, don\'t look back.',
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
    whimsicalDescription:
        'Relax alongside Cadence, Ox, and the cult of gungeoneers. Brings a warm, comforting hearthstone glow to your loadout tracking before you drop back down.',
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
    whimsicalDescription:
        'Descend into the absolute depths of the Gungeon floor layout. Lethal acid greens cut cleanly through a charred landscape of absolute bullet chaos.',
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
    whimsicalDescription:
        'Channel the ultimate mastermind of the ventilation shafts. A clever, high-contrast layout built from dirty sewer elements and brilliant, shiny stolen items.',
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
    whimsicalDescription:
        'The textbook definition of entering the breach. Clean castle stone blues paired with royal purple accents that recall the long, winding entry halls of the true first floor.',
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
    whimsicalDescription:
        'Descend into the hidden, damp pipeline layer. A layout covered in industrial sewer muck, rusted pipework bronze, and bright toxic spills that pop sharply against the dark.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0A0F08),
      card: Color(0xFF141A10),
      primary: Color(
        0xFF64DD17,
      ), // sickly sewer green (distinct from Bullet Hell's neon green)
      secondary: Color(0xFF795548),
      headlineStat: Color(
        0xFFB2FF59,
      ), // pale toxic lime (distinct from Bullet Hell's acid yellow)
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
    whimsicalDescription:
        'Kill your past or fracture the space-time continuum trying. Features deep stellar space backdrops cracked wide open by unstable, flashing neon cosmic energy.',
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
    whimsicalDescription:
        'Immerse your loadout tracker in the ominous shadows of the true gun cultists. Dark ritual violet panels broken apart by flickering candle yellow and unstable boss accents.',
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
    whimsicalDescription:
        'Ditch organic hearts entirely for pure cold steel. A ultra-clean, calculated cybernetic UI system featuring high-voltage electrical blues and neon green terminal readout indicators.',
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
    whimsicalDescription:
        'Pay homage to the standard, loyal foot soldiers of the gungeoneers\' demise. Formatted with soft ammunition brass tones and target practice reds on lead gray backdrops.',
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
    whimsicalDescription:
        'When your inventory items fuse together perfectly. An ultra-bright, dynamic color palette based on the iconic blue arrows that appear above your gungeoneer during a item pairing.',
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
    whimsicalDescription:
        'Something went terribly wrong with the chest generation parameters. A distinct glitch aesthetic combining harsh digital greens and magenta color visual artifacts over a pitch-black terminal frame.',
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
    whimsicalDescription:
        'Stand face to face with the master of the gungeon floor layout. Features skeletal bone white indicators slicing through eerie, lingering phantom teal lines and deep crypt shadows.',
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
    whimsicalDescription:
        "Step right up and test your bouncing shot trajectories. A warm, rustic carnival aesthetic balancing dark wood backgrounds with vibrant ticket orange and practice target green.",
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
    whimsicalDescription:
        'JUNK IS THE OPTIMAL SOURCE OF FUEL. A cold steel cybernetic interface with circuit-green accents and battery-blue highlights. The Robot\'s domain — efficient, calculating, and relentlessly logical.',
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
    whimsicalDescription:
        'Stay frosty. A disciplined military aesthetic with olive drab, tactical amber, and steel gray. The Marine\'s domain — precise, reliable, and always by the book.',
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
    whimsicalDescription:
        'For the glory of the Bullet-King! A brave bullet-kin aesthetic with polished brass gold, heroic red, and steel gray. The Bullet that dared to wield a blade — noble, bright, and defiant.',
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
    whimsicalDescription:
        'Who... what... when... am I? A fractured reality aesthetic with swirling paradox purple, time-rift violet, and stardust white. Existence is a loop inside a cylinder — broken, beautiful, and unknowable.',
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
    whimsicalDescription:
        'Lock and load. A smoky gunpowder aesthetic with charcoal black, sulfurous gray, and ember red. The smell of spent casings and black powder — raw, industrial, and ready to detonate.',
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
    whimsicalDescription:
        'Face the High Dragun. A molten inferno aesthetic with dragun orange, scale amber, and ash black. The Fifth Chamber burns — scales glint, fire roars, and only the worthy survive.',
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
    whimsicalDescription:
        'The master of the gungeon awaits. A necrotic domain with bone white, crypt teal, and void black. The Lich\'s chamber — cold, eternal, and absolute in its finality.',
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
    whimsicalDescription:
        'A warm hearth-lit den where a content gungeoneer and their nine lives nap between chambers. Amber paw prints padding across deep walnut, with soft copper accents and a gentle purr of warmth.',
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
    whimsicalDescription:
        'Stripped to the essentials. Soft whites on deep charcoal, quiet borders, no glow, no spectacle — the distilled GungeonMate for purists who want the data and nothing else.',
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
    whimsicalDescription:
        'Unicorn sibling - bubblegum pink melts into cotton-candy pastels.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF241620),
      card: Color(0xFF33202E),
      primary: Color(0xFFF8BBD0),
      secondary: Color(0xFFB3E5FC),
      headlineStat: Color(0xFFF48FB1),
      bulletColor: Color(0xFFF8BBD0),
      bulletGlyph: '\u2665',
      twinkleBullets: true,
      sparkleNumbers: true,
      numberGlowColor: Color(0xFFF8BBD0),
      tabularFigures: false,
      numberSizeScale: 1.03,
      numberWeight: FontWeight.w700,
      numberStyle: FontStyle.italic,
      chipRadius: 18,
      cardRadius: 18,
      dividerColor: Color(0x55F8BBD0),
      dividerThickness: 1.0,
      glowPrimary: Color(0x55F8BBD0),
      glowSecondary: Color(0x3BB3E5FC),
      auraStyle: AvatarAuraStyle.pastelPulse,
      headerGlyph: '\u2665',
      headerUnderlineColor: Color(0x88F8BBD0),
      statGroupCombat: Color(0xFFF8BBD0),
      statGroupHandling: Color(0xFFB3E5FC),
      statGroupMeta: Color(0xFFF48FB1),
      font: AppFont.fredoka,
    ),
  ),
  neonPrism(
    label: 'Neon Prism',
    vibe: 'ELECTRIC',
    diff: 'CO-OP',
    elem: 'SPECTRUM',
    whimsicalDescription:
        'Unicorn after dark - deep night lit by saturated prism accents.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0D0A14),
      card: Color(0xFF1A1226),
      primary: Color(0xFFE040FB),
      secondary: Color(0xFF00E5FF),
      headlineStat: Color(0xFFFFD740),
      bulletColor: Color(0xFFE040FB),
      bulletGlyph: '\u2726',
      twinkleBullets: true,
      sparkleNumbers: true,
      numberGlowColor: Color(0xFFE040FB),
      tabularFigures: true,
      numberSizeScale: 1.05,
      numberWeight: FontWeight.w800,
      chipRadius: 14,
      cardRadius: 16,
      cardBorderColor: Color(0x44E040FB),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x55E040FB),
      dividerThickness: 1.0,
      glowPrimary: Color(0x55E040FB),
      glowSecondary: Color(0x4000E5FF),
      auraStyle: AvatarAuraStyle.pastelPulse,
      headerGlyph: '\u2726',
      headerUnderlineColor: Color(0xAAE040FB),
      statGroupCombat: Color(0xFFE040FB),
      statGroupHandling: Color(0xFF00E5FF),
      statGroupMeta: Color(0xFFFFD740),
      font: AppFont.fredoka,
    ),
  ),
  blacksmithsFire(
    label: "Blacksmiths Fire",
    vibe: 'RUSTED',
    diff: 'EXPERT',
    elem: 'EMBER',
    whimsicalDescription:
        'Forge Master rougher kin - rust and deep ember over scorched iron.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF120B08),
      card: Color(0xFF1E130E),
      primary: Color(0xFFD84315),
      secondary: Color(0xFFFF8A65),
      headlineStat: Color(0xFFFFB74D),
      bulletColor: Color(0xFFD84315),
      bulletGlyph: '\u2622',
      twinkleBullets: true,
      tabularFigures: true,
      numberSizeScale: 1.0,
      numberWeight: FontWeight.w800,
      chipRadius: 4,
      cardRadius: 6,
      cardBorderColor: Color(0x33D84315),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x44D84315),
      dividerThickness: 1.0,
      glowPrimary: Color(0x4DD84315),
      glowSecondary: Color(0x2EFF8A65),
      auraStyle: AvatarAuraStyle.forgeGlow,
      headerGlyph: '\u2622',
      headerUnderlineColor: Color(0x88D84315),
      statGroupCombat: Color(0xFFD84315),
      statGroupHandling: Color(0xFFFF8A65),
      statGroupMeta: Color(0xFFFFB74D),
      font: AppFont.russoOne,
    ),
  ),
  moltenSteel(
    label: 'Molten Steel',
    vibe: 'FORGED',
    diff: 'EXPERT',
    elem: 'STEEL',
    whimsicalDescription:
        'Forge Master chilled - iron greys with a molten-orange edge bleeding through.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF0E0E12),
      card: Color(0xFF18181E),
      primary: Color(0xFFFF6E40),
      secondary: Color(0xFFB0BEC5),
      headlineStat: Color(0xFFECEFF1),
      bulletColor: Color(0xFFFF6E40),
      bulletGlyph: '\u2692',
      twinkleBullets: false,
      tabularFigures: true,
      numberSizeScale: 1.0,
      numberWeight: FontWeight.w700,
      chipRadius: 5,
      cardRadius: 7,
      cardBorderColor: Color(0x3378909C),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x3378909C),
      dividerThickness: 1.0,
      glowPrimary: Color(0x33FF6E40),
      glowSecondary: Color(0x2278909C),
      auraStyle: AvatarAuraStyle.forgeGlow,
      headerGlyph: '\u2692',
      headerUnderlineColor: Color(0x66FF6E40),
      statGroupCombat: Color(0xFFFF6E40),
      statGroupHandling: Color(0xFFB0BEC5),
      statGroupMeta: Color(0xFF90A4AE),
      font: AppFont.russoOne,
    ),
  ),
  paperInk(
    label: 'Paper & Ink',
    vibe: 'QUIET',
    diff: 'NORMAL',
    elem: 'INK',
    whimsicalDescription:
        'Minimalist day shift - soft paper greys under crisp ink.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF16161A),
      card: Color(0xFF222228),
      primary: Color(0xFF90A4AE),
      secondary: Color(0xFFB0BEC5),
      headlineStat: Color(0xFFECEFF1),
      bulletColor: Color(0xFF90A4AE),
      bulletGlyph: '\u25AA',
      sparkleNumbers: false,
      numberGlowColor: Color(0x00000000),
      tabularFigures: true,
      numberSizeScale: 1.0,
      numberWeight: FontWeight.w600,
      chipRadius: 4,
      cardRadius: 6,
      cardBorderColor: Color(0x3390A4AE),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x3390A4AE),
      dividerThickness: 1.0,
      glowPrimary: Color(0x00000000),
      glowSecondary: Color(0x00000000),
      auraStyle: AvatarAuraStyle.moonGlow,
      headerGlyph: '\u25AA',
      headerUnderlineColor: Color(0x5590A4AE),
      statGroupCombat: Color(0xFF90A4AE),
      statGroupHandling: Color(0xFFB0BEC5),
      statGroupMeta: Color(0xFF78909C),
      font: AppFont.gungeon,
    ),
  ),
  voidWhite(
    label: 'Void White',
    vibe: 'STARK',
    diff: 'BRUTAL',
    elem: 'VOID',
    whimsicalDescription:
        'Minimalist edge - pure white on near-black, no chrome, no noise.',
    staticFlair: ThemeFlair(
      scaffold: Color(0xFF08080C),
      card: Color(0xFF101014),
      primary: Color(0xFFFFFFFF),
      secondary: Color(0xFF9E9E9E),
      headlineStat: Color(0xFFFFFFFF),
      bulletColor: Color(0xFFFFFFFF),
      bulletGlyph: '\u25AA',
      sparkleNumbers: false,
      numberGlowColor: Color(0x00000000),
      tabularFigures: true,
      numberSizeScale: 1.0,
      numberWeight: FontWeight.w700,
      chipRadius: 4,
      cardRadius: 6,
      cardBorderColor: Color(0x33FFFFFF),
      cardBorderWidth: 1.0,
      dividerColor: Color(0x22FFFFFF),
      dividerThickness: 1.0,
      glowPrimary: Color(0x00000000),
      glowSecondary: Color(0x00000000),
      auraStyle: AvatarAuraStyle.moonGlow,
      headerGlyph: '\u25AA',
      headerUnderlineColor: Color(0x55FFFFFF),
      statGroupCombat: Color(0xFFFFFFFF),
      statGroupHandling: Color(0xFF9E9E9E),
      statGroupMeta: Color(0xFF757575),
      font: AppFont.gungeon,
    ),
  ),
  stormCaller(
    label: 'Storm Caller',
    vibe: 'ELECTRIC',
    diff: 'EXPERT',
    elem: 'LIGHTNING',
    whimsicalDescription:
        'The gungeon trembles as thunder rolls through its corridors. Crackling electric yellow arcs against storm-grey steel, with voltage blue accents — a high-voltage aesthetic for the gungeoneer who shoots first and asks questions never.',
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
    whimsicalDescription:
        'A hooded figure kneels in candlelight. Deep blue robes, flickering gold, and shadow-purple — for the gungeoneer who speaks in riddles and fights in silence.',
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
    whimsicalDescription:
        'The legend who killed the past with two guns and a grin. Polished gold, worn leather, and gunmetal — for the gungeoneer who walks in like they own the place.',
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
    whimsicalDescription:
        'A rebel with a shotgun and a grudge. Prison orange, rebel red, and dark steel — for the gungeoneer who fights harder when cornered.',
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
    whimsicalDescription:
        'A crossbow, a plan, and patience. Forest green, bark brown, and crossbow silver — for the gungeoneer who hunts from the shadows of the gungeon.',
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
    whimsicalDescription:
        'A rogueish grin and a trusty sidearm. Space silver, trust blue, and starlight — for the gungeoneer who talks their way in and shoots their way out.',
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
    whimsicalDescription:
        'A dealmaker in the dark. Cheese gold, rat brown, and stolen silver — for the gungeoneer who always has a backup plan and a price.',
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
    whimsicalDescription:
        'The gateway shimmers. Portal purple, breach blue, and starlight white — the first step into the gungeon, where every run begins.',
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
    whimsicalDescription:
        'The first chamber, ruled by the Bullet King. Brass, gold, and stone grey — a regal hall where the gungeon begins in earnest.',
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
    whimsicalDescription:
        'A forgotten chamber of sewage and poison. Toxic green, rust orange, and murky brown — for the gungeoneer who ventures where others flush.',
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
    whimsicalDescription:
        'A mine shaft of coal and gunpowder. Spark orange, coal black, and rust brown — for the gungeoneer who digs deep and shoots straight.',
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
    whimsicalDescription:
        'The final floor. Blood red, bullet black, and warning yellow — for the gungeoneer who has killed their past and lives to tell about it.',
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
    whimsicalDescription:
        'The office floor of the Research & Development Department. Neon green, paper white, and office grey — for the gungeoneer who files paperwork between bullets.',
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
    whimsicalDescription:
        'A blank canvas of absolute personal madness. Paint the town in your own choice of radioactive colors. Godspeed, designer!',
    staticFlair: null,
  ),
  minimalist(
    label: 'Minimalist',
    vibe: 'CLEAN',
    diff: 'NORMAL',
    elem: 'METAL',
    whimsicalDescription:
        'A stripped-back metallic interface: pure black, clean white, and cold grey. No glow, no noise — just crisp information.',
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
      primary: Color(
        0xFFFF80AB,
      ), // bubblegum pink (pastel — distinct from Neon's dark hot pink)
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
    cottonCandy => const [
      Color(0xFFFF69B4),
      Color(0xFFE8A7F0),
      Color(0xFFF06292),
      Color(0xFF00E5FF),
    ],
    neon => const [
      Color(0xFFFF1493),
      Color(0xFFDA70D6),
      Color(0xFFE040FB),
      Color(0xFF00E5FF),
    ],
    dreamy => const [
      Color(0xFFF8BBD0),
      Color(0xFFD1C4E9),
      Color(0xFFCE93D8),
      Color(0xFFB39DDB),
    ],
    sunset => const [
      Color(0xFFFF6B9D),
      Color(0xFFFFAB91),
      Color(0xFFFFD1DC),
      Color(0xFFFFCC80),
    ],
    bubblegum => const [
      Color(0xFFFF80AB),
      Color(0xFFE040FB),
      Color(0xFFB388FF),
      Color(0xFFFFD700),
    ],
    mulberry => const [
      Color(0xFFC2185B),
      Color(0xFF9C27B0),
      Color(0xFFF06292),
      Color(0xFFE040FB),
    ],
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
    if (this == AppFont.gungeon) {
      return const TextStyle(fontFamily: 'EnterTheGungeonBig');
    }
    try {
      return GoogleFonts.getFont(label);
    } catch (_) {
      return const TextStyle(fontFamily: 'EnterTheGungeonBig');
    }
  }

  TextTheme get textTheme {
    final base = ThemeData.dark().textTheme;
    if (this == AppFont.gungeon) {
      return base.apply(fontFamily: 'EnterTheGungeonBig');
    }
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
