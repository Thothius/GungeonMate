import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../models/gun.dart';
import '../../models/item.dart';
import '../../models/player.dart';
import '../periodic_tile.dart';
import '../gungeoneer_header.dart';
import '../inventory_list_row.dart';
import '../../services/haptics.dart';
import '../../services/app_theme.dart';
import '../../theme/tokens.dart';
import '../../services/effect_tagger.dart';
import '../../services/mp_session.dart';
import '../paradox/paradox_player_panel.dart';
import '../paradox/surprise_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/fast_route.dart';
import '../../services/goop_talk_engine.dart';
import 'active_run_helpers.dart';
import 'run_effects_block.dart';
import '../dashboards/dashboard_swiper.dart';

import 'stat_sheets.dart';
import '../../utils/format.dart';
import 'sort_picker.dart';
import 'starter_hint.dart';
import '../../screens/item_detail_screen.dart';
import '../../screens/all_synergies_screen.dart';
import '../scale_button.dart';
import '../../models/multiplayer_messages.dart';
import '../skeuo/skeuo_tokens.dart';
part 'player_page/synergy_widgets.dart';

/// A single player's loadout view. Re-usable for main + coop.
/// Coop view hides coolness/curse/synergies (those are run-scope).
///
/// Stateful so each tab can hold its own gun/item sort preference. Sort
/// state intentionally does *not* persist across app restarts — it's a
/// glance preference, not a saved configuration.
class PlayerPage extends StatefulWidget {
  final PlayerSlot slot;
  const PlayerPage({super.key, required this.slot});

  @override
  State<PlayerPage> createState() => PlayerPageState();
}

class PlayerPageState extends State<PlayerPage> {
  // Sort modes are persisted per-slot via SharedPreferences so the
  // user's choice survives player switches *and* app restarts. We
  // initialise to `pickup` (the natural order) and asynchronously
  // hydrate from prefs in initState — the brief flash of pickup-order
  // before hydration is unnoticeable in practice and avoids blocking
  // the first frame on a disk read.
  // Sort pills removed (v3 declutter): inventory always shows pickup
  // order — these stay as constants feeding the (now pass-through)
  // sort helpers.
  final GunSort _gunSort = GunSort.pickup;
  final ItemSort _itemSort = ItemSort.pickup;

  /// Per-slot inventory view mode. Defaults to `grid` (the historical
  /// look). Hydrated alongside the sort prefs and persisted on toggle.
  InvView _invView = InvView.grid;

  /// Which cool/curse stepper is open inside the top panel —
  /// 'cool', 'curse', or null (closed). Tapping the capsule toggles it.
  String? _editStat;

  /// True once the user has explicitly picked a sort *or* the prefs
  /// hydration has resolved — whichever came first. Prevents a slow
  /// initial load from clobbering a fast tap on the sort sheet (rare,
  /// but cheap to defend against).
  bool _sortHydrated = false;

  bool get isMain => widget.slot == PlayerSlot.main;
  PlayerSlot get _slot => widget.slot;

  String get _invViewKey => 'invView.${_slot.name}';

  @override
  void initState() {
    super.initState();
    _loadSortPrefs();
  }

  Future<void> _loadSortPrefs() async {
    try {
      if (!mounted || _sortHydrated) return;
      // Sort pills removed (v3 declutter): inventory is always pickup
      // order — skip the stored sort keys, keep the view-mode key.

      setState(() {
        // Periodic grid is the only view — saved view prefs ignored.
        _invView = InvView.grid;
        _sortHydrated = true;
      });
    } catch (_) {
      // SharedPreferences failed to materialise (rare platform issue).
      // We just keep the in-memory defaults — no UI surface needed.
      _sortHydrated = true;
    }
  }

  void _changeLayout(Object layout) {
    if (layout is InvView) {
      setState(() {
        _invView = layout;
      });
      _saveInvView(layout);
    } else if (layout is InventoryDisplayMode) {
      setState(() {
        _invView = InvView.grid;
      });
      _saveInvView(InvView.grid);
      VisualPrefs.setInventoryDisplayMode(layout);
    }
    Haptics.selection();
  }

