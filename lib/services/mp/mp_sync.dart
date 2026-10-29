import 'dart:async';
import 'dart:math' as math;

import '../../models/gun.dart';
import '../../models/item.dart';
import '../../models/multiplayer_messages.dart';
import '../../models/player.dart';
import '../../providers/run_provider.dart';
import 'mp_transport.dart';

/// Tracks a gift that has been removed from inventory and sent but not
/// yet confirmed by the peer's snapshot.
class _PendingGift {
  final String giftId;
  final String kind;
  final String name;
  final bool localRemoval;
  _PendingGift({
    required this.giftId,
    required this.kind,
    required this.name,
    this.localRemoval = true,
  });
}

/// A single outgoing request waiting for a `requestResp`.
class _OutgoingRequest {
  final String kind;
  final String name;
  _OutgoingRequest(this.kind, this.name);
}

/// State synchronization layer. Keeps the local `RunProvider` in sync
/// with the peer via full snapshots, gifts, requests, dice, and emotes.
///
/// Replaces the snapshot/gift/request handling in the old
/// `MultiplayerSession` god class.
class MpSync {
  final MpTransport _link;
  final RunProvider _runProvider;
  void Function(MpRole role) onPeerConnected;
  void Function(String peerNickname, String peerCharacter) onPeerMetadata;

  MpSync(
    this._link,
    this._runProvider, {
    required this.onPeerConnected,
    required this.onPeerMetadata,
  });

  // ── Guards ─────────────────────────────────────────────────────

  /// True while applying a peer snapshot to RunProvider. Prevents the
  /// infinite echo loop: apply peer → RunProvider notifies → our
  /// listener broadcasts → peer applies → ...
  bool _applyingRemote = false;
  bool _helloReceived = false;

  /// Tracks whether we believe a transport connection is active.
  /// If onConnected fires while this is true, it means the transport
  /// didn't deliver an onDisconnected first — we must reset all
  /// connection-scoped state to avoid stale data.
  bool _transportConnected = false;
  int _helloAttempts = 0;
  static const int _maxHelloAttempts = 3;
  static const int _helloTimeoutMs = 5000;
  Timer? _helloRetryTimer;

  // ── Peer metadata ──────────────────────────────────────────────
  MpRole? _peerRole;
  String? _peerNickname;
  String? _peerCharacterName;

  MpRole? get peerRole => _peerRole;
  String? get peerNickname => _peerNickname;
  String? get peerCharacterName => _peerCharacterName;

  // ── Request/gift state ─────────────────────────────────────────
  MpRequest? _pendingRequest;
  MpRequest? get pendingRequest => _pendingRequest;

  final Map<String, _OutgoingRequest> _outgoingRequests = {};
  ({String name, bool approved})? _lastResp;
  ({String name, bool approved})? get lastResp => _lastResp;
  void consumeLastResp() {
    if (_lastResp != null) {
      _lastResp = null;
    }
  }

  // ── Dedup sets ─────────────────────────────────────────────────
  final Set<String> _seenReqIds = {};
  static const int _maxSeenReqIds = 20;
  final Set<String> _seenGiftIds = {};
  static const int _maxSeenGiftIds = 20;

  // ── Pending gifts ──────────────────────────────────────────────
  final List<_PendingGift> _pendingGifts = [];
  static const int _maxPendingGifts = 50;
  int get pendingGiftCount => _pendingGifts.length;

  void _addPendingGift(_PendingGift pg) {
    _pendingGifts.add(pg);
    if (_pendingGifts.length > _maxPendingGifts) {
      _pendingGifts.removeAt(0);
    }
  }

  // ── Broadcast debounce ─────────────────────────────────────────
  Timer? _broadcastDebounce;
  bool _snapshotInFlight = false;
  int _pendingBroadcasts = 0;
  bool _disposed = false;

  // ── Shared-state diff cache (Main-authoritative model) ─────────
  // Cached values from the last broadcast/apply. Used by the Sidekick
  // to detect local shared-state changes and send them as deltas.
  double _cachedCoolness = 0;
  double _cachedCurse = 0;
  List<String> _cachedShrines = const [];

  // ── Request timeout timers ─────────────────────────────────────
  final Map<String, Timer> _requestTimeoutTimers = {};

