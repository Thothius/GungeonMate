part of '../compact_dashboards.dart';

class PlatinumBulletsDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const PlatinumBulletsDashboard({super.key, required this.slot});

  @override
  State<PlatinumBulletsDashboard> createState() =>
      PlatinumBulletsDashboardState();
}

class PlatinumBulletsDashboardState extends State<PlatinumBulletsDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final seconds = p.platinumBulletsSeconds;

    // Wiki: Fire rate doubles every 250s, maxes at 3x after 375s.
    // Damage doubles every 500s, maxes at 3x after 750s.
    final fireRateMult = seconds >= 375 ? 3.0 : 1.0 + (seconds / 375.0) * 2.0;
    final dmgMult = seconds >= 750 ? 3.0 : 1.0 + (seconds / 750.0) * 2.0;
    String tierLabel(double mult) {
      if (mult >= 3.0) return 'MAX';
      if (mult >= 2.0) return 'T2';
      if (mult > 1.0) return 'T1';
      return 'BASE';
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.flair.card,
            borderRadius: BorderRadius.all(Radii.md),
            border: Border.all(
              color: Colors.purpleAccent.withValues(alpha: 0.35),
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
                        Icons.military_tech_rounded,
                        color: Colors.purpleAccent,
                        size: 18,
                      ),
                      const SizedBox(width: Insets.sm),
                      const GoopText(
                        'PLATINUM BULLETS',
                        style: TextStyle(
                          fontSize: FontSizes.labelMedium,
                          fontWeight: FontWeight.w900,
                          color: Colors.purpleAccent,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      GoopText(
                        '${seconds}s fired',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.purpleAccent,
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
                            // Damage multiplier row
                            _buildMultRow(
                              'DMG',
                              dmgMult,
                              seconds,
                              750,
                              Colors.redAccent,
                              tierLabel(dmgMult),
                            ),
                            const SizedBox(height: Insets.sm),
                            // Fire rate multiplier row
                            _buildMultRow(
                              'RATE',
                              fireRateMult,
                              seconds,
                              375,
                              Colors.orangeAccent,
                              tierLabel(fireRateMult),
                            ),
                            const SizedBox(height: 10),
                            GoopText(
                              'Damage & fire rate scale with firing time. Max 3x each. Tap +30s after each fight.',
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
                                      seconds > 0
                                          ? () {
                                            Haptics.light();
                                            p.setPlatinumBulletsSeconds(
                                              (seconds - 30).clamp(0, 999),
                                            );
                                          }
                                          : null,
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.purpleAccent,
                                    size: 30,
                                  ),
                                  tooltip: 'Decrease platinum bullets',
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                ),
                                GoopText(
                                  '${seconds}s',
                                  style: const TextStyle(
                                    fontSize: FontSizes.titleSmall,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Haptics.light();
                                    p.setPlatinumBulletsSeconds(
                                      (seconds + 30).clamp(0, 999),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.purpleAccent,
                                    size: 30,
                                  ),
                                  tooltip: 'Increase platinum bullets',
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                ),
                                const SizedBox(width: Insets.sm),
                                TextButton(
                                  onPressed: () {
                                    Haptics.selection();
                                    p.setPlatinumBulletsSeconds(0);
                                  },
                                  child: const GoopText(
                                    'Reset',
                                    style: TextStyle(
                                      fontSize: FontSizes.labelSmall,
                                      color: Colors.redAccent,
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

  Widget _buildMultRow(
    String label,
    double mult,
    int seconds,
    int maxSeconds,
    Color color,
    String tier,
  ) {
    final progress = (seconds / maxSeconds).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: GoopText(
            label,
            style: TextStyle(
              fontSize: FontSizes.labelSmall,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.8)),
            ),
          ),
        ),
        const SizedBox(width: Insets.sm),
        SizedBox(
          width: 56,
          child: GoopText(
            '${mult.toStringAsFixed(1)}x',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: Insets.xs),
        SizedBox(
          width: 32,
          child: GoopText(
            tier,
            style: TextStyle(
              fontSize: FontSizes.labelSmall,
              fontWeight: FontWeight.w900,
              color: color.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class IronCoinDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const IronCoinDashboard({super.key, required this.slot});

  @override
  State<IronCoinDashboard> createState() => IronCoinDashboardState();
}

class IronCoinDashboardState extends State<IronCoinDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final uses = p.ironCoinUses;

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.flair.card,
            borderRadius: BorderRadius.all(Radii.md),
            border: Border.all(
              color: Colors.brown.withValues(alpha: 0.4),
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
                        Icons.paid_rounded,
                        color: Colors.amber,
                        size: 18,
                      ),
                      const SizedBox(width: Insets.sm),
                      const GoopText(
                        'IRON COIN',
                        style: TextStyle(
                          fontSize: FontSizes.labelMedium,
                          fontWeight: FontWeight.w900,
                          color: Colors.amber,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      GoopText(
                        '$uses/3 uses',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: uses > 0 ? Colors.amber : Colors.white30,
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
                            // Coin icons row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                for (int i = 0; i < 3; i++)
                                  Icon(
                                    Icons.paid_rounded,
                                    size: 32,
                                    color:
                                        i < uses
                                            ? Colors.amber
                                            : Colors.white.withValues(
                                              alpha: 0.1,
                                            ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            GoopText(
                              "Flip to reveal/destroy a chest's contents. 3 uses per run. Use wisely on high-tier chests.",
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
                                      uses < 3
                                          ? () {
                                            Haptics.light();
                                            p.setIronCoinUses(uses + 1);
                                          }
                                          : null,
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.amber,
                                    size: 30,
                                  ),
                                  tooltip: 'Increase iron coin uses',
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                ),
                                IconButton(
                                  onPressed:
                                      uses > 0
                                          ? () {
                                            Haptics.light();
                                            p.setIronCoinUses(uses - 1);
                                          }
                                          : null,
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.amber,
                                    size: 30,
                                  ),
                                  tooltip: 'Decrease iron coin uses',
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

class SpiceDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const SpiceDashboard({super.key, required this.slot});

  @override
  State<SpiceDashboard> createState() => SpiceDashboardState();
}

class SpiceDashboardState extends State<SpiceDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final count = p.spiceUsageCount;

    final damageBonus =
        count <= 2
            ? 0
            : count == 3
            ? 20
            : 20 + (count - 3) * 15;
    final curseTotal =
        count == 0
            ? 0.0
            : count == 1
            ? 0.5
            : 0.5 + (count - 1);
    final heartChange = count <= 2 ? count : 4 - count;

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.flair.card,
            borderRadius: BorderRadius.all(Radii.md),
            border: Border.all(
              color: Colors.redAccent.withValues(alpha: 0.35),
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
                      const Icon(Icons.spa, color: Colors.redAccent, size: 18),
                      const SizedBox(width: Insets.sm),
                      const GoopText(
                        'SPICE',
                        style: TextStyle(
                          fontSize: FontSizes.labelMedium,
                          fontWeight: FontWeight.w900,
                          color: Colors.redAccent,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      GoopText(
                        '+$damageBonus% DMG',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.redAccent,
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
                                _statChip('Uses', '$count'),
                                _statChip(
                                  'Curse',
                                  '+${curseTotal.toStringAsFixed(1)}',
                                ),
                                _statChip(
                                  'Hearts',
                                  heartChange == 0
                                      ? '0'
                                      : heartChange > 0
                                      ? '+$heartChange'
                                      : '$heartChange',
                                ),
                                _statChip('Dmg', '+$damageBonus%'),
                              ],
                            ),
                            const SizedBox(height: 10),
                            GoopText(
                              count == 0
                                  ? 'No Spice used. 1st use: +1 Heart, +20% Speed, -25% Spread, +0.5 Curse.'
                                  : count == 1
                                  ? '1 use done. 2nd use: +1 Heart, -10% Enemy Bullet Speed, +20% Fire Rate, +1 Curse.'
                                  : count == 2
                                  ? '2 uses done. 3rd use: -1 Heart, +20% Damage, -5% Enemy Bullet Speed, +1 Curse.'
                                  : count < 5
                                  ? 'Escalating bonuses. Each use: -1 Heart, +15% Damage, +10% Spread, +1 Curse.'
                                  : 'Diminishing returns: +15% Dmg, +1.0 Curse per additional use.',
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
                                      count > 0
                                          ? () {
                                            Haptics.light();
                                            p.setSpiceUsageCount(count - 1);
                                          }
                                          : null,
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.redAccent,
                                    size: 30,
                                  ),
                                  tooltip: 'Decrease spice uses',
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                ),
                                Text(
                                  '$count',
                                  style: const TextStyle(
                                    fontSize: FontSizes.titleSmall,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Haptics.light();
                                    p.setSpiceUsageCount(count + 1);
                                  },
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.redAccent,
                                    size: 30,
                                  ),
                                  tooltip: 'Increase spice uses',
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
            color: Colors.redAccent,
          ),
        ),
      ],
    );
  }
}

class MetronomeDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const MetronomeDashboard({super.key, required this.slot});

  @override
  State<MetronomeDashboard> createState() => MetronomeDashboardState();
}

class MetronomeDashboardState extends State<MetronomeDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final kills = p.metronomeKills;
    final damageBonus = (kills * 2).clamp(0, 150);
    final progress = kills / 75.0;

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.flair.card,
            borderRadius: BorderRadius.all(Radii.md),
            border: Border.all(
              color: Colors.tealAccent.withValues(alpha: 0.35),
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
                        Icons.speed,
                        color: Colors.tealAccent,
                        size: 18,
                      ),
                      const SizedBox(width: Insets.sm),
                      const GoopText(
                        'METRONOME',
                        style: TextStyle(
                          fontSize: FontSizes.labelMedium,
                          fontWeight: FontWeight.w900,
                          color: Colors.tealAccent,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      GoopText(
                        '+$damageBonus% DMG',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.tealAccent,
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
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.08,
                                ),
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.tealAccent.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GoopText(
                                  '$kills / 75 kills',
                                  style: TextStyle(
                                    fontSize: FontSizes.labelSmall,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                                GoopText(
                                  kills >= 75
                                      ? 'MAX STACK'
                                      : '${75 - kills} to max',
                                  style: TextStyle(
                                    fontSize: FontSizes.labelSmall,
                                    color: Colors.tealAccent.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: Insets.sm),
                            GoopText(
                              '+2% damage per kill. Resets if you take damage or swap guns. Max +150% at 75 kills.',
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
                                IconButton(
                                  onPressed:
                                      kills > 0
                                          ? () {
                                            Haptics.light();
                                            p.setMetronomeKills(kills - 1);
                                          }
                                          : null,
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.tealAccent,
                                    size: 30,
                                  ),
                                  tooltip: 'Decrease metronome kills',
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                ),
                                Text(
                                  '$kills',
                                  style: const TextStyle(
                                    fontSize: FontSizes.titleSmall,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.tealAccent,
                                  ),
                                ),
                                IconButton(
                                  onPressed:
                                      kills < 75
                                          ? () {
                                            Haptics.light();
                                            p.setMetronomeKills(kills + 1);
                                          }
                                          : null,
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.tealAccent,
                                    size: 30,
                                  ),
                                  tooltip: 'Increase metronome kills',
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                ),
                                const SizedBox(width: Insets.sm),
                                TextButton(
                                  onPressed: () {
                                    Haptics.selection();
                                    p.setMetronomeKills(0);
                                  },
                                  child: const GoopText(
                                    'Reset',
                                    style: TextStyle(
                                      fontSize: FontSizes.labelSmall,
                                      color: Colors.redAccent,
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
