import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/gun.dart';
import '../models/item.dart';
import '../models/rich_text.dart';
import '../models/synergy.dart';
import '../models/shrine.dart';
import '../models/gungeoneer.dart';
import '../models/player.dart';
import '../models/run_state.dart';

class RunProvider with ChangeNotifier {
  RunState _runState = RunState();

  List<Gun> _allGuns = [];
  List<Item> _allItems = [];
  List<Synergy> _allSynergies = [];
  List<Shrine> _allShrines = [];
  List<Gungeoneer> _allGungeoneers = [];

  /// Reverse index of "what entities reference X". Built once at scrape
  /// time, loaded lazily here. Drives the "Referenced by" panel on each
  /// item detail screen.
  BackRefs _backRefs = BackRefs.empty;

  /// Case-insensitive name → entity lookup maps, rebuilt inside
  /// [loadData] after each master list hydrates. Replace the O(n)
  /// `firstWhere` scans that previously ran on every back-ref chip
  /// render (Duct Tape's 33-chip "Referenced by" pane was doing ~17 000
  /// string comparisons per rebuild) and every rich-link tap.
  Map<String, Gun> _gunsByLowerName = const {};
  Map<String, Item> _itemsByLowerName = const {};
  Map<String, Synergy> _synergiesByLowerName = const {};

  /// Names of guns/items the user has favourited. Shared across runs
  /// and both players. Persisted independently of run state so starring
  /// stuff in one run carries over to the next.
  Set<String> _favourites = <String>{};

  int _gunderfuryLevel = 1;
  int _tripleGunForm = 1;
  int _evolverForm = 1;
  int _evolverKills = 0;
  int _spiceUsageCount = 0;

  // Sprun mystery trigger: -1 = not yet revealed for this run,
  // 0..4 = index into the possible trigger list shown in the tracker.
  int _sprunTriggerIndex = -1;

  Timer? _windgunnerTimer;
  int _windgunnerCountdown = 0;

  // Payday crew: which of Clown Mask / Drill / Loot Bag the user has
  // manually marked as "crew active" is derived from inventory, no state.

  // The Robot special features
  int _robotArmor = 6;
  int _robotJunk = 0;
  bool _robotGoldJunk = false;
  bool _robotLies = false;
  bool _fireplaceExtinguished = false;
  bool _batteryBulletsSynergy = false;
  bool _fuseDisarmer = false;

  // The Huntress special features
  int _huntressRoomClears = 0;
  bool _huntressInjured = false;

  int get gunderfuryLevel => _gunderfuryLevel;
  int get tripleGunForm => _tripleGunForm;
  int get evolverForm => _evolverForm;
  int get evolverKills => _evolverKills;
  int get sprunTriggerIndex => _sprunTriggerIndex;
  int get windgunnerCountdown => _windgunnerCountdown;
  int get spiceUsageCount => _spiceUsageCount;

  int get robotArmor => _robotArmor;
  int get robotJunk => _robotJunk;
  bool get robotGoldJunk => _robotGoldJunk;
  bool get robotLies => _robotLies;
  bool get fireplaceExtinguished => _fireplaceExtinguished;
  bool get batteryBulletsSynergy => _batteryBulletsSynergy;
  bool get fuseDisarmer => _fuseDisarmer;

  int get huntressRoomClears => _huntressRoomClears;
  bool get huntressInjured => _huntressInjured;

  bool _isLoading = true;
  String? _error;

  RunState get runState => _runState;
  List<Gun> get allGuns => _allGuns;
  List<Item> get allItems => _allItems;
  List<Synergy> get allSynergies => _allSynergies;
  List<Shrine> get allShrines => _allShrines;
  List<Gungeoneer> get allGungeoneers => _allGungeoneers;
  BackRefs get backRefs => _backRefs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasCoop => _runState.coop != null;

  // --- O(1) name lookups --------------------------------------------------

  /// Case-insensitive gun lookup. Returns null if [name] is unknown.
  /// Prefer this over `allGuns.firstWhere(...)` everywhere.
  Gun? gunByName(String name) => _gunsByLowerName[name.toLowerCase()];

  /// Case-insensitive item lookup. Returns null if [name] is unknown.
  Item? itemByName(String name) => _itemsByLowerName[name.toLowerCase()];

  /// Case-insensitive synergy lookup. Returns null if [name] is unknown.
  Synergy? synergyByName(String name) =>
      _synergiesByLowerName[name.toLowerCase()];

  /// Case-insensitive character lookup. Returns null if [name] is
  /// unknown. The roster is tiny (≈7 entries) so a linear scan is
  /// faster in practice than maintaining another map.
  Gungeoneer? gungeoneerByName(String name) {
    final lower = name.toLowerCase();
    for (final g in _allGungeoneers) {
      if (g.name.toLowerCase() == lower) return g;
    }
    return null;
  }

