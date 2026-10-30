import 'dart:math';

import 'package:flutter/material.dart';

import '../models/gun.dart';
import '../models/item.dart';
part 'quiz/quiz_data.dart';

QuizChestTier quizTierFor(String quality) => kQuizAllTiers.firstWhere(
  (t) => t.id == quality,
  orElse: () => kQuizAllTiers.first,
);

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
  int gunsForTier(QuizChestTier tier) => tier.poolQualities.fold(
    0,
    (sum, q) => sum + (_gunNamesByTier[q]?.length ?? 0),
  );

  /// Item count inside a tier's pool.
  int itemsForTier(QuizChestTier tier) => tier.poolQualities.fold(
    0,
    (sum, q) => sum + (_itemNamesByTier[q]?.length ?? 0),
  );

  /// Number of hand-curated distractor sets — test hook + stats.
  int get curatedSetCount => _kCuratedSets.length;

  /// A fresh shuffled loot pool for one chest run. The session draws
  /// from this list in order — no repeats inside a single run.
  List<QuizLoot> poolFor(String quality, {Random? rng}) {
    final pool = List<QuizLoot>.of(
      _poolByTier[quality.toUpperCase()] ?? const <QuizLoot>[],
    );
    pool.shuffle(rng ?? Random());
    return pool;
  }

  /// A fresh shuffled loot pool for a chest — mixes all of its
  /// [QuizChestTier.poolQualities] for bonus chests.
  List<QuizLoot> poolForTier(QuizChestTier tier, {Random? rng}) {
    final pool = <QuizLoot>[
      for (final q in tier.poolQualities) ...?_poolByTier[q.toUpperCase()],
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
    return [for (var i = 0; i < 3; i++) _buildSet(loot, rng, used)];
  }

  /// Assembles one set of five distractors: up to three real names from
  /// the same tier (same kind preferred), filled out with fabrications.
  List<String> _buildSet(QuizLoot loot, Random rng, Set<String> used) {
    final out = <String>[];

    final sameKind = List<String>.of(
      (loot.isGun ? _gunNamesByTier : _itemNamesByTier)[loot.quality] ??
          const <String>[],
    )..shuffle(rng);
    final crossKind = List<String>.of(
      (loot.isGun ? _itemNamesByTier : _gunNamesByTier)[loot.quality] ??
          const <String>[],
    )..shuffle(rng);

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
    'Rusted',
    'Gilded',
    'Hollow',
    'Cursed',
    'Blessed',
    'Molten',
    'Frozen',
    'Brass',
    'Chrome',
    'Leaden',
    'Ancient',
    'Forsaken',
    'Jammed',
    'Grim',
    'Silent',
    'Swift',
    'Heavy',
    'Blasphemous',
    'Copper',
    'Void-Touched',
  ];
  static const _gunNouns = <String>[
    'Blaster',
    'Carbine',
    'Revolver',
    'Cannon',
    'Repeater',
    'Longshot',
    'Scattergun',
    'Wand',
    'Pistol',
    'Rifle',
    'Launcher',
    'Sidearm',
    'Musket',
    'Volley',
    'Raildriver',
    'Bore',
  ];
  static const _itemNouns = <String>[
    'Idol',
    'Relic',
    'Charm',
    'Core',
    'Engine',
    'Boots',
    'Cape',
    'Ring',
    'Heart',
    'Skull',
    'Fang',
    'Eye',
    'Tonic',
    'Ration',
    'Coupon',
    'Map',
    'Key',
    'Medal',
    'Sack',
    'Gland',
  ];
  static const _owners = <String>[
    'Bello',
    'Cadence',
    'Ox',
    'Frifle',
    'Winchester',
    'Doug',
    'Ser Manuel',
    'Ledge',
    'Blobby',
    'Tinker',
    'Old Red',
    'Albern',
    'Norwich',
    'Daisuke',
  ];
  static const _places = <String>[
    'the Forge',
    'the Hollow',
    'the Keep',
    'the Mine',
    'the Abbey',
    'Bullet Hell',
    'the Breach',
    'the Oubliette',
    'the Fifth Chamber',
  ];
  static const _marks = <String>['MK.II', 'MK.III', 'MK.IV'];

  /// Theme-tinted adjectives, picked when the loot's lore matches a
  /// keyword family — makes fakes feel crafted rather than generic.
  static const _themeAdjs = <String, List<String>>{
    'fire|burn|flame|dragun|molten|incendiary|explosive': [
      'Ember',
      'Pyre',
      'Scorching',
      'Blazing',
      'Furnace',
      'Incendiary',
    ],
    'ice|frost|freeze|cold|glacier|snow|chill': [
      'Frozen',
      'Glacial',
      'Arctic',
      'Shivering',
      'Cryo',
      'Wintry',
    ],
    'poison|venom|toxic|acid|plague': [
      'Venomous',
      'Caustic',
      'Virulent',
      'Noxious',
      'Festering',
    ],
    'electric|shock|spark|thunder|lightning|volt|tesla|coil': [
      'Charged',
      'Voltaic',
      'Galvanic',
      'Static',
      'Surging',
    ],
    'beam|laser|light|prism|radiant|photon|luminous': [
      'Luminous',
      'Prismatic',
      'Radiant',
      'Coherent',
      'Reflected',
    ],
    'rocket|grenade|bomb|missile|blast|explode': [
      'Blast',
      'Demolition',
      'Breaching',
      'Volatile',
      'Heavy',
    ],
    'sword|blade|bat|saber|melee|slash|katana': [
      'Tempered',
      'Keen',
      'Dueling',
      'Whetted',
      'Singing',
    ],
    'magic|wand|charm|arcane|spell|rune|crystal|hex': [
      'Arcane',
      'Runic',
      'Eldritch',
      'Mystic',
      'Hallowed',
    ],
    'companion|familiar|pet|turtle|pig|owl|dog|friend': [
      'Loyal',
      'Tamed',
      'Kindred',
      'Faithful',
      'Trusted',
    ],
    'heal|health|heart|regen|life|restore|armor|shield': [
      'Vital',
      'Mending',
      'Restorative',
      'Aegis',
      'Bulwark',
    ],
    'ammo|bullet|shot|shell|reload|magazine|clip': [
      'Loaded',
      'Brass-Jacketed',
      'Full-Metal',
      'Hollow-Point',
    ],
    'curse|jammed|demon|dark|void|shadow|ghost|spirit': [
      'Cursed',
      'Forsaken',
      'Umbral',
      'Hollow',
      'Whispered',
    ],
    'mimic|chest|key|lock|coin|shop|sell|price|hegemony': [
      'Mimic',
      'Gilded',
      'Miserly',
      'Coveted',
      'Hoarded',
    ],
    'roll|dodge|speed|fast|quick|agile|dash': [
      'Swift',
      'Nimble',
      'Fleet',
      'Rolling',
      'Quickdraw',
    ],
    'synergy|combo|link|chain': ['Twinned', 'Linked', 'Chained', 'Resonant'],
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
