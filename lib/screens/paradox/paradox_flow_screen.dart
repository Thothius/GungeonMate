import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/multiplayer_messages.dart';
import '../../services/app_theme.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/haptics.dart';
import '../../services/mp_session.dart';
import '../../services/paired_partners_store.dart';
import '../../services/mp/mp_store.dart';
import '../../theme/tokens.dart';
import '../../utils/asset_paths.dart';
import '../../utils/responsive.dart';
import '../../utils/run_name_generator.dart';
import '../../widgets/paradox/avatar_frame.dart';
import '../../widgets/scale_button.dart';

/// Paradox Mode entry flow — one slick screen with sequential stages:
///
/// 1. ROLE     — MAIN or SIDEKICK cards
/// 2. AVATAR   — pick a cosmetic avatar from the registry
/// 3. IDENTITY — nickname + ENTER THE VOID
/// 4. VOID     — seek forever (no timeout) until paired
/// 5. LOBBY    — both avatars + names, run title + session #;
///               MAIN gets START RUN, SIDEKICK waits
///
/// Roles are fixed: MAIN plays The Paradox, SIDEKICK plays The Cultist.
class ParadoxFlowScreen extends StatefulWidget {
  const ParadoxFlowScreen({super.key});

  @override
  State<ParadoxFlowScreen> createState() => _ParadoxFlowScreenState();
}

enum _Stage { role, avatar, identity, void_, lobby }

