import 'package:flutter/material.dart';
import '../services/goop_talk_engine.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_theme.dart';
import '../widgets/themed_number.dart';
import '../services/haptics.dart';
import '../widgets/quality_badge.dart';

/// Full-screen swipe-to-preview theme picker. Each [PageView] page
/// renders a miniature dashboard styled with that theme's [ThemeFlair]
/// — scaffold + AppBar + card + three stat numbers + a chip row + a
/// bullet list — so the player can taste the colours and quirks
/// before committing. The currently active theme is outlined in the
/// preview's corner; tapping "Use this theme" persists via
/// [AppTheme.setMode] and pops the screen.
class ThemePickerScreen extends StatefulWidget {
  const ThemePickerScreen({super.key});

  @override
  State<ThemePickerScreen> createState() => _ThemePickerScreenState();
}

class _ThemePickerScreenState extends State<ThemePickerScreen> {
  late final PageController _pc;
  late int _index;
  late AppThemeMode _activeMode;

  void controllerRepeatHelper(AnimationController c) => c.repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _activeMode = AppTheme.mode;
    final visibleIdx = kVisibleThemes.indexOf(_activeMode);
    _index = visibleIdx >= 0 ? visibleIdx : 0;
    _pc = PageController(initialPage: _index, viewportFraction: 0.88);