  // ── Dice/emote callbacks (set by MpSession) ────────────────────
  void Function(String challengerName)? onDiceChallenge;
  void Function()? onDiceAccept;
  void Function()? onDiceDecline;
  void Function()? onDiceCancel;
  void Function(int peerScore, List<int> peerDice)? onDiceResult;
  void Function(String from, String action)? onEmote;

  /// Called when a gift is received from the peer — UI uses this
  /// to show a snackbar + haptic so the user knows they got a gift.
  void Function(String kind, String name)? onGiftReceived;

  /// Called when the peer sends [MpEndRun] — signals the session
  /// should tear down without sending another MpEndRun (avoids loop).
  void Function()? onPeerEndRun;

  // ── Paradox v3 callbacks (set by MpSession) ────────────────────
  void Function(MpHello hello)? onPeerHello;
  void Function(MpSessionMeta meta)? onSessionMeta;
  void Function(bool paused)? onPauseChanged;
  void Function()? onStartRun;
  void Function(MpChat chat)? onChat;
  void Function(MpSurprise surprise)? onSurprise;

  // ── Role (set by MpSession on start) ───────────────────────────
  MpRole? _myRole;
  String _myNickname = 'Player';
  String _myCharacterName = '';
  MpMode _mode = MpMode.classic;
  String _avatarId = '';
  String _runTitle = '';
  int _sessionNumber = 0;

  void setIdentity({
    required MpRole role,
    required String nickname,
    required String character,
  }) {
    _myRole = role;
    _myNickname = nickname;
    _myCharacterName = character;
  }

  /// Paradox session identity — carried in the hello handshake.
  void setSessionMeta({
    MpMode? mode,
    String? avatarId,
    String? runTitle,
    int? sessionNumber,
  }) {
    if (mode != null) _mode = mode;
    if (avatarId != null) _avatarId = avatarId;
    if (runTitle != null) _runTitle = runTitle;
    if (sessionNumber != null) _sessionNumber = sessionNumber;
  }

  // ── Lifecycle ──────────────────────────────────────────────────

  /// Called by MpSession when the transport connection establishes.
  /// Sends hello with retry, then the first full snapshot.
  void onConnected() {
    // If the transport fires onConnected without a prior onDisconnected
    // (a Nearby Connections edge case), reset all connection-scoped
    // state first. This prevents stale _helloReceived, peer metadata,
    // or pending operations from the previous connection bleeding into
    // the new one.
    if (_transportConnected) {
      onDisconnected();
    }
    _transportConnected = true;
    // Don't reset _helloReceived here — the peer's onConnected may
    // have fired first and already sent us a hello, which we processed.
    // Resetting would wipe that valid state. _helloReceived is reset
    // in onDisconnected() instead, which always fires before a new
    // onConnected() on reconnect.
    _helloAttempts = 0;
    _syncSharedStateCache();
    _sendHelloWithRetry();
  }

  /// Called by MpSession when the transport connection drops.
  void onDisconnected() {
    _transportConnected = false;
    _helloReceived = false;
    _helloAttempts = 0;
    _helloRetryTimer?.cancel();
    _broadcastDebounce?.cancel();
    _snapshotInFlight = false;
    _pendingBroadcasts = 0;
    _peerRole = null;
    _peerNickname = null;
    _peerCharacterName = null;
    _pendingRequest = null;
    _outgoingRequests.clear();
    for (final timer in _requestTimeoutTimers.values) {
      timer.cancel();
    }
    _requestTimeoutTimers.clear();
    // Clear shared-state cache so stale values don't cause incorrect
    // delta calculations after reconnect.
    _cachedCoolness = 0;
    _cachedCurse = 0;
    _cachedShrines = const [];
  }

  /// Called by MpSession on cancel — restore pending gifts to inventory.
  void restorePendingGifts() {
    if (_pendingGifts.isEmpty) return;
    final mySlot = _myRole == MpRole.main ? PlayerSlot.main : PlayerSlot.coop;
    for (final pg in _pendingGifts) {
      if (!pg.localRemoval) continue;
      switch (pg.kind) {
        case 'gun':
          final gun = _runProvider.gunByName(pg.name);
          if (gun != null) _runProvider.addGun(gun, slot: mySlot, force: true);
          break;
        case 'item':
          final it = _runProvider.itemByName(pg.name);
          if (it != null) _runProvider.addItem(it, slot: mySlot, force: true);
          break;
      }
    }
    _pendingGifts.clear();
  }

