import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/home_customization.dart';
import 'vortex_config.dart';

/// Lightning strikes that fire when the vortex cycle resets (masking any
/// remaining loop seam) plus random smaller strikes in between for a
/// natural, unstable-vortex feel.
///
/// **Two strike types:**
/// 1. **Cycle-boundary strike** — a big, bright bolt that fires exactly
///    when the vortex cycle wraps (every ~55s by default). This masks
///    the animation loop seam with a dramatic flash.
/// 2. **Random ambient strikes** — smaller, dimmer bolts that fire at
///    random intervals (8–18s) between cycle boundaries. These make the
///    vortex feel alive and unstable rather than perfectly predictable.
///
/// Each strike is a jagged lightning bolt rendered via [CustomPainter],
/// drawn from a random point at the top of the screen down toward the
/// vortex center. A brief white-blue screen flash accompanies each strike.
///
/// Purely decorative — wrapped in IgnorePointer by the caller. Respects
/// the Gungeoneer visibility toggle (only shows when the gungeoneer
/// sprite is visible, since the lightning is part of the vortex effect).
class VortexLightning extends StatefulWidget {
  final VortexConfig config;

  const VortexLightning({
    super.key,
    this.config = VortexConfig.defaultConfig,
  });

  @override
  State<VortexLightning> createState() => _VortexLightningState();
}

