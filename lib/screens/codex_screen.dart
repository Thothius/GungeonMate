import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/codex_entry.dart';
import '../providers/run_provider.dart';
import '../services/app_theme.dart';
import '../services/haptics.dart';
import '../theme/tokens.dart';
import '../widgets/active_run/bottom_back_bar.dart';
import '../widgets/codex/ammonomicon_tabs.dart';
import '../widgets/state_widgets.dart';
import 'codex_detail_screen.dart';
import 'gungeoneer_detail_screen.dart';
import 'item_detail_screen.dart';
import 'synergy_detail_screen.dart';
import '../utils/asset_paths.dart';
import '../utils/fast_route.dart';
import '../services/goop_talk_engine.dart';

// ── Isolate parse helper ───────────────────────────────────────
// Top-level function for compute() — parses a JSON string into a list
// of CodexEntry objects off the main isolate.
List<CodexEntry> _parseCodexEntries(String jsonStr) =>
    (jsonDecode(jsonStr) as List)
        .map((j) => CodexEntry.fromJson(j as Map<String, dynamic>))
        .toList();

/// The GungeonMate Codex — a browseable encyclopedia of Objects, Pickups,
/// NPCs, Enemies, and Bosses from Enter the Gungeon, plus themed special
/// pages for Bullet Hell, The Paradox, and The Gunslinger.
///
/// Categories are presented as a grid of tappable tiles at the top for
/// quick, visual access. Special pages come first, then data categories.
class CodexScreen extends StatefulWidget {
  final bool showBackButton;

  const CodexScreen({super.key, this.showBackButton = false});

  @override
  State<CodexScreen> createState() => _CodexScreenState();
}

