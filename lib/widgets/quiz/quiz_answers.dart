import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/goop_talk_engine.dart';
import '../../theme/tokens.dart';

/// The six-option answer panel (A–F) for a quiz question.
///
/// Two columns × three rows of big tappable tiles with letter chips.
/// Once an answer is locked in, the correct tile highlights green, a
/// wrong pick flashes red, and the rest dim — that's the reveal.
class QuizAnswerGrid extends StatelessWidget {
  const QuizAnswerGrid({
    super.key,
    required this.options,
    required this.correctIndex,
    required this.accent,
    required this.onPick,
    this.pickedIndex,
  });

  /// Six option labels, exactly one matching the loot's real name.
  final List<String> options;
  final int correctIndex;
  final Color accent;
  final ValueChanged<int> onPick;

  /// Null until the player answers; afterwards input is locked.
  final int? pickedIndex;

  static const _letters = ['A', 'B', 'C', 'D', 'E', 'F'];

  @override
  Widget build(BuildContext context) {
    final locked = pickedIndex != null;
    // Uniform step-down when the longest option runs long — every tile
    // uses the same size so the grid stays visually consistent.
    final maxLen = options.fold(0, (m, o) => o.length > m ? o.length : m);
    final fontSize =
        FontSizes.labelMedium +
        1 -
        (maxLen > 26
            ? 2.5
            : maxLen > 18
            ? 1.25
            : 0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < 3; row++)
          Padding(
            padding: EdgeInsets.only(top: row == 0 ? 0 : Insets.sm),
            child: Row(
              children: [
                for (var col = 0; col < 2; col++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: col == 0 ? 0 : Insets.sm),
                      child: _AnswerTile(
                            letter: _letters[row * 2 + col],
                            label: options[row * 2 + col],
                            fontSize: fontSize,
                            accent: accent,
                            state: _stateFor(row * 2 + col, locked),
                            onTap: locked ? null : () => onPick(row * 2 + col),
                          )
                          .animate(
                            key: ValueKey('a${row * 2 + col}'),
                            delay: Duration(milliseconds: 60 * (row * 2 + col)),
                          )
                          .fadeIn(duration: 280.ms)
                          .slideY(begin: 0.3, end: 0, duration: 280.ms),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  _TileState _stateFor(int index, bool locked) {
    if (!locked) return _TileState.idle;
    if (index == correctIndex) return _TileState.correct;
    if (index == pickedIndex) return _TileState.wrong;
    return _TileState.dimmed;
  }
}

enum _TileState { idle, correct, wrong, dimmed }

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.letter,
    required this.label,
    required this.fontSize,
    required this.accent,
    required this.state,
    required this.onTap,
  });

  final String letter;
  final String label;
  final double fontSize;
  final Color accent;
  final _TileState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isCorrect = state == _TileState.correct;
    final isWrong = state == _TileState.wrong;
    final dimmed = state == _TileState.dimmed;

    final borderColor =
        isCorrect
            ? const Color(0xFF4CAF50)
            : isWrong
            ? const Color(0xFFE53935)
            : accent.withValues(alpha: dimmed ? 0.15 : 0.5);
    final fillTop =
        isCorrect
            ? const Color(0xFF4CAF50).withValues(alpha: 0.25)
            : isWrong
            ? const Color(0xFFE53935).withValues(alpha: 0.22)
            : accent.withValues(alpha: dimmed ? 0.03 : 0.10);
    final fillBottom =
        isCorrect
            ? const Color(0xFF4CAF50).withValues(alpha: 0.10)
            : isWrong
            ? const Color(0xFFE53935).withValues(alpha: 0.08)
            : accent.withValues(alpha: dimmed ? 0.01 : 0.03);

    return AnimatedOpacity(
      opacity: dimmed ? 0.35 : 1.0,
      duration: const Duration(milliseconds: 250),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: Radii.card,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [fillTop, fillBottom],
              ),
              borderRadius: Radii.card,
              border: Border.all(color: borderColor, width: 1.4),
              boxShadow:
                  isCorrect
                      ? [
                        BoxShadow(
                          color: const Color(
                            0xFF4CAF50,
                          ).withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        ),
                      ]
                      : null,
            ),
            child: Row(
              children: [
                const SizedBox(width: Insets.sm + 2),
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isCorrect
                            ? const Color(0xFF4CAF50)
                            : isWrong
                            ? const Color(0xFFE53935)
                            : accent.withValues(alpha: 0.22),
                    border: Border.all(color: borderColor, width: 1.2),
                  ),
                  child: GoopText(
                    letter,
                    style: TextStyle(
                      fontSize: FontSizes.bodyMedium,
                      fontWeight: FontWeight.w900,
                      color: isCorrect || isWrong ? Colors.white : accent,
                    ),
                  ),
                ),
                const SizedBox(width: Insets.sm),
                Expanded(
                  child: GoopText(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: Colors.white.withValues(
                        alpha: dimmed ? 0.6 : 0.95,
                      ),
                    ),
                  ),
                ),
                if (isCorrect)
                  const Padding(
                    padding: EdgeInsets.only(right: Insets.sm),
                    child: Icon(
                      Icons.check_rounded,
                      color: Color(0xFF4CAF50),
                      size: 20,
                    ),
                  ),
                if (isWrong)
                  const Padding(
                    padding: EdgeInsets.only(right: Insets.sm),
                    child: Icon(
                      Icons.close_rounded,
                      color: Color(0xFFE53935),
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
