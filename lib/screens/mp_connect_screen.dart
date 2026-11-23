import 'dart:async';
import 'dart:math' as math;

import '../theme/tokens.dart';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../models/gungeoneer.dart';
import '../models/multiplayer_messages.dart';
import '../providers/run_provider.dart';
import '../services/app_theme.dart';
import '../services/goop_talk_engine.dart';
import '../services/haptics.dart';
import '../services/mp_session.dart';
import '../utils/asset_paths.dart';
import '../utils/responsive.dart';
import '../widgets/active_run/bottom_back_bar.dart';
import '../widgets/avatar_aura.dart';
import '../widgets/paradox/avatar_frame.dart';
import '../widgets/particles/ambient_glow.dart';

/// Clean connecting / connected view.
///
/// - **connecting** — pulsing portraits + status message
/// - **connected** — both portraits + "Connected!" → auto-navigate to run
/// - **error** — concise message + RETRY
/// - **permissionDenied** — banner + "Open Settings"
class MpConnectScreen extends StatefulWidget {
  const MpConnectScreen({super.key});

  @override
  State<MpConnectScreen> createState() => _MpConnectScreenState();
}

class _MpConnectScreenState extends State<MpConnectScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _checkPopCtrl;
  late final MpSession _session;
  bool _navigatedToRun = false;

  /// Final-handshake state for the VS splash:
  /// - Main must tap READY → [MpSession.sendStartRun] fires the
  ///   `MpStartRun` wire message and both sides drop into the run.
  /// - Sidekick waits for that message (`onStartRun`) before entering.
  /// Reconnects/restores skip the gate — the run already started.
  bool _mainConfirmed = false;
  bool _peerStarted = false;
  bool _still = false;

  /// Sidekick watchdog — if the host never confirms, surface an escape
  /// hint instead of an infinite silent WAITING.
  Timer? _hostWaitTimer;
  bool _hostWaitHint = false;

  @override
  void initState() {
    super.initState();
    _session = context.read<MpSession>();
    _session.onStartRun = _onPeerStartRun;
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _checkPopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    if (still == _still) return;
    _still = still;
    if (still) {
      _pulseCtrl.stop();
    } else if (!_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  /// Sidekick path — the host's READY fired `MpStartRun` over the
  /// wire; leave the splash and drop into the run.
  void _onPeerStartRun() {
    if (!mounted) return;
    setState(() => _peerStarted = true);
  }

  /// Fresh pairings need the host's confirm; reconnects and app-kill
  /// restores already had their handshake — enter immediately. The
  /// session-level [MpSession.runStartReceived] latch covers the case
  /// where `MpStartRun` arrived before this screen mounted.
  bool _needsHandshake(MpSession session) {
    if (session.demoMode) return false;
    return session.connectReason != MpConnectReason.reconnecting &&
        session.connectReason != MpConnectReason.restoring;
  }

  bool _awaitingHandshake(MpSession session) {
    if (session.phase != MpPhase.connected || !_needsHandshake(session)) {
      return false;
    }
    return session.myRole == MpRole.main
        ? !_mainConfirmed
        : !_peerStarted && !session.runStartReceived;
  }

  /// Arms/cancels the sidekick "host never confirmed" watchdog. Called
  /// from build — cheap flag check, timer does the real work.
  void _syncHostWaitTimer(bool waitingForHost) {
    if (waitingForHost) {
      _hostWaitTimer ??= Timer(const Duration(seconds: 25), () {
        if (mounted) setState(() => _hostWaitHint = true);
      });
    } else {
      _hostWaitTimer?.cancel();
      _hostWaitTimer = null;
      _hostWaitHint = false;
    }
  }

  /// System back / bottom bar — one path: cancel the session and pop,
  /// except during the entering beat where the start already fired
  /// (cancelling there would `MpEndRun` the peer's live run).
  void _handleSystemBack() {
    if (_navigatedToRun) return;
    final session = _session;
    if (session.isActive) session.cancel();
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  void _enterRun() {
    if (_navigatedToRun) return;
    _navigatedToRun = true;
    _checkPopCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Haptics.success();
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        // This route was pushReplacement'd — a single pop lands on
        // home. Never popUntil(isFirst): it would also pop routes the
        // user pushed on top during the beat.
        final nav = Navigator.of(context);
        if (nav.canPop()) nav.pop();
      });
    });
  }

  Future<void> _confirmAndStart() async {
    Haptics.selection();
    setState(() => _mainConfirmed = true);
    final sent = await _session.sendStartRun();
    if (!sent && mounted) {
      // Delivery failed — revert so READY re-enables and the peer
      // isn't left waiting on a message that never left.
      setState(() => _mainConfirmed = false);
      _session.logEvent(
        MpEvent.event(
          kind: 'system',
          from: _session.myNickname,
          text: 'Could not reach your partner — try READY again.',
          mine: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    _hostWaitTimer?.cancel();
    // Identity-guarded — a stacked screen must not null a callback
    // it doesn't own.
    if (_session.onStartRun == _onPeerStartRun) {
      _session.onStartRun = null;
    }
    _pulseCtrl.dispose();
    _checkPopCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<MpSession>();
    final rp = context.watch<RunProvider>();
    final sf = Responsive.factor(context);
    final flair = AppTheme.flair;

    // Sidekick watchdog — arm while we're genuinely waiting on the
    // host's READY, cancel the moment it resolves (or the phase ends).
    _syncHostWaitTimer(
      session.phase == MpPhase.connected &&
          _needsHandshake(session) &&
          session.myRole == MpRole.sidekick &&
          !_peerStarted &&
          !session.runStartReceived,
    );

    // Enter the run once the handshake resolves: main after READY,
    // sidekick after the peer's MpStartRun, reconnects immediately.
    if (session.phase == MpPhase.connected &&
        !_awaitingHandshake(session) &&
        !_navigatedToRun) {
      _enterRun();
    }

    return PopScope(
      // System back must not bypass session.cancel() — a bare pop
      // leaves zombie radios and can drop the sidekick into the run
      // without the host's confirmation.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleSystemBack();
      },
      child: Scaffold(
        backgroundColor: flair.scaffold.withValues(alpha: 0.3),
        // Hidden during the entering beat — a stray tap there would
        // send MpEndRun and tear down the peer's just-started run.
        bottomNavigationBar:
            _navigatedToRun
                ? null
                : BottomBackBar(onPressed: _handleSystemBack),
        body: Stack(
          children: [
            // Atmospheric glow — same backdrop as the lobby.
            Positioned.fill(
              child: IgnorePointer(
                child: AmbientGlow(
                  primary: flair.primary.withValues(alpha: 0.06),
                  secondary: flair.secondary.withValues(alpha: 0.04),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // Top bar
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16 * sf,
                      vertical: 12 * sf,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 48),
                        Expanded(
                          child: GoopText(
                            _titleForSession(session),
                            style: TextStyle(
                              fontSize: FontSizes.titleSmall * sf,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 48 * sf),
                      ],
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      child: KeyedSubtree(
                        key: ValueKey(session.phase),
                        child: _buildContent(session, rp, sf, flair),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Themed card shell shared by every phase — same border+glow
  /// language as the lobby's stage cards.
  Widget _cardShell({
    required List<Widget> children,
    required Color accent,
    required double sf,
    required ThemeFlair flair,
  }) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24 * sf),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 24 * sf,
                vertical: 34 * sf,
              ),
              decoration: BoxDecoration(
                color: flair.card.withValues(alpha: 0.85),
                borderRadius: BorderRadius.all(Radii.lg),
                border: Border.all(
                  color: accent.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.12),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Small run-title chip — shown once the title is known (host sets
  /// it in the lobby; the Sidekick gets it via session meta).
  Widget _runTitleChip(String title, double sf, ThemeFlair flair) {
    return Center(
      child: Container(
        margin: EdgeInsets.only(bottom: 18 * sf),
        padding: EdgeInsets.symmetric(horizontal: 12 * sf, vertical: 5 * sf),
        decoration: BoxDecoration(
          color: flair.secondary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.all(Radii.sm),
          border: Border.all(color: flair.secondary.withValues(alpha: 0.4)),
        ),
        child: GoopText(
          title.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: FontSizes.labelSmall * sf,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: flair.secondary,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    MpSession session,
    RunProvider rp,
    double sf,
    ThemeFlair flair,
  ) {
    switch (session.phase) {
      case MpPhase.permissionDenied:
        return _buildPermissionDenied(sf, flair);
      case MpPhase.error:
        return _buildError(session, sf, flair);
      case MpPhase.connected:
        return _buildConnected(session, rp, sf, flair);
      default:
        return _buildConnecting(session, rp, sf, flair);
    }
  }

  // ── Connecting ─────────────────────────────────────────────────

  Widget _buildConnecting(
    MpSession session,
    RunProvider rp,
    double sf,
    ThemeFlair flair,
  ) {
    final myChar = rp.gungeoneerByName(session.myCharacterName);
    final message = _connectingMessage(session);

    return _cardShell(
      accent: flair.primary,
      sf: sf,
      flair: flair,
      children: [
        if (session.runTitle.isNotEmpty)
          _runTitleChip(session.runTitle, sf, flair),
        // Portrait pair — wrapped in RepaintBoundary to isolate
        // the continuous pulse animation from the rest of the screen.
        RepaintBoundary(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: _Portrait(
                  character: myChar,
                  label: session.myNickname,
                  isMe: true,
                  pulse: _still ? null : _pulseCtrl,
                  sf: sf,
                  flair: flair,
                  avatarId: session.avatarId,
                  sub: session.myCharacterName,
                ),
              ),
              SizedBox(width: 20 * sf),
              // Pulsing link icon with animated glow ring
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, child) {
                    final t = _pulseCtrl.value;
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: flair.primary.withValues(
                              alpha: 0.15 + t * 0.2,
                            ),
                            blurRadius: 12 + t * 8,
                            spreadRadius: 2 + t * 2,
                          ),
                        ],
                      ),
                      child: FadeTransition(
                        opacity: _pulseCtrl,
                        child: Icon(
                          Icons.link_rounded,
                          size: 28 * sf,
                          color: flair.primary.withValues(alpha: 0.7),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: 20 * sf),
              Flexible(
                child: _Portrait(
                  character: null,
                  label: session.peerNickname ?? 'Partner',
                  isMe: false,
                  pulse: _still ? null : _pulseCtrl,
                  sf: sf,
                  flair: flair,
                  avatarId: session.peerAvatarId,
                  sub: session.peerCharacterName ?? '',
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 36 * sf),
        // Status message
        GoopText(
          message,
          style: TextStyle(
            fontSize: 15 * sf,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20 * sf),
        Center(
          child: SizedBox(
            width: 26 * sf,
            height: 26 * sf,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: flair.primary.withValues(alpha: 0.7),
            ),
          ),
        ),
        SizedBox(height: 28 * sf),
        Center(
          child: TextButton(
            onPressed: () {
              session.cancel();
              Navigator.of(context).pop();
            },
            child: GoopText(
              'CANCEL',
              style: TextStyle(
                fontSize: FontSizes.labelMedium * sf,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _connectingMessage(MpSession session) {
    // If we've discovered endpoints, show a more specific message.
    final foundEndpoints = session.discoveredEndpoints.isNotEmpty;
    switch (session.connectReason) {
      case MpConnectReason.hosting:
        return 'Waiting for a partner to join…';
      case MpConnectReason.browsing:
        return foundEndpoints
            ? 'Found games! Connecting…'
            : 'Searching for games…';
      case MpConnectReason.joining:
        return foundEndpoints
            ? 'Found host! Connecting…'
            : 'Searching for host…';
      case MpConnectReason.reconnecting:
        return 'Reconnecting to ${session.peerNickname ?? "partner"}…';
      case MpConnectReason.restoring:
        return 'Restoring your run…';
      case MpConnectReason.seeking:
        return foundEndpoints
            ? 'Found partner! Connecting…'
            : 'Seeking partner…';
    }
  }

  // ── Connected — VS splash + final handshake ────────────────────

  /// The versus screen both players see once the link is up. Big
  /// portraits flanking a pulsing VS medallion; the host must hit
  /// READY (fires `MpStartRun`) before either side drops into the
  /// run. Reconnects never reach this — they auto-enter instead.
  Widget _buildConnected(
    MpSession session,
    RunProvider rp,
    double sf,
    ThemeFlair flair,
  ) {
    final myChar = rp.gungeoneerByName(session.myCharacterName);
    final peerChar = rp.gungeoneerByName(session.peerCharacterName ?? '');
    final isMain = session.myRole == MpRole.main;
    final peerName = (session.peerNickname ?? 'Partner').toUpperCase();

    // Handshake resolved — show the brief "entering" beat while the
    // route pops back to the run.
    if (_navigatedToRun) {
      return _buildEntering(session, sf, flair);
    }

    return Stack(
      children: [
        // Drifting glow orbs — each side tinted by its player color.
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, _) {
                final t = _still ? 0.5 : _pulseCtrl.value;
                return CustomPaint(
                  painter: _VsGlowPainter(
                    left: flair.primary,
                    right: flair.secondary,
                    t: t,
                  ),
                );
              },
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20 * sf),
            child: Column(
              children: [
                SizedBox(height: 14 * sf),
                // Status row — connected pill + run title.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _VsChip(
                      icon: Icons.check_circle_rounded,
                      label: 'LINKED',
                      color: MpColors.connected,
                      sf: sf,
                    ),
                    if (session.runTitle.isNotEmpty) ...[
                      SizedBox(width: 8 * sf),
                      Flexible(
                        child: _VsChip(
                          icon: Icons.flag_outlined,
                          label: session.runTitle.toUpperCase(),
                          color: flair.secondary,
                          sf: sf,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 30 * sf),
                // The matchup — portraits huge, VS medallion between.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: _Portrait(
                        character: myChar,
                        label: session.myNickname,
                        isMe: true,
                        pulse: _still ? null : _pulseCtrl,
                        sf: sf,
                        flair: flair,
                        avatarId: session.avatarId,
                        sub: session.myCharacterName,
                        size: 108,
                        textScale: 1.45,
                      ),
                    ),
                    SizedBox(width: 10 * sf),
                    _VsMedallion(
                      ctrl: _still ? null : _pulseCtrl,
                      sf: sf,
                      flair: flair,
                    ),
                    SizedBox(width: 10 * sf),
                    Flexible(
                      child: _Portrait(
                        character: peerChar,
                        label: session.peerNickname ?? 'Partner',
                        isMe: false,
                        pulse: _still ? null : _pulseCtrl,
                        sf: sf,
                        flair: flair,
                        avatarId: session.peerAvatarId,
                        sub: session.peerCharacterName ?? '',
                        size: 108,
                        textScale: 1.45,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 34 * sf),
                // Handshake zone — host confirms, sidekick waits.
                if (isMain) ...[
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: flair.primary,
                      foregroundColor: Colors.white,
                      minimumSize: Size.fromHeight(58 * sf),
                      padding: EdgeInsets.symmetric(horizontal: 28 * sf),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: Icon(Icons.sports_mma_rounded, size: 24 * sf),
                    label: GoopText(
                      _mainConfirmed ? 'STARTING…' : 'READY — LET\'S GUNGEON',
                      style: TextStyle(
                        fontSize: 15 * sf,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    onPressed: _mainConfirmed ? null : _confirmAndStart,
                  ),
                  SizedBox(height: 10 * sf),
                  GoopText(
                    'You are MAIN — confirm to drop both of you in.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11 * sf,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ] else ...[
                  _WaitingForHost(
                    name: peerName,
                    ctrl: _still ? null : _pulseCtrl,
                    sf: sf,
                  ),
                  SizedBox(height: 10 * sf),
                  GoopText(
                    _hostWaitHint
                        ? 'Taking long? The host may have cancelled — '
                            'you can back out safely.'
                        : 'The host confirms to start the run.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11 * sf,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ],
                SizedBox(height: 20 * sf),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Transitional beat between handshake and the run — check pop +
  /// "ENTERING THE GUNGEON…" over the same VS glow.
  Widget _buildEntering(MpSession session, double sf, ThemeFlair flair) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, _) {
                final t = _still ? 0.5 : _pulseCtrl.value;
                return CustomPaint(
                  painter: _VsGlowPainter(
                    left: flair.primary,
                    right: flair.secondary,
                    t: t,
                  ),
                );
              },
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _checkPopCtrl,
                      curve: Curves.elasticOut,
                    ),
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 56 * sf,
                    color: MpColors.connected,
                  ),
                ),
                SizedBox(height: 14 * sf),
                GoopText(
                  'ENTERING THE GUNGEON…',
                  style: TextStyle(
                    fontSize: 17 * sf,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                SizedBox(height: 6 * sf),
                GoopText(
                  '${session.myNickname} vs ${session.peerNickname ?? 'Partner'}',
                  style: TextStyle(
                    fontSize: 12 * sf,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Error ──────────────────────────────────────────────────────

  Widget _buildError(MpSession session, double sf, ThemeFlair flair) {
    return _cardShell(
      accent: Colors.redAccent,
      sf: sf,
      flair: flair,
      children: [
        Icon(Icons.wifi_off_rounded, size: 48 * sf, color: Colors.redAccent),
        SizedBox(height: 16 * sf),
        GoopText(
          'Connection failed',
          style: TextStyle(
            fontSize: FontSizes.titleMedium * sf,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 8 * sf),
        GoopText(
          session.error ?? 'Something went wrong. Try again.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13 * sf,
            color: Colors.white.withValues(alpha: 0.6),
            height: 1.5,
          ),
        ),
        SizedBox(height: 12 * sf),
        GoopText(
          'Tip: Make sure both devices have Bluetooth and Wi-Fi on, '
          'and are within range.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11 * sf,
            color: Colors.white.withValues(alpha: 0.35),
            height: 1.4,
          ),
        ),
        SizedBox(height: 24 * sf),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: flair.primary,
            foregroundColor: Colors.white,
            minimumSize: Size.fromHeight(44 * sf),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: Icon(Icons.refresh_rounded, size: 20 * sf),
          label: GoopText(
            'RETRY',
            style: TextStyle(
              fontSize: 13 * sf,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          onPressed: () => session.reconnect(),
        ),
        SizedBox(height: 12 * sf),
        TextButton(
          onPressed: () {
            session.cancel();
            Navigator.of(context).pop();
          },
          child: GoopText(
            'CANCEL',
            style: TextStyle(
              fontSize: FontSizes.labelMedium * sf,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ),
      ],
    );
  }

  // ── Permission denied ──────────────────────────────────────────

  Widget _buildPermissionDenied(double sf, ThemeFlair flair) {
    return _cardShell(
      accent: Colors.amberAccent,
      sf: sf,
      flair: flair,
      children: [
        Icon(
          Icons.bluetooth_disabled_rounded,
          size: 48 * sf,
          color: Colors.amberAccent,
        ),
        SizedBox(height: 16 * sf),
        GoopText(
          'Permissions needed',
          style: TextStyle(
            fontSize: FontSizes.titleMedium * sf,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 8 * sf),
        GoopText(
          'GungeonMate needs Bluetooth and Wi-Fi permissions to connect devices.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13 * sf,
            color: Colors.white.withValues(alpha: 0.6),
            height: 1.5,
          ),
        ),
        SizedBox(height: 24 * sf),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: flair.primary,
            foregroundColor: Colors.white,
            minimumSize: Size.fromHeight(44 * sf),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: Icon(Icons.refresh_rounded, size: 20 * sf),
          label: GoopText(
            'RETRY',
            style: TextStyle(
              fontSize: 13 * sf,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          onPressed: () {
            // Re-request permissions and resume the connection
            // flow if granted. This handles the case where the
            // user granted permissions in OS settings and came
            // back — no need to go back to the lobby.
            final session = context.read<MpSession>();
            session.recheckPermissionsAndResume();
          },
        ),
        SizedBox(height: 12 * sf),
        TextButton.icon(
          onPressed: () {
            openAppSettings();
          },
          icon: Icon(
            Icons.settings_rounded,
            size: 18 * sf,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          label: GoopText(
            'OPEN DEVICE SETTINGS',
            style: TextStyle(
              fontSize: FontSizes.labelMedium * sf,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
        SizedBox(height: 12 * sf),
        TextButton(
          onPressed: () {
            context.read<MpSession>().cancel();
            Navigator.of(context).pop();
          },
          child: GoopText(
            'CANCEL',
            style: TextStyle(
              fontSize: FontSizes.labelMedium * sf,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ),
      ],
    );
  }

  String _titleForSession(MpSession session) {
    switch (session.connectReason) {
      case MpConnectReason.hosting:
        return 'HOSTING';
      case MpConnectReason.browsing:
        return 'FINDING GAMES';
      case MpConnectReason.joining:
        return 'CONNECTING';
      case MpConnectReason.reconnecting:
        return 'RECONNECTING';
      case MpConnectReason.restoring:
        return 'RESTORING';
      case MpConnectReason.seeking:
        return 'SEEKING';
    }
  }
}

// ── Portrait widget ─────────────────────────────────────────────

class _Portrait extends StatelessWidget {
  final Gungeoneer? character;
  final String label;
  final bool isMe;
  final Animation<double>? pulse;
  final double sf;
  final ThemeFlair flair;

  /// Chosen avatar id (with optional `:frame` suffix) — shown instead
  /// of the character sprite once the peer's identity is known.
  final String avatarId;

  /// Small secondary line under the nickname — the picked character.
  final String sub;

  /// Portrait edge length in sf units (84 = connecting card, 108 = VS splash).
  final double size;

  /// Multiplier on the name/character text sizes — splash runs bigger.
  final double textScale;

  const _Portrait({
    required this.character,
    required this.label,
    required this.isMe,
    required this.pulse,
    required this.sf,
    required this.flair,
    this.avatarId = '',
    this.sub = '',
    this.size = 84,
    this.textScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final color = isMe ? flair.primary : flair.secondary;
    return Column(
      children: [
        AnimatedBuilder(
          animation: pulse ?? const AlwaysStoppedAnimation(0.5),
          builder: (context, child) {
            final scale = pulse != null ? 0.92 + pulse!.value * 0.08 : 1.0;
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            width: size * sf,
            height: size * sf,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
              color: color.withValues(alpha: 0.08),
              boxShadow:
                  pulse != null
                      ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.15),
                          blurRadius: 16 * sf,
                          spreadRadius: 2 * sf,
                        ),
                      ]
                      : null,
            ),
            child:
                avatarId.isNotEmpty
                    ? FramedAvatar(
                      id: avatarId,
                      size: size * sf,
                      radius: 10,
                      idle: true,
                    )
                    : character != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.all(Radii.lg),
                      child: AvatarAura(
                        size: size * sf,
                        borderRadius: 16,
                        child: _characterImage(character!, sf, color),
                      ),
                    )
                    : Center(
                      child: Icon(
                        Icons.person_rounded,
                        size: size * sf * 0.43,
                        color: color.withValues(alpha: 0.4),
                      ),
                    ),
          ),
        ),
        SizedBox(height: 10 * sf),
        GoopText(
          label,
          style: TextStyle(
            fontSize: FontSizes.labelMedium * sf * textScale,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 2 * sf),
        GoopText(
          sub.isNotEmpty ? sub : (isMe ? 'You' : 'Partner'),
          style: TextStyle(
            fontSize: FontSizes.labelSmall * sf * textScale,
            fontWeight: FontWeight.w700,
            color: color.withValues(alpha: 0.65),
            letterSpacing: 1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _characterImage(Gungeoneer c, double sf, Color color) {
    final animPath = gungeoneerAnimatedCardPath(c.name);
    final gifPath = gungeoneerGifPath(c.name);
    final edge = size * sf;
    return SizedBox(
      width: edge,
      height: edge,
      child:
          animPath.isNotEmpty
              ? Image.asset(
                animPath,
                fit: BoxFit.contain,
                cacheWidth: (edge * 2).round(),
                cacheHeight: (edge * 2).round(),
                errorBuilder:
                    (_, _, _) =>
                        gifPath.isNotEmpty
                            ? Image.asset(
                              gifPath,
                              fit: BoxFit.contain,
                              cacheWidth: (edge * 2).round(),
                              cacheHeight: (edge * 2).round(),
                            )
                            : Icon(
                              Icons.person_rounded,
                              size: edge * 0.43,
                              color: color,
                            ),
              )
              : Icon(Icons.person_rounded, size: edge * 0.43, color: color),
    );
  }
}

// ── VS splash helpers ───────────────────────────────────────────

/// Small status chip used across the splash (LINKED / run title).
class _VsChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double sf;

  const _VsChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.sf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * sf, vertical: 4 * sf),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12 * sf, color: color),
          SizedBox(width: 5 * sf),
          Flexible(
            child: GoopText(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5 * sf,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Center medallion — breathing "VS" badge between the two portraits.
class _VsMedallion extends StatelessWidget {
  final Animation<double>? ctrl;
  final double sf;
  final ThemeFlair flair;

  const _VsMedallion({
    required this.ctrl,
    required this.sf,
    required this.flair,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: 46 * sf,
      height: 46 * sf,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            flair.primary.withValues(alpha: 0.9),
            flair.secondary.withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.65),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: flair.primary.withValues(alpha: 0.4),
            blurRadius: 18 * sf,
            spreadRadius: 2 * sf,
          ),
        ],
      ),
      child: Center(
        child: GoopText(
          'VS',
          style: TextStyle(
            fontSize: 15 * sf,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: Colors.white,
            shadows: const [
              Shadow(
                color: Colors.black54,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
    if (ctrl == null) return badge;
    return AnimatedBuilder(
      animation: ctrl!,
      builder:
          (_, child) =>
              Transform.scale(scale: 0.92 + ctrl!.value * 0.12, child: child),
      child: badge,
    );
  }
}

/// Sidekick handshake state — `WAITING FOR HOST` with staggered
/// pulsing dots driven by the shared pulse controller. [ctrl] is
/// null under reduced motion — renders a static mid-frame dot row.
class _WaitingForHost extends StatelessWidget {
  final String name;
  final AnimationController? ctrl;
  final double sf;

  const _WaitingForHost({
    required this.name,
    required this.ctrl,
    required this.sf,
  });

  @override
  Widget build(BuildContext context) {
    Widget dots(double t) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final phase = (t + i / 3) % 1.0;
          final a = 0.25 + 0.75 * (0.5 + 0.5 * math.sin(phase * math.pi * 2));
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 3 * sf),
            width: 6 * sf,
            height: 6 * sf,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: a.clamp(0.0, 1.0)),
            ),
          );
        }),
      );
    }

    return Column(
      children: [
        GoopText(
          'WAITING FOR $name',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15 * sf,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.6,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        SizedBox(height: 6 * sf),
        if (ctrl == null)
          dots(0.5)
        else
          AnimatedBuilder(
            animation: ctrl!,
            builder: (context, _) => dots(ctrl!.value),
          ),
      ],
    );
  }
}

/// Full-screen ambient wash for the VS splash — each player's color
/// blooms on their side and slowly drifts, like a fighting-game stage.
class _VsGlowPainter extends CustomPainter {
  _VsGlowPainter({required this.left, required this.right, required this.t});
  final Color left;
  final Color right;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final drift = math.sin(t * math.pi * 2) * size.width * 0.06;
    void orb(Alignment align, Color color, double radiusMul) {
      final center = align.alongSize(size);
      final paint =
          Paint()
            ..shader = RadialGradient(
              colors: [color.withValues(alpha: 0.14), Colors.transparent],
            ).createShader(
              Rect.fromCircle(
                center:
                    center +
                    Offset(drift * (align == Alignment.centerLeft ? 1 : -1), 0),
                radius: size.shortestSide * radiusMul,
              ),
            );
      canvas.drawRect(Offset.zero & size, paint);
    }

    orb(Alignment.centerLeft, left, 0.85);
    orb(Alignment.centerRight, right, 0.85);
    // Faint center vignette keeps the middle readable.
    final vg =
        Paint()
          ..shader = RadialGradient(
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
            stops: const [0.55, 1.0],
          ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vg);
  }

  @override
  bool shouldRepaint(_VsGlowPainter old) => old.t != t;
}
