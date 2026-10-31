import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/ammonomicon_entry.dart';
import '../providers/run_provider.dart';
import '../services/app_theme.dart';
import '../services/haptics.dart';
import '../theme/tokens.dart';
import '../widgets/active_run/bottom_back_bar.dart';
import '../widgets/ammonomicon/ammonomicon_tabs.dart';
import '../widgets/state_widgets.dart';
import 'ammonomicon_detail_screen.dart';
import 'gungeoneer_detail_screen.dart';
import 'item_detail_screen.dart';
import 'synergy_detail_screen.dart';
import '../utils/asset_paths.dart';
import '../utils/fast_route.dart';
import '../services/goop_talk_engine.dart';

part 'ammonomicon_widgets.dart';

// ── Isolate parse helper ───────────────────────────────────────
// Top-level function for compute() — parses a JSON string into a list
// of AmmonomiconEntry objects off the main isolate.
List<AmmonomiconEntry> _parseAmmonomiconEntries(String jsonStr) =>
    (jsonDecode(jsonStr) as List)
        .map((j) => AmmonomiconEntry.fromJson(j as Map<String, dynamic>))
        .toList();

/// The GungeonMate Ammonomicon — a browseable encyclopedia of Objects, Pickups,
/// NPCs, Enemies, and Bosses from Enter the Gungeon, plus themed special
/// pages for Bullet Hell, The Paradox, and The Gunslinger.
///
/// Categories are presented as a grid of tappable tiles at the top for
/// quick, visual access. Special pages come first, then data categories.
class AmmonomiconScreen extends StatefulWidget {
  final bool showBackButton;

  const AmmonomiconScreen({super.key, this.showBackButton = false});

  @override
  State<AmmonomiconScreen> createState() => _AmmonomiconScreenState();
}

class _AmmonomiconScreenState extends State<AmmonomiconScreen> {
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

  /// Synergies tab: show only synergies completable by owned items.
  bool _matchedOnly = false;

  // Currently selected category index (0-based). 0-5 are special pages,
  // 6-10 are data categories.
  int _selected = -1; // -1 = category picker grid (level 1)

  // Whether the bookmark tab strip is collapsed (hidden) to give the
  // content area the full screen width.

  // Loaded data
  List<AmmonomiconEntry> _objects = [];
  List<AmmonomiconEntry> _shrines = [];
  List<AmmonomiconEntry> _chapters = [];
  List<AmmonomiconEntry> _gameModes = [];
  List<AmmonomiconEntry> _pickups = [];
  List<AmmonomiconEntry> _npcs = [];
  List<AmmonomiconEntry> _enemies = [];
  List<AmmonomiconEntry> _bosses = [];
  bool _loaded = false;

