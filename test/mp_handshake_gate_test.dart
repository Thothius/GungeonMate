import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/services/mp/mp_handshake_gate.dart';

/// S4.1 — regression tests for the first-endpoint mis-pair race.
///
/// The bug class (fixed in `7be7537`): a second Nearby initiator
/// arriving while the first handshake was mid-flight would be natively
/// accepted, then dropped by the `_endpointId` guard in
/// `_onConnectionResult` — leaving a phantom "connected" peer on the
/// initiator's side. These tests pin the *decision* layer
/// (`MpHandshakeGate`) that `MpLink` delegates to; the Nearby side
/// effects are thin wrappers around the verdicts asserted here.
void main() {
  late MpHandshakeGate gate;

  setUp(() => gate = MpHandshakeGate());

  group('onInitiated — accept window', () {
    test('first initiator is accepted and marked pending', () {
      expect(gate.onInitiated('ep-a', null), MpInitiatedVerdict.accept);
      expect(gate.initiatedIds, {'ep-a'});
    });

    test('second DIFFERENT initiator mid-handshake is rejected', () {
      gate.onInitiated('ep-a', null);
      // The race: host advertising, two sidekicks initiate near-
      // simultaneously. Second must be rejected, not accepted-then-
      // dropped.
      expect(
        gate.onInitiated('ep-b', null),
        MpInitiatedVerdict.rejectHandshakeInFlight,
      );
      expect(gate.initiatedIds, {'ep-a'});
    });

    test('same endpoint re-initiating is allowed (retry)', () {
      gate.onInitiated('ep-a', null);
      expect(gate.onInitiated('ep-a', null), MpInitiatedVerdict.accept);
      expect(gate.initiatedIds, {'ep-a'});
    });

    test('pending handshake clears on result → next initiator accepted', () {
      gate.onInitiated('ep-a', null);
      gate.onResult('ep-a'); // CONNECTED or REJECTED/ERROR — either way
      // the pending mark is gone.
      expect(gate.onInitiated('ep-b', null), MpInitiatedVerdict.accept);
    });

    test('pending handshake clears on native disconnect', () {
      gate.onInitiated('ep-a', null);
      gate.onEndpointGone('ep-a'); // dropped before any result
      expect(gate.onInitiated('ep-b', null), MpInitiatedVerdict.accept);
    });
  });

  group('onInitiated — already connected', () {
    test('initiator different from active endpoint is rejected', () {
      expect(
        gate.onInitiated('ep-b', 'ep-a'),
        MpInitiatedVerdict.rejectOtherConnected,
      );
      // Rejected BEFORE the pending check — must not enter the set.
      expect(gate.initiatedIds, isEmpty);
    });

    test('same endpoint re-handshaking while active falls through', () {
      // e.g. transport-level reconnect of the same peer id.
      expect(gate.onInitiated('ep-a', 'ep-a'), MpInitiatedVerdict.accept);
      expect(gate.initiatedIds, {'ep-a'});
    });

    test('connected check wins over in-flight check', () {
      // ep-a pending AND ep-x already connected: a third endpoint
      // gets rejectOtherConnected (the stronger signal), and ep-a's
      // pending mark is untouched.
      gate.onInitiated('ep-pending', null);
      expect(
        gate.onInitiated('ep-new', 'ep-active'),
        MpInitiatedVerdict.rejectOtherConnected,
      );
      expect(gate.initiatedIds, {'ep-pending'});
    });
  });

  group('resultDisconnectsPhantom — CONNECTED result guard', () {
    test('CONNECTED for different id than active → phantom teardown', () {
      expect(gate.resultDisconnectsPhantom('ep-b', 'ep-a'), isTrue);
    });

    test('CONNECTED for the active id → no teardown', () {
      expect(gate.resultDisconnectsPhantom('ep-a', 'ep-a'), isFalse);
    });

    test('CONNECTED with no active endpoint → normal connect', () {
      expect(gate.resultDisconnectsPhantom('ep-a', null), isFalse);
    });
  });

  group('evictStale — 20s handshake-stall guard', () {
    test('evicts a pending handshake that never produced a result', () {
      gate.onInitiated('ep-a', null);
      gate.evictStale('ep-a', null);
      expect(gate.initiatedIds, isEmpty);
      // Gate un-wedged: a new initiator can now be accepted.
      expect(gate.onInitiated('ep-b', null), MpInitiatedVerdict.accept);
    });

    test('does NOT evict the active endpoint', () {
      gate.onInitiated('ep-a', null);
      // ep-a connected between initiation and the timer firing.
      gate.evictStale('ep-a', 'ep-a');
      // Result handler already removed it; assert the guard itself
      // refuses to evict an active id even if it were still present.
      gate.initiatedIds.add('ep-a');
      gate.evictStale('ep-a', 'ep-a');
      expect(gate.initiatedIds, {'ep-a'});
    });

    test('evicts a different pending id even when another is active', () {
      gate.initiatedIds.addAll({'ep-x', 'ep-y'});
      gate.evictStale('ep-x', 'ep-active');
      expect(gate.initiatedIds, {'ep-y'});
    });
  });

  group('clear — teardown paths', () {
    test('clear empties pending set (stopAll / heartbeat timeout)', () {
      gate.onInitiated('ep-a', null);
      gate.onInitiated('ep-a', null);
      gate.clear();
      expect(gate.initiatedIds, isEmpty);
    });
  });
}