  /// Called by MpSession on reconnect — re-send pending gifts.
  void resendPendingGifts() {
    if (_pendingGifts.isEmpty) return;
    for (final pg in _pendingGifts.toList()) {
      unawaited(
        _link
            .sendMessage(
              MpGift(kind: pg.kind, name: pg.name, giftId: pg.giftId),
            )
            .catchError((Object _) {}),
      );
    }
  }

  // ── Message handling ───────────────────────────────────────────

  /// Called by MpSession when a message arrives from the transport.
  void onMessage(MpMessage msg) {
    // Gate: drop state-modifying messages until the handshake completes.
    // This prevents stale messages from a previous connection or races
    // with the handshake from corrupting run state. Snapshots, dice,
    // emotes, and pings are safe to process before the handshake (they
    // either update the peer slot idempotently or are informational).
    if (!_helloReceived) {
      switch (msg) {
        case MpHello():
          break; // always process
        case MpSnapshot():
          break; // idempotent — safe
        case MpPing():
          break; // liveness
        case MpPong():
          break; // liveness
        case MpDiceChallenge():
        case MpDiceAccept():
        case MpDiceDecline():
        case MpDiceCancel():
        case MpDiceResult():
          break; // informational UI events
        case MpEmote():
          break; // informational UI events
        case MpStartRun():
        case MpPause():
        case MpResume():
        case MpChat():
        case MpSurprise():
          break; // informational UI events
        case MpGift():
        case MpRequest():
        case MpRequestResp():
        case MpSharedStateDelta():
        case MpPeerEdit():
        case MpSessionMeta():
        case MpEndRun():
          return; // state-modifying — drop until handshake
      }
    }

    switch (msg) {
      case MpHello():
        _onHello(msg);
      case MpSnapshot():
        _onSnapshot(msg);
      case MpGift():
        _onGift(msg);
      case MpRequest():
        if (_seenReqIds.contains(msg.reqId)) break;
        _seenReqIds.add(msg.reqId);
        while (_seenReqIds.length > _maxSeenReqIds) {
          _seenReqIds.remove(_seenReqIds.first);
        }
        // Queue: don't overwrite a pending request — the UI needs
        // to respond to the current one before seeing the next.
        if (_pendingRequest == null) {
          _pendingRequest = msg;
        } else {
          // Auto-decline the new request if one is already pending.
          // The peer will see a denial and can retry.
          unawaited(
            _link
                .sendMessage(MpRequestResp(reqId: msg.reqId, approved: false))
                .catchError((Object _) {}),
          );
        }
      case MpRequestResp():
        final out = _outgoingRequests.remove(msg.reqId);
        if (out != null) {
          _lastResp = (name: out.name, approved: msg.approved);
        }
        _cancelRequestTimeout(msg.reqId);
      case MpEndRun():
        _applyingRemote = true;
        try {
          _runProvider.endRun();
        } finally {
          _applyingRemote = false;
        }
        // Tell MpSession to tear down the MP transport without
        // sending another MpEndRun (avoids infinite loop).
        onPeerEndRun?.call();
      case MpPing():
        // Echo the ping timestamp so the sender can compute RTT
        // for the connection-health metric.
        unawaited(_link.sendMessage(MpPong(msg.tsMs)));
      case MpPong():
        break; // liveness only — handled by MpLink heartbeat
      case MpDiceChallenge():
        onDiceChallenge?.call(msg.challengerName);
      case MpDiceAccept():
        onDiceAccept?.call();
      case MpDiceDecline():
        onDiceDecline?.call();
      case MpDiceCancel():
        onDiceCancel?.call();
      case MpDiceResult():
        onDiceResult?.call(msg.score, msg.dice);
      case MpEmote():
        onEmote?.call(msg.from, msg.action);
      case MpSharedStateDelta():
        _onSharedStateDelta(msg);
      case MpStartRun():
        onStartRun?.call();
      case MpPause():
        onPauseChanged?.call(true);
      case MpResume():
        onPauseChanged?.call(false);
      case MpChat():
        if (msg.id.isNotEmpty && !_seenChatIds.contains(msg.id)) {
          _seenChatIds.add(msg.id);
          while (_seenChatIds.length > _maxSeenChatIds) {
            _seenChatIds.remove(_seenChatIds.first);
          }
          onChat?.call(msg);
        }
      case MpSurprise():
        onSurprise?.call(msg);
      case MpPeerEdit():
        _onPeerEdit(msg);
      case MpSessionMeta():
        if (_peerRole == MpRole.main) onSessionMeta?.call(msg);
    }
  }

