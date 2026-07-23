import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_theme.dart';

class GoopTalkEngine {
  static const Map<String, String> _goopCipher = {
    'a': '⏃', 'b': '⎎', 'c': '⎓', 'd': '⏁', 'e': '⟒',
    'f': '⎎', 'g': '⎾', 'h': '⏂', 'i': '⟌', 'j': '⎲',
    'k': '⎗', 'l': '⎾', 'm': '⏃', 'n': '⎐', 'o': '⎔',
    'p': '⎏', 'q': '⍎', 'r': '⎄', 's': '⎩', 't': '⏁',
    'u': '⎱', 'v': '⎾', 'w': '⍓', 'x': '⌺', 'y': '⎧', 'z': '⎿',
    ' ': '  ',
  };

  static String translateToGoop(String input) {
    final out = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final ch = input[i].toLowerCase();
      out.write(_goopCipher[ch] ?? input[i]);
    }
    return out.toString();
  }
}

/// Singleton animation manager — one timer drives all GoopText widgets.
/// Replaces 762 per-widget AnimationControllers + VisualPrefs listeners.
class GoopAnimationManager {
  static final GoopAnimationManager instance = GoopAnimationManager._();
  GoopAnimationManager._() {
    VisualPrefs.notifier.addListener(_onPrefsChanged);
    _evaluateState(instant: true);
  }

  final ValueNotifier<double> progress = ValueNotifier(0.0);
  Timer? _animTimer;
  Timer? _spongeDelayTimer;
  double _target = 0.0;
  double _startValue = 0.0;
  DateTime _animStart = DateTime.now();

  static const _durationMs = 500;

  void _onPrefsChanged() => _evaluateState(instant: false);

  void _evaluateState({required bool instant}) {
    final prefs = VisualPrefs.notifier.value;
    _spongeDelayTimer?.cancel();

    if (!prefs.isGoopianLanguage) {
      _animateTo(1.0, instant: instant);
      return;
    }

    if (prefs.spongeActive) {
      _animateTo(0.0, instant: instant);
      _spongeDelayTimer = Timer(const Duration(milliseconds: 500), () {
        _animateTo(1.0, instant: false);
      });
    } else {
      _animateTo(0.0, instant: instant);
    }
  }

  void _animateTo(double target, {required bool instant}) {
    _animTimer?.cancel();
    if (instant || (progress.value - target).abs() < 0.001) {
      progress.value = target;
      return;
    }
    _startValue = progress.value;
    _target = target;
    _animStart = DateTime.now();
    _animTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final elapsed = DateTime.now().difference(_animStart).inMilliseconds;
      final rawT = (elapsed / _durationMs).clamp(0.0, 1.0);
      final eased = rawT >= 1.0 ? 1.0 : 1.0 - math.pow(2, -10 * rawT).toDouble();
      progress.value = _startValue + (_target - _startValue) * eased;
      if (rawT >= 1.0) {
        _animTimer?.cancel();
        progress.value = _target;
      }
    });
  }
}

class GoopText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  const GoopText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  });

  static const _scrambleSymbols = '⏃⎎⎓⏁⟒⎾⏂⟌⎲⎗⎐⎔⎏⍎⎄⎩⎱⍓⌺⎧⎿';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: GoopAnimationManager.instance.progress,
      builder: (context, t, _) {
        final original = text;

        String activeText;
        if (t == 1.0) {
          activeText = original;
        } else if (t == 0.0) {
          activeText = GoopTalkEngine.translateToGoop(original);
        } else {
          final waveFront = (original.length * t).round();
          const scrambleWindow = 5;
          final phase = (t * 300).toInt();

          final buf = StringBuffer();
          for (int i = 0; i < original.length; i++) {
            final ch = original[i];
            final lower = ch.toLowerCase();
            final isAlpha = lower.codeUnitAt(0) >= 97 && lower.codeUnitAt(0) <= 122;

            if (i < waveFront - scrambleWindow) {
              buf.write(ch);
            } else if (i >= waveFront) {
              buf.write(GoopTalkEngine._goopCipher[lower] ?? ch);
            } else if (isAlpha) {
              buf.write(_scrambleSymbols[(i * 17 + phase) % _scrambleSymbols.length]);
            } else {
              buf.write(ch);
            }
          }
          activeText = buf.toString();
        }

        return Text(
          activeText,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
          softWrap: softWrap,
        );
      },
    );
  }
}
