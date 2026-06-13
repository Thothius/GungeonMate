import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/run_provider.dart';
import '../models/gun.dart';
import '../models/item.dart';
import '../models/player.dart';
import '../services/app_theme.dart';
import '../widgets/quality_badge.dart';
import '../widgets/game_icon.dart';
import '../widgets/rich_link_text.dart';
import '../widgets/themed_number.dart';
import '../widgets/themed_section_title.dart';
import '../widgets/wiki_sections.dart';

class ItemDetailScreen extends StatefulWidget {
  final Gun? gun;
  final Item? item;

  /// When this detail screen was opened from a specific player's tile,
  /// remove/add operations route to that slot. If null, falls back to
  /// whichever slot currently owns this entry (main takes precedence).
  final PlayerSlot? ownerSlot;

  const ItemDetailScreen({super.key, this.gun, this.item, this.ownerSlot})
      : assert(gun != null || item != null);

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  // GlobalKeys on each major section so the TOC chips can scroll to
  // them via `Scrollable.ensureVisible`. Keyed by section identity,
  // not by position, so reordering the slivers doesn't rewire them.
  final _statsKey = GlobalKey();
  final _wikiKey = GlobalKey();
  final _synergyKey = GlobalKey();
  final _refsKey = GlobalKey();
  final _scrollCtrl = ScrollController();

  bool _showInAppWiki = false;
  WebViewController? _webViewController;

