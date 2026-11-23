part of 'run_provider.dart';

// Extracted from run_provider.dart during the Phase 4 split — all
// symbols stay in the same library, no import changes needed.
// Abstract members are requirements satisfied by RunProvider.

mixin _SynergyQueries on ChangeNotifier {
  RunState get _runState;
  List<Synergy> get _allSynergies;

  // ── Owned-name memoization (L7) ──────────────────────────────
  // `allItemNames → lowercase set` was rebuilt on every query call and
  // every rebuild of every listener. Cache per slot, self-invalidating
  // on the joined-names signature — same pattern as _completesSig.
  final Map<PlayerSlot, ({String sig, Set<String> owned})> _ownedCache = {};

  Set<String> _ownedLowerFor(PlayerSlot slot) {
    final player = slot == PlayerSlot.main ? _runState.main : _runState.coop;
    if (player == null) return const {};
    final names = player.allItemNames;
    final sig = names.join('');
    final cached = _ownedCache[slot];
    if (cached != null && cached.sig == sig) return cached.owned;
    final owned = names.map((n) => n.toLowerCase()).toSet();
    _ownedCache[slot] = (sig: sig, owned: owned);
    return owned;
  }

  // Result-list caches keyed on the owned-set INSTANCE — the set object
  // is stable until the inventory signature changes, so identical() is a
  // correct invalidation check. _listFor guards against _allSynergies
  // reloads (same pattern as _pieceIndexFor).
  List<Synergy>? _activeCache;
  Set<String>? _activeCacheOwned;
  List<Synergy>? _activeCacheFor;
  List<Synergy>? _partialCache;
  Set<String>? _partialCacheOwned;
  List<Synergy>? _partialCacheFor;
  final Map<
    PlayerSlot,
    ({Set<String> owned, List<Synergy>? for_, List<Synergy> list})
  >
  _slotActiveCache = {};

  List<Synergy> getActiveSynergies() {
    final owned = _ownedLowerFor(PlayerSlot.main);
    if (_activeCache != null &&
        identical(_activeCacheOwned, owned) &&
        identical(_activeCacheFor, _allSynergies)) {
      return _activeCache!;
    }
    _activeCacheOwned = owned;
    _activeCacheFor = _allSynergies;
    return _activeCache = _allSynergies
        .where((s) => !s.isGameInactive && s.matchesOwnedSet(owned))
        .toList();
  }

  /// Partial synergies: at least one required or any-of item is owned,
  /// but the synergy is NOT fully active. These are "potential" synergies
  /// the user could complete by acquiring the remaining items.
  List<Synergy> getPartialSynergies() {
    final owned = _ownedLowerFor(PlayerSlot.main);
    if (_partialCache != null &&
        identical(_partialCacheOwned, owned) &&
        identical(_partialCacheFor, _allSynergies)) {
      return _partialCache!;
    }
    _partialCacheOwned = owned;
    _partialCacheFor = _allSynergies;
    return _partialCache = _allSynergies.where((s) {
      if (s.isGameInactive) return false;
      if (s.matchesOwnedSet(owned)) return false; // active, not partial
      return s.items.any((i) => owned.contains(i.toLowerCase())) ||
          (s.anyOf.isNotEmpty &&
              s.anyOf.any((i) => owned.contains(i.toLowerCase()))) ||
          s.groups.any(
            (g) => g.any((i) => owned.contains(i.toLowerCase())),
          );
    }).toList();
  }

  /// Active synergies for a specific player slot (main or coop).
  List<Synergy> getActiveSynergiesForSlot(PlayerSlot slot) {
    final player = slot == PlayerSlot.main ? _runState.main : _runState.coop;
    if (player == null) return const [];
    final owned = _ownedLowerFor(slot);
    final entry = _slotActiveCache[slot];
    if (entry != null &&
        identical(entry.owned, owned) &&
        identical(entry.for_, _allSynergies)) {
      return entry.list;
    }
    final list = _allSynergies
        .where((s) => !s.isGameInactive && s.matchesOwnedSet(owned))
        .toList();
    _slotActiveCache[slot] = (owned: owned, for_: _allSynergies, list: list);
    return list;
  }

  /// piece-name (lowercased) → synergies containing it in items, anyOf,
  /// or any groups pool. Built once — replaces the old per-call full
  /// 395-synergy scans in getSynergiesFor/_collectFor.
  Map<String, List<Synergy>>? _pieceIndex;
  List<Synergy>? _pieceIndexFor;

  Map<String, List<Synergy>> get _synergyPieceIndex {
    if (_pieceIndex == null || !identical(_pieceIndexFor, _allSynergies)) {
      _pieceIndex = _buildPieceIndex();
      _pieceIndexFor = _allSynergies;
    }
    return _pieceIndex!;
  }

  Map<String, List<Synergy>> _buildPieceIndex() {
    final map = <String, List<Synergy>>{};
    for (final s in _allSynergies) {
      if (s.isGameInactive) continue;
      final pieces = <String>{
        for (final i in s.items) i.toLowerCase(),
        for (final i in s.anyOf) i.toLowerCase(),
        for (final g in s.groups)
          for (final i in g) i.toLowerCase(),
      };
      for (final p in pieces) {
        map.putIfAbsent(p, () => []).add(s);
      }
    }
    return map;
  }

  List<Synergy> getSynergiesFor(String itemName) {
    return List.of(_synergyPieceIndex[itemName.toLowerCase()] ?? const []);
  }

  /// Lowercased names of every gun + item the active player currently
  /// holds. Used by the synergy UI to colour-code `any_of` alternatives
  /// — the chip for the alternative the player owns highlights amber,
  /// the rest stay muted so it's obvious which option is satisfying the
  /// "one of" branch.
  Set<String> get currentOwnedLower =>
      Set.unmodifiable(_ownedLowerFor(PlayerSlot.main));

  List<ItemSynergies> getSynergiesByInventory() {
    final lowerNames = _ownedLowerFor(PlayerSlot.main);
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
    final related =
        _synergyPieceIndex[name.toLowerCase()] ?? const <Synergy>[];
    final synergies =
        related.map((s) {
            final missing = s.missingFor(owned);
            return SynergyStatus(
              synergy: s,
              missing: missing,
              active: s.matchesOwnedSet(owned),
            );
          }).toList()
          ..sort((a, b) {
            if (a.active != b.active) return a.active ? -1 : 1;
            return a.missing.length.compareTo(b.missing.length);
          });
    return ItemSynergies(itemName: name, isGun: isGun, entries: synergies);
  }

  /// Run-wide active synergies — a synergy counts when EITHER player's
  /// own inventory satisfies it. The game evaluates synergies strictly
  /// per-player (no cross-player union), so a synergy split across P1+P2
  /// is NOT active. Memoized on the combined inventory signature.
  List<Synergy> getActiveSynergiesCombined() {
    final mainOwned = _ownedLowerFor(PlayerSlot.main);
    final coopOwned = _ownedLowerFor(PlayerSlot.coop);
    final sig = '${mainOwned.join('')}|${coopOwned.join('')}';
    if (sig != _activeCombinedSig) {
      _activeCombinedSig = sig;
      _activeCombinedCache = _allSynergies.where((s) {
        if (s.isGameInactive) return false;
        if (s.matchesOwnedSet(mainOwned)) return true;
        return coopOwned.isNotEmpty && s.matchesOwnedSet(coopOwned);
      }).toList();
    }
    return _activeCombinedCache!;
  }

  String? _activeCombinedSig;
  List<Synergy>? _activeCombinedCache;

  Map<String, int>? _synergyCountCache;
  List<Synergy>? _countCacheFor;

  int synergyCountFor(String itemName) {
    if (_synergyCountCache == null ||
        !identical(_countCacheFor, _allSynergies)) {
      _synergyCountCache = _buildSynergyCountCache();
      _countCacheFor = _allSynergies;
    }
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
                  !s.isGameInactive &&
                  !s.matchesOwnedSet(ownedLower) &&
                  s.matchesOwnedSet(wouldOwn),
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
      for (final g in s.groups) {
        for (final i in g) {
          seen.add(i.toLowerCase());
        }
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
