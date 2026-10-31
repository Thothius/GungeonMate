import '../theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../services/app_theme.dart';
import '../models/gun.dart';
import '../models/item.dart';
import '../models/player.dart';
import '../models/run_state.dart'; // Used by context.select type parameter
import 'item_detail_screen.dart';
import '../services/goop_talk_engine.dart';
import '../services/haptics.dart';
import '../utils/fast_route.dart';
import '../utils/responsive.dart';
import '../widgets/browse/any_entry.dart';
import '../widgets/browse/browse_pills.dart';
import '../widgets/browse/browse_row.dart';
import '../widgets/state_widgets.dart';
import '../widgets/skeuo/skeuo_tokens.dart';

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

enum _BrowseMode { all, tiers, synergies }

enum _KindFilter { all, guns, items, favourites }

enum _SynOwner { all, p1, p2 }

class _BrowseScreenState extends State<BrowseScreen> {
  _BrowseMode _mode = _BrowseMode.all;
  final Set<String> _tiers = {}; // empty = all tiers
  _KindFilter _kind = _KindFilter.all; // ALL-mode sub-filter
  _SynOwner _synOwner = _SynOwner.all; // synergies owner tab
  int _allCount = 0, _p1Count = 0, _p2Count = 0;
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
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Select only runState — the field that changes when items are
    // added/removed. This prevents rebuilds from MP sync events,
    // favorites toggles in other screens, or provider loading state
    // changes that don't affect the browse list.
    // The select triggers rebuilds when runState changes; the value
    // itself is read through p in the row builders below.
    context.select<RunProvider, RunState>((p) => p.runState);
    final p = context.read<RunProvider>();
    final isCoop = widget.targetSlot == PlayerSlot.coop;
    return PopScope(
      // Dismiss the soft keyboard before this route pops so the active
      // run view underneath isn't covered.
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: _buildScaffold(context, p, isCoop),
    );
  }

  Widget _buildScaffold(BuildContext context, RunProvider p, bool isCoop) {
    final sf = Responsive.factor(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        // When pushed as a route (showBackButton), show the standard
        // AppBar back arrow. When inside the bottom-nav IndexedStack,
        // keep toolbarHeight 0 — the tab strip labels the section.
        toolbarHeight: widget.showBackButton ? kToolbarHeight : 0,
        title:
            widget.showBackButton
                ? const GoopText('Browse')
                : const SizedBox.shrink(),
        bottom: PreferredSize(
          // Height is scale-factor aware — the mode bar and tier
          // strip size by Responsive.factor, so a fixed 64/108
          // overflowed vertically whenever sf > ~1.2.
          preferredSize: Size.fromHeight(
            (46 * sf) +
                (_mode == _BrowseMode.tiers ? (8 + 46 * sf) : 0) +
                (_mode == _BrowseMode.all ? (8 + 40 * sf) : 0) +
                (_mode == _BrowseMode.synergies ? (8 + 40 * sf) : 0) +
                12,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Filter mode bar — ALL / TIERS / SYNERGIES.
                Row(
                  children:
                      [
                        _modeBtn(
                          'ALL',
                          Icons.apps,
                          _BrowseMode.all,
                          isCoop ? 'ALL · P2' : 'ALL',
                          sf,
                        ),
                        _modeBtn(
                          'TIERS',
                          Icons.military_tech_outlined,
                          _BrowseMode.tiers,
                          'TIERS',
                          sf,
                        ),
                        _modeBtn(
                          'SYN',
                          Icons.hub_outlined,
                          _BrowseMode.synergies,
                          'SYNERGIES',
                          sf,
                        ),
                      ].map((w) => Expanded(child: w)).toList(),
                ),
                // Tier strip — only while TIERS mode is active. Nothing
                // selected means "show everything".
                if (_mode == _BrowseMode.tiers)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final t in const ['S', 'A', 'B', 'C', 'D', 'N'])
                          _tierChip(t, sf),
                      ],
                    ),
                  ),
                // ALL sub-filter — guns / items / favourites icons.
                if (_mode == _BrowseMode.all)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        for (final k in const [
                          (Icons.apps, 'ALL', _KindFilter.all),
                          (
                            Icons.sports_martial_arts_rounded,
                            'GUNS',
                            _KindFilter.guns,
                          ),
                          (Icons.backpack_rounded, 'ITEMS', _KindFilter.items),
                          (
                            Icons.favorite_rounded,
                            'FAVS',
                            _KindFilter.favourites,
                          ),
                        ])
                          Expanded(child: _kindChip(k.$1, k.$2, k.$3, sf)),
                      ],
                    ),
                  ),
                // SYNERGIES owner tabs — combined / P1 / P2 pools.
                if (_mode == _BrowseMode.synergies)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        for (final o in const [
                          ('ALL', _SynOwner.all),
                          ('P1', _SynOwner.p1),
                          ('P2', _SynOwner.p2),
                        ])
                          Expanded(child: _ownerTab(o.$1, o.$2, sf)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              // Align+heightFactor centers horizontally AND
              // shrink-wraps vertically — bare Center expands to eat
              // all column height and starves the list below.
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: 1.0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
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
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 6,
                              ),
                              suffixIcon:
                                  _searchCtrl.text.isEmpty
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
                      if (widget.showBackButton &&
                          Navigator.canPop(context)) ...[
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: 'Close Browse',
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 22,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.maybePop(context);
                          },
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(Insets.xs),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Wide screens: cap the row width so lists don't stretch
            // edge-to-edge on tablets/desktop windows.
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: _modeList(p),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One mode button in the ALL/TIERS/SYNERGIES bar.
  Widget _modeBtn(
    String key,
    IconData icon,
    _BrowseMode mode,
    String label,
    double sf,
  ) {
    final active = _mode == mode;
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: GestureDetector(
        onTap: () {
          Haptics.selection();
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() => _mode = mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 46 * sf,
          decoration: BoxDecoration(
            color:
                active ? primary.withValues(alpha: 0.22) : Colors.transparent,
            borderRadius: BorderRadius.all(Radii.md),
            border: Border.all(
              color:
                  active
                      ? primary.withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.12),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17 * sf,
                color: active ? primary : Colors.white.withValues(alpha: 0.45),
              ),
              SizedBox(width: 5 * sf),
              Flexible(
                child: GoopText(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: FontSizes.labelMedium * sf,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: 0.6,
                    color:
                        active ? primary : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// One tier filter chip — single-select: tapping a tier selects only
  /// it; tapping the selected tier clears back to "show all".
  /// Chest colors are muted when idle, bright when selected.
  Widget _tierChip(String tier, double sf) {
    final sel = _tiers.contains(tier);
    // Real chest colors — D brown, C blue, B green, A red, S gold.
    final accent =
        tier == 'S'
            ? const Color(0xFFFFD700)
            : tier == 'A'
            ? const Color(0xFFE53935)
            : tier == 'B'
            ? const Color(0xFF43A047)
            : tier == 'C'
            ? const Color(0xFF1E88E5)
            : tier == 'D'
            ? const Color(0xFF8D6E63)
            : Colors.white54;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: GestureDetector(
          key: Key('tier_chip_$tier'),
          onTap: () {
            Haptics.selection();
            setState(() {
              _tiers.clear();
              if (!sel) _tiers.add(tier);
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            height: 46 * sf,
            decoration: BoxDecoration(
              color:
                  sel
                      ? accent.withValues(alpha: 0.28)
                      : accent.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    sel
                        ? accent.withValues(alpha: 0.9)
                        : accent.withValues(alpha: 0.30),
                width: sel ? 1.8 : 1,
              ),
              boxShadow:
                  sel
                      ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.25),
                          blurRadius: 8,
                        ),
                      ]
                      : null,
            ),
            child: Center(
              child: GoopText(
                tier,
                style: TextStyle(
                  fontSize: 13 * sf,
                  fontWeight: FontWeight.w900,
                  color: sel ? accent : accent.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Mode-driven list — ALL/TIERS share the combined view (TIERS just
  /// filters by selected qualities); SYNERGIES shows candidates that
  /// complete or extend synergies for the COMBINED inventories.
  Widget _modeList(RunProvider p) {
    return switch (_mode) {
      _BrowseMode.all || _BrowseMode.tiers => _combinedList(p),
      _BrowseMode.synergies => _synergyCandidatesList(p),
    };
  }

  /// Combined guns+items, search-filtered, then tier-filtered when the
  /// TIERS strip has selections.
  Widget _combinedList(RunProvider p) {
    final guns =
        p.allGuns.where((g) => g.name.toLowerCase().contains(_query)).toList();
    final items =
        p.allItems
            .where((it) => it.name.toLowerCase().contains(_query))
            .toList();

    var entries = <AnyEntry>[
      for (final g in guns) AnyEntry.gun(g),
      for (final it in items) AnyEntry.item(it),
    ];

    entries.sort((a, b) {
      final c = (_qualityOrder[a.quality] ?? 99).compareTo(
        _qualityOrder[b.quality] ?? 99,
      );
      return c != 0 ? c : a.name.compareTo(b.name);
    });

    if (_mode == _BrowseMode.tiers && _tiers.isNotEmpty) {
      entries =
          entries
              .where((e) => _tiers.contains(e.quality.toUpperCase()))
              .toList();
    }
    // TIERS always spans guns + items + favourites — the ALL-mode
    // kind chips must not shrink the tier pool.
    if (_mode == _BrowseMode.all) {
      switch (_kind) {
        case _KindFilter.guns:
          entries = entries.where((e) => e.gun != null).toList();
        case _KindFilter.items:
          entries = entries.where((e) => e.item != null).toList();
        case _KindFilter.favourites:
          entries = entries.where((e) => p.isFavourite(e.name)).toList();
        case _KindFilter.all:
          break;
      }
    }

    if (entries.isEmpty) return _emptyState();
    // No prototypeItem — row heights vary (meta pills wrap to a second
    // line on narrow screens or when a COMPLETES pill is present), so
    // pinning every row to the first row's height overflows vertically.
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: entries.length,
      itemBuilder: (c, i) {
        final e = entries[i];
        return e.gun != null ? _gunRow(c, p, e.gun!) : _itemRow(c, p, e.item!);
      },
    );
  }

  /// Synergies [name] would complete against a pool, each tagged
  /// with who owns the other pieces — 'P1', 'P2', or 'P1+P2'.
  List<({String name, String owners})> _completesFor(
    String name, {
    required Set<String> combined,
    required Set<String> mainNames,
    required Set<String> coopNames,
    required Player? coop,
    required RunProvider p,
  }) {
    final lower = name.toLowerCase();
    if (combined.contains(lower)) return const [];
    final wouldOwn = {...combined, lower};
    final out = <({String name, String owners})>[];
    for (final s in p.allSynergies) {
      if (s.matchesOwnedSet(combined) || !s.matchesOwnedSet(wouldOwn)) {
        continue;
      }
      var p1 = false, p2 = false;
      for (final piece in [...s.items, ...s.anyOf]) {
        final pl = piece.toLowerCase();
        if (pl != lower) {
          if (mainNames.contains(pl)) p1 = true;
          if (coopNames.contains(pl)) p2 = true;
        }
      }
      out.add((
        name: s.name,
        owners:
            coop == null
                ? 'P1'
                : (p1 && p2
                    ? 'P1+P2'
                    : p2
                    ? 'P2'
                    : 'P1'),
      ));
    }
    return out;
  }

  /// Synergies already fully satisfied by [owned] — the 'already hits'
  /// section on top of the synergies list.
  List<({String name, String owners})> _completedSynergies(
    Set<String> owned,
    Set<String> mainNames,
    Set<String> coopNames,
    Player? coop,
    RunProvider p,
  ) {
    final out = <({String name, String owners})>[];
    for (final s in p.allSynergies) {
      if (!s.matchesOwnedSet(owned)) continue;
      var p1 = false, p2 = false;
      for (final piece in [...s.items, ...s.anyOf]) {
        final pl = piece.toLowerCase();
        if (mainNames.contains(pl)) p1 = true;
        if (coopNames.contains(pl)) p2 = true;
      }
      out.add((
        name: s.name,
        owners:
            coop == null
                ? 'P1'
                : (p1 && p2
                    ? 'P1+P2'
                    : p2
                    ? 'P2'
                    : 'P1'),
      ));
    }
    return out;
  }

  // Memoized candidate scan for _synergyCandidatesList — see sig check.
  String? _candSig;
  List<(AnyEntry, List<({String name, String owners})>)> _candHits = const [];
  List<({String name, String owners})> _candCompleted = const [];

  /// The O(guns+items × synergies) candidate scan. Runs only when the
  /// inventory+query signature changes (see _synergyCandidatesList).
  List<(AnyEntry, List<({String name, String owners})>)> _computeHits(
    Set<String> combined,
    Set<String> mainNames,
    Set<String> coopNames,
    Player? coop,
    RunProvider p,
  ) {
    final hits = <(AnyEntry, List<({String name, String owners})>)>[];
    for (final g in p.allGuns) {
      if (!g.name.toLowerCase().contains(_query)) continue;
      final done = _completesFor(
        g.name,
        combined: combined,
        mainNames: mainNames,
        coopNames: coopNames,
        coop: coop,
        p: p,
      );
      if (done.isNotEmpty) hits.add((AnyEntry.gun(g), done));
    }
    for (final it in p.allItems) {
      if (!it.name.toLowerCase().contains(_query)) continue;
      final done = _completesFor(
        it.name,
        combined: combined,
        mainNames: mainNames,
        coopNames: coopNames,
        coop: coop,
        p: p,
      );
      if (done.isNotEmpty) hits.add((AnyEntry.item(it), done));
    }
    hits.sort((a, b) {
      final c = b.$2.length.compareTo(a.$2.length);
      if (c != 0) return c;
      final q = (_qualityOrder[a.$1.quality] ?? 99).compareTo(
        _qualityOrder[b.$1.quality] ?? 99,
      );
      return q != 0 ? q : a.$1.name.compareTo(b.$1.name);
    });
    return hits;
  }

  /// Synergy candidates — guns/items neither player owns that would
  /// complete (or extend) a synergy given BOTH players' inventories.
  /// Sorted by completions desc, then quality, then name.
  Widget _synergyCandidatesList(RunProvider p) {
    final combined = <String>{
      ...p.runState.main.allItemNames.map((n) => n.toLowerCase()),
      if (p.runState.coop != null)
        ...p.runState.coop!.allItemNames.map((n) => n.toLowerCase()),
    };
    final coop = p.runState.coop;
    final mainNames =
        p.runState.main.allItemNames.map((n) => n.toLowerCase()).toSet();
    final coopNames =
        coop == null
            ? const <String>{}
            : coop.allItemNames.map((n) => n.toLowerCase()).toSet();

    // Candidate scan is O(guns+items × synergies) — memoize on the
    // inventory+query signature so rebuilds (notifyListeners, tab swaps)
    // don't rescan. Any inventory/query change produces a new signature.
    final sig = '$_query|${combined.join('')}';
    if (sig != _candSig) {
      _candSig = sig;
      _candHits = _computeHits(combined, mainNames, coopNames, coop, p);
      _candCompleted = _completedSynergies(
        combined,
        mainNames,
        coopNames,
        coop,
        p,
      );
    }
    final hits = [..._candHits];
    final completed = _candCompleted;

    // Per-owner counts for the tabs — same predicate each tab uses.
    final newAll = hits.length;
    final newP1 =
        hits.where((h) => h.$2.any((sy) => sy.owners.contains('P1'))).length;
    final newP2 =
        hits.where((h) => h.$2.any((sy) => sy.owners.contains('P2'))).length;
    if (newAll != _allCount || newP1 != _p1Count || newP2 != _p2Count) {
      _allCount = newAll;
      _p1Count = newP1;
      _p2Count = newP2;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
    // Owner tab filter — P1/P2 keep candidates where that player
    // owns at least one piece of a completable synergy.
    if (_synOwner != _SynOwner.all) {
      final tag = _synOwner == _SynOwner.p1 ? 'P1' : 'P2';
      hits.retainWhere((h) => h.$2.any((sy) => sy.owners.contains(tag)));
    }

    if (hits.isEmpty && completed.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Insets.xxl),
          child: GoopText(
            'No synergy candidates.\nGuns/items that would complete a '
            'synergy for either player show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: FontSizes.bodyMedium,
              height: 1.5,
              color: AppTheme.flair.secondary.withValues(alpha: 0.55),
            ),
          ),
        ),
      );
    }

    final headCount = completed.isEmpty ? 0 : completed.length + 2;
    // Dedupe synergies from all candidate hits — rows are synergy-
    // centric now (title + piece icons), not item-centric.
    final seen = <String>{};
    final synRows = <({String name, String owners})>[
      for (final h in hits)
        for (final s in h.$2)
          if (seen.add(s.name)) s,
    ];
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: headCount + synRows.length,
      itemBuilder: (c, i) {
        if (completed.isNotEmpty && i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 13,
                  color: Skeuo.inkIf(Colors.greenAccent),
                ),
                const SizedBox(width: 6),
                GoopText(
                  'COMPLETE',
                  style: TextStyle(
                    fontSize: FontSizes.labelSmall,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    color: Skeuo.inkIf(
                      Colors.greenAccent,
                    ).withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          );
        }
        if (completed.isNotEmpty && i <= completed.length) {
          final cs = completed[i - 1];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Skeuo.inkIf(Colors.greenAccent).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Skeuo.inkIf(
                    Colors.greenAccent,
                  ).withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 11,
                    color: Skeuo.inkIf(
                      Colors.greenAccent,
                    ).withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: GoopText(
                      cs.name,
                      style: TextStyle(
                        fontSize: FontSizes.labelSmall,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Skeuo.inkIf(
                        Colors.greenAccent,
                      ).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Skeuo.inkIf(
                          Colors.greenAccent,
                        ).withValues(alpha: 0.4),
                      ),
                    ),
                    child: GoopText(
                      cs.owners,
                      style: TextStyle(
                        fontSize: FontSizes.labelSmall,
                        fontWeight: FontWeight.w800,
                        color: Skeuo.inkIf(Colors.greenAccent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        if (completed.isNotEmpty && i == completed.length + 1) {
          return Divider(
            color: Colors.white.withValues(alpha: 0.10),
            height: 16,
            thickness: 1,
          );
        }
        final hi = i - headCount;
        return _compactSynRow(c, p, synRows[hi], combined, coop != null);
      },
    );
  }

  /// Compact synergy-centric row — title + piece icons (owned pieces
  /// highlighted, missing ones outlined + tappable to detail) + a
  /// quick-add button that grants all missing pieces.
  Widget _compactSynRow(
    BuildContext c,
    RunProvider p,
    ({String name, String owners}) syn,
    Set<String> combined,
    bool isCoop,
  ) {
    final synObj = p.allSynergies.where((s) => s.name == syn.name).firstOrNull;
    if (synObj == null) return const SizedBox.shrink();
    final pieces = <String>{...synObj.items, ...synObj.anyOf}.toList();
    final missing =
        pieces.where((n) => !combined.contains(n.toLowerCase())).toList();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.flair.card.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GoopText(
                  syn.name,
                  style: TextStyle(
                    fontSize: FontSizes.bodyMedium,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                if (isCoop)
                  GoopText(
                    syn.owners,
                    style: TextStyle(
                      fontSize: FontSizes.labelSmall,
                      color: Skeuo.inkIf(
                        Colors.greenAccent,
                      ).withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final n in pieces)
                    _pieceIcon(c, p, n, combined.contains(n.toLowerCase())),
                ],
              ),
            ),
          ),
          if (missing.isNotEmpty)
            GestureDetector(
              onTap: () {
                // Add missing required pieces; for any_of synergies add
                // only ONE missing option (that's all the synergy needs).
                var added = 0;
                final needed = [
                  ...missing.where((n) => !synObj.anyOf.contains(n)),
                  if (synObj.anyOf.isNotEmpty &&
                      !synObj.anyOf.any(
                        (n) => combined.contains(n.toLowerCase()),
                      ))
                    missing.firstWhere(
                      (n) => synObj.anyOf.contains(n),
                      orElse: () => '',
                    ),
                ];
                for (final n in needed) {
                  if (n.isEmpty) continue;
                  final g = p.allGuns.where((x) => x.name == n).firstOrNull;
                  final it = p.allItems.where((x) => x.name == n).firstOrNull;
                  if (g != null) {
                    p.addGun(g, slot: widget.targetSlot);
                    added++;
                  } else if (it != null) {
                    p.addItem(it, slot: widget.targetSlot);
                    added++;
                  }
                }
                if (added > 0) {
                  Haptics.light();
                  ScaffoldMessenger.of(c).showSnackBar(
                    SnackBar(
                      content: GoopText(
                        '$added item${added > 1 ? 's' : ''} added for ${syn.name}',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(left: 6),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Skeuo.inkIf(
                    Colors.greenAccent,
                  ).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Skeuo.inkIf(
                      Colors.greenAccent,
                    ).withValues(alpha: 0.6),
                  ),
                ),
                child: Icon(
                  Icons.add,
                  size: 18,
                  color: Skeuo.inkIf(Colors.greenAccent),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// One piece icon — highlighted when owned, outline when missing.
  /// Missing pieces tap through to that item's detail screen.
  Widget _pieceIcon(BuildContext c, RunProvider p, String name, bool owned) {
    final g = p.allGuns.where((x) => x.name == name).firstOrNull;
    final it = p.allItems.where((x) => x.name == name).firstOrNull;
    final icon = g?.icon ?? it?.icon ?? '';
    final box = Container(
      margin: const EdgeInsets.only(left: 4),
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color:
            owned
                ? Skeuo.inkIf(Colors.greenAccent).withValues(alpha: 0.18)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color:
              owned
                  ? Skeuo.inkIf(Colors.greenAccent).withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.25),
          width: owned ? 1.6 : 1,
        ),
      ),
      child: Center(
        child:
            icon.isNotEmpty
                ? Opacity(
                  opacity: owned ? 1.0 : 0.45,
                  child: Image.asset(
                    icon.startsWith('assets/') ? icon : 'assets/images/$icon',
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                    errorBuilder:
                        (_, _, _) => Icon(
                          Icons.help_outline,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                  ),
                )
                : Icon(
                  Icons.help_outline,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
      ),
    );
    if (owned || (g == null && it == null)) return box;
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        if (g != null) {
          Navigator.push(c, fastRoute(ItemDetailScreen(gun: g)));
        } else {
          Navigator.push(c, fastRoute(ItemDetailScreen(item: it)));
        }
      },
      child: box,
    );
  }

  /// Tappable row for a gun — combined + synergies views.
  Widget _gunRow(
    BuildContext c,
    RunProvider p,
    Gun g, {
    List<String>? completes,
    String? ownerLabel,
  }) {
    final syn = p.synergyCountFor(g.name);
    completes ??= p.synergiesCompletedBy(g.name, slot: widget.targetSlot);
    final targetPlayer =
        widget.targetSlot == PlayerSlot.coop
            ? p.runState.coop
            : p.runState.main;
    final charName = targetPlayer?.character?.name.toLowerCase() ?? '';
    final isRobot = charName.contains('robot');

    return BrowseRow(
      name: g.name,
      quality: g.quality,
      iconPath: g.icon,
      fallback: Icons.gps_fixed,
      meta: GunMeta(
        gun: g,
        synergyCount: syn,
        completesSynergies: completes,
        ownerLabel: ownerLabel,
      ),
      inRun: p.ownerSlotOfGun(g.name) == widget.targetSlot,
      isRobot: isRobot,
      onTap: () async {
        FocusManager.instance.primaryFocus?.unfocus();
        await Navigator.push(c, fastRoute(ItemDetailScreen(gun: g)));
        if (!mounted) return;
        // Drop the keyboard again on return — Flutter likes to restore
        // focus to the search field, which would re-open the IME.
        FocusManager.instance.primaryFocus?.unfocus();
      },
      onAdd: () {
        p.addGun(g, slot: widget.targetSlot);
        ScaffoldMessenger.of(c).showSnackBar(
          SnackBar(
            content: GoopText(
              widget.targetSlot == PlayerSlot.coop
                  ? '${g.name} added to P2'
                  : '${g.name} added',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }

  /// Tappable row for an item — combined + synergies views.
  Widget _itemRow(
    BuildContext c,
    RunProvider p,
    Item it, {
    List<String>? completes,
    String? ownerLabel,
  }) {
    final syn = p.synergyCountFor(it.name);
    completes ??= p.synergiesCompletedBy(it.name, slot: widget.targetSlot);
    final targetPlayer =
        widget.targetSlot == PlayerSlot.coop
            ? p.runState.coop
            : p.runState.main;
    final charName = targetPlayer?.character?.name.toLowerCase() ?? '';
    final isRobot = charName.contains('robot');

    return BrowseRow(
      name: it.name,
      quality: it.quality,
      iconPath: it.icon,
      fallback: it.isActive ? Icons.flash_on : Icons.inventory_2_outlined,
      meta: ItemMeta(
        item: it,
        synergyCount: syn,
        completesSynergies: completes,
        ownerLabel: ownerLabel,
      ),
      inRun: p.ownerSlotOfItem(it.name) == widget.targetSlot,
      isRobot: isRobot,
      onTap: () async {
        FocusManager.instance.primaryFocus?.unfocus();
        await Navigator.push(c, fastRoute(ItemDetailScreen(item: it)));
        if (!mounted) return;
        FocusManager.instance.primaryFocus?.unfocus();
      },
      onAdd: () {
        p.addItem(it, slot: widget.targetSlot);
        final nameLower = it.name.toLowerCase();
        final isHpUp =
            nameLower.contains('master round') ||
            nameLower.contains('heart container') ||
            nameLower.contains('heart holster') ||
            nameLower.contains('heart locket') ||
            nameLower.contains('heart purse') ||
            nameLower.contains('heart bottle') ||
            nameLower.contains('yellow chamber') ||
            nameLower.contains('pink guon stone');

        ScaffoldMessenger.of(c).showSnackBar(
          SnackBar(
            content: GoopText(
              isRobot && isHpUp
                  ? 'Robot Tax: ${it.name} converted to +1 Armor & grants 10-15 casings!'
                  : (widget.targetSlot == PlayerSlot.coop
                      ? '${it.name} added to P2'
                      : '${it.name} added'),
            ),
            duration: Duration(seconds: isRobot && isHpUp ? 3 : 1),
            backgroundColor:
                isRobot && isHpUp ? Skeuo.inkIf(Colors.blue.shade900) : null,
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return EmptyState(
      icon: Icons.search_off_rounded,
      message:
          _query.isEmpty
              ? 'No guns or items to show.'
              : 'No results for "$_query".',
      flavor:
          _query.isEmpty
              ? 'The Gungeon keeps its secrets.'
              : 'Not even the Resourceful Rat has that.',
    );
  }

  /// Kind chip for the ALL sub-filter — gun / item / heart icons.
  Widget _kindChip(IconData icon, String label, _KindFilter k, double sf) {
    final active = _kind == k;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: GestureDetector(
        onTap: () {
          Haptics.selection();
          setState(() => _kind = k);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 40 * sf,
          decoration: BoxDecoration(
            color:
                active
                    ? AppTheme.flair.primary.withValues(alpha: 0.16)
                    : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  active
                      ? AppTheme.flair.primary
                      : Colors.white.withValues(alpha: 0.15),
              width: active ? 1.6 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14 * sf,
                color:
                    active
                        ? AppTheme.flair.primary
                        : Colors.white.withValues(alpha: 0.5),
              ),
              SizedBox(width: 5 * sf),
              GoopText(
                label,
                style: TextStyle(
                  fontSize: FontSizes.labelSmall,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color:
                      active
                          ? AppTheme.flair.primary
                          : Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Owner tab for synergies — avatar + count on the right.
  Widget _ownerTab(String label, _SynOwner o, double sf) {
    final active = _synOwner == o;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: GestureDetector(
        onTap: () {
          Haptics.selection();
          setState(() => _synOwner = o);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 40 * sf,
          decoration: BoxDecoration(
            color:
                active
                    ? AppTheme.flair.primary.withValues(alpha: 0.16)
                    : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  active
                      ? AppTheme.flair.primary
                      : Colors.white.withValues(alpha: 0.15),
              width: active ? 1.6 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GoopText(
                label,
                style: TextStyle(
                  fontSize: FontSizes.labelSmall,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color:
                      active
                          ? AppTheme.flair.primary
                          : Colors.white.withValues(alpha: 0.5),
                ),
              ),
              SizedBox(width: 5 * sf),
              GoopText(
                '${o == _SynOwner.all
                    ? _allCount
                    : o == _SynOwner.p1
                    ? _p1Count
                    : _p2Count}',
                style: TextStyle(
                  fontSize: FontSizes.labelSmall,
                  fontWeight: FontWeight.w700,
                  color:
                      active
                          ? AppTheme.flair.primary
                          : Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
