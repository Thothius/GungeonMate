import 'package:flutter/material.dart';

/// Single source of truth for the six surprise presets.
///
/// The sender sheet needs (key, picker label, icon); the receiver card
/// needs (card title, icon, color, fx). They used to be two separate
/// lists that could silently drift — this record carries both views so
/// a preset can never exist on one side only (S4.5).
class SurprisePreset {
  /// Wire value sent in `MpSurprise.preset`.
  final String key;

  /// Short label on the sender picker tile.
  final String pickerLabel;

  /// Big text shown on the receiver's card.
  final String cardTitle;

  final IconData icon;
  final Color color;

  /// Fullscreen effect on the receiver ('hearts', 'shake', 'flash',
  /// 'jumpscare', 'pulse', 'scatter').
  final String fx;

  const SurprisePreset({
    required this.key,
    required this.pickerLabel,
    required this.cardTitle,
    required this.icon,
    required this.color,
    required this.fx,
  });
}

const surprisePresets = <SurprisePreset>[
  SurprisePreset(
    key: 'love',
    pickerLabel: 'LOVE',
    cardTitle: 'I LOVE YOU',
    icon: Icons.favorite_rounded,
    color: Color(0xFFFF6B81),
    fx: 'hearts',
  ),
  SurprisePreset(
    key: 'slap',
    pickerLabel: 'SLAP',
    cardTitle: '*SLAP*',
    icon: Icons.back_hand_rounded,
    color: Color(0xFFFF7043),
    fx: 'shake',
  ),
  SurprisePreset(
    key: 'blank',
    pickerLabel: 'BLANK',
    cardTitle: 'BLANK!',
    icon: Icons.brightness_7_rounded,
    color: Color(0xFFFFFFFF),
    fx: 'flash',
  ),
  SurprisePreset(
    key: 'mimic',
    pickerLabel: 'MIMIC',
    cardTitle: 'MIMIC!',
    icon: Icons.warning_amber_rounded,
    color: Color(0xFF8D6E63),
    fx: 'jumpscare',
  ),
  SurprisePreset(
    key: 'heal',
    pickerLabel: 'HEAL',
    cardTitle: 'GET WELL',
    icon: Icons.healing_rounded,
    color: Color(0xFF66BB6A),
    fx: 'pulse',
  ),
  SurprisePreset(
    key: 'gungeon',
    pickerLabel: 'GUNGEON',
    cardTitle: 'GUNGEON!',
    icon: Icons.gps_fixed_rounded,
    color: Color(0xFFB388FF),
    fx: 'scatter',
  ),
];

/// Lookup by wire key — null for 'custom' or unknown presets.
SurprisePreset? surprisePresetByKey(String key) {
  for (final p in surprisePresets) {
    if (p.key == key) return p;
  }
  return null;
}
