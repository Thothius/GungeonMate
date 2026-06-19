import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../services/goop_talk_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gungeoneer.dart';
import '../models/multiplayer_messages.dart';
import '../models/run_state.dart';
import '../providers/run_provider.dart';
import '../services/multiplayer_session.dart';
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
      MaterialPageRoute(
        builder: (_) => const MultiplayerConnectScreen(),
      ),
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

  String _formatTimestamp(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Colors.amberAccent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              fontSize: 11.5,
              color: Colors.white70,
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
      MaterialPageRoute(
        builder: (_) => const CharacterSelectScreen.multiplayerPick(),
      ),
    );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid 4-digit Connection PIN from the host!'),
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
      MaterialPageRoute(
        builder: (_) => const MultiplayerConnectScreen(),
      ),
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
            Expanded(child: Text('Bluetooth + Wi-Fi')),
          ],
        ),
        content: const Text(
          'Multiplayer pairs devices over Bluetooth and Wi-Fi (Nearby Devices).\n\n'
          'TIP: For the best speed and range, put BOTH phones on the SAME Wi-Fi network before connecting. The session will use Wi-Fi automatically when available and fall back to Bluetooth otherwise.\n\n'
          'No data is sent to servers — connections are device-to-device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiplayer'),
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
              // Role selection
              _SectionLabel('CHOOSE ROLE'),
              const SizedBox(height: 12),
              _RoleCard(
                title: 'Main Player',
                subtitle: 'Host the session, pick any Gungeoneer',
                icon: Icons.person,
                selected: _isMain,
                onTap: () => setState(() => _isMain = true),
              ),
              const SizedBox(height: 10),
              _RoleCard(
                title: 'Sidekick',
                subtitle: 'Join a host, play as The Cultist',
                icon: Icons.bluetooth_searching,
                selected: !_isMain,
                onTap: () => setState(() => _isMain = false),
              ),
              const SizedBox(height: 24),
              // Character / Nickname section
              _SectionLabel(_isMain ? 'YOUR CHARACTER' : 'SIDEKICK'),
              const SizedBox(height: 12),
              if (_isMain)
                _CharacterPickerTile(
                  character: _selectedCharacter,
                  onTap: _pickCharacter,
                )
              else
                _ForcedCultistTile(cultist: cultist),
              const SizedBox(height: 20),
              // Nickname field
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
              if (!_isMain) ...[
                const SizedBox(height: 20),
                const _SectionLabel('CONNECTION PIN'),
                const SizedBox(height: 8),
                TextField(
                  controller: _pinCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Enter 4-digit code from host',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              // Start button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  icon: Icon(_isMain ? Icons.campaign : Icons.bluetooth),
                  label: Text(_isMain ? 'Start Hosting' : 'Find Host'),
                  onPressed: _start,
                ),
              ),
              if (_savedSessions.isNotEmpty) ...[
                const SizedBox(height: 36),
                _SectionLabel('LOAD SAVED SESSION'),
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
                                      color: isMainSession ? Colors.cyanAccent : Colors.purpleAccent,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
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
                                    Text(
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
                                      child: Text(
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
                                          Text(
                                            '+${runState.coolness.toStringAsFixed(0)}',
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.local_fire_department_rounded, size: 10, color: Colors.redAccent),
                                          const SizedBox(width: 2),
                                          Text(
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
                                Text(
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
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.help_outline_rounded, size: 14, color: Colors.amberAccent),
                          SizedBox(width: 6),
                          Text(
                            'How to Play',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
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
                const Row(
                  children: [
                    Icon(Icons.help_outline_rounded, color: Colors.amberAccent, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'MULTIPLAYER GUIDE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: Colors.white,
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
            _buildGuideStep('1. Set up Player Roles 👥', 'Decide who will be the HOST (Main Player) and who will be the SIDEKICK (Co-op Cultist). The Host controls character selection, while the Sidekick plays as the Cultist.'),
            _buildGuideStep('2. Verify Wireless Settings 📡', 'Ensure BOTH devices have Bluetooth and Wi-Fi toggled ON. For optimal speed, put both phones on the SAME local Wi-Fi router network!'),
            _buildGuideStep('3. Host starts Advertising 🏁', 'The HOST picks their character, enters their Nickname, sets the Role to "Main Player", and taps "Start Advertising". A 4-digit PIN code will be generated.'),
            _buildGuideStep('4. Sidekick Enters PIN 🔑', 'The SIDEKICK enters their Nickname, selects "Sidekick", types the HOST\'s 4-digit PIN, and taps "Start Discovery". They will immediately connect device-to-device!'),
            const SizedBox(height: 32),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.amberAccent),
                label: const Text(
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
                child: Text(
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
              const Text(
                'LOBBY RECONNECTION PROTOCOL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white54,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This restores the run with ${p1Char} & ${p2Char}. Choose your connection role to resume matchmaking:',
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
                            const Text(
                              'HOST AS MAIN PLAYER',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.cyanAccent,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
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
                            const Text(
                              'JOIN AS SIDEKICK CLIENT',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.purpleAccent,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
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
              child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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
        title: const Text('Delete Save?'),
        content: Text('Are you sure you want to delete the saved session "${session.sessionName}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteSavedSession(session.sessionId);
            },
            child: const Text('Delete'),
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
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              if (character != null)
                AvatarAura(
                  size: 48,
                  borderRadius: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      character!.icon,
                      width: 48,
                      height: 48,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.person, size: 32),
                    ),
                  ),
                )
              else
                Container(
                  width: 48,
                  height: 48,
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
                    Text(
                      character?.name ?? 'Pick a Gungeoneer',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: character != null ? Colors.white : Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
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
    );
  }
}

class _ForcedCultistTile extends StatelessWidget {
  final Gungeoneer? cultist;
  const _ForcedCultistTile({required this.cultist});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              cultist?.icon ?? '',
              width: 48,
              height: 48,
              errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 32),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cultist?.name ?? 'The Cultist',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiplayer Connection'),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              RotationTransition(
                turns: _spinCtrl,
                child: Icon(
                  icon,
                  size: 64,
                  color: status == MpStatus.connected
                      ? Colors.green
                      : Colors.lightBlueAccent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              if (session.myRole == MpRole.main && (status == MpStatus.searching || status == MpStatus.handshaking) && session.pinCode != null) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.35), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'CONNECTION PIN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        session.pinCode!,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.amber,
                          letterSpacing: 4.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
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
                FilledButton(
                  onPressed: () {
                    // Navigate to active run - go back to home which shows inventory
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('Go to Run'),
                ),
              ],
              if (status == MpStatus.permissionDenied) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        await session.cancel();
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () => openAppSettings(),
                      icon: const Icon(Icons.settings, size: 18),
                      label: const Text('Open Settings'),
                    ),
                  ],
                ),
              ],
              if (status == MpStatus.error ||
                  status == MpStatus.disconnected) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        await session.cancel();
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      icon: const Icon(Icons.bluetooth_searching, size: 18),
                      label: const Text('Reconnect'),
                      onPressed: session.canReconnect
                          ? () => session.reconnect()
                          : null,
                    ),
                  ],
                ),
                if (status == MpStatus.disconnected) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Your run is preserved. The peer should still be on '
                    'the multiplayer screen — Reconnect re-pairs over '
                    'Wi-Fi / Bluetooth without losing inventory.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
              
              // LIVE MONOSPACE DIAGNOSTIC CONSOLE
              const SizedBox(height: 36),
              Row(
                children: [
                  const Icon(Icons.terminal_rounded, size: 14, color: Colors.greenAccent),
                  const SizedBox(width: 6),
                  Text(
                    'CONNECTION DIAGNOSTIC CONSOLE',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Colors.greenAccent.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
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
                      child: Text(
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
          ),
        ),
      ),
    );
  }
}
