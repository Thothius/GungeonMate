import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/multiplayer_messages.dart';
import '../models/player.dart';
import '../providers/run_provider.dart';
import '../services/app_theme.dart';
import '../services/multiplayer_session.dart';
import '../services/haptics.dart';
import 'character_select_screen.dart';
import 'theme_picker_screen.dart';

/// Central control room for Gungeon Mate.
/// - Tab 1: Theme & Sizing Preferences (launching the full 1.5k-line visual picker!)
/// - Tab 2: Functional Run Maintenance (co-op player, inventory reset, end run)
/// - Tab 3: Survival Help Directories & Tips
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
        appBar: AppBar(
          title: const Text('SETTINGS',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          centerTitle: true,
          automaticallyImplyLeading: false, // Clean inside tabs
          bottom: TabBar(
            labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900),
            indicatorColor: flair.headlineStat,
            tabs: const [
              Tab(text: 'THEME & FONT'),
              Tab(text: 'RUN UTILITIES'),
              Tab(text: 'HELP & TIPS'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ThemeVisualsTab(),
            _RunUtilitiesTab(),
            _HelpTipsTab(),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Tab 1: Appearance, Theme Palette & Fonts
// =============================================================================

class _ThemeVisualsTab extends StatelessWidget {
  const _ThemeVisualsTab();

  @override
  Widget build(BuildContext context) {
    final activeTheme = AppTheme.mode;
    final flair = AppTheme.flair;

    return ValueListenableBuilder<VisualPrefs>(
      valueListenable: VisualPrefs.notifier,
      builder: (context, prefs, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme card launcher
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: flair.scaffold.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(flair.chipRadius),
                  border: Border.all(color: flair.headlineStat.withValues(alpha: 0.25)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.palette_rounded, size: 36, color: Colors.amberAccent),
                    const SizedBox(height: 8),
                    Text(
                      'ACTIVE THEME: ${activeTheme.name.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: flair.headlineStat,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      icon: const Icon(Icons.fullscreen_rounded),
                      label: const Text('Choose Theme Palette (Carousel Preview)'),
                      style: FilledButton.styleFrom(backgroundColor: flair.headlineStat.withValues(alpha: 0.15), foregroundColor: flair.headlineStat),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ThemePickerScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Font Size Slider
              _prefSectionTitle('FONT SIZE (${prefs.fontSize.toStringAsFixed(0)} pt)'),
              Slider(
                value: prefs.fontSize,
                min: 6.0,
                max: 32.0,
                divisions: 13,
                activeColor: flair.headlineStat,
                inactiveColor: Colors.white12,
                label: '${prefs.fontSize.toStringAsFixed(0)} pt',
                onChanged: (v) => VisualPrefs.setFontSize(v),
              ),
              const SizedBox(height: 12),

              // Font Weight Bias Slider
              _prefSectionTitle('FONT WEIGHT BIAS (${prefs.fontWeightBias >= 0 ? "+" : ""}${prefs.fontWeightBias})'),
              Slider(
                value: prefs.fontWeightBias.toDouble(),
                min: -400.0,
                max: 500.0,
                divisions: 9,
                activeColor: flair.headlineStat,
                inactiveColor: Colors.white12,
                label: '${prefs.fontWeightBias}',
                onChanged: (v) => VisualPrefs.setFontWeightBias(v.toInt()),
              ),
              const SizedBox(height: 16),

              // Particles Enable Toggle
              SwitchListTile(
                title: const Text('Enable Theme Particles & Backdrops', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                subtitle: const Text('Renders falling ice, glowing sparks, or swamp toxic bubbles depending on theme.', style: TextStyle(fontSize: 10.5, color: Colors.white54)),
                value: prefs.particlesEnabled,
                activeColor: flair.headlineStat,
                onChanged: (v) => VisualPrefs.setParticles(v),
              ),

              // Background Glow Toggle
              SwitchListTile(
                title: const Text('Enable Background Ambient Glow', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                subtitle: const Text('Displays a faint colored radial gradient behind the main dashboards.', style: TextStyle(fontSize: 10.5, color: Colors.white54)),
                value: prefs.glowIntensity > 0,
                activeColor: flair.headlineStat,
                onChanged: (v) => VisualPrefs.setGlow(v ? 0.35 : 0.0),
              ),

              const Divider(color: Colors.white12, height: 24),

              // Hypnotic Background Toggle
              SwitchListTile(
                title: const Text('Enable Hypnotic Backdrops (Trippy)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                subtitle: const Text('Renders dynamic, full-bleed animated math geometries as the base layer.', style: TextStyle(fontSize: 10.5, color: Colors.white54)),
                value: prefs.hypnoticBgEnabled,
                activeColor: flair.headlineStat,
                onChanged: (v) => VisualPrefs.setHypnoticBgEnabled(v),
              ),

              if (prefs.hypnoticBgEnabled) ...[
                const SizedBox(height: 12),
                _prefSectionTitle('SELECTED HYPNOTIC PATTERN'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: prefs.hypnoticBgAsset,
                        isExpanded: true,
                        dropdownColor: flair.card,
                        icon: Icon(Icons.arrow_drop_down, color: flair.headlineStat),
                        onChanged: (String? val) {
                          if (val != null) {
                            VisualPrefs.setHypnoticBgAsset(val);
                            Haptics.selection();
                          }
                        },
                        items: const [
                          DropdownMenuItem(value: 'circles05.gif', child: Text('Expanding Vortex Circles 🕳️', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white))),
                          DropdownMenuItem(value: 'circles06.gif', child: Text('Psychedelic Ripple Dots 🔴', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white))),
                          DropdownMenuItem(value: 'kaleicospio03.gif', child: Text('Hypnotic Kaleidoscope 🌀', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white))),
                          DropdownMenuItem(value: 'lines01.gif', child: Text('Retro Scanlines 📺', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white))),
                          DropdownMenuItem(value: 'sea02.gif', child: Text('Calm Digital Waves 🌊', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white))),
                          DropdownMenuItem(value: 'sea03.gif', child: Text('Undulating Fluid Sea 〰️', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white))),
                          DropdownMenuItem(value: 'squares01.gif', child: Text('Tunneling Square Portals 🟩', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white))),
                          DropdownMenuItem(value: 'tiles01.gif', child: Text('Shifting Blue Tiles 🟦', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white))),
                          DropdownMenuItem(value: 'tiles05.gif', child: Text('Warped Amber Lattice 🟧', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white))),
                          DropdownMenuItem(value: 'weird03.gif', child: Text('Hyper-Trippy Sinusoids 🧠', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white))),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _prefSectionTitle('ANIMATION SPEED'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        onPressed: prefs.hypnoticBgSpeed <= 0.2
                            ? null
                            : () {
                                VisualPrefs.setHypnoticBgSpeed(prefs.hypnoticBgSpeed - 0.5);
                                Haptics.selection();
                              },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: flair.headlineStat, width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          '—',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: flair.headlineStat),
                        ),
                      ),
                      Text(
                        '${(prefs.hypnoticBgSpeed * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      OutlinedButton(
                        onPressed: prefs.hypnoticBgSpeed >= 4.0
                            ? null
                            : () {
                                VisualPrefs.setHypnoticBgSpeed(prefs.hypnoticBgSpeed + 0.5);
                                Haptics.selection();
                              },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: flair.headlineStat, width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          '＋',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: flair.headlineStat),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _prefSectionTitle('BACKGROUND OPACITY (${(prefs.hypnoticBgOpacity * 100).toStringAsFixed(0)}%)'),
                Slider(
                  min: 0.0,
                  max: 1.0,
                  value: prefs.hypnoticBgOpacity,
                  activeColor: flair.headlineStat,
                  inactiveColor: Colors.white10,
                  onChanged: (v) {
                    VisualPrefs.setHypnoticBgOpacity(v);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _prefSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white60, letterSpacing: 0.5),
      ),
    );
  }
}

