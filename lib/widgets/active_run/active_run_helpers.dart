import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../models/player.dart';
import '../../services/app_theme.dart';
import '../../services/effect_tagger.dart';
import '../../services/multiplayer_session.dart';
import '../../models/multiplayer_messages.dart';
import '../../utils/fast_route.dart';
import '../../services/goop_talk_engine.dart';
import 'dice_roll.dart';
import 'sort_picker.dart';
import '../../screens/effects_summary_screen.dart';
import '../../screens/favourites_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/codex_screen.dart';
import '../../screens/shrine_picker_screen.dart';
import '../../screens/character_select_screen.dart';

/// Shared confirm dialog for clearing a player's inventory.
/// Used by both the active-run HeaderMenu and the Settings Run tab.
void confirmClearInventoryDialog(
    BuildContext context, RunProvider p, PlayerSlot slot) {
  final player = slot == PlayerSlot.main ? p.runState.main : p.runState.coop;
  if (player == null || player.character == null) return;
  final name = player.character!.name;

  showDialog(
    context: context,
    builder: (c) => AlertDialog(
      icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
      title: GoopText("Clear $name's inventory?"),
      content: const GoopText(
        'Removes all guns and items except their starter loadout. '
        'Coolness, curse, and shrine status are unchanged.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const GoopText('Cancel'),
        ),
        FilledButton.tonal(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade900),
          onPressed: () {
            p.clearInventory(slot: slot);
            Navigator.pop(c);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: GoopText("$name's items cleared!"),
              duration: const Duration(seconds: 1),
            ));
          },
          child: const GoopText('Clear Inventory'),
        ),
      ],
    ),
  );
}

/// Compact, always-visible effects accordion that sits right under the
/// character header. Closed by default so it stays out of the way; tap
/// the header bar to expand and inspect every active passive/effect.
class EffectsTile extends StatefulWidget {
  final PlayerSlot slot;
  const EffectsTile({super.key, required this.slot});

  @override
  State<EffectsTile> createState() => EffectsTileState();
}

