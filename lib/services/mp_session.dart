import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';

import '../models/gungeoneer.dart';
import '../models/multiplayer_messages.dart';
import '../models/player.dart';
import '../models/run_state.dart';
import '../providers/run_provider.dart';
import '../utils/asset_paths.dart';
import 'mp/mp_foreground_service.dart';
import 'mp/mp_link.dart';
import 'mp/mp_recovery.dart';
import 'mp/mp_store.dart';
import 'mp/mp_sync.dart';
import 'mp/mp_transport.dart';

/// High-level session phase from the UI's point of view.
enum MpPhase {
  idle,
  connecting,
  connected,
  disconnected,
  permissionDenied,
  error,
}

/// Why we're in [MpPhase.connecting] — drives the UI message.
enum MpConnectReason {
  hosting,
  browsing,
  joining,
  reconnecting,
  restoring,
  seeking, // Paradox "Enter the Void" — never times out
}

/// The ONLY thing the UI talks to. Thin facade that wires together
/// [MpLink], [MpSync], [MpRecovery], and [MpStore].
class MpSession extends ChangeNotifier with WidgetsBindingObserver {
  /// Nearby Connections needs time to release the BT/Wi-Fi radio socket
  /// before re-acquiring. Below ~600ms on Android, startAdvertising /
  /// startDiscovery can silently fail.
  static const int radioCooldownMs = 800;

  /// Placeholder constructor — used by ProxyProvider before the real
  /// RunProvider is available. The real provider is injected via
  /// [updateRunProvider] on the first build.
  MpSession.placeholder() : _runProvider = RunProvider(), _link = MpLink() {
    _initSession();
  }

  /// Test constructor — inject a custom transport (e.g. FakeMpLink).
  @visibleForTesting
  MpSession.withLink(this._runProvider, this._link) {
    _initSession();
  }

  MpSession(this._runProvider) : _link = MpLink() {
    _initSession();
  }

  /// Testing Mode — fakes a connected Paradox link so the full run
  /// UI renders solo (ParadoxBar, panels, chat entry). No Nearby
  /// transport is started; nothing is sent. For visual/demo use.
  void enableDemo() {
    _demoMode = true;
    _mode = MpMode.paradox;
    _myRole = MpRole.main;
    _myCharacterName = 'The Paradox';
    _connectReason = MpConnectReason.seeking;
    // Seed identity + a fake peer so the Paradox chrome (panel
    // avatars, chat header, lobby portraits) has something to render.
    if (_avatarId.isEmpty) _avatarId = kAvatarIds.first;
    _peerAvatarId = 'the_cultist';
    _peerNickname = 'Sidekick';
    _peerCharacterName = 'The Cultist';
    if (_runTitle.isEmpty) _runTitle = 'DEMO RUN';
    _phase = MpPhase.connected;

    // Initialize run state — same shape as startParadox: back up the
    // solo run first so cancel() can restore it, then start a Paradox
    // main plus an empty coop slot (the Paradox-sidekick fantasy).
    if (_runProvider.runState.main.character != null) {
      unawaited(MpStore.saveSoloRunBackup(_runProvider.runState));
    }
    final g = _runProvider.gungeoneerByName('The Paradox');
    if (g != null) {
      _runProvider.startNewRun(g);
      if (_runProvider.runState.coop == null) {
        final cultist = _runProvider.gungeoneerByName('The Cultist');
        _runProvider.startCoopPlayer(cultist ?? g);
      }
    }
    // The demo skips the lobby and drops straight into the run, so arm
    // the run timer the way sendStartRun() would.
    _startRunTimer();
    notifyListeners();
  }

  bool _demoMode = false;
  bool get demoMode => _demoMode;

  void _initSession() {
    _sync = MpSync(
      _link,
      _runProvider,
      onPeerConnected: (_) {},
      onPeerMetadata: (_, _) {},
    );
    // Propagate the app version (set by main.dart) to the sync layer
    // so it's included in the hello handshake.
    MpSync.appVersionString = appVersionString;
    _recovery = MpRecovery(
      _link,
      _runProvider,
      onRestoreSession: ({
        required MpRole role,
        required String nickname,
        required String character,
        RunState? preSidekickRun,
        MpMode mode = MpMode.classic,
        bool paused = false,
        String avatarId = '',
        String runTitle = '',
        int sessionNumber = 0,
        int runStartMs = 0,
        int runAccumMs = 0,
      }) {},
    );
    _wireComponents();
    WidgetsBinding.instance.addObserver(this);
  }

  RunProvider _runProvider;
  final MpTransport _link;
  late MpSync _sync;
  late MpRecovery _recovery;

  // ── State ──────────────────────────────────────────────────────
  MpPhase _phase = MpPhase.idle;
  MpPhase get phase => _phase;
  MpConnectReason _connectReason = MpConnectReason.hosting;
  MpConnectReason get connectReason => _connectReason;

  String? _error;
  String? get error => _error;

  MpRole? _myRole;
  MpRole? get myRole => _myRole;

  String _myNickname = 'Player';
  String get myNickname => _myNickname;

  String _myCharacterName = '';
  String get myCharacterName => _myCharacterName;

  // ── Peer metadata ──────────────────────────────────────────────
  String? _peerNickname;
  String? get peerNickname => _peerNickname;
  String? _peerCharacterName;
  String? get peerCharacterName => _peerCharacterName;

