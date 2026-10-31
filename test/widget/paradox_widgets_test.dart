import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/models/gungeoneer.dart';
import 'package:gungeon_mate/widgets/paradox/paradox_bar.dart';
import 'package:gungeon_mate/widgets/paradox/pause_overlay.dart';
import '../helpers/fake_mp_link.dart';

/// Paradox run-view widgets — MP bar shows session meta, pause overlay
/// reacts to the session's pausedNotifier.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  (MpSession, RunProvider) makeSession() {
    final rp = RunProvider();
    return (MpSession.withLink(rp, FakeMpLink()), rp);
  }

  Widget wrap(MpSession session, RunProvider rp, Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: session),
        ChangeNotifierProvider.value(value: rp),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets('ParadoxBar shows run title', (tester) async {
    // NOTE: ParadoxBar overflows ~15px horizontally at ≤500px width
    // (title cluster + tab dots + icons) — a real narrow-device bug.
    tester.view.physicalSize = const Size(700, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final (session, rp) = makeSession();
    await session.startAsMain(
      nickname: 'T',
      character: rp.gungeoneerByName('The Paradox') ?? Gungeoneer(name: 'The Paradox'),
      avatarId: 'the_paradox',
      runTitle: 'Cursed Hunter of the Deep',
    );

    await tester.pumpWidget(
      wrap(session, rp, ParadoxBar(currentPage: 0, onPick: (_) {})),
    );
    await tester.pump();

    expect(find.textContaining('CURSED HUNTER'), findsWidgets);
    // ParadoxBar: title, timer/health toggles, 2 tab dots.
    // Chat + settings moved to ParadoxPlayerPanel (MSG stat + ⋮ menu).
    expect(find.byIcon(Icons.settings_rounded), findsNothing);
    expect(find.byIcon(Icons.forum_rounded), findsNothing);

    // Flush RunProvider's autosave debounce so no Timer outlives the tree.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('PauseOverlay renders GAME PAUSED when session paused', (
    tester,
  ) async {
    final (session, rp) = makeSession();
    await session.startAsMain(
      nickname: 'T',
      character: rp.gungeoneerByName('The Paradox') ?? Gungeoneer(name: 'The Paradox'),
      avatarId: 'the_paradox',
      runTitle: 'Test Run',
    );

    await tester.pumpWidget(
      wrap(session, rp, const PauseOverlay(child: SizedBox.expand())),
    );
    await tester.pump();

    // Not paused — no overlay text.
    expect(find.text('GAME PAUSED'), findsNothing);

    // Pause — monochrome overlay + GAME PAUSED label appear.
    session.pause();
    await tester.pump();
    expect(find.text('GAME PAUSED'), findsOneWidget);

    // Resume — overlay clears.
    session.resume();
    await tester.pump();
    expect(find.text('GAME PAUSED'), findsNothing);

    await tester.pump(const Duration(seconds: 3));
  });
}
