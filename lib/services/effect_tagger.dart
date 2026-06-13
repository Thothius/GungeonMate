import 'package:flutter/material.dart';
import '../models/gun.dart';
import '../models/item.dart';

/// High-level bucket for grouping tags on screen.
enum EffectCategory {
  mobility,
  damage,
  ammo,
  defense,
  economy,
  utility,
  status,
  debuff,
}

extension EffectCategoryMeta on EffectCategory {
  String get label {
    switch (this) {
      case EffectCategory.mobility:
        return 'Mobility';
      case EffectCategory.damage:
        return 'Damage';
      case EffectCategory.ammo:
        return 'Ammo & Reload';
      case EffectCategory.defense:
        return 'Defense';
      case EffectCategory.economy:
        return 'Economy & Loot';
      case EffectCategory.utility:
        return 'Utility';
      case EffectCategory.status:
        return 'Status';
      case EffectCategory.debuff:
        return 'Debuffs';
    }
  }

  IconData get icon {
    switch (this) {
      case EffectCategory.mobility:
        return Icons.directions_run;
      case EffectCategory.damage:
        return Icons.flash_on;
      case EffectCategory.ammo:
        return Icons.settings_backup_restore;
      case EffectCategory.defense:
        return Icons.shield_outlined;
      case EffectCategory.economy:
        return Icons.attach_money;
      case EffectCategory.utility:
        return Icons.auto_awesome;
      case EffectCategory.status:
        return Icons.bolt;
      case EffectCategory.debuff:
        return Icons.warning_amber;
    }
  }

  Color get color {
    switch (this) {
      case EffectCategory.mobility:
        return Colors.cyanAccent;
      case EffectCategory.damage:
        return Colors.orangeAccent;
      case EffectCategory.ammo:
        return Colors.amberAccent;
      case EffectCategory.defense:
        return Colors.lightGreenAccent;
      case EffectCategory.economy:
        return Colors.yellowAccent;
      case EffectCategory.utility:
        return Colors.lightBlueAccent;
      case EffectCategory.status:
        return Colors.purpleAccent;
      case EffectCategory.debuff:
        return Colors.redAccent;
    }
  }
}

/// A single recognized effect. Shared instances compared by [id].
@immutable
class EffectTag {
  final String id;
  final String label;
  final String blurb;
  final IconData icon;
  final EffectCategory category;

  /// Regex patterns. Case-insensitive match against effect/notes text.
  final List<RegExp> patterns;

  const EffectTag({
    required this.id,
    required this.label,
    required this.blurb,
    required this.icon,
    required this.category,
    required this.patterns,
  });

  @override
  bool operator ==(Object other) => other is EffectTag && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

/// One evidence of a tag — which source item produced it and, when we
/// can extract it, the sentence fragment from the source's effect /
/// notes text that triggered the match. The excerpt is what lets the
/// UI show the *real* wiki numbers (e.g. "+30% damage", "60% chance
/// to freeze") instead of just the category label.
@immutable
class EffectOccurrence {
  final EffectTag tag;
  final String sourceName;
  final bool sourceIsGun;

  /// Short sentence fragment pulled from the source text around the
  /// matched pattern. Empty when nothing meaningful could be isolated.
  final String excerpt;

  const EffectOccurrence({
    required this.tag,
    required this.sourceName,
    required this.sourceIsGun,
    this.excerpt = '',
  });
}

class EffectTagger {
  EffectTagger._();

  // ---- Tag registry (ordered; first match wins per text chunk for some) ----

  static RegExp _re(String p) => RegExp(p, caseSensitive: false);

