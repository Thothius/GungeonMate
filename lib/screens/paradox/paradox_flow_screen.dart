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
import '../../widgets/active_run/bottom_back_bar.dart';
import '../../widgets/paradox/avatar_frame.dart';
import '../../widgets/scale_button.dart';
part 'flow/flow_stages_a.dart';
part 'flow/flow_stages_b.dart';

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: GoopText('Enter a name first.')));
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
        // Back moved to the bottom thumb zone (task 17 sweep) — same
        // stage-aware _onBack the top-bar arrow used to call.
        bottomNavigationBar: BottomBackBar(onPressed: _onBack),
        body: SafeArea(
          child: Stack(
            children: [
              // Ambient void glow
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder:
                        (_, __) => Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(0, -0.3),
                              radius: 1.2,
                              colors: [
                                const Color(0xFF7C4DFF).withValues(
                                  alpha: 0.10 + _pulseCtrl.value * 0.05,
                                ),
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
                      horizontal: 12 * sf,
                      vertical: 10 * sf,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 48),
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

// ── Stage 2: avatar pick ──────────────────────────────────────────

/// Paged avatar picker — 12 per sheet, swipe between sheets, page
/// counter on top. Returns the picked id, or null if dismissed.
Future<String?> showAvatarPicker(BuildContext context, String selected) {
  return showDialog<String>(
    context: context,
    builder: (_) => _AvatarPickerDialog(selected: selected),
  );
}

// ── Stage 3: identity + Enter the Void ────────────────────────────

// ── Stage 4: the Void (seeking, forever) ──────────────────────────

// ── Stage 5: pre-run lobby ────────────────────────────────────────
