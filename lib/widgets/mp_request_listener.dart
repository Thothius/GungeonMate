import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
              content: const Text(
                'Trying to reconnect to your peer…\n\n'
                "Don't add or remove items right now — your changes "
                "won't sync until the link is restored.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                  height: 1.4,
                ),
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
