import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gungeon_mate/models/multiplayer_messages.dart';
import 'package:gungeon_mate/services/mp/mp_transport.dart';

/// In-memory fake transport for MP integration tests.
///
/// Two [FakeMpLink] instances are paired via [connectTo]. When one side
/// sends a message, it's delivered to the peer's `onMessage` callback
/// synchronously. When one side disconnects, the peer gets `onDisconnected`.
///
/// This simulates the full Nearby Connections lifecycle without needing
/// Bluetooth/Wi-Fi or real devices.
///
/// Usage:
/// ```dart
/// final host = FakeMpLink();
/// final guest = FakeMpLink();
/// host.connectTo(guest);
/// // Now host.sendMessage(msg) → guest.onMessage(msg)
/// // and guest.sendMessage(msg) → host.onMessage(msg)
/// ```
class FakeMpLink implements MpTransport {
  FakeMpLink({this.endpointIdValue = 'fake-endpoint'});

  /// The endpoint ID returned by [endpointId]. Set to null when
  /// disconnected.
  String? endpointIdValue;

  /// The paired peer. Set by [connectTo].
  FakeMpLink? _peer;

  /// Wire two fakes together so messages flow bidirectionally.
  void connectTo(FakeMpLink other) {
    _peer = other;
    other._peer = this;
  }

  // ── Callbacks ──────────────────────────────────────────────────
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

  // ── State ──────────────────────────────────────────────────────
  @override
  String? get endpointId => endpointIdValue;
  @override
  bool get isConnected => endpointIdValue != null && _peer != null;
  @override
  bool get isAdvertising => _advertising;
  bool _advertising = false;

  @override
  bool get isDiscovering => _discovering;
  bool _discovering = false;

  @override
  List<MpEndpoint> get discoveredEndpoints => _endpoints.values.toList();
  final Map<String, MpEndpoint> _endpoints = {};

  @override
  final ValueNotifier<int> healthListenable = ValueNotifier<int>(100);

  String? serviceIdUsed;

  String _nickname = 'Player';
  AutoConnectMode _autoConnect = const AutoConnectModeNone();

  /// Simulate the full connection handshake:
  /// 1. Host starts advertising with "Nickname"
  /// 2. Guest starts discovery with AutoConnectModeAny
  /// 3. Guest "discovers" the host's endpoint
  /// 4. Both sides get onConnected
  ///
  /// Call this after both sides have called startAdvertising/startDiscovery.
  void simulateDiscovery() {
    if (_peer == null) return;
    // The discovering side (guest) finds the advertising side (host).
    if (_discovering && _peer!._advertising) {
      final hostName = _peer!._nickname;

      // Surface endpoint to guest
      _endpoints['host-endpoint'] = MpEndpoint(
        endpointId: 'host-endpoint',
        nickname: hostName,
        lastSeenMs: DateTime.now().millisecondsSinceEpoch,
      );
      onEndpointsChanged?.call(discoveredEndpoints);

      // Check auto-connect mode.
      final mode = _autoConnect;
      bool shouldConnect = false;
      switch (mode) {
        case AutoConnectModeNone():
          shouldConnect = false;
        case AutoConnectModeAny():
          shouldConnect = true;
      }

      if (shouldConnect) {
        _completeConnection();
      }
    }
  }

  /// Mark both sides as connected and fire onConnected callbacks.
  void _completeConnection() {
    endpointIdValue = 'peer-endpoint';
    _peer!.endpointIdValue = 'peer-endpoint';
    _advertising = false;
    _discovering = false;
    onConnected?.call();
    _peer!.onConnected?.call();
  }

  /// Manually trigger connection (for tests that bypass discovery).
  void forceConnect() {
    if (_peer == null) return;
    _completeConnection();
  }

  // ── Lifecycle ──────────────────────────────────────────────────

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> startAdvertising(String nickname) async {
    _nickname = nickname;
    _advertising = true;
  }

  @override
  Future<void> startDiscovery(
    String nickname, {
    required AutoConnectMode autoConnect,
  }) async {
    _nickname = nickname;
    _autoConnect = autoConnect;
    _discovering = true;
  }

  @override
  void setDiscoveryCadence(Duration on, Duration off) {
    // No-op in fake — no real discovery loop.
  }

  @override
  Future<void> stopSearching() async {
    _advertising = false;
    _discovering = false;
    _endpoints.clear();
    onEndpointsChanged?.call(discoveredEndpoints);
  }

  @override
  Future<void> stopAll() async {
    await stopSearching();
    endpointIdValue = null;
  }

  @override
  Future<void> disconnectPeer() async {
    final wasConnected = endpointIdValue != null;
    endpointIdValue = null;
    if (wasConnected && _peer != null) {
      // Notify peer of disconnect
      final peer = _peer!;
      // Don't clear _peer — reconnect may use it
      onDisconnected?.call();
      peer.onDisconnected?.call();
    }
  }

  @override
  void restartHeartbeat() {
    // No-op in fake — no real heartbeat timer.
  }

  // ── Messaging ──────────────────────────────────────────────────

  @override
  Future<void> sendMessage(MpMessage msg) async {
    if (endpointIdValue == null || _peer == null) return;
    // Deliver to peer synchronously
    _peer!.onMessage?.call(msg);
  }

  @override
  Future<void> dispose() async {
    await stopAll();
    _peer?._peer = null;
    _peer = null;
  }
}
