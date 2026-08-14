// TODO: remove after CombinedRunAppTab is verified — AppTab is now dormant.
// Its content was merged into CombinedRunAppTab (run_tab.dart) in v1.9.0.
// This file is left on disk per Safety S4. Do not delete without user OK.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/run_provider.dart';
import '../../services/app_theme.dart';
import '../../services/haptics.dart';
import '../../services/goop_talk_engine.dart';
import '../../screens/character_select_screen.dart';
import '../../utils/fast_route.dart';
import 'debug_tab.dart';

class AppTab extends StatefulWidget {
  const AppTab({super.key});

  @override
  State<AppTab> createState() => AppTabState();
}

class AppTabState extends State<AppTab> {
  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final p = context.watch<RunProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language section — hidden for now (Goopian feature disabled)
          // _sectionHeader('LANGUAGE'),
          // _buildLanguageCard(flair),
          // const SizedBox(height: 12),

          // Dialogue
          _sectionHeader('DIALOGUE'),
          _buildDialogueCard(flair),
          const SizedBox(height: 12),

          // Changelog
          _sectionHeader('ABOUT'),
          _utilTile(
            title: 'View Changelog',
            subtitle: 'See version history and recent updates.',
            icon: Icons.history_edu_rounded,
            color: const Color(0xFFFFD740),
            onTap: () => _showChangelogDialog(context),
          ),
          const SizedBox(height: 12),