  static final List<EffectTag> _all = [
    // ======== MOBILITY ========
    EffectTag(
      id: 'flight',
      label: 'Flight',
      blurb: 'Immune to pits and floor hazards',
      icon: Icons.air,
      category: EffectCategory.mobility,
      patterns: [_re(r'grants? flight'), _re(r'gains? flight'), _re(r'\bflight\b')],
    ),
    EffectTag(
      id: 'speed_up',
      label: 'Move speed ↑',
      blurb: 'Moves faster',
      icon: Icons.speed,
      category: EffectCategory.mobility,
      patterns: [
        _re(r'increase[sd]? .{0,20}movement speed'),
        _re(r'\+\s*\d+%?\s*movement speed'),
        _re(r'faster movement'),
      ],
    ),
    EffectTag(
      id: 'dodge_up',
      label: 'Dodge roll ↑',
      blurb: 'Faster / longer dodge roll',
      icon: Icons.replay,
      category: EffectCategory.mobility,
      patterns: [
        _re(r'increase[sd]? dodge roll'),
        _re(r'dodge roll (distance|speed|range).* increase'),
        _re(r'longer dodge roll'),
      ],
    ),
    EffectTag(
      id: 'shoot_while_rolling',
      label: 'Shoot while rolling',
      blurb: 'Can fire during dodge roll',
      icon: Icons.swipe_up,
      category: EffectCategory.mobility,
      patterns: [_re(r'shoot while (dodge )?rolling')],
    ),

    // ======== DAMAGE ========
    EffectTag(
      id: 'damage_up',
      label: 'Damage ↑',
      blurb: 'Deals more damage',
      icon: Icons.trending_up,
      category: EffectCategory.damage,
      patterns: [
        _re(r'increase[sd]? (bullet )?damage(?! (taken|resistance))'),
        _re(r'doubles? (the )?damage'),
        _re(r'deal(s)? (more|double) damage'),
        _re(r'\+\s*\d+%?\s*damage'),
      ],
    ),
    EffectTag(
      id: 'fire_rate_up',
      label: 'Fire rate ↑',
      blurb: 'Shoots faster',
      icon: Icons.speed,
      category: EffectCategory.damage,
      patterns: [
        _re(r'increase[sd]? (rate of fire|fire rate)'),
        _re(r'fires? faster'),
        _re(r'increased rate of fire'),
      ],
    ),
    EffectTag(
      id: 'piercing',
      label: 'Piercing',
      blurb: 'Bullets pierce enemies',
      icon: Icons.arrow_forward,
      category: EffectCategory.damage,
      patterns: [_re(r'\bpiercing\b'), _re(r'bullets? pierce')],
    ),
    EffectTag(
      id: 'bouncing',
      label: 'Bouncing',
      blurb: 'Bullets bounce off walls',
      icon: Icons.sync_alt,
      category: EffectCategory.damage,
      patterns: [_re(r'\bbouncing\b'), _re(r'bullets? bounce')],
    ),
    EffectTag(
      id: 'homing',
      label: 'Homing',
      blurb: 'Bullets track enemies',
      icon: Icons.gps_fixed,
      category: EffectCategory.damage,
      patterns: [_re(r'\bhoming\b'), _re(r'homes? in on enemies')],
    ),
    EffectTag(
      id: 'explosive',
      label: 'Explosive',
      blurb: 'Rounds explode',
      icon: Icons.local_fire_department,
      category: EffectCategory.damage,
      patterns: [
        _re(r'\bexplod(e|es|ing)\b'),
        _re(r'\bexplosive\b'),
        _re(r'bullets?.* explod'),
      ],
    ),
    EffectTag(
      id: 'crit',
      label: 'Crit chance',
      blurb: 'Chance for critical hits',
      icon: Icons.star_border,
      category: EffectCategory.damage,
      patterns: [_re(r'\bcritic(al|al hit)\b'), _re(r'\bcrit(s)?\b')],
    ),
    EffectTag(
      id: 'freeze',
      label: 'Freeze chance',
      blurb: 'Chance to freeze enemies',
      icon: Icons.ac_unit,
      category: EffectCategory.damage,
      patterns: [_re(r'freeze[s]? enemies'), _re(r'chance to freeze')],
    ),
    EffectTag(
      id: 'poison',
      label: 'Poison chance',
      blurb: 'Chance to poison enemies',
      icon: Icons.science,
      category: EffectCategory.damage,
      patterns: [_re(r'\bpoison\b')],
    ),
    EffectTag(
      id: 'burn',
      label: 'Burn chance',
      blurb: 'Chance to ignite enemies',
      icon: Icons.whatshot,
      category: EffectCategory.damage,
      patterns: [
        _re(r'\bignite\b'),
        _re(r'\bburn(s|ing)?\b'),
        _re(r'burning bullets?'),
        _re(r'sets? .* on fire'),
      ],
    ),
    EffectTag(
      id: 'stun',
      label: 'Stun chance',
      blurb: 'Stuns or briefly stops enemies',
      icon: Icons.bolt_outlined,
      category: EffectCategory.damage,
      patterns: [
        _re(r'\bstun[s]?\b'),
        _re(r'briefly stops? enemies'),
      ],
    ),
    EffectTag(
      id: 'knockback',
      label: 'Knockback ↑',
      blurb: 'Pushes enemies back harder',
      icon: Icons.open_in_new,
      category: EffectCategory.damage,
      patterns: [_re(r'increase[sd]? knockback'), _re(r'\+\s*\d+%?\s*knockback')],
    ),

    // ======== AMMO / RELOAD ========
    EffectTag(
      id: 'ammo_up',
      label: 'Max ammo ↑',
      blurb: 'Larger ammo pools',
      icon: Icons.battery_full,
      category: EffectCategory.ammo,
      patterns: [
        _re(r'increase[sd]? (maximum )?ammo'),
        _re(r'increase[sd]? magazine'),
        _re(r'\+\s*\d+%?\s*max(imum)? ammo'),
        _re(r'larger magazine'),
      ],
    ),
    EffectTag(
      id: 'reload_up',
      label: 'Reload speed ↑',
      blurb: 'Reloads faster',
      icon: Icons.refresh,
      category: EffectCategory.ammo,
      patterns: [
        _re(r'faster reload'),
        _re(r'reload speed.* increase'),
        _re(r'instantly reloads?'),
        _re(r'reloads? instantly'),
      ],
    ),
    EffectTag(
      id: 'free_ammo',
      label: 'Ammo drops',
      blurb: 'Chance to get free ammo',
      icon: Icons.card_giftcard,
      category: EffectCategory.ammo,
      patterns: [
        _re(r'chance to (spawn|drop|regain) ammo'),
        _re(r'refill[s]? (the )?gun'),
        _re(r'ammo pickup'),
        _re(r'spawns? ammo'),
      ],
    ),

    // ======== DEFENSE ========
    EffectTag(
      id: 'max_hp_up',
      label: 'Max HP ↑',
      blurb: 'Extra heart container',
      icon: Icons.favorite,
      category: EffectCategory.defense,
      patterns: [
        _re(r'grants? (a |an |one |two )?heart container'),
        _re(r'heart container'),
        _re(r'increase[sd]? max(imum)? (hp|health)'),
      ],
    ),
    EffectTag(
      id: 'armor',
      label: 'Armor',
      blurb: 'Starts with / grants armor',
      icon: Icons.shield,
      category: EffectCategory.defense,
      patterns: [
        _re(r'grants? (a |one |two |a piece of )?armor'),
        _re(r'piece of armor'),
        _re(r'\+\s*\d+\s*armor'),
        _re(r'chance to get armor'),
      ],
    ),
    EffectTag(
      id: 'heal',
      label: 'Healing',
      blurb: 'Restores health on trigger',
      icon: Icons.favorite_border,
      category: EffectCategory.defense,
      patterns: [
        _re(r'heal[s]? the player'),
        _re(r'heals? (half )?a? heart'),
        _re(r'restore[s]? health'),
        _re(r'heal[s]? on kill'),
        _re(r'chance to get hearts'),
        _re(r'spawns? hearts?'),
      ],
    ),
    EffectTag(
      id: 'invuln',
      label: 'I-frames / invuln',
      blurb: 'Invincibility windows',
      icon: Icons.shield_moon,
      category: EffectCategory.defense,
      patterns: [
        _re(r'invincible'),
        _re(r'invulnerab'),
        _re(r'immun(e|ity) to damage'),
        _re(r'i-?frames'),
      ],
    ),
    EffectTag(
      id: 'damage_resist',
      label: 'Damage resist',
      blurb: 'Reduces damage taken',
      icon: Icons.fitness_center,
      category: EffectCategory.defense,
      patterns: [
        _re(r'reduce[sd]? damage taken'),
        _re(r'decrease[sd]? damage taken'),
        _re(r'damage resistance'),
      ],
    ),
    EffectTag(
      id: 'revive',
      label: 'Revive',
      blurb: 'Brings you back on death',
      icon: Icons.emergency,
      category: EffectCategory.defense,
      patterns: [
        _re(r'revive[s]? (the )?player'),
        _re(r'instantly revive'),
        _re(r'resurrect'),
      ],
    ),

    // ======== ECONOMY / LOOT ========
    EffectTag(
      id: 'key_drops',
      label: 'Key drops',
      blurb: 'Keys appear more often',
      icon: Icons.key,
      category: EffectCategory.economy,
      patterns: [
        _re(r'(chance|chance to) (get|find|drop) (a )?keys?'),
        _re(r'spawn[s]? keys?'),
        _re(r'\+\s*keys'),
      ],
    ),
    EffectTag(
      id: 'open_any',
      label: 'Universal key',
      blurb: 'Unlock anything w/o a key',
      icon: Icons.lock_open,
      category: EffectCategory.economy,
      patterns: [_re(r'open(ed)? without using a key'), _re(r'open any chest or lock')],
    ),
    EffectTag(
      id: 'shop_discount',
      label: 'Shop discount',
      blurb: 'Cheaper shop prices',
      icon: Icons.local_offer,
      category: EffectCategory.economy,
      patterns: [_re(r'discount at shops?'), _re(r'cheaper at shops?'), _re(r'shop.* discount')],
    ),
    EffectTag(
      id: 'shop_steal',
      label: 'Shop steal',
      blurb: 'Steal from the shop',
      icon: Icons.hide_image,
      category: EffectCategory.economy,
      patterns: [_re(r'steal from (the )?shop')],
    ),
    EffectTag(
      id: 'extra_loot',
      label: 'Extra drops',
      blurb: 'More chests/loot drops',
      icon: Icons.inventory_2,
      category: EffectCategory.economy,
      patterns: [
        _re(r'extra (chest|loot|drop)'),
        _re(r'chance to duplicate'),
        _re(r'chance to drop an? item'),
      ],
    ),
    EffectTag(
      id: 'map_reveal',
      label: 'Map reveal',
      blurb: 'Reveals the floor map',
      icon: Icons.map,
      category: EffectCategory.economy,
      patterns: [
        _re(r'reveal[s]? (all )?(the )?(floor )?maps?'),
        _re(r'floors? .* mapped'),
      ],
    ),

    // ======== UTILITY ========
    EffectTag(
      id: 'blank_grant',
      label: 'Auto-blank',
      blurb: 'Triggers a blank on damage',
      icon: Icons.radio_button_unchecked,
      category: EffectCategory.utility,
      patterns: [
        _re(r'automatically activates? .{0,30}blanks?'),
        _re(r'grants? (a |one |an? extra )?blank'),
        _re(r'activates? a blank effect'),
      ],
    ),
    EffectTag(
      id: 'charm',
      label: 'Charm chance',
      blurb: 'Enemies may become allies',
      icon: Icons.favorite,
      category: EffectCategory.utility,
      patterns: [_re(r'charm(s|ed)? (?:an )?enemy'), _re(r'will be charmed')],
    ),
    EffectTag(
      id: 'slow_time',
      label: 'Slow time',
      blurb: 'Time slows on trigger',
      icon: Icons.hourglass_bottom,
      category: EffectCategory.utility,
      patterns: [_re(r'slows? down time'), _re(r'slow motion'), _re(r'time slows')],
    ),
    EffectTag(
      id: 'companion_summon',
      label: 'Companion',
      blurb: 'Summons a friendly',
      icon: Icons.pets,
      category: EffectCategory.utility,
      patterns: [
        _re(r'summons? (a )?(friendly )?(companion|dog|turkey|chicken|ghost|clone)'),
        _re(r'follows? the player'),
        _re(r'follows? you'),
      ],
    ),

    // ======== STATUS ========
    EffectTag(
      id: 'coolness_up',
      label: 'Coolness +',
      blurb: 'Increases coolness',
      icon: Icons.ac_unit,
      category: EffectCategory.status,
      patterns: [_re(r'increase[sd]? coolness by'), _re(r'\+\s*\d+\s*coolness')],
    ),

    // ======== DEBUFFS ========
    EffectTag(
      id: 'curse_up',
      label: 'Curse +',
      blurb: 'Increases curse while held',
      icon: Icons.warning_amber,
      category: EffectCategory.debuff,
      patterns: [_re(r'increase[sd]? curse by'), _re(r'\+\s*\d+\s*curse')],
    ),
    EffectTag(
      id: 'damage_down',
      label: 'Damage ↓',
      blurb: 'Deals less damage',
      icon: Icons.trending_down,
      category: EffectCategory.debuff,
      patterns: [
        _re(r'decrease[sd]? (bullet )?damage'),
        _re(r'half damage'),
        _re(r'\-\s*\d+%?\s*damage'),
      ],
    ),
    EffectTag(
      id: 'ammo_down',
      label: 'Max ammo ↓',
      blurb: 'Smaller ammo pools',
      icon: Icons.battery_alert,
      category: EffectCategory.debuff,
      patterns: [
        _re(r'decrease[sd]? (maximum )?ammo'),
        _re(r'\-\s*\d+%?\s*max(imum)? ammo'),
      ],
    ),
    EffectTag(
      id: 'speed_down',
      label: 'Move speed ↓',
      blurb: 'Slows the player down',
      icon: Icons.directions_walk,
      category: EffectCategory.debuff,
      patterns: [
        _re(r'decrease[sd]? .{0,20}movement speed'),
        _re(r'slow(s|er) movement'),
      ],
    ),
    EffectTag(
      id: 'hp_cost',
      label: 'Costs HP',
      blurb: 'Trades health for power',
      icon: Icons.heart_broken,
      category: EffectCategory.debuff,
      patterns: [
        _re(r'damages? the player (for|by)'),
        _re(r'costs? (half )?a? heart'),
        _re(r'costs? half a heart'),
        _re(r'consume[s]? (a )?heart'),
      ],
    ),
    EffectTag(
      id: 'jam_risk',
      label: 'Jam risk ↑',
      blurb: 'Bullets may jam',
      icon: Icons.report,
      category: EffectCategory.debuff,
      patterns: [_re(r'chance to jam'), _re(r'jammed enemies')],
    ),
  ];

