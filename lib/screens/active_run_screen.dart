import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../models/gun.dart';
import '../models/player.dart';
import '../widgets/game_icon.dart';
import '../services/haptics.dart';
import 'browse_screen.dart';
import '../services/multiplayer_session.dart';
import '../models/multiplayer_messages.dart';
import '../utils/fast_route.dart';
import '../services/goop_talk_engine.dart';
import '../widgets/active_run/player_header.dart';
import '../widgets/active_run/player_page.dart';
import '../widgets/active_run/dice_roll.dart';

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
  MultiplayerSession? _mpSession;
  String? _lastShownError;

  @override
  void initState() {
    super.initState();
    _page = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mpSession = Provider.of<MultiplayerSession>(context, listen: false);
      _mpSession?.addListener(_onMpSessionChanged);
      _mpSession?.onDiceChallenge = _handleIncomingDiceChallenge;
    });
  }

  void _handleIncomingDiceChallenge(String challengerName) {
    if (!mounted) return;
    _mpSession?.onDiceCancel = _handleIncomingDiceCancel;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1B1816),
            title: const GoopText(
              '≡ƒÄ▓ Gunfortuna Challenge! ≡ƒÄ▓',
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
              ElevatedButton(
                onPressed: () {
                  _mpSession?.onDiceCancel = null;
                  Navigator.pop(ctx);
                  _mpSession?.sendDiceAccept();
                  showDiceRollDialog(context, isChallenged: true);
                },
                style: ElevatedButton.styleFrom(
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
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    if (_mpSession != null) {
      if (_mpSession!.onDiceChallenge == _handleIncomingDiceChallenge) {
        _mpSession!.onDiceChallenge = null;
      }
      if (_mpSession!.onDiceCancel == _handleIncomingDiceCancel) {
        _mpSession!.onDiceCancel = null;
      }
      _mpSession!.removeListener(_onMpSessionChanged);
    }
    _page.dispose();
    super.dispose();
  }

  void _onMpSessionChanged() {
    if (!mounted || _mpSession == null) return;
    final status = _mpSession!.status;
    final error = _mpSession!.error;

    if (status == MpStatus.error && error != null && error != _lastShownError) {
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
                onPressed: () async {
                  await _mpSession?.saveCurrentSession();
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
                  if (_mpSession?.canReconnect == true) {
                    _mpSession?.reconnect();
                  }
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
      return const Scaffold(
        body: Center(child: GoopText('No inventory loaded')),
      );
    }

    final session = context.watch<MultiplayerSession>();
    final isMpActive = session.isActive;
    final hasCoop = state.hasCoop;
    // Snap back if current page no longer exists (coop removed or MP ended)
    final maxPage = hasCoop ? 1 : 0;
    if (_currentPage > maxPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _page.hasClients) {
          _page.jumpToPage(maxPage);
          setState(() => _currentPage = maxPage);
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton:
          FloatingActionButton(
                heroTag: 'fab_add',
                tooltip:
                    isMpActive && !onMyMpPage
                        ? 'Add to ${session.peerNickname ?? 'Peer'}'
                        : (_currentPage == 1
                            ? 'Add to P2'
                            : 'Add to inventory'),
                onPressed: () {
                  _showQuickAddBottomSheet(
                    context,
                    _currentPage == 1 ? PlayerSlot.coop : PlayerSlot.main,
                  );
                },
                child: const Icon(Icons.add, size: 32),
              ),
      body: Column(
        children: [
          if (p.windgunnerCountdown > 0) _buildWindgunnerBanner(p),
          // In MP: unified MpHeader replaces both player switcher and
          // old status bar. In solo coop: plain PlayerSwitcher.
          if (isMpActive)
            MpHeader(
              currentPage: _currentPage,
              hasCoop: hasCoop,
              session: session,
              onPick: navigateTo,
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
                      ? const ClampingScrollPhysics()
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
    );
  }

  void _showQuickAddBottomSheet(BuildContext context, PlayerSlot slot) {
    final p = Provider.of<RunProvider>(context, listen: false);
    final focusNode = FocusNode();
    final quickAddController = TextEditingController(text: _quickQuery);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF131316),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: Color(0xFF303036), width: 1.5),
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

            final results = combinedResults.take(6).toList();

            return AnimatedPadding(
              duration: const Duration(milliseconds: 100),
              padding: MediaQuery.of(sContext).viewInsets,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sContext).size.height * 0.65,
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GoopText(
                          () {
                            final mpSession =
                                context.read<MultiplayerSession>();
                            if (mpSession.isActive &&
                                !mpSession.isSimulated &&
                                mpSession.mySlot != slot) {
                              return 'ADD TO ${mpSession.peerNickname?.toUpperCase() ?? 'PEER'}';
                            }
                            return slot == PlayerSlot.coop
                                ? 'QUICK ADD TO PLAYER 2'
                                : 'QUICK ADD TO RUN';
                          }(),
                          style: const TextStyle(
                            fontFamily: 'EnterTheGungeonBig',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.amberAccent,
                            letterSpacing: 1.0,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.pop(bContext);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                fastRoute(
                                  BrowseScreen(
                                    targetSlot: slot,
                                    showBackButton: true,
                                  ),
                                ),
                              );
                            });
                          },
                          child: const GoopText(
                            'ADVANCED LIBRARY Γ₧ö',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.cyanAccent,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: quickAddController,
                      autofocus: true,
                      focusNode: focusNode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                      ),
                      cursorColor: Colors.amberAccent,
                      decoration: InputDecoration(
                        hintText: 'Search items, guns...',
                        hintStyle: const TextStyle(
                          color: Colors.white30,
                          fontSize: 13.5,
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
                                  onPressed: () {
                                    quickAddController.clear();
                                    setModalState(() {
                                      _quickQuery = '';
                                    });
                                  },
                                )
                                : null,
                        filled: true,
                        fillColor: const Color(0xFF1E1E22),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.amberAccent,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white10),
                        ),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          _quickQuery = val;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    if (results.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: GoopText(
                          'No matching guns or items found.',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12.5,
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
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
                            final quality = isGun ? item.quality : item.quality;
                            final iconPath = isGun ? item.icon : item.icon;

                            // Read live run state directly to see if player already owns it
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

                                return ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  leading: GameIcon(
                                    assetPath: iconPath,
                                    size: 32,
                                    fallback:
                                        isGun
                                            ? Icons.gps_fixed
                                            : Icons.extension,
                                    quality: quality,
                                  ),
                                  title: GoopText(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  subtitle: GoopText(
                                    isGun
                                        ? 'Gun • Quality $quality'
                                        : 'Item • Quality $quality',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                  trailing:
                                      isOwned
                                          ? Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: Colors.greenAccent
                                                    .withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.check,
                                                  size: 12,
                                                  color: Colors.greenAccent,
                                                ),
                                                SizedBox(width: 4),
                                                GoopText(
                                                  'OWNED',
                                                  style: TextStyle(
                                                    color: Colors.greenAccent,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                          : ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF1E1E22,
                                              ),
                                              foregroundColor:
                                                  Colors.amberAccent,
                                              elevation: 0,
                                              side: const BorderSide(
                                                color: Colors.white10,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 2,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ),
                                            onPressed: () {
                                              Haptics.selection();
                                              final mpSession =
                                                  context
                                                      .read<
                                                        MultiplayerSession
                                                      >();
                                              final isMpPeerAdd =
                                                  mpSession.isActive &&
                                                  !mpSession.isSimulated &&
                                                  mpSession.mySlot != slot;
                                              if (isMpPeerAdd) {
                                                mpSession.sendAddToPeer(
                                                  kind: isGun ? 'gun' : 'item',
                                                  name: name,
                                                );
                                              } else if (isGun) {
                                                p.addGun(item, slot: slot);
                                              } else {
                                                p.addItem(item, slot: slot);
                                              }
                                              quickAddController.clear();
                                              setModalState(() {
                                                _quickQuery = '';
                                              });
                                            },
                                            child: const GoopText(
                                              'ADD',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                );
                              },
                            );
                          },
                        ),
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
    });
  }

  String _quickQuery = '';

  Widget _buildWindgunnerBanner(RunProvider p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                fontSize: 10,
                fontFamily: 'EnterTheGungeonBig',
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
