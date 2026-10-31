part of 'ammonomicon_screen.dart';

class _AmmonomiconList extends StatelessWidget {
  final List<AmmonomiconEntry> entries;
  final AmmonomiconSection section;
  final void Function(AmmonomiconEntry entry, AmmonomiconSection section)
  onEntryTap;
  final String query;

  const _AmmonomiconList({
    required this.entries,
    required this.section,
    required this.onEntryTap,
    this.query = '',
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    if (entries.isEmpty) {
      final searching = query.isNotEmpty;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searching ? Icons.search_off : Icons.inventory_2_outlined,
              size: 48,
              color: onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            GoopText(
              searching
                  ? 'No results for "$query"'
                  : 'No entries in this category',
              textAlign: TextAlign.center,
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
                return _AmmonomiconCard(
                  entry: entry,
                  section: section,
                  onTap: () {
                    Haptics.selection();
                    onEntryTap(entry, section);
                  },
                );
              }, childCount: entries.length),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width < 360 ? 3 : 4,
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

class _AmmonomiconCard extends StatelessWidget {
  final AmmonomiconEntry entry;
  final AmmonomiconSection section;
  final VoidCallback onTap;

  const _AmmonomiconCard({
    required this.entry,
    required this.section,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final assetPath = ammonomiconAssetPath(section, entry.icon);
    // For NPC entries, prefer the animated idle GIF if available.
    final idleGif =
        section == AmmonomiconSection.npcs ? npcIdleGifPath(entry.name) : '';
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
              Color.lerp(flair.card, Skeuo.collapse(Colors.black), 0.15) ??
                  flair.card,
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
// Gungeoneers ammonomicon page — grid of all gungeoneers, tap for detail
// =============================================================================

class _GungeoneersAmmonomiconPage extends StatelessWidget {
  const _GungeoneersAmmonomiconPage();

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
                          style: TextStyle(
                            fontSize: FontSizes.labelSmall,
                            fontWeight: FontWeight.w700,
                            color: Skeuo.collapse(Colors.white),
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
// =============================================================================
// Shrine swipe view — top icon tab strip + swipeable PageView. Title on top,
// big sprite, effects/costs on the card. Reference-only: no action buttons.
// =============================================================================
class _ShrineSwipePage extends StatefulWidget {
  final List<AmmonomiconEntry> entries;
  final AmmonomiconSection section;
  final void Function(AmmonomiconEntry entry, AmmonomiconSection section)
  onEntryTap;

  const _ShrineSwipePage({
    required this.entries,
    required this.section,
    required this.onEntryTap,
  });

  @override
  State<_ShrineSwipePage> createState() => _ShrineSwipePageState();
}

class _ShrineSwipePageState extends State<_ShrineSwipePage> {
  static final _accent = Skeuo.collapse(
    Color(0xFFFFB74D),
  ); // AmmonomiconColors.shrines
  final _pageCtrl = PageController();
  final _stripCtrl = ScrollController();
  int _page = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _stripCtrl.dispose();
    super.dispose();
  }

  void _onPage(int i) {
    setState(() => _page = i);
    // Keep the selected tab visible in the strip (items are ~64px).
    if (_stripCtrl.hasClients) {
      final target = (i * 64.0).clamp(0.0, _stripCtrl.position.maxScrollExtent);
      _stripCtrl.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  void _jump(int i) {
    Haptics.selection();
    _pageCtrl.animateToPage(
      i,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Icon tab strip ──
        SizedBox(
          height: 56,
          child: ListView.builder(
            controller: _stripCtrl,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: widget.entries.length,
            itemExtent: 64,
            itemBuilder: (_, i) {
              final sel = i == _page;
              final e = widget.entries[i];
              return GestureDetector(
                onTap: () => _jump(i),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: sel ? 0.2 : 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _accent.withValues(alpha: sel ? 0.85 : 0.25),
                        width: sel ? 1.6 : 1.0,
                      ),
                      boxShadow:
                          sel
                              ? [
                                BoxShadow(
                                  color: _accent.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                ),
                              ]
                              : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Image.asset(
                        ammonomiconAssetPath(widget.section, e.icon),
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                        errorBuilder:
                            (_, _, _) => Icon(
                              Icons.church,
                              size: 20,
                              color: _accent.withValues(alpha: sel ? 1 : 0.5),
                            ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // ── Swipeable shrine pages ──
        Expanded(
          child: PageView.builder(
            key: const PageStorageKey('ammonomicon_shrines'),
            controller: _pageCtrl,
            onPageChanged: _onPage,
            itemCount: widget.entries.length,
            itemBuilder: (_, i) => _shrinePage(widget.entries[i]),
          ),
        ),
      ],
    );
  }

  Widget _shrinePage(AmmonomiconEntry e) {
    final flair = AppTheme.flair;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        children: [
          // Title on top
          GoopText(
            e.name.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
              color: _accent,
            ),
          ),
          const SizedBox(height: 14),
          // Big sprite
          GestureDetector(
            onTap: () {
              Haptics.selection();
              widget.onEntryTap(e, widget.section);
            },
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _accent.withValues(alpha: 0.14),
                    _accent.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _accent.withValues(alpha: 0.45),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.12),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Image.asset(
                  ammonomiconAssetPath(widget.section, e.icon),
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                  errorBuilder:
                      (_, _, _) => Icon(
                        Icons.church,
                        size: 64,
                        color: _accent.withValues(alpha: 0.6),
                      ),
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          // Effects / costs card — tips carry effect + curse/coolness lines
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: flair.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _accent.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final tip in e.tips)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          tip.startsWith('Costs')
                              ? Icons.warning_amber_rounded
                              : Icons.bolt_rounded,
                          size: 14,
                          color:
                              tip.startsWith('Costs')
                                  ? Skeuo.collapse(Color(0xFFB388FF))
                                  : _accent,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: GoopText(
                            tip,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: Skeuo.collapse(
                                Colors.white,
                              ).withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (e.description.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: e.tips.isEmpty ? 0 : 6),
                    child: GoopText(
                      e.description,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                        color: Skeuo.collapse(
                          Colors.white,
                        ).withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      size: 12,
                      color: Skeuo.collapse(
                        Colors.white,
                      ).withValues(alpha: 0.35),
                    ),
                    SizedBox(width: 5),
                    GoopText(
                      'Tap sprite for full entry',
                      style: TextStyle(
                        fontSize: 10,
                        color: Skeuo.collapse(
                          Colors.white,
                        ).withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Category-grid index → section mapping. Public (non-private) so the
/// tab-to-section alignment can be unit-tested — an earlier refactor
/// shipped an off-by-one here that made every appended tab show the
/// previous category's content.
AmmonomiconSection ammonomiconSectionForIndex(int index) {
  switch (index) {
    case 1:
      return AmmonomiconSection.npcs;
    case 2:
      return AmmonomiconSection.enemies;
    case 3:
      return AmmonomiconSection.bosses;
    case 4:
      return AmmonomiconSection.pickups;
    case 6:
      return AmmonomiconSection.guns;
    case 7:
      return AmmonomiconSection.items;
    case 8:
      return AmmonomiconSection.synergies;
    case 9:
      return AmmonomiconSection.shrines;
    case 10:
      return AmmonomiconSection.chapters;
    case 11:
      return AmmonomiconSection.gameModes;
    default:
      return AmmonomiconSection.objects;
  }
}
