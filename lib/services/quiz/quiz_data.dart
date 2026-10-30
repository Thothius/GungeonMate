part of '../quiz_engine.dart';

/// A single piece of loot that can drop out of a quiz chest.
class QuizLoot {
  const QuizLoot({
    required this.name,
    required this.iconPath,
    required this.isGun,
    required this.quality,
    this.hint = '',
    this.lore = '',
  });

  final String name;
  final String iconPath;
  final bool isGun;
  final String quality;

  /// Flavor text for the once-per-run Ammonomicon Hint — the item's
  /// real quote, falling back to its effect/notes when no quote exists.
  final String hint;

  /// Lowercased descriptive corpus (type, class, effect, notes, quote)
  /// used to theme fabricated distractors — a fire gun produces names
  /// like "Pyre Blaster", an ice item "Glacial Idol".
  final String lore;
}

/// A chest tier and its presentation data — quality letter(s), the real
/// in-game chest sprite, and an accent color for glows/borders.
class QuizChestTier {
  const QuizChestTier({
    required this.id,
    required this.poolQualities,
    required this.title,
    required this.chestName,
    required this.asset,
    required this.accent,
    this.unlocksAfter = 0,
    this.spriteScale = 1.0,
  });

  /// Persistence key — single letter for standard tiers ('D'..'S'),
  /// a slug for bonus chests ('rainbow', 'rat').
  final String id;

  /// Which loot qualities feed this chest's pool. One letter for the
  /// five standard chests; bonus chests mix several.
  final List<String> poolQualities;

  /// Single tier letter for the standard chests ('D'..'S'). Bonus
  /// chests carry a short label instead — used wherever a QualityBadge
  /// would otherwise show.
  final String title;
  final String chestName;
  final String asset;
  final Color accent;

  /// How many chests must be COMPLETED before this chest unlocks.
  /// 0 = always open.
  final int unlocksAfter;

  /// Per-tier render scale — flat sprites (brown/blue/green are wide
  /// and short) scale up so every chest reads the same visual size.
  final double spriteScale;

  bool get isBonus => poolQualities.length > 1;
}

/// The five chest tiers, weakest to strongest, matching Enter the
/// Gungeon's chest colors (brown → blue → green → red → black).
const kQuizChestTiers = <QuizChestTier>[
  QuizChestTier(
    id: 'D',
    poolQualities: ['D'],
    title: 'D',
    chestName: 'BROWN CHEST',
    asset: 'assets/images/objects/brown_chest.png',
    accent: Color(0xFFA1887F),
    spriteScale: 1.15,
  ),
  QuizChestTier(
    id: 'C',
    poolQualities: ['C'],
    title: 'C',
    chestName: 'BLUE CHEST',
    asset: 'assets/images/objects/blue_chest.png',
    accent: Color(0xFF1E88E5),
    spriteScale: 1.15,
  ),
  QuizChestTier(
    id: 'B',
    poolQualities: ['B'],
    title: 'B',
    chestName: 'GREEN CHEST',
    asset: 'assets/images/objects/green_chest.png',
    accent: Color(0xFF43A047),
    spriteScale: 1.12,
  ),
  QuizChestTier(
    id: 'A',
    poolQualities: ['A'],
    title: 'A',
    chestName: 'RED CHEST',
    asset: 'assets/images/objects/red_chest.png',
    accent: Color(0xFFE53935),
  ),
  QuizChestTier(
    id: 'S',
    poolQualities: ['S'],
    title: 'S',
    chestName: 'BLACK CHEST',
    asset: 'assets/images/objects/black_chest.png',
    accent: Color(0xFFFFD700),
  ),
];

