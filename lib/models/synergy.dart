import '../utils/asset_paths.dart';
import 'rich_text.dart';

class Synergy {
  final String name;
  final List<String> items;

  /// Alternatives pool: at least [requiredAnyOfCount] members of this
  /// list must be owned. Defaults to 1 (classic "one of" branch); K-of-N
  /// synergies (In The Mood! = 2 of 3 guns, The Void Corps = 2 of 3)
  /// set `any_of_min` in JSON.
  final List<String> anyOf;

  /// Minimum number of [anyOf] members required. Null = 1 (or 0 when
  /// [anyOf] is empty).
  final int? anyOfMin;

  /// AND-of-OR groups: each inner list needs at least one owned member,
  /// and EVERY group must be satisfied. Used for synergies the flat
  /// items+anyOf model can't express (e.g. Smart Bombs = (Bomb|Ice Bomb)
  /// AND (Crutch|Homing Bullets)). When non-empty it takes precedence over
  /// items/anyOf for matching; items/anyOf still carry the flattened
  /// union so piece icons and entity lookups keep working.
  final List<List<String>> groups;

  final String effect;
  final String icon;

  /// Game-reported activation state from `gungeon_dump.json`
  /// (`ACTIVE`, `ACTIVE_UNBOOSTED`, `INACTIVE`). `INACTIVE` entries are
  /// cut/disabled content that never triggers in game.
  final String activation;

  /// Pre-tokenised effect text with cross-links resolved against master
  /// data. Populated by `parse_wiki_rich.py`. Empty list if absent so the
  /// renderer can fall back to plain `effect`.
  final List<RichToken> effectTokens;

  Synergy({
    required this.name,
    required this.items,
    this.anyOf = const [],
    this.anyOfMin,
    this.groups = const [],
    this.effect = '',
    this.icon = '',
    this.effectTokens = const [],
    this.activation = 'ACTIVE',
  });

  /// True when the game ships this synergy as disabled content — it can
  /// never activate, so queries treat it as absent.
  bool get isGameInactive => activation == 'INACTIVE';

  /// How many [anyOf] members must be owned (defaults to 1).
  int get requiredAnyOfCount => anyOfMin ?? (anyOf.isEmpty ? 0 : 1);

  factory Synergy.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    return Synergy(
      name: name,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      anyOf:
          (json['any_of'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      anyOfMin: json['any_of_min'] as int?,
      groups:
          (json['groups'] as List<dynamic>?)
              ?.map(
                (g) => (g as List<dynamic>).map((e) => e.toString()).toList(),
              )
              .toList() ??
          const [],
      effect: json['effect'] ?? '',
      icon: localSynergyIcon(name),
      effectTokens: parseSynergyEffectTokens(json['effect_tokens']),
      activation: json['activation'] as String? ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'items': items,
      if (anyOf.isNotEmpty) 'any_of': anyOf,
      if (anyOfMin != null) 'any_of_min': anyOfMin,
      if (groups.isNotEmpty) 'groups': groups,
      'effect': effect,
      'icon': icon,
      if (activation != 'ACTIVE') 'activation': activation,
    };
  }

  /// All required items present, AND (if any_of exists) at least one
  /// alternative present.
  bool matchesItems(List<String> itemNames) =>
      matchesOwnedSet(itemNames.map((n) => n.toLowerCase()).toSet());

  /// Set-based variant for hot paths (browse list builders) — the caller
  /// supplies a precomputed lowercase ownership set instead of paying a
  /// `toSet()` allocation per call.
  bool matchesOwnedSet(Set<String> owned) {
    // AND-of-OR groups take precedence — each group needs ≥1 owned member.
    if (groups.isNotEmpty) {
      return groups.every(
        (g) => g.any((i) => owned.contains(i.toLowerCase())),
      );
    }

    final allRequired = items.every((i) => owned.contains(i.toLowerCase()));
    if (!allRequired) return false;
    if (anyOf.isEmpty) return true;
    final ownedAnyOf = anyOf.where((i) => owned.contains(i.toLowerCase()));
    return ownedAnyOf.length >= requiredAnyOfCount;
  }

  /// Reformats the raw `effect` field into something readable when the
  /// upstream wiki cell collapsed to "One of the following: A B C" with
  /// no real separator (the parser flattens nested alternatives inline,
  /// see docs/SYNERGIES_FIX_PLAN.md). When `any_of` is populated and the
  /// effect text is just the boilerplate prefix + concatenated names,
  /// substitute a comma/or-joined version that survives the round-trip.
  /// Otherwise return the original effect verbatim.
  String get prettyEffect {
    final raw = effect.trim();
    if (raw.isEmpty || anyOf.isEmpty) return raw;
    final lower = raw.toLowerCase();
    final isPrefixOnly =
        lower.startsWith('one of the following') ||
        lower.startsWith('any of the following');
    if (!isPrefixOnly) return raw;
    // Reformat alternatives as a clean human-readable list. We don't try
    // to invent the per-combination effect text — that information isn't
    // in the wiki's synergy table, it lives on each item's own page.
    final alts = anyOf;
    final joined =
        alts.length == 1
            ? alts.first
            : alts.length == 2
            ? '${alts[0]} or ${alts[1]}'
            : '${alts.take(alts.length - 1).join(", ")} or ${alts.last}';
    final need = requiredAnyOfCount;
    return need > 1
        ? 'Activates with any $need of: $joined.'
        : 'Activates with one of: $joined.';
  }

  /// Returns the list of item names that are still missing to activate
  /// this synergy, given the current inventory. For `any_of` synergies,
  /// returns only ONE representative missing alternative (the first one).
  List<String> missingFor(Set<String> ownedLower) {
    if (groups.isNotEmpty) {
      return [
        for (final g in groups)
          if (!g.any((i) => ownedLower.contains(i.toLowerCase())))
            g.length == 1 ? g.first : 'any of: ${g.join(", ")}',
      ];
    }
    final missing =
        items.where((i) => !ownedLower.contains(i.toLowerCase())).toList();
    if (anyOf.isNotEmpty) {
      final ownedAnyOf =
          anyOf.where((i) => ownedLower.contains(i.toLowerCase())).length;
      final deficit = requiredAnyOfCount - ownedAnyOf;
      if (deficit > 0) {
        // K-of-N pools show how many more picks are needed; classic
        // "one of" pools keep the original phrasing.
        final unowned = anyOf
            .where((i) => !ownedLower.contains(i.toLowerCase()))
            .toList();
        final label = deficit == 1 ? 'any of' : 'any $deficit of';
        missing.add(
          '$label: ${unowned.take(3).join(", ")}'
          '${unowned.length > 3 ? "…" : ""}',
        );
      }
    }
    return missing;
  }
}
