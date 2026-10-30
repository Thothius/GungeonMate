import '../theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../models/run_log_entry.dart';
import '../services/haptics.dart';
import '../services/goop_talk_engine.dart';
import '../widgets/active_run/gungeon_meter.dart';
part 'stats_detail/effects.dart';
part 'stats_detail/log.dart';
part 'stats_detail/rows.dart';

enum StatType { coolness, curse }

class StatsDetailScreen extends StatelessWidget {
  final StatType statType;
  const StatsDetailScreen({super.key, required this.statType});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final isCool = statType == StatType.coolness;
    final total = isCool ? p.runState.totalCoolness : p.runState.totalCurse;
    final base = isCool ? p.runState.coolness : p.runState.curse;
    final fromItems = total - base;
    final title = isCool ? 'Coolness' : 'Curse';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: GoopText(title),
        actions: [
          if (base != 0)
            IconButton(
              tooltip: 'Reset manual adjustments',
              icon: const Icon(Icons.restart_alt),
              onPressed: () => p.resetManualStats(),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            _ValueCard(
              isCool: isCool,
              value: total,
              base: base,
              fromItems: fromItems,
              isTeam: p.runState.hasCoop,
              onDelta: (delta) {
                if (isCool) {
                  p.adjustCoolness(delta);
                } else {
                  p.adjustCurse(delta);
                }
              },
            ),
            const SizedBox(height: 16),
            // Live effects — most relevant, right under the value card
            if (isCool)
              _CoolnessEffects(coolness: total, curse: p.runState.totalCurse)
            else
              _CurseEffects(curse: total, coolness: p.runState.totalCoolness),
            const SizedBox(height: 16),
            _QuickActions(isCool: isCool),
            const SizedBox(height: 16),
            // Event log — collapsed by default
            _EventLog(isCool: isCool),
          ],
        ),
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  final bool isCool;
  final double value;
  final double base;
  final double fromItems;
  final bool isTeam;
  final void Function(double) onDelta;

  const _ValueCard({
    required this.isCool,
    required this.value,
    required this.base,
    required this.fromItems,
    required this.onDelta,
    this.isTeam = false,
  });

  String _fmt(double v) {
    final sign = v > 0 ? '+' : '';
    return '$sign${v.toStringAsFixed(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final color = isCool ? const Color(0xFF00E5FF) : const Color(0xFFFF3D00);
    final hasBreakdown = base != 0 || fromItems != 0;

    // Mathematical calculations for the visual meters
    final double maxSlider = 15.0;
    final double minSlider = 0.0;
    final double clampedVal = value.clamp(minSlider, maxSlider);

    // Active item reduction percent (max 50%) or Lord of the Jammed Threat percentage
    final meterLabel =
        isCool
            ? 'Active Cooldown Speedup: +${(value * 5).clamp(0, 50).toStringAsFixed(1)}%'
            : 'Bullet Hell Threat Level: ${(value * 10).clamp(0, 100).toStringAsFixed(1)}%';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radii.lg),
        side: BorderSide(color: color.withValues(alpha: 0.25), width: 1.2),
      ),
      child: Column(
        children: [
          // Main Value readout & Visual Indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: Column(
              children: [
                Icon(
                  isCool
                      ? Icons.ac_unit_rounded
                      : Icons.local_fire_department_rounded,
                  size: 48,
                  color: color,
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: GoopText(
                    value.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: color,
                      height: 1.0,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                if (hasBreakdown) ...[
                  GoopText(
                    isTeam
                        ? 'Base ${_fmt(base)}  ·  From Team ${_fmt(fromItems)}'
                        : 'Base ${_fmt(base)}  ·  From Items ${_fmt(fromItems)}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.65),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Live Tactile Interactive Slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: color,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                    thumbColor: Colors.white,
                    overlayColor: color.withValues(alpha: 0.2),
                    valueIndicatorColor: color,
                    valueIndicatorTextStyle: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  child: Slider(
                    value: clampedVal,
                    min: minSlider,
                    max: maxSlider,
                    divisions: 30, // steps of 0.5
                    label: value.toStringAsFixed(1),
                    onChanged: (newVal) {
                      final delta = newVal - value;
                      if (delta.abs() > 0.01) {
                        onDelta(delta);
                      }
                    },
                  ),
                ),
                // Slider scale labels
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '0.0',
                        style: TextStyle(
                          fontSize: FontSizes.labelSmall,
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '5.0',
                        style: TextStyle(
                          fontSize: FontSizes.labelSmall,
                          color: Colors.white30,
                        ),
                      ),
                      Text(
                        '10.0',
                        style: TextStyle(
                          fontSize: FontSizes.labelSmall,
                          color: Colors.white30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GoopText(
                        '15.0+',
                        style: TextStyle(
                          fontSize: FontSizes.labelSmall,
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Incremental presets (oiled quick buttons in a single spacious mobile-friendly row)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _btn('-1.0', () => onDelta(-1), Colors.redAccent, isCool),
                _btn('-0.5', () => onDelta(-0.5), Colors.redAccent, isCool),
                _btn('+0.5', () => onDelta(0.5), color, isCool),
                _btn('+1.0', () => onDelta(1), color, isCool),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Live Interactive Gungeon Meter
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Insets.md),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(15),
              ),
            ),
            child: GungeonMeter(
              value: value.clamp(0.0, 15.0),
              isCool: isCool,
              color: color,
              label: meterLabel,
              onDelta: onDelta,
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(String label, VoidCallback cb, Color btnColor, bool isCoolMode) {
    final isMinus = label.startsWith('-');
    final showWarningColor =
        !isCoolMode && !isMinus; // Curse addition highlights orange-red
    final activeColor = showWarningColor ? Colors.deepOrange : btnColor;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.5),
        child: SizedBox(
          height: 38,
          child: FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor:
                  isMinus
                      ? Colors.red.withValues(alpha: 0.12)
                      : activeColor.withValues(alpha: 0.12),
              foregroundColor: isMinus ? Colors.redAccent : activeColor,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radii.sm),
                side: BorderSide(
                  color:
                      isMinus
                          ? Colors.red.withValues(alpha: 0.15)
                          : activeColor.withValues(alpha: 0.15),
                  width: 0.8,
                ),
              ),
            ),
            onPressed: cb,
            child: GoopText(
              label,
              style: const TextStyle(
                fontSize: FontSizes.labelMedium,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------- Coolness effects -------------------------------------

// ---------------------- Curse effects + table --------------------------------

// ---------------------- Shared UI bits ---------------------------------------

// ---------------------- Quick action buttons ---------------------------------

// ---------------------- Event log feed ---------------------------------------
