import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/run_provider.dart';
import '../models/gun.dart';
import '../models/item.dart';
import '../models/player.dart';
import '../services/app_theme.dart';
import '../services/elemental_tagger.dart';
import '../services/goop_talk_engine.dart';
import '../widgets/wiki_sections.dart';
import '../widgets/item_detail/header.dart';
import '../widgets/item_detail/gun_stats.dart';
import '../widgets/item_detail/item_body.dart';
import '../widgets/item_detail/synergies_section.dart';
import '../widgets/item_detail/destroy_banner.dart';

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
  final _scrollCtrl = ScrollController();

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
    final wikiUrlEncoded = Uri.encodeComponent(name.replaceAll(' ', '_'));
    final wikiUrlString = 'https://enterthegungeon.wiki.gg/wiki/$wikiUrlEncoded';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        title: const SizedBox.shrink(),
      ),
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: AppTheme.flair.card,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.flair.primary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  ItemDetailHeader(
                    name: name,
                    subtitle: subtitle,
                    quality: quality,
                    quote: quote,
                    isGun: gun != null,
                    isActive: item?.isActive ?? false,
                    iconPath: gun?.icon ?? item?.icon ?? '',
                    chestColor: gun?.chestColorDisplay ?? item?.chestColorDisplay ?? '',
                    sellPrice: gun?.sellPrice ?? item?.sellPrice ?? '',
                    synergyCount: synergyStatuses.length,
                    curse: gun?.curse ?? item?.curse ?? 0.0,
                    coolness: gun?.coolness ?? item?.coolness ?? 0.0,
                    elements: gun != null
                        ? ElementalTagger.elementsOfGun(gun)
                        : ElementalTagger.elementsOfItem(item!),
                  ),
                  KeyedSubtree(
                    key: _statsKey,
                    child: gun != null
                        ? GunStats(gun: gun)
                        : ItemBody(item: item!, ownerSlot: ownerSlot),
                  ),
                ],
              ),
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
            child: SizedBox(
              key: _synergyKey,
              height: MediaQuery.of(context).size.height * 0.5,
              child: SingleChildScrollView(
                child: SynergiesSection(
                  statuses: synergyStatuses,
                  currentName: name,
                ),
              ),
            ),
          ),
          if (item != null && item.isDestroyedOnUse && isInRun)
            SliverToBoxAdapter(
              child: DestroyBanner(
                onDestroy: () {
                  final slot = ownerSlot ??
                      runProvider.ownerSlotOfItem(item.name) ??
                      PlayerSlot.main;
                  runProvider.removeItem(item, slot: slot);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: GoopText('${item.name} destroyed on use'),
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
                    label: const GoopText(
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
                      FocusManager.instance.primaryFocus?.unfocus();
                      Navigator.pop(context);
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
                    side: BorderSide(
                      color: AppTheme.flair.primary,
                      width: 1.5,
                    ),
                  ),
                  onPressed: () async {
                    try {
                      final uri = Uri.parse(wikiUrlString);
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } catch (_) {}
                  },
                  child: Icon(
                    Icons.open_in_browser_rounded,
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
                              content: GoopText('$name removed$who'),
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
                              content: GoopText('$name added$who'),
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
