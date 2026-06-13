import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// =============================================================================
// Synergy glow — STATIC border + soft outer glow.
//
// Previously: 10 animated effects, then one electric pulse. Both were
// distracting in a loadout view that the user spends a lot of time
// reading. The current design is a flat coloured border (1.4px) with a
// faint matching outer halo — readable, calm, GPU-cheap.
//
// API is preserved so callers don't need to change: they still pass an
// AnimationController and an effectIndex, both are now ignored.
// =============================================================================

/// Deterministic effect index per synergy name. Kept stable for any
/// downstream code that maps it to a colour or label, but the overlay
/// itself no longer reads it.
int synergyEffectFor(String name) => name.hashCode.abs() % 10;

/// Returned for API compatibility. The widget never ticks.
Duration synergyEffectDuration(int idx) =>
    const Duration(milliseconds: 500);

/// Returned for API compatibility.
bool synergyEffectReverse(int idx) => false;

// =============================================================================
// SynergyGlowOverlay
// =============================================================================

/// Wraps [child] with a static, coloured synergy outline.
///
/// [color] is the synergy's deterministic group colour. [controller] and
/// [effectIndex] are accepted purely for API compatibility — the overlay
/// no longer animates. Use [showBgTint] for list rows (a faint coloured
/// wash behind the child for slightly more presence in long lists).
class SynergyGlowOverlay extends StatelessWidget {
  final Widget child;
  final Color color;
  final AnimationController controller;
  final int effectIndex;
  final double radius;
  final bool showBgTint;

  const SynergyGlowOverlay({
    super.key,
    required this.child,
    required this.color,
    required this.controller,
    required this.effectIndex,
    this.radius = 8,
    this.showBgTint = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (showBgTint)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
            ),
          ),
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: Container().animate(
              onPlay: (controller) => controller.repeat(reverse: true),
            ).custom(
              duration: 1500.ms,
              builder: (context, value, _) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: color.withValues(alpha: 0.40 + 0.35 * value),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.12 + 0.20 * value),
                        blurRadius: 4 + 6 * value,
                        spreadRadius: 0.2 + 0.6 * value,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

