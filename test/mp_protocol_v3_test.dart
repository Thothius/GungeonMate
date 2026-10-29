import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/models/multiplayer_messages.dart';
import 'package:gungeon_mate/utils/run_name_generator.dart';

MpMessage roundTrip(MpMessage m) => MpMessage.decode(m.encode());

void main() {
  group('Protocol v3 — Paradox hello fields', () {
    test('MpHello carries paradox mode + avatar + session meta', () {
      final h = MpHello(
        role: MpRole.main,
        character: 'The Paradox',
        userLabel: 'Gun',
        appVersion: '3.0.0',
        mode: MpMode.paradox,
        avatarId: 'the_paradox',
        runTitle: 'Cursed Bullet of the Forge',
        sessionNumber: 3,
      );
      final d = roundTrip(h) as MpHello;
      expect(d.mode, MpMode.paradox);
      expect(d.avatarId, 'the_paradox');
      expect(d.runTitle, 'Cursed Bullet of the Forge');
      expect(d.sessionNumber, 3);
      expect(d.protocolVersion, 3);
    });

    test('MpHello classic mode omits v3 fields on the wire', () {
      final h = MpHello(
        role: MpRole.sidekick,
        character: 'The Cultist',
        userLabel: 'Sidekick',
        appVersion: '3.0.0',
      );
      final json = h.toJson();
      // Backward-compatible wire shape — no paradox fields emitted.
      expect(json.containsKey('mode'), isFalse);
      expect(json.containsKey('avatarId'), isFalse);
      final d = roundTrip(h) as MpHello;
      expect(d.mode, MpMode.classic);
      expect(d.sessionNumber, 0);
    });
  });

  group('Protocol v3 — session control messages', () {
    test('MpStartRun / MpPause / MpResume round-trip', () {
      expect(roundTrip(const MpStartRun()), isA<MpStartRun>());
      expect(roundTrip(const MpPause()), isA<MpPause>());
      expect(roundTrip(const MpResume()), isA<MpResume>());
    });

    test('MpSessionMeta round-trip (Main-authoritative state)', () {
      const m = MpSessionMeta(
        runTitle: 'Blasphemous Huntress',
        sessionNumber: 7,
        paused: true,
      );
      final d = roundTrip(m) as MpSessionMeta;
      expect(d.runTitle, 'Blasphemous Huntress');
      expect(d.sessionNumber, 7);
      expect(d.paused, isTrue);
    });

    test('MpSessionMeta defaults when fields missing', () {
      final d = MpSessionMeta.fromJson(const {});
      expect(d.runTitle, '');
      expect(d.sessionNumber, 0);
      expect(d.paused, isFalse);
    });
  });

  group('Protocol v3 — chat, surprise, peer edit', () {
    test('MpChat round-trip preserves sprite tokens in text', () {
      const m = MpChat(
        id: 'abc123',
        from: 'Gun',
        text: 'nice :gun_big_iron: run',
      );
      final d = roundTrip(m) as MpChat;
      expect(d.id, 'abc123');
      expect(d.from, 'Gun');
      expect(d.text, 'nice :gun_big_iron: run');
    });

    test('MpSurprise preset + custom payload round-trip', () {
      const m = MpSurprise(
        preset: 'custom',
        text: 'GL HF',
        spriteKey: 'gun_unicorn_horn',
      );
      final d = roundTrip(m) as MpSurprise;
      expect(d.preset, 'custom');
      expect(d.text, 'GL HF');
      expect(d.spriteKey, 'gun_unicorn_horn');
    });

    test('MpSurprise preset-only omits optional fields on the wire', () {
      const m = MpSurprise(preset: 'meow');
      expect(m.toJson(), const {'preset': 'meow'});
      final d = roundTrip(m) as MpSurprise;
      expect(d.preset, 'meow');
      expect(d.text, '');
      expect(d.spriteKey, '');
    });

    test('MpPeerEdit ops round-trip', () {
      const add = MpPeerEdit(op: 'add', kind: 'gun', name: 'Blasphemy');
      final dAdd = roundTrip(add) as MpPeerEdit;
      expect(dAdd.op, 'add');
      expect(dAdd.kind, 'gun');
      expect(dAdd.name, 'Blasphemy');

      const clear = MpPeerEdit(op: 'clear');
      final dClear = roundTrip(clear) as MpPeerEdit;
      expect(dClear.op, 'clear');
      expect(dClear.kind, '');
      expect(dClear.name, '');
    });
  });

  group('Protocol v3 — decode robustness', () {
    test('unknown type throws FormatException (drop, not crash)', () {
      final bytes = Uint8List.fromList(
        utf8.encode('{"type":"teleport","x":1}'),
      );
      expect(() => MpMessage.decode(bytes), throwsFormatException);
      final badJson = Uint8List.fromList(utf8.encode('not json'));
      expect(() => MpMessage.decode(badJson), throwsFormatException);
      final noType = Uint8List.fromList(utf8.encode('{"foo":1}'));
      expect(() => MpMessage.decode(noType), throwsFormatException);
    });
  });

  group('Run name generator', () {
    test('rolls non-empty themed title', () {
      final name = RunNameGenerator.roll();
      expect(name.trim(), isNotEmpty);
      expect(
        name.contains(' '),
        isTrue,
        reason: 'run titles combine an adjective with a themed noun',
      );
    });

    test('successive rolls vary (not a constant)', () {
      final names = {for (var i = 0; i < 20; i++) RunNameGenerator.roll()};
      expect(names.length, greaterThan(1));
    });
  });
}
