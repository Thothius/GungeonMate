import 'dart:math';

import 'package:flutter/material.dart';

import '../models/gun.dart';
import '../models/item.dart';

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

QuizChestTier quizTierFor(String quality) =>
    kQuizAllTiers.firstWhere((t) => t.id == quality,
        orElse: () => kQuizAllTiers.first);

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

/// Builds chest loot pools and question sets for the Gungeonmaster Quiz.
///
/// Every loot drop draws from the item's own quality pool for plausible
/// wrong answers, padded with procedurally fabricated Gungeon-flavored
/// names. Each loot has three fixed answer sets (seeded deterministically
/// by the item name); a random set is picked per drop so replays stay
/// fresh while sets remain stable.
class QuizEngine {
  QuizEngine({required List<Gun> guns, required List<Item> items}) {
    for (final g in guns) {
      final q = g.quality.toUpperCase();
      final loot = QuizLoot(
        name: g.name,
        iconPath: g.icon,
        isGun: true,
        quality: q,
        hint: g.quote.isNotEmpty ? g.quote : g.notes,
        lore: '${g.type} ${g.gunClass} ${g.notes} ${g.quote}'.toLowerCase(),
      );
      _poolByTier.putIfAbsent(q, () => []).add(loot);
      _gunNamesByTier.putIfAbsent(q, () => []).add(g.name);
      _allNames.add(g.name.toLowerCase());
    }
    for (final i in items) {
      final q = i.quality.toUpperCase();
      final loot = QuizLoot(
        name: i.name,
        iconPath: i.icon,
        isGun: false,
        quality: q,
        hint: i.quote.isNotEmpty ? i.quote : i.effect,
        lore: '${i.type} ${i.effect} ${i.quote}'.toLowerCase(),
      );
      _poolByTier.putIfAbsent(q, () => []).add(loot);
      _itemNamesByTier.putIfAbsent(q, () => []).add(i.name);
      _allNames.add(i.name.toLowerCase());
    }
  }

  final Map<String, List<QuizLoot>> _poolByTier = {};
  final Map<String, List<String>> _gunNamesByTier = {};
  final Map<String, List<String>> _itemNamesByTier = {};
  final Set<String> _allNames = {};

  /// Total loot available in a tier's chest (guns + items).
  int poolSizeFor(String quality) =>
      _poolByTier[quality.toUpperCase()]?.length ?? 0;

  /// Total loot for a chest — one quality for standard tiers, the sum
  /// of all its qualities for bonus chests.
  int poolSizeForTier(QuizChestTier tier) =>
      tier.poolQualities.fold(0, (sum, q) => sum + poolSizeFor(q));

  /// Gun count inside a tier's pool — for the "14 guns" stat line.
  int gunsForTier(QuizChestTier tier) =>
      tier.poolQualities.fold(
          0, (sum, q) => sum + (_gunNamesByTier[q]?.length ?? 0));

  /// Item count inside a tier's pool.
  int itemsForTier(QuizChestTier tier) =>
      tier.poolQualities.fold(
          0, (sum, q) => sum + (_itemNamesByTier[q]?.length ?? 0));

  /// Number of hand-curated distractor sets — test hook + stats.
  int get curatedSetCount => _kCuratedSets.length;

  /// A fresh shuffled loot pool for one chest run. The session draws
  /// from this list in order — no repeats inside a single run.
  List<QuizLoot> poolFor(String quality, {Random? rng}) {
    final pool = List<QuizLoot>.of(
        _poolByTier[quality.toUpperCase()] ?? const <QuizLoot>[]);
    pool.shuffle(rng ?? Random());
    return pool;
  }

  /// A fresh shuffled loot pool for a chest — mixes all of its
  /// [QuizChestTier.poolQualities] for bonus chests.
  List<QuizLoot> poolForTier(QuizChestTier tier, {Random? rng}) {
    final pool = <QuizLoot>[
      for (final q in tier.poolQualities)
        ...?_poolByTier[q.toUpperCase()],
    ];
    pool.shuffle(rng ?? Random());
    return pool;
  }

