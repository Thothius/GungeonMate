import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/multiplayer_messages.dart';
import '../services/multiplayer_session.dart';

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
    } catch (_) {}
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
            Text('Connection restored!', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        backgroundColor: const Color(0xFF1E1E22),
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

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return _ReconnectHubDialog(session: session);
      },
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
              backgroundColor: const Color(0xFF1E1E22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.orangeAccent, width: 1.5),
              ),
              icon: const Icon(Icons.wifi_off_rounded, size: 36, color: Colors.orangeAccent),
              title: const Text(
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
                      Text(
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
                                child: Text(
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
                  label: const Text('DISCONNECT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                      label: const Text('RE-PAIR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                      label: const Text('RETRY NOW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
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
        title: Text('$peerName wants ${req.name}'),
        content: Text(
          'Send your ${req.kind == 'gun' ? 'gun' : 'item'} '
          '"${req.name}" to $peerName?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              session.respondToPendingRequest(false);
            },
            child: const Text('Deny'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Send'),
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
      content: Text(
        r.approved
            ? '$peer sent you ${r.name}'
            : '$peer denied your request for ${r.name}',
      ),
      duration: const Duration(milliseconds: 1800),
    ));
    session.consumeLastResp();
  }
}

/// Reconnection Hub dialog — shown when the user taps FIX LINK or
/// RE-PAIR. Provides a manual re-pair flow:
/// - Main Player: displays their PIN for the Sidekick to enter
/// - Sidekick: enters the Main's PIN, then taps RECONNECT
/// Both sides auto-save before the dialog opens. Auto-closes when
/// connection is restored.
class _ReconnectHubDialog extends StatefulWidget {
  final MultiplayerSession session;
  const _ReconnectHubDialog({required this.session});

  @override
  State<_ReconnectHubDialog> createState() => _ReconnectHubDialogState();
}

class _ReconnectHubDialogState extends State<_ReconnectHubDialog> {
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
            content: Text('Enter a valid 4-digit PIN from the host.'),
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

          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: connected ? const Color(0xFF00E676) : Colors.cyanAccent,
                width: 1.5,
              ),
            ),
            icon: Icon(
              connected ? Icons.wifi_protected_setup : Icons.link,
              size: 36,
              color: connected ? const Color(0xFF00E676) : Colors.cyanAccent,
            ),
            title: Text(
              connected ? 'Connected!' : 'Reconnection Hub',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  connected
                      ? 'Link restored with ${session.peerNickname ?? 'peer'}!'
                      : searching
                          ? 'Searching for peer…'
                          : handshaking
                              ? 'Handshaking with peer…'
                              : 'Run saved locally. Ready to re-pair.',
                  style: TextStyle(
                    color: connected ? const Color(0xFF00E676) : Colors.white70,
                    fontSize: 12.5,
                    fontWeight: connected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.save_outlined,
                        size: 14,
                        color: Colors.green.withValues(alpha: 0.7)),
                    const SizedBox(width: 6),
                    Text(
                      'Run state saved to device',
                      style: TextStyle(
                        color: Colors.green.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isMain) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'YOUR CONNECTION PIN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.cyanAccent,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          session.pinCode ?? '----',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Share this PIN with your Sidekick.\nBoth players should tap RECONNECT.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.4),
                  ),
                ] else ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ENTER HOST PIN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.cyanAccent,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pinCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    enabled: !connected && !_reconnecting,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '----',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), letterSpacing: 8),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.cyanAccent),
                      ),
                      filled: true,
                      fillColor: Colors.cyanAccent.withValues(alpha: 0.05),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ask the Main Player for their 4-digit PIN,\nthen tap RECONNECT.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.4),
                  ),
                ],
                if (session.autoReconnectAttempts > 0 && !connected) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Auto-retry attempt #${session.autoReconnectAttempts}',
                    style: TextStyle(color: Colors.orange.withValues(alpha: 0.7), fontSize: 10),
                  ),
                ],
              ],
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
                label: const Text('CLOSE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: connected ? const Color(0xFF00E676) : Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: _reconnecting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : Icon(connected ? Icons.check : Icons.refresh, size: 14),
                label: Text(
                  connected ? 'DONE' : 'RECONNECT',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
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
            ],
          );
        },
      ),
    );
  }
}
