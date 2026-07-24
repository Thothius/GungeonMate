import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../models/gun.dart';
import '../../services/goop_talk_engine.dart';


class RobotDashboardSliver extends StatefulWidget {
  const RobotDashboardSliver({super.key});

  @override
  State<RobotDashboardSliver> createState() => RobotDashboardSliverState();
}

class RobotDashboardSliverState extends State<RobotDashboardSliver> {
  bool _terminalExpanded = true;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final player = p.runState.main;
    final double damageBoost = (p.robotJunk + (p.robotLies ? 1 : 0)) * 5.0 + (p.robotGoldJunk ? 500.0 : 0.0);
    final double multiplier = 1.0 + damageBoost / 100.0;
    final guns = player.guns;

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
                onTap: null,
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
                        
                      ],
                    ),
                  ],
                ),
                ),
              ),
              if (!_collapsed) ...[
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

              // Toggle row — full width, two big compact tap targets
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

              // Expandable Damage Terminal
              if (guns.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildTerminalToggle(),
                if (_terminalExpanded) _buildDamageTerminal(guns, multiplier),
              ],
              ],
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

  Widget _buildTerminalToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF001100),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3), width: 1.0),
      ),
      child: Row(
        children: [
          Icon(Icons.terminal_rounded, size: 16, color: Colors.green.withValues(alpha: 0.8)),
          const SizedBox(width: 8),
          GoopText(
            'DAMAGE CALCULATOR',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.green.withValues(alpha: 0.8),
              letterSpacing: 0.8,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDamageTerminal(List<Gun> guns, double multiplier) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF000800),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.25), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Terminal header
          Row(
            children: [
              GoopText(
                '> ROBOT_DMG_CALC v1.0',
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
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.greenAccent,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Column headers
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: GoopText(
                    'WEAPON',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.green.withValues(alpha: 0.4),
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: GoopText(
                    'BASE',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.green.withValues(alpha: 0.4),
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: GoopText(
                    'ROBOT',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.green.withValues(alpha: 0.4),
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: GoopText(
                    '╬ö',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.green.withValues(alpha: 0.4),
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Divider line
          Container(height: 1, color: Colors.green.withValues(alpha: 0.15)),
          const SizedBox(height: 4),
          // Gun rows
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
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.greenAccent,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: GoopText(
                      '+${(gun.dpsValue * multiplier - gun.dpsValue).toStringAsFixed(1)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.green.withValues(alpha: 0.5),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Terminal footer
          const SizedBox(height: 6),
          Container(height: 1, color: Colors.green.withValues(alpha: 0.15)),
          const SizedBox(height: 4),
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
                style: TextStyle(
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
    );
  }
}