  /// All tags (ordered for UI).
  static List<EffectTag> get allTags => List.unmodifiable(_all);

  /// Regex used to split source text into atomic sentences for excerpt
  /// extraction. Splits on `. ` / `; ` / newlines — conservative enough
  /// that decimals like "1.5" don't get split mid-number.
  static final RegExp _sentenceSplit = RegExp(r'(?:\. |[;\n])\s*');

  /// Find the first sentence inside [text] that any of [patterns]
  /// matches, trimmed and capped to ~110 chars. Returns the sentence
  /// verbatim so numbers, percentages and ranges come through untouched.
  static String _excerptFor(String text, List<RegExp> patterns) {
    if (text.trim().isEmpty) return '';
    final sentences = text.split(_sentenceSplit);
    for (final raw in sentences) {
      final s = raw.trim();
      if (s.isEmpty) continue;
      if (patterns.any((p) => p.hasMatch(s))) {
        // Strip trailing punctuation so repeated rows don't end in
        // `...a.` or `...b;`. Cap length to keep the row readable.
        var clean = s.replaceAll(RegExp(r'[.;]+$'), '').trim();
        if (clean.length > 110) {
          clean = '${clean.substring(0, 108).trimRight()}…';
        }
        return clean;
      }
    }
    return '';
  }

