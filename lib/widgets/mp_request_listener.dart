import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_theme.dart';

import '../models/gungeoneer.dart';
import '../models/multiplayer_messages.dart';
import '../providers/run_provider.dart';
import '../services/multiplayer_session.dart';
import '../services/haptics.dart';
import '../utils/asset_paths.dart';
import '../services/goop_talk_engine.dart';

/// Invisible widget that listens to [MultiplayerSession] for inbound
/// requests + response toasts and surfaces them as a global confirm/deny
/// dialog and a snackbar respectively. Mount once near the top of the
/// widget tree (HomeScreen) so any inventory page can produce these
/// without needing local plumbing.
///
/// Behaviour:
/// * `pendingRequest` non-null → shows a modal asking the local user to
///   approve/deny the peer's ask. Reply via
///   [MultiplayerSession.respondToPendingRequest].
/// * `lastResp` non-null → shows a one-shot snackbar
///   ("PeerName accepted X" / "denied X") then [consumeLastResp].
class MpRequestListener extends StatefulWidget {
  final Widget child;
  const MpRequestListener({super.key, required this.child});

  @override
  State<MpRequestListener> createState() => _MpRequestListenerState();
}

class _MpRequestListenerState extends State<MpRequestListener> {
  bool _dialogShowing = false;
  String? _shownReqId;
  bool _dropDialogShowing = false;
  // Track the BuildContext of the open drop-dialog so we can close it
  // imperatively when the session reconnects (without coupling to the
  // user's own Navigator stack).
  BuildContext? _dropDialogCtx;

  bool _reconnectHubShowing = false;