// =============================================================================
// Tab 2: Run Maintenance Controls (Add Player, Reset, End Run)
// =============================================================================

class _RunUtilitiesTab extends StatefulWidget {
  const _RunUtilitiesTab();

  @override
  State<_RunUtilitiesTab> createState() => _RunUtilitiesTabState();
}

class _RunUtilitiesTabState extends State<_RunUtilitiesTab> {
  void _addCoopPlayer(BuildContext context, RunProvider p) {
    final cultist = p.gungeoneerByName('The Cultist') ?? p.gungeoneerByName('Cultist');
    if (cultist != null) {
      p.startCoopPlayer(cultist);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${cultist.name} joined as Player 2!'),
        duration: const Duration(milliseconds: 1400),
        action: SnackBarAction(
          label: 'CHANGE',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CharacterSelectScreen(mode: CharSelectMode.coop),
            ),
          ),
        ),
      ));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CharacterSelectScreen(mode: CharSelectMode.coop),
      ),
    );
  }

  void _confirmRemoveCoop(BuildContext context, RunProvider p) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remove Player 2 (Co-op)?'),
        content: const Text('Their loadout will be discarded. Items are not transferred to Player 1.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade900),
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

  void _confirmClearInventory(BuildContext context, RunProvider p, PlayerSlot slot) {
    final player = slot == PlayerSlot.main ? p.runState.main : p.runState.coop;
    if (player == null || player.character == null) return;
    final name = player.character!.name;

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
        title: Text("Clear $name's inventory?"),
        content: const Text(
          'Removes all guns and items except their starter loadout. '
          'Coolness, curse, and shrine status are unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade900),
            onPressed: () {
              p.clearInventory(slot: slot);
              Navigator.pop(c);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("$name's items cleared!"),
                duration: const Duration(seconds: 1),
              ));
            },
            child: const Text('Clear Inventory'),
          ),
        ],
      ),
    );
  }

  void _confirmEndRun(BuildContext context, RunProvider p) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.warning_rounded, color: Colors.redAccent),
        title: const Text('End Run?'),
        content: const Text('This resets the current active run completely and returns you to the character select screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade900),
            onPressed: () async {
              final session = context.read<MultiplayerSession>();
              Navigator.pop(c);
              if (session.isActive) {
                await session.notifyEndRunAndCancel();
                if (session.myRole == MpRole.main) {
                  p.endRun();
                }
              } else {
                p.endRun();
              }
            },
            child: const Text('End Run'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final hasCoop = p.runState.hasCoop;
    final player1Name = p.runState.main.character?.name ?? 'Player 1';
    final player2Name = p.runState.coop?.character?.name ?? 'Player 2';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👥 Co-op Management Section
          _sectionHeader('👥 MULTIPLAYER & CO-OP'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasCoop ? 'PLAYER 2 ACTIVE' : 'SOLO PLAYER ACTIVE',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: hasCoop ? Colors.pinkAccent : Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasCoop
                            ? 'Drop-in Gungeoneer: $player2Name'
                            : 'Play with a friend by adding the co-op Cultist helper!',
                        style: const TextStyle(fontSize: 11, color: Colors.white54, height: 1.3),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: hasCoop ? () => _confirmRemoveCoop(context, p) : () => _addCoopPlayer(context, p),
                  style: FilledButton.styleFrom(
                    backgroundColor: hasCoop ? Colors.red.withValues(alpha: 0.15) : Colors.pinkAccent.withValues(alpha: 0.15),
                    foregroundColor: hasCoop ? Colors.redAccent : Colors.pinkAccent,
                    side: BorderSide(color: hasCoop ? Colors.redAccent : Colors.pinkAccent),
                  ),
                  child: Text(hasCoop ? 'Remove P2' : 'Add Co-op'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 🧹 Inventory Reset Section
          _sectionHeader('🧹 INVENTORY MAINTENANCE'),
          _utilTile(
            title: 'Reset $player1Name Items',
            subtitle: 'Wipes P1 loadout back to default starter gear.',
            icon: Icons.restart_alt_rounded,
            color: Colors.cyanAccent,
            onTap: () => _confirmClearInventory(context, p, PlayerSlot.main),
          ),
          if (hasCoop)
            _utilTile(
              title: 'Reset $player2Name Items',
              subtitle: 'Wipes Co-op loadout back to default starter gear.',
              icon: Icons.restart_alt_rounded,
              color: Colors.pinkAccent,
              onTap: () => _confirmClearInventory(context, p, PlayerSlot.coop),
            ),
          const SizedBox(height: 20),

          // ⚠️ Active Run Termination
          _sectionHeader('⚠️ CORE ACTIONS'),
          _utilTile(
            title: 'End Active Run',
            subtitle: 'Resets the current session. WARNING: Wipes all active passive logging.',
            icon: Icons.cancel_presentation_rounded,
            color: Colors.redAccent,
            onTap: () => _confirmEndRun(context, p),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
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
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 10.5, color: Colors.white54)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white38),
      ),
    );
  }
}