  /// Case-insensitive shrine lookup. Returns null if [name] is unknown.
  /// Shrines are also a small list (≈20 entries) so a linear scan is
  /// fine and avoids building yet another lowercase map at boot.
  Shrine? shrineByName(String name) {
    final lower = name.toLowerCase();
    for (final s in _allShrines) {
      if (s.name.toLowerCase() == lower) return s;
    }
    return null;
  }

  /// Unified lookup used by rich-link tap handlers: returns a `(gun,
  /// item)` record where exactly one slot is populated (or both null if
  /// the name matches neither). Guns win when the same string happens
  /// to exist in both lists (defensive — shouldn't happen).
  ({Gun? gun, Item? item}) entityByName(String name) {
    final g = gunByName(name);
    if (g != null) return (gun: g, item: null);
    return (gun: null, item: itemByName(name));
  }

  // ------------------------------------------------------------------------

  Future<void> loadData() async {
    try {
      _isLoading = true;
      notifyListeners();

      final gunsJson = await rootBundle.loadString('assets/data/guns.json');
      final itemsJson = await rootBundle.loadString('assets/data/items.json');

      final gunsList = json.decode(gunsJson) as List;
      final itemsList = json.decode(itemsJson) as List;

      _allGuns = gunsList.map((g) => Gun.fromJson(g)).toList();
      _allItems = itemsList.map((i) => Item.fromJson(i)).toList();

      try {
        final synergiesJson =
            await rootBundle.loadString('assets/data/synergies.json');
        final synergiesList = json.decode(synergiesJson) as List;
        _allSynergies =
            synergiesList.map((s) => Synergy.fromJson(s)).toList();
      } catch (e) {
// Removed debugPrint for production
        _allSynergies = [];
      }

      try {
        final shrinesJson =
            await rootBundle.loadString('assets/data/shrines.json');
        final shrinesList = json.decode(shrinesJson) as List;
        _allShrines = shrinesList.map((s) => Shrine.fromJson(s)).toList();
      } catch (e) {
// Removed debugPrint for production
        _allShrines = [];
      }

      try {
        final gungeoneerJson =
            await rootBundle.loadString('assets/data/gungeoneers.json');
        final gungeoneerList = json.decode(gungeoneerJson) as List;
        _allGungeoneers =
            gungeoneerList.map((g) => Gungeoneer.fromJson(g)).toList();
      } catch (e) {
// Removed debugPrint for production
        _allGungeoneers = [];
      }

      try {
        final backRefsJson =
            await rootBundle.loadString('assets/data/back_refs.json');
        _backRefs = BackRefs.fromJsonString(backRefsJson);
      } catch (e) {
// Removed debugPrint for production
        _backRefs = BackRefs.empty;
      }

      // Build O(1) name-lookup indices once everything else is hydrated.
      // Keys are lowercased so callers don't have to normalize at every
      // call-site. Values point at the same Gun/Item/Synergy instances
      // stored in the master lists (no copy).
      _gunsByLowerName = {
        for (final g in _allGuns) g.name.toLowerCase(): g,
      };
      _itemsByLowerName = {
        for (final i in _allItems) i.name.toLowerCase(): i,
      };
      _synergiesByLowerName = {
        for (final s in _allSynergies) s.name.toLowerCase(): s,
      };

      await _loadSavedRun();
      await _loadFavourites();
      await _loadSpecialUpgrades();

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Persistence --------------------------------------------------------

  Future<void> _loadSavedRun() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedRun = prefs.getString('current_run');
      if (savedRun != null) {
        try {
          final runJson = json.decode(savedRun);
          final loaded = RunState.fromJson(runJson);
          _runState = _refreshAgainstData(loaded);
          return;
        } catch (_) {
          // Double-buffered recovery: fall back to current_run_backup on corruption
          savedRun = prefs.getString('current_run_backup');
        }
      }
      if (savedRun == null) return;
      final runJson = json.decode(savedRun);
      final loaded = RunState.fromJson(runJson);
      _runState = _refreshAgainstData(loaded);
    } catch (e) {
// Removed debugPrint for production
    }
  }

  /// Re-resolve saved players against the current master JSON so fields
  /// like sell_price/type pick up any data updates since the save.
  RunState _refreshAgainstData(RunState s) {
    Player refreshPlayer(Player p) {
      final freshGuns = p.guns.map((g) => gunByName(g.name) ?? g).toList();
      final freshItems = p.items.map((i) => itemByName(i.name) ?? i).toList();
      Gungeoneer? freshChar = p.character;
      if (freshChar != null) {
        // Characters are few (7), a linear scan stays fine and avoids
        // adding another indexed map just for this. Cache the name
        // before the loop — Dart loses null-promotion once the closure
        // reassigns [freshChar].
        // Case-insensitive so a legacy save with a slightly different
        // name casing still re-binds to the master character entry —
        // aligns with how gun/item names are resolved everywhere else.
        final charNameLower = freshChar.name.toLowerCase();
        for (final g in _allGungeoneers) {
          if (g.name.toLowerCase() == charNameLower) {
            freshChar = g;
            break;
          }
        }
      }
      return p.copyWith(
          character: freshChar, guns: freshGuns, items: freshItems);
    }

    return s.copyWith(
      main: refreshPlayer(s.main),
      coop: s.coop != null ? refreshPlayer(s.coop!) : null,
    );
  }

