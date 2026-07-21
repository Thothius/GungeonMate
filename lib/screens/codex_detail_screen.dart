import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/codex_entry.dart';
import '../services/app_theme.dart';

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
        title: Text(
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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero icon
            Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: flair.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: flair.primary.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: assetPath.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          assetPath,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.none,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.widgets,
                            size: 56,
                            color: flair.primary.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    : Icon(
                        Icons.widgets,
                        size: 56,
                        color: flair.primary.withValues(alpha: 0.5),
                      ),
              ),
            ).animate().fadeIn(duration: 300.ms).scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.0, 1.0),
                  duration: 300.ms,
                ),

            const SizedBox(height: 20),

            // Category badge
            if (entry.category.isNotEmpty)
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: flair.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: flair.primary.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    entry.category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: flair.secondary,
                    ),
                  ),
                ),
              ),

            // Location badge (for traps)
            if (entry.location != null && entry.location!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Location: ${entry.location}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Description
            if (entry.description.isNotEmpty) ...[
              Text(
                'DESCRIPTION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: flair.secondary.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: flair.primary.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  entry.description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Wiki link
            if (entry.wikiUrl.isNotEmpty)
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    // Wiki link is for reference only — no in-app browser.
                    // Users can long-press to copy if needed.
                  },
                  icon: Icon(Icons.link,
                      size: 16, color: flair.primary.withValues(alpha: 0.6)),
                  label: Text(
                    'Source: wiki.gg',
                    style: TextStyle(
                      fontSize: 11,
                      color: flair.primary.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