  // Category definitions — Ammonomicon bookmark tabs.
  // The 5 ammonomicon tab icons map to: Guns→Objects, Items→Pickups,
  // Enemies, Bosses, Death→NPCs. The 7 special pages use themed Material
  // icons in the same bookmark visual style.
  static const _categories = [
    AmmonomiconTab(
      label: 'Gungeoneers',
      icon: Icons.person,
      color: AmmonomiconColors.gungeoneers,
      isSpecial: true,
    ),
    AmmonomiconTab(
      label: 'NPCs',
      assetIcon: 'Ammonomicon_Tab_Death',
      icon: Icons.person_outline,
      color: AmmonomiconColors.npcs,
      isSpecial: false,
    ),
    AmmonomiconTab(
      label: 'Enemies',
      assetIcon: 'Ammonomicon_Tab_Enemies',
      icon: Icons.dangerous_outlined,
      color: AmmonomiconColors.enemies,
      isSpecial: false,
    ),
    AmmonomiconTab(
      label: 'Bosses',
      assetIcon: 'Ammonomicon_Tab_Bosses',
      icon: Icons.emoji_events_outlined,
      color: AmmonomiconColors.bosses,
      isSpecial: false,
    ),
    AmmonomiconTab(
      label: 'Pickups',
      assetIcon: 'Ammonomicon_Tab_Items',
      icon: Icons.inventory_2_outlined,
      color: AmmonomiconColors.pickups,
      isSpecial: false,
    ),
    AmmonomiconTab(
      label: 'Objects',
      assetIcon: 'Ammonomicon_Tab_Guns',
      icon: Icons.widgets,
      color: AmmonomiconColors.objects,
      isSpecial: false,
    ),
    // ── Ammonomicon wiki cats (fabricated from provider data) ──
    AmmonomiconTab(
      label: 'Guns',
      assetIcon: 'Ammonomicon_Tab_Guns',
      icon: Icons.gps_fixed,
      color: AmmonomiconColors.objects,
      isSpecial: false,
    ),
    AmmonomiconTab(
      label: 'Items',
      assetIcon: 'Ammonomicon_Tab_Items',
      icon: Icons.inventory_2,
      color: AmmonomiconColors.pickups,
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
    // Per-file fallback: one missing/corrupt asset degrades to an empty
    // category instead of leaving the whole screen on skeletons forever.
    Future<String> loadOr(String path) =>
        bundle.loadString(path).then((s) => s, onError: (_) => '[]');
    try {
      final results = await Future.wait([
        loadOr('assets/data/objects.json'),
        loadOr('assets/data/pickups.json'),
        loadOr('assets/data/npcs.json'),
        loadOr('assets/data/enemies.json'),
        loadOr('assets/data/bosses.json'),
        loadOr('assets/data/shrines.json'),
        loadOr('assets/data/chapters.json'),
        loadOr('assets/data/game_modes.json'),
      ]);
      if (!mounted) return;
      // Parse each JSON file in an isolate to avoid jank on the ammonomicon screen.
      final parsed = await Future.wait([
        compute(_parseAmmonomiconEntries, results[0]),
        compute(_parseAmmonomiconEntries, results[1]),
        compute(_parseAmmonomiconEntries, results[2]),
        compute(_parseAmmonomiconEntries, results[3]),
        compute(_parseAmmonomiconEntries, results[4]),
        compute(_parseAmmonomiconEntries, results[6]),
        compute(_parseAmmonomiconEntries, results[7]),
      ]);
      if (!mounted) return;
      // Shrines: custom parse — JSON icon fields are wiki URLs; the local
      // assets live in assets/images/shrines/<slug>.webp.
      final shrineList =
          (json.decode(results[5]) as List<dynamic>).map((e) {
            final j = e as Map<String, dynamic>;
            final slug = (j['name'] as String)
                .toLowerCase()
                .replaceAll(' ', '_')
                .replaceAll('.', '');
            // 'fallen angel' ships as Angel_Shrine.webp — all other
            // shrine icons are lowercase-name webps.
            final iconFile =
                slug == 'fallen_angel' ? 'Angel_Shrine.webp' : '$slug.webp';
            final eff = (j['effect'] as String? ?? '').trim();
            return AmmonomiconEntry(
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
                  'https://enterthegungeon.wiki.gg/wiki/${(j['name'] as String).replaceAll(' ', '_')}_Shrine',
            );
          }).toList();
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
    } catch (e) {
      // Still surface the grid — categories that failed stay empty.
      debugPrint('Ammonomicon data load failed: $e');
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AmmonomiconEntry> _filter(List<AmmonomiconEntry> entries) {
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
  List<AmmonomiconEntry> _entriesFor(int index) {
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
          guns.sort(
            (a, b) => (_qualityRank[a.quality] ?? 9).compareTo(
              _qualityRank[b.quality] ?? 9,
            ),
          );
        }
        return _filter(
          guns
              .where(
                (g) =>
                    _qualityFilter.isEmpty ||
                    _qualityFilter.contains(g.quality),
              )
              .map(
                (g) => AmmonomiconEntry(
                  name: g.name,
                  category: 'Guns',
                  icon: g.icon,
                  game: 'gun',
                  description: g.notes,
                ),
              )
              .toList(),
        );
      case 7:
        var items = context.read<RunProvider>().allItems.toList();
        if (_sortMode == 'quality') {
          items.sort(
            (a, b) => (_qualityRank[a.quality] ?? 9).compareTo(
              _qualityRank[b.quality] ?? 9,
            ),
          );
        }
        return _filter(
          items
              .where(
                (i) =>
                    _qualityFilter.isEmpty ||
                    _qualityFilter.contains(i.quality),
              )
              .map(
                (i) => AmmonomiconEntry(
                  name: i.name,
                  category: 'Items',
                  icon: i.icon,
                  game: 'item',
                  description: i.ammonomiconEntry,
                ),
              )
              .toList(),
        );
      case 8:
        var syns = context.read<RunProvider>().allSynergies;
        if (_matchedOnly) {
          final p = context.read<RunProvider>();
          final owned = {
            ...p.runState.main.allItemNames.map((n) => n.toLowerCase()),
            if (p.runState.coop != null)
              ...p.runState.coop!.allItemNames.map((n) => n.toLowerCase()),
          };
          syns = syns.where((s) => s.matchesOwnedSet(owned)).toList();
        }
        return _filter(
          syns.map((s) {
            // Derive icon + folder from the first required item —
            // most synergies have no own sprite; showing the anchor
            // item's icon is the closest visual.
            final p = context.read<RunProvider>();
            final anchor = s.items.isNotEmpty ? s.items.first : '';
            final gun =
                p.allGuns
                    .where((g) => g.name.toLowerCase() == anchor.toLowerCase())
                    .firstOrNull;
            final item =
                p.allItems
                    .where((i) => i.name.toLowerCase() == anchor.toLowerCase())
                    .firstOrNull;
            String anchorIcon(String? p, String folder) =>
                p == null || p.isEmpty
                    ? ''
                    : p.startsWith('assets/')
                    ? p
                    : '$folder/$p';
            return AmmonomiconEntry(
              name: s.name,
              category: 'Synergies',
              icon:
                  gun != null
                      ? anchorIcon(gun.icon, 'guns')
                      : item != null
                      ? anchorIcon(item.icon, 'items')
                      : '',
              game: 'synergy',
              description: s.effect,
              ammonomicon: [...s.items, ...s.anyOf].join(' · '),
            );
          }).toList(),
        );
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

  /// Tiny accent chip for member-row metadata (F1 / SECRET / HUB /
  /// N MODS) in the expanded Chapters/Game Modes picker.
  Widget _metaChip(String label, Color accent) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: GoopText(
        label,
        style: TextStyle(
          fontSize: FontSizes.labelSmall,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: accent,
        ),
      ),
    );
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
                    color: c.color,
                  ),
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
                final subtitle =
                    (e.tips.isNotEmpty)
                        ? e.tips.first
                        : (e.description.isNotEmpty ? e.description : '');
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
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              c.color.withValues(alpha: 0.16),
                              c.color.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: c.color.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: c.color.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: c.color.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Center(child: _searchIcon(e, section)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GoopText(
                                    e.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (subtitle.isNotEmpty)
                                    GoopText(
                                      subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (_expanded == 10)
                              _metaChip(
                                e.floor != null
                                    ? 'F${e.floor}'
                                    : (e.secret ? 'SECRET' : 'HUB'),
                                e.secret ? const Color(0xFFB388FF) : c.color,
                              ),
                            if (_expanded == 11 && e.gameClasses.isNotEmpty)
                              _metaChip(
                                '${e.gameClasses.length} MODS',
                                c.color,
                              ),
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: c.color.withValues(alpha: 0.6),
                            ),
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
  Widget _searchIcon(AmmonomiconEntry entry, AmmonomiconSection section) {
    final path = ammonomiconAssetPath(section, entry.icon);
    if (path.isEmpty) {
      return const Icon(Icons.help_outline, size: 20);
    }
    return Image.asset(
      path,
      width: 26,
      height: 26,
      cacheWidth: 52,
      cacheHeight: 52,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Icon(Icons.help_outline, size: 20),
    );
  }

  /// Shared tap routing — guns/items go to their detail screens,
  /// synergies to the synergy graph, everything else to ammonomicon detail.
  void _openEntry(AmmonomiconEntry entry, AmmonomiconSection section) {
    final p = context.read<RunProvider>();
    final gun =
        entry.game == 'gun'
            ? p.allGuns.where((g) => g.name == entry.name).firstOrNull
            : null;
    final item =
        entry.game == 'item'
            ? p.allItems.where((i) => i.name == entry.name).firstOrNull
            : null;
    final syn =
        entry.game == 'synergy'
            ? p.allSynergies.where((s) => s.name == entry.name).firstOrNull
            : null;
    final dest =
        gun != null
            ? ItemDetailScreen(gun: gun)
            : item != null
            ? ItemDetailScreen(item: item)
            : syn != null
            ? SynergyDetailScreen(synergy: syn)
            : AmmonomiconDetailScreen(entry: entry, section: section);
    Navigator.push(context, fastRoute(dest));
  }

  Widget _buildQualityChips(ThemeFlair flair) {
    if (_selected == 8) {
      final on = _matchedOnly;
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
        child: GestureDetector(
          onTap: () {
            Haptics.selection();
            setState(() => _matchedOnly = !on);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:
                  on
                      ? const Color(0xFFB388FF).withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color:
                    on
                        ? const Color(0xFFB388FF)
                        : Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: GoopText(
              'MATCHED',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color:
                    on
                        ? const Color(0xFFB388FF)
                        : Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      );
    }
    if (_selected != 6 && _selected != 7) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Haptics.selection();
              setState(
                () => _sortMode = _sortMode == 'name' ? 'quality' : 'name',
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: GoopText(
                _sortMode == 'name' ? 'A-Z' : 'S-D',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
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
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _qualityFilter.contains(q)
                            ? flair.primary.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                          _qualityFilter.contains(q)
                              ? flair.primary.withValues(alpha: 0.8)
                              : Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: GoopText(
                    q,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color:
                          _qualityFilter.contains(q)
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

  AmmonomiconSection _sectionFor(int index) =>
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
          groups.add(
            _SearchGroup(tab: c, entries: ent, section: _sectionFor(i)),
          );
        }
      }
      return SafeArea(
        top: !widget.showBackButton,
        bottom: false,
        child:
            groups.isEmpty
                ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 40,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      const SizedBox(height: 10),
                      GoopText(
                        'Nothing found for "${_searchCtrl.text}"',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontStyle: FontStyle.italic,
                        ),
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
                          '${g.tab.label.toUpperCase()} · ${g.entries.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: g.tab.color,
                          ),
                        ),
                      ),
                      for (final e in g.entries)
                        ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          leading: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: g.tab.color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: g.tab.color.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Center(child: _searchIcon(e, g.section)),
                          ),
                          title: GoopText(
                            e.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      c.color.withValues(alpha: 0.22),
                      c.color.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.all(Radii.md),
                  border: Border.all(
                    color: c.color.withValues(alpha: 0.55),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: c.color.withValues(alpha: 0.12),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: c.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: c.color.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: c.color.withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child:
                            c.assetIcon != null
                                ? Image.asset(
                                  AmmonomiconTabStrip.tabAssetPath(
                                    c.assetIcon!,
                                  ),
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.none,
                                  errorBuilder:
                                      (_, _, _) => Icon(
                                        c.icon ?? Icons.bookmark,
                                        size: 24,
                                        color: c.color,
                                      ),
                                )
                                : Icon(
                                  c.icon ?? Icons.bookmark,
                                  size: 24,
                                  color: c.color,
                                ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    GoopText(
                      c.label.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: FontSizes.labelSmall,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: c.color,
                        height: 1.15,
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
                        if (_selected == 6 || _selected == 7 || _selected == 8)
                          _buildQualityChips(flair),
                        Expanded(
                          child: _AmmonomiconList(
                            entries: _entriesFor(_selected),
                            section: _sectionFor(_selected),
                            onEntryTap: _openEntry,
                            query: _searchCtrl.text,
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
        return const _GungeoneersAmmonomiconPage();
      default:
        return const SizedBox.shrink();
    }
  }
}

// =============================================================================
// Entry List — SliverGrid with category grouping
// =============================================================================
