import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../models/gun.dart';
import '../models/gungeoneer.dart';
import '../models/item.dart';
import '../models/player.dart';
import '../models/synergy.dart';
import '../widgets/periodic_tile.dart';
import '../widgets/gungeoneer_header.dart';
import '../widgets/inventory_list_row.dart';
import '../widgets/game_icon.dart';
import '../widgets/scale_button.dart';
import '../widgets/glass_container.dart';
import '../services/haptics.dart';
import 'item_detail_screen.dart';
import 'stats_detail_screen.dart';
import 'character_select_screen.dart';
import 'browse_screen.dart';
import 'effects_summary_screen.dart';
import 'shrine_picker_screen.dart';
import 'theme_picker_screen.dart';
import 'favourites_screen.dart';
import '../services/app_theme.dart';
import '../services/effect_tagger.dart';
import '../services/damage_calculator.dart';
import '../services/elemental_tagger.dart';
import '../services/multiplayer_session.dart';
import '../models/multiplayer_messages.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/format.dart';
import '../utils/asset_paths.dart';

/// Snappy page route: 180ms fade + slight scale-up, no ghosting of previous screen.
PageRoute<T> _fastRoute<T>(Widget child) => PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => child,
      transitionsBuilder: (_, anim, __, child) {
        final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1.0).animate(curve),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 150),
    );

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
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B1816),
        title: const Text('🎲 Gunfortuna Challenge! 🎲', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFFFD54F), letterSpacing: 1.0)),
        content: Text('$challengerName challenges you to a Gunfortuna Dice Roll! Do you accept the challenge?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text('DECLINE', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _mpSession?.sendDiceAccept();
              _showDiceRollDialog(context, isChallenged: true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD54F), foregroundColor: Colors.black),
            child: const Text('ACCEPT', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_mpSession != null) {
      if (_mpSession!.onDiceChallenge == _handleIncomingDiceChallenge) {
        _mpSession!.onDiceChallenge = null;
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
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent),
            SizedBox(width: 12),
            Text('Connection Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () async {
              await _mpSession?.saveCurrentSession();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Run saved'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Save Session'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry Reconnect'),
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
      return const Scaffold(body: Center(child: Text('No inventory loaded')));
    }

    final session = context.watch<MultiplayerSession>();
    final isMpActive = session.isActive;
    final hasCoop = state.hasCoop;
    // Snap back if current page no longer exists (coop removed or MP ended)
    final maxPage = (hasCoop ? 1 : 0) + (isMpActive && hasCoop ? 1 : 0);
    if (_currentPage > maxPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _page.hasClients) {
          _page.jumpToPage(maxPage);
          setState(() => _currentPage = maxPage);
        }
      });
    }

    // Pages: 0=P1, 1=P2 (only when coop), 2=Summary (MP only).
    // In MP, "my" page is whichever slot belongs to me.
    final myMpPage = isMpActive
        ? (session.myRole == MpRole.main ? 0 : 1)
        : 0;
    final onMyMpPage = isMpActive
        ? _currentPage == myMpPage
        : true;
    final onCoop = !isMpActive && hasCoop && _currentPage == 1;

    void navigateTo(int i) => _page.animateToPage(i,
        duration: const Duration(milliseconds: 260), curve: Curves.easeOut);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: (isMpActive && hasCoop && _currentPage >= 2)
          ? null
          : FloatingActionButton(
              heroTag: 'fab_add',
              tooltip: (isMpActive && !onMyMpPage)
                  ? null // no FAB on peer's page in MP
                  : (_currentPage == 1 ? 'Add to P2' : 'Add to inventory'),
              onPressed: (isMpActive && !onMyMpPage)
                  ? null
                  : () {
                      _showQuickAddBottomSheet(
                        context,
                        _currentPage == 1 ? PlayerSlot.coop : PlayerSlot.main,
                      );
                    },
              child: const Icon(Icons.add, size: 32),
            ),
      body: Column(
        children: [
          if (p.windgunnerCountdown > 0)
            _buildWindgunnerBanner(p),
          // In MP: unified _MpHeader replaces both player switcher and
          // old status bar. In solo coop: plain _PlayerSwitcher.
          if (isMpActive)
            _MpHeader(
              currentPage: _currentPage,
              hasCoop: hasCoop,
              session: session,
              onPick: navigateTo,
            )
          else if (hasCoop)
            _PlayerSwitcher(
              currentPage: _currentPage,
              mainName: main.character!.name,
              coopName: state.coop!.character?.name ?? 'P2',
              onPick: navigateTo,
            ),
          Expanded(
            child: PageView(
              controller: _page,
              physics: hasCoop
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              onPageChanged: (i) {
                setState(() => _currentPage = i);
                final slot = i == 0
                    ? PlayerSlot.main
                    : (i == 1 && hasCoop ? PlayerSlot.coop : null);
                if (slot != null) {
                  widget.onPlayerChanged?.call(slot);
                }
              },
              children: [
                const _PlayerPage(slot: PlayerSlot.main),
                if (hasCoop) const _PlayerPage(slot: PlayerSlot.coop),
                if (isMpActive && hasCoop) const _MpSummaryPage(),
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
            final textTheme = Theme.of(sContext).textTheme;
            final query = _quickQuery.toLowerCase().trim();

            // Smart relevance matching & sorting:
            // 1. Starts with query (highest priority)
            // 2. Contains query (medium priority)
            // 3. Quality score tie-breaker
            final matchingGuns = p.allGuns.where((g) {
              return g.name.toLowerCase().contains(query);
            }).toList();

            final matchingItems = p.allItems.where((i) {
              return i.name.toLowerCase().contains(query);
            }).toList();

            // Combined and prioritized
            final List<dynamic> combinedResults = [...matchingGuns, ...matchingItems];
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
                        Text(
                          slot == PlayerSlot.coop ? 'QUICK ADD TO PLAYER 2' : 'QUICK ADD TO RUN',
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
                                _fastRoute(BrowseScreen(
                                  targetSlot: slot,
                                  showBackButton: true,
                                )),
                              );
                            });
                          },
                          child: const Text(
                            'ADVANCED LIBRARY ➔',
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
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      cursorColor: Colors.amberAccent,
                      decoration: InputDecoration(
                        hintText: 'Search items, guns...',
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 13.5),
                        prefixIcon: const Icon(Icons.search, color: Colors.white30, size: 20),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, color: Colors.white54, size: 18),
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
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.amberAccent, width: 1.5),
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
                        child: Text(
                          'No matching guns or items found.',
                          style: TextStyle(color: Colors.white38, fontSize: 12.5),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: results.length,
                          separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
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
                                final activePlayer = slot == PlayerSlot.coop
                                    ? (p.runState.coop ?? Player())
                                    : p.runState.main;
                                final isOwned = isGun
                                    ? activePlayer.guns.any((g) => g.name == name)
                                    : (name.toLowerCase() == 'junk'
                                        ? false
                                        : activePlayer.items.any((i) => i.name == name));

                                return ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  leading: GameIcon(
                                    assetPath: iconPath,
                                    size: 32,
                                    fallback: isGun ? Icons.gps_fixed : Icons.extension,
                                    quality: quality,
                                  ),
                                  title: Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  subtitle: Text(
                                    isGun ? 'Gun • Quality $quality' : 'Item • Quality $quality',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                  trailing: isOwned
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.check, size: 12, color: Colors.greenAccent),
                                              SizedBox(width: 4),
                                              Text(
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
                                            backgroundColor: const Color(0xFF1E1E22),
                                            foregroundColor: Colors.amberAccent,
                                            elevation: 0,
                                            side: const BorderSide(color: Colors.white10),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                          ),
                                          onPressed: () {
                                            Haptics.selection();
                                            if (isGun) {
                                              p.addGun(item, slot: slot);
                                            } else {
                                              p.addItem(item, slot: slot);
                                            }
                                            quickAddController.clear();
                                            setModalState(() {
                                              _quickQuery = '';
                                            });
                                          },
                                          child: const Text(
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
            child: Text(
              'WINDGUNNER STATE COMPASS ACTIVE (${p.windgunnerCountdown}s of Infinite Power)',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'EnterTheGungeonBig',
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.8,
                shadows: [
                  Shadow(color: Colors.black54, offset: Offset(0, 1.5), blurRadius: 3),
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

/// Two-up player switcher used when local co-op is active (not MP).
/// Each tab is equal-width, large enough to read at a glance, and shows
/// the slot label (P1 / P2) above the character's name.
class _PlayerSwitcher extends StatelessWidget {
  final int currentPage;
  final String mainName;
  final String coopName;
  final void Function(int) onPick;
  const _PlayerSwitcher({
    required this.currentPage,
    required this.mainName,
    required this.coopName,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
        child: Row(
          children: [
            Expanded(
              child: _BigPlayerTab(
                active: currentPage == 0,
                slotLabel: 'P1',
                characterName: mainName,
                onTap: () => onPick(0),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BigPlayerTab(
                active: currentPage == 1,
                slotLabel: 'P2',
                characterName: coopName,
                onTap: () => onPick(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sleek tall pill used by both local-coop and MP player switchers.
/// Two-line layout: slot/role label on top, name on bottom. Active state
/// fills with primary tint; inactive is a hairline outline on near-black.
class _BigPlayerTab extends StatelessWidget {
  final bool active;
  final String slotLabel;
  final String characterName;
  final VoidCallback onTap;
  /// Optional leading green dot ("you are this player on this device"
  /// indicator for MP).
  final bool showYouDot;
  /// Optional opacity multiplier for showing a peer tab as stale.
  final double opacity;
  const _BigPlayerTab({
    required this.active,
    required this.slotLabel,
    required this.characterName,
    required this.onTap,
    this.showYouDot = false,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Opacity(
      opacity: opacity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: active
                  ? primary.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: active
                    ? primary.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.06),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showYouDot)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        slotLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                          color: active
                              ? primary
                              : Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          characterName,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight:
                                active ? FontWeight.w800 : FontWeight.w600,
                            color: active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.82),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Unified MP header shown when a multiplayer session is active.
/// Replaces both the generic _PlayerSwitcher and the old status bar:
///
///  ┌─ slim status strip ─────────────────────────── session name ─┐
///  │ ● Connected                               BraveWolf          │
///  └──────────────────────────────────────────────────────────────┘
///  ┌─ nick tab ────────┐ ┌─ nick tab ──────────┐ ┌─ Summary ─────┐
///  │ ● YourNick        │ │   PeerNick           │ │  ≡ Summary    │
///  └───────────────────┘ └──────────────────────┘ └───────────────┘
///
/// The peer tab dims when disconnected to signal stale data.
class _MpHeader extends StatelessWidget {
  final int currentPage;
  final bool hasCoop;
  final MultiplayerSession session;
  final void Function(int) onPick;
  const _MpHeader({
    required this.currentPage,
    required this.hasCoop,
    required this.session,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final f = AppTheme.flair;
    final isConnected = session.isConnected;
    final isSearching = session.status == MpStatus.searching;
    final isReconnecting = isSearching && session.canReconnect;
    final isAutoRetrying = session.isAutoReconnecting;
    final statusColor = isConnected
        ? const Color(0xFF00E676) // vibrant green
        : (isSearching || session.status == MpStatus.handshaking)
            ? const Color(0xFFFF9100) // warm orange
            : const Color(0xFFFF1744); // sharp red

    final showManualReconnect = session.canReconnect &&
        (session.status == MpStatus.disconnected ||
            session.status == MpStatus.error) &&
        !session.isAutoReconnecting;

    String statusText;
    if (isConnected) {
      statusText = 'Connected';
    } else if (isReconnecting) {
      final att = session.autoReconnectAttempts;
      statusText = att > 0 ? 'Reconnecting (attempt $att)…' : 'Reconnecting…';
    } else if (isSearching) {
      statusText = 'Searching…';
    } else if (session.status == MpStatus.handshaking) {
      statusText = 'Connecting…';
    } else if (isAutoRetrying) {
      statusText = 'Retrying (attempt ${session.autoReconnectAttempts})…';
    } else {
      statusText = 'Offline';
    }

    // Tab 0 = main slot, Tab 1 = coop slot.
    // Show the lobby nickname of whoever owns that slot.
    final myRole = session.myRole;
    final iAmMain = myRole == MpRole.main;
    final tab0Nick =
        iAmMain ? session.myNickname : (session.peerNickname ?? 'Main');
    final tab1Nick =
        !iAmMain ? session.myNickname : (session.peerNickname ?? 'Cultist');
    // "You" indicator: green dot on the tab that belongs to this device.
    final tab0IsYou = iAmMain;
    final tab1IsYou = !iAmMain;
    // Dim the peer tab when disconnected so it's clear their data may be stale.
    final peerDimmed = !isConnected && !isSearching &&
        session.status != MpStatus.handshaking;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Status strip (Clickable & Taller) ──────────────────
            InkWell(
              onTap: () => _showMpDiagnosticsDialog(context),
              borderRadius: BorderRadius.circular(f.chipRadius),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(f.chipRadius),
                  border:
                      Border.all(color: statusColor.withValues(alpha: 0.25), width: 1.0),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusText.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: statusColor,
                            ),
                          ),
                          if (session.error != null && !isConnected) ...[
                            const SizedBox(height: 2),
                            Text(
                              session.error!,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (showManualReconnect)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 24),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: Colors.lightBlueAccent,
                        ),
                        icon: const Icon(Icons.bluetooth_searching, size: 13),
                        label: const Text('Reconnect',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700)),
                        onPressed: () => session.reconnect(),
                      )
                    else
                      // Session name — stays constant across reconnects so
                      // both players can verbally confirm they're paired.
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            session.sessionName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              color: isConnected
                                  ? Colors.amber
                                  : Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.settings_outlined,
                            size: 14,
                            color: isConnected ? Colors.amber : Colors.white30,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            // ── Player tabs (only when the coop slot exists) ──────
            // P1 + P2 equal-width tabs, plus a compact Summary tab.
            // The peer tab dims when disconnected.
            if (hasCoop) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _BigPlayerTab(
                      active: currentPage == 0,
                      slotLabel: 'P1',
                      characterName: tab0Nick,
                      onTap: () => onPick(0),
                      showYouDot: tab0IsYou,
                      opacity: peerDimmed && !tab0IsYou ? 0.45 : 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _BigPlayerTab(
                      active: currentPage == 1,
                      slotLabel: 'P2',
                      characterName: tab1Nick,
                      onTap: () => onPick(1),
                      showYouDot: tab1IsYou,
                      opacity: peerDimmed && !tab1IsYou ? 0.45 : 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _SummaryTab(
                      active: currentPage == 2,
                      onTap: () => onPick(2),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showMpDiagnosticsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121214),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final f = AppTheme.flair;
        return Consumer<MultiplayerSession>(
          builder: (context, liveSession, _) {
            final isConnected = liveSession.isConnected;
            final isMain = liveSession.myRole == MpRole.main;
            final code = liveSession.pinCode ?? 'N/A';
            final lastTouch = liveSession.lastPeerTouchMs;
            final now = DateTime.now().millisecondsSinceEpoch;
            final diff = lastTouch > 0 ? (now - lastTouch) : 999999;

            String strengthText;
            Color strengthColor;
            IconData strengthIcon;
            if (!isConnected) {
              strengthText = 'Offline';
              strengthColor = const Color(0xFFEF5350);
              strengthIcon = Icons.signal_cellular_off;
            } else if (diff <= 3500) {
              strengthText = 'Excellent';
              strengthColor = const Color(0xFF66BB6A);
              strengthIcon = Icons.signal_cellular_alt;
            } else if (diff <= 7500) {
              strengthText = 'Good';
              strengthColor = const Color(0xFF9CCC65);
              strengthIcon = Icons.signal_cellular_alt;
            } else if (diff <= 15000) {
              strengthText = 'Fair';
              strengthColor = const Color(0xFFFFB74D);
              strengthIcon = Icons.signal_cellular_alt;
            } else {
              strengthText = 'Poor';
              strengthColor = const Color(0xFFEF5350);
              strengthIcon = Icons.signal_cellular_alt;
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upper drag bar indicator for premium panel feel
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header with pulsing terminal indicator
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isConnected ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
                          boxShadow: [
                            BoxShadow(
                              color: (isConnected ? const Color(0xFF66BB6A) : const Color(0xFFEF5350)).withValues(alpha: 0.5),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'GUNFORTUNA LINK PANEL',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: Colors.white54),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Overview grid: connection type, strength, role
                  Row(
                    children: [
                      Expanded(
                        child: _buildPanelMetric(
                          label: 'CONN TYPE',
                          value: isConnected ? 'Wi-Fi / BT P2P' : 'None',
                          icon: Icons.wifi_tethering_rounded,
                          color: isConnected ? Colors.cyanAccent : Colors.white38,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildPanelMetric(
                          label: 'STRENGTH',
                          value: strengthText,
                          icon: strengthIcon,
                          color: strengthColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildPanelMetric(
                          label: 'MY ROLE',
                          value: isMain ? 'Main Host' : 'Sidekick',
                          icon: isMain ? Icons.star_rounded : Icons.handshake_rounded,
                          color: isMain ? Colors.amber : Colors.purpleAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Connection Code block
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SESSION PIN CODE',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.amber,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isMain ? 'Share with your Sidekick player' : 'Connected to host session',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            code,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.amber,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Simplified stream-lined log console
                  const Row(
                    children: [
                      Icon(Icons.terminal_rounded, size: 14, color: Colors.greenAccent),
                      const SizedBox(width: 6),
                      Text(
                        'CONSOLE LOGS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.greenAccent,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 110,
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0D0F),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: liveSession.connectionLogs.isEmpty
                        ? const Center(
                            child: Text(
                              'CONSOLE IDLE',
                              style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          )
                        : ListView.builder(
                            itemCount: liveSession.connectionLogs.length,
                            reverse: true, // Newest logs on top
                            itemBuilder: (context, idx) {
                              final log = liveSession.connectionLogs[liveSession.connectionLogs.length - 1 - idx];
                              // Streamline and make them shorter & direct
                              final cleanLog = log
                                  .replaceAll('[SYSTEM]', '[SYS]')
                                  .replaceAll('Nearby Connections', 'Nearby')
                                  .replaceAll('established', 'OK')
                                  .replaceAll('successfully', 'OK')
                                  .replaceAll('Advertising failed: ', 'ERR: ')
                                  .replaceAll('Discovery failed: ', 'ERR: ')
                                  .replaceAll('Initiating reconnection sequence...', '[SYS] Reconnecting...')
                                  .replaceAll('Disconnecting from active peer by user request.', '[SYS] Disconnected by user.')
                                  .replaceAll('Drop detected during active run! Starting automatic reconnect sequence...', '[SYS] Link lost! Auto-retrying...')
                                  .replaceAll('Starting advertising/discovery...', '[SYS] Starting search...')
                                  .replaceAll('Connected to peer:', 'Connected:')
                                  .replaceAll('Disconnected from peer:', 'Disconnected:')
                                  .replaceAll('Sending handshake snapshot...', 'Handshake sent.')
                                  .replaceAll('Received handshake snapshot...', 'Handshake received.');

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  cleanLog,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 10.5,
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 18),

                  // Actions row
                  Row(
                    children: [
                      // Reconnect / Fix
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: f.primary,
                            side: BorderSide(color: f.primary.withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.sync_problem_rounded, size: 16),
                          label: const Text('FIX LINK', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                          onPressed: isConnected ? null : () {
                            liveSession.fullReconnectCycle();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Saving run & reconnecting...'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Save Session
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: f.primary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.save_rounded, size: 16),
                          label: const Text('SAVE RUN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                          onPressed: () async {
                            await liveSession.saveCurrentSession();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Run saved'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPanelMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final flair = AppTheme.flair;
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: flair.card,
      opacity: 0.85, // perfect balance of see-through & readability
      border: Border.all(color: color.withValues(alpha: 0.24), width: 1.2),
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9.0,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.65),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// A single player's loadout view. Re-usable for main + coop.
/// Coop view hides coolness/curse/synergies (those are run-scope).
///
/// Stateful so each tab can hold its own gun/item sort preference. Sort
/// state intentionally does *not* persist across app restarts — it's a
/// glance preference, not a saved configuration.
class _PlayerPage extends StatefulWidget {
  final PlayerSlot slot;
  const _PlayerPage({required this.slot});

  @override
  State<_PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<_PlayerPage> {
  // Sort modes are persisted per-slot via SharedPreferences so the
  // user's choice survives player switches *and* app restarts. We
  // initialise to `pickup` (the natural order) and asynchronously
  // hydrate from prefs in initState — the brief flash of pickup-order
  // before hydration is unnoticeable in practice and avoids blocking
  // the first frame on a disk read.
  _GunSort _gunSort = _GunSort.pickup;
  _ItemSort _itemSort = _ItemSort.pickup;

  /// Per-slot inventory view mode. Defaults to `grid` (the historical
  /// look). Hydrated alongside the sort prefs and persisted on toggle.
  _InvView _invView = _InvView.grid;

  /// True once the user has explicitly picked a sort *or* the prefs
  /// hydration has resolved — whichever came first. Prevents a slow
  /// initial load from clobbering a fast tap on the sort sheet (rare,
  /// but cheap to defend against).
  bool _sortHydrated = false;

  bool get isMain => widget.slot == PlayerSlot.main;
  PlayerSlot get _slot => widget.slot;

  String get _gunSortKey => 'sort.gun.${_slot.name}';
  String get _itemSortKey => 'sort.item.${_slot.name}';
  String get _invViewKey => 'invView.${_slot.name}';

  @override
  void initState() {
    super.initState();
    _loadSortPrefs();
  }

  Future<void> _loadSortPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || _sortHydrated) return;
      final gIdx = prefs.getInt(_gunSortKey);
      final iIdx = prefs.getInt(_itemSortKey);
      final vIdx = prefs.getInt(_invViewKey);
      setState(() {
        if (gIdx != null && gIdx >= 0 && gIdx < _GunSort.values.length) {
          _gunSort = _GunSort.values[gIdx];
        }
        if (iIdx != null && iIdx >= 0 && iIdx < _ItemSort.values.length) {
          _itemSort = _ItemSort.values[iIdx];
        }
        if (vIdx != null && vIdx >= 0 && vIdx < _InvView.values.length) {
          _invView = _InvView.values[vIdx];
        }
        _sortHydrated = true;
      });
    } catch (_) {
      // SharedPreferences failed to materialise (rare platform issue).
      // We just keep the in-memory defaults — no UI surface needed.
      _sortHydrated = true;
    }
  }

  Future<void> _saveGunSort(_GunSort s) async {
    _sortHydrated = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_gunSortKey, s.index);
    } catch (_) {
      // Persistence failure is non-fatal: the in-memory choice still
      // applies for this session.
    }
  }

  Future<void> _saveItemSort(_ItemSort s) async {
    _sortHydrated = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_itemSortKey, s.index);
    } catch (_) {
      // Same rationale as _saveGunSort — persistence is best-effort.
    }
  }

  /// Cycle between the available [_InvView] modes: grid ➔ list.
  void _toggleInvView() {
    setState(() {
      _invView = _invView == _InvView.grid ? _InvView.list : _InvView.grid;
    });
    _saveInvView(_invView);
  }

  void _changeLayout(Object layout) {
    if (layout is _InvView) {
      setState(() {
        _invView = layout;
      });
      _saveInvView(layout);
    } else if (layout is InventoryDisplayMode) {
      setState(() {
        _invView = _InvView.grid;
      });
      _saveInvView(_InvView.grid);
      VisualPrefs.setInventoryDisplayMode(layout);
    }
    Haptics.selection();
  }

  Future<void> _saveInvView(_InvView v) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_invViewKey, v.index);
    } catch (_) {
      // Persistence failure is non-fatal.
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final state = p.runState;
    final player = isMain ? state.main : state.coop;
    if (player == null || player.character == null) {
      return const Center(child: Text('No player'));
    }
    final avgDps = isMain ? p.avgDps : p.avgDpsCoop;
    final activeSynergies =
        isMain ? p.getActiveSynergies().length : 0;
    final hasCoop = state.hasCoop;

    // For multiplayer: only allow transfers when connected.
    // For local co-op: allow transfers whenever hasCoop.
    final mpSession = context.watch<MultiplayerSession>();
    final isMpActive = mpSession.status != MpStatus.idle;
    final canTransfer = hasCoop && (!isMpActive || mpSession.isConnected);

    return ValueListenableBuilder<VisualPrefs>(
      valueListenable: VisualPrefs.notifier,
      builder: (context, prefs, _) {
        // Apply the active sort modes. Pickup-order is a no-op pass-through.
        final guns = _sortGuns(player.guns, _gunSort);
    final items = _sortItems(player.items, _itemSort);

    // Identify the highest-DPS gun in this player's loadout so both
    // grid and list views can surface it subtly (gold crown tint).
    final topDpsName = player.guns.isEmpty
        ? ''
        : player.guns
            .reduce((a, b) => a.dpsValue > b.dpsValue ? a : b)
            .name;
    final topDps = player.guns.isEmpty
        ? 0.0
        : player.guns.map((g) => g.dpsValue).reduce((a, b) => a > b ? a : b);

    // Synergy glow: map of lowercased name → Color for every item/gun
    // that is part of a currently-active synergy (combined inventories).
    final glowColors = p.activeSynergyGlowColors;

    final scrollWidget = CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            top: !hasCoop,
            child: GungeoneerHeader(
              character: player.character!,
              topDps: topDps,
              gunCount: player.guns.length,
              itemCount: player.items.length,
              activeSynergies: activeSynergies,
              showSynergies: isMain,
              coolness: state.totalCoolness,
              curse: state.totalCurse,
              onTapCoolness: () => Navigator.push(
                context,
                _fastRoute(const StatsDetailScreen(
                  statType: StatType.coolness,
                )),
              ),
              onTapCurse: () => Navigator.push(
                context,
                _fastRoute(const StatsDetailScreen(
                  statType: StatType.curse,
                )),
              ),
              onLongPressCoolness: () =>
                  _showStatAdjuster(context, isCool: true),
              onLongPressCurse: () =>
                  _showStatAdjuster(context, isCool: false),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListenableBuilder(
                    listenable: VisualPrefs.notifier,
                    builder: (context, _) {
                      final prefs = VisualPrefs.notifier.value;
                      final isSponge = prefs.spongeActive;
                      final isGoopian = prefs.isGoopianLanguage;
                      if (!isGoopian) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: IconButton(
                          onPressed: () {
                            VisualPrefs.setSpongeActive(!isSponge);
                            Haptics.heavy();
                          },
                          icon: Text(
                            '🧽',
                            style: TextStyle(
                              fontSize: 18,
                              shadows: isSponge
                                  ? [
                                      const Shadow(
                                        color: Colors.amberAccent,
                                        blurRadius: 10,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          tooltip: isSponge ? 'Sponge: English translation active' : 'Sponge: Alien language active',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      );
                    },
                  ),
                  // Damage calc icon — opens bottom sheet with DPS breakdown
                  IconButton(
                    onPressed: () => _showDamageCalcSheet(context, _slot),
                    icon: const Icon(Icons.calculate_rounded, size: 18, color: Colors.amberAccent),
                    tooltip: 'Damage Calculator',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  const _HeaderMenu(),
                ],
              ),
              // Computed once per build — the tagger is a handful of
              // regex scans over a ≤40-item loadout, well under a frame.
              elements: ElementalTagger.elementsOfPlayer(player),
              effectChips: EffectTagger.summaryChips(
                guns: player.guns,
                items: player.items,
              ),
            ),
          ),
        ),
        _DashboardSwiper(slot: _slot),
        // Effects tile hidden — effect tags already shown on character dash.
        // SliverToBoxAdapter(
        //   child: _EffectsTile(slot: _slot),
        // ),
        _SectionHeaderSliver(
          title: 'Guns',
          count: guns.length,
          icon: Icons.gps_fixed,
          sortLabel: _gunSort.label,
          onTapSort: _showGunSortSheet,
          showLayoutSelector: true,
          currentInvView: _invView,
          currentDisplayMode: VisualPrefs.notifier.value.inventoryDisplayMode,
          onLayoutChanged: _changeLayout,
        ),
        if (guns.isEmpty)
          SliverToBoxAdapter(
            child: _StarterHint(
              character: player.character!,
              kind: _StarterKind.guns,
              slot: _slot,
              tileGrid: _tileGrid(context),
            ),
          )
        else if (_invView == _InvView.grid)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid.builder(
              gridDelegate: _tileGrid(context),
              itemCount: guns.length,
              itemBuilder: (c, i) {
                final g = guns[i];
                return PeriodicTile(
                  gun: g,
                  isTopDps: g.name == topDpsName,
                  synergyGlowColor: glowColors[g.name.toLowerCase()],
                  onTap: () => Navigator.push(
                    c,
                    _fastRoute(ItemDetailScreen(gun: g, ownerSlot: _slot)),
                  ),
                  onLongPress: () => _promptTileActions(c, gun: g),
                );
              },
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverList.builder(
              itemCount: guns.length,
              itemBuilder: (c, i) {
                final g = guns[i];
                return Dismissible(
                  key: Key('gun_${g.name}_${_slot}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.only(right: 16),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 24),
                  ),
                  onDismissed: (_) {
                    final p = context.read<RunProvider>();
                    p.removeGun(g, slot: _slot);
                    _toast(context, 'Removed ${g.name}');
                  },
                  child: InventoryListRow(
                    gun: g,
                    isTopDps: g.name == topDpsName,
                    synergyGlowColor: glowColors[g.name.toLowerCase()],
                    onTap: () => Navigator.push(
                      c,
                      _fastRoute(ItemDetailScreen(gun: g, ownerSlot: _slot)),
                    ),
                    onLongPress: () => _promptTileActions(c, gun: g),
                  ),
                );
              },
            ),
          ),
        _SectionHeaderSliver(
          title: 'Items',
          count: items.length,
          icon: Icons.inventory_2_outlined,
          sortLabel: _itemSort.label,
          onTapSort: _showItemSortSheet,
          showLayoutSelector: true,
          currentInvView: _invView,
          currentDisplayMode: VisualPrefs.notifier.value.inventoryDisplayMode,
          onLayoutChanged: _changeLayout,
        ),
        if (items.isEmpty)
          SliverToBoxAdapter(
            child: _StarterHint(
              character: player.character!,
              kind: _StarterKind.items,
              slot: _slot,
              tileGrid: _tileGrid(context),
            ),
          )
        else if (_invView == _InvView.grid)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
            sliver: SliverGrid.builder(
              gridDelegate: _tileGrid(context),
              itemCount: items.length,
              itemBuilder: (c, i) {
                final it = items[i];
                return PeriodicTile(
                  item: it,
                  synergyGlowColor: glowColors[it.name.toLowerCase()],
                  onTap: () => Navigator.push(
                    c,
                    _fastRoute(ItemDetailScreen(item: it, ownerSlot: _slot)),
                  ),
                  onLongPress: () => _promptTileActions(c, item: it),
                );
              },
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
            sliver: SliverList.builder(
              itemCount: items.length,
              itemBuilder: (c, i) {
                final it = items[i];
                return Dismissible(
                  key: Key('item_${it.name}_${_slot}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.only(right: 16),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 24),
                  ),
                  onDismissed: (_) {
                    final p = context.read<RunProvider>();
                    p.removeItem(it, slot: _slot);
                    _toast(context, 'Removed ${it.name}');
                  },
                  child: InventoryListRow(
                    item: it,
                    synergyGlowColor: glowColors[it.name.toLowerCase()],
                    onTap: () => Navigator.push(
                      c,
                      _fastRoute(ItemDetailScreen(item: it, ownerSlot: _slot)),
                    ),
                    onLongPress: () => _promptTileActions(c, item: it),
                  ),
                );
              },
            ),
          ),
      ],
    );

    if (isMpActive) {
      return RefreshIndicator(
        color: Colors.amber,
        backgroundColor: const Color(0xFF1E1E1E),
        onRefresh: () async {
          await mpSession.reconnect();
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: scrollWidget,
      );
    }
    return scrollWidget;
      },
    );
  }

  void _showDamageCalcSheet(BuildContext c, PlayerSlot slot) {
    showModalBottomSheet<void>(
      context: c,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      isScrollControlled: true,
      builder: (ctx) => _DamageCalcSheet(slot: slot),
    );
  }

  /// Inline +/- bottom sheet for a quick coolness/curse tweak — opened
  /// by long-pressing either bubble in the [GungeoneerHeader]. Live-rebinds
  /// to the latest provider state so the displayed number updates after
  /// each tap without dismissing the sheet.
  void _showStatAdjuster(BuildContext c, {required bool isCool}) {
    showModalBottomSheet<void>(
      context: c,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => _StatAdjusterSheet(isCool: isCool),
    );
  }

  void _showGunSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _SortPickerSheet<_GunSort>(
        title: 'Guns',
        titleIcon: Icons.gps_fixed,
        current: _gunSort,
        options: _GunSort.values,
        labelOf: (s) => s.label,
        iconOf: (s) => s.icon,
        onPick: (s) {
          setState(() => _gunSort = s);
          _saveGunSort(s);
        },
      ),
    );
  }

  void _showItemSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _SortPickerSheet<_ItemSort>(
        title: 'Items',
        titleIcon: Icons.inventory_2_outlined,
        current: _itemSort,
        options: _ItemSort.values,
        labelOf: (s) => s.label,
        iconOf: (s) => s.icon,
        onPick: (s) {
          setState(() => _itemSort = s);
          _saveItemSort(s);
        },
      ),
    );
  }

  void _toast(BuildContext c, String msg) {
    final m = ScaffoldMessenger.maybeOf(c);
    if (m == null) return;
    m.hideCurrentSnackBar();
    m.showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(milliseconds: 1500),
    ));
  }

  void _promptTransferGun(BuildContext c, Gun g) {
    final p = c.read<RunProvider>();
    final session = c.read<MultiplayerSession>();
    // All guns are droppable in Enter the Gungeon, so starter guns
    // (Crossbow, Blasphemy, Marine Sidearm, etc.) are free to transfer.
    final mpActive = session.isActive;
    final isMyInv = !mpActive || session.isSimulated || session.mySlot == _slot;
    final peerName = mpActive
        ? (session.peerNickname ?? 'Peer')
        : (isMain
            ? (p.runState.coop?.character?.name ?? 'Player 2')
            : p.runState.main.character!.name);

    final title = mpActive && !isMyInv
        ? 'Request ${g.name}?'
        : 'Transfer ${g.name}?';
    final subtitle = mpActive && !isMyInv
        ? 'Ask $peerName to send it to you'
        : 'Send to $peerName';
    final icon = mpActive && !isMyInv ? Icons.front_hand : Icons.swap_horiz;

    showModalBottomSheet(
      context: c,
      builder: (bc) => _TransferSheet(
        title: title,
        subtitle: subtitle,
        icon: icon,
        onConfirm: () async {
          Navigator.pop(bc);
          if (mpActive) {
            if (isMyInv) {
              // Send via MP — sendGift removes locally + ships the gift,
              // rolling back if the send fails.
              await session.sendGift(kind: 'gun', name: g.name);
              if (c.mounted) _toast(c, '${g.name} → $peerName');
            } else {
              final reqId =
                  await session.sendRequest(kind: 'gun', name: g.name);
              if (!c.mounted) return;
              _toast(
                c,
                reqId != null
                    ? 'Asked $peerName for ${g.name}…'
                    : 'Could not send request — check connection.',
              );
            }
          } else {
            // Local co-op — just shuffle slots in RunProvider.
            final ok = p.transferGun(g, _slot);
            if (c.mounted) {
              _toast(
                c,
                ok
                    ? '${g.name} → $peerName'
                    : '$peerName already has ${g.name}',
              );
            }
          }
        },
      ),
    );
  }

  void _promptTransferItem(BuildContext c, Item it) {
    final p = c.read<RunProvider>();
    final session = c.read<MultiplayerSession>();
    // All items are now transferable, including starter passives.
    final mpActive = session.isActive;
    final isMyInv = !mpActive || session.isSimulated || session.mySlot == _slot;
    final peerName = mpActive
        ? (session.peerNickname ?? 'Peer')
        : (isMain
            ? (p.runState.coop?.character?.name ?? 'Player 2')
            : p.runState.main.character!.name);

    final title = mpActive && !isMyInv
        ? 'Request ${it.name}?'
        : 'Transfer ${it.name}?';
    final subtitle = mpActive && !isMyInv
        ? 'Ask $peerName to send it to you'
        : 'Send to $peerName';
    final icon = mpActive && !isMyInv ? Icons.front_hand : Icons.swap_horiz;

    showModalBottomSheet(
      context: c,
      builder: (bc) => _TransferSheet(
        title: title,
        subtitle: subtitle,
        icon: icon,
        onConfirm: () async {
          Navigator.pop(bc);
          if (mpActive) {
            if (isMyInv) {
              await session.sendGift(kind: 'item', name: it.name);
              if (c.mounted) _toast(c, '${it.name} → $peerName');
            } else {
              final reqId =
                  await session.sendRequest(kind: 'item', name: it.name);
              if (!c.mounted) return;
              _toast(
                c,
                reqId != null
                    ? 'Asked $peerName for ${it.name}…'
                    : 'Could not send request — check connection.',
              );
            }
          } else {
            final ok = p.transferItem(it, _slot);
            if (c.mounted) {
              _toast(
                c,
                ok
                    ? '${it.name} → $peerName'
                    : '$peerName already has ${it.name}',
              );
            }
          }
        },
      ),
    );
  }

  SliverGridDelegate _tileGrid(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final displayMode = VisualPrefs.notifier.value.inventoryDisplayMode;

    int cross;
    double ratio;

    switch (displayMode) {
      case InventoryDisplayMode.classicPeriodic:
        final savedColCount = VisualPrefs.notifier.value.periodicGridColumnCount;
        cross = (savedColCount > 0) ? savedColCount : (w < 360 ? 3 : w < 600 ? 4 : 6);
        ratio = 0.80;
        break;
      case InventoryDisplayMode.tacticalStats:
        cross = w < 500 ? 2 : w < 850 ? 3 : 4;
        ratio = 0.95;
        break;
    }

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: cross,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: ratio,
    );
  }

  /// Solo-mode quick-actions sheet shown on long-press. Exactly one of
  /// [gun]/[item] must be non-null. Surfaces Open / Favourite / Remove
  /// in a single 3-tap-target sheet so the user can manage their loadout
  /// without leaving the inventory tab.
  void _promptTileActions(BuildContext c, {Gun? gun, Item? item}) {
    assert((gun == null) != (item == null), 'Pass exactly one of gun/item');
    final p = c.read<RunProvider>();
    final mpSession = c.read<MultiplayerSession>();
    final hasCoop = p.runState.hasCoop;
    final isMpActive = mpSession.status != MpStatus.idle;
    final canTransfer = hasCoop && (!isMpActive || mpSession.isConnected);

    showModalBottomSheet<void>(
      context: c,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetCtx) {
        VoidCallback? onTransfer;
        String? transferLabel;
        if (canTransfer) {
          final isMyInv = !isMpActive || mpSession.isSimulated || mpSession.mySlot == _slot;
          final peerName = isMpActive ? (mpSession.peerNickname ?? 'Peer') : 'Player 2';
          transferLabel = isMyInv ? 'Transfer to $peerName' : 'Request from $peerName';

          if (gun != null) {
            onTransfer = () {
              Navigator.pop(sheetCtx);
              _promptTransferGun(c, gun);
            };
          } else if (item != null) {
            onTransfer = () {
              Navigator.pop(sheetCtx);
              _promptTransferItem(c, item);
            };
          }
        }

        return _TileActionsSheet(
          gun: gun,
          item: item,
          onTransfer: onTransfer,
          transferLabel: transferLabel,
          onOpen: () {
            Navigator.pop(sheetCtx);
            Navigator.push(
              c,
              _fastRoute(ItemDetailScreen(
                  gun: gun,
                  item: item,
                  ownerSlot: _slot,
                ),
              ),
            );
          },
          onToggleFavourite: () {
            final p = c.read<RunProvider>();
            final name = gun?.name ?? item!.name;
            final nowFav = p.toggleFavourite(name);
            Navigator.pop(sheetCtx);
            ScaffoldMessenger.of(c).showSnackBar(SnackBar(
              content: Text(
                  nowFav ? '$name added to favourites' : '$name unfavourited'),
              duration: const Duration(milliseconds: 1400),
            ));
          },
          onRemove: () {
            Navigator.pop(sheetCtx);
            if (gun != null) {
              _removeGunWithUndo(c, gun);
            } else {
              _removeItemWithUndo(c, item!);
            }
          },
        );
      },
    );
  }

  /// Remove [g] from the loadout and surface a 5-second snackbar with an
  /// UNDO action. UNDO simply re-adds the gun via [RunProvider.addGun] —
  /// pickup-order is lost (it goes to the end of the list), but every
  /// other piece of state is preserved.
  ///
  /// Captures [_slot] into a local before constructing the closure so the
  /// UNDO action stays valid even if the user navigates away from this
  /// page before the snackbar times out.
  void _removeGunWithUndo(BuildContext c, Gun g) {
    final p = c.read<RunProvider>();
    final capturedSlot = _slot;
    p.removeGun(g, slot: capturedSlot);
    final messenger = ScaffoldMessenger.of(c);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text('Removed ${g.name}'),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () {
          p.addGun(g, slot: capturedSlot);
        },
      ),
    ));
  }

  void _removeItemWithUndo(BuildContext c, Item it) {
    final p = c.read<RunProvider>();
    final capturedSlot = _slot;
    p.removeItem(it, slot: capturedSlot);
    final messenger = ScaffoldMessenger.of(c);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text('Removed ${it.name}'),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'UNDO',
        onPressed: () {
          p.addItem(it, slot: capturedSlot);
        },
      ),
    ));
  }
}

class _TransferSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onConfirm;
  const _TransferSheet({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: Colors.amber),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Transfer'),
                    onPressed: onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RobotDashboardSliver extends StatefulWidget {
  const _RobotDashboardSliver();

  @override
  State<_RobotDashboardSliver> createState() => _RobotDashboardSliverState();
}

class _RobotDashboardSliverState extends State<_RobotDashboardSliver> {
  bool _terminalExpanded = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final player = p.runState.main;
    final double damageBoost = (p.robotJunk + (p.robotLies ? 1 : 0)) * 5.0 + (p.robotGoldJunk ? 500.0 : 0.0);
    final double multiplier = 1.0 + damageBoost / 100.0;
    final guns = player.guns;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.cyan.withValues(alpha: 0.35), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withValues(alpha: 0.04),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with big DMG boost badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.android_rounded, color: Colors.cyanAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'THE ROBOT HUD',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.cyanAccent,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: p.robotGoldJunk
                          ? Colors.amber.withValues(alpha: 0.18)
                          : Colors.cyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: p.robotGoldJunk
                            ? Colors.amber.withValues(alpha: 0.5)
                            : Colors.cyan.withValues(alpha: 0.4),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      '+${damageBoost.toStringAsFixed(0)}% DMG',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: p.robotGoldJunk ? Colors.amberAccent : Colors.cyanAccent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 16),

              // Junk counter — full width, no overflow
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'JUNK COUNT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.cyanAccent,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '+5% DMG each',
                          style: TextStyle(fontSize: 9, color: Colors.white38),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.cyanAccent, size: 24),
                          onPressed: p.robotJunk > 0 ? () => p.setRobotJunk(p.robotJunk - 1) : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '${p.robotJunk}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          icon: const Icon(Icons.add_circle_outline, color: Colors.cyanAccent, size: 24),
                          onPressed: () => p.setRobotJunk(p.robotJunk + 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Toggle row — full width, two big compact tap targets
              Row(
                children: [
                  Expanded(
                    child: _buildCompactToggle(
                      label: 'GOLD JUNK',
                      subtitle: '+500%',
                      value: p.robotGoldJunk,
                      activeColor: Colors.amberAccent,
                      onChanged: p.setRobotGoldJunk,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactToggle(
                      label: 'LIES',
                      subtitle: '+5%',
                      value: p.robotLies,
                      activeColor: Colors.purpleAccent,
                      onChanged: p.setRobotLies,
                    ),
                  ),
                ],
              ),

              // Expandable Damage Terminal
              if (guns.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildTerminalToggle(),
                if (_terminalExpanded) _buildDamageTerminal(guns, multiplier),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactToggle({
    required String label,
    required String subtitle,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value ? activeColor.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value ? activeColor.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08),
            width: value ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              color: value ? activeColor : Colors.white30,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: value ? activeColor : Colors.white60,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9,
                      color: value ? activeColor.withValues(alpha: 0.8) : Colors.white30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalToggle() {
    return GestureDetector(
      onTap: () {
        setState(() => _terminalExpanded = !_terminalExpanded);
        Haptics.selection();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF001100),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3), width: 1.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.terminal_rounded, size: 16, color: Colors.green.withValues(alpha: 0.8)),
                const SizedBox(width: 8),
                Text(
                  'DAMAGE CALCULATOR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.green.withValues(alpha: 0.8),
                    letterSpacing: 0.8,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            Icon(
              _terminalExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              size: 18,
              color: Colors.green.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDamageTerminal(List<Gun> guns, double multiplier) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF000800),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.25), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Terminal header
          Row(
            children: [
              Text(
                '> ROBOT_DMG_CALC v1.0',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.green.withValues(alpha: 0.5),
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '×${multiplier.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.greenAccent,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Column headers
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'WEAPON',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.green.withValues(alpha: 0.4),
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'BASE',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.green.withValues(alpha: 0.4),
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'ROBOT',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.green.withValues(alpha: 0.4),
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Δ',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.green.withValues(alpha: 0.4),
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Divider line
          Container(height: 1, color: Colors.green.withValues(alpha: 0.15)),
          const SizedBox(height: 4),
          // Gun rows
          for (final gun in guns)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      gun.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.withValues(alpha: 0.85),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      gun.dpsValue.toStringAsFixed(1),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.withValues(alpha: 0.6),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      (gun.dpsValue * multiplier).toStringAsFixed(1),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.greenAccent,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '+${(gun.dpsValue * multiplier - gun.dpsValue).toStringAsFixed(1)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.green.withValues(alpha: 0.5),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Terminal footer
          const SizedBox(height: 6),
          Container(height: 1, color: Colors.green.withValues(alpha: 0.15)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL DPS',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.green.withValues(alpha: 0.5),
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${guns.fold<double>(0, (sum, g) => sum + g.dpsValue).toStringAsFixed(1)} → ${guns.fold<double>(0, (sum, g) => sum + g.dpsValue * multiplier).toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.greenAccent,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _JunkanDashboardSliver extends StatefulWidget {
  final PlayerSlot slot;
  const _JunkanDashboardSliver({required this.slot});

  @override
  State<_JunkanDashboardSliver> createState() => _JunkanDashboardSliverState();
}

class _JunkanDashboardSliverState extends State<_JunkanDashboardSliver> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final player = widget.slot == PlayerSlot.coop
        ? (p.runState.coop ?? Player())
        : p.runState.main;

    final junkCount = player.items.where((i) => i.name.toLowerCase() == 'junk').length;
    final hasGoldJunk = player.items.any((i) => i.name.toLowerCase() == 'gold junk');

    String rankName = '';
    String description = '';
    String stats = '';

    if (hasGoldJunk) {
      rankName = 'MECHA JUNKAN (GOLD SUIT)';
      description = 'High-tech gold mechsuit! Jammed enemies struck by his machine gun become normal. Bypasses boss DPS cap.';
      stats = 'DMG: 2.2/shot (Machine Gun) • 20.0 (Laser Blade) • 8.0/rocket';
    } else {
      switch (junkCount) {
        case 0:
          rankName = 'PEASANT';
          description = 'Junkan harmlessly pushes enemies around.';
          stats = 'DMG: 0.0 • Role: Companion • Speed: Steady';
          break;
        case 1:
          rankName = 'SQUIRE';
          description = 'Gains helmet. Headbutts enemies slowly.';
          stats = 'DMG: 3.0 • Attack: Headbutt • Armor: Helmet';
          break;
        case 2:
          rankName = 'HEDGE KNIGHT';
          description = 'Gains shield. Attacks more frequently by shield-bashing.';
          stats = 'DMG: 5.0 • Attack: Shield-bash • Armor: Shield';
          break;
        case 3:
          rankName = 'KNIGHT';
          description = 'Gains sword. Attacks more frequently by slicing enemies.';
          stats = 'DMG: 7.0 • Attack: Sword-slice • Armor: Sword';
          break;
        case 4:
          rankName = 'KNIGHT LIEUTENANT';
          description = 'Gains helmet adornment. Sword attacks are faster and deal more damage.';
          stats = 'DMG: 9.0 • Attack: Upgraded Slice • Armor: Plated';
          break;
        case 5:
          rankName = 'KNIGHT COMMANDER';
          description = 'Gains cape. Spin-attacks multiple enemies simultaneously.';
          stats = 'DMG: 10.0 × 2 (Double Spin) • Attack: Spin • Armor: Cape';
          break;
        case 6:
          rankName = 'HOLY KNIGHT';
          description = 'Occasionally Blanks. Sacrifices himself to revive you at full health if you die.';
          stats = 'DMG: 13.33 • Attack: Holy Slice • Ability: Blank & Revive';
          break;
        default:
          rankName = 'ANGELIC KNIGHT';
          description = 'Gains wings. Flying. Fires rapid pink homing projectile shots.';
          stats = 'DMG: 10.0/shot • Attack: Ranged Projectiles • Ability: Flying';
          break;
      }
    }

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

    final junkItem = p.itemByName('Junk');
    final goldJunkItem = p.itemByName('Gold Junk');

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF13151A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasGoldJunk ? Colors.amber.withValues(alpha: 0.4) : Colors.teal.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (hasGoldJunk ? Colors.amber : Colors.tealAccent).withValues(alpha: 0.04),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            hasGoldJunk ? Icons.shield_rounded : Icons.star_rounded,
                            color: hasGoldJunk ? Colors.amberAccent : Colors.tealAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            hasGoldJunk ? 'MECHA JUNKAN HUD' : 'SER JUNKAN - LVL ${hasGoldJunk ? "MAX" : (junkCount > 7 ? "7+" : junkCount)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: hasGoldJunk ? Colors.amberAccent : Colors.tealAccent,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: hasGoldJunk ? Colors.amber.withValues(alpha: 0.12) : Colors.teal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              rankName,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: hasGoldJunk ? Colors.amberAccent : Colors.tealAccent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                            size: 18,
                            color: Colors.white30,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_expanded) ...[
                const Divider(color: Colors.white12, height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: hasGoldJunk ? Colors.amber.withValues(alpha: 0.2) : Colors.teal.withValues(alpha: 0.15),
                          ),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          imgPath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white24,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              description,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Colors.white70,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              stats,
                              style: TextStyle(
                                fontSize: 9.5,
                                color: hasGoldJunk ? Colors.amberAccent.withValues(alpha: 0.8) : Colors.tealAccent.withValues(alpha: 0.8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.02),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'JUNK',
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white60),
                                        ),
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: junkCount > 0 && junkItem != null
                                                  ? () => p.removeItem(junkItem, slot: widget.slot)
                                                  : null,
                                              behavior: HitTestBehavior.opaque,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                child: Icon(
                                                  Icons.remove_circle_rounded,
                                                  color: junkCount > 0 ? Colors.tealAccent : Colors.white24,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: Text(
                                                '$junkCount',
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: junkItem != null
                                                  ? () => p.addItem(junkItem, slot: widget.slot)
                                                  : null,
                                              behavior: HitTestBehavior.opaque,
                                              child: const Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                child: Icon(
                                                  Icons.add_circle_rounded,
                                                  color: Colors.tealAccent,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      if (goldJunkItem != null) {
                                        if (hasGoldJunk) {
                                          p.removeItem(goldJunkItem, slot: widget.slot);
                                        } else {
                                          p.addItem(goldJunkItem, slot: widget.slot);
                                        }
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: hasGoldJunk ? Colors.amber.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.02),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: hasGoldJunk ? Colors.amber.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.04),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.flash_on_rounded,
                                            size: 12,
                                            color: hasGoldJunk ? Colors.amberAccent : Colors.white30,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            hasGoldJunk ? 'MECH ACTIVE' : 'ACTIVATE MECH',
                                            style: TextStyle(
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w900,
                                              color: hasGoldJunk ? Colors.amberAccent : Colors.white60,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


class _GunderfuryDashboardSliver extends StatefulWidget {
  final PlayerSlot slot;
  const _GunderfuryDashboardSliver({required this.slot});

  @override
  State<_GunderfuryDashboardSliver> createState() => _GunderfuryDashboardSliverState();
}

class _GunderfuryDashboardSliverState extends State<_GunderfuryDashboardSliver> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final lvl = p.gunderfuryLevel.clamp(1, 60);

    String formName = '';
    String description = '';
    String statsDesc = '';

    if (lvl < 20) {
      formName = 'Base Form';
      description = 'Fires wide shotgun-like energy blasts.';
      statsDesc = 'Damage: 4.5 • Reload: 1.5s • Capacity: 450 • Spread: 10°';
    } else if (lvl < 30) {
      formName = 'Automatic Form';
      description = 'Increases fire rate and becomes fully automatic.';
      statsDesc = 'Damage: 4.5 • Reload: 1.5s • Capacity: 450 • Spread: 10° (Auto)';
    } else if (lvl < 40) {
      formName = 'Defender Form';
      description = 'Shoots larger, high-velocity energy spheres.';
      statsDesc = 'Damage: 6.5 • Reload: 1.1s • Capacity: 550 • Spread: 5°';
    } else if (lvl < 50) {
      formName = 'Vindicator Form';
      description = 'Fires faster with elevated accuracy and tighter groupings.';
      statsDesc = 'Damage: 6.5 • Reload: 1.1s • Capacity: 550 • Spread: 3°';
    } else if (lvl < 60) {
      formName = 'Laser Rifle';
      description = 'Fires sustained continuous rapid energy laser pulses.';
      statsDesc = 'Damage: 6.5 • Reload: 1.1s • Capacity: 550 • Spread: 2°';
    } else {
      formName = 'Awakened Gunderfury';
      description = 'Legendary form of the Blessed Gunseeker. Rapidly shoots twin light beams with absolute 0° spread, bouncing, and piercing!';
      statsDesc = 'Damage: 10.0 • Reload: 0.6s • Capacity: 650 • Spread: 0° (Perfect, Piercing, Bouncing)';
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF13151A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.35), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.purpleAccent.withValues(alpha: 0.04),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bolt, color: Colors.purpleAccent.shade100, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'GUNDERFURY HUD - LVL $lvl',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.purpleAccent.shade100,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              formName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.purpleAccent.shade100,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                            size: 18,
                            color: Colors.white30,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_expanded) ...[
                const Divider(color: Colors.white12, height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.15)),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          'assets/images/guns/gunderfury.webp',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white24,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              description,
                              style: const TextStyle(fontSize: 10.5, color: Colors.white70, height: 1.3),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              statsDesc,
                              style: TextStyle(
                                fontSize: 9.5,
                                color: Colors.purpleAccent.shade100.withValues(alpha: 0.8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.02),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'GUNDER LEVEL',
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white60),
                                        ),
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: lvl > 1 ? () => p.setGunderfuryLevel(lvl - 1) : null,
                                              behavior: HitTestBehavior.opaque,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                child: Icon(
                                                  Icons.remove_circle_rounded,
                                                  color: lvl > 1 ? Colors.purpleAccent : Colors.white24,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: Text(
                                                '$lvl',
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: lvl < 60 ? () => p.setGunderfuryLevel(lvl + 1) : null,
                                              behavior: HitTestBehavior.opaque,
                                              child: const Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                child: Icon(
                                                  Icons.add_circle_rounded,
                                                  color: Colors.purpleAccent,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TripleGunDashboardSliver extends StatefulWidget {
  final PlayerSlot slot;
  const _TripleGunDashboardSliver({required this.slot});

  @override
  State<_TripleGunDashboardSliver> createState() => _TripleGunDashboardSliverState();
}

class _TripleGunDashboardSliverState extends State<_TripleGunDashboardSliver> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
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

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF13151A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.35), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.04),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.alt_route, color: Colors.blueAccent.shade100, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'TRIPLE GUN HUD',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.blueAccent.shade100,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'FORM $form',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.blueAccent.shade100,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                            size: 18,
                            color: Colors.white30,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_expanded) ...[
                const Divider(color: Colors.white12, height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.15)),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          'assets/images/guns/triple_gun.webp',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white24,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formName,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formDesc,
                              style: const TextStyle(fontSize: 10, color: Colors.white70, height: 1.3),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.02),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'ACTIVE FORM',
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white60),
                                        ),
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: form > 1 ? () => p.setTripleGunForm(form - 1) : null,
                                              behavior: HitTestBehavior.opaque,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                child: Icon(
                                                  Icons.remove_circle_rounded,
                                                  color: form > 1 ? Colors.blueAccent : Colors.white24,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: Text(
                                                '$form',
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: form < 3 ? () => p.setTripleGunForm(form + 1) : null,
                                              behavior: HitTestBehavior.opaque,
                                              child: const Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                child: Icon(
                                                  Icons.add_circle_rounded,
                                                  color: Colors.blueAccent,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EvolverDashboardSliver extends StatefulWidget {
  final PlayerSlot slot;
  const _EvolverDashboardSliver({required this.slot});

  @override
  State<_EvolverDashboardSliver> createState() => _EvolverDashboardSliverState();
}

class _EvolverDashboardSliverState extends State<_EvolverDashboardSliver> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final activeStage = p.evolverForm;

    final stages = const [
      _EvolverStageSpec(id: 1, name: 'Amoeba', dps: '13.5 DPS', bullet: 'Base round shots', color: Colors.tealAccent),
      _EvolverStageSpec(id: 2, name: 'Sponge', dps: '19.1 DPS', bullet: 'Soaks up shots', color: Colors.greenAccent),
      _EvolverStageSpec(id: 3, name: 'Flatworm', dps: '25.8 DPS', bullet: 'Wide flattened shots', color: Colors.limeAccent),
      _EvolverStageSpec(id: 4, name: 'Snail', dps: '34.5 DPS', bullet: '3-spiked shell spread', color: Colors.amberAccent),
      _EvolverStageSpec(id: 5, name: 'Frog', dps: '23.0 DPS/sec', bullet: 'Tracking tongue', color: Colors.orangeAccent),
      _EvolverStageSpec(id: 6, name: 'Dragon', dps: '93.8 DPS', bullet: 'Accelerating homing blue flames', color: Colors.redAccent),
    ];

    final currentSpec = stages[activeStage - 1];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF13151A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.35), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withValues(alpha: 0.04),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bubble_chart, color: Colors.greenAccent.shade100, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'EVOLVER HUD',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.greenAccent.shade100,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'STAGE $activeStage: ${currentSpec.name.toUpperCase()}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: currentSpec.color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                            size: 18,
                            color: Colors.white30,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_expanded) ...[
                const Divider(color: Colors.white12, height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: currentSpec.color.withValues(alpha: 0.25)),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          'assets/images/guns/evolver.webp',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white24,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stage $activeStage: ${currentSpec.name} • ${currentSpec.dps}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: currentSpec.color),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Form Bullet: ${currentSpec.bullet}',
                              style: const TextStyle(fontSize: 10, color: Colors.white70, height: 1.3),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.02),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'EVOLUTION STAGE',
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white60),
                                        ),
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: activeStage > 1 ? () => p.setEvolverForm(activeStage - 1) : null,
                                              behavior: HitTestBehavior.opaque,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                child: Icon(
                                                  Icons.remove_circle_rounded,
                                                  color: activeStage > 1 ? Colors.greenAccent : Colors.white24,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: Text(
                                                '$activeStage',
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: activeStage < 6 ? () => p.setEvolverForm(activeStage + 1) : null,
                                              behavior: HitTestBehavior.opaque,
                                              child: const Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                child: Icon(
                                                  Icons.add_circle_rounded,
                                                  color: Colors.greenAccent,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
  final Color color;
  const _EvolverStageSpec({
    required this.id,
    required this.name,
    required this.dps,
    required this.bullet,
    required this.color,
  });
}


/// Damage Calculator bottom sheet — opened via the calc icon in the
/// GungeoneerHeader trailing row. Sums quantifiable "Damage Up"/"Damage
/// Down" effects from the player's current guns + items via
/// [DamageCalculator] and applies the resulting multiplier to every
/// equipped gun's base DPS.
class _DamageCalcSheet extends StatelessWidget {
  final PlayerSlot slot;
  const _DamageCalcSheet({required this.slot});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final player = slot == PlayerSlot.coop
        ? (p.runState.coop ?? Player())
        : p.runState.main;
    final guns = player.guns;

    final contributions = DamageCalculator.contributions(
      guns: guns,
      items: player.items,
    );
    final multiplier = DamageCalculator.multiplier(
      guns: guns,
      items: player.items,
    );
    final bonusPercent = (multiplier - 1.0) * 100.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16, 12, 16, 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.calculate_rounded, color: Colors.amberAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'DAMAGE CALCULATOR',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.amberAccent,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 1.0),
                ),
                child: Text(
                  '${bonusPercent >= 0 ? '+' : ''}${bonusPercent.toStringAsFixed(0)}% DMG',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.amberAccent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 20),
          if (contributions.isNotEmpty) ...[
            for (final c in contributions)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        c.sourceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ),
                    Text(
                      c.percent == 0
                          ? '—'
                          : '${c.percent >= 0 ? '+' : ''}${c.percent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: c.percent > 0
                            ? Colors.greenAccent
                            : c.percent < 0
                                ? Colors.redAccent
                                : Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF000800),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.25), width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      '> DMG_CALC v1.0',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.green.withValues(alpha: 0.5),
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '×${multiplier.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.greenAccent,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final gun in guns)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(
                            gun.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green.withValues(alpha: 0.85),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            gun.dpsValue.toStringAsFixed(1),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green.withValues(alpha: 0.6),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            (gun.dpsValue * multiplier).toStringAsFixed(1),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.greenAccent,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Container(height: 1, color: Colors.green.withValues(alpha: 0.15)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL DPS',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.green.withValues(alpha: 0.5),
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${guns.fold<double>(0, (sum, g) => sum + g.dpsValue).toStringAsFixed(1)} → ${guns.fold<double>(0, (sum, g) => sum + g.dpsValue * multiplier).toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.greenAccent,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Compact Huntress HUD: dig chance, item weights, mimic alert, and
/// treat/pet counters. No tabs — single concise card.
class _HuntressDashboardSliver extends StatefulWidget {
  const _HuntressDashboardSliver();

  @override
  State<_HuntressDashboardSliver> createState() => _HuntressDashboardSliverState();
}

class _HuntressDashboardSliverState extends State<_HuntressDashboardSliver> {
  int _petCount = 0;
  int _treatCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCounters();
  }

  Future<void> _loadCounters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _petCount = prefs.getInt('dog.pet_count') ?? 0;
          _treatCount = prefs.getInt('dog.treat_count') ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _incrementPet() async {
    Haptics.light();
    setState(() => _petCount++);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('dog.pet_count', _petCount);
    } catch (_) {}
  }

  Future<void> _incrementTreat() async {
    Haptics.light();
    setState(() => _treatCount++);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('dog.treat_count', _treatCount);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final ownedLower = p.runState.main.items.map((i) => i.name.toLowerCase()).toSet();
    final hasBabyGoodMimic = ownedLower.any((n) => n.contains('baby good mimic'));
    final digChance = hasBabyGoodMimic ? 10.0 : 5.0;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF101408),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.lightGreen.withValues(alpha: 0.35), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header + dig chance badge
              Row(
                children: [
                  const Icon(Icons.pets_rounded, color: Colors.lightGreenAccent, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'HUNTRESS & DOG',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.lightGreenAccent, letterSpacing: 0.8),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: hasBabyGoodMimic ? Colors.purple.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: hasBabyGoodMimic ? Colors.purpleAccent : Colors.lightGreenAccent, width: 0.8),
                    ),
                    child: Text(
                      'DIG: ${digChance.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: hasBabyGoodMimic ? Colors.purpleAccent : Colors.lightGreenAccent),
                    ),
                  ),
                ],
              ),
              if (hasBabyGoodMimic)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '✨ Baby Good Mimic active — dig rate doubled',
                    style: TextStyle(fontSize: 9.5, fontStyle: FontStyle.italic, color: Colors.purpleAccent.shade100),
                  ),
                ),
              const SizedBox(height: 10),
              // Item weights row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildWeight('❤️', '45%', Colors.redAccent),
                  _buildWeight('🔑', '20%', Colors.amberAccent),
                  _buildWeight('🛡️', '15%', Colors.blueAccent),
                  _buildWeight('📦', '15%', Colors.orangeAccent),
                  _buildWeight('💥', '5%', Colors.pinkAccent),
                ],
              ),
              const SizedBox(height: 10),
              // Mimic alert
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 14),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Junior II growls at mimic chests before they wake.',
                        style: TextStyle(fontSize: 9.5, color: Colors.redAccent, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Treat/Pet counters
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _incrementTreat,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.orangeAccent, size: 14),
                            const SizedBox(width: 6),
                            Text('TREATS: $_treatCount', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: _incrementPet,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.pinkAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 14),
                            const SizedBox(width: 6),
                            Text('PETS: $_petCount', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeight(String emoji, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(emoji, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

// =============================================================================
// Special Dashboard Swiper — PageView carousel for all active special dashboards
// =============================================================================

class _DashboardSwiper extends StatefulWidget {
  final PlayerSlot slot;
  const _DashboardSwiper({required this.slot});

  @override
  State<_DashboardSwiper> createState() => _DashboardSwiperState();
}

class _DashboardSwiperState extends State<_DashboardSwiper> {
  late final PageController _pc;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pc = PageController();
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final player = widget.slot == PlayerSlot.main ? p.runState.main : p.runState.coop;
    if (player == null) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final ownedGunNames = player.guns.map((g) => g.name.toLowerCase()).toSet();
    final ownedItemNames = player.items.map((i) => i.name.toLowerCase()).toSet();
    final charName = player.character?.name.toLowerCase() ?? '';

    // Build list of active dashboards
    final dashboards = <Widget>[];
    final labels = <String>[];

    if (charName.contains('robot')) {
      dashboards.add(const _RobotDashboardSliver());
      labels.add('ROBOT');
    }
    if (charName.contains('hunter')) {
      dashboards.add(const _HuntressDashboardSliver());
      labels.add('HUNTRESS');
    }
    if (ownedItemNames.any((n) => n.contains('ser junkan'))) {
      dashboards.add(_JunkanDashboardSliver(slot: widget.slot));
      labels.add('JUNKAN');
    }
    if (ownedGunNames.contains('gunderfury')) {
      dashboards.add(_GunderfuryDashboardSliver(slot: widget.slot));
      labels.add('GUNDERFURY');
    }
    if (ownedGunNames.contains('triple gun')) {
      dashboards.add(_TripleGunDashboardSliver(slot: widget.slot));
      labels.add('TRIPLE GUN');
    }
    if (ownedGunNames.contains('evolver')) {
      dashboards.add(_EvolverDashboardSliver(slot: widget.slot));
      labels.add('EVOLVER');
    }
    if (ownedGunNames.contains('shellegun')) {
      dashboards.add(_ShellegunDashboard(slot: widget.slot));
      labels.add('SHELLEGUN');
    }
    if (ownedGunNames.contains('chamber gun')) {
      dashboards.add(_ChamberGunDashboard(slot: widget.slot));
      labels.add('CHAMBER GUN');
    }
    if (ownedItemNames.contains('platinum bullets')) {
      dashboards.add(_PlatinumBulletsDashboard(slot: widget.slot));
      labels.add('PLATINUM');
    }
    if (ownedItemNames.contains('iron coin')) {
      dashboards.add(_IronCoinDashboard(slot: widget.slot));
      labels.add('IRON COIN');
    }
    if (ownedItemNames.contains('spice')) {
      dashboards.add(_SpiceDashboard(slot: widget.slot));
      labels.add('SPICE');
    }
    if (ownedItemNames.contains('metronome')) {
      dashboards.add(_MetronomeDashboard(slot: widget.slot));
      labels.add('METRONOME');
    }
    if (ownedItemNames.contains('sprun')) {
      dashboards.add(_SprunDashboard(slot: widget.slot));
      labels.add('SPRUN');
    }
    if (ownedGunNames.contains('boxing glove')) {
      dashboards.add(_BoxingGloveDashboard(slot: widget.slot));
      labels.add('BOXING');
    }
    if (ownedItemNames.contains('cigarettes')) {
      dashboards.add(_CigarettesDashboard(slot: widget.slot));
      labels.add('CIGARETTES');
    }
    if (dashboards.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    // Clamp page index
    if (_page >= dashboards.length) _page = 0;

    return SliverToBoxAdapter(
      child: Column(
        children: [
          SizedBox(
            height: 320,
            child: PageView.builder(
              controller: _pc,
              itemCount: dashboards.length,
              onPageChanged: (i) {
                setState(() => _page = i);
                Haptics.selection();
              },
              itemBuilder: (context, i) => CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [dashboards[i]],
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Dot indicators + label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < dashboards.length; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page ? Colors.lightGreenAccent : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            labels.isNotEmpty && _page < labels.length ? labels[_page] : '',
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// =============================================================================
// New compact dashboards for Shellegun, Chamber Gun, Platinum Bullets, Iron Coin
// =============================================================================

class _ShellegunDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const _ShellegunDashboard({required this.slot});

  @override
  State<_ShellegunDashboard> createState() => _ShellegunDashboardState();
}

class _ShellegunDashboardState extends State<_ShellegunDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final mode = p.shellegunMode;

    const modes = ['Pistol (Manual)', 'Pistol (Auto)', 'Beam'];
    const descriptions = [
      'Semi-auto energy pistol. Moderate fire rate, high accuracy.',
      'Fully automatic. Increased fire rate, same damage per shot.',
      'Continuous energy beam. Highest DPS, consumes ammo rapidly.',
    ];
    const dpsValues = [18.0, 27.5, 42.0];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1218),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.cyan.withValues(alpha: 0.35), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield_moon_rounded, color: Colors.cyanAccent, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'SHELLEGUN',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.cyanAccent, letterSpacing: 0.8),
                  ),
                  const Spacer(),
                  Text(
                    'DPS: ${dpsValues[mode - 1].toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.cyanAccent),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _modeBtn('Manual', mode == 1, () => p.setShellegunMode(1)),
                  _modeBtn('Auto', mode == 2, () => p.setShellegunMode(2)),
                  _modeBtn('Beam', mode == 3, () => p.setShellegunMode(3)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                modes[mode - 1],
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                descriptions[mode - 1],
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7), height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeBtn(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: () { Haptics.light(); onTap(); },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.cyan.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? Colors.cyanAccent : Colors.white12),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.bold : FontWeight.normal, color: active ? Colors.cyanAccent : Colors.white60)),
      ),
    );
  }
}

class _ChamberGunDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const _ChamberGunDashboard({required this.slot});

  @override
  State<_ChamberGunDashboard> createState() => _ChamberGunDashboardState();
}

class _ChamberGunDashboardState extends State<_ChamberGunDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const _floors = [
    'Keep of the Lead Lord', 'Oubliette', 'Gungeon Proper', 'Abbey of the True Gun',
    'Black Powder Mine', "Rat's Lair", 'The Hollow', 'R&G Dept', 'The Forge', 'Bullet Hell',
  ];
  static const _dps = [15.0, 18.5, 22.0, 26.0, 30.0, 34.0, 38.5, 43.0, 48.0, 55.0];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final floor = p.chamberGunFloor;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF120E08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.35), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.apartment_rounded, color: Colors.amberAccent, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'CHAMBER GUN',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.amberAccent, letterSpacing: 0.8),
                  ),
                  const Spacer(),
                  Text(
                    'DPS: ${_dps[floor].toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.amberAccent),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'FLOOR ${floor + 1}: ${_floors[floor]}',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              // Floor selector — horizontal scrollable row
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 10,
                  separatorBuilder: (_, __) => const SizedBox(width: 4),
                  itemBuilder: (context, i) {
                    final active = i == floor;
                    return InkWell(
                      onTap: () { Haptics.light(); p.setChamberGunFloor(i); },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: active ? Colors.amber.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: active ? Colors.amberAccent : Colors.white12),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.bold : FontWeight.normal, color: active ? Colors.amberAccent : Colors.white54),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlatinumBulletsDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const _PlatinumBulletsDashboard({required this.slot});

  @override
  State<_PlatinumBulletsDashboard> createState() => _PlatinumBulletsDashboardState();
}

class _PlatinumBulletsDashboardState extends State<_PlatinumBulletsDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final kills = p.platinumBulletsKills;
    final dmgBonus = (kills * 0.5).toStringAsFixed(1);
    final fireRateBonus = (kills * 0.2).toStringAsFixed(1);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF100E18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.35), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.military_tech_rounded, color: Colors.purpleAccent, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'PLATINUM BULLETS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.purpleAccent, letterSpacing: 0.8),
                  ),
                  const Spacer(),
                  Text(
                    '$kills kills',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.purpleAccent),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _statChip('DMG +$dmgBonus%', Colors.redAccent),
                  const SizedBox(width: 8),
                  _statChip('FIRE RATE +$fireRateBonus%', Colors.orangeAccent),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Each kill stacks +0.5% damage and +0.2% fire rate. Bonus persists for the entire run.',
                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.6), height: 1.3),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    onPressed: kills > 0 ? () { Haptics.light(); p.setPlatinumBulletsKills(kills - 1); } : null,
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.purpleAccent, size: 20),
                  ),
                  Text('$kills', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                  IconButton(
                    onPressed: () { Haptics.light(); p.setPlatinumBulletsKills(kills + 1); },
                    icon: const Icon(Icons.add_circle_outline, color: Colors.purpleAccent, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

class _IronCoinDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const _IronCoinDashboard({required this.slot});

  @override
  State<_IronCoinDashboard> createState() => _IronCoinDashboardState();
}

class _IronCoinDashboardState extends State<_IronCoinDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final uses = p.ironCoinUses;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF181210),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.brown.withValues(alpha: 0.4), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.paid_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'IRON COIN',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.amber, letterSpacing: 0.8),
                  ),
                  const Spacer(),
                  Text(
                    '$uses/3 uses',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: uses > 0 ? Colors.amber : Colors.white30),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Coin icons row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int i = 0; i < 3; i++)
                    Icon(
                      Icons.paid_rounded,
                      size: 32,
                      color: i < uses ? Colors.amber : Colors.white.withValues(alpha: 0.1),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Flip to reveal/destroy a chest's contents. 3 uses per run. Use wisely on high-tier chests.",
                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.6), height: 1.3),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: uses < 3 ? () { Haptics.light(); p.setIronCoinUses(uses + 1); } : null,
                    icon: const Icon(Icons.add_circle_outline, color: Colors.amber, size: 20),
                  ),
                  IconButton(
                    onPressed: uses > 0 ? () { Haptics.light(); p.setIronCoinUses(uses - 1); } : null,
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.amber, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// New dashboards: Spice, Metronome, Sprun, Boxing Glove, Cigarettes
// =============================================================================

class _SpiceDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const _SpiceDashboard({required this.slot});

  @override
  State<_SpiceDashboard> createState() => _SpiceDashboardState();
}

