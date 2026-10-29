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
  bool _navigatedToRun = false;

  @override
  void initState() {
    super.initState();
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
  void dispose() {
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

    // Auto-navigate to active run when connected (with a brief delay
    // so the user sees the "Connected!" success state).
    if (session.phase == MpPhase.connected && !_navigatedToRun) {
      _navigatedToRun = true;
      _checkPopCtrl.forward();
      final navigator = Navigator.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Haptics.success();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          navigator.popUntil((route) => route.isFirst);
        });
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: BottomBackBar(
        onPressed: () {
          if (session.isActive) session.cancel();
          Navigator.of(context).pop();
        },
      ),
      body: SafeArea(
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
            Expanded(child: _buildContent(session, rp, sf, flair)),
          ],
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

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32 * sf),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Portrait pair — wrapped in RepaintBoundary to isolate
            // the continuous pulse animation from the rest of the screen.
            RepaintBoundary(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Portrait(
                    character: myChar,
                    label: session.myNickname,
                    isMe: true,
                    pulse: _pulseCtrl,
                    sf: sf,
                    flair: flair,
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
                  _Portrait(
                    character: null,
                    label: session.peerNickname ?? 'Partner',
                    isMe: false,
                    pulse: _pulseCtrl,
                    sf: sf,
                    flair: flair,
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
            SizedBox(
              width: 26 * sf,
              height: 26 * sf,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: flair.primary.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 36 * sf),
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
                  letterSpacing: 0.5,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
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

  // ── Connected ──────────────────────────────────────────────────

  Widget _buildConnected(
    MpSession session,
    RunProvider rp,
    double sf,
    ThemeFlair flair,
  ) {
    final myChar = rp.gungeoneerByName(session.myCharacterName);
    final peerChar = rp.gungeoneerByName(session.peerCharacterName ?? '');

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32 * sf),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Portrait(
                  character: myChar,
                  label: session.myNickname,
                  isMe: true,
                  pulse: null,
                  sf: sf,
                  flair: flair,
                ),
                SizedBox(width: 20 * sf),
                Icon(
                  Icons.link_rounded,
                  size: 28 * sf,
                  color: MpColors.connected,
                ),
                SizedBox(width: 20 * sf),
                _Portrait(
                  character: peerChar,
                  label: session.peerNickname ?? 'Partner',
                  isMe: false,
                  pulse: null,
                  sf: sf,
                  flair: flair,
                ),
              ],
            ),
            SizedBox(height: 32 * sf),
            // Checkmark pops in with a spring-like scale animation.
            ScaleTransition(
              scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _checkPopCtrl,
                  curve: Curves.elasticOut,
                ),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 48 * sf,
                color: MpColors.connected,
              ),
            ),
            SizedBox(height: 12 * sf),
            GoopText(
              'Connected!',
              style: TextStyle(
                fontSize: FontSizes.titleLarge * sf,
                fontWeight: FontWeight.w900,
                color: MpColors.connected,
              ),
            ),
            SizedBox(height: 8 * sf),
            GoopText(
              '${session.myNickname} & ${session.peerNickname ?? "Partner"}',
              style: TextStyle(
                fontSize: 13 * sf,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 24 * sf),
            GoopText(
              'Entering the Gungeon…',
              style: TextStyle(
                fontSize: FontSizes.labelMedium * sf,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────────────

  Widget _buildError(MpSession session, double sf, ThemeFlair flair) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32 * sf),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 48 * sf,
              color: Colors.redAccent,
            ),
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
        ),
      ),
    );
  }

  // ── Permission denied ──────────────────────────────────────────

  Widget _buildPermissionDenied(double sf, ThemeFlair flair) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32 * sf),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
        ),
      ),
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

  const _Portrait({
    required this.character,
    required this.label,
    required this.isMe,
    required this.pulse,
    required this.sf,
    required this.flair,
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
            width: 84 * sf,
            height: 84 * sf,
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
                character != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.all(Radii.lg),
                      child: AvatarAura(
                        size: 84 * sf,
                        borderRadius: 16,
                        child: _characterImage(character!, sf, color),
                      ),
                    )
                    : Center(
                      child: Icon(
                        Icons.person_rounded,
                        size: 36 * sf,
                        color: color.withValues(alpha: 0.4),
                      ),
                    ),
          ),
        ),
        SizedBox(height: 10 * sf),
        GoopText(
          label,
          style: TextStyle(
            fontSize: FontSizes.labelMedium * sf,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.8),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 2 * sf),
        GoopText(
          isMe ? 'You' : 'Partner',
          style: TextStyle(
            fontSize: FontSizes.labelSmall * sf,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.6),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _characterImage(Gungeoneer c, double sf, Color color) {
    final animPath = gungeoneerAnimatedCardPath(c.name);
    final gifPath = gungeoneerGifPath(c.name);
    return SizedBox(
      width: 84 * sf,
      height: 84 * sf,
      child:
          animPath.isNotEmpty
              ? Image.asset(
                animPath,
                fit: BoxFit.contain,
                cacheWidth: 168,
                cacheHeight: 168,
                errorBuilder:
                    (_, __, ___) =>
                        gifPath.isNotEmpty
                            ? Image.asset(
                              gifPath,
                              fit: BoxFit.contain,
                              cacheWidth: 168,
                              cacheHeight: 168,
                            )
                            : Icon(
                              Icons.person_rounded,
                              size: 36 * sf,
                              color: color,
                            ),
              )
              : Icon(Icons.person_rounded, size: 36 * sf, color: color),
    );
  }
}
