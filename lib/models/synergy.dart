import '../utils/asset_paths.dart';
import 'rich_text.dart';

class Synergy {
  final String name;
  final List<String> items;

  /// Alternatives: the synergy additionally requires at least ONE of these
  /// to be in the inventory. Empty for plain N-of-N synergies.
  final List<String> anyOf;

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
    this.effect = '',
    this.icon = '',
    this.effectTokens = const [],
  });

  factory Synergy.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    return Synergy(
      name: name,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      anyOf: (json['any_of'] as List<dynamic>?)
              ?.map((e) => e.toString())
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
      'effect': effect,
      'icon': icon,
    };
  }

  /// All required items present, AND (if any_of exists) at least one
  /// alternative present.
  bool matchesItems(List<String> itemNames) {
    final owned = itemNames.map((n) => n.toLowerCase()).toSet();

    // Special cases for synergies with empty required items list:
    if (name == 'Smart Bombs' || name == 'Unbelievably Charming') {
      final matchesCount = anyOf.where((i) => owned.contains(i.toLowerCase())).length;
      return matchesCount >= 2;
    }
    if (name == 'Super Serum') {
      final hasGuns = owned.contains('plague pistol') || owned.contains('plunger');
      final hasDefense = owned.contains('gas mask') || owned.contains('hazmat suit');
      return hasGuns && hasDefense;
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
    final isPrefixOnly = lower.startsWith('one of the following') ||
        lower.startsWith('any of the following');
    if (!isPrefixOnly) return raw;
    // Reformat alternatives as a clean human-readable list. We don't try
    // to invent the per-combination effect text — that information isn't
    // in the wiki's synergy table, it lives on each item's own page.
    final alts = anyOf;
    final joined = alts.length == 1
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
    final missing = items
        .where((i) => !ownedLower.contains(i.toLowerCase()))
        .toList();
    if (anyOf.isNotEmpty) {
      final anySatisfied =
          anyOf.any((i) => ownedLower.contains(i.toLowerCase()));
      if (!anySatisfied) {
        // Show the alternatives as a single "one of" entry.
        missing.add('any of: ${anyOf.take(3).join(", ")}'
            '${anyOf.length > 3 ? "…" : ""}');
      }
    }
    return missing;
  }
}
