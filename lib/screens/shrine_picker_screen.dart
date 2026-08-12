import 'package:flutter/material.dart';
import '../services/goop_talk_engine.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

import '../providers/run_provider.dart';
import '../models/shrine.dart';
import '../services/haptics.dart';

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
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.temple_buddhist_outlined,
                          color: Colors.amber, size: 16),
                      const SizedBox(width: 6),
                      GoopText(
                        '${provider.runState.shrinesUsed.length} used',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 14,
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
      body: shrines.isEmpty
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
                  onUse: s.name.toLowerCase() == 'hero' && currentCurse >= 9
                      ? null
                      : () {
                          Haptics.selection();
                          final result = provider.applyShrine(s);
                          _showShrineResult(context, result);
                        },
                ).animate().fadeIn(
                      duration: 200.ms,
                      delay: (i * 30).ms,
                    );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E2A27),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white12, width: 1.2),
                ),
                elevation: 4,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              label: const GoopText(
                'BACK TO RUN',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.8),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openActivationSheet(BuildContext context, Shrine shrine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) =>
          ShrineActivationSheet(shrine: shrine, parentContext: context),
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
        name.contains('angel') || name.contains('blood') || name.contains('companion');

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
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shrine Icon
              Hero(
                tag: 'shrine_${shrine.name}',
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.08),
                      width: 1.0,
                    ),
                  ),
                  child: SizedBox(
                    height: 72,
                    width: 72,
                    child: iconAsset.startsWith('assets/')
                        ? Image.asset(
                            iconAsset,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.none,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.temple_buddhist_outlined,
                              size: 28,
                              color: Colors.amber,
                            ),
                          )
                        : iconAsset.startsWith('http')
                            ? Image.network(
                                iconAsset,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.none,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.temple_buddhist_outlined,
                                  size: 28,
                                  color: Colors.amber,
                                ),
                              )
                            : const Icon(
                                Icons.temple_buddhist_outlined,
                                size: 28,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Description (italic, 1 line)
                    if (shrine.description.isNotEmpty)
                      GoopText(
                        shrine.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.45),
                          fontStyle: FontStyle.italic,
                          height: 1.2,
                        ),
                      ),
                    const SizedBox(height: 6),

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
                          _shrineBadge(
                            'USED ${usageCount}X',
                            Colors.amber,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Use button
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: FilledButton(
                  onPressed: onUse,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        onUse == null ? Colors.white24 : Colors.amber,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white12,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: Size.zero,
                  ),
                  child: const GoopText(
                    'USE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
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
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

/// Modal bottom sheet opened when the user taps a shrine card. Shows
/// full detail + a big "Use Shrine" button.
class ShrineActivationSheet extends StatelessWidget {
  final Shrine shrine;
  final BuildContext parentContext;
  const ShrineActivationSheet({
    super.key,
    required this.shrine,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<RunProvider>();
    final name = shrine.name.toLowerCase();
    final currentCurse = provider.runState.totalCurse;
    final heroBlocked = name == 'hero' && currentCurse >= 9;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (c, ctrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                children: [
                  // Centered Large Image
                  Center(
                    child: Hero(
                      tag: 'shrine_${shrine.name}',
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.1),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          height: 120,
                          width: 120,
                          child: resolveShrineIcon(shrine.name, shrine.icon).startsWith('assets/')
                              ? Image.asset(
                                  resolveShrineIcon(shrine.name, shrine.icon),
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.none, // Pixel art!
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.temple_buddhist_outlined,
                                    size: 48,
                                    color: Colors.amber,
                                  ),
                                )
                              : resolveShrineIcon(shrine.name, shrine.icon).startsWith('http')
                                  ? Image.network(
                                      resolveShrineIcon(shrine.name, shrine.icon),
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.none,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.temple_buddhist_outlined,
                                        size: 48,
                                        color: Colors.amber,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.temple_buddhist_outlined,
                                      size: 48,
                                      color: Colors.amber,
                                    ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Centered Title
                  Center(
                    child: GoopText(
                      shrine.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Centered Ammonomicon Message
                  if (shrine.message.isNotEmpty && shrine.message != 'N/A')
                    Center(
                      child: GoopText(
                        '"${shrine.message}"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                  // Health Cost Alert for Angel or Blood Shrine (Takes a life with a life -1!)
                  if (name.contains('angel') || name.contains('blood')) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.05),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.heart_broken_rounded, color: Colors.redAccent, size: 16),
                          SizedBox(width: 8),
                          GoopText(
                            '💔 PENALTY COST: -1 HEART CONTAINER (LIFE -1)',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.redAccent,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (shrine.description.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    GoopText(
                      shrine.description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Colors.white.withValues(alpha: 0.75),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const _SectionHeader(
                      icon: Icons.auto_awesome, title: 'EFFECT'),
                  const SizedBox(height: 10),
                  _buildEffectBody(shrine),
                  const SizedBox(height: 16),
                  _WillApplyCard(shrine: shrine, currentCurse: currentCurse),
                  if (heroBlocked) ...[
                    const SizedBox(height: 12),
                    _BlockedNotice(
                      message:
                          'Hero shrine cannot be used while curse ≥ 9 (currently ${currentCurse.toStringAsFixed(1)}).',
                    ),
                  ],
                  const SizedBox(height: 90),
                ],
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const GoopText('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: heroBlocked
                          ? null
                          : () {
                              final result = provider.applyShrine(shrine);
                              Navigator.pop(context);
                              _showShrineResult(parentContext, result);
                            },
                      style: FilledButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                      ),
                      icon: const Icon(Icons.bolt, size: 20),
                      label: GoopText(
                        shrine.hasAutoEffect
                            ? 'Use Shrine'
                            : 'Mark as Used',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.amber),
        const SizedBox(width: 6),
        GoopText(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Colors.amber,
          ),
        ),
      ],
    );
  }
}

class _WillApplyCard extends StatelessWidget {
  final Shrine shrine;
  final double currentCurse;
  const _WillApplyCard(
      {required this.shrine, required this.currentCurse});

  @override
  Widget build(BuildContext context) {
    final name = shrine.name.toLowerCase();
    final auto = <({String label, Color color, IconData icon})>[];

    if (name == 'cleanse') {
      auto.add((
        label:
            'Curse → 0   (Δ ${(-currentCurse).toStringAsFixed(1)})',
        color: Colors.lightGreenAccent,
        icon: Icons.water_drop,
      ));
    } else if (name == 'hero') {
      if (currentCurse < 9) {
        auto.add((
          label:
              'Curse → 9   (Δ +${(9 - currentCurse).toStringAsFixed(1)})',
          color: Colors.deepOrangeAccent,
          icon: Icons.warning_amber,
        ));
      }
    } else {
      if (shrine.curse != 0) {
        auto.add((
          label:
              'Curse ${shrine.curse > 0 ? '+' : ''}${shrine.curse.toStringAsFixed(1)}',
          color: Colors.deepOrangeAccent,
          icon: Icons.warning_amber,
        ));
      }
      if (shrine.coolness != 0) {
        auto.add((
          label:
              'Coolness ${shrine.coolness > 0 ? '+' : ''}${shrine.coolness.toStringAsFixed(1)}',
          color: Colors.lightBlueAccent,
          icon: Icons.ac_unit,
        ));
      }
    }

    return Card(
      color: Colors.amber.withValues(alpha: 0.06),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.amber.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
                icon: Icons.bolt, title: 'WILL BE APPLIED'),
            const SizedBox(height: 8),
            if (auto.isEmpty)
              GoopText(
                'No automatic stat changes — marks the shrine as used in your log.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final a in auto) _AutoRow(
                      label: a.label, color: a.color, icon: a.icon),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AutoRow extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _AutoRow(
      {required this.label, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          GoopText(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockedNotice extends StatelessWidget {
  final String message;
  const _BlockedNotice({required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.block, color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: GoopText(
              message,
              style: const TextStyle(fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

// Top-level shrine UX helpers
void _showShrineResult(BuildContext c, ShrineApplyResult r) {
  final lines = <String>[];
  if (r.applied.isNotEmpty) lines.add(r.applied.join(' · '));
  if (r.manual.isNotEmpty) lines.add(r.manual.first);
  final label = lines.isEmpty
      ? '${r.shrine.name} marked as used'
      : '${r.shrine.name}: ${lines.join(' · ')}';
  ScaffoldMessenger.of(c).showSnackBar(
    SnackBar(
      content: GoopText(label),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 2600),
      action: r.manual.length > 1
          ? SnackBarAction(
              label: 'Details',
              onPressed: () {
                showDialog(
                  context: c,
                  builder: (_) => AlertDialog(
                    title: GoopText('${r.shrine.name} · what to do', maxLines: 1, overflow: TextOverflow.ellipsis),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (r.applied.isNotEmpty) ...[
                          const GoopText('Auto-applied:',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700)),
                          for (final a in r.applied) GoopText('  · $a'),
                          const SizedBox(height: 10),
                        ],
                        const GoopText('You do it in-game:',
                            style: TextStyle(
                                fontWeight: FontWeight.w700)),
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
    builder: (c) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          const Icon(Icons.temple_buddhist, color: Colors.amber),
          const SizedBox(width: 8),
          GoopText(
            used.isEmpty ? 'Shrines used' : '${used.length} shrines used',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: math.min(
            420,
            MediaQuery.of(c).size.height * 0.5,
          ),
        ),
        child: used.isEmpty
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
                      padding: const EdgeInsets.all(12),
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
                                    color:
                                        Colors.amber.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: GoopText(
                                    'x$count',
                                    style: const TextStyle(
                                      fontSize: 12,
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
                                color: Colors.white.withValues(alpha: 0.75),
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

Widget _buildEffectBody(Shrine shrine) {
  if (shrine.name.toLowerCase() == 'dice') {
    return _DiceEffectBody(effect: shrine.effect);
  }
  return _GenericEffectBody(effect: shrine.effect);
}

Widget _GenericEffectBody({required String effect}) {
  final sentences = effect
      .split('. ')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  if (sentences.isEmpty) return const SizedBox.shrink();

  for (var i = 0; i < sentences.length; i++) {
    if (!sentences[i].endsWith('.') &&
        !sentences[i].endsWith('!') &&
        !sentences[i].endsWith('?')) {
      sentences[i] = '${sentences[i]}.';
    }
  }

  final main = sentences.first;
  final rest = sentences.length > 1 ? sentences.sublist(1) : <String>[];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.amber.withValues(alpha: 0.3),
          ),
        ),
        child: GoopText(
          main,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1.35,
            color: Colors.white,
          ),
        ),
      ),
      const SizedBox(height: 10),
      for (final s in rest)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '•  ',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Expanded(
                child: Text(
                  s,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

const _diceEffectNames = [
  'Renewed',
  'Pained',
  'Bolstered',
  'Enfeebled',
  'Paid',
  'Robbed',
  'Cleansed',
  'Cursed',
  'Blanked',
  'De-Blanked',
  'Gift',
  'Disarmed',
  'Reloaded',
  'Limited',
  'Hasted',
  'Unsteady',
  'Shielded',
  'Priceless',
];

Widget _DiceEffectBody({required String effect}) {
  var text = effect;
  if (text.startsWith('Good Effects Bad Effects ')) {
    text = text.substring('Good Effects Bad Effects '.length);
  }

  final pattern = _diceEffectNames.map(RegExp.escape).join('|');
  final re = RegExp(
    r'(' + pattern + r')(.*?)(?=(' + pattern + r')|$)',
    dotAll: true,
  );
  final matches = re.allMatches(text).toList();
  final lastEnd = matches.isNotEmpty ? matches.last.end : 0;
  final tail = text.substring(lastEnd).trim();
  final notes = tail
      .split('. ')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  for (var i = 0; i < notes.length; i++) {
    if (!notes[i].endsWith('.') &&
        !notes[i].endsWith('!') &&
        !notes[i].endsWith('?')) {
      notes[i] = '${notes[i]}.';
    }
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const GoopText(
        'One positive and one negative effect:',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 10),
      for (var i = 0; i < matches.length; i++) ...[
        _DiceEffectCard(
          name: matches[i].group(1)!,
          body: matches[i].group(2)!.trim(),
          isGood: i.isEven,
        ),
        const SizedBox(height: 6),
      ],
      if (notes.isNotEmpty) ...[
        const _SectionHeader(icon: Icons.info_outline, title: 'NOTES'),
        const SizedBox(height: 6),
        for (final n in notes)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•  ',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Expanded(
                  child: Text(
                    n,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ],
  );
}

class _DiceEffectCard extends StatelessWidget {
  final String name;
  final String body;
  final bool isGood;
  const _DiceEffectCard({
    required this.name,
    required this.body,
    required this.isGood,
  });

  @override
  Widget build(BuildContext context) {
    final color = isGood ? Colors.lightGreenAccent : Colors.redAccent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: color, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
