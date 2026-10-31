part of 'run_provider.dart';

// Peer-state application — snapshot/restore/delta methods used by the
// MP sync layer to push remote run state into the local RunState.
// Extracted from RunProvider — same library, zero call-site changes.

mixin _PeerSnapshots on ChangeNotifier {
  RunState get _runState;
  set _runState(RunState v);
  void _scheduleSave();
  Gun? gunByName(String name);
  Item? itemByName(String name);
  Gungeoneer? gungeoneerByName(String name);
  Player _buildPlayerFor(Gungeoneer character);
  Future<void> _saveLastPlayedChar(String name);
  bool get _paradoxSidekickEmptied;
  set _paradoxSidekickEmptied(bool v);

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
    final List<String>? shrinesUsed,
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
}
