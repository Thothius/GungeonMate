import '../utils/asset_paths.dart';

class Shrine {
  final String name;
  final String description;
  final String message;
  final String effect;
  final String icon;
  final double curse;
  final double coolness;

  Shrine({
    required this.name,
    this.description = '',
    this.message = '',
    this.effect = '',
    this.icon = '',
    this.curse = 0.0,
    this.coolness = 0.0,
  });

  /// True if using the shrine produces any automatic stat change
  /// (curse/coolness delta, or one of the named special-cases).
  bool get hasAutoEffect {
    if (curse != 0 || coolness != 0) return true;
    final n = name.toLowerCase();
    return n == 'cleanse' || n == 'hero';
  }

  factory Shrine.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    return Shrine(
      name: name,
      icon: localShrineIcon(name),
      message: json['message'] ?? '',
      effect: json['effect'] ?? '',
      curse: (json['curse'] ?? 0).toDouble(),
      coolness: (json['coolness'] ?? 0).toDouble(),
    );
  }
}

/// Return value of `RunProvider.applyShrine`. Captures what happened
/// so the UI can render a rich confirmation sheet / snackbar.
class ShrineApplyResult {
  final Shrine shrine;

  /// Auto-applied adjustments, human-readable. e.g. `"Curse +3.5"`.
  final List<String> applied;

  /// Things the player must handle themselves (heart loss, loot pickup).
  final List<String> manual;

  const ShrineApplyResult({
    required this.shrine,
    this.applied = const [],
    this.manual = const [],
  });

  bool get didAnything => applied.isNotEmpty;
}
