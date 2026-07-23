import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../services/app_theme.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/haptics.dart';
import '../../utils/fast_route.dart';
import '../game_icon.dart';
import '../rich_link_text.dart';
import '../../screens/item_detail_screen.dart';

class SynergiesSection extends StatefulWidget {
  final List<SynergyStatus> statuses;
  final String currentName;
  const SynergiesSection({
    super.key,
    required this.statuses,
    required this.currentName,
  });

  @override
  State<SynergiesSection> createState() => _SynergiesSectionState();
}

class _SynergiesSectionState extends State<SynergiesSection> {
  bool _collapsed = true;

  @override
  Widget build(BuildContext context) {
    final activeCount =
        widget.statuses.where((s) => s.active).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: widget.statuses.isEmpty
                ? null
                : () {
                    Haptics.selection();
                    setState(() => _collapsed = !_collapsed);
                  },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.hub, size: 16, color: Colors.amber),
                  const SizedBox(width: 6),
                  GoopText(
                    'SYNERGIES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.statuses.isNotEmpty)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.statuses.length}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  if (activeCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: GoopText(
                        '$activeCount active',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (widget.statuses.isNotEmpty)
                    AnimatedRotation(
                      turns: _collapsed ? 0 : 0.5,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!_collapsed && widget.statuses.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GoopText(
                  'No known synergies.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                ),
              ),
            )
          else if (!_collapsed)
            ...widget.statuses.map(
              (s) => SynergyCard(
                status: s,
                currentName: widget.currentName,
              ),
            ),
        ],
      ),
    );
  }
}

class SynergyCard extends StatelessWidget {
  final SynergyStatus status;
  final String currentName;
  const SynergyCard({
    super.key,
    required this.status,
    required this.currentName,
  });

  @override
  Widget build(BuildContext context) {
    final s = status.synergy;
    final color = status.active
        ? Colors.amber
        : Colors.white.withValues(alpha: 0.25);

    final currentLower = currentName.toLowerCase();
    final currentIsAnyOf =
        s.anyOf.any((i) => i.toLowerCase() == currentLower);
    final ownedLower = context.read<RunProvider>().currentOwnedLower;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: status.active ? 1.2 : 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  status.active ? Icons.link : Icons.link_off_outlined,
                  size: 16,
                  color: status.active ? Colors.amber : Colors.white38,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: GoopText(
                          s.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.verified,
                        size: 13,
                        color: Colors.cyan,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: s.items
                  .where((i) => i.toLowerCase() != currentLower)
                  .map((i) => SynergyChip(
                        name: i,
                        missing: status.missing.contains(i),
                      ))
                  .toList(),
            ),
            if (s.anyOf.isNotEmpty) ...[
              const SizedBox(height: 8),
              if (currentIsAnyOf)
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 13,
                      color: Colors.amber.withValues(alpha: 0.80),
                    ),
                    const SizedBox(width: 5),
                    GoopText(
                      'Alternative components matched',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                )
              else ...[
                Row(
                  children: [
                    Icon(
                      Icons.alt_route,
                      size: 13,
                      color: Colors.amber.withValues(alpha: 0.75),
                    ),
                    const SizedBox(width: 4),
                    GoopText(
                      'Alternative Partners:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Colors.amber.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: s.anyOf.map((i) {
                    final isOwned = ownedLower.contains(i.toLowerCase());
                    return SynergyChip(name: i, missing: !isOwned);
                  }).toList(),
                ),
              ],
            ],
            if (s.effectTokens.isNotEmpty &&
                !s.effect.toLowerCase().startsWith('one of the following') &&
                !s.effect.toLowerCase().startsWith('any of the following')) ...[
              const SizedBox(height: 8),
              RichLinkText(
                tokens: s.effectTokens,
                baseStyle: const TextStyle(fontSize: 13, height: 1.35),
              ),
            ] else if (s.effect.isNotEmpty) ...[
              const SizedBox(height: 8),
              GoopText(
                s.prettyEffect,
                style: const TextStyle(fontSize: 13, height: 1.35),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SynergyChip extends StatelessWidget {
  final String name;
  final bool missing;
  const SynergyChip({super.key, required this.name, required this.missing});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<RunProvider>();
    final resolved = provider.entityByName(name);
    final gun = resolved.gun;
    final item = resolved.item;
    final resolvable = gun != null || item != null;

    final flair = AppTheme.flair;
    final filled = flair.chipFilled;
    final accent = filled
        ? Colors.amber.withValues(alpha: 0.4)
        : Colors.amber.withValues(alpha: 0.85);
    final mutedRule = Colors.white.withValues(alpha: 0.18);
    final bg = !filled
        ? null
        : (missing
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.amber.withValues(alpha: 0.15));
    final border = filled
        ? (missing ? Colors.white.withValues(alpha: 0.15) : accent)
        : null;

    final iconPath = gun?.icon ?? item?.icon ?? '';
    final quality = gun?.quality ?? item?.quality ?? '';
    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (resolvable && iconPath.isNotEmpty) ...[
          Opacity(
            opacity: missing ? 0.5 : 1.0,
            child: GameIcon(
              assetPath: iconPath,
              fallback: gun != null
                  ? Icons.gps_fixed
                  : Icons.inventory_2_outlined,
              quality: quality,
              size: 18,
              showRing: false,
            ),
          ),
          const SizedBox(width: 4),
        ],
        GoopText(
          name,
          style: TextStyle(
            fontSize: 11.5,
            color: missing ? Colors.white54 : Colors.white,
          ),
        ),
        if (resolvable) ...[
          const SizedBox(width: 2),
          Icon(
            Icons.chevron_right,
            size: 14,
            color: missing ? Colors.white38 : Colors.amber,
          ),
        ],
      ],
    );

    final body = Container(
      padding: filled
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
          : const EdgeInsets.fromLTRB(2, 2, 2, 1),
      decoration: filled
          ? BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(flair.chipRadius),
              border: Border.all(color: border!),
            )
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: missing ? mutedRule : accent,
                  width: 1,
                ),
              ),
            ),
      child: label,
    );

    if (!resolvable) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(flair.chipRadius),
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          Navigator.push(
            context,
            fastRoute(ItemDetailScreen(gun: gun, item: item)),
          );
        },
        onLongPress: () {
          FocusManager.instance.primaryFocus?.unfocus();
          showEntityPeekSheet(context, gun: gun, item: item);
        },
        child: body,
      ),
    );
  }
}