// =============================================================================
// Tab 3: Help, Strategy & survival Guides
// =============================================================================

class _HelpTipsTab extends StatelessWidget {
  const _HelpTipsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Introduction card
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1.2),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.widgets_rounded, color: Colors.blueAccent, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'WELCOME TO GUNGEONMATE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.blueAccent,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'GungeonMate is your ultimate real-time second-screen companion for Enter the Gungeon. Here is an overview of what you can accomplish:',
                style: TextStyle(fontSize: 12, color: Colors.white, height: 1.4),
              ),
              SizedBox(height: 10),
              Text(
                '• Active Run Tracking: Manage and track your inventory, active items, and guns across Player 1 and Player 2 (Co-op) slots.\n'
                '• Real-time Stats Analytics: View automatic recalculations of your aggregate Coolness, Curse, Chest drop probabilities, and Room Reward modifiers.\n'
                '• Dynamic Wiki Compendium: Tap any item or gun to browse comprehensive notes, synergy charts, and Ammonomicon lore on the fly.\n'
                '• Character Dashboards: Track character-specific stats like the Robot\'s Junk Counter damage multiplier or the Huntress\'s Dog dig probability tables.\n'
                '• Device-to-Peer Matchmaking: Hook up with your local co-op buddy via Bluetooth or Wi-Fi to sync inventories and trade guns seamlessly!',
                style: TextStyle(fontSize: 11.5, color: Colors.white70, height: 1.5),
              ),
            ],
          ),
        ),
        
        const Text(
          'COMPANION APP UI/UX SHORTCUTS & TIPS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Colors.white54,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),

        _buildHelpCard(
          title: '⚡ ITEM SHORTCUTS & GESTURES',
          desc: '• In the Browse / Wiki tab, long-pressing any gun or item card instantly adds/removes it from your active run inventory without opening the detailed view.\n'
              '• Tapping any item or gun in your main run screen open its wiki detailed view directly. Pressing back returns you exactly where you were.',
          color: Colors.cyanAccent,
        ),
        _buildHelpCard(
          title: '🍀 TACTILE STAT ADJUSTMENTS',
          desc: '• Need to adjust stats manually? The Coolness and Curse detailed screens feature rapid tactile quick-buttons (-1.0, -0.5, +0.5, +1.0) for oil-slick fast adjustments.\n'
              '• You can also drag the continuous Slider for precise, micro-granular stat control.',
          color: Colors.greenAccent,
        ),
        _buildHelpCard(
          title: '🎮 LOCAL MULTIPLAYER SIMULATION (SPOOFING)',
          desc: '• Want to test or design multiplayer co-op dashboards without a second phone?\n'
              '• Head to the Multiplayer Lobby, choose Sidekick role, and enter Connection PIN "0000". This starts simulated co-op matchmaking instantly! You get main control over both characters and full inventory transfer access for testing.',
          color: Colors.amberAccent,
        ),
        _buildHelpCard(
          title: '🎨 DYNAMIC VISUAL STYLING',
          desc: '• Make GungeonMate your own! Visit the "Theme & Font" tab to select magnificent color palettes and scale global font biases (-800, -400, 0, 400, 800) for high readability.\n'
              '• Custom backdrop particles are fully controlled! Tweak particle sizes and overall Particle Opacity (0% to 100%) to suit your exact brightness tastes.',
          color: Colors.orangeAccent,
        ),
      ],
    );
  }

  Widget _buildHelpCard({required String title, required String desc, required Color color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text(desc, style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.4)),
        ],
      ),
    );
  }
}
