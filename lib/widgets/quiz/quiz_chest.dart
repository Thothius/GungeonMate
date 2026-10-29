import 'dart:math';

import 'package:flutter/material.dart';

import '../../utils/reduce_motion.dart';

/// The tappable loot chest for the Gungeonmaster Quiz.
///
/// Three visual phases driven by [opening]:
/// - closed  : gentle idle bob + accent glow pulse, tap to open
/// - opening : shake → lid-flip (top half of the sprite pops off) → poof
///   particle burst; [onOpened] fires when the pop finishes
/// - opened  : settles dimmed with the lid flipped away
///
/// Uses two ClipRect halves of the same sprite to fake the lid flip —
/// we only have closed-chest art, and the illusion reads well.
class QuizChest extends StatefulWidget {
  const QuizChest({
    super.key,
    required this.asset,
    required this.accent,
    this.size = 140,
    this.opening = false,
    this.onTap,
    this.onOpened,
    this.poofSeed = 0,
  });

  final String asset;
  final Color accent;
  final double size;
  final bool opening;
  final VoidCallback? onTap;
  final VoidCallback? onOpened;

  /// Varies the poof particle pattern — pass the question index so every
  /// drop bursts differently while staying deterministic per question.
  final int poofSeed;

  @override
  State<QuizChest> createState() => _QuizChestState();
}

