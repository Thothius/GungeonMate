import 'package:flutter/material.dart';

import '../game_icon.dart';
import '../../services/app_theme.dart';
import '../../services/goop_talk_engine.dart';

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
    BorderSide borderSide = const BorderSide(color: Colors.transparent, width: 0);

    String robotTag = '';
    Color? robotTagColor;

    if (isRobot) {
      final nameLower = name.toLowerCase();
      final isGod = nameLower.contains('armor synthesizer') ||
                    nameLower.contains('gunknight') ||
                    nameLower.contains('riddle of lead') ||
                    nameLower.contains('nanomachines');
                    
      final isConverter = nameLower.contains('master round') ||
                          nameLower.contains('heart container') ||
                          nameLower.contains('heart holster') ||
                          nameLower.contains('heart locket') ||
                          nameLower.contains('heart purse') ||
                          nameLower.contains('heart bottle') ||
                          nameLower.contains('yellow chamber') ||
                          nameLower.contains('pink guon stone');
                          
      final isDeadWeight = nameLower.contains('vampire') ||
                           nameLower.contains('patches and mendy') ||
                           nameLower.contains('blasphemy');

      if (isGod) {
        borderSide = const BorderSide(color: Colors.greenAccent, width: 1.5);
        robotTag = 'GOD TIER ⚡';
        robotTagColor = Colors.greenAccent;
      } else if (isConverter) {
        borderSide = const BorderSide(color: Colors.blueAccent, width: 1.5);
        robotTag = 'CONVERTS TO ARMOR 🛡️';
        robotTagColor = Colors.blueAccent;
      } else if (isDeadWeight) {
        borderSide = const BorderSide(color: Colors.redAccent, width: 1.5);
        robotTag = 'DEAD WEIGHT ⚠️';
        robotTagColor = Colors.redAccent;
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
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
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
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: robotTagColor!.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: robotTagColor.withValues(alpha: 0.4), width: 0.8),
                            ),
                            child: GoopText(
                              robotTag,
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: robotTagColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    meta,
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: inRun ? null : onAdd,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: inRun
                        ? Colors.green.withValues(alpha: 0.15)
                        : AppTheme.flair.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: inRun
                          ? Colors.green.withValues(alpha: 0.5)
                          : AppTheme.flair.primary.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    inRun ? Icons.check : Icons.add_rounded,
                    color: inRun ? Colors.green : AppTheme.flair.primary,
                    size: 24,
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