/// Bonus chests — the endgame modes. Locked until enough standard
/// chests are completed; drawn from mixed loot pools.
const kQuizBonusTiers = <QuizChestTier>[
  QuizChestTier(
    id: 'rainbow',
    poolQualities: ['D', 'C', 'B', 'A', 'S'],
    title: '★',
    chestName: 'RAINBOW CHEST',
    asset: 'assets/images/objects/rainbow_chest.gif',
    accent: Color(0xFF00E5FF),
    unlocksAfter: 1,
    spriteScale: 0.85,
  ),
  QuizChestTier(
    id: 'rat',
    poolQualities: ['S', 'A'],
    title: 'S+A',
    chestName: 'RAT CHEST',
    asset: 'assets/images/objects/rat_chest.gif',
    accent: Color(0xFFC9A227),
    unlocksAfter: 2,
  ),
];

/// Every chest the quiz offers, in display order.
final kQuizAllTiers = <QuizChestTier>[...kQuizChestTiers, ...kQuizBonusTiers];

/// One quiz question: the revealed loot plus six labelled options,
/// exactly one of which is the loot's real name.
class QuizQuestion {
  const QuizQuestion({
    required this.loot,
    required this.options,
    required this.correctIndex,
  });

  final QuizLoot loot;

  /// Always six entries — options A through F.
  final List<String> options;
  final int correctIndex;
}