  final Set<String> _seenChatIds = {};
  static const int _maxSeenChatIds = 100;

  /// Apply a direct peer inventory edit (co-op trust model).
  /// The receiver mutates its OWN slot — the sender already saw the
  /// change on their screen. After applying we rebroadcast a snapshot
  /// so both sides converge on identical state.
  void _onPeerEdit(MpPeerEdit e) {
    final mySlot = _myRole == MpRole.main ? PlayerSlot.main : PlayerSlot.coop;
    _applyingRemote = true;
    try {
      switch (e.op) {
        case 'add':
          if (e.kind == 'gun') {
            final g = _runProvider.gunByName(e.name);
            if (g != null) _runProvider.addGun(g, slot: mySlot, force: true);
          } else if (e.kind == 'item') {
            final it = _runProvider.itemByName(e.name);
            if (it != null) _runProvider.addItem(it, slot: mySlot, force: true);
          }
        case 'remove':
          if (e.kind == 'gun') {
            final g = _runProvider.gunByName(e.name);
            if (g != null) _runProvider.removeGun(g, slot: mySlot, force: true);
          } else if (e.kind == 'item') {
            final it = _runProvider.itemByName(e.name);
            if (it != null) {
              _runProvider.removeItem(it, slot: mySlot, force: true);
            }
          }
        case 'clear':
          _runProvider.clearInventory(slot: mySlot);
      }
    } finally {
      _applyingRemote = false;
    }
    // Rebroadcast so the sender sees our updated inventory too.
    _broadcastDebounce?.cancel();
    _broadcastDebounce = Timer(const Duration(milliseconds: 150), () {
      if (_disposed) return;
      unawaited(_broadcastSnapshot(force: true));
    });
  }

  void _onHello(MpHello h) {
    // Guard: don't re-process hello if already received from this peer.
    if (_helloReceived) return;

    // Protocol version check.
    if (h.protocolVersion != MpHello.currentProtocolVersion) {
      _fail(
        'Protocol version mismatch. Update both apps to the latest version.',
      );
      unawaited(_link.disconnectPeer());
      return;
    }
    // Role pairing check.
    if (h.role == _myRole) {
      _fail(
        'Both players picked ${_myRole == MpRole.main ? 'Host' : 'Join'}. '
        'One needs to pick the other role.',
      );
      unawaited(_link.disconnectPeer());
      return;
    }

    _helloReceived = true;
    _helloRetryTimer?.cancel();
    _peerRole = h.role;
    _peerNickname = _cleanNickname(h.userLabel);
    _peerCharacterName = h.character;
    onPeerMetadata(_peerNickname!, _peerCharacterName ?? '');
    onPeerHello?.call(h);

    // Notify session that hello succeeded — triggers phase transition
    // to connected and reconnect success notifier.
    onPeerConnected(h.role);

    // Send initial full snapshot. The peer may not have received our
    // hello yet, but snapshots are idempotent — applying a peer's
    // snapshot just updates the peer slot and is safe even before
    // the handshake completes on our side.
    unawaited(_broadcastSnapshot(force: true));
  }

  String _cleanNickname(String name) {
    String cleaned = name.contains('#') ? name.split('#').first : name;
    return cleaned.isEmpty ? 'Player' : cleaned;
  }

  void _fail(String message) {
    // Forward to MpSession via callback.
    onSyncError?.call(message);
  }

  void Function(String error)? onSyncError;

