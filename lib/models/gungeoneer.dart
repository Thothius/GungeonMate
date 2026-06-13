import '../utils/asset_paths.dart';

class Gungeoneer {
  final String name;
  final String icon;
  final List<String> startingGuns;
  final List<String> startingItems;

  Gungeoneer({
    required this.name,
    this.icon = '',
    this.startingGuns = const [],
    this.startingItems = const [],
  });

  factory Gungeoneer.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    return Gungeoneer(
      name: name,
      icon: localGungeoneerIcon(name),
      startingGuns: (json['starting_guns'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      startingItems: (json['starting_items'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'starting_guns': startingGuns,
      'starting_items': startingItems,
    };
  }
}
