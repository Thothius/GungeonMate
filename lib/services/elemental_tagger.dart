import 'package:flutter/material.dart';
import '../models/gun.dart';
import '../models/item.dart';
import '../models/player.dart';

/// Canonical status-effect / elemental buckets we care about for at-a-
/// glance indicators. These intentionally overlap with [EffectTagger]
/// categories but live in their own tagger because:
///
///  * Their consumers (tiles, dashboard) want a *Set* not a Map — we
///    only need "does this loadout do fire damage" answers, not
///    excerpts.
///  * We include a few elements [EffectTagger] doesn't: electric,
///    water, which the game has but we were previously blind to.
///  * Detection rules blend the explicit `gunClass` (FIRE/ICE/POISON/
///    CHARM/EXPLOSIVE) with text-pattern scanning, and apply to
///    items too so pieces like *Frost Bullets*, *Hot Lead*, *Shock
///    Rounds* surface the correct elements.
enum ElementKind {
  fire,
  freeze,
  poison,
  electric,
  water,
  stun,
  charm,
  explosive,
}

extension ElementMeta on ElementKind {
  String get label {
    switch (this) {
      case ElementKind.fire:
        return 'Fire';
      case ElementKind.freeze:
        return 'Freeze';
      case ElementKind.poison:
        return 'Poison';
      case ElementKind.electric:
        return 'Electric';
      case ElementKind.water:
        return 'Water';
      case ElementKind.stun:
        return 'Stun';
      case ElementKind.charm:
        return 'Charm';
      case ElementKind.explosive:
        return 'Explosive';
    }
  }

  IconData get icon {
    switch (this) {
      case ElementKind.fire:
        return Icons.local_fire_department;
      case ElementKind.freeze:
        return Icons.ac_unit;
      case ElementKind.poison:
        return Icons.science;
      case ElementKind.electric:
        return Icons.bolt;
      case ElementKind.water:
        return Icons.water_drop;
      case ElementKind.stun:
        return Icons.flash_on;
      case ElementKind.charm:
        return Icons.favorite;
      case ElementKind.explosive:
        // Distinct from Fire's flame icon — using a starburst so the
        // two reads are unambiguous when both appear together.
        return Icons.flare;
    }
  }

  Color get color {
    switch (this) {
      case ElementKind.fire:
        return const Color(0xFFFF6E40);
      case ElementKind.freeze:
        return const Color(0xFF4FC3F7);
      case ElementKind.poison:
        return const Color(0xFF9CCC65);
      case ElementKind.electric:
        return const Color(0xFFFFD54F);
      case ElementKind.water:
        return const Color(0xFF42A5F5);
      case ElementKind.stun:
        return const Color(0xFFFFEE58);
      case ElementKind.charm:
        return const Color(0xFFF06292);
      case ElementKind.explosive:
        // Yellow-orange for kabooms; visibly separate from Fire's
        // pinker red-orange so the dashboard never blurs the two.
        return const Color(0xFFFFA000);
    }
  }
}

class ElementalTagger {
  ElementalTagger._();

  static RegExp _re(String p) => RegExp(p, caseSensitive: false);

