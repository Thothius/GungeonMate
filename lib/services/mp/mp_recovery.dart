import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/multiplayer_messages.dart';
import '../../models/run_state.dart';
import '../../providers/run_provider.dart';
import 'mp_transport.dart';
import 'mp_store.dart';

/// Owns the "peer came back" and "app was killed" logic.
///
/// On peer disconnect: keeps Main advertising, starts Sidekick discovery
/// loop with adaptive cadence. Never gives up while the run is alive.
///
/// On app kill: MpStore has saved state every 5s. On restart, silently
/// restores the run and re-enters the session.
class MpRecovery {
  /// Nearby Connections radio cooldown — see [MpSession.radioCooldownMs].
  /// Duplicated locally to avoid a circular import.
  static const int _radioCooldownMs = 800;

  final MpTransport _link;
  final RunProvider _runProvider;
  void Function({
    required MpRole role,
    required String nickname,
    required String character,
    RunState? preSidekickRun,
    bool paused,
    String avatarId,
    String runTitle,
    int sessionNumber,
    int runStartMs,
    int runAccumMs,
  })
  onRestoreSession;

  /// Fired with the seconds elapsed since the peer dropped — once at 0
  /// on disconnect, then on each cadence tick. Lets the session surface
  /// an escalating "peer may have left" hint; recovery itself never
  /// gives up (by design), so this is informational only.
  void Function(int elapsedSec)? onDisconnectElapsed;

  Timer? _cadenceTimer;
  int _disconnectMs = 0;
  bool _active = false;
  @visibleForTesting
  bool get isActive => _active;

  /// Current role state — set by MpSession.
  MpRole? _role;
  String _nickname = 'Player';

  MpRecovery(this._link, this._runProvider, {required this.onRestoreSession});

  void setSessionInfo({MpRole? role, required String nickname}) {
    _role = role;
    _nickname = nickname;
  }

  // ── On peer disconnect ─────────────────────────────────────────

  void onPeerDisconnected() {
    if (_active) return;
    _active = true;
    _disconnectMs = DateTime.now().millisecondsSinceEpoch;
    onDisconnectElapsed?.call(0);
    _startCadenceTimer();

    final role = _role;
    if (role == null) return;

    if (role == MpRole.main) {
      if (!_link.isAdvertising) {
        unawaited(_link.startAdvertising(_nickname));
      }
    } else {
      _startSidekickDiscovery();
    }
  }

  void onPeerReconnected() {
    _active = false;
    _cadenceTimer?.cancel();
    _cadenceTimer = null;
    _disconnectMs = 0;
  }

  void onAppResumed() {
    if (!_active) return;
    _disconnectMs = DateTime.now().millisecondsSinceEpoch;
    _applyCadence();
    if (_role == MpRole.sidekick) {
      unawaited(
        _link.stopAll().then((_) {
          Future.delayed(const Duration(milliseconds: _radioCooldownMs), () {
            if (!_active) return;
            _startSidekickDiscovery();
          });
        }),
      );
    }
  }

  void cancel() {
    _active = false;
    _cadenceTimer?.cancel();
    _cadenceTimer = null;
  }

  // ── Cadence management ─────────────────────────────────────────