class _CodexScreenState extends State<CodexScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  /// Quality-letter filter for the Ammonomicon Guns/Items tabs.
  /// Empty = show all.
  final Set<String> _qualityFilter = {};
  static const _qualities = ['D', 'C', 'B', 'A', 'S'];
  static const _qualityRank = {'S': 0, 'A': 1, 'B': 2, 'C': 3, 'D': 4};

  /// Sort mode for Guns/Items tabs: 'name' (A-Z) or 'quality' (S→D).
  String _sortMode = 'name';

  /// Index of the grid category currently expanded inline (-1 = none).
  /// Chapters/Game Modes tiles expand to show member pickers.
  int _expanded = -1;

  // Currently selected category index (0-based). 0-5 are special pages,
  // 6-10 are data categories.
  int _selected = -1; // -1 = category picker grid (level 1)

  // Whether the bookmark tab strip is collapsed (hidden) to give the
  // content area the full screen width.

  // Loaded data
  List<CodexEntry> _objects = [];
  List<CodexEntry> _shrines = [];
  List<CodexEntry> _chapters = [];
  List<CodexEntry> _gameModes = [];
  List<CodexEntry> _pickups = [];
  List<CodexEntry> _npcs = [];
  List<CodexEntry> _enemies = [];
  List<CodexEntry> _bosses = [];
  bool _loaded = false;

  // Category definitions — Ammonomicon bookmark tabs.
  // The 5 ammonomicon tab icons map to: Guns→Objects, Items→Pickups,
  // Enemies, Bosses, Death→NPCs. The 7 special pages use themed Material
  // icons in the same bookmark visual style.
  static const _categories = [
    AmmonomiconTab(
      label: 'Gungeoneers',
      icon: Icons.person,
      color: CodexColors.gungeoneers,
      isSpecial: true,
    ),
    AmmonomiconTab(
      label: 'NPCs',
      assetIcon: 'Ammonomicon_Tab_Death',
      icon: Icons.person_outline,
      color: CodexColors.npcs,
      isSpecial: false,
    ),
    AmmonomiconTab(
      label: 'Enemies',
      assetIcon: 'Ammonomicon_Tab_Enemies',
      icon: Icons.dangerous_outlined,
      color: CodexColors.enemies,
      isSpecial: false,
    ),
    AmmonomiconTab(
      label: 'Bosses',
      assetIcon: 'Ammonomicon_Tab_Bosses',
      icon: Icons.emoji_events_outlined,
      color: CodexColors.bosses,
      isSpecial: false,
    ),
    AmmonomiconTab(
      label: 'Pickups',
      assetIcon: 'Ammonomicon_Tab_Items',
      icon: Icons.inventory_2_outlined,
      color: CodexColors.pickups,
      isSpecial: false,
    ),
    AmmonomiconTab(
      label: 'Objects',
      assetIcon: 'Ammonomicon_Tab_Guns',
      icon: Icons.widgets,
      color: CodexColors.objects,
      isSpecial: false,
    ),
    // ── Ammonomicon wiki cats (fabricated from provider data) ──
    AmmonomiconTab(
      label: 'Guns',
      assetIcon: 'Ammonomicon_Tab_Guns',
      icon: Icons.gps_fixed,
      color: CodexColors.objects,
      isSpecial: false,
    ),
    AmmonomiconTab(
      label: 'Items',
      assetIcon: 'Ammonomicon_Tab_Items',
      icon: Icons.inventory_2,
      color: CodexColors.pickups,
      isSpecial: false,
    ),
    AmmonomiconTab(
      label: 'Synergies',
      icon: Icons.auto_awesome,
      color: Color(0xFFB388FF),
      isSpecial: false,
    ),
    AmmonomiconTab(
      label: 'Shrines',
      icon: Icons.church,
      color: Color(0xFFFFB74D),
      isSpecial: false,
    ),
    AmmonomiconTab(
      label: 'Chapters',
      icon: Icons.layers,
      color: Color(0xFF4FC3F7),
      isSpecial: false,
      expandable: true,
    ),
    AmmonomiconTab(
      label: 'Game Modes',
      icon: Icons.sports_esports,
      color: Color(0xFFAED581),
      isSpecial: false,
      expandable: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _loadData();
  }

  void _onSearchChanged() {
    setState(() {
      _query = _searchCtrl.text.toLowerCase();
    });
  }

  Future<void> _loadData() async {
    final bundle = DefaultAssetBundle.of(context);
    final results = await Future.wait([
      bundle.loadString('assets/data/objects.json'),
      bundle.loadString('assets/data/pickups.json'),
      bundle.loadString('assets/data/npcs.json'),
      bundle.loadString('assets/data/enemies.json'),
      bundle.loadString('assets/data/bosses.json'),
      bundle.loadString('assets/data/shrines.json'),
      bundle.loadString('assets/data/chapters.json'),
      bundle.loadString('assets/data/game_modes.json'),
    ]);
    if (!mounted) return;
    // Parse each JSON file in an isolate to avoid jank on the codex screen.
    final parsed = await Future.wait([
      compute(_parseCodexEntries, results[0]),
      compute(_parseCodexEntries, results[1]),
      compute(_parseCodexEntries, results[2]),
      compute(_parseCodexEntries, results[3]),
      compute(_parseCodexEntries, results[4]),
      compute(_parseCodexEntries, results[6]),
      compute(_parseCodexEntries, results[7]),
    ]);
    if (!mounted) return;
    // Shrines: custom parse — JSON icon fields are wiki URLs; the local
    // assets live in assets/images/shrines/<slug>.webp.
    final shrineList = (json.decode(results[5]) as List<dynamic>)
        .map((e) {
          final j = e as Map<String, dynamic>;
          final slug = (j['name'] as String)
              .toLowerCase()
              .replaceAll(' ', '_')
              .replaceAll('.', '');
          // 'fallen angel' ships as Angel_Shrine.webp — all other
          // shrine icons are lowercase-name webps.
          final iconFile = slug == 'fallen_angel'
              ? 'Angel_Shrine.webp'
              : '$slug.webp';
          final eff = (j['effect'] as String? ?? '').trim();
          return CodexEntry(
              name: j['name'] ?? '',
              category: 'Shrines',
              icon: 'shrines/$iconFile',
              description: j['description'] ?? '',
              tips: [
                if (eff.isNotEmpty) eff,
                if ((j['curse'] ?? 0) > 0) 'Costs ${j['curse']} curse',
                if ((j['coolness'] ?? 0) > 0) 'Costs ${j['coolness']} coolness',
              ],
              wikiUrl:
                  'https://enterthegungeon.wiki.gg/wiki/${(j['name'] as String).replaceAll(' ', '_')}_Shrine');
        })
        .toList();
    setState(() {
      _objects = parsed[0];
      _pickups = parsed[1];
      _npcs = parsed[2];
      _enemies = parsed[3];
      _bosses = parsed[4];
      _shrines = shrineList;
      _chapters = parsed[5];
      _gameModes = parsed[6];
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CodexEntry> _filter(List<CodexEntry> entries) {
    if (_query.isEmpty) return entries;
    return entries.where((e) {
      if (e.name.toLowerCase().contains(_query) ||
          e.category.toLowerCase().contains(_query) ||
          e.description.toLowerCase().contains(_query)) {
        return true;
      }
      if (e.ammonomicon != null &&
          e.ammonomicon!.toLowerCase().contains(_query)) {
        return true;
      }
      return e.tips.any((t) => t.toLowerCase().contains(_query));
    }).toList();
  }

  /// Returns the data entries for the selected data category.
  List<CodexEntry> _entriesFor(int index) {
    switch (index) {
      case 1:
        return _filter(_npcs);
      case 2:
        return _filter(_enemies);
      case 3:
        return _filter(_bosses);
      case 4:
        return _filter(_pickups);
      case 5:
        return _filter(_objects);
      // Ammonomicon wiki cats — fabricated from provider models on
      // demand (already loaded; no extra JSON parse).
      case 6:
        var guns = context.read<RunProvider>().allGuns.toList();
        if (_sortMode == 'quality') {
          guns.sort((a, b) =>
              (_qualityRank[a.quality] ?? 9)
                  .compareTo(_qualityRank[b.quality] ?? 9));
        }
        return _filter(guns
            .where((g) =>
                _qualityFilter.isEmpty || _qualityFilter.contains(g.quality))
            .map((g) => CodexEntry(
                name: g.name,
                category: 'Guns',
                icon: g.icon,
                game: 'gun',
                description: g.notes))
            .toList());
      case 7:
        var items = context.read<RunProvider>().allItems.toList();
        if (_sortMode == 'quality') {
          items.sort((a, b) =>
              (_qualityRank[a.quality] ?? 9)
                  .compareTo(_qualityRank[b.quality] ?? 9));
        }
        return _filter(items
            .where((i) =>
                _qualityFilter.isEmpty || _qualityFilter.contains(i.quality))
            .map((i) => CodexEntry(
                name: i.name,
                category: 'Items',
                icon: i.icon,
                game: 'item',
                description: i.ammonomiconEntry))
            .toList());
      case 8:
        return _filter(context
            .read<RunProvider>()
            .allSynergies
            .map((s) {

            // Derive icon + folder from the first required item —
            // most synergies have no own sprite; showing the anchor
            // item's icon is the closest visual.
            final p = context.read<RunProvider>();
            final anchor = s.items.isNotEmpty ? s.items.first : '';
            final gun = p.allGuns
                .where((g) => g.name.toLowerCase() == anchor.toLowerCase())
                .firstOrNull;
            final item = p.allItems
                .where((i) => i.name.toLowerCase() == anchor.toLowerCase())
                .firstOrNull;
            return CodexEntry(
                name: s.name,
                category: 'Synergies',
                icon: gun != null
                    ? 'guns/${gun.icon}'
                    : item != null
                        ? 'items/${item.icon}'
                        : '',
                game: 'synergy',
                description: s.effect,
                ammonomicon: [...s.items, ...s.anyOf].join(' · '));
          }).toList());
      case 9:
        return _filter(_shrines);
      case 10:
        return _filter(_chapters);
      case 11:
        return _filter(_gameModes);
      default:
        return [];
    }
  }

  /// Expanded member picker — a themed card list shown in place of the
  /// category grid when a Chapters/Game Modes tile is tapped.
  Widget _buildExpandedPanel(ThemeFlair flair) {
    final c = _categories[_expanded];
    final members = _entriesFor(_expanded);
    final section = _sectionFor(_expanded);
    return SafeArea(
      top: !widget.showBackButton,
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — back to grid + category label
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: c.color, size: 20),
                  onPressed: () {
                    Haptics.selection();
                    setState(() => _expanded = -1);
                  },
                  tooltip: 'Back',
                ),
                Icon(c.icon ?? Icons.list, color: c.color, size: 18),
                const SizedBox(width: 8),
                GoopText(
                  c.label.toUpperCase(),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                      color: c.color),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
              itemCount: members.length,
              itemBuilder: (_, i) {
                final e = members[i];
                final subtitle = (e.tips.isNotEmpty)
                    ? e.tips.first
                    : (e.description.isNotEmpty
                        ? e.description
                        : '');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: c.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      splashColor: c.color.withValues(alpha: 0.2),
                      onTap: () {
                        Haptics.selection();
                        _openEntry(e, section);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: c.color.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            _searchIcon(e, section),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  GoopText(e.name,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight:
                                              FontWeight.w700)),
                                  if (subtitle.isNotEmpty)
                                    GoopText(subtitle,
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.white
                                                .withValues(
                                                    alpha: 0.55))),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                size: 18,
                                color:
                                    c.color.withValues(alpha: 0.6)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Grouped search result container for the global-search view.
  Widget _searchIcon(CodexEntry entry, CodexSection section) {
    final path = codexAssetPath(section, entry.icon);
    if (path.isEmpty) {
      return const Icon(Icons.help_outline, size: 20);
    }
    return Image.asset(path,
        width: 26,
        height: 26,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.help_outline, size: 20));
  }

  /// Shared tap routing — guns/items go to their detail screens,
  /// synergies to the synergy graph, everything else to codex detail.
  void _openEntry(CodexEntry entry, CodexSection section) {
    final p = context.read<RunProvider>();
    final gun = entry.game == 'gun'
        ? p.allGuns
            .where((g) => g.name == entry.name)
            .firstOrNull
        : null;
    final item = entry.game == 'item'
        ? p.allItems
            .where((i) => i.name == entry.name)
            .firstOrNull
        : null;
    final syn = entry.game == 'synergy'
        ? p.allSynergies
            .where((s) => s.name == entry.name)
            .firstOrNull
        : null;
    final dest = gun != null
        ? ItemDetailScreen(gun: gun)
        : item != null
            ? ItemDetailScreen(item: item)
            : syn != null
                ? SynergyDetailScreen(synergy: syn)
                : CodexDetailScreen(entry: entry, section: section);
    Navigator.push(context, fastRoute(dest));
  }

  Widget _buildQualityChips(ThemeFlair flair) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Haptics.selection();
              setState(() =>
                  _sortMode = _sortMode == 'name' ? 'quality' : 'name');
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: GoopText(
                _sortMode == 'name' ? 'A-Z' : 'S-D',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.7)),
              ),
            ),
          ),
          for (final q in _qualities)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () {
                  Haptics.selection();
                  setState(() {
                    _qualityFilter.contains(q)
                        ? _qualityFilter.remove(q)
                        : _qualityFilter.add(q);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _qualityFilter.contains(q)
                        ? flair.primary.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _qualityFilter.contains(q)
                          ? flair.primary.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: GoopText(
                    q,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _qualityFilter.contains(q)
                          ? flair.primary
                          : Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  CodexSection _sectionFor(int index) =>
      ammonomiconSectionForIndex(index);

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: widget.showBackButton ? const BottomBackBar() : null,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        toolbarHeight: widget.showBackButton ? kToolbarHeight : 0,
        leading: null,
        title:
            widget.showBackButton
                ? const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GoopText(
                      'CODEX',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    GoopText(
                      'Encyclopedia of the Gungeon',
                      style: TextStyle(
                        fontSize: FontSizes.labelSmall,
                        fontWeight: FontWeight.w500,
                        color: Colors.white54,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                )
                : const SizedBox.shrink(),
      ),
      body:
          !_loaded
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SkeletonLoader(width: 220, height: 28),
                    const SizedBox(height: Insets.md),
                    const SkeletonLoader(width: 180, height: 16),
                    const SizedBox(height: Insets.sm),
                    const SkeletonLoader(width: 200, height: 16),
                    const SizedBox(height: Insets.sm),
                    const SkeletonLoader(width: 160, height: 16),
                  ],
                ),
              )
              : _selected < 0
              ? _buildCategoryGrid(flair)
              : _buildPickedCategory(flair),
    );
  }

  // ── Level 1: 4-col category picker grid ─────────────────────────────
  Widget _buildCategoryGrid(ThemeFlair flair) {
    // Global search: query active on the picker level → grouped
    // results across ALL non-special categories (browse-style).
    if (_query.isNotEmpty) {
      final groups = <_SearchGroup>[];
      for (var i = 0; i < _categories.length; i++) {
        final c = _categories[i];
        if (c.isSpecial) continue;
        final ent = _entriesFor(i);
        if (ent.isNotEmpty) {
          groups.add(_SearchGroup(
              tab: c, entries: ent, section: _sectionFor(i)));
        }
      }
      return SafeArea(
        top: !widget.showBackButton,
        bottom: false,
        child: groups.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off,
                        size: 40,
                        color: Colors.white.withValues(alpha: 0.25)),
                    const SizedBox(height: 10),
                    GoopText(
                      'Nothing found for "${_searchCtrl.text}"',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                children: [
                  for (final g in groups) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 14, 0, 6),
                      child: GoopText(
                        g.tab.label.toUpperCase(),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: g.tab.color),
                      ),
                    ),
                    for (final e in g.entries)
                      ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        leading: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: g.tab.color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: g.tab.color
                                    .withValues(alpha: 0.35)),
                          ),
                          child: Center(
                              child: _searchIcon(e, g.section)),
                        ),
                        title: GoopText(e.name,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        onTap: () {
                          Haptics.selection();
                          _openEntry(e, g.section);
                        },
                      ),
                  ],
                ],
              ),
      );
    }
    // Expanded member picker — Chapters/Game Modes tiles swap the
    // grid for a themed card list of their entries.
    if (_expanded >= 0) {
      return _buildExpandedPanel(flair);
    }
    return SafeArea(
      top: !widget.showBackButton,
      bottom: false,
      child: GridView.builder(
        padding: const EdgeInsets.all(Insets.md),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85,
        ),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final c = _categories[i];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Haptics.selection();
                setState(() {
                  _searchCtrl.clear();
                  _query = '';
                  if (c.expandable) {
                    _expanded = i;
                  } else {
                    _selected = i;
                  }
                });
              },
              borderRadius: BorderRadius.all(Radii.md),
              splashColor: c.color.withValues(alpha: 0.25),
              highlightColor: c.color.withValues(alpha: 0.10),
              child: Container(
                decoration: BoxDecoration(
                  color: c.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.all(Radii.md),
                  border: Border.all(
                    color: c.color.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (c.assetIcon != null)
                      Image.asset(
                        AmmonomiconTabStrip.tabAssetPath(c.assetIcon!),
                        width: 34,
                        height: 34,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                        errorBuilder:
                            (_, _, _) => Icon(
                              c.icon ?? Icons.bookmark,
                              size: 30,
                              color: c.color,
                            ),
                      )
                    else
                      Icon(c.icon ?? Icons.bookmark, size: 30, color: c.color),
                    const SizedBox(height: 8),
                    GoopText(
                      c.label.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: FontSizes.labelSmall,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: c.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Level 2: picked category — back + title, search, content ────────
  Widget _buildPickedCategory(ThemeFlair flair) {
    final cat = _categories[_selected];
    return SafeArea(
      top: !widget.showBackButton,
      bottom: false,
      child: Column(
        children: [
          // Header — back to grid + category title.
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, Insets.md, 2),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back to categories',
                  icon: const Icon(Icons.arrow_back, size: 22),
                  color: cat.color,
                  onPressed: () {
                    Haptics.selection();
                    setState(() => _selected = -1);
                  },
                ),
                Icon(cat.icon ?? Icons.bookmark, size: 20, color: cat.color),
                const SizedBox(width: 8),
                Expanded(
                  child: GoopText(
                    cat.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: FontSizes.titleMedium,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                      color: cat.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Category scroll strip — quick jump between categories.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.sm,
              vertical: 4,
            ),
            child: Row(
              children: List.generate(_categories.length, (i) {
                final c = _categories[i];
                final isSelected = i == _selected;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      Haptics.selection();
                      setState(() {
                        _selected = i;
                        _searchCtrl.clear();
                        _query = '';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? c.color.withValues(alpha: 0.25)
                                : c.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              isSelected
                                  ? c.color
                                  : c.color.withValues(alpha: 0.35),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (c.assetIcon != null)
                            Image.asset(
                              AmmonomiconTabStrip.tabAssetPath(c.assetIcon!),
                              width: 16,
                              height: 16,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.none,
                              errorBuilder:
                                  (_, _, _) => Icon(
                                    c.icon ?? Icons.bookmark,
                                    size: 14,
                                    color: c.color,
                                  ),
                            )
                          else
                            Icon(
                              c.icon ?? Icons.bookmark,
                              size: 14,
                              color: c.color,
                            ),
                          const SizedBox(width: 6),
                          GoopText(
                            c.label.toUpperCase(),
                            style: TextStyle(
                              fontSize: FontSizes.labelSmall,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: c.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          if (!cat.isSpecial)
            Padding(
              padding: const EdgeInsets.fromLTRB(Insets.sm, 6, Insets.md, 6),
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search ${cat.label.toLowerCase()}...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: Insets.xs,
                    ),
                    suffixIcon:
                        _searchCtrl.text.isNotEmpty
                            ? IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                _onSearchChanged();
                              },
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radii.sm),
                      borderSide: BorderSide(
                        color: flair.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radii.sm),
                      borderSide: BorderSide(
                        color: flair.primary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // ── Content ────────────────────────────────────────────────
          Expanded(
            child:
                cat.isSpecial
                    ? _specialPage(_selected)
                    : Column(
                      children: [
                        if (_selected == 6 || _selected == 7)
                          _buildQualityChips(flair),
                        Expanded(
                          child: _CodexList(
                            entries: _entriesFor(_selected),
                            section: _sectionFor(_selected),
                          ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _specialPage(int index) {
    switch (index) {
      case 0:
        return const _GungeoneersCodexPage();
      default:
        return const SizedBox.shrink();
    }
  }
}

// =============================================================================
// Entry List — SliverGrid with category grouping
// =============================================================================

class _CodexList extends StatelessWidget {
  final List<CodexEntry> entries;
  final CodexSection section;

  const _CodexList({required this.entries, required this.section});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            GoopText(
              'No results found',
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.4),
                fontSize: FontSizes.bodyMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return RepaintBoundary(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Insets.sm,
              Insets.xs,
              Insets.sm,
              Insets.xxl,
            ),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                final entry = entries[index];
                return _CodexCard(
                  entry: entry,
                  section: section,
                  onTap: () {
                    Haptics.selection();
                    // Ammonomicon wiki entries route to their native
                    // detail screens; regular codex entries unchanged.
                    final p = context.read<RunProvider>();
                    final dest = switch (entry.game) {
                      'gun' => p.allGuns
                              .where((g) => g.name == entry.name)
                              .firstOrNull !=
                          null
                          ? ItemDetailScreen(
                              gun: p.allGuns.firstWhere(
                                  (g) => g.name == entry.name))
                          : CodexDetailScreen(
                              entry: entry, section: section),
                      'item' => ItemDetailScreen(
                          item: p.allItems
                              .firstWhere((i) => i.name == entry.name)),
                      'synergy' => SynergyDetailScreen(
                          synergy: p.allSynergies.firstWhere(
                              (s) => s.name == entry.name)),
                      _ => CodexDetailScreen(
                          entry: entry, section: section),
                    };
                    Navigator.push(context, fastRoute(dest));
                  },
                );
              }, childCount: entries.length),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    MediaQuery.of(context).size.width < 360
                        ? 3
                        : MediaQuery.of(context).size.width < 500
                        ? 4
                        : 6,
                mainAxisSpacing: Insets.xs,
                crossAxisSpacing: Insets.xs,
                childAspectRatio: 0.82,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Entry Card — pixel-art icon + name label
// =============================================================================

class _CodexCard extends StatelessWidget {
  final CodexEntry entry;
  final CodexSection section;
  final VoidCallback onTap;

  const _CodexCard({
    required this.entry,
    required this.section,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final assetPath = codexAssetPath(section, entry.icon);
    // For NPC entries, prefer the animated idle GIF if available.
    final idleGif =
        section == CodexSection.npcs ? npcIdleGifPath(entry.name) : '';
    final imgPath = idleGif.isNotEmpty ? idleGif : assetPath;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              flair.card,
              Color.lerp(flair.card, Colors.black, 0.15) ?? flair.card,
            ],
          ),
          borderRadius: const BorderRadius.all(Radii.sm),
          border: Border.all(
            color: flair.primary.withValues(alpha: 0.12),
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Insets.xs),
                child:
                    imgPath.isNotEmpty
                        ? Image.asset(
                          imgPath,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.none,
                          cacheWidth: 160,
                          cacheHeight: 160,
                          errorBuilder:
                              (_, _, _) => Icon(
                                _iconForCategory(entry.category),
                                size: 24,
                                color: flair.primary.withValues(alpha: 0.5),
                              ),
                        )
                        : Icon(
                          _iconForCategory(entry.category),
                          size: 24,
                          color: flair.primary.withValues(alpha: 0.5),
                        ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(3, 0, 3, 4),
              child: GoopText(
                entry.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: FontSizes.labelSmall,
                  fontWeight: FontWeight.w700,
                  color: onSurface.withValues(alpha: 0.85),
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms, delay: 50.ms);
  }

  IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'barrel':
        return Icons.propane_tank_outlined;
      case 'chest':
        return Icons.inventory_2;
      case 'trap':
        return Icons.warning_amber;
      case 'muncher':
        return Icons.pets;
      case 'mirror':
        return Icons.flip;
      case 'health':
        return Icons.favorite;
      case 'currency':
        return Icons.paid;
      case 'defense':
        return Icons.shield;
      case 'ammo':
        return Icons.bolt;
      case 'utility':
        return Icons.key;
      case 'major npc':
      case 'minor npc':
      case 'other npc':
        return Icons.person_outline;
      case 'enemy':
        return Icons.dangerous_outlined;
      case 'boss':
        return Icons.emoji_events_outlined;
      default:
        return Icons.widgets;
    }
  }
}

// =============================================================================
// Gungeoneers codex page — grid of all gungeoneers, tap for detail
// =============================================================================

class _GungeoneersCodexPage extends StatelessWidget {
  const _GungeoneersCodexPage();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final gungeoneers = p.allGungeoneers;
    final flair = AppTheme.flair;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            Insets.sm,
            Insets.xs,
            Insets.sm,
            Insets.xxl,
          ),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate((context, index) {
              final g = gungeoneers[index];
              return GestureDetector(
                onTap: () {
                  Haptics.selection();
                  Navigator.push(
                    context,
                    fastRoute(GungeoneerDetailScreen(gungeoneer: g)),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: flair.card,
                    borderRadius: BorderRadius.all(Radii.sm),
                    border: Border.all(
                      color: flair.primary.withValues(alpha: 0.12),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(Insets.xs),
                          child: _buildGungeoneerArt(g.name),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(3, 0, 3, 4),
                        child: GoopText(
                          g.name,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: FontSizes.labelSmall,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 200.ms, delay: (index * 40).ms);
            }, childCount: gungeoneers.length),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width < 360 ? 3 : 4,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 0.82,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGungeoneerArt(String name) {
    final animPath = gungeoneerAnimatedCardPath(name);
    if (animPath.isNotEmpty) {
      return Image.asset(
        animPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        cacheWidth: 180,
        cacheHeight: 180,
        errorBuilder:
            (_, _, _) => Icon(
              Icons.person,
              size: 32,
              color: AppTheme.flair.primary.withValues(alpha: 0.5),
            ),
      );
    }
    return Icon(
      Icons.person,
      size: 32,
      color: AppTheme.flair.primary.withValues(alpha: 0.5),
    );
  }
}

/// One section of the global-search results view (category + its
/// filtered entries + icon-folder resolver).
class _SearchGroup {
  final AmmonomiconTab tab;
  final List<CodexEntry> entries;
  final CodexSection section;
  const _SearchGroup(
      {required this.tab, required this.entries, required this.section});
}

/// Category-grid index → section mapping. Public (non-private) so the
/// tab-to-section alignment can be unit-tested — an earlier refactor
/// shipped an off-by-one here that made every appended tab show the
/// previous category's content.
CodexSection ammonomiconSectionForIndex(int index) {
  switch (index) {
    case 1:
      return CodexSection.npcs;
    case 2:
      return CodexSection.enemies;
    case 3:
      return CodexSection.bosses;
    case 4:
      return CodexSection.pickups;
    case 6:
      return CodexSection.guns;
    case 7:
      return CodexSection.items;
    case 8:
      return CodexSection.synergies;
    case 9:
      return CodexSection.shrines;
    case 10:
      return CodexSection.chapters;
    case 11:
      return CodexSection.gameModes;
    default:
      return CodexSection.objects;
  }
}
