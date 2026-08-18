import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// =============================================================================
// AmbientShaderLayer — Q3 Ambient Fragment Shaders (genius audit v0.0.7).
//
// Loads a Flutter FragmentProgram from a .frag asset, animates it via a
// repeating AnimationController, and renders it full-screen via
// CustomPaint + Paint.shader. Wrapped in RepaintBoundary (Q4 foundation)
// so only the shader layer repaints on each tick.
//
// Two shaders are available:
//   - digital_rain.frag  → purple Matrix-style falling glyph columns
//   - dark_neon_fog.frag → slow-churning purple-black fog
//
// The shader is loaded once (cached at class level) and the fragment
// shader instance is reused — only the uniforms (uTime, uResolution)
// are updated per frame. This is the cheapest possible GPU animation.
// =============================================================================

/// Which ambient shader to render.
enum AmbientShader {
  /// Purple Matrix-style falling glyph columns.
  digitalRain('assets/shaders/digital_rain.frag'),

  /// Slow-churning purple-black fog.
  darkNeonFog('assets/shaders/dark_neon_fog.frag');

  final String assetPath;
  const AmbientShader(this.assetPath);
}

/// Full-screen ambient shader background layer. Place behind content
/// in a Stack with IgnorePointer.
class AmbientShaderLayer extends StatefulWidget {
  final AmbientShader shader;

  const AmbientShaderLayer({
    super.key,
    required this.shader,
  });

  @override
  State<AmbientShaderLayer> createState() => _AmbientShaderLayerState();
}

class _AmbientShaderLayerState extends State<AmbientShaderLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Stopwatch _stopwatch = Stopwatch();
  ui.FragmentProgram? _program;
  bool _loadFailed = false;

  // Cache loaded programs so switching shaders doesn't reload from disk.
  static final Map<String, ui.FragmentProgram> _programCache = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _stopwatch.start();
    _loadProgram();
  }

  @override
  void didUpdateWidget(covariant AmbientShaderLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shader != widget.shader) {
      _loadProgram();
    }
  }

  Future<void> _loadProgram() async {
    final path = widget.shader.assetPath;
    if (_programCache.containsKey(path)) {
      setState(() {
        _program = _programCache[path];
        _loadFailed = false;
      });
      return;
    }
    try {
      final prog = await ui.FragmentProgram.fromAsset(path);
      _programCache[path] = prog;
      if (mounted) {
        setState(() {
          _program = prog;
          _loadFailed = false;
        });
      }
    } catch (e) {
      debugPrint('[AmbientShader] Failed to load $path: $e');
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadFailed || _program == null) {
      return const SizedBox.shrink();
    }
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => CustomPaint(
          painter: _ShaderPainter(
            shader: _program!.fragmentShader(),
            time: _stopwatch.elapsedMilliseconds / 1000.0,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _ShaderPainter — renders the fragment shader to the canvas.
// =============================================================================

class _ShaderPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;

  _ShaderPainter({required this.shader, required this.time});

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    shader.setFloat(0, size.width);   // uResolution.x
    shader.setFloat(1, size.height);  // uResolution.y
    shader.setFloat(2, time);         // uTime

    final paint = ui.Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_ShaderPainter old) => true;
}
