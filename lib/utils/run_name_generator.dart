import 'dart:math' as math;

/// RNG run-title generator for Paradox Mode. The Main Player rolls a
/// name when starting a session; it's carried in the hello handshake
/// and session meta so both devices show the same title on the MP bar.
class RunNameGenerator {
  RunNameGenerator._();

  static const _adjectives = <String>[
    'Cursed',
    'Jammed',
    'Gilded',
    'Hollow',
    'Blasphemous',
    'Molten',
    'Forsaken',
    'Luckless',
    'Ammo-Driven',
    'Gun-Crazed',
    'Reloaded',
    'Mimic-Born',
    'Rubber-Banded',
    'Turbo',
    'Blank',
    'Bulletproof',
    'Hegemonic',
    'Unjammed',
  ];

  static const _nouns = <String>[
    'Dragunfall',
    'Bullet-King Run',
    'Ammonomicon',
    'Gundromeda Descent',
    'Lead Maiden Voyage',
    'Kill Pill Run',
    'Chamber Crawl',
    'Gungeoneer Gauntlet',
    'Lich Hunt',
    'Rat Den Raid',
    'Blobulon Breakout',
    'Shelleton Stand',
    'Minecart Massacre',
    'Oubliette Escape',
    'Bullet Hell Sprint',
    'Forge Dive',
    'Abbey Assault',
    'Hollow Point Run',
  ];

  static final _rng = math.Random();

  /// e.g. "Cursed Dragunfall" / "Jammed Bullet-King Run"
  static String roll() =>
      '${_adjectives[_rng.nextInt(_adjectives.length)]} '
      '${_nouns[_rng.nextInt(_nouns.length)]}';
}
