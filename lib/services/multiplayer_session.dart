import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/gun.dart';
import '../models/gungeoneer.dart';
import '../models/item.dart';
import '../models/multiplayer_messages.dart';
import '../models/player.dart';
import '../models/run_state.dart';
import '../providers/run_provider.dart';
import 'multiplayer_service.dart';

// SharedPreferences keys for MP session persistence. Stored only when
// a session was actually established so app-kill mid-session can resume.
// All keys cleared on explicit End Run / Disconnect.
const String _kMpPersistRole = 'mp_last_role';
const String _kMpPersistChar = 'mp_last_character';
const String _kMpPersistNick = 'mp_last_nickname';
const String _kMpPersistActive = 'mp_session_active';

/// High-level state of the session from the UI's point of view. The
/// multiplayer screen routes to a different view per value, so keep
/// this lean — no transient sub-states.
enum MpStatus {
  /// Not in a session. Picker view.
  idle,

  /// Asked for permissions, user denied. Picker view with a banner.
  permissionDenied,

  /// Advertising (Main) or discovering (Sidekick). Searching view.
  searching,

  /// Low-level Nearby connection established, but we haven't exchanged
  /// hello messages yet. Stays in this state for <1s usually.
  handshaking,

  /// Hello exchanged, snapshots flowing. Live co-op view.
  connected,

  /// We were connected but the peer dropped (or we disconnected). The
  /// last snapshot is still visible; UI offers a Reconnect button.
  disconnected,

  /// A terminal error; requires user action (cancel / retry).
  error,
}

/// A single outgoing request waiting for a `requestResp`.
class _OutgoingRequest {
  final String kind;
  final String name;
  final DateTime sentAt;
  _OutgoingRequest(this.kind, this.name) : sentAt = DateTime.now();
}

/// Owns everything multiplayer: role, transport events, protocol
/// messages, lifecycle, and the listener wiring that keeps the local
/// RunProvider in sync with the remote peer.
///
/// One instance lives for the whole app lifetime, created in `main.dart`
/// and exposed via Provider. `idle` until the user enters the
/// multiplayer screen and picks a role.
class MultiplayerSession extends ChangeNotifier {
  final MultiplayerService _service;
  RunProvider _runProvider;

  MpStatus _status = MpStatus.idle;
  String? _error;

  MpRole? _myRole;
  String _myNickname = 'Player';
  String _myCharacterName = '';

  /// Remember the last successfully-started role + character so we can
  /// offer one-tap Reconnect after a drop without re-running the lobby.
  MpRole? _lastRole;
  Gungeoneer? _lastCharacter;
  String _lastNickname = 'Player';

  /// True while we're applying a peer snapshot to RunProvider. Guards
  /// against the infinite feedback loop that would otherwise occur:
  /// apply peer → RunProvider notifies → our listener broadcasts → peer
  /// applies → peer notifies → ... Every write through this window is
  /// our own echo of the peer's state and must NOT be re-broadcast.
  bool _applyingRemote = false;
  bool _helloReceived = false;
  int _helloAttempts = 0;
  static const int _maxHelloAttempts = 3;
  static const int _helloTimeoutMs = 5000;
  bool _isSimulated = false;

  bool get isSimulated => _isSimulated;

  // -- Peer metadata (null when not connected) ----------------------------
  MpRole? _peerRole;
  String? _peerNickname;
  String? _peerCharacterName;
  int _peerLastSnapshotTs = 0;

  /// Incoming request the user hasn't answered yet. The UI shows an
  /// accept/deny sheet while this is non-null.
  MpRequest? _pendingRequest;

  // Dice Roll Callbacks (for Gunfortuna Dice Roll events)
  void Function(String challengerName)? onDiceChallenge;
  void Function()? onDiceAccept;
  void Function(int peerScore, List<int> peerDice)? onDiceResult;

  /// Requests we've sent that are still waiting for a response. Keyed
  /// by reqId. Cleared on resp or after a 30s timeout.
  final Map<String, _OutgoingRequest> _outgoingRequests = {};

  /// Latest request-resp result (for one-shot toasts). Read once by
  /// the UI and then cleared via [consumeLastResp].
  ({String name, bool approved})? _lastResp;

  /// Set when a protocol error (version/role mismatch) occurs.
  /// Prevents disconnect events from overwriting the error state.
  bool _protocolError = false;

  /// Timestamp of when the current multiplayer session was established.
  int? _sessionStartedAtMs;

  /// 4-digit security connection PIN.
  String? _pinCode;
  String? get pinCode => _pinCode;

  /// Monotonic logical sequence number for outbound snapshots (replaces absolute system clocks to prevent drift).
  int _mySnapshotSeq = 0;

  /// Track seen request IDs to prevent duplicate request popups.
  /// (Gift deduplication is intentionally NOT done by name — keying
  /// by name caused legitimate re-gifts of the same item to be silently
  /// dropped. Nearby Connections is reliable transport, so duplicates
  /// at the wire level shouldn't occur in practice.)
  final Set<String> _seenReqIds = {};
  static const int _maxSeenReqIds = 20;

  /// Timeout timers for outgoing requests, keyed by reqId.
  final Map<String, Timer> _requestTimeoutTimers = {};

  /// Sidekick mode replaces the local run with the peer's (Main
  /// Player's) data: main slot, coolness, curse and shrine list all
  /// get overwritten. Without snapshotting the pre-MP run, simply
  /// visiting the lobby would silently destroy a solo run. We capture
  /// it here on Sidekick start and restore it on cancel.
  ///
  /// Stored as a small struct of the fields the Sidekick path actually
  /// stomps on, so we don't have to take a deep copy of every Player.
  ({
    Player main,
    double coolness,
    double curse,
    List<String> shrinesUsed,
  })? _preSidekickRun;

  /// Guard against double-tap reconnect / cancel races kicking off two
  /// transport handshakes in parallel.
  bool _busyTransition = false;

  final List<String> _connectionLogs = ['[SYSTEM] Multiplayer Diagnostic Log Initialized.'];
  List<String> get connectionLogs => _connectionLogs;
  int get lastPeerTouchMs => _lastPeerTouchMs;

  void _log(String message) {
    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    final logLine = "[$timeStr] $message";
    _connectionLogs.add(logLine);
    if (_connectionLogs.length > 200) _connectionLogs.removeAt(0);
    notifyListeners();
  }

  StreamSubscription<MpServiceEvent>? _eventSub;

