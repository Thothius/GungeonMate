import '../../theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../utils/format.dart';
import '../../services/goop_talk_engine.dart';
import '../skeuo/skeuo_tokens.dart';

class StatAdjusterSheet extends StatelessWidget {
  final bool isCool;
  const StatAdjusterSheet({super.key, required this.isCool});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final value = isCool ? p.runState.coolness : p.runState.curse;
    final accent =
        isCool
            ? Skeuo.collapse(Color(0xFF29B6F6))
            : Skeuo.collapse(Color(0xFFD32F2F));
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
              foregroundColor:
                  positive ? accent : Skeuo.collapse(Colors.white70),
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
                  color: Skeuo.collapse(Colors.white).withValues(alpha: 0.18),
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
                        foregroundColor: Skeuo.collapse(Colors.white60),
                        side: BorderSide(
                          color: Skeuo.collapse(
                            Colors.white,
                          ).withValues(alpha: 0.12),
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
