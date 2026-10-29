import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/run_provider.dart';
import '../../services/app_theme.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/haptics.dart';
import '../../utils/responsive.dart';
import '../scale_button.dart';

/// Compact cool/curse effects strip — 5 derived stats in one aligned
/// row (FUSE / COOLDOWN / REWARD / JAMMED / BOSS JAM) plus COOL/CURSE
/// ± controls. Lives inside the header effects panel; pull the drag
/// handle to reveal the full stats + controls block.
class RunEffectsBlock extends StatefulWidget {
  const RunEffectsBlock({super.key});

  @override
  State<RunEffectsBlock> createState() => _RunEffectsBlockState();
}

class _RunEffectsBlockState extends State<RunEffectsBlock> {
  bool _open = false;

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

    return Column(
      children: [
        // Always-visible compact stat row.
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8 * sf, vertical: 4 * sf),
          child: Row(
            children: [
              _stat('FUSE', '${fuseSkip.toStringAsFixed(1)}%', coolCol, sf),
              _stat('CD', '-${cdSpeed.toStringAsFixed(0)}%', coolCol, sf),
              _stat('REWARD', '${reward.toStringAsFixed(1)}%', coolCol, sf),
              _stat('JAM', '${jam.toStringAsFixed(0)}%', curseCol, sf),
              _stat('BOSS', '${bossJam.toStringAsFixed(0)}%', curseCol, sf),
            ],
          ),
        ),
        // Drag handle — pull down to reveal controls.
        GestureDetector(
          onVerticalDragUpdate: (d) {
            if (d.delta.dy > 2 && !_open) {
              setState(() => _open = true);
              Haptics.selection();
            } else if (d.delta.dy < -2 && _open) {
              setState(() => _open = false);
            }
          },
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Container(
              width: 34, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.flair.primary.withValues(
                    alpha: _open ? 0.6 : 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        // Expanded controls — COOL/CURSE ± centered.
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: _open
              ? Padding(
                  padding: EdgeInsets.fromLTRB(8 * sf, 2 * sf, 8 * sf, 8 * sf),
                  child: Row(
                    children: [
                      _ctrl('COOL', cool, coolCol,
                          () => p.adjustCoolness(-1),
                          () => p.adjustCoolness(1), sf),
                      SizedBox(width: 12 * sf),
                      _ctrl('CURSE', curse, curseCol,
                          () => p.adjustCurse(-1),
                          () => p.adjustCurse(1), sf),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _stat(String label, String value, Color col, double sf) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GoopText(value,
              style: TextStyle(
                  fontSize: 12 * sf,
                  fontWeight: FontWeight.w900,
                  color: col)),
          GoopText(label,
              style: TextStyle(
                  fontSize: 7.5 * sf,
                  letterSpacing: 1,
                  color: Colors.white.withValues(alpha: 0.4))),
        ],
      ),
    );
  }

  /// Flat, minimalist control — label up top, value dead-center, −/+
  /// symmetric on either side, generous inner spacing. No border, no
  /// glow — a soft tinted pill is the only chrome.
  Widget _ctrl(String label, double value, Color col,
      VoidCallback onMinus, VoidCallback onPlus, double sf) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10 * sf, horizontal: 6 * sf),
        decoration: BoxDecoration(
          color: col.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GoopText(
              label,
              style: TextStyle(
                  fontSize: 9 * sf,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w700,
                  color: col.withValues(alpha: 0.7)),
            ),
            SizedBox(height: 8 * sf),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ScaleButton(
                    onTap: () { onMinus(); Haptics.light(); },
                    child: Container(
                      width: 34 * sf, height: 34 * sf,
                      decoration: BoxDecoration(
                        color: col.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.remove_rounded,
                          size: 18 * sf, color: col),
                    )),
                GoopText(
                    value == value.truncateToDouble()
                        ? value.toInt().toString()
                        : value.toStringAsFixed(1),
                    style: TextStyle(
                        fontSize: 22 * sf,
                        fontWeight: FontWeight.w900,
                        color: col)),
                ScaleButton(
                    onTap: () { onPlus(); Haptics.light(); },
                    child: Container(
                      width: 34 * sf, height: 34 * sf,
                      decoration: BoxDecoration(
                        color: col.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add_rounded,
                          size: 18 * sf, color: col),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
