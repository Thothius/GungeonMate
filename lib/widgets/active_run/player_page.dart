import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../models/gun.dart';
import '../../models/item.dart';
import '../../models/player.dart';
import '../../models/synergy.dart';
import '../periodic_tile.dart';
import '../gungeoneer_header.dart';
import '../inventory_list_row.dart';
import '../../services/haptics.dart';
import '../../services/app_theme.dart';
import '../../services/effect_tagger.dart';
import '../../services/damage_calculator.dart';
import '../../services/multiplayer_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/fast_route.dart';
import '../../services/goop_talk_engine.dart';
import 'active_run_helpers.dart';
import 'mode_helpers.dart' show TransferSheet;
import '../dashboards/dashboard_swiper.dart';
import '../sheets/damage_calc_sheet.dart';
import 'stat_sheets.dart';
import 'sort_picker.dart';
import 'starter_hint.dart';
import 'summary_tab.dart';
import '../../screens/item_detail_screen.dart';
import '../../screens/shrine_picker_screen.dart';
import '../../screens/synergies_overview_screen.dart';
import '../../screens/all_synergies_screen.dart';
import '../game_icon.dart';

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
  GunSort _gunSort = GunSort.pickup;
  ItemSort _itemSort = ItemSort.pickup;

  /// Per-slot inventory view mode. Defaults to `grid` (the historical
  /// look). Hydrated alongside the sort prefs and persisted on toggle.
  InvView _invView = InvView.grid;

  /// True once the user has explicitly picked a sort *or* the prefs
  /// hydration has resolved — whichever came first. Prevents a slow
  /// initial load from clobbering a fast tap on the sort sheet (rare,
  /// but cheap to defend against).
  bool _sortHydrated = false;

  bool get isMain => widget.slot == PlayerSlot.main;
  PlayerSlot get _slot => widget.slot;

  String get _gunSortKey => 'sort.gun.${_slot.name}';
  String get _itemSortKey => 'sort.item.${_slot.name}';
  String get _invViewKey => 'invView.${_slot.name}';

  @override
  void initState() {
    super.initState();
    _loadSortPrefs();
  }

  Future<void> _loadSortPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || _sortHydrated) return;
      final gIdx = prefs.getInt(_gunSortKey);
      final iIdx = prefs.getInt(_itemSortKey);
      final vIdx = prefs.getInt(_invViewKey);
      setState(() {
        if (gIdx != null && gIdx >= 0 && gIdx < GunSort.values.length) {
          _gunSort = GunSort.values[gIdx];
        }
        if (iIdx != null && iIdx >= 0 && iIdx < ItemSort.values.length) {
          _itemSort = ItemSort.values[iIdx];
        }
        if (vIdx != null && vIdx >= 0 && vIdx < InvView.values.length) {
          _invView = InvView.values[vIdx];
        }
        _sortHydrated = true;
      });
    } catch (_) {
      // SharedPreferences failed to materialise (rare platform issue).
      // We just keep the in-memory defaults — no UI surface needed.
      _sortHydrated = true;
    }
  }

  Future<void> _saveGunSort(GunSort s) async {
    _sortHydrated = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_gunSortKey, s.index);
    } catch (_) {
      // Persistence failure is non-fatal: the in-memory choice still
      // applies for this session.
    }
  }

  Future<void> _saveItemSort(ItemSort s) async {
    _sortHydrated = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_itemSortKey, s.index);
    } catch (_) {
      // Same rationale as _saveGunSort — persistence is best-effort.
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
    final activeSynergies =
        isMain ? p.getActiveSynergies().length : 0;
    final partialSynergies =
        isMain ? p.getPartialSynergies().length : 0;
    final hasCoop = state.hasCoop;
    // Robot +DMG boost for the cyber badge next to the avatar.
    final isRobot = player.character!.name.toLowerCase().contains('robot');
    final robotDmgBoost = isRobot
        ? (p.robotJunk + (p.robotLies ? 1 : 0)) * 5.0 +
            (p.robotGoldJunk ? 500.0 : 0.0)
        : 0.0;

    // For multiplayer: only allow transfers when connected.
    // For local co-op: allow transfers whenever hasCoop.
    final mpSession = context.watch<MultiplayerSession>();
    final isMpActive = mpSession.status != MpStatus.idle;

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
    final topDpsName = player.guns.isEmpty
        ? ''
        : player.guns
            .reduce((a, b) => effectiveDps(a) > effectiveDps(b) ? a : b)
            .name;
    final topDps = player.guns.isEmpty
        ? 0.0
        : player.guns.map(effectiveDps).reduce((a, b) => a > b ? a : b);

    // Synergy glow: map of lowercased name → Color for every item/gun
    // that is part of a currently-active synergy (combined inventories).
    final glowColors = p.activeSynergyGlowColors;

    final scrollWidget = CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            top: !hasCoop,
            child: GungeoneerHeader(
              character: player.character!,
              topDps: topDps,
              gunCount: player.guns.length,
              itemCount: player.items.length,
              activeSynergies: activeSynergies,
              partialSynergies: partialSynergies,
              showSynergies: isMain,
              coolness: state.totalCoolness,
              curse: state.totalCurse,
              robotDamageBoost: robotDmgBoost,
              onTapCoolness: () => _showCoolnessSheet(context),
              onTapCurse: () => _showCurseSheet(context),
              onLongPressCoolness: () =>
                  _showStatAdjuster(context, isCool: true),
              onLongPressCurse: () =>
                  _showStatAdjuster(context, isCool: false),
              onTapSynergies: () => Navigator.push(
                context,
                fastRoute(const AllSynergiesScreen()),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SpongeButton(),
                  // Damage calc — tap opens the full DPS breakdown sheet
                  // directly (the final view). Long-press toggles the
                  // compact green DPS readout panel on the dashboard.
                  ListenableBuilder(
                    listenable: VisualPrefs.notifier,
                    builder: (context, _) {
                      final isOn = VisualPrefs.notifier.value.showDamageCalculator;
                      final color = isOn ? Colors.amberAccent : Colors.white38;
                      return _LabeledIconButton(
                        icon: Icons.calculate_rounded,
                        label: 'Calc',
                        color: color,
                        tooltip: 'Tap: DPS sheet · Long-press: toggle readout',
                        onTap: () {
                          Haptics.selection();
                          _showDamageCalcSheet(context, _slot);
                        },
                        onLongPress: () {
                          VisualPrefs.setShowDamageCalculator(!isOn);
                          Haptics.selection();
                        },
                      );
                    },
                  ),
                  // Effects panel toggle — tap to show/hide the effects
                  // accordion. If there are no active effects, shows an
                  // info message instead of silently toggling.
                  ListenableBuilder(
                    listenable: VisualPrefs.notifier,
                    builder: (context, _) {
                      final isOn = VisualPrefs.notifier.value.showEffectsPanel;
                      final color = isOn ? Colors.amberAccent : Colors.white38;
                      return _LabeledIconButton(
                        icon: Icons.auto_awesome,
                        label: 'Effects',
                        color: color,
                        tooltip: isOn ? 'Effects Panel: ON' : 'Effects Panel: OFF',
                        onTap: () {
                          Haptics.selection();
                          final chips = EffectTagger.summaryChips(
                            guns: player.guns,
                            items: player.items,
                          );
                          if (chips.isEmpty) {
                            _showGungeonInfo(context, 'No Effects', 'No active effects from current guns and items.');
                            return;
                          }
                          VisualPrefs.setShowEffectsPanel(!isOn);
                        },
                      );
                    },
                  ),
                  // Shrine tracker — pill mechanic: tap toggles shrine
                  // panel on/off (shows info if no shrines used yet).
                  // Long-press opens the shrine picker screen.
                  ListenableBuilder(
                    listenable: VisualPrefs.notifier,
                    builder: (context, _) {
                      final isOn = VisualPrefs.notifier.value.showShrinePanel;
                      final color = isOn ? Colors.amberAccent : Colors.white38;
                      return _LabeledIconButton(
                        icon: Icons.temple_buddhist,
                        label: 'Shrine',
                        color: color,
                        tooltip: 'Tap: toggle shrine panel · Long-press: shrine picker',
                        onTap: () {
                          Haptics.selection();
                          if (state.shrinesUsed.isEmpty) {
                            _showGungeonInfo(context, 'No Shrines', 'No shrines used yet. Long-press to open the shrine picker and track shrines you\'ve used this run.');
                            return;
                          }
                          VisualPrefs.setShowShrinePanel(!isOn);
                        },
                        onLongPress: () {
                          Haptics.selection();
                          Navigator.push(context, fastRoute(const ShrinePickerScreen()));
                        },
                      );
                    },
                  ),
                  // Dashboards toggle — if no special panels exist, shows
                  // an info message instead of silently toggling.
                  ListenableBuilder(
                    listenable: VisualPrefs.notifier,
                    builder: (context, _) {
                      final isOn = VisualPrefs.notifier.value.showDashboards;
                      final color = isOn ? Colors.amberAccent : Colors.white38;
                      return _LabeledIconButton(
                        icon: isOn ? Icons.view_agenda_rounded : Icons.view_agenda_outlined,
                        label: 'Panels',
                        color: color,
                        tooltip: isOn ? 'Special Panels: ON' : 'Special Panels: OFF',
                        onTap: () {
                          Haptics.selection();
                          final ownedGunNames = player.guns
                              .map((g) => g.name.toLowerCase())
                              .toSet();
                          final ownedItemNames = player.items
                              .map((i) => i.name.toLowerCase())
                              .toSet();
                          final charName = player.character?.name.toLowerCase() ?? '';
                          final hasPanels = hasSpecialDashboards(
                            ownedGunNames: ownedGunNames,
                            ownedItemNames: ownedItemNames,
                            charName: charName,
                          );
                          if (!hasPanels) {
                            _showGungeonInfo(context, 'No Panels', 'No special dashboards available. Equip special guns or items (Gunderfury, Ser Junkan, Spice, etc.) to unlock tracking panels.');
                            return;
                          }
                          VisualPrefs.setShowDashboards(!isOn);
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  const HeaderMenu(),
                ],
              ),
              effectChips: EffectTagger.summaryChips(
                guns: player.guns,
                items: player.items,
              ),
              shrinesUsed: state.shrinesUsed,
            ),
          ),
        ),
        // Compact DPS readout — visible when Damage Calculator toggle is ON
        SliverToBoxAdapter(
          child: ListenableBuilder(
            listenable: VisualPrefs.notifier,
            builder: (context, _) {
              final isOn = VisualPrefs.notifier.value.showDamageCalculator;
              if (!isOn || player.guns.isEmpty) return const SizedBox.shrink();
              final multiplier = DamageCalculator.multiplier(
                guns: player.guns,
                items: player.items,
              );
              final bonusPct = (multiplier - 1.0) * 100.0;
              final topDps = player.guns
                  .map((g) => g.dpsValue * multiplier)
                  .reduce((a, b) => a > b ? a : b);
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: GestureDetector(
                  onTap: () => _showDamageCalcSheet(context, _slot),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 52),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0F0A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.greenAccent.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withValues(alpha: 0.08),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 18,
                              color: Colors.greenAccent.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 8),
                            GoopText(
                              'DPS TERMINAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.greenAccent.withValues(alpha: 0.8),
                                letterSpacing: 1.0,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (bonusPct.abs() > 0.1) ...[
                              GoopText(
                                '${bonusPct >= 0 ? '+' : ''}${bonusPct.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: bonusPct > 0 ? Colors.greenAccent : Colors.redAccent,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            GoopText(
                              'TOP: ${topDps.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        ListenableBuilder(
          listenable: VisualPrefs.notifier,
          builder: (context, _) {
            if (!VisualPrefs.notifier.value.showDashboards) {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }
            return DashboardSwiper(slot: _slot);
          },
        ),
        SectionHeaderSliver(
          title: 'Guns',
          count: guns.length,
          icon: Icons.gps_fixed,
          sortLabel: _gunSort.label,
          onTapSort: _showGunSortSheet,
          showLayoutSelector: true,
          currentInvView: _invView,
          currentDisplayMode: VisualPrefs.notifier.value.inventoryDisplayMode,
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid.builder(
              gridDelegate: _tileGrid(context),
              itemCount: guns.length,
              itemBuilder: (c, i) {
                final g = guns[i];
                return PeriodicTile(
                  gun: g,
                  isTopDps: g.name == topDpsName,
                  synergyGlowColor: glowColors[g.name.toLowerCase()],
                  onTap: () => Navigator.push(
                    c,
                    fastRoute(ItemDetailScreen(gun: g, ownerSlot: _slot)),
                  ),
                  onLongPress: () => _promptTileActions(c, gun: g),
                );
              },
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverList.builder(
              itemCount: guns.length,
              itemBuilder: (c, i) {
                final g = guns[i];
                return Dismissible(
                  key: Key('gun_${g.name}_$_slot'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.only(right: 16),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 24),
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
                    onTap: () => Navigator.push(
                      c,
                      fastRoute(ItemDetailScreen(gun: g, ownerSlot: _slot)),
                    ),
                    onLongPress: () => _promptTileActions(c, gun: g),
                  ),
                );
              },
            ),
          ),
        SectionHeaderSliver(
          title: 'Items',
          count: items.length,
          icon: Icons.inventory_2_outlined,
          sortLabel: _itemSort.label,
          onTapSort: _showItemSortSheet,
          showLayoutSelector: true,
          currentInvView: _invView,
          currentDisplayMode: VisualPrefs.notifier.value.inventoryDisplayMode,
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
                return PeriodicTile(
                  item: it,
                  synergyGlowColor: glowColors[it.name.toLowerCase()],
                  onTap: () => Navigator.push(
                    c,
                    fastRoute(ItemDetailScreen(item: it, ownerSlot: _slot)),
                  ),
                  onLongPress: () => _promptTileActions(c, item: it),
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
                return Dismissible(
                  key: Key('item_${it.name}_$_slot'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.only(right: 16),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 24),
                  ),
                  onDismissed: (_) {
                    final p = context.read<RunProvider>();
                    p.removeItem(it, slot: _slot);
                    _toast(context, 'Removed ${it.name}');
                  },
                  child: InventoryListRow(
                    item: it,
                    synergyGlowColor: glowColors[it.name.toLowerCase()],
                    onTap: () => Navigator.push(
                      c,
                      fastRoute(ItemDetailScreen(item: it, ownerSlot: _slot)),
                    ),
                    onLongPress: () => _promptTileActions(c, item: it),
                  ),
                );
              },
            ),
          ),
      ],
    );

    if (isMpActive) {
      return RefreshIndicator(
        color: Colors.amber,
        backgroundColor: const Color(0xFF1E1E1E),
        onRefresh: () async {
          await mpSession.reconnect();
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: scrollWidget,
      );
    }
    return scrollWidget;
      },
    );
  }

  void _showDamageCalcSheet(BuildContext c, PlayerSlot slot) {
    showModalBottomSheet<void>(
      context: c,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DamageCalcSheet(slot: slot),
    );
  }

  /// Inline +/- bottom sheet for a quick coolness/curse tweak — opened
  /// by long-pressing either bubble in the [GungeoneerHeader]. Live-rebinds
  /// to the latest provider state so the displayed number updates after
  /// each tap without dismissing the sheet.
  void _showStatAdjuster(BuildContext c, {required bool isCool}) {
    showModalBottomSheet<void>(
      context: c,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => StatAdjusterSheet(isCool: isCool),
    );
  }

  /// Coolness hub — mirrors the curse sheet: live effects, stat adjuster,
  /// quick actions, and a link to the full stats breakdown.
  void _showCoolnessSheet(BuildContext c) {
    Haptics.selection();
    showModalBottomSheet<void>(
      context: c,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      isScrollControlled: true,
      builder: (ctx) => const CoolnessSheet(),
    );
  }

  /// Curse hub — combines stat adjuster, curse-raising actions, and a
  /// link to the full curse stats breakdown. Opened by tapping the curse
  /// capsule on the dashboard.
  void _showCurseSheet(BuildContext c) {
    Haptics.selection();
    showModalBottomSheet<void>(
      context: c,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      isScrollControlled: true,
      builder: (ctx) => const CurseSheet(),
    );
  }

  void _showGunSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SortPickerSheet<GunSort>(
        title: 'Guns',
        titleIcon: Icons.gps_fixed,
        current: _gunSort,
        options: GunSort.values,
        labelOf: (s) => s.label,
        iconOf: (s) => s.icon,
        onPick: (s) {
          setState(() => _gunSort = s);
          _saveGunSort(s);
        },
      ),
    );
  }

  void _showItemSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SortPickerSheet<ItemSort>(
        title: 'Items',
        titleIcon: Icons.inventory_2_outlined,
        current: _itemSort,
        options: ItemSort.values,
        labelOf: (s) => s.label,
        iconOf: (s) => s.icon,
        onPick: (s) {
          setState(() => _itemSort = s);
          _saveItemSort(s);
        },
      ),
    );
  }

  void _toast(BuildContext c, String msg) {
    final m = ScaffoldMessenger.maybeOf(c);
    if (m == null) return;
    m.hideCurrentSnackBar();
    m.showSnackBar(SnackBar(
      content: GoopText(msg),
      duration: const Duration(milliseconds: 1500),
    ));
  }

  /// RPG-gungeon styled info dialog for empty-state warnings
  /// ("No Panels", "No Effects"). Dismissed by tapping outside.
  void _showGungeonInfo(BuildContext c, String title, String body) {
    showDialog<void>(
      context: c,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1E22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: Colors.amber.withValues(alpha: 0.4),
              width: 1.4,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 22,
                      color: Colors.amber.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 10),
                    GoopText(
                      title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: Colors.amber.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GoopText(
                  body,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.65),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.amber,
                    ),
                    child: const GoopText('Got it'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _promptTransferGun(BuildContext c, Gun g) {
    final p = c.read<RunProvider>();
    final session = c.read<MultiplayerSession>();
    // All guns are droppable in Enter the Gungeon, so starter guns
    // (Crossbow, Blasphemy, Marine Sidearm, etc.) are free to transfer.
    final mpActive = session.isActive;
    final isMyInv = !mpActive || session.isSimulated || session.mySlot == _slot;
    final peerName = mpActive
        ? (session.peerNickname ?? 'Peer')
        : (isMain
            ? (p.runState.coop?.character?.name ?? 'Player 2')
            : p.runState.main.character!.name);

    final title = mpActive && !isMyInv
        ? 'Request ${g.name}?'
        : 'Transfer ${g.name}?';
    final subtitle = mpActive && !isMyInv
        ? 'Ask $peerName to send it to you'
        : 'Send to $peerName';
    final icon = mpActive && !isMyInv ? Icons.front_hand : Icons.swap_horiz;

    showModalBottomSheet(
      context: c,
      builder: (bc) => TransferSheet(
        title: title,
        subtitle: subtitle,
        icon: icon,
        onConfirm: () async {
          Navigator.pop(bc);
          if (mpActive) {
            if (isMyInv) {
              // Send via MP — sendGift removes locally + ships the gift,
              // rolling back if the send fails.
              await session.sendGift(kind: 'gun', name: g.name);
              if (c.mounted) _toast(c, '${g.name} → $peerName');
            } else {
              final reqId =
                  await session.sendRequest(kind: 'gun', name: g.name);
              if (!c.mounted) return;
              _toast(
                c,
                reqId != null
                    ? 'Asked $peerName for ${g.name}…'
                    : 'Could not send request — check connection.',
              );
            }
          } else {
            // Local co-op — just shuffle slots in RunProvider.
            final ok = p.transferGun(g, _slot);
            if (c.mounted) {
              _toast(
                c,
                ok
                    ? '${g.name} → $peerName'
                    : '$peerName already has ${g.name}',
              );
            }
          }
        },
      ),
    );
  }

  void _promptTransferItem(BuildContext c, Item it) {
    final p = c.read<RunProvider>();
    final session = c.read<MultiplayerSession>();
    // All items are now transferable, including starter passives.
    final mpActive = session.isActive;
    final isMyInv = !mpActive || session.isSimulated || session.mySlot == _slot;
    final peerName = mpActive
        ? (session.peerNickname ?? 'Peer')
        : (isMain
            ? (p.runState.coop?.character?.name ?? 'Player 2')
            : p.runState.main.character!.name);

    final title = mpActive && !isMyInv
        ? 'Request ${it.name}?'
        : 'Transfer ${it.name}?';
    final subtitle = mpActive && !isMyInv
        ? 'Ask $peerName to send it to you'
        : 'Send to $peerName';
    final icon = mpActive && !isMyInv ? Icons.front_hand : Icons.swap_horiz;

    showModalBottomSheet(
      context: c,
      builder: (bc) => TransferSheet(
        title: title,
        subtitle: subtitle,
        icon: icon,
        onConfirm: () async {
          Navigator.pop(bc);
          if (mpActive) {
            if (isMyInv) {
              await session.sendGift(kind: 'item', name: it.name);
              if (c.mounted) _toast(c, '${it.name} → $peerName');
            } else {
              final reqId =
                  await session.sendRequest(kind: 'item', name: it.name);
              if (!c.mounted) return;
              _toast(
                c,
                reqId != null
                    ? 'Asked $peerName for ${it.name}…'
                    : 'Could not send request — check connection.',
              );
            }
          } else {
            final ok = p.transferItem(it, _slot);
            if (c.mounted) {
              _toast(
                c,
                ok
                    ? '${it.name} → $peerName'
                    : '$peerName already has ${it.name}',
              );
            }
          }
        },
      ),
    );
  }

  SliverGridDelegate _tileGrid(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final displayMode = VisualPrefs.notifier.value.inventoryDisplayMode;

    int cross;
    double ratio;

    switch (displayMode) {
      case InventoryDisplayMode.classicPeriodic:
        final savedColCount = VisualPrefs.notifier.value.periodicGridColumnCount;
        cross = (savedColCount > 0) ? savedColCount : (w < 360 ? 3 : w < 600 ? 4 : 6);
        ratio = 0.75; // BUG-035: bumped from 0.80 to fit type subtitle + RANGE
        break;
      case InventoryDisplayMode.tacticalStats:
        cross = w < 500 ? 2 : w < 850 ? 3 : 4;
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
    final mpSession = c.read<MultiplayerSession>();
    final hasCoop = p.runState.hasCoop;
    final isMpActive = mpSession.status != MpStatus.idle;
    final canTransfer = hasCoop && (!isMpActive || mpSession.isConnected);

    showModalBottomSheet<void>(
      context: c,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetCtx) {
        VoidCallback? onTransfer;
        String? transferLabel;
        if (canTransfer) {
          final isMyInv = !isMpActive || mpSession.isSimulated || mpSession.mySlot == _slot;
          final peerName = isMpActive ? (mpSession.peerNickname ?? 'Peer') : 'Player 2';
          transferLabel = isMyInv ? 'Transfer to $peerName' : 'Request from $peerName';

          if (gun != null) {
            onTransfer = () {
              Navigator.pop(sheetCtx);
              _promptTransferGun(c, gun);
            };
          } else if (item != null) {
            onTransfer = () {
              Navigator.pop(sheetCtx);
              _promptTransferItem(c, item);
            };
          }
        }

        return TileActionsSheet(
          gun: gun,
          item: item,
          onTransfer: onTransfer,
          transferLabel: transferLabel,
          onOpen: () {
            Navigator.pop(sheetCtx);
            Navigator.push(
              c,
              fastRoute(ItemDetailScreen(
                  gun: gun,
                  item: item,
                  ownerSlot: _slot,
                ),
              ),
            );
          },
          onToggleFavourite: () {
            final p = c.read<RunProvider>();
            final name = gun?.name ?? item!.name;
            final nowFav = p.toggleFavourite(name);
            Navigator.pop(sheetCtx);
            ScaffoldMessenger.of(c).showSnackBar(SnackBar(
              content: GoopText(
                  nowFav ? '$name added to favourites' : '$name unfavourited'),
              duration: const Duration(milliseconds: 1400),
            ));
          },
          onRemove: () {
            Navigator.pop(sheetCtx);
            if (gun != null) {
              _removeGunWithUndo(c, gun);
            } else {
              _removeItemWithUndo(c, item!);
            }
          },
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
    messenger.showSnackBar(SnackBar(
      content: GoopText('Removed ${g.name}', maxLines: 1, overflow: TextOverflow.ellipsis),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () {
          p.addGun(g, slot: capturedSlot);
        },
      ),
    ));
  }

  void _removeItemWithUndo(BuildContext c, Item it) {
    final p = c.read<RunProvider>();
    final capturedSlot = _slot;
    p.removeItem(it, slot: capturedSlot);
    final messenger = ScaffoldMessenger.of(c);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: GoopText('Removed ${it.name}', maxLines: 1, overflow: TextOverflow.ellipsis),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () {
          p.addItem(it, slot: capturedSlot);
        },
      ),
    ));
  }
}

