import '../theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/codex_entry.dart';
import '../services/app_theme.dart';
import '../services/goop_talk_engine.dart';
import '../widgets/active_run/bottom_back_bar.dart';
import '../utils/asset_paths.dart' show npcIdleGifPath;
import '../utils/responsive.dart';

/// Full-page view for a single Codex entry — large icon, name, category,
/// description, and wiki link.
class CodexDetailScreen extends StatelessWidget {
  final CodexEntry entry;
  final CodexSection section;

  const CodexDetailScreen({
    super.key,
    required this.entry,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final assetPath = codexAssetPath(section, entry.icon);
    // For NPC entries, prefer the animated idle GIF if available.
    final idleGif =
        section == CodexSection.npcs ? npcIdleGifPath(entry.name) : '';
    final heroImgPath = idleGif.isNotEmpty ? idleGif : assetPath;

    return Scaffold(
      backgroundColor: Colors.transparent,
      // Persistent bottom back bar (task 17 sweep) — replaces the
      // inline "Back to Codex" TextButton in the scroll content.
      bottomNavigationBar: const BottomBackBar(label: 'Back to Codex'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: GoopText(
          entry.name.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            fontSize: 15 * Responsive.factor(context),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Compact hero icon + badges in a row
                  Row(
                    children: [
                      // Icon — 80x80, compact
                      Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: flair.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: flair.primary.withValues(alpha: 0.3),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: flair.primary.withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child:
                                heroImgPath.isNotEmpty
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(9),
                                      child: Image.asset(
                                        heroImgPath,
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.none,
                                        cacheWidth: 160,
                                        cacheHeight: 160,
                                        errorBuilder:
                                            (_, _, _) => Icon(
                                              Icons.widgets,
                                              size: 32,
                                              color: flair.primary.withValues(
                                                alpha: 0.5,
                                              ),
                                            ),
                                      ),
                                    )
                                    : Icon(
                                      Icons.widgets,
                                      size: 32,
                                      color: flair.primary.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                          )
                          .animate()
                          .fadeIn(duration: 250.ms)
                          .scale(
                            begin: const Offset(0.92, 0.92),
                            end: const Offset(1.0, 1.0),
                            duration: 250.ms,
                          ),
                      const SizedBox(width: 14),
                      // Category + location badges stacked
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.start,
                          children: [
                            if (entry.category.isNotEmpty)
                              _badge(
                                flair,
                                entry.category.toUpperCase(),
                                accent: flair.primary,
                              ),
                            if (entry.game != null && entry.game!.isNotEmpty)
                              _badge(
                                flair,
                                entry.game!,
                                accent: CodexColors.game,
                                icon: Icons.videogame_asset_outlined,
                              ),
                            if (entry.health != null &&
                                entry.health!.isNotEmpty)
                              _badge(
                                flair,
                                'HP: ${entry.health}',
                                accent: CodexColors.health,
                                icon: Icons.favorite_outline,
                              ),
                            if (entry.location != null &&
                                entry.location!.isNotEmpty)
                              _badge(
                                flair,
                                entry.location!,
                                accent: CodexColors.location,
                                icon: Icons.place_outlined,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Description
                  if (entry.description.isNotEmpty) ...[
                    _sectionLabel(flair, 'DESCRIPTION'),
                    const SizedBox(height: 6),
                    _infoCard(
                      flair,
                      child: GoopText(
                        entry.description,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],

                  // Ammonomicon (bosses only)
                  if (entry.ammonomicon != null &&
                      entry.ammonomicon!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _sectionLabel(
                      flair,
                      'AMMONOMICON',
                      icon: Icons.menu_book_rounded,
                    ),
                    const SizedBox(height: 6),
                    _infoCard(
                      flair,
                      accent: flair.secondary,
                      child: GoopText(
                        entry.ammonomicon!,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],

                  // Tips
                  if (entry.tips.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _sectionLabel(
                      flair,
                      'TIPS',
                      icon: Icons.lightbulb_outline_rounded,
                    ),
                    const SizedBox(height: 6),
                    _infoCard(
                      flair,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < entry.tips.length; i++) ...[
                            if (i > 0) const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.bolt_rounded,
                                    size: 12,
                                    color: flair.secondary.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GoopText(
                                    entry.tips[i],
                                    style: TextStyle(
                                      fontSize: FontSizes.labelMedium,
                                      height: 1.35,
                                      color: Colors.white.withValues(
                                        alpha: 0.75,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Wiki link — functional, launches external browser
                  if (entry.wikiUrl.isNotEmpty)
                    Center(
                      child: TextButton.icon(
                        onPressed: () async {
                          try {
                            final uri = Uri.parse(entry.wikiUrl);
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (e) {
                            debugPrint('[CodexDetail] url launch error: $e');
                          }
                        },
                        onLongPress: () {
                          Clipboard.setData(ClipboardData(text: entry.wikiUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: GoopText('URL copied'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.open_in_new,
                          size: 14,
                          color: flair.primary.withValues(alpha: 0.6),
                        ),
                        label: GoopText(
                          'View on wiki.gg',
                          style: TextStyle(
                            fontSize: 11,
                            color: flair.primary.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Persistent back lives in the bottom bar now — keep
                  // breathing room at the end of the scroll.
                  const SizedBox(height: 10),
                  const SizedBox.shrink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Themed section helpers ──────────────────────────────────────

  Widget _badge(
    ThemeFlair flair,
    String text, {
    required Color accent,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.all(Radii.md),
        border: Border.all(color: accent.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: accent.withValues(alpha: 0.8)),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: GoopText(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: FontSizes.labelSmall,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: accent.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(ThemeFlair flair, String text, {IconData? icon}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: flair.secondary.withValues(alpha: 0.8)),
          const SizedBox(width: 5),
        ],
        GoopText(
          text,
          style: TextStyle(
            fontSize: FontSizes.labelSmall,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: flair.secondary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _infoCard(ThemeFlair flair, {required Widget child, Color? accent}) {
    final border = accent ?? flair.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: flair.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border.withValues(alpha: 0.15), width: 1),
      ),
      child: child,
    );
  }
}
