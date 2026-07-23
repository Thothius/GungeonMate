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
    extends State<AnimatedWallpaperBackground> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;
  int _videoInitToken = 0;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_hasError || controller == null) {
      return const SizedBox.shrink();
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
