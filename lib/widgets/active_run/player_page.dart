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
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/fast_route.dart';
import '../../services/goop_talk_engine.dart';
import 'active_run_helpers.dart';
import 'run_effects_block.dart';
import '../dashboards/dashboard_swiper.dart';

import '../../screens/cool_curse_screen.dart';
import 'cool_curse_sheet.dart';
import '../../screens/item_detail_screen.dart';
import 'sort_picker.dart';
import 'starter_hint.dart';
import '../../screens/all_synergies_screen.dart';
import '../../screens/damage_breakdown_screen.dart';
import '../../screens/shrine_picker_screen.dart';
import '../../screens/backpack_screen.dart';
import 'dash_capsules.dart';
import '../scale_button.dart';

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

  /// True once the user has explicitly picked a sort *or* the prefs
  /// hydration has resolved — whichever came first. Prevents a slow
  /// initial load from clobbering a fast tap on the sort sheet (rare,
  /// but cheap to defend against).
  bool _sortHydrated = false;

  /// User-pinned dash capsules for this slot (max 3). Hydrated from
  /// SharedPreferences; the "+" capsule picker mutates + persists.
  List<DashCapsule> _capsulePins = const <DashCapsule>[];

  bool get isMain => widget.slot == PlayerSlot.main;
  PlayerSlot get _slot => widget.slot;

  String get _invViewKey => 'invView.${_slot.name}';

  @override
  void initState() {
    super.initState();
    _loadSortPrefs();
    _loadCapsulePins();
  }

  Future<void> _loadCapsulePins() async {
    final pins = await loadDashCapsules(_slot);
    if (mounted) setState(() => _capsulePins = pins);
  }

  void _saveCapsulePins(List<DashCapsule> pins) {
    setState(() => _capsulePins = pins);
    saveDashCapsules(_slot, pins);
  }

  void _onDashCapsuleTap(DashCapsule cap, RunProvider p) {
    switch (cap) {
      case DashCapsule.steal:
        // Consequential mutation — matches the Cool/Curse sheet's
        // medium haptic for STEAL rather than a light selection tick.
        p.logSteal();
        Haptics.medium();
      case DashCapsule.useShrine:
        Haptics.selection();
        Navigator.push(context, fastRoute(const ShrinePickerScreen()));
      case DashCapsule.syn:
        Haptics.selection();
        Navigator.push(context, fastRoute(const AllSynergiesScreen()));
      case DashCapsule.dps:
        Haptics.selection();
        Navigator.push(
          context,
          fastRoute(DamageBreakdownScreen(slot: _slot)),
        );
    }
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
        // Backpack-stashed gear stays in the player's lists (it still
        // counts for synergies/DPS/coolness) but is filtered out of the
        // open inventory view — the Backpack screen shows it instead.
        final guns = sortGuns(player.guns, _gunSort)
            .where((g) => !p.isBackpacked(g, _slot))
            .toList();
        final items = sortItems(player.items, _itemSort)
            .where((i) => !p.isBackpackedItem(i, _slot))
            .toList();
        final stashedCount = p.backpackCount(_slot);
        // Per-section stashed counts for the "all stowed" cards — the
        // bag is a mixed pool, so the header total would mislabel.
        int stashedOf(bool isGun) => p
            .backpackEntries(_slot)
            .where((e) => (e.gun != null) == isGun)
            .length;

        // Identify the highest-DPS gun in this player's loadout so both
        // grid and list views can surface it subtly (gold crown tint).
        // Live form-aware DPS via the provider — same number the DPS
        // dash capsule and breakdown screen show.
        double effectiveDps(Gun g) => p.gunDps(g);

        final topDps =
            player.guns.isEmpty
                ? 0.0
                : player.guns
                    .map(effectiveDps)
                    .reduce((a, b) => a > b ? a : b);

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
                            ParadoxPlayerPanel(slot: _slot),
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
                          coolness: state.totalCoolness,
                          curse: state.totalCurse,
                          robotDamageBoost: robotDmgBoost,
                          onTapCoolness:
                              () => CoolCurseSheet.show(
                                context,
                                isCool: true,
                              ),
                          onTapCurse:
                              () => CoolCurseSheet.show(
                                context,
                                isCool: false,
                              ),
                          // Long-press opens the full Cool & Curse
                          // explainer — the same screen MP players get
                          // from the Paradox panel — so solo users see
                          // the mechanics, not just bare steppers.
                          onLongPressCoolness:
                              () => Navigator.push(
                                context,
                                fastRoute(const CoolCurseScreen()),
                              ),
                          onLongPressCurse:
                              () => Navigator.push(
                                context,
                                fastRoute(const CoolCurseScreen()),
                              ),
                          trailing: const HeaderMenu(),
                          effectChips: EffectTagger.summaryChips(
                            guns: player.guns,
                            items: player.items,
                          ),
                          shrinesUsed: state.shrinesUsed,
                          dashCapsules: _capsulePins,
                          topGunDps: topDps,
                          onDashCapsuleTap:
                              (cap) => _onDashCapsuleTap(cap, p),
                          onDashCapsulesEdit: () {
                            Haptics.selection();
                            showDashCapsulePicker(
                              context: context,
                              pinned: _capsulePins,
                              onChanged: _saveCapsulePins,
                            );
                          },
                          // Everything below the capsule row lives INSIDE
                          // the panel: cool/curse stepper (slides out)
                          // then the special-item tracker pills.
                          footer: Column(
                            children: [
                              // Listenable so the PANELS settings toggle
                              // shows/hides trackers without a rebuild.
                              ValueListenableBuilder<VisualPrefs>(
                                valueListenable: VisualPrefs.notifier,
                                builder:
                                    (_, p, _) =>
                                        p.showDashboards
                                            ? DashboardSwiperCard(slot: _slot)
                                            : const SizedBox.shrink(),
                              ),
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
              player.guns.isEmpty
                  ? SliverToBoxAdapter(
                    child: StarterHint(
                      character: player.character!,
                      kind: StarterKind.guns,
                      slot: _slot,
                      tileGrid: _tileGrid(context),
                    ),
                  )
                  : SliverToBoxAdapter(
                    child: _AllStowedCard(
                      label: 'guns',
                      stashedCount: stashedOf(true),
                      onOpen: () => _openBackpack(context),
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
                            color: Colors.redAccent.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.all(Radii.sm),
                          ),
                          child: const Icon(
                            Icons.delete_sweep_rounded,
                            color: Colors.white,
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
              // Backpack shortcut — always reachable while the player
              // owns the bag (or has gear stowed), even if the item
              // itself was deleted mid-run.
              trailing:
                  (p.backpackCount(_slot) > 0 || p.ownsBackpack(_slot))
                      ? _BackpackHeaderBtn(
                        count: stashedCount,
                        onTap: () => _openBackpack(context),
                      )
                      : null,
            ),
            if (items.isEmpty)
              player.items.isEmpty
                  ? SliverToBoxAdapter(
                    child: StarterHint(
                      character: player.character!,
                      kind: StarterKind.items,
                      slot: _slot,
                      tileGrid: _tileGrid(context),
                    ),
                  )
                  : SliverToBoxAdapter(
                    child: _AllStowedCard(
                      label: 'items',
                      stashedCount: stashedOf(false),
                      onOpen: () => _openBackpack(context),
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
                        onTap: () => _openItem(c, it),
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
                            color: Colors.redAccent.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.all(Radii.sm),
                          ),
                          child: const Icon(
                            Icons.delete_sweep_rounded,
                            color: Colors.white,
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
                          onTap: () => _openItem(c, it),
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

  /// Tap routing for item tiles — the app-only Backpack opens its
  /// storage screen instead of the (empty) detail page.
  void _openItem(BuildContext c, Item it) {
    if (it.name == RunProvider.kBackpackItemName) {
      Navigator.push(c, fastRoute(BackpackScreen(slot: _slot)));
    } else {
      Navigator.push(
        c,
        fastRoute(ItemDetailScreen(item: it, ownerSlot: _slot)),
      );
    }
  }

  void _openBackpack(BuildContext c) {
    Haptics.selection();
    Navigator.push(c, fastRoute(BackpackScreen(slot: _slot)));
  }

  /// Stash [gun]/[item] into this slot's backpack. Returns feedback
  /// via toast; the pill dialog is already dismissed by the caller.
  void _stashWithFeedback(BuildContext c, {Gun? gun, Item? item}) {
    final p = c.read<RunProvider>();
    final name = gun?.name ?? item?.name ?? '';
    final ok =
        gun != null
            ? p.stashGun(gun, slot: _slot)
            : p.stashItem(item!, slot: _slot);
    if (c.mounted) {
      _toast(
        c,
        ok ? '$name stowed in backpack' : 'Backpack full (12/12)',
      );
    }
    Haptics.medium();
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
      } else {
        unawaited(
          session.sendRequest(kind: gun != null ? 'gun' : 'item', name: name),
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
        cross =
            w < 360
                ? 3
                : w < 600
                ? 4
                : 6;
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
      barrierColor: Colors.black.withValues(alpha: 0.35),
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
                  color: Colors.black.withValues(alpha: 0.45),
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
                                ? Colors.orangeAccent
                                : AppTheme.flair.primary,
                        label: armed ? 'SURE?' : 'SEND',
                        onTap: () {
                          if (!armed) {
                            setArmed(() => _transferArmed = true);
                            return;
                          }
                          Navigator.pop(dlgCtx);
                          _transferDirect(c, gun: gun, item: item);
                        },
                      ),
                    // STASH — always available (the Backpack's whole
                    // point). Hidden for the Backpack item itself: the
                    // bag can't hold itself.
                    if (item == null ||
                        item.name != RunProvider.kBackpackItemName) ...[
                      if (canTransfer) const SizedBox(width: 12),
                      _QuickActionBtn(
                        icon: Icons.backpack_outlined,
                        color: const Color(0xFF8D6E63),
                        label: 'STASH',
                        onTap: () {
                          Navigator.pop(dlgCtx);
                          _stashWithFeedback(c, gun: gun, item: item);
                        },
                      ),
                    ],
                    const SizedBox(width: 12),
                    _QuickActionBtn(
                      icon: Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      label: 'DELETE',
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
