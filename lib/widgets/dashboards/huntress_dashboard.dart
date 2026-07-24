import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../services/haptics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/goop_talk_engine.dart';

/// Compact Huntress HUD: dig chance, item weights, mimic alert, and
/// treat/pet counters. No tabs — single concise card.
class HuntressDashboardSliver extends StatefulWidget {
  const HuntressDashboardSliver({super.key});

  @override
  State<HuntressDashboardSliver> createState() => HuntressDashboardSliverState();
}

class HuntressDashboardSliverState extends State<HuntressDashboardSliver> {
  int _petCount = 0;
  int _treatCount = 0;
  bool _collapsed = true;

  @override
  void initState() {
    super.initState();
    _loadCounters();
  }

  Future<void> _loadCounters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _petCount = prefs.getInt('dog.pet_count') ?? 0;
          _treatCount = prefs.getInt('dog.treat_count') ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _incrementPet() async {
    Haptics.light();
    setState(() => _petCount++);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('dog.pet_count', _petCount);
    } catch (_) {}
  }

  Future<void> _incrementTreat() async {
    Haptics.light();
    setState(() => _treatCount++);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('dog.treat_count', _treatCount);
    } catch (_) {}
  }

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
              // Header + dig chance badge + collapse toggle
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
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      Haptics.selection();
                      setState(() => _collapsed = !_collapsed);
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Icon(
                      _collapsed ? Icons.expand_more_rounded : Icons.expand_less_rounded,
                      color: Colors.lightGreenAccent.withValues(alpha: 0.7),
                      size: 18,
                    ),
                  ),
                ],
              ),
              if (!_collapsed) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: GoopText(
                    '✨ Baby Good Mimic active — dig rate doubled',
                    style: TextStyle(fontSize: 9.5, fontStyle: FontStyle.italic, color: Colors.purpleAccent.shade100),
                  ),
                ),
              const SizedBox(height: 10),
              // Item weights row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildWeight('Γ¥ñ∩╕Å', '45%', Colors.redAccent),
                  _buildWeight('≡ƒöæ', '20%', Colors.amberAccent),
                  _buildWeight('≡ƒ¢í∩╕Å', '15%', Colors.blueAccent),
                  _buildWeight('≡ƒôª', '15%', Colors.orangeAccent),
                  _buildWeight('≡ƒÆÑ', '5%', Colors.pinkAccent),
                ],
              ),
              const SizedBox(height: 10),
              // Mimic alert
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 14),
                    SizedBox(width: 8),
                    Expanded(
                      child: GoopText(
                        'Junior II growls at mimic chests before they wake.',
                        style: TextStyle(fontSize: 9.5, color: Colors.redAccent, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Treat/Pet counters
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _incrementTreat,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.orangeAccent, size: 14),
                            const SizedBox(width: 6),
                            GoopText('TREATS: $_treatCount', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: _incrementPet,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.pinkAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 14),
                            const SizedBox(width: 6),
                            GoopText('PETS: $_petCount', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              ], // end if (!_collapsed)
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