import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/models/gun.dart';
import 'package:gungeon_mate/models/item.dart';

/// Regression test for the description-fields gap: `ammonomicon_entry`
/// existed on every entity in the bundled data but was never parsed into
/// the models, so the flavour text could not render in detail screens.
void main() {
  group('ammonomicon_entry parsing', () {
    test('Item.fromJson parses and round-trips ammonomicon_entry', () {
      final item = Item.fromJson({
        'name': 'Test Item',
        'ammonomicon_entry': 'A very flavourful description.',
      });
      expect(item.ammonomiconEntry, 'A very flavourful description.');
      expect(item.toJson()['ammonomicon_entry'],
          'A very flavourful description.');
    });

    test('Gun.fromJson parses and round-trips ammonomicon_entry', () {
      final gun = Gun.fromJson({
        'name': 'Test Gun',
        'ammonomicon_entry': 'Bang bang, says the book.',
      });
      expect(gun.ammonomiconEntry, 'Bang bang, says the book.');
      expect(gun.toJson()['ammonomicon_entry'], 'Bang bang, says the book.');
    });

    test('missing ammonomicon_entry defaults to empty string', () {
      expect(Item.fromJson({'name': 'X'}).ammonomiconEntry, isEmpty);
      expect(Gun.fromJson({'name': 'X'}).ammonomiconEntry, isEmpty);
    });
  });
}
