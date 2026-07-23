import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/run_provider.dart';
import '../../services/haptics.dart';

class SecretCatThroneOverlay extends StatelessWidget {
  const SecretCatThroneOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      final runProvider = Provider.of<RunProvider>(context);
      final hasThrone = runProvider.runState.allItemNames.contains("Cat Bullet King Throne");
      if (!hasThrone) return const SizedBox.shrink();

      return const Positioned.fill(
        child: IgnorePointer(
          child: CuriousCatStareWidget(),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}

class CuriousCatStareWidget extends StatefulWidget {
  const CuriousCatStareWidget({super.key});

  @override
  State<CuriousCatStareWidget> createState() => _CuriousCatStareWidgetState();
}

class _CuriousCatStareWidgetState extends State<CuriousCatStareWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  Timer? _triggerTimer;
  bool _isPeeking = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _triggerTimer = Timer.periodic(const Duration(seconds: 35), (timer) {
      if (mounted && !_isPeeking) {
        _triggerCatPeek();
      }
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && !_isPeeking) {
        _triggerCatPeek();
      }
    });
  }

  void _triggerCatPeek() async {
    _isPeeking = true;
    if (mounted) {
      Haptics.light();
      await _animController.forward();
    }
    await Future.delayed(const Duration(milliseconds: 4500));
    if (mounted) {
      Haptics.light();
      await _animController.reverse();
    }
    _isPeeking = false;
  }

  @override
  void dispose() {
    _triggerTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final double value = _animController.value;
        final double slideOffset = (1.0 - value) * 120.0;
        final double wiggleAngle = value > 0.95
            ? math.sin(DateTime.now().millisecondsSinceEpoch * 0.005) * 0.04
            : 0.0;

        return Stack(
          children: [
            Positioned(
              bottom: 40.0,
              right: -45.0 + slideOffset,
              width: 140.0,
              height: 140.0,
              child: Transform.rotate(
                angle: wiggleAngle,
                alignment: Alignment.bottomCenter,
                child: child,
              ),
            ),
          ],
        );
      },
      child: Image.asset(
        'assets/images/items/cat_bullet_king_throne.webp',
        filterQuality: FilterQuality.none,
        fit: BoxFit.contain,
      ),
    );
  }
}
