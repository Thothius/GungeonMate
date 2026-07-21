/// A single event in the run log — tracks pickups, stat changes, shrines,
/// and manual actions like stealing or smoking cigarettes.
class RunLogEntry {
  final DateTime timestamp;
  final RunLogCategory category;
  final String description;
  final double curseDelta;
  final double coolnessDelta;
  final String? entityName;

  RunLogEntry({
    required this.timestamp,
    required this.category,
    required this.description,
    this.curseDelta = 0,
    this.coolnessDelta = 0,
    this.entityName,
  });

  bool get affectsCurse => curseDelta.abs() > 0.001;
  bool get affectsCoolness => coolnessDelta.abs() > 0.001;

  factory RunLogEntry.fromJson(Map<String, dynamic> j) {
    return RunLogEntry(
      timestamp: DateTime.tryParse(j['t'] as String? ?? '') ?? DateTime.now(),
      category: RunLogCategory.values.firstWhere(
        (c) => c.name == j['c'],
        orElse: () => RunLogCategory.manual,
      ),
      description: j['d'] as String? ?? '',
      curseDelta: (j['cu'] as num?)?.toDouble() ?? 0,
      coolnessDelta: (j['co'] as num?)?.toDouble() ?? 0,
      entityName: j['e'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        't': timestamp.toIso8601String(),
        'c': category.name,
        'd': description,
        if (curseDelta != 0) 'cu': curseDelta,
        if (coolnessDelta != 0) 'co': coolnessDelta,
        if (entityName != null) 'e': entityName,
      };
}

enum RunLogCategory {
  pickupGun,
  pickupItem,
  removeGun,
  removeItem,
  shrine,
  steal,
  cursula,
  smokeCig,
  rainbowRun,
  manual,
}
