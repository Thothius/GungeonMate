import 'package:flutter/material.dart';
import '../../services/app_theme.dart';
import '../../services/haptics.dart';
import '../../services/goop_talk_engine.dart';
import '../../screens/shrine_picker_screen.dart';
import '../../utils/fast_route.dart';
import 'run_log_screen.dart';
import 'swipe_picker.dart';

/// Gameplay settings tab — dialogue, dice style, shrines, event log.
/// Part of the 3-tab settings reorganization (Appearance / Gameplay / App).
class GameplayTab extends StatefulWidget {
  const GameplayTab({super.key});

  @override
  State<GameplayTab> createState() => _GameplayTabState();
}

class _GameplayTabState extends State<GameplayTab> {
  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;

    return ListenableBuilder(
      listenable: VisualPrefs.notifier,
      builder: (context, _) {
        final prefs = VisualPrefs.notifier.value;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Dialogue card ──
              _groupLabel('DIALOGUE'),
              _buildDialogueCard(flair, prefs),
              const SizedBox(height: 16),

              // ── Dice style ──
              _groupLabel('DICE STYLE'),
              _buildDicePanel(flair, prefs),
              const SizedBox(height: 16),

              // ── Quick actions grid ──
              _groupLabel('QUICK ACTIONS'),
              _buildGrid([
                _TileData(
                  icon: Icons.temple_buddhist,
                  label: 'Use Shrine',
                  color: Colors.amber,
                  onTap: () => Navigator.push(
                    context,
                    fastRoute(const ShrinePickerScreen()),
                  ),
                ),
                _TileData(
                  icon: Icons.history_edu_rounded,
                  label: 'Event Log',
                  color: const Color(0xFFFFD740),
                  onTap: () => Navigator.push(
                    context,
                    fastRoute(const RunLogScreen()),
                  ),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────

  Widget _groupLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: GoopText(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: AppTheme.flair.primary.withValues(alpha: 0.8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildGrid(List<_TileData> tiles) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: tiles.map((t) => _CompactActionTile(data: t)).toList(),
    );
  }

  Widget _buildDialogueCard(ThemeFlair flair, VisualPrefs prefs) {
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
              icon: Icons.vibration_rounded,
              label: 'Dialogue Haptics',
              value: prefs.dialogueHapticsEnabled,
              onChanged: VisualPrefs.setDialogueHapticsEnabled,
              flair: flair,
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

  Widget _buildDicePanel(ThemeFlair flair, VisualPrefs prefs) {
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
            SwipePicker<CustomDiceType>(
              items: CustomDiceType.values,
              value: prefs.customDiceType,
              onChanged: (t) => VisualPrefs.setCustomDiceType(t),
              height: 56,
              itemBuilder: (type, isSelected) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : Colors.white54,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(child: _dicePreview(type: prefs.customDiceType, flair: flair)),
          ],
        ),
      ),
    );
  }

  Widget _dicePreview({required CustomDiceType type, required ThemeFlair flair, int value = 5}) {
    final colors = _diceColors(type, flair);
    return Container(
      width: 120,
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.$2, width: 3),
        boxShadow: [BoxShadow(color: colors.$4, blurRadius: 12, spreadRadius: 3)],
      ),
      child: Text(
        '$value',
        style: TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.w900,
          color: colors.$3,
        ),
      ),
    );
  }

  (Color, Color, Color, Color) _diceColors(CustomDiceType type, ThemeFlair flair) {
    switch (type) {
      case CustomDiceType.classicWhite:
        return (const Color(0xFFFAFAFA), const Color(0xFF90A4AE), const Color(0xFF263238), Colors.white24);
      case CustomDiceType.goldGlimmer:
        return (const Color(0xFF2C2210), const Color(0xFFFFD54F), const Color(0xFFFFD54F), const Color(0x33FFD54F));
      case CustomDiceType.frostShard:
        return (const Color(0xFF101C2C), const Color(0xFF00E5FF), const Color(0xFF00E5FF), const Color(0x3300E5FF));
      case CustomDiceType.moltenAmber:
        return (const Color(0xFF2C1010), const Color(0xFFFF3D00), const Color(0xFFFF3D00), const Color(0x33FF3D00));
      case CustomDiceType.voidPurple:
        return (const Color(0xFF1F102C), const Color(0xFFD500F9), const Color(0xFFD500F9), const Color(0x33D500F9));
      case CustomDiceType.toxicOoze:
        return (const Color(0xFF102C13), const Color(0xFF00E676), const Color(0xFF00E676), const Color(0x3300E676));
      case CustomDiceType.themeDefault:
        return (const Color(0xFF161413), flair.primary, flair.primary, flair.primary.withValues(alpha: 0.3));
    }
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ThemeFlair flair,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: flair.card.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: flair.primary.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white60),
          const SizedBox(width: 12),
          Expanded(
            child: GoopText(
              label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.8),
                  letterSpacing: 0.3),
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
            GoopText(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.8))),
            GoopText(displayValue,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
        SizedBox(
          height: 36,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 4.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
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

/// Data model for a compact grid action tile.
class _TileData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TileData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

/// Compact icon+label action tile for the 2-column settings grid.
class _CompactActionTile extends StatelessWidget {
  final _TileData data;
  const _CompactActionTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    return Material(
      color: flair.card.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: data.color.withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(data.icon, size: 20, color: data.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GoopText(
                  data.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
