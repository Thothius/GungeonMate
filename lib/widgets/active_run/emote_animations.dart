import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/goop_talk_engine.dart';

/// Floating emote overlay shown on the receiver's screen when a peer
/// sends a kiss or slap. Purely visual — wrapped in `IgnorePointer` by
/// the caller so it never blocks interaction.
///
/// Both animations are self-contained [StatefulWidget]s that manage
/// their own [AnimationController] and dispose it cleanly.

// =============================================================================
// Kiss — pink heart floats up with sine wobble over 6 seconds
// =============================================================================

class KissAnimation extends StatefulWidget {
  final String from;
  const KissAnimation({super.key, required this.from});

  @override
  State<KissAnimation> createState() => _KissAnimationState();
}

class _KissAnimationState extends State<KissAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value; // 0..1
        // Vertical drift: heart rises from lower-center upward
        final dy = (1.0 - t) * screenH * 0.3;
        // Sine-wave horizontal wobble (two full cycles over 6s)
        final dx = 15.0 * math.sin(t * 6.28 * 2);
        // Fade: in 0→0.17 (~1s), hold 0.17→0.67 (~3s), out 0.67→1.0 (~2s)
        double opacity;
        if (t < 0.17) {
          opacity = t / 0.17;
        } else if (t < 0.67) {
          opacity = 1.0;
        } else {
          opacity = 1.0 - ((t - 0.67) / 0.33);
        }
        final name = widget.from.isEmpty ? 'Player' : widget.from;
        return Center(
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(dx, -dy),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pinkAccent.withValues(alpha: 0.5),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 80,
                      color: Colors.pinkAccent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: GoopText(
                      'A kiss from $name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// Slap — angry face slams down + screen shake + red flash over 2 seconds
// =============================================================================

class SlapAnimation extends StatefulWidget {
  final String from;
  const SlapAnimation({super.key, required this.from});

  @override
  State<SlapAnimation> createState() => _SlapAnimationState();
}

class _SlapAnimationState extends State<SlapAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    // Shake amplitude: 3% of screen width, max 20px
    final shakeAmp = (screenW * 0.03).clamp(0.0, 20.0);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value; // 0..1
        // Phase 1 (0→0.15): angry face slams down from top to center
        // Phase 2 (0.15→0.65): screen shake + face visible
        // Phase 3 (0.65→1.0): fade out
        double faceY;
        if (t < 0.15) {
          // Slam down: ease-in for impact
          final slamT = t / 0.15;
          faceY = -screenH * 0.5 * (1.0 - slamT * slamT);
        } else {
          faceY = 0;
        }
        // Shake: decaying sine, only during phase 2
        double shakeX = 0;
        if (t >= 0.15 && t < 0.65) {
          final shakeT = (t - 0.15) / 0.5; // 0..1 within shake phase
          final decay = 1.0 - shakeT;
          shakeX = shakeAmp * decay * math.sin(shakeT * 30);
        }
        // Red flash: 0.15→0.25 (~200ms after impact)
        double flashOpacity = 0;
        if (t >= 0.15 && t < 0.25) {
          flashOpacity = 0.15 * (1.0 - (t - 0.15) / 0.1);
        }
        // Face + label opacity
        double contentOpacity;
        if (t < 0.65) {
          contentOpacity = 1.0;
        } else {
          contentOpacity = 1.0 - ((t - 0.65) / 0.35);
        }
        final name = widget.from.isEmpty ? 'Player' : widget.from;
        return Stack(
          children: [
            // Red impact flash
            if (flashOpacity > 0)
              Positioned.fill(
                child: Container(
                  color: Colors.red.withValues(alpha: flashOpacity),
                ),
              ),
            // Angry face + label with screen shake
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(shakeX, 0),
                child: Center(
                  child: Opacity(
                    opacity: contentOpacity.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, faceY),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.sentiment_very_dissatisfied,
                              size: 100,
                              color: t < 0.15
                                  ? Colors.orange
                                  : Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.shade700
                                    .withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: GoopText(
                              'SLAP from $name!',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.red.shade300,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