  /// Builds one question for a revealed loot: correct name + five

  /// distractors taken from one of the loot's three fixed sets.
  QuizQuestion questionFor(QuizLoot loot, {Random? rng}) {
    final r = rng ?? Random();
    final sets = distractorSetsFor(loot);
    final set = sets[r.nextInt(sets.length)];
    final options = <String>[loot.name, ...set]..shuffle(r);
    return QuizQuestion(
      loot: loot,
      options: options,
      correctIndex: options.indexOf(loot.name),
    );
  }

  /// The three fixed distractor sets for a loot (five names each).
  /// Deterministic per loot so the same three sets rotate forever;
  /// curated entries override the generator for iconic drops.
  List<List<String>> distractorSetsFor(QuizLoot loot) {
    final curated = _kCuratedSets[loot.name];
    if (curated != null) {
      return curated
          .map((s) => List<String>.unmodifiable(s))
          .toList(growable: false);
    }
    final seed = _stableHash(loot.name);
    // One RNG + one shared used-set across all three sets keeps the
    // distractors distinct between sets whenever the pool allows it.
    final rng = Random(seed);
    final used = <String>{loot.name.toLowerCase()};
    return [
      for (var i = 0; i < 3; i++) _buildSet(loot, rng, used),
    ];
  }

  /// Assembles one set of five distractors: up to three real names from
  /// the same tier (same kind preferred), filled out with fabrications.
  List<String> _buildSet(QuizLoot loot, Random rng, Set<String> used) {
    final out = <String>[];

    final sameKind = List<String>.of(
        (loot.isGun ? _gunNamesByTier : _itemNamesByTier)[loot.quality] ??
            const <String>[])
      ..shuffle(rng);
    final crossKind = List<String>.of(
        (loot.isGun ? _itemNamesByTier : _gunNamesByTier)[loot.quality] ??
            const <String>[])
      ..shuffle(rng);

    // Real names are the strongest misdirection — plausible answers that
    // genuinely exist in the same chest pool.
    final realTarget = sameKind.length >= 3 ? 3 : sameKind.length;
    for (final n in sameKind) {
      if (out.length >= realTarget) break;
      if (used.add(n.toLowerCase())) out.add(n);
    }
    for (final n in crossKind) {
      if (out.length >= 3) break;
      if (used.add(n.toLowerCase())) out.add(n);
    }

    var guard = 0;
    while (out.length < 5 && guard++ < 60) {
      final fake = _fabricate(loot, rng);
      final key = fake.toLowerCase();
      // Never fabricate a name that collides with a real drop.
      if (!_allNames.contains(key) && used.add(key)) out.add(fake);
    }

    // Tiny pools fallback: any unused real names from neighboring tiers.
    if (out.length < 5) {
      final neighbors = <String>[
        ...?_gunNamesByTier[loot.quality],
        ...?_itemNamesByTier[loot.quality],
        ...?_gunNamesByTier[_neighborTier(loot.quality)],
        ...?_itemNamesByTier[_neighborTier(loot.quality)],
      ]..shuffle(rng);
      for (final n in neighbors) {
        if (out.length >= 5) break;
        if (used.add(n.toLowerCase())) out.add(n);
      }
    }
    return out;
  }

  String _neighborTier(String quality) {
    const order = ['D', 'C', 'B', 'A', 'S'];
    final i = order.indexOf(quality);
    return i <= 0 ? 'C' : order[i - 1];
  }

  // ── Fabricated name generation ─────────────────────────────────────

