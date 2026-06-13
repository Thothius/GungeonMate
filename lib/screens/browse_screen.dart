import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../models/gun.dart';
import '../models/item.dart';
import '../models/player.dart';
import '../services/multiplayer_session.dart';
import '../services/app_theme.dart';
import '../widgets/quality_badge.dart';
import '../widgets/game_icon.dart';
import 'item_detail_screen.dart';
import 'favourites_screen.dart';

enum _GunSort { name, quality, dps, gunClass }

enum _ItemSort { name, quality, type, synergies }

enum _AllSort { quality, name, synergies, type }

class BrowseScreen extends StatefulWidget {
  /// When provided, the ADD button and the snackbar route adds into the
  /// given player slot. Defaults to the main player.
  final PlayerSlot targetSlot;

  /// When this screen lives inside an [IndexedStack] (the bottom nav
  /// case), [dispose] never fires on tab switches. The parent feeds us
  /// a freshly-computed visibility flag so we can clear the search
  /// input the moment the user navigates away. Defaults to `true` for
  /// the modal-route case (Run header → Browse), where dispose handles
  /// teardown naturally.
  final bool isVisible;

  /// Explicit flag to control the back-button visibility and avoid black screen pop loops on the tab bar.
  final bool showBackButton;

  const BrowseScreen({
    super.key,
    this.targetSlot = PlayerSlot.main,
    this.isVisible = true,
    this.showBackButton = false,
  });

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _query = '';
  String _lastQuery = ''; // Stores the previous query for smart UX reference
  String _quality = 'All';
  _GunSort _gunSort = _GunSort.quality;
  _ItemSort _itemSort = _ItemSort.quality;
  _AllSort _allSort = _AllSort.quality;
  bool _piercingOnly = false;
  bool _explosiveOnly = false;
  bool _iceOnly = false;
  bool _fireOnly = false;
  bool _poisonOnly = false;
  bool _freezeOnly = false;
  bool _stunOnly = false;
  bool _stealingOnly = false;
  bool _filtersExpanded = false; // Collapsible, closed by default!
  bool _isGridView = false;

  int _getGridCrossAxisCount(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w < 360
        ? 3
        : w < 600
            ? 4
            : 6;
  }

  static const Map<String, int> _qualityOrder = {
    'S': 0,
    '1S': 0,
    'A': 1,
    'B': 2,
    'C': 3,
    'D': 4,
    'N': 5,
    '': 6,
  };

