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
      length: 2,
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
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ThemeVisualsTab(),
            _RunUtilitiesTab(),
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
    return ListenableBuilder(
      listenable: Listenable.merge([AppTheme.notifier, VisualPrefs.notifier]),
      builder: (context, _) {
        final activeTheme = AppTheme.mode;
        final flair = AppTheme.flair;
        final prefs = VisualPrefs.notifier.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme card launcher
              // Active Theme Premium Dashboard Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      flair.scaffold.withValues(alpha: 0.95),
                      flair.card.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: flair.primary.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: flair.primary.withValues(alpha: 0.08),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Pulsing colored palette icon with active primary glow!
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: flair.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: flair.primary.withValues(alpha: 0.4), width: 1.5),
                          ),
                          child: Icon(Icons.palette_rounded, size: 24, color: flair.secondary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ACTIVE PALETTE',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white38,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                activeTheme.label.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Live theme color beads showing the palette signature
                        Row(
                          children: [
                            _colorBead(flair.primary),
                            const SizedBox(width: 4),
                            _colorBead(flair.secondary),
                            const SizedBox(width: 4),
                            _colorBead(flair.headlineStat),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Choose Theme Action Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.tune_rounded, size: 16),
                        label: const Text(
                          'CHOOSE THEME PALETTE',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: flair.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ThemePickerScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // =============================================================
              // Typography Tuning Section
              // =============================================================
              _prefSectionTitle('APP TYPOGRAPHY TUNING'),
              const SizedBox(height: 8),
              Card(
                color: Colors.white.withValues(alpha: 0.02),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    children: [
                      // Font selector inside Card
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Font Family', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<AppFont>(
                                  value: prefs.font,
                                  isExpanded: true,
                                  dropdownColor: flair.card,
                                  icon: Icon(Icons.arrow_drop_down, color: flair.primary, size: 18),
                                  onChanged: (AppFont? val) {
                                    if (val != null) {
                                      VisualPrefs.setFont(val);
                                      Haptics.selection();
                                    }
                                  },
                                  items: AppFont.values.map((AppFont f) {
                                    final isSel = f == prefs.font;
                                    return DropdownMenuItem<AppFont>(
                                      value: f,
                                      child: Text(
                                        f == AppFont.gungeon ? 'Enter the Gungeon 🏹' : f.label,
                                        style: f.textStyle.copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isSel ? flair.primary : Colors.white70,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12, height: 20),

                      // Compact Font Size Slider row
                      _buildCompactSliderRow(
                        'Font Size',
                        '${prefs.fontSize.toStringAsFixed(0)} pt',
                        prefs.fontSize,
                        6.0,
                        32.0,
                        13,
                        flair.headlineStat,
                        (v) => VisualPrefs.setFontSize(v),
                      ),
                      const SizedBox(height: 10),

                      // Compact Inventory Tile Font Size Slider
                      _buildCompactSliderRow(
                        'Inventory Size',
                        '${prefs.inventoryFontSize.toStringAsFixed(1)} pt',
                        prefs.inventoryFontSize,
                        10.0,
                        18.0,
                        8,
                        flair.headlineStat,
                        (v) => VisualPrefs.setInventoryFontSize(v),
                      ),
                      const SizedBox(height: 10),

                      // Compact Font Weight Bias Slider
                      _buildCompactSliderRow(
                        'Weight Bias',
                        '${prefs.fontWeightBias >= 0 ? "+" : ""}${prefs.fontWeightBias}',
                        prefs.fontWeightBias.toDouble(),
                        -400.0,
                        500.0,
                        9,
                        flair.headlineStat,
                        (v) => VisualPrefs.setFontWeightBias(v.toInt()),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // =============================================================
              // Particle Tuning Section
              // =============================================================
              _prefSectionTitleWithInfo('PARTICLE OVERLAY STYLE', flair, tooltip: 'Select a premium custom particle theme preset (such as embers, frost, or cat paws) to float in the background of all screens.'),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CustomParticleType>(
                    value: prefs.customParticleType,
                    isExpanded: true,
                    dropdownColor: flair.card,
                    icon: Icon(Icons.arrow_drop_down, color: flair.primary),
                    onChanged: (CustomParticleType? val) {
                      if (val != null) {
                        VisualPrefs.setCustomParticleType(val);
                        Haptics.selection();
                      }
                    },
                    items: CustomParticleType.values.map((CustomParticleType t) {
                      final isSel = t == prefs.customParticleType;
                      return DropdownMenuItem<CustomParticleType>(
                        value: t,
                        child: Text(
                          t.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSel ? flair.primary : Colors.white70,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (prefs.customParticleType != CustomParticleType.none) ...[
                _prefSectionTitleWithInfo('PARTICLE COUNT / DENSITY (${prefs.particleCount})', flair, tooltip: 'Control the maximum number of custom background particles rendered simultaneously on the screen.'),
                Slider(
                  min: 5.0,
                  max: 120.0,
                  divisions: 23,
                  value: prefs.particleCount.toDouble(),
                  activeColor: flair.primary,
                  inactiveColor: Colors.white12,
                  onChanged: (v) {
                    VisualPrefs.setParticleCount(v.toInt());
                  },
                ),
                const SizedBox(height: 12),

                _prefSectionTitleWithInfo('PARTICLE SIZE SCALE (${prefs.particleSizeScale.toStringAsFixed(1)}x)', flair, tooltip: 'Scale up or down the visual dimensions of the custom background particles.'),
                Slider(
                  min: 0.5,
                  max: 3.0,
                  divisions: 25,
                  value: prefs.particleSizeScale,
                  activeColor: flair.primary,
                  inactiveColor: Colors.white12,
                  onChanged: (v) {
                    VisualPrefs.setParticleSizeScale(v);
                  },
                ),
                const SizedBox(height: 16),

                _prefSectionTitleWithInfo('PARTICLE EMITTERS', flair, tooltip: 'Choose which boundaries of the screen particles are emitted from. Active boundaries glow with your theme color.'),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDirectionChip('TOP', prefs.emitFromTop, (v) => VisualPrefs.setEmitters(top: v), flair),
                      _buildDirectionChip('BOTTOM', prefs.emitFromBottom, (v) => VisualPrefs.setEmitters(bottom: v), flair),
                      _buildDirectionChip('LEFT', prefs.emitFromLeft, (v) => VisualPrefs.setEmitters(left: v), flair),
                      _buildDirectionChip('RIGHT', prefs.emitFromRight, (v) => VisualPrefs.setEmitters(right: v), flair),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // =============================================================
              // Glow & Engine Rendering Section
              // =============================================================
              _prefSectionTitleWithInfo('AMBIENT GLOW INTENSITY (${(prefs.glowIntensity * 100).toStringAsFixed(0)}%)', flair, tooltip: 'Set the opacity blending of the dual-gradient wandering ambient glow in the background.'),
              Slider(
                min: 0.0,
                max: 1.0,
                value: prefs.glowIntensity,
                activeColor: flair.primary,
                inactiveColor: Colors.white12,
                onChanged: (v) {
                  VisualPrefs.setGlow(v);
                },
              ),
              const SizedBox(height: 16),

              _prefSectionTitle('DYNAMIC RENDER ENGINE TUNING'),
              const SizedBox(height: 6),
              _buildSwitchRow(
                context: context,
                icon: Icons.auto_awesome_rounded,
                label: 'Interactive Touch Sparkles',
                value: prefs.particlesEnabled,
                onChanged: VisualPrefs.setParticles,
                flair: flair,
                tooltip: 'When enabled, tapping anywhere on the screen spawns a physical burst of colorful kinetic sparkles that decelerate and fade.',
              ),
              const SizedBox(height: 8),
              _buildSwitchRow(
                context: context,
                icon: Icons.sync_rounded,
                label: 'Particle Dynamic Rotation',
                value: prefs.particleRotation,
                onChanged: VisualPrefs.setParticleRotation,
                flair: flair,
                tooltip: 'When active, particles dynamically spin and rotate based on their velocity vector.',
              ),
              const SizedBox(height: 8),
              _buildSwitchRow(
                context: context,
                icon: Icons.center_focus_strong_rounded,
                label: 'Avatar Gravity Vortex',
                value: prefs.gravityVortex,
                onChanged: VisualPrefs.setGravityVortex,
                flair: flair,
                tooltip: 'Simulates physical gravitational pull! Particles are warped and pulled in orbit around active character portraits.',
              ),
              const SizedBox(height: 8),
              _buildSwitchRow(
                context: context,
                icon: Icons.flash_on_rounded,
                label: 'Advanced Breeze Flicker',
                value: prefs.advancedFlicker,
                onChanged: VisualPrefs.setAdvancedFlicker,
                flair: flair,
                tooltip: 'Adds a rapid, flickering twinkle frequency to all floating particles for a magical, dynamic shimmer.',
              ),
              const SizedBox(height: 20),

              // =============================================================
              // Animated Backgrounds Section
              // =============================================================
              _prefSectionTitleWithInfo('ANIMATED BACKGROUNDS OVERLAY', flair, tooltip: 'Layer flowing, animated backgrounds or high-performance procedural static loops beneath all screens for amazing dungeon ambiance.'),
              const SizedBox(height: 6),
              _buildSwitchRow(
                context: context,
                icon: Icons.blur_circular_rounded,
                label: 'Enable Animated Backgrounds',
                value: prefs.hypnoticBgEnabled,
                onChanged: VisualPrefs.setHypnoticBgEnabled,
                flair: flair,
                tooltip: 'Layer flowing, animated backgrounds or procedural loops beneath all screens instead of solid backgrounds.',
              ),
              if (prefs.hypnoticBgEnabled) ...[
                const SizedBox(height: 12),
                _prefSectionTitleWithInfo('SELECT BACKGROUND ASSET', flair, tooltip: 'Pick from premium animated backdrops or procedural analog scanline and grid glitch engines.'),
                const SizedBox(height: 6),
                Card(
                  color: Colors.white.withValues(alpha: 0.02),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: flair.primary.withValues(alpha: 0.15)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: prefs.hypnoticBgAsset,
                        dropdownColor: const Color(0xFF1E1E22),
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: flair.primary),
                        items: const [
                          DropdownMenuItem(value: 'crt_static', child: Text('CRT Analog Static (Procedural)', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                          DropdownMenuItem(value: 'static_glitch', child: Text('Cyber Glitch Screen (Procedural)', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                          DropdownMenuItem(value: 'matrix_code', child: Text('Goopian Cipher Terminal (Procedural)', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                          DropdownMenuItem(value: 'pixel_nebula', child: Text('Pulsing Starfield Nebula (Procedural)', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                          DropdownMenuItem(value: 'circles05.gif', child: Text('Psychedelic Circles', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                          DropdownMenuItem(value: 'circles06.gif', child: Text('Expanding Ripples', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                          DropdownMenuItem(value: 'kaleicospio03.gif', child: Text('Kaleidoscopic Warp', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                          DropdownMenuItem(value: 'lines01.gif', child: Text('Tunneling Lines', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                          DropdownMenuItem(value: 'sea02.gif', child: Text('Goop Sea Wave I', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                          DropdownMenuItem(value: 'sea03.gif', child: Text('Goop Sea Wave II', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                          DropdownMenuItem(value: 'squares01.gif', child: Text('Retro Grid Squares', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                          DropdownMenuItem(value: 'tiles01.gif', child: Text('Optical Chessboard', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                          DropdownMenuItem(value: 'tiles05.gif', child: Text('Infinite Maze Tiles', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                          DropdownMenuItem(value: 'weird03.gif', child: Text('Distortion Plasma', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            VisualPrefs.setHypnoticBgAsset(val);
                            Haptics.selection();
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _prefSectionTitleWithInfo('BACKGROUND OPACITY (${(prefs.hypnoticBgOpacity * 100).toStringAsFixed(0)}%)', flair, tooltip: 'Adjust the visibility/opacity blending of the animated backgrounds.'),
                Slider(
                  min: 0.0,
                  max: 1.0,
                  value: prefs.hypnoticBgOpacity,
                  activeColor: flair.primary,
                  inactiveColor: Colors.white12,
                  onChanged: (v) {
                    VisualPrefs.setHypnoticBgOpacity(v);
                  },
                ),
                const SizedBox(height: 12),
                _prefSectionTitleWithInfo('BACKGROUND SPEED (${prefs.hypnoticBgSpeed.toStringAsFixed(1)}x)', flair, tooltip: 'Calibrate the animation rate or procedural refresh speeds of the background.'),
                Slider(
                  min: 0.1,
                  max: 4.0,
                  value: prefs.hypnoticBgSpeed,
                  activeColor: flair.primary,
                  inactiveColor: Colors.white12,
                  onChanged: (v) {
                    VisualPrefs.setHypnoticBgSpeed(v);
                  },
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _prefSectionTitleWithInfo(String title, ThemeFlair flair, {String? tooltip}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white60, letterSpacing: 0.5),
          ),
          if (tooltip != null) ...[
            const SizedBox(width: 6),
            Tooltip(
              message: tooltip,
              triggerMode: TooltipTriggerMode.tap,
              showDuration: const Duration(seconds: 5), // Keep tooltip visible for 5s!
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: flair.primary.withValues(alpha: 0.65), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: flair.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                  ),
                ],
              ),
              textStyle: const TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.bold),
              child: Icon(Icons.info_outline_rounded, size: 13, color: flair.primary.withValues(alpha: 0.6)),
            ),
          ],
        ],
      ),
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

  Widget _colorBead(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionChip(
    String label,
    bool isActive,
    ValueChanged<bool> onChanged,
    ThemeFlair f,
  ) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: isActive ? Colors.black : Colors.white70,
          letterSpacing: 0.5,
        ),
      ),
      selected: isActive,
      onSelected: (val) {
        onChanged(val);
        Haptics.selection();
      },
      selectedColor: f.primary,
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      showCheckmark: false,
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
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
                if (tooltip != null) ...[
                  const SizedBox(width: 6),
                  Tooltip(
                    message: tooltip,
                    triggerMode: TooltipTriggerMode.tap,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E22),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: flair.primary.withValues(alpha: 0.65), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: flair.primary.withValues(alpha: 0.15),
                          blurRadius: 8,
                        ),
                      ],
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
            Text(
              label,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            Text(
              displayValue,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color),
            ),
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

          // 🗣️ Run Language Section
          _sectionHeader('🗣️ RUN LANGUAGE'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INTERFACE LANGUAGE',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Simulates hold "The Sponge" 🧽 in Goopian',
                      style: TextStyle(fontSize: 10, color: Colors.white38),
                    ),
                  ],
                ),
                ListenableBuilder(
                  listenable: VisualPrefs.notifier,
                  builder: (context, _) {
                    final prefs = VisualPrefs.notifier.value;
                    final flair = AppTheme.flair;
                    return Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<bool>(
                          value: prefs.isGoopianLanguage,
                          dropdownColor: flair.card,
                          icon: Icon(Icons.arrow_drop_down, color: flair.primary, size: 18),
                          onChanged: (bool? val) {
                            if (val != null) {
                              VisualPrefs.setIsGoopianLanguage(val);
                              Haptics.heavy();
                              
                              // Trigger translation effect snackbar
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(val 
                                      ? 'Language shifted to Goopian! Hold The Sponge 🧽 to decipher.'
                                      : 'Language restored to English!'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          items: [
                            DropdownMenuItem<bool>(
                              value: false,
                              child: Text(
                                'English 🇬🇧',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: !prefs.isGoopianLanguage ? flair.primary : Colors.white70,
                                ),
                              ),
                            ),
                            DropdownMenuItem<bool>(
                              value: true,
                              child: Text(
                                'Goopian 👽',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: prefs.isGoopianLanguage ? flair.primary : Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
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
