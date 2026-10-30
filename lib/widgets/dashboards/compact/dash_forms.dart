part of '../compact_dashboards.dart';

class ShellegunDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const ShellegunDashboard({super.key, required this.slot});

  @override
  State<ShellegunDashboard> createState() => ShellegunDashboardState();
}

class ShellegunDashboardState extends State<ShellegunDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final mode = p.shellegunMode;

    const modes = ['Pistol (Manual)', 'Pistol (Auto)', 'Beam'];
    const descriptions = [
      'Semi-auto energy pistol. Moderate fire rate, high accuracy.',
      'Fully automatic. Increased fire rate, same damage per shot.',
      'Continuous energy beam. Highest DPS, consumes ammo rapidly.',
    ];
    const dpsValues = [18.0, 27.5, 42.0];

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.flair.card,
            borderRadius: BorderRadius.all(Radii.md),
            border: Border.all(
              color: Colors.cyan.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  setState(() => _collapsed = !_collapsed);
                  Haptics.selection();
                },
                borderRadius: BorderRadius.all(Radii.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Insets.md),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_moon_rounded,
                        color: Colors.cyanAccent,
                        size: 18,
                      ),
                      const SizedBox(width: Insets.sm),
                      const GoopText(
                        'SHELLEGUN',
                        style: TextStyle(
                          fontSize: FontSizes.labelMedium,
                          fontWeight: FontWeight.w900,
                          color: Colors.cyanAccent,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      GoopText(
                        'DPS: ${dpsValues[mode - 1].toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.cyanAccent,
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
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _modeBtn(
                                  'Manual',
                                  mode == 1,
                                  () => p.setShellegunMode(1),
                                ),
                                _modeBtn(
                                  'Auto',
                                  mode == 2,
                                  () => p.setShellegunMode(2),
                                ),
                                _modeBtn(
                                  'Beam',
                                  mode == 3,
                                  () => p.setShellegunMode(3),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            GoopText(
                              modes[mode - 1],
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: Insets.xs),
                            GoopText(
                              descriptions[mode - 1],
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.7),
                                height: 1.3,
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

  Widget _modeBtn(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Haptics.light();
        onTap();
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 6),
        decoration: BoxDecoration(
          color:
              active
                  ? Colors.cyan.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? Colors.cyanAccent : Colors.white12,
          ),
        ),
        child: GoopText(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? Colors.cyanAccent : Colors.white60,
          ),
        ),
      ),
    );
  }
}

class ChamberGunDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const ChamberGunDashboard({super.key, required this.slot});

  @override
  State<ChamberGunDashboard> createState() => ChamberGunDashboardState();
}

