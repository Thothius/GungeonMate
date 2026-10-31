import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../models/player.dart';
import '../../services/app_theme.dart';
import '../../theme/tokens.dart';
import '../../services/haptics.dart';
import '../../services/effect_tagger.dart';
import '../../services/mp_session.dart';
import '../../utils/fast_route.dart';
import '../../screens/ammonomicon_screen.dart';
import '../../services/goop_talk_engine.dart';
import '../../screens/effects_summary_screen.dart';
import '../../screens/shrine_picker_screen.dart';
import 'sort_picker.dart';
import 'dice_roll.dart';
import '../paradox/surprise_sheet.dart';
import '../../services/run_lifecycle.dart';
import '../../screens/settings_screen.dart';
import '../../screens/experience_studio_screen.dart';
import '../../screens/quiz/quiz_home_screen.dart';

/// Shared confirm dialog for clearing a player's inventory.
/// Used by both the active-run HeaderMenu and the Settings Run tab.
void confirmClearInventoryDialog(
  BuildContext context,
  RunProvider p,
  PlayerSlot slot,
) {
  final player = slot == PlayerSlot.main ? p.runState.main : p.runState.coop;
  if (player == null || player.character == null) return;
  final name = player.character!.name;

  showDialog(
    context: context,
    builder:
        (c) => AlertDialog(
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
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade900,
              ),
              onPressed: () {
                p.clearInventory(slot: slot);
                Navigator.pop(c);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: GoopText("$name's items cleared!"),
                    duration: const Duration(seconds: 1),
                  ),
                );
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
    final player = widget.slot == PlayerSlot.main ? state.main : state.coop;
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
              onTap:
                  totalTags == 0
                      ? null
                      : () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.amber,
                      size: 18,
                    ),
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
                        horizontal: 7,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color:
                            totalTags == 0
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.amber.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$totalTags',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color:
                              totalTags == 0
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : Colors.amber,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (totalTags > 0)
                      IconButton(
                        tooltip: 'Open detailed breakdown',
                        icon: const Icon(
                          Icons.open_in_new,
                          size: 16,
                          color: Colors.white54,
                        ),
                        onPressed:
                            () => Navigator.push(
                              context,
                              fastRoute(
                                EffectsSummaryScreen(slot: widget.slot),
                              ),
                            ),
                      ),
                    if (totalTags > 0)
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(
                          Icons.expand_more,
                          color: Colors.white54,
                        ),
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
              child:
                  _expanded && totalTags > 0
                      ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final t in tags)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: t.category.color.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: t.category.color.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      t.icon,
                                      size: 12,
                                      color: t.category.color,
                                    ),
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
    return Container(
      width: 44,
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: IconButton(
        tooltip: 'Run tools',
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.tune_rounded, size: 24, color: Colors.white70),
        onPressed: () {
          Haptics.selection();
          showModalBottomSheet<void>(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (ctx) => _RunToolsSheet(parentContext: context),
          );
        },
      ),
    );
  }
}

/// Themed run-tools sheet — the gear menu. Fixed action set per design:
/// Ammonomicon, Shrines, Dice Roll, Surprise (MP only), Reset items,
/// End run. Groups: tools → reset → danger.
class _RunToolsSheet extends StatelessWidget {
  /// Context from ABOVE the sheet route — sheet ctx is dead after pop.
  final BuildContext parentContext;
  const _RunToolsSheet({required this.parentContext});

