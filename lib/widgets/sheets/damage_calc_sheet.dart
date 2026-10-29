import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../models/player.dart';
import '../../services/damage_calculator.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/haptics.dart';

/// Damage calculator bottom sheet — opened by tapping the DPS capsule
/// in the active-run header. Shows per-gun DPS breakdown with multiplier
/// contributions and a total DPS readout.
class DamageCalcSheet extends StatelessWidget {
  final PlayerSlot slot;
  const DamageCalcSheet({super.key, required this.slot});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final player = slot == PlayerSlot.coop
        ? (p.runState.coop ?? Player())
        : p.runState.main;
    final guns = player.guns;

    final contributions = DamageCalculator.contributions(
      guns: guns,
      items: player.items,
    );
    final multiplier = DamageCalculator.multiplier(
      guns: guns,
      items: player.items,
    );
    final bonusPercent = (multiplier - 1.0) * 100.0;
    final totalBase = guns.fold<double>(0, (sum, g) => sum + g.dpsValue);
    final totalBoosted = totalBase * multiplier;

    return SafeArea(
      child: Padding(
      padding: EdgeInsets.fromLTRB(
        16, 8, 16, 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: double.infinity,
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row: big close button (left) + title + bonus badge ──
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 28, color: Colors.white70),
                tooltip: 'Close',
                onPressed: () {
                  Haptics.selection();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(width: 4),
              const GoopText(
                'dmg_calc v1.0',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.amberAccent,
                  letterSpacing: 0.5,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 1.0),
                ),
                child: GoopText(
                  '${bonusPercent >= 0 ? '+' : ''}${bonusPercent.toStringAsFixed(0)}% DMG',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.amberAccent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 20),
          // ── Contribution breakdown ──
          if (contributions.isNotEmpty) ...[
            for (final c in contributions)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: GoopText(
                        c.sourceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ),
                    GoopText(
                      c.percent == 0
                          ? '—'
                          : '${c.percent >= 0 ? '+' : ''}${c.percent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: c.percent > 0
                            ? Colors.greenAccent
                            : c.percent < 0
                                ? Colors.redAccent
                                : Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
          ],
          // ── Weapon list — card-style tiles instead of raw monospace rows ──
          if (guns.isNotEmpty) ...[
            for (final gun in guns)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0F0A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.greenAccent.withValues(alpha: 0.12),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: GoopText(
                          gun.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: GoopText(
                          gun.dpsValue.toStringAsFixed(1),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.4),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: GoopText(
                          (gun.dpsValue * multiplier).toStringAsFixed(1),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.greenAccent,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: 10),
          // ── Total DPS row ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF000800),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3), width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GoopText(
                  'TOTAL DPS',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green.withValues(alpha: 0.6),
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                GoopText(
                  '${totalBase.toStringAsFixed(1)} → ${totalBoosted.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.greenAccent,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
      ),
      ),
      ),
    );
  }
}
