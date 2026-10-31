import 'package:flutter/material.dart';

import '../game_icon.dart';
import '../../services/app_theme.dart';
import '../../services/goop_talk_engine.dart';
import '../../theme/tokens.dart';
import '../skeuo/skeuo_tokens.dart';

class BrowseRow extends StatelessWidget {
  final String name;
  final String quality;
  final String iconPath;
  final IconData fallback;
  final Widget meta;
  final bool inRun;
  final bool isRobot;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const BrowseRow({
    super.key,
    required this.name,
    required this.quality,
    required this.iconPath,
    required this.fallback,
    required this.meta,
    required this.inRun,
    required this.isRobot,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    BorderSide borderSide = const BorderSide(
      color: Colors.transparent,
      width: 0,
    );

    String robotTag = '';
    Color? robotTagColor;

    if (isRobot) {
      final nameLower = name.toLowerCase();
      final isGod =
          nameLower.contains('armor synthesizer') ||
          nameLower.contains('gunknight') ||
          nameLower.contains('riddle of lead') ||
          nameLower.contains('nanomachines');

      final isConverter =
          nameLower.contains('master round') ||
          nameLower.contains('heart container') ||
          nameLower.contains('heart holster') ||
          nameLower.contains('heart locket') ||
          nameLower.contains('heart purse') ||
          nameLower.contains('heart bottle') ||
          nameLower.contains('yellow chamber') ||
          nameLower.contains('pink guon stone');

      final isDeadWeight =
          nameLower.contains('vampire') ||
          nameLower.contains('patches and mendy') ||
          nameLower.contains('blasphemy');

      if (isGod) {
        borderSide = BorderSide(
          color: Skeuo.inkIf(Colors.greenAccent),
          width: 1.5,
        );
        robotTag = 'GOD TIER ⚡';
        robotTagColor = Skeuo.inkIf(Colors.greenAccent);
      } else if (isConverter) {
        borderSide = BorderSide(
          color: Skeuo.inkIf(Colors.blueAccent),
          width: 1.5,
        );
        robotTag = 'CONVERTS TO ARMOR 🛡️';
        robotTagColor = Skeuo.inkIf(Colors.blueAccent);
      } else if (isDeadWeight) {
        borderSide = BorderSide(
          color: Skeuo.inkIf(Colors.redAccent),
          width: 1.5,
        );
        robotTag = 'DEAD WEIGHT ⚠️';
        robotTagColor = Skeuo.inkIf(Colors.redAccent);
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: borderSide,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Row(
            children: [
              GameIcon(
                assetPath: iconPath,
                fallback: fallback,
                quality: quality,
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GoopText(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (robotTag.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: robotTagColor!.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: robotTagColor.withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                            ),
                            child: GoopText(
                              robotTag,
                              style: TextStyle(
                                fontSize: FontSizes.labelSmall,
                                fontWeight: FontWeight.bold,
                                color: robotTagColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 5),
                    // Meta is caller-provided and may not shrink — guard
                    // narrow widths (≤500px) with scale-down.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: meta,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: inRun ? null : onAdd,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 48,
                  height: 64,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color:
                            inRun
                                ? Skeuo.inkIf(
                                  Colors.green,
                                ).withValues(alpha: 0.15)
                                : AppTheme.flair.primary.withValues(
                                  alpha: 0.12,
                                ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              inRun
                                  ? Skeuo.inkIf(
                                    Colors.green,
                                  ).withValues(alpha: 0.5)
                                  : AppTheme.flair.primary.withValues(
                                    alpha: 0.4,
                                  ),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        inRun ? Icons.check_rounded : Icons.add_rounded,
                        color:
                            inRun
                                ? Skeuo.inkIf(Colors.greenAccent)
                                : AppTheme.flair.primary,
                        size: 22,
                      ),
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
}