  void _startCadenceTimer() {
    _cadenceTimer?.cancel();
    _cadenceTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!_active) return;
      _applyCadence();
    });
  }

  void _applyCadence() {
    final elapsedSec =
        (DateTime.now().millisecondsSinceEpoch - _disconnectMs) ~/ 1000;
    onDisconnectElapsed?.call(elapsedSec);

    final role = _role;
    if (role != MpRole.sidekick) return;

    // Adaptive discovery cadence — aggressive at first, relaxing over
    // time but never dropping below 50% duty cycle. The old 5s/15s
    // (25% duty) caused "can't reconnect" reports, so we keep duty >= 50%.
    Duration on, off;
    if (elapsedSec < 60) {
      // First minute: 3s on / 1s off (75% duty) — catch quick reconnects.
      on = const Duration(seconds: 3);
      off = const Duration(seconds: 1);
    } else if (elapsedSec < 300) {
      // 1–5 min: 5s on / 5s off (50% duty) — steady scanning.
      on = const Duration(seconds: 5);
      off = const Duration(seconds: 5);
    } else {
      // 5+ min: 7s on / 7s off (50% duty) — same duty cycle but longer
      // periods reduce radio thrashing and battery drain on long
      // disconnects. Still always listening half the time.
      on = const Duration(seconds: 7);
      off = const Duration(seconds: 7);
    }
    _link.setDiscoveryCadence(on, off);
    // Ensure discovery is actually running — if the initial
    // startDiscovery failed or the OS stopped it while backgrounded,
    // the cadence timer alone won't restart it.
    if (!_link.isDiscovering && _active) {
      _startSidekickDiscovery();
    }
  }

  void _startSidekickDiscovery() {
    unawaited(
      _link.startDiscovery(_nickname, autoConnect: const AutoConnectModeAny()),
    );
  }

  // ── App-kill restore ───────────────────────────────────────────

  Future<void> tryRestore() async {
    try {
      final saved = await MpStore.load();
      if (saved == null) return;

      if (saved.runState != null) {
        _runProvider.restoreEntireRunState(saved.runState!);
      }

      final currentChar = _runProvider.runState.selectedCharacter;
      if (currentChar != null &&
          currentChar.name != saved.character &&
          saved.runState == null) {
        await MpStore.saveSoloRunBackup(_runProvider.runState);
      }

      // Main restore: if the run state's main character doesn't
      // match the saved MP character (e.g. RunProvider's own
      // _loadSavedRun loaded a solo run), fix the main slot with
      // a fresh starting loadout for the correct character — but
      // preserve the coop slot and all shared state. Previously
      // this called startNewRun() which destroyed the entire
      // RunState, and then added a hardcoded Cultist placeholder
      // that got broadcast as the Sidekick's character.
      if (saved.role == MpRole.main && saved.character.isNotEmpty) {
        final mainChar = _runProvider.runState.main.character;
        if (mainChar == null || mainChar.name != saved.character) {
          final g = _runProvider.gungeoneerByName(saved.character);
          if (g != null) {
            // Reset main to correct character with fresh starting
            // loadout, preserving coop + shared state.
            _runProvider.resetMainToCharacter(g);
          }
        }
        // Do NOT add a Cultist placeholder for the coop slot.
        // The coop slot will be populated by the Sidekick's
        // snapshot on reconnect. A placeholder would get
        // broadcast as the Sidekick's character and corrupt
        // the peer's view.
      }

      // Sidekick restore: ensure the coop slot has the Sidekick's
      // character. If the saved run state didn't include a coop
      // slot (e.g. save timer didn't fire before app kill), the
      // coop slot is null. Without it, the Sidekick broadcasts an
      // empty snapshot and the Main player can't see them.
      // Use the saved character name (not a hardcoded Cultist) so
      // the Sidekick gets their actual character back.
      if (saved.role == MpRole.sidekick) {
        final charName =
            saved.character.isNotEmpty ? saved.character : 'The Cultist';
        final g = _runProvider.gungeoneerByName(charName);
        if (g != null) {
          // Ensure coop slot has the Sidekick's character.
          if (_runProvider.runState.coop == null) {
            _runProvider.startCoopPlayer(g);
          }
          // Ensure main slot is non-null to prevent blank screen.
          // The Sidekick's main slot represents the Main Player's
          // data and will be overwritten by Main's snapshot on
          // reconnect. But if saved.runState was null (save timer
          // didn't fire), main is null → ActiveRunScreen shows
          // blank/particles-only. Use the Sidekick's own character
          // as a temporary placeholder — same as startAsSidekick
          // does on initial join.
          if (_runProvider.runState.main.character == null) {
            _runProvider.startNewRun(g);
            // startNewRun wipes coop — re-add it.
            _runProvider.startCoopPlayer(g);
          }
        }
      }

      onRestoreSession(
        role: saved.role,
        nickname: saved.nickname,
        character: saved.character,
        preSidekickRun: saved.preSidekickRun,
        paused: saved.paused,
        avatarId: saved.avatarId,
        runTitle: saved.runTitle,
        sessionNumber: saved.sessionNumber,
        runStartMs: saved.runStartMs,
        runAccumMs: saved.runAccumMs,
      );
    } catch (_) {
      // Non-fatal — fall through to fresh start.
    }
  }

  void dispose() {
    _cadenceTimer?.cancel();
    _cadenceTimer = null;
  }
}