class _QuizChestState extends State<QuizChest>
    with TickerProviderStateMixin {
  late final AnimationController _idle;
  late final AnimationController _open;
  bool _poofFired = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _open = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _open.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onOpened?.call();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = ReduceMotion.of(context);
    if (reduce != _reduceMotion) {
      _reduceMotion = reduce;
      if (reduce) {
        _idle.stop();
      } else if (!widget.opening) {
        _idle.repeat(reverse: true);
      }
    }
  }

  @override
  void didUpdateWidget(covariant QuizChest old) {
    super.didUpdateWidget(old);
    if (widget.opening && !old.opening) {
      _idle.stop();
      _poofFired = false;
      _open.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _open.dispose();
    super.dispose();
  }

  /// Poof burst fires at the lid-pop moment (~55% through the open).
  bool get _poofVisible {
    if (_poofFired || !widget.opening) return _poofFired;
    if (_open.value >= 0.5) _poofFired = true;
    return _poofFired;
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return GestureDetector(
      onTap: widget.opening ? null : widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size * 1.7,
        height: size * 1.6,
        child: AnimatedBuilder(
          animation: Listenable.merge([_idle, _open]),
          builder: (context, _) {
            final t = _open.value;
            // Idle bob: smooth up/down sine on the repeat-reverse loop.
            final bob = _reduceMotion
                ? 0.0
                : (sin(_idle.value * pi) * 5.0) * (1 - t);
            // Shake: decays as the open progresses into the pop.
            final shakeT = t.clamp(0.0, 0.5) / 0.5;
            final shake = _reduceMotion
                ? 0.0
                : sin(t * 40) * 0.05 * (1 - shakeT);
            // Scale punch peaks mid-open then settles.
            final punch = t < 0.55
                ? 1 + (t / 0.55) * 0.14
                : 1 + (1 - (t - 0.55) / 0.45) * 0.14;
            final dim = 1 - (t * 0.55);

            return Stack(
              alignment: Alignment.center,
              children: [
                // Accent glow — breathes while idle, flares at the pop.
                Container(
                  width: size * 1.35,
                  height: size * 1.35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.accent.withValues(
                            alpha: 0.28 + _idle.value * 0.1 + t * 0.3),
                        widget.accent.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                // The chest — bottom half anchors, top half flips off.
                // X-jitter at a different frequency than the rotation
                // makes the rattle read physical, not mechanical.
                Transform.translate(
                  offset: Offset(
                      _reduceMotion
                          ? 0
                          : sin(t * 43) * 3.0 * (1 - shakeT),
                      bob),
                  child: Transform.rotate(
                    angle: shake,
                    child: Transform.scale(
                      scale: punch,
                      child: Opacity(
                        opacity: dim.clamp(0.45, 1.0),
                        child: _SplitChest(
                          asset: widget.asset,
                          size: size,
                          lidT: t,
                        ),
                      ),
                    ),
                  ),
                ),
                // Poof particle burst at the pop.
                if (_poofVisible)
                  _PoofBurst(
                    progress: ((t - 0.5) / 0.5).clamp(0.0, 1.0),
                    size: size,
                    accent: widget.accent,
                    seed: widget.poofSeed,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Renders the chest sprite as two horizontal halves. At rest they line
/// up into the full sprite; during the open, the top half (lid) flips
/// up and away while the bottom half stays planted.
class _SplitChest extends StatelessWidget {
  const _SplitChest({
    required this.asset,
    required this.size,
    required this.lidT,
  });

  final String asset;
  final double size;
  final double lidT;

  Widget _half(Alignment align, Widget child) => ClipRect(
        child: Align(
          alignment: align,
          heightFactor: 0.5,
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context) {
    // Lid motion: lifts, tips right, fades — only after the shake phase.
    final lt = ((lidT - 0.45) / 0.55).clamp(0.0, 1.0);
    final lidLift = Curves.easeIn.transform(lt) * size * 0.9;
    final lidSpin = Curves.easeIn.transform(lt) * -0.5;
    final lidFade = 1 - Curves.easeIn.transform(lt);

    final sprite = Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      errorBuilder: (_, __, ___) => Icon(
        Icons.inventory_2_rounded,
        size: size * 0.7,
        color: Colors.white54,
      ),
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Bottom half — stays planted at the bottom of the sprite box.
          Align(
            alignment: Alignment.bottomCenter,
            child: _half(Alignment.bottomCenter, sprite),
          ),
          // Top half (the lid) — pops off during the open.
          Align(
            alignment: Alignment.topCenter,
            child: Transform.translate(
              offset: Offset(size * 0.28 * lt, -lidLift),
              child: Transform.rotate(
                angle: lidSpin,
                child: Opacity(
                  opacity: lidFade,
                  child: _half(Alignment.topCenter, sprite),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A quick radial burst of particles — the loot poof. Painted once per
/// frame off the open controller's progress; deterministic per instance.
class _PoofBurst extends StatelessWidget {
  _PoofBurst({
    required this.progress,
    required this.size,
    required this.accent,
    required this.seed,
  }) : _seeds = List.generate(
            16, (i) => Random(seed * 31 + i).nextDouble());

  final double progress;
  final double size;
  final Color accent;
  final int seed;
  final List<double> _seeds;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size(size * 1.7, size * 1.6),
        painter: _PoofPainter(progress, accent, _seeds),
      ),
    );
  }
}

class _PoofPainter extends CustomPainter {
  _PoofPainter(this.t, this.accent, this.seeds);

  final double t;
  final Color accent;
  final List<double> seeds;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final center = Offset(size.width / 2, size.height / 2);
    final ease = Curves.easeOut.transform(t);
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < seeds.length; i++) {
      final jitter = seeds[i];
      final angle = (i / seeds.length) * 2 * pi + jitter * 0.8;
      final dist = ease * size.shortestSide * (0.45 + jitter * 0.5);
      final r = (1 - t) * (3.5 + jitter * 5);
      final pos = center + Offset(cos(angle) * dist, sin(angle) * dist);
      paint.color =
          (i.isEven ? Colors.white : accent).withValues(alpha: (1 - t) * 0.9);
      canvas.drawCircle(pos, r.clamp(0.5, 10.0), paint);
    }
    // Central flash ring that expands and fades with the burst.
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * (1 - t)
      ..color = Colors.white.withValues(alpha: (1 - t) * 0.7);
    canvas.drawCircle(center, ease * size.shortestSide * 0.55, paint);
  }

  @override
  bool shouldRepaint(_PoofPainter old) => old.t != t;
}
