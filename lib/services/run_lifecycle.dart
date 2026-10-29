import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/multiplayer_messages.dart';
import '../providers/run_provider.dart';
import '../widgets/active_run/end_run_confirm_dialog.dart';
import 'mp_session.dart';

/// The ONE end-run path. Every UI entry point — classic header menu,
/// paradox bar, paradox player panel, pause overlay, settings — goes
/// through [confirmEndRun] so the flow can't drift into per-caller
/// variants again (previously: 6 copies, 3 different dialogs, and
/// divergent run-state semantics).
///
/// END RUN semantics: the run is over, period. Sheets/dialogs close,
/// MP tears down (peer notified via MpEndRun), chat + event logs wipe,
/// and local run state resets — landing on the main menu.
class RunLifecycle {
  RunLifecycle._();

  /// Shows the Lord-of-the-Jammed fullscreen confirm, then ends the
  /// run. The dialog dismisses itself before [endRun] runs.
  static Future<void> confirmEndRun(BuildContext context) {
    final session = context.read<MpSession>();
    final isSidekick = session.isActive && session.myRole == MpRole.sidekick;
    return EndRunConfirmDialog.show(
      context,
      isSidekick: isSidekick,
      onConfirm: () => endRun(context),
    );
  }

  /// Ends the run — no confirm. Order matters:
  /// 1. Close every sheet/dialog/menu above the run — nothing may
  ///    survive the state wipe (a stale sheet holding a disposed
  ///    context is a crash vector).
  /// 2. Tear down MP — [MpSession.cancel] sends MpEndRun to the peer
  ///    and unwinds role/restore bookkeeping.
  /// 3. Wipe session activity — chat history, queued sends, unread
  ///    counter, and the unified event log.
  /// 4. Reset local run state → home falls back to the main menu.
  static Future<void> endRun(BuildContext context) async {
    final session = context.read<MpSession>();
    final p = context.read<RunProvider>();
    Navigator.maybeOf(context, rootNavigator: true)?.popUntil((r) => r.isFirst);
    if (session.isActive) {
      await session.cancel();
    }
    session.wipeSessionActivity();
    p.endRun();
  }
}
