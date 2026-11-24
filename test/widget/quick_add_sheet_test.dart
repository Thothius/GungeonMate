import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gungeon_mate/models/gungeoneer.dart';
import 'package:gungeon_mate/models/item.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/screens/active_run_screen.dart';
import 'package:gungeon_mate/services/mp/mp_transport.dart';
import 'package:gungeon_mate/services/mp_session.dart';

import '../helpers/fake_mp_link.dart';
import 'package:gungeon_mate/widgets/game_icon.dart';

/// Widget tests for the quick-add bottom sheet (`_showQuickAddBottomSheet`
/// in active_run_screen.dart) — FAB → searchable tap-to-add catalog.
///
/// Catalog data loads once in setUpAll (real async zone) because
/// RunProvider.loadData() uses compute() isolates whose futures never
/// resolve inside testWidgets' FakeAsync zone.
/// Spy session — records peer-add calls while delegating to the real
/// facade (the injected FakeMpLink is disconnected, so the underlying
/// send early-returns; we only need to prove the UI routed there).
class _SpyMpSession extends MpSession {
  // ignore: use_super_parameters — named super ctor can't take super params
  _SpyMpSession(RunProvider rp, MpTransport link) : super.withLink(rp, link);

  final List<String> peerAdds = [];

  @override
  Future<void> sendAddToPeer({
    required String kind,
    required String name,
  }) {
    peerAdds.add('$kind:$name');
    return super.sendAddToPeer(kind: kind, name: name);
  }
}

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
  });

  Widget wrap() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: p),
        ChangeNotifierProvider(create: (_) => MpSession.placeholder()),
      ],
      child: const MaterialApp(home: ActiveRunScreen()),
    );
  }

  Future<void> pumpScreen(WidgetTester t) async {
    await t.pumpWidget(wrap());
    await t.pump();
    await t.pump(const Duration(seconds: 1));
  }

  Future<void> openSheet(WidgetTester t) async {
    await t.tap(find.widgetWithIcon(FloatingActionButton, Icons.add));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
  }

  /// The modal bottom sheet hosting the quick-add UI.
  Finder sheet() => find.byType(BottomSheet);

  /// Text anywhere inside the sheet (header, toast, empty state).
  Finder sheetText(String text) =>
      find.descendant(of: sheet(), matching: find.text(text));

  /// Result-row text — scoped to the results ListView so the search
  /// field's EditableText echo of the query can't produce a second
  /// match for `find.text`.
  Finder sheetRowText(String text) => find.descendant(
    of: find.descendant(of: sheet(), matching: find.byType(ListView)),
    matching: find.text(text),
  );

  Future<void> search(WidgetTester t, String query) async {
    await t.enterText(
      find.descendant(of: sheet(), matching: find.byType(TextField)),
      query,
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
  }

  /// First catalog gun not already in the starter loadout.
  dynamic unownedGun() {
    final owned = p.runState.main.guns.map((g) => g.name).toSet();
    return p.allGuns.firstWhere((g) => !owned.contains(g.name));
  }

  /// First catalog item not already owned ('Junk' is never "owned" —
  /// the sheet special-cases it as always addable).
  Item unownedItem() {
    final owned = p.runState.main.items.map((i) => i.name).toSet();
    return p.allItems.firstWhere(
      (i) => i.name != 'Junk' && !owned.contains(i.name),
    );
  }

  // ── Discovery view ─────────────────────────────────────────────

  testWidgets('opens with random discovery rows and no exception', (t) async {
    await pumpScreen(t);
    await openSheet(t);

    expect(sheetText('Tap to add'), findsOneWidget);
    expect(
      find.descendant(of: sheet(), matching: find.byType(ListView)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet(), matching: find.byType(GameIcon)),
      findsWidgets,
    );
    expect(t.takeException(), isNull);
  });

  // ── Search filtering ───────────────────────────────────────────

  testWidgets('typing a full gun name filters to that gun', (t) async {
    final gun = unownedGun();
    await pumpScreen(t);
    await openSheet(t);
    await search(t, gun.name);

    expect(sheetRowText(gun.name), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('partial query matches multiple rows', (t) async {
    // 'pistol' appears in several gun names — a short query must not
    // collapse to zero results.
    await pumpScreen(t);
    await openSheet(t);
    await search(t, 'pistol');

    expect(
      find.descendant(of: sheet(), matching: find.byType(GameIcon)),
      findsWidgets,
    );
    expect(t.takeException(), isNull);
  });

  // ── Tap to add ─────────────────────────────────────────────────

  testWidgets('tapping a gun result adds it to the loadout', (t) async {
    final gun = unownedGun();
    final before = p.runState.main.guns.length;
    await pumpScreen(t);
    await openSheet(t);
    await search(t, gun.name);

    await t.tap(sheetRowText(gun.name));
    await t.pump();

    expect(
      p.runState.main.guns.any((g) => g.name == gun.name),
      isTrue,
      reason: 'gun was not added',
    );
    expect(p.runState.main.guns.length, before + 1);
    expect(
      find.descendant(of: sheet(), matching: find.textContaining('Added:')),
      findsOneWidget,
    );
    // Flush RunProvider's 400ms save debounce + the 800ms toast timer —
    // a pending Timer at teardown fails the test.
    await t.pump(const Duration(milliseconds: 900));
    expect(t.takeException(), isNull);
  });

  testWidgets('tapping an item result adds it to the loadout', (t) async {
    final item = unownedItem();
    await pumpScreen(t);
    await openSheet(t);
    await search(t, item.name);

    await t.tap(sheetRowText(item.name));
    await t.pump();

    expect(
      p.runState.main.items.any((i) => i.name == item.name),
      isTrue,
      reason: 'item was not added',
    );
    expect(
      find.descendant(of: sheet(), matching: find.textContaining('Added:')),
      findsOneWidget,
    );
    await t.pump(const Duration(milliseconds: 900));
    expect(t.takeException(), isNull);
  });

  // ── Owned state ────────────────────────────────────────────────

  testWidgets('owned result shows OWNED tag and cannot be re-added', (t) async {
    final item = unownedItem();
    p.addItem(item);
    final countBefore = p.runState.main.items.length;

    await pumpScreen(t);
    await openSheet(t);
    await search(t, item.name);

    expect(sheetRowText('OWNED'), findsOneWidget);

    await t.tap(sheetRowText(item.name));
    await t.pump();

    expect(p.runState.main.items.length, countBefore);
    expect(t.takeException(), isNull);
  });

  // ── Header polish ──────────────────────────────────────────────

  testWidgets('close button is 38px icon in a 48px touch target', (t) async {
    await pumpScreen(t);
    await openSheet(t);

    final closeFinder = find.descendant(
      of: sheet(),
      matching: find.byIcon(Icons.close),
    );
    expect(closeFinder, findsOneWidget);
    final icon = t.widget<Icon>(closeFinder);
    expect(icon.size, 38);

    final button = t.widget<IconButton>(
      find.ancestor(of: closeFinder, matching: find.byType(IconButton)),
    );
    expect(button.constraints?.minWidth, 48);
    expect(button.constraints?.minHeight, 48);
    expect(t.takeException(), isNull);
  });

  testWidgets('sheet renders without overflow on a narrow viewport', (t) async {
    t.view.physicalSize = const Size(320, 568);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    await pumpScreen(t);
    await openSheet(t);
    await search(t, 'gun');

    expect(sheetText('Tap to add'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  // ── Dismiss / clear ────────────────────────────────────────────

  testWidgets('close button dismisses the sheet', (t) async {
    await pumpScreen(t);
    await openSheet(t);

    // Empty query → only the header close icon exists.
    expect(
      find.descendant(of: sheet(), matching: find.byIcon(Icons.close)),
      findsOneWidget,
    );
    await t.tap(
      find.descendant(of: sheet(), matching: find.byIcon(Icons.close)),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));

    expect(sheetText('Tap to add'), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('suffix clear button empties the search field', (t) async {
    await pumpScreen(t);
    await openSheet(t);
    await search(t, 'zzz-no-match');

    // Header close + suffix clear = two close icons while query non-empty.
    expect(
      find.descendant(of: sheet(), matching: find.byIcon(Icons.close)),
      findsNWidgets(2),
    );
    await t.tap(
      find.descendant(of: sheet(), matching: find.byIcon(Icons.close)).last,
    );
    await t.pump();

    final field = t.widget<TextField>(
      find.descendant(of: sheet(), matching: find.byType(TextField)),
    );
    expect(field.controller?.text ?? '', isEmpty);
    // Back to discovery rows.
    expect(
      find.descendant(of: sheet(), matching: find.byType(GameIcon)),
      findsWidgets,
    );
    expect(t.takeException(), isNull);
  });

  // ── Fresh view per open ────────────────────────────────────────

  testWidgets('reopening after adding starts from a clean query', (t) async {
    final gun = unownedGun();
    await pumpScreen(t);
    await openSheet(t);
    await search(t, gun.name);
    await t.tap(sheetRowText(gun.name));
    await t.pump();

    // Close via header X (query non-empty → two close icons; header is first).
    await t.tap(
      find.descendant(of: sheet(), matching: find.byIcon(Icons.close)).first,
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));

    await openSheet(t);
    final field = t.widget<TextField>(
      find.descendant(of: sheet(), matching: find.byType(TextField)),
    );
    expect(field.controller?.text ?? '', isEmpty);
    expect(
      find.descendant(of: sheet(), matching: find.byType(GameIcon)),
      findsWidgets,
    );
    expect(t.takeException(), isNull);
  });

  // ── MP peer-add seam (Session B) ────────────────────────────────

  testWidgets(
    'adding on the peer page routes to sendAddToPeer, not local inventory',
    (t) async {
      final spy = _SpyMpSession(p, FakeMpLink());
      spy.enableDemo();
      await t.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: p),
            ChangeNotifierProvider<MpSession>.value(value: spy),
          ],
          child: const MaterialApp(home: ActiveRunScreen()),
        ),
      );
      await t.pump();
      await t.pump(const Duration(seconds: 1));

      // Flip to the peer's page so the FAB targets the coop slot —
      // mySlot (main) != widget.slot (coop) → peer-add path.
      await t.fling(find.byType(PageView), const Offset(-400, 0), 800);
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));

      final item = unownedItem();
      await openSheet(t);
      await search(t, item.name);
      await t.tap(sheetRowText(item.name));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      expect(spy.peerAdds, ['item:${item.name}']);
      // Peer path must NOT touch the local loadout.
      expect(
        p.runState.coop?.items.any((i) => i.name == item.name) ?? false,
        isFalse,
      );
      expect(t.takeException(), isNull);
      spy.dispose();
    },
  );
}

