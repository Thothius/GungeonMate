import 'package:flutter/material.dart';
import '../../services/app_theme.dart';
import '../../services/haptics.dart';
import '../../services/goop_talk_engine.dart';
import '../../widgets/particle_engine.dart';
import '../../screens/theme_picker_screen.dart';
import '../../utils/fast_route.dart';
import 'swipe_picker.dart';

class ThemeVisualsTab extends StatefulWidget {
  const ThemeVisualsTab({super.key});

  @override
  State<ThemeVisualsTab> createState() => ThemeVisualsTabState();
}

class ThemeVisualsTabState extends State<ThemeVisualsTab> {
  bool _particlesExpanded = false;
  bool _typographyExpanded = false;
  bool _inventoryExpanded = false;
  bool _glowExpanded = false;

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
                      SwipePicker<AppFont>(
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
                        SwipePicker<GlowEffect>(
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
              // Screen Glow Section (collapsible, collapsed by default)
              // =============================================================
              _collapsibleSectionHeader(
                'SCREEN GLOW',
                flair,
                _glowExpanded,
                () => setState(() => _glowExpanded = !_glowExpanded),
              ),
              if (_glowExpanded) ...[
              const SizedBox(height: 8),
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
                      // Glow color picker GÇö 4x3 grid
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
              ], // end if (_glowExpanded)

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
                        SwipePicker<InventoryDisplayMode>(
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
                        SwipePicker<int>(
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
        padding: const EdgeInsets.only(left: 4, top: 10, bottom: 10),
        child: Row(
          children: [
            GoopText(
              title,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: Colors.white38,
                letterSpacing: 0.6,
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
        padding: const EdgeInsets.only(left: 4, top: 10, bottom: 10),
        child: Row(
          children: [
            GoopText(
              title,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: Colors.white38,
                letterSpacing: 0.6,
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