  Future<void> _saveRun() async {
    try {
      final jsonMap = _runState.toJson();
      final encoded = await compute(_encodeRunState, jsonMap);
      final prefs = await SharedPreferences.getInstance();
      
      // Double-buffering atomic recovery: keep the last known good string as backup before overwrite
      final lastGood = prefs.getString('current_run');
      if (lastGood != null && lastGood.isNotEmpty) {
        await prefs.setString('current_run_backup', lastGood);
      }
      
      await prefs.setString('current_run', encoded);
    } catch (e) {
// Removed debugPrint for production
    }
  }

  // --- Favourites --------------------------------------------------------

  Future<void> _loadFavourites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('favourites_v1');
      if (list != null) _favourites = list.toSet();
    } catch (e) {
// Removed debugPrint for production
    }
  }

  Future<void> _saveFavourites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favourites_v1', _favourites.toList());
    } catch (e) {
// Removed debugPrint for production
    }
  }

  // --- Special Upgrades ----------------------------------------------------

  Future<void> _loadSpecialUpgrades() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _gunderfuryLevel = prefs.getInt('special.gunderfury.level') ?? 1;
      _tripleGunForm = prefs.getInt('special.triple_gun.form') ?? 1;
      _evolverForm = prefs.getInt('special.evolver.form') ?? 1;
      _evolverKills = prefs.getInt('special.evolver.kills') ?? 0;
      _sprunTriggerIndex = prefs.getInt('special.sprun.trigger') ?? -1;
      _spiceUsageCount = prefs.getInt('special.spice.count') ?? 0;

      // Robot specific values
      _robotArmor = prefs.getInt('special.robot.armor') ?? 6;
      _robotJunk = prefs.getInt('special.robot.junk') ?? 0;
      _robotGoldJunk = prefs.getBool('special.robot.goldjunk') ?? false;
      _robotLies = prefs.getBool('special.robot.lies') ?? false;
      _fireplaceExtinguished = prefs.getBool('special.robot.fireplace') ?? false;
      _batteryBulletsSynergy = prefs.getBool('special.robot.battery') ?? false;
      _fuseDisarmer = prefs.getBool('special.robot.fusedisarmer') ?? false;

      // Huntress specific values
      _huntressRoomClears = prefs.getInt('special.huntress.roomclears') ?? 0;
      _huntressInjured = prefs.getBool('special.huntress.injured') ?? false;
    } catch (_) {}
  }

  Future<void> setHuntressRoomClears(int clears) async {
    _huntressRoomClears = clears.clamp(0, 999);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('special.huntress.roomclears', _huntressRoomClears);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setHuntressInjured(bool injured) async {
    _huntressInjured = injured;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('special.huntress.injured', _huntressInjured);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setRobotArmor(int armor) async {
    _robotArmor = armor.clamp(0, 99);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('special.robot.armor', _robotArmor);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setRobotJunk(int junk) async {
    _robotJunk = junk.clamp(0, 99);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('special.robot.junk', _robotJunk);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setRobotGoldJunk(bool gold) async {
    _robotGoldJunk = gold;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('special.robot.goldjunk', _robotGoldJunk);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setRobotLies(bool lies) async {
    _robotLies = lies;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('special.robot.lies', _robotLies);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setFireplaceExtinguished(bool val) async {
    _fireplaceExtinguished = val;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('special.robot.fireplace', _fireplaceExtinguished);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setBatteryBulletsSynergy(bool val) async {
    _batteryBulletsSynergy = val;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('special.robot.battery', _batteryBulletsSynergy);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setFuseDisarmer(bool val) async {
    _fuseDisarmer = val;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('special.robot.fusedisarmer', _fuseDisarmer);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setGunderfuryLevel(int lvl) async {
    _gunderfuryLevel = lvl.clamp(1, 60);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('special.gunderfury.level', _gunderfuryLevel);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setTripleGunForm(int form) async {
    _tripleGunForm = form.clamp(1, 3);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('special.triple_gun.form', _tripleGunForm);
    } catch (_) {}
    notifyListeners();
  }

  /// Records unique-enemy-type kills for the Evolver. Every 5 unique
  /// kills force-evolves the gun one stage (max stage 6 at 25 kills),
  /// so the form is derived and kept in sync here.
  Future<void> setEvolverKills(int kills) async {
    _evolverKills = kills.clamp(0, 25);
    _evolverForm = (1 + _evolverKills ~/ 5).clamp(1, 6);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('special.evolver.kills', _evolverKills);
      await prefs.setInt('special.evolver.form', _evolverForm);
    } catch (_) {}
    notifyListeners();
  }

  /// Reveals (or re-rolls) the Sprun mystery trigger for this run.
  /// Pass -1 to reset to unrevealed.
  Future<void> setSprunTriggerIndex(int index) async {
    _sprunTriggerIndex = index.clamp(-1, 4);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('special.sprun.trigger', _sprunTriggerIndex);
    } catch (_) {}
    notifyListeners();
  }

  void startWindgunnerCountdown() {
    _windgunnerTimer?.cancel();
    _windgunnerCountdown = 20;
    notifyListeners();
    _windgunnerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_windgunnerCountdown > 0) {
        _windgunnerCountdown--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  void cancelWindgunnerCountdown() {
    _windgunnerTimer?.cancel();
    _windgunnerCountdown = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _windgunnerTimer?.cancel();
    super.dispose();
  }

  Future<void> setEvolverForm(int form) async {
    _evolverForm = form.clamp(1, 6);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('special.evolver.form', _evolverForm);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setSpiceUsageCount(int count) async {
    _spiceUsageCount = count.clamp(0, 100);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('special.spice.count', _spiceUsageCount);
    } catch (_) {}
    notifyListeners();
  }

  bool isFavourite(String name) => _favourites.contains(name);

  /// Toggle favourite status for a gun/item by name. Returns the new state.
  bool toggleFavourite(String name) {
    final nowFav = !_favourites.contains(name);
    if (nowFav) {
      _favourites.add(name);
    } else {
      _favourites.remove(name);
    }
    _saveFavourites();
    notifyListeners();
    return nowFav;
  }

  void resetFavourites() {
    _favourites.clear();
    _saveFavourites();
    notifyListeners();
  }

  int get favouritesCount => _favourites.length;

  /// Resolved Gun objects for the favourited names (preserves insertion
  /// order approximately — actually set-insertion order on Dart is
  /// unordered, so we sort by name for stable UI).
  List<Gun> get favouriteGuns => _allGuns
      .where((g) => _favourites.contains(g.name))
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  List<Item> get favouriteItems => _allItems
      .where((i) => _favourites.contains(i.name))
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  // --- Run lifecycle ------------------------------------------------------

  /// Internal: build a freshly-loaded Player for a Gungeoneer, pulling
  /// starting guns/items by name from the master data.
  Player _buildPlayerFor(Gungeoneer character) {
    final startingGuns = _allGuns
        .where((g) => character.startingGuns.contains(g.name))
        .toList();
    final startingItems = _allItems
        .where((i) => character.startingItems.contains(i.name))
        .toList();
    return Player(
      character: character,
      guns: startingGuns,
      items: startingItems,
    );
  }

  void startNewRun(Gungeoneer character) {
    _runState = RunState(main: _buildPlayerFor(character));
    _saveRun();
    notifyListeners();
  }

  /// Add a second (local co-op) player to the current run.
  void startCoopPlayer(Gungeoneer character) {
    _runState = _runState.copyWith(coop: _buildPlayerFor(character));
    _saveRun();
    notifyListeners();
  }

  /// Remove the co-op player slot entirely.
  void endCoopPlayer() {
    _runState = _runState.copyWith(clearCoop: true);
    _saveRun();
    notifyListeners();
  }

  /// Wipe a player's loadout back to their starter guns/items. Keeps the
  /// character but rebuilds the player record fresh — no acquired guns,
  /// no acquired items. Also resets coolness, curse, and shrines to zero
  /// since the user is effectively starting a fresh run.
  void clearInventory({PlayerSlot slot = PlayerSlot.main}) {
    final current = _playerFor(slot);
    final char = current.character;
    if (char == null) return;
    final fresh = _buildPlayerFor(char);
    _runState = _replacePlayer(slot, fresh);
    _runState = _runState.copyWith(coolness: 0.0, curse: 0.0, shrinesUsed: []);
    _saveRun();
    notifyListeners();
  }

  // --- Multiplayer snapshot hooks ----------------------------------------
  // Called only by MultiplayerSession when it receives a snapshot from
  // the connected peer. Keep these non-obvious mutations isolated from
  // the solo code paths by giving them distinct, multiplayer-only names.

  /// Replace the co-op slot wholesale from a partner's snapshot. Names
  /// are resolved against the current master data; unknown names are
  /// silently dropped (harmless — the peer will re-send shortly if the
  /// name does actually exist on their side).
  void applyPartnerSnapshot({
    required String characterName,
    required List<String> gunNames,
    required List<String> itemNames,
  }) {
    final char = characterName.isEmpty ? null : gungeoneerByName(characterName);
    final guns = gunNames
        .map((n) => gunByName(n))
        .whereType<Gun>()
        .toList();
    final items = itemNames
        .map((n) => itemByName(n))
        .whereType<Item>()
        .toList();
    _runState = _runState.copyWith(
      coop: Player(character: char, guns: guns, items: items),
    );
    _saveRun();
    notifyListeners();
  }

  /// Restore the local `main` slot from a previously-captured Player.
  /// Used by the multiplayer Sidekick flow when the user cancels the
  /// session: their pre-MP solo run was overwritten by the peer's
  /// snapshot, and this hands it back unchanged. Pass `Player()` to
  /// clear the slot when the user had no solo run.
  void restoreMainSlot(Player main) {
    _runState = _runState.copyWith(main: main);
    _saveRun();
    notifyListeners();
  }

  /// Atomic restore of every field the Sidekick MP path overwrites:
  /// the main slot AND the run-scope coolness/curse/shrines list. Done
  /// in a single copyWith so listeners only see one transition rather
  /// than a flicker through partially-restored states.
  void restoreRunScopeState({
    required Player main,
    required double coolness,
    required double curse,
    required List<String> shrinesUsed,
  }) {
    _runState = _runState.copyWith(
      main: main,
      coolness: coolness,
      curse: curse,
      shrinesUsed: shrinesUsed,
    );
    _saveRun();
    notifyListeners();
  }

  /// Restore the entire run state atomically (used when loading a saved multiplayer session).
  void restoreEntireRunState(RunState state) {
    _runState = state;
    _saveRun();
    notifyListeners();
  }

  /// Apply peer snapshot to either main or coop slot based on role.
  /// Main Player receives Sidekick data into coop slot;
  /// Sidekick receives Main data into main slot.
  void applyPeerSnapshot({
    required String characterName,
    required List<String> gunNames,
    required List<String> itemNames,
    required bool targetMainSlot,
  }) {
    final char = characterName.isEmpty ? null : gungeoneerByName(characterName);
    final guns = gunNames
        .map((n) => gunByName(n))
        .whereType<Gun>()
        .toList();
    final items = itemNames
        .map((n) => itemByName(n))
        .whereType<Item>()
        .toList();
    final player = Player(character: char, guns: guns, items: items);

    var currentCoop = _runState.coop;
    if (currentCoop == null) {
      final cultist = gungeoneerByName('The Cultist') ?? gungeoneerByName('Cultist');
      currentCoop = Player(
        character: cultist,
        guns: cultist != null ? cultist.startingGuns.map((g) => gunByName(g)).whereType<Gun>().toList() : [],
        items: const [],
      );
    }

    _runState = _runState.copyWith(
      main: targetMainSlot ? player : _runState.main,
      coop: targetMainSlot ? currentCoop : player,
    );
    _saveRun();
    notifyListeners();
  }

  /// Overwrite shared dungeon state (coolness / curse / shrines used)
  /// with values from a peer snapshot. Last-write-wins — the session
  /// layer only calls this when the incoming snapshot's timestamp is
  /// newer than what we've already applied, so concurrent edits on
  /// both devices still converge within a frame or two.
  void applySharedStateFromPeer({
    double? coolness,
    double? curse,
    List<String>? shrinesUsed,
  }) {
    _runState = _runState.copyWith(
      coolness: coolness ?? _runState.coolness,
      curse: curse ?? _runState.curse,
      shrinesUsed: shrinesUsed ?? _runState.shrinesUsed,
    );
    _saveRun();
    notifyListeners();
  }

  void endRun() {
    _runState = RunState();
    _saveRun();
    notifyListeners();
  }

  // --- Per-slot mutations ------------------------------------------------

  Player _playerFor(PlayerSlot slot) =>
      slot == PlayerSlot.main ? _runState.main : (_runState.coop ?? Player());

  RunState _replacePlayer(PlayerSlot slot, Player p) {
    if (slot == PlayerSlot.main) {
      return _runState.copyWith(main: p);
    }
    return _runState.copyWith(coop: p);
  }

  void addGun(Gun gun, {PlayerSlot slot = PlayerSlot.main}) {
    final p = _playerFor(slot);
    if (p.guns.any((g) => g.name == gun.name)) return;
    _runState = _replacePlayer(slot, p.copyWith(guns: [...p.guns, gun]));
    _saveRun();
    notifyListeners();
  }

  void removeGun(Gun gun, {PlayerSlot slot = PlayerSlot.main}) {
    final p = _playerFor(slot);
    _runState = _replacePlayer(
        slot, p.copyWith(guns: p.guns.where((g) => g.name != gun.name).toList()));
    _saveRun();
    notifyListeners();
  }

  void addItem(Item item, {PlayerSlot slot = PlayerSlot.main}) {
    final p = _playerFor(slot);
    final isJunk = item.name.toLowerCase() == 'junk';
    if (!isJunk && p.items.any((i) => i.name == item.name)) return;
    _runState = _replacePlayer(slot, p.copyWith(items: [...p.items, item]));

    // Robot Tax: Automatically convert HP Upgrades and Master Rounds to +1 Armor!
    final charName = p.character?.name.toLowerCase() ?? '';
    if (charName.contains('robot')) {
      final nameLower = item.name.toLowerCase();
      final isHpUp = nameLower.contains('master round') ||
                     nameLower.contains('heart container') ||
                     nameLower.contains('heart holster') ||
                     nameLower.contains('heart locket') ||
                     nameLower.contains('heart purse') ||
                     nameLower.contains('heart bottle') ||
                     nameLower.contains('yellow chamber') ||
                     nameLower.contains('pink guon stone');
      if (isHpUp) {
        setRobotArmor(_robotArmor + 1);
      }
      // Auto-track Junk-type pickups on the Robot HUD — no manual taps needed.
      _autoTrackRobotJunk(nameLower, added: true);
    }

    _saveRun();
    notifyListeners();
  }

  /// Auto-syncs the Robot's Junk damage trackers when Junk-type items
  /// are added to / removed from the inventory.
  void _autoTrackRobotJunk(String nameLower, {required bool added}) {
    final delta = added ? 1 : -1;
    if (nameLower == 'junk' || nameLower == 'sack of junk') {
      setRobotJunk(_robotJunk + delta);
    } else if (nameLower.contains('gold junk') || nameLower.contains('golden junk')) {
      setRobotGoldJunk(added);
    } else if (nameLower == 'lies') {
      setRobotLies(added);
    }
  }

  void removeItem(Item item, {PlayerSlot slot = PlayerSlot.main}) {
    final p = _playerFor(slot);
    
    // Only remove one copy if it's Junk (to allow incremental stacking/unstacking)
    List<Item> newItems;
    if (item.name.toLowerCase() == 'junk') {
      newItems = List<Item>.from(p.items);
      final index = newItems.indexWhere((i) => i.name == item.name);
      if (index != -1) {
        newItems.removeAt(index);
      }
    } else {
      newItems = p.items.where((i) => i.name != item.name).toList();
    }
    
    _runState = _replacePlayer(slot, p.copyWith(items: newItems));

    // Keep the Robot's auto Junk tracking in sync on removal too.
    final charName = p.character?.name.toLowerCase() ?? '';
    if (charName.contains('robot')) {
      _autoTrackRobotJunk(item.name.toLowerCase(), added: false);
    }

    _saveRun();
    notifyListeners();
  }

  /// Transfer a gun from one slot to the other. Returns true if the
  /// transfer actually happened. False if there's no co-op slot or if
  /// the target already owns it (prevents accidental drops).
  bool transferGun(Gun gun, PlayerSlot fromSlot) {
    if (!hasCoop) return false;
    final toSlot =
        fromSlot == PlayerSlot.main ? PlayerSlot.coop : PlayerSlot.main;
    final from = _playerFor(fromSlot);
    final to = _playerFor(toSlot);
    if (to.guns.any((g) => g.name == gun.name)) return false;
    _runState = _replacePlayer(fromSlot,
        from.copyWith(guns: from.guns.where((g) => g.name != gun.name).toList()));
    _runState = _replacePlayer(toSlot, to.copyWith(guns: [...to.guns, gun]));
    _saveRun();
    notifyListeners();
    return true;
  }

  bool transferItem(Item item, PlayerSlot fromSlot) {
    if (!hasCoop) return false;
    final toSlot =
        fromSlot == PlayerSlot.main ? PlayerSlot.coop : PlayerSlot.main;
    final from = _playerFor(fromSlot);
    final to = _playerFor(toSlot);
    if (to.items.any((i) => i.name == item.name)) return false;
    _runState = _replacePlayer(fromSlot,
        from.copyWith(items: from.items.where((i) => i.name != item.name).toList()));
    _runState = _replacePlayer(toSlot, to.copyWith(items: [...to.items, item]));
    _saveRun();
    notifyListeners();
    return true;
  }

  // --- Coolness / curse --------------------------------------------------

  void adjustCoolness(double delta) {
    _runState = _runState.copyWith(
      coolness: (_runState.coolness + delta).clamp(-100.0, 100.0),
    );
    _saveRun();
    notifyListeners();
  }

  void adjustCurse(double delta) {
    _runState = _runState.copyWith(
      curse: (_runState.curse + delta).clamp(-100.0, 100.0),
    );
    _saveRun();
    notifyListeners();
  }

  void resetManualStats() {
    _runState = _runState.copyWith(coolness: 0, curse: 0);
    _saveRun();
    notifyListeners();
  }

  // --- Shrine activation -------------------------------------------------

  /// Result of activating a shrine. [applied] holds the concrete
  /// adjustments (curse/coolness delta strings) we made automatically.
  /// [manual] holds human-readable reminders of things only the player
  /// can perform in-game (heart container loss, companion pickup, etc.).
  ShrineApplyResult applyShrine(Shrine s) {
    final applied = <String>[];
    final manual = <String>[];

    double curseDelta = s.curse;
    double coolDelta = s.coolness;

    // Special-case shrines whose JSON delta can't express their real
    // semantics. These override the naive curse/coolness values.
    final name = s.name.toLowerCase();
    if (name == 'cleanse') {
      // Sets curse to 0 (full cleanse; cost is gold, untracked).
      curseDelta = -_runState.curse;
      manual.add('Costs 5 coin per point of curse cleansed');
    } else if (name == 'hero') {
      // Only usable if current curse < 9 and past defeated.
      if (_runState.curse < 9) {
        curseDelta = 9 - _runState.curse;
      } else {
        manual.add('Already at curse 9+ — shrine has no effect');
      }
      manual.add('Requires defeating your character\'s past');
    } else if (name == 'ammo') {
      manual.add('Weapons ammo refilled');
    } else if (name == 'angel') {
      manual.add('Lose 1 heart container · +25% damage');
    } else if (name == 'blood') {
      manual.add('Lose 1 heart container · damaging aura near highlighted enemies');
    } else if (name == 'companion') {
      manual.add('Lose 1 heart container · pick up the familiar item in Browse');
    } else if (name == 'challenge') {
      manual.add('Survive 3 enemy waves → chest');
    } else if (name == 'dice') {
      manual.add('Roll 1 good + 1 bad effect — adjust loot / HP yourself');
    } else if (name == 'glass') {
      manual.add('Gain 3 Glass Guon Stones');
    } else if (name == 'junk') {
      manual.add('Trade Junk → 1 armor');
    } else if (name == 'peace') {
      manual.add('Trade held gun → 1 heart');
    } else if (name == 'blank') {
      manual.add('Use a blank nearby → 90% chest spawn');
    } else if (name == 'beholster') {
      manual.add('Deposit the 6 required guns across runs');
    } else if (name == 'y.v.') {
      manual.add('Costs 10+ coin · future shots may fire 2-4 times');
    }

    if (curseDelta != 0) {
      adjustCurse(curseDelta);
      final sign = curseDelta > 0 ? '+' : '';
      applied.add('Curse $sign${curseDelta.toStringAsFixed(1)}');
    }
    if (coolDelta != 0) {
      adjustCoolness(coolDelta);
      final sign = coolDelta > 0 ? '+' : '';
      applied.add('Coolness $sign${coolDelta.toStringAsFixed(1)}');
    }

    // Record in run-log so summary tracks usage count
    _runState = _runState.copyWith(
      shrinesUsed: [..._runState.shrinesUsed, s.name],
    );
    _saveRun();
    notifyListeners();

    return ShrineApplyResult(shrine: s, applied: applied, manual: manual);
  }

  // --- Synergies ---------------------------------------------------------

  List<Synergy> getActiveSynergies() {
    final itemNames = _runState.main.allItemNames;
    return _allSynergies.where((s) => s.matchesItems(itemNames)).toList();
  }

  List<Synergy> getSynergiesFor(String itemName) {
    final lower = itemName.toLowerCase();
    return _allSynergies
        .where((s) =>
            s.items.any((i) => i.toLowerCase() == lower) ||
            s.anyOf.any((i) => i.toLowerCase() == lower))
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
    final related = _allSynergies.where((s) =>
        s.items.any((i) => i.toLowerCase() == lower) ||
        s.anyOf.any((i) => i.toLowerCase() == lower));
    final synergies = related.map((s) {
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

  // --- Queries ------------------------------------------------------------

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
    final total = guns.map((g) => g.getDynamicDps(
      gunderLevel: _gunderfuryLevel,
      tripleForm: _tripleGunForm,
      evolverStage: _evolverForm,
    )).fold<double>(0, (a, b) => a + b);
    return total / guns.length;
  }

  double get avgDps => _avgDpsFor(_runState.main.guns);
  double get avgDpsCoop => _avgDpsFor(_runState.coop?.guns ?? const []);

  // --- Combined (both-player) metrics for Summary page ------------------

  List<Gun> get _allGunsInRun => [
        ..._runState.main.guns,
        ...?_runState.coop?.guns,
      ];

  List<Item> get _allItemsInRun => [
        ..._runState.main.items,
        ...?_runState.coop?.items,
      ];

  double get combinedAvgDps => _avgDpsFor(_allGunsInRun);

  double get combinedSumDps =>
      _allGunsInRun.map((g) => g.getDynamicDps(
        gunderLevel: _gunderfuryLevel,
        tripleForm: _tripleGunForm,
        evolverStage: _evolverForm,
      )).fold<double>(0, (a, b) => a + b);

  /// Parse "123", "N/A", "" to an int (0 on fail).
  int _parsePrice(String s) {
    if (s.isEmpty || s.toLowerCase() == 'n/a') return 0;
    final digits = RegExp(r'\d+').firstMatch(s)?.group(0);
    return int.tryParse(digits ?? '') ?? 0;
  }

  /// Combined sell-price total across both players' guns + items.
  int get combinedTotalWorth {
    int total = 0;
    for (final g in _allGunsInRun) { total += _parsePrice(g.sellPrice); }
    for (final i in _allItemsInRun) { total += _parsePrice(i.sellPrice); }
    return total;
  }

  /// Quality points: S/1S=5, A=4, B=3, C=2, D=1, N/other=0.
  int _qualityPoints(String q) {
    switch (q.toUpperCase()) {
      case 'S':
      case '1S':
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
    for (final g in _allGunsInRun) { s += _qualityPoints(g.quality); }
    for (final i in _allItemsInRun) { s += _qualityPoints(i.quality); }
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

  /// Count of each quality tier across both players (normalises 1S→S).
  Map<String, int> get combinedQualityBreakdown {
    final out = <String, int>{'S': 0, 'A': 0, 'B': 0, 'C': 0, 'D': 0, 'N': 0};
    String normal(String q) =>
        q.toUpperCase() == '1S' ? 'S' : q.toUpperCase();
    for (final g in _allGunsInRun) {
      final k = normal(g.quality);
      if (out.containsKey(k)) out[k] = out[k]! + 1;
    }
    for (final i in _allItemsInRun) {
      final k = normal(i.quality);
      if (out.containsKey(k)) out[k] = out[k]! + 1;
    }
    return out;
  }

  /// The single highest-DPS gun across the run, and which slot owns it.
  ({Gun gun, PlayerSlot slot})? get topGunAcross {
    Gun? best;
    PlayerSlot? bestSlot;
    double bestDps = -1;
    for (final g in _runState.main.guns) {
      final dpsVal = g.getDynamicDps(
        gunderLevel: _gunderfuryLevel,
        tripleForm: _tripleGunForm,
        evolverStage: _evolverForm,
      );
      if (dpsVal > bestDps) {
        bestDps = dpsVal;
        best = g;
        bestSlot = PlayerSlot.main;
      }
    }
    for (final g in _runState.coop?.guns ?? const <Gun>[]) {
      final dpsVal = g.getDynamicDps(
        gunderLevel: _gunderfuryLevel,
        tripleForm: _tripleGunForm,
        evolverStage: _evolverForm,
      );
      if (dpsVal > bestDps) {
        bestDps = dpsVal;
        best = g;
        bestSlot = PlayerSlot.coop;
      }
    }
    if (best == null || bestDps <= 0) return null;
    return (gun: best, slot: bestSlot!);
  }

  /// How many distinct synergies touch ANY owned item (required or any_of)
  /// across both players. Represents the synergy "design space" this run
  /// has opened up — more is more fun to chase.
  int get combinedSynergyPotential {
    final owned = <String>{
      for (final g in _allGunsInRun) g.name.toLowerCase(),
      for (final i in _allItemsInRun) i.name.toLowerCase(),
    };
    if (owned.isEmpty) return 0;
    int n = 0;
    for (final s in _allSynergies) {
      final hits = s.items.any((i) => owned.contains(i.toLowerCase())) ||
          s.anyOf.any((i) => owned.contains(i.toLowerCase()));
      if (hits) n++;
    }
    return n;
  }

  /// Full-run active synergies (looks across BOTH players' inventories).
  List<Synergy> getActiveSynergiesCombined() {
    final names = _runState.allItemNames; // main + coop
    return _allSynergies.where((s) => s.matchesItems(names)).toList();
  }

  /// Maps every item/gun name (lowercased) that participates in a currently
  /// active synergy to a vivid, deterministic Color for that synergy.
  /// Considers BOTH players' inventories so co-op synergies light up too.
  /// Returns an empty map when no synergies are active.
  Map<String, Color> get activeSynergyGlowColors {
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

  /// Loadout composition per-slot: guns, actives, passives, companions.
  ({int guns, int actives, int passives, int companions}) composition(
      PlayerSlot slot) {
    final p = slot == PlayerSlot.main ? _runState.main : _runState.coop;
    if (p == null) {
      return (guns: 0, actives: 0, passives: 0, companions: 0);
    }
    int a = 0, pv = 0, c = 0;
    for (final it in p.items) {
      if (it.isCompanion) {
        c++;
      } else if (it.isActive) {
        a++;
      } else if (it.isPassive) {
        pv++;
      }
    }
    return (guns: p.guns.length, actives: a, passives: pv, companions: c);
  }

  Map<String, int>? _synergyCountCache;
  int synergyCountFor(String itemName) {
    _synergyCountCache ??= _buildSynergyCountCache();
    return _synergyCountCache![itemName.toLowerCase()] ?? 0;
  }

  Map<String, int> _buildSynergyCountCache() {
    final map = <String, int>{};
    for (final s in _allSynergies) {
      final seen = <String>{};
      for (final i in s.items) { seen.add(i.toLowerCase()); }
      for (final i in s.anyOf) { seen.add(i.toLowerCase()); }
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
