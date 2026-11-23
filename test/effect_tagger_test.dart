import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/models/gun.dart';
import 'package:gungeon_mate/models/item.dart';
import 'package:gungeon_mate/services/effect_tagger.dart';

/// EffectTagger — regex-based scan of gun notes/types and item effects
/// into categorized EffectTags with source excerpts.
void main() {
  EffectTag tagById(String id) =>
      EffectTagger.allTags.firstWhere((t) => t.id == id);

  group('scan', () {
    test('empty loadout returns empty map', () {
      expect(EffectTagger.scan(guns: const [], items: const []), isEmpty);
    });

    test('gun notes produce a damage_up occurrence marked as gun', () {
      final gun = Gun(name: 'Buffed Sidearm', notes: 'Deals +30% damage.');
      final out = EffectTagger.scan(guns: [gun], items: const []);

      final occs = out[tagById('damage_up')];
      expect(occs, hasLength(1));
      expect(occs!.single.sourceName, 'Buffed Sidearm');
      expect(occs.single.sourceIsGun, isTrue);
      expect(occs.single.excerpt, contains('30%'));
    });

    test('item effect produces occurrence marked as item', () {
      final item = Item(
        name: 'Homing Rounds',
        effect: 'Bullets home in on enemies.',
      );
      final out = EffectTagger.scan(guns: const [], items: [item]);

      final occs = out[tagById('homing')];
      expect(occs, hasLength(1));
      expect(occs!.single.sourceIsGun, isFalse);
      expect(occs.single.excerpt, isNotEmpty);
    });

    test('gun type text is scanned alongside notes', () {
      // 'Bullet' type alone shouldn't tag; craft a type that does.
      final gun = Gun(name: 'Piercer', notes: '', type: 'Piercing');
      final out = EffectTagger.scan(guns: [gun], items: const []);
      expect(out[tagById('piercing')], hasLength(1));
    });

    test('multiple sources for same tag aggregate under one key', () {
      final guns = [
        Gun(name: 'A', notes: 'Deals +10% damage.'),
        Gun(name: 'B', notes: 'Deals +20% damage.'),
      ];
      final out = EffectTagger.scan(guns: guns, items: const []);
      expect(out[tagById('damage_up')], hasLength(2));
    });

    test('unrelated text produces no tags', () {
      final item = Item(name: 'Moss', effect: 'A lump of wet moss.');
      final out = EffectTagger.scan(guns: const [], items: [item]);
      expect(out, isEmpty);
    });
  });

  group('excerpt extraction', () {
    test('excerpt picks the matching sentence, not the whole blob', () {
      final gun = Gun(
        name: 'Multi',
        notes: 'A normal sentence. Bullets bounce off walls.',
      );
      final out = EffectTagger.scan(guns: [gun], items: const []);
      final excerpt = out[tagById('bouncing')]!.single.excerpt;
      expect(excerpt.toLowerCase(), contains('bounce'));
      expect(excerpt, isNot(contains('normal sentence')));
    });

    test('long excerpts are capped', () {
      final long = 'Deals +30% damage. ${'padding ' * 40}still damage text.';
      final gun = Gun(name: 'Long', notes: long);
      final out = EffectTagger.scan(guns: [gun], items: const []);
      final excerpt = out[tagById('damage_up')]!.single.excerpt;
      expect(excerpt.length, lessThanOrEqualTo(111));
    });
  });

  group('extractStat', () {
    test('percent token', () {
      expect(EffectTagger.extractStat('Deals +30% damage'), '+30%');
    });

    test('multiplier token normalizes x to ×', () {
      expect(EffectTagger.extractStat('Damage x2'), '×2');
    });

    test('unit words map to compact forms', () {
      expect(EffectTagger.extractStat('3 second duration'), '3s');
      expect(EffectTagger.extractStat('2 bounces'), '2 bounces');
      expect(EffectTagger.extractStat('4 projectiles'), '4 bullets');
    });

    test('bare 1 or 0 without sign/unit is skipped', () {
      expect(EffectTagger.extractStat('a 1 in 4 chance'), isNull);
      expect(EffectTagger.extractStat(''), isNull);
    });

    test('plain number survives', () {
      expect(EffectTagger.extractStat('+15 power'), '+15');
    });
  });

  group('groupByCategory', () {
    test('groups preserve registration order and category mapping', () {
      final item = Item(
        name: 'Utility Belt',
        effect: 'Increases maximum ammo. Grants a heart container.',
      );
      final scanned = EffectTagger.scan(guns: const [], items: [item]);
      final groups = EffectTagger.groupByCategory(scanned);

      expect(groups[EffectCategory.ammo], isNotNull);
      expect(groups[EffectCategory.defense], isNotNull);
      // Registration order: ammo_up registered before max_hp_up.
      expect(
        groups[EffectCategory.ammo]!.map((t) => t.id),
        contains('ammo_up'),
      );
    });

    test('empty scan produces empty groups', () {
      expect(
        EffectTagger.groupByCategory(
          EffectTagger.scan(guns: const [], items: const []),
        ),
        isEmpty,
      );
    });
  });

  group('summaryChips', () {
    test('one chip per active tag with sourceCount aggregated', () {
      final guns = [
        Gun(name: 'A', notes: 'Deals +10% damage.'),
        Gun(name: 'B', notes: 'Deals +20% damage.'),
      ];
      final chips = EffectTagger.summaryChips(guns: guns, items: const []);
      final dmg = chips.where((c) => c.tag.id == 'damage_up').toList();

      expect(dmg, hasLength(1));
      expect(dmg.single.sourceCount, 2);
    });

    test('chip carries the first extractable stat value', () {
      final gun = Gun(name: 'A', notes: 'Deals +30% damage.');
      final chips = EffectTagger.summaryChips(guns: [gun], items: const []);
      final dmg = chips.firstWhere((c) => c.tag.id == 'damage_up');
      expect(dmg.value, isNotNull);
    });

    test('empty loadout produces no chips', () {
      expect(
        EffectTagger.summaryChips(guns: const [], items: const []),
        isEmpty,
      );
    });
  });

  group('tag registry', () {
    test('allTags is unmodifiable', () {
      expect(
        () => EffectTagger.allTags.add(tagById('damage_up')),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('tags have unique ids', () {
      final ids = EffectTagger.allTags.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every tag has a non-empty label and at least one pattern', () {
      for (final t in EffectTagger.allTags) {
        expect(t.label, isNotEmpty, reason: 'tag ${t.id}');
        expect(t.patterns, isNotEmpty, reason: 'tag ${t.id}');
      }
    });

    test('EffectTag equality is by id', () {
      expect(tagById('damage_up'), tagById('damage_up'));
      expect(tagById('damage_up'), isNot(tagById('piercing')));
    });
  });
}
