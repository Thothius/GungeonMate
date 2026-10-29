import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/multiplayer_messages.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/haptics.dart';
import '../../services/mp_session.dart';
import '../../theme/tokens.dart';
import '../../utils/responsive.dart';
import 'emote_sprite_catalog.dart';
import 'dart:math' as math;

/// Receiving side of the Surprise interaction — a floating card that
/// springs in over whatever screen is open, holds ~3s, then drifts
/// away. Lives as a listener inside the active-run scaffold; multiple
/// incoming surprises queue sequentially.
class SurpriseOverlayHost extends StatefulWidget {
  final Widget child;
  const SurpriseOverlayHost({super.key, required this.child});

  @override
  State<SurpriseOverlayHost> createState() => _SurpriseOverlayHostState();
}

class _SurpriseOverlayHostState extends State<SurpriseOverlayHost> {
  final List<MpSurprise> _queue = [];
  MpSession? _session;

  @override
  void initState() {
    super.initState();
    EmoteSpriteCatalog.ensureLoaded();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _session = context.read<MpSession>();
      _session!.onSurpriseReceived = _onSurprise;
    });
  }

  @override
  void dispose() {
    try {
      if (_session?.onSurpriseReceived == _onSurprise) {
        _session?.onSurpriseReceived = null;
      }
    } catch (_) {}
    super.dispose();
  }

  void _onSurprise(MpSurprise s) {
    if (!mounted) return;
    Haptics.success();
    setState(() => _queue.add(s));
    // Auto-dismiss after the hold duration.
    Timer(const Duration(milliseconds: 3200), () {
      if (!mounted) return;
      setState(() {
        if (_queue.isNotEmpty) _queue.removeAt(0);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_queue.isNotEmpty)
          _SurpriseCard(key: ValueKey(_queue.first), surprise: _queue.first),
      ],
    );
  }
}

class _SurpriseCard extends StatelessWidget {
  final MpSurprise surprise;
  const _SurpriseCard({super.key, required this.surprise});

  /// Curated 6 — each has a fullscreen effect (fx).
  /// fx: hearts · shake · flash · jumpscare · pulse · scatter
  static const _presetContent = <String, (String, IconData, Color, String)>{
    'love': ('I LOVE YOU', Icons.favorite_rounded, Color(0xFFFF6B81), 'hearts'),
    'slap': ('*SLAP*', Icons.back_hand_rounded, Color(0xFFFF7043), 'shake'),
    'blank': ('BLANK!', Icons.brightness_7_rounded, Color(0xFFFFFFFF), 'flash'),
    'mimic': (
      'MIMIC!',
      Icons.warning_amber_rounded,
      Color(0xFF8D6E63),
      'jumpscare',
    ),
    'heal': ('GET WELL', Icons.healing_rounded, Color(0xFF66BB6A), 'pulse'),
    'gungeon': (
      'GUNGEON!',
      Icons.gps_fixed_rounded,
      Color(0xFFB388FF),
      'scatter',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    final preset = _presetContent[surprise.preset];
    final text =
        surprise.preset == 'custom'
            ? surprise.text
            : (preset?.$1 ?? surprise.text);
    final icon = preset?.$2 ?? Icons.auto_awesome_rounded;
    final color = preset?.$3 ?? Colors.amberAccent;
    final fx = surprise.fx.isNotEmpty ? surprise.fx : (preset?.$4 ?? 'pulse');
    final sprite =
        surprise.spriteKey.isNotEmpty
            ? EmoteSpriteCatalog.byKey(surprise.spriteKey)
            : null;

    return Positioned.fill(
      child: IgnorePointer(
        child: _SurpriseFx(
          fx: fx,
          color: color,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder:
                  (_, t, child) => Transform.scale(
                    scale: 0.3 + 0.7 * t,
                    child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
                  ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 26 * sf,
                  vertical: 22 * sf,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF140B22).withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: color.withValues(alpha: 0.7),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (sprite != null)
                      Image.asset(
                        sprite.assetPath,
                        width: 140 * sf,
                        height: 140 * sf,
                        filterQuality: FilterQuality.none,
                      )
                    else
                      Icon(icon, size: 52 * sf, color: color),
                    SizedBox(height: 12 * sf),
                    GoopText(
                      text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: FontSizes.titleMedium * sf,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: color,
                      ),
                    ),
                    SizedBox(height: 8 * sf),
                    GoopText(
                      'from ${context.read<MpSession>().peerNickname ?? 'partner'}',
                      style: TextStyle(
                        fontSize: 10.5 * sf,
                        color: Colors.white.withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fullscreen effect layer behind the surprise card — six curated
/// effects, one per preset. Ticks at 60fps via an AnimationController.
class _SurpriseFx extends StatefulWidget {
  const _SurpriseFx({
    required this.fx,
    required this.color,
    required this.child,
  });
  final String fx;
  final Color color;
  final Widget child;

  @override
  State<_SurpriseFx> createState() => _SurpriseFxState();
}

class _SurpriseFxState extends State<_SurpriseFx>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();
  final _rng = math.Random();
  late final List<Offset> _seeds = List.generate(
    24,
    (_) => Offset(_rng.nextDouble(), _rng.nextDouble()),
  );

  @override
  void initState() {
    super.initState();
    if (widget.fx == 'shake' || widget.fx == 'explosion') {
      Haptics.heavy();
    }
    if (widget.fx == 'bulletrain') Haptics.medium();
    if (widget.fx == 'jumpscare') Haptics.medium();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder:
          (_, child) => Stack(
            children: [
              if (widget.fx == 'flash')
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.white.withValues(
                        alpha: (1 - _ctrl.value) * 0.55,
                      ),
                    ),
                  ),
                ),
              if (widget.fx == 'shake' ||
                  widget.fx == 'bulletrain' ||
                  widget.fx == 'explosion')
                Positioned.fill(
                  child: IgnorePointer(
                    child: Transform.translate(
                      offset: Offset(
                        math.sin(_ctrl.value * math.pi * 40) *
                            10 *
                            (1 - _ctrl.value),
                        0,
                      ),
                      child: widget.child,
                    ),
                  ),
                )
              else
                Positioned.fill(child: widget.child),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _FxPainter(
                      fx: widget.fx,
                      t: _ctrl.value,
                      color: widget.color,
                      seeds: _seeds,
                    ),
                  ),
                ),
              ),
            ],
          ),
      child: widget.child,
    );
  }
}

