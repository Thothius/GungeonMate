part of '../special_gun_dashboards.dart';

class GunderfuryDashboardSliver extends StatefulWidget {
  final PlayerSlot slot;
  const GunderfuryDashboardSliver({super.key, required this.slot});

  @override
  State<GunderfuryDashboardSliver> createState() =>
      GunderfuryDashboardSliverState();
}

class GunderfuryDashboardSliverState extends State<GunderfuryDashboardSliver> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final p = context.read<RunProvider>();
    final lvl = context
        .select<RunProvider, int>((p) => p.gunderfuryLevel)
        .clamp(1, 60);

    String formName = '';
    String description = '';
    String statsDesc = '';

    // Per-form stats verified against the wiki (guns.json multi-value
    // fields hold these same numbers, space-separated per form).
    if (lvl < 20) {
      formName = 'Base Form';
      description = 'Fires wide shotgun-like energy blasts.';
      statsDesc =
          'Damage: 3.5x6 (21) • Fire Rate: 0.7s • Mag: 8 • Ammo: 200 • DPS: 25.5';
    } else if (lvl < 30) {
      formName = 'Automatic Form';
      description = 'Increases fire rate and becomes fully automatic.';
      statsDesc =
          'Damage: 3.5 • Fire Rate: 0.085s • Mag: 30 • Ammo: 300 • DPS: 29.6';
    } else if (lvl < 40) {
      formName = 'Defender Form';
      description = 'Shoots larger, high-velocity energy spheres.';
      statsDesc =
          'Damage: 21 • Fire Rate: 0.6s • Mag: 30 • Ammo: 350 • DPS: 33.2';
    } else if (lvl < 50) {
      formName = 'Vindicator Form';
      description =
          'Fires faster with elevated accuracy and tighter groupings.';
      statsDesc =
          'Damage: 15 • Fire Rate: 0.4s • Mag: 40 • Ammo: 400 • DPS: 34.1';
    } else if (lvl < 60) {
      formName = 'Laser Rifle';
      description = 'Fires sustained continuous rapid energy laser pulses.';
      statsDesc =
          'Damage: 15 • Fire Rate: 0.12s • Mag: 50 • Ammo: 500 • DPS: 107.1';
    } else {
      formName = 'Awakened Gunderfury';
      description =
          'Legendary form of the Blessed Gunseeker. Rapidly shoots twin light beams with absolute 0° spread, bouncing, and piercing!';
      statsDesc =
          'Damage: 20x2 (40) • Fire Rate: 0.085s • Mag: 40 • Ammo: 600 • DPS: 181.8';
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.flair.scaffold.withValues(alpha: 0.6),
            borderRadius: BorderRadius.all(Radii.md),
            border: Border.all(
              color: Skeuo.inkIf(Colors.purpleAccent).withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Skeuo.inkIf(Colors.purpleAccent).withValues(alpha: 0.04),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() => _collapsed = !_collapsed);
                  Haptics.selection();
                },
                borderRadius: BorderRadius.all(Radii.md),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.bolt,
                            color: Skeuo.inkIf(Colors.purpleAccent.shade100),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          GoopText(
                            'GUNDERFURY HUD - LVL $lvl',
                            style: TextStyle(
                              fontSize: FontSizes.labelMedium,
                              fontWeight: FontWeight.w900,
                              color: Skeuo.inkIf(Colors.purpleAccent.shade100),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Skeuo.inkIf(
                                Colors.purple,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: GoopText(
                              formName.toUpperCase(),
                              style: TextStyle(
                                fontSize: FontSizes.labelSmall,
                                fontWeight: FontWeight.w900,
                                color: Skeuo.inkIf(
                                  Colors.purpleAccent.shade100,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _collapsed ? Icons.expand_more : Icons.expand_less,
                            size: 16,
                            color: Colors.white54,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child:
                    _collapsed
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
                                      borderRadius: BorderRadius.all(Radii.sm),
                                      border: Border.all(
                                        color: Skeuo.inkIf(
                                          Colors.purpleAccent,
                                        ).withValues(alpha: 0.15),
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: Image.asset(
                                      'assets/images/guns/gunderfury.webp',
                                      fit: BoxFit.contain,
                                      cacheWidth: 144,
                                      cacheHeight: 144,
                                      errorBuilder:
                                          (_, _, _) => const Icon(
                                            Icons.broken_image_outlined,
                                            color: Colors.white24,
                                            size: 30,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        GoopText(
                                          description,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            color: Colors.white70,
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        GoopText(
                                          statsDesc,
                                          style: TextStyle(
                                            fontSize: FontSizes.labelSmall,
                                            color: Skeuo.inkIf(
                                              Colors.purpleAccent.shade100,
                                            ).withValues(alpha: 0.8),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: Insets.sm,
                                                      vertical: Insets.xs,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.02),
                                                  borderRadius:
                                                      BorderRadius.all(
                                                        Radii.sm,
                                                      ),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withValues(
                                                          alpha: 0.04,
                                                        ),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    const GoopText(
                                                      'GUNDER LEVEL',
                                                      style: TextStyle(
                                                        fontSize:
                                                            FontSizes
                                                                .labelSmall,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color: Colors.white60,
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        GestureDetector(
                                                          behavior:
                                                              HitTestBehavior
                                                                  .opaque,
                                                          onTap:
                                                              lvl > 1
                                                                  ? () {
                                                                    Haptics.light();
                                                                    p.setGunderfuryLevel(
                                                                      lvl - 1,
                                                                    );
                                                                  }
                                                                  : null,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 6,
                                                                ),
                                                            child: Icon(
                                                              Icons
                                                                  .remove_circle_rounded,
                                                              color:
                                                                  lvl > 1
                                                                      ? Colors
                                                                          .purpleAccent
                                                                      : Colors
                                                                          .white24,
                                                              size: 30,
                                                            ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                              ),
                                                          child: Text(
                                                            '$lvl',
                                                            style: const TextStyle(
                                                              fontSize:
                                                                  FontSizes
                                                                      .bodyMedium,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                        GestureDetector(
                                                          behavior:
                                                              HitTestBehavior
                                                                  .opaque,
                                                          onTap:
                                                              lvl < 60
                                                                  ? () {
                                                                    Haptics.light();
                                                                    p.setGunderfuryLevel(
                                                                      lvl + 1,
                                                                    );
                                                                  }
                                                                  : null,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 6,
                                                                ),
                                                            child: const Icon(
                                                              Icons
                                                                  .add_circle_rounded,
                                                              color:
                                                                  Colors
                                                                      .purpleAccent,
                                                              size: 30,
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
    final p = context.read<RunProvider>();
    final activeStage = context.select<RunProvider, int>((p) => p.evolverForm);

    final stages = [
      _EvolverStageSpec(
        id: 1,
        name: 'Amoeba',
        dps: '13.5 DPS',
        bullet: 'Base round shots',
        color: Skeuo.inkIf(Colors.tealAccent),
      ),
      _EvolverStageSpec(
        id: 2,
        name: 'Sponge',
        dps: '19.1 DPS',
        bullet: 'Soaks up shots',
        color: Skeuo.inkIf(Colors.greenAccent),
      ),
      _EvolverStageSpec(
        id: 3,
        name: 'Flatworm',
        dps: '25.8 DPS',
        bullet: 'Wide flattened shots',
        color: Skeuo.inkIf(Colors.limeAccent),
      ),
      _EvolverStageSpec(
        id: 4,
        name: 'Snail',
        dps: '34.5 DPS',
        bullet: '3-spiked shell spread',
        color: Skeuo.inkIf(Colors.amberAccent),
      ),
      _EvolverStageSpec(
        id: 5,
        name: 'Frog',
        dps: '23.0 DPS/sec',
        bullet: 'Tracking tongue',
        color: Skeuo.inkIf(Colors.orangeAccent),
      ),
      _EvolverStageSpec(
        id: 6,
        name: 'Dragon',
        dps: '93.8 DPS',
        bullet: 'Accelerating homing blue flames',
        color: Skeuo.inkIf(Colors.redAccent),
      ),
    ];

    final currentSpec = stages[activeStage - 1];

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.flair.scaffold.withValues(alpha: 0.6),
            borderRadius: BorderRadius.all(Radii.md),
            border: Border.all(
              color: Skeuo.inkIf(Colors.greenAccent).withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Skeuo.inkIf(Colors.greenAccent).withValues(alpha: 0.04),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() => _collapsed = !_collapsed);
                  Haptics.selection();
                },
                borderRadius: BorderRadius.all(Radii.md),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.bubble_chart,
                            color: Skeuo.inkIf(Colors.greenAccent.shade100),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          GoopText(
                            'EVOLVER HUD',
                            style: TextStyle(
                              fontSize: FontSizes.labelMedium,
                              fontWeight: FontWeight.w900,
                              color: Skeuo.inkIf(Colors.greenAccent.shade100),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Skeuo.inkIf(
                                Colors.green,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: GoopText(
                              'STAGE $activeStage: ${currentSpec.name.toUpperCase()}',
                              style: TextStyle(
                                fontSize: FontSizes.labelSmall,
                                fontWeight: FontWeight.w900,
                                color: currentSpec.color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _collapsed ? Icons.expand_more : Icons.expand_less,
                            size: 16,
                            color: Colors.white54,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child:
                    _collapsed
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
                                      borderRadius: BorderRadius.all(Radii.sm),
                                      border: Border.all(
                                        color: currentSpec.color.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: Image.asset(
                                      'assets/images/guns/evolver.webp',
                                      fit: BoxFit.contain,
                                      cacheWidth: 144,
                                      cacheHeight: 144,
                                      errorBuilder:
                                          (_, _, _) => const Icon(
                                            Icons.broken_image_outlined,
                                            color: Colors.white24,
                                            size: 30,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        GoopText(
                                          'Stage $activeStage: ${currentSpec.name} • ${currentSpec.dps}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: currentSpec.color,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        GoopText(
                                          'Form Bullet: ${currentSpec.bullet}',
                                          style: const TextStyle(
                                            fontSize: FontSizes.labelSmall,
                                            color: Colors.white70,
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: Insets.sm,
                                                      vertical: Insets.xs,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.02),
                                                  borderRadius:
                                                      BorderRadius.all(
                                                        Radii.sm,
                                                      ),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withValues(
                                                          alpha: 0.04,
                                                        ),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    const GoopText(
                                                      'EVOLUTION STAGE',
                                                      style: TextStyle(
                                                        fontSize:
                                                            FontSizes
                                                                .labelSmall,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color: Colors.white60,
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        GestureDetector(
                                                          behavior:
                                                              HitTestBehavior
                                                                  .opaque,
                                                          onTap:
                                                              activeStage > 1
                                                                  ? () {
                                                                    Haptics.light();
                                                                    p.setEvolverForm(
                                                                      activeStage -
                                                                          1,
                                                                    );
                                                                  }
                                                                  : null,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 6,
                                                                ),
                                                            child: Icon(
                                                              Icons
                                                                  .remove_circle_rounded,
                                                              color:
                                                                  activeStage >
                                                                          1
                                                                      ? Colors
                                                                          .greenAccent
                                                                      : Colors
                                                                          .white24,
                                                              size: 30,
                                                            ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                              ),
                                                          child: Text(
                                                            '$activeStage',
                                                            style: const TextStyle(
                                                              fontSize:
                                                                  FontSizes
                                                                      .bodyMedium,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                        GestureDetector(
                                                          behavior:
                                                              HitTestBehavior
                                                                  .opaque,
                                                          onTap:
                                                              activeStage < 6
                                                                  ? () {
                                                                    Haptics.light();
                                                                    p.setEvolverForm(
                                                                      activeStage +
                                                                          1,
                                                                    );
                                                                  }
                                                                  : null,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 6,
                                                                ),
                                                            child: const Icon(
                                                              Icons
                                                                  .add_circle_rounded,
                                                              color:
                                                                  Colors
                                                                      .greenAccent,
                                                              size: 30,
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

class _EvolverStageSpec {
  final int id;
  final String name;
  final String dps;
  final String bullet;
  final Color color;
  const _EvolverStageSpec({
    required this.id,
    required this.name,
    required this.dps,
    required this.bullet,
    required this.color,
  });
}
