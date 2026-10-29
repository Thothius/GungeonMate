import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_theme.dart';
import '../services/goop_talk_engine.dart';
import '../services/mp_session.dart';

/// Invisible widget that listens to [MpSession] for inbound
/// requests + response toasts and surfaces them as a global confirm/deny
/// dialog and a snackbar respectively. Mount once near the top of the
/// widget tree (HomeScreen) so any inventory page can produce these
/// without needing local plumbing.
///
/// Behaviour:
/// * `pendingRequest` non-null → shows a modal asking the local user to
///   approve/deny the peer's ask. Reply via
///   [MpSession.respondToPendingRequest].
/// * `lastResp` non-null → shows a one-shot snackbar
///   ("PeerName accepted X" / "denied X") then [consumeLastResp].
///
/// Reconnect dialogs + "Connection restored" snackbars are handled by
/// [MpReconnectBanner], not here.
class MpRequestListener extends StatefulWidget {
  final Widget child;
  const MpRequestListener({super.key, required this.child});

  @override
  State<MpRequestListener> createState() => _MpRequestListenerState();
}

class _MpRequestListenerState extends State<MpRequestListener> {
  bool _dialogShowing = false;
  String? _shownReqId;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<MpSession>();

    // Schedule UI work for after this build completes — `showDialog` /
    // `showSnackBar` mid-build is illegal.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeShowIncomingRequest(session);
      _maybeShowResponseToast(session);
    });

    return widget.child;
  }

  void _maybeShowIncomingRequest(MpSession session) {
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
        backgroundColor: AppTheme.flair.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
                color: AppTheme.flair.primary.withValues(alpha: 0.3),
                width: 1.5)),
        icon: const Icon(Icons.swap_horiz, size: 32),
        title: GoopText('$peerName wants ${req.name}',
            maxLines: 1, overflow: TextOverflow.ellipsis),
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
              // Guard: only respond if this is still the current request.
              if (session.pendingRequest?.reqId == req.reqId) {
                session.respondToPendingRequest(false);
              }
            },
            child: const GoopText('Deny'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.check, size: 18),
            label: const GoopText('Send'),
            onPressed: () {
              Navigator.pop(dialogCtx);
              // Guard: only respond if this is still the current request.
              if (session.pendingRequest?.reqId == req.reqId) {
                session.respondToPendingRequest(true);
              }
            },
          ),
        ],
      ),
    ).whenComplete(() {
      _dialogShowing = false;
    });
  }

  void _maybeShowResponseToast(MpSession session) {
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
