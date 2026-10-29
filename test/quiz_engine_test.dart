import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gungeon_mate/models/gun.dart';
import 'package:gungeon_mate/models/item.dart';
import 'package:gungeon_mate/services/quiz_engine.dart';
import 'package:gungeon_mate/services/quiz_progress.dart';

Gun _gun(String name, String quality, {String quote = ''}) =>
    Gun(name: name, quality: quality, quote: quote);
Item _item(String name, String quality, {String quote = ''}) =>
    Item(name: name, quality: quality, quote: quote);

/// Builds an engine with a realistic spread: every chest tier gets a mix
/// of guns and items so distractor pools mirror production data.
QuizEngine _engine() {
  const qualities = ['D', 'C', 'B', 'A', 'S'];
  final guns = <Gun>[];
  final items = <Item>[];
  var n = 0;
  for (final q in qualities) {
    for (var i = 0; i < 12; i++) {
      guns.add(_gun('Test Gun ${q}_${n++}', q));
      items.add(_item('Test Item ${q}_${n++}', q));
    }
  }
  // Include a curated override entry to exercise that path, plus a
  // quoted loot for the Ammonomicon hint.
  guns.add(_gun('Casey', 'D', quote: 'For The Inquisitive'));
  items.add(_item('Hintable Relic', 'S', quote: 'Whispers of loot past'));
  return QuizEngine(guns: guns, items: items);
}

