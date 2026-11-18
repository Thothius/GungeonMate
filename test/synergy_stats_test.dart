import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/models/gun.dart';
import 'package:gungeon_mate/services/synergy_stats.dart';

Gun _gun({
  String damage = '5',
  String fireRate = '0.07',
  String reloadTime = '0.78',
  String magazineSize = '6',
  String ammoCapacity = '350',
  String spread = '5°',
  String shotSpeed = '23',
  String range = '35',
  String force = '10',
}) => Gun(
  name: 'Test Gun',
  damage: damage,
  fireRate: fireRate,
  reloadTime: reloadTime,
  magazineSize: magazineSize,
  ammoCapacity: ammoCapacity,
  spread: spread,
  shotSpeed: shotSpeed,
  range: range,
  force: force,
);

void main() {
  group('parseStatMods', () {
    test('simple percent increase', () {
      final mods = parseStatMods('Increases damage by 25%.');
      expect(mods, hasLength(1));
      expect(mods.single.stat, SynStat.damage);
      expect(mods.single.kind, ModKind.percent);
      expect(mods.single.value, 25);
    });

    test('decrease reload', () {
      final mods = parseStatMods('Decreases the reload time by 33%.');
      expect(mods.single.stat, SynStat.reload);
      expect(mods.single.value, -33);
    });

    test('halves reload time via multiplier word', () {
      final mods = parseStatMods('Halves the reload time of Wind Up Gun.');
      expect(mods.single.stat, SynStat.reload);
      expect(mods.single.value, -50);
    });

    test('magazine set value', () {
      final mods = parseStatMods('Increases magazine size to 27.');
      expect(mods.single.stat, SynStat.magazine);
      expect(mods.single.kind, ModKind.setTo);
      expect(mods.single.value, 27);
    });

    test('multi-stat clause', () {
      final mods = parseStatMods(
        'Increases damage by 30%, magazine size by 50%, spread by 50%, '
        'decreases reload time by 33%.',
      );
      final stats = mods.map((m) => m.stat).toSet();
      expect(
        stats,
        containsAll([
          SynStat.damage,
          SynStat.magazine,
          SynStat.spread,
          SynStat.reload,
        ]),
      );
    });

    test('enemy-side skipped', () {
      final mods = parseStatMods(
        'Increases damage by 25% and slows down enemy bullets by 20%.',
      );
      // damage kept, enemy-bullet clause contributes nothing extra
      expect(mods.every((m) => m.stat != SynStat.shotSpeed), isTrue);
    });

    test('decimals survive clause splitting (1.5x, 0.25%)', () {
      final mods = parseStatMods(
        'Spinning 360 degrees provides a 3-second buff that gives the next '
        'shot a 1.5x damage multiplier.',
      );
      final d = mods.firstWhere((m) => m.stat == SynStat.damage);
      expect(d.value, closeTo(50, 0.001));
    });

    test('projectile count instead-of', () {
      final mods = parseStatMods(
        'Big Shotgun fires 4 projectiles instead of 3.',
      );
      expect(mods.single.stat, SynStat.projectilesPerShot);
      expect(mods.single.kind, ModKind.setTo);
      expect(mods.single.value, 4);
    });
  });

  group('resolveDeltas', () {
    test('damage percent resolves old→new', () {
      final mods = parseStatMods('Grouch: increases damage by 25%.');
      final deltas = resolveDeltas(mods, _gun(damage: '8'));
      final d = deltas.firstWhere((d) => d.stat == SynStat.damage);
      expect(d.oldText, '8');
      expect(d.newText, '10');
      expect(d.improved, isTrue);
    });

    test('fire rate percent inverts interval', () {
      // "increases fire rate by 60%" → interval 0.07 / 1.6 ≈ 0.044
      final mods = parseStatMods('Increases fire rate by 60%.');
      final deltas = resolveDeltas(mods, _gun());
      final d = deltas.single;
      expect(d.stat, SynStat.fireRate);
      expect(d.newText, isNot('0.07'));
      expect(double.parse(d.newText), closeTo(0.04375, 0.001));
    });

    test('reload decrease lowers seconds', () {
      final mods = parseStatMods('Decreases reload time by 33%.');
      final deltas = resolveDeltas(mods, _gun(reloadTime: '0.9'));
      final d = deltas.single;
      expect(d.oldText, '0.9');
      expect(d.newText, '0.603');
    });

    test('set value overrides base', () {
      final mods = parseStatMods('Magazine size to 27.');
      final deltas = resolveDeltas(mods, _gun(magazineSize: '6'));
      expect(deltas.single.newText, '27');
    });
  });

  group('clauseAppliesTo', () {
    test('generic "the guns" applies', () {
      final mods = parseStatMods('Increases the damage of the guns by 50%.');
      expect(clauseAppliesTo(mods.single, 'Diazepam', {}), isTrue);
    });

    test('other-gun clause skipped', () {
      final mods = parseStatMods("Increases Ice Breaker's damage by 20%.");
      expect(
        clauseAppliesTo(mods.single, 'The Exotic', {'ice breaker'}),
        isFalse,
      );
      expect(
        clauseAppliesTo(mods.single, 'Ice Breaker', {'the exotic'}),
        isTrue,
      );
    });
  });

  group('statBaseNum', () {
    test('parses messy values', () {
      expect(statBaseNum('5'), 5);
      expect(statBaseNum('0.07'), 0.07);
      expect(statBaseNum('5°'), 5);
      expect(statBaseNum('15 3.8'), 15);
      expect(statBaseNum('N/A'), isNull);
      expect(statBaseNum(''), isNull);
    });
  });
  group('coverage sweep', () {
    test('parses mods for a healthy share of synergies.json', () {
      final raw = File('assets/data/synergies.json').readAsStringSync();
      final list = jsonDecode(raw) as List;
      var withMods = 0;
      var total = 0;
      for (final e in list) {
        final effect = (e as Map)['effect'] as String? ?? '';
        if (effect.isEmpty) continue;
        total++;
        if (parseStatMods(effect).isNotEmpty) withMods++;
      }
      // Informational floor — bump as the parser improves.
      expect(withMods, greaterThan(75));
      // ignore: avoid_print
      print('synergy stats coverage: $withMods / $total');
    });
  });
}
// Sweep: how many real synergies yield at least one parsed mod?
// Documents parser coverage; not a correctness assertion.