/// Vertical synergy panel — lists all synergies that are active or partial
/// (at least one required item owned). Each row shows the synergy name,
/// effect text, and big item pills with graphics. Owned items are full-color
/// with a glow; unowned items are greyed but still visible.
// ignore: unused_element
class _SynergyPanel extends StatelessWidget {
  final List<Synergy> allSynergies;
  final Set<String> ownedLower;
  final RunProvider provider;

  const _SynergyPanel({
    required this.allSynergies,
    required this.ownedLower,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final ownedList = ownedLower.toList();
    final relevant = allSynergies.where((s) {
      final allItems = [...s.items, ...s.anyOf];
      return allItems.any((n) => ownedLower.contains(n.toLowerCase()));
    }).toList();

    relevant.sort((a, b) {
      final aActive = a.matchesItems(ownedList);
      final bActive = b.matchesItems(ownedList);
      if (aActive && !bActive) return -1;
      if (!aActive && bActive) return 1;
      return 0;
    });

    if (relevant.isEmpty) return const SizedBox.shrink();

    final activeCount = relevant.where((s) => s.matchesItems(ownedList)).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 18, color: Colors.amberAccent),
              const SizedBox(width: 8),
              const GoopText(
                'SYNERGIES',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white54,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.35), width: 1.2),
                ),
                child: GoopText(
                  '$activeCount active',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.amberAccent),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  fastRoute(const SynergiesOverviewScreen()),
                ),
                child: const GoopText(
                  'View All',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white60),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final syn in relevant) ...[
            _SynergyRow(
              synergy: syn,
              isActive: syn.matchesItems(ownedList),
              ownedLower: ownedLower,
              provider: provider,
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _SynergyRow extends StatelessWidget {
  final Synergy synergy;
  final bool isActive;
  final Set<String> ownedLower;
  final RunProvider provider;

  const _SynergyRow({
    required this.synergy,
    required this.isActive,
    required this.ownedLower,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final allItems = [...synergy.items, ...synergy.anyOf];
    final statusColor = isActive ? Colors.greenAccent : Colors.amberAccent;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.07)
            : Colors.amber.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withValues(alpha: isActive ? 0.3 : 0.15),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (synergy.icon.isNotEmpty)
                GameIcon(assetPath: synergy.icon, size: 26, showRing: false)
              else
                Icon(Icons.auto_awesome, size: 20, color: statusColor),
              const SizedBox(width: 10),
              Expanded(
                child: GoopText(
                  synergy.name,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.35), width: 1.2),
                ),
                child: GoopText(
                  isActive ? 'ACTIVE' : 'PARTIAL',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GoopText(
            synergy.prettyEffect.isNotEmpty ? synergy.prettyEffect : synergy.effect,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.55),
              height: 1.35,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (int i = 0; i < allItems.length; i++) ...[
                if (i > 0 && i < synergy.items.length)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Icon(Icons.add, size: 12, color: Colors.white.withValues(alpha: 0.2)),
                  ),
                _SynergyItemPill(
                  itemName: allItems[i],
                  isOwned: ownedLower.contains(allItems[i].toLowerCase()),
                  isActive: isActive,
                  provider: provider,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SynergyItemPill extends StatelessWidget {
  final String itemName;
  final bool isOwned;
  final bool isActive;
  final RunProvider provider;

  const _SynergyItemPill({
    required this.itemName,
    required this.isOwned,
    required this.isActive,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final gun = provider.gunByName(itemName);
    final item = provider.itemByName(itemName);
    final iconPath = gun?.icon ?? item?.icon ?? '';

    final pillColor = isActive
        ? Colors.greenAccent.withValues(alpha: 0.4)
        : isOwned
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.08);

    return Opacity(
      opacity: isOwned ? 1.0 : 0.4,
      child: Container(
        width: 72,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isOwned
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: pillColor, width: 1.8),
          boxShadow: isOwned && isActive
              ? [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.15), blurRadius: 8)]
              : null,
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 52,
                height: 52,
                child: _buildImage(iconPath),
              ),
            ),
            const SizedBox(height: 6),
            GoopText(
              itemName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: isOwned ? Colors.white70 : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String path) {
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
          itemName.isNotEmpty ? itemName[0].toUpperCase() : '?',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
        ),
      ),
    );
  }
}

/// Compact icon button with a tiny text label below it, for the
/// active-run header toggle row. Keeps the same 36×36 hit target
/// but adds a ~8px label for discoverability.
class _LabeledIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _LabeledIconButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.tooltip,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onTap,
          onLongPress: onLongPress,
          icon: Icon(icon, size: 20, color: color),
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 36),
        ),
        GoopText(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.5,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}