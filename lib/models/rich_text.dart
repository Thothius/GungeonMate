/// Rich-text token model produced by `parse_wiki_rich.py`.
///
/// The Python extractor walks each cached wiki page and emits the bullet
/// content of Effects / Item Interactions / Notes / Trivia / Tips sections
/// as a forest of [RichBullet]s, where each bullet's `tokens` is a flat
/// run of [RichToken]s. Cross-links to other items, guns, characters,
/// shrines and stat pages have already been resolved server-side, so the
/// app only needs to *render* — no runtime parsing.
library;

import 'dart:convert';

/// What an internal `/wiki/X` link resolved to.
///
/// `unresolved` links render as plain text (we don't have a destination).
/// `lore` links are recognised game-system pages (e.g. "Goop", "Bullet Kin")
/// that have no in-app screen — they still render distinctly so the user
/// sees they're "real" references, just not navigable.
enum RefKind { item, gun, character, shrine, stat, lore, unresolved }

RefKind _kindFromString(String? s) {
  switch (s) {
    case 'item':
      return RefKind.item;
    case 'gun':
      return RefKind.gun;
    case 'character':
      return RefKind.character;
    case 'shrine':
      return RefKind.shrine;
    case 'stat':
      return RefKind.stat;
    case 'lore':
      return RefKind.lore;
    default:
      return RefKind.unresolved;
  }
}

/// Inline style flag attached to a text run.
enum TextStyleFlag { plain, italic, code }

TextStyleFlag _styleFromString(String? s) {
  switch (s) {
    case 'i':
      return TextStyleFlag.italic;
    case 'code':
      return TextStyleFlag.code;
    default:
      return TextStyleFlag.plain;
  }
}

// =============================================================================
// Token types
// =============================================================================

sealed class RichToken {
  const RichToken();

  factory RichToken.fromJson(Map<String, dynamic> j) {
    final t = j['t'];
    switch (t) {
      case 'text':
        return RichTextRun(
          (j['v'] ?? '').toString(),
          style: _styleFromString(j['style'] as String?),
        );
      case 'ref':
        return RichRef(
          (j['v'] ?? '').toString(),
          _kindFromString(j['kind'] as String?),
        );
      case 'synref':
        return RichSynRef((j['v'] ?? '').toString());
      case 'ext':
        return RichExt(
          label: (j['v'] ?? '').toString(),
          url: (j['url'] ?? '').toString(),
        );
      default:
        // Unknown token kind — degrade to plain text so we never break
        // rendering for a future schema bump.
        return RichTextRun((j['v'] ?? '').toString());
    }
  }
}

class RichTextRun extends RichToken {
  final String text;
  final TextStyleFlag style;
  const RichTextRun(this.text, {this.style = TextStyleFlag.plain});
}

class RichRef extends RichToken {
  /// Display name (already canonicalised against our master data).
  final String name;
  final RefKind kind;
  const RichRef(this.name, this.kind);

  /// Whether this ref maps to an in-app destination (item/gun/character/
  /// shrine/stat detail screen). `lore` and `unresolved` do not.
  bool get isNavigable =>
      kind == RefKind.item ||
      kind == RefKind.gun ||
      kind == RefKind.character ||
      kind == RefKind.shrine ||
      kind == RefKind.stat;
}

class RichSynRef extends RichToken {
  final String synergyName;
  const RichSynRef(this.synergyName);
}

class RichExt extends RichToken {
  final String label;
  final String url;
  const RichExt({required this.label, required this.url});
}

// =============================================================================
// Bullet tree
// =============================================================================

/// A single bullet point. Has a flat token list and optional sub-bullets
/// rendered as a nested list (used for the "Has the following effects on
/// use:" → indented list pattern common in wiki Effects sections).
class RichBullet {
  final List<RichToken> tokens;
  final List<RichBullet> sub;

  const RichBullet({this.tokens = const [], this.sub = const []});

