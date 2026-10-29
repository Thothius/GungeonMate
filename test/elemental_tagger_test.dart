import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/models/gun.dart';
import 'package:gungeon_mate/models/item.dart';
import 'package:gungeon_mate/services/elemental_tagger.dart';

/// ElementalTagger — the keyword→element mapping that drives the
/// status icons on the gun detail header + NOTES tab.
void main() {
  test('gunClass FIRE tags as fire', () {
    final g = Gun(name: 'Test', gunClass: 'FIRE');
    expect(
        ElementalTagger.elementsOfGun(g), contains(ElementKind.fire));
  });

  test('gunClass ICE tags as freeze', () {
    final g = Gun(name: 'Test', gunClass: 'ICE');
    expect(
        ElementalTagger.elementsOfGun(g), contains(ElementKind.freeze));
  });

  test('notes with ignition verbs tag as fire', () {
    final g = Gun(
        name: 'Test',
        notes: 'Ignites enemies and leaves them burning.');
    expect(
        ElementalTagger.elementsOfGun(g), contains(ElementKind.fire));
  });

  test('generic fire-adjacent words do NOT tag as fire', () {
    // 'fires' / 'rapid fire' should not false-positive per the
    // tagger's conservative rules.
    final g = Gun(
        name: 'Test',
        notes: 'Fires rapidly. Covering fire for your allies.');
    expect(ElementalTagger.elementsOfGun(g),
        isNot(contains(ElementKind.fire)));
  });

  test('non-elemental gun produces empty set', () {
    final g = Gun(
        name: 'Plain Gun',
        notes: 'A reliable sidearm. Nothing special.',
        gunClass: 'PISTOL');
    expect(ElementalTagger.elementsOfGun(g), isEmpty);
  });

  test('items get tagged too', () {
    final it = Item(name: 'Test', effect: 'Sets enemies on fire.');
    expect(
        ElementalTagger.elementsOfItem(it), contains(ElementKind.fire));
  });
}
