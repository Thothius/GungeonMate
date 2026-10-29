import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/utils/run_name_generator.dart';

/// RunNameGenerator — Paradox run names shown in the MP bar and
/// notification ("Cursed Dragunfall" style).
void main() {
  test('roll() produces a non-empty two-word name', () {
    final name = RunNameGenerator.roll();
    expect(name.trim(), isNotEmpty);
    expect(name.trim().contains(' '), true,
        reason: 'expected adjective+noun form, got "$name"');
  });

  test('500 rolls never crash and always produce names', () {
    final names = <String>{};
    for (var i = 0; i < 500; i++) {
      final n = RunNameGenerator.roll();
      expect(n.trim(), isNotEmpty);
      names.add(n);
    }
    // With ~18 adjectives x ~34 nouns there must be variety —
    // a degenerate generator returning the same name is a bug.
    expect(names.length, greaterThan(50));
  });
}
