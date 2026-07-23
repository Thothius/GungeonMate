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
import '../../services/effect_tagger.dart';
import '../../services/damage_calculator.dart';
import '../../services/multiplayer_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/fast_route.dart';
import '../../services/goop_talk_engine.dart';
import 'active_run_helpers.dart';
import '../dashboards/dashboard_swiper.dart';
import '../sheets/damage_calc_sheet.dart';
import 'stat_sheets.dart';
import 'sort_picker.dart';
import 'starter_hint.dart';
import 'summary_tab.dart';
import '../../screens/item_detail_screen.dart';
import '../../screens/shrine_picker_screen.dart';

/// A single player's loadout view. Re-usable for main + coop.
/// Coop view hides coolness/curse/synergies (those are run-scope).
///
/// Stateful so each tab can hold its own gun/item sort preference. Sort
/// state intentionally does *not* persist across app restarts ΓÇö it's a
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
  // hydrate from prefs in initState ΓÇö the brief flash of pickup-order
  // before hydration is unnoticeable in practice and avoids blocking
  // the first frame on a disk read.
  GunSort _gunSort = GunSort.pickup;
  ItemSort _itemSort = ItemSort.pickup;

  /// Per-slot inventory view mode. Defaults to `grid` (the historical
  /// look). Hydrated alongside the sort prefs and persisted on toggle.
  InvView _invView = InvView.grid;

  /// True once the user has explicitly picked a sort *or* the prefs
  /// hydration has resolved ΓÇö whichever came first. Prevents a slow
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
      // We just keep the in-memory defaults ΓÇö no UI surface needed.
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
      // Same rationale as _saveGunSort ΓÇö persistence is best-effort.
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
    final hasCoop = state.hasCoop;

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
    final topDpsName = player.guns.isEmpty
        ? ''
        : player.guns
            .reduce((a, b) => a.dpsValue > b.dpsValue ? a : b)
            .name;
    final topDps = player.guns.isEmpty
        ? 0.0
        : player.guns.map((g) => g.dpsValue).reduce((a, b) => a > b ? a : b);

    // Synergy glow: map of lowercased name ΓåÆ Color for every item/gun
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
              showSynergies: isMain,
              coolness: state.totalCoolness,
              curse: state.totalCurse,
              onTapCoolness: () => _showCoolnessSheet(context),
              onTapCurse: () => _showCurseSheet(context),
              onLongPressCoolness: () =>
                  _showStatAdjuster(context, isCool: true),
              onLongPressCurse: () =>
                  _showStatAdjuster(context, isCool: false),
              trailing: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  const SpongeButton(),
                  // Damage calc toggle ΓÇö tap to show/hide DPS terminal on dashboard,
                  // long-press to open the full DPS breakdown sheet.
                  ListenableBuilder(
                    listenable: VisualPrefs.notifier,
                    builder: (context, _) {
                      final isOn = VisualPrefs.notifier.value.showDamageCalculator;
                      return IconButton(
                        onPressed: () {
                          VisualPrefs.setShowDamageCalculator(!isOn);
                          Haptics.selection();
                        },
                        onLongPress: () => _showDamageCalcSheet(context, _slot),
                        icon: Icon(
                          Icons.calculate_rounded,
                          size: 20,
                          color: isOn ? Colors.amberAccent : Colors.white38,
                        ),
                        tooltip: isOn ? 'Damage Calculator: ON' : 'Damage Calculator: OFF',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      );
                    },
                  ),
                  // Effects panel toggle ΓÇö tap to show/hide the effects accordion.
                  ListenableBuilder(
                    listenable: VisualPrefs.notifier,
                    builder: (context, _) {
                      final isOn = VisualPrefs.notifier.value.showEffectsPanel;
                      return IconButton(
                        onPressed: () {
                          VisualPrefs.setShowEffectsPanel(!isOn);
                          Haptics.selection();
                        },
                        icon: Icon(
                          Icons.auto_awesome,
                          size: 20,
                          color: isOn ? Colors.amberAccent : Colors.white38,
                        ),
                        tooltip: isOn ? 'Effects Panel: ON' : 'Effects Panel: OFF',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      );
                    },
                  ),
                  // Shrine tracker ΓÇö tap to open the shrine picker,
                  // long-press to toggle the shrine usage panel.
                  ListenableBuilder(
                    listenable: VisualPrefs.notifier,
                    builder: (context, _) {
                      final isOn = VisualPrefs.notifier.value.showShrinePanel;
                      return IconButton(
                        onPressed: () {
                          Haptics.selection();
                          Navigator.push(context, fastRoute(const ShrinePickerScreen()));
                        },
                        onLongPress: () {
                          VisualPrefs.setShowShrinePanel(!isOn);
                          Haptics.selection();
                        },
                        icon: Icon(
                          Icons.temple_buddhist,
                          size: 20,
                          color: isOn ? Colors.amberAccent : Colors.white38,
                        ),
                        tooltip: 'Shrine Picker',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      );
                    },
                  ),
                  // Dashboards toggle ΓÇö tap to show/hide all special-item/gun dashboards.
                  ListenableBuilder(
                    listenable: VisualPrefs.notifier,
                    builder: (context, _) {
                      final isOn = VisualPrefs.notifier.value.showDashboards;
                      return IconButton(
                        onPressed: () {
                          VisualPrefs.setShowDashboards(!isOn);
                          Haptics.selection();
                        },
                        icon: Icon(
                          Icons.dashboard_customize_rounded,
                          size: 20,
                          color: isOn ? Colors.amberAccent : Colors.white38,
                        ),
                        tooltip: isOn ? 'Dashboards: ON' : 'Dashboards: OFF',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  const HeaderMenu(),
                ],
              ),
              ),
              effectChips: EffectTagger.summaryChips(
                guns: player.guns,
                items: player.items,
              ),
              shrinesUsed: state.shrinesUsed,
            ),
          ),
        ),
        // Compact DPS readout ΓÇö visible when Damage Calculator toggle is ON
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
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF000800),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.25), width: 1.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.terminal_rounded, size: 16, color: Colors.green.withValues(alpha: 0.7)),
                            const SizedBox(width: 8),
                            GoopText(
                              'DPS CALC',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.green.withValues(alpha: 0.7),
                                letterSpacing: 0.5,
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

  /// Inline +/- bottom sheet for a quick coolness/curse tweak ΓÇö opened
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

  /// Coolness hub ΓÇö mirrors the curse sheet: live effects, stat adjuster,
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

  /// Curse hub ΓÇö combines stat adjuster, curse-raising actions, and a
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
              // Send via MP ΓÇö sendGift removes locally + ships the gift,
              // rolling back if the send fails.
              await session.sendGift(kind: 'gun', name: g.name);
              if (c.mounted) _toast(c, '${g.name} ΓåÆ $peerName');
            } else {
              final reqId =
                  await session.sendRequest(kind: 'gun', name: g.name);
              if (!c.mounted) return;
              _toast(
                c,
                reqId != null
                    ? 'Asked $peerName for ${g.name}ΓÇª'
                    : 'Could not send request ΓÇö check connection.',
              );
            }
          } else {
            // Local co-op ΓÇö just shuffle slots in RunProvider.
            final ok = p.transferGun(g, _slot);
            if (c.mounted) {
              _toast(
                c,
                ok
                    ? '${g.name} ΓåÆ $peerName'
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
              if (c.mounted) _toast(c, '${it.name} ΓåÆ $peerName');
            } else {
              final reqId =
                  await session.sendRequest(kind: 'item', name: it.name);
              if (!c.mounted) return;
              _toast(
                c,
                reqId != null
                    ? 'Asked $peerName for ${it.name}ΓÇª'
                    : 'Could not send request ΓÇö check connection.',
              );
            }
          } else {
            final ok = p.transferItem(it, _slot);
            if (c.mounted) {
              _toast(
                c,
                ok
                    ? '${it.name} ΓåÆ $peerName'
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
        ratio = 0.80;
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
  /// UNDO action. UNDO simply re-adds the gun via [RunProvider.addGun] ΓÇö
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
      content: GoopText('Removed ${g.name}'),
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
      content: GoopText('Removed ${it.name}'),
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

class TransferSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onConfirm;
  const TransferSheet({super.key, 
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: Colors.amber),
            const SizedBox(height: 10),
            GoopText(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            GoopText(subtitle,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const GoopText('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const GoopText('Transfer'),
                    onPressed: onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}