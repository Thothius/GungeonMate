import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Entity `id` provenance guard (L1, extended S3.1).
///
/// `id` in guns.json/items.json is meant to be the game dump's
/// PickupObjectId — merge tooling (tools/merge_*.py) joins on it. It is
/// NOT read by the app at runtime (Gun/Item have no id field), but a
/// duplicate or wrong id is a latent trap for the next data merge —
/// U-015 was exactly this bug class in items.json. Non-null ids must be
/// unique per file; null means "no dump counterpart" (app-only entry).
void main() {
  for (final file in ['guns.json', 'items.json']) {
    test('$file ids are unique (null allowed for app-only entries)', () {
      final raw = json.decode(
        File('assets/data/$file').readAsStringSync(),
      ) as List;
      final seen = <int, String>{};
      final dupes = <String>[];
      for (final e in raw) {
        final id = e['id'];
        if (id == null) continue;
        final name = e['name'] as String? ?? '?';
        final prev = seen[id];
        if (prev != null) {
          dupes.add('id $id shared by "$prev" and "$name"');
        } else {
          seen[id] = name;
        }
      }
      expect(dupes, isEmpty, reason: dupes.join('; '));
    });
  }
}
