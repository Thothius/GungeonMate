import '../models/gun.dart';
import '../models/item.dart';
import 'effect_tagger.dart';

/// One line-item contribution to the aggregate damage bonus, surfaced in
/// the Damage Calculator terminal so the player can see *why* the
/// multiplier is what it is (e.g. "Bloodied Scope +15%").
class DamageContribution {
  final String sourceName;
  final bool sourceIsGun;
  final double percent; // positive = buff, negative = debuff

  const DamageContribution({
    required this.sourceName,
    required this.sourceIsGun,
    required this.percent,
  });
}

/// Universal, character-agnostic damage bonus calculator.
///
/// Scans a player's equipped guns + items for known "Damage Up" / "Damage
/// Down" effect tags (via [EffectTagger]) and sums whatever numeric
/// percentages can be extracted from their wiki text, producing a single
/// aggregate multiplier that can be applied on top of any gun's base DPS.
///
/// This intentionally does NOT special-case any one character — Robot's
/// junk/lies/gold-junk bonuses stay in their own dedicated HUD. This is
/// the generic "what does my current loadout do to my damage" readout
/// available to every Gungeoneer.
class DamageCalculator {
  DamageCalculator._();

  /// Every quantifiable (and unquantifiable) damage-affecting source in
  /// the current loadout. Sources with no extractable number are still
  /// returned (percent == 0) so the UI can list them for transparency
  /// without them silently skewing the total.
  static List<DamageContribution> contributions({
    required List<Gun> guns,
    required List<Item> items,
  }) {
    final scanned = EffectTagger.scan(guns: guns, items: items);
    final out = <DamageContribution>[];
    for (final entry in scanned.entries) {
      final tag = entry.key;
      if (tag.id != 'damage_up' && tag.id != 'damage_down') continue;
      final sign = tag.id == 'damage_up' ? 1.0 : -1.0;
      // One contribution per unique source (a gun/item may match more
      // than one pattern for the same tag via its notes + type text).
      final seen = <String>{};
      for (final occ in entry.value) {
        if (!seen.add(occ.sourceName)) continue;
        double pct = 0;
        final raw = EffectTagger.extractStat(occ.excerpt);
        if (raw != null) {
          final m = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(raw);
          if (m != null) pct = double.tryParse(m.group(1)!) ?? 0;
        }
        out.add(DamageContribution(
          sourceName: occ.sourceName,
          sourceIsGun: occ.sourceIsGun,
          percent: pct * sign,
        ));
      }
    }
    return out;
  }

  /// Aggregate multiplier (e.g. 1.23 == +23%) from every quantifiable
  /// damage contribution in the loadout. Sources with no extractable
  /// number don't move this multiplier but still show up in
  /// [contributions] for transparency.
  static double multiplier({
    required List<Gun> guns,
    required List<Item> items,
  }) {
    final total = contributions(guns: guns, items: items)
        .fold<double>(0, (sum, c) => sum + c.percent);
    return 1.0 + (total / 100.0);
  }
}
