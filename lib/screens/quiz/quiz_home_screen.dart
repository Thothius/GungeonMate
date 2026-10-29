import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../providers/run_provider.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/haptics.dart';
import '../../services/quiz_engine.dart';
import '../../services/quiz_progress.dart';
import '../../theme/tokens.dart';
import '../../widgets/active_run/bottom_back_bar.dart';
import '../../utils/fast_route.dart';
import '../../utils/reduce_motion.dart';
import '../../widgets/quality_badge.dart';
import '../../widgets/scale_button.dart';
import 'quiz_session_screen.dart';

/// Gungeonmaster Quiz — chest select.
///
/// All five chest tiers are shown with their real sprites; stats above
/// each chest list the tier letter, the loot pool size, and the player's
/// best streak (X/N). A flawless run replaces the stats with a floating
/// COMPLETED! label.
class QuizHomeScreen extends StatefulWidget {
  const QuizHomeScreen({super.key, this.showBackButton = false});

  /// True when pushed from the main menu (needs a back affordance);
  /// false when hosted as a bottom-nav tab.
  final bool showBackButton;

  @override
  State<QuizHomeScreen> createState() => _QuizHomeScreenState();
}

class _QuizHomeScreenState extends State<QuizHomeScreen> {
  bool _loaded = false;
  QuizEngine? _engine;