  static const _adjectives = <String>[
    'Rusted', 'Gilded', 'Hollow', 'Cursed', 'Blessed', 'Molten', 'Frozen',
    'Brass', 'Chrome', 'Leaden', 'Ancient', 'Forsaken', 'Jammed', 'Grim',
    'Silent', 'Swift', 'Heavy', 'Blasphemous', 'Copper', 'Void-Touched',
  ];
  static const _gunNouns = <String>[
    'Blaster', 'Carbine', 'Revolver', 'Cannon', 'Repeater', 'Longshot',
    'Scattergun', 'Wand', 'Pistol', 'Rifle', 'Launcher', 'Sidearm',
    'Musket', 'Volley', 'Raildriver', 'Bore',
  ];
  static const _itemNouns = <String>[
    'Idol', 'Relic', 'Charm', 'Core', 'Engine', 'Boots', 'Cape', 'Ring',
    'Heart', 'Skull', 'Fang', 'Eye', 'Tonic', 'Ration', 'Coupon', 'Map',
    'Key', 'Medal', 'Sack', 'Gland',
  ];
  static const _owners = <String>[
    'Bello', 'Cadence', 'Ox', 'Frifle', 'Winchester', 'Doug', 'Ser Manuel',
    'Ledge', 'Blobby', 'Tinker', 'Old Red', 'Albern', 'Norwich', 'Daisuke',
  ];
  static const _places = <String>[
    'the Forge', 'the Hollow', 'the Keep', 'the Mine', 'the Abbey',
    'Bullet Hell', 'the Breach', 'the Oubliette', 'the Fifth Chamber',
  ];
  static const _marks = <String>['MK.II', 'MK.III', 'MK.IV'];

  /// Theme-tinted adjectives, picked when the loot's lore matches a
  /// keyword family — makes fakes feel crafted rather than generic.
  static const _themeAdjs = <String, List<String>>{
    'fire|burn|flame|dragun|molten|incendiary|explosive':
        ['Ember', 'Pyre', 'Scorching', 'Blazing', 'Furnace', 'Incendiary'],
    'ice|frost|freeze|cold|glacier|snow|chill':
        ['Frozen', 'Glacial', 'Arctic', 'Shivering', 'Cryo', 'Wintry'],
    'poison|venom|toxic|acid|plague':
        ['Venomous', 'Caustic', 'Virulent', 'Noxious', 'Festering'],
    'electric|shock|spark|thunder|lightning|volt|tesla|coil':
        ['Charged', 'Voltaic', 'Galvanic', 'Static', 'Surging'],
    'beam|laser|light|prism|radiant|photon|luminous':
        ['Luminous', 'Prismatic', 'Radiant', 'Coherent', 'Reflected'],
    'rocket|grenade|bomb|missile|blast|explode':
        ['Blast', 'Demolition', 'Breaching', 'Volatile', 'Heavy'],
    'sword|blade|bat|saber|melee|slash|katana':
        ['Tempered', 'Keen', 'Dueling', 'Whetted', 'Singing'],
    'magic|wand|charm|arcane|spell|rune|crystal|hex':
        ['Arcane', 'Runic', 'Eldritch', 'Mystic', 'Hallowed'],
    'companion|familiar|pet|turtle|pig|owl|dog|friend':
        ['Loyal', 'Tamed', 'Kindred', 'Faithful', 'Trusted'],
    'heal|health|heart|regen|life|restore|armor|shield':
        ['Vital', 'Mending', 'Restorative', 'Aegis', 'Bulwark'],
    'ammo|bullet|shot|shell|reload|magazine|clip':
        ['Loaded', 'Brass-Jacketed', 'Full-Metal', 'Hollow-Point'],
    'curse|jammed|demon|dark|void|shadow|ghost|spirit':
        ['Cursed', 'Forsaken', 'Umbral', 'Hollow', 'Whispered'],
    'mimic|chest|key|lock|coin|shop|sell|price|hegemony':
        ['Mimic', 'Gilded', 'Miserly', 'Coveted', 'Hoarded'],
    'roll|dodge|speed|fast|quick|agile|dash':
        ['Swift', 'Nimble', 'Fleet', 'Rolling', 'Quickdraw'],
    'synergy|combo|link|chain':
        ['Twinned', 'Linked', 'Chained', 'Resonant'],
  };

  String _noun(QuizLoot loot, Random rng) {
    final nouns = loot.isGun ? _gunNouns : _itemNouns;
    return nouns[rng.nextInt(nouns.length)];
  }

