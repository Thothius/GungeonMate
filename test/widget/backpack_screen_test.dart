import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gungeon_mate/models/gun.dart';
import 'package:gungeon_mate/models/gungeoneer.dart';
import 'package:gungeon_mate/models/item.dart';
import 'package:gungeon_mate/models/player.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/screens/backpack_screen.dart';
import 'package:gungeon_mate/screens/item_detail_screen.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/widgets/active_run/player_page.dart';
import 'package:gungeon_mate/widgets/periodic_tile.dart';

/// Backpack UI: long-press pill STASH action, open-inventory filtering,
/// Backpack item tap-through, and the BackpackScreen's stored-tile
/// interactions (tap → detail, long-press → TAKE OUT / DELETE / SEND).
void main() {
  late RunProvider p;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    p = RunProvider();
    await p.loadData();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    p.startNewRun(Gungeoneer(name: 'Marine'));
    // Tall surface so the whole player page (guns + items sections)
    // builds without scrolling — slivers are lazy.
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Widget wrap(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: p),
        ChangeNotifierProvider(create: (_) => MpSession.placeholder()),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  /// Long-press the inventory tile whose label shows [label]
  /// (title case, as the periodic grid renders names). Fixed pumps —
  /// PlayerPage runs perpetual animations so pumpAndSettle never ends.
  Future<void> longPressTile(WidgetTester t, String label) async {
    final tile = find.ancestor(
      of: find.text(label),
      matching: find.byType(PeriodicTile),
    );
    // PeriodicTile's long-press is a custom hold cycle: the gesture's
    // onLongPressStart fires at ~500ms, then an inner 200ms delay
    // fires the action — hold ~800ms+ or it cancels on release.
    final gesture = await t.startGesture(t.getCenter(tile.first));
    await t.pump(const Duration(milliseconds: 900));
    await gesture.up();
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
  }

  Future<void> pumpPlayerPage(WidgetTester t) async {
    await t.pumpWidget(wrap(PlayerPage(slot: PlayerSlot.main)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
  }

  Future<void> pumpBag(WidgetTester t, {PlayerSlot slot = PlayerSlot.main}) async {
    await t.pumpWidget(
      wrap(Scaffold(body: BackpackScreen(slot: slot))),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
  }

  // ── Open inventory ─────────────────────────────────────────────

  testWidgets('long-press pill shows STASH and DELETE', (t) async {
    t.view.physicalSize = const Size(900, 1800);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    p.addGun(Gun(name: 'Pill Test Gun'));
    await pumpPlayerPage(t);

    await longPressTile(t, 'Pill Test Gun');

    expect(find.text('STASH'), findsOneWidget);
    expect(find.text('DELETE'), findsOneWidget);
    // Solo run — no co-op partner, so SEND is hidden.
    expect(find.text('SEND'), findsNothing);
  });

  testWidgets('STASH removes the tile from the open grid', (t) async {
    t.view.physicalSize = const Size(900, 1800);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    p.addGun(Gun(name: 'Stow Me'));
    await pumpPlayerPage(t);

    await longPressTile(t, 'Stow Me');
    await t.tap(find.text('STASH'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));

    expect(p.isBackpacked(Gun(name: 'Stow Me'), PlayerSlot.main), isTrue);
    // Tile gone from the open inventory.
    expect(find.text('Stow Me'), findsNothing);
    // ...and a toast confirmed the stash.
    expect(find.textContaining('stowed in backpack'), findsOneWidget);
  });

  testWidgets('Backpack item tile opens BackpackScreen', (t) async {
    t.view.physicalSize = const Size(900, 1800);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    await pumpPlayerPage(t);
    await t.tap(find.text('Backpack'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));

    expect(find.byType(BackpackScreen), findsOneWidget);
    expect(find.text('0/12'), findsOneWidget);
  });

  testWidgets('stashed gear is hidden but still counted', (t) async {
    t.view.physicalSize = const Size(900, 1800);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    final g = Gun(name: 'Hidden Gun');
    p.addGun(g);
    p.stashGun(g);
    final gunsBefore = p.runState.main.guns.length;

    await pumpPlayerPage(t);

    // Gun still in the player's inventory (everything counts)…
    expect(p.runState.main.guns.length, gunsBefore);
    // …but its name doesn't render in the open grid.
    expect(find.text('Hidden Gun'), findsNothing);
    // The ITEMS header shows the backpack shortcut.
    expect(find.byIcon(Icons.backpack_outlined), findsWidgets);
  });

  testWidgets('all-stowed section shows the bag card, not starter hint',
      (t) async {
    t.view.physicalSize = const Size(900, 1800);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    // Stash every gun the player owns (starter roll + none added).
    for (final g in List.of(p.runState.main.guns)) {
      p.stashGun(g);
    }
    await pumpPlayerPage(t);

    expect(find.textContaining('stowed'), findsWidgets);
    expect(find.textContaining('Guns'), findsWidgets);
  });

  // ── BackpackScreen ─────────────────────────────────────────────

  testWidgets('BackpackScreen renders stored tiles + free slots',
      (t) async {
    t.view.physicalSize = const Size(900, 1400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    final g = Gun(name: 'Bag Gun');
    final it = Item(name: 'Bag Item');
    p.addGun(g);
    p.addItem(it);
    p.stashGun(g);
    p.stashItem(it);

    await pumpBag(t);

    expect(find.text('2/12'), findsOneWidget);
    expect(find.text('BAG GUN'), findsOneWidget);
    expect(find.text('BAG ITEM'), findsOneWidget);
    expect(find.text('10 free'), findsOneWidget);
  });

  testWidgets('empty backpack shows the hint', (t) async {
    await pumpBag(t);

    expect(find.text("Bag's empty"), findsOneWidget);
    expect(find.textContaining('STASH'), findsOneWidget);
  });

  testWidgets('tap stored tile opens the detail view', (t) async {
    final it = Item(name: 'Inspect Me', effect: 'A test item.');
    p.addItem(it);
    p.stashItem(it);

    await pumpBag(t);
    await t.tap(find.text('INSPECT ME'));
    await t.pumpAndSettle();

    expect(find.byType(ItemDetailScreen), findsOneWidget);
  });

  testWidgets('long-press stored tile → TAKE OUT returns it', (t) async {
    final g = Gun(name: 'Retrieve Me');
    p.addGun(g);
    p.stashGun(g);

    await pumpBag(t);
    await t.longPress(find.text('RETRIEVE ME'));
    await t.pumpAndSettle();
    expect(find.text('TAKE OUT'), findsOneWidget);

    await t.tap(find.text('TAKE OUT'));
    await t.pumpAndSettle();

    expect(p.isBackpacked(g, PlayerSlot.main), isFalse);
    expect(find.text('RETRIEVE ME'), findsNothing);
    expect(find.text('0/12'), findsOneWidget);
  });

  testWidgets('long-press stored tile → DELETE removes it', (t) async {
    final it = Item(name: 'Delete Me');
    p.addItem(it);
    p.stashItem(it);

    await pumpBag(t);
    await t.longPress(find.text('DELETE ME'));
    await t.pumpAndSettle();
    await t.tap(find.text('DELETE'));
    await t.pumpAndSettle();

    expect(
      p.runState.main.items.any((i) => i.name == 'Delete Me'),
      isFalse,
    );
    expect(p.backpackCount(PlayerSlot.main), 0);
  });

  testWidgets('long-press pill names the entry', (t) async {
    final it = Item(name: 'Caption Check');
    p.addItem(it);
    p.stashItem(it);

    await pumpBag(t);
    await t.longPress(find.text('CAPTION CHECK'));
    await t.pumpAndSettle();

    // Tile label + pill caption both render the name.
    expect(find.text('CAPTION CHECK'), findsNWidgets(2));
  });

  testWidgets('Backpack item pill hides STASH+DELETE solo (toast instead)',
      (t) async {
    t.view.physicalSize = const Size(900, 1800);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    await pumpPlayerPage(t);
    await longPressTile(t, 'Backpack');

    // Solo: no transfer partner → nothing for the pill to offer, so
    // long-press explains instead of showing an empty pill.
    expect(find.text('The Backpack stays with you'), findsOneWidget);
    expect(find.text('DELETE'), findsNothing);
    expect(find.text('STASH'), findsNothing);
    expect(find.text('SEND'), findsNothing);
  });

  testWidgets('Backpack item pill offers only SEND in co-op', (t) async {
    t.view.physicalSize = const Size(900, 1400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    p.startCoopPlayer(Gungeoneer(name: 'Hunter'));
    await pumpPlayerPage(t);
    await longPressTile(t, 'Backpack');

    expect(find.text('SEND'), findsOneWidget);
    expect(find.text('STASH'), findsNothing);
    expect(find.text('DELETE'), findsNothing);
  });

  testWidgets('local co-op SEND moves stashed gear to partner open inventory',
      (t) async {
    t.view.physicalSize = const Size(900, 1400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    p.startCoopPlayer(Gungeoneer(name: 'Hunter'));
    final it = Item(name: 'Gift Me');
    p.addItem(it); // main slot
    p.stashItem(it);

    await pumpBag(t);
    await t.longPress(find.text('GIFT ME'));
    await t.pumpAndSettle();
    expect(find.text('SEND'), findsOneWidget);

    // Arm then confirm.
    await t.tap(find.text('SEND'));
    await t.pumpAndSettle();
    await t.tap(find.text('SURE?'));
    await t.pumpAndSettle();

    // Left main's bag AND main's inventory; landed in coop's OPEN
    // inventory (no backpack key on the receiving side).
    expect(p.runState.main.items.any((i) => i.name == 'Gift Me'), isFalse);
    expect(p.backpackCount(PlayerSlot.main), 0);
    final coop = p.runState.coop!;
    expect(coop.items.any((i) => i.name == 'Gift Me'), isTrue);
    expect(coop.backpackKeys.contains('i:Gift Me'), isFalse);
  });

  testWidgets('coop backpack is independent', (t) async {
    t.view.physicalSize = const Size(900, 1400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    p.startCoopPlayer(Gungeoneer(name: 'Hunter'));
    final g = Gun(name: 'P2 Gun');
    p.addGun(g, slot: PlayerSlot.coop);
    p.stashGun(g, slot: PlayerSlot.coop);

    await pumpBag(t, slot: PlayerSlot.coop);

    expect(find.text('1/12'), findsOneWidget);
    expect(find.text('P2 GUN'), findsOneWidget);
    // Main's bag stays empty.
    expect(p.backpackCount(PlayerSlot.main), 0);
  });

  testWidgets('narrow viewport renders without overflow', (t) async {
    final g = Gun(name: 'Tiny Screen Gun');
    p.addGun(g);
    p.stashGun(g);
    t.view.physicalSize = const Size(320, 640);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    await pumpBag(t);

    expect(t.takeException(), isNull);
    expect(find.text('1/12'), findsOneWidget);
  });
}
