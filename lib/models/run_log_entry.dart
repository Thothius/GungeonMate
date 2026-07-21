import 'package:flutter/material.dart';

/// A single event in the run log — tracks pickups, stat changes, shrines,
/// transfers, synergies, and manual actions like stealing or smoking cigarettes.
class RunLogEntry {
  final DateTime timestamp;
  final RunLogCategory category;
  final String description;
  final double curseDelta;
  final double coolnessDelta;
  final String? entityName;
  final String? playerName;

  RunLogEntry({
    required this.timestamp,
    required this.category,
    required this.description,
    this.curseDelta = 0,
    this.coolnessDelta = 0,
    this.entityName,
    this.playerName,
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
      playerName: j['p'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        't': timestamp.toIso8601String(),
        'c': category.name,
        'd': description,
        if (curseDelta != 0) 'cu': curseDelta,
        if (coolnessDelta != 0) 'co': coolnessDelta,
        if (entityName != null) 'e': entityName,
        if (playerName != null) 'p': playerName,
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
  synergy,
  transfer,
  manual,
}

/// Category → color mapping for consistent visual coding across the log UI.
Color runLogCategoryColor(RunLogCategory cat) {
  switch (cat) {
    case RunLogCategory.pickupGun:
      return const Color(0xFFFFB300); // Amber — gun pickups
    case RunLogCategory.pickupItem:
      return const Color(0xFF00E676); // Green — item pickups
    case RunLogCategory.removeGun:
      return const Color(0xFFEF5350); // Red — gun removals
    case RunLogCategory.removeItem:
      return const Color(0xFFEF5350); // Red — item removals
    case RunLogCategory.shrine:
      return const Color(0xFFAB47BC); // Purple — shrine activations
    case RunLogCategory.steal:
      return const Color(0xFFEC407A); // Pink — stealing
    case RunLogCategory.cursula:
      return const Color(0xFFFF6E40); // Deep orange — Cursula visits
    case RunLogCategory.smokeCig:
      return const Color(0xFF00E5FF); // Cyan — coolness actions
    case RunLogCategory.rainbowRun:
      return const Color(0xFFB388FF); // Light purple — rainbow run
    case RunLogCategory.synergy:
      return const Color(0xFFFFD740); // Gold — synergy activation
    case RunLogCategory.transfer:
      return const Color(0xFF40C4FF); // Light blue — co-op transfers
    case RunLogCategory.manual:
      return const Color(0xFFB0BEC5); // Blue-grey — manual adjustments
  }
}

/// Short human-readable label for each category (used in the legend).
String runLogCategoryLabel(RunLogCategory cat) {
  switch (cat) {
    case RunLogCategory.pickupGun:
      return 'Gun Pickup';
    case RunLogCategory.pickupItem:
      return 'Item Pickup';
    case RunLogCategory.removeGun:
      return 'Gun Removed';
    case RunLogCategory.removeItem:
      return 'Item Removed';
    case RunLogCategory.shrine:
      return 'Shrine';
    case RunLogCategory.steal:
      return 'Steal';
    case RunLogCategory.cursula:
      return 'Cursula';
    case RunLogCategory.smokeCig:
      return 'Smoke Cig';
    case RunLogCategory.rainbowRun:
      return 'Rainbow Run';
    case RunLogCategory.synergy:
      return 'Synergy';
    case RunLogCategory.transfer:
      return 'Transfer';
    case RunLogCategory.manual:
      return 'Manual';
  }
}

/// Icon for each category.
IconData runLogCategoryIcon(RunLogCategory cat) {
  switch (cat) {
    case RunLogCategory.pickupGun:
      return Icons.gps_fixed;
    case RunLogCategory.pickupItem:
      return Icons.inventory_2_outlined;
    case RunLogCategory.removeGun:
      return Icons.remove_circle_outline;
    case RunLogCategory.removeItem:
      return Icons.remove_circle_outline;
    case RunLogCategory.shrine:
      return Icons.temple_buddhist_outlined;
    case RunLogCategory.steal:
      return Icons.front_hand;
    case RunLogCategory.cursula:
      return Icons.local_fire_department;
    case RunLogCategory.smokeCig:
      return Icons.smoking_rooms;
    case RunLogCategory.rainbowRun:
      return Icons.palette;
    case RunLogCategory.synergy:
      return Icons.auto_awesome;
    case RunLogCategory.transfer:
      return Icons.swap_horiz;
    case RunLogCategory.manual:
      return Icons.tune;
  }
}