  // ── Paradox session state (v3) ─────────────────────────────────
  MpMode _mode = MpMode.classic;
  MpMode get mode => _mode;
  bool get isParadox => _mode == MpMode.paradox;

  String _avatarId = '';
  String get avatarId => _avatarId;
  String _peerAvatarId = '';
  String get peerAvatarId => _peerAvatarId;

  String _runTitle = '';
  String get runTitle => _runTitle;
  int _sessionNumber = 0;
  int get sessionNumber => _sessionNumber;

  bool get isPaused => pausedNotifier.value;
  final ValueNotifier<bool> pausedNotifier = ValueNotifier(false);

  /// Connection health 0–100 (RTT-based), straight from the transport.
  ValueListenable<int> get healthListenable => _link.healthListenable;

  // ── Chat state (Paradox, in-memory) ────────────────────────────
  final List<MpChat> chatMessages = [];

  /// Unified activity log — chat, surprises, emotes, transfers, and
  /// connect/disconnect notes all land here for the messages panel.
  final List<MpEvent> sessionEvents = [];
  void logEvent(MpEvent e) {
    sessionEvents.add(e);
    if (sessionEvents.length > 150) sessionEvents.removeAt(0);
    notifyListeners();
  }

  /// Wipes all session-scoped activity — chat history, queued sends,
  /// unread counter, and the unified event log. Called by
  /// [RunLifecycle.endRun] so the activity log is always cleared when
  /// the run ends, not just the chat array.
  void wipeSessionActivity() {
    chatMessages.clear();
    _queuedChat.clear();
    sessionEvents.clear();
    unreadChat.value = 0;
  }

  final ValueNotifier<int> unreadChat = ValueNotifier(0);
  final List<MpChat> _queuedChat = [];
  static const int _maxChatHistory = 200;

  /// UI callbacks — set by the run screen / paradox widgets.
  void Function(MpChat chat, bool mine)? onChatMessage;
  void Function(MpSurprise surprise)? onSurpriseReceived;
  void Function()? onStartRun;

  // ── Slots ──────────────────────────────────────────────────────
  PlayerSlot? get mySlot =>
      _myRole == MpRole.main ? PlayerSlot.main : (_myRole == MpRole.sidekick ? PlayerSlot.coop : null);
  PlayerSlot? get peerSlot =>
      _myRole == MpRole.main ? PlayerSlot.coop : (_myRole == MpRole.sidekick ? PlayerSlot.main : null);

  // ── Discovered endpoints ───────────────────────────────────────
  List<MpEndpoint> get discoveredEndpoints => _link.discoveredEndpoints;

  // ── Notifiers ──────────────────────────────────────────────────
  final ValueNotifier<bool> reconnectNotifier = ValueNotifier(false);
  final ValueNotifier<bool> reconnectSuccessNotifier = ValueNotifier(false);

  // ── Request/gift state (delegated to MpSync) ───────────────────
  MpRequest? get pendingRequest => _sync.pendingRequest;
  ({String name, bool approved})? get lastResp => _sync.lastResp;
  void consumeLastResp() => _sync.consumeLastResp();
  @visibleForTesting
  int get pendingGiftCount => _sync.pendingGiftCount;

  // ── Dice/emote callbacks (set by UI) ───────────────────────────
  void Function(String challengerName)? get onDiceChallenge => _sync.onDiceChallenge;
  set onDiceChallenge(void Function(String)? fn) => _sync.onDiceChallenge = fn;
  void Function()? get onDiceAccept => _sync.onDiceAccept;
  set onDiceAccept(void Function()? fn) => _sync.onDiceAccept = fn;
  void Function()? get onDiceDecline => _sync.onDiceDecline;
  set onDiceDecline(void Function()? fn) => _sync.onDiceDecline = fn;
  void Function()? get onDiceCancel => _sync.onDiceCancel;
  set onDiceCancel(void Function()? fn) => _sync.onDiceCancel = fn;
  void Function(int, List<int>)? get onDiceResult => _sync.onDiceResult;
  set onDiceResult(void Function(int, List<int>)? fn) => _sync.onDiceResult = fn;
  void Function(String, String)? get onEmote => _sync.onEmote;
  set onEmote(void Function(String, String)? fn) => _sync.onEmote = fn;

  /// Fired when the peer sends us a gift — UI shows a snackbar.
  void Function(String kind, String name)? get onGiftReceived => _sync.onGiftReceived;
  set onGiftReceived(void Function(String kind, String name)? fn) => _sync.onGiftReceived = fn;

  // ── Static ─────────────────────────────────────────────────────
  static String appVersionString = 'unknown';

  // ── Pre-MP run snapshot (for Sidekick cancel-restore) ──────────
  RunState? _preSidekickRun;
  RunState? get preSidekickRun => _preSidekickRun;

  /// Guard against concurrent teardown. If the user taps "End Run" at
  /// the exact moment the peer sends [MpEndRun], both [cancel] and
  /// [_onPeerEndRun] would execute simultaneously — double-restoring
  /// run state and double-calling _teardown. This guard prevents that.
  bool _tearingDown = false;
  @visibleForTesting
  bool get isTearingDown => _tearingDown;

  // ── Periodic save timer ────────────────────────────────────────
  Timer? _saveTimer;

  /// Connection timeout — if we're stuck in `connecting` for too long,
  // ── Wiring ─────────────────────────────────────────────────────

