import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/models/multiplayer_messages.dart';

/// MP wire contract test — pins the on-the-wire JSON shape of every
/// MpMessage type (OPTIMIZATION_PLAN Phase 0). Old and new builds must
/// interop, so field names/types are a frozen contract:
///
///  - `toJson()` must never include a 'type' key (encode() injects it)
///  - field key sets must match the golden map below exactly
///  - `type` discriminator must decode back to the same class
///
/// Conditional (optional) fields are exercised in both states.
/// Changing a golden set here = a deliberate protocol change — bump
/// MpHello.currentProtocolVersion and think about old-peer compat.
void main() {
  // ── Golden key sets per type ─────────────────────────────────────
  final goldenKeys = <Type, Set<String>>{
    MpHello: {
      'role',
      'character',
      'userLabel',
      'appVersion',
      'protocolVersion',
      'avatarId',
      'runTitle',
      'sessionNumber',
    },
    MpSnapshot: {'character', 'guns', 'items', 'coolness', 'curse', 'shrinesUsed'},
    MpGift: {'kind', 'name', 'giftId'},
    MpRequest: {'reqId', 'kind', 'name'},
    MpRequestResp: {'reqId', 'approved'},
    MpEndRun: <String>{},
    MpPing: {'ts'},
    MpPong: {'ts'},
    MpDiceChallenge: {'challengerName'},
    MpDiceAccept: <String>{},
    MpDiceDecline: <String>{},
    MpDiceCancel: <String>{},
    MpDiceResult: {'score', 'dice'},
    MpEmote: {'from', 'action'},
    MpSharedStateDelta: {'coolnessDelta', 'curseDelta', 'shrineName'},
    MpStartRun: <String>{},
    MpPause: <String>{},
    MpResume: <String>{},
    MpSessionMeta: {'runTitle', 'sessionNumber', 'paused'},
    MpSurprise: {'preset', 'text', 'spriteKey', 'fx'},
    MpPeerEdit: {'op', 'kind', 'name'},
  };

  // One representative instance per message type (full optional fields).
  final samples = <MpMessage>[
    const MpHello(
      role: MpRole.main,
      character: 'The Marine',
      userLabel: 'host',
      appVersion: '3.2.1',
      protocolVersion: 3,
      avatarId: 'g2_4:gold',
      runTitle: 'Run of the Gun',
      sessionNumber: 2,
    ),
    const MpSnapshot(
      character: 'The Pilot',
      gunNames: ['AKEY-47', 'Casey'],
      itemNames: ['Junk'],
      coolness: 2.5,
      curse: 1.0,
      shrinesUsed: ['Peace Shrine'],
    ),
    const MpGift(kind: 'gun', name: 'Casey', giftId: 'g-1'),
    const MpRequest(reqId: 'r-1', kind: 'item', name: 'Junk'),
    const MpRequestResp(reqId: 'r-1', approved: true),
    const MpEndRun(),
    const MpPing(12345),
    const MpPong(12345),
    const MpDiceChallenge(challengerName: 'p1'),
    const MpDiceAccept(),
    const MpDiceDecline(),
    const MpDiceCancel(),
    const MpDiceResult(score: 17, dice: [6, 6, 5]),
    const MpEmote(from: 'p2', action: 'kiss'),
    const MpSharedStateDelta(
      coolnessDelta: 1.0,
      curseDelta: -0.5,
      shrineName: 'Angel Shrine',
    ),
    const MpStartRun(),
    const MpPause(),
    const MpResume(),
    const MpSessionMeta(runTitle: 'T', sessionNumber: 4, paused: true),
    const MpSurprise(preset: 'meow', text: 'hi', spriteKey: 'cat', fx: 'bulletrain'),
    const MpPeerEdit(op: 'add', kind: 'gun', name: 'Casey'),
  ];

  test('every sample covers a distinct wire type', () {
    expect(samples.length, 21);
    expect(samples.map((m) => m.runtimeType).toSet().length, 21);
    expect(
      samples.map((m) => m.runtimeType).toSet(),
      equals(goldenKeys.keys.toSet()),
    );
  });

  group('golden key sets', () {
    for (final m in samples) {
      test('${m.runtimeType} toJson keys match contract', () {
        expect(
          m.toJson().keys.toSet(),
          equals(goldenKeys[m.runtimeType]),
          reason: '${m.runtimeType} wire fields changed — protocol break',
        );
      });
    }
  });

  group('type-discriminator contract', () {
    for (final m in samples) {
      test('${m.runtimeType}: toJson has no type key; decode round-trips', () {
        expect(m.toJson().containsKey('type'), isFalse);
        final wire = jsonDecode(utf8.decode(m.encode())) as Map<String, dynamic>;
        expect(wire['type'], equals(m.type));
        final decoded = MpMessage.decode(m.encode());
        expect(decoded.runtimeType, equals(m.runtimeType));
      });
    }
  });

  group('optional-field omission contract', () {
    test('MpSurprise emits only preset when optionals empty', () {
      const m = MpSurprise(preset: 'meow');
      expect(m.toJson(), equals({'preset': 'meow'}));
    });

    test('MpPeerEdit emits only op when kind/name empty', () {
      const m = MpPeerEdit(op: 'clear');
      expect(m.toJson(), equals({'op': 'clear'}));
    });

    test('MpSharedStateDelta omits shrineName when null', () {
      const m = MpSharedStateDelta(coolnessDelta: 1);
      expect(m.toJson().containsKey('shrineName'), isFalse);
    });
  });

  test('decode rejects unknown type + malformed payloads', () {
    expect(
      () => MpMessage.decode(utf8.encode('{"type":"nope"}')),
      throwsFormatException,
    );
    expect(
      () => MpMessage.decode(utf8.encode('{"x":1}')),
      throwsFormatException,
    );
    expect(() => MpMessage.decode(utf8.encode('[1]')), throwsFormatException);
  });
}
