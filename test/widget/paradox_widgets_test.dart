import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/screens/cool_curse_screen.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/models/gungeoneer.dart';
import 'package:gungeon_mate/models/player.dart';
import 'package:gungeon_mate/utils/asset_paths.dart';
import 'package:gungeon_mate/services/app_theme.dart';
import 'package:gungeon_mate/widgets/paradox/avatar_frame.dart';
import 'package:gungeon_mate/widgets/paradox/paradox_bar.dart';
import 'package:gungeon_mate/widgets/paradox/paradox_player_panel.dart';
import 'package:gungeon_mate/widgets/paradox/pause_overlay.dart';
import '../helpers/fake_mp_link.dart';

/// Paradox run-view widgets — MP bar shows session meta, pause overlay
/// reacts to the session's pausedNotifier.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

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
      character:
          rp.gungeoneerByName('The Paradox') ?? Gungeoneer(name: 'The Paradox'),
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
      character:
          rp.gungeoneerByName('The Paradox') ?? Gungeoneer(name: 'The Paradox'),
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

  testWidgets('ParadoxPlayerPanel falls back to default avatar, never a '
      'gungeoneer sprite, when avatarId is empty', (tester) async {
    final (session, rp) = makeSession();
    await session.startAsMain(
      nickname: 'T',
      character:
          rp.gungeoneerByName('The Paradox') ?? Gungeoneer(name: 'The Paradox'),
      avatarId: '',
      runTitle: 'Test Run',
    );

    await tester.pumpWidget(
      wrap(
        session,
        rp,
        const ParadoxPlayerPanel(slot: PlayerSlot.main),
      ),
    );
    await tester.pump();

    // Custom avatar path is used even with an empty wire id.
    expect(find.byType(FramedAvatar), findsOneWidget);
    final avatarAsset = avatarPath(kAvatarIds.first);
    final hasAvatarImage = tester.widgetList<Image>(find.byType(Image)).any(
      (img) =>
          img.image is AssetImage &&
          (img.image as AssetImage).assetName == avatarAsset,
    );
    expect(hasAvatarImage, isTrue);

    await tester.pump(const Duration(seconds: 3));
  });

  group('ParadoxPlayerPanel interactions', () {
    Future<(MpSession, RunProvider)> pumpPanel(WidgetTester tester) async {
      final (session, rp) = makeSession();
      await session.startAsMain(
        nickname: 'T',
        character:
            rp.gungeoneerByName('The Paradox') ??
            Gungeoneer(name: 'The Paradox'),
        avatarId: 'the_paradox',
        runTitle: 'Test Run',
      );
      await tester.pumpWidget(
        wrap(session, rp, const ParadoxPlayerPanel(slot: PlayerSlot.main)),
      );
      await tester.pump();
      return (session, rp);
    }

    testWidgets('renders COOL / CURSE / SYN stat chips', (tester) async {
      await pumpPanel(tester);
      expect(find.text('COOL'), findsOneWidget);
      expect(find.text('CURSE'), findsOneWidget);
      expect(find.text('SYN'), findsOneWidget);
      expect(find.text('YOU'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('tap COOL opens quick sheet, long-press opens explainer', (
      tester,
    ) async {
      await pumpPanel(tester);

      await tester.tap(find.text('COOL'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      // Quick-manage sheet opened (coolness title).
      expect(find.text('COOLNESS'), findsWidgets);
      // Dismiss the sheet by tapping the barrier above it.
      await tester.tapAt(const Offset(400, 40));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.longPress(find.text('CURSE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      // Full explainer screen pushed.
      expect(find.byType(CoolCurseScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('run menu pause toggles session, panels toggle flips pref', (
      tester,
    ) async {
      final (session, _) = await pumpPanel(tester);
      final dashboardsBefore = VisualPrefs.notifier.value.showDashboards;

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Pause Run'), findsOneWidget);
      expect(find.text('Diceroller'), findsOneWidget);

      await tester.tap(find.text('Pause Run'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(session.isPaused, isTrue);

      // Reopen — now offers Resume.
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Resume Run'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(session.isPaused, isFalse);

      // DISPLAY > Panels toggle flips the global pref.
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Panels'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        VisualPrefs.notifier.value.showDashboards,
        isNot(dashboardsBefore),
      );

      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('reset P1 menu item confirms then clears own inventory', (
      tester,
    ) async {
      final (session, rp) = await pumpPanel(tester);
      // Asset JSON loads on the real event loop — runAsync required
      // inside testWidgets or the future never completes.
      await tester.runAsync(() => rp.loadData());
      String? addedName;
      if (rp.allItems.isNotEmpty) {
        addedName = rp.allItems.first.name;
        rp.addItem(rp.allItems.first, force: true);
      }
      expect(rp.runState.main.items.any((i) => i.name == addedName), isTrue);

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Reset P1 Items'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Reset your items?'), findsOneWidget);
      await tester.tap(find.text('RESET'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Inventory cleared for the main slot — player object rebuilt
      // fresh (character kept, gear gone).
      expect(
        rp.runState.main.items.any((i) => i.name == addedName),
        isFalse,
      );
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
