import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/utils/asset_paths.dart';

/// Data integrity — guns.json / items.json / synergies.json coherence.
/// A typo'd synergy piece name or a missing icon asset breaks a
/// feature silently; these tests surface it at test time instead.
void main() {
  late RunProvider p;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
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

  // B3: gun/item `id` fields are provenance metadata (the models don't
  // parse them yet) — pin uniqueness so a future consumer (MP refs,
  // wiki deep-links, robot_tier joins) can't inherit a silent collision
  // like the historical id-50 Colt 1851 / SAA clash.
  test('gun and item ids are unique where present', () {
    final offenders = <String>[];
    for (final file in ['guns', 'items']) {
      final raw =
          (jsonDecode(
                    File('assets/data/$file.json').readAsStringSync(),
                  )
                  as List)
              .cast<Map<String, dynamic>>();
      final seen = <dynamic, String>{};
      for (final e in raw) {
        final id = e['id'];
        if (id == null) continue;
        final prev = seen[id];
        if (prev != null) {
          offenders.add('$file id=$id: "$prev" vs "${e['name']}"');
        } else {
          seen[id] = e['name'] as String;
        }
      }
    }
    expect(offenders, isEmpty, reason: 'duplicate ids:\n${offenders.join('\n')}');
  });

  test('robot_tier values are from the known set', () {
    const valid = {'god', 'armor', 'dead'};
    final bad = <String>[];
    for (final file in ['guns', 'items']) {
      final raw =
          (jsonDecode(
                    File('assets/data/$file.json').readAsStringSync(),
                  )
                  as List)
              .cast<Map<String, dynamic>>();
      for (final e in raw) {
        final t = e['robot_tier'];
        if (t != null && !valid.contains(t)) {
          bad.add('$file: "${e['name']}" → "$t"');
        }
      }
    }
    expect(bad, isEmpty, reason: 'invalid robot_tier values:\n${bad.join('\n')}');
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

  test('synergy icon slug set matches the assets/images/synergies dir', () {
    // kSynergyIconSlugs gates localSynergyIcon(): a slug in the set gets a
    // real icon path, anything else returns '' so UIs fall back to a
    // piece icon. Drift in either direction breaks that contract.
    final onDisk =
        Directory('assets/images/synergies')
            .listSync()
            .whereType<File>()
            .map((f) => f.uri.pathSegments.last.replaceAll('.webp', ''))
            .toSet();
    expect(
      onDisk,
      kSynergyIconSlugs,
      reason:
          'add/remove the .webp and update kSynergyIconSlugs in '
          'lib/utils/asset_paths.dart',
    );
    // Every synergy WITH dedicated art resolves to an existing file.
    final missing = <String>[];
    for (final s in p.allSynergies) {
      final icon = s.icon;
      if (icon.isNotEmpty && !File(icon).existsSync()) {
        missing.add('${s.name} -> $icon');
      }
    }
    expect(
      missing,
      isEmpty,
      reason: 'missing synergy icons:\n${missing.join('\n')}',
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
