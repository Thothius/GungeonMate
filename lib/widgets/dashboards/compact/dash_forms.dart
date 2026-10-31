part of '../compact_dashboards.dart';

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
              color: Skeuo.inkIf(Colors.purple).withValues(alpha: 0.35),
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
                        Icons.chat_bubble,
                        color: Skeuo.inkIf(Colors.purpleAccent),
                        size: 18,
                      ),
                      SizedBox(width: Insets.sm),
                      GoopText(
                        'GUNTHER',
                        style: TextStyle(
                          fontSize: FontSizes.labelMedium,
                          fontWeight: FontWeight.w900,
                          color: Skeuo.inkIf(Colors.purpleAccent),
                          letterSpacing: 0.8,
                        ),
                      ),
                      Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Insets.sm,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Skeuo.inkIf(
                            Colors.purple,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Skeuo.inkIf(
                              Colors.purple,
                            ).withValues(alpha: 0.4),
                          ),
                        ),
                        child: GoopText(
                          'STAGE $stage',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Skeuo.inkIf(Colors.purpleAccent),
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        _collapsed ? Icons.expand_more : Icons.expand_less,
                        size: 16,
                        color: Skeuo.collapse(Colors.white54),
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
                            SizedBox(height: 10),
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
                                  backgroundColor: Skeuo.collapse(
                                    Colors.white,
                                  ).withValues(alpha: 0.08),
                                  valueColor: AlwaysStoppedAnimation(
                                    Skeuo.inkIf(Colors.purpleAccent),
                                  ),
                                ),
                              ),
                              SizedBox(height: Insets.xs),
                              GoopText(
                                '$friendship / $nextFriendship friendship to Stage ${stage + 1}',
                                style: TextStyle(
                                  fontSize: FontSizes.labelSmall,
                                  color: Skeuo.collapse(
                                    Colors.white,
                                  ).withValues(alpha: 0.5),
                                ),
                              ),
                            ] else
                              GoopText(
                                'MAX STAGE: Sentient & Homing',
                                style: TextStyle(
                                  fontSize: FontSizes.labelSmall,
                                  fontWeight: FontWeight.bold,
                                  color: Skeuo.inkIf(
                                    Colors.purpleAccent,
                                  ).withValues(alpha: 0.8),
                                ),
                              ),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _statChip('DMG', '$dmg'),
                                _statChip('DPS', dps.toStringAsFixed(1)),
                                _statChip('Trait', trait),
                              ],
                            ),
                            SizedBox(height: 10),
                            GoopText(
                              stage == 3
                                  ? 'L3: 12 dmg, homing bullets. Fully sentient — talks frequently.'
                                  : stage == 2
                                  ? 'L2: 9 dmg, bullets bounce twice. Growing personality.'
                                  : 'L1: 6 dmg, piercing bullets. Clear rooms to gain friendship.',
                              style: TextStyle(
                                fontSize: FontSizes.labelSmall,
                                color: Skeuo.collapse(
                                  Colors.white,
                                ).withValues(alpha: 0.6),
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
                                  icon: Icon(
                                    Icons.remove_circle_outline,
                                    color: Skeuo.inkIf(Colors.purpleAccent),
                                    size: 30,
                                  ),
                                  tooltip: 'Decrease Gunther friendship',
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                ),
                                Text(
                                  '$friendship',
                                  style: TextStyle(
                                    fontSize: FontSizes.titleSmall,
                                    fontWeight: FontWeight.bold,
                                    color: Skeuo.collapse(Colors.white),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Haptics.light();
                                    p.setGuntherFriendship(friendship + 1);
                                  },
                                  icon: Icon(
                                    Icons.add_circle_outline,
                                    color: Skeuo.inkIf(Colors.purpleAccent),
                                    size: 30,
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
            color: Skeuo.collapse(Colors.white).withValues(alpha: 0.4),
          ),
        ),
        GoopText(
          value,
          style: TextStyle(
            fontSize: FontSizes.labelMedium,
            fontWeight: FontWeight.bold,
            color: Skeuo.inkIf(Colors.purpleAccent),
          ),
        ),
      ],
    );
  }
}
