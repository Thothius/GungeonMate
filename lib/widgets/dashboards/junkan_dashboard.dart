import '../../theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../models/player.dart';
import '../../services/app_theme.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/haptics.dart';
import '../skeuo/skeuo_tokens.dart';

class JunkanDashboardSliver extends StatefulWidget {
  final PlayerSlot slot;
  const JunkanDashboardSliver({super.key, required this.slot});

  @override
  State<JunkanDashboardSliver> createState() => JunkanDashboardSliverState();
}

class JunkanDashboardSliverState extends State<JunkanDashboardSliver> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final player =
        widget.slot == PlayerSlot.coop
            ? (p.runState.coop ?? Player())
            : p.runState.main;

    final junkCount =
        player.items.where((i) => i.name.toLowerCase() == 'junk').length;
    final hasGoldJunk = player.items.any(
      (i) => i.name.toLowerCase() == 'gold junk',
    );

    String rankName = '';
    String description = '';
    String stats = '';

    if (hasGoldJunk) {
      rankName = 'MECHA JUNKAN (GOLD SUIT)';
      description =
          'High-tech gold mechsuit! Jammed enemies struck by his machine gun become normal. Bypasses boss DPS cap.';
      stats = 'DMG: 2.2/shot (Machine Gun) • 20.0 (Laser Blade) • 8.0/rocket';
    } else {
      switch (junkCount) {
        case 0:
          rankName = 'PEASANT';
          description = 'Junkan harmlessly pushes enemies around.';
          stats = 'DMG: 0.0 • Role: Companion • Speed: Steady';
          break;
        case 1:
          rankName = 'SQUIRE';
          description = 'Gains helmet. Headbutts enemies slowly.';
          stats = 'DMG: 3.0 • Attack: Headbutt • Armor: Helmet';
          break;
        case 2:
          rankName = 'HEDGE KNIGHT';
          description =
              'Gains shield. Attacks more frequently by shield-bashing.';
          stats = 'DMG: 5.0 • Attack: Shield-bash • Armor: Shield';
          break;
        case 3:
          rankName = 'KNIGHT';
          description =
              'Gains sword. Attacks more frequently by slicing enemies.';
          stats = 'DMG: 7.0 • Attack: Sword-slice • Armor: Sword';
          break;
        case 4:
          rankName = 'KNIGHT LIEUTENANT';
          description =
              'Gains helmet adornment. Sword attacks are faster and deal more damage.';
          stats = 'DMG: 9.0 • Attack: Upgraded Slice • Armor: Plated';
          break;
        case 5:
          rankName = 'KNIGHT COMMANDER';
          description =
              'Gains cape. Spin-attacks multiple enemies simultaneously.';
          stats = 'DMG: 10.0 × 2 (Double Spin) • Attack: Spin • Armor: Cape';
          break;
        case 6:
          rankName = 'HOLY KNIGHT';
          description =
              'Occasionally Blanks. Sacrifices himself to revive you at full health if you die.';
          stats = 'DMG: 13.33 • Attack: Holy Slice • Ability: Blank & Revive';
          break;
        default:
          rankName = 'ANGELIC KNIGHT';
          description =
              'Gains wings. Flying. Fires rapid pink homing projectile shots.';
          stats =
              'DMG: 10.0/shot • Attack: Ranged Projectiles • Ability: Flying';
          break;
      }
    }

    final String imgPath =
        hasGoldJunk
            ? 'assets/images/junkan/gold.webp'
            : switch (junkCount) {
              0 => 'assets/images/junkan/1.webp',
              1 => 'assets/images/junkan/3.webp',
              2 => 'assets/images/junkan/4.webp',
              3 => 'assets/images/junkan/5.webp',
              4 => 'assets/images/junkan/6.webp',
              5 => 'assets/images/junkan/7.webp',
              6 => 'assets/images/junkan/8.webp',
              _ => 'assets/images/junkan/8.webp',
            };

    final junkItem = p.itemByName('Junk');
    final goldJunkItem = p.itemByName('Gold Junk');

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.flair.scaffold.withValues(alpha: 0.6),
            borderRadius: BorderRadius.all(Radii.md),
            border: Border.all(
              color:
                  hasGoldJunk
                      ? Skeuo.inkIf(Colors.amber).withValues(alpha: 0.4)
                      : Skeuo.inkIf(Colors.teal).withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (hasGoldJunk
                        ? Skeuo.inkIf(Colors.amber)
                        : Skeuo.inkIf(Colors.tealAccent))
                    .withValues(alpha: 0.04),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() => _collapsed = !_collapsed);
                  Haptics.selection();
                },
                borderRadius: BorderRadius.all(Radii.md),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            hasGoldJunk
                                ? Icons.shield_rounded
                                : Icons.star_rounded,
                            color:
                                hasGoldJunk
                                    ? Skeuo.inkIf(Colors.amberAccent)
                                    : Skeuo.inkIf(Colors.tealAccent),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          GoopText(
                            hasGoldJunk
                                ? 'MECHA JUNKAN HUD'
                                : 'SER JUNKAN - LVL ${hasGoldJunk ? "MAX" : (junkCount > 7 ? "7+" : junkCount)}',
                            style: TextStyle(
                              fontSize: FontSizes.labelMedium,
                              fontWeight: FontWeight.w900,
                              color:
                                  hasGoldJunk
                                      ? Skeuo.inkIf(Colors.amberAccent)
                                      : Skeuo.inkIf(Colors.tealAccent),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  hasGoldJunk
                                      ? Skeuo.inkIf(
                                        Colors.amber,
                                      ).withValues(alpha: 0.12)
                                      : Skeuo.inkIf(
                                        Colors.teal,
                                      ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: GoopText(
                              rankName,
                              style: TextStyle(
                                fontSize: FontSizes.labelSmall,
                                fontWeight: FontWeight.w900,
                                color:
                                    hasGoldJunk
                                        ? Skeuo.inkIf(Colors.amberAccent)
                                        : Skeuo.inkIf(Colors.tealAccent),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _collapsed ? Icons.expand_more : Icons.expand_less,
                            size: 16,
                            color: Colors.white54,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child:
                    _collapsed
                        ? const SizedBox.shrink()
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(color: Colors.white12, height: 1),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.all(Radii.sm),
                                      border: Border.all(
                                        color:
                                            hasGoldJunk
                                                ? Skeuo.inkIf(
                                                  Colors.amber,
                                                ).withValues(alpha: 0.2)
                                                : Skeuo.inkIf(
                                                  Colors.teal,
                                                ).withValues(alpha: 0.15),
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: Image.asset(
                                      imgPath,
                                      fit: BoxFit.contain,
                                      cacheWidth: 144,
                                      cacheHeight: 144,
                                      errorBuilder:
                                          (_, _, _) => const Icon(
                                            Icons.broken_image_outlined,
                                            color: Colors.white24,
                                            size: 30,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        GoopText(
                                          description,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            color: Colors.white70,
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        GoopText(
                                          stats,
                                          style: TextStyle(
                                            fontSize: FontSizes.labelSmall,
                                            color:
                                                hasGoldJunk
                                                    ? Skeuo.inkIf(
                                                      Colors.amberAccent,
                                                    ).withValues(alpha: 0.8)
                                                    : Skeuo.inkIf(
                                                      Colors.tealAccent,
                                                    ).withValues(alpha: 0.8),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: Insets.sm,
                                                      vertical: Insets.xs,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.02),
                                                  borderRadius:
                                                      BorderRadius.all(
                                                        Radii.sm,
                                                      ),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withValues(
                                                          alpha: 0.04,
                                                        ),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    const GoopText(
                                                      'JUNK',
                                                      style: TextStyle(
                                                        fontSize:
                                                            FontSizes
                                                                .labelSmall,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color: Colors.white60,
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        GestureDetector(
                                                          behavior:
                                                              HitTestBehavior
                                                                  .opaque,
                                                          onTap:
                                                              junkCount > 0 &&
                                                                      junkItem !=
                                                                          null
                                                                  ? () {
                                                                    Haptics.light();
                                                                    p.removeItem(
                                                                      junkItem,
                                                                      slot:
                                                                          widget
                                                                              .slot,
                                                                    );
                                                                  }
                                                                  : null,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 6,
                                                                ),
                                                            child: Icon(
                                                              Icons
                                                                  .remove_circle_rounded,
                                                              color:
                                                                  junkCount > 0
                                                                      ? Colors
                                                                          .tealAccent
                                                                      : Colors
                                                                          .white24,
                                                              size: 30,
                                                            ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                              ),
                                                          child: Text(
                                                            '$junkCount',
                                                            style: const TextStyle(
                                                              fontSize:
                                                                  FontSizes
                                                                      .bodyMedium,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                        GestureDetector(
                                                          behavior:
                                                              HitTestBehavior
                                                                  .opaque,
                                                          onTap:
                                                              junkItem != null
                                                                  ? () {
                                                                    Haptics.light();
                                                                    p.addItem(
                                                                      junkItem,
                                                                      slot:
                                                                          widget
                                                                              .slot,
                                                                    );
                                                                  }
                                                                  : null,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 6,
                                                                ),
                                                            child: const Icon(
                                                              Icons
                                                                  .add_circle_rounded,
                                                              color:
                                                                  Colors
                                                                      .tealAccent,
                                                              size: 30,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: InkWell(
                                                onTap: () {
                                                  if (goldJunkItem != null) {
                                                    if (hasGoldJunk) {
                                                      p.removeItem(
                                                        goldJunkItem,
                                                        slot: widget.slot,
                                                      );
                                                    } else {
                                                      p.addItem(
                                                        goldJunkItem,
                                                        slot: widget.slot,
                                                      );
                                                    }
                                                  }
                                                },
                                                borderRadius: BorderRadius.all(
                                                  Radii.sm,
                                                ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 5,
                                                        horizontal: 8,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        hasGoldJunk
                                                            ? Skeuo.inkIf(
                                                              Colors.amber,
                                                            ).withValues(
                                                              alpha: 0.12,
                                                            )
                                                            : Colors.white
                                                                .withValues(
                                                                  alpha: 0.02,
                                                                ),
                                                    borderRadius:
                                                        BorderRadius.all(
                                                          Radii.sm,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          hasGoldJunk
                                                              ? Skeuo.inkIf(
                                                                Colors.amber,
                                                              ).withValues(
                                                                alpha: 0.4,
                                                              )
                                                              : Colors.white
                                                                  .withValues(
                                                                    alpha: 0.04,
                                                                  ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.flash_on_rounded,
                                                        size: 12,
                                                        color:
                                                            hasGoldJunk
                                                                ? Colors
                                                                    .amberAccent
                                                                : Colors
                                                                    .white30,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      GoopText(
                                                        hasGoldJunk
                                                            ? 'MECH ACTIVE'
                                                            : 'ACTIVATE MECH',
                                                        style: TextStyle(
                                                          fontSize:
                                                              FontSizes
                                                                  .labelSmall,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          color:
                                                              hasGoldJunk
                                                                  ? Colors
                                                                      .amberAccent
                                                                  : Colors
                                                                      .white60,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