  Timer? _broadcastDebounce;
  Timer? _heartbeat;
  Timer? _watchdog;
  Timer? _searchTimeout;
  Timer? _helloRetryTimer;
  Timer? _autoReconnectTimer;
  int _lastPeerTouchMs = 0;
  int _autoReconnectAttempts = 0;
  /// Reconnect-forever: never give up while the run is alive. The user
  /// explicitly tearing down (End Run / Disconnect / cancel) is the only
  /// way out. Backoff still grows with attempts but is capped at 30s.
  static const int _maxAutoReconnectBackoffSec = 30;
  static const int _searchTimeoutMs = 60000; // 60 seconds

  MultiplayerSession(this._service, this._runProvider) {
    _eventSub = _service.events.listen(_onServiceEvent);
    _runProvider.addListener(_onRunChanged);
  }

  /// Update the RunProvider reference (used by ProxyProvider when the
  /// dependency changes). Unregisters from old, registers to new.
  void updateRunProvider(RunProvider newProvider) {
    if (newProvider == _runProvider) return;
    _runProvider.removeListener(_onRunChanged);
    _runProvider = newProvider;
    _runProvider.addListener(_onRunChanged);
  }

  // ---- Session persistence (survives app-kill mid-session) -----------
  // Stored to SharedPreferences only after a session is established so
  // the Sidekick/Main can resume on app restart without re-running the
  // lobby. Cleared exclusively on user-initiated End Run / Disconnect.