  void _onSnapshot(MpSnapshot s) {
    // Guard: if the peer sends an empty character name, the snapshot
    // is from a restarting peer whose run state hasn't been restored
    // yet. Skip the entire snapshot — don't wipe the receiver's slots
    // or shared state with empty/default values. The peer will send
    // a valid snapshot once their run state is restored.
    if (s.character.isEmpty) return;

    bool applySucceeded = false;
    _applyingRemote = true;
    try {
      final isMain = _myRole == MpRole.main;
      _runProvider.applyPeerSnapshot(
        characterName: s.character,
        gunNames: s.gunNames,
        itemNames: s.itemNames,
        targetMainSlot: !isMain,
      );
      // Main-authoritative: only apply shared state from Main's snapshot.
      // Sidekick's snapshot shared-state fields are ignored.
      if (_peerRole == MpRole.main) {
        _runProvider.applySharedStateFromPeer(
          coolness: s.coolness,
          curse: s.curse,
          shrinesUsed: s.shrinesUsed,
        );
      }
      applySucceeded = true;
      // Confirm pending gifts only if the snapshot applied successfully.
      final peerGunSet = s.gunNames.toSet();
      final peerItemSet = s.itemNames.toSet();
      _pendingGifts.removeWhere((pg) {
        return pg.kind == 'gun'
            ? peerGunSet.contains(pg.name)
            : peerItemSet.contains(pg.name);
      });
    } catch (_) {
      // Snapshot apply error — non-fatal. Don't confirm pending
      // gifts on a failed apply — they may not have been received.
    } finally {
      _applyingRemote = false;
    }
    if (applySucceeded) _syncSharedStateCache();
  }

  void _onGift(MpGift g) {
    // Reject gifts with empty giftId — they bypass dedup and can
    // be processed repeatedly.
    if (g.giftId.isEmpty) return;
    if (_seenGiftIds.contains(g.giftId)) return;
    _seenGiftIds.add(g.giftId);
    while (_seenGiftIds.length > _maxSeenGiftIds) {
      _seenGiftIds.remove(_seenGiftIds.first);
    }
    _applyingRemote = true;
    bool added = false;
    try {
      final mySlot = _myRole == MpRole.main ? PlayerSlot.main : PlayerSlot.coop;
      switch (g.kind) {
        case 'gun':
          final gun = _runProvider.gunByName(g.name);
          if (gun != null) {
            _runProvider.addGun(gun, slot: mySlot);
            added = true;
          }
          break;
        case 'item':
          final it = _runProvider.itemByName(g.name);
          if (it != null) {
            _runProvider.addItem(it, slot: mySlot);
            added = true;
          }
          break;
      }
    } finally {
      _applyingRemote = false;
    }
    // Only notify UI and broadcast if the item was actually added.
    if (added) {
      onGiftReceived?.call(g.kind, g.name);
      // Broadcast snapshot after receiving a gift.
      _broadcastDebounce?.cancel();
      _broadcastDebounce = Timer(const Duration(milliseconds: 200), () {
        if (_disposed) return;
        unawaited(_broadcastSnapshot(force: true));
      });
    }
  }

  // ── Shared-state delta (Main-authoritative) ────────────────────

  /// Sync the cached shared-state values from the current RunProvider.
  /// Called after applying remote state and after sending deltas.
  void _syncSharedStateCache() {
    _cachedCoolness = _runProvider.runState.coolness;
    _cachedCurse = _runProvider.runState.curse;
    _cachedShrines = List.of(_runProvider.runState.shrinesUsed);
  }

  /// Sidekick-only: diff current shared state against cached values
  /// and send [MpSharedStateDelta] messages for any changes. This is
  /// how the Sidekick communicates shared-state modifications (smoking
  /// cigs, using shrines, stealing, etc.) to the Main Player.
  void _maybeSendSharedStateDelta() {
    final cur = _runProvider.runState;
    final dCool = cur.coolness - _cachedCoolness;
    final dCurse = cur.curse - _cachedCurse;
    final newShrines =
        cur.shrinesUsed.where((s) => !_cachedShrines.contains(s)).toList();

    if (dCool == 0 && dCurse == 0 && newShrines.isEmpty) return;

    // Send coolness/curse delta as one message. Only update the
    // cache after a successful send — if the message is dropped,
    // the next onRunChanged will re-detect the diff and retry.
    if (dCool != 0 || dCurse != 0) {
      _link
          .sendMessage(
            MpSharedStateDelta(coolnessDelta: dCool, curseDelta: dCurse),
          )
          .then((_) {
            _cachedCoolness = cur.coolness;
            _cachedCurse = cur.curse;
          })
          .catchError((Object _) {});
    }
    // Send each new shrine as a separate delta.
    for (final shrine in newShrines) {
      _link
          .sendMessage(MpSharedStateDelta(shrineName: shrine))
          .then((_) {
            if (!_cachedShrines.contains(shrine)) {
              _cachedShrines = [..._cachedShrines, shrine];
            }
          })
          .catchError((Object _) {});
    }
  }