          // Dev Tools
          _sectionHeader('DEV TOOLS'),
          _utilTile(
            title: 'Special Items & Guns',
            subtitle: 'Spawn all 18 dashboard-triggering items/guns into your inventory.',
            icon: Icons.grid_view_rounded,
            color: Colors.greenAccent,
            onTap: () {
              if (p.runState.main.character != null) {
                Haptics.selection();
                Navigator.push(context, fastRoute(const SpecialItemsGridScreen()));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: GoopText('Start a run first to spawn special items.'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 12),

          // Data
          _sectionHeader('DATA MANAGEMENT'),
          _utilTile(
            title: 'Reset All App Data',
            subtitle: 'Wipes everything: run state, favourites, theme prefs, settings. Restarts the app.',
            icon: Icons.restart_alt,
            color: Colors.deepOrange,
            onTap: () => _confirmResetAppData(context, p),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: GoopText(
        title,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 0.6),
      ),
    );
  }

  Widget _utilTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: Icon(icon, color: color, size: 20),
        title: GoopText(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
        subtitle: GoopText(subtitle, style: const TextStyle(fontSize: 10, color: Colors.white54)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white38),
      ),
    );
  }

  // _buildLanguageCard — hidden for now (Goopian feature disabled)
  // Widget _buildLanguageCard(ThemeFlair flair) {
  //   return Card(
  //     color: flair.card.withValues(alpha: 0.92),
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(12),
  //       side: BorderSide(color: flair.primary.withValues(alpha: 0.18)),
  //     ),
  //     child: Padding(
  //       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  //       child: ListenableBuilder(
  //         listenable: VisualPrefs.notifier,
  //         builder: (context, _) {
  //           final isGoopian = VisualPrefs.notifier.value.isGoopianLanguage;
  //           return Row(
  //             children: [
  //               Icon(Icons.language, size: 16, color: Colors.white54),
  //               const SizedBox(width: 10),
  //               Expanded(
  //                 child: GoopText(
  //                   'GOOPIAN LANGUAGE MODE',
  //                   style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 0.5),
  //                 ),
  //               ),
  //               GestureDetector(
  //                 onTap: () {
  //                   Haptics.selection();
  //                   VisualPrefs.setIsGoopianLanguage(!isGoopian);
  //                 },
  //                 child: Container(
  //                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //                   decoration: BoxDecoration(
  //                     color: isGoopian
  //                         ? const Color(0xFF9C27B0).withValues(alpha: 0.18)
  //                         : Colors.white.withValues(alpha: 0.06),
  //                     borderRadius: BorderRadius.circular(16),
  //                     border: Border.all(
  //                       color: isGoopian
  //                           ? const Color(0xFF9C27B0).withValues(alpha: 0.5)
  //                           : Colors.white.withValues(alpha: 0.15),
  //                     ),
  //                   ),
  //                   child: GoopText(
  //                     isGoopian ? 'GOOPIAN' : 'ENGLISH',
  //                     style: TextStyle(
  //                       fontSize: 10,
  //                       fontWeight: FontWeight.w900,
  //                       color: isGoopian ? const Color(0xFF9C27B0) : Colors.white54,
  //                       letterSpacing: 0.5,
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           );
  //         },
  //       ),
  //     ),
  //   );
  // }

  Widget _buildDialogueCard(ThemeFlair flair) {
    final prefs = VisualPrefs.notifier.value;
    return Card(
      color: flair.card.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: flair.primary.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            _buildSwitchRow(
              context: context,
              icon: Icons.vibration_rounded,
              label: 'Dialogue Haptics',
              value: prefs.dialogueHapticsEnabled,
              onChanged: VisualPrefs.setDialogueHapticsEnabled,
              flair: flair,
              tooltip: 'Enable haptic feedback during dialogue text reveal.',
            ),
            const Divider(color: Colors.white12, height: 20),
            _buildCompactSliderRow(
              'Text Speed',
              '${prefs.dialogueTextSpeedMs}ms',
              prefs.dialogueTextSpeedMs.toDouble(),
              10.0,
              80.0,
              14,
              flair.headlineStat,
              (v) => VisualPrefs.setDialogueTextSpeedMs(v.toInt()),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangelogDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0F0F12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF332225), width: 1.5),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_edu_rounded, color: Color(0xFFFFD54F), size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: GoopText(
                        'CHANGELOG',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: Colors.white12, height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: FutureBuilder<String>(
                      future: DefaultAssetBundle.of(context).loadString('assets/data/changelog.json'),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.cyanAccent)));
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return const GoopText('Error loading changelog.', style: TextStyle(color: Colors.white24, fontSize: 11));
                        }
                        try {
                          final List<dynamic> data = json.decode(snapshot.data!);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: data.map((v) {
                              final String version = v['version'] ?? '';
                              final String title = v['title'] ?? '';
                              final List<dynamic> items = v['items'] ?? [];
                              return _changelogGroup('$title ($version)', items.map((i) => i.toString()).toList());
                            }).toList(),
                          );
                        } catch (e) {
                          return const GoopText('Failed to parse changelog.', style: TextStyle(color: Colors.white24, fontSize: 11));
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _changelogGroup(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoopText(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          ...items.map((it) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    Expanded(child: GoopText(it, style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.25))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _confirmResetAppData(BuildContext context, RunProvider p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.restart_alt, color: Colors.deepOrange, size: 32),
        title: const GoopText('Reset All App Data?'),
        content: const GoopText(
          'This permanently erases ALL saved data:\n\n'
          '• Active run & inventory\n'
          '• Favourites\n'
          '• Theme & visual preferences\n'
          '• Special weapon upgrades\n'
          '• Multiplayer session data\n\n'
          'The app will restart. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const GoopText('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
            onPressed: () => Navigator.pop(c, true),
            child: const GoopText('RESET EVERYTHING'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) { debugPrint('[AppTab] prefs clear error: $e'); }
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      fastRoute(const CharacterSelectScreen()),
      (_) => false,
    );
  }

  Widget _buildSwitchRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ThemeFlair flair,
    String? tooltip,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: flair.card.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: flair.primary.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                GoopText(
                  label.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 0.5),
                ),
                if (tooltip != null) ...[
                  const SizedBox(width: 6),
                  Tooltip(
                    message: tooltip,
                    triggerMode: TooltipTriggerMode.tap,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: AppTheme.flair.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: flair.primary.withValues(alpha: 0.65), width: 1.2),
                      boxShadow: [BoxShadow(color: flair.primary.withValues(alpha: 0.15), blurRadius: 8)],
                    ),
                    textStyle: const TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.bold),
                    child: Icon(Icons.info_outline_rounded, size: 13, color: flair.primary.withValues(alpha: 0.5)),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: flair.primary,
            activeTrackColor: flair.primary.withValues(alpha: 0.25),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white10,
            onChanged: (val) {
              onChanged(val);
              Haptics.selection();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSliderRow(
    String label,
    String displayValue,
    double value,
    double min,
    double max,
    int divisions,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GoopText(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white70)),
            GoopText(displayValue, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
        SizedBox(
          height: 32,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
              activeTrackColor: color,
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
              valueIndicatorColor: color,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}