import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/utils/asset_paths.dart';

/// Avatar identity — the `id:frame` composite format that travels
/// over the MP wire (mixed-version peers degrade gracefully).
void main() {
  test('avatarPath resolves bare ids to the portrait asset', () {
    expect(avatarPath('g1_2'), 'assets/images/avatars/g1_2.webp');
  });

  test('avatarPath strips the frame suffix', () {
    expect(avatarPath('g1_2:rainbow'), 'assets/images/avatars/g1_2.webp');
    expect(avatarPath('g3_9:void'), 'assets/images/avatars/g3_9.webp');
  });

  test('avatarPath returns empty for empty id', () {
    expect(avatarPath(''), '');
  });

  test('avatarFrameId extracts the frame slug', () {
    expect(avatarFrameId('g1_2:rainbow'), 'rainbow');
    expect(avatarFrameId('g1_2:void'), 'void');
  });

  test('avatarFrameId returns empty for bare/empty ids', () {
    expect(avatarFrameId('g1_2'), '');
    expect(avatarFrameId(''), '');
  });

  test('avatarBaseId strips the frame suffix', () {
    expect(avatarBaseId('g1_2:rainbow'), 'g1_2');
    expect(avatarBaseId('g1_2'), 'g1_2');
  });

  test('wire round-trip — composite id decodes to same parts', () {
    // What classic lobby + paradox put on the wire.
    const wire = 'g7_4:neon';
    expect(avatarBaseId(wire), 'g7_4');
    expect(avatarFrameId(wire), 'neon');
    expect(avatarPath(wire), 'assets/images/avatars/g7_4.webp');
  });

  test('old-format id without frame degrades gracefully', () {
    // A mixed-version peer sends 'g7_4' — parses as no-frame.
    expect(avatarFrameId('g7_4'), '');
    expect(avatarPath('g7_4'), 'assets/images/avatars/g7_4.webp');
  });
}
