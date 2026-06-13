import 'dart:async';
import 'package:flutter/material.dart';
import '../services/haptics.dart';
import '../services/app_theme.dart';

/// Current state of the dialogue playback lifecycle.
enum DialogueState {
  hidden,
  entering, // Phase 1: VFX smoke/dust burst
  typing,   // Phase 2: Dialogue container revealed + typewriter typing
  completed, // Phase 3: Dialogue completed and fully visible
}

/// A highly polished, retro 8-bit style animated dialogue engine with localized cadence delays
/// and custom pixel-art smoke/dust entrance effect.
class AnimatedChatBubble extends StatefulWidget {
  final String fullText;
  final DialogueState initialState;
  final int baseTickRateMs;
  final int punctuationDelayMs;
  final VoidCallback? onCompleted;
  final TextStyle? textStyle;
  final Color bubbleColor;
  final Color borderColor;
  final IconData? icon;
  final Color? iconColor;
  final double maxWidth;
  
  /// Global config override to bypass animations
  final bool enableAnimations;

  const AnimatedChatBubble({
    super.key,
    required this.fullText,
    this.initialState = DialogueState.entering,
    this.baseTickRateMs = 30,
    this.punctuationDelayMs = 150,
    this.onCompleted,
    this.textStyle,
    this.bubbleColor = const Color(0xFF1E1E22), // Deep Gungeon charcoal
    this.borderColor = const Color(0xFFE57373), // Gungeon amber/red tint
    this.icon,
    this.iconColor,
    this.maxWidth = 400,
    this.enableAnimations = true,
  });

  @override
  State<AnimatedChatBubble> createState() => _AnimatedChatBubbleState();
}

class _AnimatedChatBubbleState extends State<AnimatedChatBubble> with SingleTickerProviderStateMixin {
  late DialogueState _state;
  late AnimationController _vfxController;
  String _visibleText = '';
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    
    // Accessibility / Global override check
    if (!widget.enableAnimations) {
      _state = DialogueState.completed;
      _visibleText = widget.fullText;
    } else {
      _state = widget.initialState;
      if (_state == DialogueState.completed) {
        _visibleText = widget.fullText;
      }
    }

    _vfxController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // Swap state triggers exactly at the apex of Phase 1 (smoke covers bubble)
    _vfxController.addListener(() {
      if (_state == DialogueState.entering && _vfxController.value >= 0.65) {
        setState(() {
          _state = DialogueState.typing;
        });
        _startTypewriter();
      }
    });

    _vfxController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _vfxController.reset();
      }
    });

    if (_state == DialogueState.entering) {
      _vfxController.forward();
    } else if (_state == DialogueState.typing) {
      _startTypewriter();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _vfxController.dispose();
    super.dispose();
  }

  /// Start the custom cadence-aware typewriter typewriter loop
  void _startTypewriter() async {
    if (_isDisposed) return;

    int currentIndex = 0;
    _visibleText = '';

    while (currentIndex < widget.fullText.length) {
      if (_isDisposed || _state != DialogueState.typing) break;

      final char = widget.fullText[currentIndex];
      _visibleText += char;
      currentIndex++;

      final prefs = VisualPrefs.notifier.value;
      if (prefs.dialogueHapticsEnabled) {
        Haptics.light();
      }

      if (mounted) {
        setState(() {});
      }

      // Check current character for punctuation to apply custom localized delays
      int delayMs = prefs.dialogueTextSpeedMs;
      if (char == '.' || char == ',' || char == '!' || char == '?') {
        // Humanized breathing pause on punctuation proportional to base speed
        delayMs = prefs.dialogueTextSpeedMs > 0 
            ? (prefs.dialogueTextSpeedMs * 4).clamp(40, 400) 
            : 0;
      }

      if (delayMs > 0) {
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }

    if (mounted && !_isDisposed && _state == DialogueState.typing) {
      setState(() {
        _state = DialogueState.completed;
      });
      widget.onCompleted?.call();
    }
  }

  /// Skip the animation straight to completed text
  void _skipTypewriter() {
    if (_state == DialogueState.typing || _state == DialogueState.entering) {
      setState(() {
        _state = DialogueState.completed;
        _visibleText = widget.fullText;
      });
      _vfxController.stop();
      _vfxController.reset();
      widget.onCompleted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state == DialogueState.hidden) {
      return const SizedBox.shrink();
    }

    // Build standard high-density text style with Gungeon fallback fonts
    final effectiveTextStyle = widget.textStyle ?? const TextStyle(
      fontFamily: 'EnterTheGungeonBig',
      fontFamilyFallback: ['ThaleahFat', 'ArcadeClassic'],
      fontSize: 11,
      color: Colors.white,
      letterSpacing: 0.5,
    );

    return GestureDetector(
      onTap: _skipTypewriter,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Phase 1 Entrance VFX: Pixelated Smoke & Dust Bursts
            if (_state == DialogueState.entering)
              SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  painter: PixelSmokePainter(animationValue: _vfxController.value),
                ),
              ),

            // Phase 2 & 3 Dialog Bubble: Scale up and typewriter animation
            AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: (_state == DialogueState.entering) ? 0.0 : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.bubbleColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: widget.borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.84),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: widget.iconColor ?? widget.borderColor,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        _visibleText,
                        style: effectiveTextStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Painter drawing a 6-frame retro pixel-art Smoke & Dust burst.
