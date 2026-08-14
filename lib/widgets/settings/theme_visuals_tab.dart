import 'package:flutter/material.dart';
import '../../services/app_theme.dart';
import '../../services/haptics.dart';
import '../../services/goop_talk_engine.dart';
import '../../screens/theme_picker_screen.dart';
import '../../utils/fast_route.dart';
import '../../utils/responsive.dart';
import 'swipe_picker.dart';

enum _VisualCategory { font, glow, inventory }

class AppearanceTab extends StatefulWidget {
  const AppearanceTab({super.key});

  @override
  State<AppearanceTab> createState() => AppearanceTabState();
}

class AppearanceTabState extends State<AppearanceTab> {
  _VisualCategory _selectedCategory = _VisualCategory.font;

  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    final btnHeight = 56 * sf;
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
              // Active Theme Premium Dashboard Card — extra prominent
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      flair.scaffold.withValues(alpha: 0.95),
                      flair.card.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: flair.primary.withValues(alpha: 0.4),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: flair.primary.withValues(alpha: 0.12),
                      blurRadius: 16,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Pulsing colored palette icon with active primary glow!
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: flair.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: flair.primary.withValues(alpha: 0.5), width: 2.0),
                          ),
                          child: Icon(Icons.palette_rounded, size: 32, color: flair.secondary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const GoopText(
                                'ACTIVE PALETTE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white38,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              GoopText(
                                activeTheme.label.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 20 * sf,
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
                            const SizedBox(width: 5),
                            _colorBead(flair.secondary),
                            const SizedBox(width: 5),
                            _colorBead(flair.headlineStat),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Choose Theme Action Button — 2x height
                    SizedBox(
                      width: double.infinity,
                      height: btnHeight,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.tune_rounded, size: 20),
                        label: const GoopText(
                          'CHOOSE THEME PALETTE',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: flair.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
              _buildCategoryChips(flair),
              const SizedBox(height: 16),

              // =============================================================
              // Typography Tuning Section (collapsible)
              // =============================================================
              _collapsibleSectionHeader(
                'APP TYPOGRAPHY TUNING',
                flair,
                _selectedCategory == _VisualCategory.font,
                () => setState(() => _selectedCategory = _VisualCategory.font),
              ),
              if (_selectedCategory == _VisualCategory.font) ...[
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
                                    fontSize: 16 * sf,
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

                      // Inventory Font Size — moved here from Inventory section
                      // so both font size controls live together.
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
              // Screen Glow Section (collapsible, collapsed by default)
              // =============================================================
              _collapsibleSectionHeader(
                'SCREEN GLOW',
                flair,
                _selectedCategory == _VisualCategory.glow,
                () => setState(() => _selectedCategory = _VisualCategory.glow),
              ),
              if (_selectedCategory == _VisualCategory.glow) ...[
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
              ], // end glow section

              // =============================================================
              // Inventory Layout Section (collapsible)
              // =============================================================
              _collapsibleSectionHeader(
                'INVENTORY LAYOUT',
                flair,
                _selectedCategory == _VisualCategory.inventory,
                () => setState(() => _selectedCategory = _VisualCategory.inventory),
              ),
              if (_selectedCategory == _VisualCategory.inventory) ...[
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
                          height: btnHeight,
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
                          height: btnHeight,
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChips(ThemeFlair flair) {
    final categories = [
      (_VisualCategory.font, 'FONT', Icons.font_download_rounded),
      (_VisualCategory.glow, 'GLOW', Icons.wb_sunny_rounded),
      (_VisualCategory.inventory, 'INVENTORY', Icons.grid_view_rounded),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((c) {
        final selected = _selectedCategory == c.$1;
        return ChoiceChip(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(c.$3, size: 14, color: selected ? Colors.black : Colors.white70),
              const SizedBox(width: 6),
              GoopText(
                c.$2,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.black : Colors.white70,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          selected: selected,
          selectedColor: flair.primary,
          backgroundColor: flair.card.withValues(alpha: 0.6),
          side: BorderSide(
            color: selected ? flair.primary : Colors.white.withValues(alpha: 0.08),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onSelected: (_) {
            Haptics.selection();
            setState(() => _selectedCategory = c.$1);
          },
        );
      }).toList(),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: flair.card.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: expanded
                ? flair.primary.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.08),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              size: 18,
              color: expanded ? flair.primary : Colors.white.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 10),
            GoopText(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: expanded ? Colors.white70 : Colors.white38,
                letterSpacing: 0.6,
              ),
            ),
            const Spacer(),
            if (expanded)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: flair.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: flair.primary.withValues(alpha: 0.4), blurRadius: 4),
                  ],
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
                color: AppTheme.flair.card,
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
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6,
            spreadRadius: 1,
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