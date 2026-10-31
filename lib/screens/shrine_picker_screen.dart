import '../theme/tokens.dart';
import 'package:flutter/material.dart';
import '../services/app_theme.dart';
import '../services/goop_talk_engine.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

import '../providers/run_provider.dart';
import '../models/shrine.dart';
import '../services/haptics.dart';
import 'package:url_launcher/url_launcher.dart';
part 'shrine_picker/shrine_sheet.dart';

/// Resolves the correct shrine icon asset, applying bundled art overrides
/// (updated Ammo/Angel shrine graphics) over the default data-driven icon.
String resolveShrineIcon(String shrineName, String defaultIcon) {
  switch (shrineName.toLowerCase()) {
    case 'ammo':
    case 'ammo shrine':
      return 'assets/images/shrines/Ammo_Shrine.webp';
    case 'fallen angel':
    case 'fallen angel shrine':
    case 'angel':
    case 'angel shrine':
      return 'assets/images/shrines/Angel_Shrine.webp';
    default:
      return defaultIcon;
  }
}

/// Generate a short one-line effect summary for list cards.
/// Takes the first sentence of the full effect text, or a custom
/// summary for shrines with very long/complex effects (Dice).
String _shortEffect(Shrine s) {
  final name = s.name.toLowerCase();
  if (name == 'dice') {
    return 'Grants one positive + one negative effect. 0.1% chance to explode (quad damage, 1 heart). 3 uses unlocks Daisuke.';
  }
  final effect = s.effect;
  final idx = effect.indexOf('. ', 20);
  if (idx > 0 && idx < 200) return effect.substring(0, idx + 1);
  return effect.length > 150 ? '${effect.substring(0, 147)}...' : effect;
}

/// Full-screen picker shown when the Shrine FAB is tapped from Active
/// Run. Each shrine is a card; tapping it opens the activation sheet.
class ShrinePickerScreen extends StatelessWidget {
  const ShrinePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RunProvider>();
    final rawShrines = provider.allShrines;
    final used = <String, int>{};
    for (final s in provider.runState.shrinesUsed) {
      used[s] = (used[s] ?? 0) + 1;
    }
    final double currentCurse = provider.runState.totalCurse;
    final List<Shrine> shrines = List.from(rawShrines)..sort((a, b) {
      // Cleanse shrine floats to top (most commonly needed).
      final aCleanse = a.name.toLowerCase().contains('cleanse');
      final bCleanse = b.name.toLowerCase().contains('cleanse');
      if (aCleanse && !bCleanse) return -1;
      if (!aCleanse && bCleanse) return 1;
      // Used shrines sink to bottom.
      final aUsed = used.containsKey(a.name) ? 1 : 0;
      final bUsed = used.containsKey(b.name) ? 1 : 0;
      if (aUsed != bUsed) return aUsed - bUsed;
      return 0; // maintain original sorting
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const GoopText('Use a Shrine'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: InkWell(
                onTap: () => _showUsedShrinesLog(context, provider),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.temple_buddhist_outlined,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      GoopText(
                        '${provider.runState.shrinesUsed.length} used',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: FontSizes.bodyMedium,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body:
          shrines.isEmpty
              ? const Center(child: GoopText('No shrine data'))
              : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                itemCount: shrines.length,
                itemBuilder: (c, i) {
                  final s = shrines[i];
                  return _ShrineListTile(
                    shrine: s,
                    usageCount: used[s.name] ?? 0,
                    onTap: () => _openActivationSheet(context, s),
                    onUse:
                        s.name.toLowerCase() == 'hero' && currentCurse >= 9
                            ? null
                            : () {
                              Haptics.selection();
                              final result = provider.applyShrine(s);
                              _showShrineResult(context, result);
                            },
                  ).animate().fadeIn(duration: 200.ms, delay: (i * 30).ms);
                },
              ),
    );
  }

  void _openActivationSheet(BuildContext context, Shrine shrine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (c) => ShrineActivationSheet(shrine: shrine, parentContext: context),
    );
  }
}

class _ShrineListTile extends StatelessWidget {
  final Shrine shrine;
  final int usageCount;
  final VoidCallback onTap;
  final VoidCallback? onUse;

