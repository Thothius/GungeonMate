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
import 'bullet_hell_codex_screen.dart';
import 'challenge_mode_codex_screen.dart';
import 'drake_codex_screen.dart';
import 'rat_codex_screen.dart';
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

  // Currently selected category index (0-based). 0-5 are special pages,
  // 6-10 are data categories.
  int _selected = -1; // -1 = category picker grid (level 1)

  // Whether the bookmark tab strip is collapsed (hidden) to give the
  // content area the full screen width.

  // Loaded data
  List<CodexEntry> _objects = [];
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
    AmmonomiconTab(
      label: 'Rat',
      icon: Icons.pest_control,
      color: CodexColors.rat,
      isSpecial: true,
    ),
    AmmonomiconTab(
      label: 'Dragun',
      icon: Icons.pets,
      color: CodexColors.dragun,
      isSpecial: true,
    ),
    AmmonomiconTab(
      label: 'Bullet Hell',
      icon: Icons.local_fire_department,
      color: CodexColors.bulletHell,
      isSpecial: true,
    ),
    AmmonomiconTab(
      label: 'Challenge',
      icon: Icons.shuffle,
      color: CodexColors.challenge,
      isSpecial: true,
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
    ]);
    if (!mounted) return;
    // Parse each JSON file in an isolate to avoid jank on the codex screen.
    final parsed = await Future.wait([
      compute(_parseCodexEntries, results[0]),
      compute(_parseCodexEntries, results[1]),
      compute(_parseCodexEntries, results[2]),
      compute(_parseCodexEntries, results[3]),
      compute(_parseCodexEntries, results[4]),
    ]);
    if (!mounted) return;
    setState(() {
      _objects = parsed[0];
      _pickups = parsed[1];
      _npcs = parsed[2];
      _enemies = parsed[3];
      _bosses = parsed[4];
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
      case 9:
        return _filter(context
            .read<RunProvider>()
            .allGuns
            .where((g) =>
                _qualityFilter.isEmpty || _qualityFilter.contains(g.quality))
            .map((g) => CodexEntry(
                name: g.name,
                category: 'Guns',
                icon: g.icon,
                game: 'gun',
                description: g.notes))
            .toList());
      case 10:
        return _filter(context
            .read<RunProvider>()
            .allItems
            .where((i) =>
                _qualityFilter.isEmpty || _qualityFilter.contains(i.quality))
            .map((i) => CodexEntry(
                name: i.name,
                category: 'Items',
                icon: i.icon,
                game: 'item',
                description: i.ammonomiconEntry))
            .toList());
      case 11:
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
      default:
        return [];
    }
  }

  Widget _buildQualityChips(ThemeFlair flair) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Row(
        children: [
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

  CodexSection _sectionFor(int index) {
    switch (index) {
      case 1:
        return CodexSection.npcs;
      case 2:
        return CodexSection.enemies;
      case 3:
        return CodexSection.bosses;
      case 4:
        return CodexSection.pickups;
      case 9:
        return CodexSection.guns;
      case 10:
        return CodexSection.items;
      case 11:
        return CodexSection.synergies;
      default:
        return CodexSection.objects;
    }
  }

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
                  _selected = i;
                  _searchCtrl.clear();
                  _query = '';
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
                        if (_selected == 9 || _selected == 10)
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
      case 6:
        return const RatCodexScreen();
      case 7:
        return const DrakeCodexScreen();
      case 8:
        return const BulletHellCodexScreen();
      case 9:
        return const ChallengeModeCodexScreen();
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