  /// Main-only: apply a shared-state delta from the Sidekick. After
  /// applying, Main re-broadcasts a snapshot so both sides converge
  /// on the authoritative values.
  void _onSharedStateDelta(MpSharedStateDelta d) {
    if (_myRole != MpRole.main) return;
    _applyingRemote = true;
    try {
      _runProvider.applySharedStateDelta(
        coolnessDelta: d.coolnessDelta,
        curseDelta: d.curseDelta,
        shrineName: d.shrineName,
      );
    } finally {
      _applyingRemote = false;
    }
    _syncSharedStateCache();
    // Main re-broadcasts so Sidekick gets the authoritative values.
    _broadcastDebounce?.cancel();
    _broadcastDebounce = Timer(const Duration(milliseconds: 100), () {
      if (_disposed) return;
      unawaited(_broadcastSnapshot(force: true));
    });
  }

  // ── Broadcast ──────────────────────────────────────────────────

  /// Called when RunProvider changes (listener set by MpSession).
  void onRunChanged() {
    if (_disposed || _applyingRemote || !_helloReceived) return;
    // Sidekick: detect shared-state changes and send deltas to Main.
    // Main is authoritative for shared state, so Sidekick sends deltas
    // instead of full shared-state snapshots.
    if (_myRole == MpRole.sidekick) {
      _maybeSendSharedStateDelta();
    }
    _broadcastDebounce?.cancel();
    _broadcastDebounce = Timer(const Duration(milliseconds: 200), () {
      if (_disposed) return;
      unawaited(_broadcastSnapshot());
    });
  }

  /// Serialised snapshot broadcast. All snapshots — forced or not —
  /// go through the same queue so they can never overlap. The `force`
  /// flag bypasses the throttle (for immediate sends after hello/gift)
  /// but still waits for any in-flight snapshot to complete first.
  Future<void> _broadcastSnapshot({bool force = false}) async {
    if (!_link.isConnected) return;
    // If a snapshot is already in flight, queue this one. The
    // pending count acts as a "needs resend" flag — any number of
    // collapsed changes will result in exactly one follow-up send.
    if (_snapshotInFlight) {
      _pendingBroadcasts++;
      return;
    }
    _snapshotInFlight = true;
    await _sendOneSnapshot();
    _snapshotInFlight = false;
    // Drain any queued broadcasts. Each iteration sends the latest
    // state, so multiple queued changes collapse into one send.
    while (_pendingBroadcasts > 0 && !_disposed && _link.isConnected) {
      _pendingBroadcasts--;
      _snapshotInFlight = true;
      await _sendOneSnapshot();
      _snapshotInFlight = false;
    }
  }

  Future<void> _sendOneSnapshot() async {
    final isMain = _myRole == MpRole.main;
    final player =
        isMain ? _runProvider.runState.main : _runProvider.runState.coop;
    final snap = MpSnapshot(
      character: player?.character?.name ?? _myCharacterName,
      gunNames: player?.guns.map((g) => g.name).toList() ?? [],
      itemNames: player?.items.map((i) => i.name).toList() ?? [],
      coolness: _runProvider.runState.coolness,
      curse: _runProvider.runState.curse,
      shrinesUsed: _runProvider.runState.shrinesUsed,
    );
    try {
      await _link.sendMessage(snap);
    } catch (_) {
      // Snapshot failed — the queue loop will retry if there are
      // pending broadcasts, otherwise the next onRunChanged will.
    }
  }

  // ── Hello with retry ───────────────────────────────────────────