class EffectsTileState extends State<EffectsTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final state = p.runState;
    final player =
        widget.slot == PlayerSlot.main ? state.main : state.coop;
    if (player == null) return const SizedBox.shrink();
    final scan = EffectTagger.scan(guns: player.guns, items: player.items);
    final tags = scan.keys.toList();
    final totalTags = tags.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Header bar — always visible, single compact line.
            InkWell(
              onTap: totalTags == 0
                  ? null
                  : () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(12, 10, 6, 10),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: Colors.amber, size: 18),
                    const SizedBox(width: 8),
                    const GoopText(
                      'Effects',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: totalTags == 0
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.amber.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$totalTags',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: totalTags == 0
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.amber,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (totalTags > 0)
                      IconButton(
                        tooltip: 'Open detailed breakdown',
                        icon: const Icon(Icons.open_in_new,
                            size: 16, color: Colors.white54),
                        onPressed: () => Navigator.push(
                          context,
                          fastRoute(EffectsSummaryScreen(slot: widget.slot)),
                        ),
                      ),
                    if (totalTags > 0)
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(Icons.expand_more,
                            color: Colors.white54),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GoopText(
                          'none',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.4),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Body — only mounted when expanded; full chip wall.
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _expanded && totalTags > 0
                  ? Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final t in tags)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: t.category.color
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: t.category.color
                                        .withValues(alpha: 0.35)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(t.icon,
                                      size: 12,
                                      color: t.category.color),
                                  const SizedBox(width: 4),
                                  GoopText(
                                    t.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: t.category.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class HeaderMenu extends StatelessWidget {
  const HeaderMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.read<RunProvider>();
    final mpSession = context.watch<MultiplayerSession>();
    final mpActive = mpSession.isActive;
    return PopupMenuButton<String>(
      tooltip: 'Run tools',
      // Big single-icon target — gear is universally read as "options".
      // Bigger hit-rect than the old "Run ▼" chip (44×44 vs 28×24).
      padding: EdgeInsets.zero,
      offset: const Offset(0, 44),
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: const Icon(Icons.tune_rounded, size: 18, color: Colors.white70),
      ),
      onSelected: (v) {
        switch (v) {
          case 'favourites':
            Navigator.push(
              context,
              fastRoute(const FavouritesScreen(embedded: false)),
            );
            break;
          case 'settings':
            Navigator.push(
              context,
              fastRoute(const SettingsScreen()),
            );
            break;
          case 'codex':
            Navigator.push(
              context,
              fastRoute(const CodexScreen(showBackButton: true)),
            );
            break;
          case 'shrine_picker':
            Navigator.push(
              context,
              fastRoute(const ShrinePickerScreen()),
            );
            break;
          case 'add_coop':
            _handleAddCoop(context, p);
            break;
          case 'end_run':
            _confirmEndRun(context, p);
            break;
          case 'leave_mp':
            _confirmLeaveMp(context, mpSession);
            break;
          case 'save_mp_session':
            unawaited(mpSession.saveCurrentSession().then((_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: GoopText('MP session saved'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }).catchError((e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: GoopText('Failed to save session: $e'),
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }));
            break;
          case 'save_run':
            unawaited(p.saveRun().then((_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: GoopText('Run saved'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }).catchError((e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: GoopText('Failed to save run: $e'),
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }));
            break;
          // toggle_dashboards — hidden for now (dashboards always on)
          // case 'toggle_dashboards':
          //   VisualPrefs.setShowDashboards(!VisualPrefs.notifier.value.showDashboards);
          //   Haptics.selection();
          //   break;
          case 'dice_roll':
            showDiceRollDialog(context);
            break;
          case 'reset_items_p1':
            confirmClearInventoryDialog(context, p, PlayerSlot.main);
            break;
          case 'reset_items_p2':
            confirmClearInventoryDialog(context, p, PlayerSlot.coop);
            break;
          case 'pause_mp':
            unawaited(mpSession.pauseRun().then((_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: GoopText('MP run paused — auto-reconnect stopped. Tap Resume when back in range.'),
                    duration: Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }));
            break;
          case 'resume_mp':
            unawaited(mpSession.resumeRun().then((_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: GoopText('MP run resumed — searching for peer...'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }));
            break;
        }
      },
      itemBuilder: (ctx) => [
        // ── NAVIGATION ──
        _menuLabel('NAVIGATION'),
        const PopupMenuItem(
          value: 'favourites',
          child: Row(children: [
            Icon(Icons.favorite_rounded, size: 18, color: Colors.pinkAccent),
            SizedBox(width: 10),
            GoopText('My Favourites'),
          ]),
        ),
        const PopupMenuItem(
          value: 'codex',
          child: Row(children: [
            Icon(Icons.menu_book_rounded, size: 18, color: Colors.tealAccent),
            SizedBox(width: 10),
            GoopText('Codex'),
          ]),
        ),
        PopupMenuItem(
          value: 'shrine_picker',
          child: const Row(children: [
            Icon(Icons.temple_buddhist, size: 18, color: Colors.amber),
            SizedBox(width: 10),
            GoopText('Shrine Picker'),
          ]),
        ),

        // ── ACTIONS ──
        _menuLabel('ACTIONS'),
        const PopupMenuItem(
          value: 'dice_roll',
          child: Row(children: [
            Icon(Icons.casino_outlined, size: 18, color: Color(0xFFFFD54F)),
            SizedBox(width: 10),
            GoopText('Gunfortuna Dice Roll'),
          ]),
        ),
        PopupMenuItem(
          value: 'add_coop',
          child: Row(children: [
            Icon(
              p.runState.hasCoop ? Icons.remove_circle_outline : Icons.person_add_alt_1,
              size: 18,
              color: p.runState.hasCoop ? Colors.redAccent : Colors.pinkAccent,
            ),
            const SizedBox(width: 10),
            GoopText(p.runState.hasCoop ? 'Remove Co-op Player' : 'Add Co-op Player'),
          ]),
        ),
        const PopupMenuItem(
          value: 'reset_items_p1',
          child: Row(children: [
            Icon(Icons.restart_alt_rounded, size: 18, color: Colors.cyanAccent),
            SizedBox(width: 10),
            GoopText('Reset P1 Items'),
          ]),
        ),
        if (p.runState.hasCoop)
          const PopupMenuItem(
            value: 'reset_items_p2',
            child: Row(children: [
              Icon(Icons.restart_alt_rounded, size: 18, color: Colors.pinkAccent),
              SizedBox(width: 10),
              GoopText('Reset P2 Items'),
            ]),
          ),

        // ── SESSION ──
        if (mpActive) ...[
          _menuLabel('SESSION'),
          const PopupMenuItem(
            value: 'save_mp_session',
            child: Row(children: [
              Icon(Icons.cloud_upload_rounded, size: 18, color: Colors.greenAccent),
              SizedBox(width: 10),
              GoopText('Save MP Session'),
            ]),
          ),
          if (mpSession.isPaused)
            const PopupMenuItem(
              value: 'resume_mp',
              child: Row(children: [
                Icon(Icons.play_circle_fill_rounded, size: 18, color: Colors.greenAccent),
                SizedBox(width: 10),
                GoopText('Resume MP Run', style: TextStyle(color: Colors.greenAccent)),
              ]),
            )
          else
            const PopupMenuItem(
              value: 'pause_mp',
              child: Row(children: [
                Icon(Icons.pause_circle_filled_rounded, size: 18, color: Colors.orangeAccent),
                SizedBox(width: 10),
                GoopText('Pause MP Run', style: TextStyle(color: Colors.orangeAccent)),
              ]),
            ),
        ] else ...[
          _menuLabel('SESSION'),
          const PopupMenuItem(
            value: 'save_run',
            child: Row(children: [
              Icon(Icons.save_outlined, size: 18, color: Colors.greenAccent),
              SizedBox(width: 10),
              GoopText('Save Run'),
            ]),
          ),
        ],

        // ── END SESSION ──
        _menuLabel('END SESSION'),
        if (mpActive && mpSession.myRole == MpRole.sidekick) ...[
          const PopupMenuItem(
            value: 'leave_mp',
            child: Row(children: [
              Icon(Icons.bluetooth_disabled,
                  size: 18, color: Colors.lightBlueAccent),
              SizedBox(width: 10),
              GoopText('Leave Multiplayer'),
            ]),
          ),
          const PopupMenuItem(
            value: 'end_run',
            child: Row(children: [
              Icon(Icons.exit_to_app, size: 18, color: Colors.redAccent),
              SizedBox(width: 10),
              GoopText('End Run & Disconnect', style: TextStyle(color: Colors.redAccent)),
            ]),
          ),
        ] else ...[
          const PopupMenuItem(
            value: 'end_run',
            child: Row(children: [
              Icon(Icons.exit_to_app, size: 18, color: Colors.redAccent),
              SizedBox(width: 10),
              GoopText('End Run', style: TextStyle(color: Colors.redAccent)),
            ]),
          ),
        ],

        // ── SETTINGS ──
        _menuLabel('SETTINGS'),
        const PopupMenuItem(
          value: 'settings',
          child: Row(children: [
            Icon(Icons.settings_rounded, size: 18, color: Colors.cyanAccent),
            SizedBox(width: 10),
            GoopText('Settings'),
          ]),
        ),
      ],
    );
  }

  /// Non-interactive section label for the popup menu.
  /// Renders as a small uppercase header with accent color and a divider,
  /// so the menu is scannable at a glance instead of a flat list.
  PopupMenuItem<String> _menuLabel(String label) {
    return PopupMenuItem<String>(
      enabled: false,
      value: '__label__',
      child: Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: Colors.white12, height: 1, thickness: 0.5),
            const SizedBox(height: 6),
            GoopText(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: AppTheme.flair.primary.withValues(alpha: 0.8),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLeaveMp(BuildContext context, MultiplayerSession session) {
    final isSidekick = session.myRole == MpRole.sidekick;
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.bluetooth_disabled,
            color: Colors.lightBlueAccent),
        title: const GoopText('Leave Multiplayer?'),
        content: GoopText(
          isSidekick
              ? 'Disconnects from the host. Your pre-multiplayer solo '
                  'run (if any) will be restored. Items the host gave '
                  'you during this session are not kept.'
              : 'Disconnects from the sidekick. Your run continues '
                  'locally with whatever you currently have.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const GoopText('Stay'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade900),
            onPressed: () async {
              Navigator.pop(c);
              await session.cancel();
            },
            child: const GoopText('Leave'),
          ),
        ],
      ),
    );
  }

  void _confirmEndRun(BuildContext context, RunProvider p) {
    final session = context.read<MultiplayerSession>();
    final isSidekick = session.isActive && session.myRole == MpRole.sidekick;

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
        titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 12),
        contentPadding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
        actionsPadding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
        icon: const Icon(Icons.warning_rounded, color: Colors.redAccent, size: 32),
        title: GoopText(
          isSidekick ? 'End Run & Disconnect?' : 'End Run?',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        content: GoopText(
          isSidekick
              ? 'This will disconnect you from the host, reset the current session, and return you to the main menu.'
              : 'This resets the current run and returns to the main menu.',
          style: const TextStyle(fontSize: 15, height: 1.45),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            onPressed: () => Navigator.pop(c),
            child: const GoopText('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            onPressed: () async {
              Navigator.pop(c);
              if (session.isActive) {
                // Tells the peer to end too, then tears the MP session down cleanly.
                await session.notifyEndRunAndCancel();
              }
              // Wipe local run state and pop screens to return to the main menu
              p.endRun();
            },
            child: GoopText(isSidekick ? 'End & Disconnect' : 'End Run'),
          ),
        ],
      ),
    );
  }

  /// Handle Add/Remove Co-op player from the Run Tools popup.
  void _handleAddCoop(BuildContext context, RunProvider p) {
    if (p.runState.hasCoop) {
      // Confirm removal
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
          title: const GoopText('Remove Co-op Player?'),
          content: GoopText(
            'Removes ${p.runState.coop?.character?.name ?? 'Player 2'} from the run.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const GoopText('Cancel'),
            ),
            FilledButton.tonal(
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade900),
              onPressed: () {
                p.endCoopPlayer();
                Navigator.pop(c);
              },
              child: const GoopText('Remove'),
            ),
          ],
        ),
      );
    } else {
      // Add co-op player — pick character first
      final cultist = p.gungeoneerByName('The Cultist') ??
          p.gungeoneerByName('Cultist');
      if (cultist != null) {
        p.startCoopPlayer(cultist);
      }
      Navigator.push(
        context,
        fastRoute(const CharacterSelectScreen(mode: CharSelectMode.coop)),
      );
    }
  }
}