class _SpiceDashboardState extends State<_SpiceDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final count = p.spiceUsageCount;

    final damageBonus = count <= 4
        ? [0, 0, 20, 40, 55][count.clamp(0, 4)]
        : 55 + (count - 4) * 15;
    final curseTotal = count == 0
        ? 0.0
        : count == 1
            ? 0.5
            : 0.5 + (count - 1);
    final heartChange = count <= 1 ? count : (2 - count).clamp(-2, 1);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF180E0E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.spa, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'SPICE',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.redAccent, letterSpacing: 0.8),
                  ),
                  const Spacer(),
                  Text(
                    '+$damageBonus% DMG',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.redAccent),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statChip('Uses', '$count'),
                  _statChip('Curse', '+${curseTotal.toStringAsFixed(1)}'),
                  _statChip('Hearts', heartChange == 0 ? '0' : heartChange > 0 ? '+$heartChange' : '$heartChange'),
                  _statChip('Dmg', '+$damageBonus%'),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                count == 0
                    ? 'No Spice used. 1st use: +1 Heart, +1 Cool, +20% Shot Speed, -10% Spread, +0.5 Curse.'
                    : count < 5
                        ? 'Escalating bonuses. Each use adds damage but costs hearts and curse.'
                        : 'Diminishing returns: +15% Dmg, +1.0 Curse per additional use.',
                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.6), height: 1.3),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: count > 0 ? () { Haptics.light(); p.setSpiceUsageCount(count - 1); } : null,
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                  ),
                  Text('$count', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  IconButton(
                    onPressed: () { Haptics.light(); p.setSpiceUsageCount(count + 1); },
                    icon: const Icon(Icons.add_circle_outline, color: Colors.redAccent, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.4))),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent)),
      ],
    );
  }
}