  Future<void> _sendHello() async {
    final role = _myRole;
    if (role == null) return;
    try {
      await _link.sendMessage(
        MpHello(
          role: role,
          character: _myCharacterName,
          userLabel: _myNickname,
          appVersion: MpSync.appVersionString,
          mode: _mode,
          avatarId: _avatarId,
          runTitle: _runTitle,
          sessionNumber: _sessionNumber,
        ),
      );
    } catch (_) {}
  }

  void _sendHelloWithRetry() {
    // Don't skip even if _helloReceived is true — we may have
    // received the peer's hello (which set _helloReceived) but
    // the peer may not have received OUR hello yet. Always send
    // our hello so the peer can complete their handshake.
    if (_helloAttempts >= _maxHelloAttempts) {
      _fail('Handshake failed. Could not establish connection with peer.');
      unawaited(_link.disconnectPeer());
      return;
    }
    _helloAttempts++;
    unawaited(_sendHello());
    _helloRetryTimer?.cancel();
    _helloRetryTimer = Timer(Duration(milliseconds: _helloTimeoutMs), () {
      if (_disposed) return;
      if (!_helloReceived) {
        _sendHelloWithRetry();
      }
    });
  }

  // ── Outgoing operations ────────────────────────────────────────

  Future<void> sendGift({required String kind, required String name}) async {
    if (!_link.isConnected) return;
    final mySlot = _myRole == MpRole.main ? PlayerSlot.main : PlayerSlot.coop;
    Gun? removedGun;
    Item? removedItem;
    switch (kind) {
      case 'gun':
        removedGun = _runProvider.gunByName(name);
        if (removedGun != null) {
          _runProvider.removeGun(removedGun, slot: mySlot);
        }
        break;
      case 'item':
        removedItem = _runProvider.itemByName(name);
        if (removedItem != null) {
          _runProvider.removeItem(removedItem, slot: mySlot);
        }
        break;
    }
    if (removedGun == null && removedItem == null) return;
    final giftId = _newReqId();
    _addPendingGift(_PendingGift(giftId: giftId, kind: kind, name: name));
    try {
      await _link.sendMessage(MpGift(kind: kind, name: name, giftId: giftId));
    } catch (_) {
      _pendingGifts.removeWhere((g) => g.giftId == giftId);
      if (removedGun != null) {
        _runProvider.addGun(removedGun, slot: mySlot, force: true);
      } else if (removedItem != null) {
        _runProvider.addItem(removedItem, slot: mySlot, force: true);
      }
    }
  }

  Future<void> sendAddToPeer({
    required String kind,
    required String name,
  }) async {
    if (!_link.isConnected) return;
    final giftId = _newReqId();
    _addPendingGift(
      _PendingGift(giftId: giftId, kind: kind, name: name, localRemoval: false),
    );
    try {
      await _link.sendMessage(MpGift(kind: kind, name: name, giftId: giftId));
    } catch (_) {
      _pendingGifts.removeWhere((g) => g.giftId == giftId);
    }
  }

  Future<String?> sendRequest({
    required String kind,
    required String name,
  }) async {
    if (!_link.isConnected) return null;
    final reqId = _newReqId();
    _outgoingRequests[reqId] = _OutgoingRequest(kind, name);
    try {
      await _link.sendMessage(MpRequest(reqId: reqId, kind: kind, name: name));
    } catch (_) {
      _outgoingRequests.remove(reqId);
      return null;
    }
    final timer = Timer(const Duration(seconds: 30), () {
      final out = _outgoingRequests.remove(reqId);
      _requestTimeoutTimers.remove(reqId);
      if (out != null) {
        _lastResp = (name: out.name, approved: false);
      }
    });
    _requestTimeoutTimers[reqId] = timer;
    return reqId;
  }

