import 'dart:async';
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

class _ActiveRunScreenState extends State<ActiveRunScreen> {
  late final PageController _page;
  int _currentPage = 0;
  MpSession? _mpSession;
  String? _lastShownError;

  // Emote overlay state — kiss/slap animations shown via root Overlay.
  Timer? _emoteTimer;
  OverlayEntry? _emoteOverlayEntry;

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

  void _handleIncomingDiceChallenge(String challengerName) {
    if (!mounted) return;
    _mpSession?.onDiceCancel = _handleIncomingDiceCancel;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      routeSettings: const RouteSettings(name: '__dice_challenge'),
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppTheme.flair.card,
            title: const GoopText(
              '\u{1F3B2} Gunfortuna Challenge! \u{1F3B2}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFFFFD54F),
                letterSpacing: 1.0,
              ),
            ),
            content: GoopText(
              '$challengerName challenges you to a Gunfortuna Dice Roll! Do you accept the challenge?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _mpSession?.onDiceCancel = null;
                  Navigator.pop(ctx);
                  _mpSession?.sendDiceDecline();
                },
                child: const GoopText(
                  'DECLINE',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
              FilledButton(
                onPressed: () {
                  _mpSession?.onDiceCancel = null;
                  Navigator.pop(ctx);
                  _mpSession?.sendDiceAccept();
                  showDiceRollDialog(context, isChallenged: true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD54F),
                  foregroundColor: Colors.black,
                ),
                child: const GoopText(
                  'ACCEPT',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
    );
  }

  void _handleIncomingDiceCancel() {
    if (!mounted) return;
    // Pop ONLY a dice-related route — blindly popping the top route
    // could close an unrelated sheet while leaving the dice dialog
    // stuck open (the reported can't-close bug).
    final navigator = Navigator.of(context);
    navigator.popUntil((route) {
      final name = route.settings.name;
      return name == null || !name.startsWith('__dice');
    });
  }

  // ---- MP Emotes (kiss / slap) ------------------------------------------

  /// Tab tap handler for MP — if the user taps their own tab while
  /// already viewing it, open the emote menu. Otherwise navigate.
  void mpTabTap(int i) {
    final session = _mpSession;
    if (session == null) return;
    final myMpPage = session.myRole == MpRole.main ? 0 : 1;
    if (i == myMpPage && _currentPage == myMpPage) {
      _showEmoteMenu();
    } else {
      if (!mounted || !_page.hasClients) return;
      _page.animateToPage(
        i,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    }
  }

  void _showEmoteMenu() {
    final session = _mpSession;
    if (session == null || !session.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: GoopText('Not connected: can\'t send emote'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Haptics.selection();
    final peerName = session.peerNickname ?? 'peer';
    final flair = AppTheme.flair;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: flair.card,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder:
          (ctx) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                GoopText(
                  'Send to $peerName',
                  style: TextStyle(
                    fontSize: FontSizes.bodyMedium,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _EmoteButton(
                      icon: Icons.favorite,
                      label: 'Kiss',
                      color: Colors.pinkAccent,
                      onTap: () {
                        Navigator.pop(ctx);
                        session.sendEmote('kiss');
                        Haptics.light();
                      },
                    ),
                    _EmoteButton(
                      icon: Icons.sentiment_very_dissatisfied,
                      label: 'Slap',
                      color: Colors.orangeAccent,
                      onTap: () {
                        Navigator.pop(ctx);
                        session.sendEmote('slap');
                        Haptics.heavy();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 8),
                // Quick session teardown
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmEndSession();
                  },
                  icon: Icon(
                    Icons.logout_rounded,
                    size: 16,
                    color: MpColors.danger.withValues(alpha: 0.7),
                  ),
                  label: GoopText(
                    'End MP Session',
                    style: TextStyle(
                      fontSize: FontSizes.labelMedium,
                      fontWeight: FontWeight.w700,
                      color: MpColors.danger.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _confirmEndSession() {
    Haptics.selection();
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppTheme.flair.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radii.lg),
              side: BorderSide(
                color: MpColors.danger.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            icon: const Icon(
              Icons.logout_rounded,
              size: 32,
              color: MpColors.danger,
            ),
            title: const GoopText(
              'End Multiplayer Session?',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            content: GoopText(
              'This will disconnect from your partner. Your run data is preserved.',
              style: TextStyle(
                fontSize: 12.5 * Responsive.factor(context),
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const GoopText(
                  'CANCEL',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: MpColors.danger,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _mpSession?.cancel();
                },
                child: const GoopText(
                  'END SESSION',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
    );
  }

  void _handleIncomingEmote(String from, String action) {
    if (!mounted) return;
    // Unknown actions from future versions are ignored gracefully.
    final duration = switch (action) {
      'kiss' => const Duration(seconds: 6),
      'slap' => const Duration(seconds: 2),
      _ => null,
    };
    if (duration == null) return;
    Haptics.light();
    // Cancel any previous emote timer + overlay before showing a new one.
    _emoteTimer?.cancel();
    _emoteOverlayEntry?.remove();
    final entry = OverlayEntry(
      builder:
          (_) => IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child:
                  action == 'slap'
                      ? SlapAnimation(from: from)
                      : KissAnimation(from: from),
            ),
          ),
    );
    _emoteOverlayEntry = entry;
    Overlay.of(context).insert(entry);
    _emoteTimer = Timer(duration, () {
      _emoteTimer = null;
      if (!mounted) return;
      entry.remove();
      _emoteOverlayEntry = null;
    });
  }

  // ---- MP Gift received feedback ---------------------------------------

  void _handleIncomingGift(String kind, String name) {
    if (!mounted) return;
    Haptics.success();
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final icon = kind == 'gun' ? Icons.gps_fixed : Icons.inventory_2_rounded;
    final label = kind == 'gun' ? 'Received gun' : 'Received item';
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: MpColors.connected, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: GoopText(
                '$label: $name',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.flair.card,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radii.md),
          side: const BorderSide(color: MpColors.connected, width: 1.5),
        ),
      ),
    );
  }

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

  void _onMpSessionChanged() {
    if (!mounted || _mpSession == null) return;
    final phase = _mpSession!.phase;
    final error = _mpSession!.error;

    // Reset error tracking when leaving the error phase so the
    // same error can be re-shown after a retry.
    if (phase != MpPhase.error) {
      _lastShownError = null;
    }

    if (phase == MpPhase.error && error != null && error != _lastShownError) {
      _lastShownError = error;
      _showErrorDialog(error);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.redAccent),
                SizedBox(width: 12),
                GoopText('Connection Error'),
              ],
            ),
            content: GoopText(message),
            actions: [
              TextButton(
                onPressed: () {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: GoopText('Run saved'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const GoopText('Save Session'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const GoopText('Dismiss'),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const GoopText('Retry Reconnect'),
                onPressed: () {
                  Navigator.pop(context);
                  _mpSession?.reconnect();
                },
              ),
            ],
          ),
    );
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
    final p = Provider.of<RunProvider>(context, listen: false);
    final focusNode = FocusNode();
    final quickAddController = TextEditingController(text: _quickQuery);
    final addedToast = ValueNotifier<String?>(null);
    Timer? addedToastTimer;

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
      builder: (bContext) {
        return StatefulBuilder(
          builder: (sContext, setModalState) {
            final query = _quickQuery.toLowerCase().trim();

            // Smart relevance matching & sorting:
            // 1. Starts with query (highest priority)
            // 2. Contains query (medium priority)
            // 3. Quality score tie-breaker
            final matchingGuns =
                p.allGuns.where((g) {
                  return g.name.toLowerCase().contains(query);
                }).toList();

            final matchingItems =
                p.allItems.where((i) {
                  return i.name.toLowerCase().contains(query);
                }).toList();

            // Combined and prioritized
            final List<dynamic> combinedResults = [
              ...matchingGuns,
              ...matchingItems,
            ];
            combinedResults.sort((a, b) {
              final aName = a.name.toLowerCase();
              final bName = b.name.toLowerCase();
              final aStarts = aName.startsWith(query);
              final bStarts = bName.startsWith(query);
              if (aStarts && !bStarts) return -1;
              if (!aStarts && bStarts) return 1;
              return aName.compareTo(bName);
            });

            final results = combinedResults;

            return AnimatedPadding(
              duration: const Duration(milliseconds: 100),
              padding: MediaQuery.of(sContext).viewInsets,
              child: Container(
                height: MediaQuery.of(sContext).size.height * 0.6,
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

                    // Header — compact: centered "Tap to add" instruction
                    // on the same row as a 25%-larger close icon. The old
                    // title + "ADVANCED LIBRARY" link are gone (v3 cleanup).
                    Row(
                      children: [
                        const SizedBox(width: 40),
                        const Expanded(
                          child: Center(
                            child: GoopText(
                              'Tap to add',
                              style: TextStyle(
                                fontSize: FontSizes.labelMedium,
                                fontWeight: FontWeight.w700,
                                color: Colors.white54,
                                fontStyle: FontStyle.italic,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white54,
                            size: 25,
                          ),
                          tooltip: 'Close',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          onPressed: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.pop(bContext);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Results — one-line rows; the whole row taps to add.
                    Expanded(
                      child: Stack(
                        children: [
                          if (results.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: Insets.xxl,
                                ),
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
                                  (_, __) => Divider(
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

                                void addIt() {
                                  Haptics.selection();
                                  final mpSession = context.read<MpSession>();
                                  final isMpPeerAdd =
                                      mpSession.isActive &&
                                      mpSession.mySlot != slot;
                                  if (isMpPeerAdd) {
                                    mpSession
                                        .sendAddToPeer(
                                          kind: isGun ? 'gun' : 'item',
                                          name: name,
                                        )
                                        .then((_) {
                                          addedToast.value = 'Added: $name';
                                          addedToastTimer?.cancel();
                                          addedToastTimer = Timer(
                                            const Duration(milliseconds: 800),
                                            () => addedToast.value = null,
                                          );
                                        })
                                        .catchError((Object _) {
                                          addedToast.value =
                                              'Could not send - check connection';
                                          addedToastTimer?.cancel();
                                          addedToastTimer = Timer(
                                            const Duration(milliseconds: 2000),
                                            () => addedToast.value = null,
                                          );
                                        });
                                  } else {
                                    if (isGun) {
                                      p.addGun(item, slot: slot);
                                    } else {
                                      p.addItem(item, slot: slot);
                                    }
                                    addedToast.value = 'Added: $name';
                                    addedToastTimer?.cancel();
                                    addedToastTimer = Timer(
                                      const Duration(milliseconds: 800),
                                      () => addedToast.value = null,
                                    );
                                  }
                                  quickAddController.clear();
                                  setModalState(() {
                                    _quickQuery = '';
                                  });
                                }

                                return AnimatedBuilder(
                                  animation: p,
                                  builder: (abContext, _) {
                                    final activePlayer =
                                        slot == PlayerSlot.coop
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
                                      onTap: isOwned ? null : addIt,
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
                                                  fontSize:
                                                      FontSizes.titleSmall,
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
                                                  color: Colors.greenAccent
                                                      .withValues(alpha: 0.85),
                                                  fontSize:
                                                      FontSizes.labelSmall,
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
                            valueListenable: addedToast,
                            builder: (_, msg, __) {
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
                                      color: Colors.green.withValues(
                                        alpha: 0.9,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: GoopText(
                                      msg,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize:
                                            11 * Responsive.factor(context),
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
                      controller: quickAddController,
                      autofocus: true,
                      focusNode: focusNode,
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
                                    quickAddController.clear();
                                    setModalState(() {
                                      _quickQuery = '';
                                    });
                                  },
                                )
                                : null,
                        filled: true,
                        fillColor: AppTheme.flair.card,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radii.sm),
                          borderSide: const BorderSide(
                            color: Colors.amberAccent,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radii.sm),
                          borderSide: const BorderSide(color: Colors.white10),
                        ),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          _quickQuery = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      focusNode.dispose();
      quickAddController.dispose();
      addedToastTimer?.cancel();
      addedToast.dispose();
    });
  }

  String _quickQuery = '';

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

/// Circular icon button used in the emote menu.
/// Scales down on press for tactile feedback.
class _EmoteButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _EmoteButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_EmoteButton> createState() => _EmoteButtonState();
}

class _EmoteButtonState extends State<_EmoteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp: (_) {
        _scaleCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleCtrl,
        builder: (context, child) {
          final scale = 1.0 - _scaleCtrl.value * 0.12;
          return Transform.scale(scale: scale, child: child);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.12),
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.08),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(widget.icon, size: 32, color: widget.color),
            ),
            const SizedBox(height: 8),
            GoopText(
              widget.label,
              style: TextStyle(
                fontSize: 13 * Responsive.factor(context),
                fontWeight: FontWeight.w700,
                color: widget.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
