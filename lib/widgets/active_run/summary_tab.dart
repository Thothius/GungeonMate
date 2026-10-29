import 'package:flutter/material.dart';

import '../../services/app_theme.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/haptics.dart';
import '../../theme/tokens.dart';

/// Sponge translation toggle with pulsing amber glow when active.
/// Only visible when Goopian language is enabled.
class SpongeButton extends StatefulWidget {
  const SpongeButton({super.key});

  @override
  State<SpongeButton> createState() => SpongeButtonState();
}

class SpongeButtonState extends State<SpongeButton>
    with SingleTickerProviderStateMixin {
  AnimationController? _glow;

  @override
  void dispose() {
    _glow?.dispose();
    super.dispose();
  }

  void _ensureGlow(bool active) {
    if (active && _glow == null) {
      _glow = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat(reverse: true);
    } else if (!active && _glow != null) {
      _glow!.dispose();
      _glow = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: VisualPrefs.notifier,
      builder: (context, _) {
        final prefs = VisualPrefs.notifier.value;
        final isSponge = prefs.spongeActive;
        final isGoopian = prefs.isGoopianLanguage;
        if (!isGoopian) return const SizedBox.shrink();

        _ensureGlow(isSponge);

        // Wrap in a Column to match the _LabeledIconButton pattern used
        // by the other trailing options (Calc/Effects/Shrine/Panels/More)
        // so the row stays symmetrical even when the sponge toggle is visible.
        return Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  VisualPrefs.setSpongeActive(!isSponge);
                  if (isSponge) {
                    Haptics.light();
                  } else {
                    Haptics.success();
                  }
                },
                icon: _glow != null
                    ? AnimatedBuilder(
                        animation: _glow!,
                        builder: (_, child) {
                          final t = _glow!.value;
                          return Text(
                            '\u{1F9FD}',
                            style: TextStyle(
                              fontSize: 20,
                              shadows: [
                                Shadow(
                                  color: Colors.amberAccent
                                      .withValues(alpha: 0.4 + 0.5 * t),
                                  blurRadius: 6 + 12 * t,
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : const Text(
                        '\u{1F9FD}',
                        style: TextStyle(fontSize: 20),
                      ),
                tooltip: isSponge
                    ? 'Sponge: English translation active'
                    : 'Sponge: Alien language active',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 36),
              ),
              GoopText(
                'Sponge',
                style: TextStyle(
                  fontSize: FontSizes.labelSmall,
                  fontWeight: FontWeight.w600,
                  color: isSponge ? Colors.amberAccent : Colors.white38,
                  letterSpacing: 0.5,
                  height: 1.0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
