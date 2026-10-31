import '../theme/tokens.dart';

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
import '../services/haptics.dart';
import '../widgets/wiki_sections.dart';
import '../widgets/item_detail/description_blocks.dart';
import '../widgets/item_detail/header.dart';
import '../widgets/item_detail/gun_stats.dart';
import '../utils/responsive.dart';
import '../widgets/item_detail/item_body.dart';
import '../widgets/item_detail/synergies_section.dart';
import '../widgets/item_detail/gun_notes_tab.dart';
import '../widgets/item_detail/gun_synergies_tab.dart';
import '../widgets/item_detail/destroy_banner.dart';
import '../widgets/skeuo/skeuo_tokens.dart';

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
    final sf = Responsive.factor(context);
    final actionBtnSize = 68 * sf;
    final name = gun?.name ?? item!.name;
    final quality = gun?.quality ?? item!.quality;
    final subtitle = gun != null ? gun.type : item!.type;
    final quote = gun?.quote ?? item!.quote;

    final ownedList = runProvider.runState.allItemNames;
    final owned = ownedList.map((n) => n.toLowerCase()).toSet();
    final synergyStatuses =
        runProvider
            .getSynergiesFor(name)
            .map(
              (s) => SynergyStatus(
                synergy: s,
                missing: s.missingFor(owned),
                active: s.matchesItems(ownedList),
              ),
            )
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
      final owner =
          gun != null
              ? runProvider.ownerSlotOfGun(gun.name)
              : runProvider.ownerSlotOfItem(item!.name);
      isInRun = owner == ownerSlot;
    } else {
      isInRun =
          gun != null
              ? runProvider.isGunInRun(gun.name)
              : runProvider.isItemInRun(item!.name);
    }

    final wiki = gun?.wiki ?? item!.wiki;
    final ammonomiconEntry = gun?.ammonomiconEntry ?? item!.ammonomiconEntry;
    final referrers = runProvider.backRefs.referrersFor(name);
    final wikiUrlEncoded = Uri.encodeComponent(name.replaceAll(' ', '_'));
    final wikiUrlString =
        'https://enterthegungeon.wiki.gg/wiki/$wikiUrlEncoded';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        title: const SizedBox.shrink(),
      ),
      // Cap content width — detail cards stretch absurdly on
      // tablets/desktop without a constraint. SizedBox pins BOTH
      // axes so the scrollable can't collapse inside loose
      // Center/ConstrainedBox constraints.
      body: LayoutBuilder(
        builder:
            (context, cons) => Center(
              child: SizedBox(
                width: cons.maxWidth > 760 ? 760 : cons.maxWidth,
                height: cons.maxHeight,
                child: CustomScrollView(
                  controller: _scrollCtrl,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        decoration: BoxDecoration(
                          color: AppTheme.flair.card,
                          borderRadius: BorderRadius.all(Radii.lg),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.flair.primary.withValues(
                                alpha: 0.08,
                              ),
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
                              effect: gun?.notes ?? '',
                              isGun: gun != null,
                              isActive: item?.isActive ?? false,
                              iconPath: gun?.icon ?? item?.icon ?? '',
                              chestColor:
                                  gun?.chestColorDisplay ??
                                  item?.chestColorDisplay ??
                                  '',
                              sellPrice:
                                  gun?.sellPrice ?? item?.sellPrice ?? '',
                              synergyCount: synergyStatuses.length,
                              curse: gun?.curse ?? item?.curse ?? 0.0,
                              coolness: gun?.coolness ?? item?.coolness ?? 0.0,
                              elements:
                                  gun != null
                                      ? ElementalTagger.elementsOfGun(gun)
                                      : ElementalTagger.elementsOfItem(item!),
                            ),
                            if (gun == null)
                              KeyedSubtree(
                                key: _statsKey,
                                child: ItemBody(
                                  item: item!,
                                  ownerSlot: ownerSlot,
                                ),
                              )
                            else
                              _ElementTagRow(
                                elements: ElementalTagger.elementsOfGun(gun),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // ---- Flat single-scroll layout (no tabs): STATS →
                    // SYNERGIES → NOTES/wiki last. Gun path renders everything;
                    // item path keeps its existing flat body + synergy section.
                    if (gun != null)
                      SliverToBoxAdapter(
                        child: KeyedSubtree(
                          key: _statsKey,
                          child: GunStats(gun: gun),
                        ),
                      ),
                    if (gun != null)
                      SliverToBoxAdapter(
                        child: SizedBox(
                          key: _synergyKey,
                          child: GunSynergiesTab(
                            statuses: synergyStatuses,
                            currentName: name,
                          ),
                        ),
                      ),
                    if (gun != null)
                      SliverToBoxAdapter(
                        child: GunNotesTab(
                          gun: gun,
                          elements: ElementalTagger.elementsOfGun(gun),
                        ),
                      ),
                    if (item != null)
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
                    // ---- Ammonomicon flavour entry + wiki rich content
                    // (Effects, Interactions, Notes, Tips) + back-refs.
                    // Same three blocks serve guns and items — the data
                    // is 100% populated on both sides.
                    if (ammonomiconEntry.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: AmmonomiconCard(text: ammonomiconEntry),
                        ),
                      ),
                    if (wiki.hasAny) ...[
                      SliverToBoxAdapter(
                        child: SizedBox(key: _wikiKey, height: 0),
                      ),
                      ...buildWikiSlivers(wiki),
                    ],
                    if (referrers.isNotEmpty)
                      SliverToBoxAdapter(
                        child: ReferencedBySection(referrers: referrers),
                      ),
                    if (item != null && item.isDestroyedOnUse && isInRun)
                      SliverToBoxAdapter(
                        child: DestroyBanner(
                          onDestroy: () {
                            final slot =
                                ownerSlot ??
                                runProvider.ownerSlotOfItem(item.name) ??
                                PlayerSlot.main;
                            runProvider.removeItem(item, slot: slot);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: GoopText(
                                  '${item.name} destroyed on use',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
              ),
            ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
          // Align+heightFactor centers horizontally AND shrink-wraps
          // vertically — bare Center expands to eat the body's height.
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: 1.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
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
                      height: actionBtnSize,
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.arrow_back, size: 24 * sf),
                        label: GoopText(
                          'Back',
                          style: TextStyle(
                            fontSize: FontSizes.titleSmall * sf,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radii.lg),
                          ),
                          side: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.6),
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
                    width: actionBtnSize,
                    height: actionBtnSize,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radii.lg),
                        ),
                        side: BorderSide(
                          color: AppTheme.flair.primary,
                          width: 1.5,
                        ),
                      ),
                      onPressed: () async {
                        try {
                          final uri = Uri.parse(wikiUrlString);
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (e) {
                          debugPrint('[ItemDetail] url launch error: $e');
                        }
                      },
                      child: Icon(
                        Icons.open_in_browser_rounded,
                        size: 26 * sf,
                        color: AppTheme.flair.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Compact action square on the right (trash if in run, + if not)
                  SizedBox(
                    width: actionBtnSize,
                    height: actionBtnSize,
                    child:
                        isInRun
                            ? OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(Radii.lg),
                                ),
                                side: BorderSide(
                                  color: Skeuo.inkIf(Colors.redAccent),
                                  width: 1.5,
                                ),
                                backgroundColor: Skeuo.inkIf(
                                  Colors.red,
                                ).withValues(alpha: 0.08),
                              ),
                              onPressed: () {
                                Haptics.selection();
                                // Remove from the owning slot (or the resolved
                                // owner if we don't know which it is).
                                final slot =
                                    ownerSlot ??
                                    (gun != null
                                        ? runProvider.ownerSlotOfGun(gun.name)
                                        : runProvider.ownerSlotOfItem(
                                          item!.name,
                                        )) ??
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
                                    duration: const Duration(
                                      milliseconds: 1200,
                                    ),
                                  ),
                                );
                              },
                              child: Icon(
                                Icons.delete_outline,
                                size: 28,
                                color: Skeuo.inkIf(Colors.redAccent),
                              ),
                            )
                            : FilledButton(
                              style: FilledButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(Radii.lg),
                                ),
                              ),
                              onPressed: () {
                                Haptics.selection();
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
                                    duration: const Duration(
                                      milliseconds: 1200,
                                    ),
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
        ),
      ),
    );
  }
}

/// Element tags rendered inline under the header card — flat rework
class _ElementTagRow extends StatelessWidget {
  final Set<ElementKind> elements;
  const _ElementTagRow({required this.elements});

  @override
  Widget build(BuildContext context) {
    if (elements.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final e in elements)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: e.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: e.color.withValues(alpha: 0.5)),
              ),
              child: GoopText(
                e.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: e.color,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