  Future<void> _saveInvView(InvView v) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_invViewKey, v.index);
    } catch (_) {
      // Persistence failure is non-fatal.
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final state = p.runState;
    final player = isMain ? state.main : state.coop;
    if (player == null || player.character == null) {
      return const Center(child: GoopText('No player'));
    }
    final activeSynergies = isMain ? p.getActiveSynergies().length : 0;
    final partialSynergies = isMain ? p.getPartialSynergies().length : 0;
    final hasCoop = state.hasCoop;
    // Robot +DMG boost for the cyber badge next to the avatar.
    final isRobot = player.character!.name.toLowerCase().contains('robot');
    final robotDmgBoost =
        isRobot
            ? (p.robotJunk + (p.robotLies ? 1 : 0)) * 5.0 +
                (p.robotGoldJunk ? 500.0 : 0.0)
            : 0.0;

    return ValueListenableBuilder<VisualPrefs>(
      valueListenable: VisualPrefs.notifier,
      builder: (context, prefs, _) {
        // Apply the active sort modes. Pickup-order is a no-op pass-through.
        final guns = sortGuns(player.guns, _gunSort);
        final items = sortItems(player.items, _itemSort);

        // Identify the highest-DPS gun in this player's loadout so both
        // grid and list views can surface it subtly (gold crown tint).
        double effectiveDps(Gun g) {
          if (g.name.toLowerCase() == 'gunderfury') {
            return g.getDynamicDps(gunderLevel: p.gunderfuryLevel);
          }
          return g.dpsValue;
        }

        final topDpsName =
            player.guns.isEmpty
                ? ''
                : player.guns
                    .reduce((a, b) => effectiveDps(a) > effectiveDps(b) ? a : b)
                    .name;

        // Synergy glow: map of lowercased name → Color for every item/gun
        // that is part of a currently-active synergy (combined inventories).
        final glowColors = p.activeSynergyGlowColors;

        final scrollWidget = CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                top: !hasCoop,
                // MP sessions (paradox + classic) swap the heavy gungeoneer
                // header for the compact player panel (avatar + stats +
                // run menu) — same info density, less chrome.
                child:
                    context.read<MpSession>().isActive
                        ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ParadoxPlayerPanel(
                              slot: _slot,
                              onTapMsg: () => SurpriseSheet.open(context),
                            ),
                            // Effects strip is always on — cool/curse
                            // are constant game factors, not a panel
                            // the user toggles.
                            const RunEffectsBlock(),
                          ],
                        )
                        : GungeoneerHeader(
                          character: player.character!,
                          gunCount: player.guns.length,
                          itemCount: player.items.length,
                          activeSynergies: activeSynergies,
                          partialSynergies: partialSynergies,
                          showSynergies: isMain,
                          coolness: state.totalCoolness,
                          curse: state.totalCurse,
                          robotDamageBoost: robotDmgBoost,
                          onTapCoolness:
                              () => setState(
                                () =>
                                    _editStat =
                                        _editStat == 'cool' ? null : 'cool',
                              ),
                          onTapCurse:
                              () => setState(
                                () =>
                                    _editStat =
                                        _editStat == 'curse' ? null : 'curse',
                              ),
                          onLongPressCoolness:
                              () => _showStatAdjuster(context, isCool: true),
                          onLongPressCurse:
                              () => _showStatAdjuster(context, isCool: false),
                          onTapSynergies:
                              () => Navigator.push(
                                context,
                                fastRoute(const AllSynergiesScreen()),
                              ),
                          trailing: const HeaderMenu(),
                          effectChips: EffectTagger.summaryChips(
                            guns: player.guns,
                            items: player.items,
                          ),
                          shrinesUsed: state.shrinesUsed,
                          // Everything below the capsule row lives INSIDE
                          // the panel: cool/curse stepper (slides out)
                          // then the special-item tracker pills.
                          footer: Column(
                            children: [
                              AnimatedSize(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                child:
                                    _editStat == null
                                        ? const SizedBox.shrink()
                                        : _InlineStatStepper(
                                          key: ValueKey(_editStat),
                                          isCool: _editStat == 'cool',
                                        ),
                              ),
                              if (VisualPrefs.notifier.value.showDashboards)
                                DashboardSwiperCard(slot: _slot),
                            ],
                          ),
                        ),
              ),
            ),
            ListenableBuilder(
              listenable: VisualPrefs.notifier,
              builder: (context, _) {
                // Solo embeds the trackers inside the header panel —
                // only the MP path keeps this separate sliver card.
                if (!VisualPrefs.notifier.value.showDashboards ||
                    !context.read<MpSession>().isActive) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return DashboardSwiper(slot: _slot);
              },
            ),
            SectionHeaderSliver(
              title: 'Guns',
              count: guns.length,
              icon: Icons.gps_fixed,
              showLayoutSelector: false,
              currentInvView: _invView,
              currentDisplayMode:
                  VisualPrefs.notifier.value.inventoryDisplayMode,
              onLayoutChanged: _changeLayout,
            ),
            if (guns.isEmpty)
              SliverToBoxAdapter(
                child: StarterHint(
                  character: player.character!,
                  kind: StarterKind.guns,
                  slot: _slot,
                  tileGrid: _tileGrid(context),
                ),
              )
            else if (_invView == InvView.grid)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.md),
                sliver: SliverGrid.builder(
                  gridDelegate: _tileGrid(context),
                  itemCount: guns.length,
                  itemBuilder: (c, i) {
                    final g = guns[i];
                    return RepaintBoundary(
                      child: PeriodicTile(
                        gun: g,
                        isTopDps: g.name == topDpsName,
                        synergyGlowColor: glowColors[g.name.toLowerCase()],
                        onTap:
                            () => Navigator.push(
                              c,
                              fastRoute(
                                ItemDetailScreen(gun: g, ownerSlot: _slot),
                              ),
                            ),
                        onLongPress: () => _promptTileActions(c, gun: g),
                      ),
                    );
                  },
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.md),
                sliver: SliverList.builder(
                  itemCount: guns.length,
                  itemBuilder: (c, i) {
                    final g = guns[i];
                    return RepaintBoundary(
                      child: Dismissible(
                        key: Key('gun_${g.name}_$_slot'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: Insets.xs,
                          ),
                          padding: const EdgeInsets.only(right: 16),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            color: Skeuo.inkIf(
                              Colors.redAccent,
                            ).withValues(alpha: 0.8),
                            borderRadius: BorderRadius.all(Radii.sm),
                          ),
                          child: Icon(
                            Icons.delete_sweep_rounded,
                            color: Skeuo.collapse(Colors.white),
                            size: 24,
                          ),
                        ),
                        onDismissed: (_) {
                          final p = context.read<RunProvider>();
                          p.removeGun(g, slot: _slot);
                          _toast(context, 'Removed ${g.name}');
                        },
                        child: InventoryListRow(
                          gun: g,
                          isTopDps: g.name == topDpsName,
                          synergyGlowColor: glowColors[g.name.toLowerCase()],
                          onTap:
                              () => Navigator.push(
                                c,
                                fastRoute(
                                  ItemDetailScreen(gun: g, ownerSlot: _slot),
                                ),
                              ),
                          onLongPress: () => _promptTileActions(c, gun: g),
                        ),
                      ),
                    );
                  },
                ),
              ),
            SectionHeaderSliver(
              title: 'Items',
              count: items.length,
              icon: Icons.inventory_2_outlined,
              showLayoutSelector: false,
              currentInvView: _invView,
              currentDisplayMode:
                  VisualPrefs.notifier.value.inventoryDisplayMode,
              onLayoutChanged: _changeLayout,
            ),
            if (items.isEmpty)
              SliverToBoxAdapter(
                child: StarterHint(
                  character: player.character!,
                  kind: StarterKind.items,
                  slot: _slot,
                  tileGrid: _tileGrid(context),
                ),
              )
            else if (_invView == InvView.grid)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                sliver: SliverGrid.builder(
                  gridDelegate: _tileGrid(context),
                  itemCount: items.length,
                  itemBuilder: (c, i) {
                    final it = items[i];
                    return RepaintBoundary(
                      child: PeriodicTile(
                        item: it,
                        synergyGlowColor: glowColors[it.name.toLowerCase()],
                        onTap:
                            () => Navigator.push(
                              c,
                              fastRoute(
                                ItemDetailScreen(item: it, ownerSlot: _slot),
                              ),
                            ),
                        onLongPress: () => _promptTileActions(c, item: it),
                      ),
                    );
                  },
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                sliver: SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (c, i) {
                    final it = items[i];
                    return RepaintBoundary(
                      child: Dismissible(
                        key: Key('item_${it.name}_$_slot'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: Insets.xs,
                          ),
                          padding: const EdgeInsets.only(right: 16),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            color: Skeuo.inkIf(
                              Colors.redAccent,
                            ).withValues(alpha: 0.8),
                            borderRadius: BorderRadius.all(Radii.sm),
                          ),
                          child: Icon(
                            Icons.delete_sweep_rounded,
                            color: Skeuo.collapse(Colors.white),
                            size: 24,
                          ),
                        ),
                        onDismissed: (_) {
                          final p = context.read<RunProvider>();
                          p.removeItem(it, slot: _slot);
                          _toast(context, 'Removed ${it.name}');
                        },
                        child: InventoryListRow(
                          item: it,
                          synergyGlowColor: glowColors[it.name.toLowerCase()],
                          onTap:
                              () => Navigator.push(
                                c,
                                fastRoute(
                                  ItemDetailScreen(item: it, ownerSlot: _slot),
                                ),
                              ),
                          onLongPress: () => _promptTileActions(c, item: it),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );

        return scrollWidget;
      },
    );
  }

  /// Inline +/- bottom sheet for a quick coolness/curse tweak — opened
  /// by long-pressing either bubble in the [GungeoneerHeader]. Live-rebinds
  /// to the latest provider state so the displayed number updates after
  /// each tap without dismissing the sheet.
  void _showStatAdjuster(BuildContext c, {required bool isCool}) {
    showModalBottomSheet<void>(
      context: c,
      backgroundColor: AppTheme.flair.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => StatAdjusterSheet(isCool: isCool),
    );
  }

  /// Direct transfer — no confirm sheet (the floating pill IS the
  /// confirm). MP: sendGift removes locally + ships; local co-op
  /// shuffles slots in RunProvider. Logs to the messages list.
  void _transferDirect(BuildContext c, {Gun? gun, Item? item}) {
    final p = c.read<RunProvider>();
    final session = c.read<MpSession>();
    final name = gun?.name ?? item?.name ?? '';
    final peerName = session.peerNickname ?? 'Player 2';
    if (session.isActive && session.isConnected) {
      final isMyInv = session.mySlot == _slot;
      if (isMyInv) {
        unawaited(
          session.sendGift(kind: gun != null ? 'gun' : 'item', name: name),
        );
        session.logEvent(
          MpEvent.event(
            kind: 'transfer',
            from: session.myNickname,
            text: '$name → $peerName',
            mine: true,
          ),
        );
      } else {
        unawaited(
          session.sendRequest(kind: gun != null ? 'gun' : 'item', name: name),
        );
        session.logEvent(
          MpEvent.event(
            kind: 'transfer',
            from: session.myNickname,
            text: 'Asked $peerName for $name',
            mine: true,
          ),
        );
      }
    } else {
      final ok =
          gun != null
              ? p.transferGun(gun, _slot)
              : p.transferItem(item!, _slot);
      if (c.mounted) {
        _toast(c, ok ? '$name → $peerName' : '$peerName already has $name');
      }
    }
    Haptics.medium();
  }

  bool _transferArmed = false;

  void _toast(BuildContext c, String msg) {
    final m = ScaffoldMessenger.maybeOf(c);
    if (m == null) return;
    m.hideCurrentSnackBar();
    m.showSnackBar(
      SnackBar(
        content: GoopText(msg),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  SliverGridDelegate _tileGrid(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    int cross;
    double ratio;

    // View lock — Periodic grid is the only layout regardless of
    // the saved display-mode pref. Other renderers stay dormant.
    switch (InventoryDisplayMode.classicPeriodic) {
      case InventoryDisplayMode.classicPeriodic:
        final savedColCount =
            VisualPrefs.notifier.value.periodicGridColumnCount;
        cross =
            (savedColCount > 0)
                ? savedColCount
                : (w < 360
                    ? 3
                    : w < 600
                    ? 4
                    : 6);
        ratio = 0.75; // BUG-035: bumped from 0.80 to fit type subtitle + RANGE
        break;
      case InventoryDisplayMode.tacticalStats:
        cross =
            w < 500
                ? 2
                : w < 850
                ? 3
                : 4;
        ratio = 0.95;
        break;
    }

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: cross,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: ratio,
    );
  }

  /// Solo-mode quick-actions sheet shown on long-press. Exactly one of
  /// [gun]/[item] must be non-null. Surfaces Open / Favourite / Remove
  /// in a single 3-tap-target sheet so the user can manage their loadout
  /// without leaving the inventory tab.
  void _promptTileActions(BuildContext c, {Gun? gun, Item? item}) {
    assert((gun == null) != (item == null), 'Pass exactly one of gun/item');
    final p = c.read<RunProvider>();
    final mpSession = c.read<MpSession>();
    final hasCoop = p.runState.hasCoop;
    final isMpActive = mpSession.phase != MpPhase.idle;
    final canTransfer = hasCoop && (!isMpActive || mpSession.isConnected);

    // Floating quick-actions — two circular buttons hovering over the
    // card: transfer + trash. Tap-away dismisses (barrierDismissible).
    _transferArmed = false;
    showDialog<void>(
      context: c,
      barrierDismissible: true,
      barrierColor: Skeuo.collapse(Colors.black).withValues(alpha: 0.35),
      builder: (dlgCtx) {
        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.flair.card,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppTheme.flair.primary.withValues(alpha: 0.25),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Skeuo.collapse(Colors.black).withValues(alpha: 0.45),
                  blurRadius: 16,
                ),
              ],
            ),
            child: StatefulBuilder(
              builder: (_, setArmed) {
                var armed = _transferArmed;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canTransfer)
                      _QuickActionBtn(
                        icon:
                            armed
                                ? Icons.check_rounded
                                : Icons.swap_horiz_rounded,
                        color:
                            armed
                                ? Skeuo.inkIf(Colors.orangeAccent)
                                : AppTheme.flair.primary,
                        onTap: () {
                          if (!armed) {
                            setArmed(() => _transferArmed = true);
                            return;
                          }
                          Navigator.pop(dlgCtx);
                          _transferDirect(c, gun: gun, item: item);
                        },
                      ),
                    if (canTransfer) const SizedBox(width: 14),
                    _QuickActionBtn(
                      icon: Icons.delete_outline_rounded,
                      color: Skeuo.inkIf(Colors.redAccent),
                      onTap: () {
                        Navigator.pop(dlgCtx);
                        if (gun != null) {
                          _removeGunWithUndo(c, gun);
                        } else {
                          _removeItemWithUndo(c, item!);
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Remove [g] from the loadout and surface a 5-second snackbar with an
  /// UNDO action. UNDO simply re-adds the gun via [RunProvider.addGun] —
  /// pickup-order is lost (it goes to the end of the list), but every
  /// other piece of state is preserved.
  ///
  /// Captures [_slot] into a local before constructing the closure so the
  /// UNDO action stays valid even if the user navigates away from this
  /// page before the snackbar times out.
  void _removeGunWithUndo(BuildContext c, Gun g) {
    final p = c.read<RunProvider>();
    final capturedSlot = _slot;
    p.removeGun(g, slot: capturedSlot);
    final messenger = ScaffoldMessenger.of(c);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: GoopText(
          'Removed ${g.name}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            p.addGun(g, slot: capturedSlot);
          },
        ),
      ),
    );
  }

  void _removeItemWithUndo(BuildContext c, Item it) {
    final p = c.read<RunProvider>();
    final capturedSlot = _slot;
    p.removeItem(it, slot: capturedSlot);
    final messenger = ScaffoldMessenger.of(c);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: GoopText(
          'Removed ${it.name}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            p.addItem(it, slot: capturedSlot);
          },
        ),
      ),
    );
  }
}

