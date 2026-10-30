part of 'run_provider.dart';

// Extracted from run_provider.dart during the Phase 4 split — all
// symbols stay in the same library, no import changes needed.
// Abstract members are requirements satisfied by RunProvider.

mixin _SynergyQueries on ChangeNotifier {
  RunState get _runState;
  List<Synergy> get _allSynergies;

  List<Synergy> getActiveSynergies() {
    final itemNames = _runState.main.allItemNames;
    return _allSynergies.where((s) => s.matchesItems(itemNames)).toList();
  }

  /// Partial synergies: at least one required or any-of item is owned,
  /// but the synergy is NOT fully active. These are "potential" synergies
  /// the user could complete by acquiring the remaining items.
  List<Synergy> getPartialSynergies() {
    final itemNames = _runState.main.allItemNames;
    final owned = itemNames.map((n) => n.toLowerCase()).toSet();
    return _allSynergies.where((s) {
      if (s.matchesItems(itemNames)) return false; // active, not partial
      return s.items.any((i) => owned.contains(i.toLowerCase())) ||
          (s.anyOf.isNotEmpty &&
              s.anyOf.any((i) => owned.contains(i.toLowerCase())));
    }).toList();
  }

  /// Active synergies for a specific player slot (main or coop).
  List<Synergy> getActiveSynergiesForSlot(PlayerSlot slot) {
    final player = slot == PlayerSlot.main ? _runState.main : _runState.coop;
    if (player == null) return [];
    final itemNames = player.allItemNames;
    return _allSynergies.where((s) => s.matchesItems(itemNames)).toList();
  }

  List<Synergy> getSynergiesFor(String itemName) {
    final lower = itemName.toLowerCase();
    return _allSynergies
        .where(
          (s) =>
              s.items.any((i) => i.toLowerCase() == lower) ||
              s.anyOf.any((i) => i.toLowerCase() == lower),
        )
        .toList();
  }

  /// Lowercased names of every gun + item the active player currently
  /// holds. Used by the synergy UI to colour-code `any_of` alternatives
  /// — the chip for the alternative the player owns highlights amber,
  /// the rest stay muted so it's obvious which option is satisfying the
  /// "one of" branch.
  Set<String> get currentOwnedLower =>
      _runState.main.allItemNames.map((n) => n.toLowerCase()).toSet();

  List<ItemSynergies> getSynergiesByInventory() {
    final names = _runState.main.allItemNames;
    final lowerNames = names.map((n) => n.toLowerCase()).toSet();
    final result = <ItemSynergies>[];
    for (final gun in _runState.main.guns) {
      result.add(_collectFor(gun.name, true, lowerNames));
    }
    for (final item in _runState.main.items) {
      result.add(_collectFor(item.name, false, lowerNames));
    }
    return result;
  }

  ItemSynergies _collectFor(String name, bool isGun, Set<String> owned) {
    final lower = name.toLowerCase();
    final related = _allSynergies.where(
      (s) =>
          s.items.any((i) => i.toLowerCase() == lower) ||
          s.anyOf.any((i) => i.toLowerCase() == lower),
    );
    final synergies =
        related.map((s) {
            final missing = s.missingFor(owned);
            return SynergyStatus(
              synergy: s,
              missing: missing,
              active: s.matchesItems(owned.toList()),
            );
          }).toList()
          ..sort((a, b) {
            if (a.active != b.active) return a.active ? -1 : 1;
            return a.missing.length.compareTo(b.missing.length);
          });
    return ItemSynergies(itemName: name, isGun: isGun, entries: synergies);
  }

  /// Full-run active synergies (looks across BOTH players' inventories).
  List<Synergy> getActiveSynergiesCombined() {
    final names = _runState.allItemNames; // main + coop
    return _allSynergies.where((s) => s.matchesItems(names)).toList();
  }

  Map<String, int>? _synergyCountCache;

  int synergyCountFor(String itemName) {
    _synergyCountCache ??= _buildSynergyCountCache();
    return _synergyCountCache![itemName.toLowerCase()] ?? 0;
  }

  /// Synergy Predictor (genius audit Q2): returns the names of synergies
  /// that are NOT currently active but WOULD become active if [itemName]
  /// were added to [slot]'s loadout. Used by the browse screen to
  /// highlight items/guns that complete partial synergies.
  ///
  /// Returns an empty list if the item is already owned (can't complete
  /// what's already counted) or if no synergy would be completed.
  List<String> synergiesCompletedBy(
    String itemName, {
    PlayerSlot slot = PlayerSlot.main,
  }) {
    final player = slot == PlayerSlot.main ? _runState.main : _runState.coop;
    if (player == null) return const [];
    final owned = player.allItemNames;
    // Inventory signature — any content change produces a new signature,
    // which clears the memo. Self-invalidating; no explicit versioning.
    final sig = '${slot.index}|${owned.join('')}';
    if (sig != _completesSig) {
      _completesCache.clear();
      _completesOwnedLower = null;
      _completesSig = sig;
    }
    final ownedLower =
        _completesOwnedLower ??= owned.map((n) => n.toLowerCase()).toSet();
    final lower = itemName.toLowerCase();
    if (ownedLower.contains(lower)) return const []; // already owned
    final cached = _completesCache[lower];
    if (cached != null) return cached;
    final wouldOwn = {...ownedLower, lower};
    return _completesCache[lower] =
        _allSynergies
            .where(
              (s) =>
                  !s.matchesOwnedSet(ownedLower) && s.matchesOwnedSet(wouldOwn),
            )
            .map((s) => s.name)
            .toList();
  }

  String? _completesSig;

  Set<String>? _completesOwnedLower;

  final Map<String, List<String>> _completesCache = {};

  Map<String, int> _buildSynergyCountCache() {
    final map = <String, int>{};
    for (final s in _allSynergies) {
      final seen = <String>{};
      for (final i in s.items) {
        seen.add(i.toLowerCase());
      }
      for (final i in s.anyOf) {
        seen.add(i.toLowerCase());
      }
      for (final k in seen) {
        map[k] = (map[k] ?? 0) + 1;
      }
    }
    return map;
  }
}

class SynergyStatus {
  final Synergy synergy;
  final List<String> missing;
  final bool active;
  SynergyStatus({
    required this.synergy,
    required this.missing,
    required this.active,
  });
}

class ItemSynergies {
  final String itemName;
  final bool isGun;
  final List<SynergyStatus> entries;
  ItemSynergies({
    required this.itemName,
    required this.isGun,
    required this.entries,
  });
}

String _encodeRunState(Map<String, dynamic> jsonMap) {
  return json.encode(jsonMap);
}
