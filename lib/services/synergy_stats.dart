/// Parses Enter the Gungeon synergy effect text into structured gun-stat
/// modifiers so detail views can show `old → new` chips (e.g. `DMG 5 → 6.5`).
///
/// Display-only: this never feeds the real synergy matcher — it annotates
/// the effect text for the player. Regex-driven; Gemini-derived overrides
/// can layer on top later via [overrideFor].
library;

import '../models/gun.dart';

enum SynStat {
  damage,
  fireRate,
  reload,
  magazine,
  ammo,
  spread,
  shotSpeed,
  range,
  force,
  pierce,
  bounce,
  projectileSize,
  projectilesPerShot,
  accuracy,
}

enum ModKind { percent, additive, setTo }

class StatMod {
  final SynStat stat;
  final ModKind kind;

  /// Percent (e.g. 25 = +25%), additive delta, or absolute set value.
  final double value;

  /// The source clause this was parsed from — shown on tap.
  final String clause;
  const StatMod(this.stat, this.kind, this.value, this.clause);
}

/// One resolved stat change for a specific gun.
class StatDelta {
  final SynStat stat;
  final String label;

  /// Base value formatted for display, or null when the stat has no
  /// numeric base on the gun (pierce, bounce, ...).
  final String? oldText;
  final String newText;
  final bool improved;
  final String clause;
  const StatDelta({
    required this.stat,
    required this.label,
    required this.oldText,
    required this.newText,
    required this.improved,
    required this.clause,
  });
}

// ---------------------------------------------------------------------------
// Parsing
// ---------------------------------------------------------------------------

/// Stat keyword → SynStat. Order matters: multi-word phrases first.
final _statKeywords = <(SynStat, RegExp)>[
  (
    SynStat.projectilesPerShot,
    RegExp(
      r'projectiles? per shot|bullets per shot|shots per (?:trigger )?pull',
      caseSensitive: false,
    ),
  ),
  (
    SynStat.projectileSize,
    RegExp(
      r'(?:bullet|projectile|shot|shell|pellet|laser|beam|shard|note|nail|seed|spike|icicle|orb|missile|rocket|grenade)s?[^.;]{0,25}\bsize\b|\bsize of (?:the |its |their )?(?:bullet|projectile|shot|shell|pellet|laser|beam)s?\b',
      caseSensitive: false,
    ),
  ),
  (
    SynStat.fireRate,
    RegExp(r'rate of fire|fire rate|firerate', caseSensitive: false),
  ),
  (
    SynStat.shotSpeed,
    RegExp(
      r'(?:shot|bullet|projectile|pellet)s? (?:speed|velocity)|muzzle velocity',
      caseSensitive: false,
    ),
  ),
  (SynStat.magazine, RegExp(r'magazine', caseSensitive: false)),
  (SynStat.reload, RegExp(r'reload', caseSensitive: false)),
  (
    SynStat.ammo,
    RegExp(
      r'max(?:imum)? ammo|ammo (?:capacity|pool)|total ammo',
      caseSensitive: false,
    ),
  ),
  (SynStat.spread, RegExp(r'\bspread\b', caseSensitive: false)),
  (SynStat.pierce, RegExp(r'pierc', caseSensitive: false)),
  (SynStat.bounce, RegExp(r'bounc', caseSensitive: false)),
  (SynStat.force, RegExp(r'knockback|\bforce\b', caseSensitive: false)),
  (SynStat.range, RegExp(r'\brange\b', caseSensitive: false)),
  (SynStat.accuracy, RegExp(r'accuracy', caseSensitive: false)),
  (SynStat.damage, RegExp(r'\bdamage\b|\bdps\b', caseSensitive: false)),
];

final _numRe = RegExp(r'(\d+(?:\.\d+)?)');
final _pctRe = RegExp(r'(\d+(?:\.\d+)?)\s*%');
final _multRe = RegExp(r'([\d.]+)\s*x\b');
final _toRe = RegExp(r'\bto\s+(\d+(?:\.\d+)?)\b');
final _enemyRe = RegExp(
  "enemy bullets?|enemies take|enemy projectiles?|enemy damage|slows? down enemy|enemy'?s bullets?",
  caseSensitive: false,
);
final _downRe = RegExp(
  r'decreas|reduc|lower|less|slower|fewer|halv|\bhalf\b|diminish|weaken|drop|loss of|loses?|losing',
  caseSensitive: false,
);
final _upRe = RegExp(
  r'increas|boost|rais|improv|enhanc|gain|add|doubl|tripl|quadrupl|buff|multiplier|\btimes\b|more damage|higher|greater|larger|stronger|faster',
  caseSensitive: false,
);
final _multWordRe = RegExp(
  r'\b(quadruples?|quadrupled|triples?|tripled|trebles?|doubles?|doubled|halves?|halved|half)\b',
  caseSensitive: false,
);