  Widget _action(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final flair = AppTheme.flair;
    return InkWell(
      borderRadius: BorderRadius.all(Radii.sm),
      onTap: () {
        Haptics.selection();
        Navigator.pop(context);
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.md,
          vertical: 13,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: GoopText(
                label,
                style: const TextStyle(
                  fontSize: FontSizes.bodyMedium,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: flair.primary.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, ThemeFlair flair) => Padding(
    padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.md, Insets.lg, 4),
    child: GoopText(
      text,
      style: TextStyle(
        fontSize: FontSizes.labelMedium,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: flair.primary.withValues(alpha: 0.5),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final mpSession = context.watch<MpSession>();
    final p = context.read<RunProvider>();
    final hasCoop = p.runState.hasCoop;
    final sheetCtx = parentContext;

    return Container(
      decoration: BoxDecoration(
        color: flair.card,
        borderRadius: Radii.sheet,
        border: Border(
          top: BorderSide(color: flair.primary.withValues(alpha: 0.2)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grab handle.
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: Insets.sm),
              decoration: BoxDecoration(
                color: flair.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _label('RUN TOOLS', flair),
            _action(
              sheetCtx,
              icon: Icons.menu_book_rounded,
              label: 'Ammonomicon',
              iconColor: const Color(0xFF4DD0E1),
              onTap: () {
                if (sheetCtx.mounted) {
                  Navigator.push(
                    sheetCtx,
                    fastRoute(const AmmonomiconScreen()),
                  );
                }
              },
            ),
            _action(
              sheetCtx,
              icon: Icons.temple_buddhist,
              label: 'Shrines',
              iconColor: Colors.amberAccent,
              onTap: () {
                if (sheetCtx.mounted) {
                  Navigator.push(
                    sheetCtx,
                    fastRoute(const ShrinePickerScreen()),
                  );
                }
              },
            ),
            _action(
              sheetCtx,
              icon: Icons.casino_rounded,
              label: 'Dice Roller',
              iconColor: const Color(0xFFFFD54F),
              onTap: () => showDiceRollDialog(sheetCtx),
            ),
            if (mpSession.isActive)
              _action(
                sheetCtx,
                icon: Icons.auto_awesome_rounded,
                label: 'Surprise',
                iconColor: Colors.amberAccent,
                onTap:
                    () => showModalBottomSheet<void>(
                      context: sheetCtx,
                      isScrollControlled: true,
                      backgroundColor: const Color(0xFF140B22),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                      ),
                      builder: (_) => const SurpriseSheet(),
                    ),
              ),
            Divider(
              height: 1,
              thickness: 0.5,
              indent: Insets.lg,
              endIndent: Insets.lg,
              color: flair.primary.withValues(alpha: 0.1),
            ),
            _label('RESET', flair),
            _action(
              sheetCtx,
              icon: Icons.restart_alt_rounded,
              label: hasCoop ? 'Reset P1 Items' : 'Reset Items',
              iconColor: Colors.cyanAccent,
              onTap:
                  () =>
                      confirmClearInventoryDialog(sheetCtx, p, PlayerSlot.main),
            ),
            if (hasCoop)
              _action(
                sheetCtx,
                icon: Icons.restart_alt_rounded,
                label: 'Reset P2 Items',
                iconColor: Colors.cyanAccent,
                onTap:
                    () => confirmClearInventoryDialog(
                      sheetCtx,
                      p,
                      PlayerSlot.coop,
                    ),
              ),
            Divider(
              height: 1,
              thickness: 0.5,
              indent: Insets.lg,
              endIndent: Insets.lg,
              color: flair.primary.withValues(alpha: 0.1),
            ),
            _action(
              sheetCtx,
              icon: Icons.draw_rounded,
              label: 'Neo-Skeuo ${AppTheme.isSkeuo ? '· ON' : '· OFF'}',
              iconColor:
                  AppTheme.isSkeuo
                      ? const Color(0xFF1F1B16)
                      : const Color(0xFF8D6E63),
              onTap: () {
                if (AppTheme.isSkeuo) {
                  AppTheme.exitSkeuo();
                } else {
                  AppTheme.enterSkeuo();
                }
              },
            ),
            _action(
              sheetCtx,
              icon:
                  AppTheme.isSkeuo
                      ? Icons.lock_outline_rounded
                      : Icons.palette_rounded,
              label:
                  AppTheme.isSkeuo
                      ? 'Customize (locked in Neo-Skeuo)'
                      : 'Customize',
              iconColor:
                  AppTheme.isSkeuo
                      ? flair.primary.withValues(alpha: 0.35)
                      : const Color(0xFFB388FF),
              onTap: () {
                if (AppTheme.isSkeuo || !sheetCtx.mounted) return;
                Navigator.push(
                  sheetCtx,
                  fastRoute(const ExperienceStudioScreen()),
                );
              },
            ),
            _action(
              sheetCtx,
              icon: Icons.quiz_rounded,
              label: 'Quiz',
              iconColor: const Color(0xFF66BB6A),
              onTap: () {
                if (sheetCtx.mounted) {
                  Navigator.push(
                    sheetCtx,
                    fastRoute(const QuizHomeScreen(showBackButton: true)),
                  );
                }
              },
            ),
            _action(
              sheetCtx,
              icon: Icons.settings_outlined,
              label: 'Preferences',
              iconColor: flair.primary.withValues(alpha: 0.6),
              onTap: () {
                if (sheetCtx.mounted) {
                  Navigator.push(sheetCtx, fastRoute(const SettingsScreen()));
                }
              },
            ),
            Divider(
              height: 1,
              thickness: 0.5,
              indent: Insets.lg,
              endIndent: Insets.lg,
              color: flair.primary.withValues(alpha: 0.1),
            ),
            _action(
              sheetCtx,
              icon: Icons.flag_rounded,
              label: 'End Run',
              iconColor: Colors.redAccent,
              onTap: () => RunLifecycle.confirmEndRun(sheetCtx),
            ),
            const SizedBox(height: Insets.sm),
          ],
        ),
      ),
    );
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

  const SectionHeaderSliver({
    super.key,
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
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
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
                        const Icon(Icons.sort, size: 13, color: Colors.white54),
                      ],
                    ),
                  ),
                ),
              ),
            if (showLayoutSelector && onLayoutChanged != null) ...[
              const SizedBox(width: 6),
              PopupMenuButton<Object>(
                tooltip: 'Select layout style',
                icon: Icon(
                  getActiveLayoutIcon(),
                  size: 18,
                  color: Colors.white70,
                ),
                offset: const Offset(0, 36),
                color: const Color(0xFF232326),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Colors.white10),
                ),
                onSelected: onLayoutChanged,
                itemBuilder:
                    (ctx) => [
                      PopupMenuItem(
                        value: InvView.list,
                        child: Row(
                          children: [
                            Icon(
                              Icons.view_list_rounded,
                              size: 15,
                              color:
                                  currentInvView == InvView.list
                                      ? Colors.amberAccent
                                      : Colors.white60,
                            ),
                            const SizedBox(width: 8),
                            GoopText(
                              'List View',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    currentInvView == InvView.list
                                        ? Colors.amberAccent
                                        : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(height: 1),
                      PopupMenuItem(
                        value: InventoryDisplayMode.classicPeriodic,
                        child: Row(
                          children: [
                            Icon(
                              Icons.grid_view_rounded,
                              size: 15,
                              color:
                                  (currentInvView == InvView.grid &&
                                          currentDisplayMode ==
                                              InventoryDisplayMode
                                                  .classicPeriodic)
                                      ? Colors.amberAccent
                                      : Colors.white60,
                            ),
                            const SizedBox(width: 8),
                            GoopText(
                              'Periodic Grid',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    (currentInvView == InvView.grid &&
                                            currentDisplayMode ==
                                                InventoryDisplayMode
                                                    .classicPeriodic)
                                        ? Colors.amberAccent
                                        : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: InventoryDisplayMode.tacticalStats,
                        child: Row(
                          children: [
                            Icon(
                              Icons.assessment_outlined,
                              size: 15,
                              color:
                                  (currentInvView == InvView.grid &&
                                          currentDisplayMode ==
                                              InventoryDisplayMode
                                                  .tacticalStats)
                                      ? Colors.amberAccent
                                      : Colors.white60,
                            ),
                            const SizedBox(width: 8),
                            GoopText(
                              'Tactical Stats',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    (currentInvView == InvView.grid &&
                                            currentDisplayMode ==
                                                InventoryDisplayMode
                                                    .tacticalStats)
                                        ? Colors.amberAccent
                                        : Colors.white,
                              ),
                            ),
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
