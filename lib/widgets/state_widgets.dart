import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A shimmer-style skeleton placeholder for loading content.
///
/// Use this instead of a bare `CircularProgressIndicator` for
/// content-shaped loading states. The skeleton matches the final
/// layout's shape, giving users a preview of what's coming rather
/// than a generic spinner.
///
/// Example:
/// ```dart
/// if (loading) SkeletonLoader.lines(3)
/// else Content()
/// ```
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = const BorderRadius.all(Radii.sm),
  });

  /// A stack of [count] skeleton lines, simulating text content.
  const SkeletonLoader.lines(int count, {super.key})
      : width = double.infinity,
        height = 16 * count * 1.5,
        borderRadius = const BorderRadius.all(Radii.sm);

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flair = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = _c.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            color: Color.lerp(
              flair.surfaceContainerHighest.withValues(alpha: 0.3),
              flair.surfaceContainerHighest.withValues(alpha: 0.6),
              t,
            ),
          ),
        );
      },
    );
  }
}

/// A shared empty-state widget with an icon, message, and optional action.
///
/// Use this when a screen or section has no content to show — never
/// leave a blank screen. The design follows the Gungeon aesthetic:
/// dark surface, themed icon, concise message, and a clear next action.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Optional Gungeon-flavored flavor line under the message
  /// ("no loot here, wanderer") — italic, dimmer than the message.
  final String? flavor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.flavor,
  });

  @override
  Widget build(BuildContext context) {
    final flair = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing accent ring — same chrome treatment as the quiz
            // tier badges so empties feel themed, not broken.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: flair.primary.withValues(alpha: 0.08),
                border: Border.all(
                    color: flair.primary.withValues(alpha: 0.35),
                    width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: flair.primary.withValues(alpha: 0.18),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Icon(icon,
                  size: 36,
                  color: flair.primary.withValues(alpha: 0.65)),
            ),
            const SizedBox(height: Insets.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: flair.onSurface.withValues(alpha: 0.7),
                  ),
            ),
            if (flavor != null) ...[
              const SizedBox(height: 6),
              Text(
                flavor!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: flair.onSurface.withValues(alpha: 0.35),
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: Insets.xl),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A shared error-state widget with an icon, message, and retry action.
///
/// Never show raw exception text to users. Use this widget with a
/// human-friendly message and a retry button.
class ErrorState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const ErrorState({
    super.key,
    this.icon = Icons.error_outline,
    required this.message,
    this.retryLabel = 'Retry',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final flair = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: flair.error.withValues(alpha: 0.6)),
            const SizedBox(height: Insets.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: flair.onSurface.withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(height: Insets.xl),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
