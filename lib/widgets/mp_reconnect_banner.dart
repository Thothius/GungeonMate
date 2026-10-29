import '../theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/multiplayer_messages.dart';
import '../services/app_theme.dart';
import '../services/goop_talk_engine.dart';
import '../services/haptics.dart';
import '../services/mp_session.dart';
import '../utils/responsive.dart';

/// Dismissable reconnect dialog + persistent banner.
///
/// When the peer drops ([MpSession.reconnectNotifier] fires):
/// - Shows a dismissable modal dialog: "Connection lost — reconnecting…"
/// - DISMISS → closes dialog, user keeps using the app. A small
///   persistent banner stays at the top: "Reconnecting… (tap to cancel)".
/// - CANCEL RUN → tears down the session.
/// - Auto-closes when [MpSession.reconnectSuccessNotifier] fires.
///
/// Mounted in HomeScreen. No log lines, no attempt counters, no
/// "peer seems gone" warnings. Either it reconnects or the user cancels.
class MpReconnectBanner extends StatefulWidget {
  final Widget child;
  const MpReconnectBanner({super.key, required this.child});

  @override
  State<MpReconnectBanner> createState() => _MpReconnectBannerState();
}

class _MpReconnectBannerState extends State<MpReconnectBanner> {
  bool _dialogShowing = false;
  BuildContext? _dialogCtx;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final session = context.read<MpSession>();
      session.reconnectNotifier.addListener(_onReconnectRequested);
      session.reconnectSuccessNotifier.addListener(_onReconnectSuccess);
    });
  }

  @override
  void dispose() {
    try {
      final session = context.read<MpSession>();
      session.reconnectNotifier.removeListener(_onReconnectRequested);
      session.reconnectSuccessNotifier.removeListener(_onReconnectSuccess);
    } catch (_) {}
    super.dispose();
  }

  void _onReconnectRequested() {
    if (!mounted) return;
    final session = context.read<MpSession>();
    if (!session.reconnectNotifier.value) return;
    // Auto-reset the notifier.
    session.reconnectNotifier.value = false;
    // Paradox Mode shows reconnect status inline in the ParadoxBar —
    // no modal dialog, no double banner (the old "two bars" bug).
    if (session.isParadox) return;
    if (_dialogShowing) return;
    _showReconnectDialog();
  }

  void _onReconnectSuccess() {
    if (!mounted) return;
    final session = context.read<MpSession>();
    if (!session.reconnectSuccessNotifier.value) return;
    session.reconnectSuccessNotifier.value = false;

    // Close dialog if open.
    _closeDialog();

    // Show a brief "Connected again" confirmation snackbar.
    Haptics.success();
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: GoopText('Connected again',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.95))),
        backgroundColor: AppTheme.flair.card,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radii.md),
          side: BorderSide(
              color: AppTheme.flair.primary.withValues(alpha: 0.4),
              width: 1.0),
        ),
      ),
    );
  }

  void _closeDialog() {
    if (_dialogShowing && _dialogCtx != null) {
      final ctx = _dialogCtx;
      if (ctx != null && Navigator.of(ctx).canPop()) {
        Navigator.of(ctx).pop();
      }
    }
    _dialogShowing = false;
    _dialogCtx = null;
    _dismissed = false;
  }

  void _showReconnectDialog() {
    _dialogShowing = true;
    bool cancelling = false;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        _dialogCtx = dialogCtx;
        return _ReconnectDialog(
          onDismiss: () {
            // Called by the DISMISS button — pop the dialog.
            Navigator.pop(dialogCtx);
          },
          onDismissed: () {
            // Called after the dialog is popped (by button or
            // barrier tap) — update state without popping again.
            // Skip if cancelling (cancel handles its own state).
            if (cancelling) return;
            _dialogShowing = false;
            _dismissed = true;
            setState(() {}); // Rebuild to show persistent banner
          },
          onCancelRun: () {
            cancelling = true;
            Navigator.pop(dialogCtx);
            _dialogShowing = false;
            _dismissed = false;
            context.read<MpSession>().cancel();
          },
        );
      },
    ).whenComplete(() {
      _dialogShowing = false;
      _dialogCtx = null;
    });
  }

  void _reopenDialog() {
    _dismissed = false;
    setState(() {});
    _showReconnectDialog();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<MpSession>();
    final showBanner = _dismissed &&
        session.phase == MpPhase.disconnected;

    return Column(
      children: [
        if (showBanner) SafeArea(
          bottom: false,
          child: _PersistentBanner(
            onTap: _reopenDialog,
            onCancel: () {
              session.cancel();
              setState(() => _dismissed = false);
            },
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}

// ── Reconnect dialog ────────────────────────────────────────────

class _ReconnectDialog extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback onDismissed;
  final VoidCallback onCancelRun;

  const _ReconnectDialog({
    required this.onDismiss,
    required this.onDismissed,
    required this.onCancelRun,
  });

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final sf = Responsive.factor(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        // When popped (by barrier tap or system back), update
        // state without popping again — the route is already gone.
        if (didPop) onDismissed();
      },
      child: AlertDialog(
        backgroundColor: flair.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radii.lg),
          side: const BorderSide(color: MpColors.reconnecting, width: 1.5),
        ),
        icon: const Icon(Icons.wifi_off_rounded,
            size: 36, color: MpColors.reconnecting),
        title: GoopText('Connection lost',
            style: TextStyle(
                color: onSurface,
                fontWeight: FontWeight.w900,
                fontSize: FontSizes.titleMedium,
                letterSpacing: 0.5)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GoopText(
              'Reconnecting to your partner automatically…\n\n'
              'Your run is preserved. You can dismiss this and keep playing — '
              'changes will sync when the connection is restored.',
              style: TextStyle(
                  color: onSurface.withValues(alpha: 0.7),
                  fontSize: 12.5,
                  height: 1.4),
            ),
            SizedBox(height: 16 * sf),
            Center(
              child: SizedBox(
                width: 24 * sf,
                height: 24 * sf,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: MpColors.reconnecting.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: MpColors.danger,
              side: const BorderSide(color: MpColors.danger, width: 1.5),
              padding: EdgeInsets.symmetric(
                  horizontal: 12 * sf, vertical: 10 * sf),
            ),
            icon: const Icon(Icons.close, size: 16),
            label: GoopText('CANCEL RUN',
                style: TextStyle(
                    fontSize: 11 * sf, fontWeight: FontWeight.bold)),
            onPressed: onCancelRun,
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: MpColors.reconnecting,
              foregroundColor: const Color(0xFF1E1E22),
              padding: EdgeInsets.symmetric(
                  horizontal: 14 * sf, vertical: 10 * sf),
            ),
            icon: const Icon(Icons.visibility_off, size: 16),
            label: GoopText('DISMISS',
                style: TextStyle(
                    fontSize: 11 * sf, fontWeight: FontWeight.w900)),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

// ── Persistent banner (after dismiss) ───────────────────────────

class _PersistentBanner extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback onCancel;

  const _PersistentBanner({
    required this.onTap,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);

    return Material(
      color: MpColors.reconnecting.withValues(alpha: 0.12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: 16 * sf, vertical: 10 * sf),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: MpColors.reconnecting.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 14 * sf,
                height: 14 * sf,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: MpColors.reconnecting.withValues(alpha: 0.8),
                ),
              ),
              SizedBox(width: 10 * sf),
              Expanded(
                child: GoopText(
                  'Reconnecting…',
                  style: TextStyle(
                      fontSize: FontSizes.labelMedium * sf,
                      fontWeight: FontWeight.w600,
                      color: MpColors.reconnecting),
                ),
              ),
              GestureDetector(
                onTap: onCancel,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8 * sf, vertical: 4 * sf),
                  child: Icon(Icons.close_rounded,
                      size: 16 * sf,
                      color: MpColors.reconnecting.withValues(alpha: 0.7)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
