import '../theme/tokens.dart';
import 'package:flutter/material.dart';
import '../services/app_theme.dart';
import '../services/goop_talk_engine.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

import '../providers/run_provider.dart';
import '../models/shrine.dart';
import '../widgets/skeuo/skeuo_tokens.dart';
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
                    color: Skeuo.inkIf(Colors.amber).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Skeuo.inkIf(Colors.amber).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.temple_buddhist_outlined,
                        color: Skeuo.inkIf(Colors.amber),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      GoopText(
                        '${provider.runState.shrinesUsed.length} used',
                        style: TextStyle(
                          color: Skeuo.inkIf(Colors.amber),
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
              : GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.78,
                ),
                itemCount: shrines.length,
                itemBuilder: (c, i) {
                  final s = shrines[i];
                  return _ShrineTile(
                    shrine: s,
                    used: used[s.name] ?? 0,
                    onTap: () => _openActivationSheet(context, s),
                  ).animate().fadeIn(duration: 200.ms, delay: (i * 25).ms);
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

class _ShrineTile extends StatelessWidget {
  final Shrine shrine;
  final int used;
  final VoidCallback onTap;
  const _ShrineTile({
    required this.shrine,
    required this.used,
    required this.onTap,
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
    final iconAsset = resolveShrineIcon(shrine.name, shrine.icon);
    final costColor =
        hasCleanse
            ? Skeuo.inkIf(Colors.lightGreenAccent)
            : hasCurse
            ? Skeuo.inkIf(Colors.deepOrangeAccent)
            : Skeuo.inkIf(Colors.amber);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color:
              used > 0
                  ? Colors.white.withValues(alpha: 0.02)
                  : AppTheme.flair.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                used > 0
                    ? Colors.white.withValues(alpha: 0.08)
                    : costColor.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon — the altar centerpiece.
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: costColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: costColor.withValues(alpha: 0.35)),
              ),
              padding: const EdgeInsets.all(7),
              child:
                  iconAsset.startsWith('assets/')
                      ? Image.asset(
                        iconAsset,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                        errorBuilder:
                            (_, _, _) => Icon(
                              Icons.temple_buddhist_outlined,
                              size: 30,
                              color: costColor,
                            ),
                      )
                      : Icon(
                        Icons.temple_buddhist_outlined,
                        size: 30,
                        color: costColor,
                      ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GoopText(
                shrine.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: FontSizes.titleSmall,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Cost / benefit chips — what this shrine takes and gives.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: [
                  if (hasCurse && !hasCleanse && name != 'hero')
                    _chip(
                      'CURSE ${shrine.curse > 0 ? '+' : ''}${shrine.curse.toStringAsFixed(1)}',
                      Skeuo.inkIf(Colors.deepOrangeAccent),
                    ),
                  if (hasCool)
                    _chip(
                      'COOL ${shrine.coolness > 0 ? '+' : ''}${shrine.coolness.toStringAsFixed(1)}',
                      Skeuo.inkIf(Colors.lightBlueAccent),
                    ),
                  if (hasCleanse)
                    _chip('CLEANSE', Skeuo.inkIf(Colors.lightGreenAccent)),
                  if (name == 'hero')
                    _chip('CURSE 9', Skeuo.inkIf(Colors.deepOrangeAccent)),
                  if (hasHeartCost)
                    _chip('HEART -1', Skeuo.inkIf(Colors.redAccent)),
                  if (used > 0)
                    _chip('USED ${used}X', Skeuo.inkIf(Colors.amber)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GoopText(
                _shortEffect(shrine),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.3,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color col) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: col.withValues(alpha: 0.4), width: 0.7),
      ),
      child: GoopText(
        label,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          color: col,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

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
              Icon(Icons.temple_buddhist, color: Skeuo.inkIf(Colors.amber)),
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
                          color: Skeuo.inkIf(
                            Colors.amber,
                          ).withValues(alpha: 0.06),
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: Skeuo.inkIf(
                                Colors.amber,
                              ).withValues(alpha: 0.2),
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
                                          color: Skeuo.inkIf(
                                            Colors.amber,
                                          ).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: GoopText(
                                          'x$count',
                                          style: TextStyle(
                                            fontSize: FontSizes.labelMedium,
                                            fontWeight: FontWeight.w800,
                                            color: Skeuo.inkIf(Colors.amber),
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
