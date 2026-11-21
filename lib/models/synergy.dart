import '../utils/asset_paths.dart';
import 'rich_text.dart';

class Synergy {
  final String name;
  final List<String> items;

  /// Alternatives: the synergy additionally requires at least ONE of these
  /// to be in the inventory. Empty for plain N-of-N synergies.
  final List<String> anyOf;

  /// AND-of-OR groups: each inner list needs at least one owned member,
  /// and EVERY group must be satisfied. Used for synergies the flat
  /// items+anyOf model can't express (e.g. Smart Bombs = (Bomb|Ice Bomb)
  /// AND (Crutch|Homing Bullets)). When non-empty it takes precedence over
  /// items/anyOf for matching; items/anyOf still carry the flattened
  /// union so piece icons and entity lookups keep working.
  final List<List<String>> groups;

  final String effect;
  final String icon;

  /// Pre-tokenised effect text with cross-links resolved against master
  /// data. Populated by `parse_wiki_rich.py`. Empty list if absent so the
  /// renderer can fall back to plain `effect`.
  final List<RichToken> effectTokens;

  Synergy({
    required this.name,
    required this.items,
    this.anyOf = const [],
    this.groups = const [],
    this.effect = '',
    this.icon = '',
    this.effectTokens = const [],
  });

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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'items': items,
      if (anyOf.isNotEmpty) 'any_of': anyOf,
      if (groups.isNotEmpty) 'groups': groups,
      'effect': effect,
      'icon': icon,
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
    return anyOf.any((i) => owned.contains(i.toLowerCase()));
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
    return 'Activates with one of: $joined.';
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
      final anySatisfied = anyOf.any(
        (i) => ownedLower.contains(i.toLowerCase()),
      );
      if (!anySatisfied) {
        // Show the alternatives as a single "one of" entry.
        missing.add(
          'any of: ${anyOf.take(3).join(", ")}'
          '${anyOf.length > 3 ? "…" : ""}',
        );
      }
    }
    return missing;
  }
}
