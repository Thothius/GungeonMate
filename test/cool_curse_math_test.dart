import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/utils/cool_curse_math.dart';

void main() {
  group('curseTable', () {
    test('has 11 rows covering curse 0-10', () {
      expect(curseTable.length, 11);
      for (var i = 0; i <= 10; i++) {
        expect(curseTable[i].curse, i);
      }
    });
  });

  group('jammedEnemyChance', () {
    test('matches wiki table at every integer 0-10', () {
      const expected = [0, 1, 1, 2, 2, 5, 5, 10, 10, 25, 50];
      for (var c = 0; c <= 10; c++) {
        expect(jammedEnemyChance(c.toDouble()), expected[c],
            reason: 'curse $c');
      }
    });

    test('caps at 50% for curse above 10', () {
      expect(jammedEnemyChance(10), 50);
      expect(jammedEnemyChance(15), 50);
      expect(jammedEnemyChance(99), 50);
    });

    test('fractional curse floors to table index', () {
      expect(jammedEnemyChance(5.9), 5);
      expect(jammedEnemyChance(9.99), 25);
    });
  });

  group('jammedBossChance', () {
    test('matches wiki table — starts at curse 7', () {
      const expected = [0, 0, 0, 0, 0, 0, 0, 20, 20, 30, 50];
      for (var c = 0; c <= 10; c++) {
        expect(jammedBossChance(c.toDouble()), expected[c],
            reason: 'curse $c');
      }
    });

    test('caps at 50% for curse above 10', () {
      expect(jammedBossChance(12), 50);
    });
  });

  group('curse side-effects', () {
    test('mimic chance is 2.25 + 2.1/pt', () {
      expect(mimicChance(0), closeTo(2.25, 0.001));
      expect(mimicChance(5), closeTo(12.75, 0.001));
      expect(mimicChance(10), closeTo(23.25, 0.001));
    });

    test('fuse bonus is +5%/pt and keeps scaling past 10', () {
      expect(curseFuseBonus(0), 0);
      expect(curseFuseBonus(5), 25);
      expect(curseFuseBonus(10), 50);
      expect(curseFuseBonus(12), 60);
    });

    test('ammo multiplier is x1.05/pt', () {
      expect(ammoDropMultiplier(0), closeTo(1.0, 0.001));
      expect(ammoDropMultiplier(10), closeTo(1.5, 0.001));
      expect(ammoDropMultiplier(20), closeTo(2.0, 0.001));
    });
  });

  group('coolness side-effects', () {
    test('cooldown reduction 5%/pt caps at 50%', () {
      expect(cooldownReduction(0), 0);
      expect(cooldownReduction(5), 25);
      expect(cooldownReduction(10), 50);
      expect(cooldownReduction(20), 50);
    });

    test('fuse chance reduction 2.5%/pt caps at 10%', () {
      expect(fuseChanceReduction(0), 0);
      expect(fuseChanceReduction(4), 10);
      expect(fuseChanceReduction(10), 10);
    });

    test('room reward chance is (1 + cool - curse), floored at 0', () {
      expect(roomRewardChance(0, 0), 1);
      expect(roomRewardChance(5, 2), 4);
      expect(roomRewardChance(0, 5), 0);
      expect(roomRewardChance(0, 50), 0);
    });
  });

  group('consistency anchors (L5-1 regression)', () {
    test('curse 5 shows 5% enemy / 0% boss — not linear extrapolation', () {
      // The old cool_curse_screen showed curse*4=20% / curse*2=10% here.
      expect(jammedEnemyChance(5), 5);
      expect(jammedBossChance(5), 0);
    });

    test('jam chances never exceed 50% even at extreme curse', () {
      for (var c = 0; c <= 30; c++) {
        expect(jammedEnemyChance(c.toDouble()), lessThanOrEqualTo(50));
        expect(jammedBossChance(c.toDouble()), lessThanOrEqualTo(50));
      }
    });
  });
}
