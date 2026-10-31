part of 'run_provider.dart';

// Extracted from run_provider.dart (Phase 4c) — same library, zero
// import churn. Abstract members are requirements on RunProvider.

mixin _RunPersistence on ChangeNotifier {
  RunState get _runState;
  set _runState(RunState s);

  /// Names of guns/items the user has favourited. Shared across runs
  /// and both players. Persisted independently of run state so starring
  /// stuff in one run carries over to the next.
  final Set<String> _favourites = <String>{};

  /// Last played character name — persists across run end and app kill.
  /// Used by the home screen fall animation to show the right sprite.
  String _lastPlayedCharName = '';

  /// Debounce timer for _saveRun — batches rapid successive saves
  /// (e.g. adding multiple guns) into a single disk write.
  Timer? _saveDebounce;

  /// Public manual save — triggers the same persistence as [_saveRun]
  /// but can be called from the UI for a "Save Run" button.
  Future<void> saveRun() => _saveRun();

  /// Debounced save — batches rapid successive state changes into a
  /// single disk write after 400ms of quiet. This prevents 28+
  /// individual SharedPreferences writes when adding/removing items.
  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 400), () {
      _saveRun();
    });
  }

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

  Future<void> _loadLastPlayedChar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastPlayedCharName = prefs.getString('last_played_character') ?? '';
    } catch (e) {
      // Removed debugPrint for production
    }
  }

  Future<void> _saveLastPlayedChar(String name) async {
    _lastPlayedCharName = name;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_played_character', name);
    } catch (e) {
      // Removed debugPrint for production
    }
  }

  /// Public hook for MP character selection to persist the last played
  /// character without starting a full run.
  void saveLastPlayedCharacter(String name) => _saveLastPlayedChar(name);

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
    _scheduleSave();
    notifyListeners();
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

  int get favouritesCount => _favourites.length;
}