  /// Precompiled theme regexes — compiled once, not per question.
  static final _themeCompiled = <RegExp, List<String>>{
    for (final e in _themeAdjs.entries) RegExp(e.key): e.value,
  };

  /// Theme-matched adjective for the loot, or a generic one — 60%
  /// themed when a keyword family matches the loot's lore.
  String _adj(QuizLoot loot, Random rng) {
    if (loot.lore.isNotEmpty && rng.nextInt(10) < 6) {
      for (final e in _themeCompiled.entries) {
        if (e.key.hasMatch(loot.lore)) {
          final list = e.value;
          return list[rng.nextInt(list.length)];
        }
      }
    }
    return _adjectives[rng.nextInt(_adjectives.length)];
  }

  /// Produces a plausible fake name riffing on the loot's real name —
  /// possessive swaps, adjective+noun combos, place-of-origin titles.
  String _fabricate(QuizLoot loot, Random rng) {
    final name = loot.name;
    switch (rng.nextInt(6)) {
      case 0:
        final owner = _owners[rng.nextInt(_owners.length)];
        // "Casey's Bat" → "Bello's Bat" — mimics the real naming scheme.
        if (name.contains("'")) {
          return "$owner'${name.split("'")[1]}";
        }
        return "$owner's ${_noun(loot, rng)}";
      case 1:
        return '${_adj(loot, rng)} ${_noun(loot, rng)}';
      case 2:
        return '${_noun(loot, rng)} of ${_places[rng.nextInt(_places.length)]}';
      case 3:
        return 'The ${_adj(loot, rng)} ${_noun(loot, rng)}';
      case 4:
        // Swap the trailing word of multi-word names: "Hyper Light
        // Blaster" → "Hyper Light Volley".
        final words = name.split(' ');
        if (words.length > 1 && !name.contains("'")) {
          return '${words.sublist(0, words.length - 1).join(' ')} ${_noun(loot, rng)}';
        }
        return 'The ${_noun(loot, rng)}';
      default:
        return '${_adj(loot, rng)} ${_noun(loot, rng)} ${_marks[rng.nextInt(_marks.length)]}';
    }
  }

  /// Deterministic 32-bit FNV-1a hash — Dart's String.hashCode is not
  /// stable across runs, so seeds must come from this instead.
  static int _stableHash(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0x7fffffff;
    }
    return h;
  }
}

