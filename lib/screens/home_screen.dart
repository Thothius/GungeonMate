import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/player.dart';
import '../providers/run_provider.dart';
import '../services/goop_talk_engine.dart';
import '../services/mp_session.dart';
import '../theme/tokens.dart';
import '../widgets/mp_reconnect_banner.dart';
import '../widgets/mp_request_listener.dart';
import '../widgets/state_widgets.dart';
import 'main_menu_screen.dart';
import 'active_run_screen.dart';
import 'browse_screen.dart';
import 'codex_screen.dart';
import 'settings_screen.dart';
import 'quiz/quiz_home_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  PlayerSlot _currentPlayerSlot = PlayerSlot.main;
  bool _mpRestoreAttempted = false;

  /// Tracks which tabs have been visited at least once.
  /// Tabs not yet visited are built as a zero-size placeholder,
  /// deferring their initState (and any expensive loading — e.g.
  /// CodexScreen's 5-file JSON parse) until the user first opens them.
  /// Once visited, the widget stays mounted in the IndexedStack so
  /// state is preserved on switch-back.
  final Set<int> _visitedTabs = {0}; // Inventory is always visited

  @override
  Widget build(BuildContext context) {
    final runProvider = context.watch<RunProvider>();

    if (runProvider.isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SkeletonLoader(width: 200, height: 24),
              const SizedBox(height: Insets.md),
              const SkeletonLoader(width: 160, height: 16),
              const SizedBox(height: Insets.sm),
              const SkeletonLoader(width: 140, height: 16),
            ],
          ),
        ),
      );
    }

    // Once data is loaded, fire-and-forget the persisted-MP-session
    // restore exactly once per app lifetime. This re-enters the lobby
    // for the previous role/character if the user was in an MP session
    // when the app died, so the peer's auto-reconnect can find them.
    if (!_mpRestoreAttempted) {
      _mpRestoreAttempted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final session = context.read<MpSession>();
        if (!session.isActive) {
          session.tryRestorePersistedSession();
        }
      });
    }

    if (runProvider.error != null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: ErrorState(
          message:
              'Could not load game data. Check your connection and try again.',
          onRetry: () => runProvider.loadData(),
        ),
      );
    }

    final hasActiveRun = runProvider.runState.selectedCharacter != null;

    // ThemeOverlay now reads RunProvider directly to determine
    // isHomeScreen, so the galaxy background swaps in the same frame
    // as the run state change — no 1-frame flicker.

    if (!hasActiveRun) {
      // Home screen (MainMenu) — Galaxy animated bg plays here
      return const MainMenuScreen();
    }

    // Inventory/Browse — no Galaxy, respect user wallpaper settings

    final screens = [
      ActiveRunScreen(
        onRequestBrowse: () {
          setState(() {
            _selectedIndex = 1;
            _visitedTabs.add(1);
          });
        },
        onPlayerChanged: (slot) => setState(() => _currentPlayerSlot = slot),
      ),
      // Feed Browse its own visibility so its didUpdateWidget hook can
      // clear the search box the instant the user picks another tab.
      _visitedTabs.contains(1)
          ? BrowseScreen(
            isVisible: _selectedIndex == 1,
            targetSlot: _currentPlayerSlot,
          )
          : const SizedBox.shrink(),
      // Codex: deferred until first visit — avoids loading 5 JSON files
      // in initState if the user never opens the Codex tab.
      _visitedTabs.contains(2)
          ? CodexScreen(showBackButton: false)
          : const SizedBox.shrink(),
      // Settings — respects the user's picked font
      _visitedTabs.contains(3)
          ? const SettingsScreen()
          : const SizedBox.shrink(),
      // Quiz: deferred until first visit — builds its engine from
      // RunProvider data on first open.
      _visitedTabs.contains(4)
          ? const QuizHomeScreen()
          : const SizedBox.shrink(),
    ];

    // Back-button policy: only the Inventory tab pops the route (which
    // on Android lets the OS minimise the app). Any other tab redirects
    // back to Inventory first — that mirrors what users testing the
    // app expected, so they don't get bounced out of the app while
    // browsing the wiki or tweaking favourites.
    final canPop = _selectedIndex == 0;
    return MpReconnectBanner(
      child: MpRequestListener(
        child: PopScope(
          canPop: canPop,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (_selectedIndex != 0) {
              setState(() => _selectedIndex = 0);
            }
          },
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: IndexedStack(index: _selectedIndex, children: screens),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                // Always drop the soft keyboard when swapping tabs so the
                // search field in Browse can never haunt other tabs.
                FocusManager.instance.primaryFocus?.unfocus();
                GoopAnimationManager.instance.pulse();
                setState(() {
                  _selectedIndex = index;
                  _visitedTabs.add(index);
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: 'Inventory',
                ),
                NavigationDestination(
                  icon: Icon(Icons.search),
                  selectedIcon: Icon(Icons.search),
                  label: 'Browse',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: 'Codex',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
                NavigationDestination(
                  icon: Icon(Icons.quiz_outlined),
                  selectedIcon: Icon(Icons.quiz),
                  label: 'Quiz',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
