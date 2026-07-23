import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../services/haptics.dart';
import '../../utils/format.dart';
import '../../utils/fast_route.dart';
import '../../services/goop_talk_engine.dart';
import '../../screens/stats_detail_screen.dart';

/// for quick zeroing.
class StatAdjusterSheet extends StatelessWidget {
  final bool isCool;
  const StatAdjusterSheet({super.key, required this.isCool});


  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final value = isCool ? p.runState.coolness : p.runState.curse;
    final accent = isCool
        ? const Color(0xFF29B6F6)
        : const Color(0xFFD32F2F);
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
          padding: const EdgeInsets.symmetric(horizontal: 4),
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
                fontSize: 14,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                GoopText(
                  formatStat(value),
                  style: TextStyle(
                    fontSize: 24,
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
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: OutlinedButton(
                      onPressed: () {
                        if (isCool) {
                          p.adjustCoolness(-value);
                        } else {
                          p.adjustCurse(-value);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
// Coolness hub sheet ΓÇö stat adjuster + quick actions + details link
// =============================================================================

class CoolnessSheet extends StatelessWidget {
  const CoolnessSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final value = p.runState.coolness;
    const accent = Color(0xFF00E5FF);

    void apply(double delta) => p.adjustCoolness(delta);

    Widget step(double delta) {
      final positive = delta > 0;
      final text = '${positive ? '+' : ''}${formatStat(delta)}';
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
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
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      );
    }

    Widget actionButton({
      required IconData icon,
      required Color color,
      required String label,
      required String subtitle,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(height: 6),
                    GoopText(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    GoopText(
                      subtitle,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final rechargeReduction = (value * 5).clamp(0.0, 50.0);
    final fuseReduction = (value * 2.5).clamp(0.0, 10.0);
    final roomReward = (1 + value - p.runState.totalCurse).clamp(0, 100);

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
                const Icon(Icons.ac_unit_rounded, color: accent, size: 22),
                const SizedBox(width: 8),
                const GoopText(
                  'COOLNESS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                GoopText(
                  formatStat(value),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: accent,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Compact live effects at current coolness level
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _coolEffectChip('CD SPEEDUP', '+${rechargeReduction.toStringAsFixed(0)}%', accent),
                _coolEffectChip('FUSE REDUCTION', '${fuseReduction.toStringAsFixed(1)}%', accent),
                _coolEffectChip('ROOM REWARD', '${roomReward.toStringAsFixed(0)}%', Colors.amber),
              ],
            ),
            const SizedBox(height: 16),

            // Stat adjuster row
            Row(
              children: [
                step(-1),
                step(-0.5),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: OutlinedButton(
                      onPressed: () => apply(-value),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
            const SizedBox(height: 16),

            // Quick coolness actions
            Row(
              children: [
                actionButton(
                  icon: Icons.smoking_rooms,
                  color: const Color(0xFF81D4FA),
                  label: 'Smoke Cig',
                  subtitle: '+1 cool',
                  onTap: () {
                    p.logSmokeCig();
                    Haptics.selection();
                  },
                ),
                actionButton(
                  icon: Icons.palette_rounded,
                  color: const Color(0xFFFF80AB),
                  label: 'Rainbow Run',
                  subtitle: '+1 cool',
                  onTap: () {
                    p.logRainbowRun();
                    Haptics.selection();
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Link to full coolness details
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    fastRoute(const StatsDetailScreen(
                      statType: StatType.coolness,
                    )),
                  );
                },
                icon: const Icon(Icons.analytics_outlined, size: 16),
                label: const GoopText(
                  'View Coolness Breakdown',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: accent.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _coolEffectChip(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 0.7),
      ),
      child: Column(
        children: [
          GoopText(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          GoopText(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color.withValues(alpha: 0.7), letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

// =============================================================================
// Curse hub sheet ΓÇö stat adjuster + curse actions + details link
// =============================================================================

class CurseSheet extends StatelessWidget {
  const CurseSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final value = p.runState.curse;
    const accent = Color(0xFFE040FB);

    void apply(double delta) => p.adjustCurse(delta);

    Widget step(double delta) {
      final positive = delta > 0;
      final text = '${positive ? '+' : ''}${formatStat(delta)}';
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
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
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      );
    }

    Widget actionButton({
      required IconData icon,
      required Color color,
      required String label,
      required String subtitle,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(height: 6),
                    GoopText(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    GoopText(
                      subtitle,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
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
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header row
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: accent, size: 22),
                const SizedBox(width: 8),
                const GoopText(
                  'CURSE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                GoopText(
                  formatStat(value),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: accent,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Curse meter bar ΓÇö visual 0-10 scale
            Builder(builder: (context) {
              final clamped = value.clamp(0.0, 10.0);
              final pct = clamped / 10.0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 8,
                      child: Stack(
                        children: [
                          // Background track
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          // Fill
                          FractionallySizedBox(
                            widthFactor: pct,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    accent.withValues(alpha: 0.5),
                                    accent,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          // Tick marks at each integer
                          Row(
                            children: List.generate(11, (i) => Expanded(
                              child: Align(
                                alignment: Alignment.center,
                                child: Container(
                                  width: 1,
                                  height: 8,
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                            )),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0', style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.35), fontWeight: FontWeight.w600)),
                      Text('5', style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.35), fontWeight: FontWeight.w600)),
                      Text('10', style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.35), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              );
            }),
            const SizedBox(height: 14),

            // Section label
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: GoopText(
                'EFFECTS AT CURRENT LEVEL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white38,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            // 3├ù2 grid of effect chips ΓÇö perfectly aligned
            Builder(builder: (context) {
              final currentIdx = value.floor().clamp(0, 10);
              final row = curseTable[currentIdx];
              Widget effectChip(String label, String val, Color color) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.30), width: 0.7),
                ),
                child: Column(
                  children: [
                    GoopText(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
                    const SizedBox(height: 3),
                    GoopText(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color.withValues(alpha: 0.7), letterSpacing: 0.3)),
                  ],
                ),
              );
              return Row(
                children: [
                  Expanded(child: effectChip('JAMMED', row.jammedEnemy, Colors.deepOrangeAccent)),
                  const SizedBox(width: 6),
                  Expanded(child: effectChip('JAM BOSS', row.jammedBoss, Colors.deepOrangeAccent)),
                  const SizedBox(width: 6),
                  Expanded(child: effectChip('MIMIC', row.mimicChance, Colors.redAccent)),
                ],
              );
            }),
            const SizedBox(height: 6),
            Builder(builder: (context) {
              final currentIdx = value.floor().clamp(0, 10);
              final row = curseTable[currentIdx];
              final coolness = p.runState.totalCoolness;
              final roomReward = (1 + coolness - value).clamp(-50, 100);
              Widget effectChip(String label, String val, Color color) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.30), width: 0.7),
                ),
                child: Column(
                  children: [
                    GoopText(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
                    const SizedBox(height: 3),
                    GoopText(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color.withValues(alpha: 0.7), letterSpacing: 0.3)),
                  ],
                ),
              );
              return Row(
                children: [
                  Expanded(child: effectChip('FUSE', row.fuseChance, Colors.redAccent)),
                  const SizedBox(width: 6),
                  Expanded(child: effectChip('ROOM', '${roomReward.toStringAsFixed(0)}%', Colors.amber)),
                  const SizedBox(width: 6),
                  Expanded(child: effectChip('AMMO', row.ammo, Colors.lightGreenAccent)),
                ],
              );
            }),
            const SizedBox(height: 16),

            // Section label
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: GoopText(
                'ADJUST CURSE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white38,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            // Stat adjuster row
            Row(
              children: [
                step(-1),
                step(-0.5),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: OutlinedButton(
                      onPressed: () => apply(-value),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
            const SizedBox(height: 16),

            // Section label
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: GoopText(
                'QUICK ACTIONS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white38,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            // Curse-raising actions
            Row(
              children: [
                actionButton(
                  icon: Icons.front_hand_outlined,
                  color: const Color(0xFFEF5350),
                  label: 'Steal',
                  subtitle: '+1 curse',
                  onTap: () {
                    p.logSteal();
                    Haptics.selection();
                  },
                ),
                actionButton(
                  icon: Icons.storefront_outlined,
                  color: const Color(0xFFCE93D8),
                  label: 'Cursula',
                  subtitle: '+2 curse',
                  onTap: () {
                    p.logCursula();
                    Haptics.selection();
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Full-width breakdown button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    fastRoute(const StatsDetailScreen(
                      statType: StatType.curse,
                    )),
                  );
                },
                icon: const Icon(Icons.analytics_outlined, size: 16),
                label: const GoopText(
                  'View Curse Breakdown',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent.withValues(alpha: 0.9),
                  side: BorderSide(color: accent.withValues(alpha: 0.3), width: 0.8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
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