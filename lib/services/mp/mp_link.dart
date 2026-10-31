import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/multiplayer_messages.dart';
import 'mp_transport.dart';

export 'mp_transport.dart'
    show MpEndpoint, AutoConnectMode, AutoConnectModeNone, AutoConnectModeAny;

/// Transport layer — thin, event-driven wrapper over `nearby_connections`.
///
/// Owns one peer-to-peer Nearby Connections connection. Handles advertising
/// (Main), discovery (Sidekick), auto-accept, message send/receive, heartbeat,
/// and persistent advertising for reconnect.
///
/// Replaces `MultiplayerService`. The only thing above this is `MpSession`,
/// which talks to it via callbacks.
class MpLink implements MpTransport {
  MpLink();

  /// Service ID for the classic lobby-based MP flow.
  static const String serviceIdClassic = 'com.saare.gungeon_mate.mp.v2';

  /// Legacy accessor kept for any call-site still reading the constant.
  static String get serviceId => serviceIdClassic;

  static const Strategy _strategy = Strategy.P2P_POINT_TO_POINT;

  final Nearby _nearby = Nearby();

  // ── Callbacks (set by MpSession) ──────────────────────────────
  @override
  void Function(List<MpEndpoint>)? onEndpointsChanged;
  @override
  void Function(MpMessage)? onMessage;
  @override
  void Function()? onConnected;
  @override
  void Function()? onDisconnected;
  @override
  void Function(String error)? onError;

  // ── Internal state ────────────────────────────────────────────
  String? _endpointId;
  @override
  String? get endpointId => _endpointId;
  @override
  bool get isConnected => _endpointId != null;

  bool _advertising = false;
  bool _discovering = false;
  @override
  bool get isAdvertising => _advertising;
  @override
  bool get isDiscovering => _discovering;

  String _nickname = 'Player';
  AutoConnectMode _autoConnect = const AutoConnectModeNone();
  AutoConnectMode get autoConnect => _autoConnect;

  /// Guard against double-tap / parallel transport transitions.
  bool _busyTransition = false;
  bool get isBusy => _busyTransition;

  /// Track endpoint IDs we've already sent a connection request for.
  /// Nearby Connections throws if requestConnection is called twice on
  /// the same endpoint while a request is pending.
  final Set<String> _connectionRequestIds= {};

  /// True when a connection request is in-flight. The discovery loop
  /// must NOT pause/stop discovery while this is true — doing so can
  /// silently abort the pending connection on some Android devices.
  bool _connectionInFlight = false;

  /// Endpoints currently mid-handshake (initiated but no result yet).
  /// Guards the accept window: a second initiator arriving before the
  /// first CONNECTED result would be natively accepted, then dropped
  /// by the _endpointId guard in _onConnectionResult — leaving a
  /// phantom pairing on the peer's side.
  final Set<String> _initiatedIds= {};

  /// Discovered endpoints (live list for Sidekick UI).
  final Map<String, MpEndpoint> _endpoints= {};
  @override
  List<MpEndpoint> get discoveredEndpoints =>
      _endpoints.values.toList()
        ..sort((a, b) => b.lastSeenMs.compareTo(a.lastSeenMs));

  // ── Discovery loop ────────────────────────────────────────────
  Timer? _discoveryLoopTimer;
  Timer? _discoveryOffTimer;
  Duration _discoveryOn = const Duration(seconds: 3);
  Duration _discoveryOff = const Duration(seconds: 1);
  bool _discoveryActive = false;

  // ── Heartbeat ─────────────────────────────────────────────────
  Timer? _heartbeatTimer;
  int _lastPeerTouchMs = 0;
  static const int _heartbeatIntervalSec = 5;
  static const int _heartbeatTimeoutSec = 25;

  // ── Connection health (RTT-based, 0–100) ──────────────────────
  final ValueNotifier<int> _health= ValueNotifier<int>(0);
  @override
  final ValueListenable<int> get healthListenable => _health;
  double _healthEwma = 0;
  bool _healthPrimed = false;

  /// Fold one RTT sample into the EWMA health score. Sub-150ms links
  /// read as perfect; score decays to ~0 at 2s round-trip.
  void _sampleRtt(int rttMs) {
    final raw =
        rttMs <= 150
            ? 100.0
            : rttMs >= 2000
            ? 0.0
            : (1.0 - (rttMs - 150) / 1850.0) * 100.0;
    _healthEwma = _healthPrimed ? _healthEwma * 0.65 + raw * 0.35 : raw;
    _healthPrimed = true;
    _publishHealth();
  }

