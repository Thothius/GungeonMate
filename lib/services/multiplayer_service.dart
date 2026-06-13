import 'dart:async';

import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/multiplayer_messages.dart';

/// Thin, event-driven wrapper over `nearby_connections`. Keeps the
/// plugin's callback-heavy API out of the rest of the app — everything
/// above this talks to us via a single `Stream<MpServiceEvent>` and a
/// handful of futures.
///
/// Role mapping:
///   * **Main Player** → advertiser (waits for a Sidekick to find them)
///   * **Sidekick**    → discoverer (scans for a Main)
///
/// We use `P2P_POINT_TO_POINT` because the session is strictly 1-to-1
/// and we want the best possible throughput/latency.
class MultiplayerService {
  MultiplayerService();

  /// Service ID shared by both peers. Must be identical on every
  /// device or discovery will silently filter each other out. Tied to
  /// app package name for uniqueness and a version suffix for future
  /// protocol bumps.
  static const String serviceId = 'com.saare.gungeon_mate.mp.v1';

  static const Strategy _strategy = Strategy.P2P_POINT_TO_POINT;

  final Nearby _nearby = Nearby();

  final StreamController<MpServiceEvent> _events =
      StreamController<MpServiceEvent>.broadcast();

  /// Consumers (MultiplayerSession) listen here for all transport
  /// lifecycle + decoded messages.
  Stream<MpServiceEvent> get events => _events.stream;

  /// The single connected endpoint, if any. Nearby hands out one ID per
  /// peer; because we're strict P2P, there's at most one.
  String? _endpointId;
  String? get endpointId => _endpointId;

  bool _advertising = false;
  bool _discovering = false;
  bool get isAdvertising => _advertising;
  bool get isDiscovering => _discovering;
  bool get isConnected => _endpointId != null;

  String _nickname = 'Player';
  String? _pinCode;

  /// Track endpoint IDs we've already sent a connection request for.
  /// Nearby Connections throws a platform exception if requestConnection
  /// is called twice on the same endpoint while a request is pending.
  final Set<String> _connectionRequestIds = {};

  /// Request the runtime permissions Nearby needs. On Android 12+ we
  /// must ask for BT scan/advertise/connect; on older devices the
  /// location permission implicitly covers BT discovery. We request
  /// all of them and ignore the ones the OS rejects as unsupported.
  ///
  /// Returns true only if the essential set was granted.
  Future<bool> requestPermissions() async {
    final needed = <Permission>[
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
      Permission.locationWhenInUse,
    ];
    final results = await needed.request();
    // Granted OR permanentlyDenied-but-not-applicable (some permissions
    // simply don't exist on older OS versions — plugin returns denied).
    // We treat any granted set that includes the three BT scopes (or
    // locationWhenInUse on pre-12) as sufficient to try.
    final bt = results[Permission.bluetoothScan] == PermissionStatus.granted &&
        results[Permission.bluetoothConnect] == PermissionStatus.granted;
    final loc =
        results[Permission.locationWhenInUse] == PermissionStatus.granted;
    return bt || loc;
  }

