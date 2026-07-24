import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../services/goop_talk_engine.dart';

/// Compact Huntress HUD: dig chance + item weights. Single concise card.
/// Toggle on left switches between full pickup weights and health-focused stats.
class HuntressDashboardSliver extends StatefulWidget {
  const HuntressDashboardSliver({super.key});

  @override
  State<HuntressDashboardSliver> createState() => _HuntressDashboardSliverState();
}

class _HuntressDashboardSliverState extends State<HuntressDashboardSliver> {
  bool _healthMode = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final ownedLower = p.runState.main.items.map((i) => i.name.toLowerCase()).toSet();
    final hasBabyGoodMimic = ownedLower.any((n) => n.contains('baby good mimic'));
    final digChance = hasBabyGoodMimic ? 10.0 : 5.0;

    // Derived health stats
    final healthWeight = 45.0;
    final effectiveHealthPerRoom = digChance * healthWeight / 100;
    final lostHealthPerRoom = effectiveHealthPerRoom; // without dog, you get 0

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF101408),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.lightGreen.withValues(alpha: 0.35), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header + toggle + dig chance badge
              Row(
                children: [
                  const Icon(Icons.pets_rounded, color: Colors.lightGreenAccent, size: 18),
                  const SizedBox(width: 8),
                  const GoopText(
                    'HUNTRESS & DOG',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.lightGreenAccent, letterSpacing: 0.8),
                  ),
                  const SizedBox(width: 8),
                  // Health toggle button
                  GestureDetector(
                    onTap: () => setState(() => _healthMode = !_healthMode),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _healthMode
                            ? Colors.redAccent.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: _healthMode ? Colors.redAccent : Colors.white24,
                          width: _healthMode ? 1.0 : 0.6,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _healthMode ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 11,
                            color: _healthMode ? Colors.redAccent : Colors.white38,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _healthMode ? 'HP' : 'ALL',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: _healthMode ? Colors.redAccent : Colors.white38,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: hasBabyGoodMimic ? Colors.purple.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: hasBabyGoodMimic ? Colors.purpleAccent : Colors.lightGreenAccent, width: 0.8),
                    ),
                    child: GoopText(
                      'DIG: ${digChance.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: hasBabyGoodMimic ? Colors.purpleAccent : Colors.lightGreenAccent),
                    ),
                  ),
                ],
              ),
              if (hasBabyGoodMimic) ...[
                const SizedBox(height: 6),
                GoopText(
                  'Baby Good Mimic active — dig rate doubled',
                  style: TextStyle(fontSize: 9.5, fontStyle: FontStyle.italic, color: Colors.purpleAccent.shade100),
                ),
              ],
              const SizedBox(height: 10),
              // Content: either full weights or health-focused stats
              if (_healthMode)
                _buildHealthStats(effectiveHealthPerRoom, lostHealthPerRoom, hasBabyGoodMimic)
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildWeight('❤', '45%', Colors.redAccent),
                    _buildWeight('🔑', '20%', Colors.amberAccent),
                    _buildWeight('🛡', '15%', Colors.blueAccent),
                    _buildWeight('📦', '15%', Colors.orangeAccent),
                    _buildWeight('💥', '5%', Colors.pinkAccent),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthStats(double effectivePerRoom, double lostPerRoom, bool hasBgm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildHealthStat('❤ PER ROOM', '${effectivePerRoom.toStringAsFixed(2)}%', Colors.redAccent),
            const SizedBox(width: 12),
            _buildHealthStat('LOST W/O DOG', '${lostPerRoom.toStringAsFixed(2)}%', Colors.redAccent.shade100),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildHealthStat('❤ WEIGHT', '45%', Colors.redAccent),
            const SizedBox(width: 12),
            _buildHealthStat('ROOMS/❤', (100 / effectivePerRoom).toStringAsFixed(1), Colors.amberAccent),
          ],
        ),
      ],
    );
  }

  Widget _buildHealthStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoopText(
            label,
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color.withValues(alpha: 0.7), letterSpacing: 0.5),
          ),
          const SizedBox(height: 2),
          GoopText(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildWeight(String emoji, String value, Color color) {
    return Column(
      children: [
        GoopText(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        GoopText(emoji, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

// =============================================================================