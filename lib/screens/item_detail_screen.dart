import '../theme/tokens.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/run_provider.dart';
import '../models/gun.dart';
import '../models/item.dart';
import '../models/player.dart';
import '../services/app_theme.dart';
import '../services/codex_prefs.dart';
import '../services/elemental_tagger.dart';
import '../services/goop_talk_engine.dart';
import '../services/haptics.dart';
import '../widgets/wiki_sections.dart';
import '../widgets/item_detail/description_blocks.dart';
import '../widgets/item_detail/header.dart';
import '../widgets/item_detail/gun_stats.dart';
import '../utils/responsive.dart';
import '../widgets/item_detail/item_body.dart';
import '../widgets/item_detail/gun_notes_tab.dart';
import '../widgets/item_detail/gun_synergies_tab.dart';
import '../widgets/item_detail/entity_synergies_view.dart';
import '../widgets/item_detail/leb_view_scope.dart';
import '../widgets/item_detail/destroy_banner.dart';
import '../widgets/scale_button.dart';

class ItemDetailScreen extends StatefulWidget {
  final Gun? gun;
  final Item? item;

  /// When this detail screen was opened from a specific player's tile,
  /// remove/add operations route to that slot. If null, falls back to
  /// whichever slot currently owns this entry (main takes precedence).
  final PlayerSlot? ownerSlot;

  /// LEB simulation override for the synergy section:
  /// * `true` — offer the LEB simulated page (catalog/browse/codex).
  /// * `false` — real inventory views only (active-run surfaces).
  /// * `null` — resolve from context: ownerSlot present → false,
  ///   otherwise the pref selected by [lebPref] (global by default,
  ///   browse-local for details pushed from the Browse tab).
  final bool? lebView;

  /// Which persisted LEB toggle feeds the fallback resolution when
  /// [lebView] is null. Ignored when [lebView] is set or ownerSlot
  /// forces real state.
  final LebPrefSource lebPref;

  const ItemDetailScreen({
    super.key,
    this.gun,
    this.item,
    this.ownerSlot,
    this.lebView,
    this.lebPref = LebPrefSource.global,
  }) : assert(gun != null || item != null);

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final _scrollCtrl = ScrollController();
  // Detail bottom tabs — -1 = all closed (default), else index
  // into the SYNERGIES/NOTES spec list. Single-open accordion.
  int _detailTab = -1;