  factory RichBullet.fromJson(Map<String, dynamic> j) {
    return RichBullet(
      tokens: ((j['tokens'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((t) => RichToken.fromJson(t))
          .toList(growable: false),
      sub: ((j['sub'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((s) => RichBullet.fromJson(s))
          .toList(growable: false),
    );
  }

  /// True if this bullet has neither tokens nor non-empty sub-bullets.
  bool get isEmpty {
    if (tokens.any((t) {
      if (t is RichTextRun) return t.text.trim().isNotEmpty;
      return true;
    })) {
      return false;
    }
    return sub.every((b) => b.isEmpty);
  }
}

List<RichBullet> _parseBulletList(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map((b) => RichBullet.fromJson(b))
      .where((b) => !b.isEmpty)
      .toList(growable: false);
}

// =============================================================================
// Wiki content per entity
// =============================================================================

/// The full set of rich wiki sections for a single gun/item, parsed from
/// the `wiki` field added to guns.json and items.json by `parse_wiki_rich.py`.
class WikiContent {
  final List<RichBullet> effects;
  final List<RichBullet> interactions;
  final List<RichBullet> notes;
  final List<RichBullet> tips;
  final List<RichBullet> trivia;

  const WikiContent({
    this.effects = const [],
    this.interactions = const [],
    this.notes = const [],
    this.tips = const [],
    this.trivia = const [],
  });

  static const empty = WikiContent();

  bool get hasAny =>
      effects.isNotEmpty ||
      interactions.isNotEmpty ||
      notes.isNotEmpty ||
      tips.isNotEmpty ||
      trivia.isNotEmpty;

  factory WikiContent.fromJson(Map<String, dynamic>? j) {
    if (j == null) return WikiContent.empty;
    return WikiContent(
      effects: _parseBulletList(j['effects']),
      interactions: _parseBulletList(j['item_interactions']),
      notes: _parseBulletList(j['notes']),
      tips: _parseBulletList(j['tips']),
      trivia: _parseBulletList(j['trivia']),
    );
  }
}

// =============================================================================
// Synergy effect tokens (top-level helper for synergies.json)
// =============================================================================

/// Parse the `effect_tokens` array on a synergy (added by
/// `parse_wiki_rich.py`). Returns an empty list if missing.
List<RichToken> parseSynergyEffectTokens(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map((t) => RichToken.fromJson(t))
      .toList(growable: false);
}

// =============================================================================
// Back-refs index (loaded once at startup from back_refs.json)
// =============================================================================

class BackRefs {
  /// Map from entity name → list of entities (items+guns) whose wiki
  /// notes/trivia/etc reference it. Sorted alphabetically by the
  /// extractor; we preserve that order.
  final Map<String, List<String>> itemToReferrers;

  /// Map from synergy name → list of items+guns that mention it.
  final Map<String, List<String>> synergyToReferrers;

  const BackRefs({
    this.itemToReferrers = const {},
    this.synergyToReferrers = const {},
  });

  static const empty = BackRefs();

  /// Get the back-ref list for [name] (case-insensitive lookup against the
  /// canonical key). Returns an empty list if no entries.
  List<String> referrersFor(String name) {
    final exact = itemToReferrers[name];
    if (exact != null) return exact;
    // Fall back to a case-insensitive scan (rare path)
    final lower = name.toLowerCase();
    for (final entry in itemToReferrers.entries) {
      if (entry.key.toLowerCase() == lower) return entry.value;
    }
    return const [];
  }

  factory BackRefs.fromJsonString(String src) {
    final m = json.decode(src) as Map<String, dynamic>;
    Map<String, List<String>> bucket(String key) {
      final raw = m[key];
      if (raw is! Map) return const {};
      return raw.map((k, v) => MapEntry(
            k.toString(),
            (v as List).map((e) => e.toString()).toList(growable: false),
          ));
    }

    return BackRefs(
      itemToReferrers: bucket('item_to_referrers'),
      synergyToReferrers: bucket('synergy_to_referrers'),
    );
  }
}
