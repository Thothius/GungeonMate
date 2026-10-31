import '../../theme/tokens.dart';
import 'package:flutter/material.dart';
import '../../services/app_theme.dart';
import '../../services/goop_talk_engine.dart';

/// Functional one-paragraph description of an entity — `Item.effect` /
/// `Gun.notes`. Rendered near the top of the detail body as the primary
/// "what it does" readout, distinct from the richer wiki sections below.
class DescriptionBlock extends StatelessWidget {
  final String text;
  const DescriptionBlock({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return GoopText(
      text,
      style: TextStyle(
        fontSize: FontSizes.bodyMedium,
        height: 1.4,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
      ),
    );
  }
}

/// Ammonomicon flavour entry — the italic long-form description shown
/// next to an entity's Ammonomicon page in-game. Rendered as a labelled
/// card near the bottom of the detail body, above the wiki sections.
class AmmonomiconCard extends StatelessWidget {
  final String text;
  const AmmonomiconCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: flair.scaffold.withValues(alpha: 0.6),
        borderRadius: BorderRadius.all(Radii.md),
        border: Border.all(color: flair.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, size: 14, color: flair.secondary),
              const SizedBox(width: Insets.sm),
              GoopText(
                'AMMONOMICON ENTRY',
                style: TextStyle(
                  fontSize: FontSizes.labelSmall,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: flair.headlineStat,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          GoopText(
            text,
            style: TextStyle(
              fontSize: FontSizes.labelMedium,
              fontStyle: FontStyle.italic,
              height: 1.4,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