  void _initWebViewController(String urlString) {
    if (_webViewController != null) return;
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F0F12))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
        ),
      )
      ..loadRequest(Uri.parse(urlString));
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gun = widget.gun;
    final item = widget.item;
    final ownerSlot = widget.ownerSlot;
    final runProvider = context.watch<RunProvider>();
    final name = gun?.name ?? item!.name;
    final quality = gun?.quality ?? item!.quality;
    final subtitle = gun != null ? gun.type : item!.type;
    final quote = gun?.quote ?? item!.quote;

    final ownedList = runProvider.runState.allItemNames;
    final owned = ownedList.map((n) => n.toLowerCase()).toSet();
    final synergyStatuses = runProvider
        .getSynergiesFor(name)
        .map((s) => SynergyStatus(
              synergy: s,
              missing: s.missingFor(owned),
              active: s.matchesItems(ownedList),
            ))
        .toList()
      ..sort((a, b) {
        if (a.active != b.active) return a.active ? -1 : 1;
        return a.missing.length.compareTo(b.missing.length);
      });

    // When opened from a specific player's tile, only that slot's
    // ownership counts for showing trash vs add. From Browse (no slot
    // context), we fall back to either-player ownership.
    final bool isInRun;
    if (ownerSlot != null) {
      final owner = gun != null
          ? runProvider.ownerSlotOfGun(gun.name)
          : runProvider.ownerSlotOfItem(item!.name);
      isInRun = owner == ownerSlot;
    } else {
      isInRun = gun != null
          ? runProvider.isGunInRun(gun.name)
          : runProvider.isItemInRun(item!.name);
    }

    final wiki = gun?.wiki ?? item!.wiki;
    final referrers = runProvider.backRefs.referrersFor(name);

    final wikiUrlEncoded = Uri.encodeComponent(name.replaceAll(' ', '_'));
    final wikiUrlString = 'https://enterthegungeon.wiki.gg/wiki/$wikiUrlEncoded';

    if (_showInAppWiki) {
      _initWebViewController(wikiUrlString);
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        title: const SizedBox.shrink(),
      ),
      body: _showInAppWiki && _webViewController != null
          ? SafeArea(
              child: WebViewWidget(controller: _webViewController!),
            )
          : CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          SliverToBoxAdapter(
            child: _Header(
              name: name,
              subtitle: subtitle,
              quality: quality,
              quote: quote,
              isGun: gun != null,
              isActive: item?.isActive ?? false,
              iconPath: gun?.icon ?? item?.icon ?? '',
              verified: gun != null ? gun.wiki.hasAny : (item != null ? item.wiki.hasAny : false),
            ),
          ),
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: _statsKey,
              child: gun != null
                  ? _GunStats(gun: gun)
                  : _ItemBody(item: item!, ownerSlot: ownerSlot),
            ),
          ),
          // ---- Wiki rich content (Effects, Interactions, Notes, Trivia) ----
          // Rendered as collapsible accordion cards. Hidden when empty so
          // entries with no wiki coverage just keep the existing layout.
          // We inject a zero-height anchor sliver *before* the group so
          // `_scrollTo(_wikiKey)` has a target — `buildWikiSlivers`
          // returns a list of slivers we can't wrap with a box-level
          // KeyedSubtree.
          if (wiki.hasAny) ...[
            SliverToBoxAdapter(
              child: SizedBox(key: _wikiKey, height: 0),
            ),
            ...buildWikiSlivers(wiki),
          ],
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: _synergyKey,
              child: _SynergiesSection(
                statuses: synergyStatuses,
                currentName: name,
              ),
            ),
          ),
          // "Referenced by" — entities whose own wiki notes mention this one.
          // Surfaces non-obvious related content, e.g. opening Duct Tape
          // shows the 33 guns that talk about it in their notes.
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: _refsKey,
              child: ReferencedBySection(referrers: referrers),
            ),
          ),
          if (item != null && item.isDestroyedOnUse && isInRun)
            SliverToBoxAdapter(
              child: _DestroyBanner(
                onDestroy: () {
                  final slot = ownerSlot ??
                      runProvider.ownerSlotOfItem(item.name) ??
                      PlayerSlot.main;
                  runProvider.removeItem(item, slot: slot);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${item.name} destroyed on use'),
                      duration: const Duration(milliseconds: 1400),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
          child: Row(
            children: [
              // Back one step (e.g. back to Browse when coming from
              // Browse, or back to the previous detail view when
              // navigating through synergies). The old `Character`
              // shortcut lived here too but was removed — it only did a
              // `popUntil((r) => r.isFirst)` which on the bottom-nav
              // flow felt identical to Back and confused users who
              // expected it to jump to a character-specific screen.
              Expanded(
                child: SizedBox(
                  height: 68,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_back, size: 24),
                    label: const Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    onPressed: () {
                      if (_showInAppWiki) {
                        setState(() {
                          _showInAppWiki = false;
                        });
                      } else {
                        FocusManager.instance.primaryFocus?.unfocus();
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Themed Wiki button inside the button group
              SizedBox(
                width: 68,
                height: 68,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: _showInAppWiki 
                        ? AppTheme.flair.primary.withValues(alpha: 0.15) 
                        : null,
                    side: BorderSide(
                      color: AppTheme.flair.primary,
                      width: _showInAppWiki ? 2.5 : 1.5,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _showInAppWiki = !_showInAppWiki;
                    });
                  },
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 26,
                    color: AppTheme.flair.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Compact action square on the right (trash if in run, + if not)
              SizedBox(
                width: 68,
                height: 68,
                child: isInRun
                    ? OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: const BorderSide(
                            color: Colors.redAccent,
                            width: 1.5,
                          ),
                          backgroundColor: Colors.red.withValues(alpha: 0.08),
                        ),
                        onPressed: () {
                          // Remove from the owning slot (or the resolved
                          // owner if we don't know which it is).
                          final slot = ownerSlot ??
                              (gun != null
                                  ? runProvider.ownerSlotOfGun(gun.name)
                                  : runProvider.ownerSlotOfItem(item!.name)) ??
                              PlayerSlot.main;
                          if (gun != null) {
                            runProvider.removeGun(gun, slot: slot);
                          } else {
                            runProvider.removeItem(item!, slot: slot);
                          }
                          final who =
                              slot == PlayerSlot.coop ? ' from P2' : '';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$name removed$who'),
                              duration: const Duration(milliseconds: 1200),
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.delete_outline,
                          size: 28,
                          color: Colors.white,
                        ),
                      )
                    : FilledButton(
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          // Add to the originating slot if known, else main.
                          final slot = ownerSlot ?? PlayerSlot.main;
                          if (gun != null) {
                            runProvider.addGun(gun, slot: slot);
                          } else {
                            runProvider.addItem(item!, slot: slot);
                          }
                          final who =
                              slot == PlayerSlot.coop ? ' to P2' : '';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$name added$who'),
                              duration: const Duration(milliseconds: 1200),
                            ),
                          );
                        },
                        child: const Icon(Icons.add, size: 30),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  final String subtitle;
  final String quality;
  final String quote;
  final bool isGun;
  final bool isActive;
  final String iconPath;
  final bool verified;
  const _Header({
    required this.name,
    required this.subtitle,
    required this.quality,
    required this.quote,
    required this.isGun,
    required this.isActive,
    required this.iconPath,
    required this.verified,
  });

  @override
  Widget build(BuildContext context) {
    final f = AppTheme.flair;
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          padding: const EdgeInsets.fromLTRB(18, 18, 48, 18), // Extra padding on right to avoid overlaps
          decoration: BoxDecoration(
            color: f.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: f.primary.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: f.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: f.secondary.withValues(alpha: 0.2),
                width: 1.0,
              ),
            ),
            child: GameIcon(
              assetPath: iconPath,
              fallback: isGun
                  ? Icons.gps_fixed
                  : (isActive ? Icons.flash_on : Icons.inventory_2_outlined),
              quality: quality,
              size: 96,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (quality.isNotEmpty) ...[
                      QualityBadge(quality: quality, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        subtitle.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: f.secondary.withValues(alpha: 0.9),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                if (quote.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      '"$quote"',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5, // Made main desc text bigger!
                        color: Colors.white.withValues(alpha: 0.9),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
    Positioned(
      top: 24,
      right: 24,
      child: IconButton(
        icon: Icon(
          context.watch<RunProvider>().isFavourite(name)
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          color: context.watch<RunProvider>().isFavourite(name)
              ? Colors.pinkAccent
              : Colors.white38,
          size: 24,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: () {
          final p = context.read<RunProvider>();
          final wasFav = p.isFavourite(name);
          p.toggleFavourite(name);
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(wasFav
                  ? '$name removed from favourites'
                  : '$name added to favourites'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    ),
  ],
);
  }
}

class _GunStats extends StatelessWidget {
  final Gun gun;
  const _GunStats({required this.gun});

  Widget _buildGunderfuryInfo(BuildContext context, RunProvider p) {
    final lvl = p.gunderfuryLevel.clamp(1, 60);
    String formName = '';
    String description = '';
    String statsDesc = '';
    int currentXp = 0;

    if (lvl < 20) {
      formName = 'Base Form';
      description = 'Fires wide shotgun-like energy blasts.';
      statsDesc = 'Damage: 4.5 • Reload: 1.5s • Capacity: 450 • Spread: 10°';
      currentXp = ((lvl / 20) * 8000).round();
    } else if (lvl < 30) {
      formName = 'Automatic Form';
      description = 'Increases fire rate and becomes fully automatic.';
      statsDesc = 'Damage: 4.5 • Reload: 1.5s • Capacity: 450 • Spread: 10° (Auto)';
      currentXp = 8000 + (((lvl - 20) / 10) * 13000).round();
    } else if (lvl < 40) {
      formName = 'Defender Form';
      description = 'Shoots larger, high-velocity energy spheres with increased punch.';
      statsDesc = 'Damage: 6.5 • Reload: 1.1s • Capacity: 550 • Spread: 5°';
      currentXp = 21000 + (((lvl - 30) / 10) * 16500).round();
    } else if (lvl < 50) {
      formName = 'Vindicator Form';
      description = 'Fires faster with elevated accuracy and tighter groupings.';
      statsDesc = 'Damage: 6.5 • Reload: 1.1s • Capacity: 550 • Spread: 3°';
      currentXp = 37500 + (((lvl - 40) / 10) * 17500).round();
    } else if (lvl < 60) {
      formName = 'Laser Rifle';
      description = 'Fires sustained continuous rapid energy laser pulses.';
      statsDesc = 'Damage: 6.5 • Reload: 1.1s • Capacity: 550 • Spread: 2°';
      currentXp = 55000 + (((lvl - 50) / 10) * 20000).round();
    } else {
      formName = 'Awakened Gunderfury';
      description = 'Legendary form of the Blessed Gunseeker. Rapidly shoots twin light beams with absolute 0° spread, bouncing, and piercing!';
      statsDesc = 'Damage: 10.0 • Reload: 0.6s • Capacity: 650 • Spread: 0° (Perfect accuracy, Piercing, Bouncing)';
      currentXp = 75000;
    }

    final double xpProgress = (currentXp / 75000).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withValues(alpha: 0.04),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: Colors.purpleAccent.shade100, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'GUNDERFURY LEVEL TRACKER',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.purpleAccent.shade100,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove_circle_outline, size: 22, color: Colors.white70),
                    onPressed: lvl > 1 ? () => p.setGunderfuryLevel(lvl - 1) : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$lvl',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.purpleAccent),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add_circle_outline, size: 22, color: Colors.white70),
                    onPressed: lvl < 60 ? () => p.setGunderfuryLevel(lvl + 1) : null,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.purpleAccent,
              inactiveTrackColor: Colors.purple.withValues(alpha: 0.2),
              thumbColor: Colors.purpleAccent,
              overlayColor: Colors.purpleAccent.withValues(alpha: 0.2),
              valueIndicatorColor: Colors.purple,
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: SizedBox(
              height: 32,
              child: Slider(
                value: lvl.toDouble(),
                min: 1,
                max: 60,
                divisions: 59,
                onChanged: (val) {
                  p.setGunderfuryLevel(val.round());
                },
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Experience Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'EXPERIENCE GAUGE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.white54,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                lvl == 60 ? 'MAX LEVEL' : '${currentXp.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} / 75,000 XP',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: lvl == 60 ? Colors.amberAccent : Colors.purpleAccent.shade100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: xpProgress,
              minHeight: 6,
              backgroundColor: Colors.purple.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(lvl == 60 ? Colors.amber : Colors.purpleAccent),
            ),
          ),
          const SizedBox(height: 12),

          // Quick Jump Buttons Row
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _QuickJumpButton(
                label: 'Lvl 10',
                active: lvl == 10,
                onTap: () => p.setGunderfuryLevel(10),
              ),
              _QuickJumpButton(
                label: 'Lvl 20',
                active: lvl == 20,
                onTap: () => p.setGunderfuryLevel(20),
              ),
              _QuickJumpButton(
                label: 'Lvl 30',
                active: lvl == 30,
                onTap: () => p.setGunderfuryLevel(30),
              ),
              _QuickJumpButton(
                label: 'Lvl 40',
                active: lvl == 40,
                onTap: () => p.setGunderfuryLevel(40),
              ),
              _QuickJumpButton(
                label: 'Lvl 50',
                active: lvl == 50,
                onTap: () => p.setGunderfuryLevel(50),
              ),
              _QuickJumpButton(
                label: 'Lvl 60',
                active: lvl == 60,
                onTap: () => p.setGunderfuryLevel(60),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 16),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3), width: 1.2),
                ),
                child: Image.asset(
                  'assets/images/guns/gunderfury.webp',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE FORM: ${formName.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.purpleAccent,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      statsDesc,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripleGunInfo(BuildContext context, RunProvider p) {
    final form = p.tripleGunForm;
    String formName = '';
    String formDesc = '';
    if (form == 1) {
      formName = 'Form 1: Pistol (100%-33% Ammo)';
      formDesc = 'Fires rapid light shots. Very accurate. Bullet count: 1.';
    } else if (form == 2) {
      formName = 'Form 2: Shotgun (33%-11% Ammo)';
      formDesc = 'Fires a 3-bullet spread shot at closer range. High stagger.';
    } else {
      formName = 'Form 3: Laser Machine Gun (<11% Ammo)';
      formDesc = 'Fires continuous energy beam blasts. Incredibly high damage and rapid rate of fire.';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.alt_route, color: Colors.blueAccent.shade100, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Triple Gun Active Form',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent.shade100,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _QuickJumpButton(
                label: 'Form 1',
                active: form == 1,
                onTap: () => p.setTripleGunForm(1),
              ),
              _QuickJumpButton(
                label: 'Form 2',
                active: form == 2,
                onTap: () => p.setTripleGunForm(2),
              ),
              _QuickJumpButton(
                label: 'Form 3',
                active: form == 3,
                onTap: () => p.setTripleGunForm(3),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formName,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formDesc,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvolverInfo(BuildContext context, RunProvider p) {
    final activeStage = p.evolverForm;
    final totalKills = p.evolverKills;

    final stages = const [
      _EvolverStageSpec(
        id: 1,
        name: 'Amoeba',
        dps: '13.5 DPS',
        bullet: 'Base round shots',
        icon: Icons.bubble_chart_outlined,
        color: Colors.tealAccent,
      ),
      _EvolverStageSpec(
        id: 2,
        name: 'Sponge',
        dps: '19.1 DPS',
        bullet: 'Soaks up shots',
        icon: Icons.layers_outlined,
        color: Colors.greenAccent,
      ),
      _EvolverStageSpec(
        id: 3,
        name: 'Flatworm',
        dps: '25.8 DPS',
        bullet: 'Wide flattened shots',
        icon: Icons.gesture_outlined,
        color: Colors.limeAccent,
      ),
      _EvolverStageSpec(
        id: 4,
        name: 'Snail',
        dps: '34.5 DPS',
        bullet: '3-spiked shell spread',
        icon: Icons.gps_fixed_outlined,
        color: Colors.amberAccent,
      ),
      _EvolverStageSpec(
        id: 5,
        name: 'Frog',
        dps: '23.0 DPS/sec',
        bullet: 'Continuous tracking tongue',
        icon: Icons.pets_outlined,
        color: Colors.orangeAccent,
      ),
      _EvolverStageSpec(
        id: 6,
        name: 'Dragon',
        dps: '93.8 DPS',
        bullet: 'Accelerating homing blue flames',
        icon: Icons.fireplace_outlined,
        color: Colors.redAccent,
      ),
    ];

    final currentSpec = stages[activeStage - 1];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.03),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Icon(Icons.science_outlined, color: Colors.greenAccent.shade200, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THE EVOLVER: METAMORPHOSIS ENGINE',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.greenAccent.shade200,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'Biological Adaptations Slay Counter',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Colors.greenAccent.withValues(alpha: 0.6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.remove, size: 16, color: Colors.greenAccent),
                      onPressed: totalKills > 0 ? () => p.setEvolverKills(totalKills - 1) : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '$totalKills/25',
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'ArcadeClassic',
                          fontWeight: FontWeight.bold,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.add, size: 16, color: Colors.greenAccent),
                      onPressed: totalKills < 25 ? () => p.setEvolverKills(totalKills + 1) : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 🌳 Evolution Tree Node Row
          SizedBox(
            height: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(stages.length, (i) {
                final spec = stages[i];
                final isUnlocked = activeStage >= spec.id;
                final isActive = activeStage == spec.id;
                final color = isActive ? spec.color : (isUnlocked ? Colors.green.shade700 : Colors.white12);

                return Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Connector line between slots
                      if (i < stages.length - 1)
                        Positioned(
                          left: 24,
                          right: -24,
                          top: 24,
                          child: Container(
                            height: 2.5,
                            color: isUnlocked && activeStage > spec.id
                                ? Colors.green.withValues(alpha: 0.5)
                                : Colors.white10,
                          ),
                        ),
                      
                      // Node Card
                      GestureDetector(
                        onTap: () {
                          // Click to force-jump to this form (sets required kills)
                          p.setEvolverKills((spec.id - 1) * 5);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive ? Colors.black45 : Colors.black26,
                                border: Border.all(
                                  color: color,
                                  width: isActive ? 2.5 : 1.2,
                                ),
                                boxShadow: isActive ? [
                                  BoxShadow(
                                    color: spec.color.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ] : null,
                              ),
                              child: Icon(
                                isActive ? spec.icon : (isUnlocked ? spec.icon : Icons.lock_outline),
                                size: isActive ? 22 : 18,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              spec.name,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
                                color: isActive ? spec.color : Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),

          // Tactile Unique Kills Checkbox Grid
          const Text(
            'UNIQUE ENEMY TYPES SLAIN CHECKLIST',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.greenAccent, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 5.5,
            runSpacing: 5.5,
            children: List.generate(25, (index) {
              final killNum = index + 1;
              final isChecked = totalKills >= killNum;
              final isThresholdNode = killNum % 5 == 0;

              return GestureDetector(
                onTap: () {
                  if (isChecked) {
                    p.setEvolverKills(killNum - 1);
                  } else {
                    p.setEvolverKills(killNum);
                  }
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isChecked 
                        ? (isThresholdNode ? Colors.green.shade800 : Colors.green.withValues(alpha: 0.35))
                        : Colors.black38,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isChecked 
                          ? Colors.greenAccent 
                          : (isThresholdNode ? Colors.greenAccent.withValues(alpha: 0.3) : Colors.white12),
                      width: isThresholdNode ? 1.5 : 1.0,
                    ),
                  ),
                  child: Center(
                    child: isChecked 
                        ? Icon(isThresholdNode ? Icons.star : Icons.check, size: 13, color: Colors.greenAccent)
                        : Text(
                            '$killNum',
                            style: TextStyle(
                              fontSize: 9, 
                              fontWeight: FontWeight.bold, 
                              color: isThresholdNode ? Colors.greenAccent.withValues(alpha: 0.4) : Colors.white24
                            ),
                          ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),

          // 📟 Shifting Bio-Analysis Terminal Console
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: currentSpec.color.withValues(alpha: 0.3), width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentSpec.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'BIO-ANALYSIS: STAGE ${currentSpec.id} [${currentSpec.name.toUpperCase()}]',
                      style: TextStyle(
                        fontFamily: 'EnterTheGungeonBig',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: currentSpec.color,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      currentSpec.dps,
                      style: TextStyle(
                        fontFamily: 'ArcadeClassic',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: currentSpec.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Projectiles: ${currentSpec.bullet}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
                const SizedBox(height: 3),
                Text(
                  'Formula: ${activeStage == 6 ? "Ultimate Form Unlocked!" : "Requires ${(activeStage * 5) - totalKills} more unique kills to force-evolve."}',
                  style: const TextStyle(fontSize: 10.5, color: Colors.white38),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
// Note: _buildEvolverInfo ends above. _GunStats continues below with build().

  @override
  Widget build(BuildContext context) {
    // Stats are grouped by mental category so a long pill list stops
    // reading as a wall:
    //   Combat   — what hits, how often, how long can it sustain
    //   Handling — feel-of-the-gun spatial properties
    //   Meta     — economy + drop-source data
    // DPS lives in the hero row above and is intentionally absent here.
    final combat = <MapEntry<String, String>>[
      MapEntry('Damage', gun.damage),
      MapEntry('Fire rate', gun.fireRate),
      MapEntry('Magazine', gun.magazineSize),
      MapEntry('Max ammo', gun.ammoCapacity),
      MapEntry('Reload', gun.reloadTime),
    ].where((e) => e.value.isNotEmpty).toList();
    final handling = <MapEntry<String, String>>[
      MapEntry('Range', gun.range),
      MapEntry('Shot speed', gun.shotSpeed),
      MapEntry('Force', gun.force),
      MapEntry('Spread', gun.spread),
    ].where((e) => e.value.isNotEmpty).toList();
    final meta = <MapEntry<String, String>>[
      MapEntry('Class', gun.gunClass),
      MapEntry('Sell', gun.sellPrice),
      MapEntry('Chest', gun.chestColorDisplay),
    ].where((e) => e.value.isNotEmpty).toList();

    final p = context.watch<RunProvider>();
    final gunderfuryInfo = gun.name.toLowerCase() == 'gunderfury'
        ? _buildGunderfuryInfo(context, p)
        : null;
    final tripleGunInfo = gun.name.toLowerCase() == 'triple gun'
        ? _buildTripleGunInfo(context, p)
        : null;
    final evolverInfo = gun.name.toLowerCase() == 'evolver'
        ? _buildEvolverInfo(context, p)
        : null;

    final String animationAsset;
    final String typeLower = gun.type.toLowerCase();
    if (typeLower.contains('charged') || typeLower.contains('charge')) {
      animationAsset = 'assets/animations/gun_types/Chargeweapon_demo.gif';
    } else if (typeLower.contains('beam')) {
      animationAsset = 'assets/animations/gun_types/Beamweapon_demo.gif';
    } else if (typeLower.contains('burst')) {
      animationAsset = 'assets/animations/gun_types/Burstweapon_demo.gif';
    } else if (typeLower.contains('automatic') || typeLower.contains('auto')) {
      animationAsset = 'assets/animations/gun_types/Automaticweapon_demo.gif';
    } else {
      animationAsset = 'assets/animations/gun_types/Semiautomaticweapon_demo.gif';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Halved Row: Left side is the Animated Fire Type, Right side is the Gun DPS!
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Side: Fire Type Animation
                  Expanded(
                    child: Container(
                      height: 142, // Exactly matches the right box height!
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.flair.scaffold.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.flair.primary.withValues(alpha: 0.25),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bolt, size: 14, color: AppTheme.flair.primary),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  gun.type.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.flair.headlineStat,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              animationAsset,
                              height: 80, // slightly shorter to fit side-by-side perfectly
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.none,
                              errorBuilder: (_, __, ___) => Container(
                                height: 80,
                                alignment: Alignment.center,
                                child: Text(
                                  gun.type,
                                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  
                  // Right Side: Gun DPS Readout
                  Expanded(
                    child: Container(
                      height: 142, // Matching the left box height!
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.flair.scaffold.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.flair.primary.withValues(alpha: 0.25),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.flash_on, size: 14, color: AppTheme.flair.secondary),
                              const SizedBox(width: 4),
                              Text(
                                'GUN DPS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.flair.headlineStat,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            gun.dpsValue > 0 ? gun.dpsValue.toStringAsFixed(1) : (gun.dps.isEmpty ? '0.0' : gun.dps),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.flair.secondary,
                              height: 1.0,
                              shadows: [
                                Shadow(
                                  color: AppTheme.flair.secondary.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Damage Per Second',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (gunderfuryInfo != null) ...[
                gunderfuryInfo,
                const SizedBox(height: 14),
              ],
              if (tripleGunInfo != null) ...[
                tripleGunInfo,
                const SizedBox(height: 14),
              ],
              if (evolverInfo != null) ...[
                evolverInfo,
                const SizedBox(height: 14),
              ],
              if (gun.notes.isNotEmpty) ...[
                Text(
                  gun.notes,
                  style: const TextStyle(fontSize: 14.5, height: 1.35),
                ),
                const Divider(height: 26),
              ],
              if (combat.isNotEmpty)
                _StatGroup(
                  label: 'Combat',
                  icon: Icons.local_fire_department,
                  stats: combat,
                ),
              if (handling.isNotEmpty) ...[
                if (combat.isNotEmpty) const SizedBox(height: 14),
                _StatGroup(
                  label: 'Handling',
                  icon: Icons.tune,
                  stats: handling,
                ),
              ],
              if (meta.isNotEmpty) ...[
                if (combat.isNotEmpty || handling.isNotEmpty)
                  const SizedBox(height: 14),
                _StatGroup(
                  label: 'Meta',
                  icon: Icons.info_outline,
                  stats: meta,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EvolverStageSpec {
  final int id;
  final String name;
  final String dps;
  final String bullet;
  final IconData icon;
  final Color color;
  const _EvolverStageSpec({
    required this.id,
    required this.name,
    required this.dps,
    required this.bullet,
    required this.icon,
    required this.color,
  });
}

/// Sub-section inside `_GunStats` that prefaces a `Wrap` of pills with a
/// quiet ALL-CAPS label and a leading icon so the eye can find the
/// category at a glance.
class _StatGroup extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<MapEntry<String, String>> stats;
  const _StatGroup({
    required this.label,
    required this.icon,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: stats
              .map((e) => _StatPill(label: e.key, value: e.value))
              .toList(),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});

  static const Map<String, Color> _chestColors = {
    'red': Color(0xFFE53935),
    'blue': Color(0xFF1E88E5),
    'green': Color(0xFF43A047),
    'black': Color(0xFF222222),
    'brown': Color(0xFF8D6E63),
    'rainbow': Colors.pinkAccent,
  };

  /// Chest *rank* derived from the chest colour. ETG ties chest tier to
  /// loot quality on a fixed scale, so showing the letter alongside the
  /// colour answers the "is this a B-tier or A-tier drop?" question
  /// without forcing the user to remember the colour mapping.
  static const Map<String, String> _chestRanks = {
    'brown': 'D',
    'blue': 'C',
    'green': 'B',
    'red': 'A',
    'black': 'S',
    'rainbow': '★',
  };

  @override
  Widget build(BuildContext context) {
    final isChest = label.toLowerCase() == 'chest';
    final isCharge = label.toLowerCase() == 'charge';
    final isDuration = label.toLowerCase() == 'duration';
    final chestColor = isChest ? _chestColors[value.toLowerCase()] : null;
    final chestRank = isChest ? _chestRanks[value.toLowerCase()] : null;
    // Numeric-looking values get ThemedNumber so the active flair drives
    // weight / italic / tabular figures / shimmer / emboss. String-only
    // values (e.g. chest "blue") fall through to plain Text since
    // shimmering "blue" would look like a glitch.
    final hasDigit = RegExp(r'\d').hasMatch(value);
    final flair = AppTheme.flair;
    final filled = flair.chipFilled;
    final accentColor = isCharge
        ? Colors.lightBlueAccent
        : isDuration
            ? Colors.greenAccent.shade200
            : null;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: filled ? 10 : 4,
        vertical: filled ? 6 : 2,
      ),
      decoration: BoxDecoration(
        color: filled
            ? (accentColor?.withValues(alpha: 0.08) ??
                Colors.white.withValues(alpha: 0.06))
            : null,
        borderRadius: BorderRadius.circular(flair.chipRadius),
        border: filled
            ? (accentColor != null
                ? Border.all(
                    color: accentColor.withValues(alpha: 0.35),
                    width: 0.8,
                  )
                : null)
            : Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCharge) ...[Icon(Icons.electric_bolt, size: 12, color: Colors.lightBlueAccent), const SizedBox(width: 3)],
          if (isDuration) ...[Icon(Icons.timer_outlined, size: 12, color: Colors.greenAccent.shade200), const SizedBox(width: 3)],
          Text(
            '$label  ',
            style: TextStyle(
              fontSize: 12,
              color: accentColor?.withValues(alpha: 0.85) ??
                  Colors.white.withValues(alpha: 0.6),
            ),
          ),
          if (chestColor != null) ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: chestColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 0.8),
              ),
            ),
            const SizedBox(width: 5),
          ],
          if (hasDigit)
            ThemedNumber(
              value: value,
              baseSize: 13,
              colorOverride: Colors.white,
              role: ThemedNumberRole.headline,
            )
          else
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (chestRank != null) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: (chestColor ?? Colors.white24)
                    .withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: (chestColor ?? Colors.white24)
                      .withValues(alpha: 0.7),
                  width: 0.7,
                ),
              ),
              child: Text(
                chestRank,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemBody extends StatelessWidget {
  final Item item;
  final PlayerSlot? ownerSlot;
  const _ItemBody({required this.item, this.ownerSlot});

  /// Pull a numeric "X second(s)" mention out of [item.effect]. Returns
  /// null when the text doesn't mention a duration, or when the only
  /// duration mentioned is what the [item.rechargeTime] already carries
  /// (so we don't show two pills with the same value). Many actives
  /// describe their effect length inline (e.g. "lasts 5 seconds",
  /// "for 4s") but never expose it as a structured field — surfacing
  /// it here closes the UX gap testers flagged.
  String? _extractDuration() {
    final effect = item.effect;
    if (effect.isEmpty) return null;
    final m = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:seconds?|secs?|s)\b',
      caseSensitive: false,
    ).firstMatch(effect);
    if (m == null) return null;
    final raw = m.group(1) ?? '';
    if (raw.isEmpty) return null;
    final asString = '${raw}s';
    final rt = item.rechargeTime.toLowerCase();
    if (rt.contains('${raw}s') || rt.contains('$raw second')) return null;
    return asString;
  }

  Widget _buildJunkanInfo(BuildContext context) {
    final p = context.watch<RunProvider>();
    final slot = ownerSlot ?? PlayerSlot.main;
    final player = slot == PlayerSlot.coop
        ? (p.runState.coop ?? Player())
        : p.runState.main;
    final junkCount = player.items
        .where((i) => i.name.toLowerCase() == 'junk')
        .length;
    final hasGoldJunk = player.items.any((i) => i.name.toLowerCase() == 'gold junk');

    String rankName = '';
    String description = '';
    String stats = '';

    if (hasGoldJunk) {
      rankName = 'MECHA JUNKAN (GOLD MECHSUIT)';
      description = 'High-tech gold mechsuit! Jammed enemies struck by Mecha Junkan\'s machine gun become normal. Bypasses boss DPS cap.';
      stats = 'Damage: 2.2/shot (Machine Gun) • 20.0 (Laser blade) • 8.0/rocket (Homing Rockets)';
    } else {
      switch (junkCount) {
        case 0:
          rankName = 'PEASANT';
          description = 'Junkan harmlessly pushes enemies around.';
          stats = 'Damage: 0.0 • Role: Companion • Speed: Steady';
          break;
        case 1:
          rankName = 'SQUIRE';
          description = 'Gains helmet. Headbutts enemies slowly.';
          stats = 'Damage: 3.0 • Attack: Headbutt • Armor: Helmet';
          break;
        case 2:
          rankName = 'HEDGE KNIGHT';
          description = 'Gains shield. Attacks more frequently by shield-bashing enemies.';
          stats = 'Damage: 5.0 • Attack: Shield-bash • Armor: Shield';
          break;
        case 3:
          rankName = 'KNIGHT';
          description = 'Gains sword. Attacks more frequently by slicing enemies.';
          stats = 'Damage: 7.0 • Attack: Sword-slice • Armor: Sword';
          break;
        case 4:
          rankName = 'KNIGHT LIEUTENANT';
          description = 'Gains helmet adornment. Sword attacks are faster and deal more damage.';
          stats = 'Damage: 9.0 • Attack: Upgraded Slice • Armor: Plated';
          break;
        case 5:
          rankName = 'KNIGHT COMMANDER';
          description = 'Gains cape. Spin-attacks multiple enemies simultaneously.';
          stats = 'Damage: 10.0 × 2 (Double Spin) • Attack: Spin Attack • Armor: Cape';
          break;
        case 6:
          rankName = 'HOLY KNIGHT';
          description = 'White color scheme. Occasionally Blanks. Sacrifices himself to revive the player at full health if they die.';
          stats = 'Damage: 13.33 • Attack: Holy Slice • Ability: Blank + Sacrifice';
          break;
        default:
          rankName = 'ANGELIC KNIGHT (7+ JUNK)';
          description = 'Gains angel armor & wings. Flying. Fires rapid pink projectiles. Loses Blanks and Sacrifice ability.';
          stats = 'Damage: 10.0/shot • Attack: Ranged Pink Shots • Ability: Flying';
          break;
      }
    }

    final junkItem = p.itemByName('Junk');
    final goldJunkItem = p.itemByName('Gold Junk');

    final String imgPath = hasGoldJunk
        ? 'assets/images/junkan/gold.webp'
        : switch (junkCount) {
            0 => 'assets/images/junkan/1.webp',
            1 => 'assets/images/junkan/3.webp',
            2 => 'assets/images/junkan/4.webp',
            3 => 'assets/images/junkan/5.webp',
            4 => 'assets/images/junkan/6.webp',
            5 => 'assets/images/junkan/7.webp',
            6 => 'assets/images/junkan/8.webp',
            _ => 'assets/images/junkan/8.webp',
          };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.04),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars, color: Colors.amber.shade300, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SER JUNKAN LEVEL TRACKER',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.amber.shade300,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Interactive Junk Count Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.inventory_2_outlined, color: Colors.white54, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Regular Junk:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove_circle_outline, size: 22, color: Colors.white70),
                    onPressed: junkCount > 0 && junkItem != null
                        ? () => p.removeItem(junkItem, slot: slot)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$junkCount',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.amber),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add_circle_outline, size: 22, color: Colors.white70),
                    onPressed: junkItem != null
                        ? () => p.addItem(junkItem, slot: slot)
                        : null,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Interactive Gold Junk Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.precision_manufacturing_outlined, color: Colors.amber.shade200, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    'Has Gold Junk (Mech Suit):',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Switch(
                value: hasGoldJunk,
                activeColor: Colors.amber,
                onChanged: (val) {
                  if (goldJunkItem == null) return;
                  if (val) {
                    p.addItem(goldJunkItem, slot: slot);
                  } else {
                    p.removeItem(goldJunkItem, slot: slot);
                  }
                },
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 16),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.35), width: 1.2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    imgPath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none, // Keep pixel art sharp!
                    errorBuilder: (_, __, ___) => const Icon(Icons.shield, color: Colors.amber, size: 32),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rank Name
                    Text(
                      'ACTIVE FORM: $rankName',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.amberAccent,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Stats Row
                    Text(
                      stats,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpiceInfo(BuildContext context) {
    final p = context.watch<RunProvider>();
    final count = p.spiceUsageCount;

    String currentEffects = '';
    String nextEffects = '';

    if (count == 0) {
      currentEffects = 'No Spice used yet.';
      nextEffects = '1st Use: +1 Heart Container, +1 Coolness, +20% Shot Speed, -10% Spread, +0.5 Curse, changes pickup quote.';
    } else if (count == 1) {
      currentEffects = '1st Use Applied: +1 Heart Container, +1 Coolness, +20% Shot Speed, -10% Spread, +0.5 Curse.';
      nextEffects = '2nd Use: +1 Coolness, +20% Shot Speed, -10% Spread, +20% Damage, -1 Heart Container, +1.0 Curse.';
    } else if (count == 2) {
      currentEffects = '2nd Use Applied: +2 Coolness, +40% Shot Speed, -19% Spread, +20% Damage, +1.0 Curse total.';
      nextEffects = '3rd Use: +20% Damage, -10% Spread, -1 Heart Container, +1.0 Curse.';
    } else if (count == 3) {
      currentEffects = '3rd Use Applied: +2 Coolness, +40% Shot Speed, -27% Spread, +40% Damage, -1 Heart Container total, +2.0 Curse total.';
      nextEffects = '4th Use: +15% Damage, -10% Spread, -1 Heart Container, +1.0 Curse.';
    } else if (count == 4) {
      currentEffects = '4th Use Applied: +2 Coolness, +40% Shot Speed, -34% Spread, +55% Damage, -2 Heart Containers total, +3.0 Curse total.';
      nextEffects = '5th+ Use: +15% Damage, +1.0 Curse (no more spread or health penalties).';
    } else {
      final extraUses = count - 4;
      final damageBonus = 55 + (extraUses * 15);
      final curseTotal = 3.0 + extraUses;
      currentEffects = '$count Uses Applied: +2 Coolness, +40% Shot Speed, -34% Spread, +$damageBonus% Damage, -2 Heart Containers, +$curseTotal Curse total.';
      nextEffects = 'Subsequent Uses: +15% Damage, +1.0 Curse per use.';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.spa, color: Colors.redAccent.shade100, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Spice Addiction Tracker',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent.shade100,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove_circle_outline, size: 22, color: Colors.white70),
                onPressed: count > 0
                    ? () {
                        final double curseToSubtract = (count == 1) ? 0.5 : 1.0;
                        final double coolnessToSubtract = (count <= 2) ? 1.0 : 0.0;
                        p.setSpiceUsageCount(count - 1);
                        p.adjustCurse(-curseToSubtract);
                        if (coolnessToSubtract != 0) {
                          p.adjustCoolness(-coolnessToSubtract);
                        }
                      }
                    : null,
              ),
              Text(
                '$count',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add_circle_outline, size: 22, color: Colors.white70),
                onPressed: () {
                  final double curseToAdd = (count == 0) ? 0.5 : 1.0;
                  final double coolnessToAdd = (count < 2) ? 1.0 : 0.0;
                  p.setSpiceUsageCount(count + 1);
                  p.adjustCurse(curseToAdd);
                  if (coolnessToAdd != 0) {
                    p.adjustCoolness(coolnessToAdd);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'CURRENT: $currentEffects',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'NEXT: $nextEffects',
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.white.withValues(alpha: 0.65),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Note: Adjusting Spice count automatically syncs Curse to your active run (+0.5 for 1st use, +1.0 for each additional use).',
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: Colors.redAccent.shade100.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSprunInfo(BuildContext context) {
    final p = context.watch<RunProvider>();
    final triggerIdx = p.sprunTriggerIndex;
    final isWindgunnerActive = p.windgunnerCountdown > 0;

    final possibleTriggers = const [
      'Activating a Map Blank',
      'Taking damage to Armor / Losing a half-heart',
      'Throwing an empty weapon at a wall',
      'Falling down an elevator shaft or trap pit',
      'Lighting yourself on fire or stepping into a poison pool'
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.cyan.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.cyanAccent.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.radar_outlined, color: Colors.cyanAccent.shade200, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SPRUN: ORB OBSERVATION DETECTOR',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.cyanAccent.shade200,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (triggerIdx == -1) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.15)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.blur_circular_outlined, size: 36, color: Colors.cyanAccent),
                  const SizedBox(height: 8),
                  const Text(
                    '🔮 ACTIVE SEED SYNERGY HIDDEN',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Each run pre-determines a randomized trigger to transform Sprun into the infinite-ammo Windgunner. Tap below to run active seed analysis.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Colors.white54, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan.shade900,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.biotech_outlined, size: 16),
                      label: const Text(
                        'ANALYZE ACTIVE RUN SEED TRIGGER',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                      onPressed: () {
                        final randomIdx = DateTime.now().millisecondsSinceEpoch % possibleTriggers.length;
                        p.setSprunTriggerIndex(randomIdx);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const Text(
              'ACTIVE SEED ANALYSIS RESULTS:',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.cyanAccent, letterSpacing: 0.5),
            ),
            const SizedBox(height: 6),
            Column(
              children: List.generate(possibleTriggers.length, (idx) {
                final isMatch = triggerIdx == idx;
                return Container(
                  margin: const EdgeInsets.only(bottom: 5),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  decoration: BoxDecoration(
                    color: isMatch ? Colors.cyan.withValues(alpha: 0.18) : Colors.black12,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isMatch ? Colors.cyanAccent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isMatch ? Icons.check_circle : Icons.circle_outlined,
                        size: 14,
                        color: isMatch ? Colors.cyanAccent : Colors.white24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          possibleTriggers[idx],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isMatch ? FontWeight.bold : FontWeight.normal,
                            color: isMatch ? Colors.white : Colors.white30,
                            decoration: isMatch ? null : TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mystery seed decoded successfully.',
                  style: TextStyle(fontSize: 9.5, color: Colors.cyanAccent.withValues(alpha: 0.5)),
                ),
                InkWell(
                  onTap: () => p.setSprunTriggerIndex(-1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'RE-SET SEED',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.cyanAccent.shade100, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const Divider(color: Colors.white12, height: 16),
          // Hype Toggle Countdown
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isWindgunnerActive ? Colors.cyan.withValues(alpha: 0.12) : Colors.black12,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isWindgunnerActive ? Colors.cyanAccent.withValues(alpha: 0.3) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isWindgunnerActive ? '⚡ WINDGUNNER MODE IS ACTIVE!' : 'WINDGUNNER MODE OFF-LINE',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: isWindgunnerActive ? Colors.cyanAccent : Colors.white54,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 1.5),
                      Text(
                        isWindgunnerActive 
                            ? 'Infinite Ammo, Flight, God-tier Burst! Count: ${p.windgunnerCountdown}s'
                            : 'Trigger criteria above to release power.',
                        style: TextStyle(fontSize: 9.5, color: isWindgunnerActive ? Colors.white70 : Colors.white38),
                      ),
                    ],
                  ),
                ),
                Switch(
                  activeColor: Colors.cyanAccent,
                  activeTrackColor: Colors.cyan.shade900,
                  value: isWindgunnerActive,
                  onChanged: (val) {
                    if (val) {
                      p.startWindgunnerCountdown();
                    } else {
                      p.cancelWindgunnerCountdown();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaydayInfo(BuildContext context) {
    final p = context.watch<RunProvider>();
    final slot = ownerSlot ?? PlayerSlot.main;
    final player = slot == PlayerSlot.coop
        ? (p.runState.coop ?? Player())
        : p.runState.main;

    // Check actual possession in active run
    final hasMask = player.items.any((i) => i.name.toLowerCase() == 'clown mask');
    final hasDrill = player.guns.any((g) => g.name.toLowerCase() == 'drill') || 
                     player.items.any((i) => i.name.toLowerCase() == 'drill');
    final hasBag = player.items.any((i) => i.name.toLowerCase() == 'loot bag');

    final int itemsCount = (hasMask ? 1 : 0) + (hasDrill ? 1 : 0) + (hasBag ? 1 : 0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blueAccent.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups_outlined, color: Colors.blueAccent.shade100, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THE PAYDAY CREW ASSEMBLY HUD',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.blueAccent,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'Heister Count Exponential Matrix',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Colors.white38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '$itemsCount/3 CO-OP',
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'ArcadeClassic',
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Horizontal 3-slot inventory bay
          Row(
            children: [
              _buildHeisterSlot(
                name: 'Dallas',
                item: 'Clown Mask',
                active: hasMask,
                desc: 'Summoned • Periodically charges & stuns enemies with melee.',
                avatar: Icons.face_retouching_natural_outlined,
              ),
              const SizedBox(width: 8),
              _buildHeisterSlot(
                name: 'Wolf',
                item: 'Drill',
                active: hasDrill,
                desc: 'Summoned • Drops mini blanks to delete incoming projectile matrices.',
                avatar: Icons.build_outlined,
              ),
              const SizedBox(width: 8),
              _buildHeisterSlot(
                name: 'Chains',
                item: 'Loot Bag',
                active: hasBag,
                desc: 'Summoned • Automated shotgun scaling with floor difficulty tier.',
                avatar: Icons.monetization_on_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Heister Summon Power Description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SUMMON POWER PROFILE:',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.blueAccent, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                if (itemsCount == 0)
                  const Text(
                    'No heisters active. Hold Dallas (Clown Mask), Wolf (Drill), or Chains (Loot Bag) to activate.',
                    style: TextStyle(fontSize: 10.5, color: Colors.white38, height: 1.2),
                  )
                else if (itemsCount == 1)
                  const Text(
                    'Dallas Active: Melee charge stuns enemies.',
                    style: TextStyle(fontSize: 10.5, color: Colors.white70, fontWeight: FontWeight.bold, height: 1.2),
                  )
                else if (itemsCount == 2)
                  const Text(
                    'Dallas + Wolf Active: Added blank defense. Deletes projectiles.',
                    style: TextStyle(fontSize: 10.5, color: Colors.cyanAccent, fontWeight: FontWeight.bold, height: 1.2),
                  )
                else
                  const Text(
                    'Dallas + Wolf + Chains Active: FULL HEIST CREW ASSEMBLED! Automated shotgun scaling active. Infinite heister capabilities!',
                    style: TextStyle(fontSize: 10.5, color: Colors.greenAccent, fontWeight: FontWeight.w900, height: 1.2),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeisterSlot({
    required String name,
    required String item,
    required bool active,
    required String desc,
    required IconData avatar,
  }) {
    return Expanded(
      child: Tooltip(
        message: '$item: $desc',
        child: Container(
          padding: const EdgeInsets.all(8),
          height: 84,
          decoration: BoxDecoration(
            color: active ? Colors.blueAccent.withValues(alpha: 0.18) : Colors.black26,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? Colors.blueAccent : Colors.white.withValues(alpha: 0.05),
              width: active ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                avatar,
                size: 24,
                color: active ? Colors.blueAccent.shade100 : Colors.white24,
              ),
              const SizedBox(height: 4),
              Text(
                name.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: active ? Colors.white : Colors.white24,
                ),
              ),
              Text(
                active ? 'SUMMONED' : 'LOCKED',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: active ? Colors.greenAccent : Colors.white24,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? durationStr;
    String? chargeStr;
    if (item.isActive) {
      durationStr = item.duration.isNotEmpty ? item.duration : _extractDuration();
      chargeStr = item.rechargeTime.isNotEmpty ? item.rechargeTime : 'via damage';
    }
    final stats = <MapEntry<String, String>>[
      if (chargeStr != null) MapEntry('Charge', chargeStr),
      if (durationStr != null) MapEntry('Duration', durationStr),
      MapEntry('Sell', item.sellPrice),
      MapEntry('Chest', item.chestColorDisplay),
    ].where((e) => e.value.isNotEmpty).toList();

    final junkanInfo = item.name.toLowerCase() == 'ser junkan'
        ? _buildJunkanInfo(context)
        : null;
    final spiceInfo = item.name.toLowerCase() == 'spice'
        ? _buildSpiceInfo(context)
        : null;
    final sprunInfo = item.name.toLowerCase() == 'sprun'
        ? _buildSprunInfo(context)
        : null;
    final isPaydayItem = const ['clown mask', 'drill', 'loot bag'].contains(item.name.toLowerCase());
    final paydayInfo = isPaydayItem
        ? _buildPaydayInfo(context)
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.effect.isNotEmpty)
                Text(
                  item.effect,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              if (junkanInfo != null) ...[
                const SizedBox(height: 12),
                junkanInfo,
              ],
              if (spiceInfo != null) ...[
                const SizedBox(height: 12),
                spiceInfo,
              ],
              if (sprunInfo != null) ...[
                const SizedBox(height: 12),
                sprunInfo,
              ],
              if (paydayInfo != null) ...[
                const SizedBox(height: 12),
                paydayInfo,
              ],
              if (stats.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: stats
                      .map((e) => _StatPill(label: e.key, value: e.value))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SynergiesSection extends StatelessWidget {
  final List<SynergyStatus> statuses;
  final String currentName;
  const _SynergiesSection({
    required this.statuses,
    required this.currentName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ThemedSectionTitle(
            icon: Icons.hub,
            iconColor: Colors.amber,
            title: 'Synergies',
            count: statuses.length,
          ),
          const SizedBox(height: 6),
          if (statuses.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No known synergies.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                ),
              ),
            )
          else
            ...statuses.map(
              (s) => _SynergyCard(
                status: s,
                currentName: currentName,
              ),
            ),
        ],
      ),
    );
  }
}

class _SynergyCard extends StatelessWidget {
  final SynergyStatus status;
  /// Name of the entity whose detail page this card is rendered on. Used
  /// to suppress redundant chips — when you're looking at "Homing Bullets",
  /// a synergy that lists Homing Bullets as one of its any_of alternatives
  /// shouldn't waste a chip slot reminding you of yourself.
  final String currentName;
  const _SynergyCard({required this.status, required this.currentName});

  @override
  Widget build(BuildContext context) {
    final s = status.synergy;
    final color = status.active
        ? Colors.amber
        : Colors.white.withValues(alpha: 0.25);

    final currentLower = currentName.toLowerCase();
    // True when the item being viewed is itself one of the anyOf alternatives
    // (it fills the "+1 of" slot rather than being a hard requirement).
    final currentIsAnyOf =
        s.anyOf.any((i) => i.toLowerCase() == currentLower);
    final ownedLower = context.read<RunProvider>().currentOwnedLower;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: status.active ? 1.2 : 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  status.active ? Icons.link : Icons.link_off_outlined,
                  size: 16,
                  color: status.active ? Colors.amber : Colors.white38,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          s.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.verified,
                        size: 13,
                        color: Colors.cyan,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Required items — all partners except the item being viewed.
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: s.items
                  .where((i) => i.toLowerCase() != currentLower)
                  .map((i) => _SynergyChip(
                        name: i,
                        missing: status.missing.contains(i),
                      ))
                  .toList(),
            ),
            if (s.anyOf.isNotEmpty) ...[
              const SizedBox(height: 8),
              if (currentIsAnyOf)
                // This item IS the "+1 of" piece — confirm the role instead
                // of listing the other alternatives (which are irrelevant when
                // the player is already holding this item).
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 13,
                      color: Colors.amber.withValues(alpha: 0.80),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Alternative components matched',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                )
              else ...[
                // Current item is a hard requirement — show only the anyOf
                // partners the player already owns so the card stays focused
                // on this item's actual connections. If none are owned yet,
                // show a compact count pill instead of listing every option.
                Row(
                  children: [
                    Icon(
                      Icons.alt_route,
                      size: 13,
                      color: Colors.amber.withValues(alpha: 0.75),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Alternative Partners:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Colors.amber.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: s.anyOf.map((i) {
                    final isOwned = ownedLower.contains(i.toLowerCase());
                    return _SynergyChip(name: i, missing: !isOwned);
                  }).toList(),
                ),
              ],
            ],
            if (s.effectTokens.isNotEmpty &&
                !s.effect.toLowerCase().startsWith('one of the following') &&
                !s.effect.toLowerCase().startsWith('any of the following')) ...[
              const SizedBox(height: 8),
              // Tokenised effect text — item/gun names mentioned mid-sentence
              // are tappable, so a synergy that says "boosts Trick Gun's
              // reload" lets you jump straight to Trick Gun.
              RichLinkText(
                tokens: s.effectTokens,
                baseStyle: const TextStyle(fontSize: 13, height: 1.35),
              ),
            ] else if (s.effect.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                s.prettyEffect,
                style: const TextStyle(fontSize: 13, height: 1.35),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pill for a synergy component. If the referenced name resolves to a
/// real gun/item in our master data, tapping it opens its detail view
/// so users can quickly hop between synergistic pieces.
class _SynergyChip extends StatelessWidget {
  final String name;
  final bool missing;
  const _SynergyChip({required this.name, required this.missing});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<RunProvider>();
    // O(1) lookup via the indexed name maps. The chip used to scan
    // allGuns then allItems linearly per build — cheap individually but
    // multiplied by every component of every synergy on the screen, this
    // got real on heavy detail pages.
    final resolved = provider.entityByName(name);
    final gun = resolved.gun;
    final item = resolved.item;
    final resolvable = gun != null || item != null;

    final flair = AppTheme.flair;
    final filled = flair.chipFilled;
    final accent = filled
        ? Colors.amber.withValues(alpha: 0.4)
        : Colors.amber.withValues(alpha: 0.85);
    final mutedRule = Colors.white.withValues(alpha: 0.18);
    final bg = !filled
        ? null
        : (missing
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.amber.withValues(alpha: 0.15));
    final border = filled
        ? (missing ? Colors.white.withValues(alpha: 0.15) : accent)
        : null;

    final iconPath = gun?.icon ?? item?.icon ?? '';
    final quality = gun?.quality ?? item?.quality ?? '';
    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (resolvable && iconPath.isNotEmpty) ...[
          // Tiny ringless sprite — purely visual breadcrumb so the chip
          // reads as a real game item, not just a name. Mute it when
          // missing so the eye lands on the owned ones first.
          Opacity(
            opacity: missing ? 0.5 : 1.0,
            child: GameIcon(
              assetPath: iconPath,
              fallback: gun != null
                  ? Icons.gps_fixed
                  : Icons.inventory_2_outlined,
              quality: quality,
              size: 18,
              showRing: false,
            ),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          name,
          style: TextStyle(
            fontSize: 11.5,
            color: missing ? Colors.white54 : Colors.white,
          ),
        ),
        if (resolvable) ...[
          const SizedBox(width: 2),
          Icon(
            Icons.chevron_right,
            size: 14,
            color: missing ? Colors.white38 : Colors.amber,
          ),
        ],
      ],
    );

    final body = Container(
      padding: filled
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
          : const EdgeInsets.fromLTRB(2, 2, 2, 1),
      decoration: filled
          ? BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(flair.chipRadius),
              border: Border.all(color: border!),
            )
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: missing ? mutedRule : accent,
                  width: 1,
                ),
              ),
            ),
      child: label,
    );

    if (!resolvable) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(flair.chipRadius),
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ItemDetailScreen(gun: gun, item: item),
            ),
          );
        },
        // Long-press offers a peek preview without growing the nav
        // stack — useful when sanity-checking what a synergy component
        // *does* while mid-theorycraft, without losing the current
        // detail page.
        onLongPress: () {
          FocusManager.instance.primaryFocus?.unfocus();
          showEntityPeekSheet(context, gun: gun, item: item);
        },
        child: body,
      ),
    );
  }
}

/// Prominent destroy call-to-action for single-use / consumed-on-use
/// active items. Lives inline in the detail body (not the bottom bar)
/// so it reads as a flavoursome action, not a generic delete.
class _DestroyBanner extends StatelessWidget {
  final VoidCallback onDestroy;
  const _DestroyBanner({required this.onDestroy});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Card(
        elevation: 0,
        color: Colors.red.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5), width: 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'DESTROYED ON USE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'This active item is consumed when used. Tap Destroy to remove it from the run; the item detail will close automatically.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: onDestroy,
                  icon: const Icon(Icons.whatshot, size: 20),
                  label: const Text(
                    'Destroy',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

class _QuickJumpButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _QuickJumpButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? Colors.white54 : Colors.white12,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }
}