  void _wireComponents() {
    _link.onEndpointsChanged = (_) => notifyListeners();
    _link.onMessage = _onMessage;
    _link.onConnected = _onLinkConnected;
    _link.onDisconnected = _onLinkDisconnected;
    _link.onError = _onLinkError;

    _sync.onPeerConnected = _onSyncPeerConnected;
    _sync.onPeerMetadata = _onSyncPeerMetadata;
    _sync.onSyncError = _onSyncError;
    _sync.onPeerEndRun = _onPeerEndRun;
    _sync.onPeerHello = _onPeerHello;
    _sync.onSessionMeta = _onSessionMeta;
    _sync.onPauseChanged = _onPeerPauseChanged;
    _sync.onStartRun = () => onStartRun?.call();
    _sync.onChat = _onChatReceived;
    _sync.onSurprise = (s) {
      logEvent(MpEvent.event(
          kind: 'surprise',
          from: _peerNickname ?? 'Peer',
          text: s.text.isEmpty ? s.preset : s.text,
          mine: false));
      onSurpriseReceived?.call(s);
    };

    _recovery.onRestoreSession = _onRecoveryRestore;
    _runProvider.addListener(_onRunChanged);
  }

  void _onRunChanged() => _sync.onRunChanged();

  // ── Message routing ────────────────────────────────────────────

  void _onMessage(MpMessage msg) {
    _sync.onMessage(msg);
    // MpSync sets _pendingRequest / _lastResp inside onMessage, but
    // MpSync is not a ChangeNotifier. The MpRequestListener widget
    // watches MpSession, so we must notify here for message types
    // that change UI-visible state without going through RunProvider
    // (which would notify on its own).
    if (msg is MpRequest || msg is MpRequestResp) {
      notifyListeners();
    }
  }

  // ── Link callbacks ─────────────────────────────────────────────

  void _onLinkConnected() => _sync.onConnected();

  void _onLinkDisconnected() {
    // Guard: don't re-activate recovery during teardown or from
    // error/permission-denied phases. During teardown, _teardown()
    // calls _link.stopAll() which fires onDisconnected — we must
    // not start recovery or flip to disconnected phase.
    if (_tearingDown) return;
    if (_phase == MpPhase.idle) return;
    if (_phase == MpPhase.error || _phase == MpPhase.permissionDenied) return;
    // Peer dropped during a live session — start recovery.
    _sync.onDisconnected();
    _setPhase(MpPhase.disconnected);
    _connectReason = MpConnectReason.reconnecting;
    reconnectNotifier.value = true;
    Future.delayed(const Duration(milliseconds: 100), () {
      reconnectNotifier.value = false;
    });
    _recovery.onPeerDisconnected();
    logEvent(MpEvent.event(
        kind: 'system',
        from: _peerNickname ?? 'Peer',
        text: 'Connection lost — reconnecting…',
        mine: false));
    if (_runProvider.runState.main.character != null) {
      unawaited(MpStore.saveRunState(_runProvider.runState, force: true));
    }
  }

  void _onLinkError(String error) {
    _error = error;
    if (_phase == MpPhase.connecting) {
      _setPhase(MpPhase.error);
      // Stop the radio — no point scanning/advertising after an error.
      unawaited(_link.stopAll());
    }
  }

  // ── Sync callbacks ─────────────────────────────────────────────

  void _onSyncPeerConnected(MpRole peerRole) {
    // Hello succeeded — transition to connected.
    _setPhase(MpPhase.connected);
    logEvent(MpEvent.event(
        kind: 'system',
        from: _peerNickname ?? 'Peer',
        text: 'Connected',
        mine: false));
    reconnectSuccessNotifier.value = true;
    Future.delayed(const Duration(milliseconds: 100), () {
      reconnectSuccessNotifier.value = false;
    });
    _recovery.onPeerReconnected();
    _sync.resendPendingGifts();
    _startSaveTimer();
    // Keep the process alive so minimizing/screen-off doesn't drop
    // the session — stopped on teardown.
    unawaited(MpForegroundService.start(_runTitle));
    // Flush queued chat — messages typed while disconnected are
    // delivered now rather than silently dropped.
    if (_queuedChat.isNotEmpty) {
      for (final m in _queuedChat) {
        unawaited(_sync.sendChat(m));
      }
      _queuedChat.clear();
    }
    // If we were paused and the user tapped resume while offline,
    // push the resume now that the link is live.
    if (!pausedNotifier.value) {
      // no-op — flag already correct; meta sync handles peers
    }
    unawaited(_persistSession());
  }

  void _onSyncPeerMetadata(String peerNickname, String peerCharacter) {
    _peerNickname = peerNickname;
    _peerCharacterName = peerCharacter;
    notifyListeners();
  }

  /// Hello handshake completed — capture Paradox identity fields.
  /// Main generates the authoritative session meta (title/number are
  /// already ours); Sidekick adopts whatever Main sent.
  void _onPeerHello(MpHello h) {
    _peerAvatarId = h.avatarId;
    if (_myRole != MpRole.main && h.runTitle.isNotEmpty) {
      _runTitle = h.runTitle;
      _sessionNumber = h.sessionNumber;
    }
    // Main: rebroadcast authoritative meta right after handshake so the
    // peer lands on the correct title/number/paused state even if it
    // missed an earlier edge message (e.g. reconnect during pause).
    if (_myRole == MpRole.main && _mode == MpMode.paradox) {
      unawaited(_sync.sendSessionMeta(
        runTitle: _runTitle,
        sessionNumber: _sessionNumber,
        paused: pausedNotifier.value,
      ));
    }
    notifyListeners();
  }

