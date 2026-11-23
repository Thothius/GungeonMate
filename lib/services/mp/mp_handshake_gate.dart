/// Pure decision logic for the Nearby Connections handshake window.
///
/// Extracted from `MpLink` so the mis-pair guards are unit-testable
/// without the `Nearby` singleton (which listens on a platform
/// EventChannel and can't be instantiated in tests). `MpLink` owns the
/// side effects (accept/reject/disconnect calls, timers); this class
/// owns *which* side effect is correct.
library;

/// Verdict for an incoming `onConnectionInitiated` event.
enum MpInitiatedVerdict {
  /// No conflict — proceed with acceptConnection.
  accept,

  /// A different endpoint is already connected — reject so the
  /// initiator isn't left hanging on a phantom pairing.
  rejectOtherConnected,

  /// Another handshake is already mid-flight — reject. Accepting
  /// would natively connect the second peer and then drop it in the
  /// result guard, leaving a phantom pairing on their side.
  rejectHandshakeInFlight,
}

class MpHandshakeGate {
  /// Endpoints currently mid-handshake (initiated but no result yet).
  final Set<String> initiatedIds = {};

  /// Decide how to handle an incoming connection initiation.
  ///
  /// [activeEndpointId] is the currently connected endpoint, if any.
  /// Order matters: the connected-peer check runs first so a stale
  /// pending handshake can't mask a live connection.
  MpInitiatedVerdict onInitiated(String id, String? activeEndpointId) {
    if (activeEndpointId != null && activeEndpointId != id) {
      return MpInitiatedVerdict.rejectOtherConnected;
    }
    if (initiatedIds.isNotEmpty && !initiatedIds.contains(id)) {
      return MpInitiatedVerdict.rejectHandshakeInFlight;
    }
    initiatedIds.add(id);
    return MpInitiatedVerdict.accept;
  }

  /// A CONNECTED result arrived — clear the pending mark.
  void onResult(String id) => initiatedIds.remove(id);

  /// The endpoint went away mid-handshake (native disconnect before a
  /// result) — clear the pending mark so the gate un-wedges.
  void onEndpointGone(String id) => initiatedIds.remove(id);

  /// A CONNECTED result for [id] must tear down a phantom when a
  /// *different* endpoint is already active — the native side
  /// connected anyway, so disconnect it rather than overwrite state.
  bool resultDisconnectsPhantom(String id, String? activeEndpointId) =>
      activeEndpointId != null && activeEndpointId != id;

  /// Handshake-stall eviction: drop [id] from the pending set unless
  /// it has since become the active endpoint.
  void evictStale(String id, String? activeEndpointId) {
    if (activeEndpointId != id) initiatedIds.remove(id);
  }

  /// Full reset (stopAll / heartbeat-timeout teardown paths).
  void clear() => initiatedIds.clear();
}
