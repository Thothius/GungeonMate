import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AnimatedWallpaperBackground extends StatefulWidget {
  final String assetName;

  const AnimatedWallpaperBackground({
    super.key,
    required this.assetName,
  });

  @override
  State<AnimatedWallpaperBackground> createState() =>
      _AnimatedWallpaperBackgroundState();
}

class _AnimatedWallpaperBackgroundState
    extends State<AnimatedWallpaperBackground>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;
  int _videoInitToken = 0;
  late final AnimationController _fallbackCtrl;

  @override
  void initState() {
    super.initState();
    _fallbackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(AnimatedWallpaperBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetName != widget.assetName) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    _initialized = false;
    _hasError = false;
    final myToken = ++_videoInitToken;
    final oldController = _controller;
    if (oldController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await oldController.dispose();
      });
      _controller = null;
    }

    final path = 'assets/images/wallpapers/animated/${widget.assetName}';
    final controller = VideoPlayerController.asset(path);
    _controller = controller;

    try {
      await controller.initialize();
      if (myToken != _videoInitToken) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0.0);
      await controller.play();
      if (myToken != _videoInitToken) {
        await controller.dispose();
        return;
      }
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to initialize animated wallpaper video: $e');
      if (myToken == _videoInitToken && mounted) {
        setState(() {
          _hasError = true;
        });
      } else {
        await controller.dispose();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _fallbackCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    // Video failed (e.g. on Windows desktop where video_player is not
    // implemented) — fall back to an animated CustomPaint vortex.
    if (_hasError || controller == null) {
      return AnimatedBuilder(
        animation: _fallbackCtrl,
        builder: (_, __) => CustomPaint(
          painter: _VortexFallbackPainter(_fallbackCtrl.value),
          size: Size.infinite,
        ),
      );
    }

    if (!_initialized) {
      return const SizedBox.shrink();
    }

    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}

/// Animated vortex portal fallback for platforms where video_player is
/// unavailable (Windows desktop). Draws rotating concentric purple rings
/// with a radial glow center — visually consistent with the mp4 vortex.
class _VortexFallbackPainter extends CustomPainter {
  final double t;

  _VortexFallbackPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.max(size.width, size.height) * 0.7;

    // Radial glow background.
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [
          const Color(0xFF4A148C).withValues(alpha: 0.5),
          const Color(0xFF1A0F2E).withValues(alpha: 0.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxR));
    canvas.drawRect(Offset.zero & size, glowPaint);

    // Rotating concentric rings — the swirling portal.
    const ringCount = 12;
    for (int i = 0; i < ringCount; i++) {
      final progress = (i / ringCount + t) % 1.0;
      final radius = maxR * progress;
      if (radius < 5) continue;
      final alpha = (1.0 - progress) * 0.35;
      final hue = 270.0 + i * 8.0;
      canvas.drawOval(
        Rect.fromCenter(center: center, width: radius * 2, height: radius * 1.6),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 + (1.0 - progress) * 2
          ..color = HSLColor.fromAHSL(alpha, hue, 0.7, 0.5).toColor(),
      );
    }

    // Bright center.
    final corePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.15,
        colors: [
          const Color(0xFFCE93D8).withValues(alpha: 0.6),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxR * 0.15));
    canvas.drawRect(Offset.zero & size, corePaint);
  }

  @override
  bool shouldRepaint(_VortexFallbackPainter old) => old.t != t;
}