  /// Main-authoritative meta applied on the Sidekick.
  void _onSessionMeta(MpSessionMeta meta) {
    _runTitle = meta.runTitle;
    _sessionNumber = meta.sessionNumber;
    if (meta.paused != pausedNotifier.value) {
      _applyPaused(meta.paused, notifyPeer: false);
    } else {
      notifyListeners();
    }
  }

  void _onPeerPauseChanged(bool paused) {
    _applyPaused(paused, notifyPeer: false);
  }

  void _onChatReceived(MpChat msg) {
    logEvent(MpEvent.chat(from: msg.from, text: msg.text, mine: false));
    chatMessages.add(msg);
    if (chatMessages.length > _maxChatHistory) chatMessages.removeAt(0);
    unreadChat.value++;
    onChatMessage?.call(msg, false);
    notifyListeners();
  }

  void _onSyncError(String error) {
    _error = error;
    _setPhase(MpPhase.error);
    // Stop the radio on sync errors (protocol mismatch, etc.).
    unawaited(_link.stopAll());
  }

  // ── Recovery callback ──────────────────────────────────────────

  void _onRecoveryRestore({
    required MpRole role,
    required String nickname,
    required String character,
    RunState? preSidekickRun,
    MpMode mode = MpMode.classic,
    bool paused = false,
    String avatarId = '',
    String runTitle = '',
    int sessionNumber = 0,
    int runStartMs = 0,
    int runAccumMs = 0,
  }) {
    _myRole = role;
    _myNickname = nickname;
    _myCharacterName = character;
    _mode = mode;
    _avatarId = avatarId;
    _runTitle = runTitle;
    _sessionNumber = sessionNumber;
    pausedNotifier.value = paused;
    _runStartMs = runStartMs;
    _runAccumMs = runAccumMs;
    _connectReason = MpConnectReason.restoring;
    if (mode == MpMode.paradox) {
      // Kill any radios still running under the previous service ID —
      // switching IDs while advertising/discovering leaves a stale
      // broadcaster the peer can't find (and vice versa).
      unawaited(_link.stopAll());
      _link.setServiceId(MpLink.serviceIdParadox);
    }
    if (role == MpRole.sidekick) {
      _preSidekickRun = preSidekickRun;
    }

    _sync.setIdentity(role: role, nickname: nickname, character: character);
    _sync.setSessionMeta(
      mode: mode,
      avatarId: avatarId,
      runTitle: runTitle,
      sessionNumber: sessionNumber,
    );
    _recovery.setSessionInfo(role: role, nickname: nickname);

    _setPhase(MpPhase.connecting);
    if (role == MpRole.main) {
      unawaited(_link.startAdvertising(nickname));
    } else {
      unawaited(_link.startDiscovery(
        nickname,
        autoConnect: const AutoConnectModeAny(),
      ));
    }
  }

  // ── Session start ──────────────────────────────────────────────

  /// Main Player starts hosting. Begins advertising and waits for a
  /// Sidekick to join.
  Future<void> startAsMain({
    required String nickname,
    required Gungeoneer character,
    String avatarId = '',
  }) async {
    _myRole = MpRole.main;
    _myNickname = nickname;
    _myCharacterName = character.name;
    _avatarId = avatarId;
    _error = null;
    _connectReason = MpConnectReason.hosting;

    _sync.setIdentity(role: MpRole.main, nickname: nickname, character: character.name);
    _sync.setSessionMeta(
      mode: MpMode.classic,
      avatarId: avatarId,
      runTitle: '',
      sessionNumber: 0,
    );
    _recovery.setSessionInfo(
      role: MpRole.main,
      nickname: nickname,
    );

    // Save the current solo run before overwriting it with the MP
    // run. Without this, the Main player loses their pre-MP run
    // when they cancel — there's no backup to restore.
    if (_runProvider.runState.main.character != null) {
      unawaited(MpStore.saveSoloRunBackup(_runProvider.runState));
    }

    // Initialize the run: main slot + coop slot.
    _runProvider.startNewRun(character);
    if (_runProvider.runState.coop == null) {
      _runProvider.startCoopPlayer(character);
    }

    final granted = await _link.requestPermissions();
    if (!granted) {
      _setPhase(MpPhase.permissionDenied);
      return;
    }

    _setPhase(MpPhase.connecting);
    await _link.startAdvertising(nickname);
  }

  /// Sidekick joins a game by discovering and auto-connecting to a host.
  Future<void> startAsSidekick({
    required String nickname,
    Gungeoneer? character,
    String avatarId = '',
  }) async {
    _myRole = MpRole.sidekick;
    _myNickname = nickname;
    _myCharacterName = character?.name ?? 'The Cultist';
    _avatarId = avatarId;
    _error = null;
    _connectReason = MpConnectReason.joining;

    // Capture pre-MP run state for cancel-restore.
    _preSidekickRun = _runProvider.runState;
    unawaited(MpStore.savePreSidekickRun(_preSidekickRun!));

    // Initialize main slot with Sidekick's character, then set up
    // the coop slot with the same character. The main slot will be
    // overwritten when Main's snapshot arrives (applyPeerSnapshot with
    // targetMainSlot: true), but the coop slot persists — that's the
    // Sidekick's own character and inventory. Without this, the
    // Sidekick sees no coop page, no MP panels, and broadcasts an
    // empty snapshot (Main can't see Cultist's starting items).
    final sidekickChar = character ?? _runProvider.gungeoneerByName('The Cultist');
    if (sidekickChar != null) {
      _runProvider.startNewRun(sidekickChar);
      if (_runProvider.runState.coop == null) {
        _runProvider.startCoopPlayer(sidekickChar);
      }
    }

    _sync.setIdentity(
      role: MpRole.sidekick,
      nickname: nickname,
      character: _myCharacterName,
    );
    _sync.setSessionMeta(
      mode: MpMode.classic,
      avatarId: avatarId,
      runTitle: '',
      sessionNumber: 0,
    );
    _recovery.setSessionInfo(
      role: MpRole.sidekick,
      nickname: nickname,
    );

    final granted = await _link.requestPermissions();
    if (!granted) {
      _setPhase(MpPhase.permissionDenied);
      return;
    }

    _setPhase(MpPhase.connecting);
    // Auto-connect to the first discovered host endpoint.
    await _link.startDiscovery(
      nickname,
      autoConnect: const AutoConnectModeAny(),
    );
  }