class _MetronomeDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const _MetronomeDashboard({required this.slot});

  @override
  State<_MetronomeDashboard> createState() => _MetronomeDashboardState();
}

class _MetronomeDashboardState extends State<_MetronomeDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final kills = p.metronomeKills;
    final damageBonus = (kills * 2).clamp(0, 150);
    final progress = kills / 75.0;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1218),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.35), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.speed, color: Colors.tealAccent, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'METRONOME',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.tealAccent, letterSpacing: 0.8),
                  ),
                  const Spacer(),
                  Text(
                    '+$damageBonus% DMG',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.tealAccent),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation(Colors.tealAccent.withValues(alpha: 0.8)),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$kills / 75 kills',
                    style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5)),
                  ),
                  Text(
                    kills >= 75 ? 'MAX STACK' : '${75 - kills} to max',
                    style: TextStyle(fontSize: 10, color: Colors.tealAccent.withValues(alpha: 0.6)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '+2% damage per kill. Resets if you take damage or swap guns. Max +150% at 75 kills.',
                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5), height: 1.3),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: kills > 0 ? () { Haptics.light(); p.setMetronomeKills(kills - 1); } : null,
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.tealAccent, size: 20),
                  ),
                  Text('$kills', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.tealAccent)),
                  IconButton(
                    onPressed: kills < 75 ? () { Haptics.light(); p.setMetronomeKills(kills + 1); } : null,
                    icon: const Icon(Icons.add_circle_outline, color: Colors.tealAccent, size: 20),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () { Haptics.selection(); p.setMetronomeKills(0); },
                    child: const Text('Reset', style: TextStyle(fontSize: 10, color: Colors.redAccent)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SprunDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const _SprunDashboard({required this.slot});

  @override
  State<_SprunDashboard> createState() => _SprunDashboardState();
}

class _SprunDashboardState extends State<_SprunDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const _triggers = [
    'Activating a Map Blank',
    'Taking damage to Armor / Losing a half-heart',
    'Throwing an empty weapon at a wall',
    'Falling down an elevator shaft or trap pit',
    'Lighting yourself on fire or stepping into a poison pool',
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final idx = p.sprunTriggerIndex;
    final isWindgunnerActive = p.windgunnerCountdown > 0;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1018),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.35), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.radar, color: Colors.cyanAccent.shade200, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'SPRUN',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.cyanAccent, letterSpacing: 0.8),
                  ),
                  const Spacer(),
                  if (isWindgunnerActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        'WINDGUNNER ${p.windgunnerCountdown}s',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                      ),
                    )
                  else
                    Text(
                      idx >= 0 ? 'REVEALED' : 'UNKNOWN',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.cyanAccent.withValues(alpha: 0.6)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (idx >= 0)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.cyan.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flash_on, color: Colors.cyanAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _triggers[idx],
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.cyanAccent),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  'Trigger unknown. Tap "Reveal" to discover this run\'s Windgunner activation condition.',
                  style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5), height: 1.3),
                ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Haptics.selection();
                      final randomIdx = DateTime.now().millisecondsSinceEpoch % _triggers.length;
                      p.setSprunTriggerIndex(randomIdx);
                    },
                    child: const Text('Reveal Trigger', style: TextStyle(fontSize: 11, color: Colors.cyanAccent)),
                  ),
                  if (idx >= 0) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () { Haptics.light(); p.setSprunTriggerIndex(-1); },
                      child: const Text('Hide', style: TextStyle(fontSize: 11, color: Colors.white38)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoxingGloveDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const _BoxingGloveDashboard({required this.slot});

  @override
  State<_BoxingGloveDashboard> createState() => _BoxingGloveDashboardState();
}

