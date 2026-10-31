part of '../app_theme.dart';

// Extracted from app_theme.dart during the lean-cleanup split.
// Symbols stay in the same library — no import changes needed.

const List<AppThemeMode> kVisibleThemes = <AppThemeMode>[
  // Paper & Ink first — it is the calm/default look; the persisted-mode
  // fallback in app_theme.dart lands on kVisibleThemes.first.
  AppThemeMode.paperInk,
  AppThemeMode.unicorn,
  AppThemeMode.moltenSteel,
  AppThemeMode.custom,
];

/// The curated themes shown in the theme picker — cut to three for
/// v3.0 (the broad picker confused users; each remaining theme's
/// customization is clearer). Users persisted on a removed theme are
/// migrated to Moonlit Chamber at load time.
/// Minimalist stays in [kVisibleThemes] as the plain default look.

const List<AppThemeMode> kPickerThemes = <AppThemeMode>[
  AppThemeMode.unicorn,
  AppThemeMode.moltenSteel,
  AppThemeMode.paperInk,
  AppThemeMode.moonlitChamber,
  AppThemeMode.dragunfire,
  AppThemeMode.lichsDomain,
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

const Map<AppThemeMode, List<({String name, List<Color> colors})>>
kThemeParticleSchemas = {
  AppThemeMode.unicorn: [
    (
      name: 'RAINBOW',
      colors: [
        Color(0xFFFF5252),
        Color(0xFFFFB300),
        Color(0xFF69F0AE),
        Color(0xFF40C4FF),
        Color(0xFFB388FF),
      ],
    ),
    (
      name: 'PASTEL',
      colors: [
        Color(0xFFF8BBD0),
        Color(0xFFB3E5FC),
        Color(0xFFD1C4E9),
        Color(0xFFC8E6C9),
      ],
    ),
    (
      name: 'GOLD',
      colors: [Color(0xFFFFD700), Color(0xFFFFB300), Color(0xFFFFF8DC)],
    ),
  ],
  AppThemeMode.forgeMaster: [
    (
      name: 'EMBER',
      colors: [Color(0xFFFF5722), Color(0xFFFF8A65), Color(0xFFD84315)],
    ),
    (
      name: 'AMBER',
      colors: [Color(0xFFFFB300), Color(0xFFFFD54F), Color(0xFFFF6F00)],
    ),
    (
      name: 'STEEL',
      colors: [Color(0xFFB0BEC5), Color(0xFF78909C), Color(0xFFECEFF1)],
    ),
  ],
  AppThemeMode.candyRush: [
    (
      name: 'BUBBLEGUM',
      colors: [Color(0xFFF8BBD0), Color(0xFFF48FB1), Color(0xFFFCE4EC)],
    ),
    (
      name: 'COTTON',
      colors: [Color(0xFFB3E5FC), Color(0xFFE1BEE7), Color(0xFFF8BBD0)],
    ),
    (
      name: 'SUGAR',
      colors: [Color(0xFFFFF0F5), Color(0xFFF8BBD0), Color(0xFFEC407A)],
    ),
  ],
  AppThemeMode.neonPrism: [
    (
      name: 'PRISM',
      colors: [Color(0xFFE040FB), Color(0xFF00E5FF), Color(0xFFFFD740)],
    ),
    (
      name: 'VOLT',
      colors: [Color(0xFF00E5FF), Color(0xFF76FF03), Color(0xFFE040FB)],
    ),
    (
      name: 'RAIN',
      colors: [Color(0xFF7C4DFF), Color(0xFF18FFFF), Color(0xFFFF4081)],
    ),
  ],
  AppThemeMode.blacksmithsFire: [
    (
      name: 'RUST',
      colors: [Color(0xFFD84315), Color(0xFF8D6E63), Color(0xFFFF8A65)],
    ),
    (
      name: 'COAL',
      colors: [Color(0xFF3E2723), Color(0xFFD84315), Color(0xFFFFB74D)],
    ),
    (
      name: 'FORGE',
      colors: [Color(0xFFFF8A65), Color(0xFFD84315), Color(0xFFFFCC80)],
    ),
  ],
  AppThemeMode.moltenSteel: [
    (
      name: 'MOLTEN',
      colors: [Color(0xFFFF6E40), Color(0xFFFF8A65), Color(0xFFDD2C00)],
    ),
    (
      name: 'STEEL',
      colors: [Color(0xFFB0BEC5), Color(0xFF78909C), Color(0xFFECEFF1)],
    ),
    (
      name: 'IRON',
      colors: [Color(0xFF546E7A), Color(0xFF90A4AE), Color(0xFFFF6E40)],
    ),
  ],
  AppThemeMode.paperInk: [
    (
      name: 'INK',
      colors: [Color(0xFF90A4AE), Color(0xFF546E7A), Color(0xFF263238)],
    ),
    (
      name: 'PAPER',
      colors: [Color(0xFFECEFF1), Color(0xFFCFD8DC), Color(0xFFB0BEC5)],
    ),
    (
      name: 'SKETCH',
      colors: [Color(0xFF78909C), Color(0xFFB0BEC5), Color(0xFF90A4AE)],
    ),
  ],
  AppThemeMode.voidWhite: [
    (
      name: 'VOID',
      colors: [Color(0xFFFFFFFF), Color(0xFF9E9E9E), Color(0xFF424242)],
    ),
    (
      name: 'STARK',
      colors: [Color(0xFFFAFAFA), Color(0xFF616161), Color(0xFFBDBDBD)],
    ),
    (
      name: 'INVERT',
      colors: [Color(0xFF212121), Color(0xFF616161), Color(0xFF9E9E9E)],
    ),
  ],
  AppThemeMode.moonlitChamber: [
    (
      name: 'MONO',
      colors: [Color(0xFFECEFF1), Color(0xFFB0BEC5), Color(0xFF90A4AE)],
    ),
    (
      name: 'WHITE',
      colors: [Color(0xFFFFFFFF), Color(0xFFFAFAFA), Color(0xFFE0E0E0)],
    ),
    (
      name: 'ONYX',
      colors: [Color(0xFF616161), Color(0xFF424242), Color(0xFF9E9E9E)],
    ),
  ],
};

/// Global particle palettes — 12 curated named color sets available on
/// every theme (replaces the per-theme 3-schema list, which left most
/// themes with only a couple of options).
const kGlobalParticlePalettes = <({String name, List<Color> colors})>[
  (
    name: 'NEON',
    colors: [
      Color(0xFF00E5FF),
      Color(0xFFFF2BD6),
      Color(0xFF7CFF00),
      Color(0xFFFFFF00),
    ],
  ),
  (
    name: 'EMBER',
    colors: [
      Color(0xFFFF3D00),
      Color(0xFFFF6E40),
      Color(0xFFFFAB40),
      Color(0xFFFFD180),
    ],
  ),
  (
    name: 'FROST',
    colors: [
      Color(0xFF80D8FF),
      Color(0xFFB3E5FC),
      Color(0xFFE1F5FE),
      Color(0xFF40C4FF),
    ],
  ),
  (
    name: 'TOXIN',
    colors: [
      Color(0xFF76FF03),
      Color(0xFF64DD17),
      Color(0xFFAEEA00),
      Color(0xFF00E676),
    ],
  ),
  (
    name: 'ROYAL',
    colors: [
      Color(0xFF7C4DFF),
      Color(0xFF651FFF),
      Color(0xFFB388FF),
      Color(0xFFD500F9),
    ],
  ),
  (
    name: 'GOLD',
    colors: [
      Color(0xFFFFD740),
      Color(0xFFFFC400),
      Color(0xFFFFAB00),
      Color(0xFFFFE57F),
    ],
  ),
  (
    name: 'BLOOD',
    colors: [
      Color(0xFFFF1744),
      Color(0xFFD50000),
      Color(0xFFFF5252),
      Color(0xFFFF8A80),
    ],
  ),
  (
    name: 'VOID',
    colors: [
      Color(0xFF6200EA),
      Color(0xFF304FFE),
      Color(0xFFAA00FF),
      Color(0xFF7C4DFF),
    ],
  ),
  (
    name: 'PRISM',
    colors: [
      Color(0xFFFF5252),
      Color(0xFFFFB300),
      Color(0xFF69F0AE),
      Color(0xFF40C4FF),
      Color(0xFFB388FF),
    ],
  ),
  (
    name: 'STEEL',
    colors: [
      Color(0xFFB0BEC5),
      Color(0xFF78909C),
      Color(0xFF546E7A),
      Color(0xFFECEFF1),
    ],
  ),
  (
    name: 'ABYSS',
    colors: [
      Color(0xFF0091EA),
      Color(0xFF00B0FF),
      Color(0xFF1DE9B6),
      Color(0xFF00B8D4),
    ],
  ),
  (
    name: 'ETHER',
    colors: [
      Color(0xFFF8BBD0),
      Color(0xFFE1BEE7),
      Color(0xFFD1C4E9),
      Color(0xFFB2EBF2),
    ],
  ),
];

/// Schema colors for the pref index (clamped to the global palette
/// list). `mode` is kept for signature compatibility — palettes are
/// global now.
List<Color> particleSchemaColors(AppThemeMode mode, int schemaIdx) {
  final list = kGlobalParticlePalettes;
  return list[schemaIdx.clamp(0, list.length - 1)].colors;
}
