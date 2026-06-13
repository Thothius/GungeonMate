import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/player.dart';
import '../providers/run_provider.dart';
import '../services/app_theme.dart';
import '../services/haptics.dart';
import 'theme_picker_screen.dart';

/// Bottom-sheet settings panel exposing theme selection.
/// Future settings (density, telemetry opt-out) can slot in here.
///
/// Show via:
/// ```
/// showModalBottomSheet(
///   context: context,
///   backgroundColor: const Color(0xFF1E1E1E),
///   shape: const RoundedRectangleBorder(
///     borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
///   ),
///   builder: (_) => const SettingsSheet(),
/// );
/// ```
class SettingsSheet extends StatefulWidget {
  /// Player slot the "Clear inventory" action targets. Defaults to main
  /// so the sheet is still safe to summon outside an active run.
  final PlayerSlot targetSlot;
  final bool isModal;
  final VoidCallback? onClearInventory;

  const SettingsSheet({
    super.key,
    this.targetSlot = PlayerSlot.main,
    this.isModal = false,
    this.onClearInventory,
  });

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late AppThemeMode _theme;

  @override
  void initState() {
    super.initState();
    _theme = AppTheme.mode;
  }

  Future<void> _openThemePicker() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ThemePickerScreen()),
    );
    if (!mounted) return;
    // Picker mutates AppTheme.mode in-place; reflect any change after
    // it pops so the row label updates without needing to reopen the
    // sheet.
    setState(() => _theme = AppTheme.mode);
  }

  Future<void> _confirmClearInventory() async {
    final p = context.read<RunProvider>();
    final state = p.runState;
    final player = widget.targetSlot == PlayerSlot.main
        ? state.main
        : state.coop;
    if (player == null || player.character == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("No active run to clear"),
        duration: Duration(milliseconds: 1200),
      ));
      return;
    }
    final name = player.character!.name;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
        title: Text("Clear $name's inventory?"),
        content: Text(
          'Removes all guns and items from $name except their starter '
          'loadout. Coolness, curse and shrine state are unchanged. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade900),
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    p.clearInventory(slot: widget.targetSlot);
    if (widget.isModal) {
      Navigator.pop(context);
    } else if (widget.onClearInventory != null) {
      widget.onClearInventory!();
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("$name's inventory cleared"),
      duration: const Duration(milliseconds: 1600),
    ));
  }

  Future<void> _confirmEndRun() async {
    final p = context.read<RunProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('End Run?'),
        content: const Text(
          'This resets the current run and returns to the main menu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('End Run'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    
    if (widget.isModal) {
      Navigator.pop(context);
    }
    
    p.endRun();
    Navigator.of(context).popUntil((route) => route.isFirst);
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Run ended successfully'),
      duration: Duration(milliseconds: 1400),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final player = widget.targetSlot == PlayerSlot.main
        ? p.runState.main
        : p.runState.coop;
    final hasActive = player != null && player.character != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isModal) ...[
              Row(
                children: [
                  const Icon(Icons.tune, size: 22, color: Colors.white70),
                  const SizedBox(width: 10),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            _VisualsDropdown(
              currentTheme: _theme,
              onTapTheme: _openThemePicker,
            ),
            const SizedBox(height: 18),
            const _SectionLabel(label: 'Run Tools'),
            const SizedBox(height: 6),
            _DangerTile(
              icon: Icons.delete_sweep_outlined,
              label: 'Clear inventory',
              subtitle: 'Strip all guns + items from this player',
              enabled: hasActive,
              onTap: _confirmClearInventory,
            ),
            const SizedBox(height: 10),
            _DangerTile(
              icon: Icons.cancel_outlined,
              label: 'End Run',
              subtitle: 'Reset active run and return to Main Menu',
              enabled: hasActive,
              onTap: _confirmEndRun,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;
  const _DangerTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? Colors.redAccent.shade100 : Colors.white24;
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Material(
        color: enabled ? Colors.red.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white38, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Visuals section widgets
// ---------------------------------------------------------------------------

class _VisualsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  const _VisualsRow({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.white54),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const Spacer(),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _GlowSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _GlowSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: value,
                min: 0,
                max: 1,
                divisions: 10,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '${(value * 100).round()}%',
              style: const TextStyle(fontSize: 12, color: Colors.white54),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightPicker extends StatelessWidget {
  final int bias;
  final ValueChanged<int> onChanged;
  const _WeightPicker({required this.bias, required this.onChanged});

  static const _labels = ['Thin', 'Normal', 'Bold'];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final bVal = i - 1; // -1, 0, +1
        final active = bias == bVal;
        return GestureDetector(
          onTap: () => onChanged(bVal),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: active
                  ? primary.withValues(alpha: 0.25)
                  : Colors.transparent,
              border: Border.all(
                color: active
                    ? primary.withValues(alpha: 0.7)
                    : Colors.white24,
                width: 1,
              ),
              borderRadius: BorderRadius.horizontal(
                left: i == 0 ? const Radius.circular(8) : Radius.zero,
                right: i == 2 ? const Radius.circular(8) : Radius.zero,
              ),
            ),
            child: Text(
              _labels[i],
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? primary : Colors.white54,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: Colors.white.withValues(alpha: 0.65),
        ),
      ),
    );
  }
}

/// Single tile that opens the swipeable [ThemePickerScreen]. Shows the
/// current theme's primary swatch, label and tagline so the user can
/// see what's active without launching the picker.
class _ThemeLauncherTile extends StatelessWidget {
  final AppThemeMode current;
  final VoidCallback onTap;
  const _ThemeLauncherTile({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final f = AppTheme.flairFor(current);
    return Material(
      color: f.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              // Two-tone swatch: primary + secondary side by side, hints
              // that themes carry more than a single accent.
              SizedBox(
                width: 36,
                height: 24,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 18,
                      child: Container(
                        decoration: BoxDecoration(
                          color: f.primary,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: 18,
                      child: Container(
                        decoration: BoxDecoration(
                          color: f.secondary,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: f.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      current.tagline,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.white54,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact "current font" chip in the settings row. Tapping opens a
/// modal sheet listing every [AppFont] with its name rendered in that
/// font so the user can pick by sight, not just by label.
class _FontPicker extends StatelessWidget {
  final AppFont current;
  final ValueChanged<AppFont> onChanged;
  const _FontPicker({required this.current, required this.onChanged});

  Future<void> _pick(BuildContext ctx) async {
    final picked = await showModalBottomSheet<AppFont>(
      context: ctx,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Choose font',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...AppFont.values.map((f) {
                  final active = f == current;
                  return Material(
                    color: active
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => Navigator.pop(sheetCtx, f),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              active
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              size: 18,
                              color: active
                                  ? Theme.of(ctx).colorScheme.primary
                                  : Colors.white38,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Render the label IN the font so the
                                  // user can preview at a glance.
                                  DefaultTextStyle.merge(
                                    style: f.textStyle.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    child: Text(f.label),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    f.description,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _pick(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              current.label,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.unfold_more, size: 14, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

class _VisualsDropdown extends StatefulWidget {
  final AppThemeMode currentTheme;
  final VoidCallback onTapTheme;

  const _VisualsDropdown({required this.currentTheme, required this.onTapTheme});

  @override
  State<_VisualsDropdown> createState() => _VisualsDropdownState();
}

class _VisualsDropdownState extends State<_VisualsDropdown> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final f = AppTheme.flair;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.tune_rounded, color: f.primary),
            title: const Text(
              'Visuals & Theme',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            trailing: Icon(
              _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: Colors.white54,
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded) ...[
            const Divider(color: Colors.white10, height: 1, thickness: 0.8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: ValueListenableBuilder<VisualPrefs>(
                valueListenable: VisualPrefs.notifier,
                builder: (_, prefs, __) => Column(
                  children: [
                    // Theme Row under it as first option
                    _VisualsRow(
                      icon: Icons.palette_outlined,
                      label: 'Theme',
                      trailing: InkWell(
                        onTap: widget.onTapTheme,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: f.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: f.primary.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            widget.currentTheme.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: f.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Font Row
                    _VisualsRow(
                      icon: Icons.font_download_outlined,
                      label: 'App Font',
                      trailing: _FontPicker(
                        current: prefs.font,
                        onChanged: VisualPrefs.setFont,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Font Weight Row
                    _VisualsRow(
                      icon: Icons.format_bold_outlined,
                      label: 'Font Weight',
                      trailing: _WeightPicker(
                        bias: prefs.fontWeightBias,
                        onChanged: VisualPrefs.setFontWeightBias,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Font Size Row
                    _VisualsRow(
                      icon: Icons.format_size_rounded,
                      label: 'Font Size',
                      trailing: SizedBox(
                        height: 32,
                        width: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: VisualPrefs.fontSizeSteps.length,
                          itemBuilder: (context, idx) {
                            final size = VisualPrefs.fontSizeSteps[idx];
                            final isSel = size == prefs.fontSize;
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: ChoiceChip(
                                label: Text(
                                  '${size.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: isSel ? Colors.black : Colors.white70,
                                  ),
                                ),
                                selected: isSel,
                                onSelected: (val) {
                                  if (val) {
                                    VisualPrefs.setFontSize(size);
                                    Haptics.selection();
                                  }
                                },
                                selectedColor: Theme.of(context).colorScheme.primary,
                                backgroundColor: Colors.white.withValues(alpha: 0.05),
                                showCheckmark: false,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Bg Glow Row
                    _VisualsRow(
                      icon: Icons.blur_on_outlined,
                      label: 'Bg Glow',
                      trailing: _GlowSlider(
                        value: prefs.glowIntensity,
                        onChanged: VisualPrefs.setGlow,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Particles Row
                    _VisualsRow(
                      icon: Icons.auto_awesome_outlined,
                      label: 'Particles',
                      trailing: Switch(
                        value: prefs.particlesEnabled,
                        onChanged: VisualPrefs.setParticles,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    if (prefs.particlesEnabled) ...[
                      const SizedBox(height: 10),
                      _VisualsRow(
                        icon: Icons.sync,
                        label: 'Particle Rotation',
                        trailing: Switch(
                          value: prefs.particleRotation,
                          onChanged: VisualPrefs.setParticleRotation,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _VisualsRow(
                        icon: Icons.filter_tilt_shift_outlined,
                        label: 'Void Gravity Vortex',
                        trailing: Switch(
                          value: prefs.gravityVortex,
                          onChanged: VisualPrefs.setGravityVortex,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _VisualsRow(
                        icon: Icons.local_fire_department_outlined,
                        label: 'Advanced Flicker',
                        trailing: Switch(
                          value: prefs.advancedFlicker,
                          onChanged: VisualPrefs.setAdvancedFlicker,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

}