  // ── Paradox Mode (v3) ──────────────────────────────────────────

  /// Paradox setup — both players "Enter the Void". Roles are fixed:
  /// MAIN plays The Paradox, SIDEKICK plays The Cultist. The avatar is
  /// cosmetic identity only. Uses the dedicated Paradox serviceId so
  /// classic-MP devices can never be discovered. **Never times out** —
  /// seeking continues until cancelled or connected.
  Future<void> startParadox({
    required MpRole role,
    required String nickname,
    required String avatarId,
    required String runTitle,
    required int sessionNumber,
  }) async {
    _mode = MpMode.paradox;
    _avatarId = avatarId;
    _myRole = role;
    _myNickname = nickname;
    _runTitle = runTitle;
    _sessionNumber = sessionNumber;
    pausedNotifier.value = false;
    _myCharacterName =
        role == MpRole.main ? 'The Paradox' : 'The Cultist';
    _error = null;
    _connectReason = MpConnectReason.seeking;

    // Stop any stale radios before switching the service ID — a
    // lingering advertiser/discovery loop under the classic ID would
    // fight the Paradox seek.
    await _link.stopAll();
    _link.setServiceId(MpLink.serviceIdParadox);
    _sync.setIdentity(
      role: role,
      nickname: nickname,
      character: _myCharacterName,
    );
    _sync.setSessionMeta(
      mode: MpMode.paradox,
      avatarId: avatarId,
      runTitle: runTitle,
      sessionNumber: sessionNumber,
    );
    _recovery.setSessionInfo(role: role, nickname: nickname);

    // Initialize run state — same shape as classic MP (main + coop).
    final charName = _myCharacterName;
    final g = _runProvider.gungeoneerByName(charName);
    if (role == MpRole.sidekick) {
      _preSidekickRun = _runProvider.runState;
      unawaited(MpStore.savePreSidekickRun(_preSidekickRun!));
    } else if (_runProvider.runState.main.character != null) {
      unawaited(MpStore.saveSoloRunBackup(_runProvider.runState));
    }
    if (g != null) {
      _runProvider.startNewRun(g);
      if (_runProvider.runState.coop == null) {
        _runProvider.startCoopPlayer(g);
      }
    }

    final granted = await _link.requestPermissions();
    if (!granted) {
      _setPhase(MpPhase.permissionDenied);
      return;
    }

    _setPhase(MpPhase.connecting);
    if (role == MpRole.main) {
      await _link.startAdvertising(nickname);
    } else {
      await _link.startDiscovery(
        nickname,
        autoConnect: const AutoConnectModeAny(),
      );
    }
  }

  /// Pause the session — both sides see the overlay. Either player
  /// may pause or resume. Radios keep polling at pause cadence so a
  /// break (phones out of range) re-heals silently.
  Future<void> pause() async => _applyPaused(true, notifyPeer: true);

  /// Resume — sends MpResume when connected; if the link is down the
  /// caller shows "Connecting…" and [startParadox]/recovery keeps
  /// seeking; the resume is flushed in [_onSyncPeerConnected].
  Future<void> resume() async => _applyPaused(false, notifyPeer: true);

  void _applyPaused(bool paused, {required bool notifyPeer}) {
    if (pausedNotifier.value == paused) return;
    pausedNotifier.value = paused;
    if (paused) {
      // Bank the live segment — the run timer freezes while paused.
      if (_runStartMs != 0) {
        _runAccumMs += DateTime.now().millisecondsSinceEpoch - _runStartMs;
        _runStartMs = 0;
      }
    } else if (_runAccumMs > 0 || _runStartMs != 0) {
      // Resume the live segment — only when a run is actually armed
      // (accum>0 means banked time exists, startMs!=0 can't happen
      // here since banking zeroes it, kept for belt-and-braces).
      _runStartMs = DateTime.now().millisecondsSinceEpoch;
    }
    unawaited(MpStore.savePauseState(
      paused: paused,
      runStartMs: _runStartMs,
      runAccumMs: _runAccumMs,
    ));
    if (paused) {
      // Pause cadence — both sides poll every ~6s.
      _link.setDiscoveryCadence(
        const Duration(seconds: 6),
        const Duration(seconds: 6),
      );
    }
    if (notifyPeer) {
      if (paused) {
        unawaited(_sync.sendPause());
      } else {
        unawaited(_sync.sendResume());
      }
      // Main rebroadcasts meta so late joiners land correctly.
      if (_myRole == MpRole.main && _mode == MpMode.paradox) {
        unawaited(_sync.sendSessionMeta(paused: paused));
      }
    }
    notifyListeners();
  }

