import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/models/multiplayer_messages.dart';

/// L2-1 — old-peer wire compatibility fixture for MpSurprise.
///
/// History: the sprite field was renamed `sprite` → `spriteKey` and `fx`
/// was added. New builds read BOTH keys (`spriteKey ?? sprite`), so
/// old→new works. New→old cannot be fixed client-side (old builds only
/// read `sprite`), but this fixture pins exactly what an old peer sees
/// so the skew is a documented, tested behavior — not a surprise.
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

  test('old peer (reads only `sprite`) loses spriteKey but keeps text/preset',
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
    // The documented skew: custom sprite silently drops on old peers.
    expect(oldDecoded.sprite, '');
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