  @override
  void initState() {
    super.initState();
    // Codex favorites shown in the header — idempotent load so the
    // bookmark reflects persisted state even when this screen is
    // opened outside the Ammonomicon (browse, loadout, etc.).
    CodexPrefs.ensureLoaded();
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
    final sf = Responsive.factor(context);
    final actionBtnSize = 68 * sf;
    final name = gun?.name ?? item!.name;
    final quality = gun?.quality ?? item!.quality;
    final subtitle = gun != null ? gun.type : item!.type;

    final owned = runProvider.ownedNamesLowerCombined;
    // Synergies evaluate per-player in co-op — a piece split across
    // P1+P2 does not activate. `active` checks each player's own
    // inventory; `missing`/grouping stay on the combined set so rows
    // still show team progress.
    final runMain = runProvider.ownedNamesLowerMain;
    final runCoop =
        runProvider.runState.coop == null
            ? null
            : runProvider.ownedNamesLowerCoop;
    final synergyStatuses =
        runProvider
            .getSynergiesFor(name)
            .map(
              (s) => SynergyStatus(
                synergy: s,
                missing: s.missingFor(owned),
                active:
                    s.matchesOwnedSet(runMain) ||
                    (runCoop != null && s.matchesOwnedSet(runCoop)),
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
      // Resolved LEB mode — explicit param wins, then run-context
      // (ownerSlot) forces real state, else the global pref. Watched
      // so flipping the setting live-swaps the synergy view.
      body: ValueListenableBuilder<VisualPrefs>(
        valueListenable: VisualPrefs.notifier,
        builder: (context, prefs, _) {
          // Run-context views show the LEB simulation only when that
          // slot actually holds Lich's Eye Bullets AND the user hasn't
          // toggled the view off — auto-enable flips the pref on at
          // acquisition, the toggle stays live for manual control.
          final lebView =
              widget.lebView ??
              (ownerSlot != null
                  ? runProvider.playerHasLeb(ownerSlot) &&
                      prefs.showLichEyeBulletsSynergies
                  : widget.lebPref == LebPrefSource.browse
                  ? prefs.browseShowLichEyeBullets
                  : prefs.showLichEyeBulletsSynergies);
          return LebViewScope(
            lebView: lebView,
            child: LayoutBuilder(
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
                                    // Guns show notes; items show their mechanical
                                    // effect line (was empty — all 270 items have
                                    // one and it was parsed but never rendered).
                                    effect: gun?.notes ?? item?.effect ?? '',
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
                                    coolness:
                                        gun?.coolness ?? item?.coolness ?? 0.0,
                                    elements:
                                        gun != null
                                            ? ElementalTagger.elementsOfGun(gun)
                                            : ElementalTagger.elementsOfItem(
                                              item!,
                                            ),
                                  ),
                                  if (gun == null)
                                    ItemBody(
                                      item: item!,
                                      ownerSlot: ownerSlot,
                                    )
                                  else
                                    GunStats(gun: gun),
                                ],
                              ),
                            ),
                          ),
                          // ---- Flat single-scroll layout (no tabs): SYNERGIES
                          // → NOTES/wiki last. Both entity types render their
                          // body inside the header card (U-051) — items get
                          // ItemBody, guns get GunStats + special panels.
                          // Collapsible detail tabs — all closed by default so
                          // the page stays compact; tapping a header expands
                          // that section (tap again to close). SYNERGIES
                          // carries the synergy list (LEB pager for guns),
                          // NOTES carries notes + ammonomicon + wiki sections.
                          if (gun != null)
                            SliverToBoxAdapter(
                              child: _DetailTabs(
                                openIndex: _detailTab,
                                onToggle:
                                    (i) => setState(
                                      () =>
                                          _detailTab = _detailTab == i ? -1 : i,
                                    ),
                                tabs: [
                                  _DetailTabSpec(
                                    label: 'SYNERGIES',
                                    count:
                                        runProvider
                                            .getSynergiesFor(name)
                                            .length,
                                    child: GunSynergiesTab(
                                      currentName: name,
                                      lebView: lebView,
                                      lebSource: widget.lebPref,
                                      showLebToggle: true,
                                    ),
                                  ),
                                  _DetailTabSpec(
                                    label: 'NOTES',
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        GunNotesTab(
                                          gun: gun,
                                          elements:
                                              ElementalTagger.elementsOfGun(
                                                gun,
                                              ),
                                        ),
                                        if (ammonomiconEntry.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              16,
                                              12,
                                              16,
                                              4,
                                            ),
                                            child: AmmonomiconCard(
                                              text: ammonomiconEntry,
                                            ),
                                          ),
                                        ...buildWikiSections(wiki),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Items get the same two-tab treatment as guns
                          // (no pager, no LEB simulation — LEB only affects
                          // guns in-game). SYNERGIES lists the grouped
                          // COMPLETE/PARTIAL/LOCKED rows; NOTES carries the
                          // Ammonomicon flavour entry + wiki sections.
                          if (item != null)
                            SliverToBoxAdapter(
                              child: _DetailTabs(
                                openIndex: _detailTab,
                                onToggle:
                                    (i) => setState(
                                      () =>
                                          _detailTab = _detailTab == i ? -1 : i,
                                    ),
                                tabs: [
                                  _DetailTabSpec(
                                    label: 'SYNERGIES',
                                    count: synergyStatuses.length,
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: EntitySynergiesView(
                                        statuses: synergyStatuses,
                                        currentName: name,
                                        ownedLower: owned,
                                      ),
                                    ),
                                  ),
                                  _DetailTabSpec(
                                    label: 'NOTES',
                                    child:
                                        ammonomiconEntry.isEmpty &&
                                                !wiki.hasAny
                                            ? const _EmptyTabNote(
                                              'No notes for this entry yet.',
                                            )
                                            : Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (ammonomiconEntry
                                                    .isNotEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets
                                                            .fromLTRB(
                                                          16,
                                                          12,
                                                          16,
                                                          4,
                                                        ),
                                                    child: AmmonomiconCard(
                                                      text: ammonomiconEntry,
                                                    ),
                                                  ),
                                                ...buildWikiSections(wiki),
                                              ],
                                            ),
                                  ),
                                ],
                              ),
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
                                      duration: const Duration(
                                        milliseconds: 1400,
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 120),
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
          );
        },
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
                                  color: Colors.redAccent,
                                  width: 1.5,
                                ),
                                backgroundColor: Colors.red.withValues(
                                  alpha: 0.08,
                                ),
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
                                color: Colors.redAccent,
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

// ---------------------------------------------------------------------------
// Collapsible detail tabs (SYNERGIES / NOTES)
// ---------------------------------------------------------------------------

class _DetailTabSpec {
  final String label;
  final int? count;
  final Widget child;
  const _DetailTabSpec({required this.label, required this.child, this.count});
}

/// Accordion of detail sections — all headers visible, exactly one
/// (or none) expanded. Closed tabs render no content, keeping the
/// page short until the user asks for it.
class _DetailTabs extends StatelessWidget {
  final int openIndex;
  final ValueChanged<int> onToggle;
  final List<_DetailTabSpec> tabs;
  const _DetailTabs({
    required this.openIndex,
    required this.onToggle,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < tabs.length; i++) ...[
          _DetailTabHeader(
            spec: tabs[i],
            open: openIndex == i,
            onTap: () => onToggle(i),
          ),
          if (openIndex == i) tabs[i].child,
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _DetailTabHeader extends StatelessWidget {
  final _DetailTabSpec spec;
  final bool open;
  final VoidCallback onTap;
  const _DetailTabHeader({
    required this.spec,
    required this.open,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    return ScaleButton(
      enableHaptics: false,
      onTap: () {
        Haptics.selection();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12 * sf),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: Row(
          children: [
            GoopText(
              spec.label,
              style: TextStyle(
                fontSize: 12 * sf,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: Colors.white.withValues(alpha: open ? 0.9 : 0.55),
              ),
            ),
            if (spec.count != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: GoopText(
                  '${spec.count}',
                  style: TextStyle(
                    fontSize: 10 * sf,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
            const Spacer(),
            AnimatedRotation(
              turns: open ? 0.5 : 0,
              duration: const Duration(milliseconds: 180),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20 * sf,
                color: Colors.white.withValues(alpha: open ? 0.8 : 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTabNote extends StatelessWidget {
  final String text;
  const _EmptyTabNote(this.text);

  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 4, 18, 18 * sf),
      child: GoopText(
        text,
        style: TextStyle(
          fontSize: 12.5 * sf,
          fontStyle: FontStyle.italic,
          color: Colors.white.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
