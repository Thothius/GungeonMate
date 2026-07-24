import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/haptics.dart';
import '../../utils/fast_route.dart';
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
  bool _collapsed = false;

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
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: status.active ? 1.5 : 0.8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  status.active ? Icons.link : Icons.link_off_outlined,
                  size: 18,
                  color: status.active ? Colors.amber : Colors.white38,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: GoopText(
                          s.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified,
                        size: 14,
                        color: Colors.cyan,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
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

    final iconPath = gun?.icon ?? item?.icon ?? '';
    final pillColor = missing
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.amber.withValues(alpha: 0.4);

    final body = Opacity(
      opacity: missing ? 0.4 : 1.0,
      child: Container(
        width: 72,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: missing
              ? const Color(0xFF0D1117)
              : Colors.amber.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: pillColor, width: 1.8),
          boxShadow: !missing
              ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.12), blurRadius: 6)]
              : null,
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 52,
                height: 52,
                child: _buildImage(iconPath, resolvable),
              ),
            ),
            const SizedBox(height: 6),
            GoopText(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: missing ? Colors.white30 : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );

    if (!resolvable) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
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

  Widget _buildImage(String path, bool resolvable) {
    if (path.isEmpty) return _fallback();
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return Image.asset(
      path,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFF0D1117),
      child: Center(
        child: GoopText(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white38),
        ),
      ),
    );
  }
}
