import '../theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/gungeoneer.dart';
import '../providers/run_provider.dart';
import '../services/app_theme.dart';
import '../services/goop_talk_engine.dart';
import '../services/haptics.dart';
import '../utils/asset_paths.dart';
import '../utils/fast_route.dart';
import '../widgets/spoiler_tag.dart';
import '../widgets/game_icon.dart';
import '../widgets/scale_button.dart';
import 'item_detail_screen.dart';
import 'home_screen.dart';

/// Rich, tabbed detail view for a single Gungeoneer.
///
/// Uses a filter/tab bar so the user sees one clean page at a time:
/// Lore → Loadout → Playstyle → Tips → Spoilers (last, labeled).
/// No overwhelming wall of data — 2026 standard UX.
class GungeoneerDetailScreen extends StatefulWidget {
  final Gungeoneer gungeoneer;

  /// Optional override for the "PLAY AS" button. When null (default),
  /// the button starts a new solo run and navigates to HomeScreen.
  /// When provided (e.g. from the MP lobby character picker), the
  /// button calls this callback instead — typically to pop the detail
  /// screen and return the gungeoneer to the caller.
  final VoidCallback? onPlayAs;

  const GungeoneerDetailScreen({
    super.key,
    required this.gungeoneer,
    this.onPlayAs,
  });

  @override
  State<GungeoneerDetailScreen> createState() => _GungeoneerDetailScreenState();
}