/// Hand-written answer sets for iconic drops — three sets of five
/// plausible fakes per loot, mixed real names and thematic fakes.
/// Extensible: add an entry keyed by the exact item/gun name.
const Map<String, List<List<String>>> _kCuratedSets = {
  'Casey': [
    [
      "Slugger's Bat",
      'Bat of the Blacksmith',
      'Mahoguny',
      'The Louisville Lead',
      'Homerun Hammer',
    ],
    ["Winchester's Bat", 'The Bunt', 'Grand Slam', 'Slugger', 'Bullet Bat'],
    [
      'Aluminium Avenger',
      'The Strikeout',
      'Bat of the Gungeoneer',
      'Ninth Inning',
      'Curveball Cannon',
    ],
  ],
  'Blasphemy': [
    [
      'Sacred Edge',
      'Fightsabre',
      'The Untouchable',
      'Wood Sword',
      'Sinner\'s Blade',
    ],
    [
      'The Blessed Blade',
      'Stick of Truth',
      'Old Reliable',
      'Plunger of Faith',
      'Sacrifice Sabre',
    ],
    [
      'Unbending Edge',
      'The Sixth Sword',
      'Broomstick',
      'Holy Poker',
      'The Heretic',
    ],
  ],
  'Gunther': [
    [
      'The Chatty Sidearm',
      'Talking Pistol',
      'Blabbergun',
      'Dragunfire',
      'The Loyal One',
    ],
    [
      'Friendship Cannon',
      'The Companion',
      'Mouthy Musket',
      'Trusty Talker',
      'Old Chatterbox',
    ],
    [
      'Sentient Sidearm',
      'The Voice',
      'Chattershooter',
      'Pew-Talker',
      'Level-Headed',
    ],
  ],
  'Yari Launcher': [
    [
      'Spear Volley',
      'Hellfire Speargun',
      'Javelin Jet',
      'Mourning Star',
      'The Skewer',
    ],
    [
      'Rapid Spears',
      'Pike Pult',
      'Lance-a-Lot',
      'Ballistic Harpoon',
      'Searing Spray',
    ],
    [
      'The Impaler',
      'Doombringer',
      'Rocket Javelin',
      'Scorcher',
      'Triple Skewer',
    ],
  ],
  'Spice': [
    [
      'Flavor Crystal',
      'The Seasoning',
      'Salt of the Gungeon',
      'Pepper Core',
      'Rare Herb',
    ],
    [
      'The Craving',
      'Savory Shard',
      'Cinnamon Relic',
      'The Ingredient',
      'Sweet Nectar',
    ],
    ['Melange', 'The Spice Flow', 'Golden Grain', 'Taste Bud', 'Secret Sauce'],
  ],
  'Pig': [
    ['Battle Swine', 'Ham on Wheels', 'The Oinker', 'War Hog', 'Pork Pal'],
    [
      'Sacrificial Swine',
      'The Baconator',
      'Loyal Piglet',
      'Boar Buddy',
      'Sir Snorts',
    ],
    [
      'Ham Familiar',
      'The Tribute',
      'Squealer',
      'Pig of War',
      'Chunky Companion',
    ],
  ],
  'Sixth Chamber': [
    [
      'The Seventh Seal',
      'Final Chamber',
      'Blessing of Kaliber',
      'The Last Room',
      'Chamber Relic',
    ],
    [
      'Seventh Chamber',
      'The Chambered One',
      'Kaliber\'s Gift',
      'Deep Chamber',
      'The Countdown',
    ],
    [
      'Chamber Idol',
      'The Loading',
      'Fifth Chamber',
      'Chamber Charm',
      'Reward of the Deep',
    ],
  ],
  'Clone': [
    ['The Duplicate', 'Second Self', 'Mirror Mimic', 'Carbon Copy', 'The Echo'],
    [
      'Twin Token',
      'Backup Gungeoneer',
      'The Double',
      'Spare Life',
      'Xerox Idol',
    ],
    [
      'Doppelganger Drop',
      'Another You',
      'The Recycle',
      'Extra Life',
      'Second Run',
    ],
  ],
  'Super Meat Gun': [
    [
      'Meat Blaster',
      'The Tenderizer',
      'Sir Loin',
      'Beef Cannon',
      'Sausage Shooter',
    ],
    [
      'Bandage Blaster',
      'The Meat Grinder',
      'Steak Shot',
      'Raw Repeater',
      'Flesh Volley',
    ],
    [
      'Ham Hock Howitzer',
      'The Carnivore',
      'Meat Missile',
      'Brisket Buster',
      'Protein Pack',
    ],
  ],
  'Banana': [
    [
      'Peel Cannon',
      'The Split',
      'Monkey Wrench',
      'Potassium Pipe',
      'Boomerang Blaster',
    ],
    [
      'The Slipstream',
      'Fruit Volley',
      'Chiquita Charge',
      'Peeler',
      'Ripe Repeater',
    ],
    [
      'Yellow Jacket',
      'The Bunch',
      'Plantain Pistol',
      'Smoothie Shooter',
      'Cannon Banana',
    ],
  ],
  'Turtle Problem': [
    [
      'Shell Shock',
      'The Slowdown',
      'Terrapin Trouble',
      'Snapper Squad',
      'Box Turtle',
    ],
    [
      'Tiny Tortoises',
      'The Stampede',
      'Shell Swarm',
      'Reptile Riot',
      'Pond Problem',
    ],
    [
      'The Menagerie',
      'Tortoise Trail',
      'Baby Snappers',
      'Shell Parade',
      'Slow Surge',
    ],
  ],
  'Sunglasses': [
    [
      'Cool Shades',
      'The Aviators',
      'Sun Blockers',
      'Stunner Shades',
      'Shutter Specs',
    ],
    [
      'Deal-With-Its',
      'The Blinds',
      'Ray Blockers',
      'Midnight Specs',
      'Flash Frames',
    ],
    [
      'The Cooldown',
      'Polarized Pair',
      'Glamour Guards',
      'Sun Specs',
      'The Squinters',
    ],
  ],
  'Gunderfury': [
    [
      'The Grit',
      'Level Ten',
      'Experience Engine',
      'Veteran Volley',
      'The Loyal Gun',
    ],
    [
      'Growing Gun',
      'The Evolver',
      'Seasoned Sidearm',
      'Rank-Up Rifle',
      'Fury of Ages',
    ],
    [
      'The Apprentice',
      'Mastery Musket',
      'Leveled Launcher',
      'Old Faithful',
      'The Graduate',
    ],
  ],
  'Dragunfire': [
    [
      'Dragon\'s Breath',
      'The Firebreather',
      'Scale Cannon',
      'Ember Engine',
      'The Wyrm',
    ],
    [
      'Flame Volley',
      'Kindled Cannon',
      'The Scorcher',
      'Ash Blaster',
      'Blaze Repeater',
    ],
    [
      'Inferno Injector',
      'The Afterburner',
      'Smolder Shot',
      'Dragonspit',
      'Fire Lance',
    ],
  ],
  'Mourning Star': [
    [
      'The Eulogy',
      'Falling Star',
      'Dusk Repeater',
      'Orbital Cannon',
      'Sky Burial',
    ],
    [
      'Event Horizon',
      'The Comet',
      'Nova Launcher',
      'Grieving Star',
      'The Meteor',
    ],
    ['Starfall', 'Cosmic Wake', 'The Requiem', 'Funeral Volley', 'Nightfall'],
  ],
  'Fightsabre': [
    [
      'The Glowblade',
      'Light Foil',
      'Jedi\'s Regret',
      'Plasma Edge',
      'Laser Rapier',
    ],
    ['Beam Sabre', 'The Duellist', 'Photon Fencer', 'Neon Katana', 'The Parry'],
    [
      'Energy Edge',
      'Saber of Light',
      'The Elegant Weapon',
      'Arc Foil',
      'Luminous Lance',
    ],
  ],
  'Finished Gun': [
    [
      'The Incomplete',
      'Almost Gun',
      'The Final Piece',
      'Last Gun',
      'Prototype Zero',
    ],
    [
      'The Completed One',
      'Unfinished Gun',
      'The Blueprint',
      'Whole Gun',
      'Missing Link',
    ],
    [
      'The Apocrypha',
      'Seventh Gun',
      'The Unmade',
      'Draft Cannon',
      'Final Draft',
    ],
  ],
  'AU Gun': [
    ['The Formula', 'Gold Gun', 'X-Blade', 'Z Gun', 'The Letter'],
    [
      'Periodic Pistol',
      'Element 79',
      'The Equation',
      'Killer Variable',
      'Au-79',
    ],
    [
      'The Artifact',
      'Bullion Blaster',
      'Golden Ratio',
      'Symbol Gun',
      'The Unknown',
    ],
  ],
  'Crestfaller': [
    [
      'The Broken Sword',
      'Fallen Blade',
      'Pride Splitter',
      'Ruined Edge',
      'Shattered Sabre',
    ],
    [
      'Knight\'s Regret',
      'The Defeated',
      'Bonfire Blade',
      'Ashen Edge',
      'Waning Sword',
    ],
    [
      'Crown Splitter',
      'The Beaten Path',
      'Sundered Steel',
      'Lost Blade',
      'Hope\'s End',
    ],
  ],
  'Devolver': [
    [
      'The Reverse',
      'Un-Evolver',
      'Backwards Gun',
      'The Devolution',
      'De-Evolver',
    ],
    [
      'Regression Ray',
      'The Reversal',
      'Backward Blaster',
      'Undo Gun',
      'Time Turner',
    ],
    [
      'The Downgrade',
      'Evolution Undoer',
      'Reverse Gun',
      'The Rewind',
      'Progress Ender',
    ],
  ],
  'Magic Lamp': [
    [
      'The Genie Lamp',
      'Three Wishes',
      'Brass Lantern',
      'Smoke Lamp',
      'Wishing Well',
    ],
    [
      'The Ifrit',
      'Aladdin\'s Relic',
      'Djinn Bottle',
      'Oil Lamp',
      'The Wish Granter',
    ],
    [
      'Spirit Lamp',
      'The Conjurer',
      'Smoke Vessel',
      'The Lantern',
      'Wishbone Lamp',
    ],
  ],
  'Owl': [
    ['The Hooter', 'Night Watch', 'Feathered Friend', 'Barn Owl', 'The Perch'],
    ['Silent Watcher', 'Talon Scout', 'The Lookout', 'Wise One', 'Night Bird'],
    ['The Companion', 'Great Horned', 'Swoop', 'Feather Scout', 'Hollow Owl'],
  ],
  'Phoenix': [
    ['The Rebirth', 'Ash Bird', 'Sunbird', 'Immortal Flame', 'Pyre Phoenix'],
    [
      'Reborn Raptor',
      'The Rising',
      'Ember Wings',
      'Solar Falcon',
      'Ashen Eagle',
    ],
    ['Firebird', 'The Resurrected', 'Flame Fowl', 'Rising Sun', 'Undying Bird'],
  ],
  'Shellegun': [
    [
      'Shell Shot',
      'The Snail Gun',
      'Casing Cannon',
      'Exoskeleton',
      'Turret Tortoise',
    ],
    [
      'Hermit Howitzer',
      'The Carapace',
      'Mollusk Mortar',
      'Escargun',
      'Bunker Beast',
    ],
    [
      'The Snail Trail',
      'Conch Cannon',
      'Shell Shield',
      'Slow Roll',
      'Home on Back',
    ],
  ],
  'Super Space Turtle': [
    [
      'Cosmic Tortoise',
      'The Terrapin',
      'Star Turtle',
      'Orbit Shell',
      'Galaxy Guardian',
    ],
    [
      'Space Shell',
      'The Voyager',
      'Astro Turtle',
      'Comet Companion',
      'Void Terrapin',
    ],
    [
      'The Slow Cosmonaut',
      'Shelled Explorer',
      'Turbo Turtle',
      'Moon Shell',
      'Star Shell',
    ],
  ],
  'Bundle of Wands': [
    [
      'The Sextet',
      'Wand Collection',
      'Six Shooter',
      'Staff Bundle',
      'The Arsenal',
    ],
    [
      'Wizard\'s Hoard',
      'The Rainbow',
      'Prismatic Pack',
      'Wand Wheel',
      'Magic Quiver',
    ],
    [
      'The Ensemble',
      'Six of Wands',
      'Spell Sampler',
      'Coven Cache',
      'The Selection',
    ],
  ],
  'Elimentaler': [
    [
      'The Element Gun',
      'Periodic Blaster',
      'Form Fuser',
      'Matter Maker',
      'The Alchemist',
    ],
    [
      'Element Cannon',
      'Phase Pistol',
      'The Transformer',
      'Formulator',
      'Reaction Ray',
    ],
    [
      'The Fabricator',
      'Matter Mixer',
      'State Changer',
      'The Chemist',
      'Element Lab',
    ],
  ],
  'Railgun': [
    [
      'The Accelerator',
      'Magnet Cannon',
      'Coil Driver',
      'Slug Thrower',
      'Hypervelocity',
    ],
    [
      'Gauss Cannon',
      'The Linear',
      'Rail Driver',
      'Mag Blaster',
      'Ferro Launcher',
    ],
    [
      'The Penetrator',
      'Coil Cannon',
      'Magnetic Musket',
      'Slug Rail',
      'The Railer',
    ],
  ],
  'Mimic Tooth Necklace': [
    [
      'False Teeth',
      'The Deceiver',
      'Maw Charm',
      'Biter\'s Prize',
      'Chest Teeth',
    ],
    [
      'The Imposter',
      'Fool\'s Fang',
      'Greedy Gnashers',
      'Trap Jaw',
      'Mimic Bite',
    ],
    [
      'The False Friend',
      'Chomp Chain',
      'Liar\'s Locket',
      'Maw Medal',
      'Bait Pendant',
    ],
  ],
  'Partially-Eaten Cheese': [
    [
      'The Leftover',
      'Nibbled Wedge',
      'Someone\'s Lunch',
      'Half Ration',
      'Mouldy Morsel',
    ],
    ['The Secondhand', 'Pre-Eaten', 'Rat\'s Share', 'Bitten Brie', 'The Scrap'],
    [
      'Cheese Remains',
      'The Nibbled',
      'Gnawed Gold',
      'Half-Eaten',
      'Leftover Loot',
    ],
  ],
  'Unicorn Horn': [
    ['The Spiral', 'Alicorn', 'Rainbow Lance', 'Mythic Horn', 'The Narwhal'],
    [
      'Magic Piercer',
      'The Unicorn\'s Gift',
      'Spiral Spear',
      'Glitter Horn',
      'Fairy Lance',
    ],
    [
      'The Pegasus',
      'Horn of Purity',
      'Rainbow Rapier',
      'Starlight Pike',
      'The Majestic',
    ],
  ],
};
