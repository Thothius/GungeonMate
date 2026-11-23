import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/models/gungeoneer.dart';
import 'package:gungeon_mate/providers/run_provider.dart';

/// Continue Run persistence contract:
///   - an unfinished run survives app restart (last run always saved)
///   - a launch-restored run sets `runRestoredFromSave` so the menu can
///     offer Continue instead of auto-entering
///   - deliberate `endRun()` clears the resumable candidate
///   - `startNewRun()` replaces the parked save (flag resets)
///   - corrupt/empty saves never produce a Continue offer
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<RunProvider> boot() async {
    final rp = RunProvider();
    await rp.loadData();
    return rp;
  }

  test('fresh install — no save → no Continue offer', () async {
    SharedPreferences.setMockInitialValues({});
    final rp = await boot();
    expect(rp.runRestoredFromSave, isFalse);
    expect(rp.runState.selectedCharacter, isNull);
  });

  test('unfinished run survives restart → Continue offer on next boot',
      () async {
    SharedPreferences.setMockInitialValues({});

    // Session 1: start a run and let it autosave.
    final rp1 = await boot();
    rp1.startNewRun(Gungeoneer(name: 'The Marine'));
    await rp1.saveRun();
    rp1.dispose();

    // Session 2 (app restart): the save restores AND flags the offer.
    final rp2 = await boot();
    expect(rp2.runRestoredFromSave, isTrue);
    expect(rp2.runState.selectedCharacter?.name, 'The Marine');
    rp2.dispose();
  });

  test('deliberate endRun clears the resumable save', () async {
    SharedPreferences.setMockInitialValues({});

    final rp1 = await boot();
    rp1.startNewRun(Gungeoneer(name: 'The Marine'));
    await rp1.saveRun();
    rp1.dispose();

    // Session 2: restore, then END RUN from the menu path.
    final rp2 = await boot();
    expect(rp2.runRestoredFromSave, isTrue);
    rp2.endRun();
    await rp2.saveRun();
    rp2.dispose();

    // Session 3: nothing left to continue.
    final rp3 = await boot();
    expect(rp3.runRestoredFromSave, isFalse);
    expect(rp3.runState.selectedCharacter, isNull);
    rp3.dispose();
  });

  test('startNewRun replaces the parked save — no stale Continue', () async {
    SharedPreferences.setMockInitialValues({});

    final rp1 = await boot();
    rp1.startNewRun(Gungeoneer(name: 'The Marine'));
    await rp1.saveRun();
    rp1.dispose();

    final rp2 = await boot();
    expect(rp2.runRestoredFromSave, isTrue);

    // User picks Local Run instead of Continue.
    rp2.startNewRun(Gungeoneer(name: 'The Pilot'));
    expect(rp2.runRestoredFromSave, isFalse);
    await rp2.saveRun();
    rp2.dispose();

    // Next boot restores the NEW run, not the parked one.
    final rp3 = await boot();
    expect(rp3.runRestoredFromSave, isTrue);
    expect(rp3.runState.selectedCharacter?.name, 'The Pilot');
    rp3.dispose();
  });

  test('corrupt save → no Continue offer (flag stays false)', () async {
    SharedPreferences.setMockInitialValues({
      'current_run': '{this is not json',
      'current_run_backup': '{also broken',
    });
    final rp = await boot();
    expect(rp.saveWasCorrupt, isTrue);
    expect(rp.runRestoredFromSave, isFalse);
    rp.dispose();
  });

  test('persisted empty run state → no Continue offer', () async {
    SharedPreferences.setMockInitialValues({});

    // Simulate the post-endRun persisted state: a valid RunState JSON
    // with no character (what endRun's save actually writes).
    final rp1 = await boot();
    rp1.endRun();
    await rp1.saveRun();
    rp1.dispose();

    final rp2 = await boot();
    expect(rp2.runRestoredFromSave, isFalse);
    expect(rp2.runState.selectedCharacter, isNull);
    rp2.dispose();
  });
}
