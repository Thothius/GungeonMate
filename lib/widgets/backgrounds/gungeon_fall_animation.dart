import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../models/gungeoneer.dart';
import '../../providers/run_provider.dart';
import '../../services/app_theme.dart';
import '../../utils/asset_paths.dart';
import '../../utils/responsive.dart';

/// A looping "falling down the Gungeon" animation for the home screen.
///
/// Layers a custom-painted vortex/portal behind a tumbling Gungeoneer
/// sprite, referencing the true ending fall sequence of Enter the Gungeon.
/// The character shown is the player's last played character, or a random
/// pick from the roster if no history exists.
///
/// Purely decorative — wrapped in [IgnorePointer], no easter eggs, no
/// tap interactions. The [child] (main menu content) is layered on top
/// and receives all input.
class GungeonFallAnimation extends StatefulWidget {
  final Widget child;

  const GungeonFallAnimation({super.key, required this.child});

  @override
  State<GungeonFallAnimation> createState() => _GungeonFallAnimationState();
}

class _GungeonFallAnimationState extends State<GungeonFallAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _vortexCtrl;
  String _spritePath = '';
  bool _picked = false;

  @override
  void initState() {
    super.initState();
    _vortexCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pick once after first frame so RunProvider is available.
    if (!_picked) {
      _pickCharacter();
      _picked = true;
    }
  }

  void _pickCharacter() {
    final p = context.read<RunProvider>();
    // 1. Try last played character
    final last = p.lastPlayedCharacter;
    if (last != null) {
      _setSprite(last);
      return;
    }
    // 2. Fallback: RNG from all gungeoneers
    final all = p.allGungeoneers;
    if (all.isEmpty) return; // data not loaded yet — vortex shows alone
    _setSprite(all[math.Random().nextInt(all.length)]);
  }

  void _setSprite(Gungeoneer char) {
    final gif = gungeoneerGifPath(char.name);
    if (gif.isNotEmpty) {
      _spritePath = gif;
      return;
    }
    // Fallback to static webp icon
    final icon = localGungeoneerIcon(char.name);
    if (icon.isNotEmpty) {
      _spritePath = icon;
    }
  }

  @override
  void dispose() {
    _vortexCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    final flair = AppTheme.flair;
    return Stack(
      children: [
        // ── Layer 1: Vortex ──────────────────────────────────────────
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _vortexCtrl,
              builder: (_, __) => CustomPaint(
                painter: _VortexPainter(
                  progress: _vortexCtrl.value,
                  colors: _vortexColors(flair),
                ),
              ),
            ),
          ),
        ),
        // ── Layer 2: Vignette scrim ──────────────────────────────────
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.85,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.35),
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),
          ),
        ),
        // ── Layer 3: Falling Gungeoneer ──────────────────────────────
        if (_spritePath.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: SizedBox(
                  width: 72 * sf,
                  height: 72 * sf,
                  child: Image.asset(
                    _spritePath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      // Endless tumble
                      .rotate(
                        begin: 0,
                        end: 2 * math.pi,
                        duration: 3.seconds,
                        curve: Curves.linear,
                      )
                      // Depth pulse — simulates falling closer/farther
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.1, 1.1),
                        duration: 4.seconds,
                        curve: Curves.easeInOutSine,
                      )
                      // Slow downward drift + reset (the "fall")
                      .moveY(
                        begin: -20 * sf,
                        end: 20 * sf,
                        duration: 6.seconds,
                        curve: Curves.easeInOut,
                      ),
                ),
              ),
            ),
          ),
        // ── Layer 4: Main menu content ───────────────────────────────
        widget.child,
      ],
    );
  }

  /// Pull vortex colors from the active theme so it always harmonizes.
  List<Color> _vortexColors(ThemeFlair flair) {
    return [
      flair.primary.withValues(alpha: 0.5),
      flair.secondary.withValues(alpha: 0.4),
      flair.glowPrimary.withValues(alpha: 0.3),
      const Color(0xFF4527A0).withValues(alpha: 0.35), // deep purple base
      flair.primary.withValues(alpha: 0.25),
    ];
  }
}

// =============================================================================
// VortexPainter — rotating logarithmic spiral arms with radial gradient hole
// =============================================================================

class _VortexPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;

  const _VortexPainter({required this.progress, required this.colors});

  static const _armCount = 6;
  static const _turns = 3.0;
  static const _steps = 60;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.max(size.width, size.height) * 0.75;
    final rotation = progress * 2 * math.pi;

    // ── Background: radial gradient "hole" ──────────────────────────
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        colors: [
          Colors.black.withValues(alpha: 0.5),
          colors.first.withValues(alpha: 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));
    canvas.drawRect(Offset.zero & size, bgPaint);

    // ── Spiral arms ─────────────────────────────────────────────────
    for (var arm = 0; arm < _armCount; arm++) {
      final armOffset = (arm / _armCount) * 2 * math.pi;
      final path = Path();
      for (var i = 0; i <= _steps; i++) {
        final t = i / _steps;
        // Logarithmic spiral: r grows exponentially with theta
        final theta = t * _turns * 2 * math.pi + armOffset + rotation;
        final r = t * maxRadius;
        final x = center.dx + r * math.cos(theta);
        final y = center.dy + r * math.sin(theta);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      // Fade alpha based on arm index for depth variation
      final color = colors[arm % colors.length];
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawPath(path, paint);
    }

    // ── Inner glow ring — the "portal edge" ─────────────────────────
    final ringPaint = Paint()
      ..color = colors.first.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, maxRadius * 0.12, ringPaint);
  }

  @override
  bool shouldRepaint(_VortexPainter old) => old.progress != progress;
}