class _BoxingGloveDashboardState extends State<_BoxingGloveDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final stars = p.boxingGloveStars;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF181410),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.35), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sports_mma_rounded, color: Colors.orangeAccent, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'BOXING GLOVE',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.orangeAccent, letterSpacing: 0.8),
                  ),
                  const Spacer(),
                  Text(
                    stars == 3 ? 'SUPER PUNCH READY' : '$stars/3 stars',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: stars == 3 ? Colors.orangeAccent : Colors.white.withValues(alpha: 0.5)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Star icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int i = 0; i < 3; i++)
                    Icon(
                      Icons.star_rounded,
                      size: 36,
                      color: i < stars
                          ? Colors.orangeAccent
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                stars == 3
                    ? '3 stars! Charge the gun to consume stars and fire a high-damage super punch.'
                    : 'Gains a star per kill (up to 3). Chance to stun on hit. Increases curse by 1.',
                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.6), height: 1.3),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: stars > 0 ? () { Haptics.light(); p.setBoxingGloveStars(stars - 1); } : null,
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.orangeAccent, size: 20),
                  ),
                  Text('$stars', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                  IconButton(
                    onPressed: stars < 3 ? () { Haptics.light(); p.setBoxingGloveStars(stars + 1); } : null,
                    icon: const Icon(Icons.add_circle_outline, color: Colors.orangeAccent, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CigarettesDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const _CigarettesDashboard({required this.slot});

  @override
  State<_CigarettesDashboard> createState() => _CigarettesDashboardState();
}

class _CigarettesDashboardState extends State<_CigarettesDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final uses = p.cigarettesUses;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF121418),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.4), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.smoking_rooms, color: Colors.blueGrey, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'CIGARETTES',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 0.8),
                  ),
                  const Spacer(),
                  Text(
                    '+$uses Cool',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statChip('Uses', '$uses'),
                  _statChip('Coolness', '+$uses'),
                  _statChip('Cost', '-$uses half-hearts'),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Each use: -half a heart, +1 Coolness. Coolness decreases active item cooldowns and increases luck.',
                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.6), height: 1.3),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: uses > 0 ? () { Haptics.light(); p.setCigarettesUses(uses - 1); } : null,
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.blueGrey, size: 20),
                  ),
                  Text('$uses', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  IconButton(
                    onPressed: () { Haptics.light(); p.setCigarettesUses(uses + 1); },
                    icon: const Icon(Icons.add_circle_outline, color: Colors.blueGrey, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.4))),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
      ],
    );
  }
}