const _multValues = {
  'double': 100.0,
  'doubles': 100.0,
  'doubled': 100.0,
  'triple': 200.0,
  'triples': 200.0,
  'tripled': 200.0,
  'treble': 200.0,
  'trebles': 200.0,
  'quadruple': 300.0,
  'quadruples': 300.0,
  'quadrupled': 300.0,
  'half': -50.0,
  'halves': -50.0,
  'halved': -50.0,
};

/// Split effect text into clauses on sentence/clause boundaries.
List<String> _clauses(String effect) {
  // Decimals must survive — "1.5x damage" and "0.25%" would shatter into
  // "1" + "5x" (+400% bug) if we split naively on '.'.
  final out = <String>[];
  final buf = StringBuffer();
  for (var i = 0; i < effect.length; i++) {
    final ch = effect[i];
    final isBreak =
        ch == '.' ||
        ch == '!' ||
        ch == '?' ||
        ch == ';' ||
        ch.codeUnitAt(0) == 10;
    final decimal =
        ch == '.' &&
        i > 0 &&
        i + 1 < effect.length &&
        _isDigit(effect[i - 1]) &&
        _isDigit(effect[i + 1]);
    if (isBreak && !decimal) {
      final c = buf.toString().trim();
      if (c.isNotEmpty) out.add(c);
      buf.clear();
    } else {
      buf.write(ch);
    }
  }
  final c = buf.toString().trim();
  if (c.isNotEmpty) out.add(c);
  return out;
}

bool _isDigit(String ch) => ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57;

/// Extract every quantified stat modifier from an effect text.
/// Each [StatMod] keeps its source clause for tap-to-inspect display.
List<StatMod> parseStatMods(String effect) {
  if (effect.isEmpty) return const [];
  final mods = <StatMod>[];
  final seen = <String>{};
  for (final clause in _clauses(effect)) {
    if (_enemyRe.hasMatch(clause)) continue;
    for (final (stat, kwRe) in _statKeywords) {
      for (final m in kwRe.allMatches(clause)) {
        final mod = _modFor(stat, clause, m.start);
        if (mod == null) continue;
        final key =
            '${stat.name}|${mod.kind.name}|${mod.value}|${clause.hashCode}';
        if (seen.add(key)) mods.add(mod);
      }
    }
    // "fires 4 projectiles instead of 3" style — one mod per clause.
    final instRe = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:projectiles?|bullets?|shots?|pellets?)\s+instead of\s+\d+',
      caseSensitive: false,
    );
    for (final m in instRe.allMatches(clause)) {
      final v = double.tryParse(m.group(1)!);
      if (v != null) {
        mods.add(StatMod(SynStat.projectilesPerShot, ModKind.setTo, v, clause));
      }
    }
  }
  return mods;
}

StatMod? _modFor(SynStat stat, String clause, int kwStart) {
  // Window around the keyword: verbs before, numbers after.
  final winStart = kwStart > 90 ? kwStart - 90 : 0;
  final winEnd = clause.length < kwStart + 110 ? clause.length : kwStart + 110;
  final before = clause.substring(winStart, kwStart);
  final after = clause.substring(kwStart, winEnd);
  final window = before + after;

  // Direction from verbs nearest the number — check the whole window,
  // preferring whichever verb appears closest to the stat keyword.
  double sign = 0;
  final downM = _downRe.firstMatch(window);
  final upM = _upRe.firstMatch(window);
  if (downM != null && upM != null) {
    sign = downM.start < upM.start ? -1 : 1;
  } else if (downM != null) {
    sign = -1;
  } else if (upM != null) {
    sign = 1;
  }

  // "to N" set-value wins when there's no % sign.
  // Numbers may sit on either side of the stat word — "50% more damage"
  // vs "damage increased by 50%" — so search after first, then before.
  final pctM = _pctRe.firstMatch(after) ?? _pctRe.firstMatch(before);
  if (pctM != null) {
    final v = double.tryParse(pctM.group(1)!);
    if (v != null && sign != 0) {
      return StatMod(stat, ModKind.percent, sign * v, clause);
    }
    // "N%" with no direction verb — assume increase.
    if (v != null && sign == 0 && _looksPositive(clause)) {
      return StatMod(stat, ModKind.percent, v, clause);
    }
    return null;
  }

  final multM = _multRe.firstMatch(after) ?? _multRe.firstMatch(before);
  if (multM != null) {
    final x = double.tryParse(multM.group(1)!);
    if (x != null) {
      final pct = (x - 1) * 100;
      final eff = sign != 0 && x >= 1 ? sign * pct.abs() : pct;
      return StatMod(stat, ModKind.percent, eff, clause);
    }
  }

  // Multiplier words: "doubles damage", "halves reload time".
  final mw = _multWordRe.firstMatch(window);
  if (mw != null) {
    final v = _multValues[mw.group(1)!.toLowerCase()];
    if (v != null) return StatMod(stat, ModKind.percent, v, clause);
  }

  // Absolute set: "magazine size to 27", "max ammo to 600".
  final toM = _toRe.firstMatch(after);
  if (toM != null && sign >= 0) {
    final v = double.tryParse(toM.group(1)!);
    if (v != null) return StatMod(stat, ModKind.setTo, v, clause);
  }

  // Additive: "+2 pierce", "gains 2 bounces" — bare number, direction up.
  if (sign > 0) {
    final numM = _numRe.firstMatch(after);
    final numInBefore = numM == null ? _numRe.firstMatch(before) : null;
    final useNum = numM ?? numInBefore;
    if (useNum != null) {
      final hay = numM != null ? after : before;
      if (!hay.substring(0, useNum.start).contains('%')) {
        // Only trust small additive counts for count-stats.
        if (stat == SynStat.pierce ||
            stat == SynStat.bounce ||
            stat == SynStat.projectilesPerShot ||
            stat == SynStat.projectileSize) {
          final v = double.tryParse(useNum.group(1)!);
          if (v != null && v <= 20) {
            return StatMod(stat, ModKind.additive, v, clause);
          }
        }
      }
    }
  }
  return null;
}