    // Seed the preview notifier with the initial selection
    AppTheme.previewNotifier.value = _activeMode;
  }

  @override
  void dispose() {
    _pc.dispose();
    // Clear the preview notifier so we restore the active app theme
    AppTheme.previewNotifier.value = null;
    super.dispose();
  }

  void _select(AppThemeMode m) {
    AppTheme.previewNotifier.value = null; // Clear preview before applying
    AppTheme.setMode(m);
    setState(() => _activeMode = m);
    Haptics.success(); // Satisfying double-pulse success haptic on apply!
    // If embedded inside a root tab (HomeScreen IndexedStack), canPop is false.
    // In that case, we don't pop, we let the user stay on the selection page.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modes = kVisibleThemes;
    final cleanTextTheme = GoogleFonts.montserratTextTheme(ThemeData.dark().textTheme);
    final cleanTheme = Theme.of(context).copyWith(
      textTheme: cleanTextTheme,
    );

    return Theme(
      data: cleanTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const GoopText('CHOOSE PALETTE'),
          centerTitle: true,
          automaticallyImplyLeading: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Arcade instruction badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.7),
                    width: 1.2,
                  ),
                ),
                child: const GoopText(
                  'SELECT YOUR THEME',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.redAccent,
                    letterSpacing: 2,
                  ),
                ),
              )
              .animate(onPlay: (c) => controllerRepeatHelper(c))
              .fadeIn(duration: 750.ms)
              .then()
              .fadeOut(duration: 750.ms),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GoopText(
                  'Swipe to preview each palette live. Tap a card to apply.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 520,
                child: PageView.builder(
                  controller: _pc,
                  itemCount: modes.length,
                  onPageChanged: (i) {
                    setState(() => _index = i);
                    AppTheme.previewNotifier.value = modes[i]; // Live dynamic preview fix!
                    Haptics.selection();
                  },
                  itemBuilder: (context, i) {
                    final m = modes[i];
                    final selected = m == _activeMode;
                    final focused = i == _index;
                    return AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      scale: focused ? 1.0 : 0.94,
                      curve: Curves.easeOut,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: _ThemePreviewCard(
                          mode: m,
                          isActive: selected,
                          onApply: () => _select(m),
                          isNew: false,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Page-dot strip
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(modes.length, (i) {
                    final on = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: on ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: on
                            ? Colors.white.withValues(alpha: 0.85)
                            : Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),
              // Live dynamic customization tuning panel
              ValueListenableBuilder<VisualPrefs>(
                valueListenable: VisualPrefs.notifier,
                builder: (context, prefs, child) {
                  return _buildTuningSection(context, prefs);
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTuningSection(BuildContext context, VisualPrefs prefs) {
    final activeThemeFlair = AppTheme.flairFor(_activeMode);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: activeThemeFlair.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: activeThemeFlair.dividerColor ?? Colors.white.withValues(alpha: 0.08),
          width: activeThemeFlair.dividerThickness,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, color: activeThemeFlair.primary, size: 20),
                const SizedBox(width: 8),
                GoopText(
                  'VIBE & CUSTOMIZATION TUNING',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: activeThemeFlair.primary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1, thickness: 1),
          
          // 1. Font Selection Dropdown (Highly Compact!)
          _buildOptionRow(
            icon: Icons.font_download_outlined,
            label: 'App Font Style',
            activeThemeFlair: activeThemeFlair,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AppFont>(
                  value: prefs.font,
                  isExpanded: true,
                  dropdownColor: activeThemeFlair.card,
                  icon: Icon(Icons.arrow_drop_down, color: activeThemeFlair.primary),
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
                        f.label,
                        style: f.textStyle.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isSel ? activeThemeFlair.primary : Colors.white70,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Live Font Preview Card (shows how the selected font fits GungeonMate's layout and colors!)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: activeThemeFlair.scaffold.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: activeThemeFlair.primary.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GoopText(
                    'LIVE FONT PREVIEW',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: activeThemeFlair.primary.withValues(alpha: 0.6),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The Breach: Bello\'s Custom Curios Shop',
                    style: prefs.font.textStyle.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: activeThemeFlair.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'DMG: 125 | CRS: +1.5 | COL: +2.0',
                    style: prefs.font.textStyle.copyWith(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 2. Font Size (6px to 32px, adjustable by 2)
          _buildOptionRow(
            icon: Icons.format_size_rounded,
            label: 'Font Size (6px - 32px, step: 2)',
            activeThemeFlair: activeThemeFlair,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Decrement Button (-)
                InkWell(
                  onTap: () {
                    VisualPrefs.setFontSize(prefs.fontSize - 2.0);
                    Haptics.selection();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: prefs.fontSize <= 6.0 
                            ? Colors.white10 
                            : activeThemeFlair.primary.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '—',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: prefs.fontSize <= 6.0 ? Colors.white24 : activeThemeFlair.primary,
                      ),
                    ),
                  ),
                ),
                
                // Current Size Readout
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 80),
                    alignment: Alignment.center,
                    child: Text(
                      '${prefs.fontSize.toStringAsFixed(0)} px',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                
                // Increment Button (+)
                InkWell(
                  onTap: () {
                    VisualPrefs.setFontSize(prefs.fontSize + 2.0);
                    Haptics.selection();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: prefs.fontSize >= 32.0 
                            ? Colors.white10 
                            : activeThemeFlair.primary.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '＋',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: prefs.fontSize >= 32.0 ? Colors.white24 : activeThemeFlair.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2.7. Ambient Glow Intensity (0.0 to 1.0)
          _buildOptionRow(
            icon: Icons.lightbulb_outline_rounded,
            label: 'Ambient Glow Intensity (${(prefs.glowIntensity * 100).toStringAsFixed(0)}%)',
            activeThemeFlair: activeThemeFlair,
            child: Slider(
              min: 0.0,
              max: 1.0,
              value: prefs.glowIntensity,
              activeColor: activeThemeFlair.primary,
              inactiveColor: Colors.white10,
              onChanged: (v) {
                VisualPrefs.setGlow(v);
              },
            ),
          ),
          
          // 3. Font Weight Bias (-800 to +800 adjustments)
          _buildOptionRow(
            icon: Icons.format_bold_rounded,
            label: 'Font Weight Bias (${prefs.fontWeightBias > 0 ? "+" : ""}${prefs.fontWeightBias})',
            activeThemeFlair: activeThemeFlair,
            child: Builder(builder: (ctx) {
              const steps = [-800, -400, 0, 400, 800];
              int idx = steps.indexOf(prefs.fontWeightBias);
              if (idx == -1) {
                // Find closest step
                int closestIdx = 2; // default 0
                double minDiff = 9999.0;
                for (int i = 0; i < steps.length; i++) {
                  final diff = (prefs.fontWeightBias - steps[i]).abs().toDouble();
                  if (diff < minDiff) {
                    minDiff = diff;
                    closestIdx = i;
                  }
                }
                idx = closestIdx;
              }
              final canDec = idx > 0;
              final canInc = idx < steps.length - 1;

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Decrement Button
                  InkWell(
                    onTap: canDec ? () {
                      VisualPrefs.setFontWeightBias(steps[idx - 1]);
                      Haptics.selection();
                    } : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 60,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: !canDec 
                              ? Colors.white10 
                              : activeThemeFlair.primary.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        'DEC',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: !canDec ? Colors.white24 : activeThemeFlair.primary,
                        ),
                      ),
                    ),
                  ),
                  
                  // Current Bias Readout
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 100),
                      alignment: Alignment.center,
                      child: Text(
                        prefs.fontWeightBias == 0 ? 'Normal' : '${prefs.fontWeightBias > 0 ? "+" : ""}${prefs.fontWeightBias}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  
                  // Increment Button
                  InkWell(
                    onTap: canInc ? () {
                      VisualPrefs.setFontWeightBias(steps[idx + 1]);
                      Haptics.selection();
                    } : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 60,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: !canInc 
                              ? Colors.white10 
                              : activeThemeFlair.primary.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        'INC',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: !canInc ? Colors.white24 : activeThemeFlair.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
          
          // 4. Particle Effect Type Customizer
          _buildOptionRow(
            icon: Icons.bubble_chart_outlined,
            label: 'Particle Effect Type',
            activeThemeFlair: activeThemeFlair,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CustomParticleType>(
                  value: prefs.customParticleType,
                  isExpanded: true,
                  dropdownColor: activeThemeFlair.card,
                  icon: Icon(Icons.arrow_drop_down, color: activeThemeFlair.primary),
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
                          color: isSel ? activeThemeFlair.primary : Colors.white70,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // 5. Particle Count (Density / Count)
          _buildOptionRow(
            icon: Icons.grain_rounded,
            label: 'Particle Count (${prefs.particleCount})',
            activeThemeFlair: activeThemeFlair,
            child: Slider(
              min: 5.0,
              max: 120.0,
              divisions: 23,
              value: prefs.particleCount.toDouble(),
              activeColor: activeThemeFlair.primary,
              inactiveColor: Colors.white10,
              onChanged: (v) {
                VisualPrefs.setParticleCount(v.toInt());
              },
            ),
          ),

          // 6. Particle Size Scale (0.5x to 3.0x)
          _buildOptionRow(
            icon: Icons.photo_size_select_small_rounded,
            label: 'Particle Size (${prefs.particleSizeScale.toStringAsFixed(1)}x)',
            activeThemeFlair: activeThemeFlair,
            child: Slider(
              min: 0.5,
              max: 3.0,
              divisions: 25,
              value: prefs.particleSizeScale,
              activeColor: activeThemeFlair.primary,
              inactiveColor: Colors.white10,
              onChanged: (v) {
                VisualPrefs.setParticleSizeScale(v);
              },
            ),
          ),

          // 7. Subtle Particle Mode
          _buildOptionRow(
            icon: Icons.visibility_off_outlined,
            label: 'Subtle Particle Mode',
            activeThemeFlair: activeThemeFlair,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Halves particles for high legibility',
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ),
                Switch(
                  value: prefs.subtleParticleMode,
                  activeColor: activeThemeFlair.primary,
                  onChanged: (v) {
                    VisualPrefs.setSubtleParticleMode(v);
                    Haptics.selection();
                  },
                ),
              ],
            ),
          ),

          // 8. Periodic Grid Columns
          _buildOptionRow(
            icon: Icons.grid_on_rounded,
            label: 'Periodic Grid Columns',
            activeThemeFlair: activeThemeFlair,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: prefs.periodicGridColumnCount,
                  isExpanded: true,
                  dropdownColor: activeThemeFlair.card,
                  icon: Icon(Icons.arrow_drop_down, color: activeThemeFlair.primary),
                  onChanged: (int? val) {
                    if (val != null) {
                      VisualPrefs.setPeriodicGridColumnCount(val);
                      Haptics.selection();
                    }
                  },
                  items: const [
                    DropdownMenuItem<int>(
                      value: 0,
                      child: Text('Responsive (Auto)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
                    ),
                    DropdownMenuItem<int>(
                      value: 2,
                      child: Text('Compact (2 Columns)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
                    ),
                    DropdownMenuItem<int>(
                      value: 3,
                      child: Text('Medium (3 Columns)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
                    ),
                    DropdownMenuItem<int>(
                      value: 4,
                      child: Text('Dense (4 Columns)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 9. Wallpaper Mode
          _buildOptionRow(
            icon: Icons.wallpaper_rounded,
            label: 'Wallpaper Mode',
            activeThemeFlair: activeThemeFlair,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<WallpaperMode>(
                  value: prefs.wallpaperMode,
                  isExpanded: true,
                  dropdownColor: activeThemeFlair.card,
                  icon: Icon(Icons.arrow_drop_down, color: activeThemeFlair.primary),
                  onChanged: (WallpaperMode? val) {
                    if (val != null) {
                      VisualPrefs.setWallpaperMode(val);
                      Haptics.selection();
                    }
                  },
                  items: WallpaperMode.values.map((WallpaperMode mode) {
                    return DropdownMenuItem<WallpaperMode>(
                      value: mode,
                      child: Text(
                        mode.label,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          if (prefs.wallpaperMode == WallpaperMode.customStill) ...[
            // 10. Select Still Wallpaper
            _buildOptionRow(
              icon: Icons.image_outlined,
              label: 'Select Still Wallpaper',
              activeThemeFlair: activeThemeFlair,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: prefs.selectedStillWallpaper,
                    isExpanded: true,
                    dropdownColor: activeThemeFlair.card,
                    icon: Icon(Icons.arrow_drop_down, color: activeThemeFlair.primary),
                    onChanged: (String? val) {
                      if (val != null) {
                        VisualPrefs.setSelectedStillWallpaper(val);
                        Haptics.selection();
                      }
                    },
                    items: kStillWallpapers.map((map) {
                      return DropdownMenuItem<String>(
                        value: map['asset'],
                        child: Text(
                          map['name']!,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            // 11. Gyroscopic Parallax Sway
            _buildOptionRow(
              icon: Icons.screen_rotation_rounded,
              label: 'Gyroscopic Parallax Sway',
              activeThemeFlair: activeThemeFlair,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Responsive 3D background sways',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ),
                  Switch(
                    value: prefs.parallaxMotionEnabled,
                    activeColor: activeThemeFlair.primary,
                    onChanged: (v) {
                      VisualPrefs.setParallaxMotionEnabled(v);
                      Haptics.selection();
                    },
                  ),
                ],
              ),
            ),
          ],

          if (prefs.wallpaperMode == WallpaperMode.customAnimated) ...[
            // 12. Select Animated Live Loop
            _buildOptionRow(
              icon: Icons.play_circle_outline_rounded,
              label: 'Select Live Loop',
              activeThemeFlair: activeThemeFlair,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: prefs.selectedAnimatedWallpaper,
                    isExpanded: true,
                    dropdownColor: activeThemeFlair.card,
                    icon: Icon(Icons.arrow_drop_down, color: activeThemeFlair.primary),
                    onChanged: (String? val) {
                      if (val != null) {
                        VisualPrefs.setSelectedAnimatedWallpaper(val);
                        Haptics.selection();
                      }
                    },
                    items: kAnimatedWallpapers.map((map) {
                      return DropdownMenuItem<String>(
                        value: map['asset'],
                        child: Text(
                          map['name']!,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildOptionRow({
    required IconData icon,
    required String label,
    required ThemeFlair activeThemeFlair,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.white54),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.white54,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
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
          fontSize: 11,
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
}

/// Renders a single theme as a self-contained mini dashboard. Uses the
/// theme's [ThemeFlair] palette directly so it's identical to what the
/// live app will look like — no approximations.
class _ThemePreviewCard extends StatelessWidget {
  final AppThemeMode mode;
  final bool isActive;
  final VoidCallback onApply;
  final bool isNew;
  const _ThemePreviewCard({
    required this.mode,
    required this.isActive,
    required this.onApply,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    final f = AppTheme.flairFor(mode);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onApply,
        child: Container(
          decoration: BoxDecoration(
            color: f.scaffold,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? f.primary
                  : Colors.white.withValues(alpha: 0.08),
              width: isActive ? 2.0 : 1.0,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: f.primary.withValues(alpha: 0.25),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Mini AppBar — coloured underline establishes the theme's
                      // primary accent immediately.
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      mode.label,
                                      style: TextStyle(
                                        color: f.headlineStat,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    if (isNew) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'NEW',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  mode.tagline,
                                  style: TextStyle(
                                    color: f.secondary.withValues(alpha: 0.85),
                                    fontSize: 11,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: f.primary.withValues(alpha: 0.15),
                                border: Border.all(color: f.primary, width: 1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: f.primary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [f.primary, f.secondary],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Arcade Style Theme Attributes Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _ArcadeAttribute(label: 'VIBE', value: mode.vibe, color: f.primary),
                          _ArcadeAttribute(label: 'DIFFICULTY', value: mode.diff, color: Colors.amberAccent),
                          _ArcadeAttribute(label: 'ELEMENT', value: mode.elem, color: f.secondary),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Whimsical Description Panel (Adds extreme Gungeon flavor!)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: f.primary.withValues(alpha: 0.1), width: 0.8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.format_quote_rounded, size: 14, color: f.primary.withValues(alpha: 0.6)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: GoopText(
                                mode.whimsicalDescription,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Core Color Swatches (Pimped out visual!)
                      Row(
                        children: [
                          const Text(
                            'PALETTE CORES:',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white54,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _ColorCoreBox(color: f.scaffold, label: 'BG'),
                          const SizedBox(width: 4),
                          _ColorCoreBox(color: f.card, label: 'CRD'),
                          const SizedBox(width: 4),
                          _ColorCoreBox(color: f.primary, label: 'PRI'),
                          const SizedBox(width: 4),
                          _ColorCoreBox(color: f.secondary, label: 'SEC'),
                          const SizedBox(width: 4),
                          _ColorCoreBox(color: f.headlineStat, label: 'ACC'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Mini card with three headline stats — directly using
                      // ThemedNumber so the picker preview includes the actual
                      // shimmer/glow/tabular treatment.
                      _PreviewWrapper(mode: mode, child: _PreviewStatsRow(flair: f)),
                      const SizedBox(height: 8),
                      // Chip row.
                      _PreviewWrapper(mode: mode, child: _PreviewChipsRow(flair: f)),
                      const SizedBox(height: 8),
                      // Bullet list — twinkles in Unicorn, paw-prints in Guan
                      // Guan, brass dashes in Winchester, etc.
                      _PreviewWrapper(mode: mode, child: _PreviewBullets(flair: f)),
                      const SizedBox(height: 8),
                      // Inventory preview row — shows a gun tile and an item tile
                      // with quality ring to give a feel of the actual game UI.
                      _PreviewWrapper(mode: mode, child: _PreviewInventoryRow(flair: f)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: FilledButton(
                  onPressed: onApply,
                  style: FilledButton.styleFrom(
                    backgroundColor: f.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(f.chipRadius),
                    ),
                  ),
                  child: GoopText(
                    isActive ? 'Selected' : 'Use this theme',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The picker is itself parented under MaterialApp's *current* theme,
/// not the theme being previewed — so widgets relying on
/// `AppTheme.flair` (e.g. [ThemedNumber]) would render with the active
/// flair, not the previewed one. To make previews accurate we paint a
/// scoped backdrop per theme for the inner widgets.
class _PreviewWrapper extends StatelessWidget {
  final AppThemeMode mode;
  final Widget child;
  const _PreviewWrapper({required this.mode, required this.child});

  @override
  Widget build(BuildContext context) {
    final f = AppTheme.flairFor(mode);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: f.card,
        borderRadius: BorderRadius.circular(f.cardRadius),
        border: Border.all(
          color: f.dividerColor ?? Colors.transparent,
          width: f.dividerThickness,
        ),
      ),
      child: child,
    );
  }
}

class _PreviewStatsRow extends StatelessWidget {
  final ThemeFlair flair;
  const _PreviewStatsRow({required this.flair});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _PreviewStat(label: 'DPS', value: '142', flair: flair),
        _PreviewStat(label: 'COOL', value: '5.0', flair: flair),
        _PreviewStat(label: 'CURSE', value: '3', flair: flair, curse: 3),
      ],
    );
  }
}

class _PreviewStat extends StatelessWidget {
  final String label;
  final String value;
  final ThemeFlair flair;
  final double curse;
  const _PreviewStat({
    required this.label,
    required this.value,
    required this.flair,
    this.curse = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Inline mini-renderer mirroring ThemedNumber but reading [flair]
    // directly (not AppTheme.notifier) so the preview always shows
    // its OWN theme even when not the active one.
    final isCurse = label == 'CURSE';
    final colour = flair.headlineStat;
    final size = 22.0 * flair.numberSizeScale;
    final style = TextStyle(
      fontSize: size,
      fontWeight: flair.numberWeight,
      fontStyle: flair.numberStyle,
      color: colour,
      shadows: flair.embossNumbers
          ? const [
              Shadow(
                offset: Offset(0, 1),
                color: Color(0x99000000),
              ),
              Shadow(
                offset: Offset(0, -0.5),
                color: Color(0x33FFFFFF),
              ),
            ]
          : null,
    );
    Widget number = Text(value, style: style);
    if (flair.glowCurse && isCurse && curse > 0) {
      final t = (curse / 8).clamp(0.15, 1.0);
      number = Stack(
        alignment: Alignment.center,
        children: [
          Text(
            value,
            style: style.copyWith(
              color: Colors.transparent,
              shadows: [
                Shadow(
                  color: const Color(0xFFFF4757).withValues(alpha: t),
                  blurRadius: 14,
                ),
              ],
            ),
          ),
          number,
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        number,
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.2,
            color: flair.secondary.withValues(alpha: 0.75),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PreviewChipsRow extends StatelessWidget {
  final ThemeFlair flair;
  const _PreviewChipsRow({required this.flair});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _previewChip('Passive', flair.primary, flair),
        _previewChip('Drum Clip', flair.secondary, flair),
        _previewChip('B-Quality', flair.headlineStat, flair),
      ],
    );
  }

  Widget _previewChip(String label, Color tint, ThemeFlair flair) {
    if (!flair.chipFilled) {
      // Minimalist: underlined plain label, no fill, no border.
      return Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: tint,
          decoration: TextDecoration.underline,
          decorationColor: tint.withValues(alpha: 0.6),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(flair.chipRadius),
        border: Border.all(color: tint.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: tint,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PreviewBullets extends StatelessWidget {
  final ThemeFlair flair;
  const _PreviewBullets({required this.flair});

  @override
  Widget build(BuildContext context) {
    final lines = const [
      'Loadout note',
      'Synergy hint',
      'Stat tweak',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text(
                  flair.bulletGlyph,
                  style: TextStyle(
                    fontSize: 14,
                    color: flair.bulletColor,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  lines[i],
                  style: TextStyle(
                    fontSize: 12,
                    color: flair.secondary.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Mini inventory row showing a gun tile + item tile with quality ring.
/// Mirrors how the actual inventory renders items so the preview is
/// representative of the in-game look.
class _PreviewInventoryRow extends StatelessWidget {
  final ThemeFlair flair;
  const _PreviewInventoryRow({required this.flair});

  // Quality colors A-D (standard S-A-B-C-D scale for preview).
  static const _ringColors = [
    Color(0xFFE0E0E0), // D
    Color(0xFF4CAF50), // C
    Color(0xFF2196F3), // B
    Color(0xFF9C27B0), // A
    Color(0xFFFFD700), // S (gold)
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Gun tile with gold S-ring
        Expanded(
          child: _previewTile(
            label: 'Marine Sidearm',
            qualityIndex: 4,
            icon: Icons.gps_fixed,
            flair: flair,
          ),
        ),
        const SizedBox(width: 10),
        // Item tile with purple A-ring
        Expanded(
          child: _previewTile(
            label: 'Armor of Thorns',
            qualityIndex: 3,
            icon: Icons.shield_outlined,
            flair: flair,
          ),
        ),
      ],
    );
  }

  Widget _previewTile({
    required String label,
    required int qualityIndex,
    required IconData icon,
    required ThemeFlair flair,
  }) {
    final ring = _ringColors[qualityIndex.clamp(0, 4)];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: flair.scaffold.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(flair.chipRadius - 2),
        border: Border.all(color: flair.dividerColor ?? Colors.transparent),
      ),
      child: Row(
        children: [
          // Quality ring with icon inside
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ring, width: 2.5),
            ),
            child: Icon(icon, size: 18, color: flair.headlineStat),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: flair.headlineStat,
                  ),
                ),
                const SizedBox(height: 2),
                _qualityPills(flair),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qualityPills(ThemeFlair flair) {
    final pills = ['D', 'C', 'B', 'A', 'S'];
    return Row(
      children: [
        for (var i = 0; i < pills.length; i++)
          Container(
            margin: const EdgeInsets.only(right: 3),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _ringColors[i].withValues(alpha: 0.25),
              border: Border.all(color: _ringColors[i], width: 1),
            ),
            child: Center(
              child: Text(
                pills[i],
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  color: _ringColors[i],
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ArcadeAttribute extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ArcadeAttribute({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: Colors.white54,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorCoreBox extends StatelessWidget {
  final Color color;
  final String label;

  const _ColorCoreBox({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24, width: 0.8),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 7.5,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 2, offset: Offset(0.5, 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
