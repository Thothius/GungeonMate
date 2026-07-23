import 'dart:async';
import 'dart:convert';

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
import '../widgets/particle_engine.dart';
import '../widgets/quality_badge.dart';
import '../utils/asset_paths.dart';
import 'character_select_screen.dart';
import 'theme_picker_screen.dart';
import 'shrine_picker_screen.dart';
import '../utils/fast_route.dart';
import '../services/goop_talk_engine.dart';

/// Central control room for Gungeon Mate.
/// - Tab 1: VISUALS — Theme, typography, particles, glow, wallpaper, inventory layout
/// - Tab 2: RUN — Co-op, inventory maintenance, shrines, event log, end run
/// - Tab 3: APP — Language, dialogue, dice, changelog, data reset
/// - Tab 4: DEBUG — Special items & guns spawner
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
      length: 4,
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
              Tab(text: 'DEBUG'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ThemeVisualsTab(),
            _RunTab(),
            _AppTab(),
            _DebugTab(),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Tab 1: Appearance, Theme Palette & Fonts
// =============================================================================

class _ThemeVisualsTab extends StatefulWidget {
  const _ThemeVisualsTab();

  @override
  State<_ThemeVisualsTab> createState() => _ThemeVisualsTabState();
}

class _ThemeVisualsTabState extends State<_ThemeVisualsTab> {
  bool _particlesExpanded = false;
  bool _typographyExpanded = false;
  bool _wallpaperExpanded = false;
  bool _inventoryExpanded = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppTheme.notifier,
        AppTheme.unicornPaletteNotifier,
        AppTheme.remixNotifier,
        VisualPrefs.notifier,
      ]),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                              const GoopText(
                                'ACTIVE PALETTE',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white38,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              GoopText(
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
                    const SizedBox(height: 12),
                    // Choose Theme Action Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.tune_rounded, size: 16),
                        label: const GoopText(
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
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            fastRoute(const ThemePickerScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // =============================================================
              // Typography Tuning Section (collapsible)
              // =============================================================
              _collapsibleSectionHeader(
                'APP TYPOGRAPHY TUNING',
                flair,
                _typographyExpanded,
                () => setState(() => _typographyExpanded = !_typographyExpanded),
              ),
              if (_typographyExpanded) ...[
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
                        height: 80,
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
                                GoopText(
                                  font.label,
                                  style: font.textStyle.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? flair.primary : Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                GoopText(
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
              ],
              const SizedBox(height: 16),

              // =============================================================
              // Particle System Section (collapsible)
              // =============================================================
              _collapsibleSectionHeaderWithInfo(
                'PARTICLE SYSTEM',
                flair,
                _particlesExpanded,
                () => setState(() => _particlesExpanded = !_particlesExpanded),
                tooltip: 'Enable and customize the background particle engine. Swipe through live previews to pick a preset, then fine-tune count, size, opacity, glow effect, and line links.',
              ),
              if (_particlesExpanded) ...[
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
                      // Enable toggle
                      _buildSwitchRow(
                        context: context,
                        icon: Icons.auto_awesome_outlined,
                        label: 'Enable Particles',
                        value: prefs.particlesEnabled,
                        onChanged: VisualPrefs.setParticles,
                        flair: flair,
                        tooltip: 'Toggle the entire particle system on or off.',
                      ),
                      if (prefs.particlesEnabled) ...[
                        const Divider(color: Colors.white12, height: 20),
                        // Live preview picker
                        ParticlePreviewPicker(
                          selected: prefs.particlePreset,
                          onChanged: (p) => VisualPrefs.setParticlePreset(p),
                          accentColor: flair.primary,
                        ),
                        const SizedBox(height: 14),
                        // Particle count slider (1-32)
                        _buildCompactSliderRow(
                          'Particle Count',
                          '${prefs.particleCount}',
                          prefs.particleCount.toDouble(),
                          1.0,
                          32.0,
                          31,
                          flair.headlineStat,
                          (v) => VisualPrefs.setParticleCount(v.toInt()),
                        ),
                        const SizedBox(height: 10),
                        // Particle size slider
                        _buildCompactSliderRow(
                          'Particle Size',
                          '${prefs.particleSizeScale.toStringAsFixed(1)}x',
                          prefs.particleSizeScale,
                          0.3,
                          2.0,
                          17,
                          flair.headlineStat,
                          (v) => VisualPrefs.setParticleSizeScale(v),
                        ),
                        const SizedBox(height: 10),
                        // Particle opacity slider
                        _buildCompactSliderRow(
                          'Particle Opacity',
                          '${(prefs.particleOpacity * 100).toStringAsFixed(0)}%',
                          prefs.particleOpacity,
                          0.0,
                          1.0,
                          20,
                          flair.headlineStat,
                          (v) => VisualPrefs.setParticleOpacity(v),
                        ),
                        const SizedBox(height: 12),
                        // Glow effect picker
                        _SwipePicker<GlowEffect>(
                          items: GlowEffect.values,
                          value: prefs.particleGlowEffect,
                          onChanged: (e) => VisualPrefs.setParticleGlowEffect(e),
                          height: 56,
                          itemBuilder: (effect, isSelected) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? flair.card.withValues(alpha: 0.9)
                                  : flair.card.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? flair.primary.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Center(
                              child: GoopText(
                                effect.label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: isSelected ? Colors.white : Colors.white54,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Line links toggle
                        _buildSwitchRow(
                          context: context,
                          icon: Icons.timeline_outlined,
                          label: 'Line Links',
                          value: prefs.particleLineLinks,
                          onChanged: VisualPrefs.setParticleLineLinks,
                          flair: flair,
                          tooltip: 'Draw faint connecting lines between nearby particles (particles.js style).',
                        ),
                        // Bounce toggle
                        _buildSwitchRow(
                          context: context,
                          icon: Icons.sports_baseball_outlined,
                          label: 'Edge Bounce',
                          value: prefs.particleBounce,
                          onChanged: VisualPrefs.setParticleBounce,
                          flair: flair,
                          tooltip: 'Particles bounce off screen edges instead of wrapping around.',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              ],
              const SizedBox(height: 16),

              // =============================================================
              // Screen Glow Section (slider + color picker)
              // =============================================================
              _prefSectionTitleWithInfo('SCREEN GLOW', flair, tooltip: 'Set the opacity of the ambient screen glow and choose from 12 deep, curated colors.'),
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
                      // Glow intensity slider
                      _buildCompactSliderRow(
                        'Glow Intensity',
                        '${(prefs.glowIntensity * 100).toStringAsFixed(0)}%',
                        prefs.glowIntensity,
                        0.0,
                        1.0,
                        20,
                        flair.headlineStat,
                        (v) => VisualPrefs.setGlow(v),
                      ),
                      const SizedBox(height: 14),
                      // Glow color picker — 4x3 grid
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GoopText(
                          'GLOW COLOR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white54,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: VisualPrefs.glowColors.length,
                        itemBuilder: (_, i) {
                          final color = VisualPrefs.glowColors[i];
                          final isSelected = i == prefs.glowColorIndex;
                          return GestureDetector(
                            onTap: () {
                              Haptics.selection();
                              VisualPrefs.setGlowColorIndex(i);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.12),
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 1)]
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // =============================================================
              // Wallpaper Section (collapsible)
              // =============================================================
              _collapsibleSectionHeader(
                'WALLPAPER',
                flair,
                _wallpaperExpanded,
                () => setState(() => _wallpaperExpanded = !_wallpaperExpanded),
              ),
              if (_wallpaperExpanded) ...[
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
                        // Wallpaper mode picker
                        _SwipePicker<WallpaperMode>(
                          items: WallpaperMode.values,
                          value: prefs.wallpaperMode,
                          onChanged: (m) => VisualPrefs.setWallpaperMode(m),
                          height: 56,
                          itemBuilder: (mode, isSelected) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? flair.card.withValues(alpha: 0.9)
                                  : flair.card.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? flair.primary.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Center(
                              child: GoopText(
                                mode.label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: isSelected ? Colors.white : Colors.white54,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (prefs.wallpaperMode == WallpaperMode.customStill) ...[
                          const SizedBox(height: 14),
                          // Still wallpaper grid picker
                          Align(
                            alignment: Alignment.centerLeft,
                            child: GoopText(
                              'STILL WALLPAPER',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white54, letterSpacing: 1.0),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1.0,
                            ),
                            itemCount: kStillWallpapers.length,
                            itemBuilder: (_, i) {
                              final w = kStillWallpapers[i];
                              final isSelected = w['asset'] == prefs.selectedStillWallpaper;
                              return GestureDetector(
                                onTap: () {
                                  Haptics.selection();
                                  VisualPrefs.setSelectedStillWallpaper(w['asset']!);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? flair.primary : Colors.white.withValues(alpha: 0.12),
                                      width: isSelected ? 2.0 : 1.0,
                                    ),
                                    boxShadow: isSelected
                                        ? [BoxShadow(color: flair.primary.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1)]
                                        : null,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    child: Image.asset(
                                      'assets/images/wallpapers/still/${w['asset']}',
                                      fit: BoxFit.cover,
                                      filterQuality: FilterQuality.low,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.white12,
                                        child: const Icon(Icons.broken_image_outlined, size: 20, color: Colors.white24),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          // Parallax motion toggle
                          _buildSwitchRow(
                            context: context,
                            icon: Icons.gps_not_fixed_outlined,
                            label: 'Parallax Motion',
                            value: prefs.parallaxMotionEnabled,
                            onChanged: VisualPrefs.setParallaxMotionEnabled,
                            flair: flair,
                            tooltip: 'Tilt your device to shift the wallpaper slightly for a 3D depth effect.',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // =============================================================
              // Inventory Layout Section (collapsible)
              // =============================================================
              _collapsibleSectionHeader(
                'INVENTORY LAYOUT',
                flair,
                _inventoryExpanded,
                () => setState(() => _inventoryExpanded = !_inventoryExpanded),
              ),
              if (_inventoryExpanded) ...[
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
                        // Display mode picker
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GoopText(
                            'DISPLAY MODE',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white54, letterSpacing: 1.0),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _SwipePicker<InventoryDisplayMode>(
                          items: InventoryDisplayMode.values,
                          value: prefs.inventoryDisplayMode,
                          onChanged: (m) => VisualPrefs.setInventoryDisplayMode(m),
                          height: 56,
                          itemBuilder: (mode, isSelected) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? flair.card.withValues(alpha: 0.9)
                                  : flair.card.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? flair.primary.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Center(
                              child: GoopText(
                                mode == InventoryDisplayMode.classicPeriodic ? 'Classic Periodic' : 'Tactical Stats',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: isSelected ? Colors.white : Colors.white54,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Divider(color: Colors.white12, height: 20),
                        // Inventory font size slider
                        _buildCompactSliderRow(
                          'Inventory Font Size',
                          '${prefs.inventoryFontSize.toStringAsFixed(0)} pt',
                          prefs.inventoryFontSize,
                          6.0,
                          20.0,
                          14,
                          flair.headlineStat,
                          (v) => VisualPrefs.setInventoryFontSize(v),
                        ),
                        const SizedBox(height: 10),
                        // Periodic grid column count
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GoopText(
                            'PERIODIC GRID COLUMNS',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white54, letterSpacing: 1.0),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _SwipePicker<int>(
                          items: const [0, 2, 3, 4],
                          value: prefs.periodicGridColumnCount,
                          onChanged: (c) => VisualPrefs.setPeriodicGridColumnCount(c),
                          height: 56,
                          itemBuilder: (cols, isSelected) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? flair.card.withValues(alpha: 0.9)
                                  : flair.card.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? flair.primary.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Center(
                              child: GoopText(
                                cols == 0 ? 'Auto' : '$cols',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: isSelected ? Colors.white : Colors.white54,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _collapsibleSectionHeader(
    String title,
    ThemeFlair flair,
    bool expanded,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: () {
        Haptics.selection();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 4),
        child: Row(
          children: [
            GoopText(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.white60,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 180),
              child: Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _collapsibleSectionHeaderWithInfo(
    String title,
    ThemeFlair flair,
    bool expanded,
    VoidCallback onTap, {
    String? tooltip,
  }) {
    return InkWell(
      onTap: () {
        Haptics.selection();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 4),
        child: Row(
          children: [
            GoopText(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.white60,
                letterSpacing: 0.5,
              ),
            ),
            if (tooltip != null) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: tooltip,
                triggerMode: TooltipTriggerMode.tap,
                showDuration: const Duration(seconds: 5),
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: flair.primary.withValues(alpha: 0.65),
                      width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: flair.primary.withValues(alpha: 0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                textStyle: const TextStyle(
                    fontSize: 10.5,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
                child: Icon(Icons.info_outline_rounded,
                    size: 13,
                    color: flair.primary.withValues(alpha: 0.6)),
              ),
            ],
            const Spacer(),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 180),
              child: Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _prefSectionTitleWithInfo(String title, ThemeFlair flair, {String? tooltip}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GoopText(
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
            GoopText(
              label,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            GoopText(
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
// Tab 2: Run Management (Add Player, Reset, End Run)
// =============================================================================

class _RunTab extends StatefulWidget {
  const _RunTab();

  @override
  State<_RunTab> createState() => _RunTabState();
}

class _RunTabState extends State<_RunTab> {
  void _addCoopPlayer(BuildContext context, RunProvider p) {
    final cultist = p.gungeoneerByName('The Cultist') ?? p.gungeoneerByName('Cultist');
    if (cultist != null) {
      p.startCoopPlayer(cultist);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: GoopText('${cultist.name} joined as Player 2!'),
        duration: const Duration(milliseconds: 1400),
        action: SnackBarAction(
          label: 'CHANGE',
          onPressed: () => Navigator.push(
            context,
            fastRoute(const CharacterSelectScreen(mode: CharSelectMode.coop)),
          ),
        ),
      ));
      return;
    }
    Navigator.push(
      context,
      fastRoute(const CharacterSelectScreen(mode: CharSelectMode.coop)),
    );
  }

  void _confirmRemoveCoop(BuildContext context, RunProvider p) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const GoopText('Remove Player 2 (Co-op)?'),
        content: const GoopText('Their loadout will be discarded. Items are not transferred to Player 1.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const GoopText('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade900),
            onPressed: () {
              p.endCoopPlayer();
              Navigator.pop(c);
            },
            child: const GoopText('Remove'),
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
        title: GoopText("Clear $name's inventory?"),
        content: const GoopText(
          'Removes all guns and items except their starter loadout. '
          'Coolness, curse, and shrine status are unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const GoopText('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade900),
            onPressed: () {
              p.clearInventory(slot: slot);
              Navigator.pop(c);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: GoopText("$name's items cleared!"),
                duration: const Duration(seconds: 1),
              ));
            },
            child: const GoopText('Clear Inventory'),
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
        title: const GoopText('End Run?'),
        content: const GoopText('This resets the current active run completely and returns you to the character select screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const GoopText('Cancel'),
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
            child: const GoopText('End Run'),
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
        title: const GoopText('Leave Multiplayer?'),
        content: GoopText(
          isSidekick
              ? 'You will disconnect from the host. Your inventory will be restored to your pre-MP state.'
              : 'You will disconnect and end the multiplayer session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const GoopText('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent.withValues(alpha: 0.15),
                foregroundColor: Colors.lightBlueAccent),
            onPressed: () {
              session.cancel();
              Navigator.pop(c);
            },
            child: const GoopText('Leave'),
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
    final mpSession = context.watch<MultiplayerSession>();
    final mpActive = mpSession.isActive;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👥 Multiplayer & Co-op
          _sectionHeader('👥 MULTIPLAYER & CO-OP'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GoopText(
                        hasCoop ? 'PLAYER 2 ACTIVE' : 'SOLO PLAYER ACTIVE',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: hasCoop ? Colors.pinkAccent : Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GoopText(
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
                  child: GoopText(hasCoop ? 'Remove P2' : 'Add Co-op'),
                ),
              ],
            ),
          ),
          if (mpActive) ...[
            const SizedBox(height: 10),
            _utilTile(
              title: 'Save MP Session',
              subtitle: 'Persist current multiplayer state for reconnection.',
              icon: Icons.save_outlined,
              color: Colors.greenAccent,
              onTap: () {
                unawaited(mpSession.saveCurrentSession().then((_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: GoopText('Run saved'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }).catchError((e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: GoopText('Failed to save session: $e'),
                        duration: const Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }));
              },
            ),
            if (mpSession.myRole == MpRole.sidekick)
              _utilTile(
                title: 'Leave Multiplayer',
                subtitle: 'Disconnect from the host and return to solo play.',
                icon: Icons.bluetooth_disabled,
                color: Colors.lightBlueAccent,
                onTap: () => _confirmLeaveMp(context, mpSession),
              ),
          ],
          const SizedBox(height: 12),

          // 🧹 Inventory Maintenance
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
          const SizedBox(height: 12),

          // 🛐 Gameplay Actions
          _sectionHeader('🛐 GAMEPLAY ACTIONS'),
          _utilTile(
            title: 'Use Shrine',
            subtitle: 'Apply a shrine effect to the active player.',
            icon: Icons.temple_buddhist,
            color: Colors.amber,
            onTap: () => Navigator.push(
              context,
              fastRoute(const ShrinePickerScreen()),
            ),
          ),
          const SizedBox(height: 12),

          // 📜 Run Data
          _sectionHeader('📜 RUN DATA'),
          _utilTile(
            title: 'View Event History',
            subtitle: 'See all pickups, stat changes, shrines, synergies & manual actions.',
            icon: Icons.history_edu_rounded,
            color: const Color(0xFFFFD740),
            onTap: () => Navigator.push(
              context,
              fastRoute(const RunLogScreen()),
            ),
          ),
          const SizedBox(height: 12),

          // ⚠️ Core Actions
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
}

// =============================================================================
// Tab 3: App — Language, Dialogue, Dice, Changelog, Data Reset
// =============================================================================

class _AppTab extends StatefulWidget {
  const _AppTab();

  @override
  State<_AppTab> createState() => _AppTabState();
}

class _AppTabState extends State<_AppTab> {
  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final p = context.watch<RunProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🌐 Language
          _sectionHeader('🌐 LANGUAGE'),
          _buildLanguageCard(flair),
          const SizedBox(height: 12),

          // 💬 Dialogue
          _sectionHeader('💬 DIALOGUE'),
          _buildDialogueCard(flair),
          const SizedBox(height: 12),

          // 🎲 Dice
          _sectionHeader('🎲 DICE'),
          _buildDiceCard(flair),
          const SizedBox(height: 12),

          // 📜 Changelog
          _sectionHeader('📜 ABOUT'),
          _utilTile(
            title: 'View Changelog',
            subtitle: 'See version history and recent updates.',
            icon: Icons.history_edu_rounded,
            color: const Color(0xFFFFD740),
            onTap: () => _showChangelogDialog(context),
          ),
          const SizedBox(height: 12),

          // ⚠️ Data
          _sectionHeader('⚠️ DATA MANAGEMENT'),
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

  Widget _buildLanguageCard(ThemeFlair flair) {
    return Card(
      color: flair.card.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: flair.primary.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: ListenableBuilder(
          listenable: VisualPrefs.notifier,
          builder: (context, _) {
            final isGoopian = VisualPrefs.notifier.value.isGoopianLanguage;
            return Row(
              children: [
                Icon(Icons.language, size: 16, color: Colors.white54),
                const SizedBox(width: 10),
                Expanded(
                  child: GoopText(
                    'GOOPIAN LANGUAGE MODE',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 0.5),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Haptics.selection();
                    VisualPrefs.setIsGoopianLanguage(!isGoopian);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isGoopian
                          ? const Color(0xFF9C27B0).withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isGoopian
                            ? const Color(0xFF9C27B0).withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: GoopText(
                      isGoopian ? 'GOOPIAN' : 'ENGLISH',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isGoopian ? const Color(0xFF9C27B0) : Colors.white54,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

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

  Widget _buildDiceCard(ThemeFlair flair) {
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
            Align(
              alignment: Alignment.centerLeft,
              child: GoopText(
                'CUSTOM DICE STYLE',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white54, letterSpacing: 1.0),
              ),
            ),
            const SizedBox(height: 8),
            _SwipePicker<CustomDiceType>(
              items: CustomDiceType.values,
              value: prefs.customDiceType,
              onChanged: (t) => VisualPrefs.setCustomDiceType(t),
              height: 56,
              itemBuilder: (type, isSelected) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? flair.card.withValues(alpha: 0.9)
                      : flair.card.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? flair.primary.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Center(
                  child: GoopText(
                    type.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : Colors.white54,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
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
    } catch (_) {}
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
                      color: const Color(0xFF1E1E22),
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
        title: const GoopText('EVENT LOG'),
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
                  GoopText(
                    'No events logged yet',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GoopText(
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
                        GoopText(
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
                    GoopText(
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
                        GoopText(
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
                            child: GoopText(
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
                GoopText(
                  '${entry.curseDelta > 0 ? '+' : ''}${entry.curseDelta.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: entry.curseDelta > 0 ? catColor : Colors.redAccent,
                  ),
                ),
              if (hasCool) ...[
                if (hasCurse) const SizedBox(width: 6),
                GoopText(
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
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoopText(
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
                  GoopText(
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
// Tab 4: Debug Mode — Special Items & Guns Spawner
// =============================================================================

class _DebugTab extends StatelessWidget {
  const _DebugTab();

  // Names exactly matching _DashboardSwiper trigger conditions.
  static const _specialGunNames = [
    'Gunderfury', 'Triple Gun', 'Evolver', 'Shellegun',
    'Chamber Gun', 'Boxing Glove', 'Polaris', 'Gunther',
  ];
  static const _specialItemNames = [
    'Ser Junkan', 'Platinum Bullets', 'Iron Coin', 'Spice',
    'Metronome', 'Sprun', 'Cigarettes', 'Gun Soul',
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final hasRun = p.runState.main.character != null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Icon(Icons.bug_report_rounded, size: 48, color: Colors.greenAccent.withValues(alpha: 0.6)),
        const SizedBox(height: 12),
        const GoopText(
          'DEBUG MODE',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.greenAccent),
        ),
        const SizedBox(height: 6),
        GoopText(
          'Testing tools for dashboards and special item interactions.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 24),
        _utilTile(
          context,
          icon: Icons.grid_view_rounded,
          title: 'Special Items & Guns',
          subtitle: 'Spawn all 18 dashboard-triggering items/guns into your inventory',
          onTap: hasRun
              ? () {
                  Haptics.selection();
                  Navigator.push(context, fastRoute(const _SpecialItemsGridScreen()));
                }
              : null,
        ),
        if (!hasRun) ...[
          const SizedBox(height: 12),
          GoopText(
            'Start a run first to use debug tools.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.orangeAccent.withValues(alpha: 0.7)),
          ),
        ],
      ],
    );
  }

  Widget _utilTile(BuildContext context, {required IconData icon, required String title, required String subtitle, VoidCallback? onTap}) {
    return Card(
      color: Colors.white.withValues(alpha: 0.03),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: Icon(icon, color: Colors.greenAccent, size: 22),
        title: GoopText(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: GoopText(subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
        trailing: Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.3), size: 20),
        onTap: onTap,
      ),
    );
  }
}

// =============================================================================
// Special Items Grid — 4-column picker with add/remove + Add All
// =============================================================================

class _SpecialItemsGridScreen extends StatefulWidget {
  const _SpecialItemsGridScreen();

  @override
  State<_SpecialItemsGridScreen> createState() => _SpecialItemsGridScreenState();
}

class _SpecialItemsGridScreenState extends State<_SpecialItemsGridScreen> {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final player = p.runState.main;
    final ownedGunNames = player.guns.map((g) => g.name.toLowerCase()).toSet();
    final ownedItemNames = player.items.map((i) => i.name.toLowerCase()).toSet();

    final entries = <_SpecialEntry>[];

    for (final name in _DebugTab._specialGunNames) {
      final gun = p.gunByName(name);
      entries.add(_SpecialEntry(
        name: name,
        isGun: true,
        owned: ownedGunNames.contains(name.toLowerCase()),
        iconPath: gun?.icon ?? localGunIcon(name),
        quality: gun?.quality ?? '',
      ));
    }
    for (final name in _DebugTab._specialItemNames) {
      final item = p.itemByName(name);
      entries.add(_SpecialEntry(
        name: name,
        isGun: false,
        owned: ownedItemNames.contains(name.toLowerCase()),
        iconPath: item?.icon ?? localItemIcon(name),
        quality: item?.quality ?? '',
      ));
    }

    final allOwned = entries.every((e) => e.owned);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E22),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: const GoopText('SPECIAL ITEMS & GUNS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Haptics.selection();
              if (allOwned) {
                for (final name in _DebugTab._specialGunNames) {
                  final gun = p.gunByName(name);
                  if (gun != null && ownedGunNames.contains(name.toLowerCase())) {
                    p.removeGun(gun, force: true);
                  }
                }
                for (final name in _DebugTab._specialItemNames) {
                  final item = p.itemByName(name);
                  if (item != null && ownedItemNames.contains(name.toLowerCase())) {
                    p.removeItem(item, force: true);
                  }
                }
              } else {
                for (final name in _DebugTab._specialGunNames) {
                  final gun = p.gunByName(name);
                  if (gun != null && !ownedGunNames.contains(name.toLowerCase())) {
                    p.addGun(gun, force: true);
                  }
                }
                for (final name in _DebugTab._specialItemNames) {
                  final item = p.itemByName(name);
                  if (item != null && !ownedItemNames.contains(name.toLowerCase())) {
                    p.addItem(item, force: true);
                  }
                }
              }
            },
            icon: Icon(allOwned ? Icons.remove_circle : Icons.add_circle, size: 18, color: Colors.greenAccent),
            label: GoopText(
              allOwned ? 'Remove All' : 'Add All',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.greenAccent),
            ),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.82,
        ),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final e = entries[index];
          return _SpecialGridTile(
            entry: e,
            onTap: () {
              Haptics.light();
              if (e.owned) {
                if (e.isGun) {
                  final gun = p.gunByName(e.name);
                  if (gun != null) p.removeGun(gun, force: true);
                } else {
                  final item = p.itemByName(e.name);
                  if (item != null) p.removeItem(item, force: true);
                }
              } else {
                if (e.isGun) {
                  final gun = p.gunByName(e.name);
                  if (gun != null) p.addGun(gun, force: true);
                } else {
                  final item = p.itemByName(e.name);
                  if (item != null) p.addItem(item, force: true);
                }
              }
            },
          );
        },
      ),
    );
  }
}

class _SpecialEntry {
  final String name;
  final bool isGun;
  final bool owned;
  final String iconPath;
  final String quality;
  const _SpecialEntry({required this.name, required this.isGun, required this.owned, required this.iconPath, required this.quality});
}

class _SpecialGridTile extends StatelessWidget {
  final _SpecialEntry entry;
  final VoidCallback onTap;
  const _SpecialGridTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = QualityBadge.colorFor(entry.quality);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: entry.owned ? accent.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: entry.owned ? accent.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08),
            width: entry.owned ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(
                    entry.iconPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      entry.isGun ? Icons.gps_fixed : Icons.star,
                      color: Colors.white24,
                      size: 20,
                    ),
                  ),
                ),
                if (entry.owned)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                      child: const Icon(Icons.check, size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            GoopText(
              entry.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: entry.owned ? accent : Colors.white.withValues(alpha: 0.5),
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