bool _looksPositive(String clause) {
  return _upRe.hasMatch(clause) && !_downRe.hasMatch(clause);
}

// ---------------------------------------------------------------------------
// Resolution against a gun's base stats
// ---------------------------------------------------------------------------

/// First parseable number in a gun stat string ("5", "0.07", "5°",
/// "15 3.8" → 15). Returns null for "", "N/A", "∞".
double? statBaseNum(String raw) {
  final t = raw.trim();
  if (t.isEmpty || t == 'N/A' || t == '∞' || t == 'inf') return null;
  final m = _numRe.firstMatch(t);
  return m == null ? null : double.tryParse(m.group(1)!);
}

String _baseFor(SynStat stat, Gun gun) {
  switch (stat) {
    case SynStat.damage:
      return gun.damage;
    case SynStat.fireRate:
      return gun.fireRate;
    case SynStat.reload:
      return gun.reloadTime;
    case SynStat.magazine:
      return gun.magazineSize;
    case SynStat.ammo:
      return gun.ammoCapacity;
    case SynStat.spread:
      return gun.spread;
    case SynStat.shotSpeed:
      return gun.shotSpeed;
    case SynStat.range:
      return gun.range;
    case SynStat.force:
      return gun.force;
    default:
      return '';
  }
}

const _labels = {
  SynStat.damage: 'DMG',
  SynStat.fireRate: 'ROF',
  SynStat.reload: 'RLD',
  SynStat.magazine: 'MAG',
  SynStat.ammo: 'AMMO',
  SynStat.spread: 'SPR',
  SynStat.shotSpeed: 'VEL',
  SynStat.range: 'RNG',
  SynStat.force: 'KNK',
  SynStat.pierce: 'PRC',
  SynStat.bounce: 'BNC',
  SynStat.projectileSize: 'SIZE',
  SynStat.projectilesPerShot: 'SHOTS',
  SynStat.accuracy: 'ACC',
};

/// Stats where a smaller displayed number is better.
const _lowerBetter = {SynStat.reload, SynStat.spread};

/// Resolve parsed mods into display deltas for [gun]. Pass `null` for
/// count-only stats (pierce/bounce/...) — they show `+N` style instead
/// of old→new since guns carry no base value for them.
List<StatDelta> resolveDeltas(List<StatMod> mods, Gun gun) {
  final out = <StatDelta>[];
  for (final mod in mods) {
    final label = _labels[mod.stat]!;
    final baseRaw = _baseFor(mod.stat, gun);
    final base = statBaseNum(baseRaw);

    double? next;
    if (mod.kind == ModKind.percent && base != null) {
      if (mod.stat == SynStat.fireRate) {
        // fireRate stat is seconds-between-shots; a +60% *rate* means the
        // interval shrinks: interval' = interval / (1 + pct/100).
        final denom = 1 + mod.value / 100;
        if (denom > 0) next = base / denom;
      } else {
        next = base * (1 + mod.value / 100);
      }
    } else if (mod.kind == ModKind.additive && base != null) {
      next = base + mod.value;
    } else if (mod.kind == ModKind.setTo) {
      next = mod.value;
    }

    if (next != null && base != null) {
      out.add(
        StatDelta(
          stat: mod.stat,
          label: label,
          oldText: _fmt(base),
          newText: _fmt(next),
          improved: _lowerBetter.contains(mod.stat) ? next < base : next > base,
          clause: mod.clause,
        ),
      );
    } else {
      // No base — additive/set on count stats: show signed value only.
      final sign = mod.value >= 0 ? '+' : '';
      final txt =
          mod.kind == ModKind.percent
              ? '$sign${_fmt(mod.value)}%'
              : '$sign${_fmt(mod.value)}';
      out.add(
        StatDelta(
          stat: mod.stat,
          label: label,
          oldText: null,
          newText: txt,
          improved: mod.value >= 0,
          clause: mod.clause,
        ),
      );
    }
  }
  return out;
}

