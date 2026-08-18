import 'package:flutter/material.dart';
import '../services/app_theme.dart';
import '../services/goop_talk_engine.dart';
import '../widgets/settings/theme_visuals_tab.dart';
import '../widgets/settings/settings_tab.dart';

/// Central control room for Gungeon Mate.
/// - Tab 1: APPEARANCE — Theme, typography, screen glow, inventory layout
/// - Tab 2: SETTINGS — Dice style, multiplayer, account/data, dev tools, danger zone
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
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white70),
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: const GoopText('SETTINGS',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Colors.white)),
          centerTitle: true,
          bottom: TabBar(
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.8),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.8),
            labelColor: flair.headlineStat,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.4),
            indicatorColor: flair.headlineStat,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 3,
            labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            tabs: const [
              Tab(text: 'APPEARANCE'),
              Tab(text: 'SETTINGS'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AppearanceTab(),
            SettingsTab(),
          ],
        ),
      ),
    );
  }
}