  Future<void> respondToPendingRequest(bool approved) async {
    final req = _pendingRequest;
    if (req == null) return;
    _pendingRequest = null;
    if (!_link.isConnected) return;

    bool actuallyApproved = approved;
    if (approved) {
      final mySlot = _myRole == MpRole.main ? PlayerSlot.main : PlayerSlot.coop;
      Gun? removedGun;
      Item? removedItem;
      switch (req.kind) {
        case 'gun':
          removedGun = _runProvider.gunByName(req.name);
          if (removedGun != null) {
            _runProvider.removeGun(removedGun, slot: mySlot);
          }
          break;
        case 'item':
          removedItem = _runProvider.itemByName(req.name);
          if (removedItem != null) {
            _runProvider.removeItem(removedItem, slot: mySlot);
          }
          break;
      }
      if (removedGun == null && removedItem == null) {
        // Can't send what we don't have — deny instead of lying.
        actuallyApproved = false;
      } else {
        final giftId = _newReqId();
        _addPendingGift(
          _PendingGift(giftId: giftId, kind: req.kind, name: req.name),
        );
        try {
          await _link.sendMessage(
            MpGift(kind: req.kind, name: req.name, giftId: giftId),
          );
        } catch (_) {
          _pendingGifts.removeWhere((g) => g.giftId == giftId);
          if (removedGun != null) {
            _runProvider.addGun(removedGun, slot: mySlot, force: true);
          } else if (removedItem != null) {
            _runProvider.addItem(removedItem, slot: mySlot, force: true);
          }
          actuallyApproved = false;
        }
      }
    }
    // Always send a response so the requester doesn't time out.
    try {
      await _link.sendMessage(
        MpRequestResp(reqId: req.reqId, approved: actuallyApproved),
      );
    } catch (_) {}
  }

  // ── Dice / emote ───────────────────────────────────────────────

  Future<void> sendDiceChallenge(String challengerName) async {
    if (_link.isConnected) {
      await _link.sendMessage(MpDiceChallenge(challengerName: challengerName));
    }
  }

  Future<void> sendDiceAccept() async {
    if (_link.isConnected) await _link.sendMessage(const MpDiceAccept());
  }

  Future<void> sendDiceDecline() async {
    if (_link.isConnected) await _link.sendMessage(const MpDiceDecline());
  }

  Future<void> sendDiceCancel() async {
    if (_link.isConnected) await _link.sendMessage(const MpDiceCancel());
  }

  Future<void> sendDiceResult(int score, List<int> dice) async {
    if (_link.isConnected) {
      await _link.sendMessage(MpDiceResult(score: score, dice: dice));
    }
  }

  Future<void> sendEmote(String action) async {
    if (_link.isConnected) {
      await _link.sendMessage(MpEmote(from: _myNickname, action: action));
    }
  }

  // ── Paradox v3 senders ─────────────────────────────────────────

  Future<void> sendStartRun() async {
    if (_link.isConnected) await _link.sendMessage(const MpStartRun());
  }

  Future<void> sendPause() async {
    if (_link.isConnected) await _link.sendMessage(const MpPause());
  }

  Future<void> sendResume() async {
    if (_link.isConnected) await _link.sendMessage(const MpResume());
  }

  /// Main-authoritative session meta — rebroadcast after hello and on
  /// every change so reconnecting peers land on the right state.
  Future<void> sendSessionMeta({
    String? runTitle,
    int? sessionNumber,
    bool? paused,
  }) async {
    if (!_link.isConnected || _myRole != MpRole.main) return;
    await _link.sendMessage(
      MpSessionMeta(
        runTitle: runTitle ?? _runTitle,
        sessionNumber: sessionNumber ?? _sessionNumber,
        paused: paused ?? false,
      ),
    );
  }

  Future<void> sendChat(MpChat chat) async {
    if (_link.isConnected) await _link.sendMessage(chat);
  }

  Future<void> sendSurprise(MpSurprise surprise) async {
    if (_link.isConnected) await _link.sendMessage(surprise);
  }

  Future<void> sendPeerEdit(MpPeerEdit edit) async {
    if (_link.isConnected) await _link.sendMessage(edit);
  }

  // ── Helpers ────────────────────────────────────────────────────

  void _cancelRequestTimeout(String reqId) {
    final timer = _requestTimeoutTimers.remove(reqId);
    timer?.cancel();
  }

  static final _rng = math.Random();
  String _newReqId() {
    return _rng.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
  }

  /// App version sent in hello for diagnostic purposes.
  static String appVersionString = 'unknown';

  void dispose() {
    _disposed = true;
    _helloRetryTimer?.cancel();
    _broadcastDebounce?.cancel();
    for (final timer in _requestTimeoutTimers.values) {
      timer.cancel();
    }
    _requestTimeoutTimers.clear();
  }
}
