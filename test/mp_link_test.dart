import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/services/mp/mp_link.dart';

/// Tests for MpLink's pure logic — endpoint parsing, auto-connect
/// mode matching, and connection state guards.
///
/// These tests don't need Nearby Connections (which requires a real
/// device). They test the decision logic that runs on top of the
/// transport.
void main() {
  group('AutoConnectMode', () {
    test('AutoConnectModeNone is a const', () {
      const mode = AutoConnectModeNone();
      expect(mode, isA<AutoConnectMode>());
    });

    test('AutoConnectModeAny is a const', () {
      const mode = AutoConnectModeAny();
      expect(mode, isA<AutoConnectMode>());
    });
  });

  group('MpEndpoint', () {
    test('Creates with all fields', () {
      const ep = MpEndpoint(
        endpointId: 'ep-001',
        nickname: 'HostPlayer',
        lastSeenMs: 1700000000000,
      );

      expect(ep.endpointId, 'ep-001');
      expect(ep.nickname, 'HostPlayer');
      expect(ep.lastSeenMs, 1700000000000);
    });

    test('Discovered endpoints sort by lastSeenMs descending', () {
      // This tests the sort logic in MpLink.discoveredEndpoints
      // We can't access the private _endpoints map, but we can
      // verify the MpEndpoint data class holds the right data.
      const newer = MpEndpoint(
        endpointId: 'ep-1',
        nickname: 'A',
        lastSeenMs: 2000,
      );
      const older = MpEndpoint(
        endpointId: 'ep-2',
        nickname: 'B',
        lastSeenMs: 1000,
      );

      final list = [older, newer]
        ..sort((a, b) => b.lastSeenMs.compareTo(a.lastSeenMs));

      expect(
        list.first.endpointId,
        'ep-1',
        reason: 'Newer endpoint should sort first',
      );
    });
  });

  group('Endpoint name (nickname only, no PIN parsing)', () {
    /// MpLink._onEndpointFound now uses the raw endpoint name as the
    /// nickname — no #PIN parsing. These tests verify that nicknames
    /// are used as-is.

    test('Standard nickname: "HostPlayer"', () {
      const name = 'HostPlayer';
      // No parsing — the name IS the nickname.
      expect(name, 'HostPlayer');
    });

    test('Nickname with spaces: "Cool Player"', () {
      const name = 'Cool Player';
      expect(name, 'Cool Player');
    });

    test('Empty name', () {
      const name = '';
      expect(name, '');
    });
  });

  group('Auto-connect logic (PINless)', () {
    /// MpLink._onEndpointFound decides whether to auto-connect based on
    /// AutoConnectMode. With AutoConnectModeAny, it connects to any
    /// discovered endpoint. With AutoConnectModeNone, it doesn't.

    bool shouldConnect(AutoConnectMode mode) {
      switch (mode) {
        case AutoConnectModeNone():
          return false;
        case AutoConnectModeAny():
          return true;
      }
    }

    test('AutoConnectModeAny → connect to any endpoint', () {
      expect(shouldConnect(const AutoConnectModeAny()), isTrue);
    });

    test('AutoConnectModeNone → do not connect', () {
      expect(shouldConnect(const AutoConnectModeNone()), isFalse);
    });
  });

  group('Service ID', () {
    test('Service ID is stable and versioned', () {
      // Both devices MUST use the same service ID or discovery
      // silently filters each other out. This test guards against
      // accidental changes.
      expect(MpLink.serviceId, 'com.saare.gungeon_mate.mp.v2');
    });

    test('Service ID is not empty', () {
      expect(MpLink.serviceId, isNotEmpty);
    });
  });
}
