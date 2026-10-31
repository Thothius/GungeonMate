import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;

import '../../models/multiplayer_messages.dart';

/// Transport interface for MP peer-to-peer communication.
///
/// The production implementation is [MpLink] (wrapping `nearby_connections`).
/// Tests use [FakeMpLink] to simulate two devices talking in-process.
///
/// This interface exists so [MpSession], [MpSync], and [MpRecovery] can
/// depend on the transport contract rather than a concrete native plugin,
/// enabling hermetic integration tests without Bluetooth/Wi-Fi.
abstract class MpTransport {
  // ── Callbacks (set by MpSession) ────────────────────────────────
  void Function(List<MpEndpoint>)? onEndpointsChanged;
  void Function(MpMessage)? onMessage;
  void Function()? onConnected;
  void Function()? onDisconnected;
  void Function(String error)? onError;

  // ── State ───────────────────────────────────────────────────────
  String? get endpointId;
  bool get isConnected;
  bool get isAdvertising;
  bool get isDiscovering;
  List<MpEndpoint> get discoveredEndpoints;

  /// Connection health estimate 0–100, derived from ping/pong RTT and
  /// missed heartbeats. 0 while disconnected.
  ValueListenable<int> get healthListenable;

  /// Switch the Nearby Connections service id used for advertising and
  /// discovery. Must be called before startAdvertising/startDiscovery —
  /// each MP mode (classic, paradox) uses its own id so cross-mode

  // ── Lifecycle ───────────────────────────────────────────────────
  Future<bool> requestPermissions();
  Future<void> startAdvertising(String nickname);
  Future<void> startDiscovery(
    String nickname, {
    required AutoConnectMode autoConnect,
  });
  void setDiscoveryCadence(Duration on, Duration off);
  Future<void> stopSearching();
  Future<void> stopAll();
  Future<void> disconnectPeer();
  void restartHeartbeat();
  Future<void> dispose();

  // ── Messaging ───────────────────────────────────────────────────
  Future<void> sendMessage(MpMessage msg);
}

/// A discovered endpoint (game host) surfaced to the Sidekick UI.
class MpEndpoint {
  final String endpointId;
  final String nickname;
  final int lastSeenMs;

  const MpEndpoint({
    required this.endpointId,
    required this.nickname,
    required this.lastSeenMs,
  });
}

/// Controls auto-connect behavior during discovery.
sealed class AutoConnectMode {
  const AutoConnectMode();
}

/// Don't auto-connect — surface endpoints to UI for manual selection.
class AutoConnectModeNone extends AutoConnectMode {
  const AutoConnectModeNone();
}

/// Auto-connect to the first discovered endpoint (PINless mode).
class AutoConnectModeAny extends AutoConnectMode {
  const AutoConnectModeAny();
}
