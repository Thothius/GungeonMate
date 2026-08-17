import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/codex_entry.dart';
import '../services/app_theme.dart';
import '../services/goop_talk_engine.dart';

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

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: GoopText(
          entry.name.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
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
                  child: assetPath.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.asset(
                            assetPath,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.none,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.widgets,
                              size: 32,
                              color: flair.primary.withValues(alpha: 0.5),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.widgets,
                          size: 32,
                          color: flair.primary.withValues(alpha: 0.5),
                        ),
                ).animate().fadeIn(duration: 250.ms).scale(
                      begin: const Offset(0.92, 0.92),
                      end: const Offset(1.0, 1.0),
                      duration: 250.ms,
                    ),
                const SizedBox(width: 14),
                // Category + location badges stacked
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (entry.category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: flair.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: flair.primary.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: GoopText(
                            entry.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: flair.secondary,
                            ),
                          ),
                        ),
                      if (entry.health != null && entry.health!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        GoopText(
                          'Base HP: ${entry.health}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: flair.secondary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                      if (entry.location != null && entry.location!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        GoopText(
                          'Location: ${entry.location}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
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
              _sectionLabel(flair, 'AMMONOMICON',
                  icon: Icons.menu_book_rounded),
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
              _sectionLabel(flair, 'TIPS', icon: Icons.lightbulb_outline_rounded),
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
                              color: flair.secondary.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GoopText(
                              entry.tips[i],
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: Colors.white.withValues(alpha: 0.75),
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
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } catch (e) { debugPrint('[CodexDetail] url launch error: $e'); }
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
                  icon: Icon(Icons.open_in_new,
                      size: 14, color: flair.primary.withValues(alpha: 0.6)),
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

            // Back button — quick nav back to codex list
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_rounded,
                    size: 18, color: flair.primary.withValues(alpha: 0.7)),
                label: GoopText(
                  'Back to Codex',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: flair.primary.withValues(alpha: 0.7),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: flair.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Themed section helpers ──────────────────────────────────────

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
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: flair.secondary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _infoCard(
    ThemeFlair flair, {
    required Widget child,
    Color? accent,
  }) {
    final border = accent ?? flair.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: flair.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: border.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
