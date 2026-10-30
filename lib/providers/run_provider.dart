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
import 'dart:math' as math;
import '../models/run_state.dart';
import '../models/run_log_entry.dart';
part 'synergy_queries.dart';
part 'trackers/special_trackers.dart';
part 'run_persistence.dart';
part 'run_stats.dart';

// ── Isolate parse helpers ──────────────────────────────────────
// Top-level functions for compute() — can't be closures or instance
// methods. Each takes the raw JSON string and returns the parsed list.
List<Gun> _parseGuns(String jsonStr) =>
    (json.decode(jsonStr) as List).map((g) => Gun.fromJson(g)).toList();
List<Item> _parseItems(String jsonStr) =>
    (json.decode(jsonStr) as List).map((i) => Item.fromJson(i)).toList();
List<Synergy> _parseSynergies(String jsonStr) =>
    (json.decode(jsonStr) as List).map((s) => Synergy.fromJson(s)).toList();
List<Shrine> _parseShrines(String jsonStr) =>
    (json.decode(jsonStr) as List).map((s) => Shrine.fromJson(s)).toList();
List<Gungeoneer> _parseGungeoneers(String jsonStr) =>
    (json.decode(jsonStr) as List).map((g) => Gungeoneer.fromJson(g)).toList();

class RunProvider
    with
        ChangeNotifier,
        _SpecialTrackers,
        _SynergyQueries,
        _RunPersistence,
        _RunStats {
  @override
  RunState _runState = RunState();

  List<Gun> _allGuns = [];
  List<Item> _allItems = [];
  @override
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

  // Shellegun mode: 1 = Pistol (manual), 2 = Pistol (auto), 3 = Beam

  // Chamber Gun floor index: 0 = Keep of the Lead Lord, 1 = Oubliette,
  // 2 = Gungeon Proper, 3 = Abbey, 4 = Black Powder Mine, 5 = Rat's Lair,
  // 6 = Hollow, 7 = R&G Dept, 8 = Forge, 9 = Bullet Hell

  // Platinum Bullets: approximate firing time in seconds

  // Iron Coin: 3 uses per run

  // Polaris: kill count and damage-taken penalty
  // Level 1: 0-10 kills, Level 2: 11-30, Level 3: 31+. Taking damage drops level.

  // Gunther: friendship points (rooms cleared with chance to gain friendship)
  // Stage 1: 0-2, Stage 2: 3-5, Stage 3: 6+

  // Gun Soul: death/respawn state
  // false = normal, true = died and respawned (soul must be reclaimed)

  // Sprun mystery trigger: -1 = not yet revealed for this run,
  // 0..4 = index into the possible trigger list shown in the tracker.

  // Payday crew: which of Clown Mask / Drill / Loot Bag the user has
  // manually marked as "crew active" is derived from inventory, no state.

  // The Robot special features

  // The Huntress special features

  // Metronome: kill streak counter (+2% dmg per kill, max 75 kills = +150%)

  // Boxing Glove: star counter (0-3, 3 stars = charged super punch)

  // Cigarettes: use counter (coolness +1 per use)

  bool _isLoading = true;
  String? _error;

  RunState get runState => _runState;
  List<Gun> get allGuns => _allGuns;
  List<Item> get allItems => _allItems;
  List<Synergy> get allSynergies => _allSynergies;

  /// Log entries relevant to curse: pickups with curse, steals, shrines,
  /// manual adjustments, plus synergy/transfer context entries.
  List<RunLogEntry> get curseLog =>
      _runState.log
          .where(
            (e) =>
                e.affectsCurse ||
                e.category == RunLogCategory.synergy ||
                e.category == RunLogCategory.transfer,
          )
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  /// Log entries relevant to coolness: pickups with coolness, cigs, shrines,
  /// manual adjustments, plus synergy/transfer context entries.
  List<RunLogEntry> get coolnessLog =>
      _runState.log
          .where(
            (e) =>
                e.affectsCoolness ||
                e.category == RunLogCategory.synergy ||
                e.category == RunLogCategory.transfer,
          )
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  List<Shrine> get allShrines => _allShrines;
  List<Gungeoneer> get allGungeoneers => _allGungeoneers;

  /// The last played character, or null if no history exists.
  /// Persists across run end and app kill — only updates when a new
  /// character is picked for SP or MP.
  Gungeoneer? get lastPlayedCharacter =>
      _lastPlayedCharName.isEmpty
          ? null
          : gungeoneerByName(_lastPlayedCharName);
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

      // Load all JSON files in parallel — much faster than sequential
      // awaits on slow storage / first asset bundle read.
      final jsonResults = await Future.wait([
        rootBundle.loadString('assets/data/guns.json'),
        rootBundle.loadString('assets/data/items.json'),
        rootBundle
            .loadString('assets/data/synergies.json')
            .catchError((_) => ''),
        rootBundle.loadString('assets/data/shrines.json').catchError((_) => ''),
        rootBundle
            .loadString('assets/data/gungeoneers.json')
            .catchError((_) => ''),
        rootBundle
            .loadString('assets/data/back_refs.json')
            .catchError((_) => ''),
      ]);

      // Parse the core data in parallel isolates.
      final gunsFuture = compute(_parseGuns, jsonResults[0]);
      final itemsFuture = compute(_parseItems, jsonResults[1]);
      _allGuns = await gunsFuture;
      _allItems = await itemsFuture;

      // Parse secondary data in parallel isolates (non-fatal on failure).
      if (jsonResults[2].isNotEmpty) {
        try {
          _allSynergies = await compute(_parseSynergies, jsonResults[2]);
        } catch (_) {
          _allSynergies = [];
        }
      } else {
        _allSynergies = [];
      }

      if (jsonResults[3].isNotEmpty) {
        try {
          _allShrines = await compute(_parseShrines, jsonResults[3]);
        } catch (_) {
          _allShrines = [];
        }
      } else {
        _allShrines = [];
      }

      if (jsonResults[4].isNotEmpty) {
        try {
          _allGungeoneers = await compute(_parseGungeoneers, jsonResults[4]);
        } catch (_) {
          _allGungeoneers = [];
        }
      } else {
        _allGungeoneers = [];
      }

      // Back-refs parsed on main thread (small JSON, fast).
      if (jsonResults[5].isNotEmpty) {
        try {
          _backRefs = BackRefs.fromJsonString(jsonResults[5]);
        } catch (_) {
          _backRefs = BackRefs.empty;
        }
      } else {
        _backRefs = BackRefs.empty;
      }

      // Build O(1) name-lookup indices once everything else is hydrated.
      // Keys are lowercased so callers don't have to normalize at every
      // call-site. Values point at the same Gun/Item/Synergy instances
      // stored in the master lists (no copy).
      _gunsByLowerName = {for (final g in _allGuns) g.name.toLowerCase(): g};
      _itemsByLowerName = {for (final i in _allItems) i.name.toLowerCase(): i};
      _synergiesByLowerName = {
        for (final s in _allSynergies) s.name.toLowerCase(): s,
      };

      // Load persisted prefs in parallel.
      await Future.wait([
        _loadSavedRun(),
        _loadFavourites(),
        _loadSpecialUpgrades(),
        _loadLastPlayedChar(),
      ]);

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
        character: freshChar,
        guns: freshGuns,
        items: freshItems,
      );
    }

    return s.copyWith(
      main: refreshPlayer(s.main),
      coop: s.coop != null ? refreshPlayer(s.coop!) : null,
    );
  }

  /// Append a log entry to the run state. Called by addGun/addItem/adjust*
  /// and manual action methods. Keeps last 200 entries to avoid unbounded
  /// growth on long runs.
  void _log(RunLogEntry entry) {
    final updated = [..._runState.log, entry];
    if (updated.length > 200) {
      _runState = _runState.copyWith(
        log: updated.sublist(updated.length - 200),
      );
    } else {
      _runState = _runState.copyWith(log: updated);
    }
  }

  /// Compares active synergies before & after a pickup/transfer. Logs any
  /// newly-activated synergies as separate log entries.
  void _checkNewSynergies(List<Synergy> before) {
    final after = getActiveSynergiesCombined();
    final beforeNames = before.map((s) => s.name).toSet();
    for (final s in after) {
      if (!beforeNames.contains(s.name)) {
        _log(
          RunLogEntry(
            timestamp: DateTime.now(),
            category: RunLogCategory.synergy,
            description: 'Synergy activated: ${s.name}',
            entityName: s.name,
          ),
        );
      }
    }
  }

  // --- Favourites --------------------------------------------------------

  // --- Last Played Character -----------------------------------------------

  // --- Special Upgrades ----------------------------------------------------

  @override
  void dispose() {
    _windgunnerTimer?.cancel();
    _saveDebounce?.cancel();
    super.dispose();
  }

  /// Resolved Gun objects for the favourited names (preserves insertion
  /// order approximately — actually set-insertion order on Dart is
  /// unordered, so we sort by name for stable UI).
  List<Gun> get favouriteGuns =>
      _allGuns.where((g) => _favourites.contains(g.name)).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  List<Item> get favouriteItems =>
      _allItems.where((i) => _favourites.contains(i.name)).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  // --- Run lifecycle ------------------------------------------------------

  /// Internal: build a freshly-loaded Player for a Gungeoneer, pulling
  /// starting guns/items by name from the master data.
  Player _buildPlayerFor(Gungeoneer character) {
    final rng = math.Random();
    final startingGuns =
        _allGuns.where((g) => character.startingGuns.contains(g.name)).toList();
    final startingItems =
        _allItems
            .where((i) => character.startingItems.contains(i.name))
            .toList();
    // Characters whose starter list is 'Random' (or otherwise resolves
    // empty — e.g. The Paradox/Cultist) get a rolled piece of gear
    // instead of starting with nothing. Matches the in-game Paradox:
    // random loadout, not an empty inventory.
    if (character.startingGuns.any((s) => s.toLowerCase() == 'random') ||
        startingGuns.isEmpty) {
      if (_allGuns.isNotEmpty) {
        startingGuns.add(_allGuns[rng.nextInt(_allGuns.length)]);
      }
    }
    if (character.startingItems.any((s) => s.toLowerCase() == 'random') ||
        startingItems.isEmpty) {
      if (_allItems.isNotEmpty) {
        startingItems.add(_allItems[rng.nextInt(_allItems.length)]);
      }
    }
    return Player(
      character: character,
      guns: startingGuns,
      items: startingItems,
    );
  }

  void startNewRun(Gungeoneer character) {
    _runState = RunState(main: _buildPlayerFor(character));
    _saveLastPlayedChar(character.name);
    _scheduleSave();
    notifyListeners();
  }

  /// One-shot flag for the MP path: on the Sidekick device the coop slot
  /// is built before the host's character arrives via snapshot, so the
  /// paradox-empty rule can't apply in startCoopPlayer. Set once the
  /// first host snapshot reveals a Paradox main — see applyPeerSnapshot.
  bool _paradoxSidekickEmptied = false;

  /// True when the main player is The Paradox. The main player rolls a
  /// random loadout (see _buildPlayerFor), but the sidekick mirrors the
  /// 'Random' fantasy by starting with nothing (user-requested).
  bool get _isParadoxMain => _runState.main.character?.name == 'The Paradox';

  /// Add a second (local co-op) player to the current run.
  void startCoopPlayer(Gungeoneer character) {
    _runState = _runState.copyWith(
      coop:
          _isParadoxMain
              ? Player(character: character)
              : _buildPlayerFor(character),
    );
    _paradoxSidekickEmptied = false;
    _scheduleSave();
    notifyListeners();
  }

  /// Remove the co-op player slot entirely.
  void endCoopPlayer() {
    _runState = _runState.copyWith(clearCoop: true);
    _scheduleSave();
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
    final fresh =
        (slot == PlayerSlot.coop && _isParadoxMain)
            ? Player(character: char)
            : _buildPlayerFor(char);
    _runState = _replacePlayer(slot, fresh);
    _runState = _runState.copyWith(coolness: 0.0, curse: 0.0, shrinesUsed: []);
    _scheduleSave();
    notifyListeners();
  }

  // --- Multiplayer snapshot hooks ----------------------------------------
  // Called only by MpSession when it receives a snapshot from
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
    final guns = gunNames.map((n) => gunByName(n)).whereType<Gun>().toList();
    final items =
        itemNames.map((n) => itemByName(n)).whereType<Item>().toList();
    _runState = _runState.copyWith(
      coop: Player(character: char, guns: guns, items: items),
    );
    _scheduleSave();
    notifyListeners();
  }

  /// Restore the local `main` slot from a previously-captured Player.
  /// Used by the multiplayer Sidekick flow when the user cancels the
  /// session: their pre-MP solo run was overwritten by the peer's
  /// snapshot, and this hands it back unchanged. Pass `Player()` to
  /// clear the slot when the user had no solo run.
  void restoreMainSlot(Player main) {
    _runState = _runState.copyWith(main: main);
    _scheduleSave();
    notifyListeners();
  }

  /// Reset the main slot to a fresh character with starting loadout,
  /// preserving the coop slot and all shared state (coolness, curse,
  /// shrines). Used by MP recovery when the saved character doesn't
  /// match the loaded one — we need the correct character's starting
  /// loadout, not the wrong character's guns/items.
  void resetMainToCharacter(Gungeoneer character) {
    final freshPlayer = _buildPlayerFor(character);
    _runState = _runState.copyWith(main: freshPlayer);
    _saveLastPlayedChar(character.name);
    _scheduleSave();
    notifyListeners();
  }

  /// Restore the entire run state atomically (used when loading a saved multiplayer session).
  void restoreEntireRunState(RunState state) {
    _runState = state;
    _scheduleSave();
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
    // Guard: if the peer sends an empty character name, don't
    // overwrite our slot with a null character. This happens when
    // the peer restarts and their run state hasn't been restored
    // yet — they broadcast a snapshot with an empty character.
    // Without this guard, the receiver's main slot gets nulled →
    // blank "No inventory loaded" screen.
    if (characterName.isEmpty) return;

    final char = gungeoneerByName(characterName);
    // Don't use toSet() — it collapses stackable items like Junk.
    // Resolve names directly, preserving duplicates and order.
    final guns = gunNames.map((n) => gunByName(n)).whereType<Gun>().toList();
    final items =
        itemNames.map((n) => itemByName(n)).whereType<Item>().toList();

    // CRITICAL: If the character can't be found (e.g. data not loaded
    // yet, or character name mismatch between devices), do NOT wipe
    // an existing valid character with a null one. That would wipe
    // selectedCharacter (main.character) and flip the HomeScreen to
    // MainMenu — the user sees "blank view" (particles but no run UI).
    // Instead, preserve the existing character and only update
    // guns/items. If there's no existing character, still create the
    // player (backward compatible with tests that expect slot population).
    if (char == null) {
      final existing = targetMainSlot ? _runState.main : _runState.coop;
      final existingChar = existing?.character;
      if (existingChar != null) {
        // Preserve existing character, update guns/items only.
        final player = Player(
          character: existingChar,
          guns: guns,
          items: items,
        );
        if (targetMainSlot) {
          _runState = _runState.copyWith(main: player);
        } else {
          _runState = _runState.copyWith(coop: player);
        }
        _scheduleSave();
        notifyListeners();
        return;
      }
      // No existing character — fall through to create player with
      // null character. This maintains backward compatibility.
    }

    final player = Player(character: char, guns: guns, items: items);

    if (targetMainSlot) {
      // Sidekick receiving host's data → main slot.
      _runState = _runState.copyWith(main: player);
      // Paradox rule (MP): the coop slot was built before the host's
      // character was known, so it still holds real starters. Clear it
      // once when the first snapshot reveals a Paradox main — mirrors
      // the local startCoopPlayer behaviour.
      if (char?.name == 'The Paradox' &&
          !_paradoxSidekickEmptied &&
          _runState.coop != null) {
        _paradoxSidekickEmptied = true;
        _runState = _runState.copyWith(
          coop: Player(character: _runState.coop!.character),
        );
      }
    } else {
      // Main receiving joiner's data → coop slot.
      _runState = _runState.copyWith(coop: player);
    }
    _scheduleSave();
    notifyListeners();
  }

  /// Overwrite shared dungeon state (coolness / curse / shrines used)
  /// with values from a peer snapshot. Only called for snapshots from
  /// the Main Player (Main-authoritative model). Sidekick snapshots
  /// carry shared-state fields but they are ignored by Main.
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
    _scheduleSave();
    notifyListeners();
  }

  /// Apply a signed delta to shared dungeon state. Used by the Main
  /// Player when it receives an [MpSharedStateDelta] from the
  /// Sidekick. The delta is applied silently (no log entry) — the
  /// Sidekick already logged the action locally. After applying, Main
  /// broadcasts a snapshot so both sides converge.
  void applySharedStateDelta({
    double coolnessDelta = 0,
    double curseDelta = 0,
    String? shrineName,
  }) {
    _runState = _runState.copyWith(
      coolness: (_runState.coolness + coolnessDelta).clamp(-100.0, 100.0),
      curse: (_runState.curse + curseDelta).clamp(-100.0, 100.0),
      shrinesUsed:
          shrineName != null && shrineName.isNotEmpty
              ? [..._runState.shrinesUsed, shrineName]
              : _runState.shrinesUsed,
    );
    _scheduleSave();
    notifyListeners();
  }

  /// Run-scoped special-gear state: per-run in-game, so a fresh run
  /// starts them clean. Gunderfury level is the exception — its XP is
  /// save-file permanent and survives across runs (by design).
  void _resetRunScopedSpecials() {
    _tripleGunForm = 1;
    _evolverForm = 1;
    _evolverKills = 0;
    _shellegunMode = 1;
    _chamberGunFloor = 0;
    _platinumBulletsSeconds = 0;
    _ironCoinUses = 3;
    _polarisKills = 0;
    _polarisDamageHits = 0;
    _guntherFriendship = 0;
    _gunSoulActivated = false;
    _metronomeKills = 0;
    _boxingGloveStars = 0;
    _cigarettesUses = 0;
    _sprunTriggerIndex = -1;
    _windgunnerCountdown = 0;
    _windgunnerTimer?.cancel();
    _spiceUsageCount = 0;
    _robotArmor = 6;
    _robotJunk = 0;
    _robotGoldJunk = false;
    _robotLies = false;
    _fireplaceExtinguished = false;
    _batteryBulletsSynergy = false;
    _fuseDisarmer = false;
    _huntressRoomClears = 0;
    _huntressInjured = false;
    _persistAllSpecials();
  }

  /// One-shot rewrite of every special.* prefs key — used after a bulk
  /// reset so a reload doesn't resurrect the old counters.
  Future<void> _persistAllSpecials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('special.triple_gun.form', _tripleGunForm);
      await prefs.setInt('special.evolver.form', _evolverForm);
      await prefs.setInt('special.evolver.kills', _evolverKills);
      await prefs.setInt('special.shellegun.mode', _shellegunMode);
      await prefs.setInt('special.chambergun.floor', _chamberGunFloor);
      await prefs.setInt('special.platinum.seconds', _platinumBulletsSeconds);
      await prefs.setInt('special.ironcoin.uses', _ironCoinUses);
      await prefs.setInt('special.polaris.kills', _polarisKills);
      await prefs.setInt('special.polaris.hits', _polarisDamageHits);
      await prefs.setInt('special.gunther.friendship', _guntherFriendship);
      await prefs.setBool('special.gunsoul.activated', _gunSoulActivated);
      await prefs.setInt('special.metronome.kills', _metronomeKills);
      await prefs.setInt('special.boxingglove.stars', _boxingGloveStars);
      await prefs.setInt('special.cigarettes.uses', _cigarettesUses);
      await prefs.setInt('special.sprun.trigger', _sprunTriggerIndex);
      await prefs.setInt('special.spice.count', _spiceUsageCount);
      await prefs.setInt('special.robot.armor', _robotArmor);
      await prefs.setInt('special.robot.junk', _robotJunk);
      await prefs.setBool('special.robot.goldjunk', _robotGoldJunk);
      await prefs.setBool('special.robot.lies', _robotLies);
      await prefs.setBool('special.robot.fireplace', _fireplaceExtinguished);
      await prefs.setBool('special.robot.battery', _batteryBulletsSynergy);
      await prefs.setBool('special.robot.fusedisarmer', _fuseDisarmer);
      await prefs.setInt('special.huntress.roomclears', _huntressRoomClears);
      await prefs.setBool('special.huntress.injured', _huntressInjured);
    } catch (e) {
      debugPrint('[RunProvider] special-persist error: $e');
    }
  }

  void endRun() {
    _runState = RunState();
    _resetRunScopedSpecials();
    _scheduleSave();
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

  void addGun(
    Gun gun, {
    PlayerSlot slot = PlayerSlot.main,
    bool force = false,
  }) {
    final p = _playerFor(slot);
    if (!force && p.guns.any((g) => g.name == gun.name)) return;
    final synergyBefore = getActiveSynergiesCombined();
    _runState = _replacePlayer(slot, p.copyWith(guns: [...p.guns, gun]));
    _log(
      RunLogEntry(
        timestamp: DateTime.now(),
        category: RunLogCategory.pickupGun,
        description: 'Picked up ${gun.name}',
        curseDelta: gun.curse,
        coolnessDelta: gun.coolness,
        entityName: gun.name,
        playerName: p.character?.name,
      ),
    );
    _checkNewSynergies(synergyBefore);
    _scheduleSave();
    notifyListeners();
  }

  void removeGun(
    Gun gun, {
    PlayerSlot slot = PlayerSlot.main,
    bool force = false,
  }) {
    final p = _playerFor(slot);
    _runState = _replacePlayer(
      slot,
      p.copyWith(guns: p.guns.where((g) => g.name != gun.name).toList()),
    );
    _log(
      RunLogEntry(
        timestamp: DateTime.now(),
        category: RunLogCategory.removeGun,
        description: 'Removed ${gun.name}',
        curseDelta: -gun.curse,
        coolnessDelta: -gun.coolness,
        entityName: gun.name,
        playerName: p.character?.name,
      ),
    );
    _scheduleSave();
    notifyListeners();
  }

  void addItem(
    Item item, {
    PlayerSlot slot = PlayerSlot.main,
    bool force = false,
  }) {
    final p = _playerFor(slot);
    final isJunk = item.name.toLowerCase() == 'junk';
    if (!force && !isJunk && p.items.any((i) => i.name == item.name)) return;
    final synergyBefore = getActiveSynergiesCombined();
    _runState = _replacePlayer(slot, p.copyWith(items: [...p.items, item]));

    _log(
      RunLogEntry(
        timestamp: DateTime.now(),
        category: RunLogCategory.pickupItem,
        description: 'Picked up ${item.name}',
        curseDelta: item.curse,
        coolnessDelta: item.coolness,
        entityName: item.name,
        playerName: p.character?.name,
      ),
    );
    _checkNewSynergies(synergyBefore);

    // Robot Tax: Automatically convert HP Upgrades and Master Rounds to +1 Armor!
    final charName = p.character?.name.toLowerCase() ?? '';
    if (charName.contains('robot')) {
      final nameLower = item.name.toLowerCase();
      final isHpUp =
          nameLower.contains('master round') ||
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

    _scheduleSave();
    notifyListeners();
  }

  /// Auto-syncs the Robot's Junk damage trackers when Junk-type items
  /// are added to / removed from the inventory.
  void _autoTrackRobotJunk(String nameLower, {required bool added}) {
    final delta = added ? 1 : -1;
    if (nameLower == 'junk' || nameLower == 'sack of junk') {
      setRobotJunk(_robotJunk + delta);
    } else if (nameLower.contains('gold junk') ||
        nameLower.contains('golden junk')) {
      setRobotGoldJunk(added);
    } else if (nameLower == 'lies') {
      setRobotLies(added);
    }
  }

  void removeItem(
    Item item, {
    PlayerSlot slot = PlayerSlot.main,
    bool force = false,
  }) {
    final p = _playerFor(slot);

    _log(
      RunLogEntry(
        timestamp: DateTime.now(),
        category: RunLogCategory.removeItem,
        description: 'Removed ${item.name}',
        curseDelta: -item.curse,
        coolnessDelta: -item.coolness,
        entityName: item.name,
        playerName: p.character?.name,
      ),
    );

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

    _scheduleSave();
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
    final synergyBefore = getActiveSynergiesCombined();
    _runState = _replacePlayer(
      fromSlot,
      from.copyWith(guns: from.guns.where((g) => g.name != gun.name).toList()),
    );
    _runState = _replacePlayer(toSlot, to.copyWith(guns: [...to.guns, gun]));
    _log(
      RunLogEntry(
        timestamp: DateTime.now(),
        category: RunLogCategory.transfer,
        description:
            'Transferred ${gun.name} → ${to.character?.name ?? 'Co-op'}',
        entityName: gun.name,
        playerName: from.character?.name,
      ),
    );
    _checkNewSynergies(synergyBefore);
    _scheduleSave();
    notifyListeners();
    return true;
  }

  bool transferItem(Item item, PlayerSlot fromSlot) {
    if (!hasCoop) return false;
    final toSlot =
        fromSlot == PlayerSlot.main ? PlayerSlot.coop : PlayerSlot.main;
    final from = _playerFor(fromSlot);
    final to = _playerFor(toSlot);
    final isJunk = item.name.toLowerCase() == 'junk';
    // Only block non-junk duplicates — junk is stackable.
    if (!isJunk && to.items.any((i) => i.name == item.name)) return false;
    // Remove only one copy from source (not the whole stack).
    final newFrom = List<Item>.from(from.items);
    final index = newFrom.indexWhere((i) => i.name == item.name);
    if (index == -1) return false;
    newFrom.removeAt(index);
    final synergyBefore = getActiveSynergiesCombined();
    _runState = _replacePlayer(fromSlot, from.copyWith(items: newFrom));
    _runState = _replacePlayer(toSlot, to.copyWith(items: [...to.items, item]));
    _log(
      RunLogEntry(
        timestamp: DateTime.now(),
        category: RunLogCategory.transfer,
        description:
            'Transferred ${item.name} → ${to.character?.name ?? 'Co-op'}',
        entityName: item.name,
        playerName: from.character?.name,
      ),
    );
    _checkNewSynergies(synergyBefore);
    _scheduleSave();
    notifyListeners();
    return true;
  }

  // --- Coolness / curse --------------------------------------------------

  void adjustCoolness(double delta) {
    _runState = _runState.copyWith(
      coolness: (_runState.coolness + delta).clamp(-100.0, 100.0),
    );
    _log(
      RunLogEntry(
        timestamp: DateTime.now(),
        category: RunLogCategory.manual,
        description:
            'Manual coolness ${delta > 0 ? "+" : ""}${delta.toStringAsFixed(1)}',
        coolnessDelta: delta,
      ),
    );
    _scheduleSave();
    notifyListeners();
  }

  void adjustCurse(double delta) {
    _runState = _runState.copyWith(
      curse: (_runState.curse + delta).clamp(-100.0, 100.0),
    );
    _log(
      RunLogEntry(
        timestamp: DateTime.now(),
        category: RunLogCategory.manual,
        description:
            'Manual curse ${delta > 0 ? "+" : ""}${delta.toStringAsFixed(1)}',
        curseDelta: delta,
      ),
    );
    _scheduleSave();
    notifyListeners();
  }

  void resetManualStats() {
    final oldCool = _runState.coolness;
    final oldCurse = _runState.curse;
    _runState = _runState.copyWith(coolness: 0, curse: 0);
    if (oldCool != 0 || oldCurse != 0) {
      _log(
        RunLogEntry(
          timestamp: DateTime.now(),
          category: RunLogCategory.manual,
          description: 'Reset manual stats to 0',
          coolnessDelta: -oldCool,
          curseDelta: -oldCurse,
        ),
      );
    }
    _scheduleSave();
    notifyListeners();
  }

  // --- Manual quick actions (things the app can't auto-detect) ------------

  /// Stealing from a shop — +1 curse per steal in ETG.
  void logSteal() {
    _runState = _runState.copyWith(
      curse: (_runState.curse + 1).clamp(-100.0, 100.0),
    );
    _log(
      RunLogEntry(
        timestamp: DateTime.now(),
        category: RunLogCategory.steal,
        description: 'Stole from a shop (+1 curse)',
        curseDelta: 1,
      ),
    );
    _scheduleSave();
    notifyListeners();
  }

  /// Visiting Cursula — +2.5 curse per visit.
  void logCursula() {
    _runState = _runState.copyWith(
      curse: (_runState.curse + 2.5).clamp(-100.0, 100.0),
    );
    _log(
      RunLogEntry(
        timestamp: DateTime.now(),
        category: RunLogCategory.cursula,
        description: 'Visited Cursula (+2.5 curse)',
        curseDelta: 2.5,
      ),
    );
    _scheduleSave();
    notifyListeners();
  }

  /// Smoking Cigarettes — +1 coolness per use.
  void logSmokeCig() {
    _runState = _runState.copyWith(
      coolness: (_runState.coolness + 1).clamp(-100.0, 100.0),
    );
    _log(
      RunLogEntry(
        timestamp: DateTime.now(),
        category: RunLogCategory.smokeCig,
        description: 'Smoked a cigarette (+1 coolness)',
        coolnessDelta: 1,
      ),
    );
    _scheduleSave();
    notifyListeners();
  }

  /// Rainbow Run reward — +1 coolness.
  void logRainbowRun() {
    _runState = _runState.copyWith(
      coolness: (_runState.coolness + 1).clamp(-100.0, 100.0),
    );
    _log(
      RunLogEntry(
        timestamp: DateTime.now(),
        category: RunLogCategory.rainbowRun,
        description: 'Rainbow Run reward (+1 coolness)',
        coolnessDelta: 1,
      ),
    );
    _scheduleSave();
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
    } else if (name == 'angel' || name == 'fallen angel') {
      manual.add('Lose 1 heart container · +25% damage');
    } else if (name == 'blood') {
      manual.add(
        'Lose 1 heart container · damaging aura near highlighted enemies',
      );
    } else if (name == 'companion') {
      manual.add(
        'Lose 1 heart container · pick up the familiar item in Browse',
      );
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
      _runState = _runState.copyWith(
        curse: (_runState.curse + curseDelta).clamp(-100.0, 100.0),
      );
      final sign = curseDelta > 0 ? '+' : '';
      applied.add('Curse $sign${curseDelta.toStringAsFixed(1)}');
    }
    if (coolDelta != 0) {
      _runState = _runState.copyWith(
        coolness: (_runState.coolness + coolDelta).clamp(-100.0, 100.0),
      );
      final sign = coolDelta > 0 ? '+' : '';
      applied.add('Coolness $sign${coolDelta.toStringAsFixed(1)}');
    }

    // Record in run-log so summary tracks usage count
    _runState = _runState.copyWith(
      shrinesUsed: [..._runState.shrinesUsed, s.name],
    );
    _log(
      RunLogEntry(
        timestamp: DateTime.now(),
        category: RunLogCategory.shrine,
        description: 'Activated ${s.name} shrine',
        curseDelta: curseDelta,
        coolnessDelta: coolDelta,
        entityName: s.name,
      ),
    );
    _scheduleSave();
    notifyListeners();

    return ShrineApplyResult(shrine: s, applied: applied, manual: manual);
  }

  // --- Synergies — extracted to synergy_queries.dart ----------------------

  // --- Queries ------------------------------------------------------------

  // --- Combined (both-player) metrics for Summary page ------------------

  @override
  List<Gun> get _allGunsInRun => [
    ..._runState.main.guns,
    ...?_runState.coop?.guns,
  ];

  @override
  List<Item> get _allItemsInRun => [
    ..._runState.main.items,
    ...?_runState.coop?.items,
  ];

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
        shellegunMode: _shellegunMode,
        chamberGunFloor: _chamberGunFloor,
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
        shellegunMode: _shellegunMode,
        chamberGunFloor: _chamberGunFloor,
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

  /// Loadout composition per-slot: guns, actives, passives, companions.
  ({int guns, int actives, int passives, int companions}) composition(
    PlayerSlot slot,
  ) {
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
}
