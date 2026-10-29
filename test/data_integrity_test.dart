import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/providers/run_provider.dart';

/// Data integrity — guns.json / items.json / synergies.json coherence.
/// A typo'd synergy piece name or a missing icon asset breaks a
/// feature silently; these tests surface it at test time instead.
void main() {
  late RunProvider p;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    p = RunProvider();
    await p.loadData();
  });

  test('datasets are populated', () {
    expect(p.allGuns.length, greaterThan(100));
    expect(p.allItems.length, greaterThan(100));
    expect(p.allSynergies.length, greaterThan(50));
  });

  test('no duplicate gun or item names', () {
    final names = <String>{};
    final dupes = <String>[];
    for (final g in p.allGuns) {
      if (!names.add(g.name.toLowerCase())) dupes.add('gun:${g.name}');
    }
    for (final i in p.allItems) {
      if (!names.add(i.name.toLowerCase())) dupes.add('item:${i.name}');
    }
    expect(dupes, isEmpty, reason: 'duplicate names: $dupes');
  });

  test('every synergy piece resolves to a real gun or item', () {
    final broken = <String>[];
    for (final s in p.allSynergies) {
      for (final piece in [...s.items, ...s.anyOf]) {
        final r = p.entityByName(piece);
        if (r.gun == null && r.item == null) {
          broken.add('${s.name}: "$piece"');
        }
      }
    }
    expect(
      broken,
      isEmpty,
      reason: 'unresolvable synergy pieces:\n${broken.join('\n')}',
    );
  });

  test('gun/item icon paths point at files that exist', () {
    final missing = <String>[];
    void check(String owner, String icon) {
      if (icon.isEmpty) return;
      // Icon fields may be bare stems or full asset paths.
      final path =
          icon.startsWith('assets/') ? icon : 'assets/images/icons/$icon';
      if (!File(path).existsSync()) missing.add('$owner -> $icon');
    }

    for (final g in p.allGuns) {
      check('gun:${g.name}', g.icon);
    }
    for (final i in p.allItems) {
      check('item:${i.name}', i.icon);
    }
    expect(
      missing,
      isEmpty,
      reason:
          '${missing.length} missing icons:\n${missing.take(20).join('\n')}',
    );
  });

  test('every gun has a name and a quality tier', () {
    final bad = <String>[];
    for (final g in p.allGuns) {
      if (g.name.trim().isEmpty) bad.add('empty-name gun');
      if (g.quality.trim().isEmpty) bad.add('${g.name}: no quality');
    }
    expect(bad, isEmpty, reason: bad.take(20).join('\n'));
  });

  test('every item has a name and a quality tier', () {
    final bad = <String>[];
    for (final i in p.allItems) {
      if (i.name.trim().isEmpty) bad.add('empty-name item');
      if (i.quality.trim().isEmpty) bad.add('${i.name}: no quality');
    }
    expect(bad, isEmpty, reason: bad.take(20).join('\n'));
  });
}