class SectionHeaderSliver extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;

  /// Optional sort affordance. When provided, the row gains a tappable
  /// pill on the right showing the active sort label and a small
  /// `Icons.sort` glyph that opens a picker bottom sheet on tap.
  final String? sortLabel;
  final VoidCallback? onTapSort;

  /// Optional premium layout selector dropdown.
  final bool showLayoutSelector;
  final InvView? currentInvView;
  final InventoryDisplayMode? currentDisplayMode;
  final ValueChanged<Object>? onLayoutChanged;

  const SectionHeaderSliver({super.key, 
    required this.title,
    required this.count,
    required this.icon,
    this.sortLabel,
    this.onTapSort,
    this.showLayoutSelector = false,
    this.currentInvView,
    this.currentDisplayMode,
    this.onLayoutChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Determine active icon for layout selector button
    IconData getActiveLayoutIcon() {
      if (currentInvView == InvView.list) {
        return Icons.view_list_rounded;
      }
      switch (currentDisplayMode ?? InventoryDisplayMode.classicPeriodic) {
        case InventoryDisplayMode.classicPeriodic:
          return Icons.grid_view_rounded;
        case InventoryDisplayMode.tacticalStats:
          return Icons.assessment_outlined;
      }
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white70),
            const SizedBox(width: 6),
            GoopText(
              '$title  ',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const Spacer(),
            if (sortLabel != null && onTapSort != null && count > 1)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onTapSort,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GoopText(
                          sortLabel!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.sort,
                          size: 13,
                          color: Colors.white54,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (showLayoutSelector && onLayoutChanged != null) ...[
              const SizedBox(width: 6),
              PopupMenuButton<Object>(
                tooltip: 'Select layout style',
                icon: Icon(getActiveLayoutIcon(), size: 18, color: Colors.white70),
                offset: const Offset(0, 36),
                color: const Color(0xFF232326),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Colors.white10),
                ),
                onSelected: onLayoutChanged,
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: InvView.list,
                    child: Row(
                      children: [
                        Icon(Icons.view_list_rounded, size: 15, color: currentInvView == InvView.list ? Colors.amberAccent : Colors.white60),
                        const SizedBox(width: 8),
                        GoopText('List View', style: TextStyle(fontSize: 12, color: currentInvView == InvView.list ? Colors.amberAccent : Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem(
                    value: InventoryDisplayMode.classicPeriodic,
                    child: Row(
                      children: [
                        Icon(Icons.grid_view_rounded, size: 15, color: (currentInvView == InvView.grid && currentDisplayMode == InventoryDisplayMode.classicPeriodic) ? Colors.amberAccent : Colors.white60),
                        const SizedBox(width: 8),
                        GoopText('Periodic Grid', style: TextStyle(fontSize: 12, color: (currentInvView == InvView.grid && currentDisplayMode == InventoryDisplayMode.classicPeriodic) ? Colors.amberAccent : Colors.white)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: InventoryDisplayMode.tacticalStats,
                    child: Row(
                      children: [
                        Icon(Icons.assessment_outlined, size: 15, color: (currentInvView == InvView.grid && currentDisplayMode == InventoryDisplayMode.tacticalStats) ? Colors.amberAccent : Colors.white60),
                        const SizedBox(width: 8),
                        GoopText('Tactical Stats', style: TextStyle(fontSize: 12, color: (currentInvView == InvView.grid && currentDisplayMode == InventoryDisplayMode.tacticalStats) ? Colors.amberAccent : Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// _EmptySection was replaced by StarterHint, which surfaces the
// character's starting loadout as ghosted tappable tiles instead of a
// plain "no items yet" string.

/// Inline coolness/curse adjuster shown by long-pressing either bubble
/// on the run header. Reads the current value from the provider on
/// every rebuild so successive taps stack visibly without dismissing.
///
/// We render four +/- chips per side (-5, -1, +1, +5) which covers the
/// common ETG deltas: most shrines & passives shift coolness by 1, the
/// "big" shrines shift by 4-5. A "Reset to 0" link sits below the row