import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../services/home_customization.dart';
import '../../services/haptics.dart';
import '../../utils/asset_paths.dart';

/// A gungeoneer in-game sprite rotating in the center of the home-screen
/// vortex. The model "falls forever": it slowly spins while a depth pulse
/// makes it shrink (going deeper) then grow back (floating out) on an
/// organic, slightly randomized loop. When no specific gungeoneer is
/// chosen, it cycles through a random character every few seconds.
///
/// Purely decorative — wrapped in IgnorePointer by the caller, but taps
/// are absorbed here too so the sprite never blocks the buttons beneath.
class RotatingGungeoneer extends StatefulWidget {
  /// Base display size of the sprite (longest edge), in logical px.
  final double size;

  const RotatingGungeoneer({super.key, this.size = 220});

  @override
  State<RotatingGungeoneer> createState() => _RotatingGungeoneerState();
}

class _RotatingGungeoneerState extends State<RotatingGungeoneer>
    with TickerProviderStateMixin {
  late final AnimationController _spin;
  late final AnimationController _depth;
  final math.Random _rng = math.Random(42);

  // RNG character cycling.
  Timer? _rngTimer;
  int _currentIdx = 0;

  @override
  void initState() {
    super.initState();
    // Slow continuous rotation (~24s per revolution).
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
    // Depth pulse: deeper-then-out breathing, ~7s cycle.
    _depth = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
    // RNG character swap on a randomized 4–8s cadence.
    _scheduleNextSwap(0);
  }

  void _scheduleNextSwap(int count) {
    _rngTimer?.cancel();
    if (count == 0) {
      _rngTimer = Timer(const Duration(milliseconds: 300), _doSwap);
      return;
    }
    final delay = Duration(seconds: 4 + _rng.nextInt(5));
    _rngTimer = Timer(delay, _doSwap);
  }

  void _doSwap() {
    if (!mounted) return;
    setState(() {
      // Advance to a different index than the current one.
      final count = context.read<RunProvider>().allGungeoneers.length;
      if (count > 1) {
        int next;
        do {
          next = _rng.nextInt(count);
        } while (next == _currentIdx);
        _currentIdx = next;
      }
    });
    Haptics.selection();
    _scheduleNextSwap(1);
  }

  @override
  void dispose() {
    _rngTimer?.cancel();
    _spin.dispose();
    _depth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HomeCustomization>(
      valueListenable: HomeCustomization.notifier,
      builder: (context, cust, _) {
        if (!cust.showGungeoneer) return const SizedBox.shrink();
        final gungeoneers = context.watch<RunProvider>().allGungeoneers;
        if (gungeoneers.isEmpty) return const SizedBox.shrink();

        // Resolve the active name. Fixed name wins; otherwise RNG cycle.
        final isRng = cust.gungeoneerName.isEmpty;
        final name = isRng
            ? gungeoneers[_currentIdx % gungeoneers.length].name
            : cust.gungeoneerName;

        return IgnorePointer(
          child: AnimatedBuilder(
            animation: Listenable.merge([_spin, _depth]),
            builder: (context, _) {
              // Depth: 0.0 = far/small (deep), 1.0 = near/large (out).
              // Ease the depth curve so the "float out" lingers.
              final d = Curves.easeInOutSine.transform(_depth.value);
              // Organic jitter: combine two slow sines driven by spin
              // progress for an RNG-assisted, non-mechanical drift.
              final t = _spin.value * 2 * math.pi;
              final jitter =
                  0.06 * math.sin(t * 1.3) + 0.04 * math.sin(t * 2.7 + 1.1);
              final scale = 0.62 + 0.38 * d + jitter;
              // Slow yaw rotation; tilt slightly with depth for parallax.
              final yaw = _spin.value * 2 * math.pi;
              final tilt = 0.12 * math.sin(t * 0.8);
              return Center(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0012) // perspective
                    ..rotateY(yaw)
                    ..rotateX(tilt)
                    ..scale(scale.clamp(0.3, 1.2)),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _GungeoneerSprite(
                      key: ValueKey(name),
                      name: name,
                      size: widget.size,
                      // Fade opacity with depth so "going deeper" dims it.
                      opacity: 0.55 + 0.45 * d,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Renders a single gungeoneer's in-game GIF sprite, falling back to the
/// static icon then to a person glyph. Adds a soft radial glow behind it
/// so the sprite reads against the vortex.
class _GungeoneerSprite extends StatelessWidget {
  final String name;
  final double size;
  final double opacity;

  const _GungeoneerSprite({
    super.key,
    required this.name,
    required this.size,
    required this.opacity,
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
                  const Color(0xFFBCA0F8).withValues(alpha: 0.28 * opacity),
                  const Color(0xFF9D5CDB).withValues(alpha: 0.10 * opacity),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: _buildImage(gif, icon),
          ),
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
