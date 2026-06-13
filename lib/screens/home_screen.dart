import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/player.dart';
import '../providers/run_provider.dart';
import '../services/multiplayer_session.dart';
import '../widgets/mp_request_listener.dart';
import 'main_menu_screen.dart';
import 'active_run_screen.dart';
import 'browse_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  PlayerSlot _currentPlayerSlot = PlayerSlot.main;
  bool _mpRestoreAttempted = false;

  @override
  Widget build(BuildContext context) {
    final runProvider = context.watch<RunProvider>();

    if (runProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
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
        final session = context.read<MultiplayerSession>();
        if (!session.isActive) {
          session.tryRestorePersistedSession();
        }
      });
    }

    if (runProvider.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${runProvider.error}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => runProvider.loadData(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final hasActiveRun = runProvider.runState.selectedCharacter != null;

    if (!hasActiveRun) {
      return const MainMenuScreen();
    }

    final screens = [
      ActiveRunScreen(
        onRequestBrowse: () => setState(() => _selectedIndex = 1),
        onPlayerChanged: (slot) => setState(() => _currentPlayerSlot = slot),
      ),
      // Feed Browse its own visibility so its didUpdateWidget hook can
      // clear the search box the instant the user picks another tab.
      BrowseScreen(
        isVisible: _selectedIndex == 1,
        targetSlot: _currentPlayerSlot,
      ),
      // Settings screen directly embedded as the third tab
      const SettingsScreen(),
    ];

    // Back-button policy: only the Inventory tab pops the route (which
    // on Android lets the OS minimise the app). Any other tab redirects
    // back to Inventory first — that mirrors what users testing the
    // app expected, so they don't get bounced out of the app while
    // browsing the wiki or tweaking favourites.
    final canPop = _selectedIndex == 0;
    return MpRequestListener(
      child: PopScope(
        canPop: canPop,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (_selectedIndex != 0) {
            setState(() => _selectedIndex = 0);
          }
        },
        child: Scaffold(
          body: IndexedStack(index: _selectedIndex, children: screens),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              // Always drop the soft keyboard when swapping tabs so the
              // search field in Browse can never haunt other tabs.
              FocusManager.instance.primaryFocus?.unfocus();
              setState(() {
                _selectedIndex = index;
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
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
