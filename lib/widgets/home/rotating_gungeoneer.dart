import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../services/home_customization.dart';
import '../../utils/asset_paths.dart';
import 'vortex_config.dart';

/// A gungeoneer in-game sprite caught in the home-screen vortex, spinning
/// 360° on its own axis while descending through the vortex column then
/// floating back up.
///
/// **Vortex physics model (descent-ascent cycle):**
/// The vortex is a swirling column of energy at the very center of the
/// screen. The gungeoneer is suspended in it. The motion is a deliberate,
/// cinematic descent-ascent cycle:
///
///   1. **Descent** (default 30s) — the sprite starts at the top of the
///      vortex (nearest/largest) and falls to the bottom (farthest/
///      smallest). The fall accelerates (ease-in, like gravity in a
///      viscous medium). During descent the sprite spins faster
///      (tumbling through the vortex).
///
///   2. **Ascent** (default 25s) — the sprite floats from the bottom back
///      to the top. The rise decelerates (ease-out, like a bubble in
///      water). The spin slows to its base speed (gentle rotation).
///
///   3. **Repeat** — the cycle loops seamlessly. The sprite arrives at
///      the top just as the next descent begins.
///
/// All motion is always-forward — a single Stopwatch drives the elapsed
/// time, and all positions/rotations are computed from it. No controllers
/// reverse; the easing curves create the organic acceleration/deceleration.
///
/// All parameters are driven by [VortexConfig] — tweak there to adjust
/// the simulation without touching this widget.
///
/// **Slight blur:** the sprite is wrapped in [ImageFiltered] with a low
/// sigma blur (default 0.8). Per Flutter 2026 guidance, ImageFiltered is
/// dramatically cheaper than BackdropFilter for single-widget blur.
///
/// Purely decorative — wrapped in IgnorePointer by the caller.
class RotatingGungeoneer extends StatefulWidget {
  /// Base display size of the sprite (longest edge), in logical px.
  /// Overridden by [VortexConfig.gungeoneerSize] if a config is provided.
  final double size;

  /// Vortex configuration. Defaults to [VortexConfig.defaultConfig].
  final VortexConfig config;

  const RotatingGungeoneer({
    super.key,
    this.size = 220,
    this.config = VortexConfig.defaultConfig,
  });

  @override
  State<RotatingGungeoneer> createState() => _RotatingGungeoneerState();
}