class _ParadoxFlowScreenState extends State<ParadoxFlowScreen>
    with TickerProviderStateMixin {
  _Stage _stage = _Stage.role;
  MpRole _role = MpRole.main;
  String _avatarId = kAvatarIds.first;
  final _nickCtrl = TextEditingController();
  String _runTitle = '';
  int _sessionNumber = 0;
  bool _seeking = false;
  late final AnimationController _pulseCtrl;
  MpSession? _mp;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _loadNickname();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mp = context.read<MpSession>();
      _mp!.addListener(_onSessionChanged);
      _mp!.onStartRun = _enterRun;
    });
  }

  Future<void> _loadNickname() async {
    final saved = await PairedPartnersStore.loadNickname();
    if (mounted && saved != null && saved.isNotEmpty) {
      _nickCtrl.text = saved;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _nickCtrl.dispose();
    try {
      _mp?.removeListener(_onSessionChanged);
      if (_mp?.onStartRun == _enterRun) _mp?.onStartRun = null;
    } catch (_) {}
    super.dispose();
  }

  // ── Session wiring ──────────────────────────────────────────────

  void _onSessionChanged() {
    if (!mounted) return;
    final s = _mp!;
    if (_stage == _Stage.void_ && s.phase == MpPhase.connected) {
      setState(() => _stage = _Stage.lobby);
      Haptics.success();
    }
    if (s.error != null && _stage == _Stage.void_) {
      // Role mismatch / protocol error — bounce back to role pick
      // with the message instead of a dead error screen.
      setState(() => _stage = _Stage.role);
      _seeking = false;
    }
  }

  /// Sidekick received MpStartRun (or Main's own send) → head to run.
  void _enterRun() {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _enterVoid() async {
    final nick = _nickCtrl.text.trim();
    if (nick.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: GoopText('Enter a name first.')),
      );
      return;
    }
    await PairedPartnersStore.saveNickname(nick);
    if (_role == MpRole.main) {
      _runTitle = RunNameGenerator.roll();
      _sessionNumber = await MpStore.nextParadoxSessionNumber();
    }
    if (!mounted) return;
    setState(() {
      _stage = _Stage.void_;
      _seeking = true;
    });
    final session = context.read<MpSession>();
    await session.startParadox(
      role: _role,
      nickname: nick,
      avatarId: _avatarId,
      runTitle: _runTitle,
      sessionNumber: _sessionNumber,
    );
  }

  Future<void> _cancelSeek() async {
    await _mp?.cancel();
    if (!mounted) return;
    setState(() {
      _stage = _Stage.role;
      _seeking = false;
    });
  }

  /// Shared back action — the header arrow and the system back gesture
  /// (via [PopScope]) both route here. During seeking/lobby it runs the
  /// same cancel path as the CANCEL button so the link is actually
  /// torn down instead of the flow screen popping off with the radios
  /// still seeking. Earlier stages just step back one stage.
  void _onBack() {
    if (_stage == _Stage.void_ || _stage == _Stage.lobby) {
      unawaited(_cancelSeek());
      return;
    }
    if (_stage == _Stage.role) {
      Navigator.of(context).maybePop();
    } else {
      setState(() => _stage = _Stage.values[_stage.index - 1]);
    }
  }

  // ── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    final flair = AppTheme.flair;
    final session = context.watch<MpSession>();

    // System back routes through _onBack too — while seeking/lobby the
    // route can't simply pop (that would orphan the active session), so
    // canPop only allows leaving from the role pick stage.
    return PopScope(
      canPop: _stage == _Stage.role,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onBack();
      },
      child: Scaffold(
      backgroundColor: const Color(0xFF0B0714),
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient void glow
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.3),
                        radius: 1.2,
                        colors: [
                          const Color(0xFF7C4DFF)
                              .withValues(alpha: 0.10 + _pulseCtrl.value * 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 12 * sf, vertical: 10 * sf),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 20, color: Colors.white70),
                        onPressed: _onBack,
                      ),
                      Expanded(
                        child: GoopText(
                          _title(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: FontSizes.titleSmall * sf,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                            color: const Color(0xFFB388FF),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: _buildStage(session, sf, flair),
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

  String _title() => switch (_stage) {
        _Stage.role => 'CHOOSE YOUR ROLE',
        _Stage.avatar => 'PICK YOUR AVATAR',
        _Stage.identity => 'IDENTITY',
        _Stage.void_ => 'THE VOID',
        _Stage.lobby => 'PARADOX LINK',
      };

  Widget _buildStage(MpSession session, double sf, ThemeFlair flair) {
    switch (_stage) {
      case _Stage.role:
        return _RoleStage(
          key: const ValueKey('role'),
          role: _role,
          onDemo: () {
            session.enableDemo();
            _enterRun();
          },
          onPick: (r) {
            Haptics.selection();
            setState(() {
              _role = r;
              _stage = _Stage.avatar;
            });
          },
          error: session.error,
          sf: sf,
        );
      case _Stage.avatar:
        return _AvatarStage(
          key: const ValueKey('avatar'),
          selected: _avatarId,
          onPick: (id) {
            Haptics.selection();
            setState(() {
              _avatarId = id;
              _stage = _Stage.identity;
            });
          },
          sf: sf,
        );
      case _Stage.identity:
        return _IdentityStage(
          key: const ValueKey('identity'),
          nickCtrl: _nickCtrl,
          avatarId: _avatarId,
          role: _role,
          onEnterVoid: _enterVoid,
          sf: sf,
        );
      case _Stage.void_:
        return _VoidStage(
          key: const ValueKey('void'),
          avatarId: _avatarId,
          nickname: _nickCtrl.text.trim(),
          seeking: _seeking,
          onCancel: _cancelSeek,
          pulse: _pulseCtrl,
          sf: sf,
        );
      case _Stage.lobby:
        return _LobbyStage(
          key: const ValueKey('lobby'),
          session: session,
          onStartRun: () async {
            await session.sendStartRun();
            _enterRun();
          },
          sf: sf,
        );
    }
  }
}

// ── Stage 1: role pick ────────────────────────────────────────────

class _RoleStage extends StatelessWidget {
  final MpRole role;
  final void Function(MpRole) onPick;
  final VoidCallback onDemo;
  final String? error;
  final double sf;
  const _RoleStage(
      {super.key,
      required this.role,
      required this.onPick,
      required this.onDemo,
      this.error,
      required this.sf});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20 * sf),
      child: Column(
        children: [
          if (error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.4)),
              ),
              child: GoopText(error!,
                  style: TextStyle(
                      fontSize: 12 * sf, color: Colors.redAccent.shade100)),
            ),
          ],
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: _BigCard(
                  title: 'MAIN',
                  subtitle: 'The Paradox\nHosts the run',
                  icon: Icons.auto_awesome_rounded,
                  color: const Color(0xFF7C4DFF),
                  onTap: () => onPick(MpRole.main),
                  sf: sf,
                ),
              ),
              SizedBox(width: 14 * sf),
              Expanded(
                child: _BigCard(
                  title: 'SIDEKICK',
                  subtitle: 'The Cultist\nJoins the run',
                  icon: Icons.group_rounded,
                  color: const Color(0xFF26C6DA),
                  onTap: () => onPick(MpRole.sidekick),
                  sf: sf,
                ),
              ),
            ],
          ),
          SizedBox(height: 14 * sf),
          _BigCard(
            title: 'TESTING MODE',
            subtitle: 'Solo demo — fake peer\nFull MP/Paradox UI, no second phone',
            icon: Icons.science_rounded,
            color: const Color(0xFFFFB300),
            onTap: onDemo,
            sf: sf,
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _BigCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double sf;
  const _BigCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.sf,
  });

  @override
  Widget build(BuildContext context) {
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
              BoxShadow(
                  color: color.withValues(alpha: 0.15), blurRadius: 24),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 44 * sf, color: color),
              SizedBox(height: 12 * sf),
              GoopText(title,
                  style: TextStyle(
                      fontSize: FontSizes.titleMedium * sf,
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: 1.5)),
              SizedBox(height: 8 * sf),
              GoopText(subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12 * sf,
                      color: Colors.white.withValues(alpha: 0.6),
                      height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stage 2: avatar pick ──────────────────────────────────────────

/// Compact avatar stage — shows the current pick; tapping opens the
/// paged popup picker (12 per sheet, swipe between sheets).
class _AvatarStage extends StatelessWidget {
  final String selected;
  final void Function(String) onPick;
  final double sf;
  const _AvatarStage(
      {super.key, required this.selected, required this.onPick, required this.sf});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () async {
          final picked = await showAvatarPicker(context, selected);
          if (picked != null) onPick(picked);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 150 * sf,
              height: 150 * sf,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFFB388FF).withValues(alpha: 0.7),
                    width: 2.5),
                boxShadow: [
                  BoxShadow(
                      color:
                          const Color(0xFF7C4DFF).withValues(alpha: 0.35),
                      blurRadius: 24),
                ],
              ),
              child: FramedAvatar(id: selected, size: 150 * sf, radius: 17),
            ),
            SizedBox(height: 18 * sf),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 18 * sf, vertical: 10 * sf),
              decoration: BoxDecoration(
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFB388FF).withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.grid_view_rounded,
                      size: 16 * sf, color: const Color(0xFFB388FF)),
                  SizedBox(width: 8 * sf),
                  GoopText(
                    'PICK AVATAR',
                    style: TextStyle(
                      fontSize: 13 * sf,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: const Color(0xFFB388FF),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8 * sf),
            GoopText(
              '${kAvatarIds.length} avatars · swipe sheets',
              style: TextStyle(
                  fontSize: 11 * sf,
                  color: Colors.white.withValues(alpha: 0.35)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paged avatar picker — 12 per sheet, swipe between sheets, page
/// counter on top. Returns the picked id, or null if dismissed.
Future<String?> showAvatarPicker(BuildContext context, String selected) {
  return showDialog<String>(
    context: context,
    builder: (_) => _AvatarPickerDialog(selected: selected),
  );
}

class _AvatarPickerDialog extends StatefulWidget {
  final String selected;
  const _AvatarPickerDialog({required this.selected});

  @override
  State<_AvatarPickerDialog> createState() => _AvatarPickerDialogState();
}

class _AvatarPickerDialogState extends State<_AvatarPickerDialog> {
  static const int _perPage = 9; // 3 cols × 3 rows per sheet
  late final PageController _pageCtrl;
  int _page = 0;
  late String _picked = widget.selected;
  bool _frameStage = false; // step 2: dedicated frame preview

  int get _pageCount =>
      (kAvatarIds.length + _perPage - 1) ~/ _perPage;

  @override
  void initState() {
    super.initState();
    // Open on the sheet containing the current pick (base id).
    final idx = kAvatarIds.indexOf(avatarBaseId(widget.selected));
    _page = idx < 0 ? 0 : idx ~/ _perPage;
    _pageCtrl = PageController(initialPage: _page);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  /// Replace the frame suffix, keeping the base portrait.
  void _pickFrame(String frameId) {
    Haptics.selection();
    final base = avatarBaseId(_picked);
    setState(() =>
        _picked = frameId.isEmpty ? base : '$base:$frameId');
  }

  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    return Dialog(
      backgroundColor: const Color(0xFF12081F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
            color: const Color(0xFF7C4DFF).withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16 * sf),
        child: _frameStage ? _buildFrameStage(sf) : _buildGridStage(sf),
      ),
    );
  }

  /// Step 2 — dedicated frame preview: the picked portrait large, every
  /// frame style rendered live around it (specials animate for real).
  Widget _buildFrameStage(double sf) {
    final frame = avatarFrameId(_picked);
    final styles = [...kAvatarFrames, ...kSpecialFrames];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _frameStage = false),
              child: Row(
                children: [
                  Icon(Icons.arrow_back_rounded,
                      size: 16 * sf, color: const Color(0xFFB388FF)),
                  SizedBox(width: 4 * sf),
                  GoopText('BACK',
                      style: TextStyle(
                          fontSize: 12 * sf,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: const Color(0xFFB388FF))),
                ],
              ),
            ),
            const Spacer(),
            GoopText('PICK A FRAME',
                style: TextStyle(
                    fontSize: 13 * sf,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    color: const Color(0xFFB388FF))),
          ],
        ),
        SizedBox(height: 16 * sf),
        FramedAvatar(id: _picked, size: 130 * sf, radius: 16),
        SizedBox(height: 6 * sf),
        GoopText(
          (avatarFrameStyleOf(frame)?.label ?? 'NONE').toUpperCase(),
          style: TextStyle(
              fontSize: 12 * sf,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Colors.white.withValues(alpha: 0.6))),
        SizedBox(height: 14 * sf),
        // Every style previewed live on the actual portrait — specials
        // animate because FramedAvatar renders the real painter.
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            for (final f in styles)
              GestureDetector(
                onTap: () => _pickFrame(f.id),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        FramedAvatar(
                          id: f.id.isEmpty
                              ? avatarBaseId(_picked)
                              : '${avatarBaseId(_picked)}:${f.id}',
                          size: 52 * sf,
                          radius: 10,
                        ),
                        if (frame == f.id)
                          Container(
                            width: 52 * sf,
                            height: 52 * sf,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white, width: 2.5),
                            ),
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                decoration: const BoxDecoration(
                                    color: Color(0xFFB388FF),
                                    shape: BoxShape.circle),
                                padding: const EdgeInsets.all(2),
                                child: Icon(Icons.check,
                                    size: 12 * sf, color: Colors.black),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 3 * sf),
                    GoopText(
                      f.label,
                      style: TextStyle(
                          fontSize: 8.5 * sf,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: frame == f.id
                              ? const Color(0xFFB388FF)
                              : Colors.white.withValues(alpha: 0.45)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        SizedBox(height: 16 * sf),
        _confirmButton(sf),
      ],
    );
  }

  Widget _confirmButton(double sf) {
    return ScaleButton(
      onTap: () => Navigator.pop(context, _picked),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12 * sf),
        decoration: BoxDecoration(
          color: const Color(0xFF7C4DFF).withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFFB388FF).withValues(alpha: 0.6)),
        ),
        child: Center(
          child: GoopText(
            'CONFIRM',
            style: TextStyle(
              fontSize: 14 * sf,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
              color: const Color(0xFFB388FF),
            ),
          ),
        ),
      ),
    );
  }

  /// Step 1 — the paged portrait grid (12 per sheet).
  Widget _buildGridStage(double sf) {
    return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GoopText(
                  'PAGE ${_page + 1}/$_pageCount',
                  style: TextStyle(
                    fontSize: 13 * sf,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    color: const Color(0xFFB388FF),
                  ),
                ),
                // Live preview of the composite pick.
                FramedAvatar(id: _picked, size: 40 * sf, radius: 9),
              ],
            ),
            SizedBox(height: 12 * sf),
            SizedBox(
              height: 330 * sf,
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _pageCount,
                onPageChanged: (p) => setState(() => _page = p),
                itemBuilder: (_, page) => GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: List.generate(_perPage, (i) {
                    final idx = page * _perPage + i;
                    // Empty slot on the last partial sheet.
                    if (idx >= kAvatarIds.length) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05)),
                        ),
                      );
                    }
                    final id = kAvatarIds[idx];
                    final isSel = id == avatarBaseId(_picked);
                    return GestureDetector(
                      onTap: () {
                        Haptics.selection();
                        final frame = avatarFrameId(_picked);
                        setState(() {
                          _picked = frame.isEmpty ? id : '$id:$frame';
                          _frameStage = true; // → dedicated frame stage
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSel
                                ? const Color(0xFFB388FF)
                                : Colors.white.withValues(alpha: 0.15),
                            width: isSel ? 2.5 : 1.2,
                          ),
                          boxShadow: isSel
                              ? [
                                  BoxShadow(
                                      color: const Color(0xFF7C4DFF)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 14)
                                ]
                              : null,
                        ),
                        child: ClipRect(
                          // Overscale bleeds off the 1-2px white
                          // gridline edges on sliced grid portraits.
                          child: Transform.scale(
                            scale: 1.20,
                            alignment: Alignment.center,
                            child: Image.asset(
                              avatarPath(id),
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.none,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person,
                                  size: 36,
                                  color: Colors.white38),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            SizedBox(height: 8 * sf),
            GoopText(
              'swipe sheets · tap a portrait for frames',
              style: TextStyle(
                  fontSize: 11 * sf,
                  color: Colors.white.withValues(alpha: 0.35)),
            ),
            SizedBox(height: 10 * sf),
            _confirmButton(sf),
          ],
    );
  }
}


