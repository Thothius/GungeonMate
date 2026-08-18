import '../../../services/app_theme.dart';

/// Decorative background style for Theme Signature mode.
/// Each style drives a different CustomPainter flourish behind
/// the run data.
enum ThemeDecor {
  none, // Minimalist — clean, no decorations
  embers, // Forge Master / Dragunfire — rising ember particles
  frost, // Hollow Chill / Moonlit Chamber — drifting ice crystals
  sparkles, // Unicorn — twinkling pastel sparkles
  circuits, // Robot's Core / Mr. Robot — scrolling circuit lines
  paws, // Cat Lady — drifting paw prints
  moonlight, // Moonlit Chamber — crescent moons + silver rays
  lightning, // Storm Caller — crackling arc flashes
  brass, // Ammonomicon / Cult of Gundead — brass filigree corners
  blade, // The Bullet — crossed blade silhouettes
  rift, // The Paradox — fractured reality shards
  powder, // Gunpowder — falling gunpowder grains
  bone, // Lich's Domain — floating bone fragments
  tactical, // Valor of Marines — tactical grid overlay
  custom, // Custom — subtle particle dust
}

/// Themed stat label overrides. When null, the default label is used.
class ThemedStatLabels {
  final String? coolness;
  final String? curse;
  final String? guns;
  final String? items;
  final String? topDps;

  const ThemedStatLabels({
    this.coolness,
    this.curse,
    this.guns,
    this.items,
    this.topDps,
  });

  static const _default = ThemedStatLabels();
}

/// Lore record for a single theme — drives the Theme Signature
/// mode's layout, decorations, and flavor text.
class ThemeLore {
  /// Lore title — the theme's "in-world" name.
  final String title;

  /// Short tagline shown under the title.
  final String tagline;

  /// A Gungeon lore quote shown in the header area.
  final String quote;

  /// The element type (FIRE, ICE, CIRCUIT, etc.).
  final String element;

  /// Decorative background style.
  final ThemeDecor decor;

  /// Themed stat label overrides.
  final ThemedStatLabels statLabels;

  /// Accent glyph shown next to the title.
  final String accentGlyph;

  const ThemeLore({
    required this.title,
    required this.tagline,
    required this.quote,
    required this.element,
    required this.decor,
    required this.statLabels,
    required this.accentGlyph,
  });
}