  void _penalizeHealth(double penalty) {
    if (!_healthPrimed) return;
    _healthEwma = (_healthEwma - penalty).clamp(0.0, 100.0);
    _publishHealth();
  }

  void _resetHealth() {
    _healthEwma = 0;
    _healthPrimed = false;
    _publishHealth();
  }

  void _publishHealth() {
    final v = _healthPrimed ? _healthEwma.round().clamp(0, 100) : 0;
    if (_health.value != v) _health.value = v;
  }

  // ── Stale endpoint cleanup ────────────────────────────────────
  Timer? _staleCleanupTimer;
  static const int _staleEndpointMs = 8000;

  // ── Permissions ───────────────────────────────────────────────

  /// Request the runtime permissions Nearby needs. Returns true only if
  /// the essential set was granted.
  @override
  Future<bool> requestPermissions() async {
    final needed = <Permission>[
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
      Permission.locationWhenInUse,
    ];
    final results = await needed.request();
    final bt =
        results[Permission.bluetoothScan] == PermissionStatus.granted &&
        results[Permission.bluetoothConnect] == PermissionStatus.granted;
    // On Android 12+ (API 31+), nearby_wifi_devices replaces
    // locationWhenInUse for Wi-Fi direct discovery. If the user granted
    // nearbyWifiDevices, accept that as satisfying the location
    // requirement — requiring locationWhenInUse on Android 12+ causes
    // a false permission-denied softlock when the OS doesn't prompt
    // for location (it's not needed anymore).
    final nearbyWifi =
        results[Permission.nearbyWifiDevices] == PermissionStatus.granted;
    final loc =
        results[Permission.locationWhenInUse] == PermissionStatus.granted;
    final locationOk = loc || nearbyWifi;
    // Bluetooth is always required. Location OR nearby_wifi is required
    // depending on Android version.
    return bt && locationOk;
  }

  // ── Advertising (Main) ────────────────────────────────────────

