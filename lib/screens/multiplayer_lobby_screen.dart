import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../services/app_theme.dart';
import '../services/goop_talk_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gungeoneer.dart';
import '../models/multiplayer_messages.dart';
import '../models/run_state.dart';
import '../providers/run_provider.dart';
import '../services/multiplayer_session.dart';
import '../services/haptics.dart';
import '../utils/asset_paths.dart';
import '../utils/fast_route.dart';
import '../utils/responsive.dart';
import '../widgets/avatar_aura.dart';
import 'character_select_screen.dart';
import 'home_screen.dart';

/// Multiplayer lobby — choose role (Main or Sidekick), pick character
/// (Main only; Sidekick is forced Cultist), enter nickname, then start
/// Bluetooth advertising (Main) or discovery (Sidekick).
class MultiplayerLobbyScreen extends StatefulWidget {
  const MultiplayerLobbyScreen({super.key});

  @override
  State<MultiplayerLobbyScreen> createState() => _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState extends State<MultiplayerLobbyScreen> {
  static const _nickPrefsKey = 'mp.nickname';

  final _pageController = PageController();
  final _nickCtrl = TextEditingController(text: 'Player');
  final _pinCtrl = TextEditingController();
  bool _isMain = true; // true = Main Player, false = Sidekick
  Gungeoneer? _selectedCharacter;
  List<SavedMpSession> _savedSessions = [];
  bool _sessionsCollapsed = true;

  @override
  void initState() {
    super.initState();
    _hydrateNickname();
    _loadSavedSessions();
  }

  Future<void> _loadSavedSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('saved_mp_sessions') ?? [];
      final List<SavedMpSession> sessions = [];
      for (final s in list) {
        try {
          sessions.add(SavedMpSession.fromJson(json.decode(s)));
        } catch (_) {}
      }
      // Sort: newest saved first
      sessions.sort((a, b) => b.savedAtMs.compareTo(a.savedAtMs));
      if (mounted) {
        setState(() => _savedSessions = sessions);
      }
    } catch (_) {}
  }

  Future<void> _deleteSavedSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('saved_mp_sessions') ?? [];
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
      await prefs.setStringList('saved_mp_sessions', updatedList);
      await _loadSavedSessions();
    } catch (_) {}
  }

  Future<void> _loadSession(SavedMpSession saved, MpRole role) async {
    final session = context.read<MultiplayerSession>();
    await session.loadSavedSession(saved, overrideRole: role);
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      fastRoute(const MultiplayerConnectScreen()),
    );
  }

  String _formatDuration(int ms) {
    final sec = (ms / 1000).floor();
    final min = (sec / 60).floor();
    final hrs = (min / 60).floor();
    
    if (hrs > 0) {
      return '${hrs}h ${min % 60}m';
    } else if (min > 0) {
      return '${min}m ${sec % 60}s';
    } else {
      return '${sec}s';
    }
  }

  Future<void> _hydrateNickname() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_nickPrefsKey);
      if (saved != null && saved.isNotEmpty && mounted) {
        _nickCtrl.text = saved;
      }
    } catch (_) {
      // Non-fatal; just stick with default 'Player'.
    }
  }

  Future<void> _saveNickname(String name) async {
    final v = name.trim();
    if (v.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nickPrefsKey, v);
    } catch (_) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nickCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Widget _buildGuideStep(String title, String body) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoopText(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: AppTheme.flair.primary,
            ),
          ),
          const SizedBox(height: 4),
          GoopText(
            body,
            style: TextStyle(
              fontSize: 11.5,
              color: AppTheme.flair.secondary.withValues(alpha: 0.7),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCharacter() async {
    final picked = await Navigator.push<Gungeoneer>(
      context,
      fastRoute(const CharacterSelectScreen.multiplayerPick()),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => _selectedCharacter = picked);
    }
  }

  Future<void> _start() async {
    final session = context.read<MultiplayerSession>();
    final nickname = _nickCtrl.text.trim();
    if (nickname.isEmpty) return;
    unawaited(_saveNickname(nickname));

    // Show permission rationale before requesting
    final shouldProceed = await _showPermissionRationale();
    if (!shouldProceed || !mounted) return;

    if (_isMain) {
      if (_selectedCharacter == null) {
        // Prompt to pick character
        await _pickCharacter();
        if (_selectedCharacter == null) return;
      }
      await session.startAsMain(
        nickname: nickname,
        character: _selectedCharacter!,
      );
    } else {
      final pinCode = _pinCtrl.text.trim();
      if (pinCode.length != 4 || int.tryParse(pinCode) == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: GoopText('Please enter a valid 4-digit Connection PIN from the host!'),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      await session.startAsSidekick(nickname: nickname, pinCode: pinCode);
    }

    if (!mounted) return;
    // Navigate to searching/connected screen
    await Navigator.pushReplacement(
      context,
      fastRoute(const MultiplayerConnectScreen()),
    );
  }

  Future<bool> _showPermissionRationale() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi, color: Colors.lightBlueAccent),
            SizedBox(width: 12),
            Expanded(child: GoopText('Bluetooth + Wi-Fi')),
          ],
        ),
        content: const GoopText(
          'Multiplayer pairs devices over Bluetooth and Wi-Fi (Nearby Devices).\n\n'
          'TIP: For the best speed and range, put BOTH phones on the SAME Wi-Fi network before connecting. The session will use Wi-Fi automatically when available and fall back to Bluetooth otherwise.\n\n'
          'No data is sent to servers — connections are device-to-device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const GoopText('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const GoopText('Continue'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final runProvider = context.watch<RunProvider>();
    final cultist = runProvider.gungeoneerByName('The Cultist') ??
        runProvider.gungeoneerByName('Cultist');
    final sf = Responsive.factor(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const GoopText('Multiplayer'),
        centerTitle: true,
      ),
      body: PageView(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        children: [
          // Page 1: Active Lobby Setup Form
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Nickname field — at the very top
              _SectionLabel('NICKNAME'),
              const SizedBox(height: 8),
              TextField(
                controller: _nickCtrl,
                maxLength: 24,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Enter your nickname',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Role selection — 1x2 grid
              _SectionLabel('CHOOSE ROLE'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _RoleCard(
                      title: 'Main',
                      subtitle: 'Host the session',
                      icon: Icons.person,
                      selected: _isMain,
                      onTap: () {
                        Haptics.selection();
                        setState(() => _isMain = true);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _RoleCard(
                      title: 'Sidekick',
                      subtitle: 'Join a host',
                      icon: Icons.bluetooth_searching,
                      selected: !_isMain,
                      onTap: () {
                        Haptics.selection();
                        setState(() => _isMain = false);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Character section
              _SectionLabel(_isMain ? 'YOUR CHARACTER' : 'SIDEKICK'),
              const SizedBox(height: 12),
              if (_isMain)
                _CharacterPickerTile(
                  character: _selectedCharacter,
                  onTap: () {
                    Haptics.selection();
                    _pickCharacter();
                  },
                )
              else
                _ForcedCultistTile(cultist: cultist),
              const SizedBox(height: 20),
              // Connection PIN — always visible, locked when Main
              _SectionLabel('CONNECTION PIN'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _PinField(
                      controller: _pinCtrl,
                      locked: _isMain,
                    ),
                  ),
                ],
              ),
              if (_isMain)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: GoopText(
                    'PIN is auto-generated when you start hosting.',
                    style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.4)),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: GoopText(
                    'Enter the 4-digit PIN from the host.',
                    style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.4)),
                  ),
                ),
              const SizedBox(height: 32),
              // Start button
              SizedBox(
                width: double.infinity,
                height: 54 * sf,
                child: FilledButton.icon(
                  icon: Icon(_isMain ? Icons.campaign : Icons.bluetooth),
                  label: GoopText(_isMain ? 'Start Hosting' : 'Find Host'),
                  onPressed: () {
                    Haptics.selection();
                    _start();
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Local Sidekick — quick access to simulated co-op
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.smart_toy_outlined, size: 18),
                  label: const GoopText('Add Local Sidekick (Solo Co-op)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.flair.secondary,
                    side: BorderSide(color: AppTheme.flair.secondary, width: 1),
                  ),
                  onPressed: () {
                    Haptics.selection();
                    _pinCtrl.text = '0000';
                    setState(() => _isMain = false);
                    _start();
                  },
                ),
              ),
              if (_savedSessions.isNotEmpty) ...[
                const SizedBox(height: 36),
                InkWell(
                  onTap: () {
                    Haptics.selection();
                    setState(() => _sessionsCollapsed = !_sessionsCollapsed);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        _SectionLabel('LOAD SAVED SESSION'),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_savedSessions.length}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        const Spacer(),
                        AnimatedRotation(
                          turns: _sessionsCollapsed ? 0 : 0.5,
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            Icons.expand_more_rounded,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!_sessionsCollapsed) ...[
                  const SizedBox(height: 12),
                  ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _savedSessions.length,
                  itemBuilder: (context, idx) {
                    final s = _savedSessions[idx];
                    final runState = RunState.fromJson(s.runStateJson);
                    final isMainSession = s.savedByRole == MpRole.main;
                    
                    final mainEquip = [...runState.main.guns.map((g) => g.name), ...runState.main.items.map((i) => i.name)];
                    final coopEquip = runState.coop != null ? [...runState.coop!.guns.map((g) => g.name), ...runState.coop!.items.map((i) => i.name)] : <String>[];
                    
                    final p1Char = runState.main.character?.name ?? 'P1';
                    final p2Char = runState.coop?.character?.name ?? 'P2';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161619),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () {
                            _confirmLoadSession(context, s);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: Icon, Session Name, and Trash button
                                Row(
                                  children: [
                                    Icon(
                                      Icons.history_edu_rounded,
                                      size: 16,
                                      color: isMainSession ? AppTheme.flair.primary : AppTheme.flair.secondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: GoopText(
                                        s.sessionName.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    GoopText(
                                      '${_formatDuration(s.durationMs)} PLAYED',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      onPressed: () {
                                        _confirmDeleteSession(context, s);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Subtitle row: Characters and Quick Stats
                                Row(
                                  children: [
                                    Expanded(
                                      child: GoopText(
                                        'CO-OP: $p1Char (Host) ✕ $p2Char (Sidekick)',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white70,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.04),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.ac_unit_rounded, size: 10, color: Colors.cyanAccent),
                                          const SizedBox(width: 2),
                                          GoopText(
                                            '+${runState.coolness.toStringAsFixed(0)}',
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.local_fire_department_rounded, size: 10, color: Colors.redAccent),
                                          const SizedBox(width: 2),
                                          GoopText(
                                            '+${runState.curse.toStringAsFixed(0)}',
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.redAccent),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Footer row: Equipment details
                                GoopText(
                                  'P1 Items: ${mainEquip.length} · P2 Items: ${coopEquip.length}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                ], // end if (!_sessionsCollapsed)
              ],
            const SizedBox(height: 32),
            Center(
              child: InkWell(
                onTap: () {
                  _pageController.animateToPage(
                    1,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.help_outline_rounded, size: 14, color: AppTheme.flair.primary),
                          const SizedBox(width: 6),
                          GoopText(
                            'How to Play',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.flair.secondary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: Colors.white38,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),

    // Page 2: Helpful Multiplayer Guide & How-to
    SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.help_outline_rounded, color: AppTheme.flair.primary, size: 24),
                    const SizedBox(width: 10),
                    GoopText(
                      'MULTIPLAYER GUIDE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: AppTheme.flair.secondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white60),
                  onPressed: () {
                    _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 24),
            _buildGuideStep('1. Connect Wi-Fi', 'Put both phones on the SAME Wi-Fi network. Enable Bluetooth on both.'),
            _buildGuideStep('2. Host: Pick Main', 'One phone selects "Main", picks a character, enters a nickname, and taps "Start Hosting". A 4-digit PIN appears.'),
            _buildGuideStep('3. Sidekick: Enter PIN', 'Other phone selects "Sidekick", enters nickname, types the host\'s 4-digit PIN, taps "Find Host".'),
            _buildGuideStep('4. Play!', 'Devices pair automatically. Host controls the run. Sidekick plays as The Cultist. Items can be gifted between players.'),
            const SizedBox(height: 20),
            _buildGuideStep('Local Sidekick', 'Want to try co-op solo? Enter PIN 0000 as Sidekick to spawn a simulated AI partner on this device.'),
            const SizedBox(height: 32),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.amberAccent),
                label: const GoopText(
                  'Swipe Up or Tap to go back',
                  style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
        ],
      ),
    );
  }

  void _confirmLoadSession(BuildContext context, SavedMpSession session) {
    final runState = RunState.fromJson(session.runStateJson);
    final p1Char = runState.main.character?.name ?? 'Main';
    final p2Char = runState.coop?.character?.name ?? 'Sidekick';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B1B1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white10),
          ),
          title: Row(
            children: [
              const Icon(Icons.wifi_protected_setup_rounded, color: Colors.amber, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: GoopText(
                  'RESUME: ${session.sessionName.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GoopText(
                'LOBBY RECONNECTION PROTOCOL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white54,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              GoopText(
                'This restores the run with $p1Char & $p2Char. Choose your connection role to resume matchmaking:',
                style: const TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.3),
              ),
              const SizedBox(height: 16),
              // Option 1: Host as Main
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  _loadSession(session, MpRole.main);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.cyan.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.cyanAccent, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const GoopText(
                              'HOST AS MAIN PLAYER',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.cyanAccent,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            GoopText(
                              'You will host and advertise this run as $p1Char.',
                              style: const TextStyle(fontSize: 11, color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Option 2: Join as Sidekick
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  _loadSession(session, MpRole.sidekick);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.handshake_rounded, color: Colors.purpleAccent, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const GoopText(
                              'JOIN AS SIDEKICK CLIENT',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.purpleAccent,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            GoopText(
                              'You will search for the Host to join this run as $p2Char.',
                              style: const TextStyle(fontSize: 11, color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const GoopText('CANCEL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteSession(BuildContext context, SavedMpSession session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const GoopText('Delete Save?'),
        content: GoopText('Are you sure you want to delete the saved session "${session.sessionName}"? This cannot be undone.', maxLines: 3, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const GoopText('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteSavedSession(session.sessionId);
            },
            child: const GoopText('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return GoopText(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
        color: Colors.white.withValues(alpha: 0.65),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = selected ? Colors.amber : Colors.white70;
    return Material(
      color: selected
          ? Colors.amber.withValues(alpha: 0.1)
          : Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GoopText(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.amber : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    GoopText(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: Colors.amber, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _CharacterPickerTile extends StatelessWidget {
  final Gungeoneer? character;
  final VoidCallback onTap;

  const _CharacterPickerTile({required this.character, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final animPath = character != null
        ? gungeoneerAnimatedCardPath(character!.name)
        : '';
    final gifPath = character != null
        ? gungeoneerGifPath(character!.name)
        : '';

    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              if (character != null)
                AvatarAura(
                  size: 56,
                  borderRadius: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: animPath.isNotEmpty
                          ? Image.asset(
                              animPath,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => gifPath.isNotEmpty
                                  ? Image.asset(
                                      gifPath,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) =>
                                          Image.asset(
                                        character!.icon,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.person, size: 32),
                                      ),
                                    )
                                  : Image.asset(
                                      character!.icon,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.person, size: 32),
                                    ),
                            )
                          : Image.asset(
                              character!.icon,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.person, size: 32),
                            ),
                    ),
                  ),
                )
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, size: 28),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GoopText(
                      character?.name ?? 'Pick a Gungeoneer',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: character != null ? Colors.white : Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    GoopText(
                      character != null ? 'Tap to change' : 'Required for Main',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _ForcedCultistTile extends StatelessWidget {
  final Gungeoneer? cultist;
  const _ForcedCultistTile({required this.cultist});

  @override
  Widget build(BuildContext context) {
    final animPath = cultist != null
        ? gungeoneerAnimatedCardPath(cultist!.name)
        : '';
    final gifPath = cultist != null
        ? gungeoneerGifPath(cultist!.name)
        : '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          AvatarAura(
            size: 56,
            borderRadius: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: animPath.isNotEmpty
                    ? Image.asset(
                        animPath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => gifPath.isNotEmpty
                            ? Image.asset(
                                gifPath,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  cultist?.icon ?? '',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.person, size: 32),
                                ),
                              )
                            : Image.asset(
                                cultist?.icon ?? '',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.person, size: 32),
                              ),
                      )
                    : Image.asset(
                        cultist?.icon ?? '',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.person, size: 32),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GoopText(
                  cultist?.name ?? 'The Cultist',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                GoopText(
                  'Sidekicks always play as The Cultist',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_outline, color: Colors.white.withValues(alpha: 0.4)),
        ],
      ),
    );
  }
}

/// Screen shown after clicking Start — shows searching/connected states
class MultiplayerConnectScreen extends StatefulWidget {
  const MultiplayerConnectScreen({super.key});

  @override
  State<MultiplayerConnectScreen> createState() => _MultiplayerConnectScreenState();
}

class _MultiplayerConnectScreenState extends State<MultiplayerConnectScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  late final ScrollController _logScrollCtrl;
  bool _consoleCollapsed = true;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _logScrollCtrl = ScrollController();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _logScrollCtrl.dispose();
    super.dispose();
  }

  void _updateSpin(bool isSpinning) {
    if (isSpinning) {
      if (!_spinCtrl.isAnimating) _spinCtrl.repeat();
    } else {
      _spinCtrl.stop();
      _spinCtrl.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<MultiplayerSession>();
    final status = session.status;

    // Auto-scroll log console to bottom when new logs are added
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollCtrl.hasClients) {
        _logScrollCtrl.jumpTo(_logScrollCtrl.position.maxScrollExtent);
      }
    });

    String title;
    String subtitle;
    IconData icon;
    bool isSpinning = false;

    switch (status) {
      case MpStatus.searching:
        title = session.myRole == MpRole.main
            ? 'Waiting for Sidekick'
            : 'Looking for Host';
        subtitle = session.myRole == MpRole.main
            ? 'Advertising via Wi-Fi & Bluetooth…'
            : 'Scanning for nearby games…';
        icon = Icons.bluetooth_searching;
        isSpinning = true;
      case MpStatus.handshaking:
        title = 'Connecting';
        subtitle = 'Exchanging data with peer...';
        icon = Icons.sync;
        isSpinning = true;
      case MpStatus.connected:
        title = 'Connected!';
        subtitle = 'Run synced with ${session.peerNickname ?? 'peer'}';
        icon = Icons.check_circle;
      case MpStatus.disconnected:
        title = 'Disconnected';
        subtitle = 'Connection lost. Retry?';
        icon = Icons.bluetooth_disabled;
      case MpStatus.permissionDenied:
        title = 'Permission Denied';
        subtitle = session.error ?? 'Bluetooth permissions required';
        icon = Icons.error_outline;
      case MpStatus.error:
        title = 'Error';
        subtitle = session.error ?? 'Something went wrong';
        icon = Icons.error_outline;
      default:
        title = 'Ready';
        subtitle = 'Press Start to begin';
        icon = Icons.bluetooth;
    }

    _updateSpin(isSpinning);

    final myChar = session.lastCharacter;
    final myNick = session.lastNickname;
    final peerCharName = session.peerCharacterName;
    final peerNick = session.peerNickname;

    Gungeoneer? peerChar;
    if (peerCharName != null && peerCharName.isNotEmpty) {
      try {
        final rp = context.read<RunProvider>();
        peerChar = rp.gungeoneerByName(peerCharName);
      } catch (_) {}
    }

    final accent = status == MpStatus.connected
        ? const Color(0xFF00E676)
        : Colors.lightBlueAccent;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const GoopText('Multiplayer Connection'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            await session.cancel();
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Animated gungeoneer portraits
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ConnectPortrait(
                      character: myChar,
                      nickname: myNick,
                      slotLabel: session.myRole == MpRole.main ? 'P1 · MAIN' : 'P2 · SIDEKICK',
                      accent: session.myRole == MpRole.main ? Colors.cyanAccent : Colors.purpleAccent,
                      isMe: true,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RotationTransition(
                          turns: _spinCtrl,
                          child: Icon(
                            icon,
                            size: 32,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GoopText(
                          status == MpStatus.connected ? 'LINKED' : isSpinning ? 'SEARCHING' : '—',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: accent.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    _ConnectPortrait(
                      character: peerChar,
                      nickname: peerNick ?? 'Waiting…',
                      slotLabel: session.myRole == MpRole.main ? 'P2 · SIDEKICK' : 'P1 · MAIN',
                      accent: session.myRole == MpRole.main ? Colors.purpleAccent : Colors.cyanAccent,
                      isMe: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GoopText(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
              const SizedBox(height: 8),
              GoopText(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              if (session.myRole == MpRole.main && (status == MpStatus.searching || status == MpStatus.handshaking) && session.pinCode != null) ...[
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      GoopText(
                        'CONNECTION PIN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: Colors.cyanAccent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      GoopText(
                        session.pinCode!,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 6.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GoopText(
                        'Share this code with your Sidekick!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (status == MpStatus.connected) ...[
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow, size: 24),
                    label: const GoopText(
                      'Go to Run',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                    onPressed: () {
                      Haptics.selection();
                      Navigator.pushAndRemoveUntil(
                        context,
                        fastRoute(const HomeScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ),
              ],
              if (status == MpStatus.permissionDenied) ...[
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      await session.cancel();
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const GoopText('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => openAppSettings(),
                    icon: const Icon(Icons.settings, size: 22),
                    label: const GoopText('Open Settings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
              if (status == MpStatus.error ||
                  status == MpStatus.disconnected) ...[
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      await session.cancel();
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const GoopText('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.key, size: 22),
                    label: const GoopText('RE-PAIR', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    onPressed: session.canReconnect
                        ? () {
                            Haptics.selection();
                            session.requestReconnectHub();
                          }
                        : null,
                  ),
                ),
                if (status == MpStatus.disconnected) ...[
                  const SizedBox(height: 12),
                  GoopText(
                    'Your run is preserved. The peer should still be on '
                    'the multiplayer screen — RE-PAIR opens the Reconnection '
                    'Hub to re-pair over Wi-Fi / Bluetooth without losing inventory.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],

              // Collapsible diagnostic console
              const SizedBox(height: 32),
              InkWell(
                onTap: () {
                  Haptics.selection();
                  setState(() => _consoleCollapsed = !_consoleCollapsed);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.terminal_rounded, size: 14, color: Colors.greenAccent),
                      const SizedBox(width: 6),
                      GoopText(
                        'DIAGNOSTIC CONSOLE',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: Colors.greenAccent.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${session.connectionLogs.length}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      const Spacer(),
                      AnimatedRotation(
                        turns: _consoleCollapsed ? 0 : 0.5,
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          Icons.expand_more_rounded,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!_consoleCollapsed) ...[
                const SizedBox(height: 8),
                Container(
                  height: 180,
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: ListView.builder(
                    controller: _logScrollCtrl,
                    itemCount: session.connectionLogs.length,
                    itemBuilder: (context, idx) {
                      final log = session.connectionLogs[idx];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: GoopText(
                          log,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 10,
                            height: 1.2,
                            color: Colors.greenAccent,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated gungeoneer portrait for the connect screen.
class _ConnectPortrait extends StatelessWidget {
  final Gungeoneer? character;
  final String nickname;
  final String slotLabel;
  final Color accent;
  final bool isMe;

  const _ConnectPortrait({
    required this.character,
    required this.nickname,
    required this.slotLabel,
    required this.accent,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final charName = character?.name ?? 'Unknown';
    final animPath = character != null
        ? gungeoneerAnimatedCardPath(character!.name)
        : '';
    final gifPath = character != null
        ? gungeoneerGifPath(character!.name)
        : '';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: accent.withValues(alpha: 0.4), width: 1),
          ),
          child: GoopText(
            slotLabel,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: accent,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 90,
            height: 110,
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accent.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (animPath.isNotEmpty)
                  Image.asset(
                    animPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => gifPath.isNotEmpty
                        ? Image.asset(
                            gifPath,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _placeholder(accent),
                          )
                        : _placeholder(accent),
                  )
                else if (gifPath.isNotEmpty)
                  Image.asset(
                    gifPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _placeholder(accent),
                  )
                else
                  _placeholder(accent),
                if (isMe)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const GoopText(
                        'YOU',
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        GoopText(
          charName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 1),
        GoopText(
          nickname,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: accent,
          ),
        ),
      ],
    );
  }

  Widget _placeholder(Color accent) {
    return Icon(
      Icons.person,
      size: 36,
      color: accent.withValues(alpha: 0.4),
    );
  }
}

/// Custom 4-digit PIN entry field with individual digit boxes.
/// When [locked] is true, shows a read-only locked state.
class _PinField extends StatefulWidget {
  final TextEditingController controller;
  final bool locked;

  const _PinField({required this.controller, this.locked = false});

  @override
  State<_PinField> createState() => _PinFieldState();
}

class _PinFieldState extends State<_PinField> {
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sync);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && !widget.locked) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
    if (mounted) setState(() {});
  }

  void _sync() {
    if (mounted) setState(() {});
  }

  void _showOverlay() {
    _removeOverlay();
    _overlay = OverlayEntry(
      builder: (context) => _PinKeypad(
        onKey: (digit) {
          final text = widget.controller.text;
          if (text.length < 4) {
            widget.controller.text = text + digit;
          }
        },
        onBackspace: () {
          final text = widget.controller.text;
          if (text.isNotEmpty) {
            widget.controller.text = text.substring(0, text.length - 1);
          }
        },
        onDone: () {
          _focusNode.unfocus();
        },
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final digits = List.generate(4, (i) => i < text.length ? text[i] : '');

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: widget.locked ? null : () => _focusNode.requestFocus(),
        child: AbsorbPointer(
          absorbing: !widget.locked,
          child: Focus(
            focusNode: _focusNode,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (i) {
                final isFilled = digits[i].isNotEmpty;
                final isCurrent = !widget.locked && _focusNode.hasFocus && i == text.length;

                return Container(
                  width: 56,
                  height: 64,
                  decoration: BoxDecoration(
                    color: widget.locked
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.locked
                          ? Colors.white.withValues(alpha: 0.08)
                          : isCurrent
                              ? Colors.amber.withValues(alpha: 0.6)
                              : isFilled
                                  ? Colors.amber.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.15),
                      width: isCurrent ? 2.0 : 1.5,
                    ),
                  ),
                  child: Center(
                    child: widget.locked
                        ? Icon(Icons.lock, size: 18, color: Colors.white.withValues(alpha: 0.2))
                        : GoopText(
                            digits[i],
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: isFilled ? Colors.amber : Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinKeypad extends StatelessWidget {
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final VoidCallback onDone;

  const _PinKeypad({
    required this.onKey,
    required this.onBackspace,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          decoration: BoxDecoration(
            color: AppTheme.flair.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const GoopText(
                    'ENTER PIN',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white54, letterSpacing: 1),
                  ),
                  TextButton(
                    onPressed: onDone,
                    child: const GoopText('Done', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final row in [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
              ]) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final d in row) _keyButton(d),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(width: 72),
                  _keyButton('0'),
                  SizedBox(
                    width: 72,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: onBackspace,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Icon(Icons.backspace_outlined, size: 20, color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _keyButton(String digit) {
    return SizedBox(
      width: 72,
      height: 56,
      child: FilledButton(
        onPressed: () => onKey(digit),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: GoopText(
          digit,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
