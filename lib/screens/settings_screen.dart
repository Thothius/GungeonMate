import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/multiplayer_messages.dart';
import '../models/player.dart';
import '../models/run_log_entry.dart';
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
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
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
              // WALLPAPER & PARALLAX ENGINE LAB (moved up!)
              // =============================================================
              _prefSectionTitleWithInfo('WALLPAPER & PARALLAX ENGINE LAB', flair, tooltip: 'Select an exclusive handcrafted Gungeon wallpaper, activate gyroscopic depth parallax sways, or loop a high-fidelity 8s live animation. Swipe to browse!'),
              const SizedBox(height: 8),
              _SwipePicker<WallpaperMode>(
                items: WallpaperMode.values
                    .where((m) => m != WallpaperMode.customStill || kStillWallpapers.isNotEmpty)
                    .toList(),
                value: prefs.wallpaperMode,
                onChanged: (m) => VisualPrefs.setWallpaperMode(m),
                height: 88,
                itemBuilder: (mode, isSelected) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? flair.card.withValues(alpha: 0.98)
                        : flair.scaffold.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? flair.primary.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.12),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        mode == WallpaperMode.themeDefault
                            ? Icons.palette_outlined
                            : mode == WallpaperMode.customStill
                                ? Icons.image_outlined
                                : Icons.play_circle_outline_rounded,
                        size: 24,
                        color: isSelected ? flair.primary : Colors.white54,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        mode.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : Colors.white54,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (prefs.wallpaperMode == WallpaperMode.customStill) ...[
                const SizedBox(height: 12),
                _prefSectionTitleWithInfo('SELECT STILL WALLPAPER', flair, tooltip: 'Swipe through 17 gorgeous high-fidelity pixel-art scenes.'),
                const SizedBox(height: 8),
                _SwipePicker<String>(
                  items: kStillWallpapers.map((w) => w['asset']!).toList(),
                  value: prefs.selectedStillWallpaper,
                  onChanged: (v) => VisualPrefs.setSelectedStillWallpaper(v),
                  height: 72,
                  itemBuilder: (asset, isSelected) {
                    final wallpaper = kStillWallpapers.firstWhere((w) => w['asset'] == asset);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? flair.card.withValues(alpha: 0.98)
                            : flair.scaffold.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? flair.primary.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.12),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 16, color: isSelected ? flair.primary : Colors.white38),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              wallpaper['name']!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? Colors.white : Colors.white54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildSwitchRow(
                  context: context,
                  icon: Icons.screen_rotation_rounded,
                  label: 'Gyroscopic Parallax Sway',
                  value: prefs.parallaxMotionEnabled,
                  onChanged: VisualPrefs.setParallaxMotionEnabled,
                  flair: flair,
                  tooltip: 'Dynamically shifts the wallpaper offset based on device tilt for a beautiful, responsive 3D parallax effect.',
                ),
              ],
              if (prefs.wallpaperMode == WallpaperMode.customAnimated) ...[
                const SizedBox(height: 12),
                _prefSectionTitleWithInfo('SELECT ANIMATED LIVE LOOP', flair, tooltip: 'Swipe through premium high-fidelity 8-second animated background scenes.'),
                const SizedBox(height: 8),
                _SwipePicker<String>(
                  items: kAnimatedWallpapers.map((w) => w['asset']!).toList(),
                  value: prefs.selectedAnimatedWallpaper,
                  onChanged: (v) => VisualPrefs.setSelectedAnimatedWallpaper(v),
                  height: 72,
                  itemBuilder: (asset, isSelected) {
                    final wallpaper = kAnimatedWallpapers.firstWhere((w) => w['asset'] == asset);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? flair.card.withValues(alpha: 0.9)
                            : flair.card.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? flair.primary.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_circle_fill, size: 16, color: isSelected ? flair.primary : Colors.white38),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              wallpaper['name']!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? Colors.white : Colors.white54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 20),

              // =============================================================
              // Typography Tuning Section (with swipe font selector!)
              // =============================================================
              _prefSectionTitle('APP TYPOGRAPHY TUNING'),
              const SizedBox(height: 8),
              Card(
                color: flair.card.withValues(alpha: 0.92),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: flair.primary.withValues(alpha: 0.18)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    children: [
                      // Swipe Font Picker with live preview
                      _SwipePicker<AppFont>(
                        items: AppFont.values,
                        value: prefs.font,
                        onChanged: (f) => VisualPrefs.setFont(f),
                        height: 112,
                        itemBuilder: (font, isSelected) => Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? flair.scaffold.withValues(alpha: 0.95)
                                : flair.scaffold.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? flair.primary.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.06),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  font.label,
                                  style: font.textStyle.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? flair.primary : Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'The Breach: Bello\'s Shop',
                                  style: font.textStyle.copyWith(
                                    fontSize: 11,
                                    color: isSelected ? Colors.white60 : Colors.white38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
              // Inventory Grid & Display Tuning Section
              // =============================================================
              _prefSectionTitle('INVENTORY GRID & DISPLAY TUNING'),
              const SizedBox(height: 8),
              Card(
                color: flair.card.withValues(alpha: 0.92),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: flair.primary.withValues(alpha: 0.18)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    children: [
                      // Default Grid Layout
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Default Layout', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
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
                                child: DropdownButton<InventoryDisplayMode>(
                                  value: prefs.inventoryDisplayMode,
                                  isExpanded: true,
                                  dropdownColor: flair.card,
                                  icon: Icon(Icons.arrow_drop_down, color: flair.primary, size: 18),
                                  onChanged: (InventoryDisplayMode? val) {
                                    if (val != null) {
                                      VisualPrefs.setInventoryDisplayMode(val);
                                      Haptics.selection();
                                    }
                                  },
                                  items: const [
                                    DropdownMenuItem<InventoryDisplayMode>(
                                      value: InventoryDisplayMode.classicPeriodic,
                                      child: Text('Periodic Grid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                                    ),
                                    DropdownMenuItem<InventoryDisplayMode>(
                                      value: InventoryDisplayMode.tacticalStats,
                                      child: Text('Tactical Stats', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Periodic Grid Columns
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Periodic Columns', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
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
                                child: DropdownButton<int>(
                                  value: prefs.periodicGridColumnCount,
                                  isExpanded: true,
                                  dropdownColor: flair.card,
                                  icon: Icon(Icons.arrow_drop_down, color: flair.primary, size: 18),
                                  onChanged: (int? val) {
                                    if (val != null) {
                                      VisualPrefs.setPeriodicGridColumnCount(val);
                                      Haptics.selection();
                                    }
                                  },
                                  items: const [
                                    DropdownMenuItem<int>(
                                      value: 0,
                                      child: Text('Responsive (Auto)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                                    ),
                                    DropdownMenuItem<int>(
                                      value: 2,
                                      child: Text('Compact (2 Columns)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                                    ),
                                    DropdownMenuItem<int>(
                                      value: 3,
                                      child: Text('Medium (3 Columns)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                                    ),
                                    DropdownMenuItem<int>(
                                      value: 4,
                                      child: Text('Dense (4 Columns)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12, height: 20),

                      // Compact Inventory Tile Font Size Slider
                      _buildCompactSliderRow(
                        'Inventory Font Size',
                        '${prefs.inventoryFontSize.toStringAsFixed(1)} pt',
                        prefs.inventoryFontSize,
                        10.0,
                        18.0,
                        8,
                        flair.headlineStat,
                        (v) => VisualPrefs.setInventoryFontSize(v),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // =============================================================
              // Particle Tuning Section (simplified — Type, Count, Size)
              // =============================================================
              _prefSectionTitleWithInfo('PARTICLE OVERLAY STYLE', flair, tooltip: 'Select a premium custom particle theme preset (such as embers, frost, or cat paws) to float in the background of all screens. Swipe to browse!'),
              const SizedBox(height: 8),
              _SwipePicker<CustomParticleType>(
                items: CustomParticleType.values,
                value: prefs.customParticleType,
                onChanged: (t) => VisualPrefs.setCustomParticleType(t),
                height: 84,
                itemBuilder: (type, isSelected) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? flair.card.withValues(alpha: 0.9)
                        : flair.card.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? flair.primary.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      type.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.white : Colors.white54,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (prefs.customParticleType != CustomParticleType.none) ...[
                _prefSectionTitleWithInfo('PARTICLE COUNT / DENSITY (${prefs.particleCount})', flair, tooltip: 'Control the maximum number of background particles rendered simultaneously. This affects both theme-default and custom particle types.'),
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
                const SizedBox(height: 16),
              ],

              // =============================================================
              // Glow Section
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
        color: flair.card.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: flair.primary.withValues(alpha: 0.10)),
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
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
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
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
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

          // 🧮 Damage Calculator Section
          _sectionHeader('🧮 DASHBOARD DISPLAY'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DAMAGE CALCULATOR',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Shows a live DPS terminal on every character\'s dashboard, factoring in equipped item/gun damage bonuses.',
                        style: TextStyle(fontSize: 10, color: Colors.white38, height: 1.3),
                      ),
                    ],
                  ),
                ),
                ListenableBuilder(
                  listenable: VisualPrefs.notifier,
                  builder: (context, _) {
                    final prefs = VisualPrefs.notifier.value;
                    final flair = AppTheme.flair;
                    return Switch(
                      value: prefs.showDamageCalculator,
                      activeColor: flair.primary,
                      onChanged: (v) {
                        VisualPrefs.setShowDamageCalculator(v);
                        Haptics.selection();
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 📜 Run Event Log
          _sectionHeader('📜 RUN EVENT LOG'),
          _utilTile(
            title: 'View Event History',
            subtitle: 'See all pickups, stat changes, shrines, synergies & manual actions.',
            icon: Icons.history_edu_rounded,
            color: const Color(0xFFFFD740),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RunLogScreen()),
            ),
          ),

          // ⚠️ Active Run Termination
          _sectionHeader('⚠️ CORE ACTIONS'),
          _utilTile(
            title: 'End Active Run',
            subtitle: 'Resets the current session. WARNING: Wipes all active passive logging.',
            icon: Icons.cancel_presentation_rounded,
            color: Colors.redAccent,
            onTap: () => _confirmEndRun(context, p),
          ),
          const SizedBox(height: 10),
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

  Future<void> _confirmResetAppData(BuildContext context, RunProvider p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.restart_alt, color: Colors.deepOrange, size: 32),
        title: const Text('Reset All App Data?'),
        content: const Text(
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
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('RESET EVERYTHING'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}
    // Restart the app by pushing to the character select screen
    // which is the root route after app launch.
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CharacterSelectScreen()),
      (_) => false,
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
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
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
// Reusable Swipe-to-Select Picker Widget
// =============================================================================

class _SwipePicker<T> extends StatefulWidget {
  final List<T> items;
  final T value;
  final ValueChanged<T> onChanged;
  final double height;
  final Widget Function(T item, bool isSelected) itemBuilder;

  const _SwipePicker({
    required this.items,
    required this.value,
    required this.onChanged,
    required this.height,
    required this.itemBuilder,
  });

  @override
  State<_SwipePicker<T>> createState() => _SwipePickerState<T>();
}

class _SwipePickerState<T> extends State<_SwipePicker<T>> {
  late final PageController _pc;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.items.indexOf(widget.value);
    if (_index < 0) _index = 0;
    _pc = PageController(initialPage: _index, viewportFraction: 0.38);
  }

  @override
  void didUpdateWidget(_SwipePicker<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIdx = widget.items.indexOf(widget.value);
    if (newIdx >= 0 && newIdx != _index) {
      _index = newIdx;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pc.hasClients) _pc.animateToPage(newIdx, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      });
    }
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _pc,
        itemCount: widget.items.length,
        onPageChanged: (i) {
          setState(() => _index = i);
          widget.onChanged(widget.items[i]);
          Haptics.selection();
        },
        itemBuilder: (context, i) {
          final item = widget.items[i];
          final isSelected = item == widget.value;
          final isFocused = i == _index;
          return AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: isFocused ? 1.0 : 0.92,
            curve: Curves.easeOut,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: widget.itemBuilder(item, isSelected || isFocused),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// Run Event Log — Full-screen history viewer
// =============================================================================

class RunLogScreen extends StatelessWidget {
  const RunLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final entries = p.runState.log.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      appBar: AppBar(
        title: const Text('EVENT LOG'),
        centerTitle: true,
      ),
      body: entries.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_toggle_off,
                      size: 64, color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(
                    'No events logged yet',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pick up guns, items, use shrines, or tap quick actions\nto start building your run history.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.3),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Icon(Icons.receipt_long,
                            size: 16, color: Colors.white.withValues(alpha: 0.4)),
                        const SizedBox(width: 6),
                        Text(
                          '${entries.length} event${entries.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _FullLogTile(entry: entries[i]),
                    childCount: entries.length,
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(top: 8)),
                SliverToBoxAdapter(
                  child: _FullLogLegend(entries: entries),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
              ],
            ),
    );
  }
}

class _FullLogTile extends StatelessWidget {
  final RunLogEntry entry;
  const _FullLogTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final catColor = runLogCategoryColor(entry.category);
    final hasCurse = entry.affectsCurse;
    final hasCool = entry.affectsCoolness;

    final timeStr =
        '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
        '${entry.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 12, right: 12),
      child: Container(
        decoration: BoxDecoration(
          color: catColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: catColor, width: 3),
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            right: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(runLogCategoryIcon(entry.category), size: 18, color: catColor),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                        if (entry.playerName != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              entry.playerName!,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: catColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (hasCurse)
                Text(
                  '${entry.curseDelta > 0 ? '+' : ''}${entry.curseDelta.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: entry.curseDelta > 0 ? catColor : Colors.redAccent,
                  ),
                ),
              if (hasCool) ...[
                if (hasCurse) const SizedBox(width: 6),
                Text(
                  '${entry.coolnessDelta > 0 ? '+' : ''}${entry.coolnessDelta.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: entry.coolnessDelta > 0 ? catColor : Colors.redAccent,
                  ),
                ),
              ],
              if (!hasCurse && !hasCool)
                Icon(runLogCategoryIcon(entry.category),
                    size: 14, color: catColor.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullLogLegend extends StatelessWidget {
  final List<RunLogEntry> entries;
  const _FullLogLegend({required this.entries});

  @override
  Widget build(BuildContext context) {
    final present = <RunLogCategory>{};
    for (final e in entries) {
      present.add(e.category);
    }
    final cats = present.toList()..sort((a, b) => a.index.compareTo(b.index));

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LEGEND',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: cats.map((c) {
              final color = runLogCategoryColor(c);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    runLogCategoryLabel(c),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
