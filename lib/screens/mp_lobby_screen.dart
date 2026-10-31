import '../theme/tokens.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gungeoneer.dart';
import '../providers/run_provider.dart';
import '../services/app_theme.dart';
import '../services/goop_talk_engine.dart';
import '../services/haptics.dart';
import '../services/mp_session.dart';
import '../services/paired_partners_store.dart';
import '../utils/asset_paths.dart';
import '../utils/fast_route.dart';
import '../utils/responsive.dart';
import '../widgets/avatar_aura.dart';
import '../widgets/paradox/avatar_frame.dart';
import '../widgets/paradox/avatar_picker.dart' show showAvatarPicker;
import '../widgets/particles/ambient_glow.dart';
import 'character_select_screen.dart';
import 'mp_connect_screen.dart';

/// MP Lobby — the breach point where two gungeoneers meet.
///
/// **Flow:**
/// 1. User sees their character preview card + nickname field.
/// 2. Below nickname: a role toggle — MAIN or SIDEKICK.
/// 3. MAIN → "HOST GAME" button (can't pick The Cultist).
/// 4. SIDEKICK → "JOIN GAME" button.
/// No PINs — joining is PINless.
class MpLobbyScreen extends StatefulWidget {
  const MpLobbyScreen({super.key});

  @override
  State<MpLobbyScreen> createState() => _MpLobbyScreenState();
}

/// Which role the user is selecting in the lobby.
enum _LobbyRole { main, sidekick }

class _MpLobbyScreenState extends State<MpLobbyScreen> {
  final _nickCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  Gungeoneer? _selectedChar;
  String _avatarId = kAvatarIds.first;
  _LobbyRole _role = _LobbyRole.main;
  int _stage = 0; // 0 role · 1 gungeoneer (main only) · 2 identity

  @override
  void initState() {
    super.initState();
    _loadNickname();
  }

  Future<void> _loadNickname() async {
    final saved = await PairedPartnersStore.loadNickname();
    if (mounted && saved != null && saved.isNotEmpty) {
      _nickCtrl.text = saved;
    }
  }

