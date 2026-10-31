import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/run_provider.dart';
import '../../services/goop_talk_engine.dart';
import '../../utils/responsive.dart';

/// Super-compact cool/curse effects strip — 5 derived stats in one
/// aligned row (FUSE / COOLDOWN / REWARD / JAMMED / BOSS JAM). The
/// COOL/CURSE ± controls live on the [CoolCurseSheet] cards behind the
/// header chips now, so this block is read-only and stays one row tall.
class RunEffectsBlock extends StatelessWidget {
  const RunEffectsBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    final p = context.watch<RunProvider>();
    final cool = p.runState.totalCoolness;
    final curse = p.runState.totalCurse;

    // Same formulas the COOL & CURSE screen uses.
    final fuseSkip = math.min(cool * 2.5, 10);
    final cdSpeed = math.min(cool * 5, 50);
    final reward = math.max(0.0, 1 + cool - curse);
    final jam = curse >= 10 ? 100.0 : curse * 4;
    final bossJam = curse >= 10 ? 100.0 : curse * 2;

    const coolCol = Color(0xFF4DD0E1);
    const curseCol = Color(0xFFBA68C8);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8 * sf, vertical: 1 * sf),
      child: Row(
        children: [
          _stat('FUSE', '${fuseSkip.toStringAsFixed(1)}%', coolCol, sf),
          _stat('CD', '-${cdSpeed.toStringAsFixed(0)}%', coolCol, sf),
          _stat('REWARD', '${reward.toStringAsFixed(1)}%', coolCol, sf),
          _stat('JAM', '${jam.toStringAsFixed(0)}%', curseCol, sf),
          _stat('BOSS', '${bossJam.toStringAsFixed(0)}%', curseCol, sf),
        ],
      ),
    );
  }

  // Single-line label+value — the strip stays ~50% shorter than the
  // old two-line column per user request.
  Widget _stat(String label, String value, Color col, double sf) {
    // FittedBox — the pair scales down on narrow viewports instead of
    // overflowing its Expanded slice (320px overflow fix).
    return Expanded(
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GoopText(
                '$label ',
                style: TextStyle(
                  fontSize: 7.5 * sf,
                  letterSpacing: 0.8,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              GoopText(
                value,
                style: TextStyle(
                  fontSize: 10.5 * sf,
                  fontWeight: FontWeight.w900,
                  color: col,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
