import 'package:flutter/material.dart';

import '../../services/haptics.dart';
import '../../services/goop_talk_engine.dart';

/// An interactive horizontal meter for coolness or curse.
///
/// - Fills left-to-right with an animated gradient.
/// - Threshold tick at [threshold] (default 10 — Lord of the Jammed
///   for curse, max effective coolness).
/// - Below threshold: calm fill. At/above threshold: the meter
///   "overflows" — pulsing red glow + skull icon at the right edge.
/// - Tap or drag to set the value (calls [onChanged] with the new
///   value delta from [value]).
/// - Haptic feedback on threshold cross.
///
/// The meter scale is 0..[maxValue] (default 15). The threshold
/// marker is drawn at [threshold]/[maxValue] of the bar width.
class GungeonMeter extends StatefulWidget {
  final double value;
  final bool isCool;
  final Color color;
  final String label;
  final void Function(double delta) onDelta;
  final double threshold;
  final double maxValue;

  const GungeonMeter({
    super.key,
    required this.value,
    required this.isCool,
    required this.color,
    required this.label,
    required this.onDelta,
    this.threshold = 10.0,
    this.maxValue = 15.0,
  });

  @override
  State<GungeonMeter> createState() => _GungeonMeterState();
}

class _GungeonMeterState extends State<GungeonMeter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _wasOverThreshold = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _wasOverThreshold = widget.value >= widget.threshold;
    if (_wasOverThreshold) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(GungeonMeter old) {
    super.didUpdateWidget(old);
    final over = widget.value >= widget.threshold;
    if (over && !_wasOverThreshold) {
      // Just crossed the threshold — haptic + start pulsing
      Haptics.heavy();
      _pulse.repeat(reverse: true);
    } else if (!over && _wasOverThreshold) {
      // Dropped back below — stop pulsing
      _pulse.stop();
    }
    _wasOverThreshold = over;
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  double get _fillFraction => (widget.value / widget.maxValue).clamp(0.0, 1.0);
  double get _thresholdFraction =>
      (widget.threshold / widget.maxValue).clamp(0.0, 1.0);
  bool get _isOverThreshold => widget.value >= widget.threshold;

  /// Convert a local X position to a value and fire onDelta.
  void _handleTap(Offset localPosition, double barWidth) {
    final fraction = (localPosition.dx / barWidth).clamp(0.0, 1.0);
    final newValue = fraction * widget.maxValue;
    final delta = newValue - widget.value;
    if (delta.abs() > 0.01) {
      Haptics.selection();
      widget.onDelta(delta);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOver = _isOverThreshold;
    final accent = widget.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GoopText(
              widget.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: accent.withValues(alpha: 0.9),
                letterSpacing: 0.2,
              ),
            ),
            if (widget.isCool && widget.value >= widget.threshold)
              const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
          ],
        ),
        const SizedBox(height: 8),

        // The meter bar — custom painted + gesture detector
        LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            return GestureDetector(
              onPanDown: (d) => _handleTap(d.localPosition, barWidth),
              onPanUpdate: (d) => _handleTap(d.localPosition, barWidth),
              child: SizedBox(
                height: 28,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Custom-painted meter
                    RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, __) => CustomPaint(
                          size: Size(barWidth, 28),
                          painter: _MeterPainter(
                            fillFraction: _fillFraction,
                            thresholdFraction: _thresholdFraction,
                            isOverThreshold: isOver,
                            pulse: isOver ? _pulse.value : 0.0,
                            color: accent,
                            isCool: widget.isCool,
                          ),
                        ),
                      ),
                    ),

                    // Skull icon at right edge when overflowed (curse only)
                    if (!widget.isCool && isOver)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: AnimatedBuilder(
                          animation: _pulse,
                          builder: (_, __) => Transform.scale(
                            scale: 0.85 + _pulse.value * 0.15,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(2),
                              child: GoopText(
                                '☠',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.redAccent,
                                  shadows: [
                                    Shadow(
                                      color: Colors.redAccent,
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Value text overlay
                    Positioned.fill(
                      child: Center(
                        child: GoopText(
                          widget.value.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white.withValues(alpha: 0.85),
                            fontFamily: 'monospace',
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Scale labels
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _scaleLabel('0'),
              _scaleLabel('5'),
              _scaleLabel('10', highlight: true),
              _scaleLabel('15+', highlight: isOver),
            ],
          ),
        ),

        // Lord of the Jammed alert (curse only, at/above threshold)
        if (!widget.isCool && isOver) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent, width: 1.0),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.redAccent, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: GoopText(
                    'LORD OF THE JAMMED HAS SPAWNED!',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.redAccent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _scaleLabel(String text, {bool highlight = false}) {
    return GoopText(
      text,
      style: TextStyle(
        fontSize: 9,
        fontWeight: highlight ? FontWeight.w900 : FontWeight.w500,
        color: highlight
            ? (widget.isCool ? Colors.amber : Colors.redAccent)
            : Colors.white.withValues(alpha: 0.3),
        fontFamily: 'monospace',
      ),
    );
  }
}

/// The custom painter for the meter bar.
///
/// Draws:
/// - Background track (dark rounded rect).
/// - Fill gradient (left-to-right, color-tinted).
/// - Threshold tick (vertical line at threshold position).
/// - Overflow glow (pulsing red border when over threshold).
/// - Tick marks at 0, 5, 10, 15.
class _MeterPainter extends CustomPainter {
  final double fillFraction;
  final double thresholdFraction;
  final bool isOverThreshold;
  final double pulse;
  final Color color;
  final bool isCool;

  _MeterPainter({
    required this.fillFraction,
    required this.thresholdFraction,
    required this.isOverThreshold,
    required this.pulse,
    required this.color,
    required this.isCool,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    final width = size.width;
    final r = Radius.circular(height / 2);

    // --- Background track ---
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, r),
      bgPaint,
    );

    // --- Tick marks at 0, 5, 10, 15 ---
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (final tick in [0.0, 5.0 / 15.0, 10.0 / 15.0, 1.0]) {
      final x = tick * width;
      canvas.drawLine(
        Offset(x, height * 0.2),
        Offset(x, height * 0.8),
        tickPaint,
      );
    }

    // --- Fill ---
    final fillWidth = fillFraction * width;
    if (fillWidth > 1) {
      final fillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, fillWidth, height),
        r,
      );
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isOverThreshold
              ? [
                  color.withValues(alpha: 0.6),
                  color,
                  Colors.redAccent.withValues(alpha: 0.8),
                ]
              : [
                  color.withValues(alpha: 0.4),
                  color,
                ],
        ).createShader(Rect.fromLTWH(0, 0, fillWidth, height))
        ..style = PaintingStyle.fill;
      canvas.drawRRect(fillRect, fillPaint);

      // Shine highlight on top edge
      final shinePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, fillWidth, height * 0.35),
          Radius.circular(height / 3),
        ),
        shinePaint,
      );
    }

    // --- Threshold tick (prominent) ---
    final thresholdX = thresholdFraction * width;
    final thresholdPaint = Paint()
      ..color = (isCool ? Colors.amber : Colors.redAccent)
          .withValues(alpha: 0.7)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(thresholdX, 2),
      Offset(thresholdX, height - 2),
      thresholdPaint,
    );

    // --- Overflow glow (pulsing border) ---
    if (isOverThreshold) {
      final glowAlpha = 0.3 + pulse * 0.4;
      final glowPaint = Paint()
        ..color = Colors.redAccent.withValues(alpha: glowAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 + pulse * 1.0
        ..maskFilter = MaskFilter.blur(BlurStyle.outer, 4 + pulse * 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          r,
        ),
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_MeterPainter old) =>
      old.fillFraction != fillFraction ||
      old.pulse != pulse ||
      old.isOverThreshold != isOverThreshold;
}
