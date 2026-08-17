import '../utils/asset_paths.dart';

class Gungeoneer {
  final String name;
  final String icon;
  final List<String> startingGuns;
  final List<String> startingItems;
  final int startingArmor;
  final String shortDesc;
  final String loreIntro;
  final String playstyle;
  final List<String> tips;
  final List<String> nicknames;
  final String voice;
  final int hegemonyCost;
  final String unlockMethod;
  final bool isDefault;
  final bool isCoopOnly;
  final String pastName;
  final String pastSummary;
  final String pastLoadout;
  final String pastDetails;
  final String pastUnlocks;
  final String altCostumeName;
  final String altCostumeUnlock;
  final String altWeaponSkinUnlock;
  final String wikiUrl;

  Gungeoneer({
    required this.name,
    this.icon = '',
    this.startingGuns = const [],
    this.startingItems = const [],
    this.startingArmor = 0,
    this.shortDesc = '',
    this.loreIntro = '',
    this.playstyle = '',
    this.tips = const [],
    this.nicknames = const [],
    this.voice = '',
    this.hegemonyCost = 0,
    this.unlockMethod = '',
    this.isDefault = true,
    this.isCoopOnly = false,
    this.pastName = '',
    this.pastSummary = '',
    this.pastLoadout = '',
    this.pastDetails = '',
    this.pastUnlocks = '',
    this.altCostumeName = '',
    this.altCostumeUnlock = '',
    this.altWeaponSkinUnlock = '',
    this.wikiUrl = '',
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
      startingArmor: (json['starting_armor'] as num?)?.toInt() ?? 0,
      shortDesc: json['short_desc'] as String? ?? '',
      loreIntro: json['lore_intro'] as String? ?? '',
      playstyle: json['playstyle'] as String? ?? '',
      tips: (json['tips'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      nicknames: (json['nicknames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      voice: json['voice'] as String? ?? '',
      hegemonyCost: (json['hegemony_cost'] as num?)?.toInt() ?? 0,
      unlockMethod: json['unlock_method'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? true,
      isCoopOnly: json['is_coop_only'] as bool? ?? false,
      pastName: json['past_name'] as String? ?? '',
      pastSummary: json['past_summary'] as String? ?? '',
      pastLoadout: json['past_loadout'] as String? ?? '',
      pastDetails: json['past_details'] as String? ?? '',
      pastUnlocks: json['past_unlocks'] as String? ?? '',
      altCostumeName: json['alt_costume_name'] as String? ?? '',
      altCostumeUnlock: json['alt_costume_unlock'] as String? ?? '',
      altWeaponSkinUnlock: json['alt_weapon_skin_unlock'] as String? ?? '',
      wikiUrl: json['wiki_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'starting_guns': startingGuns,
      'starting_items': startingItems,
      'starting_armor': startingArmor,
      'short_desc': shortDesc,
      'lore_intro': loreIntro,
      'playstyle': playstyle,
      'tips': tips,
      'nicknames': nicknames,
      'voice': voice,
      'hegemony_cost': hegemonyCost,
      'unlock_method': unlockMethod,
      'is_default': isDefault,
      'is_coop_only': isCoopOnly,
      'past_name': pastName,
      'past_summary': pastSummary,
      'past_loadout': pastLoadout,
      'past_details': pastDetails,
      'past_unlocks': pastUnlocks,
      'alt_costume_name': altCostumeName,
      'alt_costume_unlock': altCostumeUnlock,
      'alt_weapon_skin_unlock': altWeaponSkinUnlock,
      'wiki_url': wikiUrl,
    };
  }
}