String _fmt(double v) {
  final a = v.abs();
  final digits =
      a >= 100
          ? 0
          : a >= 10
          ? 1
          : a >= 1
          ? 2
          : 3;
  var s = v.toStringAsFixed(digits);
  if (s.contains('.')) {
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
  return s;
}

/// Does this modifier's clause plausibly apply to [currentName]?
/// Skips clauses that name a *different* gun from the synergy unless
/// they also say "both guns" / "the guns" / name the current gun.
bool clauseAppliesTo(
  StatMod mod,
  String currentName,
  Set<String> otherGunNames,
) {
  final c = mod.clause.toLowerCase();
  final cur = currentName.toLowerCase();
  if (c.contains(cur)) return true;
  if (RegExp(r'\b(both|the|each|all|your|two) guns?\b').hasMatch(c)) {
    return true;
  }
  for (final g in otherGunNames) {
    if (g != cur && c.contains(g.toLowerCase())) return false;
  }
  return true;
}

/// Convenience: parse + filter + resolve in one call.
/// [otherGunNames] = lowercase names of guns in the synergy other than
/// the current one (used to disambiguate "X's gun gains Y" clauses).
List<StatDelta> deltasForSynergy(
  String effect,
  Gun gun,
  String currentName,
  Set<String> otherGunNames,
) {
  final mods =
      parseStatMods(
        effect,
      ).where((m) => clauseAppliesTo(m, currentName, otherGunNames)).toList();
  return resolveDeltas(mods, gun);
}

// ---------------------------------------------------------------------------
// Gemini-derived metadata (assets/data/synergy_meta.json)
// ---------------------------------------------------------------------------

/// A qualitative (unquantified) buff/debuff reported by the data pass.
class QualBuff {
  final String stat;
  final String dir; // up | down | mixed | neutral
  final String note;
  const QualBuff(this.stat, this.dir, this.note);
}

/// Non-numeric synergy metadata merged from the Gemini classification
/// pass: fx tags, qualitative buffs, special items, co-op scope,
/// parser-miss hints, enemy-side flag.
class SynergyMeta {
  final List<String> fx;
  final List<QualBuff> qb;
  final List<Map<String, String>> si;
  final String coop;
  final List<String> miss;
  final bool enemy;
  const SynergyMeta({
    this.fx = const [],
    this.qb = const [],
    this.si = const [],
    this.coop = 'BOTH',
    this.miss = const [],
    this.enemy = false,
  });

  factory SynergyMeta.fromJson(Map<String, dynamic> j) {
    return SynergyMeta(
      fx: [for (final x in (j['fx'] as List? ?? const [])) '$x'],
      qb: [
        for (final q in (j['qb'] as List? ?? const []))
          QualBuff(
            '${(q as Map)['s'] ?? 'other'}',
            '${q['d'] ?? 'neutral'}',
            '${q['note'] ?? ''}',
          ),
      ],
      si: [
        for (final s in (j['si'] as List? ?? const []))
          {'item': '${(s as Map)['item'] ?? ''}', 'does': '${s['does'] ?? ''}'},
      ],
      coop: '${j['coop'] ?? 'BOTH'}',
      miss: [for (final x in (j['miss'] as List? ?? const [])) '$x'],
      enemy: j['enemy'] == true,
    );
  }
}

/// Short display labels for the Gemini stat-id vocabulary.
String synStatLabelFor(String id) {
  const labels = {
    'damage': 'DMG',
    'firerate': 'ROF',
    'reload': 'RLD',
    'magazine': 'MAG',
    'ammo': 'AMMO',
    'spread': 'SPR',
    'shotspeed': 'VEL',
    'range': 'RNG',
    'force': 'KNK',
    'pierce': 'PRC',
    'bounce': 'BNC',
    'projectile_size': 'SIZE',
    'projectiles_per_shot': 'SHOTS',
    'accuracy': 'ACC',
    'move_speed': 'MOV',
    'other': 'FX',
  };
  return labels[id] ?? id.toUpperCase();
}