class _VortexLightningState extends State<VortexLightning>
    with SingleTickerProviderStateMixin {
  late final AnimationController _repaint;
  final Stopwatch _clock = Stopwatch();
  final math.Random _rng = math.Random();

  /// Tracks which cycle we're in so we can detect cycle boundaries.
  int _lastCycle = 0;

  /// Current lightning opacity (fades from 1.0 → 0.0 after each strike).
  double _flashOpacity = 0.0;

  /// Current bolt intensity (0.0–1.0). Big strikes = 0.8–1.0, small = 0.3–0.5.
  double _boltIntensity = 0.0;

  /// Current bolt path (jagged polyline from top to center).
  List<Offset> _boltPath = [];

  /// Timer for the next random ambient strike.
  Timer? _ambientTimer;

  /// Timestamp when the current strike started (for fade-out timing).
  double _strikeStartElapsed = -10.0;

  VortexConfig get _cfg => widget.config;

  @override
  void initState() {
    super.initState();
    _repaint = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _clock.start();
    _scheduleNextAmbientStrike();
  }

  @override
  void dispose() {
    _ambientTimer?.cancel();
    _clock.stop();
    _repaint.dispose();
    super.dispose();
  }

  /// Schedule the next random ambient strike at a natural interval.
  void _scheduleNextAmbientStrike() {
    // Random 8–18 second interval between ambient strikes.
    final delaySeconds = 8 + _rng.nextInt(11);
    _ambientTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!mounted) return;
      _triggerStrike(
        intensity: 0.25 + _rng.nextDouble() * 0.25, // 0.25–0.50 (small)
        isCycleBoundary: false,
      );
      _scheduleNextAmbientStrike();
    });
  }

  /// Trigger a lightning strike with the given intensity.
  void _triggerStrike({
    required double intensity,
    required bool isCycleBoundary,
  }) {
    _boltIntensity = intensity.clamp(0.0, 1.0);
    _flashOpacity = 1.0;
    _strikeStartElapsed = _clock.elapsedMilliseconds / 1000.0;
    // Bolt path is regenerated in the build/paint phase using current
    // screen dimensions — we just mark it dirty here.
    _boltPath = [];
  }

  /// Check if we've crossed a cycle boundary and trigger a big strike.
  void _maybeCycleStrike(double elapsed) {
    final cycle = _cfg.gungeoneerCycleDuration;
    if (cycle <= 0) return;
    final currentCycle = (elapsed / cycle).floor();
    if (currentCycle != _lastCycle) {
      _lastCycle = currentCycle;
      // Big strike at the cycle boundary — masks the loop seam.
      // Delay slightly (200ms) so it fires right as the new cycle starts.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _triggerStrike(
          intensity: 0.75 + _rng.nextDouble() * 0.25, // 0.75–1.0 (big)
          isCycleBoundary: true,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HomeCustomization>(
      valueListenable: HomeCustomization.notifier,
      builder: (context, cust, _) {
        // Only show lightning when the gungeoneer (vortex) is visible.
        if (!cust.showGungeoneer) return const SizedBox.shrink();

        return IgnorePointer(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedBuilder(
                animation: _repaint,
                builder: (context, _) {
                  final elapsed = _clock.elapsedMilliseconds / 1000.0;
                  _maybeCycleStrike(elapsed);

                  // Fade out the flash over ~350ms.
                  final timeSinceStrike = elapsed - _strikeStartElapsed;
                  if (timeSinceStrike < 0.35 && _flashOpacity > 0) {
                    // Quick fade: bright for 80ms, then fade over 270ms.
                    if (timeSinceStrike < 0.08) {
                      _flashOpacity = _boltIntensity;
                    } else {
                      _flashOpacity = _boltIntensity *
                          (1.0 - (timeSinceStrike - 0.08) / 0.27);
                    }
                  } else if (_flashOpacity > 0) {
                    _flashOpacity = 0.0;
                  }

                  if (_flashOpacity <= 0.01) return const SizedBox.shrink();

                  // Generate bolt path if empty (new strike).
                  final screenW = constraints.maxWidth;
                  final screenH = constraints.maxHeight;
                  if (screenW <= 0 || screenH <= 0) {
                    return const SizedBox.shrink();
                  }
                  if (_boltPath.isEmpty) {
                    _boltPath = _generateBoltPath(screenW, screenH, _boltIntensity);
                  }

                  return _buildLightningOverlay(screenW, screenH);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLightningOverlay(double screenW, double screenH) {
    return Stack(
      children: [
        // ── Screen flash (full-screen white-blue tint) ──
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Color.lerp(
                    Colors.transparent,
                    const Color(0xFFB3E5FC), // Light cyan-blue
                    _flashOpacity * 0.35,
                  )!,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // ── Lightning bolt ──
        Positioned.fill(
          child: CustomPaint(
            painter: _LightningBoltPainter(
              path: _boltPath,
              intensity: _boltIntensity,
              opacity: _flashOpacity,
            ),
          ),
        ),
      ],
    );
  }

  /// Generate a jagged lightning bolt path from a random top point down
  /// toward the vortex center. Higher intensity = more jagged, longer bolt.
  List<Offset> _generateBoltPath(double screenW, double screenH, double intensity) {
    final cx = screenW / 2;
    final cy = screenH / 2;

    // Start point: random X near the top, Y at the top edge.
    final startX = cx + (_rng.nextDouble() - 0.5) * screenW * 0.6;
    final start = Offset(startX, 0);

    // End point: near the vortex center, with some random offset.
    final endX = cx + (_rng.nextDouble() - 0.5) * screenW * 0.2;
    final endY = cy + (_rng.nextDouble() - 0.5) * screenH * 0.15;
    final end = Offset(endX, endY);

    // Number of jagged segments — more for higher intensity.
    final segments = (6 + (intensity * 8).round()).clamp(6, 14);

    // Build the path by interpolating between start and end with
    // random perpendicular offsets.
    final path = <Offset>[start];
    for (int i = 1; i < segments; i++) {
      final t = i / segments;
      final baseX = start.dx + (end.dx - start.dx) * t;
      final baseY = start.dy + (end.dy - start.dy) * t;
      // Perpendicular jitter — scales with intensity and decreases
      // as we approach the center (bolt converges).
      final jitterScale = intensity * screenW * 0.08 * (1.0 - t * 0.5);
      final jitterX = (_rng.nextDouble() - 0.5) * jitterScale;
      final jitterY = (_rng.nextDouble() - 0.5) * jitterScale * 0.3;
      path.add(Offset(baseX + jitterX, baseY + jitterY));
    }
    path.add(end);

    return path;
  }
}

/// Custom painter that renders a jagged lightning bolt with a glow effect.
class _LightningBoltPainter extends CustomPainter {
  final List<Offset> path;
  final double intensity;
  final double opacity;

  const _LightningBoltPainter({
    required this.path,
    required this.intensity,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2 || opacity <= 0) return;

    // ── Outer glow stroke (wide, low opacity) ──
    final glowPaint = Paint()
      ..color = const Color(0xFF81D4FA).withValues(alpha: opacity * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 * intensity
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // ── Main bolt stroke (bright white-blue) ──
    final boltPaint = Paint()
      ..color = const Color(0xFFE1F5FE).withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * intensity
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // ── Core stroke (pure white, thin) ──
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * intensity
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Build the path.
    final uiPath = Path()..moveTo(path[0].dx, path[0].dy);
    for (int i = 1; i < path.length; i++) {
      uiPath.lineTo(path[i].dx, path[i].dy);
    }

    // Draw glow first (behind), then bolt, then core.
    canvas.drawPath(uiPath, glowPaint);
    canvas.drawPath(uiPath, boltPaint);
    canvas.drawPath(uiPath, corePaint);

    // ── Branch forks: 1–2 small branches off the main bolt ──
    if (intensity > 0.4 && path.length > 4) {
      final branchCount = intensity > 0.7 ? 2 : 1;
      for (int b = 0; b < branchCount; b++) {
        // Pick a random point on the main bolt (not too close to ends).
        final idx = 2 + _branchRng.nextInt(path.length - 4);
        final branchStart = path[idx];
        // Branch goes off at an angle, shorter than the main bolt.
        final branchLen = 30 + _branchRng.nextDouble() * 60 * intensity;
        final angle = (_branchRng.nextDouble() - 0.5) * math.pi * 0.8;
        final branchEnd = Offset(
          branchStart.dx + math.cos(angle) * branchLen,
          branchStart.dy + math.sin(angle) * branchLen.abs(),
        );
        final branchPath = Path()
          ..moveTo(branchStart.dx, branchStart.dy)
          ..lineTo(branchEnd.dx, branchEnd.dy);
        canvas.drawPath(branchPath, glowPaint);
        canvas.drawPath(branchPath, boltPaint);
      }
    }
  }

  // Static RNG for branch generation (doesn't change per repaint).
  static final _branchRng = math.Random(7);

  @override
  bool shouldRepaint(_LightningBoltPainter old) =>
      old.opacity != opacity ||
      old.intensity != intensity ||
      old.path.length != path.length;
}