  Future<void> _persistSession() async {
    final role = _myRole;
    if (role == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kMpPersistRole, role.name);
      await prefs.setString(_kMpPersistChar, _myCharacterName);
      await prefs.setString(_kMpPersistNick, _myNickname);
      await prefs.setBool(_kMpPersistActive, true);
    } catch (_) {
      // Persistence is best-effort; never let a SharedPrefs failure
      // crash the session lifecycle.
    }
  }

  Future<void> _clearPersistedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kMpPersistRole);
      await prefs.remove(_kMpPersistChar);
      await prefs.remove(_kMpPersistNick);
      await prefs.remove(_kMpPersistActive);
    } catch (_) {
      // ignore
    }
  }

  /// Call once at app startup AFTER RunProvider has finished loadData().
  /// If a previous MP session was alive when the app died, transparently
  /// re-enter the lobby in the same role with the same character so the
  /// peer's auto-reconnect can find us. If nothing was persisted this is
  /// a no-op.
  Future<void> tryRestorePersistedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final active = prefs.getBool(_kMpPersistActive) ?? false;
      if (!active) return;
      final roleName = prefs.getString(_kMpPersistRole);
      final charName = prefs.getString(_kMpPersistChar) ?? '';
      final nick = prefs.getString(_kMpPersistNick) ?? 'Player';
      if (roleName == null) return;
      final role = MpRole.values.firstWhere(
        (r) => r.name == roleName,
        orElse: () => MpRole.main,
      );
      if (role == MpRole.main) {
        final char = _runProvider.gungeoneerByName(charName);
        if (char != null) {
          await startAsMain(nickname: nick, character: char);
        }
      } else {
        await startAsSidekick(nickname: nick);
      }
    } catch (_) {
      // ignore
    }
  }

  // ---- Public getters (read by UI) --------------------------------------

  MpStatus get status => _status;
  String? get error => _error;
  MpRole? get myRole => _myRole;
  String get myNickname => _myNickname;
  String get myCharacterName => _myCharacterName;
  int? get sessionStartedAtMs => _sessionStartedAtMs;

  MpRole? get peerRole => _peerRole;
  String? get peerNickname => _peerNickname;
  String? get peerCharacterName => _peerCharacterName;
  bool get isConnected => _status == MpStatus.connected;

  /// Which local PlayerSlot represents "me" in MP. Main → main slot,
  /// Sidekick → coop slot. Null when not in an MP session.
  PlayerSlot? get mySlot {
    final r = _myRole;
    if (r == null) return null;
    return r == MpRole.main ? PlayerSlot.main : PlayerSlot.coop;
  }

  /// Which local PlayerSlot represents the peer (mirror of [mySlot]).
  PlayerSlot? get peerSlot {
    final s = mySlot;
    if (s == null) return null;
    return s == PlayerSlot.main ? PlayerSlot.coop : PlayerSlot.main;
  }

  /// True if an MP session is currently active (any non-idle state).
  bool get isActive => _status != MpStatus.idle;

  MpRequest? get pendingRequest => _pendingRequest;

  ({String name, bool approved})? get lastResp => _lastResp;

  void consumeLastResp() {
    if (_lastResp != null) {
      _lastResp = null;
      notifyListeners();
    }
  }

  // ---- Lifecycle -------------------------------------------------------

  /// Start a session as Main Player. Advertises under `nickname` with
  /// the picked character. Pulls permissions first.
  Future<void> startAsMain({
    required String nickname,
    required Gungeoneer character,
  }) async {
    if (_status == MpStatus.searching || _status == MpStatus.connected) {
      return;
    }
    _log('Initializing advertising: role=Main, nick=$nickname, character=${character.name}');
    final ok = await _service.requestPermissions();
    if (!ok) {
      _log('Advertising failed: Permission Denied.');
      _status = MpStatus.permissionDenied;
      _error = 'Bluetooth / Nearby permissions are required for multiplayer.';
      notifyListeners();
      return;
    }
    _pinCode ??= _newPinCode();
    _myRole = MpRole.main;
    _myNickname = nickname;
    _myCharacterName = character.name;
    _lastRole = MpRole.main;
    _lastCharacter = character;
    _lastNickname = nickname;
    _status = MpStatus.searching;
    _error = null;
    notifyListeners();
    // Start search timeout
    _startSearchTimeout();
    // Ensure Main Player has an active run with their chosen character.
    // If no run exists, start one. If a run exists, we keep their
    // inventory (they bring it into co-op) but ensure character matches.
    if (_runProvider.runState.selectedCharacter == null) {
      _runProvider.startNewRun(character);
    }
    // Clear the coop slot so peer's first snapshot drops cleanly.
    // Reconnect-safe: if a coop snapshot is already populated (we
    // recovered from a drop and the peer is reconnecting too), keep
    // it — the next inbound snapshot will overwrite it anyway, and
    // wiping causes a visible "Cultist disappears then reappears"
    // flicker.
    if (_runProvider.runState.coop?.character == null) {
      _runProvider.applyPartnerSnapshot(
        characterName: '',
        gunNames: const [],
        itemNames: const [],
      );
    }
    _log('Advertising initiated... Broadcasting as $nickname#$_pinCode');
    final started = await _service.startAdvertising("$nickname#$_pinCode");
    if (!started) {
      _log('Advertising failed: Could not start advertising adapter.');
      _searchTimeout?.cancel();
      await _service.stopSearching();
      _fail('Could not start advertising. Try toggling Bluetooth.');
    } else {
      _log('Advertising adapter started successfully. Awaiting sidekick connection on PIN Code: $_pinCode');
    }
  }

  /// Start a session as Sidekick. Forces the Cultist character (as per
  /// product spec). Pulls permissions, then discovers.
  Future<void> startAsSidekick({required String nickname, String pinCode = ''}) async {
    if (_status == MpStatus.searching || _status == MpStatus.connected) {
      return;
    }
    if (pinCode == '0000') {
      _log('Initializing SIMULATED local multiplayer session with PIN 0000...');
      _isSimulated = true;
      _myRole = MpRole.main; // Make them main so they control Player 1, and simulated partner is Player 2
      _myNickname = nickname;
      _pinCode = '0000';
      _myCharacterName = _runProvider.runState.selectedCharacter?.name ?? 'The Marine';
      _peerRole = MpRole.sidekick;
      _peerNickname = 'Simulated Cultist';
      _peerCharacterName = 'The Cultist';
      _status = MpStatus.connected;

      final cultist = _runProvider.gungeoneerByName('The Cultist') ??
          _runProvider.gungeoneerByName('Cultist');
      if (cultist != null) {
        _runProvider.startCoopPlayer(cultist);
      }
      _log('Simulated multiplayer session started successfully.');
      notifyListeners();
      return;
    }
    _log('Initializing discovery: role=Sidekick, nick=$nickname, filterPIN=${pinCode.isEmpty ? "None" : pinCode}');
    final ok = await _service.requestPermissions();
    if (!ok) {
      _log('Discovery failed: Permission Denied.');
      _status = MpStatus.permissionDenied;
      _error = 'Bluetooth / Nearby permissions are required for multiplayer.';
      notifyListeners();
      return;
    }
    _myRole = MpRole.sidekick;
    _myNickname = nickname;
    _pinCode = pinCode;
    // Force Cultist. Resolved locally against master data so we broadcast
    // the canonical name casing the receiver expects.
    final cultist = _runProvider.gungeoneerByName('The Cultist') ??
        _runProvider.gungeoneerByName('Cultist');
    _myCharacterName = cultist?.name ?? 'The Cultist';
    _lastRole = MpRole.sidekick;
    _lastCharacter = cultist;
    _lastNickname = nickname;
    _status = MpStatus.searching;
    _error = null;
    // Snapshot the existing run-scope state the FIRST time we start
    // as Sidekick so we can restore it on cancel. Reconnect re-enters
    // this method with the peer's stale data still sitting in `main`,
    // so we mustn't overwrite the genuine pre-MP capture.
    _preSidekickRun ??= (
      main: _runProvider.runState.main,
      coolness: _runProvider.runState.coolness,
      curse: _runProvider.runState.curse,
      shrinesUsed: List<String>.from(_runProvider.runState.shrinesUsed),
    );
    notifyListeners();
    // Start search timeout
    _startSearchTimeout();
    // Sidekick starts their run as Cultist (coop slot).
    // Main Player's data will arrive via snapshot once connected.
    //
    // Reconnect-safe: if the coop slot is already a Cultist with an
    // inventory built up during the previous session, leave it alone.
    // Calling startCoopPlayer here would wipe everything they collected.
    final coopChar = _runProvider.runState.coop?.character?.name;
    final alreadyHasCoop = cultist != null && coopChar == cultist.name;
    if (cultist != null && !alreadyHasCoop) {
      _runProvider.startCoopPlayer(cultist);
    }
    _log('Discovery initiated... Scanning for Main Host matching PIN: ${pinCode.isEmpty ? "Any" : pinCode}');
    final started = await _service.startDiscovery(nickname, pinCode: pinCode);
    if (!started) {
      _log('Discovery failed: Could not start discovery adapter.');
      _searchTimeout?.cancel();
      await _service.stopSearching();
      _fail('Could not start discovery. Try toggling Bluetooth.');
    } else {
      _log('Discovery scanner started successfully. Scanning channels...');
    }
  }

  /// User pressed Cancel on the searching view or Disconnect on the
  /// connected view. Tears down the transport and returns to idle.
  Future<void> cancel() async {
    _log('Multiplayer session cancelled by user. Restoring local state...');
    // Recovery on session end:
    //  * Sidekick: drop the Cultist coop (a transient MP avatar) and
    //    put the user's pre-MP main back so a solo run isn't lost.
    //  * Main Player: drop the stale peer snapshot from coop so the
    //    inventory tab doesn't keep showing a "Cultist" partner that
    //    isn't actually connected anymore.
    _applyingRemote = true;
    try {
      if (_myRole == MpRole.sidekick) {
        final pre = _preSidekickRun;
        _runProvider.endCoopPlayer();
        if (pre != null) {
          _runProvider.restoreRunScopeState(
            main: pre.main,
            coolness: pre.coolness,
            curse: pre.curse,
            shrinesUsed: pre.shrinesUsed,
          );
        } else {
          _runProvider.restoreMainSlot(Player());
        }
      } else if (_myRole == MpRole.main) {
        _runProvider.endCoopPlayer();
      }
    } finally {
      _applyingRemote = false;
    }
    _preSidekickRun = null;
    _pendingRequest = null;
    _outgoingRequests.clear();
    _seenReqIds.clear();
    _lastResp = null;
    // Cancel all pending request timeout timers
    for (final timer in _requestTimeoutTimers.values) {
      timer.cancel();
    }
    _requestTimeoutTimers.clear();
    // User-initiated teardown: forget the persisted session so we don't
    // try to silently rejoin on next app launch.
    unawaited(_clearPersistedSession());
    // Clear session identity so the next pairing gets a fresh name.
    _cachedSessionName = null;
    _cachedSessionId = null;
    if (_isSimulated) {
      _isSimulated = false;
    } else {
      await _service.stopAll();
    }
    _stopHeartbeat();
    _searchTimeout?.cancel();
    _helloRetryTimer?.cancel();
    _cancelAutoReconnect();
    _helloReceived = false;
    _helloAttempts = 0;
    _sessionStartedAtMs = null;
    _pinCode = null;
    _mySnapshotSeq = 0;
    _peerRole = null;
    _peerNickname = null;
    _peerCharacterName = null;
    _peerLastSnapshotTs = 0;
    _protocolError = false;
    _status = MpStatus.idle;
    _error = null;
    _log('Transport powered down. Returned to Idle.');
    notifyListeners();
  }

  /// True if we have enough remembered state to reattempt the last
  /// session via [reconnect].
  bool get canReconnect => _lastRole != null && _lastCharacter != null;

  /// Number of auto-reconnect attempts already made (0 when not retrying).
  int get autoReconnectAttempts => _autoReconnectAttempts;

  /// Whether an auto-reconnect retry is currently scheduled/running.
  bool get isAutoReconnecting => _autoReconnectTimer != null;

  /// One-tap reconnect: tear down current transport state and re-start
  /// advertising/discovery with the previously-used role + character.
  /// The peer (still on the run) will see us as a new endpoint and the
  /// auto-accept flow will re-establish the session. The local
  /// inventory state survives because this never touches RunProvider.
  Future<void> reconnect() async {
    if (_busyTransition) return;
    final role = _lastRole;
    final char = _lastCharacter;
    if (role == null || char == null) return;
    _log('Initiating reconnection sequence...');
    _busyTransition = true;
    try {
      // Reset transport state but DON'T touch the run/inventory.
      // Keep status as-is (disconnected/error) until startAsMain/Sidekick
      // sets it to searching — this prevents the status bar from briefly
      // vanishing to idle while the transport restarts.
      await _service.stopAll();
      
      _log('Nearby endpoints stopped. Entering 800ms native radio cooldown delay to fully release unbonded sockets...');
      await Future.delayed(const Duration(milliseconds: 800)); // Crucial Native Radio Cooldown delay!
      _log('Cooldown complete. Restarting transport services...');

      _stopHeartbeat();
      _searchTimeout?.cancel();
      _helloRetryTimer?.cancel();
      _helloReceived = false;
      _helloAttempts = 0;
      _peerRole = null;
      _peerNickname = null;
      _peerCharacterName = null;
      _peerLastSnapshotTs = 0;
      _protocolError = false;
      _seenReqIds.clear();
      _pendingRequest = null;
      _outgoingRequests.clear();
      // Cancel any leftover request timeout timers; their reqIds belong
      // to the dead transport session and would fire late "denied" toasts.
      for (final timer in _requestTimeoutTimers.values) {
        timer.cancel();
      }
      _requestTimeoutTimers.clear();
      // Reset peer-touch so the freshly armed watchdog doesn't trip on
      // stale data from the previous session and immediately disconnect.
      _lastPeerTouchMs = DateTime.now().millisecondsSinceEpoch;
      _lastResp = null;
      _error = null;
      _mySnapshotSeq = 0;
      notifyListeners();
      if (role == MpRole.main) {
        await startAsMain(nickname: _lastNickname, character: char);
      } else {
        await startAsSidekick(nickname: _lastNickname, pinCode: _pinCode ?? '');
      }
    } finally {
      _busyTransition = false;
    }
  }

  /// User wants to drop the current peer but NOT leave the multiplayer
  /// screen — we stay in `disconnected` so they can tap Reconnect.
  Future<void> disconnect() async {
    _log('Disconnecting from active peer by user request.');
    await _service.disconnect();
    _stopHeartbeat();
    _searchTimeout?.cancel();
    _helloRetryTimer?.cancel();
    _cancelAutoReconnect();
    _helloReceived = false;
    _mySnapshotSeq = 0;
    _protocolError = false;
    _seenReqIds.clear();
    _pendingRequest = null;
    // Cancel any in-flight requests — their responses can't arrive
    // while we're disconnected, and the 30s timeouts would surface
    // misleading "denied" toasts long after the user moved on.
    _outgoingRequests.clear();
    // Cancel all pending request timeout timers
    for (final timer in _requestTimeoutTimers.values) {
      timer.cancel();
    }
    _requestTimeoutTimers.clear();
    _lastResp = null;
    // User-initiated drop: forget the persisted session so we don't
    // silently rejoin on next app launch.
    unawaited(_clearPersistedSession());
    _status = MpStatus.disconnected;
    _log('Session disconnected.');
    notifyListeners();
  }

  /// Local user ended the run while in an MP session. Tells the peer
  /// to wrap up at the same time and tears down the session cleanly so
  /// neither side is left with a phantom "connected" status.
  Future<void> notifyEndRunAndCancel() async {
    if (isConnected) {
      try {
        await _service.sendMessage(const MpEndRun());
      } catch (e) {
        // Best-effort — if the send fails the peer will detect via
        // watchdog or by their own UI when they open multiplayer again.
// Removed debugPrint for production
      }
    }
    await cancel();
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _runProvider.removeListener(_onRunChanged);
    _broadcastDebounce?.cancel();
    _heartbeat?.cancel();
    _watchdog?.cancel();
    _searchTimeout?.cancel();
    _helloRetryTimer?.cancel();
    _autoReconnectTimer?.cancel();
    for (final timer in _requestTimeoutTimers.values) {
      timer.cancel();
    }
    _requestTimeoutTimers.clear();
    unawaited(_service.dispose());
    super.dispose();
  }

  // ---- Outgoing operations (called by UI) ------------------------------

  /// Send a dice roll challenge invitation to the peer.
  Future<void> sendDiceChallenge(String challengerName) async {
    if (isConnected) {
      await _service.sendMessage(MpDiceChallenge(challengerName: challengerName));
    }
  }

  /// Accept a dice roll challenge invitation from the peer.
  Future<void> sendDiceAccept() async {
    if (isConnected) {
      await _service.sendMessage(const MpDiceAccept());
    }
  }

  /// Broadcast dice roll results to the peer.
  Future<void> sendDiceResult(int score, List<int> dice) async {
    if (isConnected) {
      await _service.sendMessage(MpDiceResult(score: score, dice: dice));
    }
  }

  /// Gift: remove locally + send `gift`. If send fails, rollback the removal
  /// to prevent item loss.
  Future<void> sendGift({required String kind, required String name}) async {
    if (!isConnected) return;
    // Use correct slot based on role: Main uses main slot, Sidekick uses coop slot.
    final mySlot = _myRole == MpRole.main ? PlayerSlot.main : PlayerSlot.coop;
    // Remove from inventory first, but track for potential rollback.
    Gun? removedGun;
    Item? removedItem;
    switch (kind) {
      case 'gun':
        removedGun = _runProvider.gunByName(name);
        if (removedGun != null) _runProvider.removeGun(removedGun, slot: mySlot);
        break;
      case 'item':
        removedItem = _runProvider.itemByName(name);
        if (removedItem != null) _runProvider.removeItem(removedItem, slot: mySlot);
        break;
    }
    // If item wasn't found, nothing to send.
    if (removedGun == null && removedItem == null) return;
    // Attempt to send; rollback on failure to prevent item loss.
    try {
      await _service.sendMessage(MpGift(kind: kind, name: name));
    } catch (e) {
      // Rollback: restore item to inventory since send failed.
      if (removedGun != null) {
        _runProvider.addGun(removedGun, slot: mySlot);
      } else if (removedItem != null) {
        _runProvider.addItem(removedItem, slot: mySlot);
      }
// Removed debugPrint for production
    }
  }

  /// Request: send `request`; recipient will show accept/deny sheet.
  /// Returns the reqId so the UI can show a "waiting..." state for it.
  /// Returns null if not connected (request not sent).
  Future<String?> sendRequest({
    required String kind,
    required String name,
  }) async {
    if (!isConnected) {
      // Don't create orphaned requests if not connected.
      return null;
    }
    final reqId = _newReqId();
    _outgoingRequests[reqId] = _OutgoingRequest(kind, name);
    try {
      await _service.sendMessage(
        MpRequest(reqId: reqId, kind: kind, name: name),
      );
    } catch (e) {
      // Send failed - clean up the orphaned request immediately.
      _outgoingRequests.remove(reqId);
// Removed debugPrint for production
      return null;
    }
    notifyListeners();
    // Auto-expire after 30s. If the peer never responded, surface a
    // toast via _lastResp so the requester isn't left wondering.
    final timer = Timer(const Duration(seconds: 30), () {
      final out = _outgoingRequests.remove(reqId);
      _requestTimeoutTimers.remove(reqId);
      if (out != null) {
        _lastResp = (name: out.name, approved: false);
        notifyListeners();
      }
    });
    _requestTimeoutTimers[reqId] = timer;
    return reqId;
  }

  /// Answer the [pendingRequest]. If approved, sends the gift FIRST
  /// then the approval response. This prevents the race where peer gets
  /// approval but the gift fails mid-send.
  Future<void> respondToPendingRequest(bool approved) async {
    final req = _pendingRequest;
    if (req == null) return;
    _pendingRequest = null;
    if (!isConnected) {
      notifyListeners();
      return;
    }

    // If approved: send gift FIRST, then approval.
    // Prevents "phantom approval" where peer gets approval but no item.
    if (approved) {
      final mySlot = _myRole == MpRole.main ? PlayerSlot.main : PlayerSlot.coop;
      Gun? removedGun;
      Item? removedItem;
      switch (req.kind) {
        case 'gun':
          removedGun = _runProvider.gunByName(req.name);
          if (removedGun != null) _runProvider.removeGun(removedGun, slot: mySlot);
          break;
        case 'item':
          removedItem = _runProvider.itemByName(req.name);
          if (removedItem != null) _runProvider.removeItem(removedItem, slot: mySlot);
          break;
      }
      // Only send approval if gift was successfully sent.
      if (removedGun != null || removedItem != null) {
        try {
          await _service.sendMessage(MpGift(kind: req.kind, name: req.name));
        } catch (e) {
          // Rollback: restore item since send failed.
          if (removedGun != null) {
            _runProvider.addGun(removedGun, slot: mySlot);
          } else if (removedItem != null) {
            _runProvider.addItem(removedItem, slot: mySlot);
          }
// Removed debugPrint for production
          // Don't send approval since gift failed.
          notifyListeners();
          return;
        }
      }
    }

    // Send approval response (after successful gift or for denials).
    try {
      await _service.sendMessage(
        MpRequestResp(reqId: req.reqId, approved: approved),
      );
    } catch (e) {
// Removed debugPrint for production
      // Response failed but gift was already sent (if approved).
      // Peer will see it via their inventory sync anyway.
    }
    notifyListeners();
  }

  // ---- Inbound from transport ------------------------------------------

  void _onServiceEvent(MpServiceEvent e) {
    switch (e) {
      case MpEndpointFound(:final endpointId, :final endpointName):
        _log('Found target host: "$endpointName" (ID: $endpointId). Requesting connection...');
      case MpEndpointLost(:final endpointId):
        _log('Lost contact with host ID: $endpointId');
      case MpConnectionInitiated(:final endpointId, :final endpointName):
        _log('Connection initiated with: "$endpointName" (ID: $endpointId). Handshaking...');
        _status = MpStatus.handshaking;
        notifyListeners();
      case MpConnected():
        _log('Transport channel established! Starting protocol handshake Hello sequence...');
        _searchTimeout?.cancel();
        _helloRetryTimer?.cancel();
        _status = MpStatus.handshaking;
        _helloReceived = false;
        _helloAttempts = 0;
        _lastPeerTouchMs = DateTime.now().millisecondsSinceEpoch;
        notifyListeners();
        // Fire hello + first snapshot immediately, with retry logic.
        _sendHelloWithRetry();
        _startHeartbeat();
      case MpRejected():
        _log('Connection request rejected or timed out on peer device.');
        // Stop the radios alongside the user-visible error so we don't
        // keep advertising/discovering after a hard refusal.
        unawaited(_service.stopSearching());
        _fail('Connection rejected by peer.');
      case MpDisconnected():
        _log('Transport connection dropped or closed.');
        // Don't overwrite protocol errors (version/role mismatch) with disconnect.
        if (_protocolError) {
          _stopHeartbeat();
          return;
        }
        if (_status == MpStatus.connected ||
            _status == MpStatus.handshaking ||
            _status == MpStatus.error) {
          _log('Drop detected during active run! Starting automatic reconnect sequence...');
          _status = MpStatus.disconnected;
          _stopHeartbeat();
          notifyListeners();
          _startAutoReconnect();
        } else {
          _stopHeartbeat();
          notifyListeners();
        }
      case MpMessageReceived(:final message):
        _lastPeerTouchMs = DateTime.now().millisecondsSinceEpoch;
        _onMessage(message);
      case MpError(:final message):
        _log('Nearby Service internal error: $message');
        _error = message;
        notifyListeners();
    }
  }

  void _onMessage(MpMessage msg) {
    switch (msg) {
      case MpHello():
        _onHello(msg);
      case MpSnapshot():
        _onSnapshot(msg);
      case MpGift():
        _onGift(msg);
      case MpRequest():
        // Deduplication: ignore duplicate request IDs to prevent overwriting
        // a pending request with the same one arriving again.
        if (_seenReqIds.contains(msg.reqId)) {
// Removed debugPrint for production
          break;
        }
        _seenReqIds.add(msg.reqId);
        // Limit set size to prevent unbounded growth.
        while (_seenReqIds.length > _maxSeenReqIds) {
          _seenReqIds.remove(_seenReqIds.first);
        }
        // Show accept/deny sheet via pendingRequest.
        _pendingRequest = msg;
        notifyListeners();
      case MpRequestResp():
        final out = _outgoingRequests.remove(msg.reqId);
        if (out != null) {
          _lastResp = (name: out.name, approved: msg.approved);
          notifyListeners();
        }
        // Cancel and remove the timeout timer for this request
        _cancelRequestTimeout(msg.reqId);
      case MpEndRun():
        // Wrap the local clear in _applyingRemote so we don't echo an
        // empty snapshot back at the peer mid-teardown. The peer is
        // already cleaning up locally; we just need to mirror their
        // end-run, then tear down our own MP session cleanly.
        _applyingRemote = true;
        try {
          _runProvider.endRun();
        } finally {
          _applyingRemote = false;
        }
        notifyListeners();
        // Don't await — cancel() schedules transport teardown async,
        // and we don't want to block the message handler.
        unawaited(cancel());
      case MpPing():
        if (msg.lastSeq != null && msg.lastSeq! > _peerLastSnapshotTs) {
          // Detected desync: peer is ahead of our last recorded snapshot. Trigger immediate resync.
          _log('Desync detected via ping! Peer sequence ${msg.lastSeq} > ours $_peerLastSnapshotTs. Healing...');
          unawaited(_broadcastSnapshot());
        }
        unawaited(
          _service.sendMessage(
            MpPong(DateTime.now().millisecondsSinceEpoch, lastSeq: _mySnapshotSeq),
          ),
        );
      case MpPong():
        if (msg.lastSeq != null && msg.lastSeq! > _peerLastSnapshotTs) {
          // Detected desync: peer is ahead of our last recorded snapshot. Trigger immediate resync.
          _log('Desync detected via pong! Peer sequence ${msg.lastSeq} > ours $_peerLastSnapshotTs. Healing...');
          unawaited(_broadcastSnapshot());
        }
        break;
      case MpDiceChallenge():
        onDiceChallenge?.call(msg.challengerName);
      case MpDiceAccept():
        onDiceAccept?.call();
      case MpDiceResult():
        onDiceResult?.call(msg.score, msg.dice);
    }
  }

  void _onHello(MpHello h) {
    // Validate role pairing. Two Mains or two Sidekicks is never
    // valid — tell the user and bail so they can re-pick.
    // (App-version is informational only — protocolVersion guards
    // wire-compat, and version-string mismatches were causing too
    // many false rejections after every release.)
    if (h.protocolVersion != MpHello.currentProtocolVersion) {
      _fail(
        'Protocol version mismatch (yours v${MpHello.currentProtocolVersion}, '
        'peer v${h.protocolVersion}). Update both apps to the same version.',
        isProtocolError: true,
      );
      unawaited(_service.disconnect());
      return;
    }
    if (h.role == _myRole) {
      _fail(
        'Both players picked ${_roleLabel(h.role)}. '
        'One of you needs to pick the other role.',
        isProtocolError: true,
      );
      unawaited(_service.disconnect());
      return;
    }
    // Security PIN Code validation (normalized to handle null vs empty string consistently)
    final myPin = (_pinCode == null || _pinCode!.isEmpty) ? null : _pinCode;
    final peerPin = (h.pinCode == null || h.pinCode!.isEmpty) ? null : h.pinCode;
    if (peerPin != myPin) {
      _fail(
        'Security Alert: Unauthorized connection attempt with mismatched connection code.',
        isProtocolError: true,
      );
      unawaited(_service.disconnect());
      return;
    }
    _helloReceived = true;
    _helloRetryTimer?.cancel();
    _peerRole = h.role;
    _peerNickname = _cleanNickname(h.userLabel);
    _peerCharacterName = h.character;
    if (_myRole == MpRole.sidekick && h.role == MpRole.main) {
      if (h.sessionName != null) _cachedSessionName = h.sessionName;
      if (h.sessionId != null) _cachedSessionId = h.sessionId;
    }
    _status = MpStatus.connected;
    _sessionStartedAtMs ??= DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
    // Persist session identity now that the handshake succeeded so an
    // app-kill mid-session can resume into the same role on next launch.
    unawaited(_persistSession());
    // Send initial snapshot after hello exchange
    unawaited(_broadcastSnapshot(force: true));
  }

  String _cleanNickname(String name) {
    if (name.contains('#')) {
      return name.split('#').first;
    }
    return name;
  }

  String _newPinCode() {
    // Generate a 4-digit code (1000 - 9999)
    final pin = (_rng.nextInt(9000) + 1000).toString();
    return pin;
  }

  void _onSnapshot(MpSnapshot s) {
    // LWW on peer timestamp. Out-of-order packets get dropped.
    //
    // Known edge case (acceptable): if BOTH players adjust coolness or
    // curse within the 200ms broadcast-debounce window, each side
    // applies the OTHER's value and the two devices end up with
    // swapped numbers (A=7, B=6 instead of A=B=8). The next adjustment
    // on either side resyncs them. Fixing this properly needs CRDT
    // counters for those two scalars; the current model is "shared
    // dungeon state, last edit wins" and is good enough for the
    // co-op tracker use-case.
    if (s.tsMs < _peerLastSnapshotTs) return;
    _peerLastSnapshotTs = s.tsMs;
    _applyingRemote = true;
    try {
      // Role-aware slot mapping:
      // - Main Player: peer (Sidekick) data goes to coop slot
      // - Sidekick: peer (Main) data goes to main slot
      final isMain = _myRole == MpRole.main;
      _runProvider.applyPeerSnapshot(
        characterName: s.character,
        gunNames: s.gunNames,
        itemNames: s.itemNames,
        targetMainSlot: !isMain, // Sidekick gets Main's data in main slot
      );
      _runProvider.applySharedStateFromPeer(
        coolness: s.coolness,
        curse: s.curse,
        shrinesUsed: s.shrinesUsed,
      );
    } catch (e) {
// Removed debugPrint for production
    } finally {
      _applyingRemote = false;
    }
  }

  void _onGift(MpGift g) {
    // Wrap in _applyingRemote so the gift addition doesn't trigger a
    // snapshot broadcast back to the peer. The peer already knows about
    // the gift (they just sent it), and the next natural change on either
    // side will sync the updated state.
    _applyingRemote = true;
    try {
      final mySlot = _myRole == MpRole.main ? PlayerSlot.main : PlayerSlot.coop;
      switch (g.kind) {
        case 'gun':
          final gun = _runProvider.gunByName(g.name);
          if (gun != null) _runProvider.addGun(gun, slot: mySlot);
          break;
        case 'item':
          final it = _runProvider.itemByName(g.name);
          if (it != null) _runProvider.addItem(it, slot: mySlot);
          break;
      }
    } finally {
      _applyingRemote = false;
    }
    // Broadcast snapshot immediately after receiving a gift so the peer's
    // UI is synchronized in real-time.
    _broadcastDebounce?.cancel();
    _broadcastDebounce = Timer(const Duration(milliseconds: 200), () {
      unawaited(_broadcastSnapshot());
    });
  }

  // ---- Broadcast helpers ----------------------------------------------

  void _onRunChanged() {
    if (_applyingRemote) return;
    if (_status != MpStatus.connected) return;
    // Debounce 200ms so a burst of tweaks (adding 3 items quickly)
    // collapses to one snapshot on the wire.
    _broadcastDebounce?.cancel();
    _broadcastDebounce = Timer(const Duration(milliseconds: 200), () {
      unawaited(_broadcastSnapshot());
    });
  }

  Future<void> _broadcastSnapshot({bool force = false}) async {
    if (!isConnected && !force) return;
    // Role-aware slot selection:
    // - Main Player: broadcasts main slot (their own character)
    // - Sidekick: broadcasts coop slot (their Cultist character)
    final isMain = _myRole == MpRole.main;
    final player = isMain
        ? _runProvider.runState.main
        : _runProvider.runState.coop;
    _mySnapshotSeq++;
    final snap = MpSnapshot(
      character: player?.character?.name ?? _myCharacterName,
      gunNames: player?.guns.map((g) => g.name).toList() ?? [],
      itemNames: player?.items.map((i) => i.name).toList() ?? [],
      coolness: _runProvider.runState.coolness,
      curse: _runProvider.runState.curse,
      shrinesUsed: _runProvider.runState.shrinesUsed,
      tsMs: _mySnapshotSeq,
    );
    try {
      await _service.sendMessage(snap);
    } catch (e) {
      // Snapshot failed (connection dropped). Next change will retry.
// Removed debugPrint for production
    }
  }

  Future<void> _sendHello() async {
    final role = _myRole;
    if (role == null) return;
    try {
      await _service.sendMessage(
        MpHello(
          role: role,
          character: _myCharacterName,
          userLabel: _myNickname,
          // Informational only; protocolVersion is the real compat gate.
          appVersion: 'app',
          sessionName: sessionName,
          sessionId: sessionId,
          pinCode: _pinCode,
        ),
      );
    } catch (e) {
      // Hello send failed; retry timer will fire again.
// Removed debugPrint for production
    }
  }

  void _sendHelloWithRetry() {
    if (_helloReceived) return;
    if (_helloAttempts >= _maxHelloAttempts) {
      _fail('Handshake failed. Could not establish connection with peer.');
      unawaited(_service.disconnect());
      return;
    }
    _helloAttempts++;
    unawaited(_sendHello());
    // Cancel any existing retry timer before creating new one
    _helloRetryTimer?.cancel();
    // Retry after timeout if no hello received
    _helloRetryTimer = Timer(Duration(milliseconds: _helloTimeoutMs), () {
      if (!_helloReceived && _status == MpStatus.handshaking) {
        _sendHelloWithRetry();
      }
    });
  }

  // ---- Heartbeat / watchdog --------------------------------------------

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _watchdog?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!isConnected) return;
      unawaited(_service.sendMessage(
        MpPing(DateTime.now().millisecondsSinceEpoch, lastSeq: _mySnapshotSeq),
      ));
    });
    // Watchdog: if we haven't heard anything from peer in >30s, flag
    // disconnected and start auto-reconnect. 30s = ~3 missed heartbeats
    // (heartbeat every 5s) for tolerance.
    _watchdog = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_status != MpStatus.connected) return;
      final silentMs =
          DateTime.now().millisecondsSinceEpoch - _lastPeerTouchMs;
      if (silentMs > 30000) {
        _status = MpStatus.disconnected;
        notifyListeners();
        _stopHeartbeat();
        _startAutoReconnect();
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
    _watchdog?.cancel();
    _watchdog = null;
  }

  void _startSearchTimeout() {
    _searchTimeout?.cancel();
    _searchTimeout = Timer(Duration(milliseconds: _searchTimeoutMs), () {
      if (_status == MpStatus.searching) {
        _fail('No peer found. Make sure both devices have Bluetooth enabled and are close together.');
        unawaited(_service.stopSearching());
      }
    });
  }

  // ---- Auto-reconnect ---------------------------------------------------

  /// Attempts to automatically reconnect after a disconnect. Retries
  /// indefinitely with exponential backoff (capped at 30s) until the
  /// user manually cancels or we successfully reconnect.
  void _startAutoReconnect() {
    // Don't reset the attempt counter if we're already retrying —
    // both the watchdog and MpDisconnected can fire for the same drop.
    if (_autoReconnectTimer != null) return;
    _autoReconnectAttempts = 0;
    _tryAutoReconnect();
  }

  void _tryAutoReconnect() {
    if (_status != MpStatus.disconnected) return;
    _autoReconnectAttempts++;
    // Exponential backoff capped at 30s. Sequence: 2, 4, 8, 16, 30, 30, ...
    // No upper limit on attempts: the session keeps trying until the
    // user explicitly ends the run or disconnects, so an accidental
    // app-kill or transient BT/Wi-Fi drop never silently strands them.
    final raw = 1 << _autoReconnectAttempts; // 2, 4, 8, 16, 32, 64...
    final secs = raw > _maxAutoReconnectBackoffSec
        ? _maxAutoReconnectBackoffSec
        : raw;
    _log('Auto-reconnect scheduler: Attempt #$_autoReconnectAttempts scheduled in $secs seconds...');
    final delay = Duration(seconds: secs);
    _autoReconnectTimer = Timer(delay, () {
      _autoReconnectTimer = null;
      if (_status != MpStatus.disconnected) return;
      if (_busyTransition) return;
      // Try to reconnect using the last known role/character
      _log('Executing scheduled auto-reconnect attempt #$_autoReconnectAttempts...');
      unawaited(reconnect());
    });
  }

  void _cancelAutoReconnect() {
    _autoReconnectTimer?.cancel();
    _autoReconnectTimer = null;
    _autoReconnectAttempts = 0;
  }

  /// Cancel and remove the timeout timer for a specific request ID.
  /// This prevents the timer from firing after the request has already
  /// been responded to, which would overwrite _lastResp with stale data.
  void _cancelRequestTimeout(String reqId) {
    final timer = _requestTimeoutTimers.remove(reqId);
    if (timer != null) {
      timer.cancel();
    }
  }

  // ---- Session name generator -------------------------------------------

  static const _adjectives = [
    'Brave', 'Swift', 'Mighty', 'Clever', 'Bold', 'Fierce', 'Noble',
    'Sly', 'Lucky', 'Grim', 'Wild', 'Steady', 'Quick', 'Sharp',
    'Stout', 'Keen', 'Wily', 'Stalwart', 'Valiant', 'Cunning',
  ];

  static const _animals = [
    'Bullet', 'Rat', 'Owl', 'Wolf', 'Raven', 'Fox', 'Bear', 'Hawk',
    'Snake', 'Turtle', 'Badger', 'Otter', 'Lynx', 'Viper', 'Falcon',
    'Drake', 'Boar', 'Crane', 'Mantis', 'Scorpion',
  ];

  String? _cachedSessionName;
  String? _cachedSessionId;

  String get sessionName {
    _cachedSessionName ??= () {
      final adj = _adjectives[_rng.nextInt(_adjectives.length)];
      final animal = _animals[_rng.nextInt(_animals.length)];
      return '$adj $animal';
    }();
    return _cachedSessionName!;
  }

  /// A short session ID for display (e.g. "BF-7A").
  String get sessionId {
    _cachedSessionId ??= () {
      final a = _rng.nextInt(256).toRadixString(16).toUpperCase().padLeft(2, '0');
      final b = _rng.nextInt(256).toRadixString(16).toUpperCase().padLeft(2, '0');
      return '$a-$b';
    }();
    return _cachedSessionId!;
  }

  // ---- Misc ------------------------------------------------------------

  void _fail(String message, {bool isProtocolError = false}) {
    _error = message;
    _status = MpStatus.error;
    _protocolError = isProtocolError;
    _stopHeartbeat();
    notifyListeners();
  }

  static final _rng = math.Random();
  String _newReqId() {
    // 8 hex chars; plenty of uniqueness for the handful of in-flight
    // requests a single session ever has.
    final a = _rng.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    return a;
  }

  String _roleLabel(MpRole r) =>
      r == MpRole.main ? 'Main Player' : 'Sidekick';

  // ---- Multiplayer Save / Load ------------------------------------------

  /// Save the current active multiplayer session to persistent local storage.
  /// Works for BOTH Main Player and Sidekick.
  Future<void> saveCurrentSession() async {
    final role = _myRole;
    final charName = _myCharacterName;
    if (role == null) return;

    final start = _sessionStartedAtMs ?? DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.now().millisecondsSinceEpoch;
    final duration = now - start;

    final saved = SavedMpSession(
      sessionId: sessionId,
      sessionName: sessionName,
      savedByRole: role,
      myNickname: _myNickname,
      peerNickname: _peerNickname ?? 'Peer',
      myCharacterName: charName,
      peerCharacterName: _peerCharacterName ?? '',
      startedAtMs: start,
      savedAtMs: now,
      durationMs: duration,
      runStateJson: _runProvider.runState.toJson(),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('saved_mp_sessions') ?? [];
      
      // Prevent duplicate saves of the same sessionId
      final List<String> updatedList = [];
      for (final s in list) {
        try {
          final decoded = SavedMpSession.fromJson(json.decode(s));
          if (decoded.sessionId != sessionId) {
            updatedList.add(s);
          }
        } catch (_) {
          updatedList.add(s);
        }
      }

      updatedList.add(json.encode(saved.toJson()));
      await prefs.setStringList('saved_mp_sessions', updatedList);
    } catch (e) {
      rethrow;
    }
  }

  /// Load a previously saved session, restore the RunState and transition immediately
  /// to re-establishing the peer connection in the correct role.
  Future<void> loadSavedSession(SavedMpSession saved, {MpRole? overrideRole}) async {
    // 1. Restore RunState in RunProvider
    final state = RunState.fromJson(saved.runStateJson);
    _runProvider.restoreEntireRunState(state);

    final roleToUse = overrideRole ?? saved.savedByRole;
    final rolesSwapped = roleToUse != saved.savedByRole;

    // 2. Set up our MultiplayerSession identity
    _myRole = roleToUse;
    _myNickname = rolesSwapped ? saved.peerNickname : saved.myNickname;
    _myCharacterName = roleToUse == MpRole.main
        ? (state.main.character?.name ?? saved.myCharacterName)
        : (state.coop?.character?.name ?? saved.myCharacterName);
    _cachedSessionId = saved.sessionId;
    _cachedSessionName = saved.sessionName;
    _lastRole = roleToUse;
    final gungeoneer = _runProvider.gungeoneerByName(_myCharacterName);
    _lastCharacter = gungeoneer;
    _lastNickname = _myNickname;
    _sessionStartedAtMs = saved.startedAtMs;
    _peerRole = roleToUse == MpRole.main ? MpRole.sidekick : MpRole.main;
    _peerNickname = rolesSwapped ? saved.myNickname : saved.peerNickname;
    _peerCharacterName = roleToUse == MpRole.main ? state.coop?.character?.name : state.main.character?.name;

    // 3. Immediately transition to searching/lobby state and start discovery/advertising!
    _status = MpStatus.searching;
    _error = null;
    _protocolError = false;
    notifyListeners();

    _startSearchTimeout();

    if (roleToUse == MpRole.main) {
      final started = await _service.startAdvertising(_myNickname);
      if (!started) {
        _searchTimeout?.cancel();
        await _service.stopSearching();
        _fail('Could not start advertising. Try toggling Bluetooth.');
      }
    } else {
      final started = await _service.startDiscovery(_myNickname);
      if (!started) {
        _searchTimeout?.cancel();
        await _service.stopSearching();
        _fail('Could not start discovery. Try toggling Bluetooth.');
      }
    }
  }
}

