import 'package:flutter/material.dart';
import '../services/app_theme.dart';
import '../services/goop_talk_engine.dart';
import '../widgets/settings/theme_visuals_tab.dart';
import '../widgets/settings/run_tab.dart';
import '../widgets/settings/app_tab.dart';

/// Central control room for Gungeon Mate.
/// - Tab 1: VISUALS — Theme, typography, particles, glow, wallpaper, inventory layout
/// - Tab 2: RUN — Co-op, inventory maintenance, shrines, event log, end run
/// - Tab 3: APP — Language, dialogue, dice, changelog, data reset
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white70),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: const GoopText('SETTINGS',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          centerTitle: true,
          bottom: TabBar(
            labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            indicatorColor: flair.headlineStat,
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            tabs: const [
              Tab(text: 'VISUALS'),
              Tab(text: 'RUN'),
              Tab(text: 'APP'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ThemeVisualsTab(),
            RunTab(),
            AppTab(),
          ],
        ),
      ),
    );
  }
}