  @override
  void initState() {
    super.initState();
    // Length 4: All / Guns / Items / Favourites.
    _tab = TabController(length: 4, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) return;
      // Drop the keyboard whenever the user changes tab so it never
      // flickers up after navigating between sections.
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() {});
    });
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  void _onSearchFocusChanged() {
    if (_searchFocusNode.hasFocus) {
      if (_query.isNotEmpty) {
        _lastQuery = _query; // remember current query
        _searchCtrl.clear(); // clear text so they don't have to backspace
      }
    }
  }

  @override
  void didUpdateWidget(covariant BrowseScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Hosting bottom nav re-renders us with `isVisible: false` whenever
    // the user picks another tab. Treat that edge as the natural moment
    // to wipe the search box so re-opening Browse always starts clean.
    if (oldWidget.isVisible && !widget.isVisible) {
      FocusManager.instance.primaryFocus?.unfocus();
      if (_searchCtrl.text.isNotEmpty || _query.isNotEmpty) {
        _searchCtrl.clear();
        setState(() {
          _query = '';
          _lastQuery = '';
        });
      }
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool _matchesQuality(String q) {
    if (_quality == 'All') return true;
    if (_quality == 'S') return q == 'S' || q == '1S';
    return q == _quality;
  }

  bool _matchesFilters(String text) {
    final t = text.toLowerCase();
    if (_piercingOnly && !t.contains('pierce') && !t.contains('piercing')) return false;
    if (_explosiveOnly && !t.contains('explosive') && !t.contains('explosion') && !t.contains('explode') && !t.contains('detonate')) return false;
    if (_iceOnly && !t.contains('ice') && !t.contains('frost')) return false;
    if (_freezeOnly && !t.contains('freeze') && !t.contains('freezing')) return false;
    if (_fireOnly && !t.contains('fire') && !t.contains('burn') && !t.contains('ignite') && !t.contains('flame')) return false;
    if (_poisonOnly && !t.contains('poison') && !t.contains('toxic') && !t.contains('acid')) return false;
    if (_stunOnly && !t.contains('stun') && !t.contains('stunned') && !t.contains('stunning') && !t.contains('daze')) return false;
    if (_stealingOnly && !t.contains('steal') && !t.contains('stealing') && !t.contains('thief') && !t.contains('rob')) return false;
    return true;
  }

  List<Gun> _sortedGuns(RunProvider p) {
    final list = p.allGuns
        .where((g) =>
            g.name.toLowerCase().contains(_query) &&
            _matchesQuality(g.quality) &&
            _matchesFilters(g.notes))
        .toList();
    switch (_gunSort) {
      case _GunSort.name:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case _GunSort.quality:
        list.sort((a, b) {
          final c = (_qualityOrder[a.quality] ?? 99)
              .compareTo(_qualityOrder[b.quality] ?? 99);
          return c != 0 ? c : a.name.compareTo(b.name);
        });
        break;
      case _GunSort.dps:
        list.sort((a, b) => b.dpsValue.compareTo(a.dpsValue));
        break;
      case _GunSort.gunClass:
        list.sort((a, b) {
          final c = a.gunClass.toLowerCase().compareTo(b.gunClass.toLowerCase());
          return c != 0 ? c : a.name.compareTo(b.name);
        });
        break;
    }
    return list;
  }

  String _itemTypeBucket(Item it) {
    if (it.isCompanion) return '1_companion';
    if (it.isActive) return '2_active';
    if (it.isPassive) return '3_passive';
    return '4_other';
  }

  List<Item> _sortedItems(RunProvider p) {
    final list = p.allItems
        .where((it) =>
            it.name.toLowerCase().contains(_query) &&
            _matchesQuality(it.quality) &&
            _matchesFilters(it.effect))
        .toList();
    switch (_itemSort) {
      case _ItemSort.name:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case _ItemSort.quality:
        list.sort((a, b) {
          final c = (_qualityOrder[a.quality] ?? 99)
              .compareTo(_qualityOrder[b.quality] ?? 99);
          return c != 0 ? c : a.name.compareTo(b.name);
        });
        break;
      case _ItemSort.type:
        list.sort((a, b) {
          final c = _itemTypeBucket(a).compareTo(_itemTypeBucket(b));
          return c != 0 ? c : a.name.compareTo(b.name);
        });
        break;
      case _ItemSort.synergies:
        list.sort((a, b) {
          final c = p
              .synergyCountFor(b.name)
              .compareTo(p.synergyCountFor(a.name));
          return c != 0 ? c : a.name.compareTo(b.name);
        });
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final tabIdx = _tab.index;
    final isAll = tabIdx == 0;
    final isGuns = tabIdx == 1;
    final isFavs = tabIdx == 3;
    final isCoop = widget.targetSlot == PlayerSlot.coop;
    return PopScope(
      // Dismiss the soft keyboard before this route pops so the active
      // run view underneath isn't covered.
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: _buildScaffold(context, p, isAll, isGuns, isFavs, isCoop),
    );
  }

  Widget _buildScaffold(
      BuildContext context, RunProvider p, bool isAll, bool isGuns, bool isFavs, bool isCoop) {
    return Scaffold(
      appBar: AppBar(
        // No screen title — the tab strip already labels the section
        // and the redundant "Browse" word ate vertical space testers
        // wanted back. The (add to P2) hint moves into the tab strip
        // sub-line below when relevant.
        toolbarHeight: 0,
        title: const SizedBox.shrink(),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
            child: TabBar(
              controller: _tab,
              // Bigger, easier-to-tap pills. Indicator fills each tab
              // so the active state is unmistakable on small screens.
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              indicator: BoxDecoration(
                color: Theme.of(context).colorScheme.primary
                    .withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.7),
                  width: 1.2,
                ),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerHeight: 0,
              tabs: [
                Tab(
                  height: 52,
                  iconMargin: const EdgeInsets.only(bottom: 2),
                  icon: const Icon(Icons.apps, size: 20),
                  text: isCoop ? 'All · P2' : 'All',
                ),
                const Tab(
                  height: 52,
                  iconMargin: EdgeInsets.only(bottom: 2),
                  icon: Icon(Icons.gps_fixed, size: 20),
                  text: 'Guns',
                ),
                const Tab(
                  height: 52,
                  iconMargin: EdgeInsets.only(bottom: 2),
                  icon: Icon(Icons.inventory_2_outlined, size: 20),
                  text: 'Items',
                ),
                const Tab(
                  height: 52,
                  iconMargin: EdgeInsets.only(bottom: 2),
                  icon: Icon(Icons.favorite, size: 20),
                  text: 'Favs',
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (!isFavs) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  // Search is about half the old width (flex 2 vs total ≈ 4).
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 44,
                      child: TextField(
                        controller: _searchCtrl,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: _lastQuery.isNotEmpty ? "Search (was: '$_lastQuery')" : "Search",
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 6),
                          suffixIcon: _searchCtrl.text.isEmpty && _query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear',
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() {
                                      _query = '';
                                      _lastQuery = '';
                                    });
                                  },
                                ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: (v) {
                          setState(() {
                            if (v.isEmpty) {
                              _query = _lastQuery.toLowerCase();
                            } else {
                              _query = v.toLowerCase();
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Grid / List View Toggle Button
                  IconButton(
                    tooltip: _isGridView ? 'Switch to List View' : 'Switch to Grid View',
                    icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded, size: 22, color: Colors.white70),
                    onPressed: () => setState(() => _isGridView = !_isGridView),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ToolbarButton(
                      icon: Icons.sort,
                      label: isAll
                          ? _allSortLabel(_allSort)
                          : (isGuns
                              ? _gunSortLabel(_gunSort)
                              : _itemSortLabel(_itemSort)),
                      onPressed: () =>
                          _openSortSheet(context, isAll, isGuns),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _ToolbarButton(
                      icon: Icons.military_tech,
                      label: _quality == 'All' ? 'All tiers' : '$_quality only',
                      color: _quality == 'All'
                          ? null
                          : QualityBadge.colorFor(_quality),
                      onPressed: () => _openQualitySheet(context),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Expandable Header Trigger
                  InkWell(
                    onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.filter_alt_outlined, size: 16, color: AppTheme.flair.primary),
                              const SizedBox(width: 6),
                              Text(
                                'ELEMENTAL & UTILITY FILTERS',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.flair.primary,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            _filtersExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            size: 18,
                            color: Colors.white54,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Collapsible Filters Panel
                  if (_filtersExpanded) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildFilterChip('Piercing 🎯', _piercingOnly, Colors.orangeAccent, (v) => setState(() => _piercingOnly = v)),
                          _buildFilterChip('Explosive 💥', _explosiveOnly, Colors.redAccent, (v) => setState(() => _explosiveOnly = v)),
                          _buildFilterChip('Ice ❄️', _iceOnly, Colors.lightBlueAccent, (v) => setState(() => _iceOnly = v)),
                          _buildFilterChip('Freeze 🥶', _freezeOnly, Colors.cyanAccent, (v) => setState(() => _freezeOnly = v)),
                          _buildFilterChip('Fire 🔥', _fireOnly, Colors.deepOrangeAccent, (v) => setState(() => _fireOnly = v)),
                          _buildFilterChip('Poison 🤢', _poisonOnly, Colors.lightGreenAccent, (v) => setState(() => _poisonOnly = v)),
                          _buildFilterChip('Stun 💫', _stunOnly, Colors.purpleAccent, (v) => setState(() => _stunOnly = v)),
                          _buildFilterChip('Stealing 🕵️', _stealingOnly, Colors.amberAccent, (v) => setState(() => _stealingOnly = v)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _allList(p),
                _gunsList(p),
                _itemsList(p),
                const FavouritesScreen(embedded: true),
              ],
            ),
          ),
          if (widget.showBackButton && Navigator.canPop(context)) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              color: Colors.black.withValues(alpha: 0.2),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back, size: 20),
                  label: const Text(
                    'BACK TO RUN',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Toolbar handlers --------------------------------------------------

  String _gunSortLabel(_GunSort s) {
    switch (s) {
      case _GunSort.quality:
        return 'Quality';
      case _GunSort.dps:
        return 'DPS';
      case _GunSort.gunClass:
        return 'Class';
      case _GunSort.name:
        return 'Name';
    }
  }

  String _itemSortLabel(_ItemSort s) {
    switch (s) {
      case _ItemSort.quality:
        return 'Quality';
      case _ItemSort.type:
        return 'Type';
      case _ItemSort.synergies:
        return 'Synergies';
      case _ItemSort.name:
        return 'Name';
    }
  }

  String _allSortLabel(_AllSort s) {
    switch (s) {
      case _AllSort.quality:
        return 'Quality';
      case _AllSort.name:
        return 'Name';
      case _AllSort.synergies:
        return 'Synergies';
      case _AllSort.type:
        return 'Type';
    }
  }

  void _openSortSheet(BuildContext c, bool isAll, bool isGuns) {
    showModalBottomSheet(
      context: c,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Row(
                  children: [
                    Icon(Icons.sort, size: 18),
                    SizedBox(width: 8),
                    Text('Sort by',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (isAll) ...[
                _sortTile(ctx, 'Quality (S → D)', Icons.workspace_premium,
                    _allSort == _AllSort.quality,
                    () => setState(() => _allSort = _AllSort.quality)),
                _sortTile(ctx, 'Type (Guns → Active → Passive)',
                    Icons.category,
                    _allSort == _AllSort.type,
                    () => setState(() => _allSort = _AllSort.type)),
                _sortTile(ctx, 'Synergies (most → least)', Icons.hub,
                    _allSort == _AllSort.synergies,
                    () => setState(() => _allSort = _AllSort.synergies)),
                _sortTile(ctx, 'Name (A → Z)', Icons.sort_by_alpha,
                    _allSort == _AllSort.name,
                    () => setState(() => _allSort = _AllSort.name)),
              ] else if (isGuns) ...[
                _sortTile(ctx, 'Quality (S → D)', Icons.workspace_premium,
                    _gunSort == _GunSort.quality,
                    () => setState(() => _gunSort = _GunSort.quality)),
                _sortTile(ctx, 'DPS (high → low)', Icons.flash_on,
                    _gunSort == _GunSort.dps,
                    () => setState(() => _gunSort = _GunSort.dps)),
                _sortTile(ctx, 'Class', Icons.category,
                    _gunSort == _GunSort.gunClass,
                    () => setState(() => _gunSort = _GunSort.gunClass)),
                _sortTile(ctx, 'Name (A → Z)', Icons.sort_by_alpha,
                    _gunSort == _GunSort.name,
                    () => setState(() => _gunSort = _GunSort.name)),
              ] else ...[
                _sortTile(ctx, 'Quality (S → D)', Icons.workspace_premium,
                    _itemSort == _ItemSort.quality,
                    () => setState(() => _itemSort = _ItemSort.quality)),
                _sortTile(ctx, 'Type (Active / Passive / Companion)',
                    Icons.inventory_2_outlined,
                    _itemSort == _ItemSort.type,
                    () => setState(() => _itemSort = _ItemSort.type)),
                _sortTile(ctx, 'Synergies (most → least)', Icons.hub,
                    _itemSort == _ItemSort.synergies,
                    () => setState(() => _itemSort = _ItemSort.synergies)),
                _sortTile(ctx, 'Name (A → Z)', Icons.sort_by_alpha,
                    _itemSort == _ItemSort.name,
                    () => setState(() => _itemSort = _ItemSort.name)),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _sortTile(BuildContext ctx, String label, IconData icon,
      bool selected, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon,
          color: selected ? Colors.amber : Colors.white.withValues(alpha: 0.6)),
      title: Text(label,
          style: TextStyle(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500)),
      trailing: selected
          ? const Icon(Icons.check, color: Colors.amber, size: 20)
          : null,
      onTap: () {
        onTap();
        Navigator.pop(ctx);
      },
    );
  }

  void _openQualitySheet(BuildContext c) {
    const tiers = ['All', 'S', 'A', 'B', 'C', 'D', 'N'];
    showModalBottomSheet(
      context: c,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Row(
                  children: [
                    Icon(Icons.military_tech, size: 18),
                    SizedBox(width: 8),
                    Text('Filter by quality',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                  ],
                ),
              ),
              const Divider(height: 1),
              for (final t in tiers)
                ListTile(
                  leading: t == 'All'
                      ? const Icon(Icons.all_inclusive,
                          color: Colors.white70)
                      : Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: QualityBadge.colorFor(t),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            t,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                  title: Text(
                    t == 'All'
                        ? 'All tiers'
                        : (t == 'N' ? 'Starter (N)' : '$t-tier'),
                    style: TextStyle(
                      fontWeight: _quality == t
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                  trailing: _quality == t
                      ? const Icon(Icons.check,
                          color: Colors.amber, size: 20)
                      : null,
                  onTap: () {
                    setState(() => _quality = t);
                    Navigator.pop(ctx);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _gunsList(RunProvider p) {
    final items = _sortedGuns(p);
    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getGridCrossAxisCount(context),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.0,
        ),
        itemCount: items.length,
        itemBuilder: (c, i) {
          final g = items[i];
          return _gridTile(c, p, g.name, g.quality, g.icon, () => ItemDetailScreen(gun: g), () {
            if (_blockedByMpDrop(c)) return;
            p.addGun(g, slot: widget.targetSlot);
            _showAddSnackBar(c, g.name);
          });
        },
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: items.length,
      itemBuilder: (c, i) {
        final g = items[i];
        return _gunRow(c, p, g);
      },
    );
  }

  void _showAddSnackBar(BuildContext c, String name) {
    ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(
        content: Text(widget.targetSlot == PlayerSlot.coop
            ? '$name added to P2'
            : '$name added'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _gridTile(
    BuildContext c,
    RunProvider p,
    String name,
    String quality,
    String iconPath,
    Widget Function() makeDetailScreen,
    VoidCallback onAdd,
  ) {
    final isSelected = p.ownerSlotOfGun(name) == widget.targetSlot || p.ownerSlotOfItem(name) == widget.targetSlot;
    final f = AppTheme.flair;
    
    final Color qColor;
    switch (quality.toUpperCase()) {
      case 'S': qColor = Colors.amberAccent; break;
      case 'A': qColor = Colors.redAccent; break;
      case 'B': qColor = Colors.greenAccent; break;
      case 'C': qColor = Colors.blueAccent; break;
      case 'D': qColor = Colors.grey; break;
      default: qColor = Colors.white24;
    }

    return Tooltip(
      message: name,
      child: Stack(
        children: [
          InkWell(
            onTap: () async {
              FocusManager.instance.primaryFocus?.unfocus();
              await Navigator.push(
                c,
                MaterialPageRoute(builder: (_) => makeDetailScreen()),
              );
              FocusManager.instance.primaryFocus?.unfocus();
            },
            onLongPress: onAdd,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? f.primary.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected 
                      ? f.primary 
                      : Colors.white.withValues(alpha: 0.08),
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: GameIcon(
                  assetPath: iconPath,
                  size: 32,
                  fallback: Icons.extension,
                ),
              ),
            ),
          ),
          if (quality.isNotEmpty)
            Positioned(
              top: 2,
              left: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: qColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  quality,
                  style: const TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 1,
            right: 1,
            child: InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected ? f.primary : Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tappable row for a gun. Used by both the Guns and All tabs.
  Widget _gunRow(BuildContext c, RunProvider p, Gun g) {
    final syn = p.synergyCountFor(g.name);
    final targetPlayer = widget.targetSlot == PlayerSlot.coop
        ? p.runState.coop
        : p.runState.main;
    final charName = targetPlayer?.character?.name.toLowerCase() ?? '';
    final isRobot = charName.contains('robot');

    return _Row(
      name: g.name,
      quality: g.quality,
      iconPath: g.icon,
      fallback: Icons.gps_fixed,
      meta: _GunMeta(gun: g, synergyCount: syn),
      inRun: p.ownerSlotOfGun(g.name) == widget.targetSlot,
      isRobot: isRobot,
      onTap: () async {
        FocusManager.instance.primaryFocus?.unfocus();
        await Navigator.push(
          c,
          FlipPageRoute(page: ItemDetailScreen(gun: g)),
        );
        if (!mounted) return;
        // Drop the keyboard again on return — Flutter likes to restore
        // focus to the search field, which would re-open the IME.
        FocusManager.instance.primaryFocus?.unfocus();
      },
      onAdd: () {
        if (_blockedByMpDrop(c)) return;
        p.addGun(g, slot: widget.targetSlot);
        ScaffoldMessenger.of(c).showSnackBar(
          SnackBar(
            content: Text(widget.targetSlot == PlayerSlot.coop
                ? '${g.name} added to P2'
                : '${g.name} added'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }

  /// While the MP session is disconnected (auto-reconnecting in the
  /// background) any local add would silently desync from the peer
  /// until reconnect. Show a toast and bail. Returns true when the
  /// add should be blocked.
  bool _blockedByMpDrop(BuildContext c) {
    final session = c.read<MultiplayerSession>();
    if (session.status != MpStatus.disconnected) return false;
    ScaffoldMessenger.of(c).showSnackBar(
      const SnackBar(
        content: Text('Reconnecting to peer… try again in a moment.'),
        duration: Duration(milliseconds: 1400),
      ),
    );
    return true;
  }

  /// Tappable row for an item. Used by both the Items and All tabs.
  Widget _itemRow(BuildContext c, RunProvider p, Item it) {
    final syn = p.synergyCountFor(it.name);
    final targetPlayer = widget.targetSlot == PlayerSlot.coop
        ? p.runState.coop
        : p.runState.main;
    final charName = targetPlayer?.character?.name.toLowerCase() ?? '';
    final isRobot = charName.contains('robot');

    return _Row(
      name: it.name,
      quality: it.quality,
      iconPath: it.icon,
      fallback: it.isActive ? Icons.flash_on : Icons.inventory_2_outlined,
      meta: _ItemMeta(item: it, synergyCount: syn),
      inRun: p.ownerSlotOfItem(it.name) == widget.targetSlot,
      isRobot: isRobot,
      onTap: () async {
        FocusManager.instance.primaryFocus?.unfocus();
        await Navigator.push(
          c,
          FlipPageRoute(page: ItemDetailScreen(item: it)),
        );
        if (!mounted) return;
        FocusManager.instance.primaryFocus?.unfocus();
      },
      onAdd: () {
        if (_blockedByMpDrop(c)) return;
        p.addItem(it, slot: widget.targetSlot);
        final nameLower = it.name.toLowerCase();
        final isHpUp = nameLower.contains('master round') ||
                       nameLower.contains('heart container') ||
                       nameLower.contains('heart holster') ||
                       nameLower.contains('heart locket') ||
                       nameLower.contains('heart purse') ||
                       nameLower.contains('heart bottle') ||
                       nameLower.contains('yellow chamber') ||
                       nameLower.contains('pink guon stone');

        ScaffoldMessenger.of(c).showSnackBar(
          SnackBar(
            content: Text(isRobot && isHpUp
                ? 'Robot Tax: ${it.name} converted to +1 Armor & grants 10-15 casings!'
                : (widget.targetSlot == PlayerSlot.coop
                    ? '${it.name} added to P2'
                    : '${it.name} added')),
            duration: Duration(seconds: isRobot && isHpUp ? 3 : 1),
            backgroundColor: isRobot && isHpUp ? Colors.blue.shade900 : null,
          ),
        );
      },
    );
  }

  /// Combined Guns + Items list — the default Browse view. Each row carries
  /// its native meta widget, and we sort by the unified _AllSort axis.
  Widget _allList(RunProvider p) {
    // Build a heterogeneous list keyed by entry type. We only annotate
    // each entry once; rendering branches per-type at build time.
    final guns = p.allGuns
        .where((g) =>
            g.name.toLowerCase().contains(_query) &&
            _matchesQuality(g.quality) &&
            _matchesFilters(g.notes))
        .toList();
    final items = p.allItems
        .where((it) =>
            it.name.toLowerCase().contains(_query) &&
            _matchesQuality(it.quality) &&
            _matchesFilters(it.effect))
        .toList();

    final entries = <_AnyEntry>[
      for (final g in guns) _AnyEntry.gun(g),
      for (final it in items) _AnyEntry.item(it),
    ];

    int typeBucket(_AnyEntry e) {
      if (e.gun != null) return 0; // guns first
      final it = e.item!;
      if (it.isCompanion) return 1;
      if (it.isActive) return 2;
      if (it.isPassive) return 3;
      return 4;
    }

    int qualityKey(_AnyEntry e) =>
        _qualityOrder[e.quality] ?? 99;

    int synergies(_AnyEntry e) =>
        p.synergyCountFor(e.name);

    switch (_allSort) {
      case _AllSort.quality:
        entries.sort((a, b) {
          final c = qualityKey(a).compareTo(qualityKey(b));
          return c != 0 ? c : a.name.compareTo(b.name);
        });
        break;
      case _AllSort.name:
        entries.sort((a, b) => a.name.compareTo(b.name));
        break;
      case _AllSort.synergies:
        entries.sort((a, b) {
          final c = synergies(b).compareTo(synergies(a));
          return c != 0 ? c : a.name.compareTo(b.name);
        });
        break;
      case _AllSort.type:
        entries.sort((a, b) {
          final c = typeBucket(a).compareTo(typeBucket(b));
          if (c != 0) return c;
          final q = qualityKey(a).compareTo(qualityKey(b));
          return q != 0 ? q : a.name.compareTo(b.name);
        });
        break;
    }

    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getGridCrossAxisCount(context),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.0,
        ),
        itemCount: entries.length,
        itemBuilder: (c, i) {
          final e = entries[i];
          final name = e.name;
          final quality = e.quality;
          final icon = e.gun != null ? e.gun!.icon : e.item!.icon;
          final makeDetail = e.gun != null 
              ? () => ItemDetailScreen(gun: e.gun) 
              : () => ItemDetailScreen(item: e.item);
          final onAdd = e.gun != null
              ? () {
                  if (_blockedByMpDrop(c)) return;
                  p.addGun(e.gun!, slot: widget.targetSlot);
                  _showAddSnackBar(c, name);
                }
              : () {
                  if (_blockedByMpDrop(c)) return;
                  p.addItem(e.item!, slot: widget.targetSlot);
                  _showAddSnackBar(c, name);
                };
          return _gridTile(c, p, name, quality, icon, makeDetail, onAdd);
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: entries.length,
      itemBuilder: (c, i) {
        final e = entries[i];
        return e.gun != null
            ? _gunRow(c, p, e.gun!)
            : _itemRow(c, p, e.item!);
      },
    );
  }

  Widget _itemsList(RunProvider p) {
    final items = _sortedItems(p);
    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getGridCrossAxisCount(context),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.0,
        ),
        itemCount: items.length,
        itemBuilder: (c, i) {
          final it = items[i];
          return _gridTile(c, p, it.name, it.quality, it.icon, () => ItemDetailScreen(item: it), () {
            if (_blockedByMpDrop(c)) return;
            p.addItem(it, slot: widget.targetSlot);
            _showAddSnackBar(c, it.name);
          });
        },
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: items.length,
      itemBuilder: (c, i) => _itemRow(c, p, items[i]),
    );
  }

  Widget _buildFilterChip(String label, bool value, Color color, ValueChanged<bool> onSelected) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: value ? color : Colors.white70,
        ),
      ),
      selected: value,
      selectedColor: color.withValues(alpha: 0.15),
      checkmarkColor: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      side: BorderSide(
        color: value ? color : Colors.white10,
        width: 1.0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      onSelected: onSelected,
    );
  }
}

/// Internal sum-type used by the unified `All` browse list. Holds either
/// a [Gun] or an [Item] reference along with shared lookup keys.
class _AnyEntry {
  final Gun? gun;
  final Item? item;
  _AnyEntry.gun(this.gun) : item = null;
  _AnyEntry.item(this.item) : gun = null;

  String get name => gun?.name ?? item!.name;
  String get quality => gun?.quality ?? item!.quality;
}

class _Row extends StatelessWidget {
  final String name;
  final String quality;
  final String iconPath;
  final IconData fallback;
  final Widget meta;
  final bool inRun;
  final bool isRobot;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _Row({
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
    final p = context.watch<RunProvider>();
    final isS = quality.toUpperCase() == 'S' || quality.toUpperCase() == '1S';

    BorderSide borderSide = isS 
        ? const BorderSide(color: Color(0xFFFFD700), width: 1.6) // Gold outline border
        : const BorderSide(color: Colors.transparent, width: 0);

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
      color: null, // Transparent card background consistent with all other tiers
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
                          child: Text(
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
                            child: Text(
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

// ---------------------------------------------------------------------------
// Shared pill helpers — kept free-standing so _GunMeta & _ItemMeta render
// a unified look. All pills share the same height / shape / text size so
// the Wrap stays tidy even when it flows to multiple lines.
// ---------------------------------------------------------------------------

Widget _metaPill(String text, Color color, {IconData? icon}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.45), width: 0.7),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.3,
            height: 1.1,
          ),
        ),
      ],
    ),
  );
}

/// Quality pill, colored by tier with the letter in the dot so it reads
/// the same as the QualityBadge but flows in the Wrap row.
Widget _qualityPill(String quality) {
  if (quality.isEmpty) return const SizedBox.shrink();
  final color = QualityBadge.colorFor(quality);
  final letter = quality.toUpperCase() == '1S' ? 'S' : quality.toUpperCase();
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.7), width: 0.8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 15,
          height: 15,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Text(
            letter,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text(
            '$letter-tier',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
              height: 1.1,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Gold-coin sell-price pill — mimics a glittering gold coin.
Widget _coinPill(String price) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFFFC857).withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: const Color(0xFFE5A823).withValues(alpha: 0.65),
        width: 0.8,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The coin itself: gold circle with a slight inner highlight.
        Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-0.3, -0.3),
              radius: 0.9,
              colors: [
                Color(0xFFFFE082), // lighter highlight
                Color(0xFFFFC107), // mid gold
                Color(0xFFB8860B), // dark rim
              ],
              stops: [0.0, 0.55, 1.0],
            ),
            border: Border.all(
              color: const Color(0xFF8B6508),
              width: 0.6,
            ),
          ),
          alignment: Alignment.center,
          child: const Text(
            '\$',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFF7A4E00),
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text(
            price,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFFFFD166),
              letterSpacing: 0.3,
              height: 1.1,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _synergyPill(int count) {
  if (count == 0) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'no synergy',
        style: TextStyle(
          fontSize: 10,
          color: Colors.white.withValues(alpha: 0.35),
          fontStyle: FontStyle.italic,
          height: 1.1,
        ),
      ),
    );
  }
  return _metaPill('$count synergy${count == 1 ? "" : "s"}',
      Colors.blueAccent,
      icon: Icons.hub);
}

class _GunMeta extends StatelessWidget {
  final Gun gun;
  final int synergyCount;
  const _GunMeta({required this.gun, required this.synergyCount});

  @override
  Widget build(BuildContext context) {
    final bits = <Widget>[
      _qualityPill(gun.quality),
      if (gun.gunClass.isNotEmpty && gun.gunClass.toUpperCase() != 'NONE')
        _metaPill(_titleCase(gun.gunClass), Colors.orangeAccent),
      if (gun.dps.isNotEmpty)
        _metaPill('DPS ${gun.dpsValue.toStringAsFixed(0)}',
            Colors.deepOrangeAccent,
            icon: Icons.flash_on),
      if (gun.type.isNotEmpty)
        _metaPill(gun.type, Colors.white70),
      if (gun.sellPrice.isNotEmpty && gun.sellPrice != 'N/A')
        _coinPill(gun.sellPrice),
      _synergyPill(synergyCount),
    ];
    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: bits,
    );
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    final l = s.toLowerCase();
    return l[0].toUpperCase() + l.substring(1);
  }
}

/// Aligned, thumb-sized outlined button used for Sort / Quality in the
/// browse top bar. Keeps visual parity with the search field height.
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onPressed;
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white.withValues(alpha: 0.7);
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          side: BorderSide(color: c.withValues(alpha: 0.45)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: color == null ? null : c.withValues(alpha: 0.08),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: c),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: c,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemMeta extends StatelessWidget {
  final Item item;
  final int synergyCount;
  const _ItemMeta({required this.item, required this.synergyCount});

  @override
  Widget build(BuildContext context) {
    final bits = <Widget>[_qualityPill(item.quality)];
    if (item.isCompanion) {
      bits.add(_metaPill('Companion', Colors.purpleAccent));
    } else if (item.isActive) {
      bits.add(_metaPill('Active', Colors.lightBlueAccent));
      if (item.rechargeTime.isNotEmpty) {
        bits.add(_metaPill(item.rechargeTime, Colors.white70,
            icon: Icons.schedule));
      }
    } else if (item.isPassive) {
      bits.add(_metaPill('Passive', Colors.lightGreenAccent));
    }
    if (item.sellPrice.isNotEmpty && item.sellPrice != 'N/A') {
      bits.add(_coinPill(item.sellPrice));
    }
    bits.add(_synergyPill(synergyCount));
    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: bits,
    );
  }
}

class FlipPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  FlipPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 650),
          reverseTransitionDuration: const Duration(milliseconds: 550),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final anim = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
            return AnimatedBuilder(
              animation: anim,
              builder: (context, _) {
                final double value = anim.value;
                final double angle = (1.0 - value) * math.pi / 2; // rotating 90deg to 0

                return Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // 3D perspective
                      ..rotateY(angle),
                    alignment: Alignment.center,
                    child: child,
                  ),
                );
              },
            );
          },
        );
}
