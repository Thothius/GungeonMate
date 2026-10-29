import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/models/synergy.dart';

/// Synergy matching logic — the rules behind PARTIAL/COMPLETE
/// grouping and the "would complete" predictor in browse.
void main() {
  group('matchesItems — plain N-of-N', () {
    final s = Synergy(
        name: 'Test Pair', items: ['Alpha', 'Beta']);

    test('all pieces owned → matches', () {
      expect(s.matchesItems(['alpha', 'beta']), true);
    });

    test('missing one piece → no match', () {
      expect(s.matchesItems(['alpha']), false);
      expect(s.matchesItems(['beta']), false);
    });

    test('case-insensitive matching', () {
      expect(s.matchesItems(['ALPHA', 'BETA']), true);
    });

    test('extra inventory does not break the match', () {
      expect(s.matchesItems(['alpha', 'beta', 'gamma']), true);
    });
  });

  group('matchesItems — items + anyOf alternatives', () {
    // Required item + at least one of the alternatives.
    final s = Synergy(
        name: 'Test Combo',
        items: ['Core'],
        anyOf: ['Option A', 'Option B', 'Option C']);

    test('required + one alternative → matches', () {
      expect(s.matchesItems(['core', 'option b']), true);
    });

    test('required but no alternative → no match', () {
      expect(s.matchesItems(['core']), false);
    });

    test('alternative but missing required → no match', () {
      expect(s.matchesItems(['option a', 'option b']), false);
    });
  });

  group('matchesItems — hardcoded special cases', () {
    test('Smart Bombs needs ≥2 of the alternatives', () {
      final s = Synergy(
          name: 'Smart Bombs',
          items: [],
          anyOf: ['Homing Bullets', 'Crutch', 'Shock Rounds']);
      expect(s.matchesItems(['homing bullets', 'crutch']), true);
      expect(s.matchesItems(['homing bullets']), false);
    });

    test('Super Serum needs gun AND defense categories', () {
      final s = Synergy(name: 'Super Serum', items: [], anyOf: []);
      expect(s.matchesItems(['plague pistol', 'gas mask']), true);
      expect(s.matchesItems(['plunger', 'hazmat suit']), true);
      expect(s.matchesItems(['plague pistol']), false);
      expect(s.matchesItems(['gas mask', 'hazmat suit']), false);
    });
  });

  group('missingFor', () {
    test('lists unowned required pieces', () {
      final s = Synergy(
          name: 'Trio', items: ['A', 'B', 'C']);
      final missing = s.missingFor({'a', 'c'});
      expect(missing, contains('B'));
      expect(missing, isNot(contains('A')));
    });

    test('no satisfied alternative adds "any of" placeholder', () {
      final s = Synergy(
          name: 'Combo', items: ['Core'], anyOf: ['X', 'Y']);
      final missing = s.missingFor({'core'});
      expect(missing.any((m) => m.startsWith('any of:')), true);
    });

    test('satisfied alternative adds no placeholder', () {
      final s = Synergy(
          name: 'Combo', items: ['Core'], anyOf: ['X', 'Y']);
      final missing = s.missingFor({'core', 'x'});
      expect(missing.any((m) => m.startsWith('any of:')), false);
    });
  });

  group('prettyEffect', () {
    test('prefix-only effect gets reformatted with alternatives', () {
      final s = Synergy(
          name: 'Flex',
          items: [],
          anyOf: ['Alpha', 'Beta', 'Gamma'],
          effect: 'One of the following items: AlphaBetaGamma');
      expect(s.prettyEffect,
          'Activates with one of: Alpha, Beta or Gamma.');
    });

    test('real effect text passes through untouched', () {
      final s = Synergy(
          name: 'Static',
          items: ['A'],
          anyOf: [],
          effect: 'Bullets bounce off walls.');
      expect(s.prettyEffect, 'Bullets bounce off walls.');
    });

    test('single alternative formats without comma list', () {
      final s = Synergy(
          name: 'Solo',
          items: [],
          anyOf: ['OnlyOne'],
          effect: 'Any of the following items: OnlyOne');
      expect(s.prettyEffect, 'Activates with one of: OnlyOne.');
    });
  });
}