/// Compact, always-visible effects accordion that sits right under the
/// character header. Closed by default so it stays out of the way; tap
/// the header bar to expand and inspect every active passive/effect.
class _EffectsTile extends StatefulWidget {
  final PlayerSlot slot;
  const _EffectsTile({required this.slot});

  @override
  State<_EffectsTile> createState() => _EffectsTileState();
}

class _EffectsTileState extends State<_EffectsTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final state = p.runState;
    final player =
        widget.slot == PlayerSlot.main ? state.main : state.coop;
    if (player == null) return const SizedBox.shrink();
    final scan = EffectTagger.scan(guns: player.guns, items: player.items);
    final tags = scan.keys.toList();
    final totalTags = tags.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Header bar — always visible, single compact line.
            InkWell(
              onTap: totalTags == 0
                  ? null
                  : () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(12, 10, 6, 10),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: Colors.amber, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Effects',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: totalTags == 0
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.amber.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$totalTags',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: totalTags == 0
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.amber,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (totalTags > 0)
                      IconButton(
                        tooltip: 'Open detailed breakdown',
                        icon: const Icon(Icons.open_in_new,
                            size: 16, color: Colors.white54),
                        onPressed: () => Navigator.push(
                          context,
                          _fastRoute(EffectsSummaryScreen(slot: widget.slot)),
                        ),
                      ),
                    if (totalTags > 0)
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(Icons.expand_more,
                            color: Colors.white54),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text(
                          'none',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.4),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Body — only mounted when expanded; full chip wall.
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _expanded && totalTags > 0
                  ? Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final t in tags)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: t.category.color
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: t.category.color
                                        .withValues(alpha: 0.35)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(t.icon,
                                      size: 12,
                                      color: t.category.color),
                                  const SizedBox(width: 4),
                                  Text(
                                    t.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: t.category.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderMenu extends StatelessWidget {
  const _HeaderMenu();

  @override
  Widget build(BuildContext context) {
    final p = context.read<RunProvider>();
    final hasCoop = p.runState.hasCoop;
    final mpSession = context.watch<MultiplayerSession>();
    final mpActive = mpSession.isActive;
    return PopupMenuButton<String>(
      tooltip: 'Run options',
      // Big single-icon target — gear is universally read as "options".
      // Bigger hit-rect than the old "Run ▼" chip (44×44 vs 28×24).
      padding: EdgeInsets.zero,
      offset: const Offset(0, 44),
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: const Icon(Icons.tune_rounded, size: 18, color: Colors.white70),
      ),
      onSelected: (v) {
        switch (v) {
          case 'vibe':
            Navigator.push(
              context,
              _fastRoute(const ThemePickerScreen()),
            );
            break;
          case 'favourites':
            Navigator.push(
              context,
              _fastRoute(const FavouritesScreen(embedded: false)),
            );
            break;
          case 'use_shrine':
            Navigator.push(
              context,
              _fastRoute(const ShrinePickerScreen()),
            );
            break;
          case 'steal':
            p.adjustCurse(1);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Steal → Curse +1'),
                duration: Duration(milliseconds: 1600),
                behavior: SnackBarBehavior.floating,
              ),
            );
            break;
          case 'cursula':
            p.adjustCurse(2.5);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bought from Cursula → Curse +2.5'),
                duration: Duration(milliseconds: 1600),
                behavior: SnackBarBehavior.floating,
              ),
            );
            break;
          case 'add_player':
            _addCoopPlayer(context);
            break;
          case 'remove_player':
            _confirmRemoveCoop(context, p);
            break;
          case 'dice_roll':
            _showDiceRollDialog(context);
            break;
          case 'end_run':
            _confirmEndRun(context, p);
            break;
          case 'leave_mp':
            _confirmLeaveMp(context, mpSession);
            break;
          case 'reset_items_p1':
            p.clearInventory(slot: PlayerSlot.main);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Player 1 inventory reset!'),
                duration: Duration(milliseconds: 1400),
                behavior: SnackBarBehavior.floating,
              ),
            );
            break;
          case 'reset_items_p2':
            p.clearInventory(slot: PlayerSlot.coop);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Player 2 inventory reset!'),
                duration: Duration(milliseconds: 1400),
                behavior: SnackBarBehavior.floating,
              ),
            );
            break;
          case 'save_mp_session':
            unawaited(mpSession.saveCurrentSession().then((_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Run saved'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }).catchError((e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to save session: $e'),
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }));
            break;
          case 'help':
            _showHelpDialog(context);
            break;
        }
      },
      itemBuilder: (ctx) => [
        // --- Group 1: Guides & Info ---
        const PopupMenuItem(
          value: 'favourites',
          child: Row(children: [
            Icon(Icons.favorite_rounded, size: 18, color: Colors.pinkAccent),
            SizedBox(width: 10),
            Text('My Favourites'),
          ]),
        ),
        const PopupMenuItem(
          value: 'help',
          child: Row(children: [
            Icon(Icons.help_outline_rounded, size: 18, color: Colors.tealAccent),
            SizedBox(width: 10),
            Text('Help & Tips'),
          ]),
        ),
        const PopupMenuDivider(),

        // --- Group 2: Actions & Mechanics ---
        const PopupMenuItem(
          value: 'use_shrine',
          child: Row(children: [
            Icon(Icons.temple_buddhist, size: 18, color: Colors.amber),
            SizedBox(width: 10),
            Text('Use Shrine'),
          ]),
        ),
        const PopupMenuItem(
          value: 'steal',
          child: Row(children: [
            Icon(Icons.front_hand_outlined, size: 18, color: Color(0xFFEF5350)),
            SizedBox(width: 10),
            Text('Steal item  (+1 curse)'),
          ]),
        ),
        const PopupMenuItem(
          value: 'cursula',
          child: Row(children: [
            Icon(Icons.storefront_outlined, size: 18, color: Color(0xFFCE93D8)),
            SizedBox(width: 10),
            Text('Cursula Buy  (+2.5 curse)'),
          ]),
        ),
        const PopupMenuItem(
          value: 'dice_roll',
          child: Row(children: [
            Icon(Icons.casino_outlined, size: 18, color: Color(0xFFFFD54F)),
            SizedBox(width: 10),
            Text('Gunfortuna Dice Roll'),
          ]),
        ),
        const PopupMenuDivider(),

        // --- Group 3: System, Resets & Admin ---
        if (mpActive) ...[
          const PopupMenuItem(
            value: 'save_mp_session',
            child: Row(children: [
              Icon(Icons.save_outlined, size: 18, color: Colors.greenAccent),
              SizedBox(width: 10),
              Text('Save MP Session'),
            ]),
          ),
        ],
        const PopupMenuItem(
          value: 'reset_items_p1',
          child: Row(children: [
            Icon(Icons.restart_alt_rounded, size: 18, color: Colors.cyanAccent),
            SizedBox(width: 10),
            Text('Reset Player 1 Items'),
          ]),
        ),
        if (hasCoop)
          const PopupMenuItem(
            value: 'reset_items_p2',
            child: Row(children: [
              Icon(Icons.restart_alt_rounded, size: 18, color: Colors.pinkAccent),
              SizedBox(width: 10),
              Text('Reset Player 2 Items'),
            ]),
          ),
        if (!hasCoop && !mpActive)
          const PopupMenuItem(
            value: 'add_player',
            child: Row(children: [
              Icon(Icons.person_add_alt, size: 18),
              SizedBox(width: 10),
              Text('Add Player (Co-op)'),
            ]),
          ),
        if (hasCoop && !mpActive)
          const PopupMenuItem(
            value: 'remove_player',
            child: Row(children: [
              Icon(Icons.person_remove_alt_1, size: 18),
              SizedBox(width: 10),
              Text('Remove Player'),
            ]),
          ),
        if (mpActive && mpSession.myRole == MpRole.sidekick) ...[
          const PopupMenuItem(
            value: 'leave_mp',
            child: Row(children: [
              Icon(Icons.bluetooth_disabled,
                  size: 18, color: Colors.lightBlueAccent),
              SizedBox(width: 10),
              Text('Leave Multiplayer'),
            ]),
          ),
          const PopupMenuItem(
            value: 'end_run',
            child: Row(children: [
              Icon(Icons.exit_to_app, size: 18, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('End Run & Disconnect', style: TextStyle(color: Colors.redAccent)),
            ]),
          ),
        ] else ...[
          const PopupMenuItem(
            value: 'end_run',
            child: Row(children: [
              Icon(Icons.exit_to_app, size: 18, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('End Run', style: TextStyle(color: Colors.redAccent)),
            ]),
          ),
        ],
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.tealAccent, width: 1.0),
        ),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Colors.tealAccent, size: 24),
            SizedBox(width: 10),
            Text(
              'GungeonMate Help & Tips',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Scrollbar(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHelpSection(
                    title: '👉 Swipe-to-Delete',
                    desc: 'Swipe any item or gun row from right-to-left in List View to instantly delete it from your inventory. Clean, swift, and game-ready!',
                    color: Colors.redAccent,
                  ),
                  _buildHelpSection(
                    title: '🎨 Responsive Theme Customizer',
                    desc: 'Rotate your phone or use a tablet to view the theme select and customize panels side-by-side with fully live rendering fonts, custom weights, and glowing particles!',
                    color: Colors.tealAccent,
                  ),
                  _buildHelpSection(
                    title: '🤖 Ser Junkan Level Tracker',
                    desc: 'Open Ser Junkan\'s detail view to see a dedicated rank and stats tracker complete with crisp, real-time updated pixel-art of his forms as you collect Junk!',
                    color: Colors.amberAccent,
                  ),
                  _buildHelpSection(
                    title: '🎲 Gunfortuna Dice Roll',
                    desc: 'Play custom 3D dice rolling challenges with your co-op partner directly during active runs! Open it from this options gear menu.',
                    color: const Color(0xFFFFD54F),
                  ),
                  _buildHelpSection(
                    title: '📊 Dual-Player Live HUD',
                    desc: 'The top dashboard keeps you and your sidekick updated on exact, un-squished live parameters: Coolness, Curse, Synergies, and maximum DPS.',
                    color: Colors.blueAccent,
                  ),
                  _buildHelpSection(
                    title: '🔗 Wiki Back-references',
                    desc: 'Explore item notes to discover secrets! The "Referenced by" panel lists all items whose lore mentions your currently viewed gear.',
                    color: Colors.purpleAccent,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'DISMISS',
              style: TextStyle(
                color: Colors.tealAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection({required String title, required String desc, required Color color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 11.5,
              color: Colors.white70,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.white12, height: 1),
        ],
      ),
    );
  }

  void _addCoopPlayer(BuildContext context) {
    // Default to The Cultist (mirrors MP Sidekick behaviour and matches
    // the base game's drop-in co-op partner). If the user wants a
    // different Gungeoneer for Player 2 they can long-press the menu
    // entry to open the full picker — see `onLongPressedAddPlayer`.
    final p = context.read<RunProvider>();
    final cultist = p.gungeoneerByName('The Cultist') ??
        p.gungeoneerByName('Cultist');
    if (cultist != null) {
      p.startCoopPlayer(cultist);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${cultist.name} joined as Player 2'),
        duration: const Duration(milliseconds: 1400),
        action: SnackBarAction(
          label: 'CHANGE',
          onPressed: () => Navigator.push(
            context,
            _fastRoute(const CharacterSelectScreen(mode: CharSelectMode.coop)),
          ),
        ),
      ));
      return;
    }
    // Cultist not found in master data — fall back to the manual picker.
    Navigator.push(
      context,
      _fastRoute(const CharacterSelectScreen(mode: CharSelectMode.coop)),
    );
  }

  void _confirmRemoveCoop(BuildContext context, RunProvider p) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remove Player 2?'),
        content: const Text(
            'Their loadout will be discarded. Items are not transferred to Player 1.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade900),
            onPressed: () {
              p.endCoopPlayer();
              Navigator.pop(c);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveMp(BuildContext context, MultiplayerSession session) {
    final isSidekick = session.myRole == MpRole.sidekick;
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.bluetooth_disabled,
            color: Colors.lightBlueAccent),
        title: const Text('Leave Multiplayer?'),
        content: Text(
          isSidekick
              ? 'Disconnects from the host. Your pre-multiplayer solo '
                  'run (if any) will be restored. Items the host gave '
                  'you during this session are not kept.'
              : 'Disconnects from the sidekick. Your run continues '
                  'locally with whatever you currently have.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Stay'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade900),
            onPressed: () async {
              Navigator.pop(c);
              await session.cancel();
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _confirmEndRun(BuildContext context, RunProvider p) {
    final session = context.read<MultiplayerSession>();
    final isSidekick = session.isActive && session.myRole == MpRole.sidekick;

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(isSidekick ? 'End Run & Disconnect?' : 'End Run?'),
        content: Text(isSidekick
            ? 'This will disconnect you from the host, reset the current session, and return you to the main menu.'
            : 'This resets the current run and returns to the main menu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade900),
            onPressed: () async {
              Navigator.pop(c);
              if (session.isActive) {
                // Tells the peer to end too, then tears the MP session down cleanly.
                await session.notifyEndRunAndCancel();
              }
              // Wipe local run state and pop screens to return to the main menu
              p.endRun();
            },
            child: Text(isSidekick ? 'End & Disconnect' : 'End Run'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeaderSliver extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;

  /// Optional sort affordance. When provided, the row gains a tappable
  /// pill on the right showing the active sort label and a small
  /// `Icons.sort` glyph that opens a picker bottom sheet on tap.
  final String? sortLabel;
  final VoidCallback? onTapSort;

  /// Optional premium layout selector dropdown.
  final bool showLayoutSelector;
  final _InvView? currentInvView;
  final InventoryDisplayMode? currentDisplayMode;
  final ValueChanged<Object>? onLayoutChanged;

  const _SectionHeaderSliver({
    required this.title,
    required this.count,
    required this.icon,
    this.sortLabel,
    this.onTapSort,
    this.showLayoutSelector = false,
    this.currentInvView,
    this.currentDisplayMode,
    this.onLayoutChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Determine active icon for layout selector button
    IconData getActiveLayoutIcon() {
      if (currentInvView == _InvView.list) {
        return Icons.view_list_rounded;
      }
      switch (currentDisplayMode ?? InventoryDisplayMode.classicPeriodic) {
        case InventoryDisplayMode.classicPeriodic:
          return Icons.grid_view_rounded;
        case InventoryDisplayMode.tacticalStats:
          return Icons.assessment_outlined;
      }
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white70),
            const SizedBox(width: 6),
            Text(
              '$title  ',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const Spacer(),
            if (sortLabel != null && onTapSort != null && count > 1)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onTapSort,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          sortLabel!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.sort,
                          size: 13,
                          color: Colors.white54,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (showLayoutSelector && onLayoutChanged != null) ...[
              const SizedBox(width: 6),
              PopupMenuButton<Object>(
                tooltip: 'Select layout style',
                icon: Icon(getActiveLayoutIcon(), size: 18, color: Colors.white70),
                offset: const Offset(0, 36),
                color: const Color(0xFF232326),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Colors.white10),
                ),
                onSelected: onLayoutChanged,
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: _InvView.list,
                    child: Row(
                      children: [
                        Icon(Icons.view_list_rounded, size: 15, color: currentInvView == _InvView.list ? Colors.amberAccent : Colors.white60),
                        const SizedBox(width: 8),
                        Text('List View', style: TextStyle(fontSize: 12, color: currentInvView == _InvView.list ? Colors.amberAccent : Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem(
                    value: InventoryDisplayMode.classicPeriodic,
                    child: Row(
                      children: [
                        Icon(Icons.grid_view_rounded, size: 15, color: (currentInvView == _InvView.grid && currentDisplayMode == InventoryDisplayMode.classicPeriodic) ? Colors.amberAccent : Colors.white60),
                        const SizedBox(width: 8),
                        Text('Periodic Grid', style: TextStyle(fontSize: 12, color: (currentInvView == _InvView.grid && currentDisplayMode == InventoryDisplayMode.classicPeriodic) ? Colors.amberAccent : Colors.white)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: InventoryDisplayMode.tacticalStats,
                    child: Row(
                      children: [
                        Icon(Icons.assessment_outlined, size: 15, color: (currentInvView == _InvView.grid && currentDisplayMode == InventoryDisplayMode.tacticalStats) ? Colors.amberAccent : Colors.white60),
                        const SizedBox(width: 8),
                        Text('Tactical Stats', style: TextStyle(fontSize: 12, color: (currentInvView == _InvView.grid && currentDisplayMode == InventoryDisplayMode.tacticalStats) ? Colors.amberAccent : Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// _EmptySection was replaced by _StarterHint, which surfaces the
// character's starting loadout as ghosted tappable tiles instead of a
// plain "no items yet" string.

/// Inline coolness/curse adjuster shown by long-pressing either bubble
/// on the run header. Reads the current value from the provider on
/// every rebuild so successive taps stack visibly without dismissing.
///
/// We render four +/- chips per side (-5, -1, +1, +5) which covers the
/// common ETG deltas: most shrines & passives shift coolness by 1, the
/// "big" shrines shift by 4-5. A "Reset to 0" link sits below the row
/// for quick zeroing.
class _StatAdjusterSheet extends StatelessWidget {
  final bool isCool;
  const _StatAdjusterSheet({required this.isCool});


  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final value = isCool ? p.runState.coolness : p.runState.curse;
    final accent = isCool
        ? const Color(0xFF29B6F6)
        : const Color(0xFFD32F2F);
    final label = isCool ? 'Coolness' : 'Curse';
    final icon = isCool ? Icons.ac_unit : Icons.warning_amber_rounded;

    void apply(double delta) {
      if (isCool) {
        p.adjustCoolness(delta);
      } else {
        p.adjustCurse(delta);
      }
    }

    Widget step(double delta) {
      final positive = delta > 0;
      final text = '${positive ? '+' : ''}${formatStat(delta)}';
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: OutlinedButton(
            onPressed: () => apply(delta),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: positive ? accent : Colors.white70,
              side: BorderSide(
                color: accent.withValues(alpha: positive ? 0.7 : 0.25),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(icon, color: accent, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Adjust $label',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                Text(
                  formatStat(value),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: accent,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Sleek single horizontal row of premium large modifier buttons!
            Row(
              children: [
                step(-1),
                step(-0.5),
                // Premium large central Reset button!
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: OutlinedButton(
                      onPressed: () {
                        if (isCool) {
                          p.adjustCoolness(-value);
                        } else {
                          p.adjustCurse(-value);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.white60,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'RESET',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                step(0.5),
                step(1),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Inventory sort
// =============================================================================

enum _GunSort { pickup, quality, name, dps }

enum _ItemSort { pickup, quality, name, type }

/// How the per-player inventory is rendered. `grid` keeps the dense
/// periodic-tile layout we've had since the start; `list` switches to a
/// one-per-row compact list with a portrait icon, name, quality badge,
/// elemental indicators inline, and the same corner stat (DPS for guns,
/// recharge for items).
enum _InvView { grid, list }

extension _GunSortLabel on _GunSort {
  String get label {
    switch (this) {
      case _GunSort.pickup:
        return 'Pickup order';
      case _GunSort.quality:
        return 'Quality';
      case _GunSort.name:
        return 'Name (A→Z)';
      case _GunSort.dps:
        return 'DPS (high→low)';
    }
  }

  IconData get icon {
    switch (this) {
      case _GunSort.pickup:
        return Icons.history;
      case _GunSort.quality:
        return Icons.workspace_premium;
      case _GunSort.name:
        return Icons.sort_by_alpha;
      case _GunSort.dps:
        return Icons.flash_on;
    }
  }
}

extension _ItemSortLabel on _ItemSort {
  String get label {
    switch (this) {
      case _ItemSort.pickup:
        return 'Pickup order';
      case _ItemSort.quality:
        return 'Quality';
      case _ItemSort.name:
        return 'Name (A→Z)';
      case _ItemSort.type:
        return 'Type';
    }
  }

  IconData get icon {
    switch (this) {
      case _ItemSort.pickup:
        return Icons.history;
      case _ItemSort.quality:
        return Icons.workspace_premium;
      case _ItemSort.name:
        return Icons.sort_by_alpha;
      case _ItemSort.type:
        return Icons.category_outlined;
    }
  }
}

/// Convert quality letter ('S' / '1S' / 'A' / 'B' / 'C' / 'D' / 'N' / '')
/// into a sortable rank — lower = appears first.
int _qualityRank(String q) {
  switch (q.toUpperCase()) {
    case 'S':
    case '1S':
      return 0;
    case 'A':
      return 1;
    case 'B':
      return 2;
    case 'C':
      return 3;
    case 'D':
      return 4;
    case 'N':
      return 5;
    default:
      return 6;
  }
}

/// Returns a sorted view of [src] according to [mode].
/// `_GunSort.pickup` short-circuits and returns [src] unchanged — the
/// player's pickup order is the natural list order, so we avoid both
/// the allocation and the sort cost on every rebuild. Callers must not
/// mutate the returned list (they don't).
List<Gun> _sortGuns(List<Gun> src, _GunSort mode) {
  if (mode == _GunSort.pickup) return src;
  final out = List.of(src);
  switch (mode) {
    case _GunSort.quality:
      out.sort((a, b) {
        final r = _qualityRank(a.quality).compareTo(_qualityRank(b.quality));
        return r != 0 ? r : a.name.compareTo(b.name);
      });
      break;
    case _GunSort.name:
      out.sort((a, b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      break;
    case _GunSort.dps:
      out.sort((a, b) => b.dpsValue.compareTo(a.dpsValue));
      break;
    case _GunSort.pickup:
      break;
  }
  return out;
}

List<Item> _sortItems(List<Item> src, _ItemSort mode) {
  if (mode == _ItemSort.pickup) return src;
  final out = List.of(src);
  int typeRank(Item it) {
    if (it.isActive) return 0;
    if (it.isPassive) return 1;
    if (it.isCompanion) return 2;
    return 3;
  }

  switch (mode) {
    case _ItemSort.quality:
      out.sort((a, b) {
        final r = _qualityRank(a.quality).compareTo(_qualityRank(b.quality));
        return r != 0 ? r : a.name.compareTo(b.name);
      });
      break;
    case _ItemSort.name:
      out.sort((a, b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      break;
    case _ItemSort.type:
      out.sort((a, b) {
        final r = typeRank(a).compareTo(typeRank(b));
        return r != 0 ? r : a.name.compareTo(b.name);
      });
      break;
    case _ItemSort.pickup:
      break;
  }
  return out;
}

/// Bottom-sheet picker used by the inventory section headers. Generic
/// over any enum [T] so the same sheet handles guns and items.
class _SortPickerSheet<T> extends StatelessWidget {
  final String title;
  final IconData titleIcon;
  final T current;
  final List<T> options;
  final String Function(T) labelOf;
  final IconData Function(T) iconOf;
  final ValueChanged<T> onPick;

  const _SortPickerSheet({
    super.key,
    required this.title,
    required this.titleIcon,
    required this.current,
    required this.options,
    required this.labelOf,
    required this.iconOf,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: Row(
                children: [
                  Icon(titleIcon, size: 18, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'Sort $title by',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
            for (final opt in options)
              ListTile(
                dense: true,
                leading: Icon(
                  iconOf(opt),
                  color: opt == current ? Colors.amber : Colors.white70,
                  size: 20,
                ),
                title: Text(
                  labelOf(opt),
                  style: TextStyle(
                    fontWeight:
                        opt == current ? FontWeight.w700 : FontWeight.w500,
                    color: opt == current ? Colors.amber : Colors.white,
                  ),
                ),
                trailing: opt == current
                    ? const Icon(Icons.check, color: Colors.amber, size: 18)
                    : null,
                onTap: () {
                  onPick(opt);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Quick-actions sheet for solo-mode long-press on an inventory tile.
/// Three large tap targets — Open, Favourite, Remove — plus a passive
/// header that shows what tile we're acting on.
class _TileActionsSheet extends StatelessWidget {
  final Gun? gun;
  final Item? item;
  final VoidCallback onOpen;
  final VoidCallback onToggleFavourite;
  final VoidCallback onRemove;
  final VoidCallback? onTransfer;
  final String? transferLabel;

  const _TileActionsSheet({
    this.gun,
    this.item,
    required this.onOpen,
    required this.onToggleFavourite,
    required this.onRemove,
    this.onTransfer,
    this.transferLabel,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final name = gun?.name ?? item!.name;
    final isFav = p.isFavourite(name);
    final subtitle = gun != null ? gun!.type : item!.type;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Row(
                children: [
                  Icon(
                    gun != null
                        ? Icons.gps_fixed
                        : Icons.inventory_2_outlined,
                    color: Colors.white70,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (onTransfer != null && transferLabel != null)
              ListTile(
                leading: const Icon(Icons.swap_horiz, color: Colors.amberAccent),
                title: Text(
                  transferLabel!,
                  style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                ),
                onTap: onTransfer,
              ),
            ListTile(
              leading: const Icon(Icons.open_in_new,
                  color: Colors.lightBlueAccent),
              title: const Text('Open detail'),
              onTap: onOpen,
            ),
            ListTile(
              leading: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.pinkAccent : Colors.white70,
              ),
              title: Text(
                isFav ? 'Unfavourite' : 'Favourite',
              ),
              onTap: onToggleFavourite,
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text(
                'Remove from run',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

enum _StarterKind { guns, items }

/// Empty-state hint shown when a player has no guns or no items in
/// inventory. For most characters it surfaces the *starting loadout*
/// (e.g. The Marine starts with Marine Sidearm) as ghosted, tappable
/// tiles — taping a ghost adds that starter to the player's loadout
/// without leaving the screen. Falls back to a plain message for
/// The Paradox (random starter) and any character whose starting list
/// is empty.
class _StarterHint extends StatelessWidget {
  final Gungeoneer character;
  final _StarterKind kind;
  final PlayerSlot slot;
  final SliverGridDelegate tileGrid;
  final bool wideMode;

  const _StarterHint({
    required this.character,
    required this.kind,
    required this.slot,
    required this.tileGrid,
    this.wideMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.read<RunProvider>();
    final isGuns = kind == _StarterKind.guns;

    // Paradox specifically starts with a *random* loadout, so the hint
    // doesn't apply — leave them with a clear message instead of showing
    // 0 ghosts.
    final isParadox = character.name == 'The Paradox';

    // Resolve starter names to actual entities via the indexed lookups.
    // Names that don't resolve (typo, removed item) are silently dropped.
    final List<Gun> starterGuns = isGuns
        ? character.startingGuns
            .map((n) => p.gunByName(n))
            .whereType<Gun>()
            .toList()
        : const [];
    final List<Item> starterItems = !isGuns
        ? character.startingItems
            .map((n) => p.itemByName(n))
            .whereType<Item>()
            .toList()
        : const [];

    final hasStarters = (isGuns ? starterGuns : starterItems).isNotEmpty;

    if (isParadox || !hasStarters) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                isParadox
                    ? 'The Paradox starts with a random loadout — '
                        'add ${isGuns ? "guns" : "items"} as you pick them up.'
                    : isGuns
                        ? 'No guns yet — hit ADD to bring in your first.'
                        : 'No items yet — pick some up!',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
            ),
          ),
        ),
      );
    }

    final headline = isGuns
        ? '${character.name} usually starts with'
        : 'Plus this passive';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    headline,
                    style: TextStyle(
                      fontSize: 11.5,
                      letterSpacing: 0.6,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Render starters in the same grid layout as the real loadout
          // so the ghost preview slots into the same visual rhythm — the
          // user instantly recognises "this is what a filled grid will
          // look like".
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: tileGrid,
            itemCount: isGuns ? starterGuns.length : starterItems.length,
            itemBuilder: (c, i) {
              final gun = isGuns ? starterGuns[i] : null;
              final it = isGuns ? null : starterItems[i];
              final name = gun?.name ?? it!.name;
              return Opacity(
                opacity: 0.55,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: PeriodicTile(
                        gun: gun,
                        item: it,
                        wideMode: wideMode,
                        onTap: () {
                          // Tile's own _handleTap already fires a light
                          // haptic, so we don't buzz twice. Capture the
                          // messenger *before* mutating the loadout —
                          // addGun triggers a rebuild that unmounts this
                          // ghost sub-tree, so looking up the messenger
                          // via `c` afterwards would be fragile.
                          final messenger = ScaffoldMessenger.of(c);
                          if (gun != null) {
                            p.addGun(gun, slot: slot);
                          } else {
                            p.addItem(it!, slot: slot);
                          }
                          messenger.showSnackBar(SnackBar(
                            content: Text('Added $name'),
                            duration:
                                const Duration(milliseconds: 1200),
                          ));
                        },
                      ),
                    ),
                    // Tiny "+" badge bottom-centre to differentiate the
                    // ghost preview from a real tile at a glance.
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 13,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
            child: Text(
              'Tap a starter to add it, or use the ADD button for anything else.',
              style: TextStyle(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Gunfortuna Dice Roll dialog / challenge
// =============================================================================

void _showDiceRollDialog(BuildContext context, {bool isChallenged = false}) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _DiceRollDialog(isChallenged: isChallenged),
  );
}

enum _DiceStatus { idle, challenging, rollingScreen, rolling, finished }

class _DiceRollDialog extends StatefulWidget {
  final bool isChallenged;
  const _DiceRollDialog({required this.isChallenged});

  @override
  State<_DiceRollDialog> createState() => _DiceRollDialogState();
}

class _DiceRollDialogState extends State<_DiceRollDialog> with TickerProviderStateMixin {
  late final AnimationController _infiniteController;
  late final MultiplayerSession _mp;
  _DiceStatus _status = _DiceStatus.idle;

  // Actual secret results rolled at the start of rolling
  final List<int> _actualDice = [1, 1, 1];
  final List<int> _myDice = [1, 1, 1];
  final List<bool> _diceStopped = [false, false, false];
  int _myScore = 0;
  bool _hasRolled = false;

  List<int>? _peerDice;
  int? _peerScore;

  bool _peerAccepted = false;
  String _announcement = '';

  // Particles inside the dialog
  final List<_DialogParticle> _particles = [];
  late final AnimationController _particleController;

  // To restore callbacks on dispose
  void Function(String challengerName)? _prevChallenge;
  void Function()? _prevAccept;
  void Function(int peerScore, List<int> peerDice)? _prevResult;

  @override
  void initState() {
    super.initState();
    _infiniteController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _particleController.addListener(_updateParticles);

    _mp = Provider.of<MultiplayerSession>(context, listen: false);
    _prevChallenge = _mp.onDiceChallenge;
    _prevAccept = _mp.onDiceAccept;
    _prevResult = _mp.onDiceResult;

    if (widget.isChallenged) {
      _status = _DiceStatus.rollingScreen;
    }

    _mp.onDiceAccept = () {
      if (mounted) {
        setState(() {
          _peerAccepted = true;
          _status = _DiceStatus.rollingScreen;
        });
      }
    };

    _mp.onDiceResult = (peerScore, peerDice) {
      if (mounted) {
        setState(() {
          _peerScore = peerScore;
          _peerDice = peerDice;
          _checkWinner();
        });
      }
    };
  }

  @override
  void dispose() {
    _infiniteController.dispose();
    _particleController.removeListener(_updateParticles);
    _particleController.dispose();
    _mp.onDiceChallenge = _prevChallenge;
    _mp.onDiceAccept = _prevAccept;
    _mp.onDiceResult = _prevResult;
    super.dispose();
  }

  void _updateParticles() {
    if (!mounted) return;
    setState(() {
      for (int i = _particles.length - 1; i >= 0; i--) {
        final p = _particles[i];
        p.x += p.vx;
        p.y += p.vy;
        p.vy += 0.15; // Gravity
        p.life -= 0.04;
        if (p.life <= 0) {
          _particles.removeAt(i);
        }
      }
    });
  }

  void _spawnSparkles(double x, double y, Color color) {
    final rand = math.Random();
    for (int i = 0; i < 12; i++) {
      final angle = rand.nextDouble() * 2 * math.pi;
      final speed = 1.0 + rand.nextDouble() * 3.5;
      _particles.add(_DialogParticle(
        x: x,
        y: y,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed - 2.0, // slight upward bias
        color: color,
      ));
    }
  }

  void _sendChallenge() {
    setState(() {
      _status = _DiceStatus.challenging;
    });
    _mp.sendDiceChallenge(_mp.myNickname);
  }

  void _startRolling() {
    if (_hasRolled) return;
    final rand = math.Random();
    _actualDice[0] = rand.nextInt(6) + 1;
    _actualDice[1] = rand.nextInt(6) + 1;
    _actualDice[2] = rand.nextInt(6) + 1;

    setState(() {
      _status = _DiceStatus.rolling;
      _hasRolled = true;
      _diceStopped[0] = false;
      _diceStopped[1] = false;
      _diceStopped[2] = false;
      _myDice[0] = 1;
      _myDice[1] = 1;
      _myDice[2] = 1;
      _myScore = 0;
    });
  }

  void _stopDie(int index, Color particleColor) {
    if (_status != _DiceStatus.rolling || _diceStopped[index]) return;

    setState(() {
      _diceStopped[index] = true;
      _myDice[index] = _actualDice[index];
      
      // Update running sum in real-time
      int sum = 0;
      for (int i = 0; i < 3; i++) {
        if (_diceStopped[i]) {
          sum += _myDice[i];
        }
      }
      _myScore = sum;

      // Spawn satisfying sparkles
      final double xPos = 60.0 + index * 80.0;
      _spawnSparkles(xPos, 160.0, particleColor);
      Haptics.heavy();

      // Check if all dice have stopped
      if (_diceStopped.every((stopped) => stopped)) {
        // Wait 1.2s then flip to final results
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!mounted) return;
          setState(() {
            if (_mp.isActive && _mp.isConnected) {
              _status = _DiceStatus.rollingScreen; // stay on roll screen but rolled
              _mp.sendDiceResult(_myScore, List<int>.from(_myDice));
            } else {
              _status = _DiceStatus.finished;
              _announcement = 'GUNFORTUNA HAS DECLARED YOUR FATE!';
            }
            _checkWinner();
          });
        });
      }
    });
  }

  void _checkWinner() {
    if (_myScore > 0 && _peerScore != null) {
      setState(() {
        _status = _DiceStatus.finished;
        if (_myScore > _peerScore!) {
          _announcement = 'GUNFORTUNA DECLARES YOU VICTORIOUS!';
        } else if (_myScore < _peerScore!) {
          _announcement = 'GUNFORTUNA DECLARES ${_mp.peerNickname?.toUpperCase() ?? "PEER"} VICTORIOUS!';
        } else {
          _announcement = "IT'S A DRAW! THE FATES ARE IN PERFECT BALANCE!";
        }
      });
    }
  }

  void _resetSolo() {
    setState(() {
      _myDice[0] = 1;
      _myDice[1] = 1;
      _myDice[2] = 1;
      _diceStopped[0] = false;
      _diceStopped[1] = false;
      _diceStopped[2] = false;
      _myScore = 0;
      _hasRolled = false;
      _status = _DiceStatus.idle;
      _announcement = '';
      _particles.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final connected = _mp.isActive && _mp.isConnected;
    final f = AppTheme.flair;
    final prefs = VisualPrefs.notifier.value;
    final myDiceStyle = _getDiceStyle(prefs.customDiceType, f);

    return Dialog(
      backgroundColor: const Color(0xFF151211),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: f.primary, width: 2.0),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.casino_rounded, color: f.primary, size: 26),
                          const SizedBox(width: 10),
                          Text(
                            'GUNFORTUNA\'S DUEL',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: f.primary,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white38, size: 20),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Flavour text (Only show in idle state!)
                  if (_status == _DiceStatus.idle) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: const Text(
                        '“Gunfortuna, the celestial bullet-goddess of chance, spins the cylinders of fate. When co-op partners clash over loot, let her dice decide who walks away with the prize.”',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Colors.white54,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Content body
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                        child: child,
                      );
                    },
                    child: _buildCurrentBody(connected, myDiceStyle, f),
                  ),
                ],
              ),
            ),
            // Particle Layer Paint
            if (_particles.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _DialogParticlePainter(particles: _particles),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentBody(bool connected, DiceStyle diceStyle, ThemeFlair f) {
    if (_status == _DiceStatus.idle && connected) {
      return Column(
        key: const ValueKey('idle_connected'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Challenge your sidekick or main partner to a high-stakes dice duel! 3x dice will decide who gets Gunfortuna\'s favor!',
            style: TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ScaleButton(
            onTap: _sendChallenge,
            child: IgnorePointer(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.casino_outlined, size: 18),
                  label: const Text('CHALLENGE PARTNER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: f.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ScaleButton(
            onTap: _startRolling,
            child: IgnorePointer(
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('ROLL SOLO INSTEAD', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_status == _DiceStatus.challenging) {
      return const Column(
        key: ValueKey('challenging'),
        children: [
          SizedBox(height: 10),
          CircularProgressIndicator(color: Colors.amberAccent),
          SizedBox(height: 16),
          Text('Waiting for partner to accept...', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white70)),
          SizedBox(height: 10),
        ],
      );
    }

    if (_status == _DiceStatus.rolling) {
      return Column(
        key: const ValueKey('rolling_active'),
        children: [
          const Text(
            'THE CYLINDERS ARE SPINNING!',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white54, letterSpacing: 1.0),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap each die individually to stop its spin!',
            style: TextStyle(fontSize: 10, color: Colors.amberAccent, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              final isStopped = _diceStopped[index];
              return _DiceWidget(
                value: _myDice[index],
                isRolling: !isStopped,
                infiniteController: _infiniteController,
                index: index,
                style: diceStyle,
                onTap: () => _stopDie(index, diceStyle.border),
              );
            }),
          ),
          const SizedBox(height: 20),
          Text(
            'Current Sum: $_myScore',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ],
      );
    }

    if (_status == _DiceStatus.rollingScreen && _hasRolled) {
      return Column(
        key: const ValueKey('rolled_waiting'),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              return _DiceWidget(
                value: _myDice[index],
                isRolling: false,
                infiniteController: _infiniteController,
                index: index,
                style: diceStyle,
                onTap: null,
              );
            }),
          ),
          const SizedBox(height: 24),
          const Text('ROLLED!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF66E07A))),
          const SizedBox(height: 6),
          Text('Your Score: $_myScore', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 8),
          if (_peerScore == null)
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent)),
                SizedBox(width: 10),
                Text('Waiting for partner to finish rolling...', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.cyanAccent)),
              ],
            ),
        ],
      );
    }

    if (_status == _DiceStatus.finished) {
      final isMyVictory = _peerScore != null && _myScore > _peerScore!;
      final isDraw = _peerScore != null && _myScore == _peerScore!;
      final isSolo = _peerScore == null;

      final Color bannerColor = isSolo
          ? const Color(0xFFFFD54F) // Majestic Gold for Solo fate
          : (isDraw
              ? Colors.white54
              : (isMyVictory ? Colors.greenAccent : Colors.redAccent));

      return Column(
        key: const ValueKey('finished_results'),
        children: [
          // Flavour Winner announcement
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bannerColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: bannerColor,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: bannerColor.withValues(alpha: 0.08),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              _announcement,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: bannerColor == Colors.white54 ? Colors.white : bannerColor,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),

          // Side-by-side comparison with character details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Player 1 (You)
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.person, color: Colors.cyanAccent, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      _mp.myNickname.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_myScore',
                      style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0),
                    ),
                    const SizedBox(height: 4),
                    Text('(${_myDice.join("-")})', style: const TextStyle(fontSize: 11, color: Colors.white38)),
                  ],
                ),
              ),
              if (_peerScore != null) ...[
                const Text(
                  'VS',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white24),
                ),
                // Player 2 (Peer)
                Expanded(
                  child: Column(
                    children: [
                      const Icon(Icons.person_outline, color: Colors.pinkAccent, size: 24),
                      const SizedBox(height: 4),
                      Text(
                        (_mp.peerNickname ?? 'Partner').toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_peerScore',
                        style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0),
                      ),
                      const SizedBox(height: 4),
                      Text('(${_peerDice?.join("-") ?? ""})', style: const TextStyle(fontSize: 11, color: Colors.white38)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // Action buttons
          if (!connected)
            ElevatedButton(
              onPressed: _resetSolo,
              style: ElevatedButton.styleFrom(
                backgroundColor: f.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('ROLL AGAIN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            )
          else
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('CLOSE', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
            ),
        ],
      );
    }

    // Solo play initial state
    return Column(
      key: const ValueKey('solo_initial'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Throw Gunfortuna\'s sacred dice to determine your fortune in Gungeon! Spin 3x dice for a rating from 3 to 18.',
          style: TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.45),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ScaleButton(
          onTap: _startRolling,
          child: IgnorePointer(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.casino_outlined, size: 20),
                label: const Text('ROLL THE DICE!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: f.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DiceWidget extends StatefulWidget {
  final int value;
  final bool isRolling;
  final AnimationController infiniteController;
  final int index;
  final DiceStyle style;
  final VoidCallback? onTap;

  const _DiceWidget({
    required this.value,
    required this.isRolling,
    required this.infiniteController,
    required this.index,
    required this.style,
    required this.onTap,
  });

  @override
  State<_DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<_DiceWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _impactController;

  @override
  void initState() {
    super.initState();
    _impactController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _impactController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRolling && !widget.isRolling) {
      // Play sudden impact expand/pop animation on stop!
      _impactController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: Listenable.merge([widget.infiniteController, _impactController]),
          builder: (context, child) {
            final t = widget.infiniteController.value;
            final impact = _impactController.value;

            // Compute 3D rotation tumbling
            final rotX = widget.isRolling ? (t * (4 + widget.index * 2) * math.pi) : 0.0;
            final rotY = widget.isRolling ? (t * (3 + widget.index * 3) * math.pi) : 0.0;
            final rotZ = widget.isRolling ? (t * (2 + widget.index * 4) * math.pi) : 0.0;

            // Vertical floating/bobbing during roll to look organic
            final double bobY = widget.isRolling ? (math.sin(t * 2 * math.pi + widget.index * 1.5) * 8.0) : 0.0;

            // Rapid cycling face value while rolling
            final faceVal = widget.isRolling ? ((widget.index + (t * 40).round()) % 6 + 1) : widget.value;

            // Impact pop scale (up to 1.35x and bounces back quickly)
            final double scale = widget.isRolling 
                ? 1.0 
                : 1.0 + math.sin(impact * math.pi) * 0.35;

            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0018) // 3D projection
                ..translate(0.0, bobY)
                ..scale(scale)
                ..rotateX(rotX)
                ..rotateY(rotY)
                ..rotateZ(rotZ),
              alignment: Alignment.center,
              child: Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.style.bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.style.border,
                    width: widget.isRolling ? 2.0 : 3.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.style.glow,
                      blurRadius: widget.isRolling ? 6 : 12,
                      spreadRadius: widget.isRolling ? 1 : 3,
                    ),
                  ],
                ),
                child: Text(
                  '$faceVal',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: widget.style.text,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DialogParticle {
  double x, y;
  double vx, vy;
  Color color;
  double life; // 1.0 down to 0.0
  _DialogParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    this.life = 1.0,
  });
}

class _DialogParticlePainter extends CustomPainter {
  final List<_DialogParticle> particles;
  _DialogParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      paint.color = p.color.withValues(alpha: p.life);
      canvas.drawCircle(Offset(p.x, p.y), 3.0 * p.life, paint);
    }
  }

  @override
  bool shouldRepaint(_DialogParticlePainter old) => true;
}

class DiceStyle {
  final Color bg;
  final Color border;
  final Color text;
  final Color glow;
  const DiceStyle({
    required this.bg,
    required this.border,
    required this.text,
    required this.glow,
  });
}

DiceStyle _getDiceStyle(CustomDiceType type, ThemeFlair flair) {
  switch (type) {
    case CustomDiceType.classicWhite:
      return const DiceStyle(
        bg: Color(0xFFFAFAFA),
        border: Color(0xFF90A4AE),
        text: Color(0xFF263238),
        glow: Colors.white24,
      );
    case CustomDiceType.goldGlimmer:
      return const DiceStyle(
        bg: Color(0xFF2C2210),
        border: Color(0xFFFFD54F),
        text: Color(0xFFFFD54F),
        glow: Color(0x33FFD54F),
      );
    case CustomDiceType.frostShard:
      return const DiceStyle(
        bg: Color(0xFF101C2C),
        border: Color(0xFF00E5FF),
        text: Color(0xFF00E5FF),
        glow: Color(0x3300E5FF),
      );
    case CustomDiceType.moltenAmber:
      return const DiceStyle(
        bg: Color(0xFF2C1010),
        border: Color(0xFFFF3D00),
        text: Color(0xFFFF3D00),
        glow: Color(0x33FF3D00),
      );
    case CustomDiceType.voidPurple:
      return const DiceStyle(
        bg: Color(0xFF1F102C),
        border: Color(0xFFD500F9),
        text: Color(0xFFD500F9),
        glow: Color(0x33D500F9),
      );
    case CustomDiceType.toxicOoze:
      return const DiceStyle(
        bg: Color(0xFF102C13),
        border: Color(0xFF00E676),
        text: Color(0xFF00E676),
        glow: Color(0x3300E676),
      );
    case CustomDiceType.themeDefault:
    default:
      return DiceStyle(
        bg: const Color(0xFF161413),
        border: flair.primary,
        text: flair.primary,
        glow: flair.primary.withValues(alpha: 0.3),
      );
  }
}

// _InteractiveDogStrip and DogBehavior/Facing enums removed — Huntress HUD
// simplified to compact single-card layout without animated dog strip.

/// Compact tab button for the Summary page in the MP header.
class _SummaryTab extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _SummaryTab({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          decoration: BoxDecoration(
            color: active
                ? primary.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active
                  ? primary.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.06),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.summarize_rounded,
                size: 14,
                color: active
                    ? primary
                    : Colors.white.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'SUMMARY',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w800,
                    color: active
                        ? primary
                        : Colors.white.withValues(alpha: 0.55),
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

/// Multiplayer Summary page — swipe right from P2 to reach it.
/// Shows both gungeoneers as animated GIFs with usernames, a stats
/// comparison panel, and a synergy overview showing all possible
/// synergies from the combined inventories.
class _MpSummaryPage extends StatelessWidget {
  const _MpSummaryPage();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final session = context.watch<MultiplayerSession>();
    final state = p.runState;
    final main = state.main;
    final coop = state.coop ?? Player();

    // Resolve nicknames
    final iAmMain = session.myRole == MpRole.main;
    final p1Nick = iAmMain ? session.myNickname : (session.peerNickname ?? 'P1');
    final p2Nick = !iAmMain ? session.myNickname : (session.peerNickname ?? 'P2');

    // Per-player stats
    final p1Guns = main.guns;
    final p1Items = main.items;
    final p2Guns = coop.guns;
    final p2Items = coop.items;

    final p1MaxDps = p1Guns.isEmpty
        ? 0.0
        : p1Guns.map((g) => g.dpsValue).fold<double>(0, (a, b) => a > b ? a : b);
    final p2MaxDps = p2Guns.isEmpty
        ? 0.0
        : p2Guns.map((g) => g.dpsValue).fold<double>(0, (a, b) => a > b ? a : b);

    final p1DmgMult = DamageCalculator.multiplier(guns: p1Guns, items: p1Items);
    final p2DmgMult = DamageCalculator.multiplier(guns: p2Guns, items: p2Items);

    final p1ActiveSyns = p.getActiveSynergiesForSlot(PlayerSlot.main);
    final p2ActiveSyns = p.getActiveSynergiesForSlot(PlayerSlot.coop);
    final allCombinedSyns = p.getActiveSynergiesCombined();

    // All possible synergies from combined inventories (active + partial)
    final combinedNames = state.allItemNames
        .map((n) => n.toLowerCase())
        .toSet();
    final possibleSyns = p.allSynergies.where((s) {
      final hasAny = s.items.any((i) => combinedNames.contains(i.toLowerCase())) ||
          s.anyOf.any((i) => combinedNames.contains(i.toLowerCase()));
      return hasAny;
    }).toList();

    final activeSynNames = allCombinedSyns.map((s) => s.name.toLowerCase()).toSet();

    // Group possible synergies by status for at-a-glance scanning
    final activeSyns = <Synergy>[];
    final partialSyns = <Synergy>[];
    final lockedSyns = <Synergy>[];
    for (final syn in possibleSyns) {
      if (activeSynNames.contains(syn.name.toLowerCase())) {
        activeSyns.add(syn);
      } else {
        final missing = syn.missingFor(combinedNames);
        final totalNeeded = syn.items.length + (syn.anyOf.isNotEmpty ? 1 : 0);
        if (missing.length < totalNeeded) {
          partialSyns.add(syn);
        } else {
          lockedSyns.add(syn);
        }
      }
    }

    return SafeArea(
      top: false,
      child: CustomScrollView(
        slivers: [
          // ── Gungeoneer portraits row ──────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _GungeoneerPortrait(
                      character: main.character,
                      nickname: p1Nick,
                      slotLabel: 'P1',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '+',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _GungeoneerPortrait(
                      character: coop.character,
                      nickname: p2Nick,
                      slotLabel: 'P2',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Stats comparison panel ────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E22),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'LOADOUT STATS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Header row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            p1Nick,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.cyanAccent.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'STAT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            p2Nick,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.purpleAccent.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _StatComparisonRow(
                      label: 'Guns',
                      p1Value: '${p1Guns.length}',
                      p2Value: '${p2Guns.length}',
                      icon: Icons.gps_fixed,
                    ),
                    _StatComparisonRow(
                      label: 'Items',
                      p1Value: '${p1Items.length}',
                      p2Value: '${p2Items.length}',
                      icon: Icons.inventory_2_rounded,
                    ),
                    _StatComparisonRow(
                      label: 'Active Syns',
                      p1Value: '${p1ActiveSyns.length}',
                      p2Value: '${p2ActiveSyns.length}',
                      icon: Icons.auto_awesome,
                    ),
                    _StatComparisonRow(
                      label: 'Max DPS',
                      p1Value: p1MaxDps.toStringAsFixed(1),
                      p2Value: p2MaxDps.toStringAsFixed(1),
                      icon: Icons.flash_on,
                    ),
                    _StatComparisonRow(
                      label: 'DMG Bonus',
                      p1Value: '${((p1DmgMult - 1) * 100).toStringAsFixed(0)}%',
                      p2Value: '${((p2DmgMult - 1) * 100).toStringAsFixed(0)}%',
                      icon: Icons.trending_up,
                    ),
                    // Coolness/Curse are shared dungeon state — single
                    // centered value, not duplicated per-player.
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          const Spacer(),
                          Icon(Icons.ac_unit, size: 12, color: Colors.cyanAccent.withValues(alpha: 0.6)),
                          const SizedBox(width: 6),
                          Text(
                            'Coolness',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+${state.totalCoolness.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.cyanAccent,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          const Spacer(),
                          Icon(Icons.local_fire_department, size: 12, color: Colors.redAccent.withValues(alpha: 0.6)),
                          const SizedBox(width: 6),
                          Text(
                            'Curse',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+${state.totalCurse.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.redAccent,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Disconnection banner (if peer dropped) ────────────
          if (!session.isConnected)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.25), width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 14, color: Colors.orangeAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Peer data may be stale — showing last known loadout.',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.orangeAccent.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Synergy overview panel ────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E22),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.12),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 16, color: Colors.amberAccent),
                        const SizedBox(width: 8),
                        Text(
                          'SYNERGY OVERVIEW',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: Colors.amberAccent,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${allCombinedSyns.length} active',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (possibleSyns.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'No synergies available from current loadout.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      )
                    else ...[
                      // Group synergies by status for at-a-glance scanning
                      if (activeSyns.isNotEmpty) ...[
                        _SynergyGroupHeader(
                          label: 'ACTIVE',
                          count: activeSyns.length,
                          color: Colors.greenAccent,
                        ),
                        for (final syn in activeSyns)
                          _SynergySummaryRow(
                            synergy: syn,
                            isActive: true,
                            ownedLower: combinedNames,
                          ),
                      ],
                      if (partialSyns.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _SynergyGroupHeader(
                          label: 'PARTIAL',
                          count: partialSyns.length,
                          color: Colors.amberAccent,
                        ),
                        for (final syn in partialSyns)
                          _SynergySummaryRow(
                            synergy: syn,
                            isActive: false,
                            ownedLower: combinedNames,
                          ),
                      ],
                      if (lockedSyns.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _SynergyGroupHeader(
                          label: 'LOCKED',
                          count: lockedSyns.length,
                          color: Colors.white24,
                        ),
                        for (final syn in lockedSyns)
                          _SynergySummaryRow(
                            synergy: syn,
                            isActive: false,
                            ownedLower: combinedNames,
                          ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

/// Animated gungeoneer portrait with nickname below.
class _GungeoneerPortrait extends StatelessWidget {
  final Gungeoneer? character;
  final String nickname;
  final String slotLabel;
  const _GungeoneerPortrait({
    required this.character,
    required this.nickname,
    required this.slotLabel,
  });

  @override
  Widget build(BuildContext context) {
    final charName = character?.name ?? 'Unknown';
    final gifPath = gungeoneerGifPath(charName);
    final accent = slotLabel == 'P1'
        ? Colors.cyanAccent
        : Colors.purpleAccent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Slot label badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: accent.withValues(alpha: 0.4), width: 1),
          ),
          child: Text(
            slotLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: accent,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Animated GIF portrait
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accent.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.08),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Image.asset(
              gifPath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Image.asset(
                character?.icon ?? '',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.person,
                  size: 48,
                  color: accent.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Character name
        Text(
          charName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.85),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        // Nickname
        Text(
          nickname,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: accent,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// One row in the stats comparison panel.
class _StatComparisonRow extends StatelessWidget {
  final String label;
  final String p1Value;
  final String p2Value;
  final IconData icon;
  const _StatComparisonRow({
    required this.label,
    required this.p1Value,
    required this.p2Value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              p1Value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.cyanAccent,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 11, color: Colors.white.withValues(alpha: 0.35)),
                const SizedBox(width: 4),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              p2Value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.purpleAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One row in the synergy overview panel.
class _SynergySummaryRow extends StatelessWidget {
  final Synergy synergy;
  final bool isActive;
  final Set<String> ownedLower;
  const _SynergySummaryRow({
    required this.synergy,
    required this.isActive,
    required this.ownedLower,
  });

  @override
  Widget build(BuildContext context) {
    final missing = synergy.missingFor(ownedLower);
    final totalNeeded = synergy.items.length + (synergy.anyOf.isNotEmpty ? 1 : 0);
    final isPartial = !isActive && missing.length < totalNeeded;

    // Special-case synergies (Smart Bombs, Super Serum, Unbelievably
    // Charming) have items:[] and custom match logic needing ≥2 anyOf.
    // missingFor returns [] when anyOf is partially satisfied, leaving
    // no hint text. Add a fallback showing unowned items so the user
    // sees what's needed.
    final missingHint = missing.isNotEmpty
        ? 'Need: ${missing.take(3).join(", ")}${missing.length > 3 ? "…" : ""}'
        : (isPartial && synergy.items.isEmpty && synergy.anyOf.isNotEmpty
            ? () {
                final unowned = synergy.anyOf
                    .where((i) => !ownedLower.contains(i.toLowerCase()))
                    .toList();
                return 'Need: 1 more from ${unowned.take(3).join(", ")}${unowned.length > 3 ? "…" : ""}';
              }()
            : null);

    final statusColor = isActive
        ? Colors.greenAccent
        : isPartial
            ? Colors.amberAccent
            : Colors.white24;
    final statusText = isActive
        ? 'ACTIVE'
        : isPartial
            ? 'PARTIAL'
            : 'LOCKED';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.green.withValues(alpha: 0.04)
              : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: statusColor.withValues(alpha: isActive ? 0.2 : 0.06),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [BoxShadow(color: statusColor.withValues(alpha: 0.4), blurRadius: 4)]
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            // Synergy name + missing items
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    synergy.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  if (!isActive && missingHint != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      missingHint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Colors.amber.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status badge
            Text(
              statusText,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section header for grouped synergies (ACTIVE / PARTIAL / LOCKED).
class _SynergyGroupHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SynergyGroupHeader({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '($count)',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
