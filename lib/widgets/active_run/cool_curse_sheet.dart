import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/run_provider.dart';
import '../../screens/shrine_picker_screen.dart';
import '../../services/app_theme.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/haptics.dart';
import '../../theme/tokens.dart';
import '../../utils/cool_curse_math.dart';
import '../../utils/fast_route.dart';
import '../../utils/responsive.dart';

/// Quick-manage bottom sheet for COOLNESS / CURSE — opened by tapping
/// either header capsule (solo [GungeoneerHeader] or MP
/// [ParadoxPlayerPanel]). The full explainer screen stays reachable via
/// long-press.
///
/// Layout per spec: big live number centered with −1/−0.5 flanking left
/// and +0.5/+1 flanking right; bottom-left lists the stats that metric
/// drives (all math via `cool_curse_math`); bottom-right carries the
/// curse-only actions STEAL (+1 curse, `logSteal`) and CURSULA BUY
/// (+2.5 curse, `logCursula`). A SHRINES shortcut in the header opens
/// the shrine picker for quick lookup/activation.
class CoolCurseSheet extends StatelessWidget {
  final bool isCool;
  const CoolCurseSheet({super.key, required this.isCool});

  static Future<void> show(BuildContext context, {required bool isCool}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CoolCurseSheet(isCool: isCool),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    final flair = AppTheme.flair;
    final p = context.watch<RunProvider>();
    final cool = p.runState.totalCoolness;
    final curse = p.runState.totalCurse;
    final value = isCool ? cool : curse;
    final color = isCool ? StatColors.cool : StatColors.curse;
    final title = isCool ? 'COOLNESS' : 'CURSE';

    void apply(double delta) {
      if (isCool) {
        p.adjustCoolness(delta);
      } else {
        p.adjustCurse(delta);
      }
      Haptics.light();
    }

    return Container(
      decoration: BoxDecoration(
        color: flair.card,
        borderRadius: Radii.sheet,
        border: Border(
          top: BorderSide(color: flair.primary.withValues(alpha: 0.2)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab handle.
              Container(
                width: 36,
                height: 4,
                margin: EdgeInsets.only(top: 10 * sf),
                decoration: BoxDecoration(
                  color: flair.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header — metric title, shrine lookup shortcut, close.
              Padding(
                padding: EdgeInsets.fromLTRB(16 * sf, 8 * sf, 8 * sf, 0),
                child: Row(
                  children: [
                    GoopText(
                      title,
                      style: TextStyle(
                        fontSize: FontSizes.titleSmall * sf,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: color,
                      ),
                    ),
                    const Spacer(),
                    _HeaderChip(
                      icon: Icons.temple_buddhist_outlined,
                      label: 'SHRINES',
                      onTap: () => Navigator.push(
                        context,
                        fastRoute(const ShrinePickerScreen()),
                      ),
                      sf: sf,
                    ),
                    SizedBox(width: 6 * sf),
                    Semantics(
                      button: true,
                      label: 'Close',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Haptics.selection();
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: EdgeInsets.all(6 * sf),
                          child: Icon(
                            Icons.close_rounded,
                            size: 20 * sf,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Big number flanked by subtract (left) / add (right).
              Padding(
                padding: EdgeInsets.fromLTRB(12 * sf, 4 * sf, 12 * sf, 8 * sf),
                child: Row(
                  children: [
                    // Subtract cluster — right-aligned against the number.
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _StepButton(
                            label: '−1',
                            onTap: () => apply(-1),
                            color: color,
                            sf: sf,
                            filled: false,
                          ),
                          SizedBox(width: 6 * sf),
                          _StepButton(
                            label: '−0.5',
                            onTap: () => apply(-0.5),
                            color: color,
                            sf: sf,
                            filled: false,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10 * sf),
                    SizedBox(
                      width: 92 * sf,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: GoopText(
                            value.toStringAsFixed(
                              value % 1 == 0 ? 0 : 1,
                            ),
                            style: TextStyle(
                              fontSize: 52 * sf,
                              fontWeight: FontWeight.w900,
                              height: 1,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10 * sf),
                    // Add cluster — left-aligned against the number.
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _StepButton(
                            label: '+0.5',
                            onTap: () => apply(0.5),
                            color: color,
                            sf: sf,
                            filled: true,
                          ),
                          SizedBox(width: 6 * sf),
                          _StepButton(
                            label: '+1',
                            onTap: () => apply(1),
                            color: color,
                            sf: sf,
                            filled: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom area — related stats left, curse actions right.
              Padding(
                padding: EdgeInsets.fromLTRB(16 * sf, 0, 16 * sf, 16 * sf),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _StatsCard(rows: _rows(cool, curse, color))),
                    if (!isCool) ...[
                      SizedBox(width: 10 * sf),
                      _CurseActions(
                        onSteal: () {
                          p.logSteal();
                          Haptics.medium();
                        },
                        onCursula: () {
                          p.logCursula();
                          Haptics.medium();
                        },
                        sf: sf,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_StatRowData> _rows(double cool, double curse, Color color) {
    if (isCool) {
      return [
        _StatRowData(
          'Chest fuse chance',
          '−${fuseChanceReduction(cool).toStringAsFixed(1)}%',
        ),
        _StatRowData(
          'Active cooldown',
          '−${cooldownReduction(cool).toStringAsFixed(0)}%',
        ),
        _StatRowData(
          'Room reward',
          '${roomRewardChance(cool, curse).toStringAsFixed(1)}%',
        ),
      ];
    }
    return [
      _StatRowData(
        'Jammed enemies',
        '${jammedEnemyChance(curse).toStringAsFixed(0)}%',
      ),
      _StatRowData(
        'Jammed bosses',
        '${jammedBossChance(curse).toStringAsFixed(0)}%',
      ),
      _StatRowData(
        'Mimic chests',
        '${mimicChance(curse).toStringAsFixed(2)}%',
      ),
      _StatRowData(
        'Fused chests',
        '+${curseFuseBonus(curse).toStringAsFixed(0)}%',
      ),
      _StatRowData(
        'Room reward',
        '${roomRewardChance(cool, curse).toStringAsFixed(1)}%',
      ),
      _StatRowData(
        'Ammo drops',
        'x${ammoDropMultiplier(curse).toStringAsFixed(2)}',
      ),
      if (curse >= 10)
        _StatRowData('LORD OF THE JAMMED', 'ACTIVE'),
    ];
  }
}

class _StatRowData {
  final String label;
  final String value;
  const _StatRowData(this.label, this.value);
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double sf;
  const _HeaderChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.sf,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label lookup',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Haptics.selection();
          onTap();
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8 * sf, vertical: 4 * sf),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13 * sf, color: Colors.white70),
              SizedBox(width: 4 * sf),
              GoopText(
                label,
                style: TextStyle(
                  fontSize: 9.5 * sf,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final List<_StatRowData> rows;
  const _StatsCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10 * sf, vertical: 4 * sf),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 5 * sf),
              child: Row(
                children: [
                  Expanded(
                    child: GoopText(
                      rows[i].label,
                      style: TextStyle(
                        fontSize: 11 * sf,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  GoopText(
                    rows[i].value,
                    style: TextStyle(
                      fontSize: 11.5 * sf,
                      fontWeight: FontWeight.w900,
                      color: rows[i].label == 'LORD OF THE JAMMED'
                          ? const Color(0xFFFF5252)
                          : Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CurseActions extends StatelessWidget {
  final VoidCallback onSteal;
  final VoidCallback onCursula;
  final double sf;
  const _CurseActions({
    required this.onSteal,
    required this.onCursula,
    required this.sf,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _actionButton(
          context,
          icon: Icons.front_hand_rounded,
          label: 'STEAL',
          sub: '+1 CURSE',
          color: StatColors.curse,
          onTap: onSteal,
        ),
        SizedBox(height: 8 * sf),
        _actionButton(
          context,
          icon: Icons.storefront_rounded,
          label: 'CURSULA',
          sub: '+2.5 CURSE',
          color: const Color(0xFFFF9100),
          onTap: onCursula,
        ),
      ],
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String sub,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: '$label — $sub',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 108 * sf,
          padding: EdgeInsets.symmetric(vertical: 10 * sf),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.55), width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20 * sf, color: color),
              SizedBox(height: 3 * sf),
              GoopText(
                label,
                style: TextStyle(
                  fontSize: 12 * sf,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: color,
                ),
              ),
              GoopText(
                sub,
                style: TextStyle(
                  fontSize: 8.5 * sf,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final double sf;
  final bool filled;
  const _StepButton({
    required this.label,
    required this.onTap,
    required this.color,
    required this.sf,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final positive = label.startsWith('+');
    return Semantics(
      button: true,
      label:
          '${label.replaceAll('.', '')} ${positive ? 'increase' : 'decrease'}',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12 * sf,
            vertical: 10 * sf,
          ),
          decoration: BoxDecoration(
            color: color.withValues(
              alpha: positive ? (filled ? 0.2 : 0.08) : 0.05,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: positive ? 0.55 : 0.28),
            ),
          ),
          child: Center(
            child: GoopText(
              label,
              style: TextStyle(
                fontSize: 14 * sf,
                fontWeight: FontWeight.w900,
                color: positive
                    ? color
                    : Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
