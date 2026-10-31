part of '../compact_dashboards.dart';

class SprunDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const SprunDashboard({super.key, required this.slot});

  @override
  State<SprunDashboard> createState() => SprunDashboardState();
}

class SprunDashboardState extends State<SprunDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _collapsed = false;

  static const _triggers = [
    'Activating a Map Blank',
    'Taking damage to Armor / Losing a half-heart',
    'Throwing an empty weapon at a wall',
    'Falling down an elevator shaft or trap pit',
    'Lighting yourself on fire or stepping into a poison pool',
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final idx = p.sprunTriggerIndex;
    final isWindgunnerActive = p.windgunnerCountdown > 0;

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.flair.card,
            borderRadius: BorderRadius.all(Radii.md),
            border: Border.all(
              color: Skeuo.inkIf(Colors.cyanAccent).withValues(alpha: 0.35),
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
                      Icon(
                        Icons.radar,
                        color: Skeuo.inkIf(Colors.cyanAccent.shade200),
                        size: 18,
                      ),
                      const SizedBox(width: Insets.sm),
                      GoopText(
                        'SPRUN',
                        style: TextStyle(
                          fontSize: FontSizes.labelMedium,
                          fontWeight: FontWeight.w900,
                          color: Skeuo.inkIf(Colors.cyanAccent),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      if (isWindgunnerActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Insets.sm,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Skeuo.inkIf(
                              Colors.cyan,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Skeuo.inkIf(
                                Colors.cyanAccent,
                              ).withValues(alpha: 0.5),
                            ),
                          ),
                          child: GoopText(
                            'WINDGUNNER ${p.windgunnerCountdown}s',
                            style: TextStyle(
                              fontSize: FontSizes.labelSmall,
                              fontWeight: FontWeight.bold,
                              color: Skeuo.inkIf(Colors.cyanAccent),
                            ),
                          ),
                        )
                      else
                        GoopText(
                          idx >= 0 ? 'REVEALED' : 'UNKNOWN',
                          style: TextStyle(
                            fontSize: FontSizes.labelSmall,
                            fontWeight: FontWeight.w900,
                            color: Skeuo.inkIf(
                              Colors.cyanAccent,
                            ).withValues(alpha: 0.6),
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
                            if (idx >= 0)
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Skeuo.inkIf(
                                    Colors.cyan,
                                  ).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.all(Radii.sm),
                                  border: Border.all(
                                    color: Skeuo.inkIf(
                                      Colors.cyan,
                                    ).withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.flash_on,
                                      color: Skeuo.inkIf(Colors.cyanAccent),
                                      size: 16,
                                    ),
                                    const SizedBox(width: Insets.sm),
                                    Expanded(
                                      child: GoopText(
                                        _triggers[idx],
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Skeuo.inkIf(Colors.cyanAccent),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              GoopText(
                                'Trigger unknown. Tap "Reveal" to discover this run\'s Windgunner activation condition.',
                                style: TextStyle(
                                  fontSize: FontSizes.labelSmall,
                                  color: Colors.white.withValues(alpha: 0.5),
                                  height: 1.3,
                                ),
                              ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Haptics.selection();
                                    final randomIdx =
                                        DateTime.now().millisecondsSinceEpoch %
                                        _triggers.length;
                                    p.setSprunTriggerIndex(randomIdx);
                                  },
                                  child: GoopText(
                                    'Reveal Trigger',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Skeuo.inkIf(Colors.cyanAccent),
                                    ),
                                  ),
                                ),
                                if (idx >= 0) ...[
                                  const SizedBox(width: Insets.sm),
                                  TextButton(
                                    onPressed: () {
                                      Haptics.light();
                                      p.setSprunTriggerIndex(-1);
                                    },
                                    child: const GoopText(
                                      'Hide',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white38,
                                      ),
                                    ),
                                  ),
                                ],
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
}

class BoxingGloveDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const BoxingGloveDashboard({super.key, required this.slot});

  @override
  State<BoxingGloveDashboard> createState() => BoxingGloveDashboardState();
}

class BoxingGloveDashboardState extends State<BoxingGloveDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final stars = p.boxingGloveStars;

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.flair.card,
            borderRadius: BorderRadius.all(Radii.md),
            border: Border.all(
              color: Skeuo.inkIf(Colors.orangeAccent).withValues(alpha: 0.35),
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
                      Icon(
                        Icons.sports_mma_rounded,
                        color: Skeuo.inkIf(Colors.orangeAccent),
                        size: 18,
                      ),
                      const SizedBox(width: Insets.sm),
                      GoopText(
                        'BOXING GLOVE',
                        style: TextStyle(
                          fontSize: FontSizes.labelMedium,
                          fontWeight: FontWeight.w900,
                          color: Skeuo.inkIf(Colors.orangeAccent),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      GoopText(
                        stars == 3 ? 'SUPER PUNCH READY' : '$stars/3 stars',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color:
                              stars == 3
                                  ? Skeuo.inkIf(Colors.orangeAccent)
                                  : Colors.white.withValues(alpha: 0.5),
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
                            // Star icons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                for (int i = 0; i < 3; i++)
                                  Icon(
                                    Icons.star_rounded,
                                    size: 36,
                                    color:
                                        i < stars
                                            ? Skeuo.inkIf(Colors.orangeAccent)
                                            : Colors.white.withValues(
                                              alpha: 0.1,
                                            ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            GoopText(
                              stars == 3
                                  ? '3 stars! Charge the gun to consume stars and fire a high-damage super punch.'
                                  : 'Gains a star per kill (up to 3). Chance to stun on hit. Increases curse by 1.',
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
                                      stars > 0
                                          ? () {
                                            Haptics.light();
                                            p.setBoxingGloveStars(stars - 1);
                                          }
                                          : null,
                                  icon: Icon(
                                    Icons.remove_circle_outline,
                                    color: Skeuo.inkIf(Colors.orangeAccent),
                                    size: 30,
                                  ),
                                  tooltip: 'Decrease boxing glove stars',
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                ),
                                Text(
                                  '$stars',
                                  style: TextStyle(
                                    fontSize: FontSizes.titleSmall,
                                    fontWeight: FontWeight.bold,
                                    color: Skeuo.inkIf(Colors.orangeAccent),
                                  ),
                                ),
                                IconButton(
                                  onPressed:
                                      stars < 3
                                          ? () {
                                            Haptics.light();
                                            p.setBoxingGloveStars(stars + 1);
                                          }
                                          : null,
                                  icon: Icon(
                                    Icons.add_circle_outline,
                                    color: Skeuo.inkIf(Colors.orangeAccent),
                                    size: 30,
                                  ),
                                  tooltip: 'Increase boxing glove stars',
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
}

class CigarettesDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const CigarettesDashboard({super.key, required this.slot});

  @override
  State<CigarettesDashboard> createState() => CigarettesDashboardState();
}

class CigarettesDashboardState extends State<CigarettesDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final uses = p.cigarettesUses;

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.flair.card,
            borderRadius: BorderRadius.all(Radii.md),
            border: Border.all(
              color: Skeuo.inkIf(Colors.blueGrey).withValues(alpha: 0.4),
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
                      Icon(
                        Icons.smoking_rooms,
                        color: Skeuo.inkIf(Colors.blueGrey),
                        size: 18,
                      ),
                      const SizedBox(width: Insets.sm),
                      GoopText(
                        'CIGARETTES',
                        style: TextStyle(
                          fontSize: FontSizes.labelMedium,
                          fontWeight: FontWeight.w900,
                          color: Skeuo.inkIf(Colors.blueGrey),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      GoopText(
                        '+$uses Cool',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Skeuo.inkIf(Colors.blueGrey),
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
                                _statChip('Uses', '$uses'),
                                _statChip('Coolness', '+$uses'),
                                _statChip('Cost', '-$uses half-hearts'),
                              ],
                            ),
                            const SizedBox(height: 10),
                            GoopText(
                              'Each use: -half a heart, +1 Coolness. Coolness decreases active item cooldowns and increases luck.',
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
                                      uses > 0
                                          ? () {
                                            Haptics.light();
                                            p.setCigarettesUses(uses - 1);
                                          }
                                          : null,
                                  icon: Icon(
                                    Icons.remove_circle_outline,
                                    color: Skeuo.inkIf(Colors.blueGrey),
                                    size: 30,
                                  ),
                                  tooltip: 'Decrease cigarette uses',
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                ),
                                Text(
                                  '$uses',
                                  style: TextStyle(
                                    fontSize: FontSizes.titleSmall,
                                    fontWeight: FontWeight.bold,
                                    color: Skeuo.inkIf(Colors.blueGrey),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Haptics.light();
                                    p.setCigarettesUses(uses + 1);
                                  },
                                  icon: Icon(
                                    Icons.add_circle_outline,
                                    color: Skeuo.inkIf(Colors.blueGrey),
                                    size: 30,
                                  ),
                                  tooltip: 'Increase cigarette uses',
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
          style: TextStyle(
            fontSize: FontSizes.labelMedium,
            fontWeight: FontWeight.bold,
            color: Skeuo.inkIf(Colors.blueGrey),
          ),
        ),
      ],
    );
  }
}

class GunSoulDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const GunSoulDashboard({super.key, required this.slot});

  @override
  State<GunSoulDashboard> createState() => GunSoulDashboardState();
}

class GunSoulDashboardState extends State<GunSoulDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final activated = p.gunSoulActivated;

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.flair.card,
            borderRadius: BorderRadius.all(Radii.md),
            border: Border.all(
              color:
                  activated
                      ? Skeuo.inkIf(Colors.orange).withValues(alpha: 0.5)
                      : Skeuo.inkIf(Colors.deepOrange).withValues(alpha: 0.3),
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
                      Icon(
                        activated ? Icons.local_fire_department : Icons.shield,
                        color:
                            activated
                                ? Skeuo.inkIf(Colors.orangeAccent)
                                : Skeuo.inkIf(Colors.deepOrangeAccent),
                        size: 18,
                      ),
                      const SizedBox(width: Insets.sm),
                      GoopText(
                        'GUN SOUL',
                        style: TextStyle(
                          fontSize: FontSizes.labelMedium,
                          fontWeight: FontWeight.w900,
                          color: Skeuo.inkIf(Colors.deepOrangeAccent),
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
                          color:
                              activated
                                  ? Skeuo.inkIf(
                                    Colors.orange,
                                  ).withValues(alpha: 0.2)
                                  : Skeuo.inkIf(
                                    Colors.green,
                                  ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color:
                                activated
                                    ? Skeuo.inkIf(
                                      Colors.orange,
                                    ).withValues(alpha: 0.5)
                                    : Skeuo.inkIf(
                                      Colors.green,
                                    ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: GoopText(
                          activated ? 'SOUL LOST' : 'ACTIVE',
                          style: TextStyle(
                            fontSize: FontSizes.labelSmall,
                            fontWeight: FontWeight.w900,
                            color:
                                activated
                                    ? Skeuo.inkIf(Colors.orangeAccent)
                                    : Skeuo.inkIf(Colors.greenAccent),
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
                            GoopText(
                              activated
                                  ? 'You died and respawned at floor start. Gun Soul is removed from your inventory. Reach the location of your death and interact with your soul to reclaim it — dying now will end the run.'
                                  : 'Grants +1 heart container. Upon death, respawns you at the start of the current floor with all items and guns retained. Enemies respawn.',
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
                                TextButton.icon(
                                  onPressed: () {
                                    Haptics.selection();
                                    p.setGunSoulActivated(!activated);
                                  },
                                  icon: Icon(
                                    activated
                                        ? Icons.refresh
                                        : Icons.warning_amber,
                                    size: 16,
                                    color:
                                        activated
                                            ? Skeuo.inkIf(Colors.greenAccent)
                                            : Skeuo.inkIf(Colors.orangeAccent),
                                  ),
                                  label: GoopText(
                                    activated
                                        ? 'Soul Reclaimed'
                                        : 'Died — Respawned',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          activated
                                              ? Skeuo.inkIf(Colors.greenAccent)
                                              : Skeuo.inkIf(
                                                Colors.orangeAccent,
                                              ),
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
      ),
    );
  }
}
