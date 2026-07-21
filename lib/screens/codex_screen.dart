import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/codex_entry.dart';
import '../services/app_theme.dart';
import '../services/haptics.dart';
import 'codex_detail_screen.dart';

/// The GungeonMate Codex — a browseable encyclopedia of Objects, Pickups,
/// and NPCs from Enter the Gungeon. Accessed from the main menu or as a
/// bottom-nav tab during an active run.
class CodexScreen extends StatefulWidget {
  final bool showBackButton;

  const CodexScreen({super.key, this.showBackButton = false});

  @override
  State<CodexScreen> createState() => _CodexScreenState();
}

class _CodexScreenState extends State<CodexScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  // Loaded data
  List<CodexEntry> _objects = [];
  List<CodexEntry> _pickups = [];
  List<CodexEntry> _npcs = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
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
    ]);
    if (!mounted) return;
    setState(() {
      _objects = (jsonDecode(results[0]) as List)
          .map((j) => CodexEntry.fromJson(j as Map<String, dynamic>))
          .toList();
      _pickups = (jsonDecode(results[1]) as List)
          .map((j) => CodexEntry.fromJson(j as Map<String, dynamic>))
          .toList();
      _npcs = (jsonDecode(results[2]) as List)
          .map((j) => CodexEntry.fromJson(j as Map<String, dynamic>))
          .toList();
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CodexEntry> _filter(List<CodexEntry> entries, CodexSection section) {
    if (_query.isEmpty) return entries;
    return entries
        .where((e) =>
            e.name.toLowerCase().contains(_query) ||
            e.category.toLowerCase().contains(_query) ||
            e.description.toLowerCase().contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        toolbarHeight: widget.showBackButton ? kToolbarHeight : 0,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: widget.showBackButton
            ? const Text('CODEX',
                style: TextStyle(
                    fontWeight: FontWeight.w900, letterSpacing: 1.2))
            : const SizedBox.shrink(),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
            child: TabBar(
              controller: _tab,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              indicator: BoxDecoration(
                color: flair.primary.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: flair.primary.withValues(alpha: 0.7),
                  width: 1.2,
                ),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerHeight: 0,
              tabs: [
                Tab(
                  height: 48,
                  iconMargin: const EdgeInsets.only(bottom: 2),
                  icon: const Icon(Icons.widgets, size: 18),
                  text: 'Objects',
                ),
                Tab(
                  height: 48,
                  iconMargin: const EdgeInsets.only(bottom: 2),
                  icon: const Icon(Icons.inventory_2_outlined, size: 18),
                  text: 'Pickups',
                ),
                Tab(
                  height: 48,
                  iconMargin: const EdgeInsets.only(bottom: 2),
                  icon: const Icon(Icons.person_outline, size: 18),
                  text: 'NPCs',
                ),
              ],
            ),
          ),
        ),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search codex...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 6),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _onSearchChanged();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: flair.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: flair.primary.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      _CodexList(
                        entries: _filter(_objects, CodexSection.objects),
                        section: CodexSection.objects,
                      ),
                      _CodexList(
                        entries: _filter(_pickups, CodexSection.pickups),
                        section: CodexSection.pickups,
                      ),
                      _CodexList(
                        entries: _filter(_npcs, CodexSection.npcs),
                        section: CodexSection.npcs,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
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
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                size: 48, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'No results found',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Group entries by category
    final grouped = <String, List<CodexEntry>>{};
    for (final e in entries) {
      final cat = e.category.isEmpty ? 'Other' : e.category;
      grouped.putIfAbsent(cat, () => []).add(e);
    }
    final categories = grouped.keys.toList()..sort();

    return CustomScrollView(
      slivers: [
        for (final cat in categories) ...[
          // Category header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(
                cat.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: AppTheme.flair.secondary.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
          // Grid of entries
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = grouped[cat]![index];
                  return _CodexCard(
                    entry: entry,
                    section: section,
                    onTap: () {
                      Haptics.selection();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CodexDetailScreen(
                            entry: entry,
                            section: section,
                          ),
                        ),
                      );
                    },
                  );
                },
                childCount: grouped[cat]!.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.82,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 4)),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
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
    final assetPath = codexAssetPath(section, entry.icon);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E22),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: flair.primary.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: assetPath.isNotEmpty
                    ? Image.asset(
                        assetPath,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                        errorBuilder: (_, __, ___) => Icon(
                          _iconForCategory(entry.category),
                          size: 32,
                          color: flair.primary.withValues(alpha: 0.5),
                        ),
                      )
                    : Icon(
                        _iconForCategory(entry.category),
                        size: 32,
                        color: flair.primary.withValues(alpha: 0.5),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
              child: Text(
                entry.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.85),
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
      default:
        return Icons.widgets;
    }
  }
}
