import 'package:flutter/material.dart';
import '../services/goop_talk_engine.dart';
import '../widgets/settings/settings_tab.dart';

/// Central control room for Gungeon Mate.
/// All visual/theme options live in the Themes screen (opened from
/// the home menu). Settings keeps only: run tools, dice style,
/// multiplayer, account/data, developer, and danger zone —
/// organized as collapsible cards.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: const GoopText('Settings'),
        centerTitle: true,
      ),
      body: const SettingsTab(),
    );
  }
}