  /// Enumerate every (tag, excerpt) pair that fires for [text].
  static Iterable<(EffectTag, String)> _extractWithExcerpts(
      String text) sync* {
    if (text.trim().isEmpty) return;
    for (final t in _all) {
      if (t.patterns.any((p) => p.hasMatch(text))) {
        yield (t, _excerptFor(text, t.patterns));
      }
    }
  }

  /// Scan a player's loadout. Returns a list grouped by tag with source
  /// names and per-source excerpts.
  static Map<EffectTag, List<EffectOccurrence>> scan({
    required List<Gun> guns,
    required List<Item> items,
  }) {
    final out = <EffectTag, List<EffectOccurrence>>{};
    for (final g in guns) {
      final text = '${g.notes} ${g.type}';
      for (final (tag, excerpt) in _extractWithExcerpts(text)) {
        out.putIfAbsent(tag, () => []).add(
              EffectOccurrence(
                tag: tag,
                sourceName: g.name,
                sourceIsGun: true,
                excerpt: excerpt,
              ),
            );
      }
    }
    for (final it in items) {
      final text = it.effect;
      for (final (tag, excerpt) in _extractWithExcerpts(text)) {
        out.putIfAbsent(tag, () => []).add(
              EffectOccurrence(
                tag: tag,
                sourceName: it.name,
                sourceIsGun: false,
                excerpt: excerpt,
              ),
            );
      }
    }
    return out;
  }