  /// Start advertising. Main Player calls this. The `nickname` is
  /// shown to the discovering Sidekick before they accept.
  Future<bool> startAdvertising(String nickname) async {
    if (_advertising) return true;
    _nickname = nickname;
    try {
      final ok = await _nearby.startAdvertising(
        nickname,
        _strategy,
        serviceId: serviceId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
      _advertising = ok;
      return ok;
    } catch (e) {
      _events.add(MpError('startAdvertising failed: $e'));
// Removed debugPrint for production
      return false;
    }
  }

  /// Start discovery. Sidekick calls this. Endpoints surface via
  /// `MpEndpointFound` events; we auto-request a connection to the
  /// first one that matches our service ID (which is filtered by the
  /// plugin itself).
  Future<bool> startDiscovery(String nickname, {String? pinCode}) async {
    if (_discovering) return true;
    _nickname = nickname;
    _pinCode = pinCode;
    try {
      final ok = await _nearby.startDiscovery(
        nickname,
        _strategy,
        serviceId: serviceId,
        onEndpointFound: _onEndpointFound,
        onEndpointLost: _onEndpointLost,
      );
      _discovering = ok;
      return ok;
    } catch (e) {
      _events.add(MpError('startDiscovery failed: $e'));
// Removed debugPrint for production
      return false;
    }
  }

  /// Stop advertising / discovery. Does NOT disconnect an established
  /// peer — use [disconnect] or [stopAll] for that.
  Future<void> stopSearching() async {
    if (_advertising) {
      try {
        await _nearby.stopAdvertising();
      } catch (e) {
// Removed debugPrint for production
      }
      _advertising = false;
    }
    if (_discovering) {
      try {
        await _nearby.stopDiscovery();
      } catch (e) {
// Removed debugPrint for production
      }
      _discovering = false;
    }
  }

  /// Tear everything down: drop the peer and stop searching.
  Future<void> stopAll() async {
    await stopSearching();
    try {
      await _nearby.stopAllEndpoints();
    } catch (e) {
// Removed debugPrint for production
    }
    _endpointId = null;
    _connectionRequestIds.clear();
  }

  /// Drop just the connected peer (keep advertising/discovering off).
  Future<void> disconnect() async {
    final id = _endpointId;
    if (id != null) {
      try {
        await _nearby.disconnectFromEndpoint(id);
      } catch (e) {
// Removed debugPrint for production
      }
    }
    _endpointId = null;
    _connectionRequestIds.remove(id);
  }

  /// Send a typed message to the connected peer. Throws if send fails
  /// so callers can detect failures and perform rollback. No-ops if not
  /// connected (callers should check isConnected first for critical ops).
  Future<void> sendMessage(MpMessage msg) async {
    final id = _endpointId;
    if (id == null) return;
    try {
      await _nearby.sendBytesPayload(id, msg.encode());
    } catch (e) {
// Removed debugPrint for production
      _events.add(MpError('sendMessage failed: $e'));
      rethrow; // Let caller know it failed so they can rollback.
    }
  }

  // ---- Nearby callbacks -> typed events --------------------------------

  void _onEndpointFound(String id, String name, String sid) {
    _events.add(MpEndpointFound(endpointId: id, endpointName: name));
    // Security Guard: if a PIN is set, only connect to endpoints ending with '#$pin'
    final pin = _pinCode;
    if (pin != null && !name.endsWith('#$pin')) {
      return; // ignore!
    }
    // Guard: already connected (P2P — only one peer) or already requested.
    if (_endpointId != null || _connectionRequestIds.contains(id)) return;
    _connectionRequestIds.add(id);
    // Auto-request connection — we only advertise/discover our own
    // serviceId, so any found endpoint is already one of us.
    unawaited(_nearby
        .requestConnection(
          _nickname,
          id,
          onConnectionInitiated: _onConnectionInitiated,
          onConnectionResult: _onConnectionResult,
          onDisconnected: _onDisconnected,
        )
        .catchError((Object e) {
      _events.add(MpError('requestConnection failed: $e'));
      _connectionRequestIds.remove(id);
      return false;
    }));
  }

  void _onEndpointLost(String? id) {
    final epId = id ?? '';
    _events.add(MpEndpointLost(endpointId: epId));
    // Clean up so a rediscovery of the same endpoint can re-request.
    if (epId.isNotEmpty) _connectionRequestIds.remove(epId);
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    _events.add(MpConnectionInitiated(
      endpointId: id,
      endpointName: info.endpointName,
      authToken: info.authenticationToken,
      isIncoming: info.isIncomingConnection,
    ));
    // Auto-accept. For this app there's no meaningful auth handshake
    // beyond "both users tapped their role buttons" — they're already
    // expecting each other. Skipping the confirm-token dialog keeps
    // the flow to two taps total.
    unawaited(_nearby
        .acceptConnection(id, onPayLoadRecieved: _onPayloadReceived)
        .catchError((Object e) {
      _events.add(MpError('acceptConnection failed: $e'));
      return false;
    }));
  }

  void _onConnectionResult(String id, Status status) {
    switch (status) {
      case Status.CONNECTED:
        _endpointId = id;
        // Stop advertising/discovering once connected — those radios
        // are heavy and pointless to keep running. Re-enable on
        // explicit reconnect.
        unawaited(stopSearching());
        _events.add(MpConnected(endpointId: id));
      case Status.REJECTED:
        _connectionRequestIds.remove(id);
        _events.add(MpRejected(endpointId: id));
      case Status.ERROR:
        _connectionRequestIds.remove(id);
        _events.add(MpError('Connection result: ERROR for $id'));
    }
  }

  void _onDisconnected(String id) {
    if (_endpointId == id) _endpointId = null;
    _connectionRequestIds.remove(id);
    _events.add(const MpDisconnected());
  }

  void _onPayloadReceived(String endpointId, Payload payload) {
    if (payload.type != PayloadType.BYTES) return;
    final bytes = payload.bytes;
    if (bytes == null || bytes.isEmpty) return;
    try {
      final msg = MpMessage.decode(bytes);
      _events.add(MpMessageReceived(msg));
    } catch (e) {
// Removed debugPrint for production
    }
  }

  /// Release the broadcast stream. Call only on full app teardown.
  Future<void> dispose() async {
    await stopAll();
    await _events.close();
  }
}

// =============================================================================
// Transport events
// =============================================================================

/// Sealed hierarchy of events surfaced by [MultiplayerService]. Consumers
/// switch-exhaustively on these to drive their state machine.
sealed class MpServiceEvent {
  const MpServiceEvent();
}

class MpEndpointFound extends MpServiceEvent {
  final String endpointId;
  final String endpointName;
  const MpEndpointFound({required this.endpointId, required this.endpointName});
}

class MpEndpointLost extends MpServiceEvent {
  final String endpointId;
  const MpEndpointLost({required this.endpointId});
}

class MpConnectionInitiated extends MpServiceEvent {
  final String endpointId;
  final String endpointName;
  final String authToken;
  final bool isIncoming;
  const MpConnectionInitiated({
    required this.endpointId,
    required this.endpointName,
    required this.authToken,
    required this.isIncoming,
  });
}

class MpConnected extends MpServiceEvent {
  final String endpointId;
  const MpConnected({required this.endpointId});
}

class MpRejected extends MpServiceEvent {
  final String endpointId;
  const MpRejected({required this.endpointId});
}

class MpDisconnected extends MpServiceEvent {
  const MpDisconnected();
}

class MpMessageReceived extends MpServiceEvent {
  final MpMessage message;
  const MpMessageReceived(this.message);
}

class MpError extends MpServiceEvent {
  final String message;
  const MpError(this.message);
}
