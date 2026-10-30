part of '../mp_session.dart';

// Link/sync event handlers extracted from MpSession (Phase 5l) — same
// library. Abstract members are requirements satisfied by MpSession.

mixin _MpSessionHandlers on ChangeNotifier {
  // --- Required members provided by MpSession ---
  RunProvider get _runProvider;
  MpSync get _sync;
  MpRecovery get _recovery;
  MpTransport get _link;
  MpPhase get _phase;
  set _connectReason(MpConnectReason v);
  set _error(String? v);
  MpRole? get _myRole;
  set _myRole(MpRole? v);
  set _myNickname(String v);
  set _myCharacterName(String v);
  String? get _peerNickname;
  set _peerNickname(String? v);
  set _peerCharacterName(String? v);
  set _peerAvatarId(String v);
  MpMode get _mode;
  set _mode(MpMode v);
  set _avatarId(String v);
  String get _runTitle;
  set _runTitle(String v);
  int get _sessionNumber;
  set _sessionNumber(int v);
  set _runAccumMs(int v);
  set _runStartMs(int v);
  bool get _tearingDown;
  set _preSidekickRun(RunState? v);
  List<MpChat> get _queuedChat;
  List<MpChat> get chatMessages;
  ValueNotifier<bool> get pausedNotifier;
  ValueNotifier<int> get unreadChat;
  ValueNotifier<bool> get reconnectNotifier;
  ValueNotifier<bool> get reconnectSuccessNotifier;
  ValueNotifier<int> get disconnectElapsedSec;
  bool get _peerGoneHinted;
  set _peerGoneHinted(bool v);
  void Function(MpChat, bool)? get onChatMessage;
  void Function()? get onStartRun;
  void Function(MpSurprise)? get onSurpriseReceived;
  void _setPhase(MpPhase p);
  void _applyPaused(bool paused, {required bool notifyPeer});
  Future<void> _persistSession();
  void _startSaveTimer();
  void logEvent(MpEvent e);
  Future<void> _onPeerEndRun();

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
      logEvent(
        MpEvent.event(
          kind: 'surprise',
          from: _peerNickname ?? 'Peer',
          text: s.text.isEmpty ? s.preset : s.text,
          mine: false,
        ),
      );
      onSurpriseReceived?.call(s);
    };

    _recovery.onRestoreSession = _onRecoveryRestore;
    // Elapsed-time feed → notifier + one-shot "may have left" hint.
    // Recovery itself never gives up (by design) — the hint is purely
    // informational so the user isn't staring at "Reconnecting…"
    // forever without context.
    _recovery.onDisconnectElapsed = (sec) {
      disconnectElapsedSec.value = sec;
      if (sec >= 120 && !_peerGoneHinted) {
        _peerGoneHinted = true;
        logEvent(
          MpEvent.event(
            kind: 'system',
            from: _peerNickname ?? 'Peer',
            text:
                'Still searching — your partner may have left. '
                'The session keeps retrying; you can also cancel.',
            mine: false,
          ),
        );
      }
    };
    _runProvider.addListener(_onRunChanged);
  }

  void _onRunChanged() => _sync.onRunChanged();

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
    logEvent(
      MpEvent.event(
        kind: 'system',
        from: _peerNickname ?? 'Peer',
        text: 'Connection lost — reconnecting…',
        mine: false,
      ),
    );
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

  void _onSyncPeerConnected(MpRole peerRole) {
    // Hello succeeded — transition to connected.
    _setPhase(MpPhase.connected);
    disconnectElapsedSec.value = 0;
    _peerGoneHinted = false;
    logEvent(
      MpEvent.event(
        kind: 'system',
        from: _peerNickname ?? 'Peer',
        text: 'Connected',
        mine: false,
      ),
    );
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
      unawaited(
        _sync.sendSessionMeta(
          runTitle: _runTitle,
          sessionNumber: _sessionNumber,
          paused: pausedNotifier.value,
        ),
      );
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
    if (chatMessages.length > MpSession._maxChatHistory) {
      chatMessages.removeAt(0);
    }
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
      unawaited(
        _link.startDiscovery(nickname, autoConnect: const AutoConnectModeAny()),
      );
    }
  }
}
