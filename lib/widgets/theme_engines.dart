import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

// =============================================================================
// ENGINE 2: Edge Drip & Seep Engine
// =============================================================================

class EdgeDripWidget extends StatefulWidget {
  final Color color;
  final int dripCount;
  final double maxDripHeight;
  final Duration duration;
  final double viscosity; // 1.0 = standard, higher is slower

  const EdgeDripWidget({
    super.key,
    required this.color,
    this.dripCount = 4,
    this.maxDripHeight = 45.0,
    this.duration = const Duration(seconds: 10),
    this.viscosity = 1.0,
  });

  @override
  State<EdgeDripWidget> createState() => _EdgeDripWidgetState();
}

class _EdgeDripWidgetState extends State<EdgeDripWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _EdgeDripPainter(
            progress: _controller.value,
            color: widget.color,
            dripCount: widget.dripCount,
            maxDripHeight: widget.maxDripHeight,
            viscosity: widget.viscosity,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _EdgeDripPainter extends CustomPainter {
  final double progress;
  final Color color;
  final int dripCount;
  final double maxDripHeight;
  final double viscosity;

  _EdgeDripPainter({
    required this.progress,
    required this.color,
    required this.dripCount,
    required this.maxDripHeight,
    required this.viscosity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);

    final double segmentWidth = size.width / dripCount;

    for (int i = 0; i < dripCount; i++) {
      final double startX = i * segmentWidth;
      final double endX = (i + 1) * segmentWidth;
      final double midX = startX + segmentWidth / 2;

      // Calculate localized viscosity delay
      final double phase = (i / dripCount) * 0.5;
      final double adjustedProgress = ((progress * viscosity) + phase) % 1.0;

      double currentHeight;
      if (adjustedProgress < 0.2) {
        currentHeight = (adjustedProgress / 0.2) * (maxDripHeight * 0.15);
      } else if (adjustedProgress < 0.8) {
        currentHeight = maxDripHeight * 0.15 +
            ((adjustedProgress - 0.2) / 0.6) * (maxDripHeight * 0.85);
      } else {
        currentHeight = maxDripHeight * (1.0 - (adjustedProgress - 0.8) / 0.2);
      }

      final double bezierControlY = currentHeight * 1.4;

      path.lineTo(startX, 0);
      path.quadraticBezierTo(
        midX,
        bezierControlY,
        endX,
        0,
      );
    }

    path.lineTo(size.width, 0);
    path.lineTo(size.width, 4); // Small seeping header border
    path.lineTo(0, 4);
    path.close();

    canvas.drawPath(path, paint);

    // Draw localized splash droplets at the bottom of extended drips
    for (int i = 0; i < dripCount; i++) {
      final double startX = i * segmentWidth;
      final double midX = startX + segmentWidth / 2;
      final double phase = (i / dripCount) * 0.5;
      final double adjustedProgress = ((progress * viscosity) + phase) % 1.0;

      if (adjustedProgress > 0.4 && adjustedProgress < 0.85) {
        final double currentHeight = maxDripHeight * 0.15 +
            ((adjustedProgress - 0.2) / 0.6) * (maxDripHeight * 0.85);
        final double dripY = currentHeight * 0.95;
        final double dropAlpha = (1.0 - (adjustedProgress - 0.4) / 0.45).clamp(0.0, 1.0);

        final dropPaint = Paint()
          ..color = color.withValues(alpha: dropAlpha)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(midX, dripY + 4), 3.0, dropPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_EdgeDripPainter old) => old.progress != progress;
}

// =============================================================================
// ENGINE 3: Glint & Sheen Overlay
// =============================================================================

class GlintSheenOverlay extends StatefulWidget {
  final Widget child;
  final Color sheenColor;
  final Duration duration;
  final Duration interval;
  final double angle;

  const GlintSheenOverlay({
    super.key,
    required this.child,
    this.sheenColor = Colors.white,
    this.duration = const Duration(milliseconds: 1500),
    this.interval = const Duration(seconds: 6),
    this.angle = -math.pi / 4,
  });

  @override
  State<GlintSheenOverlay> createState() => _GlintSheenOverlayState();
}

class _GlintSheenOverlayState extends State<GlintSheenOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scheduleSheen();
  }

  void _scheduleSheen() {
    _timer = Timer.periodic(widget.interval, (timer) {
      if (mounted && !_controller.isAnimating) {
        _controller.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (!_controller.isAnimating) return widget.child;

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final double progress = _controller.value;
            // Map progress to scan across the bounds
            final double slideOffset = -1.0 + (progress * 3.0);

            return LinearGradient(
              begin: Alignment(slideOffset, -1.0),
              end: Alignment(slideOffset + 1.0, 1.0),
              colors: [
                const Color(0x00000000),
                widget.sheenColor.withValues(alpha: 0.15),
                widget.sheenColor.withValues(alpha: 0.75),
                widget.sheenColor.withValues(alpha: 0.15),
                const Color(0x00000000),
              ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

// =============================================================================
// ENGINE 4: Elastic Wobble Container
// =============================================================================

class ElasticWobbleContainer extends StatefulWidget {
  final Widget child;
  final double intensity;
  final double speed;
  final bool enabled;

  const ElasticWobbleContainer({
    super.key,
    required this.child,
    this.intensity = 0.08,
    this.speed = 1.0,
    this.enabled = true,
  });

  @override
  State<ElasticWobbleContainer> createState() => _ElasticWobbleContainerState();
}

class _ElasticWobbleContainerState extends State<ElasticWobbleContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * 2 * math.pi * widget.speed;

        // Apply custom matrix deformation
        final double skewX = math.sin(t) * widget.intensity * 0.04;
        final double skewY = math.cos(t * 1.3) * widget.intensity * 0.02;
        final double scaleX = 1.0 + math.sin(t * 2.0) * widget.intensity * 0.015;
        final double scaleY = 1.0 + math.cos(t * 2.0) * widget.intensity * 0.015;

        final matrix = Matrix4.identity()
          ..setEntry(0, 1, skewX)
          ..setEntry(1, 0, skewY)
          ..scale(scaleX, scaleY);

        return Transform(
          transform: matrix,
          alignment: Alignment.center,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// =============================================================================
// ENGINE 5: Scheduled Atmosphere Sequencer
// =============================================================================

class ScheduledAtmosphereSequencer extends StatefulWidget {
  final Widget child;
  final Duration interval;
  final Duration activeDuration;
  final Widget Function(BuildContext context, double animValue) sequenceBuilder;

  const ScheduledAtmosphereSequencer({
    super.key,
    required this.child,
    required this.interval,
    required this.activeDuration,
    required this.sequenceBuilder,
  });

  @override
  State<ScheduledAtmosphereSequencer> createState() =>
      _ScheduledAtmosphereSequencerState();
}

class _ScheduledAtmosphereSequencerState
    extends State<ScheduledAtmosphereSequencer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _scheduler;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.activeDuration,
    );
    _startScheduling();
  }

  void _startScheduling() {
    _scheduler = Timer.periodic(widget.interval, (timer) {
      if (mounted && !_controller.isAnimating) {
        _controller.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    _scheduler?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (!_controller.isAnimating && _controller.value == 0.0) {
              return const SizedBox.shrink();
            }
            return Positioned.fill(
              child: IgnorePointer(
                child: widget.sequenceBuilder(context, _controller.value),
              ),
            );
          },
        ),
      ],
    );
  }
}
