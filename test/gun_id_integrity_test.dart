import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Gun `id` provenance guard (L1).
///
/// `id` in guns.json is meant to be the game dump's PickupObjectId —
/// merge tooling (tools/merge_*.py) joins on it. It is NOT read by the
/// app at runtime (Gun has no id field), but a duplicate or wrong id is
/// a latent trap for the next data merge. Non-null ids must be unique;
/// null means "no dump counterpart" (app-only entry).
void main() {
  test('gun ids are unique (null allowed for app-only guns)', () {
    final raw = json.decode(
      File('assets/data/guns.json').readAsStringSync(),
    ) as List;
    final seen = <int, String>{};
    final dupes = <String>[];
    for (final g in raw) {
      final id = g['id'];
      if (id == null) continue;
      final prev = seen[id];
      if (prev != null) {
        dupes.add('id $id shared by "$prev" and "${g['name']}"');
      } else {
        seen[id] = g['name'] as String;
      }
    }
    expect(dupes, isEmpty, reason: dupes.join('; '));
  });
}
