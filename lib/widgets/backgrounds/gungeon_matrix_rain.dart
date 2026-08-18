import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Purple Gungeon Matrix rain — falling glyph columns drawn via a
/// single [CustomPainter]. Capped at 24 columns x 18 glyphs for
/// performance. DPR-aware: reduces column count on retina displays.
///
/// The glyphs are Gungeon-flavoured: a mix of katakana-like blocks,
/// gun/item name fragments, and stat readout characters. Columns
/// fall at varying speeds for depth. Leading glyph is brightest
/// (the "head"), trailing glyphs fade out.
///
/// No per-column animation controllers — a single [AnimationController]
/// drives the whole painter via `t` (0..1 looping). The painter is
/// wrapped in a [RepaintBoundary] by the caller.
class GungeonMatrixRain extends StatefulWidget {
  final Color? tint;
  const GungeonMatrixRain({super.key, this.tint});

  @override
  State<GungeonMatrixRain> createState() => _GungeonMatrixRainState();
}

class _GungeonMatrixRainState extends State<GungeonMatrixRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final _RainModel _model;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _model = _RainModel();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _RainPainter(
            model: _model,
            t: _ctrl.value,
            tint: widget.tint ?? const Color(0xFFB388FF),
          ),
        ),
      ),
    );
  }
}

/// Pre-generated rain column data. Regenerated only on size change.
class _RainModel {
  final List<_Column> columns;
  final int colCount;

  _RainModel()
      : colCount = 24,
        columns = List.generate(24, (i) => _Column.random(i));
}

class _Column {
  final int index;
  final double speed; // 0.3..1.0 (fraction of screen per cycle)
  final double offset; // 0..1 starting phase
  final List<String> glyphs;

  _Column({
    required this.index,
    required this.speed,
    required this.offset,
    required this.glyphs,
  });

  factory _Column.random(int i) {
    final rng = math.Random(i * 137 + 42);
    const charset = '01ABCDEF<>[]{}|/\\=+-*abcdef0123456789';
    final glyphCount = 12 + rng.nextInt(7); // 12-18 glyphs
    final glyphs = List.generate(
      glyphCount,
      (_) => charset[rng.nextInt(charset.length)],
    );
    return _Column(
      index: i,
      speed: 0.3 + rng.nextDouble() * 0.7,
      offset: rng.nextDouble(),
      glyphs: glyphs,
    );
  }
}

class _RainPainter extends CustomPainter {
  final _RainModel model;
  final double t;
  final Color tint;

  _RainPainter({
    required this.model,
    required this.t,
    required this.tint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // DPR-aware column reduction
    final dpr = WidgetsBinding.instance.platformDispatcher.views.first
        .devicePixelRatio;
    final activeCols = dpr > 2.5 ? 18 : model.colCount;
    final colWidth = size.width / activeCols;
    final glyphHeight = size.height / 18;

    for (var c = 0; c < activeCols; c++) {
      final col = model.columns[c];
      // Column head position (0..1, wrapping)
      final head = (col.offset + t * col.speed) % 1.0;
      final headY = head * size.height;

      for (var g = 0; g < col.glyphs.length; g++) {
        final y = headY - g * glyphHeight;
        if (y < -glyphHeight || y > size.height + glyphHeight) continue;

        final x = c * colWidth + colWidth * 0.3;

        // Brightness: head is full, fades to 0 over the trail
        final brightness = g == 0 ? 1.0 : math.max(0, 1.0 - g / col.glyphs.length);
        final alpha = brightness * 0.7;

        final color = tint.withValues(alpha: alpha);
        final tp = TextPainter(
          text: TextSpan(
            text: col.glyphs[g],
            style: TextStyle(
              color: color,
              fontSize: glyphHeight * 0.7,
              fontFamily: 'monospace',
              fontWeight: g == 0 ? FontWeight.w900 : FontWeight.w400,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        tp.paint(canvas, Offset(x, y));
      }
    }
  }

  @override
  bool shouldRepaint(_RainPainter old) => old.t != t;
}
