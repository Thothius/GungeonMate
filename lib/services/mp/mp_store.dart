import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/multiplayer_messages.dart';
import '../../models/run_state.dart';

/// Single persistence mechanism for MP sessions.
///
/// All writes are best-effort — a SharedPrefs failure never crashes
/// the session lifecycle.
class MpStore {
  static const _kSessionActive = 'mp.session_active';
  static const _kRole = 'mp.role';
  static const _kNickname = 'mp.nickname';
  static const _kCharacter = 'mp.character';
  static const _kActiveRun = 'mp.active_run';
  static const _kPreSidekickRun = 'mp.pre_sidekick_run';
  static const _kSoloRunBackup = 'mp.solo_run_backup';
  // v2 — Paradox session identity + pause/timer state.
  static const _kMode = 'mp.mode';
  static const _kPaused = 'mp.paused_v2';
  static const _kRunTitle = 'mp.run_title';
  static const _kSessionNumber = 'mp.session_number';
  static const _kAvatarId = 'mp.avatar_id';
  static const _kRunStartMs = 'mp.run_start_ms';
  static const _kRunAccumMs = 'mp.run_accum_ms';

  // ── Old keys (v1) to clean up on first launch ──────────────────
  static const _oldKeys = [
    'mp_last_role',
    'mp_last_character',
    'mp_last_nickname',
    'mp_session_active',
    'mp_last_pin',
    'mp_pre_sidekick',
    'mp_paused',
    'saved_mp_sessions',
    'mp.is_paired',
    'mp.pair_id',
  ];

  static Future<void> cleanupOldKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in _oldKeys) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }

  // ── Session identity ───────────────────────────────────────────

  static Future<void> saveSession({
    required MpRole role,
    required String nickname,
    required String character,
    MpMode mode = MpMode.classic,
    String avatarId = '',
    String runTitle = '',
    int sessionNumber = 0,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kSessionActive, true);
      await prefs.setString(_kRole, role.name);
      await prefs.setString(_kNickname, nickname);
      await prefs.setString(_kCharacter, character);
      await prefs.setString(_kMode, mode.name);
      await prefs.setString(_kAvatarId, avatarId);
      await prefs.setString(_kRunTitle, runTitle);
      await prefs.setInt(_kSessionNumber, sessionNumber);
    } catch (_) {}
  }

  /// Persist pause/timer state — written on every pause/resume so an
  /// app-kill during a break restores the overlay on relaunch.
  static Future<void> savePauseState({
    required bool paused,
    int? runStartMs,
    int? runAccumMs,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPaused, paused);
      if (runStartMs != null) await prefs.setInt(_kRunStartMs, runStartMs);
      if (runAccumMs != null) await prefs.setInt(_kRunAccumMs, runAccumMs);
    } catch (_) {}
  }

  /// Paradox session counter — starts at 0, incremented per new run.
  static Future<int> nextParadoxSessionNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final n = prefs.getInt('paradox.session_counter') ?? 0;
      await prefs.setInt('paradox.session_counter', n + 1);
      return n;
    } catch (_) {
      return 0;
    }
  }

  // ── Run state (throttled) ──────────────────────────────────────

  static int _lastRunSaveMs = 0;
  static const int _minSaveIntervalMs = 4000;

  static Future<void> saveRunState(RunState state, {bool force = false}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!force && now - _lastRunSaveMs < _minSaveIntervalMs) return;
    _lastRunSaveMs = now;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kActiveRun, json.encode(state.toJson()));
    } catch (_) {}
  }

  static Future<void> savePreSidekickRun(RunState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPreSidekickRun, json.encode(state.toJson()));
    } catch (_) {}
  }

  static Future<void> saveSoloRunBackup(RunState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSoloRunBackup, json.encode(state.toJson()));
    } catch (_) {}
  }

  // ── Load ───────────────────────────────────────────────────────

  static Future<MpSavedSession?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final active = prefs.getBool(_kSessionActive) ?? false;
      if (!active) return null;

      final roleName = prefs.getString(_kRole);
      if (roleName == null) return null;
      final role = MpRole.values.firstWhere(
        (r) => r.name == roleName,
        orElse: () => MpRole.main,
      );

      final nickname = prefs.getString(_kNickname) ?? 'Player';
      final character = prefs.getString(_kCharacter) ?? '';

      RunState? runState;
      final runJson = prefs.getString(_kActiveRun);
      if (runJson != null) {
        try {
          runState = RunState.fromJson(json.decode(runJson));
        } catch (_) {}
      }

      RunState? preSidekickRun;
      final preJson = prefs.getString(_kPreSidekickRun);
      if (preJson != null) {
        try {
          preSidekickRun = RunState.fromJson(json.decode(preJson));
        } catch (_) {}
      }

      RunState? soloRunBackup;
      final soloJson = prefs.getString(_kSoloRunBackup);
      if (soloJson != null) {
        try {
          soloRunBackup = RunState.fromJson(json.decode(soloJson));
        } catch (_) {}
      }

      final modeName = prefs.getString(_kMode);
      return MpSavedSession(
        role: role,
        nickname: nickname,
        character: character,
        runState: runState,
        preSidekickRun: preSidekickRun,
        soloRunBackup: soloRunBackup,
        mode: MpMode.values.firstWhere(
          (m) => m.name == modeName,
          orElse: () => MpMode.classic,
        ),
        paused: prefs.getBool(_kPaused) ?? false,
        avatarId: prefs.getString(_kAvatarId) ?? '',
        runTitle: prefs.getString(_kRunTitle) ?? '',
        sessionNumber: prefs.getInt(_kSessionNumber) ?? 0,
        runStartMs: prefs.getInt(_kRunStartMs) ?? 0,
        runAccumMs: prefs.getInt(_kRunAccumMs) ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Clear ──────────────────────────────────────────────────────

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kSessionActive);
      await prefs.remove(_kRole);
      await prefs.remove(_kNickname);
      await prefs.remove(_kCharacter);
      await prefs.remove(_kActiveRun);
      await prefs.remove(_kPreSidekickRun);
      await prefs.remove(_kSoloRunBackup);
      await prefs.remove(_kMode);
      await prefs.remove(_kPaused);
      await prefs.remove(_kRunTitle);
      await prefs.remove(_kSessionNumber);
      await prefs.remove(_kAvatarId);
      await prefs.remove(_kRunStartMs);
      await prefs.remove(_kRunAccumMs);
      _lastRunSaveMs = 0;
    } catch (_) {}
  }

  static Future<void> clearSoloRunBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kSoloRunBackup);
    } catch (_) {}
  }
}

/// A persisted MP session — everything needed to silently restore
/// on app restart after an app-kill.
class MpSavedSession {
  final MpRole role;
  final String nickname;
  final String character;
  final RunState? runState;
  final RunState? preSidekickRun;
  final RunState? soloRunBackup;
  final MpMode mode;
  final bool paused;
  final String avatarId;
  final String runTitle;
  final int sessionNumber;
  final int runStartMs;
  final int runAccumMs;

  const MpSavedSession({
    required this.role,
    required this.nickname,
    required this.character,
    this.runState,
    this.preSidekickRun,
    this.soloRunBackup,
    this.mode = MpMode.classic,
    this.paused = false,
    this.avatarId = '',
    this.runTitle = '',
    this.sessionNumber = 0,
    this.runStartMs = 0,
    this.runAccumMs = 0,
  });
}