  const _ShrineListTile({
    required this.shrine,
    required this.usageCount,
    required this.onTap,
    this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    final name = shrine.name.toLowerCase();
    final hasCurse = shrine.curse != 0 || name == 'hero';
    final hasCool = shrine.coolness != 0;
    final hasCleanse = name == 'cleanse';
    final hasHeartCost =
        name.contains('angel') ||
        name.contains('blood') ||
        name.contains('companion');

    final String iconAsset = resolveShrineIcon(shrine.name, shrine.icon);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Colors.amber.withValues(alpha: 0.15),
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Shrine Icon
              Hero(
                tag: 'shrine_${shrine.name}',
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.all(Radii.md),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.08),
                      width: 1.0,
                    ),
                  ),
                  child: SizedBox(
                    height: 64,
                    width: 64,
                    child:
                        iconAsset.startsWith('assets/')
                            ? Image.asset(
                              iconAsset,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.none,
                              cacheWidth: 184,
                              cacheHeight: 184,
                              errorBuilder:
                                  (_, _, _) => const Icon(
                                    Icons.temple_buddhist_outlined,
                                    size: 40,
                                    color: Colors.amber,
                                  ),
                            )
                            : iconAsset.startsWith('http')
                            ? Image.network(
                              iconAsset,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.none,
                              errorBuilder:
                                  (_, _, _) => const Icon(
                                    Icons.temple_buddhist_outlined,
                                    size: 40,
                                    color: Colors.amber,
                                  ),
                            )
                            : const Icon(
                              Icons.temple_buddhist_outlined,
                              size: 40,
                              color: Colors.amber,
                            ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Info column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    GoopText(
                      shrine.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: FontSizes.titleSmall,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Effect summary (3 lines max)
                    GoopText(
                      _shortEffect(shrine),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Badges row
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (hasCurse && !hasCleanse && name != 'hero')
                          _shrineBadge(
                            'CURSE ${shrine.curse > 0 ? '+' : ''}${shrine.curse.toStringAsFixed(1)}',
                            Colors.deepOrangeAccent,
                          ),
                        if (hasCool)
                          _shrineBadge(
                            'COOL ${shrine.coolness > 0 ? '+' : ''}${shrine.coolness.toStringAsFixed(1)}',
                            Colors.lightBlueAccent,
                          ),
                        if (hasCleanse)
                          _shrineBadge('CLEANSE', Colors.lightGreenAccent),
                        if (name == 'hero')
                          _shrineBadge('SETS CURSE 9', Colors.deepOrangeAccent),
                        if (hasHeartCost)
                          _shrineBadge('HEART -1', Colors.redAccent),
                        if (usageCount > 0)
                          _shrineBadge('USED ${usageCount}X', Colors.amber),
                      ],
                    ),
                  ],
                ),
              ),

              // Use button — chunky pill, real 48px touch target.
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: FilledButton.icon(
                      onPressed: onUse,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.white12,
                        disabledForegroundColor: Colors.white38,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        minimumSize: const Size(0, 40),
                      ),
                      icon: const Icon(Icons.bolt, size: 18),
                      label: const GoopText(
                        'USE',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Open ${shrine.name} on the Gungeon wiki',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.open_in_browser_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                    onPressed: () => _openShrineWiki(shrine.name),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shrineBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.6),
      ),
      child: GoopText(
        text,
        style: TextStyle(
          fontSize: FontSizes.labelSmall,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

// Top-level shrine UX helpers
void _showShrineResult(BuildContext c, ShrineApplyResult r) {
  final lines = <String>[];
  if (r.applied.isNotEmpty) lines.add(r.applied.join(' · '));
  if (r.manual.isNotEmpty) lines.add(r.manual.first);
  final label =
      lines.isEmpty
          ? '${r.shrine.name} marked as used'
          : '${r.shrine.name}: ${lines.join(' · ')}';
  ScaffoldMessenger.of(c).showSnackBar(
    SnackBar(
      content: GoopText(label),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 2600),
      action:
          r.manual.length > 1
              ? SnackBarAction(
                label: 'Details',
                onPressed: () {
                  showDialog(
                    context: c,
                    builder:
                        (_) => AlertDialog(
                          title: GoopText(
                            '${r.shrine.name} · what to do',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (r.applied.isNotEmpty) ...[
                                const GoopText(
                                  'Auto-applied:',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                for (final a in r.applied) GoopText('  · $a'),
                                const SizedBox(height: 10),
                              ],
                              const GoopText(
                                'You do it in-game:',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              for (final m in r.manual) GoopText('  · $m'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c),
                              child: const GoopText('OK'),
                            ),
                          ],
                        ),
                  );
                },
              )
              : null,
    ),
  );
}

void _showUsedShrinesLog(BuildContext c, RunProvider p) {
  final used = p.runState.shrinesUsed;
  final counts = <String, int>{};
  for (final name in used) {
    counts[name] = (counts[name] ?? 0) + 1;
  }
  final names = counts.keys.toList();

  showDialog(
    context: c,
    builder:
        (c) => AlertDialog(
          backgroundColor: AppTheme.flair.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radii.lg),
          ),
          title: Row(
            children: [
              const Icon(Icons.temple_buddhist, color: Colors.amber),
              const SizedBox(width: 8),
              GoopText(
                used.isEmpty ? 'Shrines used' : '${used.length} shrines used',
                style: const TextStyle(
                  fontSize: FontSizes.titleMedium,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: math.min(420, MediaQuery.of(c).size.height * 0.5),
            ),
            child:
                used.isEmpty
                    ? const Center(
                      child: GoopText('No shrines used yet this run.'),
                    )
                    : ListView.builder(
                      itemCount: names.length,
                      itemBuilder: (c, i) {
                        final name = names[i];
                        final count = counts[name]!;
                        final s = p.shrineByName(name);
                        return Card(
                          color: Colors.amber.withValues(alpha: 0.06),
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: Colors.amber.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(Insets.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: GoopText(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    if (count > 1)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: GoopText(
                                          'x$count',
                                          style: const TextStyle(
                                            fontSize: FontSizes.labelMedium,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.amber,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (s != null)
                                  GoopText(
                                    _shortEffect(s),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      height: 1.35,
                                      color: Colors.white.withValues(
                                        alpha: 0.75,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const GoopText('Close'),
            ),
          ],
        ),
  );
}

/// Opens the shrine's wiki.gg page in the external browser — same
/// URL pattern as the item detail screen's wiki button.
Future<void> _openShrineWiki(String shrineName) async {
  try {
    final slug = Uri.encodeComponent(shrineName.replaceAll(' ', '_'));
    await launchUrl(
      Uri.parse('https://enterthegungeon.wiki.gg/wiki/$slug'),
      mode: LaunchMode.externalApplication,
    );
  } catch (e) {
    debugPrint('[ShrinePicker] wiki launch error: $e');
  }
}