  /// Group a scan() result by category, preserving registration order.
  static Map<EffectCategory, List<EffectTag>> groupByCategory(
      Map<EffectTag, List<EffectOccurrence>> scan) {
    final groups = <EffectCategory, List<EffectTag>>{};
    for (final t in _all) {
      if (!scan.containsKey(t)) continue;
      groups.putIfAbsent(t.category, () => []).add(t);
    }
    return groups;
  }

  /// Pulls the *first* meaningful numeric token out of an excerpt — the
  /// kind of tiny stat we want on a compact dashboard chip. Examples
  /// of what we lift: "+30%", "x2", "2 bounces", "+15", "-20%".
  /// Returns `null` when nothing useful is extractable so the caller
  /// can fall back to just the label.
  static final RegExp _numToken = RegExp(
    r'([+\-x×])?\s*(\d+(?:\.\d+)?)\s*(%|x|×|times?|bounces?|shots?|rounds?|seconds?|s\b|hp|hearts?|projectiles?)?',
    caseSensitive: false,
  );

  static String? extractStat(String excerpt) {
    if (excerpt.isEmpty) return null;
    final m = _numToken.firstMatch(excerpt);
    if (m == null) return null;
    final sign = m.group(1) ?? '';
    final num = m.group(2)!;
    final unit = (m.group(3) ?? '').toLowerCase();
    // Skip cosmetic 1's that bleed in from prose ("a 1 in 4 chance").
    if (sign.isEmpty && unit.isEmpty && (num == '1' || num == '0')) {
      return null;
    }
    final unitOut = switch (unit) {
      '' => '',
      's' || 'second' || 'seconds' => 's',
      'hp' || 'heart' || 'hearts' => '♥',
      'time' || 'times' => 'x',
      'bounce' || 'bounces' => ' bounces',
      'shot' || 'shots' => ' shots',
      'round' || 'rounds' => ' rounds',
      'projectile' || 'projectiles' => ' bullets',
      _ => unit,
    };
    final signOut = (sign == 'x' || sign == '×') ? '×' : sign;
    return '$signOut$num$unitOut';
  }

  /// Compact dashboard view: one chip per active effect tag, with the
  /// extracted numeric stat where we can isolate one. Returned in the
  /// same registration order so layout stays stable across rebuilds.
  static List<EffectChip> summaryChips({
    required List<Gun> guns,
    required List<Item> items,
  }) {
    final scanned = scan(guns: guns, items: items);
    final out = <EffectChip>[];
    for (final tag in _all) {
      final occs = scanned[tag];
      if (occs == null || occs.isEmpty) continue;
      // Take the most informative excerpt across sources.
      String? value;
      for (final o in occs) {
        final v = extractStat(o.excerpt);
        if (v != null) {
          value = v;
          break;
        }
      }
      out.add(EffectChip(
        tag: tag,
        value: value,
        sourceCount: occs.length,
      ));
    }
    return out;
  }
}

/// Data for one dashboard chip: the recognized effect plus an
/// optional numeric value pulled from the source excerpt and a
/// duplicate-source counter (rendered as a small "×N" suffix).
@immutable
class EffectChip {
  final EffectTag tag;
  final String? value;
  final int sourceCount;
  const EffectChip({
    required this.tag,
    this.value,
    this.sourceCount = 1,
  });
}
