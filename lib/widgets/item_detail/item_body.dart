import '../../theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/item.dart';
import '../../models/player.dart';
import '../../providers/run_provider.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/haptics.dart';
import 'description_blocks.dart';
import 'gun_stats.dart';
import '../skeuo/skeuo_tokens.dart';
part 'item_body_sections.dart';

class ItemBody extends StatelessWidget with _ItemBodySections {
  @override
  final Item item;
  @override
  final PlayerSlot? ownerSlot;
  const ItemBody({super.key, required this.item, this.ownerSlot});

  @override
  Widget build(BuildContext context) {
    String? durationStr;
    String? chargeStr;
    if (item.isActive) {
      durationStr =
          item.duration.isNotEmpty ? item.duration : _extractDuration();
      chargeStr =
          item.rechargeTime.isNotEmpty ? item.rechargeTime : 'via damage';
    }
    final stats =
        <MapEntry<String, String>>[
          if (chargeStr != null) MapEntry('Charge', chargeStr),
          if (durationStr != null) MapEntry('Duration', durationStr),
        ].where((e) => e.value.isNotEmpty).toList();

    final junkanInfo =
        item.name.toLowerCase().startsWith('ser junkan')
            ? _buildJunkanInfo(context)
            : null;
    final spiceInfo =
        item.name.toLowerCase() == 'spice' ? _buildSpiceInfo(context) : null;
    final sprunInfo =
        item.name.toLowerCase() == 'sprun' ? _buildSprunInfo(context) : null;
    final isPaydayItem = [
      'clown mask',
      'drill',
      'loot bag',
    ].contains(item.name.toLowerCase());
    final paydayInfo = isPaydayItem ? _buildPaydayInfo(context) : null;
    final platinumInfo =
        item.name.toLowerCase() == 'platinum bullets'
            ? _buildPlatinumBulletsInfo(context)
            : null;
    final ironCoinInfo =
        item.name.toLowerCase() == 'iron coin'
            ? _buildIronCoinInfo(context)
            : null;
    const killThePastItems = [
      'prime primer',
      'arcane gunpowder',
      'planar lead',
      'obsidian shell casing',
    ];
    final isKillThePastItem = killThePastItems.contains(
      item.name.toLowerCase(),
    );
    final killThePastInfo =
        isKillThePastItem ? _buildKillThePastInfo(context) : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.effect.isNotEmpty) ...[
            DescriptionBlock(text: item.effect),
            const SizedBox(height: 12),
          ],
          if (junkanInfo != null) ...[const SizedBox(height: 12), junkanInfo],
          if (spiceInfo != null) ...[const SizedBox(height: 12), spiceInfo],
          if (sprunInfo != null) ...[const SizedBox(height: 12), sprunInfo],
          if (paydayInfo != null) ...[const SizedBox(height: 12), paydayInfo],
          if (platinumInfo != null) ...[
            const SizedBox(height: 12),
            platinumInfo,
          ],
          if (ironCoinInfo != null) ...[
            const SizedBox(height: 12),
            ironCoinInfo,
          ],
          if (killThePastInfo != null) ...[
            const SizedBox(height: 12),
            killThePastInfo,
          ],
          if (stats.isNotEmpty) ...[
            const SizedBox(height: 12),
            // 50/50 pills — Charge left, Duration right.
            Row(
              children: [
                for (var i = 0; i < stats.length; i++) ...[
                  Expanded(
                    child: StatPill(label: stats[i].key, value: stats[i].value),
                  ),
                  if (i < stats.length - 1) const SizedBox(width: 10),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