/// The theme lore registry — one entry per visible theme.
/// Drives the Theme Signature mode's entire aesthetic.
final Map<AppThemeMode, ThemeLore> kThemeLore = {
  AppThemeMode.minimalist: ThemeLore(
    title: 'Minimalist',
    tagline: 'No glow. No noise. Just the run.',
    quote: 'The Gungeon does not need decoration to kill you.',
    element: 'METAL',
    decor: ThemeDecor.none,
    accentGlyph: '◇',
    statLabels: const ThemedStatLabels(
      coolness: 'COMPOSURE',
      curse: 'AGGRO',
      topDps: 'PEAK DPS',
    ),
  ),
  AppThemeMode.unicorn: ThemeLore(
    title: 'Cotton Candy',
    tagline: 'A pastel dream in the breach.',
    quote: 'Even the bullets are sparkly here.',
    element: 'RAINBOW',
    decor: ThemeDecor.sparkles,
    accentGlyph: '✦',
    statLabels: const ThemedStatLabels(
      coolness: 'SPARKLE',
      curse: 'GLOOM',
      topDps: 'RAINBOW DPS',
    ),
  ),
  AppThemeMode.forgeMaster: ThemeLore(
    title: 'Forge Master',
    tagline: 'Forged in the Fifth Chamber.',
    quote: 'The Dragun\'s scales light the furnaces.',
    element: 'FIRE',
    decor: ThemeDecor.embers,
    accentGlyph: '🔥',
    statLabels: const ThemedStatLabels(
      coolness: 'TEMPER',
      curse: 'HEAT',
      topDps: 'FORGE DPS',
    ),
  ),
  AppThemeMode.robotsCore: ThemeLore(
    title: 'Robot\'s Core',
    tagline: 'Pure cold steel. No heart.',
    quote: 'JUNK PROTOCOL: OPTIMAL FUEL SOURCE.',
    element: 'CIRCUIT',
    decor: ThemeDecor.circuits,
    accentGlyph: '⚡',
    statLabels: const ThemedStatLabels(
      coolness: 'COOLANT',
      curse: 'CORRUPTION',
      topDps: 'OUTPUT DPS',
    ),
  ),
  AppThemeMode.catLady: ThemeLore(
    title: 'Cat Lady',
    tagline: 'Nine lives, one warm den.',
    quote: 'The cats know the Gungeon better than you do.',
    element: 'PAW',
    decor: ThemeDecor.paws,
    accentGlyph: '🐾',
    statLabels: const ThemedStatLabels(
      coolness: 'COZY',
      curse: 'HISS',
      topDps: 'SCRATCH DPS',
    ),
  ),
  AppThemeMode.moonlitChamber: ThemeLore(
    title: 'Moonlit Chamber',
    tagline: 'Silver light through the grates.',
    quote: 'The crescent moon watches every chamber.',
    element: 'MOON',
    decor: ThemeDecor.moonlight,
    accentGlyph: '☾',
    statLabels: const ThemedStatLabels(
      coolness: 'LUNAR',
      curse: 'ECLIPSE',
      topDps: 'SILVER DPS',
    ),
  ),
  AppThemeMode.stormCaller: ThemeLore(
    title: 'Storm Caller',
    tagline: 'Thunder rolls through the corridors.',
    quote: 'Shoot first. Ask questions never.',
    element: 'LIGHTNING',
    decor: ThemeDecor.lightning,
    accentGlyph: '⚡',
    statLabels: const ThemedStatLabels(
      coolness: 'CHARGE',
      curse: 'OVERLOAD',
      topDps: 'VOLT DPS',
    ),
  ),
  AppThemeMode.mrRobot: ThemeLore(
    title: 'Mr. Robot',
    tagline: 'Efficient. Calculating. Relentless.',
    quote: 'JUNK IS THE OPTIMAL SOURCE OF FUEL.',
    element: 'CIRCUIT',
    decor: ThemeDecor.circuits,
    accentGlyph: '🤖',
    statLabels: const ThemedStatLabels(
      coolness: 'BATTERY',
      curse: 'MALWARE',
      topDps: 'CYCLE DPS',
    ),
  ),
  AppThemeMode.valorOfMarines: ThemeLore(
    title: 'Valor of Marines',
    tagline: 'Stay frosty. Always by the book.',
    quote: 'The Marine does not flinch.',
    element: 'DOG TAG',
    decor: ThemeDecor.tactical,
    accentGlyph: '🎖',
    statLabels: const ThemedStatLabels(
      coolness: 'DISCIPLINE',
      curse: 'HEAT SIGNATURE',
      topDps: 'ISSUE DPS',
    ),
  ),
  AppThemeMode.theBullet: ThemeLore(
    title: 'The Bullet',
    tagline: 'For the glory of the Bullet-King!',
    quote: 'A bullet that dared to wield a blade.',
    element: 'BLADE',
    decor: ThemeDecor.blade,
    accentGlyph: '⚔',
    statLabels: const ThemedStatLabels(
      coolness: 'HONOR',
      curse: 'TREASON',
      topDps: 'BLADE DPS',
    ),
  ),
  AppThemeMode.theParadox: ThemeLore(
    title: 'The Paradox',
    tagline: 'Who... what... when... am I?',
    quote: 'Existence is a loop inside a cylinder.',
    element: 'RIFT',
    decor: ThemeDecor.rift,
    accentGlyph: '∞',
    statLabels: const ThemedStatLabels(
      coolness: 'STABILITY',
      curse: 'FRACTURE',
      topDps: 'PARADOX DPS',
    ),
  ),
  AppThemeMode.gunpowder: ThemeLore(
    title: 'Gunpowder',
    tagline: 'Lock and load. The smell of spent casings.',
    quote: 'Black powder and brass — the Gungeon\'s perfume.',
    element: 'POWDER',
    decor: ThemeDecor.powder,
    accentGlyph: '💥',
    statLabels: const ThemedStatLabels(
      coolness: 'COMPOSURE',
      curse: 'FLASH',
      topDps: 'YIELD DPS',
    ),
  ),
  AppThemeMode.dragunfire: ThemeLore(
    title: 'Dragunfire',
    tagline: 'Face the High Dragun. Only the worthy survive.',
    quote: 'The Fifth Chamber burns. Scales glint. Fire roars.',
    element: 'FIRE',
    decor: ThemeDecor.embers,
    accentGlyph: '🐉',
    statLabels: const ThemedStatLabels(
      coolness: 'TEMPER',
      curse: 'INFERNO',
      topDps: 'DRAGUN DPS',
    ),
  ),
  AppThemeMode.lichsDomain: ThemeLore(
    title: 'Lich\'s Domain',
    tagline: 'The master of the Gungeon awaits.',
    quote: 'Cold. Eternal. Absolute in its finality.',
    element: 'BONE',
    decor: ThemeDecor.bone,
    accentGlyph: '💀',
    statLabels: const ThemedStatLabels(
      coolness: 'CHILL',
      curse: 'DECAY',
      topDps: 'CRYPT DPS',
    ),
  ),
  AppThemeMode.custom: ThemeLore(
    title: 'Custom',
    tagline: 'A blank canvas of personal madness.',
    quote: 'Godspeed, designer.',
    element: 'BULLET',
    decor: ThemeDecor.custom,
    accentGlyph: '◆',
    statLabels: const ThemedStatLabels(),
  ),
};

/// Get the lore for the active theme, with a fallback for
/// themes not in the registry.
ThemeLore themeLoreFor(AppThemeMode mode) =>
    kThemeLore[mode] ??
    const ThemeLore(
      title: 'Gungeon',
      tagline: 'Enter the breach.',
      quote: 'The Gungeon remembers.',
      element: 'BULLET',
      decor: ThemeDecor.none,
      statLabels: ThemedStatLabels._default,
      accentGlyph: '◆',
    );
