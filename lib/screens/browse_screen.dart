import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../services/app_theme.dart';
import '../models/gun.dart';
import '../models/item.dart';
import '../models/player.dart';
import '../services/multiplayer_session.dart';
import 'item_detail_screen.dart';
import 'favourites_screen.dart';
import '../services/goop_talk_engine.dart';
import '../utils/fast_route.dart';
import '../utils/responsive.dart';
import '../widgets/browse/any_entry.dart';
import '../widgets/browse/browse_pills.dart';
import '../widgets/browse/browse_row.dart';

class BrowseScreen extends StatefulWidget {
  /// When provided, the ADD button and the snackbar route adds into the
  /// given player slot. Defaults to the main player.
  final PlayerSlot targetSlot;

  /// When this screen lives inside an [IndexedStack] (the bottom nav
  /// case), [dispose] never fires on tab switches. The parent feeds us
  /// a freshly-computed visibility flag so we can clear the search
  /// input the moment the user navigates away. Defaults to `true` for
  /// the modal-route case (Run header â†’ Browse), where dispose handles
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

  static const Map<String, int> _qualityOrder = {
    'S': 0,
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
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _query = _searchCtrl.text.toLowerCase();
    });
  }

  @override
  void didUpdateWidget(covariant BrowseScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Hosting bottom nav re-renders us with `isVisible: false` whenever
    // the user picks another tab. Treat that edge as the natural moment
    // to wipe the search box so re-opening Browse always starts clean.
    if (oldWidget.isVisible && !widget.isVisible) {
      FocusManager.instance.primaryFocus?.unfocus();
      if (_searchCtrl.text.isNotEmpty) {
        _searchCtrl.clear();
      }
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<Gun> _sortedGuns(RunProvider p) {
    final list = p.allGuns
        .where((g) => g.name.toLowerCase().contains(_query))
        .toList();
    list.sort((a, b) {
      final c = (_qualityOrder[a.quality] ?? 99)
          .compareTo(_qualityOrder[b.quality] ?? 99);
      return c != 0 ? c : a.name.compareTo(b.name);
    });
    return list;
  }

  List<Item> _sortedItems(RunProvider p) {
    final list = p.allItems
        .where((it) => it.name.toLowerCase().contains(_query))
        .toList();
    list.sort((a, b) {
      final c = (_qualityOrder[a.quality] ?? 99)
          .compareTo(_qualityOrder[b.quality] ?? 99);
      return c != 0 ? c : a.name.compareTo(b.name);
    });
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
    final sf = Responsive.factor(context);
    final tabHeight = 52 * sf;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
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
                  height: tabHeight,
                  iconMargin: const EdgeInsets.only(bottom: 2),
                  icon: Icon(Icons.apps, size: 20 * sf),
                  text: isCoop ? 'All · P2' : 'All',
                ),
                Tab(
                  height: tabHeight,
                  iconMargin: const EdgeInsets.only(bottom: 2),
                  icon: Icon(Icons.gps_fixed, size: 20 * sf),
                  text: 'Guns',
                ),
                Tab(
                  height: tabHeight,
                  iconMargin: const EdgeInsets.only(bottom: 2),
                  icon: Icon(Icons.inventory_2_outlined, size: 20 * sf),
                  text: 'Items',
                ),
                Tab(
                  height: tabHeight,
                  iconMargin: const EdgeInsets.only(bottom: 2),
                  icon: Icon(Icons.favorite, size: 20 * sf),
                  text: 'Favs',
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
        children: [
          if (!isFavs) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: TextField(
                        controller: _searchCtrl,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: "Search...",
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 6),
                          suffixIcon: _searchCtrl.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear',
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                  },
                                ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.showBackButton && Navigator.canPop(context)) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Close Browse',
                      icon: const Icon(Icons.close_rounded, size: 22, color: Colors.white70),
                      onPressed: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        Navigator.maybePop(context);
                      },
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
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
                  label: const GoopText(
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
      ),
    );
  }

  Widget _gunsList(RunProvider p) {
    final items = _sortedGuns(p);
    if (items.isEmpty) return _emptyState();
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

  /// Tappable row for a gun. Used by both the Guns and All tabs.
  Widget _gunRow(BuildContext c, RunProvider p, Gun g) {
    final syn = p.synergyCountFor(g.name);
    final targetPlayer = widget.targetSlot == PlayerSlot.coop
        ? p.runState.coop
        : p.runState.main;
    final charName = targetPlayer?.character?.name.toLowerCase() ?? '';
    final isRobot = charName.contains('robot');

    return BrowseRow(
      name: g.name,
      quality: g.quality,
      iconPath: g.icon,
      fallback: Icons.gps_fixed,
      meta: GunMeta(gun: g, synergyCount: syn),
      inRun: p.ownerSlotOfGun(g.name) == widget.targetSlot,
      isRobot: isRobot,
      onTap: () async {
        FocusManager.instance.primaryFocus?.unfocus();
        await Navigator.push(
          c,
          fastRoute(ItemDetailScreen(gun: g)),
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
            content: GoopText(widget.targetSlot == PlayerSlot.coop
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
        content: GoopText('Reconnecting to peer… try again in a moment.'),
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

    return BrowseRow(
      name: it.name,
      quality: it.quality,
      iconPath: it.icon,
      fallback: it.isActive ? Icons.flash_on : Icons.inventory_2_outlined,
      meta: ItemMeta(item: it, synergyCount: syn),
      inRun: p.ownerSlotOfItem(it.name) == widget.targetSlot,
      isRobot: isRobot,
      onTap: () async {
        FocusManager.instance.primaryFocus?.unfocus();
        await Navigator.push(
          c,
          fastRoute(ItemDetailScreen(item: it)),
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
            content: GoopText(isRobot && isHpUp
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

  /// Combined Guns + Items list — the default Browse view.
  Widget _allList(RunProvider p) {
    final guns = p.allGuns
        .where((g) => g.name.toLowerCase().contains(_query))
        .toList();
    final items = p.allItems
        .where((it) => it.name.toLowerCase().contains(_query))
        .toList();

    final entries = <AnyEntry>[
      for (final g in guns) AnyEntry.gun(g),
      for (final it in items) AnyEntry.item(it),
    ];

    entries.sort((a, b) {
      final c = (_qualityOrder[a.quality] ?? 99)
          .compareTo(_qualityOrder[b.quality] ?? 99);
      return c != 0 ? c : a.name.compareTo(b.name);
    });

    if (entries.isEmpty) return _emptyState();
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
    if (items.isEmpty) return _emptyState();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: items.length,
      itemBuilder: (c, i) => _itemRow(c, p, items[i]),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppTheme.flair.secondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            GoopText(
              _query.isEmpty
                  ? 'No guns or items to show.'
                  : 'No results for "$_query".',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.flair.secondary.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

