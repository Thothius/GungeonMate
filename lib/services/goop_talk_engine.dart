import 'dart:async';
import 'package:flutter/material.dart';
import 'app_theme.dart';

class GoopTalkEngine {
  // Map standard English alphabet to corresponding Goop Symbols
  static const Map<String, String> _goopCipher = {
    'a': '⏃', 'b': '⎎', 'c': '⎓', 'd': '⏁', 'e': '⟒', 
    'f': '⎎', 'g': '⎾', 'h': '⏂', 'i': '⟌', 'j': '⎲', 
    'k': '⎗', 'l': '⎾', 'm': '⏃', 'n': '⎐', 'o': '⎔', 
    'p': '⎏', 'q': '⍎', 'r': '⎄', 's': '⎩', 't': '⏁', 
    'u': '⎱', 'v': '⎾', 'w': '⍓', 'x': '⌺', 'y': '⎧', 'z': '⎿',
    ' ': '  ' // Keep spacing wide for alien vibes
  };

  /// Translates clean UI strings into Professor Goopton's hidden text
  static String translateToGoop(String input) {
    StringBuffer output = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      String char = input[i].toLowerCase();
      if (_goopCipher.containsKey(char)) {
        output.write(_goopCipher[char]);
      } else {
        output.write(input[i]); // Keep numbers/punctuation normal
      }
    }
    return output.toString();
  }
}

class GoopText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const GoopText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  State<GoopText> createState() => _GoopTextState();
}

class _GoopTextState extends State<GoopText> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  Timer? _spongeDelayTimer;
  bool _isTranslated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _evaluateState(instant: true);
    VisualPrefs.notifier.addListener(_onPrefsChanged);
  }

  @override
  void didUpdateWidget(covariant GoopText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _evaluateState(instant: true);
    }
  }

  @override
  void dispose() {
    VisualPrefs.notifier.removeListener(_onPrefsChanged);
    _spongeDelayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onPrefsChanged() {
    if (mounted) {
      _evaluateState(instant: false);
    }
  }

  void _evaluateState({required bool instant}) {
    final prefs = VisualPrefs.notifier.value;
    _spongeDelayTimer?.cancel();

    if (!prefs.isGoopianLanguage) {
      // If language is English, instantly go to fully translated
      _isTranslated = true;
      if (instant) {
        _controller.value = 1.0;
      } else {
        _controller.forward();
      }
      return;
    }

    if (prefs.spongeActive) {
      // Sponge is holding, always start alien, and after 1 second magically translate to English!
      if (instant) {
        _controller.value = 0.0;
        _isTranslated = false;
      }
      _spongeDelayTimer = Timer(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _isTranslated = true;
          });
          _controller.forward();
        }
      });
    } else {
      // Sponge is OFF, always stay Goopian! If it was previously translated, animate in reverse.
      _isTranslated = false;
      if (instant) {
        _controller.value = 0.0;
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double t = _animation.value; // 0 = Goopian, 1 = English
        
        // Character-by-character interpolation based on the animation value
        final original = widget.text;
        final goop = GoopTalkEngine.translateToGoop(original);

        String activeText;
        if (t == 1.0) {
          activeText = original;
        } else if (t == 0.0) {
          activeText = goop;
        } else {
          // Splice original and goop based on progress t
          final int thresholdIndex = (original.length * t).round().clamp(0, original.length);
          final left = original.substring(0, thresholdIndex);
          final right = goop.substring(
            (goop.length * t).round().clamp(0, goop.length),
            goop.length,
          );
          activeText = left + right;
        }

        return Text(
          activeText,
          style: widget.style,
          textAlign: widget.textAlign,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
        );
      },
    );
  }
}
