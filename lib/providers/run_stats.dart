part of 'run_provider.dart';

// Read-only projections of the run state — membership queries, combined
// DPS/price/quality metrics, synergy potential + glow colors. Extracted
// from RunProvider (tail sweep) — same library, no call-site changes.

mixin _RunStats on ChangeNotifier {
  RunState get _runState;
  List<Gun> get _allGunsInRun;
  List<Item> get _allItemsInRun;
  List<Synergy> get _allSynergies;
  List<Synergy> getActiveSynergiesCombined();
  int get _gunderfuryLevel;
  int get _tripleGunForm;
  int get _evolverForm;
  int get _shellegunMode;
  int get _chamberGunFloor;

  /// Returns true if any player in the run owns the named gun.
  bool isGunInRun(String name) =>
      _runState.main.guns.any((g) => g.name == name) ||
      (_runState.coop?.guns.any((g) => g.name == name) ?? false);

  bool isItemInRun(String name) =>
      _runState.main.items.any((i) => i.name == name) ||
      (_runState.coop?.items.any((i) => i.name == name) ?? false);

  /// Which slot owns this gun (main wins if both own it somehow).
  PlayerSlot? ownerSlotOfGun(String name) {
    if (_runState.main.guns.any((g) => g.name == name)) return PlayerSlot.main;
    if (_runState.coop?.guns.any((g) => g.name == name) ?? false) {
      return PlayerSlot.coop;
    }
    return null;
  }

  PlayerSlot? ownerSlotOfItem(String name) {
    if (_runState.main.items.any((i) => i.name == name)) return PlayerSlot.main;
    if (_runState.coop?.items.any((i) => i.name == name) ?? false) {
      return PlayerSlot.coop;
    }
    return null;
  }

  double _avgDpsFor(List<Gun> guns) {
    if (guns.isEmpty) return 0;
    final total = guns
        .map(
          (g) => g.getDynamicDps(
            gunderLevel: _gunderfuryLevel,
            tripleForm: _tripleGunForm,
            evolverStage: _evolverForm,
            shellegunMode: _shellegunMode,
            chamberGunFloor: _chamberGunFloor,
          ),
        )
        .fold<double>(0, (a, b) => a + b);
    return total / guns.length;
  }

  double get avgDps => _avgDpsFor(_runState.main.guns);

  double get avgDpsCoop => _avgDpsFor(_runState.coop?.guns ?? const []);

  double get combinedAvgDps => _avgDpsFor(_allGunsInRun);

  double get combinedSumDps => _allGunsInRun
      .map(
        (g) => g.getDynamicDps(
          gunderLevel: _gunderfuryLevel,
          tripleForm: _tripleGunForm,
          evolverStage: _evolverForm,
          shellegunMode: _shellegunMode,
          chamberGunFloor: _chamberGunFloor,
        ),
      )
      .fold<double>(0, (a, b) => a + b);

  /// Parse "123", "N/A", "" to an int (0 on fail).
  int _parsePrice(String s) {
    if (s.isEmpty || s.toLowerCase() == 'n/a') return 0;
    final digits = RegExp(r'\d+').firstMatch(s)?.group(0);
    return int.tryParse(digits ?? '') ?? 0;
  }

  /// Combined sell-price total across both players' guns + items.
  int get combinedTotalWorth {
    int total = 0;
    for (final g in _allGunsInRun) {
      total += _parsePrice(g.sellPrice);
    }
    for (final i in _allItemsInRun) {
      total += _parsePrice(i.sellPrice);
    }
    return total;
  }

  /// Quality points: S=5, A=4, B=3, C=2, D=1, N/other=0.
  int _qualityPoints(String q) {
    switch (q.toUpperCase()) {
      case 'S':
        return 5;
      case 'A':
        return 4;
      case 'B':
        return 3;
      case 'C':
        return 2;
      case 'D':
        return 1;
      default:
        return 0;
    }
  }

  int get combinedQualityScore {
    int s = 0;
    for (final g in _allGunsInRun) {
      s += _qualityPoints(g.quality);
    }
    for (final i in _allItemsInRun) {
      s += _qualityPoints(i.quality);
    }
    return s;
  }

  /// Normalised 0–100 quality score across the whole team. 100 = every
  /// item and gun is S-tier. Returns 0 if the team is empty. N-tier
  /// (starter) entries count as 0 points so a vanilla start ≈ 0.
  int get combinedQualityScore100 {
    final total = _allGunsInRun.length + _allItemsInRun.length;
    if (total == 0) return 0;
    final max = total * 5;
    return ((combinedQualityScore / max) * 100).round().clamp(0, 100);
  }

  /// Count of each quality tier across both players.
  Map<String, int> get combinedQualityBreakdown {
    final out = <String, int>{'S': 0, 'A': 0, 'B': 0, 'C': 0, 'D': 0, 'N': 0};
    for (final g in _allGunsInRun) {
      final k = g.quality.toUpperCase();
      if (out.containsKey(k)) out[k] = out[k]! + 1;
    }
    for (final i in _allItemsInRun) {
      final k = i.quality.toUpperCase();
      if (out.containsKey(k)) out[k] = out[k]! + 1;
    }
    return out;
  }

  /// How many distinct synergies touch ANY owned item (required or any_of)
  /// across both players. Represents the synergy "design space" this run
  /// has opened up — more is more fun to chase.
  int get combinedSynergyPotential {
    final owned = _statsOwnedLower;
    if (owned.isEmpty) return 0;
    final cached = _potentialCache;
    if (cached != null) return cached;
    var n = 0;
    for (final s in _allSynergies) {
      if (s.items.any(owned.contains) || s.anyOf.any(owned.contains)) n++;
    }
    return _potentialCache = n;
  }

  /// Owned name→lowercase set + its signature — rebuilt only when the
  /// combined inventory changes (self-invalidating memo, same pattern
  /// as the synergy predictor cache).
  String? _statsSig;
  Set<String>? _statsOwned;
  int? _potentialCache;
  Map<String, Color>? _glowCache;

  Set<String> get _statsOwnedLower {
    final guns = _allGunsInRun;
    final items = _allItemsInRun;
    final sig =
        '${guns.length}.${items.length}|${guns.map((g) => g.name).join('\n')}|${items.map((i) => i.name).join('\n')}';
    if (sig != _statsSig) {
      _statsSig = sig;
      _statsOwned = {
        for (final g in guns) g.name.toLowerCase(),
        for (final i in items) i.name.toLowerCase(),
      };
      _potentialCache = null;
      _glowCache = null;
    }
    return _statsOwned!;
  }

  /// Maps every item/gun name (lowercased) that participates in a currently
  /// active synergy to a vivid, deterministic Color for that synergy.
  /// Considers BOTH players' inventories so co-op synergies light up too.
  /// Returns an empty map when no synergies are active.
  Map<String, Color> get activeSynergyGlowColors {
    _statsOwnedLower; // refresh the signature → invalidates on change
    return _glowCache ??= _buildGlowColors();
  }

  Map<String, Color> _buildGlowColors() {
    final active = getActiveSynergiesCombined();
    if (active.isEmpty) return const {};
    final result = <String, Color>{};
    for (final syn in active) {
      final color = _colorForSynergy(syn.name);
      for (final name in [...syn.items, ...syn.anyOf]) {
        result[name.toLowerCase()] = color;
      }
    }
    return result;
  }

  /// Derives a deterministic, vivid hue from the synergy name so the same
  /// synergy always renders with the same color across sessions.
  static Color _colorForSynergy(String synName) {
    final hue = (synName.hashCode.abs() % 360).toDouble();
    return HSVColor.fromAHSV(1.0, hue, 0.88, 1.0).toColor();
  }
}
