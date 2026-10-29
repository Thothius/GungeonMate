import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/models/gun.dart';
import 'package:gungeon_mate/models/item.dart';

/// Special-item logic — Gunderfury dynamic DPS tiers, Triple Gun
/// forms, and the companion item flag (Junkan tracking, Payday crew).
void main() {
  group('getDynamicDps — Gunderfury level tiers', () {
    final gun = Gun(name: 'Gunderfury');

    // Wiki-verified per-form DPS, thresholds at 20/30/40/50/60.
    test('levels 1-19 → 25.45', () {
      expect(gun.getDynamicDps(gunderLevel: 1), 25.45);
      expect(gun.getDynamicDps(gunderLevel: 19), 25.45);
    });
    test('levels 20-29 → 29.57', () {
      expect(gun.getDynamicDps(gunderLevel: 20), 29.57);
      expect(gun.getDynamicDps(gunderLevel: 29), 29.57);
    });
    test('levels 30-39 → 33.157', () {
      expect(gun.getDynamicDps(gunderLevel: 30), 33.157);
    });
    test('levels 40-49 → 34.09', () {
      expect(gun.getDynamicDps(gunderLevel: 40), 34.09);
    });
    test('levels 50-59 → 107.14 (form 5)', () {
      expect(gun.getDynamicDps(gunderLevel: 50), 107.14);
      expect(gun.getDynamicDps(gunderLevel: 59), 107.14);
    });
    test('level 60+ → 181.82 (final form)', () {
      expect(gun.getDynamicDps(gunderLevel: 60), 181.82);
      expect(gun.getDynamicDps(gunderLevel: 99), 181.82);
    });
  });

  group('getDynamicDps — Triple Gun forms', () {
    final gun = Gun(name: 'Triple Gun');

    test('form 1 → 18.0', () {
      expect(gun.getDynamicDps(tripleForm: 1), 18.0);
    });
    test('form 2 → 28.5', () {
      expect(gun.getDynamicDps(tripleForm: 2), 28.5);
    });
    test('form 3 → 55.0', () {
      expect(gun.getDynamicDps(tripleForm: 3), 55.0);
    });
  });

  group('Item.isCompanion — tracking eligibility', () {
    test('Ser Junkan variants are companions', () {
      expect(Item(name: 'Ser Junkan').isCompanion, true);
      // The 'ser junkan 1' variant — the earlier name-match fix.
      expect(Item(name: 'Ser Junkan 1').isCompanion, true);
    });

    test('Payday crew items are companions', () {
      expect(Item(name: 'Clown Mask').isCompanion, true);
    });

    test('other tracked companions', () {
      for (final n in ['Wingman', 'Badge', 'Turkey', 'Wolf']) {
        expect(Item(name: n).isCompanion, true, reason: n);
      }
    });

    test('normal items are not companions', () {
      expect(Item(name: 'Armor').isCompanion, false);
      expect(Item(name: 'Casing').isCompanion, false);
      expect(Item(name: 'Key').isCompanion, false);
    });
  });
}
