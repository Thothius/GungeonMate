import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/player.dart';
import '../../services/app_theme.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/haptics.dart';
import '../../theme/tokens.dart';
import '../../utils/responsive.dart';
import '../scale_button.dart';

/// A pinnable capsule on the active-run header. COOL and CURSE are
/// always shown; up to [kMaxDashCapsules] of these can be pinned via
/// the "+" capsule picker. Persisted per player slot.
enum DashCapsule { steal, useShrine, syn, dps }

const int kMaxDashCapsules = 3;

/// Display spec for one capsule kind — label, icon, accent color, and
/// the short subtitle shown in the picker.
extension DashCapsuleSpec on DashCapsule {
  String get label => switch (this) {
    DashCapsule.steal => 'STEAL',
    DashCapsule.useShrine => 'SHRINE',
    DashCapsule.syn => 'SYN',
    DashCapsule.dps => 'DPS',
  };

  IconData get icon => switch (this) {
    DashCapsule.steal => Icons.front_hand,
    DashCapsule.useShrine => Icons.temple_buddhist_outlined,
    DashCapsule.syn => Icons.hub_outlined,
    DashCapsule.dps => Icons.bolt_outlined,
  };

  Color get color => switch (this) {
    // STEAL feeds CURSE directly, so it wears the curse hue.
    DashCapsule.steal => StatColors.curse,
    DashCapsule.useShrine => const Color(0xFFBA68C8),
    DashCapsule.syn => const Color(0xFFFFD740),
    DashCapsule.dps => const Color(0xFF69F0AE),
  };

  /// Full name shown on the picker row — the capsule itself stays short.
  String get pickerTitle => switch (this) {
    DashCapsule.steal => 'STEAL',
    DashCapsule.useShrine => 'USE SHRINE',
    DashCapsule.syn => 'SYNERGIES',
    DashCapsule.dps => 'DAMAGE BREAKDOWN',
  };

  String get blurb => switch (this) {
    DashCapsule.steal => 'Log a shop steal (+1 curse)',
    DashCapsule.useShrine => 'Pick and use a shrine',
    DashCapsule.syn => 'Synergies overview',
    DashCapsule.dps => 'Damage breakdown overview',
  };

  bool get isAction => this == DashCapsule.steal || this == DashCapsule.useShrine;
}

String _prefsKey(PlayerSlot slot) => 'dash.capsules.${slot.name}';

/// Loads the pinned capsules for [slot]. Unknown/duplicate ids and
/// anything beyond [kMaxDashCapsules] are dropped — the stored string
/// is comma-joined enum names.
Future<List<DashCapsule>> loadDashCapsules(PlayerSlot slot) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey(slot)) ?? '';
    final out = <DashCapsule>[];
    for (final part in raw.split(',')) {
      final c = DashCapsule.values.asNameMap()[part];
      if (c != null && !out.contains(c)) out.add(c);
      if (out.length >= kMaxDashCapsules) break;
    }
    return out;
  } catch (_) {
    return const <DashCapsule>[];
  }
}

Future<void> saveDashCapsules(
  PlayerSlot slot,
  List<DashCapsule> capsules,
) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey(slot),
      capsules.take(kMaxDashCapsules).map((c) => c.name).join(','),
    );
  } catch (_) {
    // Persistence failure is non-fatal — pins stay in memory.
  }
}

/// Capsule picker bottom sheet. Keeps a local copy of [pinned] so
/// toggles accumulate correctly within one open (the parent's
/// setState does not rebuild an already-presented modal route);
/// [onChanged] receives each new list so the parent can persist.
/// Tapping a pinned capsule unpins it; tapping an unpinned one pins
/// it unless [kMaxDashCapsules] is reached.
Future<void> showDashCapsulePicker({
  required BuildContext context,
  required List<DashCapsule> pinned,
  required ValueChanged<List<DashCapsule>> onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final f = AppTheme.flair;
      final current = List<DashCapsule>.of(pinned);
      return StatefulBuilder(
        builder: (stContext, setST) {
          void toggle(DashCapsule c) {
            Haptics.selection();
            if (current.contains(c)) {
              current.remove(c);
            } else {
              if (current.length >= kMaxDashCapsules) {
                ScaffoldMessenger.of(stContext).showSnackBar(
                  const SnackBar(
                    content: GoopText('Max 3 capsules'),
                  ),
                );
                return;
              }
              current.add(c);
            }
            onChanged(List<DashCapsule>.of(current));
            setST(() {});
          }

          Widget row(DashCapsule c) {
            final isPinned = current.contains(c);
            final color = c.color;
            return ScaleButton(
              onTap: () => toggle(c),
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 3,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      isPinned
                          ? color.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        isPinned
                            ? color.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      c.icon,
                      color: isPinned ? color : Colors.white38,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GoopText(
                            c.pickerTitle,
                            style: TextStyle(
                              fontSize:
                                  FontSizes.bodyMedium *
                                  Responsive.factor(stContext),
                              fontWeight: FontWeight.w900,
                              color: isPinned ? Colors.white : Colors.white70,
                              letterSpacing: 0.5,
                            ),
                          ),
                          GoopText(
                            c.blurb,
                            style: TextStyle(
                              fontSize:
                                  FontSizes.labelSmall *
                                  Responsive.factor(stContext),
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isPinned
                          ? Icons.check_circle
                          : Icons.add_circle_outline,
                      color: isPinned ? color : Colors.white24,
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          }

          Widget group(String title, List<DashCapsule> items) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: GoopText(
                    title,
                    style: TextStyle(
                      fontSize: FontSizes.labelSmall,
                      fontWeight: FontWeight.w900,
                      color: f.primary.withValues(alpha: 0.8),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                ...items.map(row),
              ],
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: f.card,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              border: Border.all(
                color: f.primary.withValues(alpha: 0.25),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: GoopText(
                              'DASH CAPSULES',
                              style: TextStyle(
                                fontSize: FontSizes.bodyMedium,
                                fontWeight: FontWeight.w900,
                                color: f.headlineStat,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.of(stContext).pop(),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GoopText(
                      '${current.length}/$kMaxDashCapsules pinned',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    ),
                    const SizedBox(height: 6),
                    group('ACTIONS', [
                      DashCapsule.steal,
                      DashCapsule.useShrine,
                    ]),
                    group('INFO', [DashCapsule.syn, DashCapsule.dps]),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
