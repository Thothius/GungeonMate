import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/widgets/paradox/emote_sprite_catalog.dart';

/// S4.5 — the surprise composer's `:key:` → spriteKey path.
///
/// `extractSpriteToken` only resolves keys present in the catalog, so
/// these run as widget tests: `ensureLoaded` reads the real bundled
/// JSON assets via rootBundle — real async I/O, hence `runAsync`.
void main() {
  Future<void> load(WidgetTester t) =>
      t.runAsync(() => EmoteSpriteCatalog.ensureLoaded());

  testWidgets('extractSpriteToken resolves a known catalog key', (
    tester,
  ) async {
    await load(tester);
    final key = EmoteSpriteCatalog.all.first.key;

    final (text, sprite) = EmoteSpriteCatalog.extractSpriteToken(
      'hi there :$key: friend',
    );
    expect(sprite, key);
    expect(text, 'hi there  friend');
  });

  testWidgets('extractSpriteToken leaves unknown tokens literal', (
    tester,
  ) async {
    await load(tester);
    const input = 'hello :definitely_not_a_key: world';
    final (text, sprite) = EmoteSpriteCatalog.extractSpriteToken(input);
    expect(sprite, '');
    expect(text, input);
  });

  testWidgets('extractSpriteToken consumes only the first token', (
    tester,
  ) async {
    await load(tester);
    final key = EmoteSpriteCatalog.all.first.key;
    final (text, sprite) = EmoteSpriteCatalog.extractSpriteToken(
      ':$key: and :$key: again',
    );
    expect(sprite, key);
    expect(text, 'and :$key: again');
  });

  test('extractSpriteToken passes through token-free text', () {
    final (text, sprite) = EmoteSpriteCatalog.extractSpriteToken('plain msg');
    expect(sprite, '');
    expect(text, 'plain msg');
  });
}