  /// Per-element detection rules. Each element can trigger from any of:
  ///
  ///  * a `gunClass` literal match (only meaningful for guns)
  ///  * one or more regex patterns against the source text blob
  ///
  /// Rules are intentionally conservative: we prefer false negatives
  /// over false positives because a misfiring indicator is much more
  /// irritating than a missing one.
  static final Map<ElementKind, _Rule> _rules = {
    ElementKind.fire: _Rule(
      gunClasses: {'FIRE'},
      // Patterns intentionally exclude the bare word `fire` — too
      // many wiki notes use 'fires', 'covering fire', 'rapid fire'
      // in ways that have nothing to do with the elemental status.
      // Stick to verbs and nouns that imply ignition damage.
      patterns: [
        _re(r'\bignite[sd]?\b'),
        _re(r'\bigniting\b'),
        _re(r'\bburn(s|ing|ed)?\b'),
        _re(r'\bburning bullets?\b'),
        _re(r'\bsets? .{0,20}on fire\b'),
        _re(r'\bcatches? .{0,20}on fire\b'),
        _re(r'\blight(s|ed|ing) .{0,20}on fire\b'),
        _re(r'\bincendiary\b'),
        _re(r'\bflame(s|d|thrower)?\b'),
        _re(r'\bfire damage\b'),
        _re(r'\bon fire\b'),
      ],
    ),
    ElementKind.freeze: _Rule(
      gunClasses: {'ICE'},
      patterns: [
        _re(r'\bfreeze[sd]?\b'),
        _re(r'\bfrozen\b'),
        _re(r'\bfrost\b'),
        _re(r'\bicy?\b'),
        _re(r'chance to freeze'),
      ],
    ),
    ElementKind.poison: _Rule(
      gunClasses: {'POISON'},
      patterns: [
        _re(r'\bpoison(s|ed|ous|ing)?\b'),
        _re(r'\bacid(ic)?\b'),
        _re(r'\bvenom'),
        _re(r'\birradiat'),
        _re(r'\btoxic\b'),
      ],
    ),
    ElementKind.electric: _Rule(
      // No dedicated gunClass for shock in the wiki data, but the text
      // rules below catch the common tools (Shock Rounds, Lightning
      // Gun, Tesla Spool, etc.).
      patterns: [
        _re(r'\belectrif(y|ied|ies|ying)\b'),
        _re(r'\belectric(al)?\b'),
        _re(r'\bshock(s|ed|ing|ing)?\b'),
        _re(r'\blightning\b'),
        _re(r'\btesla\b'),
        _re(r'\bvolt\b'),
        _re(r'\bzap(s|ped|ping)?\b'),
      ],
    ),
    ElementKind.water: _Rule(
      patterns: [
        _re(r'\bwater\b'),
        _re(r'\bwet\b'),
        _re(r'\bdrench(es|ed|ing)?\b'),
        _re(r'\bsoak(s|ed|ing)?\b'),
        _re(r'\bpuddle\b'),
      ],
    ),
    ElementKind.stun: _Rule(
      patterns: [
        _re(r'\bstun(s|ned|ning)?\b'),
        _re(r'\bparaly(ze|zed|sis)\b'),
        _re(r'briefly stops? enemies'),
      ],
    ),
    ElementKind.charm: _Rule(
      gunClasses: {'CHARM'},
      patterns: [
        _re(r'\bcharm(s|ed|ing)?\b'),
      ],
    ),
    ElementKind.explosive: _Rule(
      gunClasses: {'EXPLOSIVE'},
      patterns: [
        _re(r'\bexplod(e|es|ing|ed)\b'),
        _re(r'\bexplosive\b'),
        _re(r'\bexplos(ion|ions)\b'),
      ],
    ),
  };

  /// Elements that fire for a single gun. Includes `gunClass` → element
  /// short-circuits plus pattern-scan on notes + type text.
  static Set<ElementKind> elementsOfGun(Gun g) {
    final cls = g.gunClass.toUpperCase();
    final text = '${g.notes}\n${g.type}';
    final out = <ElementKind>{};
    _rules.forEach((el, rule) {
      if (rule.matches(gunClass: cls, text: text)) out.add(el);
    });
    return out;
  }

  /// Elements that fire for an item. Items only provide `effect` text;
  /// they have no `gunClass` equivalent.
  static Set<ElementKind> elementsOfItem(Item it) {
    final out = <ElementKind>{};
    _rules.forEach((el, rule) {
      if (rule.matches(gunClass: '', text: it.effect)) out.add(el);
    });
    return out;
  }

  /// Full aggregated set across a player's guns + items. Used to paint
  /// the at-a-glance row of elemental indicators on the dashboard.
  static Set<ElementKind> elementsOfPlayer(Player? p) {
    if (p == null) return const <ElementKind>{};
    final out = <ElementKind>{};
    for (final g in p.guns) {
      out.addAll(elementsOfGun(g));
    }
    for (final i in p.items) {
      out.addAll(elementsOfItem(i));
    }
    return out;
  }
}

class _Rule {
  final Set<String> gunClasses;
  final List<RegExp> patterns;
  const _Rule({this.gunClasses = const {}, this.patterns = const []});

  bool matches({required String gunClass, required String text}) {
    if (gunClass.isNotEmpty && gunClasses.contains(gunClass)) return true;
    if (text.isEmpty) return false;
    for (final p in patterns) {
      if (p.hasMatch(text)) return true;
    }
    return false;
  }
}