  @override
  void initState() {
    super.initState();
    QuizProgress.instance.ensureLoaded().then((_) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  Future<void> _openTier(QuizChestTier tier) async {
    Haptics.selection();
    await Navigator.push(
      context,
      fastRoute(QuizSessionScreen(tier: tier)),
    );
    // Refresh best-streak labels after a run.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.read<RunProvider>();
    final engine = _engine ??=
        QuizEngine(guns: rp.allGuns, items: rp.allItems);
    final progress = QuizProgress.instance;
    // Only standard chests count toward bonus-chest unlocks — the
    // Rainbow chest can't cheese the Rat chest open.
    final completedCount = kQuizChestTiers
        .where((t) => progress.isCompleted(t.id))
        .length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar:
          widget.showBackButton ? const BottomBackBar() : null,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Insets.sm, Insets.sm, Insets.lg, 0),
              child: Row(
                children: [
                  if (!widget.showBackButton) const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GoopText(
                          'GUNGEONMASTER QUIZ',
                          style: TextStyle(
                            fontSize: FontSizes.titleLarge,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.6,
                            color: const Color(0xFFFFD54F),
                            shadows: const [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 6,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        GoopText(
                          'Name the loot. Beat the chest.',
                          style: TextStyle(
                            fontSize: FontSizes.labelMedium,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Keep the header optically centered when no back
                  // button is shown — same 48px slot on both sides.
                  SizedBox(width: widget.showBackButton ? 8 : 48),
                ],
              ),
            ),
            const SizedBox(height: Insets.sm),

            // ── Chest list ──
            Expanded(
              child: _loaded
                  ? ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Insets.lg,
                        vertical: Insets.sm,
                      ),
                      itemCount: kQuizAllTiers.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: Insets.md),
                      itemBuilder: (context, i) {
                        final tier = kQuizAllTiers[i];
                        final pool = engine.poolSizeForTier(tier);
                        final guns = engine.gunsForTier(tier);
                        final items = engine.itemsForTier(tier);
                        final locked =
                            tier.unlocksAfter > completedCount;
                        return _ChestCard(
                          tier: tier,
                          guns: guns,
                          items: items,
                          poolSize: pool,
                          best: progress.bestStreak(tier.id),
                          completed: progress.isCompleted(tier.id),
                          locked: locked,
                          unlockHint:
                              'CLEAR ${tier.unlocksAfter - completedCount} MORE '
                              'CHEST${tier.unlocksAfter - completedCount == 1 ? '' : 'S'} TO UNLOCK',
                          onTap: locked ? () {} : () => _openTier(tier),
                        )
                            .animate(
                                delay: Duration(milliseconds: 70 * i))
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.15, end: 0);
                      },
                    )
                  : const SizedBox.shrink(),
            ),

            // ── Overall progress footer ──
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.lg),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: Insets.lg, vertical: Insets.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.10),
                  borderRadius: Radii.pill,
                  border: Border.all(
                    color:
                        const Color(0xFFFFD54F).withValues(alpha: 0.35),
                  ),
                ),
                child: GoopText(
                  '$completedCount/${kQuizChestTiers.length} CHESTS CLEARED',
                  style: const TextStyle(
                    fontSize: FontSizes.labelMedium,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    color: Color(0xFFFFD54F),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One chest card — stats row on top (tier badge, pool size, best
/// streak), the real chest sprite below, all tappable.
class _ChestCard extends StatelessWidget {
  const _ChestCard({
    required this.tier,
    required this.guns,
    required this.items,
    required this.poolSize,
    required this.best,
    required this.completed,
    required this.locked,
    required this.unlockHint,
    required this.onTap,
  });

  final QuizChestTier tier;
  final int guns;
  final int items;
  final int poolSize;
  final int best;
  final bool completed;
  final bool locked;
  final String unlockHint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Locked cards read as silhouettes — desaturated + dimmed so the
    // chest shape shows but the loot stays mysterious.
    final card = locked
        ? ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0.2126, 0.7152, 0.0722, 0, 0, // greyscale
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0, 0, 0, 0.55, 0, // dimmed alpha
            ]),
            child: _cardContent(),
          )
        : _cardContent();
    return IgnorePointer(ignoring: locked, child: card);
  }

  Widget _cardContent() {
    return ScaleButton(
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Insets.lg, vertical: Insets.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              tier.accent.withValues(alpha: 0.14),
              tier.accent.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: Radii.card,
          border: Border.all(
            color: tier.accent.withValues(alpha: completed ? 0.8 : 0.45),
            width: completed ? 1.8 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: tier.accent.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
          child: Column(
          children: [
            // Stats row above the chest.
            Row(
              children: [
                _TierBadge(tier: tier),
                const SizedBox(width: Insets.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GoopText(
                        tier.chestName,
                        style: TextStyle(
                          fontSize: FontSizes.titleSmall,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Colors.white
                              .withValues(alpha: 0.95),
                        ),
                      ),
                      GoopText(
                        '$poolSize loot · $guns guns · $items items',
                        style: TextStyle(
                          fontSize: FontSizes.labelMedium,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                if (locked)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      GoopText(
                        unlockHint,
                        style: TextStyle(
                          fontSize: FontSizes.labelSmall,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  )
                else if (completed)
                  const _CompletedLabel()
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GoopText(
                        'BEST',
                        style: TextStyle(
                          fontSize: FontSizes.labelSmall,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      GoopText(
                        '$best/$poolSize',
                        style: TextStyle(
                          fontSize: FontSizes.titleMedium,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: tier.accent,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: Insets.sm),

            // The chest itself — fixed slot + per-tier scale so every
            // sprite reads the same visual size.
            SizedBox(
              height: 108,
              child: Center(
                child: Image.asset(
              tier.asset,
              height: 92 * tier.spriteScale,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
              errorBuilder: (_, __, ___) => Icon(
                Icons.inventory_2_rounded,
                size: 72,
                color: tier.accent.withValues(alpha: 0.6),
              ),
            ),
              ),
            ),
            const SizedBox(height: Insets.xs),
            GoopText(
              locked
                  ? 'LOCKED'
                  : completed
                      ? 'OPEN FOR FUN'
                      : 'TAP TO START',
              style: TextStyle(
                fontSize: FontSizes.labelSmall,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tier badge for the chest card — a [QualityBadge] letter for the
/// five standard chests, an accent chip for letter-less bonus chests.
class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});

  final QuizChestTier tier;

  @override
  Widget build(BuildContext context) {
    final badge = tier.isBonus
        ? Container(
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tier.accent.withValues(alpha: 0.18),
              borderRadius: Radii.pill,
              border: Border.all(
                color: tier.accent.withValues(alpha: 0.7),
                width: 1.2,
              ),
            ),
            child: GoopText(
              tier.title,
              style: TextStyle(
                fontSize: FontSizes.labelMedium,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: tier.accent,
              ),
            ),
          )
        : QualityBadge(quality: tier.id, size: 26);
    // Polished chip — soft accent ring + tier-colored glow so the
    // badge reads as loot-tier chrome, not a flat letter.
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tier.accent.withValues(alpha: 0.10),
        border: Border.all(
            color: tier.accent.withValues(alpha: 0.55), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: tier.accent.withValues(alpha: 0.35),
            blurRadius: 10,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: badge,
    );
  }
}

/// Big bold floating COMPLETED! label — replaces the streak stats on
/// cleared chests. Loops a gentle bob unless reduced motion is on.
class _CompletedLabel extends StatefulWidget {
  const _CompletedLabel();

  @override
  State<_CompletedLabel> createState() => _CompletedLabelState();
}

class _CompletedLabelState extends State<_CompletedLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = ReduceMotion.of(context);
    if (reduce != _reduceMotion) {
      _reduceMotion = reduce;
      reduce ? _float.stop() : _float.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, sin(_float.value * pi) * 3.5),
        child: child,
      ),
      child: GoopText(
        'COMPLETED!',
        style: TextStyle(
          fontSize: FontSizes.titleMedium,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
          color: const Color(0xFFFFD700),
          shadows: const [
            Shadow(
              offset: Offset(0, 2),
              blurRadius: 8,
              color: Color(0xAA000000),
            ),
            Shadow(
              blurRadius: 16,
              color: Color(0x66FFD700),
            ),
          ],
        ),
      ),
    );
  }
}
