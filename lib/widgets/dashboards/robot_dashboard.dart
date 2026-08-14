import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/haptics.dart';


class RobotDashboardSliver extends StatefulWidget {
  const RobotDashboardSliver({super.key});

  @override
  State<RobotDashboardSliver> createState() => RobotDashboardSliverState();
}

class RobotDashboardSliverState extends State<RobotDashboardSliver> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final double damageBoost = (p.robotJunk + (p.robotLies ? 1 : 0)) * 5.0 + (p.robotGoldJunk ? 500.0 : 0.0);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.cyan.withValues(alpha: 0.35), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withValues(alpha: 0.04),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with big DMG boost badge
              InkWell(
                onTap: () { setState(() => _collapsed = !_collapsed); Haptics.selection(); },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.android_rounded, color: Colors.cyanAccent, size: 20),
                        SizedBox(width: 8),
                        GoopText(
                          'THE ROBOT HUD',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.cyanAccent,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: p.robotGoldJunk
                                ? Colors.amber.withValues(alpha: 0.18)
                                : Colors.cyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: p.robotGoldJunk
                                  ? Colors.amber.withValues(alpha: 0.5)
                                  : Colors.cyan.withValues(alpha: 0.4),
                              width: 1.0,
                            ),
                          ),
                          child: GoopText(
                            '+${damageBoost.toStringAsFixed(0)}% DMG',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: p.robotGoldJunk ? Colors.amberAccent : Colors.cyanAccent,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      Icon(_collapsed ? Icons.expand_more : Icons.expand_less, size: 16, color: Colors.white54),
                      ],
                    ),
                  ],
                ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: _collapsed
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
              const Divider(color: Colors.white12, height: 16),

              // Junk counter — full width, no overflow
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GoopText(
                          'JUNK COUNT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.cyanAccent,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        GoopText(
                          '+5% DMG each',
                          style: TextStyle(fontSize: 9, color: Colors.white38),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.cyanAccent, size: 24),
                          onPressed: p.robotJunk > 0 ? () => p.setRobotJunk(p.robotJunk - 1) : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '${p.robotJunk}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          icon: const Icon(Icons.add_circle_outline, color: Colors.cyanAccent, size: 24),
                          onPressed: () => p.setRobotJunk(p.robotJunk + 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Armor counter — Robot starts with 6 armor, gains from HP ups
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GoopText(
                          'ARMOR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.cyanAccent,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        GoopText(
                          'Hits before HP loss',
                          style: TextStyle(fontSize: 9, color: Colors.white38),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.cyanAccent, size: 24),
                          onPressed: p.robotArmor > 0 ? () => p.setRobotArmor(p.robotArmor - 1) : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '${p.robotArmor}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          icon: const Icon(Icons.add_circle_outline, color: Colors.cyanAccent, size: 24),
                          onPressed: () => p.setRobotArmor(p.robotArmor + 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Toggle row 1 — Gold Junk + Lies
              Row(
                children: [
                  Expanded(
                    child: _buildCompactToggle(
                      label: 'GOLD JUNK',
                      subtitle: '+500%',
                      value: p.robotGoldJunk,
                      activeColor: Colors.amberAccent,
                      onChanged: p.setRobotGoldJunk,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactToggle(
                      label: 'LIES',
                      subtitle: '+5%',
                      value: p.robotLies,
                      activeColor: Colors.purpleAccent,
                      onChanged: p.setRobotLies,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Toggle row 2 — Fireplace + Battery
              Row(
                children: [
                  Expanded(
                    child: _buildCompactToggle(
                      label: 'FIREPLACE OUT',
                      subtitle: 'Extinguished',
                      value: p.fireplaceExtinguished,
                      activeColor: Colors.blueAccent,
                      onChanged: p.setFireplaceExtinguished,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactToggle(
                      label: 'BATTERY',
                      subtitle: 'Bullets synergy',
                      value: p.batteryBulletsSynergy,
                      activeColor: Colors.greenAccent,
                      onChanged: p.setBatteryBulletsSynergy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Toggle row 3 — Fuse Disarmer (full width)
              _buildCompactToggle(
                label: 'FUSE DISARMER',
                subtitle: 'Disables bomb fuses',
                value: p.fuseDisarmer,
                activeColor: Colors.orangeAccent,
                onChanged: p.setFuseDisarmer,
              ),

              // Damage Terminal hidden — takes too much vertical space in
              // the dashboard panel. The +DMG% badge in the header already
              // shows the boost. Users can use the universal Damage Calculator
              // toggle in settings for per-gun breakdowns.
                      ],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactToggle({
    required String label,
    required String subtitle,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value ? activeColor.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value ? activeColor.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08),
            width: value ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              color: value ? activeColor : Colors.white30,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GoopText(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: value ? activeColor : Colors.white60,
                      letterSpacing: 0.5,
                    ),
                  ),
                  GoopText(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9,
                      color: value ? activeColor.withValues(alpha: 0.8) : Colors.white30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}