import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gungeon_mate/models/multiplayer_messages.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp/mp_sync.dart';

import 'helpers/fake_mp_link.dart';

/// Records every applyPeerSnapshot call so tests can prove a snapshot
/// was dropped without depending on bundled asset data (gungeoneerByName
/// returns null without loadData in unit tests).
class _SpyRunProvider extends RunProvider {
  final List<String> appliedCharacters = [];

  @override
  void applyPeerSnapshot({
    required String characterName,
    required List<String> gunNames,
    required List<String> itemNames,
    required bool targetMainSlot,
  }) {
    appliedCharacters.add(characterName);
    super.applyPeerSnapshot(
      characterName: characterName,
      gunNames: gunNames,
      itemNames: itemNames,
      targetMainSlot: targetMainSlot,
    );
  }
}

/// MP-2 — per-session token hardening.
///
/// Each MpSync generates a random token sent in its MpHello and echoed
/// on every MpSnapshot. The receiver stores the peer's token from the
/// hello and drops snapshots that echo a different token. This is
/// injector hygiene against stray/stale senders — Nearby Connections
/// is plaintext, so this is NOT authentication. Legacy peers that
/// omit the token must keep working (wire compat).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _SpyRunProvider rp;
  late FakeMpLink link;
  late FakeMpLink peerLink;
  late MpSync sync;
  final errors = <String>[];
  final sentToPeer = <MpMessage>[];

  MpHello peerHello({String token = 'peer-token-1'}) => MpHello(
    role: MpRole.sidekick,
    character: 'The Cultist',
    userLabel: 'Guest',
    appVersion: 'test',
    sessionToken: token,
  );

  MpSnapshot peerSnapshot({
    String character = 'The Cultist',
    String token = 'peer-token-1',
  }) => MpSnapshot(
    character: character,
    gunNames: const ['AKEY-47'],
    itemNames: const [],
    coolness: 0,
    curse: 0,
    shrinesUsed: const [],
    sessionToken: token,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    rp = _SpyRunProvider();
    link = FakeMpLink();
    peerLink = FakeMpLink();
    link.connectTo(peerLink);
    peerLink.onMessage = sentToPeer.add;
    sentToPeer.clear();
    errors.clear();
    sync = MpSync(
      link,
      rp,
      onPeerConnected: (_) {},
      onPeerMetadata: (_, _) {},
    );
    sync.onSyncError = errors.add;
    sync.setIdentity(
      role: MpRole.main,
      nickname: 'Host',
      character: 'The Marine',
    );
  });

  tearDown(() => sync.dispose());

  group('wire round-trip', () {
    test('MpHello token survives encode/decode; absent → empty', () {
      final decoded = MpMessage.decode(peerHello().encode());
      expect((decoded as MpHello).sessionToken, 'peer-token-1');

      const legacy = MpHello(
        role: MpRole.sidekick,
        character: 'C',
        userLabel: 'L',
        appVersion: '1',
      );
      expect(legacy.toJson().containsKey('sessionToken'), isFalse);
      expect(
        (MpMessage.decode(legacy.encode()) as MpHello).sessionToken,
        '',
      );
    });

    test('MpSnapshot token survives encode/decode; absent → empty', () {
      final decoded = MpMessage.decode(peerSnapshot().encode());
      expect((decoded as MpSnapshot).sessionToken, 'peer-token-1');

      const legacy = MpSnapshot(
        character: 'C',
        gunNames: [],
        itemNames: [],
        coolness: 0,
        curse: 0,
        shrinesUsed: [],
      );
      expect(legacy.toJson().containsKey('sessionToken'), isFalse);
      expect(
        (MpMessage.decode(legacy.encode()) as MpSnapshot).sessionToken,
        '',
      );
    });

    test('our hello and snapshots carry our own token', () async {
      sync.onConnected();
      // Peer hello triggers our initial broadcast snapshot.
      sync.onMessage(peerHello());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final hello = sentToPeer.whereType<MpHello>().first;
      expect(hello.sessionToken, isNotEmpty);
      final snap = sentToPeer.whereType<MpSnapshot>().first;
      expect(snap.sessionToken, hello.sessionToken);
    });
  });

  group('snapshot validation', () {
    void handshake(String token) {
      sync.onConnected();
      sync.onMessage(peerHello(token: token));
      rp.appliedCharacters.clear();
    }

    test('matching token applies snapshot to peer slot', () {
      handshake('peer-token-1');
      sync.onMessage(peerSnapshot());
      expect(rp.appliedCharacters, ['The Cultist']);
      expect(rp.runState.coop, isNotNull);
    });

    test('mismatched token drops snapshot, peer slot untouched', () {
      handshake('peer-token-1');
      sync.onMessage(peerSnapshot());
      expect(rp.appliedCharacters, hasLength(1));

      sync.onMessage(peerSnapshot(character: 'Impostor', token: 'bad'));
      expect(rp.appliedCharacters, hasLength(1)); // not applied
      expect(errors, isEmpty); // single mismatch is silent
    });

    test('repeated mismatches surface a sync error', () {
      handshake('peer-token-1');
      for (var i = 0; i < 3; i++) {
        sync.onMessage(peerSnapshot(token: 'wrong-$i'));
      }
      expect(rp.appliedCharacters, isEmpty);
      expect(errors, hasLength(1));
      expect(errors.single, contains('token mismatch'));
    });

    test('legacy peer (no token in hello) skips validation', () {
      const noToken = MpHello(
        role: MpRole.sidekick,
        character: 'Old Build',
        userLabel: 'Legacy',
        appVersion: '1.0',
      );
      sync.onConnected();
      sync.onMessage(noToken);
      rp.appliedCharacters.clear();
      sync.onMessage(peerSnapshot(token: 'anything'));
      expect(rp.appliedCharacters, ['The Cultist']);
      expect(errors, isEmpty);
    });

    test('token-less snapshot from token peer is tolerated', () {
      handshake('peer-token-1');
      sync.onMessage(
        const MpSnapshot(
          character: 'The Cultist',
          gunNames: ['AKEY-47'],
          itemNames: [],
          coolness: 0,
          curse: 0,
          shrinesUsed: [],
        ),
      );
      expect(rp.appliedCharacters, ['The Cultist']);
      expect(errors, isEmpty);
    });

    test('mismatch counter resets on a valid snapshot', () {
      handshake('peer-token-1');
      sync.onMessage(peerSnapshot(token: 'bad'));
      sync.onMessage(peerSnapshot(token: 'bad2'));
      sync.onMessage(peerSnapshot()); // valid — resets counter
      sync.onMessage(peerSnapshot(token: 'bad3'));
      sync.onMessage(peerSnapshot(token: 'bad4'));
      expect(errors, isEmpty); // only 2 consecutive since reset
    });
  });
}