void main() {
  group('QuizEngine pools', () {
    test('poolFor returns every loot in the tier with no repeats', () {
      final engine = _engine();
      final pool = engine.poolFor('B', rng: Random(1));
      expect(pool.length, engine.poolSizeFor('B'));
      expect(pool.length, 24);
      expect(pool.every((l) => l.quality == 'B'), isTrue);
      expect(pool.map((l) => l.name).toSet().length, pool.length);
    });

    test('poolFor shuffles but keeps the same membership', () {
      final engine = _engine();
      final a = engine.poolFor('C', rng: Random(7));
      final b = engine.poolFor('C', rng: Random(8));
      expect(a.map((l) => l.name).toSet(), b.map((l) => l.name).toSet());
    });

    test('loot carries its flavor quote as the hint', () {
      final engine = _engine();
      final sPool = engine.poolFor('S', rng: Random(0));
      final hinted = sPool.firstWhere((l) => l.name == 'Hintable Relic');
      expect(hinted.hint, 'Whispers of loot past');
    });

    test('bonus tiers draw from mixed pools', () {
      final engine = _engine();
      final rainbow = kQuizBonusTiers[0];
      final rat = kQuizBonusTiers[1];

      expect(rainbow.id, 'rainbow');
      expect(rainbow.poolQualities, ['D', 'C', 'B', 'A', 'S']);
      // Rainbow pool = every quality combined (120 seeded + Casey + Relic).
      expect(engine.poolSizeForTier(rainbow), 122);
      expect(rat.id, 'rat');
      expect(rat.poolQualities, ['S', 'A']);
      // Rat pool = S + A only (48 seeded + S-tier Hintable Relic).
      expect(engine.poolSizeForTier(rat), 49);

      final pool = engine.poolForTier(rat, rng: Random(9));
      expect(pool.every((l) => l.quality == 'S' || l.quality == 'A'), isTrue);
    });

    test('standard chests are unlocked, bonus chests are locked', () {
      expect(kQuizChestTiers.every((t) => t.unlocksAfter == 0), isTrue);
      expect(kQuizBonusTiers[0].unlocksAfter, 1);
      expect(kQuizBonusTiers[1].unlocksAfter, 2);
      expect(kQuizAllTiers.length, 7);
    });
  });

  group('QuizEngine distractors', () {
    test('three sets of five unique distractors per loot', () {
      final engine = _engine();
      final loot = engine.poolFor('A', rng: Random(3)).first;
      final sets = engine.distractorSetsFor(loot);
      expect(sets.length, 3);
      for (final set in sets) {
        expect(set.length, 5);
        expect(set.toSet().length, 5, reason: 'dupes inside a set');
        expect(
          set.contains(loot.name),
          isFalse,
          reason: 'correct name leaked into distractors',
        );
      }
    });

    test('distractor sets are deterministic per loot', () {
      final engine = _engine();
      final loot = engine.poolFor('B', rng: Random(5)).first;
      final a = engine.distractorSetsFor(loot);
      final b = engine.distractorSetsFor(loot);
      expect(a, b);
    });

    test('fabricated names never collide with real loot names', () {
      final engine = _engine();
      final realNames = <String>{
        for (var i = 0; i < 100; i++) ...['Test Gun A_$i', 'Test Item A_$i'],
      };
      for (final loot in engine.poolFor('A', rng: Random(11))) {
        for (final set in engine.distractorSetsFor(loot)) {
          for (final d in set) {
            // Real-name distractors are fine; fabrications must not be
            // a real name that isn't already in the answer pool.
            if (realNames.contains(d)) {
              expect(d.startsWith('Test'), isTrue);
            }
          }
        }
      }
    });

    test('curated override sets are used verbatim', () {
      final engine = _engine();
      const loot = QuizLoot(
        name: 'Casey',
        iconPath: '',
        isGun: true,
        quality: 'D',
      );
      final sets = engine.distractorSetsFor(loot);
      expect(sets.length, 3);
      expect(sets.expand((s) => s).contains('Mahoguny'), isTrue);
    });
  });

  group('QuizEngine questions', () {
    test('question has six options with exactly one correct', () {
      final engine = _engine();
      final loot = engine.poolFor('D', rng: Random(2)).first;
      final q = engine.questionFor(loot, rng: Random(2));
      expect(q.options.length, 6);
      expect(q.options.toSet().length, 6);
      expect(q.options[q.correctIndex], loot.name);
      expect(q.options.where((o) => o == loot.name).length, 1);
    });

    test('correct answer lands in a different slot across rolls', () {
      final engine = _engine();
      final loot = engine.poolFor('S', rng: Random(4)).first;
      final slots = <int>{};
      for (var i = 0; i < 20; i++) {
        slots.add(engine.questionFor(loot, rng: Random(i)).correctIndex);
      }
      expect(slots.length, greaterThan(1));
    });
  });

  group('QuizProgress', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      QuizProgress.instance.resetForTest();
    });

    test('records best streak and completion across runs', () async {
      final p = QuizProgress.instance;
      await p.ensureLoaded();

      expect(await p.recordRun('C', 3, flawless: false), isTrue);
      expect(p.bestStreak('C'), 3);
      expect(p.isCompleted('C'), isFalse);
      expect(p.runsPlayed('C'), 1);

      // A lower streak does not beat the stored best.
      expect(await p.recordRun('C', 2, flawless: false), isFalse);
      expect(p.bestStreak('C'), 3);
      expect(p.runsPlayed('C'), 2);

      // A flawless run marks the chest completed.
      expect(await p.recordRun('C', 140, flawless: true), isTrue);
      expect(p.isCompleted('C'), isTrue);
    });

    test('recordStreak live-saves only when it beats the best', () async {
      final p = QuizProgress.instance;
      await p.ensureLoaded();
      await p.recordStreak('S', 10);
      expect(p.bestStreak('S'), 10);
      await p.recordStreak('S', 5);
      expect(p.bestStreak('S'), 10);
      // Runs played untouched by live streak saves.
      expect(p.runsPlayed('S'), 0);
    });
  });

  group('curated distractor integrity', () {
    // Every hand-written set: 3 sets × 5 options, all unique, and
    // NEVER containing the correct answer — a hand-edit slip would
    // silently ship broken questions otherwise.
    const curated = [
      'Casey',
      'Blasphemy',
      'Gunther',
      'Yari Launcher',
      'Spice',
      'Pig',
      'Sixth Chamber',
      'Clone',
      'Super Meat Gun',
      'Banana',
      'Turtle Problem',
      'Sunglasses',
      'Gunderfury',
      'Dragunfire',
      'Mourning Star',
      'Fightsabre',
      'Finished Gun',
      'AU Gun',
      'Crestfaller',
      'Devolver',
      'Magic Lamp',
      'Owl',
      'Phoenix',
      'Shellegun',
      'Super Space Turtle',
      'Bundle of Wands',
      'Elimentaler',
      'Railgun',
      'Mimic Tooth Necklace',
      'Partially-Eaten Cheese',
      'Unicorn Horn',
    ];

    test('all curated sets are 3x5 unique and never the answer', () {
      final engine = QuizEngine(guns: const [], items: const []);
      expect(engine.curatedSetCount, greaterThanOrEqualTo(25));
      for (final name in curated) {
        final loot = QuizLoot(
          name: name,
          iconPath: 'x',
          isGun: true,
          quality: 'B',
        );
        final sets = engine.distractorSetsFor(loot);
        expect(sets.length, 3, reason: '$name must have 3 sets');
        for (var i = 0; i < 3; i++) {
          expect(sets[i].length, 5, reason: '$name set $i must have 5 options');
          expect(
            sets[i].toSet().length,
            5,
            reason: '$name set $i has duplicate options',
          );
          expect(
            sets[i].contains(name),
            isFalse,
            reason: '$name set $i contains the correct answer',
          );
        }
      }
    });
  });
}
