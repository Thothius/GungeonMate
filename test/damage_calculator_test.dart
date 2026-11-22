import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/models/gun.dart';
import 'package:gungeon_mate/models/item.dart';
import 'package:gungeon_mate/services/damage_calculator.dart';
import 'package:gungeon_mate/services/effect_tagger.dart';

/// DamageCalculator — aggregates damage_up/damage_down effect tags into
/// a multiplier plus per-source contribution rows.
void main() {
  group('contributions', () {
    test('empty loadout returns no contributions', () {
      expect(
        DamageCalculator.contributions(guns: const [], items: const []),
        isEmpty,
      );
    });

    test('gun notes with "+N% damage" produce a positive contribution', () {
      final gun = Gun(name: 'Buffed Sidearm', notes: 'Deals +30% damage.');
      final out = DamageCalculator.contributions(guns: [gun], items: const []);

      expect(out, hasLength(1));
      expect(out.single.sourceName, 'Buffed Sidearm');
      expect(out.single.sourceIsGun, isTrue);
      expect(out.single.percent, 30);
    });

    test('item effect "decreases damage" produces a negative contribution', () {
      final item = Item(
        name: 'Crippling Charm',
        effect: 'Decreases bullet damage by 20%.',
      );
      final out = DamageCalculator.contributions(guns: const [], items: [item]);

      expect(out, hasLength(1));
      expect(out.single.sourceIsGun, isFalse);
      expect(out.single.percent, -20);
    });

    test('unquantified damage text still lists at 0%', () {
      final item = Item(
        name: 'Mysterious Idol',
        effect: 'Deals double damage.',
      );
      final out = DamageCalculator.contributions(guns: const [], items: [item]);

      expect(out, hasLength(1));
      expect(out.single.percent, 0);
    });

    test('non-damage tags are ignored', () {
      final gun = Gun(name: 'Swift Thing', notes: 'Grants flight.');
      final out = DamageCalculator.contributions(guns: [gun], items: const []);
      expect(out, isEmpty);
    });
  });

  group('multiplier', () {
    test('empty loadout is 1.0', () {
      expect(DamageCalculator.multiplier(guns: const [], items: const []), 1.0);
    });

    test('+30% up and -20% down aggregate to 1.10', () {
      final guns = [Gun(name: 'A', notes: 'Deals +30% damage.')];
      final items = [
        Item(name: 'B', effect: 'Decreases bullet damage by 20%.'),
      ];
      expect(
        DamageCalculator.multiplier(guns: guns, items: items),
        closeTo(1.10, 0.001),
      );
    });

    test('unquantified sources do not move the multiplier', () {
      final items = [Item(name: 'B', effect: 'Deals double damage.')];
      expect(DamageCalculator.multiplier(guns: const [], items: items), 1.0);
    });
  });

  group('EffectTagger.extractStat', () {
    test('lifts signed percents and multipliers', () {
      expect(EffectTagger.extractStat('+30% damage'), '+30%');
      expect(EffectTagger.extractStat('x2 damage'), '×2');
      expect(EffectTagger.extractStat('fires 3 shots'), '3 shots');
    });

    test('skips bare cosmetic 1s from prose', () {
      expect(EffectTagger.extractStat('a 1 in 4 chance'), isNull);
      expect(EffectTagger.extractStat(''), isNull);
    });
  });
}
