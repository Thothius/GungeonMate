part of 'gun_stats.dart';

// Special-gun info sections extracted from GunStats (Phase 5d) —
// same library, abstract field requirement satisfied by GunStats.

mixin _GunStatsSections on StatelessWidget {
  Gun get gun;

  Widget _buildGunderfuryInfo(BuildContext context, RunProvider p) {
    final lvl = context
        .select<RunProvider, int>((p) => p.gunderfuryLevel)
        .clamp(1, 60);
    String formName = '';
    String description = '';
    String statsDesc = '';
    int currentXp = 0;

    if (lvl < 20) {
      formName = 'Base Form';
      description = 'Fires wide shotgun-like energy blasts.';
      statsDesc = 'Damage: 4.5 • Reload: 1.5s • Capacity: 450 • Spread: 10°';
      currentXp = ((lvl / 20) * 8000).round();
    } else if (lvl < 30) {
      formName = 'Automatic Form';
      description = 'Increases fire rate and becomes fully automatic.';
      statsDesc =
          'Damage: 4.5 • Reload: 1.5s • Capacity: 450 • Spread: 10° (Auto)';
      currentXp = 8000 + (((lvl - 20) / 10) * 13000).round();
    } else if (lvl < 40) {
      formName = 'Defender Form';
      description =
          'Shoots larger, high-velocity energy spheres with increased punch.';
      statsDesc = 'Damage: 6.5 • Reload: 1.1s • Capacity: 550 • Spread: 5°';
      currentXp = 21000 + (((lvl - 30) / 10) * 16500).round();
    } else if (lvl < 50) {
      formName = 'Vindicator Form';
      description =
          'Fires faster with elevated accuracy and tighter groupings.';
      statsDesc = 'Damage: 6.5 • Reload: 1.1s • Capacity: 550 • Spread: 3°';
      currentXp = 37500 + (((lvl - 40) / 10) * 17500).round();
    } else if (lvl < 60) {
      formName = 'Laser Rifle';
      description = 'Fires sustained continuous rapid energy laser pulses.';
      statsDesc = 'Damage: 6.5 • Reload: 1.1s • Capacity: 550 • Spread: 2°';
      currentXp = 55000 + (((lvl - 50) / 10) * 20000).round();
    } else {
      formName = 'Awakened Gunderfury';
      description =
          'Legendary form of the Blessed Gunseeker. Rapidly shoots twin light beams with absolute 0° spread, bouncing, and piercing!';
      statsDesc =
          'Damage: 10.0 • Reload: 0.6s • Capacity: 650 • Spread: 0° (Perfect accuracy, Piercing, Bouncing)';
      currentXp = 75000;
    }

    final double xpProgress = (currentXp / 75000).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: Insets.md),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.all(Radii.md),
        border: Border.all(
          color: Colors.purpleAccent.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withValues(alpha: 0.04),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: Colors.purpleAccent.shade100, size: 20),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: GoopText(
                  'GUNDERFURY LEVEL TRACKER',
                  style: TextStyle(
                    fontSize: FontSizes.labelMedium,
                    fontWeight: FontWeight.w900,
                    color: Colors.purpleAccent.shade100,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Decrease Gunderfury level',
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      size: 22,
                      color: Colors.white70,
                    ),
                    onPressed:
                        lvl > 1 ? () => p.setGunderfuryLevel(lvl - 1) : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$lvl',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.purpleAccent,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Increase Gunderfury level',
                    icon: const Icon(
                      Icons.add_circle_outline,
                      size: 22,
                      color: Colors.white70,
                    ),
                    onPressed:
                        lvl < 60 ? () => p.setGunderfuryLevel(lvl + 1) : null,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.purpleAccent,
              inactiveTrackColor: Colors.purple.withValues(alpha: 0.2),
              thumbColor: Colors.purpleAccent,
              overlayColor: Colors.purpleAccent.withValues(alpha: 0.2),
              valueIndicatorColor: Colors.purple,
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: SizedBox(
              height: Insets.xxl,
              child: Slider(
                value: lvl.toDouble(),
                min: 1,
                max: 60,
                divisions: 59,
                onChanged: (val) {
                  p.setGunderfuryLevel(val.round());
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const GoopText(
                'EXPERIENCE GAUGE',
                style: TextStyle(
                  fontSize: FontSizes.labelSmall,
                  fontWeight: FontWeight.w900,
                  color: Colors.white54,
                  letterSpacing: 0.5,
                ),
              ),
              GoopText(
                lvl == 60
                    ? 'MAX LEVEL'
                    : '${currentXp.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} / 75,000 XP',
                style: TextStyle(
                  fontSize: FontSizes.labelSmall,
                  fontWeight: FontWeight.bold,
                  color:
                      lvl == 60
                          ? Colors.amberAccent
                          : Colors.purpleAccent.shade100,
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: xpProgress,
              minHeight: 6,
              backgroundColor: Colors.purple.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                lvl == 60 ? Colors.amber : Colors.purpleAccent,
              ),
            ),
          ),
          const SizedBox(height: Insets.md),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              QuickJumpButton(
                label: 'Lvl 10',
                active: lvl == 10,
                onTap: () => p.setGunderfuryLevel(10),
              ),
              QuickJumpButton(
                label: 'Lvl 20',
                active: lvl == 20,
                onTap: () => p.setGunderfuryLevel(20),
              ),
              QuickJumpButton(
                label: 'Lvl 30',
                active: lvl == 30,
                onTap: () => p.setGunderfuryLevel(30),
              ),
              QuickJumpButton(
                label: 'Lvl 40',
                active: lvl == 40,
                onTap: () => p.setGunderfuryLevel(40),
              ),
              QuickJumpButton(
                label: 'Lvl 50',
                active: lvl == 50,
                onTap: () => p.setGunderfuryLevel(50),
              ),
              QuickJumpButton(
                label: 'Lvl 60',
                active: lvl == 60,
                onTap: () => p.setGunderfuryLevel(60),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(Insets.xs),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.all(Radii.sm),
                  border: Border.all(
                    color: Colors.purpleAccent.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child: Image.asset(
                  'assets/images/guns/gunderfury.webp',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                  cacheWidth: 88,
                  cacheHeight: 88,
                ),
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GoopText(
                      'ACTIVE FORM: ${formName.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.purpleAccent,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    GoopText(
                      statsDesc,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          GoopText(
            description,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripleGunInfo(BuildContext context, RunProvider p) {
    final form = context.select<RunProvider, int>((p) => p.tripleGunForm);
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
      formDesc =
          'Fires continuous energy beam blasts. Incredibly high damage and rapid rate of fire.';
    }

    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.alt_route,
                color: Colors.blueAccent.shade100,
                size: 20,
              ),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: GoopText(
                  'Triple Gun Active Form',
                  style: TextStyle(
                    fontSize: FontSizes.bodyMedium,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent.shade100,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              QuickJumpButton(
                label: 'Form 1',
                active: form == 1,
                onTap: () => p.setTripleGunForm(1),
              ),
              QuickJumpButton(
                label: 'Form 2',
                active: form == 2,
                onTap: () => p.setTripleGunForm(2),
              ),
              QuickJumpButton(
                label: 'Form 3',
                active: form == 3,
                onTap: () => p.setTripleGunForm(3),
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          GoopText(
            formName,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: Insets.xs),
          GoopText(
            formDesc,
            style: TextStyle(
              fontSize: FontSizes.labelMedium,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvolverInfo(BuildContext context, RunProvider p) {
    final activeStage = context.select<RunProvider, int>((p) => p.evolverForm);
    final totalKills = context.select<RunProvider, int>((p) => p.evolverKills);

    final stages = const [
      EvolverStageSpec(
        id: 1,
        name: 'Amoeba',
        dps: '13.5 DPS',
        bullet: 'Base round shots',
        icon: Icons.bubble_chart_outlined,
        color: Colors.tealAccent,
      ),
      EvolverStageSpec(
        id: 2,
        name: 'Sponge',
        dps: '19.1 DPS',
        bullet: 'Soaks up shots',
        icon: Icons.layers_outlined,
        color: Colors.greenAccent,
      ),
      EvolverStageSpec(
        id: 3,
        name: 'Flatworm',
        dps: '25.8 DPS',
        bullet: 'Wide flattened shots',
        icon: Icons.gesture_outlined,
        color: Colors.limeAccent,
      ),
      EvolverStageSpec(
        id: 4,
        name: 'Snail',
        dps: '34.5 DPS',
        bullet: '3-spiked shell spread',
        icon: Icons.gps_fixed_outlined,
        color: Colors.amberAccent,
      ),
      EvolverStageSpec(
        id: 5,
        name: 'Frog',
        dps: '23.0 DPS',
        bullet: 'Continuous tracking tongue',
        icon: Icons.pets_outlined,
        color: Colors.orangeAccent,
      ),
      EvolverStageSpec(
        id: 6,
        name: 'Dragon',
        dps: '93.8 DPS',
        bullet: 'Accelerating homing blue flames',
        icon: Icons.fireplace_outlined,
        color: Colors.redAccent,
      ),
    ];

    final currentSpec = stages[activeStage - 1];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.greenAccent.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.03),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.science_outlined,
                color: Colors.greenAccent.shade200,
                size: 22,
              ),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GoopText(
                      'THE EVOLVER: METAMORPHOSIS ENGINE',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.greenAccent.shade200,
                        letterSpacing: 0.8,
                      ),
                    ),
                    GoopText(
                      'Biological Adaptations Slay Counter',
                      style: TextStyle(
                        fontSize: FontSizes.labelSmall,
                        color: Colors.greenAccent.withValues(alpha: 0.6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.all(Radii.sm),
                  border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Decrease Evolver kills',
                      icon: const Icon(
                        Icons.remove,
                        size: 16,
                        color: Colors.greenAccent,
                      ),
                      onPressed:
                          totalKills > 0
                              ? () => p.setEvolverKills(totalKills - 1)
                              : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Insets.xs,
                      ),
                      child: GoopText(
                        '$totalKills/25',
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'ArcadeClassic',
                          fontWeight: FontWeight.bold,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Increase Evolver kills',
                      icon: const Icon(
                        Icons.add,
                        size: 16,
                        color: Colors.greenAccent,
                      ),
                      onPressed:
                          totalKills < 25
                              ? () => p.setEvolverKills(totalKills + 1)
                              : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(stages.length, (i) {
                final spec = stages[i];
                final isUnlocked = activeStage >= spec.id;
                final isActive = activeStage == spec.id;
                final color =
                    isActive
                        ? spec.color
                        : (isUnlocked ? Colors.green.shade700 : Colors.white12);

                return Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (i < stages.length - 1)
                        Positioned(
                          left: 24,
                          right: -24,
                          top: 24,
                          child: Container(
                            height: 2.5,
                            color:
                                isUnlocked && activeStage > spec.id
                                    ? Colors.green.withValues(alpha: 0.5)
                                    : Colors.white10,
                          ),
                        ),
                      GestureDetector(
                        onTap: () {
                          p.setEvolverKills((spec.id - 1) * 5);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    isActive ? Colors.black45 : Colors.black26,
                                border: Border.all(
                                  color: color,
                                  width: isActive ? 2.5 : 1.2,
                                ),
                                boxShadow:
                                    isActive
                                        ? [
                                          BoxShadow(
                                            color: spec.color.withValues(
                                              alpha: 0.2,
                                            ),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                        : null,
                              ),
                              child: Icon(
                                isActive
                                    ? spec.icon
                                    : (isUnlocked
                                        ? spec.icon
                                        : Icons.lock_outline),
                                size: isActive ? 22 : 18,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: Insets.xs),
                            GoopText(
                              spec.name,
                              style: TextStyle(
                                fontSize: FontSizes.labelSmall,
                                fontWeight:
                                    isActive
                                        ? FontWeight.w900
                                        : FontWeight.bold,
                                color: isActive ? spec.color : Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: Insets.md),
          const GoopText(
            'UNIQUE ENEMY TYPES SLAIN CHECKLIST',
            style: TextStyle(
              fontSize: FontSizes.labelSmall,
              fontWeight: FontWeight.w900,
              color: Colors.greenAccent,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 5.5,
            runSpacing: 5.5,
            children: List.generate(25, (index) {
              final killNum = index + 1;
              final isChecked = totalKills >= killNum;
              final isThresholdNode = killNum % 5 == 0;

              return GestureDetector(
                onTap: () {
                  if (isChecked) {
                    p.setEvolverKills(killNum - 1);
                  } else {
                    p.setEvolverKills(killNum);
                  }
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color:
                        isChecked
                            ? (isThresholdNode
                                ? Colors.green.shade800
                                : Colors.green.withValues(alpha: 0.35))
                            : Colors.black38,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                          isChecked
                              ? Colors.greenAccent
                              : (isThresholdNode
                                  ? Colors.greenAccent.withValues(alpha: 0.3)
                                  : Colors.white12),
                      width: isThresholdNode ? 1.5 : 1.0,
                    ),
                  ),
                  child: Center(
                    child:
                        isChecked
                            ? Icon(
                              isThresholdNode ? Icons.star : Icons.check,
                              size: 13,
                              color: Colors.greenAccent,
                            )
                            : Text(
                              '$killNum',
                              style: TextStyle(
                                fontSize: FontSizes.labelSmall,
                                fontWeight: FontWeight.bold,
                                color:
                                    isThresholdNode
                                        ? Colors.greenAccent.withValues(
                                          alpha: 0.4,
                                        )
                                        : Colors.white54,
                              ),
                            ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: Insets.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: Insets.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: currentSpec.color.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentSpec.color,
                      ),
                    ),
                    const SizedBox(width: Insets.sm),
                    GoopText(
                      'BIO-ANALYSIS: STAGE ${currentSpec.id} [${currentSpec.name.toUpperCase()}]',
                      style: TextStyle(
                        fontFamily: 'EnterTheGungeonBig',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: currentSpec.color,
                      ),
                    ),
                    const Spacer(),
                    GoopText(
                      currentSpec.dps,
                      style: TextStyle(
                        fontFamily: 'ArcadeClassic',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: currentSpec.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                GoopText(
                  'Projectiles: ${currentSpec.bullet}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 3),
                GoopText(
                  'Formula: ${activeStage == 6 ? "Ultimate Form Unlocked!" : "Requires ${(activeStage * 5) - totalKills} more unique kills to force-evolve."}',
                  style: const TextStyle(fontSize: 10.5, color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShellegunInfo(BuildContext context, RunProvider p) {
    final mode = context.select<RunProvider, int>((p) => p.shellegunMode);
    const modeNames = ['Pistol (Manual)', 'Pistol (Auto)', 'Beam'];
    const modeDescs = [
      'Fires manually-controlled shells. Highest single-shot DPS.',
      'Fires automatically. Moderate fire rate, lower per-shot damage.',
      'Continuous beam. Low DPS but piercing and consistent.',
    ];
    const modeDps = [33.1, 24.0, 13.3];

    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: Colors.tealAccent.shade100, size: 20),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: GoopText(
                  'Shellegun Firing Mode',
                  style: TextStyle(
                    fontSize: FontSizes.bodyMedium,
                    fontWeight: FontWeight.bold,
                    color: Colors.tealAccent.shade100,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              QuickJumpButton(
                label: 'Manual',
                active: mode == 1,
                onTap: () => p.setShellegunMode(1),
              ),
              QuickJumpButton(
                label: 'Auto',
                active: mode == 2,
                onTap: () => p.setShellegunMode(2),
              ),
              QuickJumpButton(
                label: 'Beam',
                active: mode == 3,
                onTap: () => p.setShellegunMode(3),
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          GoopText(
            'Form $mode: ${modeNames[mode - 1]} — ${modeDps[mode - 1]} DPS',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: Insets.xs),
          GoopText(
            modeDescs[mode - 1],
            style: TextStyle(
              fontSize: FontSizes.labelMedium,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChamberGunInfo(BuildContext context, RunProvider p) {
    final floor = context.select<RunProvider, int>((p) => p.chamberGunFloor);
    const floorNames = [
      'Keep of the Lead Lord',
      'Oubliette',
      'Gungeon Proper',
      'Abbey of the True Gun',
      'Black Powder Mine',
      "Resourceful Rat's Lair",
      'The Hollow',
      'R&G Dept.',
      'The Forge',
      'Bullet Hell',
    ];
    const floorDps = [
      15.9,
      30.3,
      25.1,
      80.0,
      300.0,
      20.0,
      68.0,
      100.0,
      70.0,
      180.0,
    ];

    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.deepOrangeAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.layers,
                color: Colors.deepOrangeAccent.shade100,
                size: 20,
              ),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: GoopText(
                  'Chamber Gun — Active Floor',
                  style: TextStyle(
                    fontSize: FontSizes.bodyMedium,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrangeAccent.shade100,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(floorNames.length, (i) {
              return QuickJumpButton(
                label: floorNames[i].split(' ').first,
                active: floor == i,
                onTap: () => p.setChamberGunFloor(i),
              );
            }),
          ),
          const SizedBox(height: Insets.sm),
          GoopText(
            '${floorNames[floor]} — ${floorDps[floor]} DPS',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: Insets.xs),
          GoopText(
            'Chamber Gun transforms based on the current floor. Select your floor to see accurate DPS.',
            style: TextStyle(
              fontSize: FontSizes.labelMedium,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseyInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: Colors.lime.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.limeAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sports_baseball,
                color: Colors.limeAccent.shade100,
                size: 20,
              ),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: GoopText(
                  'Casey — Melee & Reflect',
                  style: TextStyle(
                    fontSize: FontSizes.bodyMedium,
                    fontWeight: FontWeight.bold,
                    color: Colors.limeAccent.shade100,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          GoopText(
            '100 base damage per swing. Reflects enemy bullets back at them for massive damage. DPS shown (50) reflects only melee — actual combat value is far higher with bullet reflection.',
            style: TextStyle(
              fontSize: FontSizes.labelMedium,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  /// DPS summary panel — large number, label, and icon. Visually balanced
  Widget _buildDpsPanel(String dpsValue) {
    final flair = AppTheme.flair;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: flair.scaffold.withValues(alpha: 0.6),
        borderRadius: BorderRadius.all(Radii.md),
        border: Border.all(
          color: flair.secondary.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flash_on, size: 14, color: flair.secondary),
              const SizedBox(width: Insets.xs),
              GoopText(
                'DPS',
                style: TextStyle(
                  fontSize: FontSizes.labelSmall,
                  fontWeight: FontWeight.w900,
                  color: flair.headlineStat,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          GoopText(
            dpsValue,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: flair.secondary,
              height: 1.0,
              shadows: [
                Shadow(
                  color: flair.secondary.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.xs),
          GoopText(
            'Damage / sec',
            style: TextStyle(
              fontSize: FontSizes.labelSmall,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
