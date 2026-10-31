part of '../rich_link_text.dart';

/// Renders a list of [RichBullet]s as a column of bullet lines (`•`),
/// with nested bullets indented one level deeper. Handles arbitrary depth
/// but in practice wiki content stops at depth 2.
class RichBulletList extends StatelessWidget {
  final List<RichBullet> bullets;
  final TextStyle? baseStyle;
  final EdgeInsetsGeometry padding;

  const RichBulletList({
    super.key,
    required this.bullets,
    this.baseStyle,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (bullets.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          bullets.length,
          (i) => _BulletLine(
            bullet: bullets[i],
            depth: 0,
            siblingIndex: i,
            siblingCount: bullets.length,
            baseStyle: baseStyle,
          ),
        ),
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  final RichBullet bullet;
  final int depth;
  final int siblingIndex;
  final int siblingCount;
  final TextStyle? baseStyle;
  const _BulletLine({
    required this.bullet,
    required this.depth,
    this.siblingIndex = 0,
    this.siblingCount = 0,
    this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Top-level bullets: themed glyph (✦ for Unicorn, — for Winchester,
    // • for Coolmaxing/default, · for the others).
    // Nested bullets stay neutral so the eye reads depth, not theme,
    // on indented quirks/exceptions.
    final isTop = depth == 0;
    final glyph =
        isTop
            ? ThemedBullet(index: siblingIndex, size: _glyphSize())
            : Icon(
              Icons.fiber_manual_record,
              size: 5,
              color: Skeuo.collapse(Colors.white).withValues(alpha: 0.6),
            );
    return Padding(
      padding: EdgeInsets.only(left: depth * 18.0, top: depth == 0 ? 6 : 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                // Wider gutter than the old 6×6 dot needed because some
                // themed glyphs (✦) sit visually larger than a Material
                // circle icon — keep the text column aligned across themes.
                padding: const EdgeInsets.only(top: 1, right: 8),
                child: SizedBox(width: 14, child: Center(child: glyph)),
              ),
              Expanded(
                child: RichLinkText(
                  tokens: bullet.tokens,
                  baseStyle: baseStyle,
                ),
              ),
            ],
          ),
          // Subtle divider between top-level bullets — gives the list
          // visual rhythm without heavy borders. Skipped on the last
          // item and on nested bullets.
          if (isTop && bullet.sub.isEmpty && siblingIndex < siblingCount - 1)
            Padding(
              padding: const EdgeInsets.only(left: 22, top: 6),
              child: Container(
                height: 0.5,
                color: Skeuo.collapse(Colors.white).withValues(alpha: 0.06),
              ),
            ),
          ...List.generate(bullet.sub.length, (i) {
            return _BulletLine(
              bullet: bullet.sub[i],
              depth: depth + 1,
              siblingIndex: i,
              siblingCount: bullet.sub.length,
              baseStyle: baseStyle,
            );
          }),
        ],
      ),
    );
  }

  double _glyphSize() {
    // Tuned per-glyph so ✦ doesn't tower over —. The flair's bulletGlyph
    // is read by ThemedBullet itself; here we just choose the rendered
    // point size based on which theme is active.
    final f = AppTheme.flair;
    switch (f.bulletGlyph) {
      case '✦':
        return 11;
      case '—':
        return 12;
      case '·':
        return 14;
      default:
        return 8;
    }
  }
}

/// Self-contained accordion-style section: bold header with count badge,
/// optional collapse-by-default for long lists. Used for Notes / Trivia /
/// Item Interactions / Effects on the detail screen.
class WikiSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<RichBullet> bullets;

  /// If [bullets].length exceeds this, the section starts collapsed.
  /// 0 disables collapsing (always expanded).
  final int collapseThreshold;

  const WikiSection({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.bullets,
    this.collapseThreshold = 4,
  });

  @override
  State<WikiSection> createState() => _WikiSectionState();
}

class _WikiSectionState extends State<WikiSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded =
        widget.collapseThreshold == 0 ||
        widget.bullets.length <= widget.collapseThreshold;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bullets.isEmpty) return const SizedBox.shrink();
    final canCollapse =
        widget.collapseThreshold > 0 &&
        widget.bullets.length > widget.collapseThreshold;
    final flair = AppTheme.flair;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: flair.card,
          borderRadius: BorderRadius.all(Radii.lg),
          border: Border.all(
            color: widget.iconColor.withValues(alpha: 0.18),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.iconColor.withValues(alpha: 0.05),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap:
                    canCollapse
                        ? () => setState(() => _expanded = !_expanded)
                        : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Insets.xs),
                  child: ThemedSectionTitle(
                    icon: widget.icon,
                    iconColor: widget.iconColor,
                    title: widget.title,
                    count: widget.bullets.length,
                    trailing:
                        canCollapse
                            ? Icon(
                              _expanded ? Icons.expand_less : Icons.expand_more,
                              size: 22,
                              color: Skeuo.collapse(Colors.white54),
                            )
                            : null,
                  ),
                ),
              ),
              if (_expanded) ...[
                const SizedBox(height: 6),
                RichBulletList(bullets: widget.bullets),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
