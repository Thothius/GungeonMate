import '../../theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../services/haptics.dart';
import '../../utils/format.dart';
import '../../services/goop_talk_engine.dart';
import '../scale_button.dart';
import 'dart:math' as math;

/// for quick zeroing.
class StatAdjusterSheet extends StatelessWidget {
  final bool isCool;
  const StatAdjusterSheet({super.key, required this.isCool});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final value = isCool ? p.runState.coolness : p.runState.curse;
    final accent = isCool ? const Color(0xFF29B6F6) : const Color(0xFFD32F2F);
    final label = isCool ? 'Coolness' : 'Curse';
    final icon = isCool ? Icons.ac_unit : Icons.warning_amber_rounded;

    void apply(double delta) {
      if (isCool) {
        p.adjustCoolness(delta);
      } else {
        p.adjustCurse(delta);
      }
    }

    Widget step(double delta) {
      final positive = delta > 0;
      final text = '${positive ? '+' : ''}${formatStat(delta)}';
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Insets.xs),
          child: OutlinedButton(
            onPressed: () => apply(delta),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: positive ? accent : Colors.white70,
              side: BorderSide(
                color: accent.withValues(alpha: positive ? 0.7 : 0.25),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: GoopText(
              text,
              style: const TextStyle(
                fontSize: FontSizes.bodyMedium,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(icon, color: accent, size: 22),
                const SizedBox(width: 8),
                GoopText(
                  'Adjust $label',
                  style: const TextStyle(
                    fontSize: FontSizes.titleSmall,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                GoopText(
                  formatStat(value),
                  style: TextStyle(
                    fontSize: FontSizes.headlineSmall,
                    fontWeight: FontWeight.w900,
                    color: accent,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Sleek single horizontal row of premium large modifier buttons!
            Row(
              children: [
                step(-1),
                step(-0.5),
                // Premium large central Reset button!
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Insets.xs),
                    child: OutlinedButton(
                      onPressed: () {
                        if (isCool) {
                          p.adjustCoolness(-value);
                        } else {
                          p.adjustCurse(-value);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: Insets.lg,
                        ),
                        foregroundColor: Colors.white60,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const GoopText(
                        'RESET',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                step(0.5),
                step(1),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Compact COOL/CURSE card — number + ±(1/0.5) steppers + live effects
// stacked on one card. Replaces the old multi-section hub sheets.
// =============================================================================

class CoolCurseSheet extends StatelessWidget {
  final bool isCool;
  const CoolCurseSheet({super.key, required this.isCool});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final cool = p.runState.coolness;
    final curse = p.runState.curse;
    final value = isCool ? cool : curse;
    final accent =
        isCool ? const Color(0xFF4DD0E1) : const Color(0xFFBA68C8);
    final label = isCool ? 'COOL' : 'CURSE';
    final icon =
        isCool ? Icons.ac_unit : Icons.warning_amber_rounded;

    void apply(double delta) {
      if (isCool) {
        p.adjustCoolness(delta);
      } else {
        p.adjustCurse(delta);
      }
      Haptics.light();
    }

    // Same derived-stat formulas as RunEffectsBlock.
    final effects = <(String, String)>[
      if (isCool) ...[
        ('FUSE SKIP', '+${math.min(cool * 2.5, 10).toStringAsFixed(1)}%'),
        ('COOLDOWN', '-${math.min(cool * 5, 50).toStringAsFixed(0)}%'),
        (
          'ROOM REWARD',
          '+${math.max(0.0, 1 + cool - curse).toStringAsFixed(1)}%',
        ),
      ] else ...[
        ('JAM CHANCE', '${curse >= 10 ? 100 : curse * 4}%'),
        ('BOSS JAM', '${curse >= 10 ? 100 : curse * 2}%'),
        (
          'ROOM REWARD',
          '+${math.max(0.0, 1 + cool - curse).toStringAsFixed(1)}%',
        ),
      ],
    ];

    Widget step(double delta) {
      final positive = delta > 0;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: ScaleButton(
            onTap: () => apply(delta),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: positive ? 0.14 : 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: accent.withValues(
                    alpha: positive ? 0.5 : 0.25,
                  ),
                ),
              ),
              child: Center(
                child: GoopText(
                  '${positive ? '+' : '−'}${delta.abs() == 1.0 ? '1' : '0.5'}',
                  style: TextStyle(
                    fontSize: FontSizes.bodyMedium,
                    fontWeight: FontWeight.w900,
                    color:
                        positive
                            ? accent
                            : Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget actionChip(IconData ic, String txt, VoidCallback onTap) {
      return Expanded(
        child: ScaleButton(
          onTap: () {
            onTap();
            Haptics.selection();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: accent.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(ic, size: 14, color: accent.withValues(alpha: 0.8)),
                const SizedBox(width: 6),
                GoopText(
                  txt,
                  style: TextStyle(
                    fontSize: FontSizes.labelSmall,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header: icon + label + big live number.
            Row(
              children: [
                Icon(icon, color: accent, size: 20),
                const SizedBox(width: 8),
                GoopText(
                  label,
                  style: TextStyle(
                    fontSize: FontSizes.titleSmall,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const Spacer(),
                GoopText(
                  formatStat(value),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    color: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Stepper row: −1 | −0.5 | +0.5 | +1
            Row(
              children: [step(-1), step(-0.5), step(0.5), step(1)],
            ),
            const SizedBox(height: 14),
            // Effects stacked on the same card.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                children: [
                  for (final (name, val) in effects)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          GoopText(
                            name,
                            style: TextStyle(
                              fontSize: FontSizes.labelSmall,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                          const Spacer(),
                          GoopText(
                            val,
                            style: TextStyle(
                              fontSize: FontSizes.bodyMedium,
                              fontWeight: FontWeight.w900,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Quick actions — same flavor as the old hub sheets.
            Row(
              children:
                  isCool
                      ? [
                        actionChip(
                          Icons.smoking_rooms_outlined,
                          'SMOKE +1',
                          () => p.logSmokeCig(),
                        ),
                        const SizedBox(width: 8),
                        actionChip(
                          Icons.auto_awesome,
                          'RAINBOW +1',
                          () => p.logRainbowRun(),
                        ),
                      ]
                      : [
                        actionChip(
                          Icons.front_hand_outlined,
                          'STEAL +1',
                          () => p.logSteal(),
                        ),
                        const SizedBox(width: 8),
                        actionChip(
                          Icons.storefront_outlined,
                          'CURSULA +2',
                          () => p.logCursula(),
                        ),
                      ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Inventory sort
// =============================================================================