class _GungeoneerDetailScreenState extends State<GungeoneerDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<_DetailTab> get _tabs {
    final g = widget.gungeoneer;
    final hasSpoilers =
        g.pastSummary.isNotEmpty ||
        g.pastDetails.isNotEmpty ||
        (g.pastUnlocks.isNotEmpty && !g.pastUnlocks.contains('N/A')) ||
        (g.unlockMethod.isNotEmpty &&
            !g.unlockMethod.contains('Available from the start')) ||
        (g.altCostumeUnlock.isNotEmpty && !g.altCostumeUnlock.contains('N/A'));
    return [
      _DetailTab.loadout,
      if (g.tips.isNotEmpty) _DetailTab.tips,
      if (g.playstyle.isNotEmpty) _DetailTab.playstyle,
      if (g.loreIntro.isNotEmpty) _DetailTab.lore,
      if (hasSpoilers) _DetailTab.spoilers,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final g = widget.gungeoneer;
    final p = context.watch<RunProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: GoopText(
          g.name,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          if (g.wikiUrl.isNotEmpty)
            IconButton(
              tooltip: 'View on Wiki',
              icon: const Icon(Icons.open_in_new, size: 20),
              onPressed: () => _launchWiki(context, g.wikiUrl),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── Hero section (always visible) ──
            _HeroSection(gungeoneer: g, flair: flair),

            // ── Tab bar — 2 rows for clean layout ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: Insets.lg),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: flair.card,
                borderRadius: BorderRadius.all(Radii.md),
                border: Border.all(
                  color: flair.primary.withValues(alpha: 0.15),
                  width: 0.8,
                ),
              ),
              child: _buildTabRow(flair),
            ),
            const SizedBox(height: 8),

            // ── Tab content ──
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children:
                    _tabs.map((tab) {
                      switch (tab) {
                        case _DetailTab.lore:
                          return _LorePage(g: g);
                        case _DetailTab.loadout:
                          return _LoadoutPage(g: g, provider: p);
                        case _DetailTab.playstyle:
                          return _PlaystylePage(g: g);
                        case _DetailTab.tips:
                          return _TipsPage(g: g);
                        case _DetailTab.spoilers:
                          return _SpoilersPage(g: g);
                      }
                    }).toList(),
              ),
            ),

            // ── PLAY AS button (after all tabs) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(Insets.lg, 8, Insets.lg, 16),
              child: SizedBox(
                width: double.infinity,
                child: ScaleButton(
                  onTap: () {
                    Haptics.selection();
                    if (widget.onPlayAs != null) {
                      widget.onPlayAs!();
                      return;
                    }
                    final rp = context.read<RunProvider>();
                    rp.startNewRun(widget.gungeoneer);
                    Navigator.pushAndRemoveUntil(
                      context,
                      fastRoute(const HomeScreen()),
                      (_) => false,
                    );
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFFFE082).withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFFD54F,
                          ).withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.play_arrow_rounded,
                          size: 24,
                          color: Color(0xFF3E2723),
                        ),
                        const SizedBox(width: 10),
                        GoopText(
                          'PLAY AS ${g.name.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Color(0xFF3E2723),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchWiki(BuildContext context, String url) {
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication).catchError((
      e,
    ) {
      debugPrint('[GungeoneerDetail] url launch error: $e');
      if (context.mounted) {
        Clipboard.setData(ClipboardData(text: url));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: GoopText('Could not open. URL copied to clipboard.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return false;
    });
  }

  /// Build a single-row tab layout. All tabs in one horizontal row,
  /// each taking equal width via Expanded. Handles 2–5 tabs.
  Widget _buildTabRow(ThemeFlair flair) {
    final tabs = _tabs;

    Widget buildTab(_DetailTab tab, int index) {
      final isSelected = _tabCtrl.index == index;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            Haptics.selection();
            _tabCtrl.animateTo(index);
            setState(() {});
          },
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: Insets.sm),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? flair.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
              borderRadius: const BorderRadius.all(Radii.sm),
              border: Border.all(
                color:
                    isSelected
                        ? flair.primary.withValues(alpha: 0.5)
                        : Colors.transparent,
                width: 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tab.icon,
                  size: 16,
                  color:
                      isSelected
                          ? flair.primary
                          : Colors.white.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: GoopText(
                    tab.label,
                    style: TextStyle(
                      fontSize: FontSizes.labelSmall,
                      fontWeight:
                          isSelected ? FontWeight.w900 : FontWeight.w700,
                      letterSpacing: 0.5,
                      color:
                          isSelected
                              ? flair.primary
                              : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [for (var i = 0; i < tabs.length; i++) buildTab(tabs[i], i)],
    );
  }
}

// =============================================================================
// Tab definitions
// =============================================================================

enum _DetailTab {
  loadout('LOADOUT', Icons.inventory_2),
  tips('TIPS', Icons.lightbulb_outline),
  playstyle('PLAYSTYLE', Icons.sports_esports),
  lore('LORE', Icons.auto_stories),
  spoilers('SPOILERS', Icons.warning_amber_rounded);

  final String label;
  final IconData icon;
  const _DetailTab(this.label, this.icon);
}

// =============================================================================
// Hero section — character art + short desc + badges (always visible)
// =============================================================================

class _HeroSection extends StatelessWidget {
  final Gungeoneer gungeoneer;
  final ThemeFlair flair;

  const _HeroSection({required this.gungeoneer, required this.flair});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          // In-game sprite only — clean and simple, no extra labels.
          SizedBox(height: 120, child: Center(child: _buildSprite())),
        ],
      ),
    );
  }

  /// Always show the in-game sprite GIF — no card art.
  Widget _buildSprite() {
    final gifPath = gungeoneerGifPath(gungeoneer.name);
    if (gifPath.isNotEmpty) {
      return Image.asset(
        gifPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        gaplessPlayback: true,
        cacheWidth: 240,
        cacheHeight: 240,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    if (gungeoneer.icon.startsWith('assets/')) {
      return Image.asset(
        gungeoneer.icon,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        cacheWidth: 240,
        cacheHeight: 240,
        errorBuilder:
            (_, __, ___) =>
                const Icon(Icons.person, size: 80, color: Colors.white54),
      );
    }
    return const Icon(Icons.person, size: 80, color: Colors.white54);
  }
}

// =============================================================================
// Lore page
// =============================================================================

class _LorePage extends StatelessWidget {
  final Gungeoneer g;
  const _LorePage({required this.g});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (g.loreIntro.isNotEmpty)
            _ContentCard(
              color: Colors.purpleAccent,
              child: GoopText(
                g.loreIntro,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
          // Nicknames trivia
          if (g.nicknames.isNotEmpty || g.voice.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ContentCard(
              color: Colors.purpleAccent.withValues(alpha: 0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (g.nicknames.isNotEmpty)
                    GoopText(
                      'Also called: ${g.nicknames.join(', ')}',
                      style: TextStyle(
                        fontSize: FontSizes.labelMedium,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  if (g.voice.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    GoopText(
                      'Voice: ${g.voice}',
                      style: TextStyle(
                        fontSize: FontSizes.labelMedium,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// Loadout page
// =============================================================================

class _LoadoutPage extends StatelessWidget {
  final Gungeoneer g;
  final RunProvider provider;
  const _LoadoutPage({required this.g, required this.provider});

  @override
  Widget build(BuildContext context) {
    // Combine guns + items + armor into a single row of compact chips.
    final chips = <Widget>[];
    for (final name in g.startingGuns) {
      chips.add(
        _LoadoutTile(
          name: name,
          isRandom: name == 'Random',
          provider: provider,
        ),
      );
    }
    for (final name in g.startingItems) {
      chips.add(
        _LoadoutTile(
          name: name,
          isRandom: name == 'Random',
          provider: provider,
        ),
      );
    }
    if (g.startingArmor > 0) {
      chips.add(_ArmorTile(armor: g.startingArmor));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: _ContentCard(
        color: AppTheme.flair.primary,
        child: Wrap(spacing: 8, runSpacing: 8, children: chips),
      ),
    );
  }
}

// =============================================================================
// Playstyle page
// =============================================================================

class _PlaystylePage extends StatelessWidget {
  final Gungeoneer g;
  const _PlaystylePage({required this.g});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: _ContentCard(
        color: Colors.cyanAccent,
        child: GoopText(
          g.playstyle,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.6,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Tips page
// =============================================================================

class _TipsPage extends StatelessWidget {
  final Gungeoneer g;
  const _TipsPage({required this.g});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: _ContentCard(
        color: Colors.amberAccent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              g.tips
                  .map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.arrow_right_rounded,
                            size: 18,
                            color: Colors.amberAccent.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: GoopText(
                              t,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}

// =============================================================================
// Spoilers page — all spoiler-gated content in one place, clearly labeled
// =============================================================================

class _SpoilersPage extends StatelessWidget {
  final Gungeoneer g;
  const _SpoilersPage({required this.g});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Spoiler warning banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.25),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: Colors.redAccent.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GoopText(
                    'SPOILER WARNING — Story, past kills, and unlock details below.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.redAccent.withValues(alpha: 0.8),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Past Story
          if (g.pastSummary.isNotEmpty)
            SpoilerTag(
              label: 'Past Story',
              content: _SpoilerContent(title: g.pastName, body: g.pastSummary),
            ),
          // Past Kill Details
          if (g.pastDetails.isNotEmpty)
            SpoilerTag(
              label: 'Past Kill Details',
              content: _SpoilerContent(
                title: g.pastName,
                body: g.pastDetails,
                extra:
                    g.pastLoadout.isNotEmpty
                        ? 'Past loadout: ${g.pastLoadout}'
                        : null,
              ),
            ),
          // Past Kill Unlocks
          if (g.pastUnlocks.isNotEmpty && !g.pastUnlocks.contains('N/A'))
            SpoilerTag(
              label: 'Past Kill Unlocks',
              icon: Icons.card_giftcard,
              content: _SpoilerContent(body: g.pastUnlocks),
            ),
          // Unlock Method
          if (g.unlockMethod.isNotEmpty &&
              !g.unlockMethod.contains('Available from the start'))
            SpoilerTag(
              label: 'Unlock Method',
              icon: Icons.lock_outline,
              content: _SpoilerContent(body: g.unlockMethod),
            ),
          // Alternate Unlocks
          if (g.altCostumeUnlock.isNotEmpty &&
              !g.altCostumeUnlock.contains('N/A'))
            SpoilerTag(
              label: 'Alternate Unlocks',
              icon: Icons.palette_outlined,
              content: _SpoilerContent(
                body: [
                  if (g.altCostumeName.isNotEmpty &&
                      !g.altCostumeName.contains('N/A'))
                    'Alternate costume: ${g.altCostumeName}',
                  g.altCostumeUnlock,
                  if (g.altWeaponSkinUnlock.isNotEmpty &&
                      !g.altWeaponSkinUnlock.contains('N/A'))
                    g.altWeaponSkinUnlock,
                ].where((s) => s.isNotEmpty).join('\n\n'),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Reusable widgets
// =============================================================================

class _ContentCard extends StatelessWidget {
  final Color color;
  final Widget child;
  const _ContentCard({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.flair.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 0.8),
      ),
      child: child,
    );
  }
}

class _LoadoutTile extends StatelessWidget {
  final String name;
  final bool isRandom;
  final RunProvider provider;

  const _LoadoutTile({
    required this.name,
    required this.isRandom,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    if (isRandom) {
      return _tileContainer(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shuffle,
              size: 16,
              color: Colors.purpleAccent.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            GoopText(
              name,
              style: TextStyle(
                fontSize: FontSizes.labelMedium,
                fontWeight: FontWeight.w700,
                color: Colors.purpleAccent.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      );
    }

    final gun = provider.gunByName(name);
    final item = provider.itemByName(name);
    final exists = gun != null || item != null;
    final iconPath = gun?.icon ?? item?.icon ?? '';
    final quality = gun?.quality ?? item?.quality ?? '';
    final fallback = gun != null ? Icons.gps_fixed : Icons.inventory_2_outlined;

    return GestureDetector(
      onTap:
          exists
              ? () {
                Haptics.selection();
                Navigator.push(
                  context,
                  fastRoute(ItemDetailScreen(gun: gun, item: item)),
                );
              }
              : null,
      child: _tileContainer(
        opacity: exists ? 1.0 : 0.5,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GameIcon(
              assetPath: iconPath,
              fallback: fallback,
              quality: quality,
              size: 22,
              showRing: false,
              semanticLabel: name,
            ),
            const SizedBox(width: 6),
            GoopText(
              name,
              style: TextStyle(
                fontSize: FontSizes.labelMedium,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.85),
                decoration: exists ? null : TextDecoration.lineThrough,
              ),
            ),
            if (exists) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 14,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tileContainer({required Widget child, double opacity = 1.0}) {
    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.flair.card,
          borderRadius: BorderRadius.all(Radii.sm),
          border: Border.all(
            color: AppTheme.flair.primary.withValues(alpha: 0.15),
            width: 0.8,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Compact armor chip for the loadout row.
class _ArmorTile extends StatelessWidget {
  final int armor;
  const _ArmorTile({required this.armor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.flair.card,
        borderRadius: BorderRadius.all(Radii.sm),
        border: Border.all(
          color: Colors.blueAccent.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield,
            size: 16,
            color: Colors.blueAccent.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 6),
          GoopText(
            '$armor Armor',
            style: TextStyle(
              fontSize: FontSizes.labelMedium,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpoilerContent extends StatelessWidget {
  final String? title;
  final String body;
  final String? extra;

  const _SpoilerContent({this.title, required this.body, this.extra});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && title!.isNotEmpty) ...[
          GoopText(
            title!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.amber.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 6),
        ],
        GoopText(
          body,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.5,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        if (extra != null && extra!.isNotEmpty) ...[
          const SizedBox(height: 8),
          GoopText(
            extra!,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