  // ── Run timer ──────────────────────────────────────────────────
  int _runStartMs = 0;
  int _runAccumMs = 0;

  /// Milliseconds of unpaused run time. 0 until the run starts.
  int get runElapsedMs {
    if (_runStartMs == 0) return _runAccumMs;
    return _runAccumMs + DateTime.now().millisecondsSinceEpoch - _runStartMs;
  }

  void _startRunTimer() {
    // Arm only when idle — reconnects must not erase unbanked elapsed
    // time, and a paused run stays frozen (startMs stays 0).
    if (_runStartMs == 0 && !pausedNotifier.value) {
      _runStartMs = DateTime.now().millisecondsSinceEpoch;
    }
  }

  // ── Chat / surprise API ────────────────────────────────────────

  static int _chatSeq = 0;
  String _newChatId() =>
      '${DateTime.now().millisecondsSinceEpoch}_${_chatSeq++}';

  /// Send a chat line. When disconnected the message is queued and
  /// flushed on reconnect — nothing is silently dropped.
  Future<void> sendChatMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final msg = MpChat(id: _newChatId(), from: _myNickname, text: trimmed);
    logEvent(MpEvent.chat(from: _myNickname, text: trimmed, mine: true));
    chatMessages.add(msg);
    if (chatMessages.length > _maxChatHistory) chatMessages.removeAt(0);
    onChatMessage?.call(msg, true);
    if (_link.isConnected) {
      await _sync.sendChat(msg);
    } else {
      _queuedChat.add(msg);
    }
    notifyListeners();
  }

  Future<void> sendSurprise({
    required String preset,
    String text = '',
    String spriteKey = '',
    String fx = '',
  }) async {
    if (!_link.isConnected) return;
    logEvent(MpEvent.event(
        kind: 'surprise',
        from: _myNickname,
        text: text.isEmpty ? preset : text,
        mine: true));
    await _sync.sendSurprise(
        MpSurprise(preset: preset, text: text, spriteKey: spriteKey, fx: fx));
  }

  void markChatRead() {
    if (unreadChat.value != 0) unreadChat.value = 0;
  }

  // ── Peer inventory editing (co-op trust) ───────────────────────

  Future<void> sendPeerRemove({required String kind, required String name}) =>
      _sync.sendPeerEdit(MpPeerEdit(op: 'remove', kind: kind, name: name));

  Future<void> sendPeerClear() =>
      _sync.sendPeerEdit(const MpPeerEdit(op: 'clear'));

  /// Main → both sides: leave the pre-run lobby and begin the run.
  Future<void> sendStartRun() async {
    _startRunTimer();
    await _sync.sendStartRun();
  }

  /// Re-check permissions and resume the connection flow if granted.
  /// Called from the permission-denied screen's RETRY button — avoids
  /// forcing the user back to the lobby after granting permissions in
  /// OS settings.
  Future<void> recheckPermissionsAndResume() async {
    if (_connectReason == MpConnectReason.hosting) {
      final granted = await _link.requestPermissions();
      if (!granted) {
        _setPhase(MpPhase.permissionDenied);
        return;
      }
      _setPhase(MpPhase.connecting);
      await _link.startAdvertising(_myNickname);
    } else if (_connectReason == MpConnectReason.joining) {
      final granted = await _link.requestPermissions();
      if (!granted) {
        _setPhase(MpPhase.permissionDenied);
        return;
      }
      _setPhase(MpPhase.connecting);
      await _link.startDiscovery(
        _myNickname,
        autoConnect: const AutoConnectModeAny(),
      );
    } else {
      // Unknown state — can't resume. Fall back to cancel.
      cancel();
    }
  }

  // ── Session lifecycle ──────────────────────────────────────────

  /// User cancels — notify peer, tear down, restore pre-MP run
  /// (Sidekick). Sends [MpEndRun] to the peer so they know to tear
  /// down too. This covers both "End Run" and "Leave MP" — either
  /// way, the peer needs to know we're gone.
  Future<void> cancel() async {
    if (_tearingDown) return;
    _tearingDown = true;
    try {
      // Notify peer before tearing down the transport.
      if (_link.isConnected) {
        try {
          await _link.sendMessage(const MpEndRun());
        } catch (_) {}
      }
      final saved = await MpStore.load();
      final savedSoloBackup = saved?.soloRunBackup;
      final savedPreSidekick = saved?.preSidekickRun;
      await _teardown();
      if (_myRole == MpRole.sidekick) {
        // Sidekick: restore pre-MP run. Use restoreEntireRunState
        // (not restoreRunScopeState) so the coop slot is also
        // cleared — the Sidekick's MP coop slot should not persist.
        final pre = _preSidekickRun ?? savedPreSidekick;
        if (pre != null) {
          _runProvider.restoreEntireRunState(pre);
          _preSidekickRun = null;
        }
        // Don't also restore soloBackup — preSidekickRun IS the
        // solo backup for the Sidekick.
      } else if (_myRole == MpRole.main) {
        _runProvider.endCoopPlayer();
        // Main: restore solo backup if it exists.
        if (savedSoloBackup != null) {
          _runProvider.restoreEntireRunState(savedSoloBackup);
        }
      }
      _myRole = null;
      _peerNickname = null;
      _peerCharacterName = null;
      _demoMode = false;
      _resetParadoxState();
      _setPhase(MpPhase.idle);
    } finally {
      _tearingDown = false;
    }
  }

  /// Clear all Paradox-scoped state on teardown — returns the
  /// transport to the classic service id so a subsequent classic
  /// session works normally.
  void _resetParadoxState() {
    _mode = MpMode.classic;
    _avatarId = '';
    _peerAvatarId = '';
    _runTitle = '';
    _sessionNumber = 0;
    pausedNotifier.value = false;
    _runStartMs = 0;
    _runAccumMs = 0;
    wipeSessionActivity();
    _link.setServiceId(MpLink.serviceIdClassic);
    _sync.setSessionMeta(mode: MpMode.classic, avatarId: '', runTitle: '', sessionNumber: 0);
  }

  /// Peer sent [MpEndRun] — tear down our MP session without
  /// sending another MpEndRun (avoids infinite loop). The peer
  /// already ended the run on their side; we just need to clean
  /// up our transport and restore our local state.
  Future<void> _onPeerEndRun() async {
    if (_tearingDown) return;
    _tearingDown = true;
    logEvent(MpEvent.event(
        kind: 'system',
        from: _peerNickname ?? 'Peer',
        text: 'Partner ended the run',
        mine: false));
    try {
      final saved = await MpStore.load();
      final savedSoloBackup = saved?.soloRunBackup;
      final savedPreSidekick = saved?.preSidekickRun;
      await _teardown();
      if (_myRole == MpRole.sidekick) {
        final pre = _preSidekickRun ?? savedPreSidekick;
        if (pre != null) {
          _runProvider.restoreEntireRunState(pre);
          _preSidekickRun = null;
        }
      } else if (_myRole == MpRole.main) {
        // B2 fix: Main must also clean up the coop slot when the
        // peer (Sidekick) ends the run. Without this, the Main's
        // coop slot lingers after the Sidekick leaves.
        _runProvider.endCoopPlayer();
        if (savedSoloBackup != null) {
          _runProvider.restoreEntireRunState(savedSoloBackup);
        }
      }
      _myRole = null;
      _peerNickname = null;
      _peerCharacterName = null;
      _demoMode = false;
      _resetParadoxState();
      _setPhase(MpPhase.idle);
    } finally {
      _tearingDown = false;
    }
  }

  /// User drops peer — stay in disconnected, can reconnect.
  Future<void> disconnect() async {
    await _link.disconnectPeer();
    _sync.onDisconnected();
    _setPhase(MpPhase.disconnected);
    _connectReason = MpConnectReason.reconnecting;
    _recovery.onPeerDisconnected();
  }

  /// Manual retry (rarely needed — auto-reconnect handles it).
  Future<void> reconnect() async {
    if (_myRole == null) return;
    _connectReason = MpConnectReason.reconnecting;
    _setPhase(MpPhase.connecting);
    // Reset the sync handshake state so the new connection does
    // a fresh hello + snapshot exchange. Without this, _sync may
    // believe it already handshaked and skip the hello.
    _sync.onDisconnected();
    await _link.stopAll();
    await Future.delayed(const Duration(milliseconds: radioCooldownMs));
    if (_myRole == MpRole.main) {
      await _link.startAdvertising(_myNickname);
    } else {
      await _link.startDiscovery(
        _myNickname,
        autoConnect: const AutoConnectModeAny(),
      );
    }
  }

  /// End run + tear down (called from settings). Now equivalent to
  /// [cancel] since cancel() sends MpEndRun to the peer.
  Future<void> notifyEndRunAndCancel() async => cancel();

  // ── Gift/request API (delegated to MpSync) ─────────────────────

  Future<void> sendGift({required String kind, required String name}) =>
      _sync.sendGift(kind: kind, name: name);
  Future<void> sendAddToPeer({required String kind, required String name}) =>
      _sync.sendAddToPeer(kind: kind, name: name);
  Future<String?> sendRequest({required String kind, required String name}) =>
      _sync.sendRequest(kind: kind, name: name);
  Future<void> respondToPendingRequest(bool approved) =>
      _sync.respondToPendingRequest(approved);

  // ── Dice/emote API (delegated to MpSync) ───────────────────────

  Future<void> sendDiceChallenge(String challengerName) =>
      _sync.sendDiceChallenge(challengerName);
  Future<void> sendDiceAccept() => _sync.sendDiceAccept();
  Future<void> sendDiceDecline() => _sync.sendDiceDecline();
  Future<void> sendDiceCancel() => _sync.sendDiceCancel();
  Future<void> sendDiceResult(int score, List<int> dice) =>
      _sync.sendDiceResult(score, dice);
  Future<void> sendEmote(String action) async {
    logEvent(MpEvent.event(
        kind: 'emote', from: _myNickname, text: action, mine: true));
    await _sync.sendEmote(action);
  }

  // ── App-kill restore ───────────────────────────────────────────

  Future<void> tryRestorePersistedSession() async {
    await _recovery.tryRestore();
  }

  // ── ProxyProvider support ──────────────────────────────────────

  void updateRunProvider(RunProvider newProvider) {
    if (identical(newProvider, _runProvider)) return;
    _runProvider.removeListener(_onRunChanged);
    _runProvider = newProvider;
    // Cache UI callbacks before disposing old sync so we can
    // re-apply them to the new sync instance.
    final cachedOnDiceChallenge = _sync.onDiceChallenge;
    final cachedOnDiceAccept = _sync.onDiceAccept;
    final cachedOnDiceDecline = _sync.onDiceDecline;
    final cachedOnDiceCancel = _sync.onDiceCancel;
    final cachedOnDiceResult = _sync.onDiceResult;
    final cachedOnEmote = _sync.onEmote;
    final cachedOnGiftReceived = _sync.onGiftReceived;
    _sync.dispose();
    _recovery.dispose();
    _sync = MpSync(
      _link,
      newProvider,
      onPeerConnected: _onSyncPeerConnected,
      onPeerMetadata: _onSyncPeerMetadata,
    );
    _sync.onSyncError = _onSyncError;
    _sync.onPeerEndRun = _onPeerEndRun;
    _sync.onPeerHello = _onPeerHello;
    _sync.onSessionMeta = _onSessionMeta;
    _sync.onPauseChanged = _onPeerPauseChanged;
    _sync.onStartRun = () => onStartRun?.call();
    _sync.onChat = _onChatReceived;
    _sync.onSurprise = (s) {
      logEvent(MpEvent.event(
          kind: 'surprise',
          from: _peerNickname ?? 'Peer',
          text: s.text.isEmpty ? s.preset : s.text,
          mine: false));
      onSurpriseReceived?.call(s);
    };
    _sync.setSessionMeta(
      mode: _mode,
      avatarId: _avatarId,
      runTitle: _runTitle,
      sessionNumber: _sessionNumber,
    );
    // Re-apply cached UI callbacks.
    _sync.onDiceChallenge = cachedOnDiceChallenge;
    _sync.onDiceAccept = cachedOnDiceAccept;
    _sync.onDiceDecline = cachedOnDiceDecline;
    _sync.onDiceCancel = cachedOnDiceCancel;
    _sync.onDiceResult = cachedOnDiceResult;
    _sync.onEmote = cachedOnEmote;
    _sync.onGiftReceived = cachedOnGiftReceived;
    _sync.setIdentity(
      role: _myRole ?? MpRole.main,
      nickname: _myNickname,
      character: _myCharacterName,
    );
    newProvider.addListener(_onRunChanged);
    _recovery = MpRecovery(
      _link,
      newProvider,
      onRestoreSession: _onRecoveryRestore,
    );
    _recovery.setSessionInfo(
      role: _myRole,
      nickname: _myNickname,
    );
  }

  // ── App lifecycle ──────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_phase == MpPhase.disconnected) {
        // Both Main and Sidekick need recovery restart on resume.
        // The Sidekick path is handled by _recovery.onAppResumed.
        // Main needs advertising restarted if the OS paused it.
        if (!_demoMode) _recovery.onAppResumed();
        if (_myRole == MpRole.main) {
          unawaited(_link.stopAll().then((_) {
            Future.delayed(const Duration(milliseconds: radioCooldownMs), () {
              if (_phase != MpPhase.disconnected) return;
              unawaited(_link.startAdvertising(_myNickname));
            });
          }));
        }
      } else if (_phase == MpPhase.connected) {
        _link.restartHeartbeat();
      } else if (_phase == MpPhase.connecting) {
        // Restart the connect attempt — the OS may have throttled the
        // timers while in the background, freezing the seek.
        if (_myRole == MpRole.main) {
          unawaited(_link.startAdvertising(_myNickname));
        } else if (_myRole == MpRole.sidekick) {
          unawaited(_link.startDiscovery(
            _myNickname,
            autoConnect: const AutoConnectModeAny(),
          ));
        }
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────

  void _setPhase(MpPhase newPhase) {
    if (_phase == newPhase) return;
    _phase = newPhase;
    // Both modes now seek forever — the 45s connect timeout was the
    // "reconnecting is a hassle" complaint. The user cancels
    // explicitly; recovery keeps the radios cycling indefinitely.
    notifyListeners();
  }

  Future<void> _teardown() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    _recovery.cancel();
    _sync.restorePendingGifts();
    await _link.stopAll();
    await MpForegroundService.stop();
    await MpStore.clear();
  }

  Future<void> _persistSession() async {
    if (_demoMode) return; // demo sessions never persist/restore
    await MpStore.saveSession(
      role: _myRole ?? MpRole.main,
      nickname: _myNickname,
      character: _myCharacterName,
      mode: _mode,
      avatarId: _avatarId,
      runTitle: _runTitle,
      sessionNumber: _sessionNumber,
    );
  }

  void _startSaveTimer() {
    _saveTimer?.cancel();
    _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_phase != MpPhase.connected) return;
      unawaited(MpStore.saveRunState(_runProvider.runState));
    });
  }

  // ── Convenience getters for UI ─────────────────────────────────

  bool get isConnected => _phase == MpPhase.connected;
  bool get isActive => _phase != MpPhase.idle;

  // ── Test support ───────────────────────────────────────────────

  /// Test-only: set phase + reason + error without going through the
  /// full Nearby Connections flow. Used by widget tests to render
  /// specific states (connecting, error, etc.).
  @visibleForTesting
  void setPhaseForTest(MpPhase phase, MpConnectReason reason, {String? error}) {
    _phase = phase;
    _connectReason = reason;
    if (error != null) _error = error;
    notifyListeners();
  }

  // ── Cleanup ────────────────────────────────────────────────────

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveTimer?.cancel();
    _runProvider.removeListener(_onRunChanged);
    _sync.dispose();
    _recovery.dispose();
    unawaited(_link.dispose());
    reconnectNotifier.dispose();
    reconnectSuccessNotifier.dispose();
    super.dispose();
  }
}
