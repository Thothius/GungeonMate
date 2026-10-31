import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import 'skeuo_tokens.dart';

/// Neo-Skeuo page backdrop — warm cream paper, faint ink speckle,
/// soft pencil vignette, and optional spec-sheet chrome (crosshatch
/// corner squares + margin ruler ticks, like the reference poster).
///
/// Use [posterChrome] on gallery/spec screens; leave it off for
/// ordinary app screens so the paper stays quiet.
class SkeuoPaperBackdrop extends StatelessWidget {
  final bool posterChrome;
  final bool vignette;

  const SkeuoPaperBackdrop({
    super.key,
    this.posterChrome = false,
    this.vignette = true,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Skeuo.paper),
          const RepaintBoundary(
            child: CustomPaint(painter: SkeuoGrainPainter()),
          ),
          if (vignette)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.3,
                  colors: [
                    Colors.transparent,
                    Color(0x0A1F1B16),
                    Color(0x241F1B16),
                  ],
                  stops: [0.0, 0.62, 1.0],
                ),
              ),
            ),
          if (posterChrome)
            const RepaintBoundary(
              child: CustomPaint(painter: _PosterChromePainter()),
            ),
        ],
      ),
    );
  }
}

/// Deterministic ink-speckle paper grain — seeded so it never shimmers
/// between repaints. Painted once behind a RepaintBoundary.
class SkeuoGrainPainter extends CustomPainter {
  const SkeuoGrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final rnd = math.Random(1907);
    final speck =
        Paint()
          ..color = Skeuo.ink.withValues(alpha: 0.05)
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round;
    final pts = <Offset>[
      for (var i = 0; i < 420; i++)
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
    ];
    canvas.drawPoints(PointMode.points, pts, speck);
    // A few slightly darker flecks give the paper real tooth.
    speck
      ..color = Skeuo.ink.withValues(alpha: 0.09)
      ..strokeWidth = 1.6;
    final flecks = <Offset>[
      for (var i = 0; i < 90; i++)
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
    ];
    canvas.drawPoints(PointMode.points, flecks, speck);
    // Faint horizontal "laid paper" fibers.
    speck
      ..color = Skeuo.ink.withValues(alpha: 0.025)
      ..strokeWidth = 0.6;
    for (var i = 0; i < 28; i++) {
      final y = rnd.nextDouble() * size.height;
      final x = rnd.nextDouble() * size.width * 0.6;
      final len = 30 + rnd.nextDouble() * 90;
      canvas.drawLine(Offset(x, y), Offset(x + len, y + 1), speck);
    }
  }

  @override
  bool shouldRepaint(SkeuoGrainPainter old) => false;
}

/// Spec-sheet chrome — crosshatch squares in the four corners and
/// tick marks marching down the left + top margins, exactly like the
/// reference kit poster's printed rulers.
class _PosterChromePainter extends CustomPainter {
  const _PosterChromePainter();

  static const double _margin = 14;
  static const double _corner = 18;
  static const double _tick = 64; // every 64 logical px, like the ref

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final faint =
        Paint()
          ..color = Skeuo.ink.withValues(alpha: 0.45)
          ..strokeWidth = 0.8
          ..isAntiAlias = true;

    // Crosshatch corner squares.
    for (final c in [
      Offset(_margin, _margin),
      Offset(size.width - _margin - _corner, _margin),
      Offset(_margin, size.height - _margin - _corner),
      Offset(size.width - _margin - _corner, size.height - _margin - _corner),
    ]) {
      final r = Rect.fromLTWH(c.dx, c.dy, _corner, _corner);
      canvas.drawRect(r, faint);
      canvas.save();
      canvas.clipRect(r);
      for (var x = r.left - r.height; x < r.right; x += 3) {
        canvas.drawLine(
          Offset(x, r.top),
          Offset(x + r.height, r.bottom),
          faint,
        );
        canvas.drawLine(
          Offset(x, r.bottom),
          Offset(x + r.height, r.top),
          faint,
        );
      }
      canvas.restore();
    }

    // Margin rules.
    final topRule = Offset(size.width - _margin, _margin + _corner / 2);
    canvas.drawLine(
      Offset(_margin + _corner + 8, _margin + _corner / 2),
      topRule,
      faint,
    );
    final leftRuleTop = _margin + _corner + 8;
    canvas.drawLine(
      Offset(_margin + _corner / 2, leftRuleTop),
      Offset(_margin + _corner / 2, size.height - _margin - _corner - 8),
      faint,
    );

    // Ruler ticks + numbers along the top margin.
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final tickTop = _margin + _corner / 2;
    for (
      var x = _margin + _corner + 8 + _tick;
      x < size.width - _margin - _corner - 8;
      x += _tick
    ) {
      canvas.drawLine(Offset(x, tickTop - 5), Offset(x, tickTop + 5), faint);
    }
    // Ruler ticks + numbers down the left margin.
    var label = 4;
    for (
      var y = _margin + _corner + 8 + _tick;
      y < size.height - _margin - _corner - 8;
      y += _tick
    ) {
      canvas.drawLine(Offset(tickTop - 5, y), Offset(tickTop + 5, y), faint);
      textPainter.text = TextSpan(
        text: '$label',
        style: const TextStyle(
          fontSize: 9,
          color: Skeuo.ink,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(2, y - 4));
      label += 8;
    }
    // Top-margin numbers echo the kit's numbering (32-style counts).
    textPainter.text = const TextSpan(
      text: 'NEO-SKEUO',
      style: TextStyle(
        fontSize: 9,
        letterSpacing: 1.5,
        color: Skeuo.ink,
        fontWeight: FontWeight.w600,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width - _margin - _corner - 8 - textPainter.width, 2),
    );
  }

  @override
  bool shouldRepaint(_PosterChromePainter old) => false;
}