/// Per-fx painter — hearts rise+burst, bullets scatter, pulse glows,
/// jumpscare zooms, shake/flash handled in the widget layer.
class _FxPainter extends CustomPainter {
  _FxPainter({
    required this.fx,
    required this.t,
    required this.color,
    required this.seeds,
  });
  final String fx;
  final double t;
  final Color color;
  final List<Offset> seeds;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    if (fx == 'hearts') {
      for (final s in seeds) {
        final x = s.dx * size.width;
        final y = size.height * (1 - t * (0.6 + s.dy * 0.7));
        final a = (1 - t).clamp(0.0, 0.85);
        paint.color = color.withValues(alpha: a);
        canvas.drawCircle(Offset(x, y), 3 + s.dy * 5, paint);
      }
    } else if (fx == 'scatter') {
      final c = size.center(Offset.zero);
      for (final s in seeds) {
        final ang = s.dx * math.pi * 2;
        final r = t * size.shortestSide * (0.4 + s.dy * 0.6);
        paint.color = color.withValues(alpha: (1 - t) * 0.8);
        canvas.drawCircle(
          c + Offset(math.cos(ang) * r, math.sin(ang) * r),
          2.5 + s.dy * 3,
          paint,
        );
      }
    } else if (fx == 'bulletrain') {
      // Bullet rain — amber streaks falling top→bottom.
      for (final s in seeds) {
        final x = s.dx * size.width;
        final speed = 0.5 + s.dy * 0.8;
        final y = ((t * speed + s.dy) % 1.0) * size.height;
        paint.color = color.withValues(alpha: 0.75);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x, y),
            width: 2.5,
            height: 10 + s.dy * 12,
          ),
          paint,
        );
      }
    } else if (fx == 'heartsburst') {
      // Hearts burst — pink circles exploding outward from center.
      final c = size.center(Offset.zero);
      for (final s in seeds) {
        final ang = s.dx * math.pi * 2;
        final r = t * size.shortestSide * (0.5 + s.dy * 0.5);
        paint.color = const Color(
          0xFFFF6B81,
        ).withValues(alpha: (1 - t).clamp(0.0, 0.85));
        canvas.drawCircle(
          c + Offset(math.cos(ang) * r, math.sin(ang) * r * 0.9),
          4 + s.dy * 6,
          paint,
        );
      }
    } else if (fx == 'explosion') {
      // Explosion — expanding ring + white flash core + debris.
      final c = size.center(Offset.zero);
      final r = t * size.shortestSide * 0.9;
      paint.color = Colors.white.withValues(alpha: (1 - t) * 0.5);
      canvas.drawCircle(c, r * 0.35, paint);
      paint.color = color.withValues(alpha: (1 - t) * 0.7);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 6;
      canvas.drawCircle(c, r, paint);
      paint.style = PaintingStyle.fill;
      for (final s in seeds) {
        final ang = s.dx * math.pi * 2;
        final rr = t * size.shortestSide * (0.3 + s.dy * 0.7);
        paint.color = color.withValues(alpha: (1 - t) * 0.9);
        canvas.drawCircle(
          c + Offset(math.cos(ang) * rr, math.sin(ang) * rr),
          3,
          paint,
        );
      }
    } else if (fx == 'pulse' || fx == 'jumpscare') {
      final c = size.center(Offset.zero);
      final r = t * size.shortestSide;
      paint.color = color.withValues(alpha: (1 - t) * 0.22);
      canvas.drawCircle(c, r, paint);
      paint.color = color.withValues(alpha: (1 - t) * 0.1);
      canvas.drawCircle(c, r * 0.6, paint);
    }
  }

  @override
  bool shouldRepaint(_FxPainter old) => old.t != t;
}