  /// Start advertising. Main Player calls this. `nickname` is the
  /// player's display name — discoverers see it and auto-connect.
  @override
  Future<void> startAdvertising(String nickname) async {
    if (_busyTransition) return;
    _busyTransition = true;
    try {
      _nickname = nickname;
      if (_advertising) return; // already advertising
      final ok = await _nearby.startAdvertising(
        nickname,
        _strategy,
        serviceId: serviceIdClassic,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
      _advertising = ok;
      if (!ok) {
        onError?.call('Could not start advertising. Try toggling Bluetooth.');
      }
    } catch (e) {
      onError?.call('startAdvertising failed: $e');
    } finally {
      _busyTransition = false;
    }
  }

  // ── Discovery (Sidekick) ──────────────────────────────────────

  /// Start discovery with an auto-connect mode. The discovery loop
  /// runs on a cadence controlled by [setDiscoveryCadence].
  @override
  Future<void> startDiscovery(
    String nickname, {
    required AutoConnectMode autoConnect,
  }) async {
    if (_busyTransition) return;
    _busyTransition = true;
    try {
      _nickname = nickname;
      _autoConnect = autoConnect;
      _endpoints.clear();
      // Reset stale connection state from a prior session so
      // old request IDs / in-flight flags don't block reconnect.
      _connectionRequestIds.clear();
      _connectionInFlight = false;
      onEndpointsChanged?.call(discoveredEndpoints);
      if (_discovering) return; // already discovering
      final ok = await _nearby.startDiscovery(
        nickname,
        _strategy,
        serviceId: serviceIdClassic,
        onEndpointFound: _onEndpointFound,
        onEndpointLost: _onEndpointLost,
      );
      if (!ok) {
        onError?.call('Could not start discovery. Try toggling Bluetooth.');
      } else {
        _discovering = true;
        _discoveryActive = true;
        _startDiscoveryLoop();
        _startStaleCleanup();
      }
    } catch (e) {
      onError?.call('startDiscovery failed: $e');
    } finally {
      _busyTransition = false;
    }
  }

  /// Set the discovery loop cadence (on/off durations).
  @override
  void setDiscoveryCadence(Duration on, Duration off) {
    _discoveryOn = on;
    _discoveryOff = off;
    // Cancel any pending off-cycle resume so an old resume doesn't
    // fire after the new cadence has started.
    _discoveryOffTimer?.cancel();
    _discoveryOffTimer = null;
    // If loop is running, restart with new cadence.
    if (_discoveryLoopTimer != null) {
      _discoveryLoopTimer?.cancel();
      _startDiscoveryLoop();
    }
  }

  /// The discovery loop: scan for `_discoveryOn`, pause for
  /// `_discoveryOff`, repeat. Nearby Connections doesn't support
  /// continuous discovery indefinitely on all platforms, so we cycle.
  void _startDiscoveryLoop() {
    _discoveryLoopTimer?.cancel();
    _discoveryLoopTimer = Timer(_discoveryOn, () {
      // Don't pause discovery if a connection request is in-flight —
      // stopping discovery can silently abort the pending connection.
      // But reschedule so the loop doesn't die forever.
      if (_connectionInFlight) {
        _discoveryLoopTimer = Timer(_discoveryOff, _startDiscoveryLoop);
        return;
      }
      if (!_discovering || !_discoveryActive) return;
      // Pause discovery for the off duration, then resume.
      unawaited(
        _pauseDiscovery().then((_) {
          if (!_discoveryActive) return;
          _discoveryOffTimer?.cancel();
          _discoveryOffTimer = Timer(_discoveryOff, () {
            if (!_discoveryActive) return;
            _resumeDiscovery();
          });
        }),
      );
    });
  }

  Future<void> _pauseDiscovery() async {
    if (!_discovering) return;
    try {
      await _nearby.stopDiscovery();
    } catch (_) {}
    _discovering = false;
  }

  Future<void> _resumeDiscovery() async {
    if (!_discoveryActive) return; // cancelled while off-cycle
    if (_discovering) return;
    try {
      final ok = await _nearby.startDiscovery(
        _nickname,
        _strategy,
        serviceId: serviceIdClassic,
        onEndpointFound: _onEndpointFound,
        onEndpointLost: _onEndpointLost,
      );
      _discovering = ok;
      if (ok) _startDiscoveryLoop();
    } catch (_) {
      // Retry on next cycle.
      Future.delayed(_discoveryOff, _resumeDiscovery);
    }
  }

  void _startStaleCleanup() {
    _staleCleanupTimer?.cancel();
    _staleCleanupTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final now = DateTime.now().millisecondsSinceEpoch;
      var changed = false;
      _endpoints.removeWhere((id, ep) {
        final stale = now - ep.lastSeenMs > _staleEndpointMs;
        if (stale) {
          _connectionRequestIds.remove(id);
          changed = true;
        }
        return stale;
      });
      if (changed) onEndpointsChanged?.call(discoveredEndpoints);
    });
  }

  // ── Stop / disconnect ─────────────────────────────────────────

  /// Stop advertising and discovery. Does NOT disconnect an established
  /// peer — use [disconnectPeer] or [stopAll] for that.
  @override
  Future<void> stopSearching() async {
    _discoveryActive = false;
    _discoveryLoopTimer?.cancel();
    _discoveryLoopTimer = null;
    _discoveryOffTimer?.cancel();
    _discoveryOffTimer = null;
    _staleCleanupTimer?.cancel();
    _staleCleanupTimer = null;
    _endpoints.clear();
    _connectionRequestIds.clear();
    _initiatedIds.clear();
    _connectionInFlight = false;
    onEndpointsChanged?.call(discoveredEndpoints);
    if (_advertising) {
      try {
        await _nearby.stopAdvertising();
      } catch (_) {}
      _advertising = false;
    }
    if (_discovering) {
      try {
        await _nearby.stopDiscovery();
      } catch (_) {}
      _discovering = false;
    }
  }

  /// Stop everything: advertising, discovery, peer connection.
  @override
  Future<void> stopAll() async {
    await stopSearching();
    try {
      await _nearby.stopAllEndpoints();
    } catch (_) {}
    _endpointId = null;
    _connectionRequestIds.clear();
    _initiatedIds.clear();
    _connectionInFlight = false;
    _stopHeartbeat();
    _discoveryOffTimer?.cancel();
    _discoveryOffTimer = null;
  }

  /// Drop just the connected peer (keep advertising/discovering off).
  @override
  Future<void> disconnectPeer() async {
    final id = _endpointId;
    if (id != null) {
      try {
        await _nearby.disconnectFromEndpoint(id);
      } catch (_) {}
    }
    _endpointId = null;
    _connectionRequestIds.remove(id);
    _stopHeartbeat();
  }

  // ── Messaging ─────────────────────────────────────────────────

  /// Send a typed message to the connected peer. No-ops if not connected.
  @override
  Future<void> sendMessage(MpMessage msg) async {
    final id = _endpointId;
    if (id == null) return;
    try {
      await _nearby.sendBytesPayload(id, msg.encode());
    } catch (e) {
      onError?.call('sendMessage failed: $e');
      rethrow;
    }
  }

  // ── Heartbeat ─────────────────────────────────────────────────

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _lastPeerTouchMs = DateTime.now().millisecondsSinceEpoch;
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: _heartbeatIntervalSec),
      (_) {
        if (!isConnected) {
          _stopHeartbeat();
          return;
        }
        // sendMessage rethrows on failure — catch it so the
        // unawaited future doesn't become an unhandled async error.
        sendMessage(
          MpPing(DateTime.now().millisecondsSinceEpoch),
        ).catchError((Object _) {});
        // Check for timeout.
        final silentMs =
            DateTime.now().millisecondsSinceEpoch - _lastPeerTouchMs;
        if (silentMs > _heartbeatTimeoutSec * 1000) {
          _heartbeatTimer?.cancel();
          _heartbeatTimer = null;
          // Peer is gone — tear down the native endpoint before
          // signalling disconnect so the radio is released for
          // reconnection attempts.
          final id = _endpointId;
          _endpointId = null;
          _connectionRequestIds.clear();
          _initiatedIds.clear();
          _connectionInFlight = false;
          _resetHealth();
          if (id != null) {
            unawaited(
              _nearby.disconnectFromEndpoint(id).catchError((Object _) {}),
            );
          }
          onDisconnected?.call();
        } else if (silentMs > _heartbeatIntervalSec * 1600) {
          // A beat went unanswered — degrade the health score.
          _penalizeHealth(15);
        }
      },
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Restart the heartbeat timer (e.g. after app resume from background
  /// where the OS may have killed the timer). If connected, immediately
  /// sends a ping to verify liveness.
  @override
  void restartHeartbeat() {
    if (!isConnected) return;
    _startHeartbeat();
    sendMessage(
      MpPing(DateTime.now().millisecondsSinceEpoch),
    ).catchError((Object _) {});
  }

  // ── Nearby callbacks ──────────────────────────────────────────

  void _onEndpointFound(String id, String name, String sid) {
    // Use the raw endpoint name as the nickname (no PIN parsing).
    final nick = name;

    _endpoints[id] = MpEndpoint(
      endpointId: id,
      nickname: nick,
      lastSeenMs: DateTime.now().millisecondsSinceEpoch,
    );
    onEndpointsChanged?.call(discoveredEndpoints);

    // Auto-connect based on mode.
    final mode = _autoConnect;
    bool shouldConnect = false;
    switch (mode) {
      case AutoConnectModeNone():
        shouldConnect = false;
      case AutoConnectModeAny():
        shouldConnect = true;
    }
    if (!shouldConnect) return;

    // Guard: already connected, already requested, or another
    // connection request is already in-flight.
    if (_endpointId != null || _connectionInFlight) return;
    if (_connectionRequestIds.contains(id)) return;
    _connectionRequestIds.add(id);
    _connectionInFlight = true; // Pause discovery loop.
    unawaited(
      _nearby
          .requestConnection(
            _nickname,
            id,
            onConnectionInitiated: _onConnectionInitiated,
            onConnectionResult: _onConnectionResult,
            onDisconnected: _onDisconnected,
          )
          .catchError((Object e) {
            _connectionRequestIds.remove(id);
            _connectionInFlight = false; // Resume discovery loop.
            return false;
          }),
    );
  }

  void _onEndpointLost(String? id) {
    final epId = id ?? '';
    if (epId.isNotEmpty) {
      _endpoints.remove(epId);
      _connectionRequestIds.remove(epId);
      onEndpointsChanged?.call(discoveredEndpoints);
    }
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    // Guard: reject if already connected to another peer — actively,
    // so the initiator isn't left hanging on the native side.
    if (_endpointId != null && _endpointId != id) {
      unawaited(_nearby.rejectConnection(id).catchError((Object _) => false));
      return;
    }
    // Guard: one handshake at a time. A second initiator arriving while
    // the first is mid-accept would otherwise be natively connected and
    // then dropped by the result guard below — a phantom pairing.
    if (_initiatedIds.isNotEmpty && !_initiatedIds.contains(id)) {
      unawaited(_nearby.rejectConnection(id).catchError((Object _) => false));
      return;
    }
    _initiatedIds.add(id);
    // Handshake-stall guard — if no result ever arrives for this
    // endpoint, evict it after 20s so the accept gate un-wedges.
    Timer(const Duration(seconds: 20), () {
      if (_endpointId != id) _initiatedIds.remove(id);
    });
    // Auto-accept — both users already chose to play.
    unawaited(
      _nearby
          .acceptConnection(id, onPayLoadRecieved: _onPayloadReceived)
          .catchError((Object e) {
            _initiatedIds.remove(id);
            onError?.call('acceptConnection failed: $e');
            return false;
          }),
    );
  }

  void _onConnectionResult(String id, Status status) {
    _connectionInFlight = false; // Resume discovery loop if needed.
    _initiatedIds.remove(id);
    switch (status) {
      case Status.CONNECTED:
        // Guard: don't overwrite an existing active connection — tear
        // the phantom down so the peer doesn't sit "connected" with no
        // Dart-side state behind it.
        if (_endpointId != null && _endpointId != id) {
          unawaited(
            _nearby.disconnectFromEndpoint(id).catchError((Object _) {}),
          );
          return;
        }
        _endpointId = id;
        // Stop searching once connected — radios are heavy and pointless.
        unawaited(_stopSearchingKeepState());
        _resetHealth();
        _startHeartbeat();
        onConnected?.call();
      case Status.REJECTED:
        _connectionRequestIds.remove(id);
        onError?.call('Connection rejected by peer');
        // Resume discovery loop to try again.
        if (_discoveryActive) _startDiscoveryLoop();
      case Status.ERROR:
        _connectionRequestIds.remove(id);
        onError?.call('Connection result: ERROR for $id');
        // Resume discovery loop to try again.
        if (_discoveryActive) _startDiscoveryLoop();
    }
  }

  /// Stop searching but don't clear the endpoint list (we might want
  /// it for reconnect display). Internal variant of stopSearching.
  Future<void> _stopSearchingKeepState() async {
    _discoveryActive = false;
    _discoveryLoopTimer?.cancel();
    _discoveryLoopTimer = null;
    _discoveryOffTimer?.cancel();
    _discoveryOffTimer = null;
    // Cancel stale cleanup so discovered endpoints persist for
    // reconnect display instead of being pruned after 8 seconds.
    _staleCleanupTimer?.cancel();
    _staleCleanupTimer = null;
    if (_advertising) {
      try {
        await _nearby.stopAdvertising();
      } catch (_) {}
      _advertising = false;
    }
    if (_discovering) {
      try {
        await _nearby.stopDiscovery();
      } catch (_) {}
      _discovering = false;
    }
  }

  void _onDisconnected(String id) {
    // Clean up pending connection state even if this wasn't the
    // active endpoint (e.g. a handshake that never completed).
    _initiatedIds.remove(id);
    _connectionRequestIds.remove(id);
    if (_connectionRequestIds.isEmpty) {
      _connectionInFlight = false;
    }
    if (_endpointId == id) {
      _endpointId = null;
      _stopHeartbeat();
      _resetHealth();
      onDisconnected?.call();
    }
  }

  void _onPayloadReceived(String endpointId, Payload payload) {
    if (payload.type != PayloadType.BYTES) return;
    final bytes = payload.bytes;
    if (bytes == null || bytes.isEmpty) return;
    _lastPeerTouchMs = DateTime.now().millisecondsSinceEpoch;
    try {
      final msg = MpMessage.decode(bytes);
      // Pong echoes our ping ts → round-trip time for the health score.
      if (msg is MpPong && msg.tsMs > 0) {
        final rtt = DateTime.now().millisecondsSinceEpoch - msg.tsMs;
        if (rtt >= 0 && rtt < 10000) _sampleRtt(rtt);
      }
      onMessage?.call(msg);
    } catch (_) {
      // Malformed message — drop silently.
    }
  }

  // ── Cleanup ───────────────────────────────────────────────────

  @override
  Future<void> dispose() async {
    await stopAll();
  }
}
