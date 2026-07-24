import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../models/player.dart';
import '../../services/damage_calculator.dart';
import '../../services/goop_talk_engine.dart';

/// equipped gun's base DPS.
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

    return SafeArea(
      child: Padding(
      padding: EdgeInsets.fromLTRB(
        20, 16, 20, 20 + MediaQuery.of(context).viewInsets.bottom,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.calculate_rounded, color: Colors.amberAccent, size: 22),
                  SizedBox(width: 10),
                  GoopText(
                    'DAMAGE CALCULATOR',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.amberAccent,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
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
          const Divider(color: Colors.white12, height: 24),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF000800),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.25), width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    GoopText(
                      '> DMG_CALC v1.0',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.green.withValues(alpha: 0.5),
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    GoopText(
                      '×${multiplier.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.greenAccent,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final gun in guns)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: GoopText(
                            gun.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green.withValues(alpha: 0.85),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: GoopText(
                            gun.dpsValue.toStringAsFixed(1),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green.withValues(alpha: 0.6),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: GoopText(
                            (gun.dpsValue * multiplier).toStringAsFixed(1),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.greenAccent,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Container(height: 1, color: Colors.green.withValues(alpha: 0.15)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GoopText(
                      'TOTAL DPS',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.green.withValues(alpha: 0.5),
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GoopText(
                      '${guns.fold<double>(0, (sum, g) => sum + g.dpsValue).toStringAsFixed(1)} → ${guns.fold<double>(0, (sum, g) => sum + g.dpsValue * multiplier).toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.greenAccent,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
      ),
      ),
      ),
    );
  }
}
