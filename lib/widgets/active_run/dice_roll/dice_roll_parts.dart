part of '../dice_roll.dart';

class DiceWidget extends StatefulWidget {
  final int value;
  final bool isRolling;
  final AnimationController infiniteController;
  final int index;
  final DiceStyle style;
  final VoidCallback? onTap;
  final GlobalKey? dieKey;

  const DiceWidget({
    super.key,
    required this.value,
    required this.isRolling,
    required this.infiniteController,
    required this.index,
    required this.style,
    required this.onTap,
    this.dieKey,
  });

  @override
  State<DiceWidget> createState() => DiceWidgetState();
}

class DiceWidgetState extends State<DiceWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _impactController;

  @override
  void initState() {
    super.initState();
    _impactController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _impactController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRolling && !widget.isRolling) {
      // Play sudden impact expand/pop animation on stop!
      _impactController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: widget.dieKey,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            widget.infiniteController,
            _impactController,
          ]),
          builder: (context, child) {
            final t = widget.infiniteController.value;
            final impact = _impactController.value;

            // Compute 3D rotation tumbling
            final rotX =
                widget.isRolling ? (t * (4 + widget.index * 2) * math.pi) : 0.0;
            final rotY =
                widget.isRolling ? (t * (3 + widget.index * 3) * math.pi) : 0.0;
            final rotZ =
                widget.isRolling ? (t * (2 + widget.index * 4) * math.pi) : 0.0;

            // Vertical floating/bobbing during roll to look organic
            final double bobY =
                widget.isRolling
                    ? (math.sin(t * 2 * math.pi + widget.index * 1.5) * 8.0)
                    : 0.0;

            // Rapid cycling face value while rolling
            final faceVal =
                widget.isRolling
                    ? ((widget.index + (t * 40).round()) % 6 + 1)
                    : widget.value;

            // Impact pop scale (up to 1.35x and bounces back quickly)
            final double scale =
                widget.isRolling
                    ? 1.0
                    : 1.0 + math.sin(impact * math.pi) * 0.35;

            return Transform(
              transform:
                  Matrix4.identity()
                    ..setEntry(3, 2, 0.0018) // 3D projection
                    ..translate(0.0, bobY)
                    ..scale(scale)
                    ..rotateX(rotX)
                    ..rotateY(rotY)
                    ..rotateZ(rotZ),
              alignment: Alignment.center,
              child: Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.style.bg,
                  borderRadius: BorderRadius.all(Radii.lg),
                  border: Border.all(
                    color: widget.style.border,
                    width: widget.isRolling ? 2.0 : 3.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.style.glow,
                      blurRadius: widget.isRolling ? 6 : 12,
                      spreadRadius: widget.isRolling ? 1 : 3,
                    ),
                  ],
                ),
                child: Text(
                  '$faceVal',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: widget.style.text,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class DialogParticle {
  double x, y;
  double vx, vy;
  Color color;
  double life; // 1.0 down to 0.0
  DialogParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    // ignore: unused_element_parameter
    this.life = 1.0,
  });
}

class DialogParticlePainter extends CustomPainter {
  final List<DialogParticle> particles;
  DialogParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      paint.color = p.color.withValues(alpha: p.life);
      canvas.drawCircle(Offset(p.x, p.y), 3.0 * p.life, paint);
    }
  }

  @override
  bool shouldRepaint(DialogParticlePainter old) => true;
}

class DiceStyle {
  final Color bg;
  final Color border;
  final Color text;
  final Color glow;
  const DiceStyle({
    required this.bg,
    required this.border,
    required this.text,
    required this.glow,
  });
}