class _RotatingGungeoneerState extends State<RotatingGungeoneer>
    with SingleTickerProviderStateMixin {
  /// Single repaint trigger. The actual motion is driven by [_clock]
  /// (elapsed time), not this controller — it just forces a repaint
  /// every frame so the sprite moves smoothly.
  late final AnimationController _repaint;

  /// Elapsed-time clock — drives all motion. Stable regardless of
  /// controller duration.
  final Stopwatch _clock = Stopwatch();

  final math.Random _rng = math.Random(42);
  int _currentIdx = 0;

  /// Tracks which cycle we're in so we can swap characters at the bottom
  /// (deepest point) of each descent.
  int _lastCycle = 0;

  VortexConfig get _cfg => widget.config;

  @override
  void initState() {
    super.initState();
    _repaint = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _clock.start();
  }

  @override
  void dispose() {
    _clock.stop();
    _repaint.dispose();
    super.dispose();
  }

  void _maybeSwap(double elapsed) {
    final cycle = _cfg.gungeoneerCycleDuration;
    final currentCycle = (elapsed / cycle).floor();
    // Swap when we enter a new cycle — this is the moment the sprite
    // is at the bottom (deepest/smallest), so the swap is least visible.
    if (currentCycle != _lastCycle) {
      _lastCycle = currentCycle;
      final count = context.read<RunProvider>().allGungeoneers.length;
      if (count > 1) {
        int next;
        do {
          next = _rng.nextInt(count);
        } while (next == _currentIdx);
        setState(() => _currentIdx = next);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HomeCustomization>(
      valueListenable: HomeCustomization.notifier,
      builder: (context, cust, _) {
        if (!cust.showGungeoneer) return const SizedBox.shrink();
        final gungeoneers = context.watch<RunProvider>().allGungeoneers;
        if (gungeoneers.isEmpty) return const SizedBox.shrink();

        final isRng = cust.gungeoneerName.isEmpty;
        final name = isRng
            ? gungeoneers[_currentIdx % gungeoneers.length].name
            : cust.gungeoneerName;

        return IgnorePointer(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedBuilder(
                animation: _repaint,
                builder: (context, _) {
                  final elapsed = _clock.elapsedMilliseconds / 1000.0;
                  _maybeSwap(elapsed);
                  return _buildVortexSprite(name, constraints, elapsed);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildVortexSprite(
      String name, BoxConstraints constraints, double elapsed) {
    final screenW = constraints.maxWidth;
    final screenH = constraints.maxHeight;
    final size = widget.size;
    final cfg = _cfg;
    final cx = screenW / 2;
    final cy = screenH / 2;

    // ── Depth: tied to vertical position (top=near/large, bottom=far/small) ──
    final depth = cfg.depthFromElapsed(elapsed);

    // ── Drift range: half the current bounding box ──
    final driftRange = cfg.orbitRadiusAt(depth, screenW);

    // ── Vertical position: descent-ascent cycle ──
    final vertical =
        cfg.verticalFromElapsed(elapsed, driftRange) *
        cfg.gungeoneerOrbitYCompression;

    // ── Horizontal sway: subtle drift ──
    final swayRange = driftRange * cfg.gungeoneerSwayFraction;
    final sway = cfg.swayFromElapsed(elapsed, swayRange);

    // ── Sprite's own 360° spin (rotateZ, 2D-safe) ──
    // Faster during descent (tumbling), slower during ascent.
    final spinAngle = cfg.spinFromElapsed(elapsed);

    // ── Scale and opacity from depth ──
    final scale = cfg.gungeoneerScaleAt(depth);
    final opacity = cfg.gungeoneerOpacityAt(depth);

    // ── Final position ──
    final posX = cx + sway;
    final posY = cy + vertical;

    return Stack(
      children: [
        Positioned(
          left: posX - size / 2,
          top: posY - size / 2,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..rotateZ(spinAngle)
              ..scale(scale),
            child: Opacity(
              opacity: opacity,
              // Slight blur via ImageFiltered — cheaper than BackdropFilter
              // for single-widget blur. sigma 0 = no blur.
              child: cfg.gungeoneerBlurSigma > 0
                  ? ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(
                        sigmaX: cfg.gungeoneerBlurSigma,
                        sigmaY: cfg.gungeoneerBlurSigma,
                      ),
                      child: _GungeoneerSprite(
                        key: ValueKey(name),
                        name: name,
                        size: size,
                      ),
                    )
                  : _GungeoneerSprite(
                      key: ValueKey(name),
                      name: name,
                      size: size,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Renders a single gungeoneer's in-game GIF sprite, falling back to the
/// static icon then to a person glyph. Adds a soft radial glow behind it
/// so the sprite reads against the vortex.
class _GungeoneerSprite extends StatelessWidget {
  final String name;
  final double size;

  const _GungeoneerSprite({
    super.key,
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final gif = gungeoneerGifPath(name);
    final icon = localGungeoneerIcon(name);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft purple-white glow halo behind the sprite.
          Container(
            width: size * 0.9,
            height: size * 0.9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFBCA0F8).withValues(alpha: 0.25),
                  const Color(0xFF9D5CDB).withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          _buildImage(gif, icon),
        ],
      ),
    );
  }

  Widget _buildImage(String gif, String icon) {
    if (gif.isNotEmpty) {
      return Image.asset(
        gif,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _iconOrFallback(icon),
      );
    }
    return _iconOrFallback(icon);
  }

  Widget _iconOrFallback(String icon) {
    if (icon.isNotEmpty) {
      return Image.asset(
        icon,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) => const _PersonFallback(),
      );
    }
    return const _PersonFallback();
  }
}

class _PersonFallback extends StatelessWidget {
  const _PersonFallback();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.person,
      size: 96,
      color: Colors.white.withValues(alpha: 0.7),
    );
  }
}
