import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/codex_entry.dart';
import '../services/app_theme.dart';
import '../services/haptics.dart';
import 'bullet_hell_codex_screen.dart';
import 'paradox_codex_screen.dart';
import 'gunslinger_codex_screen.dart';
import 'codex_detail_screen.dart';
import '../utils/fast_route.dart';
import '../services/goop_talk_engine.dart';

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

  // Currently selected category index (0-based). 0-2 are special pages,
  // 3-7 are data categories.
  int _selected = 0;

  // Loaded data
  List<CodexEntry> _objects = [];
  List<CodexEntry> _pickups = [];
  List<CodexEntry> _npcs = [];
  List<CodexEntry> _enemies = [];
  List<CodexEntry> _bosses = [];
  bool _loaded = false;

  // Category definitions — special pages first, then data categories.
  // The order here determines the grid order.
  static const _categories = [
    _CategoryDef(
      label: 'Paradox',
      icon: Icons.auto_awesome,
      color: Color(0xFF00E5FF),
      isSpecial: true,
    ),
    _CategoryDef(
      label: 'Gunslinger',
      icon: Icons.casino,
      color: Color(0xFFFFD54F),
      isSpecial: true,
    ),
    _CategoryDef(
      label: 'Bullet Hell',
      icon: Icons.local_fire_department,
      color: Color(0xFFFF5252),
      isSpecial: true,
    ),
    _CategoryDef(
      label: 'Objects',
      icon: Icons.widgets,
      color: Color(0xFF66BB6A),
      isSpecial: false,
    ),
    _CategoryDef(
      label: 'Pickups',
      icon: Icons.inventory_2_outlined,
      color: Color(0xFF42A5F5),
      isSpecial: false,
    ),
    _CategoryDef(
      label: 'NPCs',
      icon: Icons.person_outline,
      color: Color(0xFFEF5350),
      isSpecial: false,
    ),
    _CategoryDef(
      label: 'Enemies',
      icon: Icons.dangerous_outlined,
      color: Color(0xFFFF7043),
      isSpecial: false,
    ),
    _CategoryDef(
      label: 'Bosses',
      icon: Icons.emoji_events_outlined,
      color: Color(0xFFAB47BC),
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
      _enemies = (jsonDecode(results[3]) as List)
          .map((j) => CodexEntry.fromJson(j as Map<String, dynamic>))
          .toList();
      _bosses = (jsonDecode(results[4]) as List)
          .map((j) => CodexEntry.fromJson(j as Map<String, dynamic>))
          .toList();
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
    return entries
        .where((e) =>
            e.name.toLowerCase().contains(_query) ||
            e.category.toLowerCase().contains(_query) ||
            e.description.toLowerCase().contains(_query))
        .toList();
  }

  /// Returns the data entries for the selected data category.
  List<CodexEntry> _entriesFor(int index) {
    switch (index) {
      case 3:
        return _filter(_objects);
      case 4:
        return _filter(_pickups);
      case 5:
        return _filter(_npcs);
      case 6:
        return _filter(_enemies);
      case 7:
        return _filter(_bosses);
      default:
        return [];
    }
  }

  CodexSection _sectionFor(int index) {
    switch (index) {
      case 3:
        return CodexSection.objects;
      case 4:
        return CodexSection.pickups;
      case 5:
        return CodexSection.npcs;
      case 6:
        return CodexSection.enemies;
      default:
        return CodexSection.bosses;
    }
  }

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final cat = _categories[_selected];

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
            ? const GoopText('CODEX',
                style: TextStyle(
                    fontWeight: FontWeight.w900, letterSpacing: 1.2))
            : const SizedBox.shrink(),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Category grid ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 0.92,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final c = _categories[index];
                      final isSelected = index == _selected;
                      return _CategoryTile(
                        label: c.label,
                        icon: c.icon,
                        color: c.color,
                        isSelected: isSelected,
                        onTap: () {
                          Haptics.selection();
                          setState(() {
                            _selected = index;
                            _searchCtrl.clear();
                            _query = '';
                          });
                        },
                      );
                    },
                  ),
                ),
                // ── Search bar (data categories only) ──────────────────
                if (!cat.isSpecial)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search ${cat.label.toLowerCase()}...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 4),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    _onSearchChanged();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: flair.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: flair.primary.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // ── Content ────────────────────────────────────────────
                Expanded(
                  child: cat.isSpecial
                      ? _specialPage(_selected)
                      : _CodexList(
                          entries: _entriesFor(_selected),
                          section: _sectionFor(_selected),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _specialPage(int index) {
    switch (index) {
      case 0:
        return const ParadoxCodexScreen();
      case 1:
        return const GunslingerCodexScreen();
      case 2:
        return const BulletHellCodexScreen();
      default:
        return const SizedBox.shrink();
    }
  }
}

// =============================================================================
// Category definition
// =============================================================================

class _CategoryDef {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSpecial;

  const _CategoryDef({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSpecial,
  });
}

// =============================================================================
// Category tile — tappable grid card with icon + label
// =============================================================================

class _CategoryTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.18)
              : const Color(0xFF1E1E22),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.8)
                : color.withValues(alpha: 0.15),
            width: isSelected ? 1.4 : 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? color : color.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 4),
            GoopText(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.6),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 150.ms, delay: 30.ms);
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
            GoopText(
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

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 24),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entry = entries[index];
                return _CodexCard(
                  entry: entry,
                  section: section,
                  onTap: () {
                    Haptics.selection();
                    Navigator.push(
                      context,
                      fastRoute(CodexDetailScreen(
                        entry: entry,
                        section: section,
                      )),
                    );
                  },
                );
              },
              childCount: entries.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 0.82,
            ),
          ),
        ),
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
          borderRadius: BorderRadius.circular(8),
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
                padding: const EdgeInsets.all(4),
                child: assetPath.isNotEmpty
                    ? Image.asset(
                        assetPath,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                        errorBuilder: (_, __, ___) => Icon(
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
                  fontSize: 8.5,
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
      case 'enemy':
        return Icons.dangerous_outlined;
      case 'boss':
        return Icons.emoji_events_outlined;
      default:
        return Icons.widgets;
    }
  }
}