/// A serialized and stored multiplayer session. Allows both Host (Main) and Client (Sidekick)
/// to snapshot the run, save character assignments, and re-join the lobby to seamlessly resume.
class SavedMpSession {
  final String sessionId;
  final String sessionName;
  final MpRole savedByRole;
  final String myNickname;
  final String peerNickname;
  final String myCharacterName;
  final String peerCharacterName;
  final int startedAtMs;
  final int savedAtMs;
  final int durationMs;
  final Map<String, dynamic> runStateJson;

  SavedMpSession({
    required this.sessionId,
    required this.sessionName,
    required this.savedByRole,
    required this.myNickname,
    required this.peerNickname,
    required this.myCharacterName,
    required this.peerCharacterName,
    required this.startedAtMs,
    required this.savedAtMs,
    required this.durationMs,
    required this.runStateJson,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'sessionName': sessionName,
        'savedByRole': savedByRole.name,
        'myNickname': myNickname,
        'peerNickname': peerNickname,
        'myCharacterName': myCharacterName,
        'peerCharacterName': peerCharacterName,
        'startedAtMs': startedAtMs,
        'savedAtMs': savedAtMs,
        'durationMs': durationMs,
        'runStateJson': runStateJson,
      };

  factory SavedMpSession.fromJson(Map<String, dynamic> json) {
    return SavedMpSession(
      sessionId: json['sessionId'],
      sessionName: json['sessionName'],
      savedByRole: MpRole.values.firstWhere((r) => r.name == json['savedByRole']),
      myNickname: json['myNickname'] ?? 'Player',
      peerNickname: json['peerNickname'] ?? 'Peer',
      myCharacterName: json['myCharacterName'] ?? '',
      peerCharacterName: json['peerCharacterName'] ?? '',
      startedAtMs: json['startedAtMs'] ?? 0,
      savedAtMs: json['savedAtMs'] ?? 0,
      durationMs: json['durationMs'] ?? 0,
      runStateJson: json['runStateJson'],
    );
  }
}
