import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/goop_talk_engine.dart';
import '../../services/haptics.dart';
import '../../services/mp_session.dart';
import '../../services/run_lifecycle.dart';
import '../../utils/responsive.dart';

/// Wraps the entire app body during a Paradox pause — desaturates the
/// screen to monochrome, dims it, and shows a giant pause icon +
/// "GAME PAUSED" label so both players always know the session state.
///
/// While paused the radios keep polling at pause cadence, so a break
/// (phones out of range) re-heals silently — when the link is found
/// again the overlay flips to "PARTNER FOUND — TAP TO RESUME".
class PauseOverlay extends StatelessWidget {
  final Widget child;
  const PauseOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: context.watch<MpSession>().pausedNotifier,
      builder: (_, paused, _) {
        final body =
            paused
                ? ColorFiltered(
                  colorFilter: const ColorFilter.matrix(_monoMatrix),
                  child: child,
                )
                : child;
        return Stack(children: [body, if (paused) const _PausedLayer()]);
      },
    );
  }
}

/// Greyscale saturation matrix — turns whatever screen is open
/// monochrome for the paused look.
const _monoMatrix = <double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
];

class _PausedLayer extends StatelessWidget {
  const _PausedLayer();

  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    final session = context.watch<MpSession>();
    final reconnected = session.phase == MpPhase.connected;

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.82),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 150 * sf,
                height: 150 * sf,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.85),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.18),
                      blurRadius: 48,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.pause_rounded,
                  size: 92 * sf,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 32 * sf),
              GoopText(
                'GAME PAUSED',
                style: TextStyle(
                  fontSize: 34 * sf,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
              SizedBox(height: 12 * sf),
              GoopText(
                reconnected
                    ? 'Partner found — tap resume'
                    : 'Phones may drift apart — we keep re-linking.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15 * sf,
                  color: Colors.white.withValues(alpha: 0.55),
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 42 * sf),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(
                    horizontal: 42 * sf,
                    vertical: 20 * sf,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: Icon(Icons.play_arrow_rounded, size: 30 * sf),
                label: GoopText(
                  reconnected ? 'RESUME' : 'RESUME (CONNECTING…)',
                  style: TextStyle(
                    fontSize: 18 * sf,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                onPressed: () {
                  Haptics.medium();
                  context.read<MpSession>().resume();
                },
              ),
              SizedBox(height: 20 * sf),
              TextButton(
                onPressed: () => RunLifecycle.confirmEndRun(context),
                child: GoopText(
                  'END RUN',
                  style: TextStyle(
                    fontSize: 14 * sf,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