class ChamberGunDashboardState extends State<ChamberGunDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _collapsed = false;

  static const _floors = [
    'Keep of the Lead Lord',
    'Oubliette',
    'Gungeon Proper',
    'Abbey of the True Gun',
    'Black Powder Mine',
    "Rat's Lair",
    'The Hollow',
    'R&G Dept',
    'The Forge',
    'Bullet Hell',
  ];
  static const _dps = [
    15.0,
    18.5,
    22.0,
    26.0,
    30.0,
    34.0,
    38.5,
    43.0,
    48.0,
    55.0,
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final floor = p.chamberGunFloor;

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.flair.card,
            borderRadius: BorderRadius.all(Radii.md),
            border: Border.all(
              color: Colors.amber.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  setState(() => _collapsed = !_collapsed);
                  Haptics.selection();
                },
                borderRadius: BorderRadius.all(Radii.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Insets.md),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.apartment_rounded,
                        color: Colors.amberAccent,
                        size: 18,
                      ),
                      const SizedBox(width: Insets.sm),
                      const GoopText(
                        'CHAMBER GUN',
                        style: TextStyle(
                          fontSize: FontSizes.labelMedium,
                          fontWeight: FontWeight.w900,
                          color: Colors.amberAccent,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      GoopText(
                        'DPS: ${_dps[floor].toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.amberAccent,
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
                            const SizedBox(height: Insets.sm),
                            GoopText(
                              'FLOOR ${floor + 1}: ${_floors[floor]}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: Insets.sm),
                            // Floor selector — horizontal scrollable row
                            SizedBox(
                              height: Insets.xxl,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: 10,
                                separatorBuilder:
                                    (_, _) => const SizedBox(width: Insets.xs),
                                itemBuilder: (context, i) {
                                  final active = i == floor;
                                  return InkWell(
                                    onTap: () {
                                      Haptics.light();
                                      p.setChamberGunFloor(i);
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      width: 28,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color:
                                            active
                                                ? Colors.amber.withValues(
                                                  alpha: 0.15,
                                                )
                                                : Colors.white.withValues(
                                                  alpha: 0.03,
                                                ),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color:
                                              active
                                                  ? Colors.amberAccent
                                                  : Colors.white12,
                                        ),
                                      ),
                                      child: GoopText(
                                        '${i + 1}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight:
                                              active
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                          color:
                                              active
                                                  ? Colors.amberAccent
                                                  : Colors.white54,
                                        ),
                                      ),
                                    ),
                                  );
                                },
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

class PolarisDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const PolarisDashboard({super.key, required this.slot});

  @override
  State<PolarisDashboard> createState() => PolarisDashboardState();
}

class PolarisDashboardState extends State<PolarisDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final kills = p.polarisKills;
    final hits = p.polarisDamageHits;

    // Effective level: base from kills, minus damage hits
    final baseLevel =
        kills >= 31
            ? 3
            : kills >= 11
            ? 2
            : 1;
    final effectiveLevel = (baseLevel - hits).clamp(1, 3);

    final dmgPerShot =
        effectiveLevel == 3
            ? 25
            : effectiveLevel == 2
            ? '5x2'
            : 5;
    final dps =
        effectiveLevel == 3
            ? 89.6
            : effectiveLevel == 2
            ? 35.8
            : 17.9;
    final nextThreshold =
        effectiveLevel == 1
            ? 11
            : effectiveLevel == 2
            ? 31
            : null;
    final progressToNext =
        nextThreshold == null
            ? 1.0
            : (kills - (effectiveLevel == 2 ? 11 : 0)) /
                (nextThreshold - (effectiveLevel == 2 ? 11 : 0));

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.flair.card,
            borderRadius: BorderRadius.all(Radii.md),
            border: Border.all(
              color: Colors.amber.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  setState(() => _collapsed = !_collapsed);
                  Haptics.selection();
                },
                borderRadius: BorderRadius.all(Radii.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Insets.md),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: Colors.amberAccent,
                        size: 18,
                      ),
                      const SizedBox(width: Insets.sm),
                      const GoopText(
                        'POLARIS',
                        style: TextStyle(
                          fontSize: FontSizes.labelMedium,
                          fontWeight: FontWeight.w900,
                          color: Colors.amberAccent,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Insets.sm,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.4),
                          ),
                        ),
                        child: GoopText(
                          'LV $effectiveLevel',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.amberAccent,
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
                            const SizedBox(height: 10),
                            // Level progress bar
                            if (nextThreshold != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: progressToNext.clamp(0.0, 1.0),
                                  minHeight: 5,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.08,
                                  ),
                                  valueColor: const AlwaysStoppedAnimation(
                                    Colors.amberAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(height: Insets.xs),
                              GoopText(
                                '$kills / $nextThreshold kills to Lv ${effectiveLevel + 1}',
                                style: TextStyle(
                                  fontSize: FontSizes.labelSmall,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ] else
                              GoopText(
                                'MAX LEVEL',
                                style: TextStyle(
                                  fontSize: FontSizes.labelSmall,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amberAccent.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _statChip('DMG', '$dmgPerShot'),
                                _statChip('DPS', dps.toStringAsFixed(1)),
                                _statChip('Hits', '$hits'),
                              ],
                            ),
                            const SizedBox(height: 10),
                            GoopText(
                              effectiveLevel == 3
                                  ? 'L3: 25 damage per shot. Homing with Star Friends synergy.'
                                  : effectiveLevel == 2
                                  ? 'L2: Fires 2 bullets (5 dmg each). Double chance-based effect triggers.'
                                  : 'L1: 5 damage per shot. Kill enemies to level up.',
                              style: TextStyle(
                                fontSize: FontSizes.labelSmall,
                                color: Colors.white.withValues(alpha: 0.6),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed:
                                      kills > 0
                                          ? () {
                                            Haptics.light();
                                            p.setPolarisKills(kills - 1);
                                          }
                                          : null,
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.amberAccent,
                                    size: 24,
                                  ),
                                  tooltip: 'Decrease Polaris kills',
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                ),
                                GoopText(
                                  '$kills kills',
                                  style: const TextStyle(
                                    fontSize: FontSizes.bodyMedium,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Haptics.light();
                                    p.setPolarisKills(kills + 1);
                                  },
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.amberAccent,
                                    size: 24,
                                  ),
                                  tooltip: 'Increase Polaris kills',
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                ),
                                const SizedBox(width: Insets.md),
                                IconButton(
                                  onPressed:
                                      hits > 0
                                          ? () {
                                            Haptics.light();
                                            p.setPolarisDamageHits(hits - 1);
                                          }
                                          : null,
                                  icon: const Icon(
                                    Icons.remove,
                                    color: Colors.redAccent,
                                    size: 22,
                                  ),
                                  tooltip: 'Reduce damage hits',
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                ),
                                GoopText(
                                  '-$hits',
                                  style: TextStyle(
                                    fontSize: FontSizes.labelMedium,
                                    color: Colors.redAccent.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Haptics.light();
                                    p.setPolarisDamageHits(hits + 1);
                                  },
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.redAccent,
                                    size: 22,
                                  ),
                                  tooltip: 'Took damage (level drop)',
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
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
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Column(
      children: [
        GoopText(
          label,
          style: TextStyle(
            fontSize: FontSizes.labelSmall,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        GoopText(
          value,
          style: const TextStyle(
            fontSize: FontSizes.labelMedium,
            fontWeight: FontWeight.bold,
            color: Colors.amberAccent,
          ),
        ),
      ],
    );
  }
}

class GuntherDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const GuntherDashboard({super.key, required this.slot});

  @override
  State<GuntherDashboard> createState() => GuntherDashboardState();
}

class GuntherDashboardState extends State<GuntherDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final friendship = p.guntherFriendship;

    final stage =
        friendship >= 6
            ? 3
            : friendship >= 3
            ? 2
            : 1;
    final dmg =
        stage == 3
            ? 12
            : stage == 2
            ? 9
            : 6;
    final dps =
        stage == 3
            ? 69.2
            : stage == 2
            ? 51.9
            : 34.6;
    final trait =
        stage == 3
            ? 'Homing'
            : stage == 2
            ? 'Bounces 2x'
            : 'Piercing';
    final nextFriendship =
        stage == 1
            ? 3
            : stage == 2
            ? 6
            : null;

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.flair.card,
            borderRadius: BorderRadius.all(Radii.md),
            border: Border.all(
              color: Colors.purple.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  setState(() => _collapsed = !_collapsed);
                  Haptics.selection();
                },
                borderRadius: BorderRadius.all(Radii.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Insets.md),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble,
                        color: Colors.purpleAccent,
                        size: 18,
                      ),
                      const SizedBox(width: Insets.sm),
                      const GoopText(
                        'GUNTHER',
                        style: TextStyle(
                          fontSize: FontSizes.labelMedium,
                          fontWeight: FontWeight.w900,
                          color: Colors.purpleAccent,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Insets.sm,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.purple.withValues(alpha: 0.4),
                          ),
                        ),
                        child: GoopText(
                          'STAGE $stage',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.purpleAccent,
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
                            const SizedBox(height: 10),
                            // Friendship progress
                            if (nextFriendship != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: (friendship / nextFriendship).clamp(
                                    0.0,
                                    1.0,
                                  ),
                                  minHeight: 5,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.08,
                                  ),
                                  valueColor: const AlwaysStoppedAnimation(
                                    Colors.purpleAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(height: Insets.xs),
                              GoopText(
                                '$friendship / $nextFriendship friendship to Stage ${stage + 1}',
                                style: TextStyle(
                                  fontSize: FontSizes.labelSmall,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ] else
                              GoopText(
                                'MAX STAGE: Sentient & Homing',
                                style: TextStyle(
                                  fontSize: FontSizes.labelSmall,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purpleAccent.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _statChip('DMG', '$dmg'),
                                _statChip('DPS', dps.toStringAsFixed(1)),
                                _statChip('Trait', trait),
                              ],
                            ),
                            const SizedBox(height: 10),
                            GoopText(
                              stage == 3
                                  ? 'L3: 12 dmg, homing bullets. Fully sentient — talks frequently.'
                                  : stage == 2
                                  ? 'L2: 9 dmg, bullets bounce twice. Growing personality.'
                                  : 'L1: 6 dmg, piercing bullets. Clear rooms to gain friendship.',
                              style: TextStyle(
                                fontSize: FontSizes.labelSmall,
                                color: Colors.white.withValues(alpha: 0.6),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed:
                                      friendship > 0
                                          ? () {
                                            Haptics.light();
                                            p.setGuntherFriendship(
                                              friendship - 1,
                                            );
                                          }
                                          : null,
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.purpleAccent,
                                    size: 24,
                                  ),
                                  tooltip: 'Decrease Gunther friendship',
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                ),
                                Text(
                                  '$friendship',
                                  style: const TextStyle(
                                    fontSize: FontSizes.titleSmall,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Haptics.light();
                                    p.setGuntherFriendship(friendship + 1);
                                  },
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.purpleAccent,
                                    size: 24,
                                  ),
                                  tooltip: 'Increase Gunther friendship',
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
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
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Column(
      children: [
        GoopText(
          label,
          style: TextStyle(
            fontSize: FontSizes.labelSmall,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        GoopText(
          value,
          style: const TextStyle(
            fontSize: FontSizes.labelMedium,
            fontWeight: FontWeight.bold,
            color: Colors.purpleAccent,
          ),
        ),
      ],
    );
  }
}
