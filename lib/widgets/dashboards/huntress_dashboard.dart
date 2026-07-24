import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../services/goop_talk_engine.dart';

/// Compact Huntress HUD: dig chance + item weights. Single concise card.
class HuntressDashboardSliver extends StatelessWidget {
  const HuntressDashboardSliver({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final ownedLower = p.runState.main.items.map((i) => i.name.toLowerCase()).toSet();
    final hasBabyGoodMimic = ownedLower.any((n) => n.contains('baby good mimic'));
    final digChance = hasBabyGoodMimic ? 10.0 : 5.0;

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
              // Header + dig chance badge
              Row(
                children: [
                  const Icon(Icons.pets_rounded, color: Colors.lightGreenAccent, size: 18),
                  const SizedBox(width: 8),
                  const GoopText(
                    'HUNTRESS & DOG',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.lightGreenAccent, letterSpacing: 0.8),
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
              // Item weights row
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