import 'package:flutter/material.dart';
import '../services/haptics.dart';
import '../services/goop_talk_engine.dart';

/// A collapsible section that hides spoiler content behind a warning
/// banner. Tapping the banner expands or collapses the content with a
/// smooth animation. Hides entirely when [content] is empty.
///
/// Used by the Gungeoneer detail screen to gate past story, past kill
/// details, unlock methods, and alternate costume information so the
/// player chooses when to reveal spoilers.
class SpoilerTag extends StatefulWidget {
  final String label;
  final Widget content;
  final IconData icon;

  const SpoilerTag({
    super.key,
    required this.label,
    required this.content,
    this.icon = Icons.warning_amber_rounded,
  });

  @override
  State<SpoilerTag> createState() => _SpoilerTagState();
}

class _SpoilerTagState extends State<SpoilerTag>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.amber.withValues(alpha: _expanded ? 0.5 : 0.25),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          // ── Banner ──
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                Haptics.selection();
                setState(() => _expanded = !_expanded);
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      widget.icon,
                      size: 18,
                      color: Colors.amber.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GoopText(
                        widget.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.amber.withValues(alpha: 0.9),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: Colors.amber.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── Expandable content ──
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                    child: widget.content,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
