import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/models/rich_text.dart';

/// Regression test for the "Exit the Gungeon" content filter in
/// [RichBullet.fromJson] / [_parseBulletList]. Wiki bullets that reference
/// the spin-off game must be dropped at parse time so they never surface
/// in Effects / Notes / Trivia / Tips sections.
///
/// The match is case-sensitive on purpose: "Exit the Gungeon" (capital E)
/// is the game title, while "exit the Gungeon" is the verb phrase
/// (e.g. Ox and Cadence's "enter and exit the Gungeon" tip) and must stay.
void main() {
  group('RichBullet Exit the Gungeon filter', () {
    test('drops XtG sub-bullet but keeps the parent (Meatbun pattern)', () {
      final wiki = WikiContent.fromJson({
        'effects': [
          {
            'tokens': [
              {
                't': 'text',
                'v': 'Grants double damage until the player is hit.',
              },
            ],
            'sub': [
              {
                'tokens': [
                  {
                    't': 'text',
                    'v':
                        'In Exit the Gungeon, the effect will also wear off when the player ascends to the next chamber.',
                  },
                ],
              },
            ],
          },
        ],
      });
      expect(wiki.effects, hasLength(1));
      expect(wiki.effects.single.plainText, contains('double damage'));
      expect(wiki.effects.single.sub, isEmpty);
    });

    test(
      'drops a top-level bullet referencing XtG via ref token (Wolf pattern)',
      () {
        final wiki = WikiContent.fromJson({
          'trivia': [
            {
              'tokens': [
                {'t': 'text', 'v': 'Wolf is a reference to Metal Gear Solid.'},
              ],
            },
            {
              'tokens': [
                {'t': 'text', 'v': 'In '},
                {'t': 'ref', 'v': 'Exit the Gungeon', 'kind': 'lore'},
                {'t': 'text', 'v': ' Wolf can pick up money and powerups.'},
              ],
            },
          ],
        });
        expect(wiki.trivia, hasLength(1));
        expect(wiki.trivia.single.plainText, contains('Metal Gear Solid'));
      },
    );

    test('drops XtG inside an italic text token (Brick Breaker pattern)', () {
      final wiki = WikiContent.fromJson({
        'effects': [
          {
            'tokens': [
              {'t': 'text', 'v': 'Shots pierce bricks.'},
            ],
            'sub': [
              {
                'tokens': [
                  {'t': 'text', 'v': ' In '},
                  {'t': 'text', 'v': 'Exit the Gungeon', 'style': 'i'},
                  {'t': 'text', 'v': ', instead of piercing they bounce.'},
                ],
              },
            ],
          },
        ],
      });
      expect(wiki.effects.single.sub, isEmpty);
    });

    test('keeps lowercase "exit the Gungeon" verb phrase', () {
      final wiki = WikiContent.fromJson({
        'notes': [
          {
            'tokens': [
              {
                't': 'text',
                'v': 'The Breach reloads when you enter and exit the Gungeon.',
              },
            ],
          },
        ],
      });
      expect(wiki.notes, hasLength(1));
      expect(wiki.notes.single.plainText, contains('exit the Gungeon'));
    });

    test('leaves unrelated bullets untouched', () {
      final wiki = WikiContent.fromJson({
        'notes': [
          {
            'tokens': [
              {'t': 'text', 'v': 'Deals bonus damage to '},
              {'t': 'ref', 'v': 'Bullet King', 'kind': 'character'},
              {'t': 'text', 'v': '.'},
            ],
          },
          {
            'tokens': [
              {'t': 'text', 'v': 'Cannot be sold.'},
            ],
            'sub': [
              {
                'tokens': [
                  {'t': 'text', 'v': 'Unless you have Sell Creep nearby.'},
                ],
              },
            ],
          },
        ],
      });
      expect(wiki.notes, hasLength(2));
      expect(wiki.notes[1].sub, hasLength(1));
    });
  });
}