  @override
  void initState() {
    super.initState();
    // Listen for reconnection success to show a themed confirmation.
    // Post-frame to ensure ScaffoldMessenger is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final session = context.read<MultiplayerSession>();
      session.reconnectSuccessNotifier.addListener(_onReconnectSuccess);
      session.showReconnectHubNotifier.addListener(_onReconnectHubRequest);
    });
  }

  @override
  void dispose() {
    // ponytail: context.read may fail in dispose if widget tree is torn
    // down, so guard with try/catch.
    try {
      final session = context.read<MultiplayerSession>();
      session.reconnectSuccessNotifier.removeListener(_onReconnectSuccess);
      session.showReconnectHubNotifier.removeListener(_onReconnectHubRequest);
    } catch (e) { debugPrint('[MpRequestListener] error: $e'); }
    super.dispose();
  }

  void _onReconnectSuccess() {
    if (!mounted) return;
    final session = context.read<MultiplayerSession>();
    if (!session.reconnectSuccessNotifier.value) return;
    session.reconnectSuccessNotifier.value = false;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi_protected_setup, color: Color(0xFF00E676), size: 18),
            SizedBox(width: 10),
            GoopText('Connection restored!', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        backgroundColor: AppTheme.flair.card,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF00E676), width: 1.5),
        ),
      ),
    );
  }

  void _onReconnectHubRequest() {
    if (!mounted) return;
    final session = context.read<MultiplayerSession>();
    if (!session.showReconnectHubNotifier.value) return;
    session.showReconnectHubNotifier.value = false;

    // Close drop dialog if open — the Reconnection Hub replaces it.
    if (_dropDialogShowing) {
      final ctx = _dropDialogCtx;
      if (ctx != null && Navigator.of(ctx).canPop()) {
        Navigator.of(ctx).pop();
      }
    }

    if (_reconnectHubShowing) return;
    _reconnectHubShowing = true;

    // Auto-save immediately so both devices have a fresh restore point.
    unawaited(session.saveCurrentSession());

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: const Color(0xFF0D1117),
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, __, ___) => _ReconnectScreen(session: session),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    ).whenComplete(() {
      _reconnectHubShowing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<MultiplayerSession>();

    // Schedule UI work for after this build completes — `showDialog` /
    // `showSnackBar` mid-build is illegal.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeShowIncomingRequest(session);
      _maybeShowResponseToast(session);
      _maybeShowDropDialog(session);
    });

    return widget.child;
  }

  /// While the session is in the `disconnected` state (and is therefore
  /// auto-reconnecting in the background), show a non-dismissable modal
  /// so the user can't add items in a desynced state. Auto-closes the
  /// moment we're connected again.
  void _maybeShowDropDialog(MultiplayerSession session) {
    final shouldShow = session.status == MpStatus.disconnected;
    if (shouldShow && !_dropDialogShowing) {
      _dropDialogShowing = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) {
          _dropDialogCtx = dialogCtx;
          return PopScope(
            canPop: false,
            child: AlertDialog(
              backgroundColor: AppTheme.flair.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.orangeAccent, width: 1.5),
              ),
              icon: const Icon(Icons.wifi_off_rounded, size: 36, color: Colors.orangeAccent),
              title: const GoopText(
                'Connection lost',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
              content: ListenableBuilder(
                listenable: session,
                builder: (context, _) {
                  final att = session.autoReconnectAttempts;
                  final isRetrying = session.isAutoReconnecting;
                  final gone = session.peerLikelyGone;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GoopText(
                        isRetrying && att > 0
                            ? 'Trying to reconnect to your peer…\n'
                              'Auto-retry attempt #$att\n\n'
                              "Don't add or remove items right now — your changes "
                              "won't sync until the link is restored."
                            : 'Trying to reconnect to your peer…\n\n'
                              "Don't add or remove items right now — your changes "
                              "won't sync until the link is restored.",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                      if (gone) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4), width: 1),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: GoopText(
                                  'Peer seems unreachable after many attempts. Try RE-PAIR to manually reconnect.',
                                  style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  icon: const Icon(Icons.close, size: 14),
                  label: const GoopText('DISCONNECT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    session.cancel();
                  },
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.cyanAccent,
                        side: const BorderSide(color: Colors.cyanAccent),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      icon: const Icon(Icons.key, size: 14),
                      label: const GoopText('RE-PAIR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        session.requestReconnectHub();
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      icon: const Icon(Icons.refresh, size: 14),
                      label: const GoopText('RETRY NOW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                      onPressed: () {
                        session.reconnect();
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ).whenComplete(() {
        _dropDialogShowing = false;
        _dropDialogCtx = null;
      });
    } else if (!shouldShow && _dropDialogShowing) {
      // Reconnected (or session torn down): close the dialog if still up.
      final ctx = _dropDialogCtx;
      if (ctx != null && Navigator.of(ctx).canPop()) {
        Navigator.of(ctx).pop();
      }
      // Distinguish a real reconnect from a teardown/cancel: only the
      // former transitions back into handshaking/connected. Teardown goes
      // to idle/error — no "restored" feedback there.
      final s = session.status;
      if (s == MpStatus.connected || s == MpStatus.handshaking) {
        Haptics.success();
        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger?.showSnackBar(SnackBar(
          content: const GoopText(
            'Connection restored — sync resumed',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          duration: const Duration(milliseconds: 1800),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _maybeShowIncomingRequest(MultiplayerSession session) {
    final req = session.pendingRequest;
    if (req == null) {
      _shownReqId = null;
      return;
    }
    if (_dialogShowing) return;
    if (_shownReqId == req.reqId) return;
    _shownReqId = req.reqId;
    _dialogShowing = true;
    final peerName = session.peerNickname ?? 'Peer';
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        icon: const Icon(Icons.swap_horiz, size: 32),
        title: GoopText('$peerName wants ${req.name}', maxLines: 1, overflow: TextOverflow.ellipsis),
        content: GoopText(
          'Send your ${req.kind == 'gun' ? 'gun' : 'item'} '
          '"${req.name}" to $peerName?',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              session.respondToPendingRequest(false);
            },
            child: const GoopText('Deny'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.check, size: 18),
            label: const GoopText('Send'),
            onPressed: () {
              Navigator.pop(dialogCtx);
              session.respondToPendingRequest(true);
            },
          ),
        ],
      ),
    ).whenComplete(() {
      _dialogShowing = false;
    });
  }

  void _maybeShowResponseToast(MultiplayerSession session) {
    final r = session.lastResp;
    if (r == null) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final peer = session.peerNickname ?? 'Peer';
    messenger.showSnackBar(SnackBar(
      content: GoopText(
        r.approved
            ? '$peer sent you ${r.name}'
            : '$peer denied your request for ${r.name}',
      ),
      duration: const Duration(milliseconds: 1800),
    ));
    session.consumeLastResp();
  }
}

/// Fullscreen Reconnection screen — shown when the user taps FIX LINK
/// or RE-PAIR. Provides a manual re-pair flow with animated gungeoneer
/// portraits, big buttons, and PIN display/entry.
/// - Main Player: displays their PIN for the Sidekick to enter
/// - Sidekick: enters the Main's PIN, then taps RECONNECT
/// Both sides auto-save before the screen opens. Auto-closes when
/// connection is restored.
class _ReconnectScreen extends StatefulWidget {
  final MultiplayerSession session;
  const _ReconnectScreen({required this.session});

  @override
  State<_ReconnectScreen> createState() => _ReconnectScreenState();
}

class _ReconnectScreenState extends State<_ReconnectScreen> {
  final _pinCtrl = TextEditingController();
  bool _isMain = false;
  bool _reconnecting = false;

  @override
  void initState() {
    super.initState();
    _isMain = widget.session.myRole == MpRole.main;
    if (!_isMain && widget.session.pinCode != null) {
      _pinCtrl.text = widget.session.pinCode!;
    }
    widget.session.reconnectSuccessNotifier.addListener(_onReconnected);
  }

  @override
  void dispose() {
    widget.session.reconnectSuccessNotifier.removeListener(_onReconnected);
    _pinCtrl.dispose();
    super.dispose();
  }

  void _onReconnected() {
    if (!mounted) return;
    if (!widget.session.reconnectSuccessNotifier.value) return;
    widget.session.reconnectSuccessNotifier.value = false;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _doReconnect() async {
    if (_reconnecting) return;
    if (!_isMain) {
      final pin = _pinCtrl.text.trim();
      if (pin.length != 4 || int.tryParse(pin) == null) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: GoopText('Enter a valid 4-digit PIN from the host.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      widget.session.setPinCode(pin);
    }
    setState(() => _reconnecting = true);
    await widget.session.fullReconnectCycle();
    if (mounted) setState(() => _reconnecting = false);
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return PopScope(
      canPop: false,
      child: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final status = session.status;
          final connected = status == MpStatus.connected;
          final searching = status == MpStatus.searching;
          final handshaking = status == MpStatus.handshaking;

          // Resolve both players' character + nickname
          final myChar = session.lastCharacter;
          final myNick = session.lastNickname;
          final peerCharName = session.peerCharacterName;
          final peerNick = session.peerNickname;

          // For peer character, try to resolve from name; fallback null
          Gungeoneer? peerChar;
          if (peerCharName != null && peerCharName.isNotEmpty) {
            try {
              final rp = context.read<RunProvider>();
              peerChar = rp.gungeoneerByName(peerCharName);
            } catch (e) { debugPrint('[MpRequestListener] error: $e'); }
          }

          final accent = connected ? const Color(0xFF00E676) : Colors.cyanAccent;

          return Scaffold(
            backgroundColor: const Color(0xFF0D1117),
            body: SafeArea(
              child: Column(
                children: [
                  // Top bar — title + close
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              connected ? Icons.wifi_protected_setup : Icons.link,
                              color: accent,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            GoopText(
                              connected ? 'Connected!' : 'Reconnection Hub',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          tooltip: 'Close',
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  // Player portraits row
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _PortraitCard(
                            character: myChar,
                            nickname: myNick,
                            slotLabel: _isMain ? 'P1 · MAIN' : 'P2 · SIDEKICK',
                            accent: _isMain ? Colors.cyanAccent : Colors.purpleAccent,
                            isMe: true,
                          ),
                          // VS divider
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                connected ? Icons.link : Icons.link_off,
                                color: connected ? const Color(0xFF00E676) : Colors.white24,
                                size: 32,
                              ),
                              const SizedBox(height: 4),
                              GoopText(
                                connected ? 'LINKED' : 'BROKEN',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  color: connected ? const Color(0xFF00E676) : Colors.white24,
                                ),
                              ),
                            ],
                          ),
                          _PortraitCard(
                            character: peerChar,
                            nickname: peerNick ?? 'Waiting…',
                            slotLabel: _isMain ? 'P2 · SIDEKICK' : 'P1 · MAIN',
                            accent: _isMain ? Colors.purpleAccent : Colors.cyanAccent,
                            isMe: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Status + save indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        GoopText(
                          connected
                              ? 'Link restored with ${session.peerNickname ?? 'peer'}!'
                              : searching
                                  ? 'Searching for peer…'
                                  : handshaking
                                      ? 'Handshaking with peer…'
                                      : 'Run saved locally. Ready to re-pair.',
                          style: TextStyle(
                            color: connected ? const Color(0xFF00E676) : Colors.white70,
                            fontSize: 14,
                            fontWeight: connected ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_outlined,
                                size: 16,
                                color: Colors.green.withValues(alpha: 0.7)),
                            const SizedBox(width: 6),
                            GoopText(
                              'Run state saved to device',
                              style: TextStyle(
                                color: Colors.green.withValues(alpha: 0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (session.autoReconnectAttempts > 0 && !connected) ...[
                          const SizedBox(height: 6),
                          GoopText(
                            'Auto-retry attempt #${session.autoReconnectAttempts}',
                            style: TextStyle(
                              color: Colors.orange.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // PIN display / entry
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      child: _isMain ? _buildPinDisplay(session, accent) : _buildPinEntry(connected),
                    ),
                  ),
                  // Big action buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: connected
                                  ? const Color(0xFF00E676)
                                  : Colors.cyanAccent,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              shadowColor: accent.withValues(alpha: 0.4),
                            ),
                            icon: _reconnecting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5, color: Colors.black),
                                  )
                                : Icon(
                                    connected ? Icons.check_circle : Icons.refresh,
                                    size: 24,
                                  ),
                            label: GoopText(
                              connected ? 'DONE' : 'RECONNECT',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            onPressed: connected
                                ? () {
                                    if (Navigator.of(context).canPop()) {
                                      Navigator.of(context).pop();
                                    }
                                  }
                                : _reconnecting
                                    ? null
                                    : _doReconnect,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.close, size: 20),
                            label: const GoopText(
                              'DISCONNECT',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            onPressed: () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                              session.cancel();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPinDisplay(MultiplayerSession session, Color accent) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GoopText(
          'YOUR CONNECTION PIN',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: accent,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.5),
          ),
          child: GoopText(
            session.pinCode ?? '----',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 12,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const GoopText(
          'Share this PIN with your Sidekick.\nBoth players should tap RECONNECT.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildPinEntry(bool connected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GoopText(
          'ENTER HOST PIN',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.cyanAccent,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pinCtrl,
          keyboardType: TextInputType.number,
          maxLength: 4,
          enabled: !connected && !_reconnecting,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: 12,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            counterText: '',
            hintText: '----',
            hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.2), letterSpacing: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.cyanAccent, width: 2),
            ),
            filled: true,
            fillColor: Colors.cyanAccent.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 12),
        const GoopText(
          'Ask the Main Player for their 4-digit PIN,\nthen tap RECONNECT.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }
}

/// Animated gungeoneer portrait card for the reconnect screen.
class _PortraitCard extends StatelessWidget {
  final Gungeoneer? character;
  final String nickname;
  final String slotLabel;
  final Color accent;
  final bool isMe;

  const _PortraitCard({
    required this.character,
    required this.nickname,
    required this.slotLabel,
    required this.accent,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final charName = character?.name ?? 'Unknown';
    final animPath = gungeoneerAnimatedCardPath(charName);
    final gifPath = gungeoneerGifPath(charName);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Slot label badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent.withValues(alpha: 0.4), width: 1),
          ),
          child: GoopText(
            slotLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: accent,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Animated portrait
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 120,
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accent.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.1),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Try animated card first, then gif, then static icon, then placeholder
                if (animPath.isNotEmpty)
                  Image.asset(
                    animPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => gifPath.isNotEmpty
                        ? Image.asset(
                            gifPath,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _placeholderIcon(accent),
                          )
                        : _placeholderIcon(accent),
                  )
                else if (gifPath.isNotEmpty)
                  Image.asset(
                    gifPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _placeholderIcon(accent),
                  )
                else
                  _placeholderIcon(accent),
                // "YOU" badge overlay
                if (isMe)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const GoopText(
                        'YOU',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Character name
        GoopText(
          charName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.85),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        // Nickname
        GoopText(
          nickname,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: accent,
          ),
        ),
      ],
    );
  }

  Widget _placeholderIcon(Color accent) {
    return Icon(
      Icons.person,
      size: 48,
      color: accent.withValues(alpha: 0.4),
    );
  }
}