/// Draws blocky square-pixel shapes in typical Gungeon dust colors for pure 8-bit aesthetic.
class PixelSmokePainter extends CustomPainter {
  final double animationValue;

  PixelSmokePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final Paint paint = Paint()..style = PaintingStyle.fill;

    // Define standard Gungeon smoke palette (Grey-Purple, Muted Lavender, Dusty Pink)
    final colors = [
      const Color(0xFF38383F), // Deep charcoal shadow
      const Color(0xFF6B6A78), // Dusty steel grey
      const Color(0xFF9B9AA8), // Light ash grey
      const Color(0xFFE2B4C0), // Smoke light reflection (Dusty pinkish)
    ];

    // Frame indices from 0 to 5 based on 250ms duration
    final int frame = (animationValue * 5).floor().clamp(0, 5);

    void drawPixelBlock(double x, double y, double blockSize, Color color) {
      paint.color = color;
      canvas.drawRect(
        Rect.fromLTWH(
          (x / blockSize).round() * blockSize,
          (y / blockSize).round() * blockSize,
          blockSize,
          blockSize,
        ),
        paint,
      );
    }

    // High fidelity custom frame shapes (represented as pixel coordinates)
    const double pxSize = 4.0; // The size of one "pixel block"

    // Helper offset triggers for concentric expansions
    if (frame == 0) {
      // Frame 0: Small starting spark
      drawPixelBlock(centerX, centerY, pxSize, colors[2]);
      drawPixelBlock(centerX - pxSize, centerY, pxSize, colors[1]);
      drawPixelBlock(centerX, centerY - pxSize, pxSize, colors[1]);
    } else if (frame == 1) {
      // Frame 1: Small cluster
      for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
          final color = (i == 0 && j == 0) ? colors[3] : colors[1];
          drawPixelBlock(centerX + i * pxSize, centerY + j * pxSize, pxSize, color);
        }
      }
    } else if (frame == 2) {
      // Frame 2: Expanding cloud
      // Central cloud
      for (double x = -2; x <= 2; x++) {
        for (double y = -2; y <= 2; y++) {
          if (x.abs() + y.abs() <= 3) {
            drawPixelBlock(centerX + x * pxSize, centerY + y * pxSize, pxSize, colors[1]);
          }
        }
      }
      // Detached small pixels
      drawPixelBlock(centerX - 4 * pxSize, centerY - 2 * pxSize, pxSize, colors[0]);
      drawPixelBlock(centerX + 4 * pxSize, centerY + 2 * pxSize, pxSize, colors[2]);
    } else if (frame == 3) {
      // Frame 3: Apex size (obscures origin)
      for (double x = -4; x <= 4; x++) {
        for (double y = -4; y <= 4; y++) {
          final dist = x.abs() + y.abs();
          if (dist <= 5) {
            final colIdx = (dist <= 2) ? 3 : (dist <= 4 ? 2 : 0);
            drawPixelBlock(centerX + x * pxSize, centerY + y * pxSize, pxSize, colors[colIdx]);
          }
        }
      }
      // Outward sparks
      drawPixelBlock(centerX - 6 * pxSize, centerY + 4 * pxSize, pxSize, colors[3]);
      drawPixelBlock(centerX + 6 * pxSize, centerY - 4 * pxSize, pxSize, colors[3]);
    } else if (frame == 4) {
      // Frame 4: Dispersing puff rings
      for (double x = -5; x <= 5; x++) {
        for (double y = -5; y <= 5; y++) {
          final dist = x.abs() + y.abs();
          // Leave the center empty/hollow to look like dispersing rings
          if (dist >= 3 && dist <= 6) {
            final colIdx = (dist == 3 || dist == 4) ? 1 : 0;
            drawPixelBlock(centerX + x * pxSize, centerY + y * pxSize, pxSize, colors[colIdx]);
          }
        }
      }
    } else if (frame == 5) {
      // Frame 5: Tiny dissipating ashes
      drawPixelBlock(centerX - 5 * pxSize, centerY - 5 * pxSize, pxSize, colors[0]);
      drawPixelBlock(centerX + 5 * pxSize, centerY - 3 * pxSize, pxSize, colors[0]);
      drawPixelBlock(centerX - 3 * pxSize, centerY + 5 * pxSize, pxSize, colors[0]);
      drawPixelBlock(centerX + 5 * pxSize, centerY + 5 * pxSize, pxSize, colors[0]);
    }
  }

  @override
  bool shouldRepaint(covariant PixelSmokePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