// ── Stage 3: identity + Enter the Void ────────────────────────────

class _IdentityStage extends StatelessWidget {
  final TextEditingController nickCtrl;
  final String avatarId;
  final MpRole role;
  final VoidCallback onEnterVoid;
  final double sf;
  const _IdentityStage({
    super.key,
    required this.nickCtrl,
    required this.avatarId,
    required this.role,
    required this.onEnterVoid,
    required this.sf,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24 * sf),
      child: Column(
        children: [
          Container(
            width: 110 * sf,
            height: 110 * sf,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: const Color(0xFFB388FF).withValues(alpha: 0.6),
                  width: 2),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
                    blurRadius: 20),
              ],
            ),
            child: FramedAvatar(id: avatarId, size: 110 * sf, radius: 16),
          ),
          SizedBox(height: 24 * sf),
          TextField(
            controller: nickCtrl,
            maxLength: 20,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22 * sf, fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              hintText: 'Your name',
              hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontWeight: FontWeight.w600),
              counterStyle:
                  TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.5))),
              focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFB388FF))),
            ),
          ),
          SizedBox(height: 12 * sf),
          GoopText(
            role == MpRole.main
                ? 'You will host as THE PARADOX'
                : 'You will join as THE CULTIST',
            style: TextStyle(
                fontSize: 11 * sf,
                letterSpacing: 1.2,
                color: Colors.white.withValues(alpha: 0.45),
                fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 36 * sf),
          GestureDetector(
            onTap: onEnterVoid,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 18 * sf),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF4A148C)],
                ),
                border: Border.all(
                    color: const Color(0xFFB388FF).withValues(alpha: 0.8),
                    width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.4),
                      blurRadius: 24,
                      spreadRadius: 1),
                ],
              ),
              child: GoopText('ENTER THE VOID',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: FontSizes.titleSmall * sf,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stage 4: the Void (seeking, forever) ──────────────────────────

class _VoidStage extends StatelessWidget {
  final String avatarId;
  final String nickname;
  final bool seeking;
  final VoidCallback onCancel;
  final Animation<double> pulse;
  final double sf;
  const _VoidStage({
    super.key,
    required this.avatarId,
    required this.nickname,
    required this.seeking,
    required this.onCancel,
    required this.pulse,
    required this.sf,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28 * sf),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: pulse,
              builder: (_, child) => Container(
                width: 120 * sf,
                height: 120 * sf,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C4DFF)
                          .withValues(alpha: 0.2 + pulse.value * 0.3),
                      blurRadius: 30 + pulse.value * 20,
                      spreadRadius: 4 + pulse.value * 6,
                    ),
                  ],
                ),
                child: child,
              ),
              child: FramedAvatar(id: avatarId, size: double.infinity, radius: 60),
            ),
            SizedBox(height: 14 * sf),
            GoopText(nickname,
                style: TextStyle(
                    fontSize: 15 * sf,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.85))),
            SizedBox(height: 36 * sf),
            SizedBox(
              width: 26 * sf,
              height: 26 * sf,
              child: const CircularProgressIndicator(
                  strokeWidth: 2.5, color: Color(0xFFB388FF)),
            ),
            SizedBox(height: 16 * sf),
            GoopText('Seeking partner through the Void…',
                style: TextStyle(
                    fontSize: 13 * sf,
                    color: Colors.white.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic)),
            SizedBox(height: 8 * sf),
            GoopText('Keep both apps open — the link forms on its own.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11 * sf,
                    color: Colors.white.withValues(alpha: 0.35))),
            SizedBox(height: 36 * sf),
            TextButton(
              onPressed: onCancel,
              child: GoopText('CANCEL',
                  style: TextStyle(
                      fontSize: 12 * sf,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: Colors.white.withValues(alpha: 0.4))),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stage 5: pre-run lobby ────────────────────────────────────────

class _LobbyStage extends StatelessWidget {
  final MpSession session;
  final VoidCallback onStartRun;
  final double sf;
  const _LobbyStage(
      {super.key,
      required this.session,
      required this.onStartRun,
      required this.sf});

  @override
  Widget build(BuildContext context) {
    final isMain = session.myRole == MpRole.main;
    return SingleChildScrollView(
      padding: EdgeInsets.all(24 * sf),
      child: Column(
        children: [
          // Run title + session number
          GoopText(
            session.runTitle.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: FontSizes.titleLarge * sf,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
                color: const Color(0xFFB388FF)),
          ),
          SizedBox(height: 4 * sf),
          GoopText('SESSION #${session.sessionNumber}',
            style: TextStyle(
                fontSize: 12 * sf,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: Colors.white.withValues(alpha: 0.5))),
          SizedBox(height: 30 * sf),
          // Both players side by side
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LobbyPortrait(
                avatarId: session.avatarId,
                name: session.myNickname,
                role: session.myRole == MpRole.main ? 'MAIN' : 'SIDEKICK',
                color: const Color(0xFF7C4DFF),
                sf: sf,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16 * sf),
                child: const Icon(Icons.link_rounded,
                    color: Color(0xFF00E676), size: 30),
              ),
              _LobbyPortrait(
                avatarId: session.peerAvatarId,
                name: session.peerNickname ?? 'Partner',
                role: session.myRole == MpRole.main ? 'SIDEKICK' : 'MAIN',
                color: const Color(0xFF26C6DA),
                sf: sf,
              ),
            ],
          ),
          SizedBox(height: 40 * sf),
          if (isMain)
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
                foregroundColor: Colors.white,
                minimumSize: Size.fromHeight(56 * sf),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onStartRun,
              child: GoopText('START RUN',
                  style: TextStyle(
                      fontSize: FontSizes.titleSmall * sf,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5)),
            )
          else
            Column(
              children: [
                const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF26C6DA))),
                SizedBox(height: 12 * sf),
                GoopText('Waiting to start…',
                    style: TextStyle(
                        fontSize: 13 * sf,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withValues(alpha: 0.6))),
              ],
            ),
        ],
      ),
    );
  }
}

class _LobbyPortrait extends StatelessWidget {
  final String avatarId;
  final String name;
  final String role;
  final Color color;
  final double sf;
  const _LobbyPortrait({
    required this.avatarId,
    required this.name,
    required this.role,
    required this.color,
    required this.sf,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96 * sf,
          height: 96 * sf,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 18)
            ],
          ),
          child: FramedAvatar(id: avatarId, size: double.infinity, radius: 14),
        ),
        SizedBox(height: 10 * sf),
        GoopText(name,
            style: TextStyle(
                fontSize: 14 * sf,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.9))),
        SizedBox(height: 2 * sf),
        GoopText(role,
            style: TextStyle(
                fontSize: 10 * sf,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: color.withValues(alpha: 0.8))),
      ],
    );
  }
}
