import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../models/player.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/haptics.dart';



class GunderfuryDashboardSliver extends StatefulWidget {
  final PlayerSlot slot;
  const GunderfuryDashboardSliver({super.key, required this.slot});

  @override
  State<GunderfuryDashboardSliver> createState() => GunderfuryDashboardSliverState();
}

class GunderfuryDashboardSliverState extends State<GunderfuryDashboardSliver> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final lvl = p.gunderfuryLevel.clamp(1, 60);

    String formName = '';
    String description = '';
    String statsDesc = '';

    if (lvl < 20) {
      formName = 'Base Form';
      description = 'Fires wide shotgun-like energy blasts.';
      statsDesc = 'Damage: 4.5 • Reload: 1.5s • Capacity: 450 • Spread: 10°';
    } else if (lvl < 30) {
      formName = 'Automatic Form';
      description = 'Increases fire rate and becomes fully automatic.';
      statsDesc = 'Damage: 4.5 • Reload: 1.5s • Capacity: 450 • Spread: 10° (Auto)';
    } else if (lvl < 40) {
      formName = 'Defender Form';
      description = 'Shoots larger, high-velocity energy spheres.';
      statsDesc = 'Damage: 6.5 • Reload: 1.1s • Capacity: 550 • Spread: 5°';
    } else if (lvl < 50) {
      formName = 'Vindicator Form';
      description = 'Fires faster with elevated accuracy and tighter groupings.';
      statsDesc = 'Damage: 6.5 • Reload: 1.1s • Capacity: 550 • Spread: 3°';
    } else if (lvl < 60) {
      formName = 'Laser Rifle';
      description = 'Fires sustained continuous rapid energy laser pulses.';
      statsDesc = 'Damage: 6.5 • Reload: 1.1s • Capacity: 550 • Spread: 2°';
    } else {
      formName = 'Awakened Gunderfury';
      description = 'Legendary form of the Blessed Gunseeker. Rapidly shoots twin light beams with absolute 0° spread, bouncing, and piercing!';
      statsDesc = 'Damage: 10.0 • Reload: 0.6s • Capacity: 650 • Spread: 0° (Perfect, Piercing, Bouncing)';
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF13151A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.35), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.purpleAccent.withValues(alpha: 0.04),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () { setState(() => _collapsed = !_collapsed); Haptics.selection(); },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bolt, color: Colors.purpleAccent.shade100, size: 20),
                          const SizedBox(width: 8),
                          GoopText(
                            'GUNDERFURY HUD - LVL $lvl',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.purpleAccent.shade100,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: GoopText(
                              formName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.purpleAccent.shade100,
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
                const Divider(color: Colors.white12, height: 1),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.15)),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          'assets/images/guns/gunderfury.webp',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white24,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GoopText(
                              description,
                              style: const TextStyle(fontSize: 10.5, color: Colors.white70, height: 1.3),
                            ),
                            const SizedBox(height: 6),
                            GoopText(
                              statsDesc,
                              style: TextStyle(
                                fontSize: 9.5,
                                color: Colors.purpleAccent.shade100.withValues(alpha: 0.8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.02),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const GoopText(
                                          'GUNDER LEVEL',
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white60),
                                        ),
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: lvl > 1 ? () { Haptics.light(); p.setGunderfuryLevel(lvl - 1); } : null,
                                              behavior: HitTestBehavior.opaque,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                child: Icon(
                                                  Icons.remove_circle_rounded,
                                                  color: lvl > 1 ? Colors.purpleAccent : Colors.white24,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: Text(
                                                '$lvl',
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: lvl < 60 ? () { Haptics.light(); p.setGunderfuryLevel(lvl + 1); } : null,
                                              behavior: HitTestBehavior.opaque,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                child: const Icon(
                                                  Icons.add_circle_rounded,
                                                  color: Colors.purpleAccent,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                      ],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TripleGunDashboardSliver extends StatefulWidget {
  final PlayerSlot slot;
  const TripleGunDashboardSliver({super.key, required this.slot});

  @override
  State<TripleGunDashboardSliver> createState() => TripleGunDashboardSliverState();
}

class TripleGunDashboardSliverState extends State<TripleGunDashboardSliver> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final form = p.tripleGunForm;

    String formName = '';
    String formDesc = '';
    if (form == 1) {
      formName = 'Form 1: Pistol (100%-33% Ammo)';
      formDesc = 'Fires rapid light shots. Very accurate. Bullet count: 1.';
    } else if (form == 2) {
      formName = 'Form 2: Shotgun (33%-11% Ammo)';
      formDesc = 'Fires a 3-bullet spread shot at closer range. High stagger.';
    } else {
      formName = 'Form 3: Laser Machine Gun (<11% Ammo)';
      formDesc = 'Fires continuous energy beam blasts. Incredibly high damage and rapid rate of fire.';
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF13151A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.35), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.04),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () { setState(() => _collapsed = !_collapsed); Haptics.selection(); },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.alt_route, color: Colors.blueAccent.shade100, size: 20),
                          const SizedBox(width: 8),
                          GoopText(
                            'TRIPLE GUN HUD',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.blueAccent.shade100,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: GoopText(
                              'FORM $form',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.blueAccent.shade100,
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
                const Divider(color: Colors.white12, height: 1),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.15)),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          'assets/images/guns/triple_gun.webp',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white24,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GoopText(
                              formName,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            GoopText(
                              formDesc,
                              style: const TextStyle(fontSize: 10, color: Colors.white70, height: 1.3),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.02),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const GoopText(
                                          'ACTIVE FORM',
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white60),
                                        ),
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: form > 1 ? () { Haptics.light(); p.setTripleGunForm(form - 1); } : null,
                                              behavior: HitTestBehavior.opaque,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                child: Icon(
                                                  Icons.remove_circle_rounded,
                                                  color: form > 1 ? Colors.blueAccent : Colors.white24,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: Text(
                                                '$form',
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: form < 3 ? () { Haptics.light(); p.setTripleGunForm(form + 1); } : null,
                                              behavior: HitTestBehavior.opaque,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                child: const Icon(
                                                  Icons.add_circle_rounded,
                                                  color: Colors.blueAccent,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                      ],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EvolverDashboardSliver extends StatefulWidget {
  final PlayerSlot slot;
  const EvolverDashboardSliver({super.key, required this.slot});

  @override
  State<EvolverDashboardSliver> createState() => EvolverDashboardSliverState();
}

class EvolverDashboardSliverState extends State<EvolverDashboardSliver> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final activeStage = p.evolverForm;

    final stages = const [
      EvolverStageSpec(id: 1, name: 'Amoeba', dps: '13.5 DPS', bullet: 'Base round shots', color: Colors.tealAccent),
      EvolverStageSpec(id: 2, name: 'Sponge', dps: '19.1 DPS', bullet: 'Soaks up shots', color: Colors.greenAccent),
      EvolverStageSpec(id: 3, name: 'Flatworm', dps: '25.8 DPS', bullet: 'Wide flattened shots', color: Colors.limeAccent),
      EvolverStageSpec(id: 4, name: 'Snail', dps: '34.5 DPS', bullet: '3-spiked shell spread', color: Colors.amberAccent),
      EvolverStageSpec(id: 5, name: 'Frog', dps: '23.0 DPS/sec', bullet: 'Tracking tongue', color: Colors.orangeAccent),
      EvolverStageSpec(id: 6, name: 'Dragon', dps: '93.8 DPS', bullet: 'Accelerating homing blue flames', color: Colors.redAccent),
    ];

    final currentSpec = stages[activeStage - 1];

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF13151A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.35), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withValues(alpha: 0.04),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () { setState(() => _collapsed = !_collapsed); Haptics.selection(); },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bubble_chart, color: Colors.greenAccent.shade100, size: 20),
                          const SizedBox(width: 8),
                          GoopText(
                            'EVOLVER HUD',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.greenAccent.shade100,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: GoopText(
                              'STAGE $activeStage: ${currentSpec.name.toUpperCase()}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: currentSpec.color,
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
                const Divider(color: Colors.white12, height: 1),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: currentSpec.color.withValues(alpha: 0.25)),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          'assets/images/guns/evolver.webp',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white24,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GoopText(
                              'Stage $activeStage: ${currentSpec.name} • ${currentSpec.dps}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: currentSpec.color),
                            ),
                            const SizedBox(height: 4),
                            GoopText(
                              'Form Bullet: ${currentSpec.bullet}',
                              style: const TextStyle(fontSize: 10, color: Colors.white70, height: 1.3),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.02),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const GoopText(
                                          'EVOLUTION STAGE',
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white60),
                                        ),
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: activeStage > 1 ? () { Haptics.light(); p.setEvolverForm(activeStage - 1); } : null,
                                              behavior: HitTestBehavior.opaque,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                child: Icon(
                                                  Icons.remove_circle_rounded,
                                                  color: activeStage > 1 ? Colors.greenAccent : Colors.white24,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: Text(
                                                '$activeStage',
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: activeStage < 6 ? () { Haptics.light(); p.setEvolverForm(activeStage + 1); } : null,
                                              behavior: HitTestBehavior.opaque,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                child: const Icon(
                                                  Icons.add_circle_rounded,
                                                  color: Colors.greenAccent,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                      ],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EvolverStageSpec {
  final int id;
  final String name;
  final String dps;
  final String bullet;
  final Color color;
  const EvolverStageSpec({
    required this.id,
    required this.name,
    required this.dps,
    required this.bullet,
    required this.color,
  });
}


/// Damage Calculator bottom sheet — opened via the calc icon in the
/// GungeoneerHeader trailing row. Sums quantifiable "Damage Up"/"Damage
/// Down" effects from the player's current guns + items via
/// [DamageCalculator] and applies the resulting multiplier to every