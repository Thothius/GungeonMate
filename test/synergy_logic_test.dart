import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/models/synergy.dart';

/// Synergy matching logic — the rules behind PARTIAL/COMPLETE
/// grouping and the "would complete" predictor in browse.
void main() {
  group('matchesItems — plain N-of-N', () {
    final s = Synergy(name: 'Test Pair', items: ['Alpha', 'Beta']);

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
      anyOf: ['Option A', 'Option B', 'Option C'],
    );

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

  group('matchesItems — groups (AND-of-OR pools)', () {
    // Smart Bombs: (Bomb|Ice Bomb) AND (Crutch|Homing Bullets)
    final smartBombs = Synergy(
      name: 'Smart Bombs',
      items: [],
      anyOf: ['Bomb', 'Ice Bomb', 'Crutch', 'Homing Bullets'],
      groups: [
        ['Bomb', 'Ice Bomb'],
        ['Crutch', 'Homing Bullets'],
      ],
    );

    test('one member per group → matches', () {
      expect(smartBombs.matchesItems(['bomb', 'crutch']), true);
      expect(smartBombs.matchesItems(['ice bomb', 'homing bullets']), true);
    });

    test('two members of one group only → no match', () {
      expect(smartBombs.matchesItems(['bomb', 'ice bomb']), false);
      expect(smartBombs.matchesItems(['crutch', 'homing bullets']), false);
    });

    test('missing a whole group → no match', () {
      expect(smartBombs.matchesItems(['bomb']), false);
      expect(smartBombs.matchesItems(['crutch', 'homing bullets', 'bomb']),
          true);
    });

    // Unbelievably Charming: (Charmed Bow|Shotgun Full of Love)
    // AND (Charming Rounds|Pink Guon Stone) — two guns alone must NOT match.
    final charming = Synergy(
      name: 'Unbelievably Charming',
      items: [],
      anyOf: [
        'Charmed Bow',
        'Shotgun Full of Love',
        'Charming Rounds',
        'Pink Guon Stone',
      ],
      groups: [
        ['Charmed Bow', 'Shotgun Full of Love'],
        ['Charming Rounds', 'Pink Guon Stone'],
      ],
    );

    test('gun + item combo → matches', () {
      expect(
        charming.matchesItems(['charmed bow', 'pink guon stone']),
        true,
      );
    });

    test('two guns or two items → no match', () {
      expect(
        charming.matchesItems([
          'charmed bow',
          'shotgun full of love',
        ]),
        false,
      );
      expect(
        charming.matchesItems(['charming rounds', 'pink guon stone']),
        false,
      );
    });

    test('groups round-trip through JSON', () {
      final s = Synergy.fromJson({
        'name': 'G',
        'items': [],
        'groups': [
          ['A', 'B'],
          ['C'],
        ],
      });
      expect(s.matchesItems(['b', 'c']), true);
      expect(s.matchesItems(['a']), false);
      expect(s.toJson()['groups'], [
        ['A', 'B'],
        ['C'],
      ]);
    });
  });

  group('matchesItems — anyOfMin (K-of-N pools)', () {
    // In The Mood!: any 2 of BSG / Thunderclap / Strafe Gun.
    final mood = Synergy(
      name: 'In The Mood!',
      items: const [],
      anyOf: ['BSG', 'Thunderclap', 'Strafe Gun'],
      anyOfMin: 2,
    );

    test('two of three → matches', () {
      expect(mood.matchesItems(['bsg', 'strafe gun']), true);
      expect(mood.matchesItems(['thunderclap', 'strafe gun']), true);
    });

    test('one of three → no match', () {
      expect(mood.matchesItems(['bsg']), false);
    });

    test('all three → matches', () {
      expect(
        mood.matchesItems(['bsg', 'thunderclap', 'strafe gun']),
        true,
      );
    });

    test('mandatory item still required alongside pool picks', () {
      // Chief Master: Alien Sidearm + any 2 of 5 Master Rounds.
      final chief = Synergy(
        name: 'Chief Master',
        items: const ['Alien Sidearm'],
        anyOf: const [
          'Master Round I',
          'Master Round II',
          'Master Round III',
          'Master Round IV',
          'Master Round V',
        ],
        anyOfMin: 2,
      );
      expect(
        chief.matchesItems(['alien sidearm', 'master round i', 'master round iii']),
        true,
      );
      expect(
        chief.matchesItems(['alien sidearm', 'master round i']),
        false,
      );
      expect(
        chief.matchesItems(['master round i', 'master round ii']),
        false,
      );
    });

    test('missingFor reports the pick deficit', () {
      final missing = mood.missingFor({'bsg'});
      expect(missing.any((m) => m.startsWith('any of:')), true);
      final none = mood.missingFor(const {});
      expect(none.any((m) => m.startsWith('any 2 of:')), true);
      final done = mood.missingFor({'bsg', 'thunderclap'});
      expect(done.any((m) => m.startsWith('any')), false);
    });

    test('any_of_min round-trips through JSON', () {
      final s = Synergy.fromJson({
        'name': 'K',
        'items': [],
        'any_of': ['A', 'B', 'C'],
        'any_of_min': 2,
      });
      expect(s.requiredAnyOfCount, 2);
      expect(s.toJson()['any_of_min'], 2);
      expect(s.matchesItems(['a', 'b']), true);
      expect(s.matchesItems(['a']), false);
    });
  });

  group('activation — game-disabled synergies', () {
    test('INACTIVE never matches even with all pieces', () {
      final s = Synergy(
        name: 'Cut Content',
        items: const ['A', 'B'],
        activation: 'INACTIVE',
      );
      expect(s.isGameInactive, true);
      // matching itself stays pure — the query layer filters these out
      expect(s.matchesItems(['a', 'b']), true);
      expect(s.toJson()['activation'], 'INACTIVE');
    });

    test('default activation is ACTIVE', () {
      final s = Synergy(name: 'Live', items: const ['A']);
      expect(s.isGameInactive, false);
      expect(s.toJson().containsKey('activation'), false);
    });
  });

  group('missingFor', () {
    test('lists unowned required pieces', () {
      final s = Synergy(name: 'Trio', items: ['A', 'B', 'C']);
      final missing = s.missingFor({'a', 'c'});
      expect(missing, contains('B'));
      expect(missing, isNot(contains('A')));
    });

    test('no satisfied alternative adds "any of" placeholder', () {
      final s = Synergy(name: 'Combo', items: ['Core'], anyOf: ['X', 'Y']);
      final missing = s.missingFor({'core'});
      expect(missing.any((m) => m.startsWith('any of:')), true);
    });

    test('satisfied alternative adds no placeholder', () {
      final s = Synergy(name: 'Combo', items: ['Core'], anyOf: ['X', 'Y']);
      final missing = s.missingFor({'core', 'x'});
      expect(missing.any((m) => m.startsWith('any of:')), false);
    });

    test('groups report one "any of" entry per unsatisfied group', () {
      final s = Synergy(
        name: 'G',
        items: const [],
        groups: [
          ['A', 'B'],
          ['C', 'D'],
        ],
      );
      final missing = s.missingFor({'a'});
      expect(missing, hasLength(1));
      expect(missing.single, 'any of: C, D');
    });
  });

  group('prettyEffect', () {
    test('prefix-only effect gets reformatted with alternatives', () {
      final s = Synergy(
        name: 'Flex',
        items: [],
        anyOf: ['Alpha', 'Beta', 'Gamma'],
        effect: 'One of the following items: AlphaBetaGamma',
      );
      expect(s.prettyEffect, 'Activates with one of: Alpha, Beta or Gamma.');
    });

    test('real effect text passes through untouched', () {
      final s = Synergy(
        name: 'Static',
        items: ['A'],
        anyOf: [],
        effect: 'Bullets bounce off walls.',
      );
      expect(s.prettyEffect, 'Bullets bounce off walls.');
    });

    test('single alternative formats without comma list', () {
      final s = Synergy(
        name: 'Solo',
        items: [],
        anyOf: ['OnlyOne'],
        effect: 'Any of the following items: OnlyOne',
      );
      expect(s.prettyEffect, 'Activates with one of: OnlyOne.');
    });
  });
}
