import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../services/app_theme.dart';
import '../theme/tokens.dart';
import '../models/gun.dart';
import '../models/player.dart';
import '../widgets/game_icon.dart';
import '../services/haptics.dart';
import '../services/mp_session.dart';
import '../models/multiplayer_messages.dart';
import '../services/goop_talk_engine.dart';
import '../widgets/active_run/player_header.dart';
import '../widgets/active_run/player_page.dart';
import '../widgets/active_run/dice_roll.dart';
import '../widgets/active_run/emote_animations.dart';
import '../widgets/paradox/paradox_bar.dart';
import '../widgets/paradox/pause_overlay.dart';
import '../widgets/paradox/surprise_overlay.dart';
import '../widgets/state_widgets.dart';
import '../utils/responsive.dart';

part 'active_run/emote_button.dart';
part 'active_run/mp_handlers.dart';

class ActiveRunScreen extends StatefulWidget {
  final VoidCallback? onRequestBrowse;
  final void Function(PlayerSlot)? onPlayerChanged;
  const ActiveRunScreen({
    super.key,
    this.onRequestBrowse,
    this.onPlayerChanged,
  });

  @override
  State<ActiveRunScreen> createState() => _ActiveRunScreenState();
}

class _ActiveRunScreenState extends State<ActiveRunScreen>
    with _ActiveRunMpHandlers {
  @override
  late final PageController _page;
  @override
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _page = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mpSession = Provider.of<MpSession>(context, listen: false);
      _mpSession?.addListener(_onMpSessionChanged);
      _mpSession?.onDiceChallenge = _handleIncomingDiceChallenge;
      _mpSession?.onEmote = _handleIncomingEmote;
      _mpSession?.onGiftReceived = _handleIncomingGift;
    });
  }

  // ---- MP Emotes (kiss / slap) ------------------------------------------

  // ---- MP Gift received feedback ---------------------------------------

  @override
  void dispose() {
    _emoteTimer?.cancel();
    _emoteOverlayEntry?.remove();
    if (_mpSession != null) {
      if (_mpSession!.onDiceChallenge == _handleIncomingDiceChallenge) {
        _mpSession!.onDiceChallenge = null;
      }
      if (_mpSession!.onDiceCancel == _handleIncomingDiceCancel) {
        _mpSession!.onDiceCancel = null;
      }
      if (_mpSession!.onEmote == _handleIncomingEmote) {
        _mpSession!.onEmote = null;
      }
      if (_mpSession!.onGiftReceived == _handleIncomingGift) {
        _mpSession!.onGiftReceived = null;
      }
      _mpSession!.removeListener(_onMpSessionChanged);
    }
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final state = p.runState;
    final main = state.main;

    if (main.character == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: EmptyState(
          icon: Icons.inventory_2_outlined,
          message:
              'No run active. Pick a Gungeoneer to start tracking your inventory.',
          actionLabel: 'Start a Run',
          onAction: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    final session = context.watch<MpSession>();
    final isMpActive = session.isActive;
    final hasCoop = state.hasCoop;
    // Clamp current page synchronously to avoid rendering an
    // out-of-range page before the post-frame jump.
    final maxPage = hasCoop ? 1 : 0;
    if (_currentPage < 0 || _currentPage > maxPage) {
      _currentPage = _currentPage.clamp(0, maxPage);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _page.hasClients) {
          _page.jumpToPage(_currentPage);
        }
      });
    }

    // Pages: 0=P1, 1=P2 (only when coop).
    // In MP, "my" page is whichever slot belongs to me.
    final myMpPage = isMpActive ? (session.myRole == MpRole.main ? 0 : 1) : 0;
    final onMyMpPage = isMpActive ? _currentPage == myMpPage : true;
    // onCoop tracking removed — was unused

    void navigateTo(int i) => _page.animateToPage(
      i,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );

    // MP sessions (paradox + classic) get the pause + surprise overlay
    // treatment: pause desaturates/dims the whole screen, surprises
    // float on top. Solo runs render the plain column.
    final bool mpSession = isMpActive;
    Widget wrapOverlays(Widget w) =>
        mpSession ? PauseOverlay(child: SurpriseOverlayHost(child: w)) : w;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_add',
        tooltip:
            isMpActive && !onMyMpPage
                ? 'Add to ${session.peerNickname ?? 'Peer'}'
                : (_currentPage == 1 ? 'Add to P2' : 'Add to inventory'),
        onPressed: () {
          _showQuickAddBottomSheet(
            context,
            _currentPage == 1 ? PlayerSlot.coop : PlayerSlot.main,
          );
        },
        child: const Icon(Icons.add, size: 32),
      ),
      body: wrapOverlays(
        Column(
          children: [
            if (p.windgunnerCountdown > 0) _buildWindgunnerBanner(p),
            // In MP: the unified session bar replaces both player
            // switcher and old status bar — one chrome for classic +
            // paradox. In solo coop: plain PlayerSwitcher.
            if (isMpActive)
              SafeArea(
                bottom: false,
                child: ParadoxBar(currentPage: _currentPage, onPick: mpTabTap),
              )
            else if (hasCoop)
              PlayerSwitcher(
                currentPage: _currentPage,
                mainName: main.character!.name,
                coopName: state.coop!.character?.name ?? 'P2',
                onPick: navigateTo,
              ),
            Expanded(
              child: PageView(
                controller: _page,
                physics:
                    hasCoop
                        ? const PageScrollPhysics(
                          parent: ClampingScrollPhysics(),
                        )
                        : const NeverScrollableScrollPhysics(),
                onPageChanged: (i) {
                  setState(() => _currentPage = i);
                  final slot =
                      i == 0
                          ? PlayerSlot.main
                          : (i == 1 && hasCoop ? PlayerSlot.coop : null);
                  if (slot != null) {
                    widget.onPlayerChanged?.call(slot);
                  }
                },
                children: [
                  const PlayerPage(slot: PlayerSlot.main),
                  if (hasCoop) const PlayerPage(slot: PlayerSlot.coop),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickAddBottomSheet(BuildContext context, PlayerSlot slot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // Cap sheet width on tablets/desktop — a full-width sheet on a
      // 1600px window stretches rows absurdly.
      constraints: const BoxConstraints(maxWidth: 640),
      backgroundColor: AppTheme.flair.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(
          color: AppTheme.flair.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      builder: (_) => _QuickAddSheet(slot: slot),
    );
  }

  Widget _buildWindgunnerBanner(RunProvider p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.lg,
        vertical: Insets.sm,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF006064), // deep cyan
            Color(0xFF00E5FF), // neon cyan
            Color(0xFF006064), // deep cyan
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flash_on, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: GoopText(
              'WINDGUNNER STATE COMPASS ACTIVE (${p.windgunnerCountdown}s of Infinite Power)',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: FontSizes.labelSmall,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.8,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    offset: Offset(0, 1.5),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.flash_on, color: Colors.white, size: 16),
        ],
      ),
    );
  }
}

/// Quick-add sheet content. Owns its [TextEditingController], toast
/// notifier and timer as [State] fields so the framework disposes them
/// when the route's subtree unmounts — after the dismiss animation.
/// (Disposing in `showModalBottomSheet().whenComplete` races the exit
/// animation: the route future completes while the sheet is still
/// mounted, and the next rebuild touches a disposed controller.)
class _QuickAddSheet extends StatefulWidget {
  final PlayerSlot slot;
  const _QuickAddSheet({required this.slot});

  @override
  State<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<_QuickAddSheet> {
  late final RunProvider p;
  late final TextEditingController _controller;
  final ValueNotifier<String?> _addedToast = ValueNotifier<String?>(null);
  Timer? _addedToastTimer;
  String _query = '';

  /// Empty-query view = random discovery picks, reshuffled on every
  /// open so repeat visits surface different gear. Fixed for the
  /// sheet's lifetime so rows don't reshuffle while typing/browsing.
  late final List<dynamic> _discoveryPicks;

  @override
  void initState() {
    super.initState();
    p = Provider.of<RunProvider>(context, listen: false);
    _controller = TextEditingController();
    final discovery = <dynamic>[...p.allGuns, ...p.allItems]
      ..shuffle(math.Random());
    _discoveryPicks = discovery.take(60).toList();
  }

  @override
  void dispose() {
    _addedToastTimer?.cancel();
    _controller.dispose();
    _addedToast.dispose();
    super.dispose();
  }

  void _showToast(String msg, {int millis = 800}) {
    _addedToast.value = msg;
    _addedToastTimer?.cancel();
    _addedToastTimer = Timer(Duration(milliseconds: millis), () {
      _addedToast.value = null;
    });
  }

  void _addIt(dynamic item, bool isGun) {
    final name = item.name as String;
    Haptics.selection();
    final mpSession = context.read<MpSession>();
    final isMpPeerAdd = mpSession.isActive && mpSession.mySlot != widget.slot;
    if (isMpPeerAdd) {
      mpSession
          .sendAddToPeer(kind: isGun ? 'gun' : 'item', name: name)
          .then((_) {
            // Sheet may be dismissed before the Nearby send resolves —
            // writing _addedToast after dispose crashes.
            if (mounted) _showToast('Added: $name');
          })
          .catchError((Object _) {
            if (mounted) {
              _showToast('Could not send - check connection', millis: 2000);
            }
          });
    } else {
      if (isGun) {
        p.addGun(item, slot: widget.slot);
      } else {
        p.addItem(item, slot: widget.slot);
      }
      _showToast('Added: $name');
    }
    _controller.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.toLowerCase().trim();

    // Empty query → random discovery picks; typed query →
    // relevance-sorted full catalog.
    final List<dynamic> results;
    if (query.isEmpty) {
      results = _discoveryPicks;
    } else {
      final matchingGuns = p.allGuns.where(
        (g) => g.name.toLowerCase().contains(query),
      );
      final matchingItems = p.allItems.where(
        (i) => i.name.toLowerCase().contains(query),
      );
      final combinedResults = <dynamic>[...matchingGuns, ...matchingItems];
      combinedResults.sort((a, b) {
        final aName = a.name.toLowerCase();
        final bName = b.name.toLowerCase();
        final aStarts = aName.startsWith(query);
        final bStarts = bName.startsWith(query);
        if (aStarts && !bStarts) return -1;
        if (!aStarts && bStarts) return 1;
        return aName.compareTo(bName);
      });
      results = combinedResults;
    }

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            // Handlebar indicator
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header — drag handle + balanced top bar: centered
            // "Tap to add" hint between symmetric 48px edge slots
            // (leading spacer matches the close button's width so
            // the title stays optically centered at any text size).
            // Hairline divider separates chrome from the results.
            Row(
              children: [
                const SizedBox(width: 48),
                Expanded(
                  child: Center(
                    child: GoopText(
                      'Tap to add',
                      style: TextStyle(
                        fontSize: FontSizes.labelMedium,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.55),
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.65),
                    size: 38,
                  ),
                  tooltip: 'Close',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),

            Divider(
              height: 1,
              thickness: 1,
              color: Colors.white.withValues(alpha: 0.07),
            ),
            const SizedBox(height: 4),

            // Results — one-line rows; the whole row taps to add.
            Expanded(
              child: Stack(
                children: [
                  if (results.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: Insets.xxl),
                        child: GoopText(
                          'No matching guns or items found.',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: FontSizes.labelMedium,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      itemCount: results.length,
                      separatorBuilder:
                          (_, _) => Divider(
                            color: Colors.white.withValues(alpha: 0.05),
                            height: 1,
                          ),
                      itemBuilder: (lContext, index) {
                        final item = results[index];
                        final isGun = item is Gun;
                        final name = item.name;
                        final quality = item.quality;
                        final iconPath = item.icon;
                        final kindTag =
                            isGun
                                ? 'GUN'
                                : (item.isActive
                                    ? 'ACTIVE'
                                    : (item.isCompanion
                                        ? 'COMPANION'
                                        : 'PASSIVE'));
                        final kindColor =
                            isGun
                                ? Colors.amberAccent
                                : (item.isActive
                                    ? Colors.lightBlueAccent
                                    : (item.isCompanion
                                        ? Colors.purpleAccent
                                        : Colors.lightGreenAccent));

                        return AnimatedBuilder(
                          animation: p,
                          builder: (abContext, _) {
                            final activePlayer =
                                widget.slot == PlayerSlot.coop
                                    ? (p.runState.coop ?? Player())
                                    : p.runState.main;
                            final isOwned =
                                isGun
                                    ? activePlayer.guns.any(
                                      (g) => g.name == name,
                                    )
                                    : (name.toLowerCase() == 'junk'
                                        ? false
                                        : activePlayer.items.any(
                                          (i) => i.name == name,
                                        ));

                            return InkWell(
                              onTap: isOwned ? null : () => _addIt(item, isGun),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 9,
                                ),
                                child: Row(
                                  children: [
                                    GameIcon(
                                      assetPath: iconPath,
                                      size: 30,
                                      fallback:
                                          isGun
                                              ? Icons.gps_fixed
                                              : Icons.extension,
                                      quality: quality,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: GoopText(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: FontSizes.titleSmall,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GoopText(
                                      kindTag,
                                      style: TextStyle(
                                        color: kindColor.withValues(
                                          alpha: 0.85,
                                        ),
                                        fontSize: FontSizes.labelSmall,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    if (isOwned) ...[
                                      const SizedBox(width: 6),
                                      GoopText(
                                        'OWNED',
                                        style: TextStyle(
                                          color: Colors.greenAccent.withValues(
                                            alpha: 0.85,
                                          ),
                                          fontSize: FontSizes.labelSmall,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  // Brief "Added: [name]" toast — auto-dismisses
                  ValueListenableBuilder<String?>(
                    valueListenable: _addedToast,
                    builder: (_, msg, _) {
                      if (msg == null) return const SizedBox.shrink();
                      return Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: GoopText(
                              msg,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11 * Responsive.factor(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Search field — at the bottom, above keyboard
            TextField(
              controller: _controller,
              autofocus: true,
              style: TextStyle(
                color: Colors.white,
                fontSize: FontSizes.labelMedium,
              ),
              cursorColor: Colors.amberAccent,
              decoration: InputDecoration(
                hintText: 'Search items, guns...',
                hintStyle: TextStyle(
                  color: Colors.white30,
                  fontSize: FontSizes.labelMedium,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.white30,
                  size: 20,
                ),
                suffixIcon:
                    query.isNotEmpty
                        ? IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white54,
                            size: 18,
                          ),
                          tooltip: 'Clear search',
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                        )
                        : null,
                filled: true,
                fillColor: AppTheme.flair.card,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radii.sm),
                  borderSide: BorderSide(color: Colors.amberAccent, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radii.sm),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
              ),
              onChanged: (val) {
                setState(() => _query = val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
