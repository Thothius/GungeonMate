import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../models/shrine.dart';

/// Resolves the correct shrine icon asset, applying bundled art overrides
/// (updated Ammo/Angel shrine graphics) over the default data-driven icon.
String resolveShrineIcon(String shrineName, String defaultIcon) {
  switch (shrineName.toLowerCase()) {
    case 'ammo':
    case 'ammo shrine':
      return 'assets/images/shrines/Ammo_Shrine.webp';
    case 'angel':
    case 'angel shrine':
      return 'assets/images/shrines/Angel_Shrine.webp';
    default:
      return defaultIcon;
  }
}

/// Full-screen picker shown when the Shrine FAB is tapped from Active
/// Run. Each shrine is a card; tapping it opens the activation sheet.
class ShrinePickerScreen extends StatelessWidget {
  const ShrinePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RunProvider>();
    final rawShrines = provider.allShrines;
    final List<Shrine> shrines = List.from(rawShrines)..sort((a, b) {
      final aCleanse = a.name.toLowerCase().contains('cleanse');
      final bCleanse = b.name.toLowerCase().contains('cleanse');
      if (aCleanse && !bCleanse) return -1;
      if (!aCleanse && bCleanse) return 1;
      return 0; // maintain original sorting
    });
    final used = <String, int>{};
    for (final s in provider.runState.shrinesUsed) {
      used[s] = (used[s] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Use a Shrine'),
        actions: [
          if (provider.runState.shrinesUsed.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '${provider.runState.shrinesUsed.length} used',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: shrines.isEmpty
          ? const Center(child: Text('No shrine data'))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 shrines per row!
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.78, // Taller, highly readable cards!
              ),
              itemCount: shrines.length,
              itemBuilder: (c, i) {
                final s = shrines[i];
                return _ShrineGridTile(
                  shrine: s,
                  usageCount: used[s.name] ?? 0,
                  onTap: () => _openActivationSheet(context, s),
                );
              },
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

class _ShrineGridTile extends StatelessWidget {
  final Shrine shrine;
  final int usageCount;
  final VoidCallback onTap;

  const _ShrineGridTile({
    required this.shrine,
    required this.usageCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = shrine.name.toLowerCase();
    final hasCurse = shrine.curse != 0 || name == 'hero';
    final hasCool = shrine.coolness != 0;
    final hasCleanse = name == 'cleanse';

    final String iconAsset = resolveShrineIcon(shrine.name, shrine.icon);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Colors.amber.withValues(alpha: 0.15),
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap, // Tapping directly triggers the activation sheet!
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Shrine Icon (with nice circular backup background)
              Hero(
                tag: 'shrine_${shrine.name}',
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.05),
                      width: 1.0,
                    ),
                  ),
                  child: SizedBox(
                    height: 80,
                    width: 80,
                    child: iconAsset.startsWith('assets/')
                        ? Image.asset(
                            iconAsset,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.none, // Pixel art!
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.temple_buddhist_outlined,
                              size: 32,
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
                                  size: 32,
                                  color: Colors.amber,
                                ),
                              )
                            : const Icon(
                                Icons.temple_buddhist_outlined,
                                size: 32,
                                color: Colors.amber,
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Shrine Name
              Text(
                shrine.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),

              // Quick stats badge row
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: [
                  if (hasCurse && !hasCleanse && name != 'hero')
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.deepOrangeAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.deepOrangeAccent.withValues(alpha: 0.35), width: 0.6),
                        ),
                        child: Text(
                          'CURSE ${shrine.curse > 0 ? '+' : ''}${shrine.curse.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.deepOrangeAccent),
                        ),
                      ),
                    ),
                  if (hasCool)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.lightBlueAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.lightBlueAccent.withValues(alpha: 0.35), width: 0.6),
                        ),
                        child: Text(
                          'COOL ${shrine.coolness > 0 ? '+' : ''}${shrine.coolness.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.lightBlueAccent),
                        ),
                      ),
                    ),
                  if (hasCleanse)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.lightGreenAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.lightGreenAccent.withValues(alpha: 0.35), width: 0.6),
                        ),
                        child: const Text(
                          'CLEANSE',
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.lightGreenAccent),
                        ),
                      ),
                    ),
                  if (name == 'hero')
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.deepOrangeAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.deepOrangeAccent.withValues(alpha: 0.35), width: 0.6),
                        ),
                        child: const Text(
                          'MAX',
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.deepOrangeAccent),
                        ),
                      ),
                    ),
                ],
              ),
              
              // Used badge overlay (bottom center)
              if (usageCount > 0) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.35), width: 0.6),
                  ),
                  child: Text(
                    'USED $usageCount TIME${usageCount > 1 ? "S" : ""}',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ],
            ],
          ),
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
                    child: Text(
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
                      child: Text(
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
                          Text(
                            '💔 PENALTY COST: -1 HEART CONTAINER (LIFE -1)',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.black,
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
                    Text(
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
                  const SizedBox(height: 6),
                  Text(
                    shrine.effect,
                    style: const TextStyle(fontSize: 13.5, height: 1.4),
                  ),
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
                      child: const Text('Cancel'),
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
                              _showResultSnackbar(parentContext, result);
                            },
                      style: FilledButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                      ),
                      icon: const Icon(Icons.bolt, size: 20),
                      label: Text(
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

  void _showResultSnackbar(BuildContext c, ShrineApplyResult r) {
    final lines = <String>[];
    if (r.applied.isNotEmpty) lines.add(r.applied.join(' · '));
    if (r.manual.isNotEmpty) lines.add(r.manual.first);
    final label = lines.isEmpty
        ? '${r.shrine.name} marked as used'
        : '${r.shrine.name}: ${lines.join(' · ')}';
    ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(
        content: Text(label),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2600),
        action: r.manual.length > 1
            ? SnackBarAction(
                label: 'Details',
                onPressed: () {
                  showDialog(
                    context: c,
                    builder: (_) => AlertDialog(
                      title: Text('${r.shrine.name} · what to do'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (r.applied.isNotEmpty) ...[
                            const Text('Auto-applied:',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700)),
                            for (final a in r.applied) Text('  · $a'),
                            const SizedBox(height: 10),
                          ],
                          const Text('You do it in-game:',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700)),
                          for (final m in r.manual) Text('  · $m'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c),
                          child: const Text('OK'),
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
        Text(
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
              Text(
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
          Text(
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
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