/// Hand-written answer sets for iconic drops — three sets of five
/// plausible fakes per loot, mixed real names and thematic fakes.
/// Extensible: add an entry keyed by the exact item/gun name.
const Map<String, List<List<String>>> _kCuratedSets = {
  'Casey': [
    ["Slugger's Bat", 'Bat of the Blacksmith', 'Mahoguny',
        'The Louisville Lead', 'Homerun Hammer'],
    ["Winchester's Bat", 'The Bunt', 'Grand Slam', 'Slugger',
        'Bullet Bat'],
    ['Aluminium Avenger', 'The Strikeout', 'Bat of the Gungeoneer',
        'Ninth Inning', 'Curveball Cannon'],
  ],
  'Blasphemy': [
    ['Sacred Edge', 'Fightsabre', 'The Untouchable', 'Wood Sword',
        'Sinner\'s Blade'],
    ['The Blessed Blade', 'Stick of Truth', 'Old Reliable',
        'Plunger of Faith', 'Sacrifice Sabre'],
    ['Unbending Edge', 'The Sixth Sword', 'Broomstick', 'Holy Poker',
        'The Heretic'],
  ],
  'Gunther': [
    ['The Chatty Sidearm', 'Talking Pistol', 'Blabbergun', 'Dragunfire',
        'The Loyal One'],
    ['Friendship Cannon', 'The Companion', 'Mouthy Musket',
        'Trusty Talker', 'Old Chatterbox'],
    ['Sentient Sidearm', 'The Voice', 'Chattershooter', 'Pew-Talker',
        'Level-Headed'],
  ],
  'Yari Launcher': [
    ['Spear Volley', 'Hellfire Speargun', 'Javelin Jet', 'Mourning Star',
        'The Skewer'],
    ['Rapid Spears', 'Pike Pult', 'Lance-a-Lot', 'Ballistic Harpoon',
        'Searing Spray'],
    ['The Impaler', 'Doombringer', 'Rocket Javelin', 'Scorcher',
        'Triple Skewer'],
  ],
  'Spice': [
    ['Flavor Crystal', 'The Seasoning', 'Salt of the Gungeon',
        'Pepper Core', 'Rare Herb'],
    ['The Craving', 'Savory Shard', 'Cinnamon Relic', 'The Ingredient',
        'Sweet Nectar'],
    ['Melange', 'The Spice Flow', 'Golden Grain', 'Taste Bud',
        'Secret Sauce'],
  ],
  'Pig': [
    ['Battle Swine', 'Ham on Wheels', 'The Oinker', 'War Hog',
        'Pork Pal'],
    ['Sacrificial Swine', 'The Baconator', 'Loyal Piglet', 'Boar Buddy',
        'Sir Snorts'],
    ['Ham Familiar', 'The Tribute', 'Squealer', 'Pig of War',
        'Chunky Companion'],
  ],
  'Sixth Chamber': [
    ['The Seventh Seal', 'Final Chamber', 'Blessing of Kaliber',
        'The Last Room', 'Chamber Relic'],
    ['Seventh Chamber', 'The Chambered One', 'Kaliber\'s Gift',
        'Deep Chamber', 'The Countdown'],
    ['Chamber Idol', 'The Loading', 'Fifth Chamber', 'Chamber Charm',
        'Reward of the Deep'],
  ],
  'Clone': [
    ['The Duplicate', 'Second Self', 'Mirror Mimic', 'Carbon Copy',
        'The Echo'],
    ['Twin Token', 'Backup Gungeoneer', 'The Double', 'Spare Life',
        'Xerox Idol'],
    ['Doppelganger Drop', 'Another You', 'The Recycle', 'Extra Life',
        'Second Run'],
  ],
  'Super Meat Gun': [
    ['Meat Blaster', 'The Tenderizer', 'Sir Loin', 'Beef Cannon',
        'Sausage Shooter'],
    ['Bandage Blaster', 'The Meat Grinder', 'Steak Shot', 'Raw Repeater',
        'Flesh Volley'],
    ['Ham Hock Howitzer', 'The Carnivore', 'Meat Missile',
        'Brisket Buster', 'Protein Pack'],
  ],
  'Banana': [
    ['Peel Cannon', 'The Split', 'Monkey Wrench', 'Potassium Pipe',
        'Boomerang Blaster'],
    ['The Slipstream', 'Fruit Volley', 'Chiquita Charge', 'Peeler',
        'Ripe Repeater'],
    ['Yellow Jacket', 'The Bunch', 'Plantain Pistol', 'Smoothie Shooter',
        'Cannon Banana'],
  ],
  'Turtle Problem': [
    ['Shell Shock', 'The Slowdown', 'Terrapin Trouble', 'Snapper Squad',
        'Box Turtle'],
    ['Tiny Tortoises', 'The Stampede', 'Shell Swarm', 'Reptile Riot',
        'Pond Problem'],
    ['The Menagerie', 'Tortoise Trail', 'Baby Snappers', 'Shell Parade',
        'Slow Surge'],
  ],
  'Sunglasses': [
    ['Cool Shades', 'The Aviators', 'Sun Blockers', 'Stunner Shades',
        'Shutter Specs'],
    ['Deal-With-Its', 'The Blinds', 'Ray Blockers', 'Midnight Specs',
        'Flash Frames'],
    ['The Cooldown', 'Polarized Pair', 'Glamour Guards', 'Sun Specs',
        'The Squinters'],
  ],
  'Gunderfury': [
    ['The Grit', 'Level Ten', 'Experience Engine', 'Veteran Volley',
        'The Loyal Gun'],
    ['Growing Gun', 'The Evolver', 'Seasoned Sidearm', 'Rank-Up Rifle',
        'Fury of Ages'],
    ['The Apprentice', 'Mastery Musket', 'Leveled Launcher',
        'Old Faithful', 'The Graduate'],
  ],
  'Dragunfire': [
    ['Dragon\'s Breath', 'The Firebreather', 'Scale Cannon',
        'Ember Engine', 'The Wyrm'],
    ['Flame Volley', 'Kindled Cannon', 'The Scorcher', 'Ash Blaster',
        'Blaze Repeater'],
    ['Inferno Injector', 'The Afterburner', 'Smolder Shot',
        'Dragonspit', 'Fire Lance'],
  ],
  'Mourning Star': [
    ['The Eulogy', 'Falling Star', 'Dusk Repeater', 'Orbital Cannon',
        'Sky Burial'],
    ['Event Horizon', 'The Comet', 'Nova Launcher', 'Grieving Star',
        'The Meteor'],
    ['Starfall', 'Cosmic Wake', 'The Requiem', 'Funeral Volley',
        'Nightfall'],
  ],
  'Fightsabre': [
    ['The Glowblade', 'Light Foil', 'Jedi\'s Regret', 'Plasma Edge',
        'Laser Rapier'],
    ['Beam Sabre', 'The Duellist', 'Photon Fencer', 'Neon Katana',
        'The Parry'],
    ['Energy Edge', 'Saber of Light', 'The Elegant Weapon', 'Arc Foil',
        'Luminous Lance'],
  ],
  'Finished Gun': [
    ['The Incomplete', 'Almost Gun', 'The Final Piece', 'Last Gun',
        'Prototype Zero'],
    ['The Completed One', 'Unfinished Gun', 'The Blueprint', 'Whole Gun',
        'Missing Link'],
    ['The Apocrypha', 'Seventh Gun', 'The Unmade', 'Draft Cannon',
        'Final Draft'],
  ],
  'AU Gun': [
    ['The Formula', 'Gold Gun', 'X-Blade', 'Z Gun', 'The Letter'],
    ['Periodic Pistol', 'Element 79', 'The Equation', 'Killer Variable',
        'Au-79'],
    ['The Artifact', 'Bullion Blaster', 'Golden Ratio', 'Symbol Gun',
        'The Unknown'],
  ],
  'Crestfaller': [
    ['The Broken Sword', 'Fallen Blade', 'Pride Splitter', 'Ruined Edge',
        'Shattered Sabre'],
    ['Knight\'s Regret', 'The Defeated', 'Bonfire Blade', 'Ashen Edge',
        'Waning Sword'],
    ['Crown Splitter', 'The Beaten Path', 'Sundered Steel', 'Lost Blade',
        'Hope\'s End'],
  ],
  'Devolver': [
    ['The Reverse', 'Un-Evolver', 'Backwards Gun', 'The Devolution',
        'De-Evolver'],
    ['Regression Ray', 'The Reversal', 'Backward Blaster', 'Undo Gun',
        'Time Turner'],
    ['The Downgrade', 'Evolution Undoer', 'Reverse Gun', 'The Rewind',
        'Progress Ender'],
  ],
  'Magic Lamp': [
    ['The Genie Lamp', 'Three Wishes', 'Brass Lantern', 'Smoke Lamp',
        'Wishing Well'],
    ['The Ifrit', 'Aladdin\'s Relic', 'Djinn Bottle', 'Oil Lamp',
        'The Wish Granter'],
    ['Spirit Lamp', 'The Conjurer', 'Smoke Vessel', 'The Lantern',
        'Wishbone Lamp'],
  ],
  'Owl': [
    ['The Hooter', 'Night Watch', 'Feathered Friend', 'Barn Owl',
        'The Perch'],
    ['Silent Watcher', 'Talon Scout', 'The Lookout', 'Wise One',
        'Night Bird'],
    ['The Companion', 'Great Horned', 'Swoop', 'Feather Scout',
        'Hollow Owl'],
  ],
  'Phoenix': [
    ['The Rebirth', 'Ash Bird', 'Sunbird', 'Immortal Flame',
        'Pyre Phoenix'],
    ['Reborn Raptor', 'The Rising', 'Ember Wings', 'Solar Falcon',
        'Ashen Eagle'],
    ['Firebird', 'The Resurrected', 'Flame Fowl', 'Rising Sun',
        'Undying Bird'],
  ],
  'Shellegun': [
    ['Shell Shot', 'The Snail Gun', 'Casing Cannon', 'Exoskeleton',
        'Turret Tortoise'],
    ['Hermit Howitzer', 'The Carapace', 'Mollusk Mortar', 'Escargun',
        'Bunker Beast'],
    ['The Snail Trail', 'Conch Cannon', 'Shell Shield', 'Slow Roll',
        'Home on Back'],
  ],
  'Super Space Turtle': [
    ['Cosmic Tortoise', 'The Terrapin', 'Star Turtle', 'Orbit Shell',
        'Galaxy Guardian'],
    ['Space Shell', 'The Voyager', 'Astro Turtle', 'Comet Companion',
        'Void Terrapin'],
    ['The Slow Cosmonaut', 'Shelled Explorer', 'Turbo Turtle',
        'Moon Shell', 'Star Shell'],
  ],
  'Bundle of Wands': [
    ['The Sextet', 'Wand Collection', 'Six Shooter', 'Staff Bundle',
        'The Arsenal'],
    ['Wizard\'s Hoard', 'The Rainbow', 'Prismatic Pack', 'Wand Wheel',
        'Magic Quiver'],
    ['The Ensemble', 'Six of Wands', 'Spell Sampler', 'Coven Cache',
        'The Selection'],
  ],
  'Elimentaler': [
    ['The Element Gun', 'Periodic Blaster', 'Form Fuser', 'Matter Maker',
        'The Alchemist'],
    ['Element Cannon', 'Phase Pistol', 'The Transformer', 'Formulator',
        'Reaction Ray'],
    ['The Fabricator', 'Matter Mixer', 'State Changer', 'The Chemist',
        'Element Lab'],
  ],
  'Railgun': [
    ['The Accelerator', 'Magnet Cannon', 'Coil Driver', 'Slug Thrower',
        'Hypervelocity'],
    ['Gauss Cannon', 'The Linear', 'Rail Driver', 'Mag Blaster',
        'Ferro Launcher'],
    ['The Penetrator', 'Coil Cannon', 'Magnetic Musket', 'Slug Rail',
        'The Railer'],
  ],
  'Mimic Tooth Necklace': [
    ['False Teeth', 'The Deceiver', 'Maw Charm', 'Biter\'s Prize',
        'Chest Teeth'],
    ['The Imposter', 'Fool\'s Fang', 'Greedy Gnashers', 'Trap Jaw',
        'Mimic Bite'],
    ['The False Friend', 'Chomp Chain', 'Liar\'s Locket', 'Maw Medal',
        'Bait Pendant'],
  ],
  'Partially-Eaten Cheese': [
    ['The Leftover', 'Nibbled Wedge', 'Someone\'s Lunch', 'Half Ration',
        'Mouldy Morsel'],
    ['The Secondhand', 'Pre-Eaten', 'Rat\'s Share', 'Bitten Brie',
        'The Scrap'],
    ['Cheese Remains', 'The Nibbled', 'Gnawed Gold', 'Half-Eaten',
        'Leftover Loot'],
  ],
  'Unicorn Horn': [
    ['The Spiral', 'Alicorn', 'Rainbow Lance', 'Mythic Horn',
        'The Narwhal'],
    ['Magic Piercer', 'The Unicorn\'s Gift', 'Spiral Spear',
        'Glitter Horn', 'Fairy Lance'],
    ['The Pegasus', 'Horn of Purity', 'Rainbow Rapier', 'Starlight Pike',
        'The Majestic'],
  ],
};
