import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/models/multiplayer_messages.dart';

/// L2-1 + S4.4 — old-peer wire compatibility fixture for MpSurprise.
///
/// History: the sprite field was renamed `sprite` → `spriteKey` and `fx`
/// was added. New builds dual-write BOTH keys so old peers (which only
/// read `sprite`) still receive the sprite, and read `spriteKey ??
/// sprite` so old→new works too. These fixtures pin both directions.
void main() {
  Map<String, dynamic> newPeerPayload() {
    // What a current build puts on the wire (encode() injects 'type').
    final m = const MpSurprise(
      preset: 'custom',
      text: 'gm',
      spriteKey: 'gun_unicorn_horn',
      fx: 'heartsburst',
    );
    return {'type': m.type, ...m.toJson()};
  }

  test('old peer (reads only `sprite`) still gets the sprite via dual-write',
      () {
    final j = newPeerPayload();

    // Simulated OLD fromJson — the pre-rename parser.
    final oldDecoded = (
      preset: j['preset'] as String? ?? 'custom',
      text: j['text'] as String? ?? '',
      sprite: j['sprite'] as String? ?? '', // old key only
      // old parser has no `fx` field at all — silently ignored
    );

    expect(oldDecoded.preset, 'custom');
    expect(oldDecoded.text, 'gm');
    // S4.4 dual-write: the sprite survives the new→old direction.
    expect(oldDecoded.sprite, 'gun_unicorn_horn');
    // fx remains wire-additive — old peers ignore the unknown key.
  });

  test('new peer reads legacy `sprite` key (old→new direction)', () {
    final d = MpSurprise.fromJson({
      'preset': 'custom',
      'text': 'gm',
      'sprite': 'gun_unicorn_horn', // legacy key, no spriteKey
    });
    expect(d.spriteKey, 'gun_unicorn_horn');
    expect(d.fx, '');
  });

  test('new peer prefers spriteKey when both keys present', () {
    final d = MpSurprise.fromJson({
      'preset': 'custom',
      'sprite': 'old_value',
      'spriteKey': 'new_value',
    });
    expect(d.spriteKey, 'new_value');
  });

  test('fx is wire-additive — present in payload, absent from old schema',
      () {
    final j = newPeerPayload();
    expect(j['fx'], 'heartsburst');
    // Old schema had no fx — a strict old parser simply ignores it.
    expect(MpSurprise.fromJson(j).fx, 'heartsburst');
  });
}