/// Vertical synergy panel — lists all synergies that are active or partial
/// (at least one required item owned). Each row shows the synergy name,
/// effect text, and big item pills with graphics. Owned items are full-color
/// with a glow; unowned items are greyed but still visible.
// ignore: unused_element

/// Inline cool/curse stepper — slides out inside the header panel when
/// a capsule is tapped. Centered live number + ±1/±0.5 buttons, nothing
/// else (per user request — no bloat). Replaces the bottom sheet.
class _InlineStatStepper extends StatelessWidget {
  final bool isCool;
  const _InlineStatStepper({super.key, required this.isCool});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final value = isCool ? p.runState.coolness : p.runState.curse;
    final accent =
        isCool
            ? Skeuo.inkIf(Skeuo.collapse(Color(0xFF4DD0E1)))
            : Skeuo.inkIf(Skeuo.collapse(Color(0xFFBA68C8)));

    void apply(double delta) {
      if (isCool) {
        p.adjustCoolness(delta);
      } else {
        p.adjustCurse(delta);
      }
      Haptics.light();
    }

    Widget step(double delta) {
      final positive = delta > 0;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: GestureDetector(
            onTap: () => apply(delta),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: positive ? 0.14 : 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: accent.withValues(alpha: positive ? 0.5 : 0.25),
                ),
              ),
              child: Center(
                child: GoopText(
                  '${positive ? '+' : '−'}${delta.abs() == 1.0 ? '1' : '0.5'}',
                  style: TextStyle(
                    fontSize: FontSizes.bodyMedium,
                    fontWeight: FontWeight.w900,
                    color:
                        positive
                            ? accent
                            : Skeuo.collapse(
                              Colors.white,
                            ).withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Column(
        children: [
          Container(
            height: 1,
            color: Skeuo.collapse(Colors.white).withValues(alpha: 0.06),
            margin: const EdgeInsets.only(bottom: 8),
          ),
          Row(
            children: [
              step(-1),
              step(-0.5),
              // Centered number — the single focus of the control.
              Expanded(
                flex: 2,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: GoopText(
                      key: ValueKey(value),
                      formatStat(value),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: accent,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
              step(0.5),
              step(1),
            ],
          ),
        ],
      ),
    );
  }
}
