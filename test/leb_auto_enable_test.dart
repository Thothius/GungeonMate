import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/models/item.dart';
import 'package:gungeon_mate/models/player.dart';
import 'package:gungeon_mate/models/synergy.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/app_theme.dart';
import 'package:gungeon_mate/widgets/item_detail/gun_synergies_tab.dart';

/// Lich's Eye Bullets lifecycle — the simulated-synergy view must
/// auto-enable when LEB actually enters a run (Gunslinger starter or
/// mid-run pickup) while staying a manual on/off toggle afterwards.
/// Also pins the LEB eligibility rules: pure dual-wield synergies are
/// never simulated (Trigger Twins excepted) and 3+-piece synergies
/// still need real components alongside LEB.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RunProvider p;
  late Item leb;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    p = RunProvider();
    await p.loadData();
    leb = p.itemByName("Lich's Eye Bullets")!;
  });

  setUp(() {
    p.endRun();
    VisualPrefs.notifier.value = const VisualPrefs();
  });

  ({String name, bool hasLeb}) nonLebCharacter() {
    for (final c in p.allGungeoneers) {
      if (!c.startingItems.contains("Lich's Eye Bullets")) {
        return (name: c.name, hasLeb: false);
      }
    }
    throw StateError('no non-LEB character in catalog');
  }

  // --- auto-enable on acquisition -------------------------------------

  test('Gunslinger starter LEB auto-enables both LEB views', () async {
    await VisualPrefs.setShowLichEyeBulletsSynergies(false);
    await VisualPrefs.setBrowseShowLichEyeBullets(false);
    final gunslinger = p.allGungeoneers.firstWhere(
      (c) => c.name == 'The Gunslinger',
    );
    p.startNewRun(gunslinger);

    expect(p.playerHasLeb(PlayerSlot.main), isTrue);
    expect(VisualPrefs.notifier.value.showLichEyeBulletsSynergies, isTrue);
    expect(VisualPrefs.notifier.value.browseShowLichEyeBullets, isTrue);
  });

  test('non-LEB starter does not flip the views on', () async {
    await VisualPrefs.setShowLichEyeBulletsSynergies(false);
    await VisualPrefs.setBrowseShowLichEyeBullets(false);
    final c = nonLebCharacter();
    p.startNewRun(p.allGungeoneers.firstWhere((g) => g.name == c.name));

    expect(p.playerHasLeb(PlayerSlot.main), isFalse);
    expect(VisualPrefs.notifier.value.showLichEyeBulletsSynergies, isFalse);
    expect(VisualPrefs.notifier.value.browseShowLichEyeBullets, isFalse);
  });

  test('picking up LEB mid-run auto-enables both views', () async {
    await VisualPrefs.setShowLichEyeBulletsSynergies(false);
    await VisualPrefs.setBrowseShowLichEyeBullets(false);
    final c = nonLebCharacter();
    p.startNewRun(p.allGungeoneers.firstWhere((g) => g.name == c.name));
    expect(VisualPrefs.notifier.value.showLichEyeBulletsSynergies, isFalse);

    p.addItem(leb, slot: PlayerSlot.main);
    // Setters are async (persist) — the notifier flips synchronously.
    expect(p.playerHasLeb(PlayerSlot.main), isTrue);
    expect(VisualPrefs.notifier.value.showLichEyeBulletsSynergies, isTrue);
    expect(VisualPrefs.notifier.value.browseShowLichEyeBullets, isTrue);
  });

  test('unrelated pickup does NOT re-enable a manual toggle-off', () async {
    await VisualPrefs.setShowLichEyeBulletsSynergies(false);
    await VisualPrefs.setBrowseShowLichEyeBullets(false);
    final c = nonLebCharacter();
    p.startNewRun(p.allGungeoneers.firstWhere((g) => g.name == c.name));
    p.addItem(leb, slot: PlayerSlot.main);
    expect(VisualPrefs.notifier.value.showLichEyeBulletsSynergies, isTrue);

    // User manually turns the simulated view off.
    await VisualPrefs.setShowLichEyeBulletsSynergies(false);
    await VisualPrefs.setBrowseShowLichEyeBullets(false);

    // Picking up something else must not fight the manual choice.
    final other = p.allItems.firstWhere((i) => i.name != leb.name);
    p.addItem(other, slot: PlayerSlot.main);
    expect(VisualPrefs.notifier.value.showLichEyeBulletsSynergies, isFalse);
  });

  test('removing then re-adding LEB counts as a fresh acquisition', () async {
    await VisualPrefs.setShowLichEyeBulletsSynergies(false);
    await VisualPrefs.setBrowseShowLichEyeBullets(false);
    final c = nonLebCharacter();
    p.startNewRun(p.allGungeoneers.firstWhere((g) => g.name == c.name));
    p.addItem(leb, slot: PlayerSlot.main);
    await VisualPrefs.setShowLichEyeBulletsSynergies(false);

    p.removeItem(leb, slot: PlayerSlot.main);
    expect(p.playerHasLeb(PlayerSlot.main), isFalse);

    p.addItem(leb, slot: PlayerSlot.main);
    expect(VisualPrefs.notifier.value.showLichEyeBulletsSynergies, isTrue);
  });

  test('co-op: LEB on either slot enables; playerHasLeb is per-slot', () async {
    await VisualPrefs.setShowLichEyeBulletsSynergies(false);
    await VisualPrefs.setBrowseShowLichEyeBullets(false);
    final chars = p.allGungeoneers;
    final main = chars.firstWhere((c) => !c.startingItems.contains("Lich's Eye Bullets"));
    final coop = chars.firstWhere((c) => c.name != main.name);
    p.startNewRun(main);
    p.startCoopPlayer(coop);
    p.addItem(leb, slot: PlayerSlot.coop);

    expect(p.playerHasLeb(PlayerSlot.coop), isTrue);
    expect(p.playerHasLeb(PlayerSlot.main), isFalse);
    expect(VisualPrefs.notifier.value.showLichEyeBulletsSynergies, isTrue);
  });

  // --- LEB eligibility rules ------------------------------------------

  Synergy synergyNamed(String name) =>
      p.allSynergies.firstWhere((s) => s.name == name);

  Synergy findTwoPiece() {
    for (final s in p.allSynergies) {
      if (s.items.length == 2 &&
          s.anyOf.isEmpty &&
          s.groups.isEmpty) {
        return s;
      }
    }
    throw StateError('no plain 2-piece synergy in catalog');
  }

  test('pure dual-wield synergies are excluded from LEB simulation', () {
    for (final name in [
      'Blammo!',
      'Assault and Battery',
      'Circle of Bricks',
      'Cold 1896',
      'Detective Magnum',
      'Heavy Artillery',
      'I Studied The Blade',
      'The Killing Joke',
      'Love/Hate',
      'No Odd Job',
      'The Submachinist',
    ]) {
      expect(
        isLebExcludedSynergy(synergyNamed(name)),
        isTrue,
        reason: '$name is a dual-wield synergy LEB cannot simulate',
      );
    }
  });

  test('Trigger Twins stays simulated — non-wield bonuses still apply', () {
    expect(isLebExcludedSynergy(synergyNamed('Trigger Twins')), isFalse);
  });

  test('named hard exclusions remain excluded', () {
    for (final name in [
      'Rubenstein\'s Monster',
      'Detective Mode',
    ]) {
      expect(isLebExcludedSynergy(synergyNamed(name)), isTrue);
    }
  });

  test('3+-piece synergies need real components alongside LEB', () {
    // LEB counts as ONE piece — these can't be satisfied by LEB alone.
    expect(lebNeedsRealPieces(synergyNamed('Resourceful Indeed')), isTrue);
    expect(lebNeedsRealPieces(synergyNamed('Behold!')), isTrue);
    expect(lebNeedsRealPieces(synergyNamed('Cormorant')), isTrue);
    expect(lebNeedsRealPieces(synergyNamed('In The Mood!')), isTrue);
    expect(
      lebNeedsRealPieces(synergyNamed('Mmmmmmmmm MMMMmm!')),
      isTrue,
    );
    // Ordinary 2-piece synergies are fully simulated.
    final pair = findTwoPiece();
    expect(lebNeedsRealPieces(pair), isFalse);
  });

  test('lebSlotsNeeded counts groups as single slots', () {
    // Resourceful Indeed: Elimentaler + any-of rat pool = group model.
    final s = synergyNamed('Resourceful Indeed');
    expect(lebSlotsNeeded(s), greaterThanOrEqualTo(3));
  });
}
