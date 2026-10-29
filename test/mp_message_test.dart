import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/models/multiplayer_messages.dart';

/// Round-trip tests for every message type in the wire protocol.
/// Each test encodes a message and decodes it back, verifying that
/// all fields survive the JSON serialization.
void main() {
  group('MpMessage round-trip', () {
    test('MpHello — all fields preserved', () {
      const original = MpHello(
        role: MpRole.sidekick,
        character: 'The Hunter',
        userLabel: 'CoolPlayer',
        appVersion: '2.0.3',
        protocolVersion: 2,
      );
      final bytes = original.encode();
      final decoded = MpMessage.decode(bytes) as MpHello;

      expect(decoded.type, 'hello');
      expect(decoded.role, MpRole.sidekick);
      expect(decoded.character, 'The Hunter');
      expect(decoded.userLabel, 'CoolPlayer');
      expect(decoded.appVersion, '2.0.3');
      expect(decoded.protocolVersion, 2);
    });

    test('MpHello — default protocol version is 3', () {
      const hello = MpHello(
        role: MpRole.main,
        character: '',
        userLabel: '',
        appVersion: '',
      );
      expect(hello.protocolVersion, 3);
      expect(MpHello.currentProtocolVersion, 3);
    });

    test('MpSnapshot — full state round-trip', () {
      const original = MpSnapshot(
        character: 'The Pilot',
        gunNames: ['Rogue Special', 'Budget Gun', 'SAA'],
        itemNames: ['Ring of Triggers', 'Ration', 'Number 2'],
        coolness: 12.5,
        curse: -3.0,
        shrinesUsed: ['Glass Guon Stone', 'Pillar Shrine'],
      );
      final bytes = original.encode();
      final decoded = MpMessage.decode(bytes) as MpSnapshot;

      expect(decoded.type, 'snapshot');
      expect(decoded.character, 'The Pilot');
      expect(decoded.gunNames, ['Rogue Special', 'Budget Gun', 'SAA']);
      expect(decoded.itemNames, ['Ring of Triggers', 'Ration', 'Number 2']);
      expect(decoded.coolness, 12.5);
      expect(decoded.curse, -3.0);
      expect(decoded.shrinesUsed, ['Glass Guon Stone', 'Pillar Shrine']);
    });

    test('MpSnapshot — empty lists round-trip', () {
      const original = MpSnapshot(
        character: 'The Cultist',
        gunNames: [],
        itemNames: [],
        coolness: 0,
        curse: 0,
        shrinesUsed: [],
      );
      final bytes = original.encode();
      final decoded = MpMessage.decode(bytes) as MpSnapshot;

      expect(decoded.gunNames, isEmpty);
      expect(decoded.itemNames, isEmpty);
      expect(decoded.shrinesUsed, isEmpty);
    });

    test('MpGift — round-trip', () {
      const original = MpGift(
        kind: 'gun',
        name: 'Megahand',
        giftId: 'gift-abc-123',
      );
      final bytes = original.encode();
      final decoded = MpMessage.decode(bytes) as MpGift;

      expect(decoded.type, 'gift');
      expect(decoded.kind, 'gun');
      expect(decoded.name, 'Megahand');
      expect(decoded.giftId, 'gift-abc-123');
    });

    test('MpRequest — round-trip', () {
      const original = MpRequest(
        reqId: 'req-xyz-789',
        kind: 'item',
        name: 'Spice',
      );
      final bytes = original.encode();
      final decoded = MpMessage.decode(bytes) as MpRequest;

      expect(decoded.type, 'request');
      expect(decoded.reqId, 'req-xyz-789');
      expect(decoded.kind, 'item');
      expect(decoded.name, 'Spice');
    });

    test('MpRequestResp — approved=true round-trip', () {
      const original = MpRequestResp(reqId: 'req-1', approved: true);
      final bytes = original.encode();
      final decoded = MpMessage.decode(bytes) as MpRequestResp;

      expect(decoded.type, 'requestResp');
      expect(decoded.reqId, 'req-1');
      expect(decoded.approved, isTrue);
    });

    test('MpRequestResp — approved=false round-trip', () {
      const original = MpRequestResp(reqId: 'req-2', approved: false);
      final bytes = original.encode();
      final decoded = MpMessage.decode(bytes) as MpRequestResp;

      expect(decoded.approved, isFalse);
    });

    test('MpEndRun — round-trip (no body)', () {
      const original = MpEndRun();
      final bytes = original.encode();
      final decoded = MpMessage.decode(bytes);

      expect(decoded, isA<MpEndRun>());
      expect(decoded.type, 'endRun');
    });

    test('MpPing — round-trip', () {
      final original = MpPing(1700000000000);
      final bytes = original.encode();
      final decoded = MpMessage.decode(bytes) as MpPing;

      expect(decoded.type, 'ping');
      expect(decoded.tsMs, 1700000000000);
    });

    test('MpPong — round-trip', () {
      final original = MpPong(1700000001234);
      final bytes = original.encode();
      final decoded = MpMessage.decode(bytes) as MpPong;

      expect(decoded.type, 'pong');
      expect(decoded.tsMs, 1700000001234);
    });

    test('MpDiceChallenge — round-trip', () {
      const original = MpDiceChallenge(challengerName: 'HostPlayer');
      final bytes = original.encode();
      final decoded = MpMessage.decode(bytes) as MpDiceChallenge;

      expect(decoded.type, 'diceChallenge');
      expect(decoded.challengerName, 'HostPlayer');
    });

    test('MpDiceAccept — round-trip (no body)', () {
      const original = MpDiceAccept();
      final bytes = original.encode();
      final decoded = MpMessage.decode(bytes);

      expect(decoded, isA<MpDiceAccept>());
      expect(decoded.type, 'diceAccept');
    });

    test('MpDiceDecline — round-trip (no body)', () {
      const original = MpDiceDecline();
      final bytes = original.encode();
      final decoded = MpMessage.decode(bytes);

      expect(decoded, isA<MpDiceDecline>());
      expect(decoded.type, 'diceDecline');
    });

    test('MpDiceCancel — round-trip (no body)', () {
      const original = MpDiceCancel();
      final bytes = original.encode();
      final decoded = MpMessage.decode(bytes);

      expect(decoded, isA<MpDiceCancel>());
      expect(decoded.type, 'diceCancel');
    });

    test('MpDiceResult — round-trip with dice values', () {
      const original = MpDiceResult(score: 42, dice: [6, 6, 6, 6, 6, 6, 6]);
      final bytes = original.encode();
      final decoded = MpMessage.decode(bytes) as MpDiceResult;

      expect(decoded.type, 'diceResult');
      expect(decoded.score, 42);
      expect(decoded.dice, [6, 6, 6, 6, 6, 6, 6]);
    });

    test('MpDiceResult — empty dice list round-trip', () {
      const original = MpDiceResult(score: 0, dice: []);
      final bytes = original.encode();
      final decoded = MpMessage.decode(bytes) as MpDiceResult;

      expect(decoded.score, 0);
      expect(decoded.dice, isEmpty);
    });

    test('MpEmote — kiss round-trip', () {
      const original = MpEmote(from: 'PartnerPlayer', action: 'kiss');
      final bytes = original.encode();
      final decoded = MpMessage.decode(bytes) as MpEmote;

      expect(decoded.type, 'emote');
      expect(decoded.from, 'PartnerPlayer');
      expect(decoded.action, 'kiss');
    });

    test('MpEmote — slap round-trip', () {
      const original = MpEmote(from: 'HostPlayer', action: 'slap');
      final bytes = original.encode();
      final decoded = MpMessage.decode(bytes) as MpEmote;

      expect(decoded.action, 'slap');
    });

    test('MpSharedStateDelta — coolness only round-trip', () {
      const original = MpSharedStateDelta(coolnessDelta: 2.5);
      final bytes = original.encode();
      final decoded = MpMessage.decode(bytes) as MpSharedStateDelta;

      expect(decoded.type, 'sharedStateDelta');
      expect(decoded.coolnessDelta, 2.5);
      expect(decoded.curseDelta, 0);
      expect(decoded.shrineName, isNull);
    });

    test('MpSharedStateDelta — curse only round-trip', () {
      const original = MpSharedStateDelta(curseDelta: -1.0);
      final bytes = original.encode();
      final decoded = MpMessage.decode(bytes) as MpSharedStateDelta;

      expect(decoded.coolnessDelta, 0);
      expect(decoded.curseDelta, -1.0);
      expect(decoded.shrineName, isNull);
    });

    test('MpSharedStateDelta — shrine only round-trip', () {
      const original = MpSharedStateDelta(shrineName: 'Glass Guon Stone');
      final bytes = original.encode();
      final decoded = MpMessage.decode(bytes) as MpSharedStateDelta;

      expect(decoded.coolnessDelta, 0);
      expect(decoded.curseDelta, 0);
      expect(decoded.shrineName, 'Glass Guon Stone');
    });

    test('MpSharedStateDelta — all fields round-trip', () {
      const original = MpSharedStateDelta(
        coolnessDelta: 3.0,
        curseDelta: 1.5,
        shrineName: 'Pillar Shrine',
      );
      final bytes = original.encode();
      final decoded = MpMessage.decode(bytes) as MpSharedStateDelta;

      expect(decoded.coolnessDelta, 3.0);
      expect(decoded.curseDelta, 1.5);
      expect(decoded.shrineName, 'Pillar Shrine');
    });

    test('MpSharedStateDelta — negative deltas round-trip', () {
      const original = MpSharedStateDelta(
        coolnessDelta: -5.0,
        curseDelta: -2.0,
      );
      final bytes = original.encode();
      final decoded = MpMessage.decode(bytes) as MpSharedStateDelta;

      expect(decoded.coolnessDelta, -5.0);
      expect(decoded.curseDelta, -2.0);
    });
  });

  group('MpMessage decode error handling', () {
    test('Unknown type throws FormatException', () {
      final bytes = _encodeJson({'type': 'totallyFake'});
      expect(
        () => MpMessage.decode(bytes),
        throwsA(isA<FormatException>()),
      );
    });

    test('Missing type field throws FormatException', () {
      final bytes = _encodeJson({'role': 'main'});
      expect(
        () => MpMessage.decode(bytes),
        throwsA(isA<FormatException>()),
      );
    });

    test('Non-object root throws FormatException', () {
      final bytes = _encodeJson([1, 2, 3]);
      expect(
        () => MpMessage.decode(bytes),
        throwsA(isA<FormatException>()),
      );
    });

    test('Malformed JSON throws', () {
      final bytes = _rawBytes('not json at all');
      expect(
        () => MpMessage.decode(bytes),
        throwsA(isA<FormatException>()),
      );
    });

    test('Empty bytes throws', () {
      final bytes = _rawBytes('');
      expect(
        () => MpMessage.decode(bytes),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('MpRole wire format', () {
    test('main → "main" → main', () {
      expect(MpRole.main.wire, 'main');
      expect(MpRoleWire.parse('main'), MpRole.main);
    });

    test('sidekick → "sidekick" → sidekick', () {
      expect(MpRole.sidekick.wire, 'sidekick');
      expect(MpRoleWire.parse('sidekick'), MpRole.sidekick);
    });

    test('Unknown role string throws FormatException', () {
      expect(
        () => MpRoleWire.parse('admin'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

// ── Helpers ──────────────────────────────────────────────────────

Uint8List _encodeJson(Object obj) =>
    Uint8List.fromList(utf8.encode(jsonEncode(obj)));

Uint8List _rawBytes(String s) =>
    Uint8List.fromList(utf8.encode(s));