  @override
  void dispose() {
    _nickCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  /// The character currently shown in the preview. Falls back through
  /// the selection → last played → first available → stub.
  /// When MAIN role is selected, The Cultist is skipped (Main can't
  /// play Cultist), so the preview never shows a character the user
  /// can't actually host with.
  /// When SIDEKICK role is selected, The Cultist is the only option —
  /// Sidekick always plays The Cultist.
  Gungeoneer get _defaultChar {
    final rp = context.read<RunProvider>();
    final isMain = _role == _LobbyRole.main;
    // Sidekick is always The Cultist — no other option.
    if (!isMain) {
      return rp.gungeoneerByName('The Cultist') ??
          (rp.allGungeoneers.isNotEmpty
              ? rp.allGungeoneers.first
              : Gungeoneer(name: 'The Cultist'));
    }
    // If the user explicitly picked a character, use it.
    if (_selectedChar != null) return _selectedChar!;
    // Try last played — skip Cultist for Main.
    final last = rp.lastPlayedCharacter;
    if (last != null && last.name != 'The Cultist') return last;
    // First non-Cultist gungeoneer for Main.
    return rp.allGungeoneers.firstWhere(
      (g) => g.name != 'The Cultist',
      orElse: () => rp.allGungeoneers.isNotEmpty
          ? rp.allGungeoneers.first
          : Gungeoneer(name: 'The Marine'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    final flair = AppTheme.flair;

    return Scaffold(
      backgroundColor: flair.scaffold.withValues(alpha: 0.3),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const GoopText(
          'MULTIPLAYER',
          style: TextStyle(
            fontSize: FontSizes.titleSmall,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        leading: IconButton(
          tooltip: _stage == 0 ? 'Leave lobby' : 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (_stage > 0) {
              setState(() => _stage -= (_role == _LobbyRole.sidekick ? 2 : 1));
              return;
            }
            final session = context.read<MpSession>();
            if (session.isActive) session.cancel();
            Navigator.of(context).maybePop();
          },
        ),
      ),
      body: Stack(
        children: [
          // Atmospheric particle background
          Positioned.fill(
            child: IgnorePointer(
              child: AmbientGlow(
                primary: flair.primary.withValues(alpha: 0.06),
                secondary: flair.secondary.withValues(alpha: 0.04),
              ),
            ),
          ),
          // Main content
          SafeArea(child: _stageBody(sf, flair)),
        ],
      ),
    );
  }

  // ── Staged flow — bold, clean, simple ───────────────────────────
  // 0 ROLE → 1 GUNGEONEER (main only) → 2 IDENTITY. Sidekick skips
  // stage 1 (always The Cultist).

  Widget _stageBody(double sf, ThemeFlair flair) {
    final title = switch (_stage) {
      0 => 'WHO ARE YOU?',
      1 => 'PICK YOUR GUNGEONEER',
      _ => 'IDENTITY',
    };
    final widgets = switch (_stage) {
      0 => _roleStage(sf, flair),
      1 => _gungeoneerStage(sf, flair),
      _ => _identityStage(sf, flair),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Padding(
        key: ValueKey(_stage),
        padding: EdgeInsets.symmetric(horizontal: 20 * sf, vertical: 8 * sf),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._stageHeader(title, sf),
            // Paradox-style: content centered in the remaining space,
            // still scrollable when it can't fit (keyboard, small screens).
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: c.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: widgets,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _stageHeader(String title, double sf) {
    // Progress dots — 3 steps; sidekick's identity stage still shows
    // dot 3 (it logically skipped step 2, that's honest feedback).
    return [
      SizedBox(height: 12 * sf),
      Row(
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= _stage
                      ? AppTheme.flair.primary
                      : Colors.white.withValues(alpha: 0.18),
                ),
              ),
            ),
          const SizedBox(width: 8),
          GoopText(
            title,
            style: TextStyle(
              fontSize: FontSizes.titleSmall,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
      SizedBox(height: 18 * sf),
    ];
  }

  List<Widget> _roleStage(double sf, ThemeFlair flair) => [
    _stageCard(
      title: 'HOST',
      subtitle: 'Main player\nLeads the run',
      icon: Icons.military_tech_rounded,
      color: const Color(0xFF4DD0E1),
      sf: sf,
      onTap: () {
        Haptics.selection();
        setState(() {
          _role = _LobbyRole.main;
          _stage = 1;
        });
      },
    ),
    SizedBox(height: 16 * sf),
    _stageCard(
      title: 'SIDEKICK',
      subtitle: 'Join as The Cultist\nBackup for the main player',
      icon: Icons.groups_rounded,
      color: flair.secondary,
      sf: sf,
      onTap: () {
        Haptics.selection();
        setState(() {
          _role = _LobbyRole.sidekick;
          _selectedChar = null;
          _stage = 2; // skip gungeoneer pick
        });
      },
    ),
    SizedBox(height: 22 * sf),

    // Subtle paradox entry — alt co-op mode with avatars/surprises,
    // demoted to a text link since the main menu paradox button
    // was removed.
  ];

  List<Widget> _gungeoneerStage(double sf, ThemeFlair flair) => [
    _buildCharacterPreview(sf, flair),
    SizedBox(height: 24 * sf),
    FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: flair.primary,
        foregroundColor: Colors.white,
        minimumSize: Size.fromHeight(56 * sf),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(Icons.arrow_forward_rounded, size: 24 * sf),
      label: GoopText(
        'CONTINUE',
        style: TextStyle(
          fontSize: FontSizes.titleSmall * sf,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
      onPressed: () {
        Haptics.selection();
        setState(() => _stage = 2);
      },
    ),
  ];

  List<Widget> _identityStage(double sf, ThemeFlair flair) => [
    Row(
      children: [
        GestureDetector(
          onTap: _pickAvatar,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: flair.primary.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: FramedAvatar(id: _avatarId, size: 52 * sf, radius: 26 * sf),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _buildNicknameField(sf, flair)),
      ],
    ),
    // Run title is Main-only — the host names the run, the Sidekick
    // receives it via the session-meta handshake.
    if (_role == _LobbyRole.main) ...[
      SizedBox(height: 14 * sf),
      _buildRunTitleField(sf, flair),
    ],
    SizedBox(height: 24 * sf),
    _buildActionButton(sf, flair),
    SizedBox(height: 24 * sf),
    TextButton.icon(
      onPressed: _showHowToPlay,
      icon: Icon(
        Icons.help_outline_rounded,
        size: 18 * sf,
        color: Colors.white.withValues(alpha: 0.4),
      ),
      label: GoopText(
        'How to Play',
        style: TextStyle(
          fontSize: FontSizes.labelMedium * sf,
          color: Colors.white.withValues(alpha: 0.4),
        ),
      ),
    ),
  ];

  /// Bold tappable card — same visual language as Paradox's _BigCard.
  Widget _stageCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required double sf,
  }) {
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 30 * sf, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1.8),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 24),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 44 * sf, color: color),
              SizedBox(height: 12 * sf),
              GoopText(
                title,
                style: TextStyle(
                  fontSize: FontSizes.titleMedium * sf,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 8 * sf),
              GoopText(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12 * sf,
                  color: Colors.white.withValues(alpha: 0.6),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Character preview ──────────────────────────────────────────

  Widget _buildCharacterPreview(double sf, ThemeFlair flair) {
    final char = _defaultChar;
    final animPath = gungeoneerAnimatedCardPath(char.name);
    final gifPath = gungeoneerGifPath(char.name);
    final isMain = _role == _LobbyRole.main;
    final glowColor = isMain ? flair.primary : flair.secondary;

    // Sidekick is always The Cultist — no character picker.
    // Main can tap to pick a different character.
    return GestureDetector(
      onTap: isMain ? () => _pickCharacter() : null,
      child: Container(
        padding: EdgeInsets.all(20 * sf),
        decoration: BoxDecoration(
          color: flair.card.withValues(alpha: 0.7),
          borderRadius: BorderRadius.all(Radii.lg),
          border: Border.all(color: glowColor.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: 0.12),
              blurRadius: 24 * sf,
              spreadRadius: 2 * sf,
            ),
          ],
        ),
        child: Row(
          children: [
            // Character portrait (larger)
            Container(
              width: 96 * sf,
              height: 96 * sf,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: glowColor.withValues(alpha: 0.5),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.15),
                    blurRadius: 12 * sf,
                    spreadRadius: 1 * sf,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AvatarAura(
                  size: 96 * sf,
                  borderRadius: 14,
                  child: _characterImage(char, animPath, gifPath, sf, flair),
                ),
              ),
            ),
            SizedBox(width: 18 * sf),
            // Character info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GoopText(
                    char.name,
                    style: TextStyle(
                      fontSize: FontSizes.titleLarge * sf,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                  if (!isMain)
                    GoopText(
                      'Sidekick always plays The Cultist',
                      style: TextStyle(
                        fontSize: FontSizes.labelSmall * sf,
                        color: Colors.white.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              isMain ? Icons.chevron_right_rounded : Icons.lock_rounded,
              size: 28 * sf,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _characterImage(
    Gungeoneer c,
    String animPath,
    String gifPath,
    double sf,
    ThemeFlair flair,
  ) {
    return SizedBox(
      width: 96 * sf,
      height: 96 * sf,
      child: animPath.isNotEmpty
          ? Image.asset(
              animPath,
              fit: BoxFit.contain,
              cacheWidth: 192,
              cacheHeight: 192,
              errorBuilder: (_, _, _) => gifPath.isNotEmpty
                  ? Image.asset(
                      gifPath,
                      fit: BoxFit.contain,
                      cacheWidth: 192,
                      cacheHeight: 192,
                    )
                  : Icon(
                      Icons.person_rounded,
                      size: 40 * sf,
                      color: flair.primary,
                    ),
            )
          : gifPath.isNotEmpty
          ? Image.asset(
              gifPath,
              fit: BoxFit.contain,
              cacheWidth: 192,
              cacheHeight: 192,
            )
          : Icon(Icons.person_rounded, size: 40 * sf, color: flair.primary),
    );
  }

  Future<void> _pickCharacter() async {
    Haptics.selection();
    final rp = context.read<RunProvider>();
    // Main player can't pick The Cultist — filter it out.
    final available = _role == _LobbyRole.main
        ? rp.allGungeoneers.where((g) => g.name != 'The Cultist').toList()
        : rp.allGungeoneers;
    final Gungeoneer? picked = await Navigator.push<Gungeoneer>(
      context,
      fastRoute(
        CharacterSelectScreen(
          mode: CharSelectMode.multiplayerPick,
          gungeoneers: available,
        ),
      ),
    );
    if (mounted && picked != null) {
      setState(() => _selectedChar = picked);
    }
  }

  // ── Fields ─────────────────────────────────────────────────────

  Future<void> _pickAvatar() async {
    final picked = await showAvatarPicker(context, _avatarId);
    if (picked != null && mounted) setState(() => _avatarId = picked);
  }

  Widget _buildNicknameField(double sf, ThemeFlair flair) {
    return TextField(
      controller: _nickCtrl,
      maxLength: 24,
      style: TextStyle(fontSize: 20 * sf, fontWeight: FontWeight.w800),
      decoration: InputDecoration(
        labelText: 'NICKNAME',
        labelStyle: TextStyle(
          fontSize: FontSizes.labelSmall * sf,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
          color: flair.primary.withValues(alpha: 0.7),
        ),
        hintText: 'Enter your nickname',
        hintStyle: TextStyle(
          fontSize: 20 * sf,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.3),
        ),
        prefixIcon: Icon(Icons.person_outline, size: 26 * sf),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 18 * sf,
          vertical: 16 * sf,
        ),
      ),
      onChanged: (value) async {
        await PairedPartnersStore.saveNickname(value);
      },
    );
  }

  Widget _buildRunTitleField(double sf, ThemeFlair flair) {
    return TextField(
      controller: _titleCtrl,
      maxLength: 40,
      style: TextStyle(fontSize: 16 * sf, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: 'RUN TITLE (OPTIONAL)',
        labelStyle: TextStyle(
          fontSize: FontSizes.labelSmall * sf,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
          color: flair.primary.withValues(alpha: 0.7),
        ),
        hintText: 'Name this run',
        hintStyle: TextStyle(
          fontSize: 16 * sf,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.3),
        ),
        prefixIcon: Icon(Icons.flag_outlined, size: 22 * sf),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 18 * sf,
          vertical: 14 * sf,
        ),
        counterStyle: TextStyle(
          fontSize: 10 * sf,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  // ── Role toggle ────────────────────────────────────────────────

  Widget _buildActionButton(double sf, ThemeFlair flair) {
    if (_role == _LobbyRole.main) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: flair.primary,
          foregroundColor: Colors.white,
          minimumSize: Size.fromHeight(56 * sf),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(Icons.wifi_tethering_rounded, size: 24 * sf),
        label: GoopText(
          'HOST GAME',
          style: TextStyle(
            fontSize: FontSizes.titleSmall * sf,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        onPressed: _host,
      );
    }
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: flair.secondary,
        foregroundColor: Colors.white,
        minimumSize: Size.fromHeight(56 * sf),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(Icons.login_rounded, size: 24 * sf),
      label: GoopText(
        'JOIN GAME',
        style: TextStyle(
          fontSize: FontSizes.titleSmall * sf,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
      onPressed: _join,
    );
  }

  // ── Actions ────────────────────────────────────────────────────

  /// HOST flow: pick character → connect screen.
  Future<void> _host() async {
    final nick = _nickCtrl.text.trim();
    if (nick.isEmpty) {
      _toast('Please enter a nickname.');
      return;
    }
    final char = _defaultChar;
    if (char.name == 'The Cultist') {
      _toast('Main player can\'t be The Cultist. Pick another character.');
      return;
    }

    Haptics.selection();
    final session = context.read<MpSession>();
    await _showPermissionRationale();
    if (!mounted) return;
    await session.startAsMain(
      nickname: nick,
      character: char,
      avatarId: _avatarId,
      runTitle: _titleCtrl.text.trim(),
    );
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      fastRoute(const MpConnectScreen()),
    );
  }

  /// JOIN flow: connect screen (PINless).
  Future<void> _join() async {
    final nick = _nickCtrl.text.trim();
    if (nick.isEmpty) {
      _toast('Please enter a nickname.');
      return;
    }
    final char = _defaultChar;
    final session = context.read<MpSession>();
    await _showPermissionRationale();
    if (!mounted) return;
    await session.startAsSidekick(
      nickname: nick,
      character: char,
      avatarId: _avatarId,
    );
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      fastRoute(const MpConnectScreen()),
    );
  }

  // ── How to play ────────────────────────────────────────────────

  void _showHowToPlay() {
    final flair = AppTheme.flair;
    final sf = Responsive.factor(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: flair.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20 * sf, 12, 20 * sf, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 16 * sf),
              GoopText(
                'HOW TO PLAY',
                style: TextStyle(
                  fontSize: FontSizes.titleSmall * sf,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 16 * sf),
              _HowToStep(
                num: '1',
                text: 'Both players enter a nickname.',
                sf: sf,
              ),
              SizedBox(height: 6 * sf),
              _HowToStep(
                num: '2',
                text: 'One player picks MAIN and taps HOST GAME, then picks a character.',
                sf: sf,
              ),
              SizedBox(height: 6 * sf),
              _HowToStep(
                num: '3',
                text: 'The other player picks SIDEKICK and taps JOIN GAME.',
                sf: sf,
              ),
              SizedBox(height: 6 * sf),
              _HowToStep(
                num: '4',
                text:
                    'Your inventories sync automatically. Send gifts, '
                    'roll dice, and emote!',
                sf: sf,
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Permission rationale ───────────────────────────────────────

  Future<void> _showPermissionRationale() async {
    final flair = AppTheme.flair;
    final sf = Responsive.factor(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: flair.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radii.lg),
          side: BorderSide(
            color: flair.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        icon: Icon(Icons.bluetooth_rounded, size: 36, color: flair.primary),
        title: const GoopText(
          'Bluetooth + Wi-Fi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: FontSizes.titleMedium,
          ),
        ),
        content: GoopText(
          'GungeonMate uses Bluetooth and Wi-Fi to connect devices. '
          'You\'ll be asked to grant permissions — please allow them.',
          style: TextStyle(
            fontSize: 13 * sf,
            color: Colors.white.withValues(alpha: 0.7),
            height: 1.5,
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: flair.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const GoopText('GOT IT'),
          ),
        ],
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: GoopText(msg), duration: const Duration(seconds: 2)),
    );
  }
}

// ── Helper widgets ───────────────────────────────────────────────

/// Small uppercase section label with a subtle accent line.
class _HowToStep extends StatelessWidget {
  final String num;
  final String text;
  final double sf;

  const _HowToStep({required this.num, required this.text, required this.sf});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.flair.primary.withValues(alpha: 0.6);
    return Semantics(
      label: 'Step $num: $text',
      child: Padding(
        padding: EdgeInsets.only(bottom: 10 * sf),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24 * sf,
              height: 24 * sf,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
                border: Border.all(color: color, width: 1.5),
              ),
              child: Center(
                child: GoopText(
                  num,
                  style: TextStyle(
                    fontSize: FontSizes.labelMedium * sf,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12 * sf),
            Expanded(
              child: GoopText(
                text,
                style: TextStyle(
                  fontSize: 13 * sf,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
