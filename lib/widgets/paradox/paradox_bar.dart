import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/multiplayer_messages.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/mp_session.dart';
import '../../utils/responsive.dart';
import '../skeuo/skeuo_tokens.dart';

/// Unified top MP bar — always visible during any MP session
/// (classic + paradox):
///   `RUN TITLE #N`  (optional timer)        [YOU] [P2]
/// Replaces MpHeader for all sessions; reconnect status is shown
/// inline here — never the modal banner (kills the "two bars" bug).
/// Chat/settings live on the player panel below, not in this bar.
class ParadoxBar extends StatefulWidget {
  final int currentPage;
  final void Function(int) onPick;

  const ParadoxBar({
    super.key,
    required this.currentPage,
    required this.onPick,
  });

  /// User prefs for the bar — toggled from the settings popup.
  static final showTimer = ValueNotifier<bool>(false);
  static final showHealth = ValueNotifier<bool>(false);

  @override
  State<ParadoxBar> createState() => _ParadoxBarState();
}

class _ParadoxBarState extends State<ParadoxBar> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _fmtElapsed(int ms) {
    final s = ms ~/ 1000;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = sec.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    final session = context.watch<MpSession>();
    final reconnecting =
        session.phase == MpPhase.disconnected ||
        (session.phase == MpPhase.connecting &&
            session.connectReason == MpConnectReason.reconnecting);
    // Below ~460px the title + tabs + icons overflow — collapse to
    // compact mode (short labels, tighter padding, no health chip).
    final compact = MediaQuery.sizeOf(context).width < 460;

    // Rebuild when the ⋮ DISPLAY toggles flip — the 1s ticker would
    // pick it up eventually, but a listener makes it instant.
    return ListenableBuilder(
      listenable: Listenable.merge([
        ParadoxBar.showTimer,
        ParadoxBar.showHealth,
      ]),
      builder:
          (context, _) => Container(
            padding: EdgeInsets.fromLTRB(12 * sf, 6 * sf, 4 * sf, 6 * sf),
            decoration: BoxDecoration(
              color: Skeuo.collapse(Color(0xFF12081F)),
              border: Border(
                bottom: BorderSide(
                  color: Skeuo.collapse(
                    Color(0xFF7C4DFF),
                  ).withValues(alpha: 0.4),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: GoopText(
                              session.runTitle.isNotEmpty
                                  ? session.runTitle.toUpperCase()
                                  : (session.isParadoxRun
                                      ? 'PARADOX'
                                      : 'CO-OP'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11 * sf,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: Skeuo.collapse(Color(0xFFB388FF)),
                              ),
                            ),
                          ),
                          if (ParadoxBar.showTimer.value) ...[
                            SizedBox(width: 8 * sf),
                            Icon(
                              Icons.timer_outlined,
                              size: 12 * sf,
                              color: Skeuo.collapse(
                                Colors.white,
                              ).withValues(alpha: 0.4),
                            ),
                            SizedBox(width: 3 * sf),
                            GoopText(
                              _fmtElapsed(session.runElapsedMs),
                              style: TextStyle(
                                fontSize: 11.5 * sf,
                                fontWeight: FontWeight.w700,
                                color: Skeuo.collapse(
                                  Colors.white,
                                ).withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (reconnecting)
                        ValueListenableBuilder<int>(
                          valueListenable: session.disconnectElapsedSec,
                          builder: (context, sec, _) {
                            final label =
                                session.isPaused
                                    ? 'paused'
                                    : sec >= 120
                                    ? 'reconnecting… partner may have left'
                                    : 'reconnecting…';
                            return GoopText(
                              label,
                              style: TextStyle(
                                fontSize: 10.5 * sf,
                                fontWeight: FontWeight.w600,
                                color: Skeuo.inkIf(
                                  Colors.orangeAccent,
                                ).withValues(alpha: 0.8),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                // Narrow-width collapse (~460px and below): the trailing
                // cluster (2 tab dots + chat + gear) overflowed the bar by
                // ~15px. Health chip hides and the dots compress to slot
                // labels only — tapping still flips pages.
                if (ParadoxBar.showHealth.value && !compact)
                  Padding(
                    padding: EdgeInsets.only(right: 4 * sf),
                    child: ValueListenableBuilder<int>(
                      valueListenable: session.healthListenable,
                      builder:
                          (_, health, _) => _HealthChip(health: health, sf: sf),
                    ),
                  ),
                // Player tabs
                _TabDot(
                  label:
                      compact
                          ? (session.myRole == MpRole.main ? 'YOU' : 'P1')
                          : (session.myRole == MpRole.main
                              ? 'YOU'
                              : session.peerNickname ?? 'P1'),
                  active: widget.currentPage == 0,
                  onTap: () => widget.onPick(0),
                  sf: sf,
                  compact: compact,
                ),
                _TabDot(
                  label:
                      compact
                          ? (session.myRole == MpRole.main ? 'P2' : 'YOU')
                          : (session.myRole == MpRole.main
                              ? session.peerNickname ?? 'P2'
                              : 'YOU'),
                  active: widget.currentPage == 1,
                  onTap: () => widget.onPick(1),
                  sf: sf,
                  compact: compact,
                ),
              ],
            ),
          ),
    );
  }
}

class _TabDot extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final double sf;
  final bool compact;
  const _TabDot({
    required this.label,
    required this.active,
    required this.onTap,
    required this.sf,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.symmetric(horizontal: (compact ? 1.5 : 3) * sf),
        padding: EdgeInsets.symmetric(
          horizontal: (compact ? 6 : 10) * sf,
          vertical: 5 * sf,
        ),
        decoration: BoxDecoration(
          color:
              active
                  ? Skeuo.collapse(Color(0xFF7C4DFF)).withValues(alpha: 0.25)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                active
                    ? Skeuo.collapse(Color(0xFFB388FF))
                    : Skeuo.collapse(Colors.white).withValues(alpha: 0.15),
          ),
        ),
        child: GoopText(
          label.length > 8 ? '${label.substring(0, 8)}…' : label.toUpperCase(),
          style: TextStyle(
            fontSize: 10.5 * sf,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color:
                active
                    ? Skeuo.collapse(Color(0xFFB388FF))
                    : Skeuo.collapse(Colors.white).withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

class _HealthChip extends StatelessWidget {
  final int health;
  final double sf;
  const _HealthChip({required this.health, required this.sf});

  @override
  Widget build(BuildContext context) {
    final c =
        health >= 70
            ? Skeuo.collapse(Color(0xFF00E676))
            : health >= 35
            ? Skeuo.inkIf(Colors.orangeAccent)
            : Skeuo.inkIf(Colors.redAccent);
    return Tooltip(
      message: 'Connection health $health%',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6 * sf, vertical: 3 * sf),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: c.withValues(alpha: 0.5), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.signal_cellular_alt_rounded, size: 11 * sf, color: c),
            SizedBox(width: 3 * sf),
            GoopText(
              '$health',
              style: TextStyle(
                fontSize: 10 * sf,
                fontWeight: FontWeight.w800,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
