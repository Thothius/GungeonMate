import 'dart:async';
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
import '../../utils/reduce_motion.dart';
import '../../utils/fast_route.dart';
import '../../models/player.dart';
import '../item_detail_screen.dart';
import '../../widgets/game_icon.dart';
import '../../widgets/active_run/bottom_back_bar.dart';
import '../../widgets/quality_badge.dart';
import '../../widgets/quiz/quiz_answers.dart';
import '../../widgets/quiz/quiz_chest.dart';
import '../../widgets/scale_button.dart';

/// One chest run of the Gungeonmaster Quiz.
///
/// Flow: tap the chest → it pops open with a loot drop → name the drop
/// from six options. A right pick advances the streak and rolls the next
/// chest; a wrong pick ends the run — best streak is saved live, so a
/// flawless run through the whole pool completes the chest.
class QuizSessionScreen extends StatefulWidget {
  const QuizSessionScreen({super.key, required this.tier});

  final QuizChestTier tier;

  @override
  State<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

enum _Phase { closed, opening, question, reveal, gameOver }

class _QuizSessionScreenState extends State<QuizSessionScreen> {
  final _rng = Random();
  late final QuizEngine _engine;
  late List<QuizLoot> _pool;

  _Phase _phase = _Phase.closed;
  int _index = 0;
  int _streak = 0;
  int _sessionBest = 0;
  QuizQuestion? _question;
  int? _pickedIndex;
  Timer? _revealTimer;
  bool _runOver = false;
  bool _flawless = false;
  bool _newBest = false;
  bool _engineReady = false;
  bool _hintUsed = false;
  bool _exiting = false;
  bool _backDialogOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_engineReady) return;
    final rp = context.read<RunProvider>();
    _engine = QuizEngine(guns: rp.allGuns, items: rp.allItems);
    _startRun();
    _engineReady = true;
  }

  void _startRun() {
    _pool = _engine.poolForTier(widget.tier, rng: _rng);
    _index = 0;
    _streak = 0;
    _sessionBest = 0;
    _question = null;
    _pickedIndex = null;
    _runOver = false;
    _flawless = false;
    _newBest = false;
    _hintUsed = false;
    // Empty pool (data shrink / broken tier) — straight to game-over
    // instead of crashing on _pool[0] in _onChestOpened.
    _phase = _pool.isEmpty ? _Phase.gameOver : _Phase.closed;
  }

  QuizLoot get _current => _pool[_index];
  int get _poolSize => _pool.length;

  // ── Flow ───────────────────────────────────────────────────────────

  void _onChestTap() {
    if (_phase != _Phase.closed) return;
    Haptics.medium();
    setState(() => _phase = _Phase.opening);
  }

  void _onChestOpened() {
    if (!mounted || _phase != _Phase.opening) return;
    setState(() {
      _question = _engine.questionFor(_current, rng: _rng);
      _pickedIndex = null;
      _phase = _Phase.question;
    });
  }

  /// Opens the loot's Ammonomicon entry — resolves name → Gun/Item
  /// via the provider, then pushes the detail screen.
  void _openAmmonomicon(QuizQuestion q) {
    final p = context.read<RunProvider>();
    final name = q.loot.name;
    if (q.loot.isGun) {
      final gun = p.allGuns.where((g) => g.name == name).firstOrNull;
      if (gun == null) return;
      Navigator.push(
        context,
        fastRoute(ItemDetailScreen(gun: gun, ownerSlot: PlayerSlot.main)),
      );
    } else {
      final item = p.allItems.where((i) => i.name == name).firstOrNull;
      if (item == null) return;
      Navigator.push(
        context,
        fastRoute(ItemDetailScreen(item: item, ownerSlot: PlayerSlot.main)),
      );
    }
  }

  void _onPick(int index) {
    if (_phase != _Phase.question || _question == null) return;
    final correct = index == _question!.correctIndex;
    setState(() {
      _pickedIndex = index;
      _phase = _Phase.reveal;
    });
    if (correct) {
      Haptics.success();
      _streak++;
      if (_streak > _sessionBest) {
        _sessionBest = _streak;
        // Live-save the high-water mark — quitting early keeps progress.
        QuizProgress.instance.recordStreak(widget.tier.id, _sessionBest);
      }
      _revealTimer = Timer(
        ReduceMotion.of(context)
            ? const Duration(milliseconds: 350)
            : const Duration(milliseconds: 650),
        _advance,
      );
    } else {
      // Wrong pick ends the run — but the reveal holds until the player
      // taps through it, so the correct answer gets its learning beat.
      Haptics.warning();
    }
  }

  /// Once per run: reveal the loot's real Ammonomicon quote/effect.
  void _useHint() {
    final q = _question;
    if (_phase != _Phase.question ||
        _hintUsed ||
        q == null ||
        q.loot.hint.isEmpty) {
      return;
    }
    Haptics.light();
    setState(() => _hintUsed = true);
  }

  /// Next loot: roll a fresh closed chest, or finish flawlessly when the
  /// pool is exhausted (reaching the end means every pick was right).
  void _advance() {
    if (!mounted) return;
    if (_index >= _poolSize - 1) {
      _endRun();
      return;
    }
    setState(() {
      _index++;
      _question = null;
      _pickedIndex = null;
      _phase = _Phase.closed;
    });
  }

  Future<void> _endRun() async {
    if (!mounted || _runOver) return;
    _runOver = true;
    _flawless = _streak == _poolSize && _poolSize > 0;
    _newBest = await QuizProgress.instance.recordRun(
      widget.tier.id,
      _sessionBest,
      flawless: _flawless,
    );
    if (!mounted) return;
    setState(() => _phase = _Phase.gameOver);
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    super.dispose();
  }

  /// System back (gesture/button) routes through PopScope — it must
  /// clear the same guard as the in-app back button. [_exiting] lets
  /// a confirmed pop pass canPop on the next frame.
  bool get _canPop => _exiting || _phase == _Phase.gameOver || _streak == 0;

  /// Back during a live streak asks first — progress is saved either
  /// way, but a mis-tap shouldn't end a good run for free.
  Future<void> _onBack() async {
    if (_canPop) {
      Navigator.maybePop(context);
      return;
    }
    if (_backDialogOpen) return;
    _backDialogOpen = true;
    final leave = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: const GoopText('End chest run?'),
            content: GoopText(
              'Your streak of $_streak is already saved as your best.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const GoopText('Keep Going'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(c, true),
                child: const GoopText('End Run'),
              ),
            ],
          ),
    );
    _backDialogOpen = false;
    if (leave == true && mounted) {
      // Pop next frame — canPop must rebuild with _exiting first.
      setState(() => _exiting = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.maybePop(context);
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tier = widget.tier;
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // Back moved to the bottom thumb zone (task 17 sweep) — same
        // stage-aware _onBack the top-bar arrow used to call.
        bottomNavigationBar: BottomBackBar(onPressed: _onBack),
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(tier),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: _buildPhase(tier),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(QuizChestTier tier) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Insets.xs, Insets.xs, Insets.lg, 0),
      child: Row(
        children: [
          const SizedBox(width: 40),
          _tierBadge(tier),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: GoopText(
              tier.chestName,
              style: TextStyle(
                fontSize: FontSizes.titleSmall,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
          // Answered / pool progress.
          GoopText(
            '${min(_index + 1, _poolSize)}/$_poolSize',
            style: TextStyle(
              fontSize: FontSizes.labelMedium,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: Insets.md),
          // Streak pill — pulses when the streak grows.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder:
                (child, anim) => ScaleTransition(
                  scale: Tween(begin: 1.25, end: 1.0).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                ),
            child: Container(
              key: ValueKey(_streak),
              padding: const EdgeInsets.symmetric(
                horizontal: Insets.sm + 2,
                vertical: Insets.xs,
              ),
              decoration: BoxDecoration(
                color:
                    _streak > 0
                        ? tier.accent.withValues(alpha: 0.20)
                        : Colors.white.withValues(alpha: 0.06),
                borderRadius: Radii.pill,
                border: Border.all(
                  color:
                      _streak > 0
                          ? tier.accent.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: 14,
                    color:
                        _streak > 0 ? const Color(0xFFFFB300) : Colors.white38,
                  ),
                  const SizedBox(width: 3),
                  GoopText(
                    '$_streak',
                    style: TextStyle(
                      fontSize: FontSizes.labelMedium,
                      fontWeight: FontWeight.w900,
                      color:
                          _streak > 0
                              ? const Color(0xFFFFB300)
                              : Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhase(QuizChestTier tier) {
    switch (_phase) {
      case _Phase.closed:
      case _Phase.opening:
        return _buildChestPrompt(tier);
      case _Phase.question:
      case _Phase.reveal:
        return _buildQuestion(tier);
      case _Phase.gameOver:
        return _buildGameOver(tier);
    }
  }

  /// The closed/opening chest — the whole interaction surface.
  Widget _buildChestPrompt(QuizChestTier tier) {
    final opening = _phase == _Phase.opening;
    return Center(
      key: const ValueKey('chest'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QuizChest(
                asset: tier.asset,
                accent: tier.accent,
                size: 150 * tier.spriteScale,
                opening: opening,
                onTap: _onChestTap,
                onOpened: _onChestOpened,
                poofSeed: _index,
              )
              .animate(key: ValueKey('chest_$_index'))
              .fadeIn(duration: 200.ms)
              .scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1, 1),
                duration: 320.ms,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: Insets.md),
          AnimatedOpacity(
            opacity: opening ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child:
                (opening || ReduceMotion.of(context))
                    ? _tapToOpenText(tier)
                    : _tapToOpenText(tier)
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .fadeIn(duration: 900.ms),
          ),
          const SizedBox(height: Insets.xs),
          GoopText(
            'one wrong answer ends the run',
            style: TextStyle(
              fontSize: FontSizes.labelSmall,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  /// Letter badge for standard chests; an accent pill for the
  /// letter-less bonus chests — matches the select card's badge.
  Widget _tierBadge(QuizChestTier tier) {
    if (!tier.isBonus) return QualityBadge(quality: tier.id, size: 24);
    return Container(
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
    );
  }

  Widget _tapToOpenText(QuizChestTier tier) {
    return GoopText(
      'TAP TO OPEN',
      style: TextStyle(
        fontSize: FontSizes.titleSmall,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.2,
        color: tier.accent.withValues(alpha: 0.85),
      ),
    );
  }

  /// The revealed loot on the top half, six options below.
  /// After a wrong pick the reveal holds — any tap ends the run.
  Widget _buildQuestion(QuizChestTier tier) {
    final q = _question!;
    final revealed = _phase == _Phase.reveal;
    final wasCorrect = revealed && _pickedIndex == q.correctIndex;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: revealed && !wasCorrect ? _endRun : null,
      child: LayoutBuilder(
        builder:
            (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    key: ValueKey('q_$_index'),
                    padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
                    child: Column(
                      children: [
                        const Spacer(),
                        // Revealed loot card — springs in like it popped from the chest.
                        Container(
                              padding: const EdgeInsets.all(Insets.lg),
                              decoration: BoxDecoration(
                                color: tier.accent.withValues(alpha: 0.08),
                                borderRadius: Radii.card,
                                border: Border.all(
                                  color: tier.accent.withValues(alpha: 0.3),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: tier.accent.withValues(alpha: 0.18),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: GameIcon(
                                assetPath: q.loot.iconPath,
                                quality: q.loot.quality,
                                size: 118,
                                fallback:
                                    q.loot.isGun
                                        ? Icons.gps_fixed_rounded
                                        : Icons.inventory_2_rounded,
                                semanticLabel: 'Mystery loot',
                              ),
                            )
                            .animate()
                            .scale(
                              begin: const Offset(0.3, 0.3),
                              end: const Offset(1, 1),
                              duration: 520.ms,
                              curve: Curves.elasticOut,
                            )
                            .fadeIn(duration: 200.ms),
                        const SizedBox(height: Insets.lg),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: GoopText(
                            !revealed
                                ? 'WHAT IS THIS LOOT?'
                                : wasCorrect
                                ? 'CORRECT!'
                                : 'IT WAS:  ${q.loot.name}',
                            key: ValueKey('$revealed$wasCorrect'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: FontSizes.titleSmall,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4,
                              color:
                                  !revealed
                                      ? Colors.white.withValues(alpha: 0.75)
                                      : wasCorrect
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFE53935),
                            ),
                          ),
                        ),
                        if (revealed)
                          GestureDetector(
                            onTap: () => _openAmmonomicon(q),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.menu_book_rounded,
                                    size: 14,
                                    color: tier.accent.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(width: 5),
                                  GoopText(
                                    'AMMONOMICON',
                                    style: TextStyle(
                                      fontSize: FontSizes.labelSmall,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                      color: tier.accent.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 14,
                                    color: tier.accent.withValues(alpha: 0.6),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: Insets.sm),
                        // Ammonomicon hint — once per run, shows the item's real
                        // flavor quote/effect. Sits in a fixed slot so the grid
                        // never jumps when it's used.
                        SizedBox(
                          height: 40,
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _buildHintSlot(tier, q),
                            ),
                          ),
                        ),
                        const Spacer(),
                        QuizAnswerGrid(
                          options: q.options,
                          correctIndex: q.correctIndex,
                          accent: tier.accent,
                          pickedIndex: _pickedIndex,
                          onPick: _onPick,
                        ),
                        const SizedBox(height: Insets.md),
                        // Wrong-pick reveal: the run is over but the answer stays up
                        // until the player taps through it.
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child:
                              revealed && !wasCorrect
                                  ? GoopText(
                                        'TAP TO CONTINUE',
                                        key: const ValueKey('tapout'),
                                        style: TextStyle(
                                          fontSize: FontSizes.labelMedium,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2.0,
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      )
                                      .animate(
                                        onPlay:
                                            (c) =>
                                                ReduceMotion.of(context)
                                                    ? null
                                                    : c.repeat(reverse: true),
                                      )
                                      .fadeIn(duration: 800.ms)
                                  : const SizedBox(
                                    height: 18,
                                    key: ValueKey('tapin'),
                                  ),
                        ),
                        const SizedBox(height: Insets.lg),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
  }

  /// The hint affordance — a small pill button until used, then the
  /// loot's real quote/effect in an Ammonomicon-style card. Empty while
  /// a question reveals or when the loot has no flavor text.
  Widget _buildHintSlot(QuizChestTier tier, QuizQuestion q) {
    final hasHint = q.loot.hint.isNotEmpty;
    if (_hintUsed && hasHint) {
      return Container(
        key: const ValueKey('hintcard'),
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.md,
          vertical: Insets.xs + 2,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E22),
          borderRadius: Radii.card,
          border: Border.all(
            color: const Color(0xFF8E6F3E).withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_stories_rounded,
              size: 14,
              color: Color(0xFFCDA349),
            ),
            const SizedBox(width: Insets.sm),
            Flexible(
              child: GoopText(
                '"${q.loot.hint}"',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: FontSizes.labelMedium,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFCDA349),
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (_phase == _Phase.question && !_hintUsed && hasHint) {
      return ScaleButton(
        key: const ValueKey('hintbtn'),
        onTap: _useHint,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.md,
            vertical: Insets.xs + 2,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFCDA349).withValues(alpha: 0.10),
            borderRadius: Radii.pill,
            border: Border.all(
              color: const Color(0xFFCDA349).withValues(alpha: 0.45),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_stories_rounded,
                size: 13,
                color: Color(0xFFCDA349),
              ),
              SizedBox(width: 6),
              GoopText(
                'AMMONOMICON HINT',
                style: TextStyle(
                  fontSize: FontSizes.labelSmall,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Color(0xFFCDA349),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink(key: ValueKey('hinthidden'));
  }

  /// End-of-run summary — chest, headline, stats, action buttons.
  Widget _buildGameOver(QuizChestTier tier) {
    return Center(
      key: const ValueKey('over'),
      child: SingleChildScrollView(
            padding: const EdgeInsets.all(Insets.xl),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 340),
              padding: const EdgeInsets.all(Insets.xl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    tier.accent.withValues(alpha: 0.16),
                    tier.accent.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: Radii.card,
                border: Border.all(
                  color: tier.accent.withValues(alpha: 0.55),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: tier.accent.withValues(alpha: 0.25),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    tier.asset,
                    height: 84,
                    filterQuality: FilterQuality.none,
                    errorBuilder:
                        (_, _, _) =>
                            const Icon(Icons.inventory_2_rounded, size: 64),
                  ),
                  const SizedBox(height: Insets.md),
                  GoopText(
                        _flawless ? 'COMPLETED!' : 'RUN OVER',
                        style: TextStyle(
                          fontSize: FontSizes.headlineSmall,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color:
                              _flawless ? const Color(0xFFFFD700) : tier.accent,
                          shadows:
                              _flawless
                                  ? const [
                                    Shadow(
                                      blurRadius: 18,
                                      color: Color(0x88FFD700),
                                    ),
                                  ]
                                  : null,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .scale(
                        begin: const Offset(0.7, 0.7),
                        end: const Offset(1, 1),
                        duration: 400.ms,
                        curve: Curves.easeOutBack,
                      ),
                  const SizedBox(height: Insets.xs),
                  GoopText(
                    _flawless
                        ? 'Every single drop named. Flawless!'
                        : 'The chest slams shut...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: FontSizes.labelMedium,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: Insets.lg),
                  _statRow('STREAK', '$_sessionBest'),
                  const SizedBox(height: Insets.xs),
                  _statRow('POOL', '$_poolSize'),
                  const SizedBox(height: Insets.xs),
                  _statRow(
                    'BEST',
                    '${QuizProgress.instance.bestStreak(widget.tier.id)}/$_poolSize',
                  ),
                  if (_newBest && !_flawless) ...[
                    const SizedBox(height: Insets.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Insets.md,
                        vertical: Insets.xs,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                        borderRadius: Radii.pill,
                        border: Border.all(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                        ),
                      ),
                      child: const GoopText(
                        'NEW BEST!',
                        style: TextStyle(
                          fontSize: FontSizes.labelMedium,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.6,
                          color: Color(0xFFFFD700),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: Insets.xl),
                  _gameOverButton(
                    label: 'OPEN ANOTHER',
                    accent: tier.accent,
                    filled: true,
                    onTap: () {
                      Haptics.selection();
                      setState(_startRun);
                    },
                  ),
                  const SizedBox(height: Insets.sm),
                  _gameOverButton(
                    label: 'BACK TO CHESTS',
                    accent: tier.accent,
                    filled: false,
                    onTap: () {
                      Haptics.light();
                      Navigator.maybePop(context);
                    },
                  ),
                ],
              ),
            ),
          )
          .animate()
          .fadeIn(duration: 280.ms)
          .slideY(begin: 0.12, end: 0, duration: 320.ms),
    );
  }

  Widget _statRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GoopText(
          label,
          style: TextStyle(
            fontSize: FontSizes.labelMedium,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
        GoopText(
          value,
          style: const TextStyle(
            fontSize: FontSizes.titleSmall,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _gameOverButton({
    required String label,
    required Color accent,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient:
              filled
                  ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accent.withValues(alpha: 0.85),
                      accent.withValues(alpha: 0.6),
                    ],
                  )
                  : null,
          color: filled ? null : accent.withValues(alpha: 0.10),
          borderRadius: Radii.card,
          border: Border.all(
            color: accent.withValues(alpha: filled ? 0.9 : 0.45),
            width: 1.4,
          ),
          boxShadow:
              filled
                  ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: GoopText(
          label,
          style: TextStyle(
            fontSize: FontSizes.bodyMedium,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.6,
            color: filled ? Colors.black87 : accent,
          ),
        ),
      ),
    );
  }
}
